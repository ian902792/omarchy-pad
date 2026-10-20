#!/data/data/com.termux/files/usr/bin/bash
# Apply wallpaper / dark GTK / DPI-scaled sizes to a RUNNING XFCE session via xfconf.
# Needs the session D-Bus (start-xfce.sh runs this inside it). Safe to re-run (used by set-theme.sh).
OMP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$OMP_ROOT/lib/common.sh"
load_env
export DISPLAY="${DISPLAY:-:0}"

for _ in $(seq 1 40); do xfconf-query -c xsettings -l >/dev/null 2>&1 && break; sleep 1; done
xfconf-query -c xsettings -l >/dev/null 2>&1 || { warn "xfconf not reachable; XFCE theme not applied"; exit 0; }

xf() { xfconf-query -c "$1" -p "$2" -n -t "$3" -s "$4" >/dev/null 2>&1 || warn "xfconf set failed: $1 $2"; }

# GTK: dark Adwaita + our palette overrides (~/.config/gtk-3.0/gtk.css, rendered by render.sh)
xf xsettings /Net/ThemeName string Adwaita
xf xsettings /Gtk/ApplicationPreferDarkTheme bool true
xf xsettings /Net/IconThemeName string Adwaita
xf xsettings /Gtk/FontName string "Sans 11"
xf xsettings /Xft/DPI int "$OMP_DPI"
xf xsettings /Gtk/CursorThemeSize int "$((OMP_DPI / 4))"

# Sizes scaled from 96-dpi defaults
xf xfce4-panel /panels/panel-1/size uint "$((OMP_DPI * 36 / 96))"
for pn in $(xfconf-query -c xfce4-panel -l 2>/dev/null | sed -n 's|^/panels/\(panel-[0-9]*\)/size$|\1|p' | sort -u); do
    [ "$pn" = panel-1 ] || xf xfce4-panel "/panels/$pn/size" uint "$((OMP_DPI * 48 / 96))"
done
xf xfce4-desktop /desktop-icons/icon-size uint "$((OMP_DPI * 48 / 96))"
xf xfwm4 /general/title_font string "Sans Bold 11"

# Wallpaper on every monitor/workspace entry xfdesktop knows, plus the usual Termux:X11 output names
wp="$OMP_ROOT/themes/$OMP_THEME/wallpaper.png"
if [ -r "$wp" ]; then
    props=$(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep '/last-image$')
    for m in monitorscreen monitorbuiltin monitor0; do
        props="$props"$'\n'"/backdrop/screen0/$m/workspace0/last-image"
    done
    printf '%s\n' "$props" | sort -u | while read -r p; do
        [ -n "$p" ] || continue
        xf xfce4-desktop "$p" string "$wp"
        xf xfce4-desktop "${p%last-image}image-style" int 5
    done
fi
info "XFCE themed (theme=$OMP_THEME dpi=$OMP_DPI)"
