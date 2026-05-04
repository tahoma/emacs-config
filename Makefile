EMACS ?= emacs
RM_RF ?= rm -rf

.PHONY: clean compile realclean setup test

FIRST_PARTY_ELC = init.elc \
	lisp/tahoma-package.elc \
	lisp/tahoma-ui.elc \
	lisp/tahoma-project.elc \
	lisp/tahoma-tools.elc \
	lisp/tahoma-elisp.elc \
	lisp/tahoma-embedded.elc \
	scripts/compile.elc \
	scripts/setup.elc \
	tests/init-test.elc
RUNTIME_FILES = custom.el history places recentf savehist package-quickstart.el network-security.data
RUNTIME_DIRS = .cache auto-save-list backups eln-cache transient tramp url var
PACKAGE_DIRS = elpa quelpa

clean:
	$(RM) $(FIRST_PARTY_ELC) $(RUNTIME_FILES) *~ \#*\# .\#*
	$(RM_RF) $(RUNTIME_DIRS)

compile:
	$(EMACS) -Q --batch -l scripts/compile.el

realclean: clean
	$(RM_RF) $(PACKAGE_DIRS)

setup:
	$(EMACS) -Q --batch -l scripts/setup.el

test:
	$(EMACS) -Q --batch -l tests/init-test.el
