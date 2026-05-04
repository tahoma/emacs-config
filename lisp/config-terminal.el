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

(my/terminal-apply-osc52-clipboard)
(my/terminal-apply-editor-environment)
(my/terminal-maybe-start-server)

(provide 'config-terminal)

;;; config-terminal.el ends here
