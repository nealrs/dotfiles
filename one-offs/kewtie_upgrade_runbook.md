# kewtie — apt upgrade + reboot + switch to zsh runbook

Written 2026-07-20, not expected to run for a while. **Before following this,
re-run the Phase 1 checks fresh regardless of what's written below** — if
enough time has passed, package state, kernel version, and container list
will have drifted from whatever's assumed here.

## Why this document exists

kewtie is SSH-only production home infra with no console fallback (~20
Docker containers: Home Assistant, AdGuard DNS, nginx-proxy-manager,
zigbee2mqtt, and more — see `ubuntu.prd.md` for full background). Two
separate risk-bearing operations are bundled into one planned window here
rather than done piecemeal at random times:

1. Applying the pending OS patch set + the reboot it requires.
2. Switching kewtie's login shell from bash to zsh (`chsh`).

Do this interactively, with someone present the whole time — never
unattended, never scripted end-to-end. Every phase below has a checkpoint
where you look at real output before continuing.

**This is NOT the 22.04 → 24.04 release upgrade.** That was deliberately
considered and deferred: kewtie is enrolled in Ubuntu Pro/ESM (security
coverage on 22.04 out to 2032, not just 22.04's normal 2027 end-of-support),
and nearly everything that matters on kewtie runs in Docker containers with
their own package versions baked into the images — the host OS's package
freshness barely affects what you actually use day to day. Revisit
`do-release-upgrade` only if something concrete comes up that needs it
(a host-level package version, a hardware/kernel support gap, or 22.04
support actually approaching its end) — not as routine maintenance.

## Before you start

- Pick a low-usage time. AdGuard is the house's DNS — the reboot causes a
  brief, house-wide DNS blip. A heads-up to whoever else is home isn't a bad
  idea.
- Budget maybe 20-30 minutes end to end, most of it waiting/verifying, not
  active risk.
- No physical access is expected to be needed. It's the one real tail-risk
  in Phase 3 (see Troubleshooting) — worth knowing it's there, not worth
  losing sleep over on a routine HWE kernel point-release.

---

## Phase 1 — Pre-flight checks (zero risk, do this part anytime, even days ahead)

```bash
# Baselines to diff against after the reboot
docker ps --format '{{.Names}}' | sort > ~/pre-reboot-containers.txt
uname -r
docker ps --format '{{.Names}}' | wc -l

# zsh needs to be an *allowed* shell before chsh will accept it later —
# this only adds an option, does not change your actual default
ZSH_PATH="$(brew --prefix)/bin/zsh"
grep -qF "$ZSH_PATH" /etc/shells || echo "$ZSH_PATH" | sudo tee -a /etc/shells
cat /etc/shells   # confirm $ZSH_PATH is listed
```

Also worth a quick sanity check that zsh itself still launches cleanly
before touching anything else:
```bash
zsh   # should drop into a working prompt, no errors; exit back to bash
```

---

## Phase 2 — Apply the upgrade

```bash
sudo apt update && sudo apt upgrade
```

Check what needs restarting to actually pick up the new packages:
```bash
sudo apt install needrestart   # if not already present
sudo needrestart
```
(No-install alternative: `sudo lsof -nP 2>/dev/null | grep '(deleted)' | grep '\.so'`
— empty output means nothing needs restarting.)

**Restart the low-risk services now** — irrelevant-to-kewtie desktop/laptop
daemons and anything with at most a momentary blip, nothing here touches
Docker or your session:

```bash
for s in ModemManager accounts-daemon avahi-daemon bluetooth colord cups \
  irqbalance kerneloops networkd-dispatcher packagekit power-profiles-daemon \
  rtkit-daemon switcheroo-control systemd-oomd systemd-timesyncd thermald \
  udisks2 unattended-upgrades upower gdm gdm3; do
  sudo systemctl restart "$s" 2>/dev/null
done
```

**Leave these three for the reboot, don't restart by hand:**
- `docker.service` — restarting it now takes down every container immediately, uncoordinated with the rest of this plan.
- `systemd-logind.service` — manages session tracking, including your current SSH session; some systemd versions have had issues with active sessions surviving this restart.
- `user@1000.service` — restarting your own user's systemd instance kills the persistent `ssh-agent` (see `ssh_agent_init.sh`) — not dangerous, just means one more passphrase entry, which is going to happen anyway once you reboot.

A kernel update is also sitting there regardless (`linux-image-generic-hwe-22.04` et al.) — it only takes effect on reboot. No reason to solve these four separately when the reboot in Phase 3 handles all of them, in the correct dependency order, better than 4 manual `systemctl restart` calls would.

---

## Phase 3 — The reboot

```bash
sudo reboot
```

This applies the kernel, and cleanly restarts `docker`, `systemd-logind`,
and `user@1000` as part of the normal, tested boot sequence — safer than
doing those three by hand.

---

## Phase 4 — Post-reboot verification

Don't move on to Phase 5 until everything here checks out.

```bash
ssh kewtie                                   # fresh connection — still bash, chsh not done yet
uname -r                                     # should show the new kernel
docker ps --format '{{.Names}}' | sort > ~/post-reboot-containers.txt
diff ~/pre-reboot-containers.txt ~/post-reboot-containers.txt   # expect no output
```

Spot-check the services that actually matter: AdGuard resolving
(`dig @127.0.0.1 example.com` or whatever's appropriate), Home Assistant's
web UI reachable, anything else load-bearing.

```bash
zsh
```
Expect **one** passphrase prompt here — the persisted ssh-agent died with
the reboot, this is a fresh one, not a bug. `exit` back to bash once
confirmed working.

If anything above looks wrong, stop here and fix it before touching the
login shell — don't compound an unverified reboot with an unverified `chsh`.

---

## Phase 5 — Switch to zsh on login

Two ways to get here — pick one. Both give you zsh on every interactive
login (SSH *and* a physical console, if one's ever hooked up); neither
affects non-interactive access (git/rsync/scp/cron/systemd never source
login-shell startup files, so those stay on plain bash regardless of which
option you pick).

### Option A — `chsh` (the standard mechanism)

Changes `/etc/passwd` so bash is no longer even attempted at login.

Two-session safety net — `chsh` doesn't affect sessions already open, so as
long as you don't close everything, you can't actually get locked out, only
see a broken *new* connection that you then revert from an old one.

1. Open **two** separate `ssh kewtie` sessions, both at a working bash prompt.
2. In session 1:
   ```bash
   chsh -s "$(brew --prefix)/bin/zsh"
   ```
3. **Leave both sessions open.** Open a **third**, brand-new terminal and try a completely fresh `ssh kewtie`.
   - Lands in a working zsh prompt → done.
   - Fails, hangs, errors → sessions 1 and 2 are untouched. Revert immediately from either one:
     ```bash
     chsh -s /bin/bash
     ```
4. Also sanity-check the non-interactive path, since that's a separate code path from interactive login and would also break scripts/automation if something's wrong:
   ```bash
   ssh kewtie echo hello    # from your Mac
   ```

If something's wrong with zsh at connection time, sshd has nothing to exec
at all and the connection is refused outright — the real "lockout" failure
mode, mitigated only by always keeping a session open during the test above.

### Option B — `exec zsh` from `~/.profile` (safer failure mode, less standard)

Never touches `/etc/passwd` — bash stays the system-of-record login shell,
so sshd is *always* able to successfully exec something on every connection.
This block just hands off to zsh as a second, in-process step immediately
after:

```sh
# ~/.profile
# Linuxbrew — needed so `zsh` is even findable
[ -f /home/linuxbrew/.linuxbrew/bin/brew ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Persistent ssh-agent — covers the fallback-to-bash case below
for d in "$HOME/repos/dotfiles" "$HOME/Documents/repos/dotfiles"; do
  [ -f "$d/ssh_agent_init.sh" ] && . "$d/ssh_agent_init.sh" && break
done

# Drop into zsh on interactive login without changing the real login shell.
# `exec -l` replaces this process (as a proper login shell) instead of
# nesting a child, so `exit` closes the SSH session directly — no
# double-exit. If zsh isn't found, exec fails gracefully and bash just
# continues below — never a dropped connection.
if [[ $- == *i* ]] && command -v zsh >/dev/null 2>&1; then
  export SHELL="$(command -v zsh)"
  exec -l zsh
fi
```

No two-session dance strictly required here (failure degrades to a working
bash prompt, not a dropped connection) — but testing via a second session
first is still good practice before trusting it.

**Known gaps with Option B, worth knowing:** `getent passwd nealrs` and any
tool that reads `/etc/passwd` directly still reports bash, not zsh — the
system record never changes. Less standard than `chsh`, so it may confuse
whoever administers this box next (including future-you). Otherwise
functionally equivalent to Option A.

Once either option is confirmed working, you're done — every future
`ssh kewtie` (and physical console login, if applicable) lands directly in
zsh, sourcing `.zshrc.linux` (→ `ssh_agent_init.sh`) automatically. If you
went with Option A, the `~/.profile` ssh-agent lines (if added during the
bash-era testing) become dead weight — harmless to leave, since zsh login
shells don't read `.profile` at all.

---

## Troubleshooting

- **Reboot doesn't come back.** Ubuntu keeps the previous kernel installed and selectable from GRUB by default — but reaching it needs physical access. A routine HWE point-release kernel bump on a stable 22.04 install is about as well-tested as this gets; treat this as a known-but-unlikely tail risk, not a reason to avoid the reboot.
- **A container doesn't come back.** Check its restart policy: `docker inspect <name> --format '{{.HostConfig.RestartPolicy.Name}}'`. Most are probably `unless-stopped`/`always` and self-heal; anything else needs `docker compose up -d` from wherever it's defined.
- **`chsh` breaks zsh.** Revert from the still-open safety-net session: `chsh -s /bin/bash`. Then diagnose at leisure — check `zsh --version`, re-run `zsh` manually in bash to see the actual error, check Linuxbrew's health (`brew doctor`).
- **Unexpected extra passphrase prompt.** Expected once right after the reboot (new agent) and possibly once more if you end up restarting `user@1000` again for any reason. Anything beyond that suggests `ssh_agent_init.sh`/`~/.ssh/agent.env` got corrupted again — see that file's own comments, or just `rm ~/.ssh/agent.env` and let it rebuild on next shell start.

## Explicitly out of scope here

- `do-release-upgrade` to 24.04 — see "Why this document exists" above.
- Disabling gdm/X-Wayland for a truly headless boot — independent, lower-stakes, already covered by `kewtie_headless.sh`; can be done anytime, not gated on anything in this runbook.
