;;; config-notes.el --- Org capture for developer notes -*- lexical-binding: t; -*-

;;; Commentary:
;; Org capture gives Emacs a lightweight developer notebook without adding a
;; database, service, or project-specific dependency. The goal here is fast
;; capture from any buffer: tasks, short notes, decisions, and debugging trails
;; all land in runtime files under var/notes/ where they are available to Org
;; agenda but stay out of git.

;;; Code:

(require 'org)
(require 'org-agenda)
(require 'org-capture)
(require 'config-editing)
(require 'config-project)
(require 'use-package)

(defcustom my/notes-prefix "C-c o"
  "Global prefix for Org-backed developer notes."
  :type 'string
  :group 'org)

(defcustom my/notes-directory
  (expand-file-name "notes/" my/editing-var-directory)
  "Directory for local Org note files."
  :type 'directory
  :group 'org)

(defcustom my/notes-inbox-file
  (expand-file-name "inbox.org" my/notes-directory)
  "Org file where quick tasks and notes are captured."
  :type 'file
  :group 'org)

(defcustom my/notes-decisions-file
  (expand-file-name "decisions.org" my/notes-directory)
  "Org file where project decisions are captured."
  :type 'file
  :group 'org)

(defcustom my/notes-debug-file
  (expand-file-name "debug.org" my/notes-directory)
  "Org file where debugging notes are captured."
  :type 'file
  :group 'org)

(defun my/notes-project-root ()
  "Return the current project root for Org capture templates."
  (abbreviate-file-name (file-name-as-directory (my/project-root))))

(defun my/notes-file-seeds ()
  "Return initial contents for note files that do not exist yet."
  `((,my/notes-inbox-file . "#+title: Developer Inbox\n\n* Inbox\n* Notes\n")
    (,my/notes-decisions-file . "#+title: Decisions\n\n* Decisions\n")
    (,my/notes-debug-file . "#+title: Debug Log\n\n* Debug Log\n")))

(defun my/notes-ensure-files ()
  "Create the notes directory and seed files used by Org capture."
  (make-directory my/notes-directory t)
  (dolist (seed (my/notes-file-seeds))
    (let ((file (car seed))
          (contents (cdr seed)))
      (unless (file-exists-p file)
        (with-temp-buffer
          (insert contents)
          (write-region (point-min) (point-max) file nil 'silent))))))

(defun my/notes-capture-templates ()
  "Return Org capture templates for developer notes."
  `(("t" "Task" entry
     (file+headline ,my/notes-inbox-file "Inbox")
     "* TODO %?\n:PROPERTIES:\n:Captured: %U\n:Project: %(my/notes-project-root)\n:END:\n%a\n")
    ("n" "Note" entry
     (file+headline ,my/notes-inbox-file "Notes")
     "* %?\n:PROPERTIES:\n:Captured: %U\n:Project: %(my/notes-project-root)\n:END:\n%a\n")
    ("d" "Decision" entry
     (file+headline ,my/notes-decisions-file "Decisions")
     "* %? :decision:\n:PROPERTIES:\n:Captured: %U\n:Project: %(my/notes-project-root)\n:END:\n\nContext:\n\nDecision:\n\nConsequences:\n")
    ("b" "Debug Log" entry
     (file+headline ,my/notes-debug-file "Debug Log")
     "* %? :debug:\n:PROPERTIES:\n:Captured: %U\n:Project: %(my/notes-project-root)\n:END:\n\nObservation:\n\nHypothesis:\n\nNext step:\n")))

(defun my/notes-capture-template (key)
  "Start Org capture with template KEY."
  (org-capture nil key))

(defun my/notes-capture-task ()
  "Capture a developer task."
  (interactive)
  (my/notes-capture-template "t"))

(defun my/notes-capture-note ()
  "Capture a developer note."
  (interactive)
  (my/notes-capture-template "n"))

(defun my/notes-capture-decision ()
  "Capture a project decision."
  (interactive)
  (my/notes-capture-template "d"))

(defun my/notes-capture-debug ()
  "Capture a debugging breadcrumb."
  (interactive)
  (my/notes-capture-template "b"))

(defun my/notes-open-inbox ()
  "Open the Org notes inbox."
  (interactive)
  (find-file my/notes-inbox-file))

(defun my/notes-open-directory ()
  "Open the notes directory in Dired."
  (interactive)
  (dired my/notes-directory))

(use-package org
  :ensure nil
  :bind (("C-c o c" . org-capture)
         ("C-c o a" . org-agenda)
         ("C-c o i" . my/notes-open-inbox)
         ("C-c o o" . my/notes-open-directory)
         ("C-c o t" . my/notes-capture-task)
         ("C-c o n" . my/notes-capture-note)
         ("C-c o d" . my/notes-capture-decision)
         ("C-c o b" . my/notes-capture-debug))
  :config
  (my/notes-ensure-files)
  ;; Keep local notes useful without making the config repository itself a
  ;; personal knowledge base.
  (setq org-directory my/notes-directory
        org-default-notes-file my/notes-inbox-file
        org-agenda-files (list my/notes-inbox-file
                               my/notes-decisions-file
                               my/notes-debug-file)
        org-capture-templates (my/notes-capture-templates)
        org-log-done 'time
        org-return-follows-link t
        org-startup-folded 'content))

(provide 'config-notes)

;;; config-notes.el ends here
