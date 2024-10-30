
VERSION=$(shell sed -n "s/ModuleVersion = '\(.*\)'/\1/p" Tririga-Manage/Tririga-Manage.psd1)

PSFILES=$(shell find . \( -iname *.psd1 -or -iname *.psm1 \) -and ! -path "*dist/*")

DISTROOT:=dist
DISTBASE:=tririga-manage-ps1
DISTDIR:=$(DISTROOT)/$(DISTBASE)
DISTZIP:=tririga-manage-ps1-$(VERSION).zip

.PHONY: dist

DIST_EXTRAS:=Install.ps1 environments.example.ps1 README.rst ChangeLog.rst

$(DISTROOT)/$(DISTZIP): $(DIST_EXTRAS) $(PSFILES)
	mkdir -p $(DISTDIR)
	cp -r Tririga-Manage $(DISTDIR)
	cp -r Tririga-Manage-Rest $(DISTDIR)
	cp $(DIST_EXTRAS) $(DISTDIR)/
	cd $(DISTROOT) && zip -r $(DISTZIP) $(DISTBASE)/

dist: $(DISTROOT)/$(DISTZIP)
