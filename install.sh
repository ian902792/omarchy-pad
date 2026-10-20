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
    termux-x11-nightly i3 i3status rofi dunst kitty python-pillow fcitx5 fcitx5-chinese-addons fcitx5-gtk3 libime xorg-xrdb xorg-xsetroot xorg-xkbcomp dbus thunar ristretto xclip papirus-icon-theme clang \
    openssh mosh git gh starship nodejs-lts neovim fzf ripgrep jq termux-api glibc-runner

echo "==> font (JetBrainsMono Nerd Font)"
fdir="$PREFIX/share/fonts/JetBrainsMonoNF"
if [ ! -d "$fdir" ]; then
    mkdir -p "$fdir"
    curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/JetBrainsMono.tar.xz | tar -xJ -C "$fdir"
    fc-cache -f >/dev/null
fi

echo "==> configs (symlinked to $ROOT/config; old dirs kept as *.bak)"
mkdir -p ~/.config ~/.local/bin ~/.shortcuts
for d in i3 i3status kitty rofi dunst gtk-3.0; do
    t=~/.config/$d
    [ -L "$t" ] && rm "$t"
    [ -e "$t" ] && mv "$t" "$t.bak.$(date +%s)"
    ln -s "$ROOT/config/$d" "$t"
done
ln -sf "$ROOT/config/Xresources" ~/.Xresources
# photos open in ristretto (Thunar double-click)
xdg-mime default org.xfce.ristretto.desktop image/jpeg image/png image/gif image/webp image/heic
for f in "$ROOT"/bin/*; do ln -sf "$f" ~/.local/bin/; done
"$ROOT/bin/omp-watermark" >/dev/null   # key cheat sheet behind kitty text
mkdir -p ~/.local/lib && clang -shared -fPIC -O2 -o ~/.local/lib/omp-notag.so "$ROOT/lib/omp-notag.c"
ln -sf "$ROOT/config/starship.toml" ~/.config/starship.toml
# ~/.bashrc stays yours: drop the old one-line PATH hook, then source config/bashrc once
sed -i '/# omarchy-pad$/d' ~/.bashrc 2>/dev/null || true
grep -qs 'omarchy-pad/config/bashrc' ~/.bashrc || echo ". \"$ROOT/config/bashrc\"" >> ~/.bashrc

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

echo "==> Chinese input: fcitx5 + 自由大新倉頡 (ime/newcj.cin -> fcitx5 table)"
fx=~/.local/share/fcitx5
mkdir -p "$fx/table" "$fx/inputmethod" ~/.config/fcitx5
tmp=$(mktemp -d)
{ printf "KeyCode=abcdefghijklmnopqrstuvwxyz,.;'[]?\nLength=5\n[Data]\n"
  # NF==2 drops the one cin entry whose value contains spaces
  awk '/^%chardef begin/{on=1;next} /^%chardef end/{on=0} on && !/^#/ && NF==2 {print $1, $2}' "$ROOT/ime/newcj.cin"
} > "$tmp/newcj.txt"
libime_tabledict "$tmp/newcj.txt" "$fx/table/newcj.main.dict"
rm -rf "$tmp"
cp "$ROOT/config/fcitx5/newcj.conf" "$fx/inputmethod/"
# copies, not links: fcitx5 rewrites profile/config on exit
pkill -x fcitx5 2>/dev/null || true
cp "$ROOT/config/fcitx5/profile" "$ROOT/config/fcitx5/config" ~/.config/fcitx5/
mkdir -p ~/.config/fcitx5/conf && cp "$ROOT/config/fcitx5/classicui.conf" ~/.config/fcitx5/conf/

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
echo "Add this key to the Mac's ~/.ssh/authorized_keys and to GitHub (Settings > SSH keys):"
cat ~/.ssh/id_ed25519.pub
mkdir -p ~/.config/omarchy-pad
e=~/.config/omarchy-pad/env
grep -qs '^MAC=' "$e" || { [ -f "$e" ] && mv "$e" "$e.old"; cp "$ROOT/env.example" "$e"; }
echo "done. Start: bash $ROOT/start.sh (or Termux:Widget > Desktop Start)"
