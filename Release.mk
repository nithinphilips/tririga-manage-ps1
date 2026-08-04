.PHONY: release-info release release-github release-gitea release-s3 create-git-tag
SHELL := /bin/bash
# Uncomment above and run make --debug --trace ...

######################################
# Release management for Make projects
######################################

CMD_NOT_FOUND = $(error $(1) command is required for Release.mk)
CHECK_CMD = $(if $(shell command -v $(1)),,$(call CMD_NOT_FOUND,$(1)))

#
# Required Variables
#

ifndef PROJECT
  $(error PROJECT variable with the name of the project is not set. Define it before the include statement)
endif

ifndef VERSION
  $(error VERSION with the project version is not set. Define it before the include statement)
endif

ifndef RELEASE_DIST_FILES
  $(error RELEASE_DIST_FILES with a list of release artifacts is not set. Define it before the include statement)
endif

#
# If not set, auto detect remotes and remote types
#
GITHUB_REMOTE_NAME?=$(shell git remote -v | grep --max-count 1 github.com | awk '{print $$1}')
GITEA_REMOTE_NAME?=$(shell git remote -v | grep --max-count 1 gitea | awk '{print $$1}')
S3_BUCKET?=

#
# The name of the dependency that will build the distribution packages
#
RELEASE_DIST_DEP?=dist
GIT_TAG?=v$(VERSION)

# If 1, the released files will be overwritten if they already exist
# The behavior depends on release type.
# Gitea: Duplicates are allowed. If RELEASE_CLOBBER=1, existing file with the same name is deleted first
# Github: If file exists and RELEASE_CLOBBER=0 an error is thrown
RELEASE_CLOBBER=1

CHANGELOG_FILE?=ChangeLog.rst

########################
# Dependency Integration
########################
# Additional targets for the release to depend on
# RELEASE_DIST_DEP is already required
RELEASE_DEPS:=

# Additional target for the release to depend on, but only when publishing to Github, Gitea, or S3
RELEASE_GITEA_DEPS?=
RELEASE_GITHUB_DEPS?=
RELEASE_S3_DEPS?=

RELEASE_CHECK_DEPS?=

#######
# Tools
#######
PANDOC_BIN?=pandoc
AWS_BIN?=aws
# cargo install markdown-extract
MARKDOWN_EXTRACT_BIN?=markdown-extract
GITHUB_BIN?=gh
GITEA_BIN?=tea

# Check if tools exist
$(call CHECK_CMD,git)
$(call CHECK_CMD,grep)
$(call CHECK_CMD,awk)
$(call CHECK_CMD,$(PANDOC_BIN))
$(call CHECK_CMD,$(MARKDOWN_EXTRACT_BIN))

# Flags to pass to various tools. While this can be overriden, it is not
# intended to be changed by users
ifeq ($(RELEASE_CLOBBER), 1) 
  GITHUB_BIN_UPLOAD_CLOBBER_FLAG?=--clobber
else:
  GITHUB_BIN_UPLOAD_CLOBBER_FLAG?=
endif

GITEA_BIN_FLAGS?=--remote $(GITEA_REMOTE_NAME)
S3_BIN_FLAGS?=--acl=public-read

NO_GIT_REMOTE_CHECK?=0
NO_GITHUB_REMOTE_CHECK:=$(NO_GIT_REMOTE_CHECK)
NO_GITEA_REMOTE_CHECK:=$(NO_GIT_REMOTE_CHECK)

#################
# Release Options
#################

RELEASE_HAS_GITHUB_REMOTE=$(shell test $$(git remote -v | grep -c -F github.com) -gt 0 && echo "1" || echo "0")
RELEASE_HAS_GITEA_REMOTE=$(shell test $$(git remote -v | grep -c -F gitea) -gt 0 && echo "1" || echo "0")

# These flags allow us to enable/disable Github/Gitea/S3 remote releases independently
# By default we auto detect based on which remotes are present
ENABLE_GITHUB_RELEASE?=$(RELEASE_HAS_GITHUB_REMOTE)
ENABLE_GITEA_RELEASE?=$(RELEASE_HAS_GITEA_REMOTE)
# Enable/disable S3 release based on the S3_BUCKET variable
ifndef S3_BUCKET
  #$(info S3_BUCKET is not set. S3 Release will be disabled)
  ENABLE_S3_RELEASE?=0
else
  ENABLE_S3_RELEASE?=1
endif

# If a release type is disabled, skip remote tag check for that type
ifeq ($(ENABLE_GITHUB_RELEASE), 0)
 NO_GITHUB_REMOTE_CHECK:=1
endif

ifeq ($(ENABLE_GITEA_RELEASE), 0)
 NO_GITEA_REMOTE_CHECK:=1
endif

# Dynamically set release dependencies depending on which release types are enabled
RELEASE_DEPS?=

ifeq ($(ENABLE_GITHUB_RELEASE),1)
 RELEASE_DEPS:=$(RELEASE_DEPS) release-github
 GITHUB_BIN_FLAGS=$(GITHUB_BIN_FLAGS) --repo "$(shell git remote get-url $(GITHUB_REMOTE_NAME))"
 #$(call CHECK_CMD,$(GITHUB_BIN))
endif

ifeq ($(ENABLE_GITEA_RELEASE),1)
 RELEASE_DEPS:=$(RELEASE_DEPS) release-gitea
 #$(call CHECK_CMD,$(GITEA_BIN))
endif

ifeq ($(ENABLE_S3_RELEASE),1)
 RELEASE_DEPS:=$(RELEASE_DEPS) release-s3
 #$(call CHECK_CMD,$(AWS_BIN))
endif

.INTERMEDIATE: ChangeLog.$(GIT_TAG).md ChangeLog.md

release-info: ## Debug information about the release configuration
	@echo "RELEASE_HAS_GITHUB_REMOTE: $(RELEASE_HAS_GITHUB_REMOTE)"
	@echo "RELEASE_HAS_GITEA_REMOTE: $(RELEASE_HAS_GITEA_REMOTE)"
	@echo "ENABLE_GITHUB_RELEASE: $(ENABLE_GITHUB_RELEASE)"
	@echo "ENABLE_GITEA_RELEASE: $(ENABLE_GITEA_RELEASE)"
	@echo "ENABLE_S3_RELEASE: $(ENABLE_S3_RELEASE)"
	@echo "GITEA_REMOTE_NAME: $(GITEA_REMOTE_NAME)"
	@echo "GITHUB_REMOTE_NAME: $(GITHUB_REMOTE_NAME)"
	@echo "RELEASE_DEPS: $(RELEASE_DEPS)"
	@echo "RELEASE_DIST_FILES: $(RELEASE_DIST_FILES)"

# Convert RST files to Markdown
%.md: %.rst
	$(PANDOC_BIN) --from=rst --to=markdown --columns=99999 -o $@ $<

# Extract a changelog for a specific version from ChangeLog gile
ChangeLog.%.md: ChangeLog.md
	$(MARKDOWN_EXTRACT_BIN) $* $< | sed 1d > $@

create-git-tag: ## Creates a git tag for the current version
	git tag v$(VERSION)

release-check: $(RELEASE_CHECK_DEPS) ## Checks if the repo is ready to make a release
	# Check if repo is clean
	git diff-index --quiet HEAD -- || (echo "You have uncommited changes. Commit them before release."; exit 1) && (printf "\e[1;38:5:40m✓\e[0m No uncommited changes\n")
	# Check if a ChangeLog file exists
	test -f $(CHANGELOG_FILE) || (echo "Error: Please add a $(CHANGELOG_FILE) file"; exit 1) && (printf "\e[1;38:5:40m✓\e[0m $(CHANGELOG_FILE) file exists\n")
	# Check if a ChangeLog entry exists
	test $(shell grep -c '^$(GIT_TAG)' $(CHANGELOG_FILE)) -eq 1 || (echo "Error: Please add a change log entry for release $(GIT_TAG) before releasing"; exit 1) && (printf "\e[1;38:5:40m✓\e[0m ChangeLog entry exists for release $(GIT_TAG)\n")
	# Check if the tag exists in the local repo
	test $(shell git tag -l | grep -x -c -F "$(GIT_TAG)") -eq 1 || ( echo "The tag $(GIT_TAG) does not exit in this repository. Tag your release first. Run: make create-git-tag"; exit 1 ) && (printf "\e[1;38:5:40m✓\e[0m Git Tag exists for release $(GIT_TAG)\n")
	# Check if the tag exists in the remote repo
	# git ls-remote will open a connection to the remote repository!
	if [ $(NO_GITHUB_REMOTE_CHECK) -eq 0 ]; then \
			if [ $$(git ls-remote --tags $(GITHUB_REMOTE_NAME) | grep -c "refs/tags/$(GIT_TAG)$$") -eq 1 ]; then \
				printf "\e[1;38:5:40m✓\e[0m Github: Tag $(GIT_TAG) has been pushed to $(GITHUB_REMOTE_NAME)\n"; \
			else \
				printf "\e[1;38:5:196m✕\e[0m Github: Tag $(GIT_TAG) has not been pushed to $(GITHUB_REMOTE_NAME). Push your tags first by running: git push --tags\n"; \
				exit 1; \
			fi \
	fi
	if [ $(NO_GITEA_REMOTE_CHECK) -eq 0 ]; then \
			if [ $$(git ls-remote --tags $(GITEA_REMOTE_NAME) | grep -c "refs/tags/$(GIT_TAG)$$") -eq 1 ]; then \
				printf "\e[1;38:5:40m✓\e[0m Gitea: Tag $(GIT_TAG) has been pushed to $(GITEA_REMOTE_NAME)\n"; \
			else \
				printf "\e[1;38:5:196m✕\e[0m Gitea: Tag $(GIT_TAG) has not been pushed to $(GITEA_REMOTE_NAME). Push your tags first by running: git push $(GITEA_REMOTE_NAME) --tags \n"; \
				exit 1; \
			fi \
	fi

release-github: $(RELEASE_GITHUB_DEPS) $(RELEASE_DIST_DEP) ChangeLog.$(GIT_TAG).md release-check ## Release to Github
	($(GITHUB_BIN) release create $(GITHUB_BIN_FLAGS) $(GIT_TAG) --notes-file ChangeLog.$(GIT_TAG).md $(dist_file) && printf "\e[1;38:5:40m✓\e[0m Github: Release $(GIT_TAG) created\n" || printf "\e[1;38:5:190m✓\e[0m Github: Release $(GIT_TAG) exists\n")
	$(foreach dist_file,$(RELEASE_DIST_FILES),$(GITHUB_BIN) release upload $(GITHUB_BIN_FLAGS) $(GITHUB_BIN_UPLOAD_CLOBBER_FLAG) $(GIT_TAG) $(dist_file) && printf "\e[1;38:5:40m✓\e[0m Github: Uploaded file $(dist_file) to release $(GIT_TAG)\n";)

release-gitea: $(RELEASE_GITEA_DEPS) $(RELEASE_DIST_DEP) ChangeLog.$(GIT_TAG).md release-check ## Release to Gitea
	# tea version 0.11.1 or higher required for the --note-file option
	# 'tea release create' may fail with exit code 1 if release already exists, but that's OK.
	($(GITEA_BIN) release create $(GITEA_BIN_FLAGS) --note-file ChangeLog.$(GIT_TAG).md --tag $(GIT_TAG) --title $(GIT_TAG) && printf "\e[1;38:5:40m✓\e[0m Gitea: Release $(GIT_TAG) created\n" || printf "\e[1;38:5:190m✓\e[0m Gitea: Release $(GIT_TAG) exists\n")
	# Gitea will duplicate files, so remove existing file if you're re-releasing
	# But, if your release process is multi-stage, do not do this
	if [ $(RELEASE_CLOBBER) -eq 1 ]; then \
		$(foreach dist_file,$(RELEASE_DIST_FILES),$$($(GITEA_BIN) release assets delete $(GITEA_BIN_FLAGS) --confirm $(GIT_TAG) $(notdir $(dist_file)) || exit 0)); \
	fi
	$(foreach dist_file,$(RELEASE_DIST_FILES),$(GITEA_BIN) release assets create $(GITEA_BIN_FLAGS) $(GIT_TAG) $(dist_file) && printf "\e[1;38:5:40m✓\e[0m Gitea: Uploaded file $(dist_file) to release $(GIT_TAG)\n";)

release-s3: $(RELEASE_S3_DEPS) $(RELEASE_DIST_DEP) ## Release to AWS S3
	$(foreach dist_file,$(RELEASE_DIST_FILES),aws s3 cp --quiet "$(dist_file)" s3://$(S3_BUCKET) $(S3_BIN_FLAGS) && printf "\e[1;38:5:40m✓\e[0m S3: Uploaded file $(dist_file) to https://$(S3_BUCKET).s3.amazonaws.com/$(notdir $(dist_file))\n";)

release: $(RELEASE_DEPS) ## Publishes releases

