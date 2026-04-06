#!/usr/bin/env bash
# 00-helpers.sh — Shared utilities: logging, checks, config prompts
# Source this file; do not execute directly.

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_success() { echo -e "${GREEN}[✓]${NC}    $*"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_step()    { echo -e "${CYAN}  →${NC} $*"; }
log_header()  { echo -e "\n${BOLD}${CYAN}━━━ $* ━━━${NC}\n"; }

print_banner() {
  echo -e "${BOLD}${CYAN}"
  echo "  ██████╗  █████╗ ██████╗ ██╗   ██╗██╗   ██╗████████╗ █████╗ "
  echo "  ██╔══██╗██╔══██╗██╔══██╗╚██╗ ██╔╝██║   ██║╚══██╔══╝██╔══██╗"
  echo "  ██████╔╝███████║██████╔╝ ╚████╔╝ ██║   ██║   ██║   ███████║"
  echo "  ██╔══██╗██╔══██║██╔═══╝   ╚██╔╝  ██║   ██║   ██║   ██╔══██║"
  echo "  ██║  ██║██║  ██║██║        ██║   ╚██████╔╝   ██║   ██║  ██║"
  echo "  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝        ╚═╝    ╚═════╝    ╚═╝   ╚═╝  ╚═╝"
  echo -e "${NC}"
  echo -e "  ${BOLD}Rapyuta Robotics — Ubuntu Laptop Setup${NC}"
  echo -e "  Compatible with Ubuntu 20.04+"
  echo ""
}

# ── OS check ─────────────────────────────────────────────────────────────────
check_ubuntu_version() {
  if ! command -v lsb_release &>/dev/null; then
    log_error "lsb_release not found. Is this Ubuntu?"
    exit 1
  fi

  local distro version
  distro=$(lsb_release -is)
  version=$(lsb_release -rs)

  if [[ "$distro" != "Ubuntu" ]]; then
    log_error "This script targets Ubuntu (found: $distro)"
    exit 1
  fi

  local major minor
  major="${version%%.*}"
  minor="${version##*.}"
  if [[ $major -lt 20 ]] || [[ $major -eq 20 && ${minor#0} -lt 4 ]]; then
    log_error "Ubuntu 20.04+ required (found: $version)"
    exit 1
  fi

  export UBUNTU_VERSION="$version"
  export UBUNTU_CODENAME
  UBUNTU_CODENAME=$(lsb_release -cs)
  log_info "Ubuntu $version ($UBUNTU_CODENAME) — OK"
}

# ── Config prompts ────────────────────────────────────────────────────────────
# Gathered once by setup.sh; exported so child scripts inherit them.
prompt_setup_config() {
  log_header "Setup Configuration"
  log_info "Press Enter to accept the [default] shown in brackets."
  echo ""

  read -rp "Git user name  [Juleshwar Babu]: " RR_GIT_NAME
  RR_GIT_NAME="${RR_GIT_NAME:-Juleshwar Babu}"

  read -rp "Git user email [juleshwar.babu@rapyuta-robotics.com]: " RR_GIT_EMAIL
  RR_GIT_EMAIL="${RR_GIT_EMAIL:-juleshwar.babu@rapyuta-robotics.com}"

  echo ""
  log_info "quay.io credentials — used for 'docker login quay.io'."
  log_info "Leave username blank to skip Docker registry auth."
  read -rp "quay.io username [skip]: " RR_QUAY_USER
  RR_QUAY_USER="${RR_QUAY_USER:-}"
  if [[ -n "$RR_QUAY_USER" ]]; then
    read -srp "quay.io password / CLI token: " RR_QUAY_PASS
    echo ""
  else
    RR_QUAY_PASS=""
  fi

  export RR_GIT_NAME RR_GIT_EMAIL RR_QUAY_USER RR_QUAY_PASS

  echo ""
  log_success "Configuration captured:"
  log_step "Git:    $RR_GIT_NAME <$RR_GIT_EMAIL>"
  log_step "quay.io: ${RR_QUAY_USER:-[skipped]}"
  echo ""
}

# ── Phase runner ─────────────────────────────────────────────────────────────
run_phase() {
  local phase_id="$1"
  local phase_name="$2"
  local script="$3"

  log_header "$phase_id — $phase_name"

  if [[ ! -f "$script" ]]; then
    log_warning "Script not found: $script — skipping"
    return
  fi

  bash "$script"
  log_success "$phase_name complete"
}

# ── Idempotency helpers ───────────────────────────────────────────────────────
# Returns 0 (true) if the package is already installed
apt_installed() { dpkg -s "$1" &>/dev/null; }

# Returns 0 if command exists in PATH
has_cmd() { command -v "$1" &>/dev/null; }

# Adds an apt source list + key, idempotently
add_apt_source() {
  local name="$1"      # e.g. "vscode"
  local keyring="$2"   # full path for the .gpg keyring
  local key_url="$3"   # URL to fetch the signing key
  local repo_line="$4" # deb [...] line to write

  if [[ ! -f "$keyring" ]]; then
    log_step "Adding signing key → $keyring"
    curl -fsSL "$key_url" | gpg --dearmor | sudo tee "$keyring" > /dev/null
    sudo chmod 644 "$keyring"
  fi

  local list_file="/etc/apt/sources.list.d/${name}.list"
  if [[ ! -f "$list_file" ]]; then
    log_step "Adding APT source → $list_file"
    echo "$repo_line" | sudo tee "$list_file" > /dev/null
  fi
}
