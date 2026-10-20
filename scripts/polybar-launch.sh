#!/data/data/com.termux/files/usr/bin/bash
# (Re)start polybar. Log: ~/.omarchy-pad/logs/polybar.log
export DISPLAY="${DISPLAY:-:0}"
LOG="$HOME/.omarchy-pad/logs/polybar.log"
# Termux has no /tmp; bspwm's socket lives in $TMPDIR and polybar must be told (BSPWM_SOCKET).
export BSPWM_SOCKET="${TMPDIR:-${PREFIX:-/data/data/com.termux/files/usr}/tmp}/bspwm_0_0-socket"
mkdir -p "$(dirname "$LOG")"
pkill -x polybar 2>/dev/null
for _ in 1 2 3 4 5 6 7 8 9 10; do pgrep -x polybar >/dev/null || break; sleep 0.2; done
polybar --config="$HOME/.config/polybar/config.ini" main >>"$LOG" 2>&1 &
