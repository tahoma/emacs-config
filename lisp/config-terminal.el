;;; config-terminal.el --- Terminal-frame editing support -*- lexical-binding: t; -*-

;;; Commentary:
;; Terminal Emacs deserves a few behaviors that are separate from GUI Emacs:
;; remote sessions, `emacsclient -t', and EDITOR-driven buffers all run inside
;; terminal frames where OS clipboard commands and GUI-only affordances are not
;; always available. This module gathers those terminal-specific choices so the
;; normal platform module can stay focused on host OS integration.

;;; Code:

(require 'server)
(require 'subr-x)
(require 'tramp)
(require 'config-editing)

(declare-function shell-command-with-editor-mode "with-editor")
(declare-function with-editor-async-shell-command "with-editor")
(declare-function with-editor-cancel "with-editor")
(declare-function with-editor-export-editor "with-editor")
(declare-function with-editor-finish "with-editor")
(declare-function with-editor-shell-command "with-editor")
(declare-function flyspell-mode "flyspell")

(defvar git-commit-mode-map)
(defvar ispell-program-name)
(defvar remote-file-name-inhibit-locks)
(defvar tramp-auto-save-directory)
(defvar tramp-default-method)
(defvar tramp-verbose)

(defgroup my/terminal nil
  "Terminal-frame behavior for this Emacs config."
  :group 'convenience)

(defcustom my/terminal-osc52-copy-enabled t
  "When non-nil, copy from terminal Emacs through OSC 52 escape sequences.
OSC 52 asks the terminal emulator to place text on the local clipboard. That
is especially useful over SSH, where platform tools such as pbcopy or wl-copy
would run on the remote machine rather than on the workstation in front of you."
  :type 'boolean
  :group 'my/terminal)

(defcustom my/terminal-osc52-max-bytes 100000
  "Maximum UTF-8 byte length to send through OSC 52.
Terminal emulators and multiplexers often cap OSC 52 payloads. Keeping a
bounded default avoids flooding a terminal with huge escape sequences when a
large region is killed accidentally."
  :type 'integer
  :group 'my/terminal)

(defcustom my/terminal-start-server t
  "When non-nil, start an Emacs server during interactive sessions.
The server is what makes `emacsclient -t -a \"\"' fast and reliable for Git,
SSH shells, and other command-line tools that ask for an editor. Batch runs do
not start a server because build and test commands should stay self-contained."
  :type 'boolean
  :group 'my/terminal)

(defcustom my/terminal-editor-command "emacsclient -t -a \"\""
  "Editor command recommended for terminal-first command-line workflows.
The `-t' flag keeps the client in the current terminal, while `-a \"\"' starts a
fresh server-backed Emacs if no server is already available."
  :type 'string
  :group 'my/terminal)

(defcustom my/terminal-with-editor-enabled t
  "When non-nil, make Emacs-launched shells export editor variables.
This uses the `with-editor' package so commands started from shell, eshell,
term, vterm, and `shell-command' can open editor requests in the current Emacs
server instead of hanging on a nested editor."
  :type 'boolean
  :group 'my/terminal)

(defcustom my/terminal-mouse-enabled t
  "When non-nil, enable mouse events in interactive terminal frames.
Terminal mouse support is most useful over SSH and in `emacsclient -t' frames,
where it makes scrolling, selecting windows, and point placement feel closer to
GUI Emacs without changing GUI behavior."
  :type 'boolean
  :group 'my/terminal)

(defcustom my/terminal-git-commit-fill-column 72
  "Fill column used while editing Git commit message bodies."
  :type 'integer
  :group 'my/terminal)

(defcustom my/terminal-git-commit-summary-max-length 72
  "Maximum Git commit summary length before `git-commit' warns."
  :type 'integer
  :group 'my/terminal)

(defcustom my/terminal-tramp-auto-save-directory
  (expand-file-name "tramp-auto-save/" my/editing-var-directory)
  "Local directory for TRAMP auto-save files.
Remote editing should not scatter generated safety files on servers or pay
extra network round trips for lock and autosave bookkeeping."
  :type 'directory
  :group 'my/terminal)

(defcustom my/terminal-tramp-verbose 1
  "TRAMP verbosity level for normal editing.
Level 1 keeps useful connection errors visible without filling buffers during
routine SSH-backed editing."
  :type 'integer
  :group 'my/terminal)

(defconst my/terminal-xterm-key-decodes
  '(("\e[1;2A" . [S-up])
    ("\e[1;2B" . [S-down])
    ("\e[1;2C" . [S-right])
    ("\e[1;2D" . [S-left])
    ("\e[1;5A" . [C-up])
    ("\e[1;5B" . [C-down])
    ("\e[1;5C" . [C-right])
    ("\e[1;5D" . [C-left])
    ("\e[1;6A" . [C-S-up])
    ("\e[1;6B" . [C-S-down])
    ("\e[1;6C" . [C-S-right])
    ("\e[1;6D" . [C-S-left])
    ("\e[1;2H" . [S-home])
    ("\e[1;2F" . [S-end])
    ("\e[1;5H" . [C-home])
    ("\e[1;5F" . [C-end]))
  "Conservative xterm-style modified key decodes for terminal Emacs.
Many terminals can send these sequences for modified arrows, Home, and End.
Decoding them gives terminal frames useful navigation keys without depending on
GUI-only modifiers such as Super or Hyper.")

(defun my/terminal-frame-p (&optional frame)
  "Return non-nil when FRAME, or the selected frame, is interactive terminal Emacs.
Batch Emacs is non-graphical too, but it is not a terminal editor session. That
distinction matters because test runs and build scripts should not emit OSC 52
escape sequences or compete with the normal kill ring."
  (and (not noninteractive)
       (not (display-graphic-p frame))))

(defun my/terminal-osc52-transport ()
  "Return the OSC 52 transport wrapper needed by the current terminal.
Plain terminal emulators receive the OSC sequence directly. tmux and GNU
Screen need a DCS wrapper so the escape sequence can pass through the
multiplexer to the real terminal emulator."
  (cond
   ((getenv "TMUX") 'tmux)
   ((getenv "STY") 'screen)
   (t 'direct)))

(defun my/terminal-osc52-sequence (text &optional transport)
  "Return an OSC 52 clipboard escape sequence for TEXT.
TRANSPORT may be `direct', `tmux', or `screen'. It defaults to the value from
`my/terminal-osc52-transport'."
  (let* ((payload (base64-encode-string
                   (encode-coding-string text 'utf-8-unix)
                   t))
         (osc (format "\e]52;c;%s\a" payload)))
    (pcase (or transport (my/terminal-osc52-transport))
      ('tmux (concat "\ePtmux;\e"
                     (replace-regexp-in-string "\e" "\e\e" osc t t)
                     "\e\\"))
      ('screen (concat "\eP" osc "\e\\"))
      (_ osc))))

(defun my/terminal-osc52-copy (text)
  "Copy TEXT to the local terminal clipboard with OSC 52.
This is installed as `interprogram-cut-function' for terminal frames. Pasting
continues to use whatever platform integration is available because OSC 52 is
a copy-only protocol in normal terminal workflows."
  (when (and my/terminal-osc52-copy-enabled
             (my/terminal-frame-p))
    (let ((byte-count (string-bytes (encode-coding-string text 'utf-8-unix))))
      (if (> byte-count my/terminal-osc52-max-bytes)
          (progn
            (message "Skipping OSC 52 copy: %s bytes exceeds %s byte limit"
                     byte-count my/terminal-osc52-max-bytes)
            nil)
        (send-string-to-terminal (my/terminal-osc52-sequence text))
        ;; `interprogram-cut-function' return values can affect how callers
        ;; reconcile the kill ring with external clipboard state. Return nil so
        ;; OSC 52 mirrors the copy without claiming ownership of kill-ring text.
        nil))))

(defun my/terminal-apply-osc52-clipboard ()
  "Prefer OSC 52 clipboard copy when Emacs is running in a terminal.
`config-platform' may have already installed pbcopy, wl-copy, clip.exe, or
similar helpers. Those are excellent for local terminal Emacs, but OSC 52 is
the more portable default for SSH sessions because the terminal emulator owns
the user's actual clipboard."
  (when (my/terminal-frame-p)
    (setq interprogram-cut-function #'my/terminal-osc52-copy)))

(defun my/terminal-editor-environment ()
  "Return EDITOR-style environment entries managed by this config.
Setting these inside Emacs affects shells and subprocesses launched from Emacs.
Users should still export the same values in their login shell so Git and other
CLI tools launched outside Emacs get the fast `emacsclient -t' path too."
  `(("EDITOR" . ,my/terminal-editor-command)
    ("VISUAL" . ,my/terminal-editor-command)
    ("GIT_EDITOR" . ,my/terminal-editor-command)))

(defun my/terminal-apply-editor-environment ()
  "Set EDITOR, VISUAL, and GIT_EDITOR for subprocesses launched from Emacs."
  (dolist (entry (my/terminal-editor-environment))
    (setenv (car entry) (cdr entry))))

(defun my/terminal-maybe-start-server ()
  "Start the Emacs server for `emacsclient' when this is an interactive session."
  (when (and my/terminal-start-server
             (not noninteractive)
             (not (server-running-p)))
    (server-start)))

(defun my/terminal-enable-with-editor ()
  "Teach shells launched inside Emacs how to call back into this Emacs.
The hook coverage handles long-lived shell buffers, while the remaps and global
mode cover one-shot `M-!' and `M-&' commands. This is the inside-Emacs
counterpart to exporting EDITOR in the user's login shell."
  (when my/terminal-with-editor-enabled
    (add-hook 'shell-mode-hook #'with-editor-export-editor)
    (add-hook 'eshell-mode-hook #'with-editor-export-editor)
    (add-hook 'term-exec-hook #'with-editor-export-editor)
    (add-hook 'vterm-mode-hook #'with-editor-export-editor)
    (keymap-global-set "<remap> <async-shell-command>"
                       #'with-editor-async-shell-command)
    (keymap-global-set "<remap> <shell-command>"
                       #'with-editor-shell-command)
    (shell-command-with-editor-mode 1)))

(defun my/terminal-apply-mouse (&optional frame)
  "Enable terminal mouse support for FRAME when appropriate.
`xterm-mouse-mode' is a global minor mode, but checking the frame keeps the
intent clear and avoids enabling terminal escape handling during batch runs."
  (when (and my/terminal-mouse-enabled
             (my/terminal-frame-p frame)
             (fboundp 'xterm-mouse-mode))
    (xterm-mouse-mode 1)
    ;; These events are common in xterm-compatible terminals and make wheel
    ;; scrolling work even when a terminal does not translate them itself.
    (keymap-global-set "<mouse-4>" #'scroll-down-line)
    (keymap-global-set "<mouse-5>" #'scroll-up-line)))

(defun my/terminal-spell-command-available-p ()
  "Return non-nil when Flyspell has an external spelling program to call."
  (and (boundp 'ispell-program-name)
       ispell-program-name
       (executable-find ispell-program-name)))

(defun my/terminal-git-commit-setup ()
  "Apply writing defaults for commit messages opened by Git.
Commit buffers are a common terminal `$EDITOR' path, so make the body wrap at a
conventional width, enable Auto Fill, and turn on Flyspell when the host has a
spelling backend. The finish/cancel bindings live in the package declaration so
they are visible even before a commit buffer has run its hooks."
  (setq-local fill-column my/terminal-git-commit-fill-column)
  (auto-fill-mode 1)
  (when (and (fboundp 'flyspell-mode)
             (my/terminal-spell-command-available-p))
    (flyspell-mode 1)))

(defun my/terminal-remote-buffer-p (&optional buffer)
  "Return non-nil when BUFFER, or the current buffer, visits a remote file."
  (with-current-buffer (or buffer (current-buffer))
    (and buffer-file-name
         (file-remote-p buffer-file-name))))

(defun my/terminal-remote-editing-setup ()
  "Apply buffer-local defaults that keep remote editing lightweight."
  (when (my/terminal-remote-buffer-p)
    ;; Lock files over TRAMP can create surprising permission or latency
    ;; problems, and Emacs already has local autosaves under var/ for recovery.
    (setq-local create-lockfiles nil)))

(defun my/terminal-apply-tramp-defaults ()
  "Apply SSH-friendly TRAMP defaults for terminal-heavy development."
  (make-directory my/terminal-tramp-auto-save-directory t)
  (setq tramp-default-method "ssh"
        tramp-verbose my/terminal-tramp-verbose
        tramp-auto-save-directory my/terminal-tramp-auto-save-directory
        remote-file-name-inhibit-locks t))

(defun my/terminal-apply-key-decodes ()
  "Teach Emacs common xterm escape sequences for modified navigation keys."
  (dolist (decode my/terminal-xterm-key-decodes)
    (define-key input-decode-map (car decode) (cdr decode))))

(use-package with-editor
  :commands (shell-command-with-editor-mode
             with-editor-async-shell-command
             with-editor-export-editor
             with-editor-shell-command)
  :config
  (my/terminal-enable-with-editor))

(use-package git-commit
  ;; `git-commit' is shipped by Magit, so `make setup' installs it by installing
  ;; Magit. Marking it as not separately ensured avoids asking package.el for a
  ;; package that does not exist as an independent archive entry.
  :ensure nil
  :after with-editor
  :custom
  (git-commit-summary-max-length my/terminal-git-commit-summary-max-length)
  :hook (git-commit-setup . my/terminal-git-commit-setup)
  :bind (:map git-commit-mode-map
         ("C-c C-c" . with-editor-finish)
         ("C-c C-k" . with-editor-cancel)))

(my/terminal-apply-osc52-clipboard)
(my/terminal-apply-editor-environment)
(my/terminal-maybe-start-server)
(my/terminal-apply-mouse)
(my/terminal-apply-tramp-defaults)
(my/terminal-apply-key-decodes)
(add-hook 'after-make-frame-functions #'my/terminal-apply-mouse)
(add-hook 'find-file-hook #'my/terminal-remote-editing-setup)

(provide 'config-terminal)

;;; config-terminal.el ends here
