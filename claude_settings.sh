#!/usr/bin/env bash
# Writes ~/.claude/settings.json from the template, then separately injects
# the neal-todo mcp token via 1Password. Config first, secret second: the
# 1Password step (session sign-in, timeouts, etc.) is the flakiest part of
# bootstrap, so it shouldn't block permissions/mcp config from refreshing.
#
# Sourced by linux_bootstrap.sh and mac_bootstrap.sh — expects $DOTFILES and
# the info/ok helpers to already be defined by the caller.

mkdir -p ~/.claude

# Carry forward a previously-injected token so re-running this on a box
# that's signed out of 1Password doesn't wipe out a working mcp token.
OLD_TOKEN=""
if [[ -f ~/.claude/settings.json ]]; then
  OLD_TOKEN=$(jq -r '.mcpServers["neal-todos"].url // empty | sub("^.*/mcp/"; "")' ~/.claude/settings.json 2>/dev/null)
  [[ "$OLD_TOKEN" == "__TODO_MCP_TOKEN__" ]] && OLD_TOKEN=""
fi

cp "$DOTFILES/claude_settings.json.tpl" ~/.claude/settings.json && ok "~/.claude/settings.json written"

inject_todo_token() {
  local token="$1"
  jq --arg t "$token" '.mcpServers["neal-todos"].url |= (rtrimstr("__TODO_MCP_TOKEN__") + $t)' ~/.claude/settings.json > ~/.claude/settings.json.tmp \
    && mv ~/.claude/settings.json.tmp ~/.claude/settings.json
  local rc=$?
  rm -f ~/.claude/settings.json.tmp
  return "$rc"
}

[[ -n "$OLD_TOKEN" ]] && inject_todo_token "$OLD_TOKEN"

if command -v op &>/dev/null; then
  info "Injecting neal-todo mcp token via 1Password..."
  TOKEN=$(op read "op://Private/to-do-mcp/token" 2>/dev/null)
  if [[ -n "$TOKEN" ]]; then
    inject_todo_token "$TOKEN" && ok "neal-todo mcp token injected" || info "token injection failed — re-run updatedots"
  elif [[ -n "$OLD_TOKEN" ]]; then
    info "op read failed — keeping previously injected token (sign into 1Password to refresh)"
  else
    info "op read failed — sign into 1Password and re-run updatedots"
  fi
else
  if [[ -n "$OLD_TOKEN" ]]; then
    info "1Password CLI not ready — keeping previously injected token"
  else
    info "1Password CLI not ready — skipping neal-todo mcp token (run updatedots after signing in)"
  fi
fi

# Contains a live auth token — not group/world readable.
chmod 600 ~/.claude/settings.json

if [[ -L ~/.claude/CLAUDE.md || ! -e ~/.claude/CLAUDE.md ]]; then
  ln -sf "$DOTFILES/CLAUDE.md" ~/.claude/CLAUDE.md && ok "~/.claude/CLAUDE.md → dotfiles"
else
  info "~/.claude/CLAUDE.md exists as a real file — skipping (to fix: ln -sf $DOTFILES/CLAUDE.md ~/.claude/CLAUDE.md)"
fi
