#!/data/data/com.termux/files/usr/bin/bash
# Roll back omarchy-pad. Usage: rollback.sh [--backup DIR] [--xfce]
#   1. stops the bspwm desktop   2. snapshots the current state (pre-rollback)
#   3. restores managed configs from the ORIGINAL backup (or --backup DIR)
#   4. optionally starts the XFCE fallback (--xfce)
# NOT touched: user files, installed packages (listed only), Android settings,
# ~/start-x11.sh and other DroidDesk launchers, ~/.omarchy-pad logs/backups.
set -euo pipefail
OMP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$OMP_ROOT/lib/common.sh"
require_termux_native

backup=""; to_xfce=0
while [ $# -gt 0 ]; do
    case "$1" in
        --backup) backup="$2"; shift 2;;
        --xfce) to_xfce=1; shift;;
        *) die "unknown option $1";;
    esac
done
[ -n "$backup" ] || { [ -r "$OMP_BACKUP_DIR/ORIGINAL" ] && backup="$(cat "$OMP_BACKUP_DIR/ORIGINAL")"; }
[ -n "$backup" ] && [ -d "$backup" ] || die "no backup found (run backup.sh first, or pass --backup DIR)"
[ -r "$backup/absent.txt" ] || die "$backup is not a valid omarchy-pad backup"

info "rolling back to $backup"
"$OMP_ROOT/stop-omarchy.sh" || warn "stop-omarchy.sh reported a problem; continuing"
"$OMP_ROOT/backup.sh" pre-rollback

# Remove only the paths this project manages, then restore what existed originally.
for p in "${OMP_MANAGED_PATHS[@]}"; do
    case "$p" in ""|/*|*..*) die "refusing unsafe managed path '$p'";; esac
    rm -rf "${HOME:?}/$p"
done
if [ -r "$backup/configs.tar" ]; then
    tar -C "$HOME" -xf "$backup/configs.tar"
    info "restored configs from $backup/configs.tar"
else
    info "original state had none of the managed paths; they are now removed"
fi
"$OMP_ROOT/scripts/x11-prefs.sh" restore "$backup/x11-prefs.txt"

if [ -r "$OMP_STATE/installed-packages.txt" ]; then
    info "$(wc -l < "$OMP_STATE/installed-packages.txt") packages added since the original state are KEPT (shared deps may be used by other tools)."
    info "list: $OMP_STATE/installed-packages.txt   -- remove selectively with: pkg uninstall <name>"
fi
info "rollback done"

if [ "$to_xfce" = 1 ]; then
    exec "$OMP_ROOT/start-xfce.sh"
fi
