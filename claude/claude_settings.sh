#!/usr/bin/env bash
# Writes ~/.claude/settings.json from the template, then registers jobbot and
# neal-todos as user-scope MCP servers via `claude mcp add`, injecting tokens
# via 1Password.
#
# IMPORTANT: MCP server connections are NOT configured via settings.json's
# "mcpServers" key — Claude Code doesn't read that. Servers live in
# ~/.claude.json (user/local scope, written by `claude mcp add`) or a
# project's .mcp.json. An earlier version of this script hand-wrote a
# mcpServers block into settings.json; it silently did nothing, for both
# jobbot and neal-todos, potentially for a long while. Don't revert to that.
#
# Config first, secret second: the 1Password step (session sign-in, timeouts,
# etc.) is the flakiest part of bootstrap, so it shouldn't block permissions
# from refreshing.
#
# Sourced by linux_bootstrap.sh and mac_bootstrap.sh — expects $DOTFILES and
# the info/ok helpers to already be defined by the caller.

mkdir -p ~/.claude

cp "$DOTFILES/claude/claude_settings.json.tpl" ~/.claude/settings.json && ok "~/.claude/settings.json written"
chmod 600 ~/.claude/settings.json

# $1: server name, $2: base url (no trailing token), $3: 1Password ref
register_mcp_server() {
  local name="$1" base_url="$2" op_ref="$3"
  local old_token="" token=""

  # Carry forward the currently-registered token so re-running this on a box
  # that's signed out of 1Password doesn't wipe out a working mcp server.
  if [[ -f ~/.claude.json ]]; then
    old_token=$(jq -r --arg n "$name" '.mcpServers[$n].url // empty | sub("^.*/mcp/"; "")' ~/.claude.json 2>/dev/null)
  fi

  if command -v op &>/dev/null; then
    token=$(op read "$op_ref" 2>/dev/null)
  fi

  if [[ -z "$token" ]]; then
    if [[ -n "$old_token" ]]; then
      token="$old_token"
      info "op read failed for $name mcp token — keeping previously registered token"
    else
      token="REPLACE_ME"
      info "op read failed for $name mcp token and no previous registration found — registering with a placeholder token; edit ~/.claude.json (mcpServers.$name.url) to add the real one"
    fi
  fi

  claude mcp remove "$name" --scope user &>/dev/null
  if claude mcp add --transport http "$name" "${base_url}/${token}" --scope user &>/dev/null; then
    ok "$name mcp server registered (user scope)"
  else
    info "$name mcp server registration failed — re-run updatedots"
  fi
}

if command -v claude &>/dev/null; then
  # Raw tailnet IP, not the "kewtie" MagicDNS name — claude's MCP client
  # fails to connect over the hostname for reasons unconfirmed.
  register_mcp_server "neal-todos" "http://100.81.255.110:3737/mcp" "op://Private/to-do-mcp/token"
  register_mcp_server "jobbot" "http://100.81.255.110:4242/mcp" "op://Private/jobbot-mcp/token"
else
  info "claude CLI not found — skipping MCP server registration"
fi

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
