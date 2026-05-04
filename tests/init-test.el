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
(defvar my/platform-open-bindings-prefix)
(defvar my/platform-preferred-windows-shells)
(defvar my/snippets-directory)
(defvar my/agent-codex-command)
(defvar my/agent-save-project-buffers-before-launch)
(defvar my/debug-dape-buffer-arrangement)
(defvar my/debug-dape-inlay-hints)
(defvar my/tools-shell-environment-variables)
(defvar exec-path-from-shell-variables)
(declare-function my/project-root "config-project")
(declare-function my/tools-import-shell-environment-p "config-tools")
(declare-function my/c-default-compile-command "config-c")
(declare-function my/c-format-buffer "config-c")
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
(declare-function my/agent-codex "config-agent")
(declare-function my/agent-codex-available-p "config-agent")
(declare-function my/agent-codex-with-file "config-agent")
(declare-function my/agent-codex-with-region "config-agent")
(declare-function my/agent-command-line "config-agent")
(declare-function my/agent-copy-file-context "config-agent")
(declare-function my/agent-copy-region-context "config-agent")
(declare-function my/agent-project-vterm "config-agent")
(declare-function my/agent-run-in-project-vterm "config-agent")
(declare-function my/agent-save-project-buffers "config-agent")
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
                     config-platform
                     config-project
                     config-completion
                     config-snippets
                     config-diagnostics
                     config-debug
                     config-environment
                     config-tools
                     config-agent
                     config-elisp
                     config-c
                     config-sql
                     config-rust
                     config-js
                     config-markup
                     config-python))
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
                               "lisp/config-platform.el"
                               "lisp/config-project.el"
                               "lisp/config-completion.el"
                               "lisp/config-snippets.el"
                               "lisp/config-diagnostics.el"
                               "lisp/config-debug.el"
                               "lisp/config-environment.el"
                               "lisp/config-tools.el"
                               "lisp/config-agent.el"
                               "lisp/config-elisp.el"
                               "lisp/config-c.el"
                               "lisp/config-sql.el"
                               "lisp/config-rust.el"
                               "lisp/config-js.el"
                               "lisp/config-markup.el"
                               "lisp/config-python.el"
                               "init.el"
                               "scripts/setup.el"
                               "scripts/compile.el"
                               "tests/init-test.el"))
        (should (search-forward (prin1-to-string relative-file) nil t))))))

(ert-deftest emacs-config/compiled-artifacts-are-ignored ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name ".gitignore" emacs-config-test-root))
    (should (search-forward "*.elc" nil t))))

(ert-deftest emacs-config/make-clean-targets-are-split-by-package-state ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name "Makefile" emacs-config-test-root))
    (let ((makefile (buffer-string)))
      (should (string-match-p "^clean:" makefile))
      (should (string-match-p "^realclean: clean" makefile))
      (should (string-match-p "lisp/config-package\\.elc" makefile))
      (should (string-match-p "lisp/config-editing\\.elc" makefile))
      (should (string-match-p "lisp/config-platform\\.elc" makefile))
      (should (string-match-p "lisp/config-completion\\.elc" makefile))
      (should (string-match-p "lisp/config-snippets\\.elc" makefile))
      (should (string-match-p "lisp/config-diagnostics\\.elc" makefile))
      (should (string-match-p "lisp/config-debug\\.elc" makefile))
      (should (string-match-p "lisp/config-environment\\.elc" makefile))
      (should (string-match-p "lisp/config-agent\\.elc" makefile))
      (should (string-match-p "lisp/config-c\\.elc" makefile))
      (should (string-match-p "lisp/config-sql\\.elc" makefile))
      (should (string-match-p "lisp/config-rust\\.elc" makefile))
      (should (string-match-p "lisp/config-js\\.elc" makefile))
      (should (string-match-p "lisp/config-markup\\.elc" makefile))
      (should (string-match-p "lisp/config-python\\.elc" makefile))
      (should (string-match-p "^PACKAGE_DIRS = .*elpa" makefile))
      (should-not (string-match-p "^RUNTIME_DIRS = .*elpa" makefile)))))

(ert-deftest emacs-config/make-help-target-documents-common-targets ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name "Makefile" emacs-config-test-root))
    (let ((makefile (buffer-string)))
      (should (string-match-p "^\\.DEFAULT_GOAL := help" makefile))
      (should (string-match-p "^\\.PHONY: .*help" makefile))
      (dolist (target '("help" "host" "setup" "test" "compile" "clean" "realclean"))
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
        (should (string-match-p "npm install -g" script))
        (should (string-match-p "pipx ensurepath" script))))))

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

;;; Agentic development workflow
(ert-deftest emacs-config/agent-defaults-are-portable ()
  (should (equal my/agent-codex-command '("codex")))
  (should my/agent-save-project-buffers-before-launch)
  (let ((my/agent-codex-command '("definitely-not-a-real-codex-command")))
    (should-not (my/agent-codex-available-p))))

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

(ert-deftest emacs-config/agent-bindings-are-present ()
  (should (eq (lookup-key global-map (kbd "C-c a a")) 'my/agent-codex))
  (should (eq (lookup-key global-map (kbd "C-c a f"))
              'my/agent-codex-with-file))
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

(when noninteractive
  (ert-run-tests-batch-and-exit))

;;; init-test.el ends here
