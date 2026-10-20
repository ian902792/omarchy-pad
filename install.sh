#!/data/data/com.termux/files/usr/bin/bash
# omarchy-pad installer. Idempotent. Run in the Termux NATIVE shell (keep Termux in the foreground:
# ColorOS blocks network for background apps).
#   install.sh [--no-xfce] [--no-gpu]
#
# Order: detect env -> verify packages exist -> backup -> install packages (record new ones)
#        -> write env file (kept if present) -> render configs -> static validation.
# Any failure in a step aborts the later steps that depend on it (set -e).
set -euo pipefail
OMP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$OMP_ROOT/lib/common.sh"

want_xfce=1; want_gpu=1
for a in "$@"; do
    case "$a" in
        --no-xfce) want_xfce=0;;
        --no-gpu) want_gpu=0;;
        *) die "unknown option $a";;
    esac
done

# Packages by role. No versions are pinned: apt picks the current Termux build.
CORE_PKGS=(x11-repo termux-x11-nightly bspwm sxhkd polybar rofi feh xfce4-terminal git zsh starship
           xorg-xsetroot xorg-xrdb xorg-xrandr xorg-xdpyinfo xorg-xprop xdotool wmctrl
           procps dbus pulseaudio fontconfig-utils ttf-nerd-fonts-symbols otf-noto-sans-cjk
           adwaita-icon-theme)
XFCE_PKGS=(xfce4)
# vulkan-loader-android conflicts with vulkan-loader-generic (pulled in by mesa); the generic loader
# + freedreno ICD is the combination used here. Zink/Turnip is validated by gpu-probe.sh, not assumed.
GPU_PKGS=(mesa mesa-vulkan-icd-freedreno mesa-demos vulkan-tools)

step() { info "=== $* ==="; }

step "1/7 environment"
require_termux_native
info "arch=$(uname -m) android=$(getprop ro.build.version.release 2>/dev/null || echo ?) model=$(getprop ro.product.model 2>/dev/null || echo ?)"
[ "$(uname -m)" = "aarch64" ] || die "expected aarch64, got $(uname -m)"
if ! curl -fsS -m 10 -o /dev/null https://packages.termux.dev/apt/termux-main/dists/stable/InRelease; then
    die "cannot reach packages.termux.dev. Keep Termux in the foreground (ColorOS blocks background network) and check Wi-Fi."
fi

step "2/7 backup"
"$OMP_ROOT/backup.sh" pre-install

step "3/7 package availability"
export DEBIAN_FRONTEND=noninteractive
# x11-repo carries bspwm/polybar/...; it must be enabled before the package lists are refreshed.
if ! pkg_ok x11-repo; then
    apt-get install -y -q x11-repo >>"$OMP_LOG_FILE" 2>&1 || die "could not install x11-repo (see $OMP_LOG_FILE)"
fi
apt-get update -q >>"$OMP_LOG_FILE" 2>&1 || die "apt-get update failed (see $OMP_LOG_FILE)"
wanted=("${CORE_PKGS[@]}")
[ "$want_xfce" = 1 ] && wanted+=("${XFCE_PKGS[@]}")
[ "$want_gpu" = 1 ] && wanted+=("${GPU_PKGS[@]}")
missing=()
for p in "${wanted[@]}"; do
    cand=$(apt-cache policy "$p" 2>/dev/null | awk '/Candidate:/ {print $2}')
    if [ -z "$cand" ] || [ "$cand" = "(none)" ]; then missing+=("$p"); else info "available: $p $cand"; fi
done
[ "${#missing[@]}" -eq 0 ] || die "packages missing from Termux repos: ${missing[*]}"

step "4/7 packages"
mkdir -p "$OMP_STATE"
# Packages added since the ORIGINAL backup (pre-install state), recorded even if a later step fails.
record_new() {
    local orig; orig="$(cat "$OMP_BACKUP_DIR/ORIGINAL")/dpkg.txt"
    [ -r "$orig" ] || return 0
    comm -13 <(cut -d' ' -f1 "$orig" | sort) <(dpkg-query -W -f='${Package}\n' | sort) > "$OMP_STATE/installed-packages.txt"
}
trap record_new EXIT
install_group() {
    local name="$1"; shift
    local todo=()
    for p in "$@"; do pkg_ok "$p" || todo+=("$p"); done
    if [ "${#todo[@]}" -eq 0 ]; then info "$name: all installed"; return 0; fi
    info "$name: installing ${todo[*]}"
    apt-get install -y -q -o Dpkg::Options::=--force-confold "${todo[@]}" >>"$OMP_LOG_FILE" 2>&1 \
        || die "$name: apt-get install failed (see $OMP_LOG_FILE)"
}
install_group core "${CORE_PKGS[@]}"
[ "$want_xfce" = 1 ] && install_group xfce "${XFCE_PKGS[@]}"
[ "$want_gpu" = 1 ] && install_group gpu "${GPU_PKGS[@]}"
record_new
info "packages added since the ORIGINAL backup: $(wc -l < "$OMP_STATE/installed-packages.txt") (list: $OMP_STATE/installed-packages.txt)"
for p in "${wanted[@]}"; do
    info "installed: $p $(dpkg-query -W -f='${Version}' "$p" 2>/dev/null)"
done

step "5/7 env file"
mkdir -p "$OMP_CFG"
if [ -e "$OMP_ENV_FILE" ]; then
    info "keeping existing $OMP_ENV_FILE"
    grep -q '^OMP_ROOT=' "$OMP_ENV_FILE" && sed -i "s|^OMP_ROOT=.*|OMP_ROOT=$OMP_ROOT|" "$OMP_ENV_FILE" || echo "OMP_ROOT=$OMP_ROOT" >> "$OMP_ENV_FILE"
else
    cat > "$OMP_ENV_FILE" <<EOF
# omarchy-pad settings (kept across reinstalls). Re-render after editing: $OMP_ROOT/render.sh
OMP_ROOT=$OMP_ROOT
OMP_THEME=catppuccin
# alt is the default: on the OPPO Pad (ColorOS 16) an injected Super/Meta key press was taken by the
# Android launcher (went Home) and never reached X11. Set super to retry with your keyboard.
OMP_MOD=alt
# Xft.dpi. 13.2" 3392x2400 panel is ~315 ppi; 192 = 2x scale. Lower (144) for more screen space.
OMP_DPI=192
# llvmpipe = stable software GL (default). zink = Turnip/Vulkan; validate with gpu-probe.sh first.
OMP_GPU=llvmpipe
OMP_TERMINAL=xfce4-terminal
EOF
fi

step "6/7 render configs"
"$OMP_ROOT/render.sh"
"$OMP_ROOT/scripts/x11-prefs.sh" apply

step "7/7 static validation"
for f in "$OMP_ROOT"/*.sh "$OMP_ROOT"/lib/*.sh "$OMP_ROOT"/scripts/*.sh; do
    bash -n "$f" || die "syntax error in $f"
done
sh -n "$HOME/.config/bspwm/bspwmrc" || die "bspwmrc syntax error"
info "install finished OK. Start: $OMP_ROOT/start-omarchy.sh   Check: $OMP_ROOT/doctor.sh"
