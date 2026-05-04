;;; config-sql.el --- SQL editing and interactive query support -*- lexical-binding: t; -*-

;;; Commentary:
;; SQL work tends to happen in two shapes here: standalone query files and
;; embedded query fragments copied out of firmware or service code. This module
;; keeps both paths close to the built-in SQL tools while adding formatting,
;; indentation, keyword cleanup, scratch buffers, and safe connection helpers.

;;; Code:

(require 'comint)
(require 'eglot)
(require 'sql)
(require 'use-package)

(declare-function sqlformat-buffer "sqlformat")
(declare-function sqlformat-region "sqlformat")
(declare-function sqlind-minor-mode "sql-indent")
(declare-function sqlup-mode "sqlup-mode")

(defgroup my/sql nil
  "SQL editing and interactive query defaults."
  :group 'tools)

(defcustom my/sql-default-product 'ansi
  "Default SQL dialect used for highlighting new SQL buffers."
  :type '(choice (const :tag "ANSI SQL" ansi)
                 (const :tag "PostgreSQL" postgres)
                 (const :tag "SQLite" sqlite)
                 (const :tag "MySQL" mysql)
                 (const :tag "MariaDB" mariadb)
                 (const :tag "Microsoft SQL Server" ms)
                 (const :tag "Oracle" oracle)
                 symbol)
  :group 'my/sql)

(defcustom my/sql-fill-column 100
  "Default fill column for SQL buffers."
  :type 'integer
  :group 'my/sql)

(defcustom my/sql-history-file
  (expand-file-name "var/sql-history" user-emacs-directory)
  "Input history file for SQL interpreter buffers."
  :type 'file
  :group 'my/sql)

(defcustom my/sql-connections nil
  "SQL connection presets.
Values use the same shape as `sql-connection-alist'. Keep passwords out of this
git repository; prefer auth-source files such as ~/.authinfo.gpg or set
connection details from private dir-locals/custom files."
  :type '(repeat
          (cons :tag "Connection"
                (string :tag "Name")
                (repeat :tag "Settings"
                        (list (symbol :tag "SQL variable")
                              (sexp :tag "Value")))))
  :set (lambda (symbol value)
         (set-default symbol value)
         (setq sql-connection-alist value))
  :group 'my/sql)

(defcustom my/sql-language-server-command '("sqls")
  "Language server command for SQL buffers.
If the first executable is not available, SQL buffers simply skip Eglot."
  :type '(repeat string)
  :group 'my/sql)

(defvar my/sql-prefix-map (make-sparse-keymap)
  "Global prefix map for SQL commands.")

(defun my/sql--language-server-available-p ()
  "Return non-nil when the configured SQL language server is available."
  (and my/sql-language-server-command
       (executable-find (car my/sql-language-server-command))))

(defun my/sql-eglot-ensure ()
  "Start Eglot for SQL files when a SQL language server is installed."
  (when (and buffer-file-name (my/sql--language-server-available-p))
    (eglot-ensure)))

(defun my/sql-format-region-or-buffer ()
  "Format the active region or current SQL buffer.
Use sqlformat when its external formatter is available; fall back to normal
Emacs indentation if the formatter command is not installed on this machine."
  (interactive)
  (condition-case err
      (if (use-region-p)
          (if (fboundp 'sqlformat-region)
              (sqlformat-region (region-beginning) (region-end))
            (indent-region (region-beginning) (region-end)))
        (if (fboundp 'sqlformat-buffer)
            (sqlformat-buffer)
          (indent-region (point-min) (point-max))))
    (file-error
     (message "SQL formatter unavailable (%s); using indentation instead"
              (error-message-string err))
     (if (use-region-p)
         (indent-region (region-beginning) (region-end))
       (indent-region (point-min) (point-max))))))

(defun my/sql-send-region-or-buffer ()
  "Send the active region, or the whole buffer, to the current SQL process."
  (interactive)
  (if (use-region-p)
      (sql-send-region (region-beginning) (region-end))
    (sql-send-buffer)))

(defun my/sql-scratch (&optional product)
  "Open a reusable SQL scratch buffer.
With prefix argument PRODUCT, prompt for the SQL dialect to use in the scratch
buffer."
  (interactive
   (list (when current-prefix-arg
           (sql-read-product "SQL product: " my/sql-default-product))))
  (let ((buffer (get-buffer-create "*SQL Scratch*")))
    (pop-to-buffer buffer)
    (unless (derived-mode-p 'sql-mode)
      (sql-mode))
    (sql-set-product (or product my/sql-default-product))))

(defun my/sql-copy-region-to-scratch (start end)
  "Copy the region between START and END into `my/sql-scratch'.
This is handy when a query lives inside a C string, test fixture, or other
source buffer and needs to be inspected, formatted, or sent to SQLi."
  (interactive "r")
  (unless (use-region-p)
    (user-error "Select a SQL fragment first"))
  (let ((text (buffer-substring-no-properties start end)))
    (my/sql-scratch)
    (goto-char (point-max))
    (unless (bolp)
      (newline))
    (insert text)
    (unless (bolp)
      (newline))))

(defun my/sql-connect ()
  "Start a SQLi session from a preset, or prompt for a SQL product.
Connection presets come from `my/sql-connections' or `sql-connection-alist'."
  (interactive)
  (if sql-connection-alist
      (sql-connect
       (completing-read "SQL connection: "
                        (mapcar #'car sql-connection-alist)
                        nil t))
    (call-interactively #'sql-product-interactive)))

(defun my/sql-mode-setup ()
  "Enable local defaults for SQL buffers."
  (sql-set-product my/sql-default-product)
  (setq-local fill-column my/sql-fill-column)
  (setq-local indent-tabs-mode nil)
  (setq-local tab-width 2)
  (setq-local show-trailing-whitespace t)
  (when (fboundp 'sqlup-mode)
    (sqlup-mode 1))
  (when (fboundp 'sqlind-minor-mode)
    (sqlind-minor-mode 1))
  (local-set-key (kbd "C-c C-c") #'my/sql-send-region-or-buffer)
  (local-set-key (kbd "C-c C-r") #'sql-send-region)
  (local-set-key (kbd "C-c C-b") #'sql-send-buffer)
  (local-set-key (kbd "C-c C-p") #'sql-set-product)
  (local-set-key (kbd "C-c C-f") #'my/sql-format-region-or-buffer)
  (local-set-key (kbd "C-c C-z") #'sql-show-sqli-buffer)
  (my/sql-eglot-ensure))

(defun my/sql-interactive-mode-setup ()
  "Enable local defaults for SQL interpreter buffers."
  (setq-local truncate-lines t)
  (setq-local comint-input-ignoredups t)
  (when my/sql-history-file
    (make-directory (file-name-directory my/sql-history-file) t)
    (setq-local comint-input-ring-file-name my/sql-history-file))
  (when (fboundp 'sqlup-mode)
    (sqlup-mode 1)))

;; Built-in sql.el owns processes and connection management. The package
;; declarations below smooth out editing and formatting without replacing that
;; core workflow.
(use-package sql
  :ensure nil
  :mode (("\\.sql\\'" . sql-mode)
         ("\\.pgsql\\'" . sql-mode)
         ("\\.psql\\'" . sql-mode)
         ("\\.mysql\\'" . sql-mode)
         ("\\.sqlite\\'" . sql-mode)
         ("\\.sqlite3\\'" . sql-mode)
         ("\\.ddl\\'" . sql-mode)
         ("\\.dml\\'" . sql-mode))
  :hook ((sql-mode . my/sql-mode-setup)
         (sql-interactive-mode . my/sql-interactive-mode-setup))
  :custom
  (sql-input-ring-file-name my/sql-history-file)
  (sql-pop-to-buffer-after-send-region 'display-buffer)
  (sql-send-terminator t))

;; sql-indent provides the `sqlind-minor-mode' backend that sql.el's own
;; `sql-indent-enable' hook knows how to activate.
(use-package sql-indent
  :commands sqlind-minor-mode
  :hook ((sql-mode sql-interactive-mode) . sqlind-minor-mode))

;; sqlup-mode keeps hand-written queries visually consistent by uppercasing SQL
;; keywords as they are typed.
(use-package sqlup-mode
  :commands sqlup-mode
  :hook ((sql-mode sql-interactive-mode) . sqlup-mode))

;; sqlformat delegates to an external formatter such as sqlformat, pgformatter,
;; or sqlfluff. The wrapper command above falls back gracefully when no formatter
;; binary has been installed yet.
(use-package sqlformat
  :commands (sqlformat-buffer sqlformat-region))

(use-package eglot
  :ensure nil
  :config
  (when my/sql-language-server-command
    (add-to-list 'eglot-server-programs
                 `(sql-mode . ,my/sql-language-server-command))))

(define-key global-map (kbd "C-c s") my/sql-prefix-map)
(define-key my/sql-prefix-map (kbd "c") #'my/sql-connect)
(define-key my/sql-prefix-map (kbd "i") #'sql-product-interactive)
(define-key my/sql-prefix-map (kbd "s") #'my/sql-scratch)
(define-key my/sql-prefix-map (kbd "e") #'my/sql-copy-region-to-scratch)
(define-key my/sql-prefix-map (kbd "f") #'my/sql-format-region-or-buffer)

(provide 'config-sql)

;;; config-sql.el ends here
