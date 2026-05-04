;;; init.el --- Small vanilla Emacs starter config -*- lexical-binding: t; -*-

;;; Commentary:
;; Keep startup obvious: add the first-party library directory, load each
;; configuration module in dependency order, then load Custom's generated file
;; last so hand-written configuration remains the source of truth.

;;; Code:

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

(require 'tahoma-package)
(require 'tahoma-ui)
(require 'tahoma-project)
(require 'tahoma-tools)
(require 'tahoma-elisp)
(require 'tahoma-c)
(require 'tahoma-sql)

;; Keep Custom settings out of init.el so hand-written config stays tidy.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

(provide 'init)

;;; init.el ends here
