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
- Completion and search support: Vertico, Orderless, Marginalia, Consult,
  Embark, and Which-Key for fast minibuffer selection, project search, and
  discoverable command prefixes
- macOS GUI Emacs shell-environment import so Homebrew tools are visible from
  Emacs.app
- Magit via `C-c g`
- vterm via `C-c t`, plus project-root vterm via `C-c T`
- Emacs Lisp development support: Helpful, Paredit, Rainbow Delimiters,
  Aggressive Indent, Eros, Macrostep, Package-Lint, and Flymake integration
- C/C++ support: clangd through Eglot, Corfu completion, clang-format,
  CMake mode, project build/debug helpers, and modes for linker scripts,
  assembly, and GDB command files
- SQL support: sql-mode and SQLi connections, query scratch buffers,
  sqlformat, sqlup-mode, sql-indent, and optional SQL language-server support
- Rust support: rust-mode with tree-sitter upgrade path, rust-analyzer through
  Eglot, rustfmt-on-save, Cargo helpers, and Cargo.toml support
- JavaScript/TypeScript support: JS, TS, TSX, JSON, TypeScript language server
  through Eglot, project-local Prettier formatting, node_modules/.bin, and
  package-manager script helpers
- Markup and data-file support: Markdown/GFM editing and preview hooks,
  Mermaid diagram rendering commands, YAML with optional language-server
  support, and JSON helpers for jq and JSON language-server support
- Python support: virtualenv discovery, optional Eglot language-server support,
  ruff/black formatting, pytest and ruff project commands, Python REPL helpers,
  and requirements/pyproject support

## Layout

`init.el` is intentionally small. It adds `lisp/` to `load-path`, requires the
first-party modules, and loads `custom.el` last. Stable behavior lives in normal
libraries:

- `config-package.el`: package archives, priorities, and `use-package`
- `config-ui.el`: basic interface defaults and Helpful
- `config-project.el`: project root helpers
- `config-completion.el`: minibuffer completion, project search, command
  discovery, and action menus
- `config-tools.el`: vterm and Magit
- `config-elisp.el`: Emacs Lisp development support
- `config-c.el`: C, C++, CMake, compile, format, and debug support
- `config-sql.el`: SQL editing, formatting, scratch buffers, and SQLi
  connection helpers
- `config-rust.el`: Rust, Cargo, rustfmt, rust-analyzer, and Cargo.toml
  support
- `config-js.el`: JavaScript, TypeScript, TSX, JSON, Prettier, package
  scripts, and TypeScript language-server support
- `config-markup.el`: Markdown, Mermaid, YAML, and extra JSON support
- `config-python.el`: Python, virtualenvs, pytest, ruff/black, Eglot, and
  requirements files

## Test

Run the test suite from the repository root:

```sh
make test
```

Or invoke Emacs directly:

```sh
emacs -Q --batch -l tests/init-test.el
```

## Help

List the available Make targets:

```sh
make help
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

## Optional External Tools

Some language modules use external command-line tools when they are present and
fall back gracefully when they are not:

- Project search: `rg` from ripgrep, plus `fd` or `find` for file discovery
- Markdown preview: `pandoc`, `multimarkdown`, or `markdown`
- Mermaid rendering: `mmdc` from `@mermaid-js/mermaid-cli`
- JSON filtering/pretty-printing: `jq`
- JSON/YAML language servers: `vscode-json-language-server` and
  `yaml-language-server`
- Python tooling: `python3`, `pytest`, `ruff` or `black`, and a language server
  such as `basedpyright-langserver`, `pyright-langserver`, or `pylsp`

On macOS with Homebrew:

```sh
brew install cmake jq node pandoc python ruff uv pipx ripgrep fd
npm install -g @mermaid-js/mermaid-cli vscode-langservers-extracted yaml-language-server
pipx install basedpyright
```

On Ubuntu/Debian:

```sh
sudo apt update
sudo apt install -y build-essential cmake jq nodejs npm pandoc python3 python3-venv python3-pip pipx ripgrep fd-find
sudo npm install -g @mermaid-js/mermaid-cli vscode-langservers-extracted yaml-language-server
pipx install basedpyright
```

`vscode-langservers-extracted` provides `vscode-json-language-server`. Mermaid
CLI can be picky about Node versions on older Linux distributions; if the distro
Node is too old, install a current LTS Node through your preferred Node version
manager and rerun the `npm install -g` line.

Python project tools such as `pytest`, `ruff`, and `black` are usually best kept
inside each project's virtualenv. The config will find them in `.venv/bin`
automatically when they are installed there.

## Restore

Clone this repository as `~/.emacs.d`, replacing the URL with your own config
repository:

```sh
git clone git@github.com:YOUR-USER/emacs-config.git ~/.emacs.d
```

If your GitHub CLI is configured for HTTPS, use:

```sh
git clone https://github.com/YOUR-USER/emacs-config.git ~/.emacs.d
```
