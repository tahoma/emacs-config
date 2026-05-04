# Emacs Config

Minimal vanilla Emacs configuration.

This repository is meant to live at `~/.emacs.d`.

## Files

- `init.el`: handwritten Emacs configuration
- `.gitignore`: local Emacs state and generated files to keep out of git
- `tests/init-test.el`: ERT tests for the config

## Test

Run the test suite from the repository root:

```sh
make test
```

Or invoke Emacs directly:

```sh
emacs -Q --batch -l tests/init-test.el
```

## Restore

Clone this repository as `~/.emacs.d`:

```sh
git clone git@github.com:tahoma/emacs-config.git ~/.emacs.d
```

If your GitHub CLI is configured for HTTPS, use:

```sh
git clone https://github.com/tahoma/emacs-config.git ~/.emacs.d
```
