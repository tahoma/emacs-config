;;; setup.el --- Bootstrap this Emacs config -*- lexical-binding: t; -*-

;;; Commentary:
;; Install package dependencies for a fresh clone of this repository.

;;; Code:

(require 'package)

;; The setup script may be run from Make, directly from Emacs, or from another
;; directory. Resolve the repo root from this file so all paths stay stable.
(defconst emacs-config-setup-root
  (file-name-directory
   (directory-file-name
    (file-name-directory
     (or load-file-name buffer-file-name)))))

;; Keep this list explicit so `make setup' installs every package needed before
;; the first interactive launch. Built-in packages are intentionally omitted.
(defconst emacs-config-setup-packages
  '(use-package
    helpful
    vertico
    orderless
    marginalia
    consult
    embark
    embark-consult
    which-key
    corfu
    cape
    yasnippet
    dape
    envrc
    exec-path-from-shell
    vterm
    magit
    diff-hl
    vundo
    transient
    with-editor
    paredit
    rainbow-delimiters
    aggressive-indent
    eros
    macrostep
    package-lint
    clang-format
    cmake-mode
    sqlformat
    sqlup-mode
    sql-indent
    rust-mode
    typescript-mode
    web-mode
    json-mode
    add-node-modules-path
    markdown-mode
    yaml-mode
    mermaid-mode
    pyvenv
    pip-requirements))

;; Mirror init.el's archive configuration so setup can run before init.el has
;; loaded and still fetch packages from the same sources.
(setq package-archives
      '(("gnu" . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa" . "https://melpa.org/packages/")))

;; Keep package selection deterministic when a package is available from more
;; than one archive.
(setq package-archive-priorities
      '(("gnu" . 20)
        ("nongnu" . 10)
        ("melpa" . 0)))

(package-initialize)

;; Always refresh during setup so a fresh clone sees current package metadata
;; before installing dependencies.
(package-refresh-contents)

;; Install only missing packages so the setup rule is safe to rerun.
(dolist (package emacs-config-setup-packages)
  (unless (package-installed-p package)
    (package-install package)))

;; Load the real config after packages are present. This catches configuration
;; errors during setup instead of deferring them to the next GUI launch.
(load (expand-file-name "init.el" emacs-config-setup-root) nil t)

;; Force native module compilation during setup instead of on first use.
(require 'vterm)

;; Freshen local byte-compiled files after dependencies and native modules are
;; ready. This keeps a fresh clone fast without checking generated .elc files
;; into git.
(load (expand-file-name "scripts/compile.el" emacs-config-setup-root) nil t)

(message "Emacs config setup complete")

;;; setup.el ends here
