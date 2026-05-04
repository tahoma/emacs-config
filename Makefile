EMACS ?= emacs
HOST_INSTALL ?= 0
USER_INSTALL ?= 0
USER_SHELL_FILE ?=
USER_TMUX_FILE ?=
RM_RF ?= rm -rf

.DEFAULT_GOAL := help

.PHONY: clean compile help host realclean setup test user

FIRST_PARTY_ELC = init.elc \
	lisp/config-package.elc \
	lisp/config-ui.elc \
	lisp/config-editing.elc \
	lisp/config-platform.elc \
	lisp/config-terminal.elc \
	lisp/config-project.elc \
	lisp/config-workspace.elc \
	lisp/config-files.elc \
	lisp/config-completion.elc \
	lisp/config-snippets.elc \
	lisp/config-diagnostics.elc \
	lisp/config-debug.elc \
	lisp/config-environment.elc \
	lisp/config-tools.elc \
	lisp/config-agent.elc \
	lisp/config-elisp.elc \
	lisp/config-c.elc \
	lisp/config-sql.elc \
	lisp/config-rust.elc \
	lisp/config-js.elc \
	lisp/config-markup.elc \
	lisp/config-python.elc \
	scripts/compile.elc \
	scripts/setup.elc \
	tests/init-test.elc
RUNTIME_FILES = custom.el history places recentf savehist package-quickstart.el network-security.data
RUNTIME_DIRS = .cache auto-save-list backups eln-cache transient tramp url var
PACKAGE_DIRS = elpa quelpa

help: ## Show available Make targets.
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make <target>\n\nTargets:\n"} /^[a-zA-Z0-9_-]+:.*##/ {gsub(/^ /, "", $$2); printf "  %-10s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

host: ## Show host setup commands; set HOST_INSTALL=1 to execute them.
	HOST_INSTALL=$(HOST_INSTALL) bash scripts/host.sh

user: ## Show user shell setup; set USER_INSTALL=1 to update dotfiles.
	USER_INSTALL=$(USER_INSTALL) USER_SHELL_FILE="$(USER_SHELL_FILE)" USER_TMUX_FILE="$(USER_TMUX_FILE)" bash scripts/user.sh

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
