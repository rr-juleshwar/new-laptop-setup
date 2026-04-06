#!/usr/bin/env bash
# 02-zsh.sh — ZSH + Zim framework + dotfile deployment via GNU Stow

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/scripts/00-helpers.sh"
strict_mode

# ── Install zsh ───────────────────────────────────────────────────────────────
apt_ensure zsh

# ── Set zsh as default shell ──────────────────────────────────────────────────
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
if [[ "$CURRENT_SHELL" != *zsh ]]; then
  log_step "Setting zsh as default shell"
  run_sudo chsh -s "$(which zsh)" "$USER"
  log_success "Default shell changed to zsh"
else
  log_info "zsh is already the default shell"
fi

# ── Deploy dotfiles via GNU Stow ─────────────────────────────────────────────
apt_ensure stow

log_step "Deploying dotfiles via GNU Stow"

# Remove existing files that would conflict with stow symlinks
STOW_TARGETS=(
  "$HOME/.zshrc"
  "$HOME/.zimrc"
  "$HOME/.config/zsh/aliases/general.zsh"
  "$HOME/.config/zsh/aliases/git.zsh"
  "$HOME/.config/zsh/aliases/ubuntu-wayland.zsh"
  "$HOME/.config/ghostty/config"
)

for target in "${STOW_TARGETS[@]}"; do
  if [[ -f "$target" && ! -L "$target" ]]; then
    log_info "  Backing up $target → ${target}.bak"
    mv "$target" "${target}.bak"
  fi
done

# Ensure parent dirs exist (stow won't create intermediate dirs on older versions)
mkdir -p "$HOME/.config/zsh/aliases"
mkdir -p "$HOME/.config/ghostty"

# Stow packages: zsh and ghostty (relative to dotfiles/)
if [[ "$DRY_RUN" == "true" ]]; then
  echo -e "${YELLOW}[DRY-RUN]${NC} stow -d $REPO_ROOT/dotfiles -t $HOME --restow zsh ghostty"
else
  stow -d "$REPO_ROOT/dotfiles" -t "$HOME" --restow zsh ghostty
fi

log_success "Dotfiles deployed via Stow"
log_info "  ~/.zshrc → dotfiles/zsh/.zshrc (symlink)"
log_info "  ~/.zimrc → dotfiles/zsh/.zimrc (symlink)"
log_info "  ~/.config/ghostty/config → dotfiles/ghostty/... (symlink)"

# ── Zim bootstrap note ────────────────────────────────────────────────────────
log_info "Zim will auto-install on first zsh launch (bootstrap block in .zshrc)"
log_info "Run 'zsh' now to trigger Zim module installation"
