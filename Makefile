EMACS ?= emacs
HOST_INSTALL ?= 0
USER_INSTALL ?= 0
USER_MCP_INSTALL ?= 0
USER_MCP_CLIENTS ?= claude codex cursor
USER_EDITOR_COMMAND ?=
USER_SHELL_FILE ?=
USER_TMUX_FILE ?=
USER_EMACS_MCP_SCRIPT ?=
USER_CLAUDE_CONFIG_FILE ?=
USER_CODEX_CONFIG_FILE ?=
USER_CURSOR_MCP_FILE ?=
RM_RF ?= rm -rf

.DEFAULT_GOAL := help

.PHONY: clean compile help host realclean setup test user

FIRST_PARTY_ELC = init.elc \
	lisp/config-package.elc \
	lisp/config-ui.elc \
	lisp/config-editing.elc \
	lisp/config-undo.elc \
	lisp/config-platform.elc \
	lisp/config-terminal.elc \
	lisp/config-project.elc \
	lisp/config-project-commands.elc \
	lisp/config-navigation.elc \
	lisp/config-notes.elc \
	lisp/config-workspace.elc \
	lisp/config-files.elc \
	lisp/config-buffers.elc \
	lisp/config-completion.elc \
	lisp/config-snippets.elc \
	lisp/config-diagnostics.elc \
	lisp/config-debug.elc \
	lisp/config-environment.elc \
	lisp/config-tools.elc \
	lisp/config-vc.elc \
	lisp/config-mcp.elc \
	lisp/config-agent.elc \
	lisp/config-elisp.elc \
	lisp/config-c.elc \
	lisp/config-verilog.elc \
	lisp/config-sql.elc \
	lisp/config-rust.elc \
	lisp/config-js.elc \
	lisp/config-markup.elc \
	lisp/config-python.elc \
	lisp/config-treesit.elc \
	scripts/compile.elc \
	scripts/host.elc \
	scripts/setup.elc \
	scripts/user.elc \
	tests/init-test.elc
RUNTIME_FILES = custom.el emacs-mcp-stdio.sh history places recentf savehist package-quickstart.el network-security.data
RUNTIME_DIRS = .cache auto-save-list backups eln-cache transient tramp url var
PACKAGE_DIRS = elpa quelpa

help: ## Show available Make targets.
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make <target>\n\nTargets:\n"} /^[a-zA-Z0-9_-]+:.*##/ {gsub(/^ /, "", $$2); printf "  %-10s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

host: ## Show host setup commands; set HOST_INSTALL=1 to execute them.
	HOST_INSTALL=$(HOST_INSTALL) $(EMACS) -Q --batch -l scripts/host.el

user: ## Show user setup; set USER_INSTALL=1 and/or USER_MCP_INSTALL=1 to apply.
	USER_INSTALL=$(USER_INSTALL) USER_MCP_INSTALL=$(USER_MCP_INSTALL) USER_MCP_CLIENTS="$(USER_MCP_CLIENTS)" USER_EDITOR_COMMAND='$(USER_EDITOR_COMMAND)' USER_SHELL_FILE="$(USER_SHELL_FILE)" USER_TMUX_FILE="$(USER_TMUX_FILE)" USER_EMACS_MCP_SCRIPT="$(USER_EMACS_MCP_SCRIPT)" USER_CLAUDE_CONFIG_FILE="$(USER_CLAUDE_CONFIG_FILE)" USER_CODEX_CONFIG_FILE="$(USER_CODEX_CONFIG_FILE)" USER_CURSOR_MCP_FILE="$(USER_CURSOR_MCP_FILE)" $(EMACS) -Q --batch -l scripts/user.el

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
