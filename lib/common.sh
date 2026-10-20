#!/data/data/com.termux/files/usr/bin/bash
# omarchy-pad shared helpers. Source this file; do not execute it.
# Environment: Termux native shell only (NOT Android adb shell, NOT proot).

OMP_TERMUX_PREFIX="/data/data/com.termux/files/usr"
OMP_ROOT="${OMP_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
OMP_STATE="${OMP_STATE:-$HOME/.omarchy-pad}"
OMP_LOG_DIR="$OMP_STATE/logs"
OMP_BACKUP_DIR="$OMP_STATE/backups"
OMP_CFG="$HOME/.config/omarchy-pad"
OMP_ENV_FILE="$OMP_CFG/env"
OMP_LOG_FILE="${OMP_LOG_FILE:-$OMP_LOG_DIR/$(basename "${0:-omp}" .sh).log}"

# Config locations this project manages (relative to $HOME). Used by backup/rollback.
OMP_MANAGED_PATHS=(
    .config/bspwm
    .config/sxhkd
    .config/polybar
    .config/rofi
    .config/gtk-3.0
    .config/xfce4/terminal
    .config/omarchy-pad
    .config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
    .config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
    .Xresources
)

mkdir -p "$OMP_LOG_DIR" "$OMP_BACKUP_DIR" 2>/dev/null

_ts() { date '+%Y-%m-%d %H:%M:%S'; }

log() {   # log LEVEL message...   (stdout + log file)
    local lvl="$1"; shift
    printf '%s [%s] %s\n' "$(_ts)" "$lvl" "$*" | tee -a "$OMP_LOG_FILE" >&2
}
info() { log INFO "$@"; }
warn() { log WARN "$@"; }
die()  { log ERROR "$@"; exit 1; }

# Refuse to run outside Termux native (different package managers / paths / permissions).
require_termux_native() {
    [ "${PREFIX:-}" = "$OMP_TERMUX_PREFIX" ] || die "PREFIX is '${PREFIX:-unset}', expected $OMP_TERMUX_PREFIX. Run inside the Termux native shell (not adb shell, not proot)."
    [ -x "$PREFIX/bin/apt-get" ] || die "apt-get not found under $PREFIX/bin"
    [ -r /proc/self/exe ] || true
    if [ -e /etc/os-release ] && grep -qiE 'ubuntu|debian|arch' /etc/os-release 2>/dev/null; then
        die "Looks like a proot distro (/etc/os-release). Run from the Termux native shell."
    fi
}

load_env() {
    [ -r "$OMP_ENV_FILE" ] && . "$OMP_ENV_FILE"
    : "${OMP_THEME:=catppuccin}" "${OMP_MOD:=alt}" "${OMP_DPI:=192}" \
      "${OMP_GPU:=llvmpipe}" "${OMP_TERMINAL:=xfce4-terminal}"
    export OMP_ROOT OMP_THEME OMP_MOD OMP_DPI OMP_GPU OMP_TERMINAL
}

# GPU environment per mode. Default llvmpipe = stable software GL.
# zink = Turnip (Adreno) via Vulkan; must be validated with gpu-probe.sh first.
apply_gpu_env() {
    case "${OMP_GPU:-llvmpipe}" in
        zink)
            export MESA_LOADER_DRIVER_OVERRIDE=zink GALLIUM_DRIVER=zink
            export TU_DEBUG=noconform ZINK_DESCRIPTORS=lazy MESA_VK_WSI_PRESENT_MODE=immediate
            ;;
        *)
            export LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe
            ;;
    esac
}

# Is a process with exact name running?
is_running() { pgrep -x "$1" >/dev/null 2>&1; }

# Start PulseAudio (best effort; desktop works without sound).
start_audio() {
    command -v pulseaudio >/dev/null 2>&1 || return 0
    pulseaudio --check 2>/dev/null && return 0
    pulseaudio --start --exit-idle-time=-1 2>>"$OMP_LOG_FILE" || warn "pulseaudio failed to start (no sound)"
    pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 >/dev/null 2>&1 || true
    export PULSE_SERVER=127.0.0.1
}

# Start the Termux:X11 server on :0 and wait for its socket. Dies on failure.
start_x11() {
    command -v termux-x11 >/dev/null 2>&1 || die "termux-x11 not installed (run install.sh)"
    local sock="${TMPDIR:-$PREFIX/tmp}/.X11-unix/X0"
    if [ ! -S "$sock" ] || ! pgrep -f 'termux-x11 com.termux.x11' >/dev/null 2>&1; then
        rm -f "$sock" "${TMPDIR:-$PREFIX/tmp}/.X0-lock" 2>/dev/null
        nohup termux-x11 :0 -ac >>"$OMP_LOG_DIR/termux-x11.log" 2>&1 &
        local i
        for i in $(seq 1 60); do [ -S "$sock" ] && break; sleep 0.25; done
        [ -S "$sock" ] || die "X socket $sock did not appear; see $OMP_LOG_DIR/termux-x11.log"
    fi
    export DISPLAY=:0
    # Bring the Termux:X11 app to the front (best effort).
    am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || true
    # Prefs can only be set while the X11 app/server is up; landscape applies on the next surface change.
    "$OMP_ROOT/scripts/x11-prefs.sh" apply >/dev/null 2>&1 || true
}
