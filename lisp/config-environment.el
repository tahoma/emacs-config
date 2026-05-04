;;; config-environment.el --- Project-local environment loading -*- lexical-binding: t; -*-

;;; Commentary:
;; Modern projects often describe their toolchain in the repository itself:
;; Python virtualenvs, cross-compilers, cloud credentials, SDK paths, feature
;; flags, or per-client database URLs. direnv keeps those decisions in .envrc
;; files, and envrc teaches Emacs to see the same environment as the shell once
;; a project has been explicitly allowed.

;;; Code:

(require 'use-package)

(declare-function envrc-allow "envrc")
(declare-function envrc-deny "envrc")
(declare-function envrc-global-mode "envrc")
(declare-function envrc-reload "envrc")

(defcustom my/environment-direnv-executable "direnv"
  "direnv executable used by envrc."
  :type 'string
  :group 'tools)

(defcustom my/environment-auto-enable-direnv t
  "When non-nil, enable envrc globally when direnv is installed."
  :type 'boolean
  :group 'tools)

(defun my/environment-direnv-available-p ()
  "Return non-nil when `my/environment-direnv-executable' is available."
  (not (null (executable-find my/environment-direnv-executable))))

(defun my/environment-enable-envrc ()
  "Enable envrc when both configuration and the direnv executable allow it."
  (interactive)
  (if (my/environment-direnv-available-p)
      (envrc-global-mode 1)
    (when (called-interactively-p 'interactive)
      (message "direnv executable not found; envrc global mode not enabled"))))

;; envrc is intentionally quiet until direnv exists and a project .envrc has
;; been allowed. This keeps Emacs startup portable while still making
;; environment hydration automatic on machines that use direnv.
(use-package envrc
  :commands (envrc-allow envrc-deny envrc-global-mode envrc-reload)
  :bind (("C-c E a" . envrc-allow)
         ("C-c E d" . envrc-deny)
         ("C-c E e" . my/environment-enable-envrc)
         ("C-c E r" . envrc-reload))
  :config
  (when my/environment-auto-enable-direnv
    (my/environment-enable-envrc)))

(provide 'config-environment)

;;; config-environment.el ends here
