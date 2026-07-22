#!/bin/bash
# kewtie_bootstrap.sh — hand-walked bootstrap for kewtie specifically.
#
# WHY THIS EXISTS (see ubuntu.prd.md for full detail):
#   kewtie is SSH-only production home infra with no console fallback.
#   AdGuard is the network's DNS; Home Assistant, zigbee2mqtt, and ~20 other
#   Docker containers are load-bearing. linux_bootstrap.sh (the general
#   Bazzite/Ubuntu script) is NOT run on kewtie unattended — this script is
#   the safe, incremental substitute: every section reads/verifies before
#   writing anything, pauses so you can check the result, and skips whatever
#   is already true on this machine.
#
# ASSUMED ALREADY TRUE ON THIS MACHINE (verified, not redone, in Section 1):
#   - git is configured with an SSH key already added to GitHub
#   - the dotfiles repo is already cloned locally
#   - ~/.hostname is already set
#   - nvm / node / Docker are already installed and Docker is running
#     a bunch of services — none of that is touched here.
#
# HARD RULES this script follows throughout:
#   - No `chsh` / no changing the login shell. Ever. bash stays default.
#   - No `docker`, `systemctl`, `/etc/hosts`, or firewall/port commands.
#   - No `apt install` beyond what Homebrew's installer needs on its own.
#   - No reboot required or suggested at any point.
#   - No GUI packages (1Password app, Ghostty, Deskflow, Slack, LocalSend) —
#     kewtie is headless. Those live only in linux_bootstrap.sh.
#   - Every section is idempotent — safe to re-run the whole script, or just
#     the one section you're on, as many times as you want.
#
# HOW TO RUN THIS:
#   Recommended: inside tmux/screen, so a dropped SSH connection doesn't
#   interrupt a step partway:
#     tmux new -s bootstrap
#     bash ~/repos/dotfiles/kewtie_bootstrap.sh   # or wherever you cloned it
#   The script pauses after every section — read the output, run the
#   suggested "verify" command yourself, then press Enter to continue (or
#   Ctrl+C to stop here for the day; every section is safe to resume later).
#   Prefer to go even slower? Copy-paste one section at a time into your own
#   shell instead of running the file — every section below is self-contained.
#
#   Set PAUSE=0 to run straight through without stopping, once you've done
#   a full walkthrough once and trust it:  PAUSE=0 bash kewtie_bootstrap.sh

set -uo pipefail   # deliberately not -e: an optional step failing (e.g. op
                    # inject with no 1Password session) shouldn't abort the run

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'
ok()      { echo -e "${GREEN}✓${NC}  $1"; }
info()    { echo -e "${YELLOW}→${NC}  $1"; }
warn()    { echo -e "${RED}!${NC}  $1"; }
section() { echo -e "\n${CYAN}== $1 ==${NC}"; }

PAUSE="${PAUSE:-1}"
checkpoint() {
  [[ "$PAUSE" == "0" ]] && return 0
  echo ""
  info "Checkpoint — $1"
  read -p "   Press Enter to continue, or Ctrl+C to stop here for now... " _
}

# ============================================================
# 0. SAFETY SNAPSHOT (read-only — nothing is modified in this section)
# ============================================================
section "0. Safety snapshot"
info "Recording current state so you can confirm nothing changed later."
INITIAL_CONTAINERS="$(docker ps -q 2>/dev/null | wc -l | tr -d ' ')"
echo "   Login shell:         $SHELL"
echo "   Running containers:  $INITIAL_CONTAINERS  (docker ps for details)"
ok "snapshot taken — nothing modified yet"

# ============================================================
# 1. VERIFY PREREQUISITES (should already all be true — this only checks)
# ============================================================
section "1. Verify prerequisites"

if [[ -f ~/.hostname ]]; then
  ok "~/.hostname = $(cat ~/.hostname)"
else
  warn "~/.hostname missing. This script assumes it's already set: echo kewtie > ~/.hostname"
fi

if [[ -f ~/.ssh/id_ed25519 ]]; then
  ok "SSH key exists (~/.ssh/id_ed25519)"
else
  warn "No SSH key found at ~/.ssh/id_ed25519 — this script assumes one already exists and does not generate one."
fi

GIT_NAME=$(git config --global user.name 2>/dev/null || true)
GIT_EMAIL=$(git config --global user.email 2>/dev/null || true)
if [[ -n "$GIT_NAME" && -n "$GIT_EMAIL" ]]; then
  ok "git config: $GIT_NAME <$GIT_EMAIL>"
else
  warn "git user.name/user.email not set globally. Set by hand if needed:"
  warn "  git config --global user.name \"...\"  &&  git config --global user.email \"...\""
fi

DOTFILES=""
for candidate in "$HOME/repos/dotfiles" "$HOME/Documents/repos/dotfiles"; do
  if [[ -d "$candidate/.git" ]]; then
    DOTFILES="$candidate"
    break
  fi
done
if [[ -z "$DOTFILES" ]]; then
  read -p "   Couldn't find the cloned dotfiles repo in the usual spots — full path to it: " DOTFILES
fi
if [[ -d "$DOTFILES/.git" ]]; then
  ok "dotfiles repo found at $DOTFILES"
else
  warn "$DOTFILES doesn't look like the dotfiles repo (.git missing) — fix and re-run this script."
  exit 1
fi

if command -v curl &>/dev/null; then
  ok "curl present"
else
  warn "curl not found — needed by the Homebrew install step below. Install it by hand (e.g. sudo apt-get install curl) and re-run."
fi

if command -v docker &>/dev/null; then
  ok "docker present, $INITIAL_CONTAINERS containers running — this script will not touch it, ever"
else
  warn "docker not found on PATH in this shell — unexpected for kewtie, but not this script's concern either way"
fi

checkpoint "prerequisites verified. Nothing has been installed or changed yet — safe to stop here."

# ============================================================
# 2. LINUXBREW (needs sudo once)
# ============================================================
section "2. Linuxbrew"
info "The official installer may run apt-get for a few missing build deps"
info "(build-essential, procps, file) if you don't have them — additive only,"
info "no existing package touched, no reboot needed. Accepted in ubuntu.prd.md."
if command -v brew &>/dev/null; then
  ok "already installed ($(brew --version | head -1))"
else
  info "Installing Linuxbrew — you'll be prompted for your sudo password once..."
  /bin/bash -c "$(curl -fsSL --connect-timeout 10 https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ok "Linuxbrew installed"
fi
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

checkpoint "verify with: brew --version   — and: docker ps -q | wc -l   (should still read $INITIAL_CONTAINERS)"

# ============================================================
# 3. BREW PACKAGES
# ============================================================
section "3. Brew packages"
PACKAGES=(zsh starship atuin zoxide eza bat fd ripgrep nano btop fzf jq direnv zsh-autosuggestions zsh-syntax-highlighting 1password-cli)
for pkg in "${PACKAGES[@]}"; do
  if brew list "$pkg" &>/dev/null 2>&1; then
    ok "$pkg"
  else
    info "Installing $pkg..."
    brew install "$pkg" && ok "$pkg"
  fi
done
info "No chsh here — bash stays your login shell. You'll test zsh by hand in Section 5."

checkpoint "verify with: brew list   — and: docker ps -q | wc -l   (should still read $INITIAL_CONTAINERS)"

# ============================================================
# 4. PNPM (additive only — your existing nvm/node install is untouched)
# ============================================================
section "4. pnpm"
if ! command -v npm &>/dev/null; then
  warn "npm not on PATH in this shell. If nvm is lazy-loaded, try: nvm use default"
  warn "Skipping pnpm for now — re-run this section once npm is reachable."
else
  info "Existing node: $(node --version), npm: $(npm --version) — untouched by this step"
  if command -v pnpm &>/dev/null; then
    ok "pnpm already installed ($(pnpm --version))"
  else
    info "Installing pnpm as a global npm package..."
    npm install -g pnpm && ok "pnpm installed ($(pnpm --version))"
  fi
fi
info "pnpm is a separate binary — it doesn't change npm, package-lock.json, or any"
info "existing project. It only activates in a project if you deliberately run 'pnpm install' there."

checkpoint "verify with: pnpm --version   — and confirm an existing npm project still works: npm run <whatever> as usual"

# ============================================================
# 5. UV (Python toolchain — additive only, doesn't touch system python)
# ============================================================
section "5. uv"
if command -v uv &>/dev/null; then
  ok "already installed ($(uv --version))"
else
  info "Installing uv..."
  curl -LsSf --connect-timeout 10 https://astral.sh/uv/install.sh | sh -s -- --no-modify-path
  export PATH="$HOME/.local/bin:$PATH"
  ok "uv installed"
fi

if uv python list 2>/dev/null | grep -q "3.13"; then
  ok "Python 3.13 already installed via uv"
else
  info "Installing Python 3.13 via uv..."
  uv python install 3.13 && ok "Python 3.13 installed"
fi

checkpoint "verify with: uv --version   — and: docker ps -q | wc -l   (should still read $INITIAL_CONTAINERS)"

# ============================================================
# 6. SYMLINK DOTFILES
# ============================================================
section "6. Symlink dotfiles"
symlink_dotfile() {
  local src="$1" dst="$2" label; label="$(basename "$dst")"
  if [[ -L "$dst" ]]; then
    ok "$label symlink exists"
  elif [[ -e "$dst" ]]; then
    warn "$label exists as a real file — NOT overwriting. Fix by hand if desired: ln -sf $src $dst"
  elif [[ -f "$src" ]]; then
    ln -sf "$src" "$dst"
    ok "$label -> dotfiles"
  else
    info "$label not in repo — skipping"
  fi
}

symlink_dotfile "$DOTFILES/.zshrc.linux" ~/.zshrc
symlink_dotfile "$DOTFILES/.nanorc.linux" ~/.nanorc
mkdir -p ~/.config
symlink_dotfile "$DOTFILES/starship.toml" ~/.config/starship.toml
info "Skipping ghostty.linux.config on purpose — kewtie is headless, no terminal emulator to configure."

checkpoint "IMPORTANT — verify by hand before continuing: run 'zsh' (just the command, not chsh).
   Check the prompt (starship), aliases (ll, gs, k, ...), and that a new pane starts fast.
   Then 'exit' back to bash. Your login shell is still bash either way — this only tests it."

# ============================================================
# 7. REGENERATE ~/.ssh/config
# This only affects OUTBOUND `ssh <host>` FROM kewtie to other machines —
# it does not touch sshd_config or anything about how other machines
# connect INTO kewtie, so it cannot cause a lockout either way.
# ============================================================
section "7. Regenerate ~/.ssh/config"
BACKUP=""
if [[ -f ~/.ssh/config ]]; then
  BACKUP=~/.ssh/config.bak.$(date +%Y%m%d%H%M%S)
  cp ~/.ssh/config "$BACKUP"
  ok "backed up existing ~/.ssh/config -> $BACKUP"
fi
if [[ -f "$DOTFILES/gen_ssh_config.sh" ]]; then
  bash "$DOTFILES/gen_ssh_config.sh" && ok "~/.ssh/config generated"
fi

checkpoint "verify with: diff \"${BACKUP:-/dev/null}\" ~/.ssh/config   then try: ssh gibson-tailnet (or any Host block) from kewtie"

# ============================================================
# 8. SSH TRUST (read-only — prints commands, changes nothing)
# ============================================================
section "8. SSH trust"
if [[ -f "$DOTFILES/print_ssh_trust.sh" ]]; then
  bash "$DOTFILES/print_ssh_trust.sh"
fi
info "Those ssh-copy-id commands only add kewtie's PUBLIC key to the OTHER machines'"
info "authorized_keys — nothing local to kewtie changes. Run them whenever you're ready."

# ============================================================
# 9. CLAUDE CODE SETTINGS (optional — needs 1Password CLI signed in)
# Last on purpose: op inject depends on the 1Password CLI being installed
# AND signed in, which often isn't true yet on a first run. Everything else
# above should succeed regardless of whether this step does.
# ============================================================
section "9. Claude Code settings"
mkdir -p ~/.claude
if command -v op &>/dev/null; then
  info "Rendering ~/.claude/settings.json via 1Password..."
  op inject -i "$DOTFILES/claude_settings.json.tpl" -o ~/.claude/settings.json \
    && ok "~/.claude/settings.json rendered" \
    || warn "op inject failed — run 'op signin' and re-run just this section later"
else
  info "1Password CLI not installed/signed in on kewtie — skipping. Harmless to skip; re-run this section anytime."
fi

checkpoint "verify with: cat ~/.claude/settings.json  (skip entirely if you don't run Claude Code on kewtie)"

# ============================================================
# DONE
# ============================================================
section "Done"
FINAL_CONTAINERS="$(docker ps -q 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$FINAL_CONTAINERS" == "$INITIAL_CONTAINERS" ]]; then
  ok "Docker container count unchanged: $INITIAL_CONTAINERS -> $FINAL_CONTAINERS"
else
  warn "Docker container count changed: $INITIAL_CONTAINERS -> $FINAL_CONTAINERS (this script never runs docker commands — worth checking why)"
fi

echo ""
echo "  What this script deliberately did NOT do (see ubuntu.prd.md for why):"
echo "  - Did not run chsh — bash is still kewtie's login shell."
echo "  - Did not touch docker, systemctl, /etc/hosts, or any port/firewall config."
echo "  - Did not reboot, or ask you to."
echo "  - Did not reinstall or modify nvm, node, or existing npm workflows."
echo "  - Did not install any GUI app (1Password, Ghostty, Deskflow, Slack, LocalSend) — headless box."
echo ""
echo "  Next steps, at your own pace:"
echo "  1. Keep using 'zsh' by hand across sessions to build confidence in it."
echo "  2. Only decide later whether/how to flip the default shell (chsh vs. a"
echo "     client-side SSH RemoteCommand) — still an open question in ubuntu.prd.md."
echo "  3. Run the ssh-copy-id commands from Section 8 once you're ready to let"
echo "     kewtie SSH into other machines without a password."
echo ""
