#!/data/data/com.termux/files/usr/bin/bash
# omarchy-pad health check. Usage: doctor.sh
# PASS = actually exercised and succeeded | FAIL = exercised and failed
# SKIP = prerequisite missing (e.g. X not running) | UNVERIFIED = needs a human / not exercised
# A static check (file exists, syntax ok) is labelled "static" and is NOT proof the graphical desktop works.
OMP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$OMP_ROOT/lib/common.sh"
load_env

npass=0; nfail=0; nskip=0; nunv=0
r() {   # r STATUS name detail
    printf '%-11s %-34s %s\n' "$1" "$2" "${3:-}"
    echo "$(_ts) $1 $2 ${3:-}" >> "$OMP_LOG_FILE"
    case "$1" in PASS) npass=$((npass+1));; FAIL) nfail=$((nfail+1));; SKIP) nskip=$((nskip+1));; *) nunv=$((nunv+1));; esac
}
export DISPLAY="${DISPLAY:-:0}"
XUP=0; xdpyinfo >/dev/null 2>&1 && XUP=1
XFCE_ACTIVE=0; pgrep -x xfce4-session >/dev/null 2>&1 && XFCE_ACTIVE=1

# --- 1. Linux userspace -------------------------------------------------------
if [ "${PREFIX:-}" = "$OMP_TERMUX_PREFIX" ] && [ "$(uname -m)" = "aarch64" ] && dpkg -s bspwm >/dev/null 2>&1; then
    r PASS "userspace (Termux native)" "$(uname -mo) bspwm $(dpkg-query -W -f='${Version}' bspwm)"
else
    r FAIL "userspace (Termux native)" "PREFIX='${PREFIX:-}' arch=$(uname -m) bspwm installed? no"
fi
missing=()
for b in bspwm bspc sxhkd polybar rofi feh xfce4-terminal git zsh starship xsetroot xrdb xdpyinfo glxinfo; do
    command -v "$b" >/dev/null 2>&1 || missing+=("$b")
done
[ "${#missing[@]}" -eq 0 ] && r PASS "required binaries" "all present" || r FAIL "required binaries" "missing: ${missing[*]}"

# --- 2. Themes / configs -------------------------------------------------------
bad=()
for d in "$OMP_ROOT"/themes/*/; do
    n=$(basename "$d")
    ( . "$d/colors.sh"
      for v in BG MANTLE SURFACE SURFACE1 FG SUBTEXT MUTED BLUE MAUVE GREEN RED YELLOW PEACH TEAL; do
          eval "val=\${$v:-}"; printf '%s' "$val" | grep -Eq '^#[0-9a-fA-F]{6}$' || exit 1
      done
      [ "$(printf '%s' "$PALETTE" | awk -F';' '{print NF}')" -eq 16 ] || exit 1 ) || bad+=("$n")
done
[ "${#bad[@]}" -eq 0 ] && r PASS "theme palettes valid" "$(ls "$OMP_ROOT/themes" | tr '\n' ' ')" || r FAIL "theme palettes valid" "invalid: ${bad[*]}"

cfgmiss=()
for f in .config/bspwm/bspwmrc .config/sxhkd/sxhkdrc .config/polybar/config.ini .config/rofi/config.rasi \
         .config/xfce4/terminal/terminalrc .config/gtk-3.0/settings.ini .Xresources .config/omarchy-pad/env; do
    [ -s "$HOME/$f" ] || cfgmiss+=("$f")
done
if [ "${#cfgmiss[@]}" -ne 0 ]; then
    r FAIL "rendered configs" "missing: ${cfgmiss[*]}"
elif grep -rlE '@[A-Z_0-9]+@' "$HOME/.config/bspwm" "$HOME/.config/sxhkd" "$HOME/.config/polybar" "$HOME/.config/rofi" >/dev/null 2>&1; then
    r FAIL "rendered configs" "unrendered @TOKEN@ present"
else
    r PASS "rendered configs" "theme=$OMP_THEME (static)"
fi
if rofi -no-config -config "$HOME/.config/rofi/config.rasi" -dump-config >/dev/null 2>&1 || rofi -config "$HOME/.config/rofi/config.rasi" -dump-config >/dev/null 2>&1; then
    r PASS "rofi config parses" "rofi -dump-config ok"
else
    r FAIL "rofi config parses" "rofi -dump-config failed"
fi

# --- 3. Script syntax ---------------------------------------------------------
synfail=()
for f in "$OMP_ROOT"/*.sh "$OMP_ROOT"/lib/*.sh "$OMP_ROOT"/scripts/*.sh; do bash -n "$f" 2>/dev/null || synfail+=("$(basename "$f")"); done
[ -r "$HOME/.config/bspwm/bspwmrc" ] && { sh -n "$HOME/.config/bspwm/bspwmrc" 2>/dev/null || synfail+=(bspwmrc); }
[ "${#synfail[@]}" -eq 0 ] && r PASS "script syntax" "bash -n / sh -n clean (static)" || r FAIL "script syntax" "${synfail[*]}"

# --- 4. X11 + live components -------------------------------------------------
if [ "$XUP" = 1 ]; then
    r PASS "X11 display $DISPLAY" "$(xdpyinfo 2>/dev/null | awk '/dimensions:/ {print $2}')"
else
    r SKIP "X11 display $DISPLAY" "Termux:X11 server not running (run start-omarchy.sh)"
fi
live() {  # live name process
    if [ "$XUP" = 0 ]; then r SKIP "$1" "X not running"
    elif [ "$XFCE_ACTIVE" = 1 ] && ! pgrep -x bspwm >/dev/null 2>&1; then r SKIP "$1" "XFCE session is active (bspwm checks apply to the bspwm session)"
    elif pgrep -x "$2" >/dev/null 2>&1; then r PASS "$1" "pid $(pgrep -x "$2" | head -1)"
    else r FAIL "$1" "$2 not running while X is up"; fi
}
live "window manager (bspwm)" bspwm
if [ "$XUP" = 1 ] && pgrep -x bspwm >/dev/null 2>&1; then
    n=$(bspc query -D 2>/dev/null | wc -l)
    [ "$n" -eq 6 ] && r PASS "6 virtual desktops" "bspc query -D = $n" || r FAIL "6 virtual desktops" "bspc query -D = $n"
else
    r SKIP "6 virtual desktops" "bspwm not running"
fi
live "hotkey daemon (sxhkd)" sxhkd
live "status bar (polybar)" polybar
if [ "$XUP" = 1 ] && pgrep -x polybar >/dev/null 2>&1; then
    if xprop -root _NET_CLIENT_LIST >/dev/null 2>&1 && ! tail -n 20 "$OMP_LOG_DIR/polybar.log" 2>/dev/null | grep -qiE 'error|cannot|failed'; then
        r PASS "polybar log clean" "no errors in last 20 lines"
    else
        r FAIL "polybar log clean" "see $OMP_LOG_DIR/polybar.log"
    fi
fi

launch_test() {  # launch_test name cmd... : start, expect process alive after 2s, kill
    local name="$1" proc="$2"; shift 2
    if [ "$XUP" = 0 ]; then r SKIP "$name" "X not running"; return; fi
    "$@" >/dev/null 2>&1 &
    sleep 2.5
    if pgrep -x "$proc" >/dev/null 2>&1; then r PASS "$name" "$proc started and stayed up 2.5s"; pkill -x "$proc"
    else r FAIL "$name" "$proc did not start / exited"; fi
}
launch_test "launcher (rofi)" rofi rofi -show drun
launch_test "terminal (xfce4-terminal)" xfce4-terminal xfce4-terminal --disable-server -e "sleep 5"

# --- 5. GPU -------------------------------------------------------------------
if [ "$XUP" = 1 ] && command -v glxinfo >/dev/null 2>&1; then
    ( apply_gpu_env; glxinfo -B 2>&1 ) > "$OMP_LOG_DIR/glxinfo.txt"
    rend=$(awk -F': ' '/OpenGL renderer string/ {print $2}' "$OMP_LOG_DIR/glxinfo.txt")
    if [ -z "$rend" ]; then r FAIL "OpenGL renderer ($OMP_GPU)" "glxinfo failed: $(head -1 "$OMP_LOG_DIR/glxinfo.txt")"
    elif [ "$OMP_GPU" = zink ] && ! printf '%s' "$rend" | grep -qiE 'zink|turnip|adreno'; then
        r FAIL "OpenGL renderer ($OMP_GPU)" "$rend (wanted Zink/Turnip)"
    else r PASS "OpenGL renderer ($OMP_GPU)" "$rend"; fi
else
    r SKIP "OpenGL renderer" "X not running or glxinfo missing"
fi

# --- 6. XFCE fallback ---------------------------------------------------------
if command -v startxfce4 >/dev/null 2>&1 && bash -n "$OMP_ROOT/start-xfce.sh" 2>/dev/null; then
    r PASS "XFCE fallback installed" "startxfce4 + start-xfce.sh (static)"
else
    r FAIL "XFCE fallback installed" "startxfce4 or start-xfce.sh missing/invalid"
fi
if pgrep -x xfce4-session >/dev/null 2>&1; then r PASS "XFCE session live" "xfce4-session running"
else r UNVERIFIED "XFCE session live" "not running now; run start-xfce.sh and re-run doctor"; fi

# --- 7. Needs a human ---------------------------------------------------------
r UNVERIFIED "touch / right-click gestures" "manual: see README 'Manual checks'"
r UNVERIFIED "modifier key ($OMP_MOD) on real keyboard" "manual: press $OMP_MOD+Return on your Bluetooth keyboard (Super was captured by ColorOS in an injected-key test)"
r UNVERIFIED "Chinese input (IME)" "no IME installed by this project"
r UNVERIFIED "visual layout / theme look" "manual: needs eyes on the screen"

echo
echo "summary: PASS=$npass FAIL=$nfail SKIP=$nskip UNVERIFIED=$nunv   (log: $OMP_LOG_FILE)"
[ "$nfail" -eq 0 ]
