#!/usr/bin/env bash
# 05-apps.sh — Desktop apps: VSCode, Firefox, Slack, Ghostty

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/scripts/00-helpers.sh"
strict_mode

# ── Pinned versions ───────────────────────────────────────────────────────────
SLACK_VERSION="${SLACK_VERSION:-4.43.51}"

# ── VSCode (Microsoft apt repo, NOT snap) ─────────────────────────────────────
if ! has_cmd code; then
  log_step "Installing Visual Studio Code"
  add_apt_source \
    "vscode" \
    "/etc/apt/keyrings/packages.microsoft.gpg" \
    "https://packages.microsoft.com/keys/microsoft.asc" \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main"
  run_sudo apt-get update -qq
  apt_ensure code
  log_success "VSCode installed"
else
  log_info "VSCode already installed — skipping"
fi

# ── VSCode extensions ─────────────────────────────────────────────────────────
log_step "Installing VSCode extensions"
EXTENSIONS=(
  cweijan.dbclient-jdbc
  cweijan.vscode-database-client2
  diemasmichiels.emulate
  donjayamanne.githistory
  eamodio.gitlens
  esbenp.prettier-vscode
  formulahendry.code-runner
  github.copilot-chat
  github.vscode-pull-request-github
  mechatroner.rainbow-csv
  ms-azuretools.vscode-containers
  ms-playwright.playwright
  ms-python.debugpy
  ms-python.python
  ms-python.vscode-pylance
  ms-python.vscode-python-envs
  streetsidesoftware.code-spell-checker
)

for ext in "${EXTENSIONS[@]}"; do
  if code --list-extensions 2>/dev/null | grep -qi "^${ext}$"; then
    log_info "  $ext — already installed"
  else
    run code --install-extension "$ext" --force 2>/dev/null && \
      log_step "  Installed: $ext" || \
      log_warning "  Failed to install: $ext"
  fi
done
log_success "VSCode extensions configured"

# ── Firefox (Mozilla PPA — removes snap, works across all versions) ───────────
if ! has_cmd firefox || snap list firefox &>/dev/null 2>&1; then
  log_step "Installing Firefox via Mozilla PPA"
  # Remove snap firefox if present
  if snap list firefox &>/dev/null 2>&1; then
    log_step "Removing snap firefox"
    run_sudo snap remove firefox
  fi
  add_ppa "mozillateam/ppa"
  # Ensure Mozilla PPA takes priority over snap
  if [[ ! -f /etc/apt/preferences.d/mozilla-firefox ]]; then
    if [[ "$DRY_RUN" != "true" ]]; then
      echo 'Package: firefox*
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001' | sudo tee /etc/apt/preferences.d/mozilla-firefox > /dev/null
    fi
  fi
  run_sudo apt-get update -qq
  apt_ensure firefox
  log_success "Firefox installed"
else
  log_info "Firefox already installed — skipping"
fi

# ── Slack (official .deb download, pinned version) ────────────────────────────
if ! has_cmd slack; then
  log_step "Downloading and installing Slack $SLACK_VERSION"
  SLACK_URL="https://downloads.slack-edge.com/releases/linux/${SLACK_VERSION}/prod/x64/slack-desktop-${SLACK_VERSION}-amd64.deb"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}[DRY-RUN]${NC} Would download Slack from $SLACK_URL"
  else
    curl -fsSL "$SLACK_URL" -o /tmp/slack.deb
    sudo apt-get install -y /tmp/slack.deb
    rm -f /tmp/slack.deb
  fi
  log_success "Slack installed"
else
  log_info "Slack already installed — skipping"
fi

# ── Ghostty terminal ──────────────────────────────────────────────────────────
install_ghostty_apt() {
  log_step "Adding ghostty apt repo"
  add_apt_source \
    "ghostty" \
    "/etc/apt/keyrings/ghostty-keyring.gpg" \
    "https://apt.ghostty.org/gpg.key" \
    "deb [signed-by=/etc/apt/keyrings/ghostty-keyring.gpg] https://apt.ghostty.org/ any main"
  run_sudo apt-get update -qq
  apt_ensure ghostty
}

install_ghostty_flatpak() {
  log_step "Installing Ghostty via Flatpak (Ubuntu 20.04 fallback)"
  if ! has_cmd flatpak; then
    apt_ensure flatpak
    run_sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  fi
  run_sudo flatpak install -y flathub com.mitchellh.ghostty
  log_warning "Ghostty installed via Flatpak. Launch with: flatpak run com.mitchellh.ghostty"
}

if ! has_cmd ghostty; then
  MAJOR="${UBUNTU_VERSION%%.*}"
  if [[ "$MAJOR" -ge 22 ]]; then
    install_ghostty_apt && log_success "Ghostty installed" || {
      log_warning "Ghostty apt install failed — trying Flatpak"
      install_ghostty_flatpak
    }
  else
    log_warning "Ubuntu 20.04: using Flatpak for Ghostty"
    install_ghostty_flatpak
  fi
else
  log_info "Ghostty already installed — skipping"
fi

# ── Ghostty config (deployed via stow in 02-zsh.sh, just ensure dir exists) ──
mkdir -p "$HOME/.config/ghostty"
