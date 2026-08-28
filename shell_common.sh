#!/usr/bin/env zsh
# shell_common.sh — functions shared by .zshrc.mac and .zshrc.linux, sourced by
# both so they can't drift (that bit us once: hi() updated on mac, missed on
# linux). OS-specific functions (lan, wifi, s3down) stay in each zshrc.
#
# Depends on $REPOS being set by the caller; source it AFTER machines.sh (hi
# calls muxhere from there). All cross-references resolve at call time, so the
# OS-specific helpers (lan) defined later in each zshrc are available when hi runs.
#   Source line: [[ -f "$REPOS/dotfiles/shell_common.sh" ]] && source "$REPOS/dotfiles/shell_common.sh"

# ============================================================
# FUNCTIONS — shared (mac + linux)
# ============================================================

# --- wan ---
function wan(){
  local data=$(curl -s --max-time 3 https://ipinfo.io/json)
  local ip6=$(curl -s --max-time 3 https://api64.ipify.org)
  local ip=$(echo $data | grep -o '"ip": *"[^"]*"' | cut -d'"' -f4)
  local city=$(echo $data | grep -o '"city": *"[^"]*"' | cut -d'"' -f4)
  local country=$(echo $data | grep -o '"country": *"[^"]*"' | cut -d'"' -f4)
  printf "IPv4: \e[33m$ip\e[0m \e[37m($city, $country)\e[0m\n"
  printf "IPv6: \e[33m$ip6\e[0m\n"
}

# --- net ---
function net(){
  printf "\n";
  printf "\e[32mWAN\e[0m\n";
  wan
  printf "\n\e[32mLAN\e[0m\n";
  lan
}

# --- weather ---
function weather(){
  curl --max-time 3 'wttr.in?format=3'
}

# --- mo ---
function mo(){
  local _f="$REPOS/dotfiles/motivation.md"
  [[ -f "$_f" ]] || curl -fsSo "$_f" https://raw.githubusercontent.com/nealrs/dotfiles/master/motivation.md
  local things=("${(@f)$(grep '^- ' "$_f" | sed 's/^- //')}")
  local idx=$(( RANDOM % ${#things[@]} + 1 ))
  printf "\n\e[33mBro, ${things[$idx]}.\e[0m\n"
}

# --- mcd ---
function mcd(){
  mkdir -p -- "$1" && cd -P -- "$1"
}

# --- rn ---
rn() {
  local _script
  for _dir in ~/repos/dotfiles ~/Documents/repos/dotfiles; do
    [[ -f "$_dir/rename.sh" ]] && _script="$_dir/rename.sh" && break
  done
  [[ -n $_script ]] && bash "$_script" "$@" || echo "rn: rename.sh not found" >&2
}

# --- updatedots ---
function updatedots(){
  git -C "$REPOS/dotfiles" pull && genssh
  ok()   { echo "  ✓  $1"; }
  info() { echo "  →  $1"; }
  DOTFILES="$REPOS/dotfiles"
  source "$DOTFILES/symlink_dotfiles.sh"
  source "$DOTFILES/claude/claude_settings.sh"
  unset -f ok info register_mcp_server symlink_dotfile
  unset DOTFILES
  source ~/.zshrc
}

# --- exit ---
# Inside tmux, "exit" detaches instead of killing the shell/pane — no need to
# reach for the C-a prefix. Ctrl-D and pane-close still kill the shell as usual.
function exit(){
  if [[ -n "$TMUX" ]]; then
    tmux detach-client
  else
    builtin exit "$@"
  fi
}

# --- ssh ---
# Wraps every ssh call (aliases/tssh/mssh/muxall all funnel through this) to
# reset local mouse-tracking modes on exit. A remote tmux/vim turns these on
# in the LOCAL terminal via escape codes; if the connection dies uncleanly
# (e.g. laptop sleep), the remote never gets to send the matching disable
# codes and the terminal is left echoing raw mouse escapes on every move.
# No-op if mouse mode was never touched.
function ssh(){
  command ssh "$@"
  local ec=$?
  printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l'
  return $ec
}

# --- push ---
# rsync a local file/dir to a host (any alias from ~/.ssh/config, e.g. kewtie,
# tsk). Resumable + real progress, unlike scp; files and directories both just
# work, no separate -r to remember. Remote path defaults to the basename in
# the remote home dir. Directories are synced by contents (trailing slash
# added automatically) into a dest dir of that same name, so re-running push
# on the same folder updates it in place instead of nesting it a level deeper
# the second time — the classic rsync/scp trailing-slash trap.
push(){
  local src="$1" host="$2" dest="$3"
  if [[ -z "$src" || -z "$host" ]]; then
    echo "usage: push <local-path> <host> [remote-path]" >&2
    return 1
  fi
  if [[ ! -e "$src" ]]; then
    echo "push: no such local file/dir: $src" >&2
    return 1
  fi
  [[ -z "$dest" ]] && dest="${src:t}"
  [[ -d "$src" ]] && src="${src%/}/"
  rsync -avz --progress -e ssh -- "$src" "${host}:${dest}"
}

# --- pull ---
# Inverse of push: rsync a file/dir from a host to local, same idempotent
# directory-contents behavior (see push). Local path defaults to the remote
# basename in the current directory. Costs one quick `ssh -- [ -d ... ]`
# round trip to tell whether the remote path is a directory, since that
# can't be known locally the way it can for push.
pull(){
  local host="$1" src="$2" dest="$3"
  if [[ -z "$host" || -z "$src" ]]; then
    echo "usage: pull <host> <remote-path> [local-path]" >&2
    return 1
  fi
  [[ -z "$dest" ]] && dest="${src:t}"
  if ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" "[ -d ${(q)src} ]" 2>/dev/null; then
    src="${src%/}/"
  fi
  rsync -avz --progress -e ssh -- "${host}:${src}" "$dest"
}

# --- maint ---
# Occasional system upkeep report (brew, docker/podman, dotfiles staleness,
# OS-specific extras) — see maint.sh for what it actually checks. Report/
# suggest only, never runs an upgrade/cleanup/prune itself. Stamps a
# last-run timestamp so hi() can nag if it's been 30+ days (see below) —
# written on completion regardless of what the checks found; it marks
# "you looked," not "everything's clean."
maint(){
  bash "$REPOS/dotfiles/maint.sh" "$@"
  mkdir -p ~/.cache/dotfiles && date +%s > ~/.cache/dotfiles/maint_last_run
}

# --- hi ---
function hi(){
  local ascii="$REPOS/dotfiles/ascii_art.sh"
  [[ -f "$ascii" ]] || curl -fsSo "$ascii" https://raw.githubusercontent.com/nealrs/dotfiles/master/ascii_art.sh
  if [[ -f "$ascii" ]]; then
    source "$ascii"
    if [[ -f ~/.hostname ]]; then
      local _host="$(cat ~/.hostname)"
      local _banner="banner_${_host}"
      if typeset -f "$_banner" &>/dev/null; then
        "$_banner"
      else
        diamond_banner "$_host"
      fi
    fi
  fi

  echo ""
  bash "$REPOS/dotfiles/health.sh"

  # Local tmux sessions you can reattach to — fresh terminal only (skip inside
  # tmux so it's not repeated per pane). Local & instant; sits below health,
  # above wan/lan. Reports 0 when there are none. `muxall` for the fleet view.
  [[ -z "$TMUX" ]] && typeset -f muxhere &>/dev/null && muxhere

  # `maint` staleness nag — fresh terminal only (same guard as muxhere,
  # same reasoning: don't repeat this once per tmux pane). Only checks a
  # timestamp file; never runs the actual checks itself.
  if [[ -z "$TMUX" ]]; then
    local _mf=~/.cache/dotfiles/maint_last_run
    local _mage=$(( ( $(date +%s) - $(cat "$_mf" 2>/dev/null || echo 0) ) / 86400 ))
    if [[ ! -f "$_mf" || $_mage -ge 30 ]]; then
      printf "\e[33m→ last \`maint\` run: %s — run \`maint\`\e[0m\n" \
        "$([[ -f "$_mf" ]] && echo "${_mage} days ago" || echo "never")"
    fi
  fi

  net
  echo ""
  weather
  mo
}

