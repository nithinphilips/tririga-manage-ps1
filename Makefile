
PANDOC_BIN:=pandoc

VERSION:=$(shell sed -n "s/ModuleVersion = '\(.*\)'/\1/p" Tririga-Manage/Tririga-Manage.psd1)
PSFILES:=$(shell find . \( -iname *.psd1 -or -iname *.psm1 \) -and ! -path "*dist/*")

DISTROOT:=dist
DISTBASE:=tririga-manage-ps1
DISTDIR:=$(DISTROOT)/$(DISTBASE)
DISTZIP:=tririga-manage-ps1-$(VERSION).zip

.PHONY: dist

DIST_EXTRAS:=Install.ps1 environments.sample.ps1 README.rst ChangeLog.rst README.docx ChangeLog.docx

.INTERMEDIATE: Tririga-Manage.csv Tririga-Manage-Rest.csv all-docs.csv all-docs.tmp README.docx ChangeLog.docx


%.docx: %.rst
	$(PANDOC_BIN) -t docx -o $@ $<

# Select-Object Name,Synopsis,ModuleName
%.csv: $(PSFILES)
	pwsh -Command "\$$env:PSModulePath = (Resolve-Path .).Path; Get-Command -Module $* | % {Get-Help \$$_.Name} | Select-Object Name,Synopsis | Export-CSV $*.csv"

all-docs.csv: Tririga-Manage.csv Tririga-Manage-Rest.csv
	mlr --icsv --ocsv cat then sort -f Name then clean-whitespace $^ > $@

$(DISTROOT)/$(DISTZIP): $(DIST_EXTRAS) $(PSFILES)
	mkdir -p $(DISTDIR)
	cp -r Tririga-Manage/ $(DISTDIR)/Tririga-Manage/$(VERSION)/
	cp -r Tririga-Manage-Rest $(DISTDIR)
	cp $(DIST_EXTRAS) $(DISTDIR)/
	cd $(DISTROOT) && zip -r $(DISTZIP) $(DISTBASE)/
	rm -rf $(DISTDIR)

all-docs.tmp: all-docs.csv
	echo ".. csv-table::" > $@
	echo "    :header-rows: 1" >> $@
	echo "    :stub-columns: 1" >> $@
	echo "" >> $@
	sed 's/^/    /g' $< >> $@

update-readme: all-docs.tmp
	# Delete everything between these lines
	sed -i -e '/BEGIN TABLE/,/END TABLE/{//!d}' README.rst
	sed -i -e '/BEGIN TABLE/ r $<' README.rst

dist: $(DISTROOT)/$(DISTZIP)
