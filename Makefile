.PHONY: dist all clean

PANDOC_BIN:=pandoc
AWS_BIN=aws

AWS_BUCKET=tririga-shared-files-np

NO_GIT_REMOTE_CHECK?=0

VERSION:=$(shell sed -n "s/ModuleVersion = '\(.*\)'/\1/p" Tririga-Manage/Tririga-Manage.psd1)
PSFILES:=$(shell find . \( -iname *.psd1 -or -iname *.psm1 \) -and ! -path "*dist/*")

GIT_TAG=v$(VERSION)

DISTROOT:=dist
DISTBASE:=tririga-manage-ps1
DISTDIR:=$(DISTROOT)/$(DISTBASE)
DISTZIP:=tririga-manage-ps1-$(VERSION).zip



DIST_EXTRAS:=Install.ps1 environments.sample.ps1 README.rst ChangeLog.rst README.docx ChangeLog.docx

.INTERMEDIATE: Tririga-Manage.csv Tririga-Manage-Rest.csv all-docs.csv all-docs.tmp README.docx ChangeLog.docx ChangeLog.md ChangeLog.$(GIT_TAG).md

# Extract a changelog for a specific version from ChangeLog.rst
# cargo install markdown-extract
ChangeLog.%.md: ChangeLog.md
	markdown-extract $* $< | sed 1d > $@

%.md: %.rst
	pandoc --from=rst --to=markdown --columns=99999 -o $@ $<

%.docx: %.rst
	$(PANDOC_BIN) -t docx -o $@ $<

# Select-Object Name,Synopsis,ModuleName
%.csv: $(PSFILES)
	pwsh -Command "\$$env:PSModulePath = (Resolve-Path .).Path; Get-Command -Module $* | % {\$$h=(Get-Help \$$_.Name); if(\$$_.CommandType -eq \"Alias\") {Add-Member -Force -InputObject \$$h "Name" \$$_.Name}; \$$h} | Select-Object Name,Synopsis | Export-CSV $*.csv"

all-docs.csv: Tririga-Manage.csv Tririga-Manage-Rest.csv
	mlr --icsv --ocsv cat then put '$$SortName = splitax($$Name, "-")[2]' then sort -f SortName then cut -x -f SortName then clean-whitespace $^ > $@

$(DISTROOT)/$(DISTZIP): update-module update-readme $(DIST_EXTRAS) $(PSFILES)
	mkdir -p $(DISTDIR) $(DISTDIR)/Tririga-Manage/$(VERSION) $(DISTDIR)/Tririga-Manage-Rest/$(VERSION)
	cp -r Tririga-Manage/* $(DISTDIR)/Tririga-Manage/$(VERSION)/
	cp -r Tririga-Manage-Rest/* $(DISTDIR)/Tririga-Manage-Rest/$(VERSION)/
	cp $(DIST_EXTRAS) $(DISTDIR)/
	cd $(DISTROOT) && zip -r $(DISTZIP) $(DISTBASE)/
	rm -rf $(DISTDIR)

all-docs.tmp: all-docs.csv
	echo ".. csv-table::" > $@
	echo "    :header-rows: 1" >> $@
	echo "    :stub-columns: 1" >> $@
	echo "" >> $@
	sed 's/^/    /g' $< >> $@

update-module:
	pwsh Install.ps1 -UpdateModule -NoInstallModule

update-readme: all-docs.tmp
	# Delete everything between these lines
	sed -i -e '/BEGIN TABLE/,/END TABLE/{//!d}' README.rst
	sed -i -e '/BEGIN TABLE/ r $<' README.rst

dist: $(DISTROOT)/$(DISTZIP)

release-check:
	# Check if a ChangeLog entry exists
	test $(shell grep -c '^$(GIT_TAG)' ChangeLog.rst) -eq 1 || (echo "Please add a change log entry for release $(GIT_TAG) before releasing"; exit 1) && (printf "\e[1;38:5:40m✓\e[0m ChangeLog entry exists for release $(GIT_TAG)\n")
	# Check if the tag exists in the local repo
	test $(shell git tag -l | grep -x -c -F "$(GIT_TAG)") -eq 1 || ( echo "The tag $(GIT_TAG) does not exit in this repository. Tag your release first. Run: git tag $(GIT_TAG)"; exit 1 ) && (printf "\e[1;38:5:40m✓\e[0m Git Tag exists for release $(GIT_TAG)\n")
	# Check if the tag exists in the remote repo
	# git ls-remote will open a connection to the remote repository!
	if [ $(NO_GIT_REMOTE_CHECK) -eq 0 ]; then \
			if [ $$(git ls-remote --tags origin | grep -c "refs/tags/$(GIT_TAG)$$") -eq 1 ]; then \
				printf "\e[1;38:5:40m✓\e[0m Tag $(GIT_TAG) has been pushed to origin\n"; \
			else \
				printf "\e[1;38:5:196m✕\e[0m Tag $(GIT_TAG) has not been pushed to remote. Push your tags first by running: git push --tags\n"; \
				exit 1; \
			fi \
	else \
		printf "\e[1;38:5:190m?\e[0m Not checking if tag $(GIT_TAG) has been pushed to origin because NO_GIT_REMOTE_CHECK is set to $(NO_GIT_REMOTE_CHECK)\n"; \
	fi \

release: update-module dist ChangeLog.$(GIT_TAG).md release-check ## Releases the current version to Gitea
	# This uses my version of tea. If it gets upgraded, it may lose the --note-file flag
	# 'tea release create' may fail with exit code 1 if release already exists, but that's OK.
	(tea release create --note-file ChangeLog.$(GIT_TAG).md --tag $(GIT_TAG) --title $(GIT_TAG) && printf "\e[1;38:5:40m✓\e[0m Release $(GIT_TAG) created\n" || printf "\e[1;38:5:190m✓\e[0m Release $(GIT_TAG) exists\n")
	# Remove existing file if you're re-releasing
	#-tea release assets delete --confirm $(GIT_TAG) $(NATIVE_DISTZIP)
	tea release assets create $(GIT_TAG) $(DISTROOT)/$(DISTZIP)
	printf "\e[1;38:5:40m✓\e[0m Uploaded file $(DISTZIP) to release $(GIT_TAG)\n"
	pwsh Install.ps1 -Publish -NoInstallModule -NuGetApiKey $(GITEA_API_TOKEN)
	printf "\e[1;38:5:40m✓\e[0m Published package to Gitea NuGet repository\n"
	pwsh Install.ps1 -PublishPSGallery -NoInstallModule -NuGetApiKey $(PSGALLERY_API_TOKEN)
	printf "\e[1;38:5:40m✓\e[0m Published package to PowerShell Gallery\n"

publish: dist # Published the dist file to Amazon AWS
	aws s3 cp "$(DISTROOT)/$(DISTZIP)" s3://$(AWS_BUCKET) --acl=public-read && echo "OMP Published to: https://$(AWS_BUCKET).s3.amazonaws.com/$(DISTZIP)"

help: ## This help dialog.
	@IFS=$$'\n' ; \
	help_lines=(`fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##/~~/'`); \
	for help_line in $${help_lines[@]}; do \
		IFS=$$'~~' ; \
		help_split=($$help_line) ; \
		IFS=$$':' ; \
		help_command_split=($${help_split[0]}) ; \
		help_command=`echo $${help_command_split[0]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
		help_target=`echo $${help_command_split[1]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
		help_info=`echo $${help_split[2]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
		printf '\033[36m'; \
		printf "%-9s %s" $$help_command ; \
		printf '\033[33m'; \
		printf ": %-35s %s" $$help_target ; \
		printf '\033[0m'; \
		printf "%s\n" $$help_info; \
	done

# Suppress command echo by default. When V=<anything> disable suppression.
$(V).SILENT:
	

