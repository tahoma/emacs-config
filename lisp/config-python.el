;;; config-python.el --- Python development support -*- lexical-binding: t; -*-

;;; Commentary:
;; Python projects are often shaped by a local virtual environment plus a few
;; project tools. This module keeps Emacs close to that layout: discover the
;; project root, prefer project-local executables, run pytest and ruff from the
;; root, format with ruff or black, and start Eglot only when a Python language
;; server is actually available.

;;; Code:

(require 'cl-lib)
(require 'compile)
(require 'eglot)
(require 'flymake)
(require 'python)
(require 'subr-x)
(require 'config-project)
(require 'treesit nil t)
(require 'use-package)

(declare-function pip-requirements-mode "pip-requirements")
(declare-function pyvenv-activate "pyvenv")
(declare-function pyvenv-deactivate "pyvenv")

(defvar python-indent-offset)
(defvar python-shell-interpreter)
(defvar python-shell-interpreter-args)
(defvar python-ts-mode-indent-offset)

(defgroup my/python nil
  "Python development defaults."
  :group 'tools)

(defcustom my/python-basic-offset 4
  "Default indentation width for Python buffers."
  :type 'integer
  :group 'my/python)

(defcustom my/python-fill-column 88
  "Default fill column for Python buffers.
The default follows the line length used by black and ruff format."
  :type 'integer
  :group 'my/python)

(defcustom my/python-format-on-save t
  "When non-nil, format Python buffers before saving."
  :type 'boolean
  :group 'my/python)

(defcustom my/python-default-interpreter "python3"
  "Fallback Python interpreter used when no project virtualenv is found."
  :type 'string
  :group 'my/python)

(defcustom my/python-project-root-files
  '("pyproject.toml"
    "setup.cfg"
    "setup.py"
    "requirements.txt"
    "tox.ini"
    "noxfile.py"
    "Pipfile"
    "uv.lock"
    "poetry.lock")
  "Files that mark the root of a Python project."
  :type '(repeat string)
  :group 'my/python)

(defcustom my/python-venv-directories '(".venv" "venv" "env")
  "Virtual environment directory names to prefer inside Python projects."
  :type '(repeat string)
  :group 'my/python)

(defcustom my/python-language-server-commands
  '(("basedpyright-langserver" "--stdio")
    ("pyright-langserver" "--stdio")
    ("pylsp"))
  "Candidate language server commands for Python buffers.
The first executable command in this list is used by automatic Eglot startup."
  :type '(repeat (repeat string))
  :group 'my/python)

(defconst my/python-mode-hooks '(python-mode-hook python-ts-mode-hook)
  "Hooks used by Python source modes.")

(defun my/python-project-root ()
  "Return the nearest Python project root, falling back to `my/project-root'."
  (file-name-as-directory
   (or (cl-some (lambda (marker)
                  (locate-dominating-file default-directory marker))
                my/python-project-root-files)
       (my/project-root))))

(defun my/python-venv-root ()
  "Return a detected virtualenv directory for the current Python project."
  (let ((root (my/python-project-root)))
    (cl-some (lambda (directory)
               (let ((candidate (expand-file-name directory root)))
                 (when (file-directory-p candidate)
                   candidate)))
             my/python-venv-directories)))

(defun my/python-venv-bin-dir ()
  "Return the executable directory for the detected virtualenv."
  (when-let ((venv-root (my/python-venv-root)))
    (let ((bin-dir (expand-file-name
                    (if (eq system-type 'windows-nt) "Scripts" "bin")
                    venv-root)))
      (when (file-directory-p bin-dir)
        bin-dir))))

(defun my/python-local-executable (name)
  "Return project-local executable NAME, or nil when it is unavailable."
  (when-let ((bin-dir (my/python-venv-bin-dir)))
    (let ((candidate (expand-file-name name bin-dir)))
      (cond
       ((file-executable-p candidate) candidate)
       ((and (eq system-type 'windows-nt)
             (file-executable-p (concat candidate ".exe")))
        (concat candidate ".exe"))
       (t nil)))))

(defun my/python-executable ()
  "Return the Python executable to use for the current project."
  (or (my/python-local-executable "python")
      (executable-find my/python-default-interpreter)
      (executable-find "python3")
      (executable-find "python")
      my/python-default-interpreter))

(defun my/python-tool-command (tool)
  "Return an executable command list for Python TOOL.
Prefer project-local executables. If no executable exists, fall back to running
TOOL as a Python module through the project interpreter."
  (cond
   ((my/python-local-executable tool)
    (list (my/python-local-executable tool)))
   ((and (file-exists-p (expand-file-name "uv.lock" (my/python-project-root)))
         (executable-find "uv"))
    (list (executable-find "uv") "run" tool))
   ((and (file-exists-p (expand-file-name "poetry.lock" (my/python-project-root)))
         (executable-find "poetry"))
    (list (executable-find "poetry") "run" tool))
   ((executable-find tool)
    (list (executable-find tool)))
   (t
    (list (my/python-executable) "-m" tool))))

(defun my/python-command-line (command)
  "Return shell-quoted COMMAND list as a string."
  (mapconcat #'shell-quote-argument command " "))

(defun my/python-run-command (command &optional edit-command)
  "Run shell COMMAND from the Python project root.
With prefix argument EDIT-COMMAND, prompt with the generated command first."
  (let ((default-directory (my/python-project-root))
        (compile-command (my/python-command-line command)))
    (if edit-command
        (call-interactively #'compile)
      (compile compile-command))))

(defun my/python-compile-file (&optional edit-command)
  "Byte-compile the current Python file with py_compile."
  (interactive "P")
  (unless buffer-file-name
    (user-error "Save this Python buffer before compiling it"))
  (my/python-run-command
   (list (my/python-executable) "-m" "py_compile" buffer-file-name)
   edit-command))

(defun my/python-check (&optional edit-command)
  "Run `ruff check .' from the Python project root."
  (interactive "P")
  (my/python-run-command
   (append (my/python-tool-command "ruff") '("check" "."))
   edit-command))

(defun my/python-test (&optional edit-command)
  "Run pytest from the Python project root."
  (interactive "P")
  (my/python-run-command
   (my/python-tool-command "pytest")
   edit-command))

(defun my/python-test-file (&optional edit-command)
  "Run pytest for the current Python file."
  (interactive "P")
  (unless buffer-file-name
    (user-error "Save this Python buffer before testing it"))
  (my/python-run-command
   (append (my/python-tool-command "pytest") (list buffer-file-name))
   edit-command))

(defun my/python-run-file (&optional edit-command)
  "Run the current Python file."
  (interactive "P")
  (unless buffer-file-name
    (user-error "Save this Python buffer before running it"))
  (my/python-run-command
   (list (my/python-executable) buffer-file-name)
   edit-command))

(defun my/python-format-command (filename)
  "Return a formatter command for FILENAME, or nil when none is available."
  (cond
   ((or (my/python-local-executable "ruff") (executable-find "ruff"))
    (append (my/python-tool-command "ruff")
            (list "format" "--stdin-filename" filename "-")))
   ((or (my/python-local-executable "black") (executable-find "black"))
    (append (my/python-tool-command "black")
            (list "--quiet" "--stdin-filename" filename "-")))
   (t nil)))

(defun my/python--format-region-with-command (command start end)
  "Format the region from START to END using formatter COMMAND."
  (let ((input (buffer-substring-no-properties start end))
        (error-buffer (generate-new-buffer " *python-format-errors*")))
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
                     (error "Python formatter failed: %s"
                            (with-current-buffer error-buffer
                              (string-trim (buffer-string)))))
                   (buffer-string)))))
          (delete-region start end)
          (insert output))
      (kill-buffer error-buffer))))

(defun my/python-format-region-or-buffer ()
  "Format the active region or current Python buffer.
Use ruff format or black when available, then fall back to indentation."
  (interactive)
  (let* ((start (if (use-region-p) (region-beginning) (point-min)))
         (end (if (use-region-p) (region-end) (point-max)))
         (filename (or buffer-file-name "buffer.py"))
         (command (my/python-format-command filename)))
    (condition-case err
        (cond
         (command
          (my/python--format-region-with-command command start end))
         ((and (fboundp 'eglot-managed-p) (eglot-managed-p))
          (if (use-region-p)
              (eglot-format start end)
            (eglot-format-buffer)))
         (t
          (indent-region start end)))
      (error
       (message "Python formatter unavailable (%s); using indentation instead"
                (error-message-string err))
       (indent-region start end)))))

(defun my/python-format-before-save ()
  "Format the current buffer before saving when configured to do so."
  (when my/python-format-on-save
    (my/python-format-region-or-buffer)))

(defun my/python-language-server-command ()
  "Return the first configured Python language-server command available."
  (cl-find-if (lambda (command)
                (and command (executable-find (car command))))
              my/python-language-server-commands))

(defun my/python-eglot-contact (_interactive _project)
  "Return a Python language-server contact for Eglot."
  (or (my/python-language-server-command)
      (car my/python-language-server-commands)))

(defun my/python-language-server-available-p ()
  "Return non-nil when a configured Python language server is available."
  (not (null (my/python-language-server-command))))

(defun my/python-eglot-ensure ()
  "Start Eglot for file-backed Python buffers when a server is installed."
  (when (and buffer-file-name (my/python-language-server-available-p))
    (eglot-ensure)))

(defun my/python-add-venv-bin-to-path ()
  "Add the detected virtualenv bin directory to buffer-local lookup paths."
  (when-let ((bin-dir (my/python-venv-bin-dir)))
    (setq-local exec-path (cons bin-dir exec-path))
    (setq-local process-environment
                (cons (format "PATH=%s:%s"
                              bin-dir
                              (or (getenv "PATH") ""))
                      process-environment))))

(defun my/python-activate-venv (&optional directory)
  "Activate a Python virtualenv with pyvenv.
When DIRECTORY is nil, prefer a detected project virtualenv."
  (interactive
   (list (let ((detected (my/python-venv-root)))
           (if detected
               detected
             (read-directory-name "Virtualenv: "
                                  (my/python-project-root))))))
  (unless (fboundp 'pyvenv-activate)
    (user-error "pyvenv is not installed"))
  (pyvenv-activate (or directory (my/python-venv-root))))

(defun my/python-repl ()
  "Start or switch to an inferior Python process for the current project."
  (interactive)
  (let ((default-directory (my/python-project-root))
        (python-shell-interpreter (my/python-executable)))
    (run-python nil nil t)))

(defun my/python-mode-setup ()
  "Enable local defaults for Python buffers."
  (my/python-add-venv-bin-to-path)
  (setq-local indent-tabs-mode nil)
  (setq-local tab-width my/python-basic-offset)
  (setq-local fill-column my/python-fill-column)
  (setq-local show-trailing-whitespace t)
  (setq-local python-indent-offset my/python-basic-offset)
  (setq-local python-shell-interpreter (my/python-executable))
  (setq-local python-shell-interpreter-args "-i")
  (when (boundp 'python-ts-mode-indent-offset)
    (setq-local python-ts-mode-indent-offset my/python-basic-offset))
  (flymake-mode 1)
  (add-hook 'before-save-hook #'my/python-format-before-save nil t)
  (local-set-key (kbd "C-c b") #'my/python-compile-file)
  (local-set-key (kbd "C-c c") #'my/python-check)
  (local-set-key (kbd "C-c e") #'eglot)
  (local-set-key (kbd "C-c f") #'my/python-format-region-or-buffer)
  (local-set-key (kbd "C-c i") #'my/python-repl)
  (local-set-key (kbd "C-c r") #'my/python-run-file)
  (local-set-key (kbd "C-c t") #'my/python-test)
  (local-set-key (kbd "C-c T") #'my/python-test-file)
  (local-set-key (kbd "C-c v") #'my/python-activate-venv)
  (local-set-key (kbd "C-c V") #'pyvenv-deactivate)
  (my/python-eglot-ensure))

(defun my/python-toml-mode-setup ()
  "Enable Python project keys in pyproject.toml and Pipfile buffers."
  (when (and buffer-file-name
             (member (file-name-nondirectory buffer-file-name)
                     '("pyproject.toml" "Pipfile")))
    (setq-local tab-width 2)
    (local-set-key (kbd "C-c c") #'my/python-check)
    (local-set-key (kbd "C-c t") #'my/python-test)
    (local-set-key (kbd "C-c v") #'my/python-activate-venv)))

(defun my/python-enable-treesit-remaps ()
  "Prefer tree-sitter Python mode when the grammar is installed."
  (when (and (boundp 'treesit-language-source-alist)
             (boundp 'major-mode-remap-alist))
    (add-to-list 'treesit-language-source-alist
                 '(python "https://github.com/tree-sitter/tree-sitter-python")))
  (when (and (boundp 'major-mode-remap-alist)
             (fboundp 'treesit-ready-p)
             (fboundp 'python-ts-mode)
             (treesit-ready-p 'python t))
    (add-to-list 'major-mode-remap-alist '(python-mode . python-ts-mode))))

;; Built-in python.el owns indentation, shell interaction, and tree-sitter mode.
;; This config layers project commands and virtualenv discovery on top.
(use-package python
  :ensure nil
  :mode (("\\.py\\'" . python-mode)
         ("\\.pyi\\'" . python-mode)
         ("SConstruct\\'" . python-mode)
         ("SConscript\\'" . python-mode))
  :interpreter ("python3" . python-mode)
  :hook ((python-mode python-ts-mode) . my/python-mode-setup)
  :custom
  (python-indent-offset my/python-basic-offset))

(use-package pyvenv
  :commands (pyvenv-activate pyvenv-deactivate pyvenv-workon))

(use-package pip-requirements
  :mode (("\\(?:requirements\\|constraints\\).*\\.txt\\'"
          . pip-requirements-mode)))

(use-package conf-mode
  :ensure nil
  :mode ("Pipfile\\'" . conf-toml-mode)
  :hook (conf-toml-mode . my/python-toml-mode-setup))

(add-hook 'toml-ts-mode-hook #'my/python-toml-mode-setup)

(use-package eglot
  :ensure nil
  :commands (eglot eglot-ensure)
  :config
  (add-to-list 'eglot-server-programs
               `((python-mode python-ts-mode) . ,#'my/python-eglot-contact)))

(dolist (hook my/python-mode-hooks)
  (add-hook hook #'my/python-mode-setup))

(my/python-enable-treesit-remaps)

(provide 'config-python)

;;; config-python.el ends here
