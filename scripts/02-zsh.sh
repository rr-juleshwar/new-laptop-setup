#!/usr/bin/env bash
# 02-zsh.sh — Install ZSH, copy dotfiles, set default shell, bootstrap Zim
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/scripts/00-helpers.sh"

DOTFILES="$REPO_ROOT/dotfiles"

# ── ZSH already installed by 01-system, make it the default shell ─────────────
if [[ "$SHELL" != "$(which zsh)" ]]; then
  log_step "Setting ZSH as default shell"
  chsh -s "$(which zsh)" "$USER"
  log_success "Default shell set to $(which zsh) — takes effect on next login"
else
  log_info "ZSH is already the default shell"
fi

# ── Install dotfiles ───────────────────────────────────────────────────────────
log_step "Installing .zshrc"
cp "$DOTFILES/zshrc" "$HOME/.zshrc"

log_step "Installing .zimrc"
cp "$DOTFILES/zimrc" "$HOME/.zimrc"

log_step "Installing ZSH alias files"
mkdir -p "$HOME/.config/zsh/aliases"
cp "$DOTFILES/zsh-aliases/general.zsh"         "$HOME/.config/zsh/aliases/general.zsh"
cp "$DOTFILES/zsh-aliases/git.zsh"             "$HOME/.config/zsh/aliases/git.zsh"
cp "$DOTFILES/zsh-aliases/ubuntu-wayland.zsh"  "$HOME/.config/zsh/aliases/ubuntu-wayland.zsh"

# ── Zim will self-bootstrap on first interactive ZSH session ──────────────────
# Pre-download zimfw.zsh now so the first shell launch is faster.
ZIM_HOME="$HOME/.zim"
if [[ ! -e "$ZIM_HOME/zimfw.zsh" ]]; then
  log_step "Pre-downloading Zim plugin manager"
  mkdir -p "$ZIM_HOME"
  curl -fsSL --create-dirs -o "$ZIM_HOME/zimfw.zsh" \
    https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  log_success "Zim downloaded — modules will install on first 'zsh' launch"
else
  log_info "Zim already present at $ZIM_HOME"
fi

log_success "ZSH dotfiles installed"
log_info "Run 'exec zsh' after setup completes to activate"
