#!/usr/bin/env bash
# 06-devtools.sh — Node.js (via NVM) + optional Bun

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/scripts/00-helpers.sh"
strict_mode

# ── NVM + Node.js LTS ────────────────────────────────────────────────────────
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

if [[ ! -d "$NVM_DIR" ]]; then
  log_step "Installing NVM"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}[DRY-RUN]${NC} Would install NVM"
  else
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
  fi
  log_success "NVM installed"
else
  log_info "NVM already installed — skipping"
fi

# Source NVM for the rest of the script
export NVM_DIR
# shellcheck source=/dev/null
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

if has_cmd nvm 2>/dev/null || type nvm &>/dev/null; then
  if ! has_cmd node; then
    log_step "Installing Node.js LTS via NVM"
    if [[ "$DRY_RUN" != "true" ]]; then
      nvm install --lts
      nvm alias default lts/*
    fi
    log_success "Node.js LTS installed"
  else
    log_info "Node.js already installed — $(node --version)"
  fi
else
  log_warning "NVM not available in current shell — node install skipped"
fi

# ── Bun (optional, fast JS runtime) ──────────────────────────────────────────
if ! has_cmd bun; then
  if [[ "$UNATTENDED" == "true" ]]; then
    INSTALL_BUN="${INSTALL_BUN:-no}"
  else
    read -rp "Install Bun runtime? [y/N] " INSTALL_BUN
  fi
  if [[ "$INSTALL_BUN" =~ ^[Yy] ]]; then
    log_step "Installing Bun"
    if [[ "$DRY_RUN" == "true" ]]; then
      echo -e "${YELLOW}[DRY-RUN]${NC} Would install Bun"
    else
      curl -fsSL https://bun.sh/install | bash
    fi
    log_success "Bun installed"
  fi
else
  log_info "Bun already installed — skipping"
fi
