#!/bin/bash
# Run on the Mac with the pad on USB: checks the Android-side settings this desktop needs and fixes the
# wrong ones (they live outside Termux, so install.sh can't). Safe to re-run; prints what it changed.
# Run it after a ColorOS update, an app reinstall, or when Super stops working / the desktop gets killed.
#   ./android-setup.sh          check + fix
#   ./android-setup.sh --check  only report
ADB="${ADB:-$(command -v adb || echo ~/Library/Android/sdk/platform-tools/adb)}"
CHECK=; [ "$1" = --check ] && CHECK=1
changed=0 bad=0

a() { "$ADB" shell "$@" | tr -d '\r'; }
report() {   # name, current, wanted, fix command...
    local name=$1 cur=$2 want=$3; shift 3
    if [ "$cur" = "$want" ]; then printf '  ok     %s\n' "$name"; return; fi
    bad=$((bad + 1))
    if [ -n "$CHECK" ]; then printf '  WRONG  %s (is "%s", want "%s")\n' "$name" "$cur" "$want"; return; fi
    "$@" >/dev/null && changed=$((changed + 1))
    printf '  FIXED  %s (was "%s")\n' "$name" "$cur"
}

"$ADB" get-state >/dev/null 2>&1 || { echo "No device: plug in the pad and allow USB debugging."; exit 1; }
echo "Device: $(a getprop ro.product.model), Android $(a getprop ro.build.version.release)"
for p in com.termux com.termux.x11 com.termux.widget com.termux.api; do
    a pm path "$p" | grep -q . || echo "  MISSING app $p (install from F-Droid / GitHub)"
done

echo "Keyboard: Termux:X11 KeyInterceptor (Super keys; without it the Android IME eats keys)"
ki=com.termux.x11/com.termux.x11.utils.KeyInterceptor
svcs=$(a settings get secure enabled_accessibility_services)
case ":$svcs:" in *":$ki:"*) has=yes ;; *) has=no ;; esac
want="$ki"; [ "$svcs" != null ] && [ -n "$svcs" ] && want="$svcs:$ki"   # keep other services
report "accessibility service" "$has" yes a settings put secure enabled_accessibility_services "$want"
report "accessibility enabled" "$(a settings get secure accessibility_enabled)" 1 \
    a settings put secure accessibility_enabled 1

echo "Phantom process killer (Android kills the whole desktop past 32 child processes)"
report "device_config sync" "$(a device_config get_sync_disabled_for_tests)" persistent \
    a device_config set_sync_disabled_for_tests persistent
report "max_phantom_processes" "$(a device_config get activity_manager max_phantom_processes)" 2147483647 \
    a device_config put activity_manager max_phantom_processes 2147483647
report "monitor phantom procs" "$(a settings get global settings_enable_monitor_phantom_procs)" false \
    a settings put global settings_enable_monitor_phantom_procs false

echo "Battery: exempt from Doze (background apps get frozen otherwise)"
idle=$(a dumpsys deviceidle whitelist)
for p in com.termux com.termux.x11 com.tailscale.ipn; do
    a pm path "$p" | grep -q . || continue
    case "$idle" in *",$p,"*) has=yes ;; *) has=no ;; esac
    report "$p" "$has" yes a dumpsys deviceidle whitelist +"$p"
done

echo "Termux:X11 preferences"
x11pref() { a am broadcast -a com.termux.x11.CHANGE_PREFERENCE -p com.termux.x11 "$@"; }
prefs=$(x11pref -e list null)
for kv in fullscreen:true hideCutout:true keepScreenOn:true clipboardEnable:true dexMetaKeyCapture:true \
          showAdditionalKbd:false additionalKbdVisible:false preferScancodes:false displayResolutionMode:scaled; do
    k=${kv%%:*} v=${kv#*:}
    cur=$(printf '%s\n' "$prefs" | sed -n "s/.*\"$k\"=\"\([^\"]*\)\".*/\1/p")
    report "$k" "$cur" "$v" x11pref -e "$k" "$v"
done

echo
if [ "$bad" = 0 ]; then echo "All good."
elif [ -n "$CHECK" ]; then echo "$bad wrong. Run without --check to fix."
else echo "Fixed $changed of $bad. Restart the desktop (Desktop Start) if keyboard or X11 settings changed."; fi
echo "Can't be set over adb (check by hand): battery 'Unrestricted' for Termux/Termux:X11/Tailscale in ColorOS,"
echo "Tailscale as always-on VPN, Termux 預設開啟 = 在瀏覽器中開啟 (else links don't open)."
