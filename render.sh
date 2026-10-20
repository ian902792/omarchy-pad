#!/data/data/com.termux/files/usr/bin/bash
# Render configs/*/*.tpl into ~/.config using the active theme + env settings.
# Usage: render.sh            (theme/env from ~/.config/omarchy-pad/env)
# Template syntax: @TOKEN@ (colours, sizes, paths) and @px:N@ (N pixels at 96 dpi, scaled to OMP_DPI).
set -euo pipefail
OMP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$OMP_ROOT/lib/common.sh"
load_env

THEME_DIR="$OMP_ROOT/themes/$OMP_THEME"
[ -r "$THEME_DIR/colors.sh" ] || die "unknown theme '$OMP_THEME' (see themes/)"
. "$THEME_DIR/colors.sh"

# Derived values (px sizes follow DPI: 96 dpi = 1x)
BAR_H=$(( OMP_DPI * 25 / 100 ))
CURSOR=$(( OMP_DPI / 4 ))
BORDER=$(( OMP_DPI / 64 + 1 ))
GAP=$(( OMP_DPI / 16 ))
MOD="$OMP_MOD"
DPI="$OMP_DPI"
TERMINAL="$OMP_TERMINAL"
SCRIPTS="$OMP_ROOT/scripts"
ROOT="$OMP_ROOT"
THEME="$OMP_THEME"
WALLPAPER="${OMP_WALLPAPER:-$OMP_ROOT/themes/$OMP_THEME/wallpaper.png}"

# "#rrggbb" -> "r,g,b" (for rgba()) and alpha-prefixed "#aarrggbb" (polybar)
rgb() { printf '%d,%d,%d' "0x${1:1:2}" "0x${1:3:2}" "0x${1:5:2}"; }
BG_RGB=$(rgb "$BG"); MANTLE_RGB=$(rgb "$MANTLE"); SURFACE_RGB=$(rgb "$SURFACE"); FG_RGB=$(rgb "$FG")
BLUE_RGB=$(rgb "$BLUE"); MAUVE_RGB=$(rgb "$MAUVE"); GREEN_RGB=$(rgb "$GREEN")
BG_A="#d9${BG#\#}"; SURFACE_A="#a6${SURFACE#\#}"

TOKENS=(BG MANTLE SURFACE SURFACE1 FG SUBTEXT MUTED BLUE MAUVE GREEN RED YELLOW PEACH TEAL PALETTE
        BG_RGB MANTLE_RGB SURFACE_RGB FG_RGB BLUE_RGB MAUVE_RGB GREEN_RGB BG_A SURFACE_A
        BAR_H CURSOR BORDER GAP MOD DPI TERMINAL SCRIPTS ROOT THEME WALLPAPER)

# Escape sed replacement metacharacters (\ & and the | delimiter) in values.
esc() { printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'; }
sedargs=()
for t in "${TOKENS[@]}"; do
    sedargs+=(-e "s|@${t}@|$(esc "${!t}")|g")
done

# @px:N@ -> N * DPI / 96 (integer)
scale_px() {
    awk -v dpi="$OMP_DPI" '{
        while (match($0, /@px:[0-9]+@/)) {
            n = substr($0, RSTART + 4, RLENGTH - 5)
            $0 = substr($0, 1, RSTART - 1) int(n * dpi / 96 + 0.5) substr($0, RSTART + RLENGTH)
        }
        print
    }'
}

# template (relative to configs/)  ->  destination (relative to $HOME)  [mode]
MAP=(
    "bspwm/bspwmrc.tpl|.config/bspwm/bspwmrc|755"
    "sxhkd/sxhkdrc.tpl|.config/sxhkd/sxhkdrc|644"
    "polybar/config.ini.tpl|.config/polybar/config.ini|644"
    "rofi/config.rasi.tpl|.config/rofi/config.rasi|644"
    "terminal/terminalrc.tpl|.config/xfce4/terminal/terminalrc|644"
    "gtk/settings.ini.tpl|.config/gtk-3.0/settings.ini|644"
    "gtk/gtk.css.tpl|.config/gtk-3.0/gtk.css|644"
    "x11/Xresources.tpl|.Xresources|644"
    "picom/picom.conf.tpl|.config/picom/picom.conf|644"
    "eww/eww.yuck.tpl|.config/eww/eww.yuck|644"
    "eww/eww.scss.tpl|.config/eww/eww.scss|644"
)

for entry in "${MAP[@]}"; do
    IFS='|' read -r src dst mode <<<"$entry"
    [ -r "$OMP_ROOT/configs/$src" ] || die "missing template configs/$src"
    out="$HOME/$dst"
    mkdir -p "$(dirname "$out")"
    sed "${sedargs[@]}" "$OMP_ROOT/configs/$src" | scale_px > "$out.tmp"
    if grep -qE '@([A-Z_0-9]+|px:[0-9]+)@' "$out.tmp"; then
        rm -f "$out.tmp"; die "unrendered token left in $dst"
    fi
    chmod "$mode" "$out.tmp"; mv "$out.tmp" "$out"
    info "rendered $dst (theme=$OMP_THEME)"
done
