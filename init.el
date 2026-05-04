;;; init.el --- Small vanilla Emacs starter config -*- lexical-binding: t; -*-

;;; Commentary:
;; Keep startup obvious: add the first-party library directory, load each
;; configuration module in dependency order, then load Custom's generated file
;; last so hand-written configuration remains the source of truth.

;;; Code:

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

(require 'config-package)
(require 'config-ui)
(require 'config-editing)
(require 'config-platform)
(require 'config-terminal)
(require 'config-project)
(require 'config-project-commands)
(require 'config-workspace)
(require 'config-files)
(require 'config-buffers)
(require 'config-completion)
(require 'config-snippets)
(require 'config-diagnostics)
(require 'config-debug)
(require 'config-environment)
(require 'config-tools)
(require 'config-vc)
(require 'config-agent)
(require 'config-elisp)
(require 'config-c)
(require 'config-sql)
(require 'config-rust)
(require 'config-js)
(require 'config-markup)
(require 'config-python)
(require 'config-treesit)

;; Keep Custom settings out of init.el so hand-written config stays tidy.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

(provide 'init)

;;; init.el ends here
