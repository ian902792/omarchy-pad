#!/data/data/com.termux/files/usr/bin/bash
# Start the bspwm desktop on Termux:X11. Does not touch ~/start-x11.sh (DroidDesk) or XFCE.
OMP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$OMP_ROOT/lib/common.sh"
require_termux_native
load_env
[ -x "$HOME/.config/bspwm/bspwmrc" ] || die "not installed; run $OMP_ROOT/install.sh first"

"$OMP_ROOT/stop-omarchy.sh" --quiet
info "starting bspwm session (theme=$OMP_THEME mod=$OMP_MOD dpi=$OMP_DPI gpu=$OMP_GPU)"
start_audio
start_x11
apply_gpu_env
export XDG_CONFIG_HOME="$HOME/.config"
export OMP_AUTOSTART=1   # bspwmrc opens one terminal so the first screen is not empty

if command -v dbus-launch >/dev/null 2>&1; then
    exec dbus-launch --exit-with-session bspwm
else
    warn "dbus-launch not found; starting bspwm without a session bus"
    exec bspwm
fi
