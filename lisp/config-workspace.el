;;; config-workspace.el --- Window and workspace ergonomics -*- lexical-binding: t; -*-

;;; Commentary:
;; Long-lived Emacs sessions accumulate windows, tabs, terminals, Magit status
;; buffers, compilation logs, and agent conversations. This module turns the
;; built-in window and tab tools into a small workspace layer without adding a
;; separate workspace package.

;;; Code:

(require 'project)
(require 'tab-bar)
(require 'windmove)
(require 'winner)
(require 'use-package)

(defcustom my/workspace-enable-tab-bar t
  "When non-nil, enable `tab-bar-mode' for named workspace tabs."
  :type 'boolean
  :group 'convenience)

(defcustom my/workspace-tab-bar-show 1
  "Value for `tab-bar-show'.
The default shows the tab bar only when more than one tab exists."
  :type 'integer
  :group 'convenience)

(defcustom my/workspace-windmove-wrap-around nil
  "When non-nil, directional window movement wraps at frame edges."
  :type 'boolean
  :group 'convenience)

(defun my/workspace-project-name ()
  "Return a readable name for the current project or directory."
  (let ((root (if-let ((project (project-current nil)))
                  (project-root project)
                default-directory)))
    (file-name-nondirectory (directory-file-name root))))

(defun my/workspace-tab-new-for-project ()
  "Create a new tab named for the current project."
  (interactive)
  (tab-new)
  (tab-rename (my/workspace-project-name)))

(defun my/workspace-tab-rename-for-project ()
  "Rename the current tab to the current project name."
  (interactive)
  (tab-rename (my/workspace-project-name)))

(use-package winner
  :ensure nil
  :bind (("C-c w u" . winner-undo)
         ("C-c w r" . winner-redo))
  :config
  (winner-mode 1))

(use-package windmove
  :ensure nil
  :bind (("C-c w h" . windmove-left)
         ("C-c w j" . windmove-down)
         ("C-c w k" . windmove-up)
         ("C-c w l" . windmove-right))
  :config
  (setq windmove-wrap-around my/workspace-windmove-wrap-around))

(use-package tab-bar
  :ensure nil
  :bind (("C-c w n" . my/workspace-tab-new-for-project)
         ("C-c w m" . my/workspace-tab-rename-for-project)
         ("C-c w o" . tab-next)
         ("C-c w p" . tab-previous)
         ("C-c w c" . tab-close))
  :config
  (setq tab-bar-show my/workspace-tab-bar-show
        tab-bar-new-tab-choice "*scratch*"
        tab-bar-close-button-show nil
        tab-bar-tab-hints t)
  (when my/workspace-enable-tab-bar
    (tab-bar-mode 1)))

(provide 'config-workspace)

;;; config-workspace.el ends here
