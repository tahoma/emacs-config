# Emacs Config

Minimal vanilla Emacs configuration.

This repository is meant to live at `~/.emacs.d`.

## Files

- `init.el`: handwritten Emacs configuration
- `lisp/`: first-party byte-compilable configuration libraries
- `.gitignore`: local Emacs state and generated files to keep out of git
- `scripts/setup.el`: fresh-machine dependency bootstrap
- `scripts/compile.el`: byte-compilation helper for first-party ELisp
- `scripts/host.sh`: host-level external tool helper
- `scripts/user.sh`: user shell, editor, PATH, and terminal profile helper
- `tests/init-test.el`: ERT tests for the config
- `AGENTS.md`: shared project instructions for coding agents
- `CLAUDE.md`: Claude Code adapter that imports the shared agent instructions
- `.cursor/rules/emacs-config.mdc`: Cursor project rule for the same shared
  context

## Features

- MELPA, GNU ELPA, and Nongnu ELPA package archives
- Completion and search support: Vertico, Orderless, Marginalia, Consult,
  Embark, Which-Key, Corfu, and CAPE for fast minibuffer selection, in-buffer
  completion, project search, and discoverable command prefixes
- Diagnostics and navigation support: consistent Flymake, Xref, Eglot,
  Consult-Imenu, references, rename, and code-action bindings across language
  modules
- Project environment support: envrc/direnv integration so repository-local
  `.envrc` files can provide toolchain paths and environment variables to Emacs
- Editing hygiene: generated backup/auto-save files under `var/`,
  save-place, auto-revert, long-line protection, delete-selection behavior, and
  code-buffer whitespace cleanup
- Platform integration: guarded macOS, GNU/Linux, WSL, and Windows defaults for
  modifier keys, Dired, external open/reveal commands, terminal clipboards,
  browser launchers, trash behavior, and shell selection
- Terminal integration: OSC 52 clipboard copy for terminal frames, including
  SSH sessions where local OS clipboard tools would run on the wrong host,
  plus an `emacsclient -t` editor environment for CLI tools and `with-editor`
  support for shells launched from Emacs, and xterm-compatible mouse support
- Workspace ergonomics: Winner history, directional window movement, and
  project-named tab-bar workspaces without a separate workspace framework
- Snippet support: Yasnippet with small repo-owned templates for common test and
  source skeletons
- Agentic workflow support: project-root Codex, Claude Code, and Cursor Agent
  launch helpers, project buffer saving, and copyable file/region/project
  context commands
- Debugging support: optional Dape keybindings for Debug Adapter Protocol
  sessions across language-specific adapters
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
- `config-editing.el`: editing state, generated-file locations, auto-revert,
  and code-buffer whitespace hygiene
- `config-platform.el`: OS-specific host integration guarded by `system-type`
- `config-terminal.el`: terminal-frame behavior for SSH, `emacsclient -t`, and
  CLI editor sessions
- `config-project.el`: project root helpers
- `config-workspace.el`: window history, directional movement, and tab-bar
  project workspaces
- `config-completion.el`: minibuffer completion, in-buffer completion, project
  search, command discovery, and action menus
- `config-snippets.el`: Yasnippet setup and repo-owned snippet directory
- `config-diagnostics.el`: diagnostics, code navigation, references, rename,
  and language-server action bindings
- `config-debug.el`: optional Dape/DAP debugging controls
- `snippets/`: first-party snippets loaded by `config-snippets.el`
- `config-environment.el`: direnv/envrc project environment loading
- `config-tools.el`: vterm and Magit
- `config-agent.el`: agent provider registry plus project-root terminal helpers
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

## Agent Context

Project-level agent instructions live in `AGENTS.md`. Keep that file concise,
generic, and safe for a public repository: project layout, verification
commands, edit boundaries, and maintenance workflows belong there; personal
preferences, private paths, credentials, and employer-specific details do not.

Claude Code reads `CLAUDE.md`, which imports `AGENTS.md` and adds only thin
Claude-specific notes. Cursor reads `.cursor/rules/emacs-config.mdc`, an
always-on project rule that points back at the same canonical instructions.
This keeps Codex, Claude, Cursor, and other agents aligned without duplicating
the full guidance in multiple files.

Local personal agent notes should stay untracked. `CLAUDE.local.md`,
`.claude/settings.local.json`, and `.cursor/rules/*.local.mdc` are ignored by
git for that reason.

## Agent Control Plane

The `C-c a` prefix gathers agent-facing workflows in one place. `C-c a ?`
opens a Transient control surface for launching agents, gathering context,
opening Magit, and jumping into a project terminal. `C-c a a` launches Codex,
`C-c a d` launches Claude Code, `C-c a u` launches Cursor Agent, and `C-c a A`
prompts for any configured provider. All launchers start in the current project
root and save modified project buffers first when
`my/agent-save-project-buffers-before-launch` is non-nil.

Use `C-c a p` to copy generated project context for an agent, or `C-c a P` to
open that context in a review buffer. The generated context includes the project
root, git branch/status, and project instruction files such as `AGENTS.md`,
`CLAUDE.md`, Cursor rules, and `README.md`.

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

## Host Setup

Show the host-level commands that install optional external tools for the
current operating system:

```sh
make host
```

The target is a dry run by default. To actually install packages, opt in
explicitly:

```sh
make host HOST_INSTALL=1
```

The host helper detects macOS, Ubuntu/Debian-like Linux, WSL, and native
Windows shells such as Git Bash or MSYS2. It covers tools such as ripgrep, fd,
jq, pandoc, direnv, clangd, clang-format, Node-based language servers, Mermaid
CLI, pipx-managed Python tools, platform clipboard/open helpers, and agent CLI
availability for Codex, Claude Code, and Cursor Agent. It intentionally does not
manage project-local virtualenvs, debug adapters, commercial agent
authentication, or per-user shell profile settings.

## User Setup

Show whether user shell settings are configured for terminal Emacs, CLI editor
workflows, and tmux:

```sh
make user
```

The target is a dry run by default. To update the detected shell startup file
and `~/.tmux.conf` with managed, idempotent blocks, opt in explicitly:

```sh
make user USER_INSTALL=1
```

The user helper checks and can configure `EDITOR`, `VISUAL`, `GIT_EDITOR`,
`~/.local/bin` on `PATH`, Homebrew/Linuxbrew shell environment loading when
`brew` is installed, and tmux mouse/clipboard/truecolor settings. Override the
detected files when needed:

```sh
make user USER_INSTALL=1 USER_SHELL_FILE=~/.zshrc USER_TMUX_FILE=~/.tmux.conf
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
make host
make user
make setup
make test
```

Run `make host HOST_INSTALL=1` first if you want the helper to install
host-level external tools. Run `make user USER_INSTALL=1` if you want the helper
to write shell editor/PATH/tmux settings into your user dotfiles. `make setup`
refreshes package archives, installs the managed package set, and compiles the
`vterm` native module, then freshens local `.elc` files. `vterm` requires a
working compiler toolchain and `cmake` on the machine.

## Terminal Editor

For terminal-heavy work, point shell editor variables at the Emacs server:

```sh
export EDITOR='emacsclient -t -a ""'
export VISUAL="$EDITOR"
export GIT_EDITOR="$EDITOR"
```

`make user USER_INSTALL=1` can add those exports to the detected shell startup
file, along with PATH and tmux settings used by this config.

The config starts an Emacs server during interactive sessions when one is not
already running, and it sets the same variables for subprocesses launched from
inside Emacs. `with-editor` also exports editor variables for `shell`, `eshell`,
`term`, `vterm`, and one-shot shell commands. `emacsclient -t` keeps Git commits
and other CLI editor requests inside the current terminal; `-a ""` starts a
server-backed Emacs if needed. In interactive terminal frames, `xterm-mouse-mode`
is enabled so scrolling and point/window selection work in terminals that
support mouse escape sequences. Git commit message buffers get a 72-column body
fill, Auto Fill, Flyspell when a spelling backend exists, and familiar
`C-c C-c`/`C-c C-k` finish/cancel bindings. TRAMP defaults prefer SSH, keep
remote autosaves under `var/tramp-auto-save/`, reduce lockfile friction, and use
modest logging for normal remote editing. Common xterm escape sequences are
decoded for modified arrows, Home, and End so terminal frames can use familiar
navigation keys without GUI-only modifiers.

## Terminal Environment

Terminal Emacs quality depends partly on the terminal outside Emacs:

- Use a capable `TERM`, such as `xterm-256color` outside tmux or
  `tmux-256color` inside tmux. Avoid `TERM=dumb` except for intentionally
  minimal command output.
- Enable clipboard passthrough for OSC 52 in the local terminal emulator. This
  is what lets remote `emacs -nw` copy text back to the workstation clipboard.
- In tmux, enable mouse and clipboard passthrough, and advertise truecolor when
  your terminal supports it:

```tmux
set -g mouse on
set -g set-clipboard on
set -as terminal-features ',xterm-256color:RGB'
```

Older tmux versions may use this truecolor form instead:

```tmux
set -ga terminal-overrides ',*:Tc'
```

## Optional External Tools

Some language modules use external command-line tools when they are present and
fall back gracefully when they are not:

- Platform integration: `open` on macOS, `xdg-open` plus optional
  `wl-copy`/`wl-paste`, `xclip`, or `xsel` on Linux, and Windows
  `explorer.exe`/`clip.exe`/PowerShell where available
- Terminal clipboard: OSC 52 support is built in. Some terminal multiplexers
  need clipboard passthrough enabled, such as `set -g set-clipboard on` in tmux.
- Project search: `rg` from ripgrep, plus `fd` or `find` for file discovery
- Project environments: `direnv`
- Agent workflows: `codex` or another Codex CLI launch command on `PATH`
- Debugging: language-specific DAP adapters such as `debugpy`,
  `codelldb`/`lldb-dap`, or JavaScript debug adapters
- Markdown preview: `pandoc`, `multimarkdown`, or `markdown`
- Mermaid rendering: `mmdc` from `@mermaid-js/mermaid-cli`
- JSON filtering/pretty-printing: `jq`
- JSON/YAML language servers: `vscode-json-language-server` and
  `yaml-language-server`
- Python tooling: `python3`, `pytest`, `ruff` or `black`, and a language server
  such as `basedpyright-langserver`, `pyright-langserver`, or `pylsp`

On macOS with Homebrew:

```sh
brew install aspell cmake direnv fd jq llvm node pandoc pipx python ripgrep ruff shellcheck uv
npm install -g @mermaid-js/mermaid-cli typescript-language-server vscode-langservers-extracted yaml-language-server
pipx install basedpyright
pipx install sqlparse
```

On Ubuntu/Debian:

```sh
sudo apt update
sudo apt install -y aspell build-essential clang-format clangd cmake curl direnv fd-find gdb git jq libtool-bin lldb nodejs npm pandoc pipx python3 python3-pip python3-venv ripgrep shellcheck wl-clipboard xclip xsel xdg-utils
sudo npm install -g @mermaid-js/mermaid-cli typescript-language-server vscode-langservers-extracted yaml-language-server
pipx install basedpyright
pipx install ruff
pipx install sqlparse
```

On Windows with winget from Git Bash or another POSIX-like shell:

```sh
winget install --id GNU.Emacs --exact
winget install --id Git.Git --exact
winget install --id LLVM.LLVM --exact
winget install --id Kitware.CMake --exact
winget install --id BurntSushi.ripgrep.MSVC --exact
winget install --id sharkdp.fd --exact
winget install --id jqlang.jq --exact
winget install --id OpenJS.NodeJS.LTS --exact
winget install --id Python.Python.3.13 --exact
winget install --id JohnMacFarlane.Pandoc --exact
npm install -g @mermaid-js/mermaid-cli typescript-language-server vscode-langservers-extracted yaml-language-server
py -m pip install --user pipx
py -m pipx install basedpyright
py -m pipx install ruff
py -m pipx install sqlparse
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
