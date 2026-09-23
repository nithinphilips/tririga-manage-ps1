.PHONY: dist all clean

PANDOC_BIN:=pandoc
AWS_BIN=aws

AWS_BUCKET?=tririga-shared-files-np

PROJECT:=tririga-manage-ps1
VERSION:=$(shell sed -n "s/ModuleVersion = '\(.*\)'/\1/p" Tririga-Manage/Tririga-Manage.psd1)
PSFILES:=$(shell find . \( -iname *.psd1 -or -iname *.psm1 \) -and ! -path "*dist/*")

GIT_TAG=v$(VERSION)

DISTROOT:=dist
DISTBASE:=tririga-manage-ps1
DISTDIR:=$(DISTROOT)/$(DISTBASE)
DISTZIP:=tririga-manage-ps1-$(VERSION).zip

DIST_EXTRAS:=Install.ps1 environments.sample.psd1 README.rst ChangeLog.rst README.docx ChangeLog.docx

RELEASE_DIST_FILES:=$(DISTROOT)/$(DISTZIP)
RELEASE_DIST_DEP:=update-module dist
RELEASE_DEPS:=publish-psgallery
RELEASE_GITEA_DEPS:=publish-gitea
RELEASE_CHECK_DEPS:=code-check
include Common.mk
include Release.mk

.INTERMEDIATE: Tririga-Manage.csv Tririga-Manage-Rest.csv Tririga-Manage.processed.csv Tririga-Manage-Rest.processed.csv Tririga-Manage.rst.tmp Tririga-Manage-Rest.rst.tmp all-docs.csv all-docs.tmp README.docx ChangeLog.docx ChangeLog.md ChangeLog.$(GIT_TAG).md environments.sample.psd1.tmp

%.docx: %.rst
	$(PANDOC_BIN) -t docx -o $@ $<

# Select-Object Name,Synopsis,ModuleName
%.csv: $(PSFILES)
	pwsh -Command "\$$env:PSModulePath = (Resolve-Path .).Path; Get-Command -Module $* | % {\$$h=(Get-Help \$$_.Name); if(\$$_.CommandType -eq \"Alias\") {Add-Member -Force -InputObject \$$h "Name" \$$_.Name}; \$$h} | Select-Object Name,Synopsis | Export-CSV $*.csv"
	mlr --icsv --ocsv put '$$SortName = splitax($$Name, "-")[2]' then put '$$Name = format("`{} <docs/{}.md>`_", $$Name,$$Name)' then sort -f SortName then cut -x -f SortName then clean-whitespace $@ > $@.tmp
	mv $@.tmp $@

%.rst.tmp: %.csv
	echo ".. csv-table::" > $@
	echo "    :header-rows: 1" >> $@
	echo "    :stub-columns: 1" >> $@
	echo " " >> $@
	sed 's/^/    /g' $< >> $@

$(DISTROOT)/$(DISTZIP): update-module update-readme $(DIST_EXTRAS) $(PSFILES)
	mkdir -p $(DISTDIR) $(DISTDIR)/Tririga-Manage/$(VERSION) $(DISTDIR)/Tririga-Manage-Rest/$(VERSION)
	cp -r Tririga-Manage/* $(DISTDIR)/Tririga-Manage/$(VERSION)/
	cp -r Tririga-Manage-Rest/* $(DISTDIR)/Tririga-Manage-Rest/$(VERSION)/
	cp $(DIST_EXTRAS) $(DISTDIR)/
	cd $(DISTROOT) && zip -r $(DISTZIP) $(DISTBASE)/
	rm -rf $(DISTDIR)

environments.sample.psd1.tmp: environments.sample.psd1
	echo "   .. code:: ps1" > $@
	echo "   " >> $@
	sed 's/^/        /g' $< >> $@
	dos2unix $@

# TODO: Pickup additional module files (except tests)
Tririga-Manage/Tririga-Manage.psd1 Tririga-Manage-Rest/Tririga-Manage-Rest.psd1: ChangeLog.$(GIT_TAG).md Tririga-Manage/Tririga-Manage.psm1 Tririga-Manage-Rest/Tririga-Manage-Rest.psm1 Install.ps1
	pwsh Install.ps1 -UpdateModule -NoInstallModule -ReleaseNoteFile $<

# Need: https://github.com/PowerShell/platyPS for docs generation
create-docs:
	mkdir -p docs
	pwsh -Command "\$$env:PSModulePath = \"\$$(Resolve-Path .)\" + [IO.Path]::PathSeparator + \$$env:PSModulePath; Import-Module Tririga-Manage -Force; Import-Module Tririga-Manage-Rest -Force; New-MarkdownHelp -OutputFolder docs -Module Tririga-Manage, Tririga-Manage-Rest"

update-docs:
	mkdir -p docs
	pwsh -Command "\$$env:PSModulePath = \"\$$(Resolve-Path .)\" + [IO.Path]::PathSeparator + \$$env:PSModulePath; Import-Module Tririga-Manage -Force; Import-Module Tririga-Manage-Rest -Force; Update-MarkdownHelpModule -Path docs -AlphabeticParamsOrder -RefreshModulePage -UpdateInputOutput"

update-module: Tririga-Manage/Tririga-Manage.psd1 Tririga-Manage-Rest/Tririga-Manage-Rest.psd1 ChangeLog.$(GIT_TAG).md

update-readme: update-module Tririga-Manage.rst.tmp Tririga-Manage-Rest.rst.tmp environments.sample.psd1.tmp
	# Delete everything between these lines
	sed -i -e '/BEGIN TABLE TRIRIGA MANAGE/,/END TABLE TRIRIGA MANAGE/{//!d}' README.rst
	sed -i -e '/BEGIN TABLE TRIRIGA MANAGE/ r Tririga-Manage.rst.tmp' README.rst
	sed -i -e '/BEGIN TABLE TRIRIGA MANAGE REST/,/END TABLE TRIRIGA MANAGE REST/{//!d}' README.rst
	sed -i -e '/BEGIN TABLE TRIRIGA MANAGE REST/ r Tririga-Manage-Rest.rst.tmp' README.rst
	sed -i -e '/BEGIN CONFIG SAMPLE/,/END CONFIG SAMPLE/{//!d}' README.rst
	sed -i -e '/BEGIN CONFIG SAMPLE/ r environments.sample.psd1.tmp' README.rst

dist: $(DISTROOT)/$(DISTZIP)

publish-gitea: update-module
	pwsh Install.ps1 -Publish -NoInstallModule -NuGetApiKey $(GITEA_API_TOKEN)
	printf "\e[1;38:5:40m✓\e[0m Published package to Gitea NuGet repository\n"

publish-psgallery: update-module
	pwsh Install.ps1 -PublishPSGallery -NoInstallModule -NuGetApiKey $(PSGALLERY_API_TOKEN)
	printf "\e[1;38:5:40m✓\e[0m Published package to PowerShell Gallery\n"

check: update-module
	pwsh -Command "\$$env:PSModulePath = \"\$$(Resolve-Path .)\" + [IO.Path]::PathSeparator + \$$env:PSModulePath; Invoke-Pester -Output Detailed"

code-check:
	pwsh -Command "Invoke-ScriptAnalyzer -Recurse -Path Tririga-Manage | ft -AutoSize; Invoke-ScriptAnalyzer -Recurse -Path Tririga-Manage-Rest | ft -AutoSize"


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
	

