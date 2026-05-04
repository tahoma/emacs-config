EMACS ?= emacs

.PHONY: compile setup test

compile:
	$(EMACS) -Q --batch -l scripts/compile.el

setup:
	$(EMACS) -Q --batch -l scripts/setup.el

test:
	$(EMACS) -Q --batch -l tests/init-test.el
