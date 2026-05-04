;;; config-navigation.el --- Bookmarks and registers -*- lexical-binding: t; -*-

;;; Commentary:
;; Bookmarks and registers are old-school Emacs superpowers: they make it cheap
;; to keep named places, snippets, and window layouts close at hand without
;; adding a separate navigation framework. This module gives those built-ins a
;; memorable prefix and stores bookmark state under var/ so the repository stays
;; clean.

;;; Code:

(require 'bookmark)
(require 'register)
(require 'config-editing)
(require 'use-package)

(defcustom my/navigation-prefix "C-c n"
  "Global prefix for bookmark and register navigation commands."
  :type 'string
  :group 'convenience)

(defcustom my/navigation-bookmark-file
  (expand-file-name "bookmarks" my/editing-var-directory)
  "File where Emacs saves interactive bookmarks."
  :type 'file
  :group 'convenience)

(defcustom my/navigation-register-preview-delay 0.4
  "Delay before Emacs previews register contents during register commands."
  :type 'number
  :group 'convenience)

(defun my/navigation-ensure-runtime-directory ()
  "Create the directory that holds navigation runtime files."
  (make-directory (file-name-directory my/navigation-bookmark-file) t))

(my/navigation-ensure-runtime-directory)

(use-package bookmark
  :ensure nil
  :bind (("C-c n b" . bookmark-set)
         ("C-c n j" . bookmark-jump)
         ("C-c n l" . list-bookmarks)
         ("C-c n d" . bookmark-delete)
         ("C-c n R" . bookmark-rename)
         ("C-c n S" . bookmark-save))
  :config
  ;; Saving after each bookmark change makes bookmarks dependable across GUI,
  ;; terminal, and agent-launched Emacs sessions.
  (setq bookmark-default-file my/navigation-bookmark-file
        bookmark-save-flag 1))

(use-package register
  :ensure nil
  :bind (("C-c n s" . point-to-register)
         ("C-c n r" . jump-to-register)
         ("C-c n v" . view-register)
         ("C-c n i" . insert-register)
         ("C-c n x" . copy-to-register)
         ("C-c n a" . append-to-register)
         ("C-c n w" . window-configuration-to-register)
         ("C-c n f" . frameset-to-register))
  :config
  ;; Register previews teach the user what they saved without forcing a trip to
  ;; `view-register' first.
  (when (boundp 'register-preview-delay)
    (setq register-preview-delay my/navigation-register-preview-delay)))

(provide 'config-navigation)

;;; config-navigation.el ends here
