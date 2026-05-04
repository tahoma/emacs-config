;;; config-js.el --- JavaScript and TypeScript development support -*- lexical-binding: t; -*-

;;; Commentary:
;; JavaScript projects vary wildly in toolchain shape, so this module keeps the
;; defaults project-aware: use TypeScript language server when present, prefer a
;; project-local Prettier binary, find node_modules/.bin for one-off tools, and
;; pick npm/yarn/pnpm/bun from lockfiles for common scripts.

;;; Code:

(require 'compile)
(require 'eglot)
(require 'flymake)
(require 'js)
(require 'subr-x)
(require 'config-project)
(require 'treesit nil t)
(require 'use-package)

(declare-function add-node-modules-path "add-node-modules-path")
(declare-function typescript-mode "typescript-mode")
(declare-function web-mode "web-mode")

(defvar js-indent-level)
(defvar json-reformat:indent-width)
(defvar typescript-indent-level)
(defvar typescript-ts-mode-indent-offset)
(defvar web-mode-code-indent-offset)
(defvar web-mode-css-indent-offset)
(defvar web-mode-markup-indent-offset)

(defgroup my/js nil
  "JavaScript and TypeScript development defaults."
  :group 'tools)

(defcustom my/js-basic-offset 2
  "Default indentation width for JavaScript, TypeScript, JSON, and TSX."
  :type 'integer
  :group 'my/js)

(defcustom my/js-fill-column 100
  "Default fill column for JavaScript and TypeScript buffers."
  :type 'integer
  :group 'my/js)

(defcustom my/js-format-on-save t
  "When non-nil, format JavaScript and TypeScript buffers before saving."
  :type 'boolean
  :group 'my/js)

(defcustom my/js-package-manager nil
  "Package manager override for JavaScript projects.
When nil, `my/js-detect-package-manager' chooses from project lockfiles."
  :type '(choice (const :tag "Auto-detect" nil)
                 (const :tag "npm" "npm")
                 (const :tag "yarn" "yarn")
                 (const :tag "pnpm" "pnpm")
                 (const :tag "bun" "bun")
                 string)
  :group 'my/js)

(defcustom my/js-language-server-command
  '("typescript-language-server" "--stdio")
  "Language server command for JavaScript and TypeScript buffers."
  :type '(repeat string)
  :group 'my/js)

(defconst my/js-source-mode-hooks
  '(js-mode-hook
    js-ts-mode-hook
    js-jsx-mode-hook
    typescript-mode-hook
    typescript-ts-mode-hook
    tsx-ts-mode-hook
    web-mode-hook)
  "Hooks used by JavaScript and TypeScript source modes.")

(defconst my/js-json-mode-hooks
  '(json-mode-hook json-ts-mode-hook)
  "Hooks used by JSON modes.")

(defun my/js-project-root ()
  "Return the nearest package.json project root, falling back to project root."
  (let ((package-root (locate-dominating-file default-directory "package.json")))
    (file-name-as-directory (or package-root (my/project-root)))))

(defun my/js-detect-package-manager ()
  "Detect the JavaScript package manager for the current project."
  (or my/js-package-manager
      (let ((root (my/js-project-root)))
        (cond
         ((file-exists-p (expand-file-name "pnpm-lock.yaml" root)) "pnpm")
         ((file-exists-p (expand-file-name "yarn.lock" root)) "yarn")
         ((or (file-exists-p (expand-file-name "bun.lockb" root))
              (file-exists-p (expand-file-name "bun.lock" root)))
          "bun")
         (t "npm")))))

(defun my/js-package-script-command (script)
  "Build a package-manager command for running SCRIPT."
  (let ((manager (my/js-detect-package-manager)))
    (pcase manager
      ("npm" (format "%s run %s"
                     (shell-quote-argument manager)
                     (shell-quote-argument script)))
      ("yarn" (format "%s %s"
                      (shell-quote-argument manager)
                      (shell-quote-argument script)))
      ("pnpm" (format "%s %s"
                      (shell-quote-argument manager)
                      (shell-quote-argument script)))
      ("bun" (format "%s run %s"
                     (shell-quote-argument manager)
                     (shell-quote-argument script)))
      (_ (format "%s run %s"
                 (shell-quote-argument manager)
                 (shell-quote-argument script))))))

(defun my/js-run-script (script &optional edit-command)
  "Run package SCRIPT from the nearest package.json root.
With prefix argument EDIT-COMMAND, prompt with the generated command before
running it."
  (interactive (list (read-string "Package script: " "test")
                     current-prefix-arg))
  (let ((default-directory (my/js-project-root))
        (compile-command (my/js-package-script-command script)))
    (if edit-command
        (call-interactively #'compile)
      (compile compile-command))))

(defun my/js-build (&optional edit-command)
  "Run the package build script."
  (interactive "P")
  (my/js-run-script "build" edit-command))

(defun my/js-install (&optional edit-command)
  "Install JavaScript project dependencies."
  (interactive "P")
  (let* ((default-directory (my/js-project-root))
         (manager (my/js-detect-package-manager))
         (compile-command (if (string= manager "yarn")
                              "yarn install"
                            (format "%s install"
                                    (shell-quote-argument manager)))))
    (if edit-command
        (call-interactively #'compile)
      (compile compile-command))))

(defun my/js-lint (&optional edit-command)
  "Run the package lint script."
  (interactive "P")
  (my/js-run-script "lint" edit-command))

(defun my/js-start (&optional edit-command)
  "Run the package start script."
  (interactive "P")
  (my/js-run-script "start" edit-command))

(defun my/js-test (&optional edit-command)
  "Run the package test script."
  (interactive "P")
  (my/js-run-script "test" edit-command))

(defun my/js-node-modules-bin ()
  "Return the local node_modules/.bin directory when it exists."
  (let ((bin-dir (expand-file-name "node_modules/.bin" (my/js-project-root))))
    (when (file-directory-p bin-dir)
      bin-dir)))

(defun my/js-add-node-modules-bin ()
  "Add local node_modules/.bin to buffer-local command lookup paths."
  (when (fboundp 'add-node-modules-path)
    (add-node-modules-path))
  (when-let ((bin-dir (my/js-node-modules-bin)))
    (setq-local exec-path (cons bin-dir exec-path))
    (setq-local process-environment
                (cons (format "PATH=%s:%s"
                              bin-dir
                              (or (getenv "PATH") ""))
                      process-environment))))

(defun my/js-prettier-command ()
  "Return a project-local or global prettier executable, if one exists."
  (let ((local-prettier (expand-file-name "node_modules/.bin/prettier"
                                          (my/js-project-root))))
    (cond
     ((file-executable-p local-prettier) local-prettier)
     ((executable-find "prettier"))
     (t nil))))

(defun my/js--format-region-with-prettier (start end)
  "Format the region from START to END with prettier."
  (let* ((prettier (my/js-prettier-command))
         (filename (or buffer-file-name
                       (pcase major-mode
                         ('json-mode "buffer.json")
                         ('json-ts-mode "buffer.json")
                         ('typescript-mode "buffer.ts")
                         ('typescript-ts-mode "buffer.ts")
                         ('tsx-ts-mode "buffer.tsx")
                         ('web-mode "buffer.tsx")
                         (_ "buffer.js"))))
         (args (list "--stdin-filepath" filename))
         (input (buffer-substring-no-properties start end))
         (error-buffer (generate-new-buffer " *prettier-errors*")))
    (unless prettier
      (user-error "No prettier executable found"))
    (unwind-protect
        (let ((output
               (with-temp-buffer
                 (insert input)
                 (let ((status (apply #'call-process-region
                                      (point-min) (point-max)
                                      prettier
                                      t
                                      (list t error-buffer)
                                      nil
                                      args)))
                   (unless (zerop status)
                     (error "prettier failed: %s"
                            (with-current-buffer error-buffer
                              (string-trim (buffer-string)))))
                   (buffer-string)))))
          (delete-region start end)
          (insert output))
      (kill-buffer error-buffer))))

(defun my/js-format-region-or-buffer ()
  "Format the active region or current buffer.
Use prettier when available, falling back to indentation otherwise."
  (interactive)
  (let ((start (if (use-region-p) (region-beginning) (point-min)))
        (end (if (use-region-p) (region-end) (point-max))))
    (condition-case err
        (my/js--format-region-with-prettier start end)
      (error
       (message "JavaScript formatter unavailable (%s); using indentation instead"
                (error-message-string err))
       (indent-region start end)))))

(defun my/js-format-before-save ()
  "Format the current buffer before saving when configured to do so."
  (when my/js-format-on-save
    (my/js-format-region-or-buffer)))

(defun my/js-language-server-available-p ()
  "Return non-nil when the configured TypeScript language server is available."
  (and my/js-language-server-command
       (executable-find (car my/js-language-server-command))))

(defun my/js-eglot-ensure ()
  "Start TypeScript language server through Eglot for file-backed source files."
  (when (and buffer-file-name (my/js-language-server-available-p))
    (eglot-ensure)))

(defun my/js-source-mode-setup ()
  "Enable local defaults for JavaScript and TypeScript source buffers."
  (my/js-add-node-modules-bin)
  (setq-local indent-tabs-mode nil)
  (setq-local tab-width my/js-basic-offset)
  (setq-local fill-column my/js-fill-column)
  (setq-local show-trailing-whitespace t)
  (setq-local js-indent-level my/js-basic-offset)
  (when (boundp 'typescript-indent-level)
    (setq-local typescript-indent-level my/js-basic-offset))
  (when (boundp 'typescript-ts-mode-indent-offset)
    (setq-local typescript-ts-mode-indent-offset my/js-basic-offset))
  (when (boundp 'web-mode-code-indent-offset)
    (setq-local web-mode-code-indent-offset my/js-basic-offset)
    (setq-local web-mode-css-indent-offset my/js-basic-offset)
    (setq-local web-mode-markup-indent-offset my/js-basic-offset))
  (flymake-mode 1)
  (add-hook 'before-save-hook #'my/js-format-before-save nil t)
  (local-set-key (kbd "C-c b") #'my/js-build)
  (local-set-key (kbd "C-c c") #'my/js-run-script)
  (local-set-key (kbd "C-c e") #'eglot)
  (local-set-key (kbd "C-c f") #'my/js-format-region-or-buffer)
  (local-set-key (kbd "C-c i") #'my/js-install)
  (local-set-key (kbd "C-c l") #'my/js-lint)
  (local-set-key (kbd "C-c r") #'my/js-start)
  (local-set-key (kbd "C-c t") #'my/js-test)
  (my/js-eglot-ensure))

(defun my/js-json-mode-setup ()
  "Enable local defaults for JSON buffers."
  (my/js-add-node-modules-bin)
  (setq-local indent-tabs-mode nil)
  (setq-local tab-width my/js-basic-offset)
  (setq-local js-indent-level my/js-basic-offset)
  (when (boundp 'json-reformat:indent-width)
    (setq-local json-reformat:indent-width my/js-basic-offset))
  (add-hook 'before-save-hook #'my/js-format-before-save nil t)
  (local-set-key (kbd "C-c f") #'my/js-format-region-or-buffer))

(defun my/js-enable-treesit-remaps ()
  "Prefer tree-sitter JS/TS/JSON modes when grammars are installed."
  (when (and (boundp 'treesit-language-source-alist)
             (boundp 'major-mode-remap-alist))
    (dolist (source '((javascript "https://github.com/tree-sitter/tree-sitter-javascript" nil "src")
                      (typescript "https://github.com/tree-sitter/tree-sitter-typescript" nil "typescript/src")
                      (tsx "https://github.com/tree-sitter/tree-sitter-typescript" nil "tsx/src")
                      (json "https://github.com/tree-sitter/tree-sitter-json")))
      (add-to-list 'treesit-language-source-alist source)))
  (when (and (boundp 'major-mode-remap-alist)
             (fboundp 'treesit-ready-p))
    (when (and (fboundp 'js-ts-mode) (treesit-ready-p 'javascript t))
      (add-to-list 'major-mode-remap-alist '(js-mode . js-ts-mode)))
    (when (and (fboundp 'typescript-ts-mode) (treesit-ready-p 'typescript t))
      (add-to-list 'major-mode-remap-alist '(typescript-mode . typescript-ts-mode)))
    (when (and (fboundp 'json-ts-mode) (treesit-ready-p 'json t))
      (add-to-list 'major-mode-remap-alist '(json-mode . json-ts-mode)))
    (when (and (fboundp 'tsx-ts-mode) (treesit-ready-p 'tsx t))
      (add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode)))))

;; Built-in js-mode handles ordinary JavaScript well. Tree-sitter remaps take
;; over automatically when the local grammar exists.
(use-package js
  :ensure nil
  :mode (("\\.js\\'" . js-mode)
         ("\\.cjs\\'" . js-mode)
         ("\\.mjs\\'" . js-mode)
         ("\\.jsx\\'" . js-jsx-mode))
  :hook ((js-mode js-ts-mode js-jsx-mode) . my/js-source-mode-setup))

;; typescript-mode is the dependable fallback for .ts files without a
;; tree-sitter grammar.
(use-package typescript-mode
  :mode ("\\.ts\\'" . typescript-mode)
  :hook (typescript-mode . my/js-source-mode-setup))

;; web-mode gives TSX/JSX projects a capable fallback when tsx-ts-mode is not
;; available locally.
(use-package web-mode
  :mode ("\\.tsx\\'" . web-mode)
  :hook (web-mode . my/js-source-mode-setup))

(use-package json-mode
  :mode (("\\.json\\'" . json-mode)
         ("\\.jsonc\\'" . json-mode)
         ("\\.eslintrc\\'" . json-mode)
         ("\\.prettierrc\\'" . json-mode))
  :hook (json-mode . my/js-json-mode-setup))

(use-package add-node-modules-path
  :commands add-node-modules-path)

(use-package eglot
  :ensure nil
  :commands (eglot eglot-ensure)
  :config
  (when my/js-language-server-command
    (add-to-list 'eglot-server-programs
                 `((js-mode js-ts-mode js-jsx-mode
                            typescript-mode typescript-ts-mode
                            tsx-ts-mode web-mode)
                   . ,my/js-language-server-command))))

(dolist (hook my/js-source-mode-hooks)
  (add-hook hook #'my/js-source-mode-setup))

(dolist (hook my/js-json-mode-hooks)
  (add-hook hook #'my/js-json-mode-setup))

(my/js-enable-treesit-remaps)

(provide 'config-js)

;;; config-js.el ends here
