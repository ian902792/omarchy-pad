#!/data/data/com.termux/files/usr/bin/bash
# One-tap launchers for the Termux:Widget app (separate app, install it yourself).
# Creates the scripts in BOTH places Termux:Widget reads:
#   ~/.shortcuts/tasks/                       -> the home-screen list widget (background tasks)
#   ~/.termux/widget/dynamic_shortcuts/       -> long-press the Termux:Widget app icon (verified on the OPPO Pad)
# After running this, open Termux:Widget and tap "CREATE SHORTCUTS" (dynamic shortcuts) and/or "REFRESH WIDGETS".
# Remove again with: install-shortcuts.sh --remove
set -euo pipefail
OMP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$OMP_ROOT/lib/common.sh"
require_termux_native

DIRS=("$HOME/.shortcuts/tasks" "$HOME/.termux/widget/dynamic_shortcuts")
NAMES=("Omarchy Start" "Omarchy Stop" "XFCE Start" "Omarchy Theme Toggle")

if [ "${1:-}" = "--remove" ]; then
    for d in "${DIRS[@]}"; do for n in "${NAMES[@]}"; do rm -f "$d/$n"; done; done
    info "removed omarchy shortcuts"; exit 0
fi

mk() {  # mk "Name" "command"
    for d in "${DIRS[@]}"; do
        mkdir -p "$d"
        printf '#!/data/data/com.termux/files/usr/bin/bash\n%s\n' "$2" > "$d/$1"
        chmod 700 "$d/$1"
    done
    info "shortcut: $1"
}
mk "Omarchy Start"        "exec bash \"$OMP_ROOT/start-omarchy.sh\" >> \"\$HOME/.omarchy-pad/logs/session.out\" 2>&1"
mk "Omarchy Stop"         "exec bash \"$OMP_ROOT/stop-omarchy.sh\""
mk "XFCE Start"           "exec bash \"$OMP_ROOT/start-xfce.sh\" >> \"\$HOME/.omarchy-pad/logs/session-xfce.out\" 2>&1"
mk "Omarchy Theme Toggle" "exec bash \"$OMP_ROOT/set-theme.sh\" toggle"
info "Next: open Termux:Widget -> CREATE SHORTCUTS, then long-press its icon (or add the Widget and tap REFRESH WIDGETS)."
