#!/usr/bin/env bash
# 08-verify.sh — Post-install verification

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/scripts/00-helpers.sh"
strict_mode

PASS=0; FAIL=0; WARN=0

check() {
  local label="$1"; shift
  if "$@" &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} $label"
    ((PASS++))
  else
    echo -e "  ${RED}✗${NC} $label"
    ((FAIL++))
  fi
}

check_warn() {
  local label="$1"; shift
  if "$@" &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} $label"
    ((PASS++))
  else
    echo -e "  ${YELLOW}⚠${NC} $label (optional)"
    ((WARN++))
  fi
}

# ── Core tools ────────────────────────────────────────────────────────────────
echo -e "\n${BLUE}▸ Core tools${NC}"
for cmd in zsh git gh curl wget jq tree htop ripgrep eza bat fd; do
  # bat/fd may be batcat/fdfind on older Ubuntu
  case "$cmd" in
    bat)       check "$cmd" bash -c "command -v bat || command -v batcat" ;;
    fd)        check "$cmd" bash -c "command -v fd || command -v fdfind" ;;
    ripgrep)   check "$cmd" command -v rg ;;
    *)         check "$cmd" command -v "$cmd" ;;
  esac
done

# ── ZSH ───────────────────────────────────────────────────────────────────────
echo -e "\n${BLUE}▸ ZSH${NC}"
check "zsh is default shell" bash -c "[[ \$(getent passwd $USER | cut -d: -f7) == *zsh ]]"
check ".zshrc is symlink" test -L "$HOME/.zshrc"
check ".zimrc is symlink" test -L "$HOME/.zimrc"
check_warn "Zim installed" test -d "${ZIM_HOME:-$HOME/.zim}"

# ── Docker ────────────────────────────────────────────────────────────────────
echo -e "\n${BLUE}▸ Docker${NC}"
check "docker installed" command -v docker
check "docker-compose installed" bash -c "command -v docker-compose || docker compose version"
check "user in docker group" id -nG "$USER" | grep -qw docker
check_warn "docker pull test (hello-world)" docker pull hello-world

# ── Applications ──────────────────────────────────────────────────────────────
echo -e "\n${BLUE}▸ Applications${NC}"
check "VSCode" command -v code
check "Firefox" command -v firefox
check_warn "Slack" bash -c "command -v slack || flatpak list 2>/dev/null | grep -qi slack"
check_warn "Ghostty" bash -c "command -v ghostty || flatpak list 2>/dev/null | grep -qi ghostty"

# ── Dev tools ─────────────────────────────────────────────────────────────────
echo -e "\n${BLUE}▸ Dev tools${NC}"
check_warn "nvm" bash -c "export NVM_DIR=\"\${HOME}/.nvm\"; [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" && nvm --version"
check_warn "node" bash -c "export NVM_DIR=\"\${HOME}/.nvm\"; [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" && node --version"
check_warn "bun" command -v bun

# ── SSH key ───────────────────────────────────────────────────────────────────
echo -e "\n${BLUE}▸ SSH${NC}"
check "SSH key exists" test -f "$HOME/.ssh/id_ed25519.pub"
check_warn "GitHub SSH auth" ssh -T git@github.com 2>&1 | grep -qi "successfully authenticated"

# ── Workspace repos ───────────────────────────────────────────────────────────
echo -e "\n${BLUE}▸ Workspace repos${NC}"
if [[ -f "$REPO_ROOT/repos.txt" ]]; then
  while IFS= read -r repo || [[ -n "$repo" ]]; do
    [[ -z "$repo" || "$repo" == \#* ]] && continue
    name="$(basename "$repo" .git)"
    check_warn "  $name" test -d "$HOME/Workspace/$name/.git"
  done < "$REPO_ROOT/repos.txt"
else
  echo -e "  ${YELLOW}⚠${NC} repos.txt not found"
  ((WARN++))
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo -e "\n${BLUE}━━━ Summary ━━━${NC}"
echo -e "  ${GREEN}Passed:${NC} $PASS   ${RED}Failed:${NC} $FAIL   ${YELLOW}Warnings:${NC} $WARN"
if (( FAIL > 0 )); then
  echo -e "\n${RED}Some checks failed. Review above and re-run the relevant phase.${NC}"
  exit 1
fi
echo -e "\n${GREEN}All required checks passed!${NC}"
