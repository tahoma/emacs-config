;;; config-tools.el --- Shell, terminal, and version-control tools -*- lexical-binding: t; -*-

;;; Commentary:
;; Keep interactive tools outside init.el so the startup file remains a small
;; orchestration layer. GUI Emacs also needs the same shell environment as a
;; terminal-launched Emacs, otherwise Homebrew and language-tool binaries can be
;; invisible to package helpers such as Markdown preview.

;;; Code:

(require 'use-package)
(require 'config-project)

(defvar exec-path-from-shell-variables)

(defcustom my/tools-shell-environment-variables '("PATH" "MANPATH" "SHELL")
  "Shell environment variables imported into GUI Emacs sessions."
  :type '(repeat string)
  :group 'tools)

(defun my/tools-import-shell-environment-p ()
  "Return non-nil when Emacs should import login-shell environment variables."
  (or (memq window-system '(mac ns x))
      (daemonp)))

(defun my/tools-import-shell-environment ()
  "Import shell environment variables when running outside a login shell."
  (when (and (my/tools-import-shell-environment-p)
             (fboundp 'exec-path-from-shell-initialize))
    (exec-path-from-shell-initialize)))

(defun my/vterm-project ()
  "Open `vterm' in the current project root."
  (interactive)
  (let ((default-directory (my/project-root)))
    (vterm)))

;; macOS GUI apps do not inherit the user's login-shell PATH. Importing it here
;; keeps Homebrew-installed tools visible to Markdown preview, language servers,
;; formatters, and any compile command spawned by Emacs.app.
(use-package exec-path-from-shell
  :init
  (setq exec-path-from-shell-variables my/tools-shell-environment-variables)
  :config
  (my/tools-import-shell-environment))

;; vterm gives Codex and other terminal TUIs a real terminal inside Emacs.
;; Compile its native module during setup/load so first use does not stop for an
;; interactive prompt.
(use-package vterm
  :init
  (setq vterm-always-compile-module t)
  :commands (vterm my/vterm-project)
  :bind (("C-c t" . vterm)
         ("C-c T" . my/vterm-project))
  :custom
  (vterm-max-scrollback 10000))

;; Magit is useful both for this config repo and for any codebase edited from
;; Emacs.
(use-package magit
  :bind ("C-c g" . magit-status))

(provide 'config-tools)

;;; config-tools.el ends here
