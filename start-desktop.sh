#!/data/data/com.termux/files/usr/bin/bash
# Start the macOS-like Desktop session on Termux:X11 (default mode). Usage: start-desktop.sh
OMP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$OMP_ROOT/lib/common.sh"
require_termux_native
load_env
for b in xfwm4 picom polybar plank eww feh dbus-launch; do
    command -v "$b" >/dev/null 2>&1 || die "$b not installed (run install.sh)"
done
[ -s "$HOME/.config/picom/picom.conf" ] || die "configs not rendered; run $OMP_ROOT/render.sh"

"$OMP_ROOT/stop-omarchy.sh" --quiet
info "starting Desktop session (theme=$OMP_THEME dpi=$OMP_DPI gpu=$OMP_GPU)"
start_audio
start_x11
apply_gpu_env
export OMP_ROOT
exec dbus-launch --exit-with-session "$OMP_ROOT/scripts/desktop-session.sh"
