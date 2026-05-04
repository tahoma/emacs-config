;;; config-snippets.el --- First-party snippets and templates -*- lexical-binding: t; -*-

;;; Commentary:
;; Snippets are most useful when they encode the small structures a developer
;; actually reaches for: tests, module skeletons, and repeated local idioms.
;; This config keeps snippets in the repository instead of depending on a large
;; external bundle, so they can be reviewed and evolved like the rest of the
;; configuration.

;;; Code:

(require 'use-package)

(declare-function yas-global-mode "yasnippet")
(declare-function yas-insert-snippet "yasnippet")
(declare-function yas-new-snippet "yasnippet")
(declare-function yas-reload-all "yasnippet")
(declare-function yas-visit-snippet-file "yasnippet")

(defcustom my/snippets-directory
  (expand-file-name "snippets/" user-emacs-directory)
  "Directory containing first-party Yasnippet snippets."
  :type 'directory
  :group 'convenience)

;; Keep snippet ownership explicit. Users can add more directories through
;; Custom, but the repo-owned snippets stay first so local project idioms win.
(use-package yasnippet
  :demand t
  :commands (yas-insert-snippet
             yas-minor-mode
             yas-new-snippet
             yas-reload-all
             yas-visit-snippet-file)
  :bind (("C-c y i" . yas-insert-snippet)
         ("C-c y n" . yas-new-snippet)
         ("C-c y r" . yas-reload-all)
         ("C-c y v" . yas-visit-snippet-file))
  :init
  (setq yas-snippet-dirs (list my/snippets-directory)
        yas-wrap-around-region t)
  :config
  (when (file-directory-p my/snippets-directory)
    (let ((inhibit-message noninteractive))
      (yas-reload-all)))
  (yas-global-mode 1))

(provide 'config-snippets)

;;; config-snippets.el ends here
