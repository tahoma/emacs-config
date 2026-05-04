;;; tahoma-markup.el --- Markup and data-file editing support -*- lexical-binding: t; -*-

;;; Commentary:
;; Project glue tends to live in Markdown, Mermaid, YAML, and JSON files. This
;; module gives those formats enough first-class support to be comfortable
;; without turning lightweight config/document editing into a heavyweight IDE.

;;; Code:

(require 'compile)
(require 'eglot)
(require 'flymake)
(require 'subr-x)
(require 'treesit nil t)
(require 'use-package)

(declare-function gfm-mode "markdown-mode")
(declare-function markdown-mode "markdown-mode")
(declare-function markdown-preview "markdown-mode")
(declare-function mermaid-mode "mermaid-mode")
(declare-function yaml-mode "yaml-mode")

(defvar js-indent-level)
(defvar json-ts-mode-indent-offset)
(defvar markdown-command)
(defvar markdown-code-lang-modes)
(defvar markdown-fontify-code-blocks-natively)
(defvar mermaid-flags)
(defvar mermaid-mmdc-location)
(defvar yaml-indent-offset)
(defvar yaml-ts-mode-indent-offset)

(defgroup my/markup nil
  "Markdown, Mermaid, YAML, and JSON editing defaults."
  :group 'tools)

(defcustom my/markup-basic-offset 2
  "Default indentation width for markup and data buffers."
  :type 'integer
  :group 'my/markup)

(defcustom my/markup-fill-column 100
  "Default fill column for prose-adjacent markup and data files."
  :type 'integer
  :group 'my/markup)

(defcustom my/markup-json-language-server-command
  '("vscode-json-language-server" "--stdio")
  "Language server command for JSON buffers."
  :type '(repeat string)
  :group 'my/markup)

(defcustom my/markup-jq-command "jq"
  "jq executable used by `my/markup-json-jq-region-or-buffer'."
  :type 'string
  :group 'my/markup)

(defcustom my/markup-yaml-language-server-command
  '("yaml-language-server" "--stdio")
  "Language server command for YAML buffers."
  :type '(repeat string)
  :group 'my/markup)

(defcustom my/markup-mermaid-cli-command "mmdc"
  "Mermaid CLI executable used to render Mermaid diagrams."
  :type 'string
  :group 'my/markup)

(defcustom my/markup-mermaid-cli-extra-args nil
  "Additional arguments passed to the Mermaid CLI renderer."
  :type '(repeat string)
  :group 'my/markup)

(defcustom my/markup-mermaid-output-extension "svg"
  "File extension used by Mermaid render commands."
  :type '(choice (const :tag "SVG" "svg")
                 (const :tag "PNG" "png")
                 (const :tag "PDF" "pdf")
                 string)
  :group 'my/markup)

(defconst my/markup-markdown-mode-hooks
  '(markdown-mode-hook gfm-mode-hook)
  "Hooks used by Markdown major modes.")

(defconst my/markup-json-mode-hooks
  '(json-mode-hook json-ts-mode-hook)
  "Hooks used by JSON major modes.")

(defconst my/markup-yaml-mode-hooks
  '(yaml-mode-hook yaml-ts-mode-hook)
  "Hooks used by YAML major modes.")

(defun my/markup--server-available-p (command)
  "Return non-nil when language-server COMMAND is executable."
  (and command (executable-find (car command))))

(defun my/markup-fill-region-or-paragraph ()
  "Fill the active region or current paragraph."
  (interactive)
  (if (use-region-p)
      (fill-region (region-beginning) (region-end))
    (fill-paragraph)))

(defun my/markup-detect-markdown-command ()
  "Return a Markdown-to-HTML command available on this machine."
  (cond
   ((executable-find "pandoc") "pandoc -f gfm -t html")
   ((executable-find "multimarkdown") "multimarkdown")
   ((executable-find "markdown") "markdown")
   (t nil)))

(defun my/markup-markdown-preview ()
  "Preview the current Markdown buffer when a renderer is installed."
  (interactive)
  (let ((command (or markdown-command (my/markup-detect-markdown-command))))
    (unless command
      (user-error "No Markdown renderer found; install pandoc, multimarkdown, or markdown"))
    (setq-local markdown-command command)
    (call-interactively #'markdown-preview)))

(defun my/markup-markdown-mode-setup ()
  "Enable local defaults for Markdown prose and documentation buffers."
  (setq-local fill-column my/markup-fill-column)
  (setq-local indent-tabs-mode nil)
  (setq-local tab-width my/markup-basic-offset)
  (setq-local sentence-end-double-space nil)
  (visual-line-mode 1)
  (when (fboundp 'flyspell-mode)
    (flyspell-mode 1))
  (local-set-key (kbd "C-c f") #'my/markup-fill-region-or-paragraph)
  (local-set-key (kbd "C-c p") #'my/markup-markdown-preview))

(defun my/markup-json-language-server-available-p ()
  "Return non-nil when the configured JSON language server is available."
  (my/markup--server-available-p my/markup-json-language-server-command))

(defun my/markup-json-eglot-ensure ()
  "Start JSON language-server support for file-backed JSON buffers."
  (when (and buffer-file-name (my/markup-json-language-server-available-p))
    (eglot-ensure)))

(defun my/markup-json-jq-region-or-buffer (filter)
  "Run jq FILTER over the active region or current buffer.
The command replaces the selected JSON with jq's output. Use the default filter
\".\" as a quick pretty-printer."
  (interactive (list (read-string "jq filter: " ".")))
  (let ((jq (executable-find my/markup-jq-command))
        (start (if (use-region-p) (region-beginning) (point-min)))
        (end (if (use-region-p) (region-end) (point-max))))
    (unless jq
      (user-error "No jq executable found"))
    (let ((input (buffer-substring-no-properties start end))
          (error-buffer (generate-new-buffer " *jq-errors*")))
      (unwind-protect
          (let ((output
                 (with-temp-buffer
                   (insert input)
                   (let ((status (call-process-region
                                  (point-min) (point-max)
                                  jq
                                  t
                                  (list t error-buffer)
                                  nil
                                  filter)))
                     (unless (zerop status)
                       (error "jq failed: %s"
                              (with-current-buffer error-buffer
                                (string-trim (buffer-string)))))
                     (buffer-string)))))
            (delete-region start end)
            (insert output))
        (kill-buffer error-buffer)))))

(defun my/markup-json-mode-setup ()
  "Enable local helpers for JSON buffers without replacing Prettier setup."
  (setq-local indent-tabs-mode nil)
  (setq-local tab-width my/markup-basic-offset)
  (setq-local js-indent-level my/markup-basic-offset)
  (when (boundp 'json-ts-mode-indent-offset)
    (setq-local json-ts-mode-indent-offset my/markup-basic-offset))
  (local-set-key (kbd "C-c e") #'eglot)
  (local-set-key (kbd "C-c j") #'my/markup-json-jq-region-or-buffer)
  (my/markup-json-eglot-ensure))

(defun my/markup-yaml-language-server-available-p ()
  "Return non-nil when the configured YAML language server is available."
  (my/markup--server-available-p my/markup-yaml-language-server-command))

(defun my/markup-yaml-eglot-ensure ()
  "Start YAML language-server support for file-backed YAML buffers."
  (when (and buffer-file-name (my/markup-yaml-language-server-available-p))
    (eglot-ensure)))

(defun my/markup-yaml-format-region-or-buffer ()
  "Format the active YAML region or current buffer.
Use the YAML language server when available, then fall back to indentation."
  (interactive)
  (condition-case err
      (cond
       ((and (fboundp 'eglot-managed-p) (eglot-managed-p))
        (if (use-region-p)
            (eglot-format (region-beginning) (region-end))
          (eglot-format-buffer)))
       ((use-region-p)
        (indent-region (region-beginning) (region-end)))
       (t
        (indent-region (point-min) (point-max))))
    (error
     (message "YAML formatter unavailable (%s); using indentation instead"
              (error-message-string err))
     (if (use-region-p)
         (indent-region (region-beginning) (region-end))
       (indent-region (point-min) (point-max))))))

(defun my/markup-yaml-mode-setup ()
  "Enable local defaults for YAML buffers."
  (setq-local fill-column my/markup-fill-column)
  (setq-local indent-tabs-mode nil)
  (setq-local tab-width my/markup-basic-offset)
  (setq-local show-trailing-whitespace t)
  (when (boundp 'yaml-indent-offset)
    (setq-local yaml-indent-offset my/markup-basic-offset))
  (when (boundp 'yaml-ts-mode-indent-offset)
    (setq-local yaml-ts-mode-indent-offset my/markup-basic-offset))
  (flymake-mode 1)
  (local-set-key (kbd "C-c e") #'eglot)
  (local-set-key (kbd "C-c f") #'my/markup-yaml-format-region-or-buffer)
  (my/markup-yaml-eglot-ensure))

(defun my/markup-mermaid-cli ()
  "Return the Mermaid CLI executable, if one can be found."
  (or (executable-find my/markup-mermaid-cli-command)
      my/markup-mermaid-cli-command))

(defun my/markup-mermaid-output-file ()
  "Return the render target for the current Mermaid buffer."
  (unless buffer-file-name
    (user-error "Save this Mermaid buffer before rendering it"))
  (concat (file-name-sans-extension buffer-file-name)
          "."
          my/markup-mermaid-output-extension))

(defun my/markup-mermaid-compile-command ()
  "Build the Mermaid CLI command for the current buffer."
  (unless buffer-file-name
    (user-error "Save this Mermaid buffer before rendering it"))
  (mapconcat #'shell-quote-argument
             (append (list (my/markup-mermaid-cli)
                           "-i"
                           buffer-file-name
                           "-o"
                           (my/markup-mermaid-output-file))
                     my/markup-mermaid-cli-extra-args)
             " "))

(defun my/markup-mermaid-compile (&optional edit-command)
  "Render the current Mermaid diagram with mmdc.
With prefix argument EDIT-COMMAND, prompt with the generated command before
running it."
  (interactive "P")
  (unless buffer-file-name
    (user-error "Save this Mermaid buffer before rendering it"))
  (when (buffer-modified-p)
    (save-buffer))
  (let ((compile-command (my/markup-mermaid-compile-command)))
    (if edit-command
        (call-interactively #'compile)
      (compile compile-command))))

(defun my/markup-mermaid-mode-setup ()
  "Enable local defaults for Mermaid diagram buffers."
  (setq-local fill-column my/markup-fill-column)
  (setq-local indent-tabs-mode nil)
  (setq-local tab-width my/markup-basic-offset)
  (when buffer-file-name
    (setq-local compile-command (my/markup-mermaid-compile-command)))
  (local-set-key (kbd "C-c c") #'my/markup-mermaid-compile))

(defun my/markup-enable-yaml-treesit-remaps ()
  "Prefer tree-sitter YAML mode when the grammar is installed."
  (when (and (boundp 'treesit-language-source-alist)
             (boundp 'major-mode-remap-alist))
    (add-to-list 'treesit-language-source-alist
                 '(yaml "https://github.com/ikatyang/tree-sitter-yaml")))
  (when (and (boundp 'major-mode-remap-alist)
             (fboundp 'treesit-ready-p)
             (fboundp 'yaml-ts-mode)
             (treesit-ready-p 'yaml t))
    (add-to-list 'major-mode-remap-alist '(yaml-mode . yaml-ts-mode))))

(use-package markdown-mode
  :mode (("README\\.md\\'" . gfm-mode)
         ("CHANGELOG\\.md\\'" . gfm-mode)
         ("\\.md\\'" . markdown-mode)
         ("\\.markdown\\'" . markdown-mode))
  :hook ((markdown-mode gfm-mode) . my/markup-markdown-mode-setup)
  :config
  ;; Native highlighting keeps fenced code readable without introducing a
  ;; heavier polymode setup for every Markdown buffer.
  (setq markdown-fontify-code-blocks-natively t)
  (when-let ((command (my/markup-detect-markdown-command)))
    (setq markdown-command command))
  (when (boundp 'markdown-code-lang-modes)
    (add-to-list 'markdown-code-lang-modes '("mermaid" . mermaid-mode))))

(use-package yaml-mode
  :mode (("\\.ya?ml\\'" . yaml-mode)
         ("\\.clang-format\\'" . yaml-mode)
         ("\\.clang-tidy\\'" . yaml-mode))
  :hook (yaml-mode . my/markup-yaml-mode-setup))

(use-package mermaid-mode
  :mode (("\\.mmd\\'" . mermaid-mode)
         ("\\.mermaid\\'" . mermaid-mode))
  :hook (mermaid-mode . my/markup-mermaid-mode-setup)
  :config
  ;; mermaid-mode's own commands look at these variables. Keep them aligned with
  ;; the wrapper command so either path uses the same CLI.
  (setq mermaid-mmdc-location (my/markup-mermaid-cli))
  (setq mermaid-flags (string-join my/markup-mermaid-cli-extra-args " ")))

(use-package eglot
  :ensure nil
  :commands (eglot eglot-ensure)
  :config
  (when my/markup-json-language-server-command
    (add-to-list 'eglot-server-programs
                 `((json-mode json-ts-mode)
                   . ,my/markup-json-language-server-command)))
  (when my/markup-yaml-language-server-command
    (add-to-list 'eglot-server-programs
                 `((yaml-mode yaml-ts-mode)
                   . ,my/markup-yaml-language-server-command))))

(dolist (hook my/markup-markdown-mode-hooks)
  (add-hook hook #'my/markup-markdown-mode-setup))

(dolist (hook my/markup-json-mode-hooks)
  (add-hook hook #'my/markup-json-mode-setup))

(dolist (hook my/markup-yaml-mode-hooks)
  (add-hook hook #'my/markup-yaml-mode-setup))

(add-hook 'mermaid-mode-hook #'my/markup-mermaid-mode-setup)

(my/markup-enable-yaml-treesit-remaps)

(provide 'tahoma-markup)

;;; tahoma-markup.el ends here
