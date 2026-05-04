;;; config-agent.el --- Agentic development workflows -*- lexical-binding: t; -*-

;;; Commentary:
;; Agent CLIs work best when they inherit the current project directory and the
;; user can hand them focused context without ceremony. This module gives agent
;; tools a small, durable bridge: save project buffers, open a project-root
;; vterm, launch the configured command, and copy selected region or file
;; context in a predictable format for pasting into the agent.

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

(defcustom my/agent-claude-command '("claude")
  "Command used to start Claude Code.
Keep this as a list so paths and arguments are shell-quoted safely."
  :type '(repeat string)
  :group 'tools)

(defcustom my/agent-cursor-command '("cursor-agent")
  "Command used to start Cursor Agent CLI.
Keep this as a list so paths and arguments are shell-quoted safely."
  :type '(repeat string)
  :group 'tools)

(defcustom my/agent-providers
  '((codex :name "Codex" :command-variable my/agent-codex-command)
    (claude :name "Claude Code" :command-variable my/agent-claude-command)
    (cursor :name "Cursor Agent" :command-variable my/agent-cursor-command))
  "Agent providers that can be launched from a project-root vterm.
Each entry is `(ID :name NAME :command-variable VARIABLE)'. VARIABLE should
hold a command list suitable for `my/agent-command-line'."
  :type 'sexp
  :group 'tools)

(defcustom my/agent-save-project-buffers-before-launch t
  "When non-nil, save modified project buffers before launching an agent."
  :type 'boolean
  :group 'tools)

(defun my/agent-command-line (command)
  "Return shell-quoted COMMAND list as a single command line."
  (mapconcat #'shell-quote-argument command " "))

(defun my/agent-provider-spec (provider)
  "Return the provider plist for PROVIDER."
  (or (alist-get provider my/agent-providers)
      (user-error "Unknown agent provider: %s" provider)))

(defun my/agent-provider-name (provider)
  "Return the human-readable name for PROVIDER."
  (or (plist-get (my/agent-provider-spec provider) :name)
      (symbol-name provider)))

(defun my/agent-provider-command (provider)
  "Return the command list configured for PROVIDER."
  (let* ((spec (my/agent-provider-spec provider))
         (variable (plist-get spec :command-variable)))
    (unless (and variable (boundp variable))
      (user-error "Agent provider %s has no command variable" provider))
    (symbol-value variable)))

(defun my/agent-provider-available-p (provider)
  "Return non-nil when PROVIDER's executable is on `exec-path'."
  (let ((command (my/agent-provider-command provider)))
    (and command
         (executable-find (car command)))))

(defun my/agent-codex-available-p ()
  "Return non-nil when the configured Codex executable is on `exec-path'."
  (my/agent-provider-available-p 'codex))

(defun my/agent-read-provider ()
  "Read an agent provider from `my/agent-providers'."
  (let* ((candidates
          (mapcar (lambda (entry)
                    (cons (plist-get (cdr entry) :name)
                          (car entry)))
                  my/agent-providers))
         (choice (completing-read "Agent: " candidates nil t nil nil "Codex")))
    (cdr (assoc choice candidates))))

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

(defun my/agent-project-vterm (&optional buffer-suffix)
  "Open a vterm rooted at the current project.
BUFFER-SUFFIX names the agent-specific buffer when provided."
  (interactive)
  (unless (require 'vterm nil t)
    (user-error "vterm is not installed"))
  (let* ((root (my/project-root))
         (name (file-name-nondirectory (directory-file-name root)))
         (default-directory root))
    (vterm (format "*agent:%s%s*"
                   name
                   (if buffer-suffix
                       (format ":%s" buffer-suffix)
                     "")))))

(defun my/agent-run-in-project-vterm (command &optional buffer-suffix)
  "Run shell COMMAND in a project-root vterm.
BUFFER-SUFFIX names the agent-specific buffer when provided."
  (my/agent-project-vterm buffer-suffix)
  (vterm-send-string command)
  (vterm-send-return))

(defun my/agent-launch (provider)
  "Launch PROVIDER from the current project root."
  (interactive (list (my/agent-read-provider)))
  (let ((command (my/agent-provider-command provider)))
    (unless (my/agent-provider-available-p provider)
      (user-error "%s command not found: %s"
                  (my/agent-provider-name provider)
                  (car command)))
    (when my/agent-save-project-buffers-before-launch
      (my/agent-save-project-buffers))
    (my/agent-run-in-project-vterm
     (my/agent-command-line command)
     (symbol-name provider))))

(defun my/agent-codex ()
  "Launch Codex CLI from the current project root."
  (interactive)
  (my/agent-launch 'codex))

(defun my/agent-claude ()
  "Launch Claude Code from the current project root."
  (interactive)
  (my/agent-launch 'claude))

(defun my/agent-cursor ()
  "Launch Cursor Agent CLI from the current project root."
  (interactive)
  (my/agent-launch 'cursor))

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
  :bind (("C-c a A" . my/agent-launch)
         ("C-c a a" . my/agent-codex)
         ("C-c a d" . my/agent-claude)
         ("C-c a u" . my/agent-cursor)
         ("C-c a f" . my/agent-codex-with-file)
         ("C-c a r" . my/agent-codex-with-region)
         ("C-c a t" . my/agent-project-vterm)))

(provide 'config-agent)

;;; config-agent.el ends here
