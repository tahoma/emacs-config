#!/usr/bin/env bash
# Configure host-level tools used by this Emacs config.
#
# This script is intentionally a dry-run by default. It prints the package
# manager commands that make the surrounding machine a better host for the Emacs
# configuration, but it only executes them when called with HOST_INSTALL=1. That
# keeps `make host' safe to run while still providing a one-command path for
# fresh machines. Per-user shell profile setup lives in scripts/user.sh.

set -euo pipefail

HOST_INSTALL="${HOST_INSTALL:-0}"

installing() {
  [[ "$HOST_INSTALL" == "1" ]]
}

say() {
  printf '%s\n' "$*"
}

run_shell() {
  if installing; then
    printf '+ %s\n' "$*"
    bash -lc "$*"
  else
    printf '  %s\n' "$*"
  fi
}

have() {
  command -v "$1" >/dev/null 2>&1
}

running_wsl() {
  [[ -r /proc/version ]] && grep -Eiq '(Microsoft|WSL)' /proc/version
}

show_tools() {
  local tool
  for tool in "$@"; do
    if have "$tool"; then
      printf '  ok      %s -> %s\n' "$tool" "$(command -v "$tool")"
    else
      printf '  missing %s\n' "$tool"
    fi
  done
}

section() {
  printf '\n%s\n' "$1"
  printf '%s\n' "----------------------------------------"
}

pipx_install_command() {
  local package="$1"
  printf 'pipx install %s || pipx upgrade %s' "$package" "$package"
}

show_tool_status() {
  section "Detected tool status"
  show_tools \
    emacs git cmake clangd clang-format rg fd jq node npm pandoc python3 \
    pipx direnv ruff uv basedpyright-langserver typescript-language-server \
    vscode-json-language-server yaml-language-server mmdc sqlformat \
    verible-verilog-format verible-verilog-lint verible-verilog-ls \
    verilator iverilog codex claude cursor-agent

  case "$(uname -s)" in
    Darwin)
      show_tools open pbcopy pbpaste
      ;;
    Linux)
      if running_wsl; then
        show_tools wslview xdg-open explorer.exe clip.exe powershell.exe pwsh.exe
      else
        show_tools xdg-open wl-copy wl-paste xclip xsel
      fi
      ;;
    CYGWIN* | MINGW* | MSYS*)
      show_tools python py explorer.exe clip.exe powershell.exe pwsh.exe winget
      ;;
  esac
}

setup_macos() {
  section "macOS host setup"
  if ! have brew; then
    say "Homebrew is required for the macOS package setup below."
    say "Install Homebrew from https://brew.sh, then rerun this target."
    if installing; then
      return 1
    fi
  fi

  run_shell "brew install aspell cmake direnv fd icarus-verilog jq llvm node pandoc pipx python ripgrep ruff shellcheck uv verible verilator"
  run_shell "npm install -g @mermaid-js/mermaid-cli typescript-language-server vscode-langservers-extracted yaml-language-server"
  run_shell "pipx ensurepath"
  run_shell "$(pipx_install_command basedpyright)"
  run_shell "$(pipx_install_command sqlparse)"
}

setup_debian_like() {
  section "Ubuntu/Debian host setup"
  run_shell "sudo apt-get update"
  run_shell "sudo apt-get install -y aspell build-essential clang-format clangd cmake curl direnv fd-find gdb git iverilog jq libtool-bin lldb nodejs npm pandoc pipx python3 python3-pip python3-venv ripgrep shellcheck verilator wl-clipboard xclip xsel xdg-utils"
  run_shell "npm install -g @mermaid-js/mermaid-cli typescript-language-server vscode-langservers-extracted yaml-language-server"
  run_shell "python3 -m pipx ensurepath"
  run_shell "$(pipx_install_command basedpyright)"
  run_shell "$(pipx_install_command ruff)"
  run_shell "$(pipx_install_command sqlparse)"
  if have fdfind || ! installing; then
    run_shell "mkdir -p \"\$HOME/.local/bin\" && ln -sf \"\$(command -v fdfind)\" \"\$HOME/.local/bin/fd\""
  fi
}

setup_generic_linux() {
  section "Generic Linux host setup"
  say "This script only knows how to install packages automatically on Ubuntu/Debian-like systems."
  say "Install equivalents with your distribution's package manager:"
  say "  aspell clang-format clangd cmake direnv fd iverilog jq lldb node npm pandoc pipx python3 ripgrep shellcheck verilator wl-clipboard xclip xsel xdg-utils"
  say "Then install shared language tools:"
  say "  npm install -g @mermaid-js/mermaid-cli typescript-language-server vscode-langservers-extracted yaml-language-server"
  say "  pipx install basedpyright"
  say "  pipx install ruff"
  say "  pipx install sqlparse"
  say "Install Verible from your distribution, package manager, or release packages if available."
}

setup_windows() {
  section "Windows host setup"
  say "Run this target from Git Bash or another POSIX-like shell with winget on PATH."
  say "Scoop or Chocolatey equivalents are also fine if those are how the host is managed."
  run_shell "winget install --id GNU.Emacs --exact"
  run_shell "winget install --id Git.Git --exact"
  run_shell "winget install --id LLVM.LLVM --exact"
  run_shell "winget install --id Kitware.CMake --exact"
  run_shell "winget install --id BurntSushi.ripgrep.MSVC --exact"
  run_shell "winget install --id sharkdp.fd --exact"
  run_shell "winget install --id jqlang.jq --exact"
  run_shell "winget install --id OpenJS.NodeJS.LTS --exact"
  run_shell "winget install --id Python.Python.3.13 --exact"
  run_shell "winget install --id JohnMacFarlane.Pandoc --exact"
  run_shell "npm install -g @mermaid-js/mermaid-cli typescript-language-server vscode-langservers-extracted yaml-language-server"
  run_shell "py -m pip install --user pipx"
  run_shell "py -m pipx ensurepath"
  run_shell "py -m pipx install basedpyright || py -m pipx upgrade basedpyright"
  run_shell "py -m pipx install ruff || py -m pipx upgrade ruff"
  run_shell "py -m pipx install sqlparse || py -m pipx upgrade sqlparse"
}

main() {
  if installing; then
    say "HOST_INSTALL=1: commands will be executed."
  else
    say "Dry run: commands are printed only. Run 'make host HOST_INSTALL=1' to execute them."
  fi

  show_tool_status

  case "$(uname -s)" in
    Darwin)
      setup_macos
      ;;
    Linux)
      if [[ -r /etc/os-release ]] && grep -Eiq '^(ID|ID_LIKE)=.*(debian|ubuntu)' /etc/os-release; then
        setup_debian_like
      else
        setup_generic_linux
      fi
      ;;
    CYGWIN* | MINGW* | MSYS*)
      setup_windows
      ;;
    *)
      section "Unsupported host"
      say "Unsupported OS: $(uname -s)"
      say "Use the README's optional external tools list as a manual checklist."
      ;;
  esac

  section "User environment"
  say "Run 'make user' to check shell editor variables, PATH, and terminal/tmux settings."

  section "After host setup"
  say "Restart your shell if PATH changed, then run:"
  say "  make user"
  say "  make setup"
  say "  make test"
  say "Project-local tools such as pytest, black, debugpy, and codelldb are still best installed per project."
}

main "$@"
