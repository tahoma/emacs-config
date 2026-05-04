;;; config-agent.el --- Agentic development workflows -*- lexical-binding: t; -*-

;;; Commentary:
;; Agent CLIs work best when they inherit the current project directory and the
;; user can hand them focused context without ceremony. This module gives agent
;; tools a small, durable bridge: save project buffers, open a project-root
;; vterm, launch the configured command, and copy selected region or file
;; context in a predictable format for pasting into the agent.

;;; Code:

(require 'subr-x)
(require 'seq)
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

(defcustom my/agent-project-context-files
  '("AGENTS.md"
    "CLAUDE.md"
    ".cursor/rules/emacs-config.mdc"
    "README.md")
  "Project-relative files to include in generated agent context.
Missing files are skipped so the same command works across repositories that
only use part of this agent instruction setup."
  :type '(repeat string)
  :group 'tools)

(defcustom my/agent-project-context-status-limit 80
  "Maximum number of `git status --short' lines in project context."
  :type 'integer
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

(defun my/agent--git-lines (root &rest args)
  "Return lines from running git ARGS in ROOT, or nil when unavailable."
  (when (executable-find "git")
    (let ((default-directory root))
      (ignore-errors
        (apply #'process-lines "git" args)))))

(defun my/agent--git-branch (root)
  "Return a human-readable git branch or revision for ROOT."
  (or (car (my/agent--git-lines root "branch" "--show-current"))
      (car (my/agent--git-lines root "rev-parse" "--short" "HEAD"))
      "unavailable"))

(defun my/agent--git-status-lines (root)
  "Return a bounded list of `git status --short' lines for ROOT."
  (if (not (executable-find "git"))
      '("unavailable")
    (let ((default-directory root))
      (condition-case nil
          (let ((lines (process-lines "git" "status" "--short")))
            (cond
             ((null lines) '("clean"))
             ((> (length lines) my/agent-project-context-status-limit)
              (append (seq-take lines my/agent-project-context-status-limit)
                      (list (format "... %d more files"
                                    (- (length lines)
                                       my/agent-project-context-status-limit)))))
             (t lines)))
        (error '("unavailable"))))))

(defun my/agent--context-file-section (root relative-file)
  "Return an agent-context markdown section for RELATIVE-FILE under ROOT."
  (let ((file (expand-file-name relative-file root)))
    (when (file-readable-p file)
      (with-temp-buffer
        (insert-file-contents file)
        (format "## %s\n\n```text\n%s\n```\n"
                relative-file
                (buffer-string))))))

(defun my/agent-project-context-string ()
  "Return a markdown project briefing suitable for agent context."
  (let* ((root (my/project-root))
         (branch (my/agent--git-branch root))
         (status-lines (my/agent--git-status-lines root))
         (file-sections
          (delq nil
                (mapcar (lambda (relative-file)
                          (my/agent--context-file-section root relative-file))
                        my/agent-project-context-files))))
    (string-join
     (append
      (list
       "# Agent Project Context\n"
       (format "- Project root: `%s`" (directory-file-name root))
       (format "- Git branch/revision: `%s`" branch)
       ""
       "## Git Status"
       ""
       "```text"
       (string-join status-lines "\n")
       "```"
       "")
      file-sections)
     "\n")))

(defun my/agent-copy-project-context ()
  "Copy a project briefing for pasting into an agent."
  (interactive)
  (kill-new (my/agent-project-context-string))
  (message "Copied project context for agent use"))

(defun my/agent-open-project-context ()
  "Open a generated project briefing buffer for review or editing."
  (interactive)
  (let* ((root (my/project-root))
         (name (file-name-nondirectory (directory-file-name root)))
         (buffer (get-buffer-create (format "*agent-context:%s*" name))))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (my/agent-project-context-string))
        (goto-char (point-min))
        (if (fboundp 'markdown-mode)
            (markdown-mode)
          (text-mode)))
      (view-mode 1))
    (pop-to-buffer buffer)))

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

(defun my/agent-launch-with-project-context (provider)
  "Copy project context, then launch PROVIDER."
  (interactive (list (my/agent-read-provider)))
  (my/agent-copy-project-context)
  (my/agent-launch provider))

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
         ("C-c a p" . my/agent-copy-project-context)
         ("C-c a P" . my/agent-open-project-context)
         ("C-c a L" . my/agent-launch-with-project-context)
         ("C-c a r" . my/agent-codex-with-region)
         ("C-c a t" . my/agent-project-vterm)))

(provide 'config-agent)

;;; config-agent.el ends here
