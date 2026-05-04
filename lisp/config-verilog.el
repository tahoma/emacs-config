;;; config-verilog.el --- Verilog and SystemVerilog development -*- lexical-binding: t; -*-

;;; Commentary:
;; Verilog and SystemVerilog projects often mix old-school simulator flows with
;; newer Verible/Verilator tooling. Emacs already ships a capable verilog-mode,
;; so this module keeps that as the foundation and layers on project-aware
;; build/lint commands, optional formatting, and optional Eglot support when an
;; HDL language server is installed.

;;; Code:

(require 'cl-lib)
(require 'compile)
(require 'eglot)
(require 'flymake)
(require 'subr-x)
(require 'verilog-mode)
(require 'config-project)
(require 'use-package)

(declare-function verilog-auto "verilog-mode")
(declare-function verilog-indent-buffer "verilog-mode")

(defvar verilog-auto-endcomments)
(defvar verilog-auto-newline)
(defvar verilog-case-indent)
(defvar verilog-indent-level)
(defvar verilog-indent-level-behavioral)
(defvar verilog-indent-level-declaration)
(defvar verilog-indent-level-directive)
(defvar verilog-indent-level-module)
(defvar verilog-tool)

(defgroup my/verilog nil
  "Verilog and SystemVerilog development defaults."
  :group 'tools)

(defcustom my/verilog-basic-offset 2
  "Default indentation width for Verilog and SystemVerilog buffers."
  :type 'integer
  :group 'my/verilog)

(defcustom my/verilog-fill-column 100
  "Default fill column for Verilog and SystemVerilog buffers."
  :type 'integer
  :group 'my/verilog)

(defcustom my/verilog-format-on-save nil
  "When non-nil, format Verilog buffers before saving.
This is disabled by default because RTL repositories often have established
layout conventions and generated sections where automatic whole-buffer
formatting can create noisy churn."
  :type 'boolean
  :group 'my/verilog)

(defcustom my/verilog-build-command nil
  "Project build command override.
When nil, `my/verilog-default-build-command' chooses a command from common
project files and locally installed HDL tools."
  :type '(choice (const :tag "Auto-detect" nil) string)
  :group 'my/verilog)

(defcustom my/verilog-language-server-commands
  '(("verible-verilog-ls")
    ("svlangserver" "--stdio"))
  "Candidate language server commands for Verilog buffers.
The first executable command in this list is used for automatic Eglot startup."
  :type '(repeat (repeat string))
  :group 'my/verilog)

(defcustom my/verilog-project-root-files
  '("fusesoc.conf"
    "Bender.yml"
    "bender.yml"
    "edalize.yml"
    "Makefile"
    "makefile")
  "Files that mark the root of a Verilog/SystemVerilog project."
  :type '(repeat string)
  :group 'my/verilog)

(defun my/verilog-project-root ()
  "Return the nearest HDL project root, falling back to `my/project-root'."
  (file-name-as-directory
   (or (cl-some (lambda (marker)
                  (locate-dominating-file default-directory marker))
                my/verilog-project-root-files)
       (my/project-root))))

(defun my/verilog-command-line (command)
  "Return shell-quoted COMMAND list as a command line."
  (mapconcat #'shell-quote-argument command " "))

(defun my/verilog-current-file ()
  "Return the current file, or signal a user-facing error."
  (unless buffer-file-name
    (user-error "Save this Verilog buffer before running HDL tools"))
  buffer-file-name)

(defun my/verilog--project-file-exists-p (relative-file)
  "Return non-nil when RELATIVE-FILE exists in the HDL project root."
  (file-exists-p (expand-file-name relative-file (my/verilog-project-root))))

(defun my/verilog-lint-command ()
  "Return a lint command list for the current buffer, or nil."
  (let ((file (my/verilog-current-file)))
    (cond
     ((executable-find "verible-verilog-lint")
      (list "verible-verilog-lint" file))
     ((executable-find "verilator")
      (list "verilator" "--lint-only" "-Wall" file))
     ((executable-find "iverilog")
      (list "iverilog" "-Wall" "-tnull" file))
     (t nil))))

(defun my/verilog-default-build-command ()
  "Choose a useful default HDL build or lint command."
  (cond
   (my/verilog-build-command
    my/verilog-build-command)
   ((or (my/verilog--project-file-exists-p "Makefile")
        (my/verilog--project-file-exists-p "makefile"))
    "make -k")
   ((buffer-file-name)
    (or (when-let ((lint-command (my/verilog-lint-command)))
          (my/verilog-command-line lint-command))
        compile-command))
   (t compile-command)))

(defun my/verilog-run-command (command &optional edit-command)
  "Run shell COMMAND from the HDL project root.
With prefix argument EDIT-COMMAND, prompt with the generated command first."
  (let ((default-directory (my/verilog-project-root))
        (compile-command command))
    (if edit-command
        (call-interactively #'compile)
      (compile compile-command))))

(defun my/verilog-build (&optional edit-command)
  "Build or lint the current HDL project."
  (interactive "P")
  (my/verilog-run-command (my/verilog-default-build-command) edit-command))

(defun my/verilog-lint (&optional edit-command)
  "Lint the current Verilog/SystemVerilog buffer."
  (interactive "P")
  (let ((lint-command (my/verilog-lint-command)))
    (unless lint-command
      (user-error "Install verible-verilog-lint, verilator, or iverilog"))
    (my/verilog-run-command (my/verilog-command-line lint-command)
                            edit-command)))

(defun my/verilog-format-command (filename)
  "Return a formatter command for FILENAME, or nil."
  (when (executable-find "verible-verilog-format")
    (list "verible-verilog-format"
          (format "--indentation_spaces=%d" my/verilog-basic-offset)
          (format "--column_limit=%d" my/verilog-fill-column)
          (format "--stdin_name=%s" filename)
          "-")))

(defun my/verilog--format-region-with-command (command start end)
  "Format the region from START to END using formatter COMMAND."
  (let ((input (buffer-substring-no-properties start end))
        (error-buffer (generate-new-buffer " *verilog-format-errors*")))
    (unwind-protect
        (let ((output
               (with-temp-buffer
                 (insert input)
                 (let ((status (apply #'call-process-region
                                      (point-min) (point-max)
                                      (car command)
                                      t
                                      (list t error-buffer)
                                      nil
                                      (cdr command))))
                   (unless (zerop status)
                     (error "Verilog formatter failed: %s"
                            (with-current-buffer error-buffer
                              (string-trim (buffer-string)))))
                   (buffer-string)))))
          (delete-region start end)
          (insert output))
      (kill-buffer error-buffer))))

(defun my/verilog-format-region-or-buffer ()
  "Format the active region or current Verilog/SystemVerilog buffer.
Use Verible when available, then fall back to verilog-mode indentation."
  (interactive)
  (let* ((start (if (use-region-p) (region-beginning) (point-min)))
         (end (if (use-region-p) (region-end) (point-max)))
         (filename (or buffer-file-name "buffer.sv"))
         (command (my/verilog-format-command filename)))
    (condition-case err
        (cond
         (command
          (my/verilog--format-region-with-command command start end))
         ((and (not (use-region-p)) (fboundp 'verilog-indent-buffer))
          (verilog-indent-buffer))
         (t
          (indent-region start end)))
      (error
       (message "Verilog formatter unavailable (%s); using indentation instead"
                (error-message-string err))
       (if (and (not (use-region-p)) (fboundp 'verilog-indent-buffer))
           (verilog-indent-buffer)
         (indent-region start end))))))

(defun my/verilog-format-before-save ()
  "Format the current buffer before saving when configured to do so."
  (when my/verilog-format-on-save
    (my/verilog-format-region-or-buffer)))

(defun my/verilog-language-server-command ()
  "Return the first available Verilog language server command, or nil."
  (cl-some (lambda (command)
             (when (and command (executable-find (car command)))
               (copy-sequence command)))
           my/verilog-language-server-commands))

(defun my/verilog-eglot-server-command ()
  "Return a stable Eglot server command for Verilog buffers."
  (or (my/verilog-language-server-command)
      (car my/verilog-language-server-commands)))

(defun my/verilog-eglot-ensure ()
  "Start a Verilog language server through Eglot when one is installed."
  (when (and buffer-file-name (my/verilog-language-server-command))
    (eglot-ensure)))

(defun my/verilog-mode-setup ()
  "Enable local defaults for Verilog and SystemVerilog buffers."
  (setq-local indent-tabs-mode nil)
  (setq-local tab-width my/verilog-basic-offset)
  (setq-local fill-column my/verilog-fill-column)
  (setq-local show-trailing-whitespace t)
  (setq-local verilog-indent-level my/verilog-basic-offset)
  (setq-local verilog-indent-level-module my/verilog-basic-offset)
  (setq-local verilog-indent-level-declaration my/verilog-basic-offset)
  (setq-local verilog-indent-level-behavioral my/verilog-basic-offset)
  (setq-local verilog-indent-level-directive 1)
  (setq-local verilog-case-indent my/verilog-basic-offset)
  (setq-local verilog-auto-newline nil)
  (setq-local verilog-auto-endcomments t)
  (setq-local verilog-tool 'verilog-linter)
  (flymake-mode 1)
  (add-hook 'before-save-hook #'my/verilog-format-before-save nil t)
  (local-set-key (kbd "C-c b") #'my/verilog-build)
  (local-set-key (kbd "C-c l") #'my/verilog-lint)
  (local-set-key (kbd "C-c f") #'my/verilog-format-region-or-buffer)
  (local-set-key (kbd "C-c e") #'eglot)
  (local-set-key (kbd "C-c C-a") #'verilog-auto)
  (my/verilog-eglot-ensure))

;; verilog-mode is built into Emacs and has decades of HDL-specific knowledge.
;; Keep it as the major mode for both Verilog and SystemVerilog files, then make
;; external tools optional around it.
(use-package verilog-mode
  :ensure nil
  :mode (("\\.v\\'" . verilog-mode)
         ("\\.vh\\'" . verilog-mode)
         ("\\.sv\\'" . verilog-mode)
         ("\\.svh\\'" . verilog-mode)
         ("\\.sva\\'" . verilog-mode))
  :hook (verilog-mode . my/verilog-mode-setup))

(use-package eglot
  :ensure nil
  :commands (eglot eglot-ensure)
  :config
  (add-to-list 'eglot-server-programs
               `(verilog-mode . ,(my/verilog-eglot-server-command))))

(provide 'config-verilog)

;;; config-verilog.el ends here
