;;; init-test.el --- Tests for the Emacs config -*- lexical-binding: t; -*-

;;; Commentary:
;; Run from the repository root with:
;;
;;   emacs -Q --batch -l tests/init-test.el

;;; Code:

(require 'ert)

(defvar recentf-save-file)
(defvar savehist-file)
(defvar my/embedded-c-basic-offset)
(defvar my/embedded-fill-column)
(declare-function my/project-root "tahoma-project")
(declare-function my/embedded-default-compile-command "tahoma-embedded")
(declare-function my/embedded-format-buffer "tahoma-embedded")

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

(ert-deftest emacs-config/provides-first-party-module-features ()
  (dolist (feature '(tahoma-package
                     tahoma-ui
                     tahoma-project
                     tahoma-tools
                     tahoma-elisp
                     tahoma-embedded))
    (should (featurep feature))))

(ert-deftest emacs-config/init-adds-first-party-lisp-to-load-path ()
  (should (member (expand-file-name "lisp" emacs-config-test-root)
                  load-path)))

(ert-deftest emacs-config/compile-helper-knows-first-party-files ()
  (let ((compile-helper (expand-file-name "scripts/compile.el"
                                          emacs-config-test-root)))
    (should (file-exists-p compile-helper))
    (with-temp-buffer
      (insert-file-contents compile-helper)
      (dolist (relative-file '("lisp/tahoma-package.el"
                               "lisp/tahoma-ui.el"
                               "lisp/tahoma-project.el"
                               "lisp/tahoma-tools.el"
                               "lisp/tahoma-elisp.el"
                               "lisp/tahoma-embedded.el"
                               "init.el"
                               "scripts/setup.el"
                               "scripts/compile.el"
                               "tests/init-test.el"))
        (should (search-forward (prin1-to-string relative-file) nil t))))))

(ert-deftest emacs-config/compiled-artifacts-are-ignored ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name ".gitignore" emacs-config-test-root))
    (should (search-forward "*.elc" nil t))))

(ert-deftest emacs-config/make-clean-targets-are-split-by-package-state ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name "Makefile" emacs-config-test-root))
    (let ((makefile (buffer-string)))
      (should (string-match-p "^clean:" makefile))
      (should (string-match-p "^realclean: clean" makefile))
      (should (string-match-p "lisp/tahoma-package\\.elc" makefile))
      (should (string-match-p "lisp/tahoma-embedded\\.elc" makefile))
      (should (string-match-p "^PACKAGE_DIRS = .*elpa" makefile))
      (should-not (string-match-p "^RUNTIME_DIRS = .*elpa" makefile)))))

(ert-deftest emacs-config/make-help-target-documents-common-targets ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name "Makefile" emacs-config-test-root))
    (let ((makefile (buffer-string)))
      (should (string-match-p "^\\.DEFAULT_GOAL := help" makefile))
      (should (string-match-p "^\\.PHONY: .*help" makefile))
      (dolist (target '("help" "setup" "test" "compile" "clean" "realclean"))
        (should (string-match-p
                 (format "^%s:.*## .+" (regexp-quote target))
                 makefile))))))

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

;;; Embedded C and C++ development environment
(ert-deftest emacs-config/embedded-helper-packages-are-installed ()
  (dolist (feature '(corfu clang-format cmake-mode eglot))
    (should (require feature nil t))))

(ert-deftest emacs-config/setup-installs-embedded-helper-packages ()
  (with-temp-buffer
    (insert-file-contents (expand-file-name "scripts/setup.el"
                                            emacs-config-test-root))
    (dolist (package '(corfu clang-format cmake-mode))
      (should (search-forward (symbol-name package) nil t)))))

(ert-deftest emacs-config/embedded-c-mode-enables-development-defaults ()
  (with-temp-buffer
    (c-mode)
    (should (= c-basic-offset my/embedded-c-basic-offset))
    (should (= tab-width my/embedded-c-basic-offset))
    (should (= fill-column my/embedded-fill-column))
    (should (not indent-tabs-mode))
    (should show-trailing-whitespace)
    (should (bound-and-true-p flymake-mode))
    (should (bound-and-true-p hs-minor-mode))
    (should (eq (local-key-binding (kbd "C-c b")) 'my/embedded-compile))
    (should (eq (local-key-binding (kbd "C-c r")) 'my/embedded-recompile))
    (should (eq (local-key-binding (kbd "C-c f")) 'my/embedded-format-buffer))
    (should (eq (local-key-binding (kbd "C-c e")) 'eglot))
    (should (eq (local-key-binding (kbd "C-c d")) 'my/embedded-debug))
    (should (eq (local-key-binding (kbd "C-c o")) 'ff-find-other-file))))

(ert-deftest emacs-config/embedded-eglot-uses-clangd ()
  (let ((entry (assoc '(c-mode c-ts-mode c++-mode c++-ts-mode)
                      eglot-server-programs)))
    (should entry)
    (should (equal (car (cdr entry)) "clangd"))
    (should (member "--background-index" (cdr entry)))
    (should (member "--clang-tidy" (cdr entry)))))

(ert-deftest emacs-config/embedded-default-build-command-detects-make ()
  (let ((root (file-name-as-directory (make-temp-file "emacs-config-test-" t))))
    (unwind-protect
        (progn
          (write-region "" nil (expand-file-name "Makefile" root) nil 'silent)
          (let ((default-directory root))
            (should (equal (my/embedded-default-compile-command) "make -k"))))
      (delete-directory root t))))

(ert-deftest emacs-config/embedded-default-build-command-detects-cmake-build-dir ()
  (let* ((root (file-name-as-directory (make-temp-file "emacs-config-test-" t)))
         (build-dir (expand-file-name "build" root)))
    (unwind-protect
        (progn
          (make-directory build-dir)
          (write-region "" nil (expand-file-name "Makefile" build-dir)
                        nil 'silent)
          (let ((default-directory root))
            (should (equal (my/embedded-default-compile-command)
                           "cmake --build build"))))
      (delete-directory root t))))

(ert-deftest emacs-config/embedded-file-associations-cover-firmware-files ()
  (dolist (case '(("main.S" . asm-mode)
                  ("firmware.ld" . ld-script-mode)
                  ("debug.gdb" . gdb-script-mode)
                  ("Kconfig" . conf-mode)))
    (should (eq (cdr case)
                (assoc-default (car case) auto-mode-alist #'string-match-p)))))

(when noninteractive
  (ert-run-tests-batch-and-exit))

;;; init-test.el ends here
