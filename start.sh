#!/data/data/com.termux/files/usr/bin/bash
# Start Termux:X11 + i3. Safe to re-run (restarts the session).
"$(dirname "$0")/stop.sh"
export DISPLAY=:0 XDG_RUNTIME_DIR="$TMPDIR/runtime"
mkdir -p -m 700 "$XDG_RUNTIME_DIR"
# GPU GL via zink (Adreno 830 / Turnip). kitty renders cleanly on it and uses ~9x less CPU than llvmpipe
# (300k-line test: 0.49s vs 4.25s). alacritty drew garbage on zink, which is why it was dropped.
# Fallback if kitty ever fails to start: replace this line with  export LIBGL_ALWAYS_SOFTWARE=1
export MESA_LOADER_DRIVER_OVERRIDE=zink GALLIUM_DRIVER=zink TU_DEBUG=noconform
export GDK_SCALE=2 GDK_DPI_SCALE=0.5   # GTK: 2x widgets; text already scaled by Xft.dpi, undo the 2x
# fcitx5 (自由大新): kitty only speaks IBus, which fcitx5 emulates; GTK uses its own module, others XIM
export GLFW_IM_MODULE=ibus GTK_IM_MODULE=fcitx QT_IM_MODULE=fcitx XMODIFIERS=@im=fcitx
rm -f ~/.config/ibus/bus/*   # stale address from the last fcitx5 would point kitty at a dead socket
nohup termux-x11 :0 -ac -noreset -xstartup "$HOME/.local/bin/omp-session" \
    >"$TMPDIR/omarchy-pad.log" 2>&1 &
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1
# Remote access while the desktop runs: sshd on 8022 (key-only), and a wake lock so Android keeps Termux alive.
pgrep -x sshd >/dev/null || sshd
termux-wake-lock
