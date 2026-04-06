#!/usr/bin/env bash
# 01-system.sh — System packages and essentials
# Installs: build tools, curl, fonts, wl-clipboard, eza, zoxide, bat, fd, fzf, ripgrep, jq, stow, etc.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/scripts/00-helpers.sh"
strict_mode

# ── Pinned versions (override with --latest logic in future) ──────────────────
EZA_VERSION="${EZA_VERSION:-0.21.2}"

# ── apt update ────────────────────────────────────────────────────────────────
log_step "Updating package lists"
run_sudo apt-get update -qq

# ── Core utilities (idempotent — apt_ensure skips installed pkgs) ─────────────
log_step "Installing core utilities"
apt_ensure \
  curl wget git build-essential apt-transport-https \
  ca-certificates gnupg software-properties-common \
  lsb-release unzip zip \
  zsh stow \
  wl-clipboard xclip \
  fonts-powerline fontconfig \
  zoxide bat fd-find fzf ripgrep jq \
  xdg-utils

# ── eza (modern ls replacement) ───────────────────────────────────────────────
if ! has_cmd eza; then
  log_step "Installing eza v${EZA_VERSION}"
  EZA_URL="https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_x86_64-unknown-linux-gnu.tar.gz"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}[DRY-RUN]${NC} Download + install eza $EZA_VERSION"
  else
    curl -fsSL "$EZA_URL" -o /tmp/eza.tar.gz
    sudo tar xzf /tmp/eza.tar.gz -C /usr/local/bin eza
    rm -f /tmp/eza.tar.gz
  fi
  log_success "eza ${EZA_VERSION} installed"
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
if ! fc-list 2>/dev/null | grep -qi "MesloLGS"; then
  log_step "Installing MesloLGS NF (Powerline / Nerd Font)"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}[DRY-RUN]${NC} Would download 4 MesloLGS NF font files"
  else
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
  fi
  log_success "MesloLGS NF installed — set it as your terminal font"
else
  log_info "MesloLGS NF already installed — skipping"
fi

# ── keyd (keyboard remapping — Super→Ctrl for clipboard) ─────────────────────
if ! has_cmd keyd; then
  log_step "Installing keyd"
  run_sudo apt-get install -y keyd 2>/dev/null || {
    log_warning "keyd not in apt — installing from source"
    if [[ "$DRY_RUN" == "true" ]]; then
      echo -e "${YELLOW}[DRY-RUN]${NC} Would build keyd from source"
    else
      apt_ensure libsystemd-dev
      KEYD_TMP=$(mktemp -d)
      git clone --depth=1 https://github.com/rvaiya/keyd.git "$KEYD_TMP"
      make -C "$KEYD_TMP"
      sudo make -C "$KEYD_TMP" install
      rm -rf "$KEYD_TMP"
    fi
  }
  run_sudo systemctl enable --now keyd

  if [[ ! -f /etc/keyd/default.conf ]]; then
    log_step "Writing keyd config"
    run_sudo mkdir -p /etc/keyd
    if [[ "$DRY_RUN" != "true" ]]; then
      sudo tee /etc/keyd/default.conf > /dev/null <<'KEYDEOF'
[ids]
*

[main]
capslock = esc
meta.c = C-c
meta.x = C-x
meta.v = C-v
KEYDEOF
      sudo systemctl restart keyd
    fi
  fi
  log_success "keyd installed and configured"
else
  log_info "keyd already installed — skipping"
fi

log_success "System packages installed"
