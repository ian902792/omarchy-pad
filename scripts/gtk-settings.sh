#!/data/data/com.termux/files/usr/bin/bash
# GTK / xfwm4 look via xfconf (needs xfsettingsd + the session D-Bus). Shared by Desktop and XFCE sessions.
OMP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$OMP_ROOT/lib/common.sh"
load_env

for _ in $(seq 1 40); do xfconf-query -c xsettings -l >/dev/null 2>&1 && break; sleep 1; done
xfconf-query -c xsettings -l >/dev/null 2>&1 || { warn "xfconf not reachable; GTK settings not applied"; exit 0; }
xf() { xfconf-query -c "$1" -p "$2" -n -t "$3" -s "$4" >/dev/null 2>&1 || warn "xfconf set failed: $1 $2"; }

icons=Adwaita
[ -d "$PREFIX/share/icons/Papirus-Dark" ] && icons=Papirus-Dark
xf xsettings /Net/ThemeName string Adwaita
xf xsettings /Gtk/ApplicationPreferDarkTheme bool true
xf xsettings /Net/IconThemeName string "$icons"
xf xsettings /Gtk/FontName string "Sans 11"
xf xsettings /Xft/DPI int "$OMP_DPI"
xf xsettings /Gtk/CursorThemeSize int "$((OMP_DPI / 4))"

# Window manager: hi-dpi decoration theme, macOS-style buttons on the left, centred title.
# Compositing is done by picom (rounded corners/shadows), so xfwm4's own is off.
wmtheme=Default
if [ "$OMP_DPI" -ge 168 ] && [ -d "$PREFIX/share/themes/Default-xhdpi" ]; then wmtheme=Default-xhdpi
elif [ "$OMP_DPI" -ge 120 ] && [ -d "$PREFIX/share/themes/Default-hdpi" ]; then wmtheme=Default-hdpi; fi
xf xfwm4 /general/theme string "$wmtheme"
xf xfwm4 /general/button_layout string "CHM|"
xf xfwm4 /general/title_alignment string center
xf xfwm4 /general/title_font string "Sans Bold 11"
xf xfwm4 /general/use_compositing bool false
xf xfwm4 /general/placement_mode string center

# xfce4-terminal >= 1.0 reads xfconf (terminalrc is only imported once), so theme/borders must be set here.
. "$OMP_ROOT/themes/$OMP_THEME/colors.sh"
xf xfce4-terminal /misc-borders-default bool true
xf xfce4-terminal /misc-menubar-default bool false
xf xfce4-terminal /font-name string "Monospace 12"
xf xfce4-terminal /color-foreground string "$FG"
xf xfce4-terminal /color-background string "$BG"
xf xfce4-terminal /color-cursor string "$MAUVE"
xf xfce4-terminal /color-palette string "$PALETTE"
xf xfce4-terminal /color-bold-use-default bool true
info "GTK/xfwm4 settings applied (icons=$icons wm-theme=$wmtheme dpi=$OMP_DPI)"
