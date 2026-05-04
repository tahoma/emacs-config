;;; config-vc.el --- Diff, merge, and VCS ergonomics -*- lexical-binding: t; -*-

;;; Commentary:
;; Magit owns the big Git workflows, but day-to-day version-control work also
;; needs buffer-local signals: changed-line markers, friendly Ediff windows, and
;; quick conflict-resolution keys when a merge lands in a source buffer.

;;; Code:

(require 'ediff)
(require 'smerge-mode)
(require 'use-package)

(declare-function diff-hl-dired-mode "diff-hl")
(declare-function diff-hl-flydiff-mode "diff-hl")
(declare-function diff-hl-magit-post-refresh "diff-hl")
(declare-function global-diff-hl-mode "diff-hl")

(defcustom my/vc-diff-hl-enabled t
  "When non-nil, enable `diff-hl' when the package is installed."
  :type 'boolean
  :group 'vc)

(defcustom my/vc-smerge-prefix "C-c v"
  "Prefix used for merge-conflict resolution bindings."
  :type 'string
  :group 'vc)

(defun my/vc-enable-diff-hl ()
  "Enable `diff-hl' integrations when the package is available."
  (interactive)
  (unless (require 'diff-hl nil t)
    (user-error "diff-hl is not installed; run make setup"))
  (global-diff-hl-mode 1)
  (diff-hl-flydiff-mode 1)
  (add-hook 'dired-mode-hook #'diff-hl-dired-mode)
  (with-eval-after-load 'magit
    (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh)))

(use-package ediff
  :ensure nil
  :config
  ;; Reusing the current frame keeps Ediff from scattering control windows across
  ;; the desktop, and horizontal splits compare code the way most diffs render.
  (setq ediff-window-setup-function #'ediff-setup-windows-plain
        ediff-split-window-function #'split-window-horizontally))

(use-package smerge-mode
  :ensure nil
  :bind (:map smerge-mode-map
              ("C-c v n" . smerge-next)
              ("C-c v p" . smerge-prev)
              ("C-c v RET" . smerge-keep-current)
              ("C-c v a" . smerge-keep-all)
              ("C-c v b" . smerge-keep-base)
              ("C-c v l" . smerge-keep-lower)
              ("C-c v u" . smerge-keep-upper)
              ("C-c v r" . smerge-resolve)
              ("C-c v =" . smerge-diff-base-upper)
              ("C-c v E" . smerge-ediff)))

(when my/vc-diff-hl-enabled
  (when (require 'diff-hl nil t)
    (my/vc-enable-diff-hl)))

(provide 'config-vc)

;;; config-vc.el ends here
