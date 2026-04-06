#!/usr/bin/env bash
# 07-workspace.sh — SSH key + ~/Workspace + Rapyuta repos

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/scripts/00-helpers.sh"
strict_mode

# ── SSH key (for GitHub) ──────────────────────────────────────────────────────
SSH_KEY="$HOME/.ssh/id_ed25519"
if [[ ! -f "$SSH_KEY" ]]; then
  log_step "Generating SSH key"
  GIT_EMAIL="${RR_GIT_EMAIL:-}"
  if [[ -z "$GIT_EMAIL" ]]; then
    read -rp "Email for SSH key: " GIT_EMAIL
  fi
  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}[DRY-RUN]${NC} Would generate ed25519 SSH key for $GIT_EMAIL"
  else
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -N "" -f "$SSH_KEY"
    eval "$(ssh-agent -s)"
    ssh-add "$SSH_KEY"
    echo ""
    log_warning "Add this SSH key to GitHub:"
    echo "──────────────────────────────────────────"
    cat "${SSH_KEY}.pub"
    echo "──────────────────────────────────────────"
    echo ""
    if has_cmd gh; then
      log_info "Or run: gh ssh-key add ${SSH_KEY}.pub --title 'ubuntu-laptop'"
    fi
  fi
else
  log_info "SSH key already exists — skipping"
fi

# ── Clone Rapyuta repos ──────────────────────────────────────────────────────
REPOS_FILE="$REPO_ROOT/repos.txt"
WORKSPACE_DIR="$HOME/Workspace"
mkdir -p "$WORKSPACE_DIR"

if [[ ! -f "$REPOS_FILE" ]]; then
  log_warning "repos.txt not found — skipping repo cloning"
  exit 0
fi

if [[ "$UNATTENDED" == "true" ]]; then
  CLONE_REPOS="${CLONE_REPOS:-yes}"
else
  read -rp "Clone Rapyuta repos into ~/Workspace? [Y/n] " CLONE_REPOS
  CLONE_REPOS="${CLONE_REPOS:-yes}"
fi

if [[ "$CLONE_REPOS" =~ ^[Yy]|^$ ]]; then
  CLONED=0 SKIPPED=0 FAILED=0

  while IFS= read -r repo || [[ -n "$repo" ]]; do
    [[ -z "$repo" || "$repo" =~ ^# ]] && continue

    REPO_NAME=$(basename "$repo" .git)
    DEST="$WORKSPACE_DIR/$REPO_NAME"

    if [[ -d "$DEST/.git" ]]; then
      log_info "  $REPO_NAME — already cloned"
      (( SKIPPED++ ))
      continue
    fi

    log_step "  Cloning $REPO_NAME"
    if [[ "$DRY_RUN" == "true" ]]; then
      echo -e "${YELLOW}[DRY-RUN]${NC}   git clone $repo $DEST"
      (( CLONED++ ))
    else
      if git clone "$repo" "$DEST" 2>/dev/null; then
        (( CLONED++ ))
      else
        log_warning "  Failed to clone $REPO_NAME (SSH key not on GitHub yet?)"
        (( FAILED++ ))
      fi
    fi
  done < "$REPOS_FILE"

  log_success "Repos: $CLONED cloned, $SKIPPED skipped, $FAILED failed"
else
  log_info "Repo cloning skipped"
fi
