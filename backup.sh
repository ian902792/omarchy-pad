#!/data/data/com.termux/files/usr/bin/bash
# Snapshot every config path omarchy-pad manages. Usage: backup.sh [label]
# Output: ~/.omarchy-pad/backups/<timestamp>[-label]/{configs.tar,absent.txt,dpkg.txt,x11-prefs.txt}
# The FIRST backup ever taken is recorded as ORIGINAL (pre-install state) and is what rollback restores.
set -euo pipefail
OMP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$OMP_ROOT/lib/common.sh"
require_termux_native

label="${1:-}"
base="$OMP_BACKUP_DIR/$(date +%Y%m%d-%H%M%S)${label:+-$label}"
dir="$base"; n=0
# Never reuse an existing snapshot directory (same-second backups would overwrite ORIGINAL).
until mkdir "$dir" 2>/dev/null; do n=$((n + 1)); dir="$base-$n"; done

present=(); : > "$dir/absent.txt"
for p in "${OMP_MANAGED_PATHS[@]}"; do
    if [ -L "$HOME/$p" ]; then
        rm -rf "$dir"
        die "$HOME/$p is a symlink; refusing to manage it (tar would save only the link and render would overwrite its target). Replace it with a real path or move it away."
    elif [ -e "$HOME/$p" ]; then present+=("$p"); else echo "$p" >> "$dir/absent.txt"; fi
done
if [ "${#present[@]}" -gt 0 ]; then
    tar -C "$HOME" -cf "$dir/configs.tar" "${present[@]}"
    tar -tf "$dir/configs.tar" >/dev/null   # verify the archive is readable
else
    : > "$dir/configs.tar.empty"
fi
dpkg-query -W -f='${Package} ${Version}\n' > "$dir/dpkg.txt"
"$OMP_ROOT/scripts/x11-prefs.sh" save "$dir/x11-prefs.txt"
echo "$dir" > "$OMP_BACKUP_DIR/LATEST"
[ -e "$OMP_BACKUP_DIR/ORIGINAL" ] || { echo "$dir" > "$OMP_BACKUP_DIR/ORIGINAL"; info "recorded as ORIGINAL"; }
info "backup complete: $dir (existing: ${#present[@]}, absent: $(wc -l < "$dir/absent.txt"))"
