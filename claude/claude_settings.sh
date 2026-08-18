#!/usr/bin/env bash
# Writes ~/.claude/settings.json from the template, then separately injects
# the neal-todo mcp token via 1Password. Config first, secret second: the
# 1Password step (session sign-in, timeouts, etc.) is the flakiest part of
# bootstrap, so it shouldn't block permissions/mcp config from refreshing.
#
# Sourced by linux_bootstrap.sh and mac_bootstrap.sh — expects $DOTFILES and
# the info/ok helpers to already be defined by the caller.

mkdir -p ~/.claude

# Carry forward previously-injected tokens so re-running this on a box
# that's signed out of 1Password doesn't wipe out a working mcp token.
OLD_TODO_TOKEN=""
OLD_JOBBOT_TOKEN=""
if [[ -f ~/.claude/settings.json ]]; then
  OLD_TODO_TOKEN=$(jq -r '.mcpServers["neal-todos"].url // empty | sub("^.*/mcp/"; "")' ~/.claude/settings.json 2>/dev/null)
  [[ "$OLD_TODO_TOKEN" == "__TODO_MCP_TOKEN__" ]] && OLD_TODO_TOKEN=""
  OLD_JOBBOT_TOKEN=$(jq -r '.mcpServers["jobbot"].url // empty | sub("^.*/mcp/"; "")' ~/.claude/settings.json 2>/dev/null)
  [[ "$OLD_JOBBOT_TOKEN" == "__JOBBOT_MCP_TOKEN__" ]] && OLD_JOBBOT_TOKEN=""
fi

cp "$DOTFILES/claude/claude_settings.json.tpl" ~/.claude/settings.json && ok "~/.claude/settings.json written"

# $1: mcpServers key, $2: placeholder token in the template, $3: real token
inject_mcp_token() {
  local server="$1" placeholder="$2" token="$3"
  jq --arg t "$token" --arg s "$server" '.mcpServers[$s].url |= (rtrimstr("'"$placeholder"'") + $t)' ~/.claude/settings.json > ~/.claude/settings.json.tmp \
    && mv ~/.claude/settings.json.tmp ~/.claude/settings.json
  local rc=$?
  rm -f ~/.claude/settings.json.tmp
  return "$rc"
}

[[ -n "$OLD_TODO_TOKEN" ]] && inject_mcp_token "neal-todos" "__TODO_MCP_TOKEN__" "$OLD_TODO_TOKEN"
[[ -n "$OLD_JOBBOT_TOKEN" ]] && inject_mcp_token "jobbot" "__JOBBOT_MCP_TOKEN__" "$OLD_JOBBOT_TOKEN"

if command -v op &>/dev/null; then
  info "Injecting neal-todo mcp token via 1Password..."
  TOKEN=$(op read "op://Private/to-do-mcp/token" 2>/dev/null)
  if [[ -n "$TOKEN" ]]; then
    inject_mcp_token "neal-todos" "__TODO_MCP_TOKEN__" "$TOKEN" && ok "neal-todo mcp token injected" || info "token injection failed — re-run updatedots"
  elif [[ -n "$OLD_TODO_TOKEN" ]]; then
    info "op read failed — keeping previously injected neal-todo token (sign into 1Password to refresh)"
  else
    info "op read failed — sign into 1Password and re-run updatedots"
  fi

  info "Injecting jobbot mcp token via 1Password..."
  JOBBOT_TOKEN=$(op read "op://Private/jobbot-mcp/token" 2>/dev/null)
  if [[ -n "$JOBBOT_TOKEN" ]]; then
    inject_mcp_token "jobbot" "__JOBBOT_MCP_TOKEN__" "$JOBBOT_TOKEN" && ok "jobbot mcp token injected" || info "token injection failed — re-run updatedots"
  elif [[ -n "$OLD_JOBBOT_TOKEN" ]]; then
    info "op read failed — keeping previously injected jobbot token (sign into 1Password to refresh)"
  else
    info "op read failed — sign into 1Password and re-run updatedots"
  fi
else
  if [[ -n "$OLD_TODO_TOKEN" ]]; then
    info "1Password CLI not ready — keeping previously injected neal-todo token"
  else
    info "1Password CLI not ready — skipping neal-todo mcp token (run updatedots after signing in)"
  fi
  if [[ -n "$OLD_JOBBOT_TOKEN" ]]; then
    info "1Password CLI not ready — keeping previously injected jobbot token"
  else
    info "1Password CLI not ready — skipping jobbot mcp token (run updatedots after signing in)"
  fi
fi

# Contains a live auth token — not group/world readable.
chmod 600 ~/.claude/settings.json

if [[ -L ~/.claude/CLAUDE.md || ! -e ~/.claude/CLAUDE.md ]]; then
  ln -sf "$DOTFILES/claude/CLAUDE.md" ~/.claude/CLAUDE.md && ok "~/.claude/CLAUDE.md → dotfiles"
else
  info "~/.claude/CLAUDE.md exists as a real file — skipping (to fix: ln -sf $DOTFILES/claude/CLAUDE.md ~/.claude/CLAUDE.md)"
fi

if [[ -L ~/.claude/agents || ! -e ~/.claude/agents ]]; then
  # -n (not -f alone): without it, ln follows an existing symlink-to-dir and
  # creates the link *inside* it (dotfiles/claude/agents/agents) instead of
  # replacing it — a self-referential symlink that reappears on every re-run.
  ln -sfn "$DOTFILES/claude/agents" ~/.claude/agents && ok "~/.claude/agents → dotfiles"
else
  info "~/.claude/agents exists as a real directory — skipping (to fix: rm -rf ~/.claude/agents && ln -sf $DOTFILES/claude/agents ~/.claude/agents)"
fi
