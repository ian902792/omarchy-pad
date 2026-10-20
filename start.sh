#!/data/data/com.termux/files/usr/bin/bash
# Start Termux:X11 + i3. Safe to re-run (restarts the session).
# Detach first: Termux:Widget kills the shortcut's whole process group when the script exits, which took the
# X server down with it (nohup only covers SIGHUP). setsid gives everything below its own session.
[ -n "$OMP_DETACHED" ] || OMP_DETACHED=1 exec setsid "$0" "$@"
termux-wake-lock   # first: keeps TermuxService (and this script) alive when launched from Termux:Widget
# Bring Termux:X11 up front. Works from the Termux app or ssh; from Termux:Widget ColorOS blocks it
# (BAL_BLOCK in logcat), so after Desktop Start the user taps the Termux:X11 icon.
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1
"$(dirname "$0")/stop.sh" --restart
. ~/.config/omarchy-pad/env 2>/dev/null
# X renders at OMP_SCALE % of the native 3392x2400 and Termux:X11 upscales it. Every frame kitty draws is
# copied through the X server, so pixels = latency: per typed key the X server cost ~17ms at 100%,
# ~10ms at 75%, ~6ms at 50%. Lower = snappier, softer text. DPI follows so sizes stay the same.
OMP_SCALE="${OMP_SCALE:-75}"
export OMP_DPI=$((240 * OMP_SCALE / 100)) OMP_SCALE
export DISPLAY=:0 XDG_RUNTIME_DIR="$TMPDIR/runtime"
mkdir -p -m 700 "$XDG_RUNTIME_DIR"
# GPU GL via zink (Adreno 830 / Turnip). kitty renders cleanly on it and uses ~9x less CPU than llvmpipe
# (300k-line test: 0.49s vs 4.25s). alacritty drew garbage on zink, which is why it was dropped.
# Fallback if kitty ever fails to start: replace this line with  export LIBGL_ALWAYS_SOFTWARE=1
export MESA_LOADER_DRIVER_OVERRIDE=zink GALLIUM_DRIVER=zink TU_DEBUG=noconform
# The default (fifo) X11 swapchain sometimes shows an older frame: typed text and IME preedit jumped back for a moment.
# mailbox had 0 backward frames in tests/frame-order.py (fifo: ~10 per 220 keys).
export MESA_VK_WSI_PRESENT_MODE=mailbox
export GDK_SCALE=2 GDK_DPI_SCALE=0.5   # GTK: 2x widgets; text already scaled by Xft.dpi, undo the 2x
# fcitx5 (自由大新): kitty only speaks IBus, which fcitx5 emulates; GTK uses its own module, others XIM
export GLFW_IM_MODULE=ibus GTK_IM_MODULE=fcitx QT_IM_MODULE=fcitx XMODIFIERS=@im=fcitx
rm -f ~/.config/ibus/bus/*   # stale address from the last fcitx5 would point kitty at a dead socket
nohup termux-x11 :0 -ac -noreset -xstartup "$HOME/.local/bin/omp-session" \
    >"$TMPDIR/omarchy-pad.log" 2>&1 &
# displayScale is the inverse (200 = half resolution); it only sticks while the X11 app is up, so retry
( for i in 1 2 3 4 5 6 7 8 9 10; do
      timeout 5 termux-x11-preference displayResolutionMode:scaled displayScale:$((10000 / OMP_SCALE)) >/dev/null 2>&1 && break
      sleep 1
  done ) &
"$(dirname "$0")/bin/omp-watermark" >/dev/null 2>&1 &
# Remote access while the desktop runs: sshd on 8022 (key-only); the wake lock above keeps Termux alive.
pgrep -x sshd >/dev/null || sshd
