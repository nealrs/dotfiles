#!/usr/bin/env zsh
# tailnet.sh — generates ssh aliases from .tailnet.json (kewtie, gibson, etc.)
# Source from .zshrc.mac / .zshrc.bazzite with the json path as $1:
#   [[ -f "$REPOS/dotfiles/tailnet.sh" ]] && source "$REPOS/dotfiles/tailnet.sh" "$REPOS/dotfiles/.tailnet.json"
# Edit .tailnet.json to add/rename hosts — never hardcode IPs in zshrc files.

_TAILNET_JSON="$1"

if [[ -f "$_TAILNET_JSON" ]] && command -v python3 &>/dev/null; then
  eval "$(python3 - "$_TAILNET_JSON" <<'PY'
import json, sys, shlex

with open(sys.argv[1]) as f:
    hosts = json.load(f)["hosts"]

for h in hosts:
    user  = h["user"]
    ip    = h.get("local_ip")
    ts    = h.get("tailscale_hostname")

    if h.get("local_alias") and ip:
        print(f"alias {h['local_alias']}={shlex.quote(f'ssh {user}@{ip}')}")

    if h.get("tailscale_alias") and ts:
        print(f"alias {h['tailscale_alias']}={shlex.quote(f'ssh {user}@{ts}')}")

    for extra in h.get("extra_aliases", []):
        if ip:
            print(f"alias {extra}={shlex.quote(f'ssh {user}@{ip}')}")
PY
)"
fi

# tssh <name> — connect to any host in .tailnet.json by name via tailscale
tssh() {
  local host="$1"
  [[ -n "$host" ]] || { echo "usage: tssh <hostname>" >&2; return 1 }
  [[ -f "$_TAILNET_JSON" ]] || { echo "tssh: .tailnet.json not found" >&2; return 1 }

  local target
  target="$(python3 - "$_TAILNET_JSON" "$host" <<'PY'
import json, sys

with open(sys.argv[1]) as f:
    hosts = json.load(f)["hosts"]

needle = sys.argv[2]
for h in hosts:
    names = [h["name"], h.get("local_alias",""), h.get("tailscale_alias","")] + h.get("extra_aliases",[])
    if needle in names:
        ts = h.get("tailscale_hostname", h["name"])
        print(f"{h['user']}@{ts}")
        sys.exit(0)
sys.exit(1)
PY
)"

  if [[ -n "$target" ]]; then
    ssh "$target"
  else
    echo "tssh: unknown host '$host' (check .tailnet.json)" >&2
    return 1
  fi
}
