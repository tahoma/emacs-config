;;; config-agent.el --- Agentic development workflows -*- lexical-binding: t; -*-

;;; Commentary:
;; Agent CLIs work best when they inherit the current project directory and the
;; user can hand them focused context without ceremony. This module gives Codex
;; a small, durable bridge: save project buffers, open a project-root vterm,
;; launch the configured command, and copy selected region or file context in a
;; predictable format for pasting into the agent.

;;; Code:

(require 'subr-x)
(require 'config-project)
(require 'use-package)

(declare-function vterm "vterm")
(declare-function vterm-send-return "vterm")
(declare-function vterm-send-string "vterm")

(defcustom my/agent-codex-command '("codex")
  "Command used to start Codex CLI.
Keep this as a list so paths and arguments are shell-quoted safely. For example,
customize it to \\='(\"npx\" \"@openai/codex\") if that is how a machine launches
Codex."
  :type '(repeat string)
  :group 'tools)

(defcustom my/agent-save-project-buffers-before-launch t
  "When non-nil, save modified project buffers before launching an agent."
  :type 'boolean
  :group 'tools)

(defun my/agent-command-line (command)
  "Return shell-quoted COMMAND list as a single command line."
  (mapconcat #'shell-quote-argument command " "))

(defun my/agent-codex-available-p ()
  "Return non-nil when the configured Codex executable is on `exec-path'."
  (and my/agent-codex-command
       (executable-find (car my/agent-codex-command))))

(defun my/agent--project-buffer-p (buffer root)
  "Return non-nil when BUFFER visits a file below ROOT."
  (when-let ((file (buffer-file-name buffer)))
    (string-prefix-p (file-truename root) (file-truename file))))

(defun my/agent-save-project-buffers ()
  "Save modified file buffers that belong to the current project."
  (interactive)
  (let ((root (my/project-root)))
    (save-some-buffers
     t
     (lambda ()
       (my/agent--project-buffer-p (current-buffer) root)))))

(defun my/agent-project-vterm ()
  "Open a vterm rooted at the current project."
  (interactive)
  (unless (require 'vterm nil t)
    (user-error "vterm is not installed"))
  (let* ((root (my/project-root))
         (name (file-name-nondirectory (directory-file-name root)))
         (default-directory root))
    (vterm (format "*agent:%s*" name))))

(defun my/agent-run-in-project-vterm (command)
  "Run shell COMMAND in a project-root vterm."
  (my/agent-project-vterm)
  (vterm-send-string command)
  (vterm-send-return))

(defun my/agent-codex ()
  "Launch Codex CLI from the current project root."
  (interactive)
  (unless (my/agent-codex-available-p)
    (user-error "Codex command not found: %s"
                (car my/agent-codex-command)))
  (when my/agent-save-project-buffers-before-launch
    (my/agent-save-project-buffers))
  (my/agent-run-in-project-vterm
   (my/agent-command-line my/agent-codex-command)))

(defun my/agent-copy-region-context (start end)
  "Copy the active region from START to END with file and line context."
  (interactive "r")
  (unless (use-region-p)
    (user-error "Select a region first"))
  (let ((context (format "Context from %s:%d\n\n%s"
                         (or buffer-file-name (buffer-name))
                         (line-number-at-pos start)
                         (buffer-substring-no-properties start end))))
    (kill-new context)
    (message "Copied region context for agent use")))

(defun my/agent-codex-with-region (start end)
  "Copy region context from START to END, then launch Codex."
  (interactive "r")
  (my/agent-copy-region-context start end)
  (my/agent-codex))

(defun my/agent-copy-file-context ()
  "Copy the current file and line as lightweight agent context."
  (interactive)
  (unless buffer-file-name
    (user-error "Current buffer is not visiting a file"))
  (kill-new (format "File context: %s:%d"
                    buffer-file-name
                    (line-number-at-pos)))
  (message "Copied file context for agent use"))

(defun my/agent-codex-with-file ()
  "Copy current file context, then launch Codex."
  (interactive)
  (my/agent-copy-file-context)
  (my/agent-codex))

(use-package vterm
  :commands (vterm)
  :bind (("C-c a a" . my/agent-codex)
         ("C-c a f" . my/agent-codex-with-file)
         ("C-c a r" . my/agent-codex-with-region)
         ("C-c a t" . my/agent-project-vterm)))

(provide 'config-agent)

;;; config-agent.el ends here
