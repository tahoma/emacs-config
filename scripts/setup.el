;;; setup.el --- Bootstrap this Emacs config -*- lexical-binding: t; -*-

;;; Commentary:
;; Install package dependencies for a fresh clone of this repository.

;;; Code:

(require 'package)

(defconst emacs-config-setup-root
  (file-name-directory
   (directory-file-name
    (file-name-directory
     (or load-file-name buffer-file-name)))))

(defconst emacs-config-setup-packages
  '(use-package
    helpful
    vterm
    magit
    paredit
    rainbow-delimiters
    aggressive-indent
    eros
    macrostep
    package-lint))

(setq package-archives
      '(("gnu" . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa" . "https://melpa.org/packages/")))

(setq package-archive-priorities
      '(("gnu" . 20)
        ("nongnu" . 10)
        ("melpa" . 0)))

(package-initialize)
(package-refresh-contents)

(dolist (package emacs-config-setup-packages)
  (unless (package-installed-p package)
    (package-install package)))

(load (expand-file-name "init.el" emacs-config-setup-root) nil t)

;; Force native module compilation during setup instead of on first use.
(require 'vterm)

(message "Emacs config setup complete")

;;; setup.el ends here
