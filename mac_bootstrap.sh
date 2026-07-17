#!/bin/bash
# bootstrap.sh — sets up a new Mac with everything needed for .zshrc
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
# XCODE CLI TOOLS
# ============================================================
section "Xcode CLI Tools"
if xcode-select -p &>/dev/null; then
  ok "already installed"
else
  info "Installing Xcode CLI Tools (follow the prompt)..."
  xcode-select --install
  until xcode-select -p &>/dev/null; do sleep 5; done
  ok "installed"
fi

# ============================================================
# CORE TOOLS (curl, jq)
# curl ships with macOS by default and is needed below to install Homebrew
# itself, so this is just a sanity check, not an install step.
# ============================================================
section "Core tools"
if command -v curl &>/dev/null; then
  ok "curl"
else
  info "curl not found — unexpected on macOS. Install it manually before re-running this script."
fi

# ============================================================
# HOMEBREW
# ============================================================
section "Homebrew"
if command -v brew &>/dev/null; then
  ok "already installed"
else
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ok "installed"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

# ============================================================
# BREW PACKAGES
# ============================================================
section "Brew packages"

PACKAGES=(
  git
  gh
  ruby
  nano
  uv
  eza
  bat
  btop
  fd
  ripgrep
  jq
  direnv
  zsh-autosuggestions
  zsh-syntax-highlighting
  fzf
  powerlevel10k
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

# uv-managed Python (avoids relying on system Python)
if uv python list 2>/dev/null | grep -q "3.13"; then
  ok "Python 3.13 already installed via uv"
else
  info "Installing Python 3.13 via uv..."
  uv python install 3.13 && ok "Python 3.13 installed"
fi

# fzf key bindings (Ctrl+R / Ctrl+T / Alt+C)
if [[ ! -f ~/.fzf.zsh ]]; then
  info "Configuring fzf key bindings..."
  "$(brew --prefix)/opt/fzf/install" --all --no-bash --no-fish --no-update-rc
  ok "fzf key bindings written to ~/.fzf.zsh"
else
  ok "fzf key bindings (~/.fzf.zsh)"
fi

# ============================================================
# TAPS
# ============================================================
section "Homebrew taps"
brew tap deskflow/tap 2>/dev/null && ok "deskflow/tap"

# ============================================================
# APPLICATIONS (CASKS)
# ============================================================
section "Applications"

CASKS=(
  docker
  betterdisplay
  home-assistant
  deskflow
  1password
  slack
  ghostty
  firefox
  tableplus
  cleanshot
  devutils
  localsend
  music-decoy
  netnewswire
  steermouse
  sonos
  zoom
  claude
  claude-code
)

for cask in "${CASKS[@]}"; do
  if brew list --cask "$cask" &>/dev/null 2>&1; then
    ok "$cask"
  else
    info "Installing $cask..."
    brew install --cask "$cask" && ok "$cask"
  fi
done

# ============================================================
# MAC APP STORE
# ============================================================
section "Mac App Store"

if ! brew list mas &>/dev/null; then
  info "Installing mas..."
  brew install mas && ok "mas"
else
  ok "mas"
fi

mas_install() {
  local id="$1" name="$2"
  if mas list 2>/dev/null | grep -q "^${id} "; then
    ok "$name"
  else
    info "Installing $name (MAS ${id})..."
    mas install "$id" && ok "$name" || info "$name — sign into App Store first if this fails"
  fi
}

mas_install 441258766 "Magnet"
mas_install 1475387142 "Tailscale"

# ============================================================
# NVM
# ============================================================
section "NVM"
if [[ -d "$HOME/.nvm" ]]; then
  ok "already installed"
else
  info "Installing NVM (latest)..."
  LATEST_NVM=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
  curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${LATEST_NVM}/install.sh" | bash
  ok "installed ($LATEST_NVM)"
fi

export NVM_DIR="$HOME/.nvm"
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
  info "Installing pnpm via nvm-managed npm..."
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

if [[ -f ~/.ssh/id_rsa ]]; then
  ok "RSA key exists"
else
  info "No RSA key found (optional, skip if you only use ED25519)."
  read -p "   Generate one now? (y/n) " -n 1 -r; echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    ssh-keygen -t rsa -b 4096 -C "$EMAIL"
    ok "Generated ~/.ssh/id_rsa"
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

symlink_dotfile "$DOTFILES/.zshrc.mac" ~/.zshrc
symlink_dotfile "$DOTFILES/.nanorc" ~/.nanorc
mkdir -p "$HOME/Library/Application Support/com.mitchellh.ghostty"
symlink_dotfile "$DOTFILES/ghostty.mac.config" "$HOME/Library/Application Support/com.mitchellh.ghostty/config"

if [[ -L ~/.p10k.zsh ]]; then
  ok ".p10k.zsh symlink exists"
elif [[ -f "$DOTFILES/.p10k.zsh" ]]; then
  ln -sf "$DOTFILES/.p10k.zsh" ~/.p10k.zsh
  ok ".p10k.zsh → dotfiles"
else
  info ".p10k.zsh not in repo yet — run 'p10k configure' then commit $DOTFILES/.p10k.zsh"
fi

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
echo "  1. Launch Docker Desktop to finish its setup"
echo "  2. source ~/.zshrc"
echo "  3. p10k configure   (first time only — config saves to dotfiles repo)"
if [[ -f ~/.ssh/id_ed25519 ]]; then
  echo "  4. Add your SSH key to GitHub:"
  echo "     https://github.com/settings/ssh/new"
fi
echo "  5. Run the ssh-copy-id commands above to authorize this machine on the others"
echo ""
