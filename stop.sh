#!/data/data/com.termux/files/usr/bin/bash
pkill -x i3 2>/dev/null
pkill -f 'termux-x11 com.termux.x11' 2>/dev/null
pkill -f com.termux.x11.Loader 2>/dev/null
termux-wake-unlock   # sshd keeps running; Android may stop it later without the lock
true
