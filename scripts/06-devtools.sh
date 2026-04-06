#!/usr/bin/env bash
# 06-devtools.sh — NVM + Node.js LTS, optional Bun
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/scripts/00-helpers.sh"

# ── NVM ───────────────────────────────────────────────────────────────────────
NVM_DIR="$HOME/.nvm"
if [[ ! -d "$NVM_DIR" ]]; then
  log_step "Installing NVM (Node Version Manager)"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
  log_success "NVM installed"
else
  log_info "NVM already installed at $NVM_DIR"
fi

# Load NVM in current session so we can install Node
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

# ── Node.js LTS ───────────────────────────────────────────────────────────────
if has_cmd nvm; then
  log_step "Installing Node.js LTS"
  nvm install --lts
  nvm use --lts
  nvm alias default 'lts/*'
  log_success "Node.js $(node --version) / npm $(npm --version) installed"
else
  log_warning "NVM not in PATH in this shell — Node.js will be installed on first 'zsh' launch"
fi

# ── Bun (optional) ────────────────────────────────────────────────────────────
if ! has_cmd bun; then
  read -rp "Install Bun (fast JS runtime/bundler)? [y/N]: " INSTALL_BUN
  if [[ "${INSTALL_BUN,,}" == "y" ]]; then
    log_step "Installing Bun"
    curl -fsSL https://bun.sh/install | bash
    log_success "Bun installed — restart shell or run: source ~/.bashrc"
  else
    log_info "Bun install skipped"
  fi
else
  log_info "Bun already installed — skipping"
fi
