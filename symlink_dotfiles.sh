#!/usr/bin/env bash
# Creates (or repairs) every dotfile symlink for this OS. Sourced by
# mac_bootstrap.sh, linux_bootstrap.sh, and updatedots — expects $DOTFILES
# and the info/ok helpers to already be defined by the caller.

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

if [[ "$(uname -s)" == "Darwin" ]]; then
  symlink_dotfile "$DOTFILES/.zshrc.mac" ~/.zshrc
  symlink_dotfile "$DOTFILES/.nanorc.mac" ~/.nanorc
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

  mkdir -p ~/.config/atuin
  symlink_dotfile "$DOTFILES/atuin.toml" ~/.config/atuin/config.toml
else
  symlink_dotfile "$DOTFILES/.zshrc.linux" ~/.zshrc
  symlink_dotfile "$DOTFILES/.nanorc.linux" ~/.nanorc

  mkdir -p ~/.config
  symlink_dotfile "$DOTFILES/starship.toml" ~/.config/starship.toml

  # Defaults to 0 (attempt the symlink) when sourced outside bootstrap, e.g.
  # from updatedots, where nothing prompts for/sets this. Harmless on a
  # headless box either way — it's an unused config file, not a package.
  : "${HEADLESS:=0}"
  if [[ "$HEADLESS" == "1" ]]; then
    info "Headless — skipping ghostty.linux.config, no terminal emulator to configure."
  else
    mkdir -p ~/.config/ghostty
    symlink_dotfile "$DOTFILES/ghostty.linux.config" ~/.config/ghostty/config
  fi

  mkdir -p ~/.config/atuin
  symlink_dotfile "$DOTFILES/atuin.toml" ~/.config/atuin/config.toml
fi
