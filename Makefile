EMACS ?= emacs
RM_RF ?= rm -rf

.DEFAULT_GOAL := help

.PHONY: clean compile help realclean setup test

FIRST_PARTY_ELC = init.elc \
	lisp/tahoma-package.elc \
	lisp/tahoma-ui.elc \
	lisp/tahoma-project.elc \
	lisp/tahoma-tools.elc \
	lisp/tahoma-elisp.elc \
	lisp/tahoma-c.elc \
	lisp/tahoma-sql.elc \
	lisp/tahoma-rust.elc \
	lisp/tahoma-js.elc \
	scripts/compile.elc \
	scripts/setup.elc \
	tests/init-test.elc
RUNTIME_FILES = custom.el history places recentf savehist package-quickstart.el network-security.data
RUNTIME_DIRS = .cache auto-save-list backups eln-cache transient tramp url var
PACKAGE_DIRS = elpa quelpa

help: ## Show available Make targets.
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make <target>\n\nTargets:\n"} /^[a-zA-Z0-9_-]+:.*##/ {gsub(/^ /, "", $$2); printf "  %-10s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

clean: ## Remove runtime files and first-party bytecode, preserving packages.
	$(RM) $(FIRST_PARTY_ELC) $(RUNTIME_FILES) *~ \#*\# .\#*
	$(RM_RF) $(RUNTIME_DIRS)

compile: ## Byte-compile first-party ELisp files.
	$(EMACS) -Q --batch -l scripts/compile.el

realclean: clean ## Remove runtime files, bytecode, and installed packages.
	$(RM_RF) $(PACKAGE_DIRS)

setup: ## Install packages, compile vterm, and freshen bytecode.
	$(EMACS) -Q --batch -l scripts/setup.el

test: ## Run the ERT test suite.
	$(EMACS) -Q --batch -l tests/init-test.el
