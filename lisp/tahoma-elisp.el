;;; tahoma-elisp.el --- Emacs Lisp development environment -*- lexical-binding: t; -*-

;;; Commentary:
;; Make editing this config pleasant: structural editing, inline eval feedback,
;; macro expansion, Eldoc, Flymake, and package-quality linting.

;;; Code:

(require 'use-package)

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

(provide 'tahoma-elisp)

;;; tahoma-elisp.el ends here
