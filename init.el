;;; init.el --- Small vanilla Emacs starter config -*- lexical-binding: t; -*-

;;; Commentary:
;; This file intentionally avoids Spacemacs. It keeps Emacs close to stock
;; while enabling a few practical built-in defaults.

;;; Code:

;;; Package management
;; Keep package setup explicit so a fresh clone behaves like a normal Emacs
;; config, while still allowing MELPA packages where the built-in archives do
;; not have what this setup needs.
(require 'package)

(setq package-archives
      '(("gnu" . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa" . "https://melpa.org/packages/")))

;; Prefer official archives when a package exists in more than one place, and
;; use MELPA as the wider ecosystem fallback.
(setq package-archive-priorities
      '(("gnu" . 20)
        ("nongnu" . 10)
        ("melpa" . 0)))

(package-initialize)

;; Emacs 30 ships use-package, but older supported installs may not. Bootstrap
;; it here so the rest of the config can use one declarative package shape.
(unless (require 'use-package nil t)
  (unless package-archive-contents
    (package-refresh-contents))
  (package-install 'use-package)
  (require 'use-package))

;; This config is small enough that package declarations should install their
;; dependencies automatically instead of requiring a separate package list in
;; init.el. Fresh-machine setup still has an explicit package list in
;; scripts/setup.el for predictable bootstrapping.
(setq use-package-always-ensure t)

;;; Basic interface defaults
;; Stay close to stock Emacs, but remove the startup friction and visual chrome
;; that get in the way of editing.
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

;;; Help and introspection
;; Helpful keeps the usual help key muscle memory while showing richer source,
;; docstring, and call-site context for symbols.
(use-package helpful
  :bind (("C-h f" . helpful-callable)
         ("C-h v" . helpful-variable)
         ("C-h k" . helpful-key)
         ("C-h x" . helpful-command)
         ("C-c h" . helpful-at-point)))

;;; Project helpers
;; Built-in project.el is enough for this config. The helper gives terminal and
;; future commands one canonical way to find the current project root.
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

;;; Terminal and version control
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

;; Magit is the review/staging cockpit for this config repo and any codebase
;; edited from Emacs.
(use-package magit
  :bind ("C-c g" . magit-status))

;;; Emacs Lisp development
;; Eldoc and Flymake are built in. Load Flymake eagerly because this config
;; binds keys in its mode map and enables it for Lisp buffers.
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

;; Structural editing and visual delimiter depth matter more in Lisp than in
;; most languages; these modes make s-expression edits calmer and clearer.
(use-package paredit
  :hook ((emacs-lisp-mode lisp-interaction-mode ielm-mode) . paredit-mode))

(use-package rainbow-delimiters
  :hook ((emacs-lisp-mode lisp-interaction-mode ielm-mode)
         . rainbow-delimiters-mode))

(use-package aggressive-indent
  :hook ((emacs-lisp-mode lisp-interaction-mode) . aggressive-indent-mode))

;; Eros displays evaluation results inline, which makes iterating on config and
;; small functions faster than hunting through the echo area.
(use-package eros
  :hook ((emacs-lisp-mode lisp-interaction-mode) . eros-mode))

;; Macrostep is the fastest way to inspect what a macro call becomes without
;; leaving the source buffer.
(use-package macrostep
  :commands macrostep-expand)

;; package-lint catches common packaging and metadata issues. Its package also
;; provides the package-lint-flymake backend used by the hook below.
(use-package package-lint
  :commands (package-lint-current-buffer package-lint-flymake-setup)
  :hook (emacs-lisp-mode . package-lint-flymake-setup))

;; Keep the mode hook tiny and local-buffer-oriented so it is easy to extend as
;; this config grows.
(defun my/emacs-lisp-mode-setup ()
  "Enable the built-in interactive tooling for Emacs Lisp buffers."
  (setq-local indent-tabs-mode nil)
  (eldoc-mode 1)
  (flymake-mode 1))

;; Bind the high-frequency Lisp commands in the mode maps rather than globally:
;; evaluate, check structure, lint, expand macros, and jump into IELM.
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
