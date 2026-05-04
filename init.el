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

(use-package helpful
  :bind (("C-h f" . helpful-callable)
         ("C-h v" . helpful-variable)
         ("C-h k" . helpful-key)
         ("C-h x" . helpful-command)
         ("C-c h" . helpful-at-point)))

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

(use-package eldoc
  :ensure nil
  :custom
  (eldoc-idle-delay 0.2)
  (eldoc-echo-area-use-multiline-p nil))

(use-package flymake
  :ensure nil
  :demand t
  :bind (:map flymake-mode-map
              ("M-n" . flymake-goto-next-error)
              ("M-p" . flymake-goto-prev-error)))

(use-package paredit
  :hook ((emacs-lisp-mode lisp-interaction-mode ielm-mode) . paredit-mode))

(use-package rainbow-delimiters
  :hook ((emacs-lisp-mode lisp-interaction-mode ielm-mode)
         . rainbow-delimiters-mode))

(use-package aggressive-indent
  :hook ((emacs-lisp-mode lisp-interaction-mode) . aggressive-indent-mode))

(use-package eros
  :hook ((emacs-lisp-mode lisp-interaction-mode) . eros-mode))

(use-package macrostep
  :commands macrostep-expand)

(use-package package-lint
  :commands (package-lint-current-buffer package-lint-flymake-setup)
  :hook (emacs-lisp-mode . package-lint-flymake-setup))

(defun my/emacs-lisp-mode-setup ()
  "Enable the built-in interactive tooling for Emacs Lisp buffers."
  (setq-local indent-tabs-mode nil)
  (eldoc-mode 1)
  (flymake-mode 1))

(use-package elisp-mode
  :ensure nil
  :hook ((emacs-lisp-mode lisp-interaction-mode) . my/emacs-lisp-mode-setup)
  :bind (:map emacs-lisp-mode-map
              ("C-c C-b" . eval-buffer)
              ("C-c C-c" . eval-defun)
              ("C-c C-k" . check-parens)
              ("C-c C-l" . package-lint-current-buffer)
              ("C-c C-m" . macrostep-expand)
              ("C-c C-z" . ielm)
              :map lisp-interaction-mode-map
              ("C-c C-b" . eval-buffer)
              ("C-c C-c" . eval-defun)
              ("C-c C-k" . check-parens)
              ("C-c C-m" . macrostep-expand)
              ("C-c C-z" . ielm)))

;; Keep Custom settings out of init.el so hand-written config stays tidy.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

(provide 'init)

;;; init.el ends here
