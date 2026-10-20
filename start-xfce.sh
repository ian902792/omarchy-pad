#!/data/data/com.termux/files/usr/bin/bash
# XFCE fallback desktop on Termux:X11. Separate from DroidDesk's ~/start-x11.sh (not touched).
OMP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$OMP_ROOT/lib/common.sh"
require_termux_native
load_env
command -v startxfce4 >/dev/null 2>&1 || die "startxfce4 not installed (pkg install xfce4)"

"$OMP_ROOT/stop-omarchy.sh" --quiet
info "starting XFCE fallback session (gpu=$OMP_GPU)"
start_audio
start_x11
apply_gpu_env
# XFCE ignores ~/.Xresources for GTK DPI; set it through xfconf (inside the session bus) once xfsettingsd is up.
export OMP_DPI
exec dbus-launch --exit-with-session sh -c '
    ( for _ in $(seq 1 30); do xfconf-query -c xsettings -l >/dev/null 2>&1 && break; sleep 1; done
      xfconf-query -c xsettings -p /Xft/DPI -n -t int -s "$OMP_DPI" >/dev/null 2>&1
      xfconf-query -c xfce4-panel -p /panels/panel-1/size -n -t uint -s "$((OMP_DPI * 28 / 96))" >/dev/null 2>&1 ) &
    exec startxfce4'
