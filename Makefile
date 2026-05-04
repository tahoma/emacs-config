EMACS ?= emacs

.PHONY: test
test:
	$(EMACS) -Q --batch -l tests/init-test.el
