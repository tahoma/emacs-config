# Emacs Config

Minimal vanilla Emacs configuration.

This repository is meant to live at `~/.emacs.d`.

## Files

- `init.el`: handwritten Emacs configuration
- `.gitignore`: local Emacs state and generated files to keep out of git
- `tests/init-test.el`: ERT tests for the config

## Features

- MELPA, GNU ELPA, and Nongnu ELPA package archives
- Magit via `C-c g`
- vterm via `C-c t`, plus project-root vterm via `C-c T`
- Emacs Lisp development support: Helpful, Paredit, Rainbow Delimiters,
  Aggressive Indent, Eros, Macrostep, Package-Lint, and Flymake integration

## Test

Run the test suite from the repository root:

```sh
make test
```

Or invoke Emacs directly:

```sh
emacs -Q --batch -l tests/init-test.el
```

## Fresh Machine Setup

Clone this repository as `~/.emacs.d`, then run setup once:

```sh
cd ~/.emacs.d
make setup
make test
```

`make setup` refreshes package archives, installs the managed package set, and
compiles the `vterm` native module. `vterm` requires a working compiler toolchain
and `cmake` on the machine.

## Restore

Clone this repository as `~/.emacs.d`:

```sh
git clone git@github.com:tahoma/emacs-config.git ~/.emacs.d
```

If your GitHub CLI is configured for HTTPS, use:

```sh
git clone https://github.com/tahoma/emacs-config.git ~/.emacs.d
```
