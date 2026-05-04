;;; tahoma-tools.el --- Terminal and version-control tools -*- lexical-binding: t; -*-

;;; Commentary:
;; Keep interactive tools outside init.el so the startup file remains a small
;; orchestration layer. vterm supports terminal TUIs; Magit is the review and
;; staging cockpit.

;;; Code:

(require 'use-package)
(require 'tahoma-project)

(defun my/vterm-project ()
  "Open `vterm' in the current project root."
  (interactive)
  (let ((default-directory (my/project-root)))
    (vterm)))

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

(provide 'tahoma-tools)

;;; tahoma-tools.el ends here
