;;; config-project-commands.el --- Generic project command runner -*- lexical-binding: t; -*-

;;; Commentary:
;; Language modules provide specialized commands, but every project still needs
;; a quick way to run "the obvious command" from the repository root. This module
;; layers project-aware command selection over Emacs' built-in compilation
;; buffer so output remains searchable, clickable, and repeatable.

;;; Code:

(require 'compile)
(require 'subr-x)
(require 'config-project)
(require 'use-package)

(defcustom my/project-command-defaults
  '(("build" . "make -k")
    ("test" . "make test")
    ("lint" . "make lint")
    ("run" . "make run"))
  "Fallback project commands offered in every project."
  :type '(alist :key-type string :value-type string)
  :group 'tools)

(defvar my/project-command-history nil
  "Minibuffer history for project command strings.")

(defun my/project-command--file-exists-p (root file)
  "Return non-nil when FILE exists under ROOT."
  (file-exists-p (expand-file-name file root)))

(defun my/project-command-detected-candidates (&optional root)
  "Return command candidates detected from files under ROOT."
  (let* ((project-root (or root (my/project-root)))
         (candidates nil))
    (when (my/project-command--file-exists-p project-root "Makefile")
      (push '("make build" . "make -k") candidates)
      (push '("make test" . "make test") candidates))
    (when (my/project-command--file-exists-p project-root "package.json")
      (push '("npm test" . "npm test") candidates)
      (push '("npm run build" . "npm run build") candidates))
    (when (my/project-command--file-exists-p project-root "Cargo.toml")
      (push '("cargo test" . "cargo test") candidates)
      (push '("cargo build" . "cargo build") candidates))
    (when (my/project-command--file-exists-p project-root "pyproject.toml")
      (push '("pytest" . "pytest") candidates)
      (push '("ruff check" . "ruff check .") candidates))
    (nreverse candidates)))

(defun my/project-command-candidates (&optional root)
  "Return project command candidates for ROOT."
  (let ((seen nil)
        (result nil))
    (dolist (candidate (append (my/project-command-detected-candidates root)
                               my/project-command-defaults))
      (unless (member (cdr candidate) seen)
        (push (cdr candidate) seen)
        (push candidate result)))
    (nreverse result)))

(defun my/project-command-read ()
  "Read a project command, preferring detected command candidates."
  (let* ((candidates (my/project-command-candidates))
         (choice (completing-read "Project command: "
                                  candidates nil nil nil
                                  'my/project-command-history
                                  (cdar candidates))))
    (or (cdr (assoc choice candidates))
        choice)))

(defun my/project-command-run (command)
  "Run project COMMAND through `compile' from the project root."
  (interactive (list (my/project-command-read)))
  (let ((default-directory (my/project-root))
        (compile-command command))
    (compile command)))

(defun my/project-command-repeat ()
  "Repeat the most recent project compilation command."
  (interactive)
  (let ((default-directory (my/project-root)))
    (recompile)))

(use-package compile
  :ensure nil
  :bind (("C-c p c" . my/project-command-run)
         ("C-c p C" . my/project-command-repeat))
  :config
  (setq compilation-scroll-output 'first-error))

(provide 'config-project-commands)

;;; config-project-commands.el ends here
