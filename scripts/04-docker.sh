#!/usr/bin/env bash
# 04-docker.sh — Docker CE + post-install + quay.io registry login

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/scripts/00-helpers.sh"
strict_mode

# ── Install Docker CE ─────────────────────────────────────────────────────────
if ! has_cmd docker; then
  log_step "Installing Docker CE via official install script"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}[DRY-RUN]${NC} curl -fsSL https://get.docker.com | sh"
  else
    curl -fsSL https://get.docker.com | sh
  fi
  log_success "Docker installed"
else
  log_info "Docker already installed — $(docker --version)"
fi

# ── Post-install: add user to docker group ────────────────────────────────────
if ! groups "$USER" | grep -q '\bdocker\b'; then
  log_step "Adding $USER to docker group"
  run_sudo usermod -aG docker "$USER"
  log_warning "Docker group change requires re-login or 'newgrp docker'"
else
  log_info "User $USER is already in docker group"
fi

# ── Enable + start Docker service ─────────────────────────────────────────────
log_step "Enabling Docker service"
run_sudo systemctl enable --now docker

# ── quay.io registry login ────────────────────────────────────────────────────
QUAY_USER="${RR_QUAY_USER:-}"
QUAY_PASS="${RR_QUAY_PASS:-}"

if [[ -z "$QUAY_USER" && "$UNATTENDED" != "true" ]]; then
  read -rp "quay.io username (leave blank to skip): " QUAY_USER
fi

if [[ -n "$QUAY_USER" ]]; then
  if [[ -z "$QUAY_PASS" && "$UNATTENDED" != "true" ]]; then
    read -srp "quay.io password / CLI token: " QUAY_PASS
    echo ""
  fi
  log_step "Logging in to quay.io as $QUAY_USER"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}[DRY-RUN]${NC} docker login quay.io --username $QUAY_USER"
  else
    echo "$QUAY_PASS" | sudo -E docker login quay.io --username "$QUAY_USER" --password-stdin
    # Copy root's docker config to user's config
    sudo mkdir -p "$HOME/.docker"
    if [[ -f /root/.docker/config.json ]]; then
      sudo cp /root/.docker/config.json "$HOME/.docker/config.json"
      sudo chown "$USER:$USER" "$HOME/.docker/config.json"
      sudo chmod 600 "$HOME/.docker/config.json"
    fi
  fi
  log_success "Logged in to quay.io"
else
  log_info "quay.io login skipped — run 'docker login quay.io' manually later"
fi
