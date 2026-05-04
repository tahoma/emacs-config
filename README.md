# Emacs Config

Minimal vanilla Emacs configuration.

This repository is meant to live at `~/.emacs.d`.

## Files

- `init.el`: handwritten Emacs configuration
- `lisp/`: first-party byte-compilable configuration libraries
- `.gitignore`: local Emacs state and generated files to keep out of git
- `scripts/setup.el`: fresh-machine dependency bootstrap
- `scripts/compile.el`: byte-compilation helper for first-party ELisp
- `tests/init-test.el`: ERT tests for the config

## Features

- MELPA, GNU ELPA, and Nongnu ELPA package archives
- Magit via `C-c g`
- vterm via `C-c t`, plus project-root vterm via `C-c T`
- Emacs Lisp development support: Helpful, Paredit, Rainbow Delimiters,
  Aggressive Indent, Eros, Macrostep, Package-Lint, and Flymake integration
- Embedded C/C++ support: clangd through Eglot, Corfu completion,
  clang-format, CMake mode, project build/debug helpers, and modes for linker
  scripts, assembly, and GDB command files

## Layout

`init.el` is intentionally small. It adds `lisp/` to `load-path`, requires the
first-party modules, and loads `custom.el` last. Stable behavior lives in normal
libraries:

- `tahoma-package.el`: package archives, priorities, and `use-package`
- `tahoma-ui.el`: basic interface defaults and Helpful
- `tahoma-project.el`: project root helpers
- `tahoma-tools.el`: vterm and Magit
- `tahoma-elisp.el`: Emacs Lisp development support
- `tahoma-embedded.el`: embedded C, C++, CMake, compile, format, and debug
  support

## Test

Run the test suite from the repository root:

```sh
make test
```

Or invoke Emacs directly:

```sh
emacs -Q --batch -l tests/init-test.el
```

## Compile

Freshen local byte-compiled ELisp files:

```sh
make compile
```

The generated `.elc` files are local artifacts and are ignored by git. Emacs may
load a fresh `init.elc` faster than source, but the source files remain the
canonical project state.

## Clean

Remove local runtime files and first-party byte-compiled artifacts while keeping
installed packages:

```sh
make clean
```

Remove runtime files plus installed package directories:

```sh
make realclean
```

After `make realclean`, run `make setup` before expecting the full config to
load with all packages available.

## Fresh Machine Setup

Clone this repository as `~/.emacs.d`, then run setup once:

```sh
cd ~/.emacs.d
make setup
make test
```

`make setup` refreshes package archives, installs the managed package set, and
compiles the `vterm` native module, then freshens local `.elc` files. `vterm`
requires a working compiler toolchain and `cmake` on the machine.

## Restore

Clone this repository as `~/.emacs.d`:

```sh
git clone git@github.com:tahoma/emacs-config.git ~/.emacs.d
```

If your GitHub CLI is configured for HTTPS, use:

```sh
git clone https://github.com/tahoma/emacs-config.git ~/.emacs.d
```
