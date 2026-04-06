#!/usr/bin/env bash
# 01-system.sh — System packages and essentials
# Installs: build tools, curl, git-core PPA, fonts, wl-clipboard, eza, zoxide, bat, fd, fzf, ripgrep, jq, etc.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/scripts/00-helpers.sh"

# ── apt update ────────────────────────────────────────────────────────────────
log_step "Updating package lists"
sudo apt-get update -qq

# ── Core utilities ────────────────────────────────────────────────────────────
log_step "Installing core utilities"
sudo apt-get install -y \
  curl wget git build-essential apt-transport-https \
  ca-certificates gnupg software-properties-common \
  lsb-release unzip zip \
  zsh \
  wl-clipboard xclip \
  fonts-powerline fontconfig \
  zoxide bat fd-find fzf ripgrep jq \
  xdg-utils

# ── eza (modern ls replacement) ───────────────────────────────────────────────
# eza is not in Ubuntu 20.04/22.04 apt repos — install from their official deb
if ! has_cmd eza; then
  log_step "Installing eza"
  EZA_VER=$(curl -fsSL "https://api.github.com/repos/eza-community/eza/releases/latest" | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
  EZA_URL="https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz"
  curl -fsSL "$EZA_URL" -o /tmp/eza.tar.gz
  sudo tar xzf /tmp/eza.tar.gz -C /usr/local/bin eza
  rm -f /tmp/eza.tar.gz
  log_success "eza $EZA_VER installed"
else
  log_info "eza already installed — skipping"
fi

# ── bat symlink (Ubuntu ships it as 'batcat') ─────────────────────────────────
if has_cmd batcat && ! has_cmd bat; then
  log_step "Creating 'bat' symlink → batcat"
  mkdir -p ~/.local/bin
  ln -sf "$(which batcat)" ~/.local/bin/bat
fi

# ── fd symlink (Ubuntu ships it as 'fdfind') ─────────────────────────────────
if has_cmd fdfind && ! has_cmd fd; then
  log_step "Creating 'fd' symlink → fdfind"
  mkdir -p ~/.local/bin
  ln -sf "$(which fdfind)" ~/.local/bin/fd
fi

# ── Nerd Font (required for agnoster prompt) ──────────────────────────────────
FONT_DIR="$HOME/.local/share/fonts"
if ! fc-list | grep -qi "MesloLGS"; then
  log_step "Installing MesloLGS NF (Powerline / Nerd Font)"
  mkdir -p "$FONT_DIR"
  BASE_URL="https://github.com/romkatv/powerlevel10k-media/raw/master"
  for font in \
    "MesloLGS NF Regular.ttf" \
    "MesloLGS NF Bold.ttf" \
    "MesloLGS NF Italic.ttf" \
    "MesloLGS NF Bold Italic.ttf"; do
    curl -fsSL "$BASE_URL/${font// /%20}" -o "$FONT_DIR/$font"
  done
  fc-cache -f "$FONT_DIR"
  log_success "MesloLGS NF installed — set it as your terminal font"
else
  log_info "MesloLGS NF already installed — skipping"
fi

# ── keyd (keyboard remapping — Super→Ctrl for clipboard) ─────────────────────
# The Ghostty config relies on keyd for Super+C/V/X clipboard shortcuts.
if ! has_cmd keyd; then
  log_step "Installing keyd"
  sudo apt-get install -y keyd 2>/dev/null || {
    # keyd is not in older Ubuntu repos — build from source
    log_warning "keyd not in apt — installing from source"
    sudo apt-get install -y libsystemd-dev
    KEYD_TMP=$(mktemp -d)
    git clone --depth=1 https://github.com/rvaiya/keyd.git "$KEYD_TMP"
    make -C "$KEYD_TMP"
    sudo make -C "$KEYD_TMP" install
    rm -rf "$KEYD_TMP"
  }
  sudo systemctl enable --now keyd
  log_step "Writing keyd config (Super+C/X/V → Ctrl+C/X/V)"
  sudo mkdir -p /etc/keyd
  if [[ ! -f /etc/keyd/default.conf ]]; then
    sudo tee /etc/keyd/default.conf > /dev/null <<'EOF'
[ids]
*

[main]
# Remap CapsLock to Escape
capslock = esc

# Remap Super+C/X/V to Ctrl+C/X/V (clipboard shortcuts)
meta.c = C-c
meta.x = C-x
meta.v = C-v
EOF
    sudo systemctl restart keyd
  fi
  log_success "keyd installed and configured"
else
  log_info "keyd already installed — skipping"
fi

log_success "System packages installed"
