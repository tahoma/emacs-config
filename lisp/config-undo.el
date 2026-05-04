;;; config-undo.el --- Visual undo history -*- lexical-binding: t; -*-

;;; Commentary:
;; Plain undo is fast, but complex code edits often need a map of where the
;; buffer has been. Vundo visualizes Emacs' built-in undo tree without replacing
;; the underlying undo system, which makes it a good fit for both GUI and
;; terminal-heavy development workflows.

;;; Code:

(require 'use-package)

(defvar vundo-ascii-symbols)
(defvar vundo-compact-display)
(defvar vundo-glyph-alist)
(defvar vundo-roll-back-on-quit)
(defvar vundo-unicode-symbols)
(defvar vundo-window-max-height)

(defcustom my/undo-vundo-prefix "C-c u"
  "Global prefix for undo-history commands."
  :type 'string
  :group 'convenience)

(defcustom my/undo-vundo-window-max-height 12
  "Maximum height of the Vundo visualization window."
  :type 'integer
  :group 'convenience)

(defun my/undo-vundo-glyph-alist ()
  "Return Vundo glyphs appropriate for the current display."
  (if (display-graphic-p)
      vundo-unicode-symbols
    vundo-ascii-symbols))

(defun my/undo-configure-vundo ()
  "Apply Vundo defaults after the package is available."
  ;; The ASCII fallback keeps terminal and SSH frames legible, while GUI frames
  ;; can use Vundo's richer built-in symbol set.
  (setq vundo-glyph-alist (my/undo-vundo-glyph-alist)
        vundo-compact-display t
        vundo-roll-back-on-quit t
        vundo-window-max-height my/undo-vundo-window-max-height))

(use-package vundo
  :demand t
  :bind (("C-x u" . vundo)
         ("C-c u v" . vundo)
         ("C-c u u" . undo-only)
         ("C-c u r" . undo-redo))
  :config
  (my/undo-configure-vundo))

(provide 'config-undo)

;;; config-undo.el ends here
