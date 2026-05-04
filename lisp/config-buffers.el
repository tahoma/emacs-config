;;; config-buffers.el --- Buffer list ergonomics -*- lexical-binding: t; -*-

;;; Commentary:
;; Emacs encourages long-running sessions, which means buffer lists quickly
;; become a working set rather than a flat list. Ibuffer is built in, fast, and
;; programmable; this module makes it the default buffer cockpit with stable
;; groups for common development buffers.

;;; Code:

(require 'ibuffer)
(require 'ibuf-ext)
(require 'use-package)

(defcustom my/buffers-ibuffer-filter-groups
  '(("Development"
     (or
      (mode . prog-mode)
      (mode . conf-mode)
      (mode . text-mode)))
    ("Dired"
     (mode . dired-mode))
    ("Magit"
     (or
      (name . "^magit")
      (name . "^\\*magit")))
    ("Terminals"
     (or
      (mode . vterm-mode)
      (mode . term-mode)
      (mode . shell-mode)
      (mode . eshell-mode)))
    ("Help"
     (or
      (mode . help-mode)
      (mode . helpful-mode)
      (mode . Info-mode)))
    ("Emacs"
     (or
      (name . "^\\*Messages\\*")
      (name . "^\\*Warnings\\*")
      (name . "^\\*scratch\\*"))))
  "Saved Ibuffer filter groups for normal development sessions."
  :type 'sexp
  :group 'convenience)

(defun my/buffers-ibuffer-setup ()
  "Apply saved development groups to the current Ibuffer."
  (setq ibuffer-filter-groups my/buffers-ibuffer-filter-groups)
  (unless (eq ibuffer-sorting-mode 'alphabetic)
    (ibuffer-do-sort-by-alphabetic)))

(defun my/buffers-ibuffer ()
  "Open Ibuffer with the configured development groups."
  (interactive)
  (ibuffer)
  (my/buffers-ibuffer-setup))

(use-package ibuffer
  :ensure nil
  :bind (("C-x C-b" . my/buffers-ibuffer)
         ("C-c b b" . my/buffers-ibuffer)
         ("C-c b r" . ibuffer-update))
  :config
  (setq ibuffer-expert t
        ibuffer-show-empty-filter-groups nil
        ibuffer-use-other-window nil)
  (add-hook 'ibuffer-mode-hook #'my/buffers-ibuffer-setup))

(provide 'config-buffers)

;;; config-buffers.el ends here
