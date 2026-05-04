;;; config-files.el --- Dired and file-management workflows -*- lexical-binding: t; -*-

;;; Commentary:
;; Dired is one of Emacs' most distinctive strengths: it is a file manager that
;; can also become an editable buffer. This module makes that workflow visible
;; with project-root entry points, omit/hide defaults, and Wdired for bulk
;; renaming without leaving Emacs.

;;; Code:

(require 'dired)
(require 'dired-x)
(require 'wdired)
(require 'config-project)
(require 'use-package)

(defcustom my/files-dired-omit-files
  (concat dired-omit-files
          "\\|^\\.DS_Store\\'"
          "\\|^\\.direnv\\'"
          "\\|\\.elc\\'")
  "Regexp of generated or noisy files hidden by `dired-omit-mode'."
  :type 'regexp
  :group 'files)

(defun my/files-dired-project-root ()
  "Open Dired at the current project root."
  (interactive)
  (dired (my/project-root)))

(defun my/files-dired-toggle-omit ()
  "Toggle Dired omit mode in the current Dired buffer."
  (interactive)
  (unless (derived-mode-p 'dired-mode)
    (user-error "Current buffer is not Dired"))
  (dired-omit-mode 'toggle))

(defun my/files-dired-setup ()
  "Apply local Dired defaults for quieter project file management."
  (dired-hide-details-mode 1)
  (dired-omit-mode 1))

(use-package dired
  :ensure nil
  :bind (("C-c f d" . dired-jump)
         ("C-c f p" . my/files-dired-project-root))
  :config
  (setq dired-dwim-target t
        dired-recursive-copies 'always
        dired-recursive-deletes 'top
        dired-auto-revert-buffer t
        dired-kill-when-opening-new-dired-buffer t)
  (put 'dired-find-alternate-file 'disabled nil)
  (add-hook 'dired-mode-hook #'my/files-dired-setup))

(use-package dired-x
  :ensure nil
  :after dired
  :config
  (setq dired-omit-files my/files-dired-omit-files))

(use-package wdired
  :ensure nil
  :after dired
  :bind (:map dired-mode-map
              ("C-c C-e" . wdired-change-to-wdired-mode)
              ("." . my/files-dired-toggle-omit)
              ("^" . dired-up-directory)
              ("RET" . dired-find-alternate-file)))

(provide 'config-files)

;;; config-files.el ends here
