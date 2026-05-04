#!/usr/bin/env bash
# Configure host-level tools used by this Emacs config.
#
# This script is intentionally a dry-run by default. It prints the package
# manager and shell-environment commands that make the surrounding machine a
# better host for the Emacs configuration, but it only executes them when called
# with HOST_INSTALL=1. That keeps `make host' safe to run while still providing a
# one-command path for fresh machines.

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
  local tool
  for tool in \
    emacs git cmake clangd clang-format rg fd jq node npm pandoc python3 \
    pipx direnv ruff uv basedpyright-langserver typescript-language-server \
    vscode-json-language-server yaml-language-server mmdc sqlformat codex
  do
    if have "$tool"; then
      printf '  ok      %s -> %s\n' "$tool" "$(command -v "$tool")"
    else
      printf '  missing %s\n' "$tool"
    fi
  done
}

print_shell_notes() {
  section "Shell environment notes"
  case "$(uname -s)" in
    Darwin)
      if have brew; then
        local brew_prefix
        brew_prefix="$(brew --prefix)"
        if [[ ":$PATH:" != *":$brew_prefix/bin:"* ]]; then
          say "Homebrew is installed, but $brew_prefix/bin is not on PATH for this shell."
          say "Consider adding this to ~/.zprofile or ~/.zshrc:"
          say "  eval \"\$($brew_prefix/bin/brew shellenv)\""
        else
          say "Homebrew's bin directory is already visible on PATH."
        fi
      else
        say "Homebrew is not installed. Install it first if you want make host HOST_INSTALL=1 to manage macOS packages."
      fi
      ;;
    Linux)
      if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        say "~/.local/bin is not on PATH. pipx-installed tools may be hidden until the shell profile is updated."
        say "Consider adding this to ~/.profile, ~/.bashrc, or ~/.zshrc:"
        say "  export PATH=\"\$HOME/.local/bin:\$PATH\""
      else
        say "~/.local/bin is already visible on PATH."
      fi
      if have fdfind && ! have fd; then
        say "Debian-style fd is installed as fdfind. The host install path can add an fd shim in ~/.local/bin."
      fi
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

  run_shell "brew install aspell cmake direnv fd jq llvm node pandoc pipx python ripgrep ruff shellcheck uv"
  run_shell "npm install -g @mermaid-js/mermaid-cli typescript-language-server vscode-langservers-extracted yaml-language-server"
  run_shell "pipx ensurepath"
  run_shell "$(pipx_install_command basedpyright)"
  run_shell "$(pipx_install_command sqlparse)"
}

setup_debian_like() {
  section "Ubuntu/Debian host setup"
  run_shell "sudo apt-get update"
  run_shell "sudo apt-get install -y aspell build-essential clang-format clangd cmake curl direnv fd-find gdb git jq libtool-bin lldb nodejs npm pandoc pipx python3 python3-pip python3-venv ripgrep shellcheck"
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
  say "  aspell clang-format clangd cmake direnv fd jq lldb node npm pandoc pipx python3 ripgrep shellcheck"
  say "Then install shared language tools:"
  say "  npm install -g @mermaid-js/mermaid-cli typescript-language-server vscode-langservers-extracted yaml-language-server"
  say "  pipx install basedpyright"
  say "  pipx install ruff"
  say "  pipx install sqlparse"
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
    *)
      section "Unsupported host"
      say "Unsupported OS: $(uname -s)"
      say "Use the README's optional external tools list as a manual checklist."
      ;;
  esac

  print_shell_notes

  section "After host setup"
  say "Restart your shell if PATH changed, then run:"
  say "  make setup"
  say "  make test"
  say "Project-local tools such as pytest, black, debugpy, and codelldb are still best installed per project."
}

main "$@"
