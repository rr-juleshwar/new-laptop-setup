#!/usr/bin/env bash
# 03-git.sh — Latest git, configured gitconfig, GitHub CLI
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/scripts/00-helpers.sh"

# ── Latest Git via PPA ────────────────────────────────────────────────────────
log_step "Adding git-core PPA for latest Git"
sudo add-apt-repository -y ppa:git-core/ppa
sudo apt-get update -qq
sudo apt-get install -y git
log_success "Git $(git --version) installed"

# ── Configure gitconfig from template ─────────────────────────────────────────
GIT_NAME="${RR_GIT_NAME:-}"
GIT_EMAIL="${RR_GIT_EMAIL:-}"

if [[ -z "$GIT_NAME" ]]; then
  read -rp "Git user name: " GIT_NAME
fi
if [[ -z "$GIT_EMAIL" ]]; then
  read -rp "Git user email: " GIT_EMAIL
fi

log_step "Writing ~/.gitconfig"
sed \
  -e "s|{{GIT_USER_NAME}}|$GIT_NAME|g" \
  -e "s|{{GIT_USER_EMAIL}}|$GIT_EMAIL|g" \
  "$REPO_ROOT/dotfiles/gitconfig.template" > "$HOME/.gitconfig"

log_success "~/.gitconfig configured for $GIT_NAME <$GIT_EMAIL>"

# ── GitHub CLI ────────────────────────────────────────────────────────────────
if ! has_cmd gh; then
  log_step "Installing GitHub CLI (gh)"
  add_apt_source \
    "github-cli" \
    "/etc/apt/keyrings/githubcli-archive-keyring.gpg" \
    "https://cli.github.com/packages/githubcli-archive-keyring.gpg" \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main"
  sudo apt-get update -qq
  sudo apt-get install -y gh
  log_success "gh $(gh --version | head -1) installed"
else
  log_info "gh already installed — skipping"
fi

log_info "Run 'gh auth login' to authenticate with GitHub"
