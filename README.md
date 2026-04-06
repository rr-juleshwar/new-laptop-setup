# new-laptop-setup

Automated setup script for a fresh Ubuntu (20.04+) machine — Rapyuta Robotics dev environment.

## What it sets up

| Phase | Script | What it does |
|-------|--------|--------------|
| 01 | `01-system.sh` | curl, wget, zsh, wl-clipboard, eza, bat, fd, MesloLGS NF font, keyd |
| 02 | `02-zsh.sh` | Zim framework, zshrc + zimrc + alias dotfiles, chsh |
| 03 | `03-git.sh` | Latest git (PPA), gitconfig, GitHub CLI (gh) |
| 04 | `04-docker.sh` | Docker CE, docker group, quay.io login |
| 05 | `05-apps.sh` | VSCode + 17 extensions, Firefox, Slack, Ghostty |
| 06 | `06-devtools.sh` | NVM, Node.js LTS, Bun (optional) |
| 07 | `07-workspace.sh` | ~/Workspace, SSH key, Rapyuta repo cloning |

## Usage

### Full setup

```bash
git clone git@github.com:rapyuta-robotics/new-laptop-setup.git ~/Workspace/new-laptop-setup
cd ~/Workspace/new-laptop-setup
chmod +x setup.sh scripts/*.sh
./setup.sh
```

### Single phase

```bash
./setup.sh --phase=04   # Only run Docker setup
```

### List phases

```bash
./setup.sh --list
```

## Requirements

- Ubuntu 20.04 or later (tested on 20.04, 22.04, 24.04)
- Internet connection
- sudo access

## Credentials prompted at start

- Git user name + email
- quay.io username + password (for Docker registry login)

These are **never stored in the scripts** — only held in environment variables for the session.

## Post-setup

After the script completes:

1. Add your SSH public key to GitHub: https://github.com/settings/keys
2. Authenticate with GitHub CLI: `gh auth login`
3. Restart your terminal (or `exec zsh`) to activate ZSH + Zim

## Notes

- **Ghostty** uses `apt.ghostty.org` on Ubuntu 22.04+; falls back to Flatpak on 20.04
- **Firefox** uses Mozilla's PPA (not snap) to avoid snap limitations
- **Slack** downloads the official `.deb` directly from Slack's CDN
- **VSCode** uses Microsoft's apt repo (not snap)
- **keyd** needs `udev` rules, so you'll need to reboot/re-login for key remapping to take effect

## Dotfiles

All dotfiles live in `dotfiles/`:

| File | Destination |
|------|-------------|
| `zshrc` | `~/.zshrc` |
| `zimrc` | `~/.zimrc` |
| `gitconfig.template` | `~/.gitconfig` (after substituting name/email) |
| `ghostty-config` | `~/.config/ghostty/config` |
| `zsh-aliases/general.zsh` | `~/.config/zsh/aliases/general.zsh` |
| `zsh-aliases/git.zsh` | `~/.config/zsh/aliases/git.zsh` |
| `zsh-aliases/ubuntu-wayland.zsh` | `~/.config/zsh/aliases/ubuntu-wayland.zsh` |

## Repos

`repos.txt` lists all Rapyuta private repos to clone into `~/Workspace`. Edit before running if the list changes.
