;;; config-c.el --- C and C++ development -*- lexical-binding: t; -*-

;;; Commentary:
;; C and C++ work benefits from a few things being close at hand: clangd for
;; navigation and diagnostics, clang-format, project-aware build and debug
;; commands, good completion UI, and sane modes for common adjacent tooling
;; files such as CMake, assembly, linker scripts, and GDB command files.

;;; Code:

(require 'ansi-color)
(require 'cc-mode)
(require 'compile)
(require 'eglot)
(require 'find-file)
(require 'gdb-mi)
(require 'hideshow)
(require 'config-project)
(require 'use-package)

(defgroup my/c nil
  "C and C++ development defaults."
  :group 'tools)

(defcustom my/c-basic-offset 4
  "Default indentation width for C-family buffers."
  :type 'integer
  :group 'my/c)

(defcustom my/c-fill-column 100
  "Default fill column for C-family buffers."
  :type 'integer
  :group 'my/c)

(defcustom my/c-build-command nil
  "Project build command override.
When nil, `my/c-default-compile-command' chooses a command from common
project files such as Makefiles and CMake build directories."
  :type '(choice (const :tag "Auto-detect" nil) string)
  :group 'my/c)

(defcustom my/c-clangd-arguments
  '("--background-index"
    "--clang-tidy"
    "--completion-style=detailed"
    "--header-insertion=iwyu"
    "--pch-storage=memory")
  "Arguments passed to clangd through Eglot."
  :type '(repeat string)
  :group 'my/c)

(defcustom my/c-gdb-command (or (getenv "GDB") "gdb")
  "GDB executable used by `my/c-debug'.
Set the GDB environment variable before launching Emacs, or customize this to
a target-specific debugger such as arm-none-eabi-gdb when needed."
  :type 'string
  :group 'my/c)

(defconst my/c-family-hooks
  '(c-mode-common-hook c-ts-mode-hook c++-ts-mode-hook)
  "Hooks used by C-family major modes in stock and tree-sitter Emacs.")

(defun my/c--project-file-exists-p (relative-file)
  "Return non-nil when RELATIVE-FILE exists in the current project root."
  (file-exists-p (expand-file-name relative-file (my/project-root))))

(defun my/c-default-compile-command ()
  "Choose a useful default build command for the current project."
  (cond
   ((or (my/c--project-file-exists-p "build/build.ninja")
        (my/c--project-file-exists-p "build/Makefile"))
    "cmake --build build")
   ((my/c--project-file-exists-p "Makefile")
    "make -k")
   ((my/c--project-file-exists-p "makefile")
    "make -k")
   ((my/c--project-file-exists-p "CMakePresets.json")
    "cmake --build --preset default")
   ((my/c--project-file-exists-p "CMakeLists.txt")
    "cmake -S . -B build && cmake --build build")
   (t compile-command)))

(defun my/c-compile (&optional edit-command)
  "Compile the current project.
With prefix argument EDIT-COMMAND, prompt with the detected command as the
initial value. Without a prefix, run the detected command immediately."
  (interactive "P")
  (let ((default-directory (my/project-root))
        (compile-command (or my/c-build-command
                             (my/c-default-compile-command))))
    (if edit-command
        (call-interactively #'compile)
      (compile compile-command))))

(defun my/c-recompile ()
  "Re-run the last compilation command from the current project root."
  (interactive)
  (let ((default-directory (my/project-root)))
    (recompile)))

(defun my/c-debug (program)
  "Start a GDB session for PROGRAM from the current project root."
  (interactive
   (list (read-file-name "Debug executable: " (my/project-root) nil t)))
  (let* ((default-directory (my/project-root))
         (program-path (expand-file-name program default-directory))
         (command (format "%s -i=mi %s"
                          my/c-gdb-command
                          (shell-quote-argument program-path))))
    (gdb command)))

(defun my/c-format-buffer ()
  "Format the current buffer with clang-format when available."
  (interactive)
  (if (fboundp 'clang-format-buffer)
      (clang-format-buffer)
    (indent-region (point-min) (point-max))))

(defun my/c-eglot-ensure ()
  "Start clangd through Eglot for file-backed C-family buffers."
  (when (and buffer-file-name (executable-find "clangd"))
    (eglot-ensure)))

(defun my/c-mode-setup ()
  "Enable local defaults for C and C++ development buffers."
  (when (and (fboundp 'c-set-style)
             (derived-mode-p 'c-mode 'c++-mode))
    (c-set-style "linux"))
  (setq-local c-basic-offset my/c-basic-offset)
  (setq-local tab-width my/c-basic-offset)
  (when (boundp 'c-ts-mode-indent-offset)
    (setq-local c-ts-mode-indent-offset my/c-basic-offset))
  (setq-local fill-column my/c-fill-column)
  (setq-local indent-tabs-mode nil)
  (setq-local show-trailing-whitespace t)
  (flymake-mode 1)
  (hs-minor-mode 1)
  (local-set-key (kbd "C-c b") #'my/c-compile)
  (local-set-key (kbd "C-c r") #'my/c-recompile)
  (local-set-key (kbd "C-c f") #'my/c-format-buffer)
  (local-set-key (kbd "C-c e") #'eglot)
  (local-set-key (kbd "C-c d") #'my/c-debug)
  (local-set-key (kbd "C-c o") #'ff-find-other-file)
  (my/c-eglot-ensure))

(defun my/cmake-mode-setup ()
  "Use compact, space-only indentation for CMake files."
  (setq-local indent-tabs-mode nil)
  (setq-local tab-width 2))

(defun my/c-colorize-compilation-buffer ()
  "Apply ANSI colors to new output in compilation buffers."
  (ansi-color-apply-on-region compilation-filter-start (point)))

(defun my/c-enable-treesit-remaps ()
  "Prefer tree-sitter C-family modes when the grammars are installed."
  (when (and (boundp 'treesit-language-source-alist)
             (boundp 'major-mode-remap-alist))
    (dolist (source '((c "https://github.com/tree-sitter/tree-sitter-c")
                      (cpp "https://github.com/tree-sitter/tree-sitter-cpp")
                      (cmake "https://github.com/uyha/tree-sitter-cmake")))
      (add-to-list 'treesit-language-source-alist source)))
  (when (and (boundp 'major-mode-remap-alist)
             (fboundp 'treesit-ready-p))
    (when (and (fboundp 'c-ts-mode) (treesit-ready-p 'c t))
      (add-to-list 'major-mode-remap-alist '(c-mode . c-ts-mode)))
    (when (and (fboundp 'c++-ts-mode) (treesit-ready-p 'cpp t))
      (add-to-list 'major-mode-remap-alist '(c++-mode . c++-ts-mode)))
    (when (and (fboundp 'cmake-ts-mode) (treesit-ready-p 'cmake t))
      (add-to-list 'major-mode-remap-alist '(cmake-mode . cmake-ts-mode)))))

;; clang-format reads the project's .clang-format file when one exists, so the
;; buffer command below respects each C/C++ codebase's style.
(use-package clang-format
  :commands (clang-format-buffer clang-format-region))

;; CMake is common across C and C++ projects. Use the package mode by default,
;; and transparently remap to Emacs' tree-sitter mode when the local CMake
;; grammar is installed.
(use-package cmake-mode
  :mode ("CMakeLists\\.txt\\'" "\\.cmake\\'")
  :hook (cmake-mode . my/cmake-mode-setup))

(use-package cc-mode
  :ensure nil
  :mode (("\\.h\\'" . c-or-c++-mode)
         ("\\.hh\\'" . c++-mode)
         ("\\.hpp\\'" . c++-mode)
         ("\\.hxx\\'" . c++-mode)
         ("\\.ipp\\'" . c++-mode)
         ("\\.tpp\\'" . c++-mode)
         ("\\.ino\\'" . c++-mode)))

(use-package eglot
  :ensure nil
  :commands (eglot eglot-ensure)
  :custom
  (eglot-autoshutdown t)
  (eglot-events-buffer-size 0)
  :config
  (add-to-list 'eglot-server-programs
               `((c-mode c-ts-mode c++-mode c++-ts-mode)
                 . ("clangd" ,@my/c-clangd-arguments))))

(use-package compile
  :ensure nil
  :custom
  (compilation-always-kill t)
  (compilation-ask-about-save nil)
  (compilation-scroll-output 'first-error))

(use-package ansi-color
  :ensure nil
  :hook (compilation-filter . my/c-colorize-compilation-buffer))

(use-package which-func
  :ensure nil
  :init
  (which-function-mode 1))

(use-package gdb-mi
  :ensure nil
  :commands (gdb)
  :custom
  (gdb-many-windows t)
  (gdb-show-main t))

(dolist (hook my/c-family-hooks)
  (add-hook hook #'my/c-mode-setup))

(add-hook 'cmake-ts-mode-hook #'my/cmake-mode-setup)

(my/c-enable-treesit-remaps)

;; C and C++ repositories often include assembly, linker scripts, and debugger
;; command files. These associations keep those buffers out of plain text mode.
(dolist (mode '(("\\.S\\'" . asm-mode)
                ("\\.s\\'" . asm-mode)
                ("\\.ld\\'" . ld-script-mode)
                ("\\.lds\\'" . ld-script-mode)
                ("\\.gdb\\'" . gdb-script-mode)
                ("\\.gdbinit\\'" . gdb-script-mode)
                ("openocd.*\\.cfg\\'" . conf-mode)
                ("Kconfig\\'" . conf-mode)))
  (add-to-list 'auto-mode-alist mode))

(provide 'config-c)

;;; config-c.el ends here
