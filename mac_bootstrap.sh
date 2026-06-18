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
  ruby
  uv
  zsh-autosuggestions
  zsh-syntax-highlighting
  fzf
  powerlevel10k
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
# DOCKER DESKTOP
# ============================================================
section "Docker Desktop"
if command -v docker &>/dev/null; then
  ok "already installed"
else
  info "Installing Docker Desktop..."
  brew install --cask docker
  ok "installed — launch Docker.app once to complete setup"
fi

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
# DOTFILES
# ============================================================
section "Dotfiles"

if [[ ! -f ~/.motivation.md ]]; then
  info "Fetching .motivation.md from dotfiles repo..."
  curl -fsSo ~/.motivation.md https://raw.githubusercontent.com/nealrs/dotfiles/master/.motivation.md
  ok ".motivation.md fetched"
else
  ok ".motivation.md exists"
fi

if [[ ! -f ~/.zshrc ]]; then
  info "Fetching .zshrc from dotfiles repo..."
  curl -fsSo ~/.zshrc https://raw.githubusercontent.com/nealrs/dotfiles/master/.zshrc
  ok ".zshrc fetched"
else
  ok ".zshrc exists (not overwriting)"
fi

# ============================================================
# DONE
# ============================================================
echo -e "\n${GREEN}Bootstrap complete.${NC}\n"
echo "  Next steps:"
echo "  1. Launch Docker Desktop to finish its setup"
echo "  2. source ~/.zshrc"
echo "  3. p10k configure   (sets up your prompt — first time only)"
if [[ -f ~/.ssh/id_ed25519 ]]; then
  echo "  4. Add your SSH key to GitHub:"
  echo "     https://github.com/settings/ssh/new"
fi
echo ""
