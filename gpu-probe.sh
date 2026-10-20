#!/data/data/com.termux/files/usr/bin/bash
# Probe GL renderer under each GPU mode against the running Termux:X11 display.
# Usage: gpu-probe.sh   (start-omarchy.sh or start-xfce.sh must be running)
# Writes nothing to your config; to adopt a mode set OMP_GPU in ~/.config/omarchy-pad/env.
OMP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$OMP_ROOT/lib/common.sh"
export DISPLAY="${DISPLAY:-:0}"
xdpyinfo >/dev/null 2>&1 || die "no X display on $DISPLAY; start a session first"
command -v glxinfo >/dev/null 2>&1 || die "glxinfo missing (pkg install mesa-demos)"

for mode in llvmpipe zink; do
    echo "== OMP_GPU=$mode =="
    out=$( OMP_GPU=$mode; apply_gpu_env; timeout 40 glxinfo -B 2>&1 ); rc=$?
    echo "$out" | grep -E 'renderer string|OpenGL version|direct rendering|Error|error|failed' | head -6
    echo "exit=$rc"
done
echo "== Vulkan =="
if command -v vulkaninfo >/dev/null 2>&1; then
    timeout 40 vulkaninfo --summary 2>&1 | grep -E 'deviceName|driverName|apiVersion|ERROR' | head -8
else
    echo "vulkaninfo missing (pkg install vulkan-tools)"
fi
