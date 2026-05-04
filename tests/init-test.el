;;; init-test.el --- Tests for the Emacs config -*- lexical-binding: t; -*-

;;; Commentary:
;; Run from the repository root with:
;;
;;   emacs -Q --batch -l tests/init-test.el

;;; Code:

(require 'ert)

;; Resolve paths relative to the test file so the suite works from `make test',
;; direct batch invocation, or an arbitrary current working directory.
(defconst emacs-config-test-root
  (file-name-directory
   (directory-file-name
    (file-name-directory
     (or load-file-name buffer-file-name)))))

;; The config enables history-writing modes. Point them at temporary files so
;; tests never mutate a user's normal interactive Emacs state.
(setq recentf-save-file
      (expand-file-name "emacs-config-recentf-test" temporary-file-directory)
      savehist-file
      (expand-file-name "emacs-config-savehist-test" temporary-file-directory))

;; Load the real init file. These are configuration tests, so they intentionally
;; exercise the same startup path a user gets after cloning the repo.
(load (expand-file-name "init.el" emacs-config-test-root) nil t)

;;; Startup and package-management contract
(ert-deftest emacs-config/provides-init-feature ()
  (should (featurep 'init)))

(ert-deftest emacs-config/package-archives-include-melpa ()
  (should (equal (alist-get "gnu" package-archives nil nil #'string=)
                 "https://elpa.gnu.org/packages/"))
  (should (equal (alist-get "nongnu" package-archives nil nil #'string=)
                 "https://elpa.nongnu.org/nongnu/"))
  (should (equal (alist-get "melpa" package-archives nil nil #'string=)
                 "https://melpa.org/packages/")))

(ert-deftest emacs-config/package-archive-priorities-prefer-official-archives ()
  (should (> (alist-get "gnu" package-archive-priorities nil nil #'string=)
             (alist-get "melpa" package-archive-priorities nil nil #'string=)))
  (should (> (alist-get "nongnu" package-archive-priorities nil nil #'string=)
             (alist-get "melpa" package-archive-priorities nil nil #'string=))))

(ert-deftest emacs-config/use-package-is-ready ()
  (should (featurep 'use-package))
  (should use-package-always-ensure))

;;; Baseline interactive behavior
(ert-deftest emacs-config/basic-ui-defaults-are-enabled ()
  (should inhibit-startup-screen)
  (should (eq ring-bell-function 'ignore))
  (should (bound-and-true-p global-display-line-numbers-mode))
  (should (bound-and-true-p savehist-mode))
  (should (bound-and-true-p recentf-mode))
  (should (bound-and-true-p electric-pair-mode)))

(ert-deftest emacs-config/custom-file-is-separated ()
  (should (equal custom-file
                 (expand-file-name "custom.el" user-emacs-directory))))

;;; Project helper behavior
(ert-deftest emacs-config/project-root-falls-back-to-default-directory ()
  (let ((root (file-name-as-directory (make-temp-file "emacs-config-test-" t))))
    (unwind-protect
        (let ((default-directory root))
          (should (equal (my/project-root) root)))
      (delete-directory root t))))

(ert-deftest emacs-config/project-root-detects-git-repositories ()
  (skip-unless (executable-find "git"))
  (let* ((root (file-name-as-directory (make-temp-file "emacs-config-test-" t)))
         (subdir (expand-file-name "nested" root)))
    (unwind-protect
        (progn
          (make-directory subdir)
          (should (zerop (call-process "git" nil nil nil "-C" root "init" "-q")))
          (let ((default-directory subdir))
            (should (equal (file-truename (my/project-root))
                           (file-truename root)))))
      (delete-directory root t))))

;;; Integrated tools
(ert-deftest emacs-config/magit-is-installed-and-bound ()
  (should (require 'magit nil t))
  (should (fboundp 'magit-status))
  (should (eq (lookup-key global-map (kbd "C-c g")) 'magit-status)))

(ert-deftest emacs-config/vterm-is-installed-compiled-and-bound ()
  (should (require 'vterm nil t))
  (should (featurep 'vterm-module))
  (should (fboundp 'vterm))
  (should (fboundp 'my/vterm-project))
  (should (bound-and-true-p vterm-always-compile-module))
  (should (= vterm-max-scrollback 10000))
  (should (eq (lookup-key global-map (kbd "C-c t")) 'vterm))
  (should (eq (lookup-key global-map (kbd "C-c T")) 'my/vterm-project)))

(ert-deftest emacs-config/helpful-is-installed-and-bound ()
  (should (require 'helpful nil t))
  (should (fboundp 'helpful-callable))
  (should (fboundp 'helpful-variable))
  (should (fboundp 'helpful-key))
  (should (fboundp 'helpful-command))
  (should (fboundp 'helpful-at-point))
  (should (eq (lookup-key global-map (kbd "C-h f")) 'helpful-callable))
  (should (eq (lookup-key global-map (kbd "C-h v")) 'helpful-variable))
  (should (eq (lookup-key global-map (kbd "C-h k")) 'helpful-key))
  (should (eq (lookup-key global-map (kbd "C-h x")) 'helpful-command))
  (should (eq (lookup-key global-map (kbd "C-c h")) 'helpful-at-point)))

;;; Emacs Lisp development environment
(ert-deftest emacs-config/elisp-helper-packages-are-installed ()
  (dolist (feature '(paredit
                     rainbow-delimiters
                     aggressive-indent
                     eros
                     macrostep
                     package-lint
                     package-lint-flymake))
    (should (require feature nil t))))

(ert-deftest emacs-config/elisp-mode-enables-development-minor-modes ()
  (with-temp-buffer
    (insert "(defun emacs-config-test-example ()\n  :ok)\n")
    (emacs-lisp-mode)
    (should (not indent-tabs-mode))
    (should (bound-and-true-p eldoc-mode))
    (should (bound-and-true-p flymake-mode))
    (should (bound-and-true-p paredit-mode))
    (should (bound-and-true-p rainbow-delimiters-mode))
    (should (bound-and-true-p aggressive-indent-mode))
    (should (bound-and-true-p eros-mode))))

(ert-deftest emacs-config/elisp-mode-keybindings-are-present ()
  (should (eq (lookup-key emacs-lisp-mode-map (kbd "C-c C-b")) 'eval-buffer))
  (should (eq (lookup-key emacs-lisp-mode-map (kbd "C-c C-c")) 'eval-defun))
  (should (eq (lookup-key emacs-lisp-mode-map (kbd "C-c C-k")) 'check-parens))
  (should (eq (lookup-key emacs-lisp-mode-map (kbd "C-c C-l"))
              'package-lint-current-buffer))
  (should (eq (lookup-key emacs-lisp-mode-map (kbd "C-c C-m"))
              'macrostep-expand))
  (should (eq (lookup-key emacs-lisp-mode-map (kbd "C-c C-z")) 'ielm)))

(ert-deftest emacs-config/eldoc-and-flymake-are-tuned-for-elisp ()
  (should (= eldoc-idle-delay 0.2))
  (should (not eldoc-echo-area-use-multiline-p))
  (should (eq (lookup-key flymake-mode-map (kbd "M-n"))
              'flymake-goto-next-error))
  (should (eq (lookup-key flymake-mode-map (kbd "M-p"))
              'flymake-goto-prev-error)))

(when noninteractive
  (ert-run-tests-batch-and-exit))

;;; init-test.el ends here
