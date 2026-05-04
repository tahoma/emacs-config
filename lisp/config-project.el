;;; config-project.el --- Project helpers -*- lexical-binding: t; -*-

;;; Commentary:
;; Built-in project.el is enough for this config. The helper gives terminal and
;; future commands one canonical way to find the current project root.

;;; Code:

(require 'project)

(defun my/project-root ()
  "Return the current project root, or `default-directory'."
  (let ((project (project-current nil)))
    (if project
        (project-root project)
      default-directory)))

(provide 'config-project)

;;; config-project.el ends here
