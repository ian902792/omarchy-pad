#!/data/data/com.termux/files/usr/bin/bash
# Switch theme: set-theme.sh catppuccin | tokyo-night | toggle | list
# Persists the choice in ~/.config/omarchy-pad/env, re-renders configs and live-reloads
# bspwm colours, polybar, wallpaper if a desktop is running. Already-open terminals/GTK apps keep old colours.
set -euo pipefail
OMP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$OMP_ROOT/lib/common.sh"
load_env

themes=()
for d in "$OMP_ROOT"/themes/*/; do [ -r "$d/colors.sh" ] && themes+=("$(basename "$d")"); done

want="${1:-}"
case "$want" in
    list|"") printf '%s\n' "${themes[@]}"; echo "current: $OMP_THEME"; [ -z "$want" ] && exit 1; exit 0;;
    toggle)
        want="${themes[0]}"
        for i in "${!themes[@]}"; do
            [ "${themes[$i]}" = "$OMP_THEME" ] && want="${themes[$(( (i + 1) % ${#themes[@]} ))]}"
        done;;
esac

ok=0; for t in "${themes[@]}"; do [ "$t" = "$want" ] && ok=1; done
[ "$ok" = 1 ] || die "unknown theme '$want' (available: ${themes[*]})"

mkdir -p "$OMP_CFG"
if grep -q '^OMP_THEME=' "$OMP_ENV_FILE" 2>/dev/null; then
    sed -i "s|^OMP_THEME=.*|OMP_THEME=$want|" "$OMP_ENV_FILE"
else
    echo "OMP_THEME=$want" >> "$OMP_ENV_FILE"
fi
OMP_THEME="$want"; export OMP_THEME
"$OMP_ROOT/render.sh"

export DISPLAY="${DISPLAY:-:0}"
if xdpyinfo >/dev/null 2>&1 && is_running bspwm; then
    sh "$HOME/.config/bspwm/bspwmrc" >/dev/null 2>&1 || warn "live reload of bspwmrc failed"
    info "live-reloaded bspwm colours, polybar, wallpaper"
fi
info "theme is now: $want"
