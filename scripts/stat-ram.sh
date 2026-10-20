#!/data/data/com.termux/files/usr/bin/bash
# RAM usage from /proc/meminfo (readable by Termux apps). Usage: stat-ram.sh pct | text
awk -v mode="${1:-pct}" '
    /^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2}
    END {
        if (t == 0) exit 0
        u = t - a
        if (mode == "text") printf "%.1f / %.1f GB\n", u/1048576, t/1048576
        else printf "%d\n", u * 100 / t
    }' /proc/meminfo
