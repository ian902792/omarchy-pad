#!/data/data/com.termux/files/usr/bin/bash
# SoC temperature from thermal_zone0 (readable by Termux apps on this device).
# Usage: status-temp.sh        -> "36°C" (polybar)     status-temp.sh num -> "36" (eww)
# Prints nothing if the zone is unreadable (polybar hides the module; eww shows 0).
raw=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null) || { [ "${1:-}" = num ] && echo 0; exit 0; }
c=$(( raw / 1000 ))
if [ "${1:-}" = num ]; then echo "$c"; else echo "${c}°C"; fi
