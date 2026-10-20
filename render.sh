#!/data/data/com.termux/files/usr/bin/bash
# Render configs/*/*.tpl into ~/.config using the active theme + env settings.
# Usage: render.sh            (theme/env from ~/.config/omarchy-pad/env)
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

TOKENS=(BG MANTLE SURFACE SURFACE1 FG SUBTEXT MUTED BLUE MAUVE GREEN RED YELLOW PEACH TEAL PALETTE
        BAR_H CURSOR BORDER GAP MOD DPI TERMINAL SCRIPTS ROOT THEME)

sedargs=()
for t in "${TOKENS[@]}"; do
    sedargs+=(-e "s|@${t}@|${!t}|g")
done

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
)

for entry in "${MAP[@]}"; do
    IFS='|' read -r src dst mode <<<"$entry"
    [ -r "$OMP_ROOT/configs/$src" ] || die "missing template configs/$src"
    out="$HOME/$dst"
    mkdir -p "$(dirname "$out")"
    sed "${sedargs[@]}" "$OMP_ROOT/configs/$src" > "$out.tmp"
    if grep -q '@[A-Z_0-9]*@' "$out.tmp"; then
        rm -f "$out.tmp"; die "unrendered token left in $dst"
    fi
    chmod "$mode" "$out.tmp"; mv "$out.tmp" "$out"
    info "rendered $dst (theme=$OMP_THEME)"
done
