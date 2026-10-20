#!/data/data/com.termux/files/usr/bin/bash
# XFCE desktop on Termux:X11 (the "Desktop" mode). Separate from DroidDesk's ~/start-x11.sh (not touched).
OMP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$OMP_ROOT/lib/common.sh"
require_termux_native
load_env
command -v startxfce4 >/dev/null 2>&1 || die "startxfce4 not installed (pkg install xfce4)"

"$OMP_ROOT/stop-omarchy.sh" --quiet
info "starting XFCE session (gpu=$OMP_GPU)"
start_audio
start_x11
apply_gpu_env
export OMP_ROOT
# xfce-theme.sh must run inside the session bus; it waits for xfsettingsd, then applies wallpaper/dark/DPI.
exec dbus-launch --exit-with-session sh -c '
    ( "$OMP_ROOT/scripts/xfce-theme.sh" >> "$HOME/.omarchy-pad/logs/xfce-theme.log" 2>&1 ) &
    exec startxfce4'
