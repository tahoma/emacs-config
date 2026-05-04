#!/usr/bin/env bash
# Configure user-level shell settings used by this Emacs config.
#
# This helper is intentionally a dry-run by default. It reports whether the
# current shell environment has the editor, PATH, terminal, and MCP client
# settings that make terminal and agentic Emacs pleasant. It only writes to user
# dotfiles with USER_INSTALL=1, and only updates MCP client configuration with
# USER_MCP_INSTALL=1.

set -euo pipefail

USER_INSTALL="${USER_INSTALL:-0}"
USER_MCP_INSTALL="${USER_MCP_INSTALL:-0}"
USER_MCP_CLIENTS="${USER_MCP_CLIENTS:-claude codex cursor}"
USER_SHELL_FILE="${USER_SHELL_FILE:-}"
USER_TMUX_FILE="${USER_TMUX_FILE:-$HOME/.tmux.conf}"
USER_EMACS_MCP_SCRIPT="${USER_EMACS_MCP_SCRIPT:-$HOME/.emacs.d/emacs-mcp-stdio.sh}"
USER_CLAUDE_CONFIG_FILE="${USER_CLAUDE_CONFIG_FILE:-$HOME/.claude.json}"
USER_CODEX_CONFIG_FILE="${USER_CODEX_CONFIG_FILE:-$HOME/.codex/config.toml}"
USER_CURSOR_MCP_FILE="${USER_CURSOR_MCP_FILE:-$HOME/.cursor/mcp.json}"

EDITOR_COMMAND='emacsclient -t -a ""'
MCP_SERVER_NAME="elisp-dev"
MCP_SERVER_ID="elisp-dev-mcp"
MCP_INIT_FUNCTION="elisp-dev-mcp-enable"
MCP_STOP_FUNCTION="elisp-dev-mcp-disable"
SHELL_BLOCK_BEGIN="# >>> emacs-config user shell setup >>>"
SHELL_BLOCK_END="# <<< emacs-config user shell setup <<<"
TMUX_BLOCK_BEGIN="# >>> emacs-config terminal setup >>>"
TMUX_BLOCK_END="# <<< emacs-config terminal setup <<<"

installing() {
  [[ "$USER_INSTALL" == "1" ]]
}

mcp_installing() {
  [[ "$USER_MCP_INSTALL" == "1" ]]
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

requested_mcp_client() {
  [[ " $USER_MCP_CLIENTS " == *" $1 "* ]]
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

quoted_command() {
  local first=1
  local part
  for part in "$@"; do
    if [[ "$first" == "1" ]]; then
      first=0
    else
      printf ' '
    fi
    printf '%q' "$part"
  done
  printf '\n'
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

mcp_stdio_command() {
  quoted_command \
    "$USER_EMACS_MCP_SCRIPT" \
    "--init-function=$MCP_INIT_FUNCTION" \
    "--stop-function=$MCP_STOP_FUNCTION" \
    "--server-id=$MCP_SERVER_ID"
}

claude_mcp_add_command() {
  quoted_command \
    claude mcp add --transport stdio --scope user "$MCP_SERVER_NAME" -- \
    "$USER_EMACS_MCP_SCRIPT" \
    "--init-function=$MCP_INIT_FUNCTION" \
    "--stop-function=$MCP_STOP_FUNCTION" \
    "--server-id=$MCP_SERVER_ID"
}

codex_mcp_add_command() {
  quoted_command \
    codex mcp add "$MCP_SERVER_NAME" -- \
    "$USER_EMACS_MCP_SCRIPT" \
    "--init-function=$MCP_INIT_FUNCTION" \
    "--stop-function=$MCP_STOP_FUNCTION" \
    "--server-id=$MCP_SERVER_ID"
}

claude_mcp_configured() {
  file_has "$USER_CLAUDE_CONFIG_FILE" "$MCP_SERVER_NAME"
}

codex_mcp_configured() {
  file_has "$USER_CODEX_CONFIG_FILE" "[mcp_servers.$MCP_SERVER_NAME]"
}

cursor_mcp_configured() {
  file_has "$USER_CURSOR_MCP_FILE" "\"$MCP_SERVER_NAME\""
}

show_mcp_status() {
  section "MCP client status"

  say "Clients: $USER_MCP_CLIENTS"
  say "Emacs MCP stdio script: $USER_EMACS_MCP_SCRIPT"
  if [[ -x "$USER_EMACS_MCP_SCRIPT" ]]; then
    status "ok" "stdio bridge script is installed and executable"
  else
    status "missing" "stdio bridge script is missing; run make setup"
  fi

  if have emacsclient; then
    if emacsclient -e t >/dev/null 2>&1; then
      status "ok" "emacsclient can reach a running Emacs server"
    else
      status "warn" "emacsclient cannot reach Emacs; start a daemon before MCP use"
    fi
  else
    status "missing" "emacsclient command is not on PATH"
  fi

  if requested_mcp_client claude; then
    say "Claude Code config: $USER_CLAUDE_CONFIG_FILE"
    if ! have claude; then
      status "manual" "Claude Code CLI is not on PATH"
    elif claude_mcp_configured; then
      status "ok" "Claude Code has $MCP_SERVER_NAME MCP server configured"
    else
      status "missing" "Claude Code is missing $MCP_SERVER_NAME MCP server"
    fi
  fi

  if requested_mcp_client codex; then
    say "Codex config: $USER_CODEX_CONFIG_FILE"
    if ! have codex; then
      status "manual" "Codex CLI is not on PATH"
    elif codex_mcp_configured; then
      status "ok" "Codex has $MCP_SERVER_NAME MCP server configured"
    else
      status "missing" "Codex is missing $MCP_SERVER_NAME MCP server"
    fi
  fi

  if requested_mcp_client cursor; then
    say "Cursor MCP file: $USER_CURSOR_MCP_FILE"
    if cursor_mcp_configured; then
      status "ok" "Cursor has $MCP_SERVER_NAME MCP server configured"
    else
      status "missing" "Cursor is missing $MCP_SERVER_NAME MCP server"
    fi
  fi
}

cursor_mcp_json() {
  cat <<EOF
{
  "mcpServers": {
    "$MCP_SERVER_NAME": {
      "command": "$USER_EMACS_MCP_SCRIPT",
      "args": [
        "--init-function=$MCP_INIT_FUNCTION",
        "--stop-function=$MCP_STOP_FUNCTION",
        "--server-id=$MCP_SERVER_ID"
      ]
    }
  }
}
EOF
}

show_user_plan() {
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

show_mcp_plan() {
  section "Planned MCP client setup"
  say "The MCP clients should run this stdio command:"
  say "  $(mcp_stdio_command)"
  say ""
  say "Emacs must be running as a server and the MCP server must be started from Emacs:"
  say "  M-x my/mcp-start"

  if requested_mcp_client claude; then
    say ""
    say "Would register Claude Code with:"
    say "  $(claude_mcp_add_command)"
  fi

  if requested_mcp_client codex; then
    say ""
    say "Would register Codex with:"
    say "  $(codex_mcp_add_command)"
  fi

  if requested_mcp_client cursor; then
    say ""
    say "Would ensure this Cursor MCP entry exists in $USER_CURSOR_MCP_FILE:"
    cursor_mcp_json
  fi
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

install_cursor_mcp() {
  mkdir -p "$(dirname "$USER_CURSOR_MCP_FILE")"

  if cursor_mcp_configured; then
    say "Cursor already has $MCP_SERVER_NAME MCP server configured"
  elif [[ -f "$USER_CURSOR_MCP_FILE" && -s "$USER_CURSOR_MCP_FILE" ]] && have jq; then
    local tmp
    tmp="$(mktemp)"
    if jq \
      --arg name "$MCP_SERVER_NAME" \
      --arg command "$USER_EMACS_MCP_SCRIPT" \
      --arg init "--init-function=$MCP_INIT_FUNCTION" \
      --arg stop "--stop-function=$MCP_STOP_FUNCTION" \
      --arg server "--server-id=$MCP_SERVER_ID" \
      '.mcpServers = (.mcpServers // {}) | .mcpServers[$name] = {"command": $command, "args": [$init, $stop, $server]}' \
      "$USER_CURSOR_MCP_FILE" >"$tmp"; then
      mv "$tmp" "$USER_CURSOR_MCP_FILE"
      say "Updated $USER_CURSOR_MCP_FILE"
    else
      rm -f "$tmp"
      say "Skipped Cursor MCP update because $USER_CURSOR_MCP_FILE is not valid JSON"
    fi
  elif [[ -f "$USER_CURSOR_MCP_FILE" && -s "$USER_CURSOR_MCP_FILE" ]]; then
    say "Skipped Cursor MCP update because jq is not available for merging existing JSON"
  else
    cursor_mcp_json >"$USER_CURSOR_MCP_FILE"
    say "Created $USER_CURSOR_MCP_FILE"
  fi
}

apply_mcp_setup() {
  section "Applying MCP client setup"

  if [[ ! -x "$USER_EMACS_MCP_SCRIPT" ]]; then
    say "Warning: $USER_EMACS_MCP_SCRIPT is missing or not executable. Run make setup before using the MCP clients."
  fi

  if requested_mcp_client claude; then
    if ! have claude; then
      say "Skipped Claude Code MCP registration: claude is not on PATH"
    elif claude_mcp_configured; then
      say "Claude Code already has $MCP_SERVER_NAME MCP server configured"
    else
      claude mcp add --transport stdio --scope user "$MCP_SERVER_NAME" -- \
        "$USER_EMACS_MCP_SCRIPT" \
        "--init-function=$MCP_INIT_FUNCTION" \
        "--stop-function=$MCP_STOP_FUNCTION" \
        "--server-id=$MCP_SERVER_ID"
    fi
  fi

  if requested_mcp_client codex; then
    if ! have codex; then
      say "Skipped Codex MCP registration: codex is not on PATH"
    elif codex_mcp_configured; then
      say "Codex already has $MCP_SERVER_NAME MCP server configured"
    else
      codex mcp add "$MCP_SERVER_NAME" -- \
        "$USER_EMACS_MCP_SCRIPT" \
        "--init-function=$MCP_INIT_FUNCTION" \
        "--stop-function=$MCP_STOP_FUNCTION" \
        "--server-id=$MCP_SERVER_ID"
    fi
  fi

  if requested_mcp_client cursor; then
    install_cursor_mcp
  fi
}

main() {
  local shell_file
  USER_TMUX_FILE="$(expand_user_path "$USER_TMUX_FILE")"
  USER_EMACS_MCP_SCRIPT="$(expand_user_path "$USER_EMACS_MCP_SCRIPT")"
  USER_CLAUDE_CONFIG_FILE="$(expand_user_path "$USER_CLAUDE_CONFIG_FILE")"
  USER_CODEX_CONFIG_FILE="$(expand_user_path "$USER_CODEX_CONFIG_FILE")"
  USER_CURSOR_MCP_FILE="$(expand_user_path "$USER_CURSOR_MCP_FILE")"
  shell_file="$(detected_shell_file)"

  if installing; then
    say "USER_INSTALL=1: user dotfiles will be updated."
  else
    say "Dry run: user dotfiles are not modified. Run 'make user USER_INSTALL=1' to update them."
  fi

  if mcp_installing; then
    say "USER_MCP_INSTALL=1: MCP client configuration will be updated."
  else
    say "Dry run: MCP clients are not modified. Run 'make user USER_MCP_INSTALL=1' to update them."
  fi

  show_shell_status "$shell_file"
  show_terminal_status
  show_mcp_status

  if installing; then
    apply_user_setup "$shell_file"
  else
    show_user_plan "$shell_file"
  fi

  if mcp_installing; then
    apply_mcp_setup
  else
    show_mcp_plan
  fi

  section "After user setup"
  say "Restart your shell or source the updated shell file, then run:"
  say "  make user"
}

main "$@"
