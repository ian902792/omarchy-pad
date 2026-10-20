#!/data/data/com.termux/files/usr/bin/bash
# omarchy-pad installer. Run in the Termux app (foreground: ColorOS blocks background network).
# Idempotent: re-run to update packages, configs and Claude Code.
set -euo pipefail
[ "${PREFIX:-}" = /data/data/com.termux/files/usr ] || { echo "run inside Termux"; exit 1; }
ROOT="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_VER="${CLAUDE_VER:-latest}"

echo "==> packages"
apt-get update
apt-get install -y -o Dpkg::Options::=--force-confold x11-repo glibc-repo
apt-get update
apt-get install -y -o Dpkg::Options::=--force-confold \
    termux-x11-nightly i3 i3status rofi dunst alacritty xorg-xrdb xorg-xsetroot dbus thunar \
    openssh mosh git gh nodejs-lts neovim fzf ripgrep jq termux-api glibc-runner

echo "==> font (JetBrainsMono Nerd Font)"
fdir="$PREFIX/share/fonts/JetBrainsMonoNF"
if [ ! -d "$fdir" ]; then
    mkdir -p "$fdir"
    curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/JetBrainsMono.tar.xz | tar -xJ -C "$fdir"
    fc-cache -f >/dev/null
fi

echo "==> configs (symlinked to $ROOT/config; old dirs kept as *.bak)"
mkdir -p ~/.config ~/.local/bin ~/.shortcuts
for d in i3 i3status alacritty rofi dunst; do
    t=~/.config/$d
    [ -L "$t" ] && rm "$t"
    [ -e "$t" ] && mv "$t" "$t.bak.$(date +%s)"
    ln -s "$ROOT/config/$d" "$t"
done
ln -sf "$ROOT/config/Xresources" ~/.Xresources
for f in "$ROOT"/bin/*; do ln -sf "$f" ~/.local/bin/; done
grep -q 'omarchy-pad' ~/.bashrc 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"  # omarchy-pad' >> ~/.bashrc

# Termux:Widget entries (tasks/ = run in background, no terminal window). Old omarchy-pad entries removed.
rm -f ~/.shortcuts/"Desktop Start" ~/.shortcuts/"Desktop Stop" \
      ~/.shortcuts/tasks/{"Classic XFCE Start","Tiling Start","Theme Toggle","Desktop Start","Desktop Stop"}
# Long-press menu of the Termux:Widget app icon = ~/.termux/widget/dynamic_shortcuts (needs a tap on
# CREATE SHORTCUTS in the Termux:Widget app after changes).
dyn=~/.termux/widget/dynamic_shortcuts
rm -f "$dyn"/{"Classic XFCE Start","Tiling Start","Theme Toggle","Desktop Start","Desktop Stop"}
mkdir -p ~/.shortcuts/tasks "$dyn"
for n in start stop; do
    f=~/.shortcuts/tasks/"Desktop ${n^}"
    printf '#!/data/data/com.termux/files/usr/bin/bash\nexec bash "%s/%s.sh"\n' "$ROOT" "$n" > "$f"
    chmod +x "$f"
    cp "$f" "$dyn/"
done

echo "==> Claude Code ($CLAUDE_VER, linux-arm64 glibc build)"
# No Android build exists; the glibc build runs through glibc-runner's loader (see bin/claude).
cdir=~/.local/share/claude-glibc
mkdir -p "$cdir"
tmp=$(mktemp -d)
(cd "$tmp" && npm pack -s "@anthropic-ai/claude-code-linux-arm64@$CLAUDE_VER" >/dev/null && tar xzf ./*.tgz)
mv "$tmp/package/claude" "$cdir/claude"
rm -rf "$tmp"
~/.local/bin/claude --version

echo "==> ssh key for the Mac"
[ -f ~/.ssh/id_ed25519 ] || ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519 -C omarchy-pad
echo "Add this to the Mac's ~/.ssh/authorized_keys:"
cat ~/.ssh/id_ed25519.pub
mkdir -p ~/.config/omarchy-pad
e=~/.config/omarchy-pad/env
grep -qs '^MAC=' "$e" || { [ -f "$e" ] && mv "$e" "$e.old"; cp "$ROOT/env.example" "$e"; }
echo "done. Start: bash $ROOT/start.sh (or Termux:Widget > Desktop Start)"
