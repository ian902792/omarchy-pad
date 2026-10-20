#!/data/data/com.termux/files/usr/bin/bash
# Stop the bspwm desktop (and XFCE fallback session) plus the Termux:X11 server. Usage: stop-omarchy.sh [--quiet]
# Only touches processes by exact name; leaves Termux shells, sshd, proot sessions alone.
OMP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$OMP_ROOT/lib/common.sh"
quiet=0; [ "${1:-}" = "--quiet" ] && quiet=1

stopped=()
for name in polybar sxhkd bspwm xfce4-session xfwm4 xfce4-panel xfdesktop Thunar; do
    if pgrep -x "$name" >/dev/null 2>&1; then
        pkill -x "$name" 2>/dev/null && stopped+=("$name")
    fi
done
sleep 0.5
X_PAT='termux-x11 com.termux.x11'
if pgrep -f "$X_PAT" >/dev/null 2>&1; then
    pkill -f "$X_PAT" 2>/dev/null && stopped+=("termux-x11")
    # wait (max ~5s) for the server to really exit before its socket is removed / a new one starts
    for _ in $(seq 1 25); do pgrep -f "$X_PAT" >/dev/null 2>&1 || break; sleep 0.2; done
    pgrep -f "$X_PAT" >/dev/null 2>&1 && { pkill -9 -f "$X_PAT" 2>/dev/null; sleep 0.3; }
fi
command -v pulseaudio >/dev/null 2>&1 && pulseaudio --kill 2>/dev/null
rm -f "${TMPDIR:-$PREFIX/tmp}/.X11-unix/X0" "${TMPDIR:-$PREFIX/tmp}/.X0-lock" 2>/dev/null
if [ "$quiet" = 0 ]; then
    info "stopped: ${stopped[*]:-nothing was running}"
fi
exit 0
