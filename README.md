# new-laptop-setup

[![CI](https://github.com/rr-juleshwar/new-laptop-setup/actions/workflows/test.yml/badge.svg)](https://github.com/rr-juleshwar/new-laptop-setup/actions/workflows/test.yml)

Automated setup scripts for a fresh Ubuntu (20.04+) laptop — Rapyuta Robotics dev environment.

## Features

- **Modular phases** — run everything, a single phase, or skip specific ones
- **Idempotent** — safe to re-run after partial failures; skips already-installed packages
- **Dry-run mode** — preview every command without executing
- **Unattended mode** — CI-friendly, reads credentials from env vars / `.env` file
- **GNU Stow dotfiles** — symlinked, so edits in the repo are live immediately
- **Post-install verification** — checks all tools, services, and repos
- **ShellCheck clean** — all scripts pass static analysis
- **Cross-version** — Ubuntu 20.04, 22.04, 24.04+ with automatic fallbacks

## What it sets up

| Phase | Script | What it does |
|-------|--------|--------------|
| 01 | `01-system.sh` | curl, wget, zsh, wl-clipboard, eza (v0.21.2), bat, fd, MesloLGS NF font, keyd |
| 02 | `02-zsh.sh` | Zim framework, .zshrc + .zimrc + aliases via GNU Stow, chsh |
| 03 | `03-git.sh` | Latest git (PPA), gitconfig from template, GitHub CLI (gh) |
| 04 | `04-docker.sh` | Docker CE via get.docker.com, docker group, quay.io login |
| 05 | `05-apps.sh` | VSCode + 17 extensions, Firefox (Mozilla PPA), Slack (v4.43.51), Ghostty |
| 06 | `06-devtools.sh` | NVM (v0.40.0), Node.js LTS, Bun (optional) |
| 07 | `07-workspace.sh` | ~/Workspace, SSH key generation, Rapyuta repo cloning |
| 08 | `08-verify.sh` | Post-install verification with pass/fail/warn summary |

## Quick start

```bash
git clone git@github.com:rr-juleshwar/new-laptop-setup.git ~/Workspace/new-laptop-setup
cd ~/Workspace/new-laptop-setup
./setup.sh
```

## Usage

```bash
./setup.sh                  # Full interactive setup
./setup.sh --dry-run        # Preview all commands without executing
./setup.sh --phase=04       # Run only Docker setup
./setup.sh --skip=04,06     # Run everything except Docker and devtools
./setup.sh --unattended     # Non-interactive (reads .env or env vars)
./setup.sh --list           # List available phases
./setup.sh --help           # Show help
```

### Makefile shortcuts

```bash
make setup                  # Full setup
make dry-run                # Dry-run
make docker                 # Single phase
make verify                 # Run verification
make lint                   # ShellCheck all scripts
make clean                  # Remove stow symlinks
```

### Unattended mode

Create a `.env` file (never committed — in `.gitignore`):

```bash
RR_GIT_NAME="Your Name"
RR_GIT_EMAIL="you@rapyuta-robotics.com"
RR_QUAY_USER="quay_username"
RR_QUAY_PASS="quay_password"
```

Then run:

```bash
./setup.sh --unattended
```

## Requirements

- Ubuntu 20.04 or later
- Internet connection
- sudo access

## Credentials

The setup prompts for:

- **Git** user name + email
- **quay.io** username + password (Docker registry)

These are **never persisted** — held only as environment variables for the session.

## Dotfiles (GNU Stow)

Dotfiles are managed with [GNU Stow](https://www.gnu.org/software/stow/) — symlinked from the repo into `$HOME`:

```
dotfiles/
├── zsh/
│   ├── .zshrc
│   ├── .zimrc
│   └── .config/zsh/aliases/
│       ├── general.zsh
│       ├── git.zsh
│       └── ubuntu-wayland.zsh
├── ghostty/
│   └── .config/ghostty/config
└── gitconfig.template          # sed-substituted, not stowed
```

Edit files in `dotfiles/` and they take effect immediately (symlinks). To uninstall:

```bash
stow -d dotfiles -t ~ -D zsh ghostty
```

## Cross-version compatibility

| App | 22.04+ | 20.04 |
|-----|--------|-------|
| Ghostty | `apt.ghostty.org` | Flatpak fallback |
| Firefox | Mozilla PPA (removes snap) | Mozilla PPA |
| Docker | `get.docker.com` | `get.docker.com` |
| VSCode | Microsoft apt repo | Microsoft apt repo |
| eza | GitHub binary release | GitHub binary release |
| bat | `bat` package | `batcat` + symlink |

## Post-setup

1. Add your SSH public key to [GitHub](https://github.com/settings/keys)
2. Authenticate with GitHub CLI: `gh auth login`
3. Restart your terminal (or `exec zsh`) to activate ZSH + Zim
4. Reboot for keyd key remapping to take effect

## Repos

`repos.txt` lists Rapyuta private repos cloned into `~/Workspace/`. Edit before running if the list changes.

## Local testing with Docker

Test the setup scripts in a disposable container without touching your host machine:

```bash
make test-docker                # Dry-run on Ubuntu 20.04 (default)
make test-docker UBUNTU=22.04   # Dry-run on Ubuntu 22.04
make test-docker UBUNTU=24.04   # Dry-run on Ubuntu 24.04
make test-docker-live           # Interactive shell for manual testing
```

The Docker test environment creates a non-root user with sudo, sets up
env vars for unattended mode, and runs `setup.sh --dry-run --unattended`
by default.

## CI

GitHub Actions runs on every push:

1. **ShellCheck** — lints all scripts
2. **Dry-run matrix** — `setup.sh --dry-run --unattended` on Ubuntu 22.04 + 24.04
