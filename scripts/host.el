;;; host.el --- Check/install host tools for this Emacs config -*- lexical-binding: t; -*-

;;; Commentary:
;; This helper is deliberately standalone batch Elisp. It assumes a stock Emacs
;; executable is already installed, but it does not load init.el, package
;; archives, bytecode, or third-party packages. That keeps `make host' usable
;; before this repository's custom Emacs setup has run.
;;
;; By default this script is a dry run. It reports host-level tool status and
;; prints package-manager commands. It executes those commands only when
;; HOST_INSTALL=1 is present in the environment. Per-user shell profile setup
;; lives in scripts/user.el.

;;; Code:

(require 'cl-lib)
(require 'subr-x)

(defvar host--install nil)

(defconst host--common-tools
  '("emacs" "git" "cmake" "clangd" "clang-format" "rg" "fd" "jq" "node"
    "npm" "pandoc" "python3" "pipx" "direnv" "ruff" "uv"
    "basedpyright-langserver" "typescript-language-server"
    "vscode-json-language-server" "yaml-language-server" "mmdc" "sqlformat"
    "verible-verilog-format" "verible-verilog-lint" "verible-verilog-ls"
    "verilator" "iverilog" "codex" "claude" "cursor-agent")
  "Host-level tools that are useful to this Emacs configuration.")

(defun host--env (name &optional default)
  "Return environment variable NAME, using DEFAULT for nil or empty values."
  (let ((value (getenv name)))
    (if (or (null value) (string-empty-p value))
        default
      value)))

(defun host--env-flag-p (name)
  "Return non-nil when environment variable NAME is exactly 1."
  (string= (host--env name "0") "1"))

(defun host--say (format-string &rest args)
  "Print FORMAT-STRING and ARGS followed by a newline."
  (princ (apply #'format format-string args))
  (princ "\n"))

(defun host--section (title)
  "Print section TITLE."
  (host--say "")
  (host--say "%s" title)
  (host--say "----------------------------------------"))

(defun host--status (state message &rest args)
  "Print status STATE and MESSAGE formatted with ARGS."
  (host--say "  %-7s %s" state (apply #'format message args)))

(defun host--executable-path (command)
  "Return COMMAND's executable path, or nil when it is not on `exec-path'."
  (executable-find command))

(defun host--have-p (command)
  "Return non-nil when COMMAND is available."
  (host--executable-path command))

(defun host--show-tools (&rest tools)
  "Print detected status for each command in TOOLS."
  (dolist (tool tools)
    (if-let ((path (host--executable-path tool)))
        (host--status "ok" "%s -> %s" tool path)
      (host--status "missing" "%s" tool))))

(defun host--file-matches-p (file regexp)
  "Return non-nil when FILE exists and contains REGEXP."
  (and (file-readable-p file)
       (with-temp-buffer
         (insert-file-contents file)
         (goto-char (point-min))
         (re-search-forward regexp nil t))))

(defun host--running-wsl-p ()
  "Return non-nil when Emacs appears to be running under WSL."
  (host--file-matches-p "/proc/version" "\\(Microsoft\\|WSL\\)"))

(defun host--debian-like-p ()
  "Return non-nil when /etc/os-release looks Debian- or Ubuntu-like."
  (host--file-matches-p "/etc/os-release"
                        "^\\(ID\\|ID_LIKE\\)=.*\\(debian\\|ubuntu\\)"))

(defun host--windows-like-p ()
  "Return non-nil when this Emacs is running on a Windows-like host."
  (or (memq system-type '(windows-nt cygwin ms-dos))
      (getenv "MSYSTEM")))

(defun host--shell-program ()
  "Return the shell program to use for host setup commands."
  (or (host--executable-path "bash")
      (and (boundp 'shell-file-name) shell-file-name)
      (if (host--windows-like-p) "cmd.exe" "sh")))

(defun host--shell-arguments (command)
  "Return shell arguments that ask the current shell to run COMMAND."
  (let ((program (file-name-nondirectory (host--shell-program))))
    (cond
     ((string-match-p "\\`bash\\(\\.exe\\)?\\'" program)
      (list "-lc" command))
     ((host--windows-like-p)
      (list "/d" "/s" "/c" command))
     (t
      (list shell-command-switch command)))))

(defun host--process-input-file ()
  "Return a useful input file for child processes, or nil when unavailable.

When HOST_INSTALL=1 runs commands that invoke sudo, using /dev/tty as stdin
gives sudo a chance to read from the user's terminal if the platform exposes
one. Commands still work non-interactively when sudo credentials are cached."
  (when (and (not (host--windows-like-p))
             (file-readable-p "/dev/tty"))
    "/dev/tty"))

(defun host--run-shell-command (command)
  "Run COMMAND through a login-ish shell and return its exit status."
  (let ((program (host--shell-program))
        (arguments (host--shell-arguments command)))
    (unless program
      (error "No shell program available to run: %s" command))
    (with-temp-buffer
      (let ((status (apply #'call-process program
                           (host--process-input-file)
                           t nil arguments))
            (output (buffer-string)))
        (unless (string-empty-p output)
          (princ output))
        status))))

(defun host--successful-status-p (status)
  "Return non-nil when process STATUS represents success."
  (and (integerp status) (zerop status)))

(defun host--status-description (status)
  "Return a human-readable description for process STATUS."
  (if (integerp status)
      (number-to-string status)
    (format "%s" status)))

(defun host--run-shell (command)
  "Print or execute shell COMMAND according to HOST_INSTALL."
  (if host--install
      (progn
        (host--say "+ %s" command)
        (let ((status (host--run-shell-command command)))
          (unless (host--successful-status-p status)
            (error "Command failed with status %s: %s"
                   (host--status-description status) command))))
    (host--say "  %s" command)))

(defun host--run-optional-shell (command description)
  "Print or execute optional shell COMMAND for DESCRIPTION.

Optional host tools should not prevent the rest of HOST_INSTALL=1 from
finishing. That is especially useful for tools distributed outside an operating
system's default package set."
  (if host--install
      (progn
        (host--say "+ %s" command)
        (let ((status (host--run-shell-command command)))
          (unless (host--successful-status-p status)
            (host--status "warn" "optional setup failed for %s (status %s)"
                          description (host--status-description status)))))
    (host--say "  %s" command)))

(defun host--process-output (program &rest args)
  "Return trimmed output from PROGRAM ARGS, or nil on failure."
  (when program
    (with-temp-buffer
      (when (host--successful-status-p
             (apply #'call-process program nil t nil args))
        (string-trim (buffer-string))))))

(defun host--pipx-install-command (package)
  "Return a shell command that installs or upgrades pipx PACKAGE."
  (format "pipx install %s || pipx upgrade %s" package package))

(defun host--show-tool-status ()
  "Print host-level tool status."
  (host--section "Detected tool status")
  (apply #'host--show-tools host--common-tools)
  (pcase system-type
    ('darwin
     (host--show-tools "open" "pbcopy" "pbpaste"))
    ('gnu/linux
     (if (host--running-wsl-p)
         (host--show-tools "wslview" "xdg-open" "explorer.exe" "clip.exe"
                           "powershell.exe" "pwsh.exe")
       (host--show-tools "xdg-open" "wl-copy" "wl-paste" "xclip" "xsel")))
    (_
     (when (host--windows-like-p)
       (host--show-tools "python" "py" "explorer.exe" "clip.exe"
                         "powershell.exe" "pwsh.exe" "winget")))))

(defun host--setup-macos ()
  "Print or apply macOS host setup commands."
  (host--section "macOS host setup")
  (unless (host--have-p "brew")
    (host--say "Homebrew is required for the macOS package setup below.")
    (host--say "Install Homebrew from https://brew.sh, then rerun this target.")
    (when host--install
      (error "Homebrew is required for HOST_INSTALL=1 on macOS")))
  (host--run-shell
   "brew install aspell cmake direnv fd icarus-verilog jq llvm node pandoc pipx python ripgrep ruff shellcheck uv verilator")
  ;; Verible is maintained in the CHIPS Alliance tap rather than Homebrew core,
  ;; so keep it separate from the main package batch. If that optional tap is
  ;; temporarily unavailable, the rest of the host setup should still complete.
  (host--say "Verible is installed from the CHIPS Alliance Homebrew tap.")
  (host--run-optional-shell
   "brew tap chipsalliance/verible && brew install verible"
   "Verible SystemVerilog tools")
  (host--run-optional-shell
   "npm install -g @mermaid-js/mermaid-cli typescript-language-server vscode-langservers-extracted yaml-language-server"
   "Node-based language servers and Mermaid CLI")
  (host--run-shell "pipx ensurepath")
  (host--run-shell (host--pipx-install-command "basedpyright"))
  (host--run-shell (host--pipx-install-command "sqlparse")))

(defun host--setup-debian-like ()
  "Print or apply Ubuntu/Debian host setup commands."
  (host--section "Ubuntu/Debian host setup")
  (host--run-shell "sudo apt-get update")
  (host--run-shell
   "sudo apt-get install -y aspell build-essential clang-format clangd cmake curl direnv fd-find gdb git iverilog jq libtool-bin lldb nodejs npm pandoc pipx python3 python3-pip python3-venv ripgrep shellcheck verilator wl-clipboard xclip xsel xdg-utils")
  (host--run-optional-shell
   "npm install -g @mermaid-js/mermaid-cli typescript-language-server vscode-langservers-extracted yaml-language-server"
   "Node-based language servers and Mermaid CLI")
  (host--run-shell "python3 -m pipx ensurepath")
  (host--run-shell (host--pipx-install-command "basedpyright"))
  (host--run-shell (host--pipx-install-command "ruff"))
  (host--run-shell (host--pipx-install-command "sqlparse"))
  (when (or (host--have-p "fdfind") (not host--install))
    (host--run-shell
     "mkdir -p \"$HOME/.local/bin\" && ln -sf \"$(command -v fdfind)\" \"$HOME/.local/bin/fd\"")))

(defun host--setup-generic-linux ()
  "Print manual generic Linux host setup guidance."
  (host--section "Generic Linux host setup")
  (host--say
   "This script only knows how to install packages automatically on Ubuntu/Debian-like systems.")
  (host--say "Install equivalents with your distribution's package manager:")
  (host--say
   "  aspell clang-format clangd cmake direnv fd iverilog jq lldb node npm pandoc pipx python3 ripgrep shellcheck verilator wl-clipboard xclip xsel xdg-utils")
  (host--say "Then install shared language tools:")
  (host--say
   "  npm install -g @mermaid-js/mermaid-cli typescript-language-server vscode-langservers-extracted yaml-language-server")
  (host--say "  pipx install basedpyright")
  (host--say "  pipx install ruff")
  (host--say "  pipx install sqlparse")
  (host--say "Install Verible from your distribution, package manager, or release packages if available."))

(defun host--setup-windows ()
  "Print or apply Windows host setup commands."
  (host--section "Windows host setup")
  (host--say "Run this target from Git Bash or another POSIX-like shell with winget on PATH.")
  (host--say "Scoop or Chocolatey equivalents are also fine if those are how the host is managed.")
  (unless (host--have-p "winget")
    (host--say "winget is required for the Windows package setup below.")
    (when host--install
      (error "winget is required for HOST_INSTALL=1 on Windows")))
  (host--run-shell "winget install --id Git.Git --exact")
  (host--run-shell "winget install --id LLVM.LLVM --exact")
  (host--run-shell "winget install --id Kitware.CMake --exact")
  (host--run-shell "winget install --id BurntSushi.ripgrep.MSVC --exact")
  (host--run-shell "winget install --id sharkdp.fd --exact")
  (host--run-shell "winget install --id jqlang.jq --exact")
  (host--run-shell "winget install --id OpenJS.NodeJS.LTS --exact")
  (host--run-shell "winget install --id Python.Python.3.13 --exact")
  (host--run-shell "winget install --id JohnMacFarlane.Pandoc --exact")
  (host--run-optional-shell
   "npm install -g @mermaid-js/mermaid-cli typescript-language-server vscode-langservers-extracted yaml-language-server"
   "Node-based language servers and Mermaid CLI")
  (host--run-shell "py -m pip install --user pipx")
  (host--run-shell "py -m pipx ensurepath")
  (host--run-shell "py -m pipx install basedpyright || py -m pipx upgrade basedpyright")
  (host--run-shell "py -m pipx install ruff || py -m pipx upgrade ruff")
  (host--run-shell "py -m pipx install sqlparse || py -m pipx upgrade sqlparse"))

(defun host--setup-current-platform ()
  "Print or apply setup commands for the current platform."
  (pcase system-type
    ('darwin
     (host--setup-macos))
    ('gnu/linux
     (if (host--debian-like-p)
         (host--setup-debian-like)
       (host--setup-generic-linux)))
    (_
     (if (host--windows-like-p)
         (host--setup-windows)
       (host--section "Unsupported host")
       (host--say "Unsupported OS: %s" system-type)
       (host--say "Use the README's optional external tools list as a manual checklist.")))))

(defun host--main ()
  "Run the host setup helper."
  (setq host--install (host--env-flag-p "HOST_INSTALL"))
  (if host--install
      (host--say "HOST_INSTALL=1: commands will be executed.")
    (host--say
     "Dry run: commands are printed only. Run 'make host HOST_INSTALL=1' to execute them."))
  (host--show-tool-status)
  (host--setup-current-platform)
  (host--section "User environment")
  (host--say "Run 'make user' to check shell editor variables, PATH, terminal/tmux settings, and MCP client setup.")
  (host--section "After host setup")
  (host--say "Restart your shell if PATH changed, then run:")
  (host--say "  make user")
  (host--say "  make setup")
  (host--say "  make test")
  (host--say "Project-local tools such as pytest, black, debugpy, and codelldb are still best installed per project."))

(condition-case err
    (host--main)
  (error
   (host--say "Host setup failed: %s" (error-message-string err))
   (kill-emacs 1)))

;;; host.el ends here
