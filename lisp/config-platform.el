;;; config-platform.el --- Host platform integration -*- lexical-binding: t; -*-

;;; Commentary:
;; This module contains the small runtime checks that make the same config feel
;; native on macOS, GNU/Linux, WSL, and Windows. The key rule is that platform
;; behavior lives behind `system-type' predicates: modifier keys, Dired's `ls'
;; assumptions, external open/reveal commands, terminal clipboard integration,
;; browser launching, and shell defaults should all adapt to the host rather
;; than leaking one operating system's habits into another.

;;; Code:

(require 'browse-url)
(require 'cl-lib)
(require 'dired)
(require 'ls-lisp)
(require 'subr-x)

(defvar dired-use-ls-dired)
(defvar explicit-shell-file-name)
(defvar insert-directory-program)
(defvar ls-lisp-use-insert-directory-program)
(defvar mac-command-modifier)
(defvar mac-option-modifier)
(defvar mac-right-option-modifier)
(defvar ns-command-modifier)
(defvar ns-option-modifier)
(defvar ns-right-option-modifier)
(defvar vterm-shell)
(defvar w32-apps-modifier)
(defvar w32-lwindow-modifier)
(defvar w32-rwindow-modifier)

(defcustom my/platform-open-bindings-prefix "C-c O"
  "Global prefix for host open/reveal/path helper commands."
  :type 'string
  :group 'convenience)

(defcustom my/platform-preferred-windows-shells
  '("pwsh.exe" "powershell.exe" "cmd.exe")
  "Windows shell executables to prefer, in order."
  :type '(repeat string)
  :group 'tools)

(defun my/platform-macos-p (&optional system)
  "Return non-nil when SYSTEM, or `system-type', is macOS."
  (eq (or system system-type) 'darwin))

(defun my/platform-linux-p (&optional system)
  "Return non-nil when SYSTEM, or `system-type', is GNU/Linux."
  (eq (or system system-type) 'gnu/linux))

(defun my/platform-windows-p (&optional system)
  "Return non-nil when SYSTEM, or `system-type', is native Windows."
  (memq (or system system-type) '(windows-nt cygwin ms-dos)))

(defun my/platform-wsl-p (&optional system version-string)
  "Return non-nil when running under Windows Subsystem for Linux.
SYSTEM defaults to `system-type'. VERSION-STRING is useful for tests; when it
is nil, read /proc/version on GNU/Linux."
  (and (my/platform-linux-p system)
       (let ((version (or version-string
                          (when (file-readable-p "/proc/version")
                            (with-temp-buffer
                              (insert-file-contents "/proc/version")
                              (buffer-string))))))
         (and version
              (string-match-p
               (rx (or "Microsoft" "microsoft" "WSL"))
               version)))))

(defun my/platform--command (name)
  "Return executable NAME or nil when it is not available."
  (executable-find name))

(defun my/platform--first-command (commands)
  "Return the first available executable from COMMANDS."
  (cl-some #'my/platform--command commands))

(defun my/platform-default-shell (&optional system)
  "Return a sensible shell for SYSTEM, or the current host."
  (cond
   ((my/platform-windows-p system)
    (or (my/platform--first-command my/platform-preferred-windows-shells)
        "cmd.exe"))
   (t
    (or (getenv "SHELL")
        (my/platform--first-command '("zsh" "bash" "sh"))
        "/bin/sh"))))

(defun my/platform-apply-shell-defaults ()
  "Keep Emacs shell commands aligned with the host shell."
  (let ((shell (my/platform-default-shell)))
    (setq shell-file-name shell
          explicit-shell-file-name shell)
    (with-eval-after-load 'vterm
      (setq vterm-shell shell))))

(defun my/platform-apply-modifier-defaults ()
  "Apply OS-specific modifier-key defaults when the variables exist."
  (cond
   ((my/platform-macos-p)
    ;; Command-as-Meta matches common macOS Emacs muscle memory. Leaving Option
    ;; nil preserves normal macOS special-character input.
    (when (boundp 'mac-command-modifier)
      (setq mac-command-modifier 'meta))
    (when (boundp 'mac-option-modifier)
      (setq mac-option-modifier nil))
    (when (boundp 'mac-right-option-modifier)
      (setq mac-right-option-modifier nil))
    (when (boundp 'ns-command-modifier)
      (setq ns-command-modifier 'meta))
    (when (boundp 'ns-option-modifier)
      (setq ns-option-modifier nil))
    (when (boundp 'ns-right-option-modifier)
      (setq ns-right-option-modifier nil)))
   ((my/platform-windows-p)
    ;; Treat Windows keys as Super so they are available for user bindings
    ;; without colliding with Meta.
    (when (boundp 'w32-lwindow-modifier)
      (setq w32-lwindow-modifier 'super))
    (when (boundp 'w32-rwindow-modifier)
      (setq w32-rwindow-modifier 'super))
    (when (boundp 'w32-apps-modifier)
      (setq w32-apps-modifier 'hyper)))))

(defun my/platform-apply-dired-defaults ()
  "Make Dired behave well with each platform's directory listing tools."
  (setq dired-listing-switches "-alh")
  (cond
   ((my/platform-macos-p)
    (if (my/platform--command "gls")
        (setq insert-directory-program (my/platform--command "gls")
              dired-use-ls-dired t)
      ;; macOS ships BSD ls, which does not support GNU ls --dired markers.
      (setq dired-use-ls-dired nil)))
   ((my/platform-windows-p)
    ;; Native Windows Emacs is most reliable when Dired uses Emacs' Lisp
    ;; implementation instead of expecting a Unix ls binary.
    (setq ls-lisp-use-insert-directory-program nil
          dired-use-ls-dired nil))
   ((my/platform-linux-p)
    (setq dired-use-ls-dired t))))

(defun my/platform--windows-path (path)
  "Return PATH in a form accepted by Windows shell tools."
  (cond
   ((and (my/platform-wsl-p)
         (my/platform--command "wslpath"))
    (or (ignore-errors
          (car (process-lines "wslpath" "-w" (expand-file-name path))))
        path))
   (t
    (replace-regexp-in-string "/" "\\\\" (expand-file-name path) t t))))

(defun my/platform-open-command (path &optional system)
  "Return a command list that opens PATH externally for SYSTEM."
  (let ((system (or system system-type)))
    (cond
     ((my/platform-macos-p system)
      (list "open" path))
     ((and (my/platform-wsl-p system)
           (my/platform--command "wslview"))
      (list "wslview" path))
     ((my/platform-linux-p system)
      (when (my/platform--command "xdg-open")
        (list "xdg-open" path)))
     ((my/platform-windows-p system)
      (list "cmd.exe" "/c" "start" "" (my/platform--windows-path path))))))

(defun my/platform-reveal-command (path &optional system)
  "Return a command list that reveals PATH in a file manager for SYSTEM."
  (let* ((system (or system system-type))
         (file (expand-file-name path))
         (directory (if (file-directory-p file)
                        file
                      (file-name-directory file))))
    (cond
     ((my/platform-macos-p system)
      (if (file-directory-p file)
          (list "open" file)
        (list "open" "-R" file)))
     ((and (my/platform-wsl-p system)
           (my/platform--command "explorer.exe"))
      (list "explorer.exe" (concat "/select," (my/platform--windows-path file))))
     ((my/platform-linux-p system)
      (cond
       ((my/platform--command "nautilus")
        (list "nautilus" "--select" file))
       ((my/platform--command "dolphin")
        (list "dolphin" "--select" file))
       ((my/platform--command "thunar")
        (list "thunar" directory))
       ((my/platform--command "xdg-open")
        (list "xdg-open" directory))))
     ((my/platform-windows-p system)
      (list "explorer.exe" (concat "/select," (my/platform--windows-path file)))))))

(defun my/platform--path-at-point ()
  "Return the file or directory that platform open commands should target."
  (or buffer-file-name
      (and (derived-mode-p 'dired-mode) (dired-get-file-for-visit))
      default-directory))

(defun my/platform--start-command (name command)
  "Start COMMAND asynchronously with process NAME."
  (unless command
    (user-error "No platform command is available for this host"))
  (apply #'start-process name nil command))

(defun my/platform-open-file-externally (&optional path)
  "Open PATH, or the current buffer's file, with the host OS."
  (interactive)
  (my/platform--start-command
   "emacs-platform-open"
   (my/platform-open-command (or path (my/platform--path-at-point)))))

(defun my/platform-reveal-in-file-manager (&optional path)
  "Reveal PATH, or the current buffer's file, in the host file manager."
  (interactive)
  (my/platform--start-command
   "emacs-platform-reveal"
   (my/platform-reveal-command (or path (my/platform--path-at-point)))))

(defun my/platform-copy-file-path (&optional path)
  "Copy PATH, or the current buffer's file path, to the kill ring."
  (interactive)
  (let ((target (expand-file-name (or path (my/platform--path-at-point)))))
    (kill-new target)
    (message "Copied path: %s" target)))

(defun my/platform-clipboard-copy-command (&optional system)
  "Return a command list that writes stdin to the OS clipboard."
  (let ((system (or system system-type)))
    (cond
     ((my/platform-macos-p system)
      (when (my/platform--command "pbcopy")
        '("pbcopy")))
     ((my/platform-wsl-p system)
      (when (my/platform--command "clip.exe")
        '("clip.exe")))
     ((my/platform-windows-p system)
      (when (my/platform--command "clip.exe")
        '("clip.exe")))
     ((my/platform-linux-p system)
      (cond
       ((and (getenv "WAYLAND_DISPLAY")
             (my/platform--command "wl-copy"))
        '("wl-copy"))
       ((my/platform--command "xclip")
        '("xclip" "-selection" "clipboard"))
       ((my/platform--command "xsel")
        '("xsel" "--clipboard" "--input")))))))

(defun my/platform-clipboard-paste-command (&optional system)
  "Return a command list that reads stdout from the OS clipboard."
  (let ((system (or system system-type)))
    (cond
     ((my/platform-macos-p system)
      (when (my/platform--command "pbpaste")
        '("pbpaste")))
     ((my/platform-wsl-p system)
      (when (my/platform--command "powershell.exe")
        '("powershell.exe" "-NoProfile" "-Command" "Get-Clipboard")))
     ((my/platform-windows-p system)
      (when (my/platform--command "powershell.exe")
        '("powershell.exe" "-NoProfile" "-Command" "Get-Clipboard")))
     ((my/platform-linux-p system)
      (cond
       ((and (getenv "WAYLAND_DISPLAY")
             (my/platform--command "wl-paste"))
        '("wl-paste" "-n"))
       ((my/platform--command "xclip")
        '("xclip" "-selection" "clipboard" "-out"))
       ((my/platform--command "xsel")
        '("xsel" "--clipboard" "--output")))))))

(defun my/platform--call-with-input (command text)
  "Send TEXT to COMMAND, returning non-nil on success."
  (with-temp-buffer
    (insert text)
    (zerop (apply #'call-process-region
                  (point-min) (point-max)
                  (car command)
                  nil nil nil
                  (cdr command)))))

(defun my/platform-clipboard-copy (text)
  "Copy TEXT to the host clipboard when a terminal clipboard tool exists."
  (when-let ((command (my/platform-clipboard-copy-command)))
    (my/platform--call-with-input command text)))

(defun my/platform-clipboard-paste ()
  "Return text from the host clipboard when a terminal clipboard tool exists."
  (when-let ((command (my/platform-clipboard-paste-command)))
    (with-temp-buffer
      (when (zerop (apply #'call-process (car command) nil t nil (cdr command)))
        (buffer-string)))))

(defun my/platform-apply-terminal-clipboard ()
  "Use host clipboard commands for terminal Emacs when available."
  (unless (display-graphic-p)
    (when (my/platform-clipboard-copy-command)
      (setq interprogram-cut-function #'my/platform-clipboard-copy))
    (when (my/platform-clipboard-paste-command)
      (setq interprogram-paste-function #'my/platform-clipboard-paste))))

(defun my/platform-apply-browser-defaults ()
  "Use the host OS browser launcher when Emacs opens URLs."
  (cond
   ((and (my/platform-macos-p)
         (fboundp 'browse-url-default-macosx-browser))
    (setq browse-url-browser-function #'browse-url-default-macosx-browser))
   ((and (my/platform-linux-p)
         (my/platform--command "xdg-open"))
    (setq browse-url-browser-function #'browse-url-xdg-open))
   ((and (my/platform-windows-p)
         (fboundp 'browse-url-default-windows-browser))
    (setq browse-url-browser-function #'browse-url-default-windows-browser))))

(defun my/platform-apply-trash-defaults ()
  "Move deleted files to the host trash when possible."
  (when (or (my/platform-macos-p)
            (my/platform-linux-p)
            (my/platform-windows-p))
    (setq delete-by-moving-to-trash t)))

(defun my/platform-bind-open-commands ()
  "Bind global host open/reveal/path helper commands."
  (global-set-key (kbd (concat my/platform-open-bindings-prefix " o"))
                  #'my/platform-open-file-externally)
  (global-set-key (kbd (concat my/platform-open-bindings-prefix " r"))
                  #'my/platform-reveal-in-file-manager)
  (global-set-key (kbd (concat my/platform-open-bindings-prefix " p"))
                  #'my/platform-copy-file-path))

(defun my/platform-apply-defaults ()
  "Apply all host-platform defaults."
  (my/platform-apply-shell-defaults)
  (my/platform-apply-modifier-defaults)
  (my/platform-apply-dired-defaults)
  (my/platform-apply-browser-defaults)
  (my/platform-apply-terminal-clipboard)
  (my/platform-apply-trash-defaults)
  (my/platform-bind-open-commands))

(my/platform-apply-defaults)

(provide 'config-platform)

;;; config-platform.el ends here
