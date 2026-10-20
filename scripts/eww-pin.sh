#!/data/data/com.termux/files/usr/bin/bash
# Make eww widget windows behave like desktop widgets under xfwm4: no decorations, always below
# other windows, on all workspaces, hidden from taskbar/pager, and placed at their configured spot
# (xfwm4 ignores the position hints of normal windows; wm-ignore would keep them ABOVE windows).
OMP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$OMP_ROOT/lib/common.sh"
load_env
export DISPLAY="${DISPLAY:-:0}"
s() { echo $(( $1 * OMP_DPI / 96 )); }   # 96-dpi px -> real px

# window name -> x y (96-dpi px); keep in sync with configs/eww/eww.yuck.tpl
place() {
    local id
    for _ in 1 2 3 4 5 6 7 8; do
        id=$(xdotool search --name "^Eww - $1\$" 2>/dev/null | head -1)
        [ -n "$id" ] && break
        sleep 1
    done
    [ -n "$id" ] || { warn "eww window '$1' not found"; return; }
    xprop -id "$id" -f _MOTIF_WM_HINTS 32c -set _MOTIF_WM_HINTS "2, 0, 0, 0, 0" 2>/dev/null
    xprop -id "$id" -f WM_HINTS 32c -set WM_HINTS "1, 0, 0, 0, 0, 0, 0, 0, 0" 2>/dev/null   # never take focus
    wmctrl -i -r "$id" -b add,below,sticky,skip_taskbar,skip_pager 2>/dev/null
    xdotool windowmove "$id" "$(s "$2")" "$(s "$3")"
    # blank title so the menu bar's active-window label never shows "Eww - ..." (eww windows get focus on map)
    xdotool set_window --name " " "$id"
}
place clock 40 70
place stats 40 250
