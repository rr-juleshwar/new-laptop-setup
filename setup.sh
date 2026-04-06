#!/usr/bin/env bash
# Rapyuta Robotics — Ubuntu Laptop Setup
# Replicates the RR dev environment: zsh+Zim, git, Docker (quay.io),
# desktop apps, dev tools, and Workspace repos.
# Compatible with Ubuntu 20.04+
#
# Usage:
#   bash setup.sh                     # Run all phases
#   bash setup.sh --phase=03-git      # Run a single phase
#   bash setup.sh --phase=03-git --phase=04-docker  # Run specific phases
#   bash setup.sh --list              # List all phases

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/00-helpers.sh"

# ── Argument parsing ─────────────────────────────────────────────────────────
PHASES=()
for arg in "$@"; do
  case "$arg" in
    --phase=*) PHASES+=("${arg#*=}") ;;
    --list)
      echo "Available phases:"
      echo "  01-system    System packages & essentials"
      echo "  02-zsh       ZSH + Zim shell framework + dotfiles"
      echo "  03-git       Git config + GitHub CLI"
      echo "  04-docker    Docker CE + quay.io registry"
      echo "  05-apps      Desktop apps (Slack, Firefox, Ghostty, VSCode)"
      echo "  06-devtools  Developer tools (NVM, Node.js, bun)"
      echo "  07-workspace Workspace folder + SSH key + repo list"
      exit 0
      ;;
    --help|-h)
      echo "Usage: bash setup.sh [--phase=PHASE_ID ...] [--list]"
      exit 0
      ;;
    *)
      log_error "Unknown argument: $arg"
      exit 1
      ;;
  esac
done

# ── Pre-flight ────────────────────────────────────────────────────────────────
print_banner
check_ubuntu_version

# Gather config upfront so phases can run unattended
prompt_setup_config

export RR_SCRIPT_DIR="$SCRIPT_DIR"

# ── Phase runner ──────────────────────────────────────────────────────────────
declare -a ALL_PHASES=(
  "01-system:System packages & essentials"
  "02-zsh:ZSH + Zim shell framework"
  "03-git:Git config + GitHub CLI"
  "04-docker:Docker CE + quay.io"
  "05-apps:Desktop apps (Slack, Firefox, Ghostty, VSCode)"
  "06-devtools:Developer tools (NVM, Node.js, bun)"
  "07-workspace:Workspace folder & repository setup"
)

for phase_def in "${ALL_PHASES[@]}"; do
  phase_id="${phase_def%%:*}"
  phase_name="${phase_def##*:}"

  # If specific phases were requested, skip others
  if [[ ${#PHASES[@]} -gt 0 ]]; then
    match=false
    for p in "${PHASES[@]}"; do
      [[ "$p" == "$phase_id" ]] && match=true && break
    done
    $match || continue
  fi

  run_phase "$phase_id" "$phase_name" "$SCRIPT_DIR/scripts/$phase_id.sh"
done

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
log_success "🎉 Setup complete!"
echo ""
log_info "Remaining manual steps:"
echo "  1. Reload shell:       exec zsh"
echo "  2. GitHub CLI auth:    gh auth login"
echo "  3. Generate SSH key:   ssh-keygen -t ed25519 -C '${RR_GIT_EMAIL:-your@email.com}'"
echo "  4. Add SSH key to GitHub: cat ~/.ssh/id_ed25519.pub  →  github.com/settings/keys"
echo "  5. Clone repos:        bash $SCRIPT_DIR/scripts/07-workspace.sh"
echo ""
