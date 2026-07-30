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
  unset -f ok info inject_todo_token symlink_dotfile
  unset DOTFILES OLD_TOKEN TOKEN
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
  net
  echo ""
  weather
  mo
}

