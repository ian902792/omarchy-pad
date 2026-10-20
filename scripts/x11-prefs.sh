#!/data/data/com.termux/files/usr/bin/bash
# Termux:X11 app preferences (app settings only; no Android system settings are changed).
#   x11-prefs.sh save FILE      dump current prefs to FILE (used by backup.sh)
#   x11-prefs.sh apply          force landscape for the tablet (failure is a warning, not fatal)
#   x11-prefs.sh restore FILE   put back the values apply changed, from a saved dump
OMP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$OMP_ROOT/lib/common.sh"
command -v termux-x11-preference >/dev/null 2>&1 || { warn "termux-x11-preference not available; skipping"; exit 0; }

# keys touched by apply (kept in sync with restore)
KEYS=(forceOrientation)

case "${1:-}" in
    save)
        termux-x11-preference list > "$2" 2>/dev/null || : > "$2" ;;
    apply)
        if termux-x11-preference forceOrientation:landscape >/dev/null 2>&1; then
            info "Termux:X11 forceOrientation=landscape"
        else
            warn "could not set Termux:X11 forceOrientation (app installed/running?); rotate the tablet manually"
        fi ;;
    restore)
        [ -s "${2:-}" ] || { warn "no saved Termux:X11 prefs to restore"; exit 0; }
        for k in "${KEYS[@]}"; do
            v=$(sed -n "s/^\"$k\"=\"\(.*\)\"\$/\1/p" "$2")
            if [ -n "$v" ] && termux-x11-preference "$k:$v" >/dev/null 2>&1; then
                info "Termux:X11 $k restored to $v"
            else
                warn "could not restore Termux:X11 $k"
            fi
        done ;;
    *) echo "usage: $0 save FILE | apply | restore FILE"; exit 2 ;;
esac
exit 0
