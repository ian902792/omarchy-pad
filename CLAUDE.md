# omarchy-pad — notes for Claude

Keyboard-first i3 desktop for an OPPO Pad 4 Pro (ColorOS / Android 16) on **Termux native + Termux:X11**.
Synced via GitHub (`git@github.com:ian902792/omarchy-pad.git`, private). Copies:
- tablet: `/data/data/com.termux/files/home/omarchy-pad` (= `~/omarchy-pad` in Termux)
- Mac: `/Users/ianyu/GitHub/omarchy-pad`

## Where things live (tablet)

| File in repo | Live path (symlink) | Apply a change |
|---|---|---|
| `config/i3/config` | `~/.config/i3/config` | `i3-msg reload` (bar/layout: `i3-msg restart`) |
| `config/i3status/config` | `~/.config/i3status/config` | `i3-msg restart` |
| `config/kitty/kitty.conf` | `~/.config/kitty/kitty.conf` | new kitty windows; existing: ctrl+shift+F5 |
| `config/rofi/config.rasi`, `config/dunst/dunstrc` | `~/.config/{rofi,dunst}/` | next launch / `pkill dunst` |
| `config/Xresources` | `~/.Xresources` | restart session (`start.sh`) |
| `config/starship.toml`, `config/bashrc` | `~/.config/starship.toml`, sourced by `~/.bashrc` | new shell |
| `bin/*` | `~/.local/bin/*` | immediate |
| `config/kitty/watermark.png` | generated, gitignored | `omp-watermark` (keys list lives in `bin/omp-watermark`; keep it in sync with i3 bindings) |

Session: `start.sh` (restarts X11 + i3, starts sshd, wake lock) / `stop.sh`. `install.sh` is idempotent (packages, links, Claude Code).
Termux:Widget entries: `~/.shortcuts/tasks/` and `~/.termux/widget/dynamic_shortcuts/` (written by install.sh).
Logs: `$TMPDIR/omarchy-pad.log` (X server + session stderr).

Run GUI commands from a shell with `DISPLAY=:0`. Test keys with `xdotool key super+t` (adb-injected Super is eaten by ColorOS).

## Constraints (verified on this device — don't relearn them)

- Hyprland/Wayland impossible (Termux:X11 is an X server). i3 only.
- GL: zink (Turnip, Adreno 830) set in `start.sh`. kitty is clean on it and ~9x cheaper than llvmpipe;
  alacritty rendered garbage on zink (reason it was replaced). llvmpipe fallback: `LIBGL_ALWAYS_SOFTWARE=1`.
- Latency = pixels: kitty frames go through the X server. `OMP_SCALE` (env file, default 75) sets the X resolution
  as % of native via Termux:X11 `displayScale` (inverse: 133 = 75%), and DPI = 240*scale; restart the desktop after changing.
- termux-x11 needs `-noreset`, otherwise xrdb resources (Xft.dpi 240) vanish.
- Physical keyboard: Super works, but **Super+Return is taken by ColorOS**; Super+T opens a terminal.
- i3 config has no trailing comments on `bindsym` lines (they become part of the command).
- Termux:Widget start: `start.sh` takes the wake lock first and `stop.sh --restart` keeps it; dropping it lets
  TermuxService stop and kill the new desktop. The X11 activity can't be raised from a widget (BAL_BLOCK).
- Termux in background cannot open Android activities (`termux-open-url` fails) — ColorOS policy.
- Android only exposes `/proc/meminfo` and `thermal_zone0`; no battery/CPU/network stats.
- Claude Code: linux-arm64 glibc build run via `bin/claude` (glibc ld.so, LD_PRELOAD dropped, restored for Bash via CLAUDE_ENV_FILE). No self-update; update with `install.sh`.
- Chinese input = fcitx5 + 自由大新 table (`ime/newcj.cin`, built by install.sh into `~/.local/share/fcitx5/table/`).
  Start it only via `bin/omp-ime`: fcitx5 treats Termux as Android (on-screen-keyboard mode) and never shows the
  candidate window unless a fake `org.fcitx.Fcitx5.VirtualKeyboard` D-Bus owner exists. Do not mark classicui
  `UIType=OnScreenKeyboard` (segfaults in updateVirtualKeyboardVisibility). Restarting fcitx5 breaks IBus in
  already-open kitty windows (open a new one). Check state: `CurrentUI` on `org.fcitx.Fcitx5 /controller` should be `classicui`.
- Tailscale MagicDNS names don't resolve in Termux; use IPs (Mac = `MAC=` in `~/.config/omarchy-pad/env`).

## Workflow

Edit in the repo, apply (table above), verify on screen, then `git commit` and `git push`; the other machine does `git pull`.
Shell scripts target Termux bash (`#!/data/data/com.termux/files/usr/bin/bash`); no `/bin/sh`, no `/usr/bin/env` paths in configs.
