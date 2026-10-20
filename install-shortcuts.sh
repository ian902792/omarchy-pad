#!/data/data/com.termux/files/usr/bin/bash
# Create one-tap launchers for the Termux:Widget app (separate app, must be installed by you):
#   ~/.shortcuts/tasks/*   run in the background (no terminal window pops up)
# Remove them again with: install-shortcuts.sh --remove
set -euo pipefail
OMP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$OMP_ROOT/lib/common.sh"
require_termux_native

DIR="$HOME/.shortcuts/tasks"
NAMES=("Omarchy Start" "Omarchy Stop" "XFCE Start" "Omarchy Theme Toggle")

if [ "${1:-}" = "--remove" ]; then
    for n in "${NAMES[@]}"; do rm -f "$DIR/$n"; done
    info "removed omarchy shortcuts"; exit 0
fi

mkdir -p "$DIR"
# Termux:Widget ignores shortcuts when these directories are group/world-writable.
chmod 700 "$HOME/.shortcuts" "$DIR"
mk() {  # mk "Name" "command"
    printf '#!/data/data/com.termux/files/usr/bin/bash\n%s\n' "$2" > "$DIR/$1"
    chmod 700 "$DIR/$1"
    info "shortcut: $1"
}
mk "Omarchy Start"        "exec bash \"$OMP_ROOT/start-omarchy.sh\" >> \"\$HOME/.omarchy-pad/logs/session.out\" 2>&1"
mk "Omarchy Stop"         "exec bash \"$OMP_ROOT/stop-omarchy.sh\""
mk "XFCE Start"           "exec bash \"$OMP_ROOT/start-xfce.sh\" >> \"\$HOME/.omarchy-pad/logs/session-xfce.out\" 2>&1"
mk "Omarchy Theme Toggle" "exec bash \"$OMP_ROOT/set-theme.sh\" toggle"
info "Now install Termux:Widget (same source/signature as your Termux) and add its widget to the home screen."
