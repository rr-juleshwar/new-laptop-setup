#!/usr/bin/env bash
# 07-workspace.sh — Workspace directory, SSH key, Rapyuta repo cloning
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/scripts/00-helpers.sh"

WORKSPACE="$HOME/Workspace"

# ── Create Workspace directory ────────────────────────────────────────────────
log_step "Creating ~/Workspace"
mkdir -p "$WORKSPACE"

# ── SSH key ───────────────────────────────────────────────────────────────────
SSH_KEY="$HOME/.ssh/id_ed25519"
if [[ ! -f "$SSH_KEY" ]]; then
  GIT_EMAIL="${RR_GIT_EMAIL:-}"
  if [[ -z "$GIT_EMAIL" ]]; then
    read -rp "Email for SSH key: " GIT_EMAIL
  fi
  log_step "Generating SSH key (ed25519)"
  ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY" -N ""
  eval "$(ssh-agent -s)"
  ssh-add "$SSH_KEY"
  log_success "SSH key generated: $SSH_KEY"
  echo ""
  log_info "Add this public key to GitHub → https://github.com/settings/keys"
  echo ""
  cat "${SSH_KEY}.pub"
  echo ""
else
  log_info "SSH key already exists at $SSH_KEY"
fi

# ── Show Rapyuta repos to clone ───────────────────────────────────────────────
REPOS_FILE="$REPO_ROOT/repos.txt"

log_header "Rapyuta Repos"
if [[ ! -f "$REPOS_FILE" ]]; then
  log_warning "repos.txt not found at $REPOS_FILE"
else
  echo ""
  cat "$REPOS_FILE"
  echo ""
fi

# ── Optional auto-clone ───────────────────────────────────────────────────────
read -rp "Auto-clone all repos into ~/Workspace? Requires SSH key on GitHub [y/N]: " DO_CLONE
if [[ "${DO_CLONE,,}" == "y" ]]; then
  if [[ ! -f "$REPOS_FILE" ]]; then
    log_error "Cannot clone — repos.txt missing"
    exit 1
  fi

  log_step "Cloning repos into $WORKSPACE"
  while IFS= read -r repo || [[ -n "$repo" ]]; do
    [[ -z "$repo" || "$repo" =~ ^# ]] && continue  # skip blank/comment lines

    # Parse "org/repo-name" format
    repo_name="${repo##*/}"
    target="$WORKSPACE/$repo_name"

    if [[ -d "$target/.git" ]]; then
      log_info "  $repo_name — already cloned, skipping"
    else
      log_step "  Cloning $repo → $target"
      git clone "git@github.com:${repo}.git" "$target" && \
        log_success "  Cloned $repo_name" || \
        log_warning "  Failed to clone $repo — add SSH key to GitHub and retry"
    fi
  done < "$REPOS_FILE"
  log_success "Workspace setup complete"
else
  log_info "Skipped auto-clone. Run manually:"
  log_step "  cd ~/Workspace && gh repo clone rapyuta-robotics/<repo>"
fi
