;;; compile.el --- Byte-compile first-party Emacs config files -*- lexical-binding: t; -*-

;;; Commentary:
;; Byte-compile only the ELisp files owned by this repository. Generated .elc
;; files are local build artifacts and are ignored by git.

;;; Code:

(require 'package)
(require 'bytecomp)

;; Resolve paths from this file so the helper works through Make or direct
;; batch invocation from any current directory.
(defconst emacs-config-compile-root
  (file-name-directory
   (directory-file-name
    (file-name-directory
     (or load-file-name buffer-file-name)))))

(add-to-list 'load-path (expand-file-name "lisp" emacs-config-compile-root))

;; Keep this list explicit. Compiling all *.el recursively would wander into
;; package directories if ignore rules or directory layout changed later.
(defconst emacs-config-compile-files
  '("lisp/tahoma-package.el"
    "lisp/tahoma-ui.el"
    "lisp/tahoma-project.el"
    "lisp/tahoma-tools.el"
    "lisp/tahoma-elisp.el"
    "lisp/tahoma-c.el"
    "lisp/tahoma-sql.el"
    "lisp/tahoma-rust.el"
    "init.el"
    "scripts/setup.el"
    "scripts/compile.el"
    "tests/init-test.el"))

;; Byte-compiling init.el needs macro definitions from installed packages.
(package-initialize)
(require 'use-package)

(let ((byte-compile-error-on-warn nil))
  (dolist (relative-file emacs-config-compile-files)
    (let ((file (expand-file-name relative-file emacs-config-compile-root)))
      (unless (file-exists-p file)
        (error "Cannot compile missing file: %s" file))
      (message "Byte-compiling %s" relative-file)
      (unless (byte-compile-file file)
        (error "Byte-compilation failed: %s" file)))))

(message "Emacs config byte-compilation complete")

;;; compile.el ends here
