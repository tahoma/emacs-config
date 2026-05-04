;;; config-diagnostics.el --- Diagnostics and code navigation -*- lexical-binding: t; -*-

;;; Commentary:
;; Language modules enable Flymake and Eglot where they make sense. This module
;; gives those tools one consistent set of global bindings: C-c ! for
;; diagnostics, and C-c x for code-intelligence navigation and refactoring.
;; Keeping the bindings here avoids every language module inventing its own
;; slightly different way to list errors, jump to symbols, or request a code
;; action.

;;; Code:

(require 'eglot)
(require 'flymake)
(require 'xref)
(require 'use-package)

(declare-function consult-flymake "consult")
(declare-function consult-imenu "consult")
(declare-function consult-imenu-multi "consult")
(declare-function consult-xref "consult")
(declare-function eglot-code-actions "eglot")
(declare-function eglot-managed-p "eglot")
(declare-function eglot-rename "eglot")

(defun my/diagnostics-list ()
  "List diagnostics for the current buffer with Consult and Flymake."
  (interactive)
  (consult-flymake))

(defun my/diagnostics-buffer ()
  "Show the built-in Flymake diagnostics buffer."
  (interactive)
  (flymake-show-buffer-diagnostics))

(defun my/diagnostics-code-actions ()
  "Ask the current Eglot language server for code actions."
  (interactive)
  (if (and (fboundp 'eglot-managed-p) (eglot-managed-p))
      (eglot-code-actions)
    (user-error "Current buffer is not managed by Eglot")))

(defun my/diagnostics-rename ()
  "Rename the symbol at point through the current Eglot language server."
  (interactive)
  (if (and (fboundp 'eglot-managed-p) (eglot-managed-p))
      (call-interactively #'eglot-rename)
    (user-error "Current buffer is not managed by Eglot")))

;; Consult gives xref a completing-read interface with previews, so definition
;; and reference jumps feel like the rest of the minibuffer workflow.
(use-package xref
  :ensure nil
  :custom
  (xref-show-xrefs-function #'consult-xref)
  (xref-show-definitions-function #'consult-xref)
  :config
  (when (boundp 'xref-search-program)
    (setq xref-search-program 'ripgrep)))

;; These bindings intentionally use global prefixes that avoid the per-language
;; C-c e/C-c f/C-c t command sets. They are always available, and local language
;; maps can keep owning their short, workflow-specific keys.
(use-package flymake
  :ensure nil
  :bind (("C-c ! l" . my/diagnostics-list)
         ("C-c ! b" . my/diagnostics-buffer)
         ("C-c ! n" . flymake-goto-next-error)
         ("C-c ! p" . flymake-goto-prev-error)
         :map flymake-mode-map
         ("M-n" . flymake-goto-next-error)
         ("M-p" . flymake-goto-prev-error)))

(use-package eglot
  :ensure nil
  :bind (("C-c x a" . my/diagnostics-code-actions)
         ("C-c x r" . xref-find-references)
         ("C-c x R" . my/diagnostics-rename)
         ("C-c x d" . xref-find-definitions)
         ("C-c x i" . consult-imenu)
         ("C-c x I" . consult-imenu-multi)))

(provide 'config-diagnostics)

;;; config-diagnostics.el ends here
