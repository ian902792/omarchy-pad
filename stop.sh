#!/data/data/com.termux/files/usr/bin/bash
pkill -x i3 2>/dev/null
pkill -f 'termux-x11 com.termux.x11' 2>/dev/null
pkill -f com.termux.x11.Loader 2>/dev/null
# Release the wake lock only on a real stop. start.sh passes --restart: when Termux was launched by
# Termux:Widget, dropping the lock makes TermuxService stop and kill the starting desktop with it.
[ "$1" = --restart ] || termux-wake-unlock   # sshd keeps running; Android may stop it later without the lock
true
