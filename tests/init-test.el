;;; init-test.el --- Tests for the Emacs config -*- lexical-binding: t; -*-

;;; Commentary:
;; Run from the repository root with:
;;
;;   emacs -Q --batch -l tests/init-test.el

;;; Code:

(require 'ert)
(require 'cl-lib)

(defvar recentf-save-file)
(defvar savehist-file)
(defvar my/c-basic-offset)
(defvar my/c-fill-column)
(defvar my/verilog-basic-offset)
(defvar my/verilog-fill-column)
(defvar my/verilog-format-on-save)
(defvar my/verilog-language-server-commands)
(defvar my/verilog-project-root-files)
(defvar verilog-case-indent)
(defvar verilog-indent-level)
(defvar verilog-indent-level-behavioral)
(defvar verilog-indent-level-declaration)
(defvar verilog-indent-level-module)
(defvar my/sql-default-product)
(defvar my/sql-fill-column)
(defvar my/sql-history-file)
(defvar my/rust-basic-offset)
(defvar my/rust-fill-column)
(defvar my/rust-format-on-save)
(defvar my/js-basic-offset)
(defvar my/js-fill-column)
(defvar my/js-format-on-save)
(defvar my/markup-basic-offset)
(defvar my/markup-fill-column)
(defvar my/markup-json-language-server-command)
(defvar my/markup-mermaid-output-extension)
(defvar my/markup-yaml-language-server-command)
(defvar my/python-basic-offset)
(defvar my/python-fill-column)
(defvar my/python-format-on-save)
(defvar my/python-language-server-commands)
(defvar my/treesit-default-language-sources)
(defvar treesit-language-source-alist)
(defvar corfu-auto)
(defvar corfu-count)
(defvar corfu-cycle)
(defvar corfu-on-exact-match)
(defvar corfu-preview-current)
(defvar my/completion-corfu-count)
(defvar my/completion-preview-delay)
(defvar my/environment-auto-enable-direnv)
(defvar my/environment-direnv-executable)
(defvar my/editing-auto-save-directory)
(defvar my/editing-backup-directory)
(defvar my/editing-fill-column)
(defvar my/editing-var-directory)
(defvar my/undo-vundo-prefix)
(defvar my/undo-vundo-window-max-height)
(defvar my/workspace-enable-tab-bar)
(defvar my/workspace-tab-bar-show)
(defvar my/workspace-windmove-wrap-around)
(defvar my/files-dired-omit-files)
(defvar dired-auto-revert-buffer)
(defvar dired-dwim-target)
(defvar dired-kill-when-opening-new-dired-buffer)
(defvar dired-omit-files)
(defvar dired-recursive-copies)
(defvar dired-recursive-deletes)
(defvar ibuffer-expert)
(defvar ibuffer-filter-groups)
(defvar ibuffer-show-empty-filter-groups)
(defvar ibuffer-use-other-window)
(defvar my/buffers-ibuffer-filter-groups)
(defvar ediff-split-window-function)
(defvar ediff-window-setup-function)
(defvar my/vc-diff-hl-enabled)
(defvar my/vc-smerge-prefix)
(defvar my/platform-open-bindings-prefix)
(defvar my/platform-preferred-windows-shells)
(defvar my/terminal-osc52-copy-enabled)
(defvar my/terminal-osc52-max-bytes)
(defvar my/terminal-editor-command)
(defvar my/terminal-start-server)
(defvar my/terminal-with-editor-enabled)
(defvar my/terminal-mouse-enabled)
(defvar my/terminal-git-commit-fill-column)
(defvar my/terminal-git-commit-summary-max-length)
(defvar my/terminal-tramp-auto-save-directory)
(defvar my/terminal-tramp-verbose)
(defvar my/terminal-xterm-key-decodes)
(defvar my/project-command-defaults)
(defvar my/project-command-history)
(defvar my/navigation-bookmark-file)
(defvar my/navigation-prefix)
(defvar my/navigation-register-preview-delay)
(defvar my/notes-debug-file)
(defvar my/notes-decisions-file)
(defvar my/notes-directory)
(defvar my/notes-inbox-file)
(defvar my/notes-prefix)
(defvar bookmark-default-file)
(defvar bookmark-save-flag)
(defvar org-agenda-files)
(defvar org-capture-templates)
(defvar org-default-notes-file)
(defvar org-directory)
(defvar org-log-done)
(defvar org-return-follows-link)
(defvar org-startup-folded)
(defvar register-preview-delay)
(defvar vundo-ascii-symbols)
(defvar vundo-compact-display)
(defvar vundo-glyph-alist)
(defvar vundo-roll-back-on-quit)
(defvar vundo-unicode-symbols)
(defvar vundo-window-max-height)
(defvar create-lockfiles)
(defvar git-commit-mode-map)
(defvar git-commit-setup-hook)
(defvar git-commit-summary-max-length)
(defvar remote-file-name-inhibit-locks)
(defvar shell-command-with-editor-mode)
(defvar tramp-auto-save-directory)
(defvar tramp-default-method)
(defvar tramp-verbose)
(defvar my/snippets-directory)
(defvar my/agent-codex-command)
(defvar my/agent-claude-command)
(defvar my/agent-cursor-command)
(defvar my/agent-providers)
(defvar my/agent-project-context-files)
(defvar my/agent-project-context-status-limit)
(defvar my/agent-save-project-buffers-before-launch)
(defvar my/mcp-elisp-dev-allowed-dirs)
(defvar my/mcp-elisp-dev-init-function)
(defvar my/mcp-elisp-dev-stop-function)
(defvar my/mcp-install-directory)
(defvar my/mcp-server-id)
(defvar my/mcp-server-name)
(defvar my/debug-dape-buffer-arrangement)
(defvar my/debug-dape-inlay-hints)
(defvar my/tools-shell-environment-variables)
(defvar exec-path-from-shell-variables)
(defvar elisp-dev-mcp-additional-allowed-dirs)
(declare-function my/project-root "config-project")
(declare-function my/project-command-candidates "config-project-commands")
(declare-function my/project-command-detected-candidates "config-project-commands")
(declare-function my/project-command-read "config-project-commands")
(declare-function my/project-command-repeat "config-project-commands")
(declare-function my/project-command-run "config-project-commands")
(declare-function my/navigation-ensure-runtime-directory "config-navigation")
(declare-function my/notes-capture-debug "config-notes")
(declare-function my/notes-capture-decision "config-notes")
(declare-function my/notes-capture-note "config-notes")
(declare-function my/notes-capture-task "config-notes")
(declare-function my/notes-capture-template "config-notes")
(declare-function my/notes-capture-templates "config-notes")
(declare-function my/notes-ensure-files "config-notes")
(declare-function my/notes-file-seeds "config-notes")
(declare-function my/notes-open-directory "config-notes")
(declare-function my/notes-open-inbox "config-notes")
(declare-function my/notes-project-root "config-notes")
(declare-function my/tools-import-shell-environment-p "config-tools")
(declare-function my/c-default-compile-command "config-c")
(declare-function my/c-format-buffer "config-c")
(declare-function my/verilog-command-line "config-verilog")
(declare-function my/verilog-default-build-command "config-verilog")
(declare-function my/verilog-format-before-save "config-verilog")
(declare-function my/verilog-format-command "config-verilog")
(declare-function my/verilog-format-region-or-buffer "config-verilog")
(declare-function my/verilog-language-server-command "config-verilog")
(declare-function my/verilog-lint "config-verilog")
(declare-function my/verilog-lint-command "config-verilog")
(declare-function my/verilog-project-root "config-verilog")
(declare-function my/sql-format-region-or-buffer "config-sql")
(declare-function my/sql-send-region-or-buffer "config-sql")
(declare-function my/sql-scratch "config-sql")
(declare-function my/rust-cargo-command-line "config-rust")
(declare-function my/rust-cargo-root "config-rust")
(declare-function my/rust-format-buffer "config-rust")
(declare-function my/js-detect-package-manager "config-js")
(declare-function my/js-format-region-or-buffer "config-js")
(declare-function my/js-package-script-command "config-js")
(declare-function my/js-project-root "config-js")
(declare-function my/markup-detect-markdown-command "config-markup")
(declare-function my/markup-ensure-markdown-command "config-markup")
(declare-function my/markup-json-jq-region-or-buffer "config-markup")
(declare-function my/markup-markdown-command-available-p "config-markup")
(declare-function my/markup-markdown-preview "config-markup")
(declare-function my/markup-mermaid-compile "config-markup")
(declare-function my/markup-mermaid-compile-command "config-markup")
(declare-function my/markup-yaml-format-region-or-buffer "config-markup")
(declare-function my/python-check "config-python")
(declare-function my/python-command-line "config-python")
(declare-function my/python-compile-file "config-python")
(declare-function my/python-executable "config-python")
(declare-function my/python-format-region-or-buffer "config-python")
(declare-function my/python-language-server-command "config-python")
(declare-function my/python-project-root "config-python")
(declare-function my/python-run-file "config-python")
(declare-function my/python-test "config-python")
(declare-function my/python-test-file "config-python")
(declare-function my/python-tool-command "config-python")
(declare-function my/python-venv-root "config-python")
(declare-function my/treesit-available-p "config-treesit")
(declare-function my/treesit-configured-languages "config-treesit")
(declare-function my/treesit-install-language "config-treesit")
(declare-function my/treesit-install-missing-grammars "config-treesit")
(declare-function my/treesit-language-ready-p "config-treesit")
(declare-function my/treesit-register-default-sources "config-treesit")
(declare-function my/treesit-status "config-treesit")
(declare-function my/completion-consult-find "config-completion")
(declare-function my/completion-consult-line-multi "config-completion")
(declare-function my/completion-consult-ripgrep "config-completion")
(declare-function my/completion-project-root "config-completion")
(declare-function my/diagnostics-buffer "config-diagnostics")
(declare-function my/diagnostics-code-actions "config-diagnostics")
(declare-function my/diagnostics-list "config-diagnostics")
(declare-function my/diagnostics-rename "config-diagnostics")
(declare-function my/environment-direnv-available-p "config-environment")
(declare-function my/environment-enable-envrc "config-environment")
(declare-function my/editing-clean-code-whitespace-on-save "config-editing")
(declare-function my/editing-code-buffer-visuals "config-editing")
(declare-function my/editing-ensure-runtime-directories "config-editing")
(declare-function my/undo-configure-vundo "config-undo")
(declare-function my/undo-vundo-glyph-alist "config-undo")
(declare-function my/workspace-project-name "config-workspace")
(declare-function my/workspace-tab-new-for-project "config-workspace")
(declare-function my/workspace-tab-rename-for-project "config-workspace")
(declare-function my/files-dired-project-root "config-files")
(declare-function my/files-dired-toggle-omit "config-files")
(declare-function my/files-dired-setup "config-files")
(declare-function my/buffers-ibuffer "config-buffers")
(declare-function my/buffers-ibuffer-setup "config-buffers")
(declare-function my/vc-enable-diff-hl "config-vc")
(declare-function my/platform-apply-defaults "config-platform")
(declare-function my/platform-clipboard-copy-command "config-platform")
(declare-function my/platform-clipboard-paste-command "config-platform")
(declare-function my/platform-copy-file-path "config-platform")
(declare-function my/platform-default-shell "config-platform")
(declare-function my/platform-linux-p "config-platform")
(declare-function my/platform-macos-p "config-platform")
(declare-function my/platform-open-command "config-platform")
(declare-function my/platform-open-file-externally "config-platform")
(declare-function my/platform-reveal-command "config-platform")
(declare-function my/platform-reveal-in-file-manager "config-platform")
(declare-function my/platform-windows-p "config-platform")
(declare-function my/platform-wsl-p "config-platform")
(declare-function my/terminal-frame-p "config-terminal")
(declare-function my/terminal-apply-osc52-clipboard "config-terminal")
(declare-function my/terminal-apply-editor-environment "config-terminal")
(declare-function my/terminal-editor-environment "config-terminal")
(declare-function my/terminal-enable-with-editor "config-terminal")
(declare-function my/terminal-apply-mouse "config-terminal")
(declare-function my/terminal-apply-key-decodes "config-terminal")
(declare-function my/terminal-apply-tramp-defaults "config-terminal")
(declare-function my/terminal-git-commit-setup "config-terminal")
(declare-function my/terminal-maybe-start-server "config-terminal")
(declare-function my/terminal-osc52-copy "config-terminal")
(declare-function my/terminal-osc52-sequence "config-terminal")
(declare-function my/terminal-osc52-transport "config-terminal")
(declare-function my/terminal-remote-buffer-p "config-terminal")
(declare-function my/terminal-remote-editing-setup "config-terminal")
(declare-function my/agent-codex "config-agent")
(declare-function my/agent-codex-available-p "config-agent")
(declare-function my/agent-claude "config-agent")
(declare-function my/agent-cursor "config-agent")
(declare-function my/agent-codex-with-file "config-agent")
(declare-function my/agent-codex-with-region "config-agent")
(declare-function my/agent-command-line "config-agent")
(declare-function my/agent-control "config-agent")
(declare-function my/agent-control-transient "config-agent")
(declare-function my/agent-copy-file-context "config-agent")
(declare-function my/agent-copy-project-context "config-agent")
(declare-function my/agent-copy-region-context "config-agent")
(declare-function my/agent-launch "config-agent")
(declare-function my/agent-launch-with-project-context "config-agent")
(declare-function my/agent-open-project-context "config-agent")
(declare-function my/agent-provider-available-p "config-agent")
(declare-function my/agent-provider-command "config-agent")
(declare-function my/agent-provider-name "config-agent")
(declare-function my/agent-provider-spec "config-agent")
(declare-function my/agent-project-context-string "config-agent")
(declare-function my/agent-project-vterm "config-agent")
(declare-function my/agent-run-in-project-vterm "config-agent")
(declare-function my/agent-save-project-buffers "config-agent")
(declare-function my/mcp-apply-elisp-dev-allowed-dirs "config-mcp")
(declare-function my/mcp-command-line "config-mcp")
(declare-function my/mcp-copy-elisp-dev-stdio-command "config-mcp")
(declare-function my/mcp-disable-elisp-dev "config-mcp")
(declare-function my/mcp-elisp-dev-stdio-command "config-mcp")
(declare-function my/mcp-enable-elisp-dev "config-mcp")
(declare-function my/mcp-install-stdio-script "config-mcp")
(declare-function my/mcp-package-stdio-script-path "config-mcp")
(declare-function my/mcp-start "config-mcp")
(declare-function my/mcp-stdio-script-path "config-mcp")
(declare-function my/mcp-stop "config-mcp")
(declare-function my/debug-configure-dape "config-debug")

;; Resolve paths relative to the test file so the suite works from `make test',
;; direct batch invocation, or an arbitrary current working directory.
(defconst emacs-config-test-root
  (file-name-directory
   (directory-file-name
    (file-name-directory
     (or load-file-name buffer-file-name)))))

;; The config enables history-writing modes. Point them at temporary files so
;; tests never mutate a user's normal interactive Emacs state.
(setq recentf-save-file
      (expand-file-name "emacs-config-recentf-test" temporary-file-directory)
      savehist-file
      (expand-file-name "emacs-config-savehist-test" temporary-file-directory))

;; Load the real init file. These are configuration tests, so they intentionally
;; exercise the same startup path a user gets after cloning the repo.
(load (expand-file-name "init.el" emacs-config-test-root) nil t)

;;; Startup and package-management contract
(ert-deftest emacs-config/provides-init-feature ()
  (should (featurep 'init)))

(ert-deftest emacs-config/provides-first-party-module-features ()
  (dolist (feature '(config-package
                     config-ui
                     config-editing
                     config-undo
                     config-platform
                     config-terminal
                     config-project
                     config-project-commands
                     config-navigation
                     config-notes
                     config-workspace
                     config-files
                     config-buffers
                     config-completion
                     config-snippets
                     config-diagnostics
                     config-debug
                     config-environment
                     config-tools
                     config-vc
                     config-mcp
                     config-agent
                     config-elisp
                     config-c
                     config-verilog
                     config-sql
                     config-rust
                     config-js
                     config-markup
                     config-python
                     config-treesit))
    (should (featurep feature))))

(ert-deftest emacs-config/init-adds-first-party-lisp-to-load-path ()
  (should (member (expand-file-name "lisp" emacs-config-test-root)
                  load-path)))

(ert-deftest emacs-config/compile-helper-knows-first-party-files ()
  (let ((compile-helper (expand-file-name "scripts/compile.el"
                                          emacs-config-test-root)))
    (should (file-exists-p compile-helper))
    (with-temp-buffer
      (insert-file-contents compile-helper)
      (dolist (relative-file '("lisp/config-package.el"
                               "lisp/config-ui.el"
                               "lisp/config-editing.el"
                               "lisp/config-undo.el"
                               "lisp/config-platform.el"
                               "lisp/config-terminal.el"
                               "lisp/config-project.el"
                               "lisp/config-project-commands.el"
                               "lisp/config-navigation.el"
                               "lisp/config-notes.el"
                               "lisp/config-workspace.el"
                               "lisp/config-files.el"
                               "lisp/config-buffers.el"
                               "lisp/config-completion.el"
                               "lisp/config-snippets.el"
                               "lisp/config-diagnostics.el"
                               "lisp/config-debug.el"
                               "lisp/config-environment.el"
                               "lisp/config-tools.el"
                               "lisp/config-vc.el"
                               "lisp/config-mcp.el"
                               "lisp/config-agent.el"
                               "lisp/config-elisp.el"
                               "lisp/config-c.el"
                               "lisp/config-verilog.el"
                               "lisp/config-sql.el"
                               "lisp/config-rust.el"
                               "lisp/config-js.el"
                               "lisp/config-markup.el"
                               "lisp/config-python.el"
                               "lisp/config-treesit.el"
                               "init.el"
                               "scripts/setup.el"
                               "scripts/compile.el"
                               "scripts/user.el"
                               "tests/init-test.el"))
        (should (search-forward (prin1-to-string relative-file) nil t))))))

(ert-deftest emacs-config/compiled-artifacts-are-ignored ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name ".gitignore" emacs-config-test-root))
    (should (search-forward "*.elc" nil t))
    (goto-char (point-min))
    (should (search-forward "emacs-mcp-stdio.sh" nil t))))

(ert-deftest emacs-config/agent-context-files-share-canonical-instructions ()
  (let ((agents-file (expand-file-name "AGENTS.md" emacs-config-test-root))
        (claude-file (expand-file-name "CLAUDE.md" emacs-config-test-root))
        (cursor-rule (expand-file-name ".cursor/rules/emacs-config.mdc"
                                       emacs-config-test-root)))
    (dolist (file (list agents-file claude-file cursor-rule))
      (should (file-exists-p file)))
    (with-temp-buffer
      (insert-file-contents agents-file)
      (let ((instructions (buffer-string)))
        (should (string-match-p "lisp/config-\\*\\.el" instructions))
        (should (string-match-p "scripts/setup\\.el" instructions))
        (should (string-match-p "tests/init-test\\.el" instructions))
        (should (string-match-p "make compile" instructions))
        (should (string-match-p "make test" instructions))
        (should (string-match-p "C-c a \\?" instructions))
        (should (string-match-p "Do not edit files under `elpa/" instructions))))
    (with-temp-buffer
      (insert-file-contents claude-file)
      (should (string-prefix-p "@AGENTS.md" (buffer-string))))
    (with-temp-buffer
      (insert-file-contents cursor-rule)
      (let ((rule (buffer-string)))
        (should (string-match-p "alwaysApply: true" rule))
        (should (string-match-p "@AGENTS\\.md" rule))))))

(ert-deftest emacs-config/local-agent-notes-are-ignored ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name ".gitignore" emacs-config-test-root))
    (let ((gitignore (buffer-string)))
      (should (string-match-p "CLAUDE\\.local\\.md" gitignore))
      (should (string-match-p "\\.claude/settings\\.local\\.json" gitignore))
      (should (string-match-p "\\.cursor/rules/\\*\\.local\\.mdc" gitignore)))))

(ert-deftest emacs-config/readme-usage-notes-cover-main-workflows ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name "README.md" emacs-config-test-root))
    (let ((readme (buffer-string)))
      (should (string-match-p "^## Usage Notes" readme))
      (dolist (text '("C-c p"
                      "C-c x"
                      "C-c a \\?"
                      "C-c a m s"
                      "C-c T"
                      "C-c f p"
                      "C-c g"
                      "C-c n"
                      "C-c o"
                      "C-c E"
                      "C-c l"
                      "Verilog/SystemVerilog"
                      "make host"
                      "USER_MCP_INSTALL=1"))
        (should (string-match-p text readme))))))

(ert-deftest emacs-config/make-clean-targets-are-split-by-package-state ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name "Makefile" emacs-config-test-root))
    (let ((makefile (buffer-string)))
      (should (string-match-p "^clean:" makefile))
      (should (string-match-p "^realclean: clean" makefile))
      (should (string-match-p "lisp/config-package\\.elc" makefile))
      (should (string-match-p "lisp/config-editing\\.elc" makefile))
      (should (string-match-p "lisp/config-undo\\.elc" makefile))
      (should (string-match-p "lisp/config-platform\\.elc" makefile))
      (should (string-match-p "lisp/config-terminal\\.elc" makefile))
      (should (string-match-p "lisp/config-project-commands\\.elc" makefile))
      (should (string-match-p "lisp/config-navigation\\.elc" makefile))
      (should (string-match-p "lisp/config-notes\\.elc" makefile))
      (should (string-match-p "lisp/config-workspace\\.elc" makefile))
      (should (string-match-p "lisp/config-files\\.elc" makefile))
      (should (string-match-p "lisp/config-buffers\\.elc" makefile))
      (should (string-match-p "lisp/config-completion\\.elc" makefile))
      (should (string-match-p "lisp/config-snippets\\.elc" makefile))
      (should (string-match-p "lisp/config-diagnostics\\.elc" makefile))
      (should (string-match-p "lisp/config-debug\\.elc" makefile))
      (should (string-match-p "lisp/config-environment\\.elc" makefile))
      (should (string-match-p "lisp/config-vc\\.elc" makefile))
      (should (string-match-p "lisp/config-mcp\\.elc" makefile))
      (should (string-match-p "lisp/config-agent\\.elc" makefile))
      (should (string-match-p "lisp/config-c\\.elc" makefile))
      (should (string-match-p "lisp/config-verilog\\.elc" makefile))
      (should (string-match-p "lisp/config-sql\\.elc" makefile))
      (should (string-match-p "lisp/config-rust\\.elc" makefile))
      (should (string-match-p "lisp/config-js\\.elc" makefile))
      (should (string-match-p "lisp/config-markup\\.elc" makefile))
      (should (string-match-p "lisp/config-python\\.elc" makefile))
      (should (string-match-p "lisp/config-treesit\\.elc" makefile))
      (should (string-match-p "scripts/user\\.elc" makefile))
      (should (string-match-p "^PACKAGE_DIRS = .*elpa" makefile))
      (should-not (string-match-p "^RUNTIME_DIRS = .*elpa" makefile)))))

(ert-deftest emacs-config/make-help-target-documents-common-targets ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name "Makefile" emacs-config-test-root))
    (let ((makefile (buffer-string)))
      (should (string-match-p "^\\.DEFAULT_GOAL := help" makefile))
      (should (string-match-p "^\\.PHONY: .*help" makefile))
      (dolist (target '("help" "host" "user" "setup" "test" "compile" "clean" "realclean"))
        (should (string-match-p
                 (format "^%s:.*## .+" (regexp-quote target))
                 makefile))))))

(ert-deftest emacs-config/make-host-target-documents-host-setup ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name "Makefile" emacs-config-test-root))
    (let ((makefile (buffer-string)))
      (should (string-match-p "^HOST_INSTALL \\?= 0" makefile))
      (should (string-match-p "^host:.*## .*HOST_INSTALL=1" makefile))
      (should (string-match-p "bash scripts/host\\.sh" makefile)))))

(ert-deftest emacs-config/make-user-target-documents-user-setup ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name "Makefile" emacs-config-test-root))
    (let ((makefile (buffer-string)))
      (should (string-match-p "^USER_INSTALL \\?= 0" makefile))
      (should (string-match-p "^USER_MCP_INSTALL \\?= 0" makefile))
      (should (string-match-p "^USER_MCP_CLIENTS \\?= claude codex cursor" makefile))
      (should (string-match-p "^USER_SHELL_FILE \\?=" makefile))
      (should (string-match-p "^USER_TMUX_FILE \\?=" makefile))
      (should (string-match-p "^USER_EMACS_MCP_SCRIPT \\?=" makefile))
      (should (string-match-p "^USER_CLAUDE_CONFIG_FILE \\?=" makefile))
      (should (string-match-p "^USER_CODEX_CONFIG_FILE \\?=" makefile))
      (should (string-match-p "^USER_CURSOR_MCP_FILE \\?=" makefile))
      (should (string-match-p "^user:.*## .*USER_INSTALL=1" makefile))
      (should (string-match-p "^user:.*## .*USER_MCP_INSTALL=1" makefile))
      (should (string-match-p " -Q --batch -l scripts/user\\.el" makefile))
      (should-not (string-match-p "scripts/user\\.sh" makefile)))))

(ert-deftest emacs-config/host-helper-is-safe-and-platform-aware ()
  (let ((host-helper (expand-file-name "scripts/host.sh"
                                       emacs-config-test-root)))
    (should (file-exists-p host-helper))
    (with-temp-buffer
      (insert-file-contents host-helper)
      (let ((script (buffer-string)))
        (should (string-match-p "HOST_INSTALL" script))
        (should (string-match-p "Dry run" script))
        (should (string-match-p "Darwin" script))
        (should (string-match-p "Ubuntu/Debian" script))
        (should (string-match-p "Windows host setup" script))
        (should (string-match-p "brew install" script))
        (should (string-match-p "apt-get install" script))
        (should (string-match-p "winget install" script))
        (should (string-match-p "wl-clipboard" script))
        (should (string-match-p "xdg-utils" script))
        (should (string-match-p "explorer\\.exe" script))
        (should (string-match-p "verible-verilog-format" script))
        (should (string-match-p "verilator" script))
        (should (string-match-p "iverilog" script))
        (should (string-match-p "codex" script))
        (should (string-match-p "claude" script))
        (should (string-match-p "cursor-agent" script))
        (should (string-match-p "make user" script))
        (should (string-match-p "npm install -g" script))
        (should (string-match-p "pipx ensurepath" script))))))

(ert-deftest emacs-config/user-helper-is-safe-and-idempotent ()
  (let ((user-helper (expand-file-name "scripts/user.el"
                                       emacs-config-test-root)))
    (should (file-exists-p user-helper))
    (with-temp-buffer
      (insert-file-contents user-helper)
      (let ((script (buffer-string)))
        (should (string-match-p "USER_INSTALL" script))
        (should (string-match-p "USER_MCP_INSTALL" script))
        (should (string-match-p "USER_MCP_CLIENTS" script))
        (should (string-match-p "USER_EMACS_MCP_SCRIPT" script))
        (should (string-match-p "USER_CLAUDE_CONFIG_FILE" script))
        (should (string-match-p "USER_CODEX_CONFIG_FILE" script))
        (should (string-match-p "USER_CURSOR_MCP_FILE" script))
        (should (string-match-p "Dry run" script))
        (should (string-match-p "USER_INSTALL=1" script))
        (should (string-match-p "USER_MCP_INSTALL=1" script))
        (should (string-match-p "USER_SHELL_FILE" script))
        (should (string-match-p "USER_TMUX_FILE" script))
        (should (string-match-p "emacsclient -t -a" script))
        (should (string-match-p "GIT_EDITOR" script))
        (should (string-match-p "\\.local/bin" script))
        (should (string-match-p "brew shellenv" script))
        (should (string-match-p "/opt/homebrew/bin/brew" script))
        (should (string-match-p "/home/linuxbrew/\\.linuxbrew/bin/brew" script))
        (should (string-match-p "set-clipboard" script))
        (should (string-match-p "terminal-features" script))
        (should (string-match-p "\"claude\" \"mcp\" \"add\"" script))
        (should (string-match-p "\"codex\" \"mcp\" \"add\"" script))
        (should (string-match-p "\\.cursor/mcp\\.json" script))
        (should (string-match-p "json-parse-buffer" script))
        (should (string-match-p "json-serialize" script))
        (should (string-match-p "elisp-dev-mcp-enable" script))
        (should (string-match-p "user--install-block" script))))))

(ert-deftest emacs-config/package-archives-include-melpa ()
  (should (equal (alist-get "gnu" package-archives nil nil #'string=)
                 "https://elpa.gnu.org/packages/"))
  (should (equal (alist-get "nongnu" package-archives nil nil #'string=)
                 "https://elpa.nongnu.org/nongnu/"))
  (should (equal (alist-get "melpa" package-archives nil nil #'string=)
                 "https://melpa.org/packages/")))

(ert-deftest emacs-config/package-archive-priorities-prefer-official-archives ()
  (should (> (alist-get "gnu" package-archive-priorities nil nil #'string=)
             (alist-get "melpa" package-archive-priorities nil nil #'string=)))
  (should (> (alist-get "nongnu" package-archive-priorities nil nil #'string=)
             (alist-get "melpa" package-archive-priorities nil nil #'string=))))

(ert-deftest emacs-config/use-package-is-ready ()
  (should (featurep 'use-package))
  (should use-package-always-ensure))

;;; Baseline interactive behavior
(ert-deftest emacs-config/basic-ui-defaults-are-enabled ()
  (should inhibit-startup-screen)
  (should (eq ring-bell-function 'ignore))
  (should (bound-and-true-p global-display-line-numbers-mode))
  (should (bound-and-true-p savehist-mode))
  (should (bound-and-true-p recentf-mode))
  (should (bound-and-true-p electric-pair-mode)))

(ert-deftest emacs-config/editing-state-defaults-are-enabled ()
  (should (bound-and-true-p save-place-mode))
  (should (bound-and-true-p global-auto-revert-mode))
  (should (bound-and-true-p global-so-long-mode))
  (should (bound-and-true-p delete-selection-mode))
  (should (bound-and-true-p column-number-mode))
  (should (bound-and-true-p show-paren-mode))
  (should require-final-newline)
  (should-not sentence-end-double-space)
  (should kill-do-not-save-duplicates)
  (should-not auto-revert-verbose)
  (should (= (default-value 'fill-column) my/editing-fill-column)))

(ert-deftest emacs-config/editing-runtime-files-live-under-var ()
  (should (file-directory-p my/editing-var-directory))
  (should (file-directory-p my/editing-backup-directory))
  (should (file-directory-p my/editing-auto-save-directory))
  (should (string-prefix-p (expand-file-name "var/" emacs-config-test-root)
                           my/editing-var-directory))
  (should (equal (cdr (assoc "." backup-directory-alist))
                 my/editing-backup-directory))
  (should (string-prefix-p my/editing-auto-save-directory
                           auto-save-list-file-prefix)))

(ert-deftest emacs-config/editing-code-buffers-clean-whitespace ()
  (with-temp-buffer
    (emacs-lisp-mode)
    (should (memq #'delete-trailing-whitespace before-save-hook))
    (should show-trailing-whitespace)
    (when (fboundp 'display-fill-column-indicator-mode)
      (should (bound-and-true-p display-fill-column-indicator-mode)))))

(ert-deftest emacs-config/visual-undo-helper-package-is-installed ()
  (should (require 'vundo nil t)))

(ert-deftest emacs-config/setup-installs-visual-undo-package ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name "scripts/setup.el"
                                            emacs-config-test-root))
    (should (search-forward "vundo" nil t))))

(ert-deftest emacs-config/visual-undo-bindings-and-defaults-are-present ()
  (should (equal my/undo-vundo-prefix "C-c u"))
  (should (eq (lookup-key global-map (kbd "C-x u")) 'vundo))
  (should (eq (lookup-key global-map (kbd "C-c u v")) 'vundo))
  (should (eq (lookup-key global-map (kbd "C-c u u")) 'undo-only))
  (should (eq (lookup-key global-map (kbd "C-c u r")) 'undo-redo))
  (should vundo-compact-display)
  (should vundo-roll-back-on-quit)
  (should (= vundo-window-max-height my/undo-vundo-window-max-height))
  (should (member vundo-glyph-alist
                  (list vundo-ascii-symbols vundo-unicode-symbols))))

;;; Platform-specific host integration
(ert-deftest emacs-config/platform-predicates-identify-system-types ()
  (should (my/platform-macos-p 'darwin))
  (should-not (my/platform-macos-p 'gnu/linux))
  (should (my/platform-linux-p 'gnu/linux))
  (should-not (my/platform-linux-p 'windows-nt))
  (should (my/platform-windows-p 'windows-nt))
  (should (my/platform-windows-p 'cygwin))
  (should-not (my/platform-windows-p 'darwin))
  (should (my/platform-wsl-p 'gnu/linux "Linux version Microsoft WSL2"))
  (should-not (my/platform-wsl-p 'gnu/linux "Linux version generic")))

(ert-deftest emacs-config/platform-shell-default-is-portable ()
  (let ((process-environment (cons "SHELL=/bin/test-shell"
                                   process-environment)))
    (should (equal (my/platform-default-shell 'gnu/linux)
                   "/bin/test-shell")))
  (cl-letf (((symbol-function 'executable-find)
             (lambda (command)
               (and (equal command "pwsh.exe") command))))
    (should (equal (my/platform-default-shell 'windows-nt)
                   "pwsh.exe"))))

(ert-deftest emacs-config/platform-open-and-reveal-commands-are-selected ()
  (should (equal (my/platform-open-command "/tmp/demo.txt" 'darwin)
                 '("open" "/tmp/demo.txt")))
  (should (equal (my/platform-reveal-command "/tmp/demo.txt" 'darwin)
                 (list "open" "-R" (expand-file-name "/tmp/demo.txt"))))
  (cl-letf (((symbol-function 'executable-find)
             (lambda (command)
               (and (member command '("xdg-open" "nautilus")) command))))
    (should (equal (my/platform-open-command "/tmp/demo.txt" 'gnu/linux)
                   '("xdg-open" "/tmp/demo.txt")))
    (should (equal (car (my/platform-reveal-command "/tmp/demo.txt" 'gnu/linux))
                   "nautilus")))
  (should (equal (cl-subseq
                  (my/platform-open-command "C:/tmp/demo.txt" 'windows-nt)
                  0 4)
                 '("cmd.exe" "/c" "start" "")))
  (should (equal (car (my/platform-reveal-command
                       "C:/tmp/demo.txt" 'windows-nt))
                 "explorer.exe")))

(ert-deftest emacs-config/platform-clipboard-commands-are-selected ()
  (cl-letf (((symbol-function 'executable-find)
             (lambda (command)
               (and (member command '("pbcopy" "pbpaste"
                                      "clip.exe" "powershell.exe"
                                      "wl-copy" "wl-paste"
                                      "xclip"))
                    command))))
    (should (equal (my/platform-clipboard-copy-command 'darwin)
                   '("pbcopy")))
    (should (equal (my/platform-clipboard-paste-command 'darwin)
                   '("pbpaste")))
    (should (equal (my/platform-clipboard-copy-command 'windows-nt)
                   '("clip.exe")))
    (should (equal (my/platform-clipboard-paste-command 'windows-nt)
                   '("powershell.exe" "-NoProfile" "-Command" "Get-Clipboard")))
    (let ((process-environment (cons "WAYLAND_DISPLAY=wayland-0"
                                     process-environment)))
      (should (equal (my/platform-clipboard-copy-command 'gnu/linux)
                     '("wl-copy")))
      (should (equal (my/platform-clipboard-paste-command 'gnu/linux)
                     '("wl-paste" "-n")))))
  (cl-letf (((symbol-function 'executable-find)
             (lambda (command)
               (and (equal command "xclip") command))))
    (should (equal (my/platform-clipboard-copy-command 'gnu/linux)
                   '("xclip" "-selection" "clipboard")))))

(ert-deftest emacs-config/platform-global-bindings-are-present ()
  (should (equal my/platform-open-bindings-prefix "C-c O"))
  (should (eq (lookup-key global-map (kbd "C-c O o"))
              'my/platform-open-file-externally))
  (should (eq (lookup-key global-map (kbd "C-c O r"))
              'my/platform-reveal-in-file-manager))
  (should (eq (lookup-key global-map (kbd "C-c O p"))
              'my/platform-copy-file-path))
  (should delete-by-moving-to-trash)
  (should (stringp shell-file-name))
  (should (stringp explicit-shell-file-name)))

;;; Terminal-frame behavior
(ert-deftest emacs-config/terminal-osc52-sequence-encodes-clipboard-text ()
  (let ((sequence (my/terminal-osc52-sequence "hello" 'direct)))
    (should (string-prefix-p "\e]52;c;" sequence))
    (should (string-match-p "aGVsbG8=" sequence))
    (should (string-suffix-p "\a" sequence))))

(ert-deftest emacs-config/terminal-osc52-transport-detects-multiplexers ()
  (let ((process-environment '("TMUX=/tmp/tmux-501/default,123,0")))
    (should (eq (my/terminal-osc52-transport) 'tmux)))
  (let ((process-environment '("STY=1234.pts-0.host")))
    (should (eq (my/terminal-osc52-transport) 'screen)))
  (let ((process-environment nil))
    (should (eq (my/terminal-osc52-transport) 'direct))))

(ert-deftest emacs-config/terminal-osc52-copy-respects-byte-limit ()
  (let ((my/terminal-osc52-max-bytes 1)
        (my/terminal-osc52-copy-enabled t)
        (sent nil))
    (cl-letf (((symbol-function 'display-graphic-p)
               (lambda (&optional frame)
                 (ignore frame)
                 nil))
              ((symbol-function 'send-string-to-terminal)
               (lambda (string &optional terminal)
                 (ignore terminal)
                 (setq sent string))))
      (let ((noninteractive nil))
        (should-not (my/terminal-osc52-copy "hello")))
      (should-not sent))))

(ert-deftest emacs-config/terminal-osc52-copy-mirrors-without-owning-kill-ring ()
  (let ((my/terminal-osc52-max-bytes 100)
        (my/terminal-osc52-copy-enabled t)
        (sent nil))
    (cl-letf (((symbol-function 'display-graphic-p)
               (lambda (&optional frame)
                 (ignore frame)
                 nil))
              ((symbol-function 'send-string-to-terminal)
               (lambda (string &optional terminal)
                 (ignore terminal)
                 (setq sent string))))
      (let ((noninteractive nil))
        (should-not (my/terminal-osc52-copy "hello")))
      (should sent))))

(ert-deftest emacs-config/terminal-osc52-copy-is-disabled-in-batch ()
  (let ((sent nil))
    (cl-letf (((symbol-function 'send-string-to-terminal)
               (lambda (string &optional terminal)
                 (ignore terminal)
                 (setq sent string))))
      (should-not (my/terminal-osc52-copy "hello"))
      (should-not sent))))

(ert-deftest emacs-config/terminal-osc52-copy-installs-cut-function ()
  (should-not (my/terminal-frame-p))
  (let ((interprogram-cut-function nil))
    (cl-letf (((symbol-function 'display-graphic-p)
               (lambda (&optional frame)
                 (ignore frame)
                 nil)))
      (let ((noninteractive nil))
        (my/terminal-apply-osc52-clipboard))
      (should (eq interprogram-cut-function #'my/terminal-osc52-copy)))))

(ert-deftest emacs-config/terminal-editor-environment-points-at-emacsclient ()
  (should (equal my/terminal-editor-command "emacsclient -t -a \"\""))
  (should (equal (my/terminal-editor-environment)
                 '(("EDITOR" . "emacsclient -t -a \"\"")
                   ("VISUAL" . "emacsclient -t -a \"\"")
                   ("GIT_EDITOR" . "emacsclient -t -a \"\"")))))

(ert-deftest emacs-config/terminal-editor-environment-is-applied ()
  (let ((process-environment nil)
        (my/terminal-editor-command "emacsclient -t -a \"\""))
    (my/terminal-apply-editor-environment)
    (should (equal (getenv "EDITOR") "emacsclient -t -a \"\""))
    (should (equal (getenv "VISUAL") "emacsclient -t -a \"\""))
    (should (equal (getenv "GIT_EDITOR") "emacsclient -t -a \"\""))))

(ert-deftest emacs-config/terminal-server-does-not-start-in-batch ()
  (let ((my/terminal-start-server t)
        (started nil))
    (cl-letf (((symbol-function 'server-running-p)
               (lambda (&optional name)
                 (ignore name)
                 nil))
              ((symbol-function 'server-start)
               (lambda (&optional leave-dead name)
                 (ignore leave-dead name)
                 (setq started t))))
      (my/terminal-maybe-start-server)
      (should-not started))))

(ert-deftest emacs-config/terminal-with-editor-package-is-installed ()
  (should (require 'with-editor nil t)))

(ert-deftest emacs-config/setup-installs-terminal-helper-packages ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name "scripts/setup.el"
                                            emacs-config-test-root))
    (should (search-forward "with-editor" nil t))))

(ert-deftest emacs-config/terminal-with-editor-is-enabled-for-shells ()
  (should my/terminal-with-editor-enabled)
  (should (bound-and-true-p shell-command-with-editor-mode))
  (dolist (hook '(shell-mode-hook
                  eshell-mode-hook
                  term-exec-hook
                  vterm-mode-hook))
    (should (memq #'with-editor-export-editor (symbol-value hook)))))

(ert-deftest emacs-config/terminal-with-editor-remaps-shell-commands ()
  (should (eq (lookup-key global-map [remap async-shell-command])
              'with-editor-async-shell-command))
  (should (eq (lookup-key global-map [remap shell-command])
              'with-editor-shell-command)))

(ert-deftest emacs-config/terminal-mouse-is-configured-for-new-frames ()
  (should my/terminal-mouse-enabled)
  (should (memq #'my/terminal-apply-mouse after-make-frame-functions)))

(ert-deftest emacs-config/terminal-mouse-stays-disabled-in-batch ()
  (let ((enabled nil))
    (cl-letf (((symbol-function 'xterm-mouse-mode)
               (lambda (&optional arg)
                 (setq enabled arg))))
      (my/terminal-apply-mouse)
      (should-not enabled))))

(ert-deftest emacs-config/terminal-mouse-enables-interactive-terminal-frames ()
  (let ((enabled nil))
    (cl-letf (((symbol-function 'display-graphic-p)
               (lambda (&optional frame)
                 (ignore frame)
                 nil))
              ((symbol-function 'xterm-mouse-mode)
               (lambda (&optional arg)
                 (setq enabled arg))))
      (let ((noninteractive nil))
        (my/terminal-apply-mouse))
      (should (equal enabled 1))
      (should (lookup-key global-map [mouse-4]))
      (should (lookup-key global-map [mouse-5])))))

(ert-deftest emacs-config/terminal-git-commit-package-is-available ()
  (should (require 'git-commit nil t)))

(ert-deftest emacs-config/terminal-git-commit-defaults-are-configured ()
  (should (= my/terminal-git-commit-fill-column 72))
  (should (= my/terminal-git-commit-summary-max-length 72))
  (should (= git-commit-summary-max-length
             my/terminal-git-commit-summary-max-length))
  (should (memq #'my/terminal-git-commit-setup git-commit-setup-hook)))

(ert-deftest emacs-config/terminal-git-commit-setup-enables-writing-defaults ()
  (with-temp-buffer
    (let ((my/terminal-git-commit-fill-column 72))
      (cl-letf (((symbol-function 'executable-find)
                 (lambda (_command) nil)))
        (my/terminal-git-commit-setup)))
    (should (= fill-column 72))
    (should (bound-and-true-p auto-fill-function))))

(ert-deftest emacs-config/terminal-git-commit-finish-bindings-are-present ()
  (should (eq (lookup-key git-commit-mode-map (kbd "C-c C-c"))
              'with-editor-finish))
  (should (eq (lookup-key git-commit-mode-map (kbd "C-c C-k"))
              'with-editor-cancel)))

(ert-deftest emacs-config/terminal-tramp-defaults-are-ssh-friendly ()
  (should (equal tramp-default-method "ssh"))
  (should (= tramp-verbose my/terminal-tramp-verbose))
  (should (equal tramp-auto-save-directory
                 my/terminal-tramp-auto-save-directory))
  (should remote-file-name-inhibit-locks)
  (should (file-directory-p my/terminal-tramp-auto-save-directory))
  (should (string-prefix-p (expand-file-name "var/" emacs-config-test-root)
                           my/terminal-tramp-auto-save-directory)))

(ert-deftest emacs-config/terminal-environment-docs-cover-terminal-setup ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name "README.md" emacs-config-test-root))
    (let ((readme (buffer-string)))
      (should (string-match-p "## Terminal Environment" readme))
      (should (string-match-p "TERM" readme))
      (should (string-match-p "OSC 52" readme))
      (should (string-match-p "set-clipboard" readme))
      (should (string-match-p "terminal-features" readme)))))

(ert-deftest emacs-config/terminal-xterm-key-decodes-are-data-driven ()
  (should (assoc "\e[1;5D" my/terminal-xterm-key-decodes))
  (should (assoc "\e[1;5C" my/terminal-xterm-key-decodes))
  (should (assoc "\e[1;5H" my/terminal-xterm-key-decodes))
  (should (assoc "\e[1;5F" my/terminal-xterm-key-decodes)))

(ert-deftest emacs-config/terminal-xterm-key-decodes-are-installed ()
  (should (equal (lookup-key input-decode-map "\e[1;5D") [C-left]))
  (should (equal (lookup-key input-decode-map "\e[1;5C") [C-right]))
  (should (equal (lookup-key input-decode-map "\e[1;5H") [C-home]))
  (should (equal (lookup-key input-decode-map "\e[1;5F") [C-end])))

(ert-deftest emacs-config/terminal-remote-buffer-detection-is-parser-only ()
  (with-temp-buffer
    (setq buffer-file-name "/ssh:example:/tmp/demo.c")
    (should (my/terminal-remote-buffer-p)))
  (with-temp-buffer
    (setq buffer-file-name "/tmp/demo.c")
    (should-not (my/terminal-remote-buffer-p))))

(ert-deftest emacs-config/terminal-remote-editing-disables-lockfiles-locally ()
  (with-temp-buffer
    (setq buffer-file-name "/ssh:example:/tmp/demo.c")
    (setq-local create-lockfiles t)
    (my/terminal-remote-editing-setup)
    (should-not create-lockfiles)))

(ert-deftest emacs-config/custom-file-is-separated ()
  (should (equal custom-file
                 (expand-file-name "custom.el" user-emacs-directory))))

;;; Completion, search, and command discovery
(ert-deftest emacs-config/completion-helper-packages-are-installed ()
  (dolist (feature '(vertico
                     orderless
                     marginalia
                     consult
                     embark
                     embark-consult
                     which-key
                     corfu
                     cape))
    (should (require feature nil t))))

(ert-deftest emacs-config/setup-installs-completion-helper-packages ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name "scripts/setup.el"
                                            emacs-config-test-root))
    (dolist (package '("vertico"
                       "orderless"
                       "marginalia"
                       "consult"
                       "embark"
                       "embark-consult"
                       "which-key"
                       "corfu"
                       "cape"))
      (should (search-forward package nil t)))))

(ert-deftest emacs-config/completion-minibuffer-defaults-are-enabled ()
  (should (bound-and-true-p vertico-mode))
  (should (bound-and-true-p marginalia-mode))
  (should (bound-and-true-p which-key-mode))
  (should (equal completion-styles '(orderless basic)))
  (should (assoc 'file completion-category-overrides))
  (should (= my/completion-preview-delay 0.25)))

(ert-deftest emacs-config/completion-corfu-and-cape-are-global ()
  (should (bound-and-true-p global-corfu-mode))
  (should corfu-auto)
  (should (= corfu-count my/completion-corfu-count))
  (should corfu-cycle)
  (should-not corfu-on-exact-match)
  (should-not corfu-preview-current)
  (dolist (backend '(cape-file cape-dabbrev cape-keyword))
    (should (memq backend (default-value 'completion-at-point-functions)))))

(ert-deftest emacs-config/completion-project-search-bindings-are-present ()
  (should (eq (lookup-key global-map (kbd "C-s")) 'consult-line))
  (should (eq (lookup-key global-map (kbd "C-x b")) 'consult-buffer))
  (should (eq (lookup-key global-map (kbd "C-c p b"))
              'consult-project-buffer))
  (should (eq (lookup-key global-map (kbd "C-c p f"))
              'my/completion-consult-find))
  (should (eq (lookup-key global-map (kbd "C-c p g"))
              'my/completion-consult-ripgrep))
  (should (eq (lookup-key global-map (kbd "C-c p l"))
              'my/completion-consult-line-multi))
  (should (eq (lookup-key global-map (kbd "C-c p r"))
              'consult-recent-file)))

(ert-deftest emacs-config/completion-embark-bindings-are-present ()
  (should (eq (lookup-key global-map (kbd "C-."))
              'embark-act))
  (should (eq (lookup-key global-map (kbd "C-;"))
              'embark-dwim))
  (should (eq (lookup-key global-map (kbd "C-h B"))
              'embark-bindings))
  (should (eq prefix-help-command 'embark-prefix-help-command)))

;;; Snippets and templates
(ert-deftest emacs-config/snippets-helper-package-is-installed ()
  (should (require 'yasnippet nil t)))

(ert-deftest emacs-config/setup-installs-snippet-helper-package ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name "scripts/setup.el"
                                            emacs-config-test-root))
    (should (search-forward "yasnippet" nil t))))

(ert-deftest emacs-config/snippets-are-loaded-from-repo ()
  (should (bound-and-true-p yas-global-mode))
  (should (equal my/snippets-directory
                 (expand-file-name "snippets/" emacs-config-test-root)))
  (should (member my/snippets-directory yas-snippet-dirs))
  (dolist (relative-file '("snippets/emacs-lisp-mode/ert"
                           "snippets/python-mode/pytest"
                           "snippets/c-mode/main"
                           "snippets/rust-mode/test"
                           "snippets/typescript-mode/test"))
    (should (file-exists-p
             (expand-file-name relative-file emacs-config-test-root)))))

(ert-deftest emacs-config/snippet-bindings-are-present ()
  (should (eq (lookup-key global-map (kbd "C-c y i")) 'yas-insert-snippet))
  (should (eq (lookup-key global-map (kbd "C-c y n")) 'yas-new-snippet))
  (should (eq (lookup-key global-map (kbd "C-c y r")) 'yas-reload-all))
  (should (eq (lookup-key global-map (kbd "C-c y v"))
              'yas-visit-snippet-file)))

;;; Diagnostics and code navigation
(ert-deftest emacs-config/diagnostics-built-in-tools-are-available ()
  (dolist (feature '(flymake xref eglot consult))
    (should (require feature nil t))))

(ert-deftest emacs-config/diagnostics-global-bindings-are-present ()
  (should (eq (lookup-key global-map (kbd "C-c ! l"))
              'my/diagnostics-list))
  (should (eq (lookup-key global-map (kbd "C-c ! b"))
              'my/diagnostics-buffer))
  (should (eq (lookup-key global-map (kbd "C-c ! n"))
              'flymake-goto-next-error))
  (should (eq (lookup-key global-map (kbd "C-c ! p"))
              'flymake-goto-prev-error))
  (should (eq (lookup-key global-map (kbd "C-c x a"))
              'my/diagnostics-code-actions))
  (should (eq (lookup-key global-map (kbd "C-c x d"))
              'xref-find-definitions))
  (should (eq (lookup-key global-map (kbd "C-c x r"))
              'xref-find-references))
  (should (eq (lookup-key global-map (kbd "C-c x R"))
              'my/diagnostics-rename))
  (should (eq (lookup-key global-map (kbd "C-c x i"))
              'consult-imenu))
  (should (eq (lookup-key global-map (kbd "C-c x I"))
              'consult-imenu-multi)))

(ert-deftest emacs-config/diagnostics-xref-uses-consult ()
  (should (eq xref-show-xrefs-function 'consult-xref))
  (should (eq xref-show-definitions-function 'consult-xref))
  (when (boundp 'xref-search-program)
    (should (eq xref-search-program 'ripgrep))))

;;; Debug adapter protocol support
(ert-deftest emacs-config/debug-helper-package-is-installed ()
  (should (require 'dape nil t)))

(ert-deftest emacs-config/setup-installs-debug-helper-package ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name "scripts/setup.el"
                                            emacs-config-test-root))
    (should (search-forward "dape" nil t))))

(ert-deftest emacs-config/debug-defaults-are-portable ()
  (should (eq my/debug-dape-buffer-arrangement 'right))
  (should my/debug-dape-inlay-hints))

(ert-deftest emacs-config/debug-bindings-are-present ()
  (should (eq (lookup-key global-map (kbd "C-c D d")) 'dape))
  (should (eq (lookup-key global-map (kbd "C-c D b"))
              'dape-breakpoint-toggle))
  (should (eq (lookup-key global-map (kbd "C-c D B"))
              'dape-breakpoint-remove-all))
  (should (eq (lookup-key global-map (kbd "C-c D c")) 'dape-continue))
  (should (eq (lookup-key global-map (kbd "C-c D i")) 'dape-info))
  (should (eq (lookup-key global-map (kbd "C-c D k")) 'dape-kill))
  (should (eq (lookup-key global-map (kbd "C-c D n")) 'dape-next))
  (should (eq (lookup-key global-map (kbd "C-c D r")) 'dape-restart))
  (should (eq (lookup-key global-map (kbd "C-c D s")) 'dape-step-in))
  (should (eq (lookup-key global-map (kbd "C-c D o")) 'dape-step-out)))

;;; Project environment loading
(ert-deftest emacs-config/environment-helper-package-is-installed ()
  (should (require 'envrc nil t)))

(ert-deftest emacs-config/setup-installs-environment-helper-package ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name "scripts/setup.el"
                                            emacs-config-test-root))
    (should (search-forward "envrc" nil t))))

(ert-deftest emacs-config/environment-direnv-defaults-are-portable ()
  (should (equal my/environment-direnv-executable "direnv"))
  (should my/environment-auto-enable-direnv)
  (let ((my/environment-direnv-executable
         "definitely-not-a-real-direnv-command"))
    (should-not (my/environment-direnv-available-p))))

(ert-deftest emacs-config/environment-global-bindings-are-present ()
  (should (eq (lookup-key global-map (kbd "C-c E a")) 'envrc-allow))
  (should (eq (lookup-key global-map (kbd "C-c E d")) 'envrc-deny))
  (should (eq (lookup-key global-map (kbd "C-c E e"))
              'my/environment-enable-envrc))
  (should (eq (lookup-key global-map (kbd "C-c E r")) 'envrc-reload)))

;;; MCP endpoint support for external agents
(ert-deftest emacs-config/mcp-helper-packages-are-installed ()
  (should (require 'mcp-server-lib nil t))
  (should (require 'mcp-server-lib-commands nil t))
  (should (require 'elisp-dev-mcp nil t)))

(ert-deftest emacs-config/setup-installs-mcp-helper-packages ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name "scripts/setup.el"
                                            emacs-config-test-root))
    (dolist (package '("mcp-server-lib" "elisp-dev-mcp"))
      (should (search-forward package nil t)))
    (should (search-forward "my/mcp-install-stdio-script" nil t))))

(ert-deftest emacs-config/mcp-defaults-and-stdio-command-are-portable ()
  (should (equal my/mcp-server-name "elisp-dev"))
  (should (equal my/mcp-server-id "elisp-dev-mcp"))
  (should (equal my/mcp-elisp-dev-init-function "elisp-dev-mcp-enable"))
  (should (equal my/mcp-elisp-dev-stop-function "elisp-dev-mcp-disable"))
  (should (equal my/mcp-install-directory user-emacs-directory))
  (should (equal (my/mcp-stdio-script-path)
                 (expand-file-name "emacs-mcp-stdio.sh"
                                   user-emacs-directory)))
  (should (equal (my/mcp-elisp-dev-stdio-command)
                 (list (my/mcp-stdio-script-path)
                       "--init-function=elisp-dev-mcp-enable"
                       "--stop-function=elisp-dev-mcp-disable"
                       "--server-id=elisp-dev-mcp")))
  (should (string-match-p "emacs-mcp-stdio\\.sh"
                          (my/mcp-command-line
                           (my/mcp-elisp-dev-stdio-command)))))

(ert-deftest emacs-config/mcp-elisp-dev-allowed-dirs-are-first-party ()
  (my/mcp-apply-elisp-dev-allowed-dirs)
  (dolist (relative-directory '("lisp/" "scripts/" "tests/"))
    (should (member (file-name-as-directory
                     (expand-file-name relative-directory
                                       emacs-config-test-root))
                    elisp-dev-mcp-additional-allowed-dirs))))

(ert-deftest emacs-config/mcp-bindings-are-present ()
  (should (eq (lookup-key global-map (kbd "C-c a m s")) 'my/mcp-start))
  (should (eq (lookup-key global-map (kbd "C-c a m x")) 'my/mcp-stop))
  (should (eq (lookup-key global-map (kbd "C-c a m i"))
              'my/mcp-install-stdio-script))
  (should (eq (lookup-key global-map (kbd "C-c a m c"))
              'my/mcp-copy-elisp-dev-stdio-command))
  (should (eq (lookup-key global-map (kbd "C-c a m d"))
              'mcp-server-lib-describe-setup))
  (should (eq (lookup-key global-map (kbd "C-c a m M"))
              'mcp-server-lib-show-metrics)))

;;; Agentic development workflow
(ert-deftest emacs-config/agent-defaults-are-portable ()
  (should (equal my/agent-codex-command '("codex")))
  (should (equal my/agent-claude-command '("claude")))
  (should (equal my/agent-cursor-command '("cursor-agent")))
  (should my/agent-save-project-buffers-before-launch)
  (dolist (provider '(codex claude cursor))
    (should (alist-get provider my/agent-providers))
    (should (listp (my/agent-provider-command provider)))
    (should (stringp (my/agent-provider-name provider))))
  (should (member "AGENTS.md" my/agent-project-context-files))
  (should (member "README.md" my/agent-project-context-files))
  (should (natnump my/agent-project-context-status-limit))
  (let ((my/agent-codex-command '("definitely-not-a-real-codex-command")))
    (should-not (my/agent-codex-available-p))))

(ert-deftest emacs-config/agent-provider-availability-checks-provider-command ()
  (let ((my/agent-claude-command '("definitely-not-a-real-claude-command"))
        (my/agent-cursor-command '("definitely-not-a-real-cursor-command")))
    (should-not (my/agent-provider-available-p 'claude))
    (should-not (my/agent-provider-available-p 'cursor))))

(ert-deftest emacs-config/agent-control-plane-uses-transient ()
  (should (require 'transient nil t))
  (should (fboundp 'my/agent-control))
  (should (fboundp 'my/agent-control-transient)))

(ert-deftest emacs-config/setup-installs-agent-control-plane-package ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name "scripts/setup.el"
                                            emacs-config-test-root))
    (should (search-forward "transient" nil t))))

(ert-deftest emacs-config/agent-command-line-quotes-arguments ()
  (should (equal (my/agent-command-line
                  '("/path with spaces/codex" "--flag" "two words"))
                 "/path\\ with\\ spaces/codex --flag two\\ words")))

(ert-deftest emacs-config/agent-copy-file-context-includes-line ()
  (let ((file (make-temp-file "emacs-config-agent-" nil ".txt")))
    (unwind-protect
        (with-temp-buffer
          (insert "one\ntwo\n")
          (write-region (point-min) (point-max) file nil 'silent)
          (find-file file)
          (goto-char (point-min))
          (forward-line 1)
          (my/agent-copy-file-context)
          (should (equal (current-kill 0)
                         (format "File context: %s:2" file)))
          (kill-buffer))
      (when (file-exists-p file)
        (delete-file file)))))

(ert-deftest emacs-config/agent-project-context-includes-guidance-and-status ()
  (let* ((root (file-name-as-directory
                (make-temp-file "emacs-config-agent-project-" t)))
         (default-directory root)
         (my/agent-project-context-files '("AGENTS.md" "README.md" "missing.md")))
    (unwind-protect
        (progn
          (write-region "agent rules\n" nil (expand-file-name "AGENTS.md" root)
                        nil 'silent)
          (write-region "readme notes\n" nil (expand-file-name "README.md" root)
                        nil 'silent)
          (let ((context (my/agent-project-context-string)))
            (should (string-match-p "# Agent Project Context" context))
            (should (string-match-p "Project root:" context))
            (should (string-match-p "Git Status" context))
            (should (string-match-p "## AGENTS\\.md" context))
            (should (string-match-p "agent rules" context))
            (should (string-match-p "## README\\.md" context))
            (should (string-match-p "readme notes" context))
            (should-not (string-match-p "missing\\.md" context))))
      (delete-directory root t))))

(ert-deftest emacs-config/agent-copy-project-context-populates-kill-ring ()
  (let* ((root (file-name-as-directory
                (make-temp-file "emacs-config-agent-project-" t)))
         (default-directory root)
         (my/agent-project-context-files '("AGENTS.md")))
    (unwind-protect
        (progn
          (write-region "copyable context\n" nil
                        (expand-file-name "AGENTS.md" root) nil 'silent)
          (my/agent-copy-project-context)
          (should (string-match-p "copyable context" (current-kill 0))))
      (delete-directory root t))))

(ert-deftest emacs-config/agent-bindings-are-present ()
  (should (eq (lookup-key global-map (kbd "C-c a ?")) 'my/agent-control))
  (should (eq (lookup-key global-map (kbd "C-c a A")) 'my/agent-launch))
  (should (eq (lookup-key global-map (kbd "C-c a a")) 'my/agent-codex))
  (should (eq (lookup-key global-map (kbd "C-c a d")) 'my/agent-claude))
  (should (eq (lookup-key global-map (kbd "C-c a u")) 'my/agent-cursor))
  (should (eq (lookup-key global-map (kbd "C-c a f"))
              'my/agent-codex-with-file))
  (should (eq (lookup-key global-map (kbd "C-c a p"))
              'my/agent-copy-project-context))
  (should (eq (lookup-key global-map (kbd "C-c a P"))
              'my/agent-open-project-context))
  (should (eq (lookup-key global-map (kbd "C-c a L"))
              'my/agent-launch-with-project-context))
  (should (eq (lookup-key global-map (kbd "C-c a r"))
              'my/agent-codex-with-region))
  (should (eq (lookup-key global-map (kbd "C-c a t"))
              'my/agent-project-vterm)))

;;; Project helper behavior
(ert-deftest emacs-config/project-root-falls-back-to-default-directory ()
  (let ((root (file-name-as-directory (make-temp-file "emacs-config-test-" t))))
    (unwind-protect
        (let ((default-directory root))
          (should (equal (my/project-root) root)))
      (delete-directory root t))))

(ert-deftest emacs-config/project-root-detects-git-repositories ()
  (skip-unless (executable-find "git"))
  (let* ((root (file-name-as-directory (make-temp-file "emacs-config-test-" t)))
         (subdir (expand-file-name "nested" root)))
    (unwind-protect
        (progn
          (make-directory subdir)
          (should (zerop (call-process "git" nil nil nil "-C" root "init" "-q")))
          (let ((default-directory subdir))
            (should (equal (file-truename (my/project-root))
                           (file-truename root)))))
      (delete-directory root t))))

;;; Generic project command runner
(ert-deftest emacs-config/project-command-defaults-and-bindings-are-present ()
  (dolist (command '("make -k" "make test" "make lint" "make run"))
    (should (member command (mapcar #'cdr my/project-command-defaults))))
  (should (eq (lookup-key global-map (kbd "C-c p c")) 'my/project-command-run))
  (should (eq (lookup-key global-map (kbd "C-c p C"))
              'my/project-command-repeat))
  (should (eq compilation-scroll-output 'first-error)))

(ert-deftest emacs-config/project-command-detects-common-project-files ()
  (let ((root (file-name-as-directory
               (make-temp-file "emacs-config-project-commands-" t))))
    (unwind-protect
        (progn
          (write-region "all:\n" nil (expand-file-name "Makefile" root)
                        nil 'silent)
          (write-region "{}\n" nil (expand-file-name "package.json" root)
                        nil 'silent)
          (write-region "[package]\nname = \"demo\"\nversion = \"0.1.0\"\n"
                        nil (expand-file-name "Cargo.toml" root) nil 'silent)
          (write-region "[project]\nname = \"demo\"\n"
                        nil (expand-file-name "pyproject.toml" root)
                        nil 'silent)
          (let ((commands (mapcar #'cdr
                                  (my/project-command-detected-candidates root))))
            (dolist (command '("make -k" "make test" "npm test"
                               "npm run build" "cargo test" "cargo build"
                               "pytest" "ruff check ."))
              (should (member command commands)))))
      (delete-directory root t))))

;;; Bookmarks and registers
(ert-deftest emacs-config/navigation-bookmarks-and-registers-are-configured ()
  (should (equal my/navigation-prefix "C-c n"))
  (should (string-prefix-p (expand-file-name "var/" emacs-config-test-root)
                           my/navigation-bookmark-file))
  (should (file-directory-p (file-name-directory my/navigation-bookmark-file)))
  (should (equal bookmark-default-file my/navigation-bookmark-file))
  (should (equal bookmark-save-flag 1))
  (when (boundp 'register-preview-delay)
    (should (= register-preview-delay my/navigation-register-preview-delay)))
  (dolist (binding '(("C-c n b" . bookmark-set)
                     ("C-c n j" . bookmark-jump)
                     ("C-c n l" . list-bookmarks)
                     ("C-c n d" . bookmark-delete)
                     ("C-c n R" . bookmark-rename)
                     ("C-c n S" . bookmark-save)
                     ("C-c n s" . point-to-register)
                     ("C-c n r" . jump-to-register)
                     ("C-c n v" . view-register)
                     ("C-c n i" . insert-register)
                     ("C-c n x" . copy-to-register)
                     ("C-c n a" . append-to-register)
                     ("C-c n w" . window-configuration-to-register)
                     ("C-c n f" . frameset-to-register)))
    (should (eq (lookup-key global-map (kbd (car binding)))
                (cdr binding)))))

;;; Org developer notes
(ert-deftest emacs-config/notes-org-capture-defaults-are-configured ()
  (should (equal my/notes-prefix "C-c o"))
  (should (string-prefix-p (expand-file-name "var/notes/" emacs-config-test-root)
                           my/notes-directory))
  (dolist (file (list my/notes-inbox-file
                      my/notes-decisions-file
                      my/notes-debug-file))
    (should (file-exists-p file))
    (should (string-prefix-p my/notes-directory file)))
  (should (equal org-directory my/notes-directory))
  (should (equal org-default-notes-file my/notes-inbox-file))
  (should (equal org-agenda-files
                 (list my/notes-inbox-file
                       my/notes-decisions-file
                       my/notes-debug-file)))
  (should (equal org-log-done 'time))
  (should org-return-follows-link)
  (should (eq org-startup-folded 'content))
  (dolist (key '("t" "n" "d" "b"))
    (should (assoc key org-capture-templates))))

(ert-deftest emacs-config/notes-bindings-and-template-helpers-are-present ()
  (dolist (binding '(("C-c o c" . org-capture)
                     ("C-c o a" . org-agenda)
                     ("C-c o i" . my/notes-open-inbox)
                     ("C-c o o" . my/notes-open-directory)
                     ("C-c o t" . my/notes-capture-task)
                     ("C-c o n" . my/notes-capture-note)
                     ("C-c o d" . my/notes-capture-decision)
                     ("C-c o b" . my/notes-capture-debug)))
    (should (eq (lookup-key global-map (kbd (car binding)))
                (cdr binding))))
  (let ((captured nil))
    (cl-letf (((symbol-function 'org-capture)
               (lambda (&optional goto keys)
                 (ignore goto)
                 (setq captured keys))))
      (my/notes-capture-task)
      (should (equal captured "t"))
      (my/notes-capture-note)
      (should (equal captured "n"))
      (my/notes-capture-decision)
      (should (equal captured "d"))
      (my/notes-capture-debug)
      (should (equal captured "b")))))

;;; Workspace and window ergonomics
(ert-deftest emacs-config/workspace-window-and-tab-defaults-are-enabled ()
  (should (bound-and-true-p winner-mode))
  (should my/workspace-enable-tab-bar)
  (should (= my/workspace-tab-bar-show 1))
  (should (eq windmove-wrap-around my/workspace-windmove-wrap-around))
  (should (bound-and-true-p tab-bar-mode))
  (should tab-bar-tab-hints)
  (should-not tab-bar-close-button-show))

(ert-deftest emacs-config/workspace-bindings-are-present ()
  (should (eq (lookup-key global-map (kbd "C-c w u")) 'winner-undo))
  (should (eq (lookup-key global-map (kbd "C-c w r")) 'winner-redo))
  (should (eq (lookup-key global-map (kbd "C-c w h")) 'windmove-left))
  (should (eq (lookup-key global-map (kbd "C-c w j")) 'windmove-down))
  (should (eq (lookup-key global-map (kbd "C-c w k")) 'windmove-up))
  (should (eq (lookup-key global-map (kbd "C-c w l")) 'windmove-right))
  (should (eq (lookup-key global-map (kbd "C-c w n"))
              'my/workspace-tab-new-for-project))
  (should (eq (lookup-key global-map (kbd "C-c w m"))
              'my/workspace-tab-rename-for-project))
  (should (eq (lookup-key global-map (kbd "C-c w o")) 'tab-next))
  (should (eq (lookup-key global-map (kbd "C-c w p")) 'tab-previous))
  (should (eq (lookup-key global-map (kbd "C-c w c")) 'tab-close)))

;;; Dired and file management
(ert-deftest emacs-config/files-dired-defaults-are-enabled ()
  (should dired-dwim-target)
  (should (eq dired-recursive-copies 'always))
  (should (eq dired-recursive-deletes 'top))
  (should dired-auto-revert-buffer)
  (should dired-kill-when-opening-new-dired-buffer)
  (should (equal dired-omit-files my/files-dired-omit-files))
  (should (string-match-p "\\.DS_Store" my/files-dired-omit-files))
  (should (string-match-p "\\.direnv" my/files-dired-omit-files))
  (should (string-match-p "\\.elc" my/files-dired-omit-files)))

(ert-deftest emacs-config/files-dired-bindings-are-present ()
  (should (eq (lookup-key global-map (kbd "C-c f d")) 'dired-jump))
  (should (eq (lookup-key global-map (kbd "C-c f p"))
              'my/files-dired-project-root))
  (should (eq (lookup-key dired-mode-map (kbd "C-c C-e"))
              'wdired-change-to-wdired-mode))
  (should (eq (lookup-key dired-mode-map (kbd "."))
              'my/files-dired-toggle-omit))
  (should (eq (lookup-key dired-mode-map (kbd "^")) 'dired-up-directory))
  (should (eq (lookup-key dired-mode-map (kbd "RET"))
              'dired-find-alternate-file)))

;;; Buffer management
(ert-deftest emacs-config/buffers-ibuffer-defaults-are-enabled ()
  (should ibuffer-expert)
  (should-not ibuffer-show-empty-filter-groups)
  (should-not ibuffer-use-other-window)
  (dolist (group '("Development" "Dired" "Magit" "Terminals" "Help" "Emacs"))
    (should (assoc group my/buffers-ibuffer-filter-groups))))

(ert-deftest emacs-config/buffers-ibuffer-bindings-are-present ()
  (should (eq (lookup-key global-map (kbd "C-x C-b")) 'my/buffers-ibuffer))
  (should (eq (lookup-key global-map (kbd "C-c b b")) 'my/buffers-ibuffer))
  (should (eq (lookup-key global-map (kbd "C-c b r")) 'ibuffer-update)))

;;; Integrated tools
(ert-deftest emacs-config/exec-path-from-shell-is-installed-and-configured ()
  (should (require 'exec-path-from-shell nil t))
  (should (equal exec-path-from-shell-variables
                 my/tools-shell-environment-variables))
  (dolist (variable '("PATH" "MANPATH" "SHELL"))
    (should (member variable my/tools-shell-environment-variables))))

(ert-deftest emacs-config/setup-installs-shell-environment-helper ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name "scripts/setup.el"
                                            emacs-config-test-root))
    (should (search-forward "exec-path-from-shell" nil t))))

(ert-deftest emacs-config/magit-is-installed-and-bound ()
  (should (require 'magit nil t))
  (should (fboundp 'magit-status))
  (should (eq (lookup-key global-map (kbd "C-c g")) 'magit-status)))

(ert-deftest emacs-config/vc-ediff-and-smerge-defaults-are-enabled ()
  (should (eq ediff-window-setup-function #'ediff-setup-windows-plain))
  (should (eq ediff-split-window-function #'split-window-horizontally))
  (should my/vc-diff-hl-enabled)
  (should (equal my/vc-smerge-prefix "C-c v")))

(ert-deftest emacs-config/vc-smerge-bindings-are-present ()
  (should (eq (lookup-key smerge-mode-map (kbd "C-c v n")) 'smerge-next))
  (should (eq (lookup-key smerge-mode-map (kbd "C-c v p")) 'smerge-prev))
  (should (eq (lookup-key smerge-mode-map (kbd "C-c v RET"))
              'smerge-keep-current))
  (should (eq (lookup-key smerge-mode-map (kbd "C-c v a")) 'smerge-keep-all))
  (should (eq (lookup-key smerge-mode-map (kbd "C-c v l"))
              'smerge-keep-lower))
  (should (eq (lookup-key smerge-mode-map (kbd "C-c v u"))
              'smerge-keep-upper))
  (should (eq (lookup-key smerge-mode-map (kbd "C-c v ="))
              'smerge-diff-base-upper))
  (should (eq (lookup-key smerge-mode-map (kbd "C-c v E")) 'smerge-ediff)))

(ert-deftest emacs-config/setup-installs-vc-helper-package ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name "scripts/setup.el"
                                            emacs-config-test-root))
    (should (search-forward "diff-hl" nil t))))

(ert-deftest emacs-config/vterm-is-installed-compiled-and-bound ()
  (should (require 'vterm nil t))
  (should (featurep 'vterm-module))
  (should (fboundp 'vterm))
  (should (fboundp 'my/vterm-project))
  (should (bound-and-true-p vterm-always-compile-module))
  (should (= vterm-max-scrollback 10000))
  (should (eq (lookup-key global-map (kbd "C-c t")) 'vterm))
  (should (eq (lookup-key global-map (kbd "C-c T")) 'my/vterm-project)))

(ert-deftest emacs-config/helpful-is-installed-and-bound ()
  (should (require 'helpful nil t))
  (should (fboundp 'helpful-callable))
  (should (fboundp 'helpful-variable))
  (should (fboundp 'helpful-key))
  (should (fboundp 'helpful-command))
  (should (fboundp 'helpful-at-point))
  (should (eq (lookup-key global-map (kbd "C-h f")) 'helpful-callable))
  (should (eq (lookup-key global-map (kbd "C-h v")) 'helpful-variable))
  (should (eq (lookup-key global-map (kbd "C-h k")) 'helpful-key))
  (should (eq (lookup-key global-map (kbd "C-h x")) 'helpful-command))
  (should (eq (lookup-key global-map (kbd "C-c h")) 'helpful-at-point)))

;;; Emacs Lisp development environment
(ert-deftest emacs-config/elisp-helper-packages-are-installed ()
  (dolist (feature '(paredit
                     rainbow-delimiters
                     aggressive-indent
                     eros
                     macrostep
                     package-lint
                     package-lint-flymake))
    (should (require feature nil t))))

(ert-deftest emacs-config/elisp-mode-enables-development-minor-modes ()
  (with-temp-buffer
    (insert "(defun emacs-config-test-example ()\n  :ok)\n")
    (emacs-lisp-mode)
    (should (not indent-tabs-mode))
    (should (bound-and-true-p eldoc-mode))
    (should (bound-and-true-p flymake-mode))
    (should (bound-and-true-p paredit-mode))
    (should (bound-and-true-p rainbow-delimiters-mode))
    (should (bound-and-true-p aggressive-indent-mode))
    (should (bound-and-true-p eros-mode))))

(ert-deftest emacs-config/elisp-mode-keybindings-are-present ()
  (should (eq (lookup-key emacs-lisp-mode-map (kbd "C-c C-b")) 'eval-buffer))
  (should (eq (lookup-key emacs-lisp-mode-map (kbd "C-c C-c")) 'eval-defun))
  (should (eq (lookup-key emacs-lisp-mode-map (kbd "C-c C-k")) 'check-parens))
  (should (eq (lookup-key emacs-lisp-mode-map (kbd "C-c C-l"))
              'package-lint-current-buffer))
  (should (eq (lookup-key emacs-lisp-mode-map (kbd "C-c C-m"))
              'macrostep-expand))
  (should (eq (lookup-key emacs-lisp-mode-map (kbd "C-c C-z")) 'ielm)))

(ert-deftest emacs-config/eldoc-and-flymake-are-tuned-for-elisp ()
  (should (= eldoc-idle-delay 0.2))
  (should (not eldoc-echo-area-use-multiline-p))
  (should (eq (lookup-key flymake-mode-map (kbd "M-n"))
              'flymake-goto-next-error))
  (should (eq (lookup-key flymake-mode-map (kbd "M-p"))
              'flymake-goto-prev-error)))

;;; C and C++ development environment
(ert-deftest emacs-config/c-helper-packages-are-installed ()
  (dolist (feature '(clang-format cmake-mode eglot))
    (should (require feature nil t))))

(ert-deftest emacs-config/setup-installs-c-helper-packages ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name "scripts/setup.el"
                                            emacs-config-test-root))
    (dolist (package '(clang-format cmake-mode))
      (should (search-forward (symbol-name package) nil t)))))

(ert-deftest emacs-config/c-mode-enables-development-defaults ()
  (with-temp-buffer
    (c-mode)
    (should (= c-basic-offset my/c-basic-offset))
    (should (= tab-width my/c-basic-offset))
    (should (= fill-column my/c-fill-column))
    (should (not indent-tabs-mode))
    (should show-trailing-whitespace)
    (should (bound-and-true-p flymake-mode))
    (should (bound-and-true-p hs-minor-mode))
    (should (eq (local-key-binding (kbd "C-c b")) 'my/c-compile))
    (should (eq (local-key-binding (kbd "C-c r")) 'my/c-recompile))
    (should (eq (local-key-binding (kbd "C-c f")) 'my/c-format-buffer))
    (should (eq (local-key-binding (kbd "C-c e")) 'eglot))
    (should (eq (local-key-binding (kbd "C-c d")) 'my/c-debug))
    (should (eq (local-key-binding (kbd "C-c o")) 'ff-find-other-file))))

(ert-deftest emacs-config/c-eglot-uses-clangd ()
  (let ((entry (assoc '(c-mode c-ts-mode c++-mode c++-ts-mode)
                      eglot-server-programs)))
    (should entry)
    (should (equal (car (cdr entry)) "clangd"))
    (should (member "--background-index" (cdr entry)))
    (should (member "--clang-tidy" (cdr entry)))))

(ert-deftest emacs-config/c-default-build-command-detects-make ()
  (let ((root (file-name-as-directory (make-temp-file "emacs-config-test-" t))))
    (unwind-protect
        (progn
          (write-region "" nil (expand-file-name "Makefile" root) nil 'silent)
          (let ((default-directory root))
            (should (equal (my/c-default-compile-command) "make -k"))))
      (delete-directory root t))))

(ert-deftest emacs-config/c-default-build-command-detects-cmake-build-dir ()
  (let* ((root (file-name-as-directory (make-temp-file "emacs-config-test-" t)))
         (build-dir (expand-file-name "build" root)))
    (unwind-protect
        (progn
          (make-directory build-dir)
          (write-region "" nil (expand-file-name "Makefile" build-dir)
                        nil 'silent)
          (let ((default-directory root))
            (should (equal (my/c-default-compile-command)
                           "cmake --build build"))))
      (delete-directory root t))))

(ert-deftest emacs-config/c-file-associations-cover-adjacent-tooling-files ()
  (dolist (case '(("main.S" . asm-mode)
                  ("linker.ld" . ld-script-mode)
                  ("debug.gdb" . gdb-script-mode)
                  ("Kconfig" . conf-mode)))
    (should (eq (cdr case)
                (assoc-default (car case) auto-mode-alist #'string-match-p)))))

;;; Verilog and SystemVerilog development environment
(ert-deftest emacs-config/verilog-helper-mode-is-available ()
  (should (require 'verilog-mode nil t)))

(ert-deftest emacs-config/verilog-mode-enables-development-defaults ()
  (with-temp-buffer
    (verilog-mode)
    (should (= verilog-indent-level my/verilog-basic-offset))
    (should (= verilog-indent-level-module my/verilog-basic-offset))
    (should (= verilog-indent-level-declaration my/verilog-basic-offset))
    (should (= verilog-indent-level-behavioral my/verilog-basic-offset))
    (should (= verilog-case-indent my/verilog-basic-offset))
    (should (= tab-width my/verilog-basic-offset))
    (should (= fill-column my/verilog-fill-column))
    (should (not indent-tabs-mode))
    (should show-trailing-whitespace)
    (should (bound-and-true-p flymake-mode))
    (should (not my/verilog-format-on-save))
    (should (memq #'my/verilog-format-before-save before-save-hook))
    (should (eq (local-key-binding (kbd "C-c b")) 'my/verilog-build))
    (should (eq (local-key-binding (kbd "C-c l")) 'my/verilog-lint))
    (should (eq (local-key-binding (kbd "C-c f"))
                'my/verilog-format-region-or-buffer))
    (should (eq (local-key-binding (kbd "C-c e")) 'eglot))
    (should (eq (local-key-binding (kbd "C-c C-a")) 'verilog-auto))))

(ert-deftest emacs-config/verilog-default-build-command-detects-make ()
  (let ((root (file-name-as-directory (make-temp-file "emacs-config-test-" t))))
    (unwind-protect
        (progn
          (write-region "" nil (expand-file-name "Makefile" root) nil 'silent)
          (let ((default-directory root))
            (should (equal (my/verilog-default-build-command) "make -k"))))
      (delete-directory root t))))

(ert-deftest emacs-config/verilog-lint-command-prefers-common-tools ()
  (let ((buffer-file-name "/tmp/top.sv"))
    (cl-letf (((symbol-function 'executable-find)
               (lambda (command)
                 (and (string= command "verible-verilog-lint") command))))
      (should (equal (my/verilog-lint-command)
                     '("verible-verilog-lint" "/tmp/top.sv"))))
    (cl-letf (((symbol-function 'executable-find)
               (lambda (command)
                 (and (string= command "verilator") command))))
      (should (equal (my/verilog-lint-command)
                     '("verilator" "--lint-only" "-Wall" "/tmp/top.sv"))))
    (cl-letf (((symbol-function 'executable-find)
               (lambda (command)
                 (and (string= command "iverilog") command))))
      (should (equal (my/verilog-lint-command)
                     '("iverilog" "-Wall" "-tnull" "/tmp/top.sv"))))))

(ert-deftest emacs-config/verilog-language-server-command-selects-installed-server ()
  (let ((my/verilog-language-server-commands
         '(("verible-verilog-ls") ("svlangserver" "--stdio"))))
    (cl-letf (((symbol-function 'executable-find)
               (lambda (command)
                 (and (string= command "svlangserver") command))))
      (should (equal (my/verilog-language-server-command)
                     '("svlangserver" "--stdio"))))))

(ert-deftest emacs-config/verilog-file-associations-cover-hdl-files ()
  (dolist (case '(("rtl/top.v" . verilog-mode)
                  ("rtl/top.vh" . verilog-mode)
                  ("rtl/top.sv" . verilog-mode)
                  ("rtl/top.svh" . verilog-mode)
                  ("rtl/assertions.sva" . verilog-mode)))
    (should (eq (cdr case)
                (assoc-default (car case) auto-mode-alist #'string-match-p)))))

;;; SQL development environment
(ert-deftest emacs-config/sql-helper-packages-are-installed ()
  (dolist (feature '(sql sqlformat sqlup-mode sql-indent))
    (should (require feature nil t))))

(ert-deftest emacs-config/setup-installs-sql-helper-packages ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name "scripts/setup.el"
                                            emacs-config-test-root))
    (dolist (package '(sqlformat sqlup-mode sql-indent))
      (should (search-forward (symbol-name package) nil t)))))

(ert-deftest emacs-config/sql-mode-enables-query-editing-defaults ()
  (with-temp-buffer
    (sql-mode)
    (should (eq sql-product my/sql-default-product))
    (should (= fill-column my/sql-fill-column))
    (should (not indent-tabs-mode))
    (should (= tab-width 2))
    (should show-trailing-whitespace)
    (should (bound-and-true-p sqlup-mode))
    (should (bound-and-true-p sqlind-minor-mode))
    (should (eq (local-key-binding (kbd "C-c C-c"))
                'my/sql-send-region-or-buffer))
    (should (eq (local-key-binding (kbd "C-c C-r")) 'sql-send-region))
    (should (eq (local-key-binding (kbd "C-c C-b")) 'sql-send-buffer))
    (should (eq (local-key-binding (kbd "C-c C-p")) 'sql-set-product))
    (should (eq (local-key-binding (kbd "C-c C-f"))
                'my/sql-format-region-or-buffer))
    (should (eq (local-key-binding (kbd "C-c C-z")) 'sql-show-sqli-buffer))))

(ert-deftest emacs-config/sql-global-prefix-keys-are-bound ()
  (should (eq (lookup-key global-map (kbd "C-c s c")) 'my/sql-connect))
  (should (eq (lookup-key global-map (kbd "C-c s i"))
              'sql-product-interactive))
  (should (eq (lookup-key global-map (kbd "C-c s s")) 'my/sql-scratch))
  (should (eq (lookup-key global-map (kbd "C-c s e"))
              'my/sql-copy-region-to-scratch))
  (should (eq (lookup-key global-map (kbd "C-c s f"))
              'my/sql-format-region-or-buffer)))

(ert-deftest emacs-config/sql-file-associations-cover-common-query-files ()
  (dolist (case '(("query.sql" . sql-mode)
                  ("migration.pgsql" . sql-mode)
                  ("scratch.sqlite" . sql-mode)
                  ("schema.ddl" . sql-mode)
                  ("seed.dml" . sql-mode)))
    (should (eq (cdr case)
                (assoc-default (car case) auto-mode-alist #'string-match-p)))))

(ert-deftest emacs-config/sql-history-file-lives-under-runtime-var ()
  (should (equal sql-input-ring-file-name my/sql-history-file))
  (should (string-prefix-p (expand-file-name "var/" emacs-config-test-root)
                           my/sql-history-file)))

(ert-deftest emacs-config/sql-eglot-uses-configured-language-server ()
  (let ((entry (assoc 'sql-mode eglot-server-programs)))
    (should entry)
    (should (equal (cdr entry) '("sqls")))))

;;; Rust development environment
(ert-deftest emacs-config/rust-helper-packages-are-installed ()
  (dolist (feature '(rust-mode eglot))
    (should (require feature nil t))))

(ert-deftest emacs-config/setup-installs-rust-helper-packages ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name "scripts/setup.el"
                                            emacs-config-test-root))
    (should (search-forward "rust-mode" nil t))))

(ert-deftest emacs-config/rust-mode-enables-development-defaults ()
  (with-temp-buffer
    (rust-mode)
    (should (= rust-indent-offset my/rust-basic-offset))
    (should (= tab-width my/rust-basic-offset))
    (should (= fill-column my/rust-fill-column))
    (should (not indent-tabs-mode))
    (should show-trailing-whitespace)
    (should (bound-and-true-p flymake-mode))
    (should (memq #'my/rust-format-before-save before-save-hook))
    (should my/rust-format-on-save)
    (should (eq (local-key-binding (kbd "C-c b")) 'my/rust-cargo-build))
    (should (eq (local-key-binding (kbd "C-c c")) 'my/rust-cargo-check))
    (should (eq (local-key-binding (kbd "C-c l")) 'my/rust-cargo-clippy))
    (should (eq (local-key-binding (kbd "C-c f")) 'my/rust-format-buffer))
    (should (eq (local-key-binding (kbd "C-c F")) 'my/rust-cargo-fmt))
    (should (eq (local-key-binding (kbd "C-c r")) 'my/rust-cargo-run))
    (should (eq (local-key-binding (kbd "C-c t")) 'my/rust-cargo-test))
    (should (eq (local-key-binding (kbd "C-c C-c")) 'my/rust-cargo))
    (should (eq (local-key-binding (kbd "C-c e")) 'eglot))))

(ert-deftest emacs-config/rust-cargo-root-detects-nearest-cargo-toml ()
  (let* ((root (file-name-as-directory (make-temp-file "emacs-config-test-" t)))
         (src (expand-file-name "src" root)))
    (unwind-protect
        (progn
          (make-directory src)
          (write-region "[package]\nname = \"demo\"\nversion = \"0.1.0\"\n"
                        nil (expand-file-name "Cargo.toml" root) nil 'silent)
          (let ((default-directory src))
            (should (equal (file-truename (my/rust-cargo-root))
                           (file-truename root)))))
      (delete-directory root t))))

(ert-deftest emacs-config/rust-cargo-command-line-quotes-cargo-binary ()
  (let ((my/rust-cargo-command "/path with spaces/cargo"))
    (should (equal (my/rust-cargo-command-line "check")
                   "/path\\ with\\ spaces/cargo check"))))

(ert-deftest emacs-config/rust-eglot-uses-rust-analyzer ()
  (let ((entry (assoc '(rust-mode rust-ts-mode) eglot-server-programs)))
    (should entry)
    (should (equal (cdr entry) '("rust-analyzer")))))

(ert-deftest emacs-config/rust-file-associations-cover-rust-and-cargo-files ()
  (should (eq (assoc-default "lib.rs" auto-mode-alist #'string-match-p)
              'rust-mode))
  (should (eq (assoc-default "Cargo.toml" auto-mode-alist #'string-match-p)
              'conf-toml-mode)))

(ert-deftest emacs-config/rust-tree-sitter-sources-are-registered ()
  (when (boundp 'treesit-language-source-alist)
    (should (assoc 'rust treesit-language-source-alist))
    (should (assoc 'toml treesit-language-source-alist))))

;;; JavaScript and TypeScript development environment
(ert-deftest emacs-config/js-helper-packages-are-installed ()
  (dolist (feature '(typescript-mode web-mode json-mode add-node-modules-path eglot))
    (should (require feature nil t))))

(ert-deftest emacs-config/setup-installs-js-helper-packages ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name "scripts/setup.el"
                                            emacs-config-test-root))
    (dolist (package '("typescript-mode"
                       "web-mode"
                       "json-mode"
                       "add-node-modules-path"))
      (should (search-forward package nil t)))))

(ert-deftest emacs-config/js-mode-enables-development-defaults ()
  (with-temp-buffer
    (js-mode)
    (should (= js-indent-level my/js-basic-offset))
    (should (= tab-width my/js-basic-offset))
    (should (= fill-column my/js-fill-column))
    (should (not indent-tabs-mode))
    (should show-trailing-whitespace)
    (should (bound-and-true-p flymake-mode))
    (should (memq #'my/js-format-before-save before-save-hook))
    (should my/js-format-on-save)
    (should (eq (local-key-binding (kbd "C-c b")) 'my/js-build))
    (should (eq (local-key-binding (kbd "C-c c")) 'my/js-run-script))
    (should (eq (local-key-binding (kbd "C-c e")) 'eglot))
    (should (eq (local-key-binding (kbd "C-c f"))
                'my/js-format-region-or-buffer))
    (should (eq (local-key-binding (kbd "C-c i")) 'my/js-install))
    (should (eq (local-key-binding (kbd "C-c l")) 'my/js-lint))
    (should (eq (local-key-binding (kbd "C-c r")) 'my/js-start))
    (should (eq (local-key-binding (kbd "C-c t")) 'my/js-test))))

(ert-deftest emacs-config/typescript-mode-enables-development-defaults ()
  (with-temp-buffer
    (typescript-mode)
    (should (= typescript-indent-level my/js-basic-offset))
    (should (= tab-width my/js-basic-offset))
    (should (memq #'my/js-format-before-save before-save-hook))
    (should (eq (local-key-binding (kbd "C-c b")) 'my/js-build))))

(ert-deftest emacs-config/js-project-root-detects-package-json ()
  (let* ((root (file-name-as-directory (make-temp-file "emacs-config-test-" t)))
         (src (expand-file-name "src" root)))
    (unwind-protect
        (progn
          (make-directory src)
          (write-region "{\"scripts\":{\"test\":\"node test.js\"}}\n"
                        nil (expand-file-name "package.json" root) nil 'silent)
          (let ((default-directory src))
            (should (equal (file-truename (my/js-project-root))
                           (file-truename root)))))
      (delete-directory root t))))

(ert-deftest emacs-config/js-package-manager-detects-lockfiles ()
  (let ((root (file-name-as-directory (make-temp-file "emacs-config-test-" t))))
    (unwind-protect
        (let ((default-directory root))
          (write-region "{}\n" nil (expand-file-name "package.json" root)
                        nil 'silent)
          (should (equal (my/js-detect-package-manager) "npm"))
          (write-region "" nil (expand-file-name "pnpm-lock.yaml" root)
                        nil 'silent)
          (should (equal (my/js-detect-package-manager) "pnpm")))
      (delete-directory root t))))

(ert-deftest emacs-config/js-package-script-command-uses-detected-manager ()
  (let ((my/js-package-manager "npm"))
    (should (equal (my/js-package-script-command "build")
                   "npm run build")))
  (let ((my/js-package-manager "yarn"))
    (should (equal (my/js-package-script-command "test:unit")
                   "yarn test\\:unit"))))

(ert-deftest emacs-config/js-eglot-uses-typescript-language-server ()
  (let ((entry (assoc '(js-mode js-ts-mode js-jsx-mode
                               typescript-mode typescript-ts-mode
                               tsx-ts-mode web-mode)
                      eglot-server-programs)))
    (should entry)
    (should (equal (cdr entry)
                   '("typescript-language-server" "--stdio")))))

(ert-deftest emacs-config/js-file-associations-cover-js-ts-json-files ()
  (should (memq (assoc-default "index.js" auto-mode-alist #'string-match-p)
                '(js-mode js-ts-mode)))
  (should (memq (assoc-default "component.jsx" auto-mode-alist #'string-match-p)
                '(js-jsx-mode js-ts-mode)))
  (should (memq (assoc-default "app.ts" auto-mode-alist #'string-match-p)
                '(typescript-mode typescript-ts-mode)))
  (should (memq (assoc-default "view.tsx" auto-mode-alist #'string-match-p)
                '(web-mode tsx-ts-mode)))
  (should (memq (assoc-default "package.json" auto-mode-alist #'string-match-p)
                '(json-mode json-ts-mode))))

(ert-deftest emacs-config/js-tree-sitter-sources-are-registered ()
  (when (boundp 'treesit-language-source-alist)
    (dolist (language '(javascript typescript tsx json))
      (should (assoc language treesit-language-source-alist)))))

;;; Markup and data-file editing environment
(ert-deftest emacs-config/markup-helper-packages-are-installed ()
  (dolist (feature '(markdown-mode yaml-mode mermaid-mode eglot))
    (should (require feature nil t))))

(ert-deftest emacs-config/setup-installs-markup-helper-packages ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name "scripts/setup.el"
                                            emacs-config-test-root))
    (dolist (package '("markdown-mode" "yaml-mode" "mermaid-mode"))
      (should (search-forward package nil t)))))

(ert-deftest emacs-config/markdown-mode-enables-documentation-defaults ()
  (with-temp-buffer
    (markdown-mode)
    (should (= fill-column my/markup-fill-column))
    (should (= tab-width my/markup-basic-offset))
    (should (not indent-tabs-mode))
    (should (bound-and-true-p visual-line-mode))
    (should markdown-fontify-code-blocks-natively)
    (should (assoc "mermaid" markdown-code-lang-modes))
    (should (eq (local-key-binding (kbd "C-c f"))
                'my/markup-fill-region-or-paragraph))
    (should (eq (local-key-binding (kbd "C-c p"))
                'my/markup-markdown-preview))))

(ert-deftest emacs-config/markdown-preview-refreshes-missing-renderer-command ()
  (with-temp-buffer
    (markdown-mode)
    (let ((markdown-command "definitely-not-a-markdown-renderer"))
      (if (my/markup-detect-markdown-command)
          (progn
            (my/markup-ensure-markdown-command)
            (should (my/markup-markdown-command-available-p markdown-command)))
        (should-not (my/markup-markdown-command-available-p markdown-command))))))

(ert-deftest emacs-config/json-mode-keeps-prettier-and-adds-json-helpers ()
  (with-temp-buffer
    (json-mode)
    (should (= tab-width my/markup-basic-offset))
    (should (eq (local-key-binding (kbd "C-c f"))
                'my/js-format-region-or-buffer))
    (should (eq (local-key-binding (kbd "C-c j"))
                'my/markup-json-jq-region-or-buffer))
    (should (eq (local-key-binding (kbd "C-c e")) 'eglot))))

(ert-deftest emacs-config/yaml-mode-enables-config-file-defaults ()
  (with-temp-buffer
    (yaml-mode)
    (should (= fill-column my/markup-fill-column))
    (should (= tab-width my/markup-basic-offset))
    (should (not indent-tabs-mode))
    (should show-trailing-whitespace)
    (should (bound-and-true-p flymake-mode))
    (should (eq (local-key-binding (kbd "C-c f"))
                'my/markup-yaml-format-region-or-buffer))
    (should (eq (local-key-binding (kbd "C-c e")) 'eglot))))

(ert-deftest emacs-config/mermaid-mode-enables-render-command ()
  (let ((file (make-temp-file "emacs-config-diagram-" nil ".mmd")))
    (unwind-protect
        (with-temp-buffer
          (set-visited-file-name file t t)
          (mermaid-mode)
          (should (= fill-column my/markup-fill-column))
          (should (= tab-width my/markup-basic-offset))
          (should (not indent-tabs-mode))
          (should (string-match-p "\\bmmdc\\b" compile-command))
          (should (string-match-p "\\.svg\\b" compile-command))
          (should (string-match-p "\\.svg\\b"
                                  (my/markup-mermaid-compile-command)))
          (should (eq (local-key-binding (kbd "C-c c"))
                      'my/markup-mermaid-compile)))
      (delete-file file))))

(ert-deftest emacs-config/markup-eglot-uses-json-and-yaml-language-servers ()
  (let ((json-entry (assoc '(json-mode json-ts-mode) eglot-server-programs))
        (yaml-entry (assoc '(yaml-mode yaml-ts-mode) eglot-server-programs)))
    (should json-entry)
    (should yaml-entry)
    (should (equal (cdr json-entry) my/markup-json-language-server-command))
    (should (equal (cdr yaml-entry) my/markup-yaml-language-server-command))))

(ert-deftest emacs-config/markup-file-associations-cover-docs-and-configs ()
  (should (memq (assoc-default "README.md" auto-mode-alist #'string-match-p)
                '(gfm-mode markdown-mode)))
  (should (eq (assoc-default "notes.markdown" auto-mode-alist #'string-match-p)
              'markdown-mode))
  (should (memq (assoc-default "workflow.yml" auto-mode-alist #'string-match-p)
                '(yaml-mode yaml-ts-mode)))
  (should (memq (assoc-default ".clang-format" auto-mode-alist #'string-match-p)
                '(yaml-mode yaml-ts-mode)))
  (should (eq (assoc-default "architecture.mmd" auto-mode-alist #'string-match-p)
              'mermaid-mode))
  (should (eq (assoc-default "sequence.mermaid" auto-mode-alist #'string-match-p)
              'mermaid-mode)))

(ert-deftest emacs-config/markup-tree-sitter-sources-are-registered ()
  (when (boundp 'treesit-language-source-alist)
    (should (assoc 'yaml treesit-language-source-alist))))

;;; Python development environment
(ert-deftest emacs-config/python-helper-packages-are-installed ()
  (dolist (feature '(python pyvenv pip-requirements eglot))
    (should (require feature nil t))))

(ert-deftest emacs-config/setup-installs-python-helper-packages ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name "scripts/setup.el"
                                            emacs-config-test-root))
    (dolist (package '("pyvenv" "pip-requirements"))
      (should (search-forward package nil t)))))

(ert-deftest emacs-config/python-mode-enables-development-defaults ()
  (with-temp-buffer
    (python-mode)
    (should (= python-indent-offset my/python-basic-offset))
    (should (= tab-width my/python-basic-offset))
    (should (= fill-column my/python-fill-column))
    (should (not indent-tabs-mode))
    (should show-trailing-whitespace)
    (should (bound-and-true-p flymake-mode))
    (should (memq #'my/python-format-before-save before-save-hook))
    (should my/python-format-on-save)
    (should (eq (local-key-binding (kbd "C-c b")) 'my/python-compile-file))
    (should (eq (local-key-binding (kbd "C-c c")) 'my/python-check))
    (should (eq (local-key-binding (kbd "C-c e")) 'eglot))
    (should (eq (local-key-binding (kbd "C-c f"))
                'my/python-format-region-or-buffer))
    (should (eq (local-key-binding (kbd "C-c i")) 'my/python-repl))
    (should (eq (local-key-binding (kbd "C-c r")) 'my/python-run-file))
    (should (eq (local-key-binding (kbd "C-c t")) 'my/python-test))
    (should (eq (local-key-binding (kbd "C-c T")) 'my/python-test-file))
    (should (eq (local-key-binding (kbd "C-c v")) 'my/python-activate-venv))
    (should (eq (local-key-binding (kbd "C-c V")) 'pyvenv-deactivate))))

(ert-deftest emacs-config/python-project-root-detects-pyproject ()
  (let* ((root (file-name-as-directory (make-temp-file "emacs-config-test-" t)))
         (package-dir (expand-file-name "src/demo" root)))
    (unwind-protect
        (progn
          (make-directory package-dir t)
          (write-region "[project]\nname = \"demo\"\n"
                        nil (expand-file-name "pyproject.toml" root)
                        nil 'silent)
          (let ((default-directory package-dir))
            (should (equal (file-truename (my/python-project-root))
                           (file-truename root)))))
      (delete-directory root t))))

(ert-deftest emacs-config/python-venv-root-detects-project-venv ()
  (let* ((root (file-name-as-directory (make-temp-file "emacs-config-test-" t)))
         (venv (expand-file-name ".venv" root)))
    (unwind-protect
        (progn
          (write-region "[project]\nname = \"demo\"\n"
                        nil (expand-file-name "pyproject.toml" root)
                        nil 'silent)
          (make-directory (expand-file-name "bin" venv) t)
          (let ((default-directory root))
            (should (equal (file-truename (my/python-venv-root))
                           (file-truename venv)))))
      (delete-directory root t))))

(ert-deftest emacs-config/python-tool-command-prefers-module-fallback ()
  (let* ((root (file-name-as-directory (make-temp-file "emacs-config-test-" t)))
         (my/python-default-interpreter "/path with spaces/python"))
    (unwind-protect
        (let ((default-directory root)
              (exec-path nil))
          (write-region "[project]\nname = \"demo\"\n"
                        nil (expand-file-name "pyproject.toml" root)
                        nil 'silent)
          (should (equal (my/python-tool-command "pytest")
                         '("/path with spaces/python" "-m" "pytest")))
          (should (equal (my/python-command-line
                          (my/python-tool-command "pytest"))
                         "/path\\ with\\ spaces/python -m pytest")))
      (delete-directory root t))))

(ert-deftest emacs-config/python-eglot-registers-dynamic-language-server ()
  (let ((entry (assoc '(python-mode python-ts-mode) eglot-server-programs)))
    (should entry)
    (should (functionp (cdr entry)))
    (should (member (funcall (cdr entry) nil nil)
                    my/python-language-server-commands))))

(ert-deftest emacs-config/python-file-associations-cover-python-project-files ()
  (should (memq (assoc-default "module.py" auto-mode-alist #'string-match-p)
                '(python-mode python-ts-mode)))
  (should (memq (assoc-default "types.pyi" auto-mode-alist #'string-match-p)
                '(python-mode python-ts-mode)))
  (should (eq (assoc-default "requirements.txt" auto-mode-alist #'string-match-p)
              'pip-requirements-mode))
  (should (eq (assoc-default "constraints-dev.txt" auto-mode-alist #'string-match-p)
              'pip-requirements-mode))
  (should (memq (assoc-default "Pipfile" auto-mode-alist #'string-match-p)
                '(conf-toml-mode toml-ts-mode))))

(ert-deftest emacs-config/python-tree-sitter-source-is-registered ()
  (when (boundp 'treesit-language-source-alist)
    (should (assoc 'python treesit-language-source-alist))))

;;; Tree-sitter grammar management
(ert-deftest emacs-config/treesit-management-commands-are-bound ()
  (should (eq (lookup-key global-map (kbd "C-c l s")) 'my/treesit-status))
  (should (eq (lookup-key global-map (kbd "C-c l i"))
              'my/treesit-install-language))
  (should (eq (lookup-key global-map (kbd "C-c l a"))
              'my/treesit-install-missing-grammars)))

(ert-deftest emacs-config/treesit-management-sees-registered-languages ()
  (when (my/treesit-available-p)
    (dolist (language '(c cpp cmake javascript json python rust toml tsx typescript yaml))
      (should (assoc language my/treesit-default-language-sources)))
    (dolist (language '(c cpp rust javascript typescript json yaml python))
      (should (memq language (my/treesit-configured-languages))))))

(when noninteractive
  (ert-run-tests-batch-and-exit))

;;; init-test.el ends here
