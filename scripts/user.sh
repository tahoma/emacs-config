#!/usr/bin/env bash
# Configure user-level shell settings used by this Emacs config.
#
# This helper is intentionally a dry-run by default. It reports whether the
# current shell environment has the editor, PATH, and terminal settings that make
# terminal Emacs pleasant. It only writes to user dotfiles when called with
# USER_INSTALL=1.

set -euo pipefail

USER_INSTALL="${USER_INSTALL:-0}"
USER_SHELL_FILE="${USER_SHELL_FILE:-}"
USER_TMUX_FILE="${USER_TMUX_FILE:-$HOME/.tmux.conf}"

EDITOR_COMMAND='emacsclient -t -a ""'
SHELL_BLOCK_BEGIN="# >>> emacs-config user shell setup >>>"
SHELL_BLOCK_END="# <<< emacs-config user shell setup <<<"
TMUX_BLOCK_BEGIN="# >>> emacs-config terminal setup >>>"
TMUX_BLOCK_END="# <<< emacs-config terminal setup <<<"

installing() {
  [[ "$USER_INSTALL" == "1" ]]
}

say() {
  printf '%s\n' "$*"
}

section() {
  printf '\n%s\n' "$1"
  printf '%s\n' "----------------------------------------"
}

have() {
  command -v "$1" >/dev/null 2>&1
}

expand_user_path() {
  case "$1" in
    "~")
      printf '%s\n' "$HOME"
      ;;
    "~/"*)
      printf '%s/%s\n' "$HOME" "${1#~/}"
      ;;
    *)
      printf '%s\n' "$1"
      ;;
  esac
}

path_has() {
  local directory="$1"
  [[ ":$PATH:" == *":$directory:"* ]]
}

status() {
  printf '  %-7s %s\n' "$1" "$2"
}

detected_shell_file() {
  if [[ -n "$USER_SHELL_FILE" ]]; then
    expand_user_path "$USER_SHELL_FILE"
    return
  fi

  case "$(basename "${SHELL:-}")" in
    zsh)
      printf '%s\n' "$HOME/.zshrc"
      ;;
    bash)
      printf '%s\n' "$HOME/.bashrc"
      ;;
    ksh)
      printf '%s\n' "$HOME/.kshrc"
      ;;
    fish)
      printf '%s\n' "$HOME/.config/fish/config.fish"
      ;;
    *)
      printf '%s\n' "$HOME/.profile"
      ;;
  esac
}

posix_shell_file_p() {
  case "$(basename "$1")" in
    config.fish)
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

file_has() {
  local file="$1"
  local needle="$2"
  [[ -f "$file" ]] && grep -Fq "$needle" "$file"
}

shell_block() {
  cat <<'EOF'
# Keep shell-launched CLI editor flows inside the current terminal.
export EDITOR='emacsclient -t -a ""'
export VISUAL="$EDITOR"
export GIT_EDITOR="$EDITOR"

# Make pipx-managed tools visible to Emacs and commands launched from Emacs.
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# Make Homebrew or Linuxbrew tools visible when brew is installed.
if command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
elif [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
EOF
}

tmux_block() {
  cat <<'EOF'
# Make terminal Emacs feel closer to GUI Emacs inside tmux.
set -g mouse on
set -g set-clipboard on
set -as terminal-features ',xterm-256color:RGB'
EOF
}

install_block() {
  local file="$1"
  local begin="$2"
  local end="$3"
  local content="$4"
  local tmp

  mkdir -p "$(dirname "$file")"
  touch "$file"
  tmp="$(mktemp)"
  awk -v begin="$begin" -v end="$end" '
    $0 == begin { skip = 1; next }
    $0 == end { skip = 0; next }
    !skip { print }
  ' "$file" >"$tmp"
  {
    printf '\n%s\n' "$begin"
    printf '%s\n' "$content"
    printf '%s\n' "$end"
  } >>"$tmp"
  mv "$tmp" "$file"
}

brew_command() {
  if have brew; then
    command -v brew
  elif [[ -x /opt/homebrew/bin/brew ]]; then
    printf '%s\n' /opt/homebrew/bin/brew
  elif [[ -x /usr/local/bin/brew ]]; then
    printf '%s\n' /usr/local/bin/brew
  elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    printf '%s\n' /home/linuxbrew/.linuxbrew/bin/brew
  fi
}

show_shell_status() {
  local shell_file="$1"
  section "Shell environment status"
  say "Shell file: $shell_file"

  if posix_shell_file_p "$shell_file"; then
    if file_has "$shell_file" "$SHELL_BLOCK_BEGIN"; then
      status "ok" "managed Emacs shell block is present"
    else
      status "missing" "managed Emacs shell block is not present"
    fi
  else
    status "manual" "fish shell detected; add equivalent settings manually"
  fi

  if [[ "${EDITOR:-}" == "$EDITOR_COMMAND" ]]; then
    status "ok" "EDITOR is $EDITOR_COMMAND"
  else
    status "missing" "EDITOR is not $EDITOR_COMMAND"
  fi

  if [[ "${VISUAL:-}" == "$EDITOR_COMMAND" ]]; then
    status "ok" "VISUAL is $EDITOR_COMMAND"
  else
    status "missing" "VISUAL is not $EDITOR_COMMAND"
  fi

  if [[ "${GIT_EDITOR:-}" == "$EDITOR_COMMAND" ]]; then
    status "ok" "GIT_EDITOR is $EDITOR_COMMAND"
  else
    status "missing" "GIT_EDITOR is not $EDITOR_COMMAND"
  fi

  if path_has "$HOME/.local/bin"; then
    status "ok" "$HOME/.local/bin is on PATH"
  else
    status "missing" "$HOME/.local/bin is not on PATH"
  fi

  local brew_cmd
  brew_cmd="$(brew_command || true)"
  if [[ -n "$brew_cmd" ]]; then
    local brew_prefix
    if brew_prefix="$("$brew_cmd" --prefix 2>/dev/null)"; then
      if path_has "$brew_prefix/bin"; then
        status "ok" "$brew_prefix/bin is on PATH"
      else
        status "missing" "$brew_prefix/bin is not on PATH"
      fi
    else
      status "warn" "$brew_cmd is present but did not report a prefix"
    fi
  fi
}

show_terminal_status() {
  section "Terminal environment status"

  if [[ "${TERM:-}" == "dumb" || -z "${TERM:-}" ]]; then
    status "warn" "TERM is ${TERM:-unset}; terminal Emacs may be limited"
  else
    status "ok" "TERM is ${TERM}"
  fi

  say "tmux file: $USER_TMUX_FILE"
  if file_has "$USER_TMUX_FILE" "$TMUX_BLOCK_BEGIN"; then
    status "ok" "managed tmux block is present"
  else
    status "missing" "managed tmux block is not present"
  fi
}

show_plan() {
  local shell_file="$1"
  section "Planned user setup"

  if posix_shell_file_p "$shell_file"; then
    say "Would manage this shell block in $shell_file:"
    printf '%s\n%s\n%s\n' "$SHELL_BLOCK_BEGIN" "$(shell_block)" "$SHELL_BLOCK_END"
  else
    say "No automatic shell edit planned for fish. Add equivalent EDITOR, VISUAL, GIT_EDITOR, and PATH settings manually."
  fi

  say ""
  say "Would manage this tmux block in $USER_TMUX_FILE:"
  printf '%s\n%s\n%s\n' "$TMUX_BLOCK_BEGIN" "$(tmux_block)" "$TMUX_BLOCK_END"
}

apply_user_setup() {
  local shell_file="$1"
  if posix_shell_file_p "$shell_file"; then
    install_block "$shell_file" "$SHELL_BLOCK_BEGIN" "$SHELL_BLOCK_END" "$(shell_block)"
    say "Updated $shell_file"
  else
    say "Skipped automatic shell update for fish: $shell_file"
  fi

  install_block "$USER_TMUX_FILE" "$TMUX_BLOCK_BEGIN" "$TMUX_BLOCK_END" "$(tmux_block)"
  say "Updated $USER_TMUX_FILE"
}

main() {
  local shell_file
  USER_TMUX_FILE="$(expand_user_path "$USER_TMUX_FILE")"
  shell_file="$(detected_shell_file)"

  if installing; then
    say "USER_INSTALL=1: user dotfiles will be updated."
  else
    say "Dry run: user dotfiles are not modified. Run 'make user USER_INSTALL=1' to update them."
  fi

  show_shell_status "$shell_file"
  show_terminal_status

  if installing; then
    apply_user_setup "$shell_file"
  else
    show_plan "$shell_file"
  fi

  section "After user setup"
  say "Restart your shell or source the updated shell file, then run:"
  say "  make user"
}

main "$@"
