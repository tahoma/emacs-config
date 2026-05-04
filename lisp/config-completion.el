;;; config-completion.el --- Completion, search, and command discovery -*- lexical-binding: t; -*-

;;; Commentary:
;; This module improves the stock Emacs command surface without replacing the
;; built-in concepts underneath it. Vertico makes minibuffer candidates easy to
;; scan, Orderless makes fuzzy-ish matching predictable, Marginalia annotates
;; candidates with useful context, Consult provides project-aware search and
;; navigation commands, Embark turns the thing at point into an action menu, and
;; Which-Key makes multi-key prefixes self-documenting while the bindings are
;; still new to muscle memory.

;;; Code:

(require 'use-package)
(require 'config-project)

(declare-function cape-dabbrev "cape")
(declare-function cape-file "cape")
(declare-function cape-keyword "cape")

(defcustom my/completion-preview-delay 0.25
  "Preview delay, in seconds, for Consult commands that show live previews."
  :type 'number
  :group 'convenience)

(defcustom my/completion-corfu-count 14
  "Number of Corfu completion candidates to show at once."
  :type 'integer
  :group 'convenience)

(defun my/completion-project-root ()
  "Return the project root used by project-scoped completion commands."
  (file-name-as-directory (my/project-root)))

(defun my/completion-consult-find ()
  "Find a file from the current project root with Consult."
  (interactive)
  (consult-find (my/completion-project-root)))

(defun my/completion-consult-ripgrep ()
  "Search the current project root with ripgrep through Consult."
  (interactive)
  (consult-ripgrep (my/completion-project-root)))

(defun my/completion-consult-line-multi ()
  "Search visible project buffers with Consult."
  (interactive)
  (consult-line-multi
   (lambda (buffer)
     (with-current-buffer buffer
       (string-prefix-p (my/completion-project-root)
                        (or buffer-file-name default-directory))))))

;; Vertico keeps the minibuffer vertical and predictable. It deliberately works
;; with Emacs' standard completion APIs, so every package benefits without
;; needing package-specific configuration.
(use-package vertico
  :custom
  (vertico-cycle t)
  (vertico-count 15)
  :init
  (vertico-mode 1))

;; Orderless matching lets "buf init" match candidates such as
;; "consult-buffer init.el" without requiring exact substring order.
(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles basic partial-completion)))))

;; Corfu is the in-buffer companion to Vertico: completion-at-point stays
;; standard, while candidates from Eglot, modes, tags, and CAPE appear in a
;; compact popup near point.
(use-package corfu
  :custom
  (corfu-auto t)
  (corfu-count my/completion-corfu-count)
  (corfu-cycle t)
  (corfu-on-exact-match nil)
  (corfu-preview-current nil)
  :init
  (global-corfu-mode 1))

;; CAPE adds small completion-at-point helpers that work even when a language
;; server is absent: file paths, words from open buffers, and mode keywords.
;; They are appended so major-mode and Eglot completions keep first refusal.
(use-package cape
  :init
  (dolist (backend '(cape-file cape-dabbrev cape-keyword))
    (unless (memq backend (default-value 'completion-at-point-functions))
      (set-default 'completion-at-point-functions
                   (append (default-value 'completion-at-point-functions)
                           (list backend))))))

;; Marginalia adds lightweight annotations in the minibuffer: file metadata,
;; command doc hints, variable values, and other context that prevents needless
;; trips into help buffers.
(use-package marginalia
  :init
  (marginalia-mode 1))

;; Consult supplies modern replacements for high-traffic stock commands while
;; still composing with project.el, xref, recentf, and the standard completion
;; system.
(use-package consult
  :bind (("C-s" . consult-line)
         ("M-y" . consult-yank-pop)
         ("C-x b" . consult-buffer)
         ("C-x 4 b" . consult-buffer-other-window)
         ("C-c p b" . consult-project-buffer)
         ("C-c p f" . my/completion-consult-find)
         ("C-c p g" . my/completion-consult-ripgrep)
         ("C-c p l" . my/completion-consult-line-multi)
         ("C-c p r" . consult-recent-file))
  :custom
  (consult-preview-key (list :debounce my/completion-preview-delay 'any)))

;; Embark is the "act on this thing" layer. It is especially helpful in Consult
;; buffers where a candidate can become a file visit, grep export, kill action,
;; or symbol lookup without leaving the minibuffer flow.
(use-package embark
  :bind (("C-." . embark-act)
         ("C-;" . embark-dwim)
         ("C-h B" . embark-bindings))
  :custom
  (prefix-help-command #'embark-prefix-help-command))

(use-package embark-consult
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;; Which-Key turns prefix maps into living documentation. That is useful for a
;; config intentionally organized around discoverable prefixes such as C-c p.
(use-package which-key
  :custom
  (which-key-idle-delay 0.5)
  (which-key-idle-secondary-delay 0.05)
  :init
  (which-key-mode 1)
  :config
  ;; which-key-mode installs its own C-h dispatcher as prefix help. Put Embark
  ;; back in that slot so C-h on a prefix opens the richer action-aware help
  ;; buffer while Which-Key still displays idle prefix hints.
  (setq prefix-help-command #'embark-prefix-help-command))

(provide 'config-completion)

;;; config-completion.el ends here
