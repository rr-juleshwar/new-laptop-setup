#!/usr/bin/env bash
# setup.sh — Rapyuta Robotics Ubuntu Laptop Setup (orchestrator)
# Usage: sudo -E bash setup.sh [options]
# Options:
#   --phase=N       Run only phase N (e.g. --phase=3)
#   --skip=N[,M]    Skip phase(s) (e.g. --skip=4,6)
#   --dry-run       Print what would happen without making changes
#   --unattended    Non-interactive mode; reads from .env or environment
#   --list          Show available phases and exit
#   --help          Show this help and exit

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export RR_SCRIPT_DIR="$SCRIPT_DIR"

# ── Parse arguments ───────────────────────────────────────────────────────────
PHASE_ONLY=""
SKIP_PHASES=""
export DRY_RUN="false"
export UNATTENDED="false"
SHOW_LIST=false

for arg in "$@"; do
  case "$arg" in
    --phase=*) PHASE_ONLY="${arg#*=}" ;;
    --skip=*)  SKIP_PHASES="${arg#*=}" ;;
    --dry-run) DRY_RUN="true" ;;
    --unattended) UNATTENDED="true" ;;
    --list) SHOW_LIST=true ;;
    --help|-h)
      head -10 "$0" | grep '^#' | sed 's/^# //'
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg (try --help)"
      exit 1
      ;;
  esac
done

# ── Source helpers ─────────────────────────────────────────────────────────────
source "$SCRIPT_DIR/scripts/00-helpers.sh"

# ── Phase definitions ─────────────────────────────────────────────────────────
ALL_PHASES=(
  "01:System Packages:$SCRIPT_DIR/scripts/01-system.sh"
  "02:ZSH & Dotfiles:$SCRIPT_DIR/scripts/02-zsh.sh"
  "03:Git & GitHub CLI:$SCRIPT_DIR/scripts/03-git.sh"
  "04:Docker & Registry:$SCRIPT_DIR/scripts/04-docker.sh"
  "05:Desktop Apps:$SCRIPT_DIR/scripts/05-apps.sh"
  "06:Dev Tools (NVM/Node):$SCRIPT_DIR/scripts/06-devtools.sh"
  "07:Workspace & Repos:$SCRIPT_DIR/scripts/07-workspace.sh"
  "08:Post-Install Verify:$SCRIPT_DIR/scripts/08-verify.sh"
)

# ── --list ────────────────────────────────────────────────────────────────────
if $SHOW_LIST; then
  echo "Available phases:"
  for phase_entry in "${ALL_PHASES[@]}"; do
    IFS=':' read -r id name _ <<< "$phase_entry"
    echo "  $id  $name"
  done
  exit 0
fi

# ── Build skip set ────────────────────────────────────────────────────────────
declare -A SKIP_SET
if [[ -n "$SKIP_PHASES" ]]; then
  IFS=',' read -ra parts <<< "$SKIP_PHASES"
  for p in "${parts[@]}"; do
    # Zero-pad to 2 digits for matching
    SKIP_SET[$(printf "%02d" "$p")]=1
  done
fi

# ── Banner + pre-checks ──────────────────────────────────────────────────────
print_banner
check_ubuntu_version

# ── Load .env if present ──────────────────────────────────────────────────────
load_env_file "$SCRIPT_DIR/.env"

# ── Prompt for config (unless --unattended) ───────────────────────────────────
prompt_setup_config

# ── ERR trap for this script ─────────────────────────────────────────────────
trap '_err_handler $LINENO "${BASH_SOURCE[0]:-setup.sh}" "main" "$?"' ERR

# ── Run phases ────────────────────────────────────────────────────────────────
for phase_entry in "${ALL_PHASES[@]}"; do
  IFS=':' read -r phase_id phase_name phase_script <<< "$phase_entry"

  # --phase= filter
  if [[ -n "$PHASE_ONLY" ]]; then
    if [[ "$phase_id" != "$(printf "%02d" "$PHASE_ONLY")" ]]; then
      continue
    fi
  fi

  # --skip= filter
  if [[ -v "SKIP_SET[$phase_id]" ]]; then
    log_info "Skipping phase $phase_id ($phase_name) — per --skip flag"
    continue
  fi

  run_phase "$phase_id" "$phase_name" "$phase_script"
done

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
log_header "🎉  Setup Complete!"
log_info "Some changes require logging out and back in to take effect:"
log_step "ZSH default shell change"
log_step "Docker group membership"
echo ""
log_info "Run 'exec zsh' to start a ZSH session now."
