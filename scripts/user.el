;;; user.el --- Configure per-user environment for this Emacs config -*- lexical-binding: t; -*-

;;; Commentary:
;; This helper is deliberately standalone batch Elisp. It does not load init.el,
;; package archives, or third-party packages, so `make user' is safe before
;; `make setup'. A working Emacs executable is the only bootstrap dependency;
;; host-level external tool setup stays in scripts/host.el.
;;
;; By default this script is a dry run. It reports shell, terminal, and MCP
;; client status. It writes user dotfiles only when USER_INSTALL=1, and writes
;; MCP client configuration only when USER_MCP_INSTALL=1.

;;; Code:

(require 'cl-lib)
(require 'json)
(require 'subr-x)

(defconst user--editor-command "emacsclient -t -a \"\"")
(defconst user--mcp-server-name "elisp-dev")
(defconst user--mcp-server-id "elisp-dev-mcp")
(defconst user--mcp-init-function "elisp-dev-mcp-enable")
(defconst user--mcp-stop-function "elisp-dev-mcp-disable")
(defconst user--shell-block-begin "# >>> emacs-config user shell setup >>>")
(defconst user--shell-block-end "# <<< emacs-config user shell setup <<<")
(defconst user--tmux-block-begin "# >>> emacs-config terminal setup >>>")
(defconst user--tmux-block-end "# <<< emacs-config terminal setup <<<")

(defvar user--install nil)
(defvar user--mcp-install nil)
(defvar user--mcp-clients nil)
(defvar user--tmux-file nil)
(defvar user--emacs-mcp-script nil)
(defvar user--claude-config-file nil)
(defvar user--codex-config-file nil)
(defvar user--cursor-mcp-file nil)

(defun user--env (name &optional default)
  "Return environment variable NAME, using DEFAULT for nil or empty values."
  (let ((value (getenv name)))
    (if (or (null value) (string-empty-p value))
        default
      value)))

(defun user--env-flag-p (name)
  "Return non-nil when environment variable NAME is exactly 1."
  (string= (user--env name "0") "1"))

(defun user--home ()
  "Return the current user's home directory."
  (or (user--env "HOME")
      (expand-file-name "~")))

(defun user--expand-path (path)
  "Expand PATH with normal Emacs user and environment expansion."
  (expand-file-name (substitute-in-file-name path)))

(defun user--say (format-string &rest args)
  "Print FORMAT-STRING and ARGS followed by a newline."
  (princ (apply #'format format-string args))
  (princ "\n"))

(defun user--section (title)
  "Print section TITLE."
  (user--say "")
  (user--say "%s" title)
  (user--say "----------------------------------------"))

(defun user--status (state message &rest args)
  "Print status STATE and MESSAGE formatted with ARGS."
  (user--say "  %-7s %s" state (apply #'format message args)))

(defun user--executable-p (command)
  "Return non-nil when COMMAND is on `exec-path'."
  (executable-find command))

(defun user--requested-mcp-client-p (client)
  "Return non-nil when CLIENT was requested in USER_MCP_CLIENTS."
  (member client user--mcp-clients))

(defun user--path-has-p (directory)
  "Return non-nil when DIRECTORY is on PATH."
  (member directory (split-string (or (getenv "PATH") "") path-separator t)))

(defun user--file-has-p (file needle)
  "Return non-nil when FILE contains NEEDLE."
  (and (file-readable-p file)
       (with-temp-buffer
         (insert-file-contents file)
         (goto-char (point-min))
         (search-forward needle nil t))))

(defun user--detected-shell-file ()
  "Return the shell startup file to inspect or manage."
  (if-let ((override (user--env "USER_SHELL_FILE")))
      (user--expand-path override)
    (pcase (file-name-nondirectory (or (user--env "SHELL") ""))
      ("zsh" (expand-file-name ".zshrc" (user--home)))
      ("bash" (expand-file-name ".bashrc" (user--home)))
      ("ksh" (expand-file-name ".kshrc" (user--home)))
      ("fish" (expand-file-name ".config/fish/config.fish" (user--home)))
      (_ (expand-file-name ".profile" (user--home))))))

(defun user--posix-shell-file-p (file)
  "Return non-nil when FILE can receive the POSIX shell block."
  (not (string= (file-name-nondirectory file) "config.fish")))

(defun user--shell-block ()
  "Return the managed shell configuration block body."
  (string-join
   '("# Keep shell-launched CLI editor flows inside the current terminal."
     "export EDITOR='emacsclient -t -a \"\"'"
     "export VISUAL=\"$EDITOR\""
     "export GIT_EDITOR=\"$EDITOR\""
     ""
     "# Make pipx-managed tools visible to Emacs and commands launched from Emacs."
     "case \":$PATH:\" in"
     "  *\":$HOME/.local/bin:\"*) ;;"
     "  *) export PATH=\"$HOME/.local/bin:$PATH\" ;;"
     "esac"
     ""
     "# Make Homebrew or Linuxbrew tools visible when brew is installed."
     "if command -v brew >/dev/null 2>&1; then"
     "  eval \"$(brew shellenv)\""
     "elif [ -x /opt/homebrew/bin/brew ]; then"
     "  eval \"$(/opt/homebrew/bin/brew shellenv)\""
     "elif [ -x /usr/local/bin/brew ]; then"
     "  eval \"$(/usr/local/bin/brew shellenv)\""
     "elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then"
     "  eval \"$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\""
     "fi")
   "\n"))

(defun user--tmux-block ()
  "Return the managed tmux configuration block body."
  (string-join
   '("# Make terminal Emacs feel closer to GUI Emacs inside tmux."
     "set -g mouse on"
     "set -g set-clipboard on"
     "set -as terminal-features ',xterm-256color:RGB'")
   "\n"))

(defun user--managed-block (begin content end)
  "Return a complete managed block from BEGIN, CONTENT, and END."
  (format "%s\n%s\n%s\n" begin content end))

(defun user--install-block (file begin end content)
  "Install managed CONTENT in FILE between BEGIN and END markers."
  (make-directory (file-name-directory file) t)
  (let ((existing-lines
         (when (file-readable-p file)
           (with-temp-buffer
             (insert-file-contents file)
             (split-string (buffer-string) "\n"))))
        (skip nil)
        (kept nil))
    (dolist (line existing-lines)
      (cond
       ((string= line begin)
        (setq skip t))
       ((string= line end)
        (setq skip nil))
       ((not skip)
        (push line kept))))
    (with-temp-buffer
      (insert (string-join (nreverse kept) "\n"))
      (unless (bolp)
        (insert "\n"))
      (insert "\n")
      (insert (user--managed-block begin content end))
      (write-region (point-min) (point-max) file nil 'silent))))

(defun user--brew-command ()
  "Return a Homebrew executable path if one is available."
  (or (executable-find "brew")
      (cl-find-if #'file-executable-p
                  '("/opt/homebrew/bin/brew"
                    "/usr/local/bin/brew"
                    "/home/linuxbrew/.linuxbrew/bin/brew"))))

(defun user--process-output (program &rest args)
  "Return trimmed output from PROGRAM ARGS, or nil on failure."
  (when program
    (with-temp-buffer
      (when (zerop (apply #'process-file program nil t nil args))
        (string-trim (buffer-string))))))

(defun user--show-shell-status (shell-file)
  "Print shell status for SHELL-FILE."
  (user--section "Shell environment status")
  (user--say "Shell file: %s" shell-file)
  (if (user--posix-shell-file-p shell-file)
      (if (user--file-has-p shell-file user--shell-block-begin)
          (user--status "ok" "managed Emacs shell block is present")
        (user--status "missing" "managed Emacs shell block is not present"))
    (user--status "manual" "fish shell detected; add equivalent settings manually"))
  (dolist (variable '("EDITOR" "VISUAL" "GIT_EDITOR"))
    (if (string= (or (getenv variable) "") user--editor-command)
        (user--status "ok" "%s is %s" variable user--editor-command)
      (user--status "missing" "%s is not %s" variable user--editor-command)))
  (let ((local-bin (expand-file-name ".local/bin" (user--home))))
    (if (user--path-has-p local-bin)
        (user--status "ok" "%s is on PATH" local-bin)
      (user--status "missing" "%s is not on PATH" local-bin)))
  (when-let* ((brew (user--brew-command))
              (prefix (user--process-output brew "--prefix")))
    (let ((brew-bin (expand-file-name "bin" prefix)))
      (if (user--path-has-p brew-bin)
          (user--status "ok" "%s is on PATH" brew-bin)
        (user--status "missing" "%s is not on PATH" brew-bin)))))

(defun user--show-terminal-status ()
  "Print terminal environment status."
  (user--section "Terminal environment status")
  (let ((term (or (getenv "TERM") "")))
    (if (or (string-empty-p term) (string= term "dumb"))
        (user--status "warn" "TERM is %s; terminal Emacs may be limited"
                      (if (string-empty-p term) "unset" term))
      (user--status "ok" "TERM is %s" term)))
  (user--say "tmux file: %s" user--tmux-file)
  (if (user--file-has-p user--tmux-file user--tmux-block-begin)
      (user--status "ok" "managed tmux block is present")
    (user--status "missing" "managed tmux block is not present")))

(defun user--quote-command (command)
  "Return shell-quoted COMMAND list as one command line."
  (mapconcat (lambda (argument)
               (if (string-match-p "\\`[[:alnum:]_@%+=:,./-]+\\'" argument)
                   argument
                 (shell-quote-argument argument)))
             command
             " "))

(defun user--mcp-stdio-command-list ()
  "Return the MCP stdio command list."
  (list user--emacs-mcp-script
        (format "--init-function=%s" user--mcp-init-function)
        (format "--stop-function=%s" user--mcp-stop-function)
        (format "--server-id=%s" user--mcp-server-id)))

(defun user--claude-mcp-add-command-list ()
  "Return the Claude Code MCP registration command list."
  (append (list "claude" "mcp" "add" "--transport" "stdio" "--scope" "user"
                user--mcp-server-name "--")
          (user--mcp-stdio-command-list)))

(defun user--codex-mcp-add-command-list ()
  "Return the Codex MCP registration command list."
  (append (list "codex" "mcp" "add" user--mcp-server-name "--")
          (user--mcp-stdio-command-list)))

(defun user--claude-mcp-configured-p ()
  "Return non-nil when Claude Code appears to know this MCP server."
  (user--file-has-p user--claude-config-file user--mcp-server-name))

(defun user--codex-mcp-configured-p ()
  "Return non-nil when Codex appears to know this MCP server."
  (user--file-has-p user--codex-config-file
                    (format "[mcp_servers.%s]" user--mcp-server-name)))

(defun user--cursor-mcp-configured-p ()
  "Return non-nil when Cursor appears to know this MCP server."
  (user--file-has-p user--cursor-mcp-file
                    (format "\"%s\"" user--mcp-server-name)))

(defun user--emacsclient-reachable-p ()
  "Return non-nil when emacsclient can reach a running Emacs server."
  (and (user--executable-p "emacsclient")
       (zerop (call-process "emacsclient" nil nil nil "-e" "t"))))

(defun user--show-mcp-status ()
  "Print MCP client status."
  (user--section "MCP client status")
  (user--say "Clients: %s" (string-join user--mcp-clients " "))
  (user--say "Emacs MCP stdio script: %s" user--emacs-mcp-script)
  (if (file-executable-p user--emacs-mcp-script)
      (user--status "ok" "stdio bridge script is installed and executable")
    (user--status "missing" "stdio bridge script is missing; run make setup"))
  (cond
   ((not (user--executable-p "emacsclient"))
    (user--status "missing" "emacsclient command is not on PATH"))
   ((user--emacsclient-reachable-p)
    (user--status "ok" "emacsclient can reach a running Emacs server"))
   (t
    (user--status "warn" "emacsclient cannot reach Emacs; start a daemon before MCP use")))
  (when (user--requested-mcp-client-p "claude")
    (user--say "Claude Code config: %s" user--claude-config-file)
    (cond
     ((not (user--executable-p "claude"))
      (user--status "manual" "Claude Code CLI is not on PATH"))
     ((user--claude-mcp-configured-p)
      (user--status "ok" "Claude Code has %s MCP server configured" user--mcp-server-name))
     (t
      (user--status "missing" "Claude Code is missing %s MCP server" user--mcp-server-name))))
  (when (user--requested-mcp-client-p "codex")
    (user--say "Codex config: %s" user--codex-config-file)
    (cond
     ((not (user--executable-p "codex"))
      (user--status "manual" "Codex CLI is not on PATH"))
     ((user--codex-mcp-configured-p)
      (user--status "ok" "Codex has %s MCP server configured" user--mcp-server-name))
     (t
      (user--status "missing" "Codex is missing %s MCP server" user--mcp-server-name))))
  (when (user--requested-mcp-client-p "cursor")
    (user--say "Cursor MCP file: %s" user--cursor-mcp-file)
    (if (user--cursor-mcp-configured-p)
        (user--status "ok" "Cursor has %s MCP server configured" user--mcp-server-name)
      (user--status "missing" "Cursor is missing %s MCP server" user--mcp-server-name))))

(defun user--show-user-plan (shell-file)
  "Print planned user dotfile setup for SHELL-FILE."
  (user--section "Planned user setup")
  (if (user--posix-shell-file-p shell-file)
      (progn
        (user--say "Would manage this shell block in %s:" shell-file)
        (princ (user--managed-block user--shell-block-begin
                                    (user--shell-block)
                                    user--shell-block-end)))
    (user--say "No automatic shell edit planned for fish. Add equivalent EDITOR, VISUAL, GIT_EDITOR, and PATH settings manually."))
  (user--say "")
  (user--say "Would manage this tmux block in %s:" user--tmux-file)
  (princ (user--managed-block user--tmux-block-begin
                              (user--tmux-block)
                              user--tmux-block-end)))

(defun user--cursor-mcp-object ()
  "Return a JSON object for Cursor MCP configuration."
  (let ((server (make-hash-table :test 'equal))
        (servers (make-hash-table :test 'equal))
        (root (make-hash-table :test 'equal)))
    (puthash "command" user--emacs-mcp-script server)
    (puthash "args" (vconcat (cdr (user--mcp-stdio-command-list))) server)
    (puthash user--mcp-server-name server servers)
    (puthash "mcpServers" servers root)
    root))

(defun user--json-serialize-pretty (object)
  "Serialize JSON OBJECT with a final newline."
  (with-temp-buffer
    (insert (json-serialize object
                            :null-object nil
                            :false-object :false))
    (when (fboundp 'json-pretty-print-buffer)
      (json-pretty-print-buffer))
    (goto-char (point-max))
    (unless (bolp)
      (insert "\n"))
    (buffer-string)))

(defun user--cursor-mcp-json ()
  "Return Cursor MCP configuration JSON."
  (user--json-serialize-pretty (user--cursor-mcp-object)))

(defun user--show-mcp-plan ()
  "Print planned MCP client setup."
  (user--section "Planned MCP client setup")
  (user--say "The MCP clients should run this stdio command:")
  (user--say "  %s" (user--quote-command (user--mcp-stdio-command-list)))
  (user--say "")
  (user--say "Emacs must be running as a server and the MCP server must be started from Emacs:")
  (user--say "  M-x my/mcp-start")
  (when (user--requested-mcp-client-p "claude")
    (user--say "")
    (user--say "Would register Claude Code with:")
    (user--say "  %s" (user--quote-command (user--claude-mcp-add-command-list))))
  (when (user--requested-mcp-client-p "codex")
    (user--say "")
    (user--say "Would register Codex with:")
    (user--say "  %s" (user--quote-command (user--codex-mcp-add-command-list))))
  (when (user--requested-mcp-client-p "cursor")
    (user--say "")
    (user--say "Would ensure this Cursor MCP entry exists in %s:" user--cursor-mcp-file)
    (princ (user--cursor-mcp-json))))

(defun user--apply-user-setup (shell-file)
  "Apply user dotfile setup for SHELL-FILE."
  (if (user--posix-shell-file-p shell-file)
      (progn
        (user--install-block shell-file user--shell-block-begin
                             user--shell-block-end (user--shell-block))
        (user--say "Updated %s" shell-file))
    (user--say "Skipped automatic shell update for fish: %s" shell-file))
  (user--install-block user--tmux-file user--tmux-block-begin
                       user--tmux-block-end (user--tmux-block))
  (user--say "Updated %s" user--tmux-file))

(defun user--json-file-object (file)
  "Read FILE as a JSON object hash table, or nil when invalid."
  (when (and (file-readable-p file)
             (> (nth 7 (file-attributes file)) 0))
    (condition-case nil
        (with-temp-buffer
          (insert-file-contents file)
          (let ((object (json-parse-buffer :object-type 'hash-table
                                           :array-type 'vector
                                           :null-object nil
                                           :false-object :false)))
            (when (hash-table-p object)
              object)))
      (error nil))))

(defun user--write-json-file (file object)
  "Write JSON OBJECT to FILE."
  (make-directory (file-name-directory file) t)
  (with-temp-file file
    (insert (user--json-serialize-pretty object))))

(defun user--install-cursor-mcp ()
  "Install or update Cursor MCP JSON configuration."
  (make-directory (file-name-directory user--cursor-mcp-file) t)
  (cond
   ((user--cursor-mcp-configured-p)
    (user--say "Cursor already has %s MCP server configured" user--mcp-server-name))
   ((and (file-exists-p user--cursor-mcp-file)
         (> (nth 7 (file-attributes user--cursor-mcp-file)) 0))
    (if-let ((object (user--json-file-object user--cursor-mcp-file)))
        (let ((servers (gethash "mcpServers" object)))
          (unless (hash-table-p servers)
            (setq servers (make-hash-table :test 'equal))
            (puthash "mcpServers" servers object))
          (puthash user--mcp-server-name
                   (gethash user--mcp-server-name
                            (gethash "mcpServers" (user--cursor-mcp-object)))
                   servers)
          (user--write-json-file user--cursor-mcp-file object)
          (user--say "Updated %s" user--cursor-mcp-file))
      (user--say "Skipped Cursor MCP update because %s is not valid JSON"
                 user--cursor-mcp-file)))
   (t
    (user--write-json-file user--cursor-mcp-file (user--cursor-mcp-object))
    (user--say "Created %s" user--cursor-mcp-file))))

(defun user--run-command (command)
  "Run COMMAND list, streaming output, and signal on failure."
  (let ((status (apply #'call-process (car command) nil t t (cdr command))))
    (unless (zerop status)
      (error "Command failed with status %s: %s"
             status (user--quote-command command)))))

(defun user--apply-mcp-setup ()
  "Apply MCP client setup."
  (user--section "Applying MCP client setup")
  (unless (file-executable-p user--emacs-mcp-script)
    (user--say "Warning: %s is missing or not executable. Run make setup before using the MCP clients."
               user--emacs-mcp-script))
  (when (user--requested-mcp-client-p "claude")
    (cond
     ((not (user--executable-p "claude"))
      (user--say "Skipped Claude Code MCP registration: claude is not on PATH"))
     ((user--claude-mcp-configured-p)
      (user--say "Claude Code already has %s MCP server configured" user--mcp-server-name))
     (t
      (user--run-command (user--claude-mcp-add-command-list)))))
  (when (user--requested-mcp-client-p "codex")
    (cond
     ((not (user--executable-p "codex"))
      (user--say "Skipped Codex MCP registration: codex is not on PATH"))
     ((user--codex-mcp-configured-p)
      (user--say "Codex already has %s MCP server configured" user--mcp-server-name))
     (t
      (user--run-command (user--codex-mcp-add-command-list)))))
  (when (user--requested-mcp-client-p "cursor")
    (user--install-cursor-mcp)))

(defun user--initialize ()
  "Initialize script state from environment variables."
  (setq user--install (user--env-flag-p "USER_INSTALL")
        user--mcp-install (user--env-flag-p "USER_MCP_INSTALL")
        user--mcp-clients (split-string (user--env "USER_MCP_CLIENTS"
                                                   "claude codex cursor")
                                        "[[:space:]]+" t)
        user--tmux-file (user--expand-path
                         (user--env "USER_TMUX_FILE"
                                    (expand-file-name ".tmux.conf" (user--home))))
        user--emacs-mcp-script (user--expand-path
                                (user--env "USER_EMACS_MCP_SCRIPT"
                                           (expand-file-name ".emacs.d/emacs-mcp-stdio.sh"
                                                             (user--home))))
        user--claude-config-file (user--expand-path
                                  (user--env "USER_CLAUDE_CONFIG_FILE"
                                             (expand-file-name ".claude.json"
                                                               (user--home))))
        user--codex-config-file (user--expand-path
                                 (user--env "USER_CODEX_CONFIG_FILE"
                                            (expand-file-name ".codex/config.toml"
                                                              (user--home))))
        user--cursor-mcp-file (user--expand-path
                               (user--env "USER_CURSOR_MCP_FILE"
                                          (expand-file-name ".cursor/mcp.json"
                                                            (user--home))))))

(defun user--main ()
  "Run the user setup helper."
  (user--initialize)
  (let ((shell-file (user--detected-shell-file)))
    (if user--install
        (user--say "USER_INSTALL=1: user dotfiles will be updated.")
      (user--say "Dry run: user dotfiles are not modified. Run 'make user USER_INSTALL=1' to update them."))
    (if user--mcp-install
        (user--say "USER_MCP_INSTALL=1: MCP client configuration will be updated.")
      (user--say "Dry run: MCP clients are not modified. Run 'make user USER_MCP_INSTALL=1' to update them."))
    (user--show-shell-status shell-file)
    (user--show-terminal-status)
    (user--show-mcp-status)
    (if user--install
        (user--apply-user-setup shell-file)
      (user--show-user-plan shell-file))
    (if user--mcp-install
        (user--apply-mcp-setup)
      (user--show-mcp-plan))
    (user--section "After user setup")
    (user--say "Restart your shell or source the updated shell file, then run:")
    (user--say "  make user")))

(user--main)

;;; user.el ends here
