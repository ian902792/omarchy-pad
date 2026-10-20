#!/data/data/com.termux/files/usr/bin/bash
# Snapshot every config path omarchy-pad manages. Usage: backup.sh [label]
# Output: ~/.omarchy-pad/backups/<timestamp>[-label]/{configs.tar,absent.txt,dpkg.txt}
# The FIRST backup ever taken is recorded as ORIGINAL (pre-install state) and is what rollback restores.
set -euo pipefail
OMP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$OMP_ROOT/lib/common.sh"
require_termux_native

label="${1:-}"
dir="$OMP_BACKUP_DIR/$(date +%Y%m%d-%H%M%S)${label:+-$label}"
mkdir -p "$dir"

present=(); : > "$dir/absent.txt"
for p in "${OMP_MANAGED_PATHS[@]}"; do
    if [ -e "$HOME/$p" ] || [ -L "$HOME/$p" ]; then present+=("$p"); else echo "$p" >> "$dir/absent.txt"; fi
done
if [ "${#present[@]}" -gt 0 ]; then
    tar -C "$HOME" -cf "$dir/configs.tar" "${present[@]}"
else
    : > "$dir/configs.tar.empty"
fi
dpkg-query -W -f='${Package} ${Version}\n' > "$dir/dpkg.txt"
"$OMP_ROOT/scripts/x11-prefs.sh" save "$dir/x11-prefs.txt"
echo "$dir" > "$OMP_BACKUP_DIR/LATEST"
[ -e "$OMP_BACKUP_DIR/ORIGINAL" ] || { echo "$dir" > "$OMP_BACKUP_DIR/ORIGINAL"; info "recorded as ORIGINAL"; }
info "backup complete: $dir (existing: ${#present[@]}, absent: $(wc -l < "$dir/absent.txt"))"
