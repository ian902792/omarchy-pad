#!/data/data/com.termux/files/usr/bin/bash
# Set root background: themes/<theme>/wallpaper.png via feh if present, else a solid theme colour.
OMP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$OMP_ROOT/lib/common.sh"
load_env
. "$OMP_ROOT/themes/$OMP_THEME/colors.sh"
export DISPLAY="${DISPLAY:-:0}"
wp="$OMP_ROOT/themes/$OMP_THEME/wallpaper.png"
if [ -r "$wp" ] && command -v feh >/dev/null 2>&1; then
    feh --no-fehbg --bg-fill "$wp"
else
    xsetroot -solid "$BG"
fi
