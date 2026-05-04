;;; tahoma-rust.el --- Rust development support -*- lexical-binding: t; -*-

;;; Commentary:
;; Rust has a strong standard toolchain, so this module keeps Emacs close to
;; cargo, rustfmt, and rust-analyzer instead of inventing parallel workflows.
;; It also makes Cargo.toml pleasant enough to edit and leaves tree-sitter as a
;; transparent upgrade when local grammars are installed.

;;; Code:

(require 'compile)
(require 'eglot)
(require 'flymake)
(require 'subr-x)
(require 'tahoma-project)
(require 'use-package)

(defvar rust-format-on-save)
(defvar rust-indent-offset)
(defvar rust-ts-mode-indent-offset)

(declare-function rust-format-buffer "rust-mode")

(defgroup my/rust nil
  "Rust development defaults."
  :group 'tools)

(defcustom my/rust-basic-offset 4
  "Default indentation width for Rust buffers."
  :type 'integer
  :group 'my/rust)

(defcustom my/rust-fill-column 100
  "Default fill column for Rust buffers."
  :type 'integer
  :group 'my/rust)

(defcustom my/rust-cargo-command "cargo"
  "Cargo executable used by project commands."
  :type 'string
  :group 'my/rust)

(defcustom my/rust-analyzer-command '("rust-analyzer")
  "Language server command for Rust buffers."
  :type '(repeat string)
  :group 'my/rust)

(defcustom my/rust-format-on-save t
  "When non-nil, format Rust buffers before saving."
  :type 'boolean
  :group 'my/rust)

(defconst my/rust-mode-hooks
  '(rust-mode-hook rust-ts-mode-hook)
  "Hooks used by Rust major modes in package and tree-sitter Emacs.")

(defun my/rust-cargo-root ()
  "Return the nearest Cargo project root, falling back to `my/project-root'."
  (let ((cargo-root (locate-dominating-file default-directory "Cargo.toml")))
    (file-name-as-directory (or cargo-root (my/project-root)))))

(defun my/rust-cargo-command-line (subcommand)
  "Build a shell command for cargo SUBCOMMAND."
  (string-join
   (delq nil (list (shell-quote-argument my/rust-cargo-command)
                   (unless (or (null subcommand)
                               (string-empty-p subcommand))
                     subcommand)))
   " "))

(defun my/rust-cargo (subcommand &optional edit-command)
  "Run cargo SUBCOMMAND from the nearest Cargo project root.
With prefix argument EDIT-COMMAND, prompt with the generated command before
running it."
  (interactive (list (read-string "Cargo command: " "check")
                     current-prefix-arg))
  (let ((default-directory (my/rust-cargo-root))
        (compile-command (my/rust-cargo-command-line subcommand)))
    (if edit-command
        (call-interactively #'compile)
      (compile compile-command))))

(defun my/rust-cargo-build (&optional edit-command)
  "Run `cargo build'."
  (interactive "P")
  (my/rust-cargo "build" edit-command))

(defun my/rust-cargo-check (&optional edit-command)
  "Run `cargo check'."
  (interactive "P")
  (my/rust-cargo "check" edit-command))

(defun my/rust-cargo-clippy (&optional edit-command)
  "Run `cargo clippy --all-targets'."
  (interactive "P")
  (my/rust-cargo "clippy --all-targets" edit-command))

(defun my/rust-cargo-fmt (&optional edit-command)
  "Run `cargo fmt --all'."
  (interactive "P")
  (my/rust-cargo "fmt --all" edit-command))

(defun my/rust-cargo-run (&optional edit-command)
  "Run `cargo run'."
  (interactive "P")
  (my/rust-cargo "run" edit-command))

(defun my/rust-cargo-test (&optional edit-command)
  "Run `cargo test'."
  (interactive "P")
  (my/rust-cargo "test" edit-command))

(defun my/rust-format-buffer ()
  "Format the current Rust buffer.
Use rust-analyzer when Eglot manages the buffer, then fall back to rust-mode's
rustfmt integration, and finally to normal indentation."
  (interactive)
  (condition-case err
      (cond
       ((and (fboundp 'eglot-managed-p) (eglot-managed-p))
        (eglot-format-buffer))
       ((fboundp 'rust-format-buffer)
        (rust-format-buffer))
       (t
        (indent-region (point-min) (point-max))))
    (error
     (message "Rust formatter unavailable (%s); using indentation instead"
              (error-message-string err))
     (indent-region (point-min) (point-max)))))

(defun my/rust-format-before-save ()
  "Format the current buffer before saving when configured to do so."
  (when my/rust-format-on-save
    (my/rust-format-buffer)))

(defun my/rust-language-server-available-p ()
  "Return non-nil when the configured Rust language server is available."
  (and my/rust-analyzer-command
       (executable-find (car my/rust-analyzer-command))))

(defun my/rust-eglot-ensure ()
  "Start rust-analyzer through Eglot for file-backed Rust buffers."
  (when (and buffer-file-name (my/rust-language-server-available-p))
    (eglot-ensure)))

(defun my/rust-mode-setup ()
  "Enable local defaults for Rust buffers."
  (setq-local indent-tabs-mode nil)
  (setq-local tab-width my/rust-basic-offset)
  (setq-local fill-column my/rust-fill-column)
  (setq-local show-trailing-whitespace t)
  (setq-local rust-indent-offset my/rust-basic-offset)
  (when (boundp 'rust-ts-mode-indent-offset)
    (setq-local rust-ts-mode-indent-offset my/rust-basic-offset))
  (flymake-mode 1)
  (add-hook 'before-save-hook #'my/rust-format-before-save nil t)
  (local-set-key (kbd "C-c b") #'my/rust-cargo-build)
  (local-set-key (kbd "C-c c") #'my/rust-cargo-check)
  (local-set-key (kbd "C-c l") #'my/rust-cargo-clippy)
  (local-set-key (kbd "C-c f") #'my/rust-format-buffer)
  (local-set-key (kbd "C-c F") #'my/rust-cargo-fmt)
  (local-set-key (kbd "C-c r") #'my/rust-cargo-run)
  (local-set-key (kbd "C-c t") #'my/rust-cargo-test)
  (local-set-key (kbd "C-c C-c") #'my/rust-cargo)
  (local-set-key (kbd "C-c e") #'eglot)
  (my/rust-eglot-ensure))

(defun my/rust-toml-mode-setup ()
  "Enable local defaults useful for Cargo.toml buffers."
  (setq-local indent-tabs-mode nil)
  (setq-local tab-width 2)
  (when (and buffer-file-name
             (string= (file-name-nondirectory buffer-file-name) "Cargo.toml"))
    (local-set-key (kbd "C-c c") #'my/rust-cargo-check)
    (local-set-key (kbd "C-c t") #'my/rust-cargo-test)
    (local-set-key (kbd "C-c r") #'my/rust-cargo-run)
    (local-set-key (kbd "C-c C-c") #'my/rust-cargo)))

(defun my/rust-enable-treesit-remaps ()
  "Prefer tree-sitter Rust and TOML modes when grammars are installed."
  (when (and (boundp 'treesit-language-source-alist)
             (boundp 'major-mode-remap-alist))
    (dolist (source '((rust "https://github.com/tree-sitter/tree-sitter-rust")
                      (toml "https://github.com/tree-sitter/tree-sitter-toml")))
      (add-to-list 'treesit-language-source-alist source)))
  (when (and (boundp 'major-mode-remap-alist)
             (fboundp 'treesit-ready-p))
    (when (and (fboundp 'rust-ts-mode) (treesit-ready-p 'rust t))
      (add-to-list 'major-mode-remap-alist '(rust-mode . rust-ts-mode)))
    (when (and (fboundp 'toml-ts-mode) (treesit-ready-p 'toml t))
      (add-to-list 'major-mode-remap-alist '(conf-toml-mode . toml-ts-mode)))))

;; rust-mode is the fallback major mode when the local tree-sitter grammar is
;; not installed. The local before-save hook owns formatting so package-global
;; save formatting remains disabled.
(use-package rust-mode
  :mode ("\\.rs\\'" . rust-mode)
  :hook (rust-mode . my/rust-mode-setup)
  :custom
  (rust-format-on-save nil))

;; Cargo.toml matters almost as much as source files in Rust projects. The
;; built-in TOML mode is enough unless tree-sitter grammars are installed.
(use-package conf-mode
  :ensure nil
  :mode (("Cargo\\.toml\\'" . conf-toml-mode)
         ("\\.toml\\'" . conf-toml-mode))
  :hook (conf-toml-mode . my/rust-toml-mode-setup))

(use-package eglot
  :ensure nil
  :commands (eglot eglot-ensure)
  :config
  (when my/rust-analyzer-command
    (add-to-list 'eglot-server-programs
                 `((rust-mode rust-ts-mode) . ,my/rust-analyzer-command))))

(dolist (hook my/rust-mode-hooks)
  (add-hook hook #'my/rust-mode-setup))

(add-hook 'toml-ts-mode-hook #'my/rust-toml-mode-setup)

(my/rust-enable-treesit-remaps)

(provide 'tahoma-rust)

;;; tahoma-rust.el ends here
