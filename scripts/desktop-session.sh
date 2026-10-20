#!/data/data/com.termux/files/usr/bin/bash
# The "Desktop" session body (macOS-like): xfwm4 (floating windows) + picom (rounded/shadows/translucency)
# + polybar menu bar + Plank dock + eww widgets + wallpaper. Runs INSIDE the D-Bus session started by start-desktop.sh.
# The session lives as long as xfwm4 does.
OMP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$OMP_ROOT/lib/common.sh"
load_env
export DISPLAY="${DISPLAY:-:0}"
LOGS="$OMP_LOG_DIR"

xrdb -merge "$HOME/.Xresources" 2>/dev/null
xsetroot -cursor_name left_ptr 2>/dev/null

xfsettingsd >>"$LOGS/xfsettingsd.log" 2>&1 &
xfwm4 --compositor=off --replace >>"$LOGS/xfwm4.log" 2>&1 &
WM=$!
sleep 1.5
"$OMP_ROOT/scripts/gtk-settings.sh" >>"$LOGS/gtk-settings.log" 2>&1 &
picom --config "$HOME/.config/picom/picom.conf" >>"$LOGS/picom.log" 2>&1 &
"$OMP_ROOT/scripts/wallpaper.sh" &
"$OMP_ROOT/scripts/polybar-launch.sh" mac
"$OMP_ROOT/scripts/plank-setup.sh" >>"$LOGS/plank-setup.log" 2>&1
plank >>"$LOGS/plank.log" 2>&1 &
( eww daemon >>"$LOGS/eww.log" 2>&1 &
  sleep 2
  eww open clock >>"$LOGS/eww.log" 2>&1
  eww open stats >>"$LOGS/eww.log" 2>&1
  "$OMP_ROOT/scripts/eww-pin.sh" ) &

info "desktop session up (xfwm4 pid $WM)"
wait "$WM"
