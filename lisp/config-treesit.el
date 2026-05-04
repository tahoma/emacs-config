;;; config-treesit.el --- Tree-sitter grammar management -*- lexical-binding: t; -*-

;;; Commentary:
;; Language modules register tree-sitter grammar sources close to the modes that
;; use them. This module adds the missing operational layer: inspect configured
;; grammars, install one grammar, or install every missing configured grammar
;; from a single Emacs command.

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'treesit nil t)
(require 'use-package)

(defcustom my/treesit-default-language-sources
  '((c "https://github.com/tree-sitter/tree-sitter-c")
    (cpp "https://github.com/tree-sitter/tree-sitter-cpp")
    (cmake "https://github.com/uyha/tree-sitter-cmake")
    (javascript "https://github.com/tree-sitter/tree-sitter-javascript" nil "src")
    (json "https://github.com/tree-sitter/tree-sitter-json")
    (python "https://github.com/tree-sitter/tree-sitter-python")
    (rust "https://github.com/tree-sitter/tree-sitter-rust")
    (toml "https://github.com/tree-sitter/tree-sitter-toml")
    (tsx "https://github.com/tree-sitter/tree-sitter-typescript" nil "tsx/src")
    (typescript "https://github.com/tree-sitter/tree-sitter-typescript" nil "typescript/src")
    (yaml "https://github.com/ikatyang/tree-sitter-yaml"))
  "Tree-sitter grammar sources this config knows how to install.
Language modules also register the sources they use. Keeping a central list here
makes the management commands useful even when a mode-specific remap was skipped
because the local grammar is not installed yet."
  :type 'sexp
  :group 'tools)

(defun my/treesit-available-p ()
  "Return non-nil when this Emacs has built-in tree-sitter support."
  (and (featurep 'treesit)
       (fboundp 'treesit-install-language-grammar)
       (boundp 'treesit-language-source-alist)))

(defun my/treesit-register-default-sources ()
  "Register tree-sitter grammar sources known to this config."
  (when (my/treesit-available-p)
    (dolist (source my/treesit-default-language-sources)
      (add-to-list 'treesit-language-source-alist source))))

(defun my/treesit-configured-languages ()
  "Return configured tree-sitter languages in display order."
  (when (my/treesit-available-p)
    (sort (delete-dups (mapcar #'car treesit-language-source-alist))
          (lambda (left right)
            (string< (symbol-name left) (symbol-name right))))))

(defun my/treesit-language-ready-p (language)
  "Return non-nil when LANGUAGE's grammar is installed."
  (and (my/treesit-available-p)
       (fboundp 'treesit-ready-p)
       (treesit-ready-p language t)))

(defun my/treesit-read-language ()
  "Read a configured tree-sitter language from the minibuffer."
  (unless (my/treesit-available-p)
    (user-error "This Emacs does not have tree-sitter grammar support"))
  (let* ((languages (my/treesit-configured-languages))
         (names (mapcar #'symbol-name languages))
         (choice (completing-read "Grammar: " names nil t)))
    (intern choice)))

(defun my/treesit-install-language (language)
  "Install or update the tree-sitter grammar for LANGUAGE."
  (interactive (list (my/treesit-read-language)))
  (unless (assoc language treesit-language-source-alist)
    (user-error "No tree-sitter grammar source registered for %s" language))
  (treesit-install-language-grammar language))

(defun my/treesit-install-missing-grammars ()
  "Install every configured tree-sitter grammar that is not ready."
  (interactive)
  (unless (my/treesit-available-p)
    (user-error "This Emacs does not have tree-sitter grammar support"))
  (dolist (language (my/treesit-configured-languages))
    (unless (my/treesit-language-ready-p language)
      (message "Installing tree-sitter grammar: %s" language)
      (my/treesit-install-language language))))

(defun my/treesit-status ()
  "Show configured tree-sitter grammars and whether each is installed."
  (interactive)
  (let ((buffer (get-buffer-create "*tree-sitter grammars*")))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (erase-buffer)
        (if (not (my/treesit-available-p))
            (insert "Tree-sitter grammar support is not available in this Emacs.\n")
          (insert "Tree-sitter grammar status\n\n")
          (dolist (language (my/treesit-configured-languages))
            (insert (format "%-16s %s\n"
                            language
                            (if (my/treesit-language-ready-p language)
                                "ready"
                              "missing")))))
        (goto-char (point-min))
        (special-mode)))
    (pop-to-buffer buffer)))

(global-set-key (kbd "C-c l s") #'my/treesit-status)
(global-set-key (kbd "C-c l i") #'my/treesit-install-language)
(global-set-key (kbd "C-c l a") #'my/treesit-install-missing-grammars)

(my/treesit-register-default-sources)

(provide 'config-treesit)

;;; config-treesit.el ends here
