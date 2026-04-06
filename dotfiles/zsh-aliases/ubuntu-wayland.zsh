# Ubuntu + Wayland compatibility overrides

# Clipboard (replace macOS pbcopy/pbpaste)
if command -v wl-copy >/dev/null 2>&1; then
  alias pbcopy='wl-copy'
  alias pbpaste='wl-paste --no-newline'
  alias cpwd='pwd | wl-copy'
  alias pa='wl-paste --no-newline'
elif command -v xclip >/dev/null 2>&1; then
  # fallback (usually for X11, but can work via XWayland)
  alias pbcopy='xclip -selection clipboard'
  alias pbpaste='xclip -selection clipboard -o'
  alias cpwd='pwd | xclip -selection clipboard'
  alias pa='xclip -selection clipboard -o'
fi

# "ports" alias: netstat is often missing on minimal installs
if command -v ss >/dev/null 2>&1; then
  alias ports='ss -tulanp'
fi

# If you prefer eza (exa successor) on Ubuntu:
if command -v eza >/dev/null 2>&1; then
  alias l='eza -aF --icons'
  alias la='eza -aF --icons'
  alias ll='eza -laF --icons'
  alias lm='eza -lahr --color-scale --icons -s=modified'
  alias lb='eza -lahr --color-scale --icons -s=size'
  alias tree='f() { eza -aF --tree -L=${1:-2} --icons };f'
fi