# dotfiles

Personal shell environment, machine bootstrap, and cross-machine SSH trust for Neal's machines. One repo, cloned to `~/repos/dotfiles` (or `~/Documents/repos/dotfiles`) on every box, drives:

- a shared zsh config (aliases, functions, prompt, tool wiring) with a per-platform variant for Mac and Linux (Bazzite/Fedora, Ubuntu/Debian), built for parity — the same alias/function surface on both, branching only where the OS actually forces it
- one-shot bootstrap scripts that take a fresh machine to "fully set up", converging toward one generic script per OS (`mac_bootstrap.sh`, `linux_bootstrap.sh`) rather than per-machine scripts
- a single source of truth for known machines (`.machines.json`) that generates both `~/.ssh/config` and SSH-alias shell aliases
- passwordless SSH between machines, and the snippet to set it up
- a shared system health check (`health.sh`) with the same output shape on Mac and Linux
- Claude Code settings, rendered from a template so the one live secret (an MCP token) never touches the repo

Repo is **public** (`github.com/nealrs/dotfiles`) — see [Data & secrets](#data--secrets) before adding anything to it.

## Machine profiles

| Machine | OS | Profile | Status | SSH target? |
| --- | --- | --- | --- | --- |
| gibson | Bazzite (Fedora) | `linux_bootstrap.sh` + `.zshrc.linux` | done | yes — in `.machines.json` |
| kewtie | Ubuntu 22.04 (home server, headless, SSH-only) | `linux_bootstrap.sh` + `.zshrc.linux`, rolled out by hand | **not yet migrated** — currently plain bash. Design doc: `ubuntu.prd.md`. kewtie is production home infra (Home Assistant, AdGuard DNS, etc.), so this profile gets rolled out step-by-step, never by running the script unattended. | yes — in `.machines.json` |
| Macs | macOS | `mac_bootstrap.sh` + `.zshrc.mac` | done | **no** |

Macs get the same shell/tool setup as everything else, but they aren't SSH *targets* — nobody dials into a laptop. `.machines.json` is specifically the registry of SSH-reachable boxes (headless servers like gibson and kewtie), so Macs don't get an entry there and never appear in generated `~/.ssh/config` `Host` blocks. A Mac still runs `print_ssh_trust.sh`/`sshtrust` so it can reach gibson/kewtie without a password — that direction is one-way.

Every machine still gets a `~/.hostname` written during bootstrap (e.g. `kewtie`, `gibson`, or whatever you name a given Mac) — that's what selects its `banner_<name>` in `ascii_art.sh` at login. For SSH-target machines, that same name is also the key in `.machines.json`.

## Configuring a new machine

### Mac

```
git clone https://github.com/nealrs/dotfiles ~/repos/dotfiles
bash ~/repos/dotfiles/mac_bootstrap.sh
```

(or just run the script directly — it clones the repo itself if it isn't already at `~/repos/dotfiles`.) Prompts for: email (SSH key comment), a machine name for `~/.hostname`, git name/email if unset, and whether to generate SSH keys if missing. It checks for curl (ships with macOS — this is just a sanity check), then installs Homebrew + packages (`git gh ruby nano uv eza bat fd ripgrep jq direnv zsh-autosuggestions zsh-syntax-highlighting fzf powerlevel10k 1password-cli`), casks (Docker, 1Password, Slack, Ghostty, etc.), Mac App Store apps (Magnet, Tailscale), NVM + Node LTS + pnpm, symlinks the dotfiles (see [File reference](#file-reference)), generates `~/.ssh/config`, and prints the SSH trust snippet.

Finish with: `source ~/.zshrc`, run `p10k configure` once (saves back into the repo), and run the `ssh-copy-id` commands it printed.

### Linux — Bazzite/Fedora or Ubuntu/Debian

```
git clone https://github.com/nealrs/dotfiles ~/repos/dotfiles
bash ~/repos/dotfiles/linux_bootstrap.sh
```

One script, both distro families — it detects `rpm-ostree` vs `apt-get` and only branches where the package manager actually differs (1Password/Ghostty/Deskflow install method; `apt-get` needs no reboot, `rpm-ostree` does). Everything else is shared: host identity, a curl sanity check, Linuxbrew + packages (`zsh starship atuin zoxide eza fzf jq direnv zsh-autosuggestions zsh-syntax-highlighting 1password-cli`), sets zsh as the login shell, Flatpak apps (Slack, LocalSend) where flatpak is present, NVM + Node LTS + pnpm, SSH keys, symlinks, `~/.ssh/config`, SSH trust snippet.

Finish with: log out/in (or `exec $ZSH_PATH`) to pick up zsh, `source ~/.zshrc`, run the `ssh-copy-id` commands it printed.

**kewtie is the exception** — it's a production, SSH-only home server with no console fallback, so `linux_bootstrap.sh` is never run on it unattended. See `ubuntu.prd.md` for why, and `kewtie_bootstrap.sh` for the hand-walked, step-by-step equivalent (same end state, run and verified one section at a time, no `chsh`).

### Adding a new SSH target (a new headless/server box)

1. Bootstrap it (above) — this generates its own SSH keypair.
2. Add an entry for it to `.machines.json` (name, user, `local_ip` if it has one, `tailscale_hostname`, `tailscale_alias`, `ssh_set_env`).
3. On every machine that should reach it (including Macs), run `updatedotfiles` (pulls the repo, regenerates `~/.ssh/config`) so it knows the new `Host` aliases, then `sshtrust` to get the `ssh-copy-id` command for the new target.

### Adding a new Mac (or any non-target machine)

Just bootstrap it (above) and run `sshtrust` on it — no `.machines.json` entry needed, since nothing will ever need to SSH *into* it. `sshtrust` already lists every current SSH target to authorize against.

Either way, this is still O(n) manual `ssh-copy-id` runs per new machine, not automatic — see `print_ssh_trust.sh` below if that ever becomes worth automating further.

## Aliases & functions

Shared between `.zshrc.mac` and `.zshrc.linux` unless noted. Full source is the zshrc files — this is the map, not the last word.

**General** — `ll`/`l`/`ls` (eza), `k` (clear), `..`/`...`, `reload`/`rel`/`resource` (source `~/.zshrc`), `path` (PATH one-per-line), `json` (pretty print via `python3 -m json.tool`), `psg` (`ps aux | grep`), `o` (open file manager here), `npm` → `pnpm`, `pico` → `nano`, `repos` (`cd $REPOS`), `dots` (`cd $REPOS/dotfiles`).

**Tool swaps** (only if installed) — `cat`→`bat`, `find`→`fd`, `grep`→`rg`.

**Platform-specific**

- Mac: `dns` (flush DNS cache), `hosts` (edit `/etc/hosts`), `showfiles`/`hidefiles` (Finder hidden files), `copy`/`paste` (pbcopy/pbpaste)
- Linux: `copy`/`paste`/`pbcopy`/`pbpaste` (wl-copy/wl-paste under Wayland, else xclip), `open`/`o` (`xdg-open`), `hosts`

**Network/dev** — `ports` (listening sockets — `lsof` on Mac, `ss` on Linux), `headers` (`curl -I`), `web` (quick HTTP server via `python3`), `ii` (connectivity + a title-tag fetch from neal.rs).

**System** — `health` (`health.sh`: CPU load/temp/fan, memory, disk free — same output shape on Mac and Linux, reading native OS commands directly rather than shelling out to something like glances/btop).

**Docker/Podman** — `dockup`/`dockupbuild`/`dockdown`/`docklog`/`dockps`/`dockexec`. On Linux, `docker` aliases to `podman` if Docker itself isn't installed; `pc` is `podman compose` when available.

**Git** — `gs` status, `ga` add -A, `gc` commit -m, `gcl` clone, `gp`/`gpl` push/pull, `gb` checkout -b, `gco` checkout, `gl` log graph, `gd` diff, `gst`/`gsp` stash/pop, `gundo` (soft-reset last commit).

**Python (uv)** — `py` (`uv run python`), `pip`→`uv pip`, `uvr`/`uva`/`uvs`/`uvi`/`uvpy` (run/add/sync/init/python).

**SSH / machines** — generated per host in `.machines.json` by `machines.sh`: for each host with a `local_ip`, an alias named after it (e.g. `kewtie` → `ssh kewtie-lan`); for each host with a `tailscale_alias`, that alias (e.g. `tsk` → `ssh kewtie-tailnet`, `tsg` → `ssh gibson-tailnet`); plus any `extra_aliases`. `tssh <name>` connects to any host by name over Tailscale. `genssh` regenerates `~/.ssh/config` from `.machines.json` + `ssh_config.base`. `sshtrust` prints the `ssh-copy-id` commands to authorize this machine on every other one. `ts`/`ts-status`/`ts-up`/`ts-down` (Tailscale).

**`updatedotfiles`** — `git pull` on the repo, `genssh`, re-renders `~/.claude/settings.json` via `op inject` (skips with a message if 1Password CLI isn't installed/signed in), then re-sources `~/.zshrc`.

**Functions** — `wan`/`lan`/`net` (public + local IPs, shown at login), `weather` (wttr.in), `wifi` (power-cycle Wi-Fi), `mcd` (mkdir + cd), `rn` (runs `rename.sh` — see below), `mo` (random line from `motivation.md`), `hi` (login banner: ASCII art for this host, `net`, `mo`, `weather` — this is what prints the WAN/LAN/weather block you see on every new shell). `nvm` stays lazy (only `nvm.sh` sourcing waits for the first `nvm` call) but the default Node version is primed onto `PATH` at shell startup, so `node`/`npm` work immediately without forcing the full load or fighting a system Node on `PATH`.

## Data & secrets

- **Private SSH keys never live in this repo.** Each machine generates its own keypair during bootstrap (`ssh-keygen`, prompted, skippable). Trust between machines is one-directional-per-pair and set up by copying a *public* key straight to the target's `~/.ssh/authorized_keys` via `ssh-copy-id` (see `print_ssh_trust.sh`) — nothing key-related is ever committed.
- **`.machines.json`** has hostnames, usernames, LAN IPs (RFC1918, only reachable from inside the home network), and Tailscale hostnames/aliases. None of this is a credential, but it's real topology about home infrastructure in a public repo — don't add anything more sensitive than that here (no tokens, no passwords, no public IPs of anything you don't want indexed).
- **`claude_settings.json.tpl`** contains a 1Password *reference* (`op://Private/to-do-mcp/token`), not a secret — `op inject` resolves it locally at render time (via `updatedotfiles` or bootstrap) into `~/.claude/settings.json`, which is never written back into the repo. Rendering silently no-ops (with a message) if the `op` CLI isn't installed or you're not signed in.
- **`.gitignore` only excludes OS noise (`.DS_Store`)** — nothing generated (rendered configs, keys, `~/.ssh/config`) is ever written inside the repo in the first place, it's all written to `$HOME` or `~/.ssh`/`~/.config`. Keep it that way: anything this repo writes should land outside the repo, not get committed.
- **`q11.json`** is an unrelated keyboard (QMK/VIA) config backup — not read by any script here, just parked in the repo for safekeeping.

## File reference

| File | Purpose | Symlinked / rendered to |
| --- | --- | --- |
| `.machines.json` | Source of truth for known **SSH-target** machines (headless servers like gibson/kewtie — not Macs): name, SSH user, LAN IP, Tailscale hostname/alias, extra aliases, per-host `SetEnv`. Edit this to add/rename/remove an SSH target — never hardcode a host's IP anywhere else. | — (read by `gen_ssh_config.sh`, `machines.sh`, `print_ssh_trust.sh`) |
| `ssh_config.base` | Static SSH config appended after the generated per-host blocks — currently just the `github.com` / `UseKeychain` stanza (macOS-only; stripped on Linux — see comment in the file for why `IgnoreUnknown` must be global, not host-scoped). | folded into `~/.ssh/config` |
| `gen_ssh_config.sh` | Generates `~/.ssh/config` from `.machines.json` (`<name>-lan` / `<name>-tailnet` `Host` blocks) + `ssh_config.base`. Strips macOS-only directives when run on non-Darwin. Run via `genssh`. | writes `~/.ssh/config` |
| `print_ssh_trust.sh` | Prints `ssh-copy-id` commands to authorize this machine's public key on every *other* machine in `.machines.json`. Run via `sshtrust`, also run once at the end of bootstrap. | — (prints only, does not run ssh-copy-id itself) |
| `machines.sh` | Generates the per-host shell aliases (`kewtie`, `tsk`, `tsg`, ...) and the `tssh` function from `.machines.json`. Sourced by both zshrc files. | — |
| `mac_bootstrap.sh` | One-shot Mac setup: Xcode CLI tools, Homebrew + packages/casks/MAS apps, NVM/Node/pnpm, SSH keys, git config, clones the repo, symlinks dotfiles, generates `~/.ssh/config`, prints SSH trust snippet. | — |
| `linux_bootstrap.sh` | Same shape, for any Linux box: detects `rpm-ostree` (Bazzite/Fedora) vs `apt-get` (Ubuntu/Debian) and branches only for 1Password/Ghostty/Deskflow install method; Linuxbrew + packages, sets zsh as login shell, Flatpak apps, NVM/Node/pnpm, SSH keys, git config, symlinks, `~/.ssh/config`, SSH trust snippet. Not run unattended on kewtie — see `kewtie_bootstrap.sh`. | — |
| `kewtie_bootstrap.sh` | Hand-walked equivalent of `linux_bootstrap.sh` for kewtie specifically: same end state, split into independently-runnable, idempotent sections with no `chsh` and no step that touches Docker/systemd/ports. Read `ubuntu.prd.md` for why. | — |
| `ubuntu.prd.md` | Design doc for the Ubuntu/kewtie profile, written against kewtie's current state — the rollout constraints, and why kewtie gets the manual script instead of `linux_bootstrap.sh` directly. | — |
| `health.sh` | Quick system health snapshot (CPU load/temp/fan, memory, disk free) using native OS commands (`sysctl`/`vm_stat` on Mac, `/proc`/`sensors` on Linux) rather than a slower tool like glances. Run via `health`. | — |
| `.zshrc.mac` | zsh config for Mac machines. | `~/.zshrc` (Mac) |
| `.zshrc.linux` | zsh config for Linux machines (Bazzite/Fedora, Ubuntu/Debian). | `~/.zshrc` (Linux) |
| `motivation.md` | One quote per `- line`, read by `mo()` directly from the repo. Auto-downloaded from GitHub raw into the repo if missing on a machine that skipped bootstrap. | — |
| `.nanorc` | nano editor config (line numbers, softwrap, syntax highlighting). | `~/.nanorc` |
| `.p10k.zsh` | Powerlevel10k prompt config, generated by `p10k configure` (Mac only). Bootstrap symlinks it only if it already exists in the repo. | `~/.p10k.zsh` (Mac) |
| `starship.toml` | Starship prompt config (Linux only — Mac uses Powerlevel10k instead). | `~/.config/starship.toml` (Linux) |
| `ghostty.mac.config` | Ghostty config for Mac: shared appearance (font, theme, cursor) plus sudo shell integration. Duplicated from `ghostty.linux.config` rather than shared via `config-file` — that directive doesn't resolve reliably through a symlinked dotfile. | `~/Library/Application Support/com.mitchellh.ghostty/config` (Mac) |
| `ghostty.linux.config` | Ghostty config for Linux: same shared appearance as the Mac file, plus ctrl+c/ctrl+v copy-paste (no Cmd key on Linux). | `~/.config/ghostty/config` (Linux) |
| `ascii_art.sh` | `banner_<name>` functions (one per machine, e.g. `banner_kewtie`, `banner_gibson`), sourced by `hi()` at shell startup. Auto-downloaded from GitHub raw if missing. | sourced, not symlinked |
| `rename.sh` | Standalone file-renaming utility (normalizes markdown/txt/PDF/image filenames to `YYYY-MM-DD-kebab-case.ext`). Invoked via the `rn` function, which locates it under `~/repos/dotfiles` or `~/Documents/repos/dotfiles`. | invoked directly, not symlinked |
| `claude_settings.json.tpl` | Template for Claude Code settings (MCP servers, permission allow/deny lists) with a 1Password secret reference. Rendered via `op inject` in `updatedotfiles`/bootstrap. | renders to `~/.claude/settings.json` (not committed) |
| `q11.json` | Keyboard config backup, unrelated to shell setup. | — |
| `fusion_drive.sh` | One-off aliases (`diskcheck`, `nofusion`) for a specific dying HDD on an iMac 2019 Fusion Drive — not sourced by any zshrc, not part of the general machine setup. | — |

## `$REPOS` resolution

Both zshrc files set `REPOS="$HOME/repos"`, falling back to `$HOME/Documents/repos` if `~/repos` doesn't exist. Bootstrap scripts always clone to `~/repos/dotfiles`; the fallback exists for machines (like this one) where the repo instead lives under `~/Documents/repos/dotfiles`.
