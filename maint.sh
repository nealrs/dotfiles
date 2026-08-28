#!/usr/bin/env bash
# maint.sh — occasional system upkeep report: brew, docker/podman, dotfiles
# staleness, and a couple of OS-specific checks. Report/suggest only — never
# runs an upgrade, cleanup, or prune itself. Run via the `maint` function
# (shell_common.sh), which also stamps ~/.cache/dotfiles/maint_last_run so
# hi() can nag if it's been 30+ days. Mirrors health.sh's shape: standalone,
# uname-branching, no shared state.
# https://github.com/nealrs/dotfiles

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

section()  { printf "\n${CYAN}== %s ==${NC}\n" "$1"; }
row()      { printf "${GREEN}%-14s${NC} %s\n" "$1" "$2"; }
suggest()  { printf "${YELLOW}→${NC}  %s\n" "$1"; }

# Self-locate rather than trust an inherited $REPOS (it's unexported in
# .zshrc.*, so a plain `bash maint.sh` subshell wouldn't see it anyway).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

OS="$(uname -s)"

# ============================================================
# Homebrew (mac + linuxbrew boxes — both already on PATH via shellenv in
# an interactive shell)
# ============================================================
if command -v brew &>/dev/null; then
  section "Homebrew"
  if brew update --quiet &>/dev/null; then
    outdated="$(brew outdated 2>/dev/null)"
    if [[ -n "$outdated" ]]; then
      row "Outdated" "$(echo "$outdated" | wc -l | tr -d ' ') package(s)"
      echo "$outdated" | sed 's/^/    /'
      suggest "brew upgrade && brew cleanup"
    else
      row "Outdated" "none"
    fi
  else
    row "Outdated" "skipped (brew update failed — offline?)"
  fi

  cleanup="$(brew cleanup --dry-run 2>/dev/null)"
  if [[ -n "$cleanup" ]]; then
    row "Cleanup" "would reclaim:"
    echo "$cleanup" | tail -5 | sed 's/^/    /'
  else
    row "Cleanup" "nothing to reclaim"
  fi

  doctor="$(brew doctor 2>&1)"
  if [[ "$doctor" == *"ready to brew"* ]]; then
    row "Doctor" "ok"
  else
    row "Doctor" "flagged issues — run \`brew doctor\` for details"
  fi
fi

# ============================================================
# Docker / Podman — prefer docker if present and its daemon responds
# (common on mac to have the CLI but Docker Desktop not running), else
# fall back to podman.
# ============================================================
runtime=""
if command -v docker &>/dev/null && docker info &>/dev/null; then
  runtime="docker"
elif command -v podman &>/dev/null; then
  runtime="podman"
fi

if [[ -n "$runtime" ]]; then
  section "Containers ($runtime)"
  restarting="$($runtime ps -a --filter status=restarting -q 2>/dev/null | wc -l | tr -d ' ')"
  unhealthy="$($runtime ps -a --filter health=unhealthy -q 2>/dev/null | wc -l | tr -d ' ')"
  if [[ "$restarting" -gt 0 || "$unhealthy" -gt 0 ]]; then
    row "Health" "${restarting} restarting, ${unhealthy} unhealthy"
  else
    row "Health" "all healthy"
  fi

  df_out="$($runtime system df 2>/dev/null)"
  if [[ -n "$df_out" ]]; then
    echo "$df_out" | sed 's/^/  /'
    if echo "$df_out" | awk 'NR>1{gsub(/[^0-9.]/,"",$NF); if ($NF+0>0) f=1} END{exit !f}'; then
      suggest "$runtime system prune -a  # -a also drops unused-but-tagged images, not just dangling ones"
    fi
  else
    row "Status" "could not read system df"
  fi
elif command -v docker &>/dev/null; then
  section "Containers (docker)"
  row "Status" "docker CLI found but daemon not responding (Docker Desktop not running?)"
fi

# ============================================================
# Dotfiles staleness
# ============================================================
section "Dotfiles"
if [[ -d "$SCRIPT_DIR/.git" ]]; then
  if git -C "$SCRIPT_DIR" fetch --quiet origin master 2>/dev/null; then
    behind="$(git -C "$SCRIPT_DIR" rev-list --count HEAD..origin/master 2>/dev/null || echo "?")"
    if [[ "$behind" == "0" ]]; then
      row "Behind origin" "up to date"
    else
      row "Behind origin" "$behind commit(s)"
      suggest "updatedots"
    fi
  else
    row "Behind origin" "skipped (fetch failed — offline?)"
  fi
else
  row "Status" "not a git checkout — skipped"
fi

# ============================================================
# Dev tool globals
# ============================================================
if command -v npm &>/dev/null || command -v pnpm &>/dev/null || command -v uv &>/dev/null; then
  section "Dev tool globals"
  if command -v npm &>/dev/null; then
    # Real npm binary — npm is aliased to pnpm interactively (.zshrc.*), so
    # this checks the underlying install you don't actually use day-to-day.
    npm_out="$(npm outdated -g 2>/dev/null)"
    if [[ -n "$npm_out" ]]; then
      row "npm -g (real)" "$(echo "$npm_out" | tail -n +2 | wc -l | tr -d ' ') outdated"
      suggest "command npm update -g  # 'command' bypasses the npm->pnpm alias"
    else
      row "npm -g (real)" "none"
    fi
  fi
  if command -v pnpm &>/dev/null; then
    pnpm_out="$(pnpm outdated -g 2>/dev/null)"
    if [[ -n "$pnpm_out" ]]; then
      row "pnpm -g" "$(echo "$pnpm_out" | tail -n +2 | wc -l | tr -d ' ') outdated"
      suggest "pnpm update -g"
    else
      row "pnpm -g" "none"
    fi
  fi
  if command -v uv &>/dev/null; then
    # uv has no reliable "outdated" flag as of this writing — just surface
    # the installed count and point at the manual upgrade command.
    uv_count="$(uv tool list 2>/dev/null | grep -c '^[a-zA-Z]')"
    row "uv tools" "$uv_count installed"
    [[ "$uv_count" -gt 0 ]] && suggest "uv tool upgrade --all"
  fi
fi

# ============================================================
# Uptime
# ============================================================
section "Uptime"
if [[ "$OS" == "Darwin" ]]; then
  # awk field-split on non-digits, same technique health.sh already uses for
  # vm_stat — more robust than a regex against BSD sed's quirks (a sed -E
  # capture-group version of this silently failed to parse and produced a
  # bogus ~56-year uptime instead of erroring, hence the explicit guard below).
  boot="$(sysctl -n kern.boottime | awk -F'[^0-9]+' '{print $2}')"
  if [[ -n "$boot" && "$boot" -gt 0 ]]; then
    elapsed=$(( $(date +%s) - boot ))
    row "Since boot" "$(( elapsed/86400 ))d $(( (elapsed%86400)/3600 ))h"
  else
    row "Since boot" "couldn't parse kern.boottime — got: $(sysctl -n kern.boottime 2>&1)"
  fi
else
  row "Since boot" "$(uptime -p 2>/dev/null | sed 's/^up //')"
  [[ -f /var/run/reboot-required ]] && row "Reboot" "required (kernel/lib update pending)"
fi

# ============================================================
# systemd journal size (Linux)
# ============================================================
if [[ "$OS" != "Darwin" ]] && command -v journalctl &>/dev/null; then
  section "systemd journal"
  jsize="$(journalctl --disk-usage 2>/dev/null | grep -oE '[0-9.]+[KMGT]' | tail -1)"
  row "Disk usage" "${jsize:-unknown}"
fi

# ============================================================
# OS-specific extras
# ============================================================
if [[ "$OS" == "Darwin" ]]; then
  section "macOS Software Update (this can take 10-20s)"
  su_out="$(softwareupdate -l 2>&1)"
  if echo "$su_out" | grep -qi "no new software available"; then
    row "Updates" "none"
  else
    row "Updates" "available — run \`softwareupdate -l\` for details"
  fi
else
  if command -v rpm-ostree &>/dev/null; then
    section "rpm-ostree"
    pending="$(rpm-ostree status 2>/dev/null | awk '/^State: /{print $2}')"
    if [[ "$pending" == "idle" ]]; then
      row "Deployments" "no pending update"
    else
      row "Deployments" "update in progress or pending reboot — check \`rpm-ostree status\`"
    fi

    # --check does a lightweight remote metadata check without staging
    # anything — doesn't need root.
    check_out="$(rpm-ostree upgrade --check 2>&1)"
    if echo "$check_out" | grep -qi "no upgrade available\|already booted"; then
      row "Upgrade" "none available"
    elif echo "$check_out" | grep -qi "AvailableUpdate\|Version:"; then
      row "Upgrade" "available"
      suggest "rpm-ostree upgrade"
    else
      row "Upgrade" "check failed — offline? (\`rpm-ostree upgrade --check\` for details)"
    fi
  elif command -v apt-get &>/dev/null; then
    section "apt"
    # Uses the existing package cache — doesn't run `apt update` itself
    # (needs root, and this script never sudos). Numbers reflect however
    # stale/fresh the last `apt update` (by anyone/anything) left it.
    upgradable="$(apt list --upgradable 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')"
    if [[ "$upgradable" -gt 0 ]]; then
      row "Upgradable" "$upgradable package(s) (per last \`apt update\`)"
      suggest "sudo apt update && sudo apt upgrade"
    else
      row "Upgradable" "none (per last \`apt update\` — run it first if unsure)"
    fi

    orphans="$(apt-get -s autoremove 2>/dev/null | grep -c '^Remv')"
    if [[ "$orphans" -gt 0 ]]; then
      row "Orphaned pkgs" "$orphans"
      suggest "sudo apt-get autoremove"
    else
      row "Orphaned pkgs" "none"
    fi
  fi
fi

echo ""
