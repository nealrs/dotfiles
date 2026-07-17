#!/bin/bash
# linux_bootstrap.sh — sets up a new Linux box with everything needed for .zshrc.linux
# Supports Bazzite/Fedora (rpm-ostree) and Ubuntu/Debian (apt). Detects which
# one it's running on and branches only where the package manager differs.
# https://github.com/nealrs/dotfiles

read -p "Email address (for SSH key): " EMAIL

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ok()      { echo -e "${GREEN}✓${NC}  $1"; }
info()    { echo -e "${YELLOW}→${NC}  $1"; }
section() { echo -e "\n${CYAN}== $1 ==${NC}"; }

# ============================================================
# OS DETECTION
# ============================================================
if command -v rpm-ostree &>/dev/null; then
  OS_FAMILY="ostree"
elif command -v apt-get &>/dev/null; then
  OS_FAMILY="apt"
else
  OS_FAMILY="unknown"
fi

# ============================================================
# HOST IDENTITY
# ============================================================
section "Host identity"
if [[ -f ~/.hostname ]]; then
  ok "~/.hostname already set to '$(cat ~/.hostname)'"
else
  read -p "   Machine name (e.g. kewtie, gibson): " HOST_NAME
  echo "$HOST_NAME" > ~/.hostname
  ok "~/.hostname written ('$HOST_NAME')"
fi

# ============================================================
# SYSTEM PACKAGES (1Password, Ghostty, Deskflow)
# rpm-ostree branch requires a reboot after; apt branch does not.
# ============================================================
if [[ "$OS_FAMILY" == "ostree" ]]; then
  section "System packages (rpm-ostree)"

  # 1Password — official RPM repo
  if rpm -q 1password &>/dev/null; then
    ok "1password"
  else
    info "Setting up 1Password repo..."
    sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc
    sudo tee /etc/yum.repos.d/1password.repo > /dev/null <<'EOF'
[1password]
name=1Password Stable Channel
baseurl=https://downloads.1password.com/linux/rpm/stable/x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://downloads.1password.com/linux/keys/1password.asc
EOF
    sudo rpm-ostree install 1password && ok "1password — reboot required" || info "1password failed"
  fi

  # Ghostty — Fedora COPR (no official Fedora/Flathub package yet)
  if rpm -q ghostty &>/dev/null; then
    ok "ghostty"
  else
    info "Enabling ghostty COPR (scottames/ghostty)..."
    sudo dnf copr enable -y scottames/ghostty
    sudo rpm-ostree install ghostty && ok "ghostty — reboot required" || info "ghostty failed"
  fi

  # Deskflow — no yum repo; install manually from GitHub releases
  if rpm -q deskflow &>/dev/null; then
    ok "deskflow"
  else
    info "Deskflow: download the RPM from https://github.com/deskflow/deskflow/releases"
    info "  then run: sudo rpm-ostree install <path>.rpm && systemctl reboot"
  fi

elif [[ "$OS_FAMILY" == "apt" ]]; then
  section "System packages (apt)"
  sudo apt-get update -qq

  # 1Password — official apt repo
  if dpkg -s 1password &>/dev/null; then
    ok "1password"
  else
    info "Setting up 1Password apt repo..."
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
      sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
    echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | \
      sudo tee /etc/apt/sources.list.d/1password.list > /dev/null
    sudo apt-get update -qq
    sudo apt-get install -y 1password && ok "1password" || info "1password failed"
  fi

  # Ghostty — official Ubuntu repo on 26.04+, community packages otherwise
  if dpkg -s ghostty &>/dev/null; then
    ok "ghostty"
  elif apt-cache show ghostty &>/dev/null 2>&1; then
    info "Installing ghostty (official repo)..."
    sudo apt-get install -y ghostty && ok "ghostty" || info "ghostty failed"
  else
    info "ghostty not in apt repos on this release — using community packages (mkasberg/ghostty-ubuntu)..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)" && \
      ok "ghostty" || info "ghostty failed"
  fi

  # Deskflow — no reliable repo across releases; install manually from GitHub releases
  if dpkg -s deskflow &>/dev/null; then
    ok "deskflow"
  else
    info "Deskflow: download the .deb for your release from https://github.com/deskflow/deskflow/releases"
    info "  then run: sudo apt install ./deskflow-<version>-<codename>-x86_64.deb"
  fi

else
  section "System packages"
  info "Unrecognized package manager (no rpm-ostree or apt-get found) — skipping 1Password/Ghostty/Deskflow"
fi

# ============================================================
# HOMEBREW (Linuxbrew)
# ============================================================
section "Homebrew (Linuxbrew)"
if command -v brew &>/dev/null; then
  ok "already installed"
else
  info "Installing Linuxbrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ok "installed"
fi
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# ============================================================
# BREW PACKAGES
# ============================================================
section "Brew packages"

PACKAGES=(
  zsh
  starship
  atuin
  zoxide
  eza
  fzf
  direnv
  zsh-autosuggestions
  zsh-syntax-highlighting
  1password-cli
)

for pkg in "${PACKAGES[@]}"; do
  if brew list "$pkg" &>/dev/null 2>&1; then
    ok "$pkg"
  else
    info "Installing $pkg..."
    brew install "$pkg" && ok "$pkg"
  fi
done

# ============================================================
# ZSH AS DEFAULT SHELL
# ============================================================
section "Default shell"
ZSH_PATH="$(brew --prefix)/bin/zsh"
if [[ "$SHELL" == "$ZSH_PATH" ]]; then
  ok "zsh already default ($ZSH_PATH)"
else
  if ! grep -qF "$ZSH_PATH" /etc/shells; then
    info "Adding $ZSH_PATH to /etc/shells..."
    echo "$ZSH_PATH" | sudo tee -a /etc/shells
  fi
  info "Setting default shell to $ZSH_PATH..."
  chsh -s "$ZSH_PATH"
  ok "default shell set — takes effect on next login"
fi

# ============================================================
# FLATPAK APPS
# ============================================================
section "Flatpak apps"

if ! command -v flatpak &>/dev/null; then
  info "flatpak not installed — skipping Slack/LocalSend (Ubuntu: sudo apt install flatpak)"
else
  flatpak_install() {
    local id="$1" name="$2"
    if flatpak list --columns=application 2>/dev/null | grep -qF "$id"; then
      ok "$name"
    else
      info "Installing $name..."
      flatpak install -y flathub "$id" 2>/dev/null && ok "$name" || \
        info "$name failed — ensure Flathub is enabled: flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo"
    fi
  }

  flatpak_install com.slack.Slack "Slack"
  flatpak_install org.localsend.localsend_app "LocalSend"
  # flatpak_install us.zoom.Zoom "Zoom"
fi

# ============================================================
# UV (Python toolchain)
# ============================================================
section "uv"
if command -v uv &>/dev/null; then
  ok "already installed ($(uv --version))"
else
  info "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
  ok "uv installed"
fi

if uv python list 2>/dev/null | grep -q "3.13"; then
  ok "Python 3.13 already installed via uv"
else
  info "Installing Python 3.13 via uv..."
  uv python install 3.13 && ok "Python 3.13 installed"
fi

# ============================================================
# NVM
# ============================================================
section "NVM"
export NVM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvm"
if [[ -d "$NVM_DIR" ]]; then
  ok "already installed ($NVM_DIR)"
else
  info "Installing NVM (latest) to $NVM_DIR..."
  LATEST_NVM=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
  curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${LATEST_NVM}/install.sh" | bash
  ok "installed ($LATEST_NVM)"
fi

[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

# ============================================================
# NODE + PNPM
# ============================================================
section "Node.js + pnpm"
if nvm ls --no-colors 2>/dev/null | grep -q "lts"; then
  ok "Node.js LTS already installed via nvm ($(node --version))"
else
  info "Installing Node.js LTS via nvm..."
  nvm install --lts
  nvm use --lts
  nvm alias default lts/*
  ok "Node.js LTS installed ($(node --version))"
fi

if command -v pnpm &>/dev/null; then
  ok "pnpm already installed"
else
  info "Installing pnpm..."
  npm install -g pnpm
  ok "pnpm installed"
fi

# ============================================================
# SSH KEYS
# ============================================================
section "SSH Keys"
if [[ -f ~/.ssh/id_ed25519 ]]; then
  ok "ED25519 key exists"
else
  info "No ED25519 key found."
  read -p "   Generate one now? (y/n) " -n 1 -r; echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    ssh-keygen -t ed25519 -C "$EMAIL"
    ok "Generated ~/.ssh/id_ed25519"
    echo ""
    echo "   Public key — add this to GitHub / servers:"
    echo ""
    cat ~/.ssh/id_ed25519.pub
    echo ""
  fi
fi

# ============================================================
# GIT CONFIG
# ============================================================
section "Git config"
GIT_NAME=$(git config --global user.name 2>/dev/null)
GIT_EMAIL=$(git config --global user.email 2>/dev/null)
if [[ -n "$GIT_NAME" && -n "$GIT_EMAIL" ]]; then
  ok "git config: $GIT_NAME <$GIT_EMAIL>"
else
  read -p "   Git name: " GIT_NAME
  read -p "   Git email: " GIT_EMAIL
  git config --global user.name "$GIT_NAME"
  git config --global user.email "$GIT_EMAIL"
  ok "git config set"
fi

# ============================================================
# DOTFILES
# ============================================================
section "Dotfiles"

DOTFILES="$HOME/repos/dotfiles"
mkdir -p "$HOME/repos"

symlink_dotfile() {
  local src="$1" dst="$2" label
  label="$(basename "$dst")"
  if [[ -L "$dst" ]]; then
    ok "$label symlink exists"
  elif [[ -e "$dst" ]]; then
    info "$label exists as a real file — skipping (to fix: ln -sf $src $dst)"
  elif [[ -f "$src" ]]; then
    ln -sf "$src" "$dst"
    ok "$label → dotfiles"
  else
    info "$label not in repo — skipping"
  fi
}

if [[ -d "$DOTFILES/.git" ]]; then
  ok "dotfiles repo already cloned"
else
  info "Cloning dotfiles repo..."
  git clone https://github.com/nealrs/dotfiles "$DOTFILES"
  ok "cloned to $DOTFILES"
fi

symlink_dotfile "$DOTFILES/.zshrc.linux" ~/.zshrc
symlink_dotfile "$DOTFILES/.nanorc" ~/.nanorc

mkdir -p ~/.config
symlink_dotfile "$DOTFILES/starship.toml" ~/.config/starship.toml
mkdir -p ~/.config/ghostty
symlink_dotfile "$DOTFILES/ghostty.linux.config" ~/.config/ghostty/config

if [[ -f "$DOTFILES/gen_ssh_config.sh" ]]; then
  info "Generating ~/.ssh/config from .machines.json..."
  bash "$DOTFILES/gen_ssh_config.sh" && ok "~/.ssh/config generated"
fi

# ============================================================
# SSH TRUST
# ============================================================
section "SSH trust"
if [[ -f "$DOTFILES/print_ssh_trust.sh" ]]; then
  bash "$DOTFILES/print_ssh_trust.sh"
fi

# ============================================================
# CLAUDE CODE SETTINGS
# Last on purpose: op inject depends on the 1Password CLI being installed
# AND signed in, which often isn't true yet on a first run. Everything else
# in this script should succeed regardless of whether this step does.
# ============================================================
section "Claude Code settings"
mkdir -p ~/.claude
if command -v op &>/dev/null; then
  info "Rendering claude settings via 1Password..."
  op inject -i "$DOTFILES/claude_settings.json.tpl" -o ~/.claude/settings.json && ok "~/.claude/settings.json rendered" || info "op inject failed — sign into 1Password and re-run updatedotfiles"
else
  info "1Password CLI not ready — skipping claude settings (run updatedotfiles after signing in)"
fi

# ============================================================
# DONE
# ============================================================
echo -e "\n${GREEN}Bootstrap complete.${NC}\n"
echo "  Next steps:"
if [[ "$OS_FAMILY" == "ostree" ]]; then
  echo "  1. systemctl reboot  (if rpm-ostree installed anything new)"
fi
echo "  2. Log out and back in (or exec \$ZSH_PATH) to switch to zsh"
echo "  3. source ~/.zshrc"
if [[ -f ~/.ssh/id_ed25519 ]]; then
  echo "  4. Add your SSH key to GitHub:"
  echo "     https://github.com/settings/ssh/new"
fi
echo "  5. Run the ssh-copy-id commands above to authorize this machine on the others"
echo ""
