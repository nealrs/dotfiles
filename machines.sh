#!/usr/bin/env zsh
# machines.sh — generates ssh aliases from .machines.json (kewtie, gibson, etc.)
# Source from .zshrc.mac / .zshrc.bazzite with the json path as $1:
#   [[ -f "$REPOS/dotfiles/machines.sh" ]] && source "$REPOS/dotfiles/machines.sh" "$REPOS/dotfiles/.machines.json"
# Edit .machines.json to add/rename hosts — never hardcode IPs in zshrc files.
#
# Aliases target the <name>-lan / <name>-tailnet Host entries that
# gen_ssh_config.sh writes to ~/.ssh/config (run: genssh). User/HostName/
# SetEnv live there, not here — run genssh after editing .machines.json.

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

    for extra in h.get("extra_aliases", []):
        print(f"alias {extra}={shlex.quote(f'ssh {name}-lan')}")
PY
)"
fi

# tssh <name> — connect to any host in .machines.json by name via tailscale
tssh() {
  local host="$1"
  [[ -n "$host" ]] || { echo "usage: tssh <hostname>" >&2; return 1 }
  ssh "${host}-tailnet"
}
