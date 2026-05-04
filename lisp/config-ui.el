;;; config-ui.el --- Interface and help defaults -*- lexical-binding: t; -*-

;;; Commentary:
;; Stay close to stock Emacs, but remove startup friction and wire better
;; introspection into the familiar help keys.

;;; Code:

(require 'use-package)

;;; Basic interface defaults
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

(provide 'config-ui)

;;; config-ui.el ends here
