;;; config-debug.el --- Optional DAP debugging with Dape -*- lexical-binding: t; -*-

;;; Commentary:
;; Dape gives Emacs a Debug Adapter Protocol client without replacing the
;; language-specific build, test, and run helpers elsewhere in this config. This
;; module only provides the editor-side controls and leaves adapter binaries
;; project-specific: debugpy for Python, codelldb/lldb-dap for native code and
;; Rust, and JavaScript adapters where a Node project expects them.

;;; Code:

(require 'use-package)

(declare-function dape "dape")
(declare-function dape-breakpoint-remove-all "dape")
(declare-function dape-breakpoint-toggle "dape")
(declare-function dape-continue "dape")
(declare-function dape-info "dape")
(declare-function dape-kill "dape")
(declare-function dape-next "dape")
(declare-function dape-restart "dape")
(declare-function dape-step-in "dape")
(declare-function dape-step-out "dape")

(defcustom my/debug-dape-buffer-arrangement 'right
  "Preferred Dape window arrangement when the variable is available."
  :type 'symbol
  :group 'tools)

(defcustom my/debug-dape-inlay-hints t
  "When non-nil, enable Dape inlay hints when supported by the package."
  :type 'boolean
  :group 'tools)

(defun my/debug-configure-dape ()
  "Apply Dape settings that are available in the installed package version."
  (when (boundp 'dape-buffer-window-arrangement)
    (setq dape-buffer-window-arrangement
          my/debug-dape-buffer-arrangement))
  (when (boundp 'dape-inlay-hints)
    (setq dape-inlay-hints my/debug-dape-inlay-hints)))

;; Keep the prefix uppercase so it does not collide with language-local C-c d
;; bindings such as C/C++ debug launch helpers.
(use-package dape
  :commands (dape
             dape-breakpoint-remove-all
             dape-breakpoint-toggle
             dape-continue
             dape-info
             dape-kill
             dape-next
             dape-restart
             dape-step-in
             dape-step-out)
  :bind (("C-c D d" . dape)
         ("C-c D b" . dape-breakpoint-toggle)
         ("C-c D B" . dape-breakpoint-remove-all)
         ("C-c D c" . dape-continue)
         ("C-c D i" . dape-info)
         ("C-c D k" . dape-kill)
         ("C-c D n" . dape-next)
         ("C-c D r" . dape-restart)
         ("C-c D s" . dape-step-in)
         ("C-c D o" . dape-step-out))
  :config
  (my/debug-configure-dape))

(provide 'config-debug)

;;; config-debug.el ends here
