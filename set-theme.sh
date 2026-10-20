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
if pgrep -x picom >/dev/null 2>&1 && pgrep -x xfwm4 >/dev/null 2>&1; then
    # Desktop session: reload everything that has a theme. Settings live on the session bus.
    bus=$(tr '\0' '\n' < "/proc/$(pgrep -x xfwm4 | head -1)/environ" 2>/dev/null | sed -n 's/^DBUS_SESSION_BUS_ADDRESS=//p')
    if [ -n "$bus" ]; then
        export DBUS_SESSION_BUS_ADDRESS="$bus"
        "$OMP_ROOT/scripts/gtk-settings.sh" >/dev/null 2>&1 || warn "gtk-settings failed"
        "$OMP_ROOT/scripts/plank-setup.sh" >/dev/null 2>&1 && { pkill -x plank; sleep 0.5; plank >/dev/null 2>&1 & }
        eww reload >/dev/null 2>&1 || warn "eww reload failed"
        "$OMP_ROOT/scripts/eww-pin.sh" >/dev/null 2>&1
    fi
    "$OMP_ROOT/scripts/wallpaper.sh"
    "$OMP_ROOT/scripts/polybar-launch.sh" mac
    info "live-reloaded Desktop session (polybar, dock, widgets, wallpaper; open terminals keep old colours)"
fi
if pgrep -x xfce4-session >/dev/null 2>&1 && command -v dbus-launch >/dev/null 2>&1; then
    # XFCE settings live in its session bus; take the address from the running session
    bus=$(tr '\0' '\n' < "/proc/$(pgrep -x xfce4-session | head -1)/environ" 2>/dev/null | sed -n 's/^DBUS_SESSION_BUS_ADDRESS=//p')
    [ -n "$bus" ] && DBUS_SESSION_BUS_ADDRESS="$bus" "$OMP_ROOT/scripts/xfce-theme.sh" >/dev/null 2>&1 \
        && info "re-applied XFCE wallpaper/theme"
fi
info "theme is now: $want"
