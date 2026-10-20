#!/data/data/com.termux/files/usr/bin/bash
# Start Termux:X11 + i3. Safe to re-run (restarts the session).
"$(dirname "$0")/stop.sh"
export DISPLAY=:0 XDG_RUNTIME_DIR="$TMPDIR/runtime"
mkdir -p -m 700 "$XDG_RUNTIME_DIR"
# Software GL: zink (Turnip) drew alacritty with a garbage band; llvmpipe is crisp and fast enough.
export LIBGL_ALWAYS_SOFTWARE=1
export GDK_SCALE=2 GDK_DPI_SCALE=0.5   # GTK: 2x widgets; text already scaled by Xft.dpi, undo the 2x
nohup termux-x11 :0 -ac -noreset -xstartup "$HOME/.local/bin/omp-session" \
    >"$TMPDIR/omarchy-pad.log" 2>&1 &
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1
