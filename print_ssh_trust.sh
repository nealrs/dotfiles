#!/usr/bin/env bash
# print_ssh_trust.sh — prints ssh-copy-id commands to authorize this
# machine's public key on every other machine in .machines.json.
# Run via: sshtrust (also run once at the end of bootstrap)

_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pubkey=""
for f in id_ed25519.pub id_rsa.pub; do
  if [[ -f ~/.ssh/$f ]]; then
    pubkey="~/.ssh/$f"
    break
  fi
done

if [[ -z "$pubkey" ]]; then
  echo "No SSH public key found in ~/.ssh (id_ed25519.pub / id_rsa.pub) — generate one first: ssh-keygen -t ed25519"
  exit 0
fi

self="$(cat ~/.hostname 2>/dev/null)"

python3 - "$_dir/.machines.json" "$self" "$pubkey" <<'PY'
import json, sys

machines_path, self_name, pubkey = sys.argv[1], sys.argv[2], sys.argv[3]

with open(machines_path) as f:
    hosts = json.load(f)["hosts"]

others = [h for h in hosts if h["name"] != self_name]

if not others:
    print("No other machines in .machines.json to authorize.")
    sys.exit(0)

print("Run these to let this machine SSH into the others without a password:")
print()
for h in others:
    name = h["name"]
    print(f"ssh-copy-id -i {pubkey} {name}-tailnet")
    if h.get("local_ip"):
        print(f"ssh-copy-id -i {pubkey} {name}-lan")
print()
PY
