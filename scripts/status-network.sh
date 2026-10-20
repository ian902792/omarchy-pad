#!/data/data/com.termux/files/usr/bin/bash
# Print a connectivity hint if the kernel exposes an up interface to this app; else print nothing.
# Android (untrusted_app SELinux domain) often hides netlink/sysfs data, so this is best-effort.
for i in /sys/class/net/*; do
    n=$(basename "$i")
    case "$n" in lo|dummy*|sit*|ip6*|tun*) continue;; esac
    st=$(cat "$i/operstate" 2>/dev/null)
    if [ "$st" = "up" ]; then
        case "$n" in wlan*) echo "WiFi";; rmnet*|ccmni*) echo "Mobile";; *) echo "NET $n";; esac
        exit 0
    fi
done
exit 0
