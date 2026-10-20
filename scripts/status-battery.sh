#!/data/data/com.termux/files/usr/bin/bash
# Print battery % if a readable source exists; print nothing otherwise (polybar hides the module).
# Sources tried in order: Linux sysfs, Termux:API (termux-battery-status, needs the Termux:API app).
for f in /sys/class/power_supply/battery/capacity /sys/class/power_supply/BAT0/capacity; do
    if [ -r "$f" ]; then
        pct=$(cat "$f" 2>/dev/null) && [ -n "$pct" ] && { echo "BAT ${pct}%"; exit 0; }
    fi
done
if command -v termux-battery-status >/dev/null 2>&1; then
    out=$(timeout 3 termux-battery-status 2>/dev/null) || exit 0
    pct=$(printf '%s' "$out" | sed -n 's/.*"percentage": *\([0-9]*\).*/\1/p')
    [ -n "$pct" ] && echo "BAT ${pct}%"
fi
exit 0
