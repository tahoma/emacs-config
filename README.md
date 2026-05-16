# Emacs Config

Minimal vanilla Emacs configuration.

This repository is meant to live at `~/.emacs.d`.

## Files

- `init.el`: handwritten Emacs configuration
- `lisp/`: first-party byte-compilable configuration libraries
- `.gitignore`: local Emacs state and generated files to keep out of git
- `scripts/setup.el`: fresh-machine dependency bootstrap
- `scripts/compile.el`: byte-compilation helper for first-party ELisp
- `scripts/host.el`: host-level external tool helper
- `scripts/user.el`: user shell, editor, PATH, terminal, and MCP client helper
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
- Project command runner: generic project-root `compile` commands detect common
  Make, Node, Cargo, and Python project commands
- Navigation memory: bookmarks persist under `var/`, and registers have
  first-class keys for saved points, text snippets, and window/frame layouts
- Developer notes: Org capture templates under `C-c o` keep tasks, notes,
  decisions, and debug logs in local runtime files under `var/notes/`
- Editing hygiene: generated backup/auto-save files under `var/`,
  save-place, auto-revert, long-line protection, delete-selection behavior, and
  code-buffer whitespace cleanup
- Visual undo: Vundo on `C-x u` and `C-c u` exposes the undo history as a
  navigable tree while preserving built-in undo commands
- Platform integration: guarded macOS, GNU/Linux, WSL, and Windows defaults for
  modifier keys, Dired, external open/reveal commands, terminal clipboards,
  browser launchers, trash behavior, and shell selection
- Terminal integration: OSC 52 clipboard copy for terminal frames, including
  SSH sessions where local OS clipboard tools would run on the wrong host,
  plus `with-editor` support for shells launched from Emacs, optional
  shell-editor integration, and xterm-compatible mouse support
- Workspace ergonomics: Winner history, directional window movement, and
  project-named tab-bar workspaces without a separate workspace framework
- Dired file management: project-root Dired entry points, Wdired bulk rename,
  hidden generated files, DWIM copy targets, and recursive copy/delete defaults
- Buffer management: Ibuffer replaces the flat buffer list with grouped
  development, Dired, Magit, terminal, help, and Emacs internal buffers
- Version-control ergonomics: Ediff uses a single-frame layout, Smerge gets
  conflict-resolution keys, and diff-hl shows changed lines when installed
- Snippet support: Yasnippet with small repo-owned templates for common test and
  source skeletons
- Agentic workflow support: project-root Codex, Claude Code, and Cursor Agent
  launch helpers, project buffer saving, and copyable file/region/project
  context commands
- MCP endpoint support: external agents can connect to a running Emacs session
  through `mcp-server-lib` and `elisp-dev-mcp` for read-only Elisp docs,
  definitions, variable metadata, Info lookup, and source inspection
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
- Verilog/SystemVerilog support: built-in verilog-mode, project-aware
  build/lint helpers, optional Verible formatting and language-server support,
  and Verilator/Icarus lint fallbacks
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
- Tree-sitter grammar management: inspect configured grammars and install one
  or all missing grammars from Emacs

## Layout

`init.el` is intentionally small. It adds `lisp/` to `load-path`, requires the
first-party modules, and loads `custom.el` last. Stable behavior lives in normal
libraries:

- `config-package.el`: package archives, priorities, and `use-package`
- `config-ui.el`: basic interface defaults and Helpful
- `config-editing.el`: editing state, generated-file locations, auto-revert,
  and code-buffer whitespace hygiene
- `config-undo.el`: Vundo visual undo tree bindings and display defaults
- `config-platform.el`: OS-specific host integration guarded by `system-type`
- `config-terminal.el`: terminal-frame behavior for SSH, optional CLI editor
  integration, and terminal input/clipboard details
- `config-project.el`: project root helpers
- `config-project-commands.el`: generic project-root command runner using
  compilation buffers
- `config-navigation.el`: persistent bookmarks and register-based navigation
- `config-notes.el`: Org capture, agenda files, and local developer notes
- `config-workspace.el`: window history, directional movement, and tab-bar
  project workspaces
- `config-files.el`: Dired, Dired-X, Wdired, and project file-management
  defaults
- `config-buffers.el`: Ibuffer grouping and buffer-list defaults
- `config-completion.el`: minibuffer completion, in-buffer completion, project
  search, command discovery, and action menus
- `config-snippets.el`: Yasnippet setup and repo-owned snippet directory
- `config-diagnostics.el`: diagnostics, code navigation, references, rename,
  and language-server action bindings
- `config-debug.el`: optional Dape/DAP debugging controls
- `snippets/`: first-party snippets loaded by `config-snippets.el`
- `config-environment.el`: direnv/envrc project environment loading
- `config-tools.el`: vterm and Magit
- `config-vc.el`: Ediff, Smerge, and diff-hl version-control ergonomics
- `config-mcp.el`: MCP stdio bridge helpers and Elisp development MCP tools
- `config-agent.el`: agent provider registry plus project-root terminal helpers
- `config-elisp.el`: Emacs Lisp development support
- `config-c.el`: C, C++, CMake, compile, format, and debug support
- `config-verilog.el`: Verilog/SystemVerilog editing, formatting, lint, and
  language-server support
- `config-sql.el`: SQL editing, formatting, scratch buffers, and SQLi
  connection helpers
- `config-rust.el`: Rust, Cargo, rustfmt, rust-analyzer, and Cargo.toml
  support
- `config-js.el`: JavaScript, TypeScript, TSX, JSON, Prettier, package
  scripts, and TypeScript language-server support
- `config-markup.el`: Markdown, Mermaid, YAML, and extra JSON support
- `config-python.el`: Python, virtualenvs, pytest, ruff/black, Eglot, and
  requirements files
- `config-treesit.el`: tree-sitter grammar status and install helpers

## Usage Notes

This config is easiest to use as a set of prefix-driven workbenches. Which-Key
will usually show the next command after a short pause, so start with the
prefixes and let Emacs remind you of the leaves.

- Use `C-c p` for project work. `C-c p f` finds files, `C-c p g` searches with
  ripgrep, `C-c p b` switches project buffers, `C-c p c` runs a detected build,
  test, lint, or run command through `compile`, and `C-c p C` repeats the last
  project command.
- Treat compilation buffers as the normal command output surface. Build, test,
  lint, and language helper commands use clickable diagnostics where possible,
  and `recompile` keeps the edit-run loop short.
- In programming buffers, the local bindings are intentionally similar across
  languages: `C-c e` starts or reconnects Eglot, `C-c f` formats, `C-c b`
  builds or compiles, `C-c t` tests, and `C-c r` runs when the language has a
  natural run command. Verilog/SystemVerilog uses `C-c l` for linting, and SQL
  keeps the traditional `C-c C-*` SQLi bindings.
- Use `C-c x` for code intelligence across languages: actions, definitions,
  references, rename, and Imenu. These bindings work even when a language module
  adds its own local build/test keys.
- Use `C-c a ?` as the agent control plane. `C-c a p` copies project context,
  `C-c a P` opens it for review, `C-c a a`/`d`/`u` launch Codex, Claude Code,
  or Cursor Agent from the project root, and `C-c a m s` starts the Emacs MCP
  endpoint for external agents.
- Use `C-c T` for a project-root vterm and `C-c t` for a plain vterm. On
  terminal-heavy machines, run `make user USER_INSTALL=1` for PATH and tmux
  setup. Add `USER_EDITOR_COMMAND='emacs -nw'` or your preferred editor command
  only when you want this repo to manage shell editor variables too.
- Use Dired as a file-management buffer, not just a browser. `C-c f p` opens
  the project root, `C-c f d` jumps to the current file, `.` toggles omitted
  generated files, `(` toggles long listing details, and `C-c C-e` switches to
  Wdired for bulk renames.
- Use `C-c g` for Magit, and use the `C-c v` Smerge keys when a conflict buffer
  is active. Ediff and Smerge are tuned to keep merge work inside one coherent
  frame.
- Use `C-c n` for durable navigation with bookmarks and registers, `C-c w` for
  window and tab workspaces, and `C-x u` when you want Vundo's visual undo tree.
- Use `C-c o` for local developer notes. Captured tasks, notes, decisions, and
  debug logs live under `var/notes/`, so they are useful on the machine but stay
  out of the public config repo.
- Use `C-c E` for direnv/envrc project environments and `C-c l` to inspect or
  install tree-sitter grammars.
- On a new machine, after stock Emacs is installed, run `make host`, `make
  user`, `make setup`, and `make test` in that order. Use `HOST_INSTALL=1`,
  `USER_INSTALL=1`, and `USER_MCP_INSTALL=1` only when you want the helpers to
  modify the host or user environment.

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

## Emacs As MCP Endpoint

External agents can also reach into Emacs through MCP. `make setup` installs
the `mcp-server-lib` and `elisp-dev-mcp` packages, installs the local stdio
bridge at `~/.emacs.d/emacs-mcp-stdio.sh`, and keeps that generated script out
of git. In the Emacs session you want agents to reach, run `M-x my/mcp-start`;
it starts the Emacs server needed by the stdio bridge and then enables the MCP
tools. Stop it with `M-x my/mcp-stop` when done.

The `elisp-dev-mcp` server is intentionally read-focused. It exposes tools for
Elisp function docs, function definitions, variable metadata without values,
Info node lookup, and source reads from trusted Emacs/package directories. This
config also allows first-party source under `lisp/`, `scripts/`, and `tests/`.

Useful bindings:

- `C-c a m s`: start the Emacs MCP server and enable Elisp tools
- `C-c a m x`: disable Elisp tools and stop the MCP server
- `C-c a m i`: reinstall the stdio bridge script
- `C-c a m c`: copy the raw stdio command for another MCP client
- `C-c a m d`: describe registered MCP tools/resources
- `C-c a m M`: show MCP usage metrics

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

`scripts/host.el` is standalone batch Elisp. It assumes a working stock Emacs
executable is already installed, but it does not load `init.el` or third-party
packages, so it is safe to run before `make setup`.

## User Setup

Show whether user shell settings are configured for terminal Emacs, optional
CLI editor workflows, tmux, and external MCP clients:

```sh
make user
```

The target is a dry run by default. To update the detected shell startup file
and `~/.tmux.conf` with managed, idempotent blocks, opt in explicitly:

```sh
make user USER_INSTALL=1
```

MCP client configuration is also a dry run by default. To register the Emacs
Elisp MCP server with supported user-level clients, opt in separately:

```sh
make user USER_MCP_INSTALL=1
```

By default, the helper reports/applies configuration for Claude Code, Codex, and
Cursor. Override the list or paths when needed:

```sh
make user USER_MCP_INSTALL=1 USER_MCP_CLIENTS="claude codex cursor"
make user USER_EMACS_MCP_SCRIPT=~/.emacs.d/emacs-mcp-stdio.sh USER_CURSOR_MCP_FILE=~/.cursor/mcp.json
```

The user helper checks and can configure `~/.local/bin` on `PATH`,
Homebrew/Linuxbrew shell environment loading when `brew` is installed, and tmux
mouse/clipboard/truecolor settings. It leaves `EDITOR`, `VISUAL`, and
`GIT_EDITOR` unmanaged by default; opt in with `USER_EDITOR_COMMAND` when you
want those variables managed too. Override the detected files when needed:

```sh
make user USER_INSTALL=1 USER_SHELL_FILE=~/.zshrc USER_TMUX_FILE=~/.tmux.conf
make user USER_INSTALL=1 USER_EDITOR_COMMAND='emacs -nw'
```

`scripts/user.el` is standalone batch Elisp. It does not load `init.el` or
third-party packages, so it is safe to run before `make setup`; it only needs a
working Emacs executable.

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

Install stock Emacs through your operating system's normal package path, clone
this repository as `~/.emacs.d`, then run setup once:

```sh
cd ~/.emacs.d
make host
make user
make setup
make test
```

Run `make host HOST_INSTALL=1` first if you want the helper to install
host-level external tools. Run `make user USER_INSTALL=1` if you want the helper
to write shell editor/PATH/tmux settings into your user dotfiles, and run
`make user USER_MCP_INSTALL=1` if you want user-scoped agent clients to know
how to launch the Emacs MCP stdio bridge. `make setup` refreshes package
archives, installs the managed package set, installs the local MCP stdio bridge,
and compiles the `vterm` native module, then freshens local `.elc` files.
`vterm` requires a working compiler toolchain and `cmake` on the machine.

## Terminal Editor

By default, this config does not overwrite `EDITOR`, `VISUAL`, or `GIT_EDITOR`
in your login shell. That keeps ordinary Git commit-message editing predictable
and avoids making `emacsclient` part of basic shell muscle memory unless you
explicitly ask for it.

`with-editor` remains enabled for editor requests launched from inside Emacs:
`shell`, `eshell`, `term`, `vterm`, `M-!`, and `M-&` can call back into the
current Emacs session without forcing your outside shell to use `emacsclient`.
In Git commit buffers, `C-c C-c` finishes, `C-c C-k` cancels, and `C-x C-c`
also finishes the quick editor instead of trying to shut down the whole Emacs
session.

If you do want this repository to manage shell editor variables, opt in with an
explicit command:

```sh
make user USER_INSTALL=1 USER_EDITOR_COMMAND='emacs -nw'
make user USER_INSTALL=1 USER_EDITOR_COMMAND='emacsclient -t -a ""'
```

The matching Emacs-side knob is `my/terminal-editor-command`; leave it nil to
avoid changing subprocess editor variables, or set it to the same command you
use in your shell. `my/terminal-start-server` is also opt-in. Plain
`emacsclient` edits still finish with `C-x #` when you intentionally use them.

In interactive terminal frames, `xterm-mouse-mode` is enabled so scrolling and
point/window selection work in terminals that support mouse escape sequences.
Git commit message buffers get a 72-column body fill, Auto Fill, and Flyspell
when a spelling backend exists. TRAMP defaults prefer SSH, keep remote autosaves
under `var/tramp-auto-save/`, reduce lockfile friction, and use modest logging
for normal remote editing. Common xterm escape sequences are decoded for
modified arrows, Home, and End so terminal frames can use familiar navigation
keys without GUI-only modifiers.

## Terminal Environment

Terminal Emacs quality depends partly on the terminal outside Emacs:

- Use a capable `TERM`, such as `xterm-256color` outside tmux or
  `tmux-256color` inside tmux. Avoid `TERM=dumb` except for intentionally
  minimal command output.
- Local terminal Emacs uses a paired host clipboard integration when one is
  available, such as `pbcopy`/`pbpaste` on macOS. That keeps ordinary editing
  intact: text killed with `C-k` is the text yanked back with `C-y`.
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
- Verilog/SystemVerilog tooling: `verible-verilog-format`,
  `verible-verilog-lint`, `verible-verilog-ls`, `verilator`, and `iverilog`

On macOS with Homebrew:

```sh
brew install aspell cmake direnv fd icarus-verilog jq llvm node pandoc pipx python ripgrep ruff shellcheck uv verilator
brew tap chipsalliance/verible
brew install verible
npm install -g @mermaid-js/mermaid-cli typescript-language-server vscode-langservers-extracted yaml-language-server
pipx install basedpyright
pipx install sqlparse
```

Verible is not a core Homebrew formula; its macOS formula is maintained in the
CHIPS Alliance tap.

On Ubuntu/Debian:

```sh
sudo apt update
sudo apt install -y aspell build-essential clang-format clangd cmake curl direnv fd-find gdb git iverilog jq libtool-bin lldb nodejs npm pandoc pipx python3 python3-pip python3-venv ripgrep shellcheck verilator wl-clipboard xclip xsel xdg-utils
sudo npm install -g @mermaid-js/mermaid-cli typescript-language-server vscode-langservers-extracted yaml-language-server
pipx install basedpyright
pipx install ruff
pipx install sqlparse
```

Verible package availability varies across Ubuntu/Debian releases. Install it
from your distribution, a third-party package source, or upstream release
packages when you want Verible formatting, linting, and language-server support.

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

`vscode-langservers-extracted` provides `vscode-json-language-server`. The host
helper treats the global npm package batch as optional: if Node/npm is broken or
the available Node version is a poor fit, the rest of `make host
HOST_INSTALL=1` can continue. Repair Node or install a current LTS Node through
your preferred Node version manager, then rerun the `npm install -g` line.

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
