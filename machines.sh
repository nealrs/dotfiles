#!/usr/bin/env zsh
# machines.sh — generates ssh aliases from machines.json (kewtie, gibson, etc.)
# Source from .zshrc.mac / .zshrc.linux with the json path as $1:
#   [[ -f "$REPOS/dotfiles/machines.sh" ]] && source "$REPOS/dotfiles/machines.sh" "$REPOS/dotfiles/machines.json"
# Edit machines.json to add/rename hosts — never hardcode IPs in zshrc files.
#
# Aliases target the <name>-lan / <name>-tailnet Host entries that
# gen_ssh_config.sh writes to ~/.ssh/config (run: genssh). User/HostName/
# SetEnv live there, not here — run genssh after editing machines.json.

_MACHINES_JSON="$1"

if [[ -f "$_MACHINES_JSON" ]] && command -v python3 &>/dev/null; then
  eval "$(python3 - "$_MACHINES_JSON" <<'PY'
import json, sys, shlex

with open(sys.argv[1]) as f:
    hosts = json.load(f)["hosts"]

for h in hosts:
    name = h["name"]

    if h.get("local_ip"):
        print(f"alias {name}={shlex.quote(f'ssh {name}-lan')}")

    if h.get("tailscale_alias") and h.get("tailscale_hostname"):
        print(f"alias {h['tailscale_alias']}={shlex.quote(f'ssh {name}-tailnet')}")

    # m<name> — attach to this host's tmux session picker over tailscale.
    # The double quotes keep the tilde from expanding locally; the remote
    # shell expands it. Needs mux symlinked to ~/.local/bin/mux on the box.
    # (Built by concatenation, not a nested f-string: f-strings can't contain
    # backslashes before Python 3.12, and kewtie runs an older Python.)
    if h.get("tmux"):
        _mcmd = 'ssh ' + name + '-tailnet -t "~/.local/bin/mux"'
        print(f"alias m{name}={shlex.quote(_mcmd)}")

    for extra in h.get("extra_aliases", []):
        print(f"alias {extra}={shlex.quote(f'ssh {name}-lan')}")
PY
)"
fi

# tssh <name> — connect to any host in machines.json by name via tailscale
tssh() {
  local host="$1"
  [[ -n "$host" ]] || { echo "usage: tssh <hostname>" >&2; return 1 }
  ssh "${host}-tailnet"
}

# mssh <name> — attach to a host's tmux session picker over tailscale.
# Parallel to tssh, but drops into `mux` instead of a raw shell. The per-host
# m<name> aliases above are the shortcut for tmux-enabled hosts.
mssh() {
  local host="$1"
  [[ -n "$host" ]] || { echo "usage: mssh <hostname>" >&2; return 1 }
  ssh "${host}-tailnet" -t "~/.local/bin/mux"
}

# muxall — sessions across every tmux host in machines.json, plus this box.
# tmux sessions live on each HOST's server (not your client), so the only way
# to see them all from one place is to ask each host: one ssh per host, 2s
# connect-timeout + BatchMode so a sleeping box can't hang or prompt you.
muxall() {
  local json="${_MACHINES_JSON:-$REPOS/dotfiles/machines.json}"
  local -a hosts
  hosts=(${(f)"$(python3 -c 'import json,sys; print("\n".join(h["name"] for h in json.load(open(sys.argv[1]))["hosts"] if h.get("tmux")))' "$json" 2>/dev/null)"})
  local A=$'\e[38;5;209m' D=$'\e[38;5;245m' Bd=$'\e[1m' Rs=$'\e[0m'
  # sessions + windows from list-sessions; panes from list-panes -a. One round
  # trip per host; __SEP__/__OK__ delimit the two counts and prove reachability.
  local probe='tmux list-sessions -F "#{session_windows}" 2>/dev/null; echo __SEP__; tmux list-panes -a 2>/dev/null | grep -c .; echo __OK__'
  local host label out wins np ns nw self
  self="$(cat ~/.hostname 2>/dev/null || hostname -s 2>/dev/null)"
  printf '\n  %s✦ tmux sessions%s\n' "$A$Bd" "$Rs"
  for host in local $hosts; do
    if [[ $host == local ]]; then label="here"; out="$(eval "$probe")"
    elif [[ $host == $self ]]; then continue   # this box — 'here' already covers it, don't ssh to ourselves
    else label="$host"; out="$(ssh -o ConnectTimeout=2 -o BatchMode=yes "${host}-tailnet" "$probe" 2>/dev/null)"; fi
    if [[ $out != *__OK__* ]]; then
      printf '    %s%-10s%s %soffline / unreachable%s\n' "$A" "$label" "$Rs" "$D" "$Rs"; continue
    fi
    wins="${out%%__SEP__*}"
    np="${out#*__SEP__}"; np="${np%%__OK__*}"; np="${np//[^0-9]/}"
    ns=$(print -r -- "$wins" | grep -c .)
    nw=$(print -r -- "$wins" | awk '{s+=$1} END{print s+0}')
    if (( ns == 0 )); then
      printf '    %s%-10s%s %sno sessions%s\n' "$A" "$label" "$Rs" "$D" "$Rs"
    else
      printf '    %s%-10s%s %d sess · %d win · %d panes\n' "$A" "$label" "$Rs" "$ns" "$nw" "${np:-0}"
    fi
  done
  printf '    %sattach: mgibson · mkewtie · mux%s\n\n' "$D" "$Rs"
}

# muxhere — compact LOCAL tmux summary for the login banner (no network, instant).
# hi() uses this; muxall is the on-demand fleet view.
muxhere() {
  local out ns nw np verb A D Rs
  A=$'\e[38;5;209m'; D=$'\e[38;5;245m'; Rs=$'\e[0m'
  out="$(tmux list-sessions -F '#{session_windows}' 2>/dev/null)"
  ns=$(print -r -- "$out" | grep -c .)
  nw=$(print -r -- "$out" | awk '{s+=$1} END{print s+0}')
  np=$(tmux list-panes -a 2>/dev/null | grep -c .)
  (( ns == 0 )) && verb="mux to start" || verb="mux to attach"
  printf '\n%s⧉ tmux%s local: %d sess · %d win · %d panes %s— %s · muxall for the fleet%s\n' "$A" "$Rs" "$ns" "$nw" "$np" "$D" "$verb" "$Rs"
}
