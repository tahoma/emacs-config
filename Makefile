EMACS ?= emacs

.PHONY: setup test

setup:
	$(EMACS) -Q --batch -l scripts/setup.el

test:
	$(EMACS) -Q --batch -l tests/init-test.el
