#!/data/data/com.termux/files/usr/bin/bash
# Configure the Plank dock (bottom, centred, zoom) and its launchers. Needs the session D-Bus (dconf).
# Idempotent: rewrites ~/.config/plank/dock1/launchers and dconf keys every start.
OMP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$OMP_ROOT/lib/common.sh"
load_env

apps="$HOME/.local/share/applications"
mkdir -p "$apps"
cat > "$apps/omarchy-apps.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Apps
Exec=rofi -show drun
Icon=view-app-grid
Terminal=false
EOF
cat > "$apps/omarchy-theme.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Theme
Exec=$OMP_ROOT/set-theme.sh toggle
Icon=preferences-desktop-theme
Terminal=false
EOF

L="$HOME/.config/plank/dock1/launchers"
mkdir -p "$L"
rm -f "$L"/*.dockitem
n=0; items=()
add() {  # add path-to-desktop-file (skipped if missing)
    [ -r "$1" ] || return 0
    n=$((n + 1))
    local f; f="$(printf '%02d' "$n")-$(basename "$1" .desktop).dockitem"
    printf '[PlankDockItemPreferences]\nLauncher=file://%s\n' "$1" > "$L/$f"
    items+=("'$f'")
}
add "$apps/omarchy-apps.desktop"
add "$PREFIX/share/applications/xfce4-terminal.desktop"
add "$PREFIX/share/applications/thunar.desktop"
add "$PREFIX/share/applications/org.xfce.mousepad.desktop"
add "$PREFIX/share/applications/xfce-settings-manager.desktop"
add "$apps/omarchy-theme.desktop"
dock_items="[$(IFS=,; echo "${items[*]}")]"

# Custom glass theme: derive from Default (keeps every key), then override panel shape/colours.
. "$OMP_ROOT/themes/$OMP_THEME/colors.sh"
rgb() { printf '%d;;%d;;%d' "0x${1:1:2}" "0x${1:3:2}" "0x${1:5:2}"; }
T="$HOME/.local/share/plank/themes/Omarchy"
mkdir -p "$T"
sed -e "s/^TopRoundness=.*/TopRoundness=$((OMP_DPI * 24 / 96))/" \
    -e "s/^BottomRoundness=.*/BottomRoundness=$((OMP_DPI * 24 / 96))/" \
    -e "s/^OuterStrokeColor=.*/OuterStrokeColor=$(rgb "$FG");;45/" \
    -e "s/^FillStartColor=.*/FillStartColor=$(rgb "$SURFACE");;170/" \
    -e "s/^FillEndColor=.*/FillEndColor=$(rgb "$MANTLE");;150/" \
    -e "s/^InnerStrokeColor=.*/InnerStrokeColor=$(rgb "$FG");;22/" \
    -e "s/^HorizPadding=.*/HorizPadding=6/" \
    -e "s/^TopPadding=.*/TopPadding=4/" \
    -e "s/^BottomPadding=.*/BottomPadding=4/" \
    -e "s/^ItemPadding=.*/ItemPadding=4/" \
    -e "s/^IndicatorColor=.*/IndicatorColor=$(rgb "$FG");;255/" \
    "$PREFIX/share/plank/themes/Default/dock.theme" > "$T/dock.theme"

D=/net/launchpad/plank/docks/dock1
w() { dconf write "$D/$1" "$2" 2>/dev/null || warn "dconf write failed: $1"; }
w theme "'Omarchy'"
w dock-items "$dock_items"
w position "'bottom'"
w alignment "'center'"
w hide-mode "'none'"
w icon-size "$((OMP_DPI * 56 / 96))"
w zoom-enabled true
w zoom-percent 150
w pinned-only false
w lock-items false
info "plank configured ($n launchers)"
