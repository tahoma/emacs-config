;;; init.el --- Small vanilla Emacs starter config -*- lexical-binding: t; -*-

;;; Commentary:
;; This file intentionally avoids Spacemacs. It keeps Emacs close to stock
;; while enabling a few practical built-in defaults.

;;; Code:

(require 'package)

(setq package-archives
      '(("gnu" . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa" . "https://melpa.org/packages/")))

(setq package-archive-priorities
      '(("gnu" . 20)
        ("nongnu" . 10)
        ("melpa" . 0)))

(package-initialize)

(unless (require 'use-package nil t)
  (unless package-archive-contents
    (package-refresh-contents))
  (package-install 'use-package)
  (require 'use-package))

(setq use-package-always-ensure t)

(setq inhibit-startup-screen t)
(setq ring-bell-function 'ignore)

(when (fboundp 'menu-bar-mode)
  (menu-bar-mode -1))
(when (fboundp 'tool-bar-mode)
  (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode -1))

(global-display-line-numbers-mode 1)
(savehist-mode 1)
(recentf-mode 1)
(electric-pair-mode 1)

(require 'project)

(defun my/project-root ()
  "Return the current project root, or `default-directory'."
  (let ((project (project-current nil)))
    (if project
        (project-root project)
      default-directory)))

(defun my/vterm-project ()
  "Open `vterm' in the current project root."
  (interactive)
  (let ((default-directory (my/project-root)))
    (vterm)))

(use-package vterm
  :init
  (setq vterm-always-compile-module t)
  :commands (vterm my/vterm-project)
  :bind (("C-c t" . vterm)
         ("C-c T" . my/vterm-project))
  :custom
  (vterm-max-scrollback 10000))

(use-package magit
  :bind ("C-c g" . magit-status))

;; Keep Custom settings out of init.el so hand-written config stays tidy.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

(provide 'init)

;;; init.el ends here
