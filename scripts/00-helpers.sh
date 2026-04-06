#!/usr/bin/env bash
# 00-helpers.sh — Shared utilities: logging, checks, config prompts, guards
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

# ── Strict mode ───────────────────────────────────────────────────────────────
# Call this at the top of every phase script after sourcing helpers.
strict_mode() {
  set -Eeuo pipefail
  trap '_err_handler $LINENO "${BASH_SOURCE[0]:-unknown}" "${FUNCNAME[0]:-main}" "$?"' ERR
}

_err_handler() {
  local line="$1" source="$2" func="$3" code="$4"
  log_error "Command failed (exit $code) at line $line in $(basename "$source") [$func]"
}

# ── Dry-run support ───────────────────────────────────────────────────────────
# DRY_RUN is exported by setup.sh when --dry-run is passed.
: "${DRY_RUN:=false}"

# Execute a command, or print it if DRY_RUN is set.
run() {
  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}[DRY-RUN]${NC} $*"
    return 0
  fi
  "$@"
}

# Execute a command with sudo, or print it if DRY_RUN is set.
run_sudo() {
  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}[DRY-RUN]${NC} sudo $*"
    return 0
  fi
  sudo "$@"
}

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
  [[ "$DRY_RUN" == "true" ]] && echo -e "  ${YELLOW}⚠  DRY-RUN MODE — no changes will be made${NC}"
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
  if [[ "$major" -lt 20 ]] || { [[ "$major" -eq 20 ]] && [[ "${minor#0}" -lt 4 ]]; }; then
    log_error "Ubuntu 20.04+ required (found: $version)"
    exit 1
  fi

  export UBUNTU_VERSION="$version"
  export UBUNTU_CODENAME
  UBUNTU_CODENAME=$(lsb_release -cs)
  log_info "Ubuntu $version ($UBUNTU_CODENAME) — OK"
}

# ── Unattended / .env support ─────────────────────────────────────────────────
# UNATTENDED is exported by setup.sh when --unattended is passed.
: "${UNATTENDED:=false}"

# Load variables from .env file if it exists (key=value, no export keyword).
load_env_file() {
  local env_file="${1:-.env}"
  if [[ -f "$env_file" ]]; then
    log_info "Loading configuration from $env_file"
    while IFS='=' read -r key value; do
      # Skip blank lines and comments
      [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
      # Trim whitespace
      key=$(echo "$key" | xargs)
      value=$(echo "$value" | xargs)
      # Remove surrounding quotes from value
      value="${value%\"}"
      value="${value#\"}"
      value="${value%\'}"
      value="${value#\'}"
      export "$key=$value"
    done < "$env_file"
  fi
}

# ── Config prompts ────────────────────────────────────────────────────────────
# Gathered once by setup.sh; exported so child scripts inherit them.
prompt_setup_config() {
  log_header "Setup Configuration"

  if [[ "$UNATTENDED" == "true" ]]; then
    # In unattended mode, require env vars (from .env or environment)
    RR_GIT_NAME="${RR_GIT_NAME:-}"
    RR_GIT_EMAIL="${RR_GIT_EMAIL:-}"
    RR_QUAY_USER="${RR_QUAY_USER:-}"
    RR_QUAY_PASS="${RR_QUAY_PASS:-}"

    if [[ -z "$RR_GIT_NAME" || -z "$RR_GIT_EMAIL" ]]; then
      log_error "Unattended mode requires RR_GIT_NAME and RR_GIT_EMAIL"
      log_info "Set them via environment or a .env file"
      exit 1
    fi

    log_success "Using configuration from environment:"
  else
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
  fi

  export RR_GIT_NAME RR_GIT_EMAIL RR_QUAY_USER RR_QUAY_PASS

  echo ""
  log_success "Configuration:"
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

  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY-RUN] Would execute: $script"
    # Still source/run so the script can print its dry-run output
  fi

  bash "$script"
  log_success "$phase_name complete"
}

# ── Idempotency helpers ───────────────────────────────────────────────────────

# Returns 0 (true) if the package is already installed
apt_installed() { dpkg -s "$1" &>/dev/null; }

# Returns 0 if command exists in PATH
has_cmd() { command -v "$1" &>/dev/null; }

# Install apt packages only if not already installed. Accepts a list.
apt_ensure() {
  local to_install=()
  for pkg in "$@"; do
    if ! apt_installed "$pkg"; then
      to_install+=("$pkg")
    fi
  done
  if [[ ${#to_install[@]} -gt 0 ]]; then
    log_step "Installing: ${to_install[*]}"
    run_sudo apt-get install -y "${to_install[@]}"
  else
    log_info "All packages already installed: $*"
  fi
}

# Copy a file only if the destination is missing or differs.
copy_if_changed() {
  local src="$1" dest="$2"
  if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then
    log_info "  $(basename "$dest") — already up to date"
    return 0
  fi
  local dest_dir
  dest_dir=$(dirname "$dest")
  [[ -d "$dest_dir" ]] || mkdir -p "$dest_dir"
  run cp "$src" "$dest"
  log_step "  Installed $(basename "$dest")"
}

# Adds an apt source list + key, idempotently
add_apt_source() {
  local name="$1"      # e.g. "vscode"
  local keyring="$2"   # full path for the .gpg keyring
  local key_url="$3"   # URL to fetch the signing key
  local repo_line="$4" # deb [...] line to write

  if [[ ! -f "$keyring" ]]; then
    log_step "Adding signing key → $keyring"
    run_sudo mkdir -p "$(dirname "$keyring")"
    if [[ "$DRY_RUN" == "true" ]]; then
      echo -e "${YELLOW}[DRY-RUN]${NC} curl ... | gpg --dearmor > $keyring"
    else
      curl -fsSL "$key_url" | gpg --dearmor | sudo tee "$keyring" > /dev/null
      sudo chmod 644 "$keyring"
    fi
  fi

  local list_file="/etc/apt/sources.list.d/${name}.list"
  if [[ ! -f "$list_file" ]]; then
    log_step "Adding APT source → $list_file"
    if [[ "$DRY_RUN" == "true" ]]; then
      echo -e "${YELLOW}[DRY-RUN]${NC} echo '...' > $list_file"
    else
      echo "$repo_line" | sudo tee "$list_file" > /dev/null
    fi
  fi
}

# Check if a PPA is already added
has_ppa() {
  local ppa="$1"
  grep -rqh "^deb.*${ppa}" /etc/apt/sources.list.d/ 2>/dev/null
}

# Add a PPA only if not already present
add_ppa() {
  local ppa="$1"
  if has_ppa "$ppa"; then
    log_info "PPA $ppa already added — skipping"
  else
    log_step "Adding PPA: $ppa"
    run_sudo add-apt-repository -y "ppa:$ppa"
  fi
}
