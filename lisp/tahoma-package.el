;;; tahoma-package.el --- Package management for this Emacs config -*- lexical-binding: t; -*-

;;; Commentary:
;; Keep package setup explicit so a fresh clone behaves like a normal Emacs
;; config, while still allowing MELPA packages where the built-in archives do
;; not have what this setup needs.

;;; Code:

(require 'package)

(setq package-archives
      '(("gnu" . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa" . "https://melpa.org/packages/")))

;; Prefer official archives when a package exists in more than one place, and
;; use MELPA as the wider ecosystem fallback.
(setq package-archive-priorities
      '(("gnu" . 20)
        ("nongnu" . 10)
        ("melpa" . 0)))

(package-initialize)

;; Emacs 30 ships use-package, but older supported installs may not. Bootstrap
;; it here so the rest of the config can use one declarative package shape.
(unless (require 'use-package nil t)
  (unless package-archive-contents
    (package-refresh-contents))
  (package-install 'use-package)
  (require 'use-package))

;; This config is small enough that package declarations should install their
;; dependencies automatically instead of requiring a separate package list in
;; init.el. Fresh-machine setup still has an explicit package list in
;; scripts/setup.el for predictable bootstrapping.
(setq use-package-always-ensure t)

(provide 'tahoma-package)

;;; tahoma-package.el ends here
