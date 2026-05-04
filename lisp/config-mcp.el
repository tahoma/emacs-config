;;; config-mcp.el --- MCP endpoint support for external agents -*- lexical-binding: t; -*-

;;; Commentary:
;; The rest of this config lets Emacs launch agent CLIs. This module turns the
;; direction around: Emacs can expose selected, read-only Elisp development
;; capabilities to external MCP clients. The stdio bridge still requires a
;; running Emacs daemon, so startup remains explicit instead of silently opening
;; a control surface on every Emacs launch.

;;; Code:

(require 'subr-x)
(require 'use-package)

(defvar elisp-dev-mcp-additional-allowed-dirs)
(defvar mcp-server-lib--running)

(declare-function elisp-dev-mcp-disable "elisp-dev-mcp")
(declare-function elisp-dev-mcp-enable "elisp-dev-mcp")
(declare-function mcp-server-lib-describe-setup "mcp-server-lib-commands")
(declare-function mcp-server-lib-show-metrics "mcp-server-lib-commands")
(declare-function mcp-server-lib-start "mcp-server-lib-commands")
(declare-function mcp-server-lib-stop "mcp-server-lib-commands")

(defcustom my/mcp-install-directory user-emacs-directory
  "Directory where the Emacs MCP stdio bridge script is installed."
  :type 'directory
  :group 'tools)

(defcustom my/mcp-server-name "elisp-dev"
  "External MCP client name for the Elisp development server."
  :type 'string
  :group 'tools)

(defcustom my/mcp-server-id "elisp-dev-mcp"
  "Server identifier used by `mcp-server-lib' for Elisp development tools."
  :type 'string
  :group 'tools)

(defcustom my/mcp-elisp-dev-init-function "elisp-dev-mcp-enable"
  "Function called by the stdio bridge when an MCP client connects."
  :type 'string
  :group 'tools)

(defcustom my/mcp-elisp-dev-stop-function "elisp-dev-mcp-disable"
  "Function called by the stdio bridge when an MCP client disconnects."
  :type 'string
  :group 'tools)

(defcustom my/mcp-elisp-dev-allowed-dirs
  (mapcar (lambda (relative-directory)
            (expand-file-name relative-directory user-emacs-directory))
          '("lisp/" "scripts/" "tests/"))
  "Trusted first-party Elisp directories exposed to `elisp-dev-mcp'.
These directories are intentionally narrow: they let agents read this config's
source through the Elisp MCP source reader without granting access to arbitrary
files under `user-emacs-directory'."
  :type '(repeat directory)
  :group 'tools)

(defun my/mcp-stdio-script-path ()
  "Return the installed stdio bridge script path."
  (expand-file-name "emacs-mcp-stdio.sh" my/mcp-install-directory))

(defun my/mcp-package-stdio-script-path ()
  "Return the stdio bridge script path from the installed package."
  (when-let ((library (locate-library "mcp-server-lib")))
    (let ((script (expand-file-name "emacs-mcp-stdio.sh"
                                    (file-name-directory library))))
      (when (file-exists-p script)
        script))))

(defun my/mcp-install-stdio-script ()
  "Install or freshen the Emacs MCP stdio bridge script."
  (interactive)
  (require 'mcp-server-lib)
  (let ((source (my/mcp-package-stdio-script-path))
        (target (my/mcp-stdio-script-path)))
    (unless source
      (user-error "Cannot find emacs-mcp-stdio.sh in mcp-server-lib package"))
    (make-directory (file-name-directory target) t)
    (copy-file source target t)
    (set-file-modes target #o755)
    (when (called-interactively-p 'any)
      (message "Installed Emacs MCP stdio bridge: %s" target))
    target))

(defun my/mcp-apply-elisp-dev-allowed-dirs ()
  "Apply the trusted source directories used by `elisp-dev-mcp'."
  (setq elisp-dev-mcp-additional-allowed-dirs
        (mapcar #'file-name-as-directory
                (mapcar #'expand-file-name my/mcp-elisp-dev-allowed-dirs))))

(defun my/mcp-enable-elisp-dev ()
  "Register the Elisp development MCP tools."
  (interactive)
  (require 'elisp-dev-mcp)
  (my/mcp-apply-elisp-dev-allowed-dirs)
  (elisp-dev-mcp-enable)
  (when (called-interactively-p 'any)
    (message "Enabled Elisp MCP tools")))

(defun my/mcp-disable-elisp-dev ()
  "Unregister the Elisp development MCP tools."
  (interactive)
  (require 'elisp-dev-mcp)
  (elisp-dev-mcp-disable)
  (when (called-interactively-p 'any)
    (message "Disabled Elisp MCP tools")))

(defun my/mcp-start ()
  "Start the Emacs MCP server and register Elisp development tools."
  (interactive)
  (require 'mcp-server-lib-commands)
  (my/mcp-enable-elisp-dev)
  (unless (and (boundp 'mcp-server-lib--running)
               mcp-server-lib--running)
    (mcp-server-lib-start))
  (when (called-interactively-p 'any)
    (message "Started Emacs MCP server")))

(defun my/mcp-stop ()
  "Stop the Emacs MCP server after unregistering Elisp tools."
  (interactive)
  (require 'mcp-server-lib-commands)
  (my/mcp-disable-elisp-dev)
  (when (and (boundp 'mcp-server-lib--running)
             mcp-server-lib--running)
    (mcp-server-lib-stop))
  (when (called-interactively-p 'any)
    (message "Stopped Emacs MCP server")))

(defun my/mcp-elisp-dev-stdio-command ()
  "Return the stdio command external MCP clients should run."
  (list (my/mcp-stdio-script-path)
        (format "--init-function=%s" my/mcp-elisp-dev-init-function)
        (format "--stop-function=%s" my/mcp-elisp-dev-stop-function)
        (format "--server-id=%s" my/mcp-server-id)))

(defun my/mcp-command-line (command)
  "Return shell-quoted COMMAND list as a command line."
  (mapconcat #'shell-quote-argument command " "))

(defun my/mcp-copy-elisp-dev-stdio-command ()
  "Copy the Elisp development MCP stdio command to the kill ring."
  (interactive)
  (kill-new (my/mcp-command-line (my/mcp-elisp-dev-stdio-command)))
  (message "Copied Elisp MCP stdio command"))

(use-package mcp-server-lib
  :commands (mcp-server-lib-describe-setup
             mcp-server-lib-show-metrics
             mcp-server-lib-start
             mcp-server-lib-stop)
  :bind (("C-c a m s" . my/mcp-start)
         ("C-c a m x" . my/mcp-stop)
         ("C-c a m i" . my/mcp-install-stdio-script)
         ("C-c a m c" . my/mcp-copy-elisp-dev-stdio-command)
         ("C-c a m d" . mcp-server-lib-describe-setup)
         ("C-c a m M" . mcp-server-lib-show-metrics)))

(use-package elisp-dev-mcp
  :commands (elisp-dev-mcp-enable elisp-dev-mcp-disable)
  :init
  (my/mcp-apply-elisp-dev-allowed-dirs))

(provide 'config-mcp)

;;; config-mcp.el ends here
