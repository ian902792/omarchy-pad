# omarchy-pad — notes for agents

> **This is a public repo.** Everything committed (including history) is visible to anyone.
> Never commit secrets, keys, tokens, real IPs/hostnames, usernames or personal data: use placeholders
> (e.g. `you@100.x.y.z` in `env.example`) and keep real values in untracked files like `~/.config/omarchy-pad/env`.
> Check `git diff --cached` for them before every commit.

Keyboard-first i3 desktop for an OPPO Pad 4 Pro (ColorOS / Android 16) on **Termux native + Termux:X11**.
Synced via GitHub (`git@github.com:ian902792/omarchy-pad.git`). Copies:
- tablet: `/data/data/com.termux/files/home/GitHub/omarchy-pad` (= `~/GitHub/omarchy-pad` in Termux)
- Mac: `/Users/ianyu/GitHub/omarchy-pad`

## Where things live (tablet)

| File in repo | Live path (symlink) | Apply a change |
|---|---|---|
| `config/i3/config` | `~/.config/i3/config` | `i3-msg reload` (bar/layout: `i3-msg restart`) |
| `config/i3status/config` | `~/.config/i3status/config` | `i3-msg restart` |
| `config/kitty/kitty.conf` | `~/.config/kitty/kitty.conf` | new kitty windows; existing: ctrl+shift+F5 |
| `config/rofi/config.rasi`, `config/dunst/dunstrc` | `~/.config/{rofi,dunst}/` | next launch / `pkill dunst` |
| `config/gtk-3.0/{settings.ini,gtk.css,bookmarks}` | `~/.config/gtk-3.0` | restart the app (`thunar -q` quits Thunar's daemon) |
| Thunar sidebar width / hidden Network | xfconf, set by an `exec xfconf-query` line in the i3 config | next desktop start |
| `config/Xresources` | `~/.Xresources` | restart session (`start.sh`) |
| `config/starship.toml`, `config/bashrc` | `~/.config/starship.toml`, sourced by `~/.bashrc` | new shell |
| `config/gitconfig` | included from `~/.gitconfig` (delta pager) | immediate |
| `config/lazygit/config.yml` | `~/.config/lazygit/config.yml` | next `lg` |
| `bin/omp-status` (battery block: red < 25%, orange < 40%, else green; 中/英 of fcitx5; Mac reachable on :22, green/red) | i3bar `status_command` | `i3-msg restart` |
| `bin/omp-cal` (launcher entry Calendar: month grid, ←/→ months; Taiwan holidays from ruyut/TaiwanCalendar JSON cached in `~/.cache/omarchy-pad`; NYSE closures from pip `holidays` + early-close rule) | rofi | immediate |
| `bin/omp-claude-notify` (spoken via `termux-tts-speak` + notification + dunst when Claude waits; Stop only after turns > `OMP_NOTIFY_MIN`=20 s) | hooks in `~/.claude/settings.json`, merged by install.sh | next Claude turn |
| `config/claude/statusline.py` (Claude Code status line, same as the Mac's: model, prompt count, context, rate limits, cost) | `statusLine` in `~/.claude/settings.json`, set by install.sh | next status refresh |
| `bin/omp-tile` (side-by-side layouts; Super+S = `omp-tile toggle`) | daemon from i3 `exec_always` | `i3-msg restart`; `omp-tile test` = self-check |
| `bin/omp-wallpaper` (feh, re-set on every RandR resize: displayScale lands after i3 starts, else 2x2 tiling) | i3 `exec_always` | `i3-msg restart` |
| `bin/omp-keys` (key cheat sheet + system info: first entry of Super+Space, rofi combi; rows = `#:` lines in `config/i3/config`, Enter runs the binding) | rofi script mode | immediate |
| `bin/omp-speak` (`\` / Ctrl+`\`: toggles Speak Only voice input via `am broadcast` when it is the active Android IME, else types the key with xdotool from the empty `speakonly-pass` mode; Termux:X11's KeyInterceptor hides keys from IMEs) | i3 `bindsym` | immediate |
| `bin/*` | `~/.local/bin/*` | immediate |

Session: `start.sh` (restarts X11 + i3, starts sshd, wake lock) / `stop.sh` (also Super+Escape and the launcher's Shut Down Desktop, via `omp-keys shutdown`). `install.sh` is idempotent (packages, links, Claude Code).
Termux:Widget entries: `~/.shortcuts/tasks/` and `~/.termux/widget/dynamic_shortcuts/` (written by install.sh).
Logs: `$TMPDIR/omarchy-pad.log` (X server + session stderr).

Run GUI commands from a shell with `DISPLAY=:0`. Test keys with `xdotool key super+t` (adb-injected Super is eaten by ColorOS).

## Constraints (verified on this device — don't relearn them)

- Hyprland/Wayland impossible (Termux:X11 is an X server). i3 only.
- GL: zink (Turnip, Adreno 830) set in `start.sh`. kitty is clean on it and ~9x cheaper than llvmpipe;
  alacritty rendered garbage on zink (reason it was replaced). llvmpipe fallback: `LIBGL_ALWAYS_SOFTWARE=1`.
  Keep `MESA_VK_WSI_PRESENT_MODE=mailbox`: with the default fifo the screen briefly showed older frames
  (text/preedit jumping back). Check after Mesa/kitty upgrades with `tests/frame-order.py` (expect backwards=0).
- Latency = pixels: kitty frames go through the X server. `OMP_SCALE` (env file, default 75) sets the X resolution
  as % of native via Termux:X11 `displayScale` (inverse: 133 = 75%), and DPI = 240*scale; restart the desktop after changing.
- termux-x11 needs `-noreset`, otherwise xrdb resources (Xft.dpi 240) vanish.
- Physical keyboard: Super works, but **Super+Return is taken by ColorOS**; Super+T opens a terminal.
- Keys reach X only through Termux:X11's KeyInterceptor accessibility service. ColorOS sometimes turns it off;
  then Super dies AND the Android IME (LIME) eats keys and composes (cursor jumps back, wrong chars).
  Fix: `./android-setup.sh` on the Mac (pad on USB).
  Termux itself can't read or write secure settings.
- i3 config has no trailing comments on `bindsym` lines (they become part of the command).
- Termux:Widget start: `start.sh` takes the wake lock first and `stop.sh --restart` keeps it; dropping it lets
  TermuxService stop and kill the new desktop. The X11 activity can't be raised from a widget (BAL_BLOCK).
- Android's phantom process killer (max 32 child processes for all apps) killed the whole desktop incl. sshd
  ("Trimming phantom processes" in logcat; every kitty window adds ~3 processes). Disabled by `./android-setup.sh`;
  re-run it after a ColorOS update.
- Android tags heap pointers (0xb400...), which overflow i3's con_id: i3bar workspace clicks failed with
  "Could not parse con id". `lib/omp-notag.c` (built by install.sh, preloaded by `omp-session`) turns tagging off.
  The `NATIVE_HEAP_POINTER_TAGGING` compat flag does not help: it only covers the app process, not what Termux execs.
- `termux-open-url` (`$BROWSER`, tapped URLs) silently does nothing (am still reports success) until Android
  Settings → Termux → 預設開啟 is switched from「在應用程式中開啟」to「在瀏覽器中開啟」. Then it works from the Termux app and from the X desktop.
- Termux:API notifications never appeared and made no sound (Android 13+ notification permission / ColorOS
  channel defaults); `termux-notification` still exits 0. `termux-tts-speak` is heard (media volume).
- rofi `-theme-str`: a quoted value runs on to the last `"` in the string, swallowing later rules; pass one
  quoted value per `-theme-str`. Pango markup with a repeated attribute (two `color=`) blanks the whole message.
  The message box (`-mesg`) takes its font from `textbox { font }` (not `message textbox`) and is sized by it:
  spans larger than that font get clipped, smaller ones are fine — so set the big font there and shrink with spans.
- i3status dies on SIGUSR1 sent before it prints its first line (handler not set yet): omp-status waits for that.
- Android only exposes `/proc/meminfo` and `thermal_zone0`; no CPU/network stats. Battery only via the Termux:API app
  (`termux-battery-status`, ~0.5 s): `bin/omp-status` wraps i3status and adds it, refreshed every 60 s.
- Claude Code: linux-arm64 glibc build run via `bin/claude` (glibc ld.so, LD_PRELOAD dropped, restored for the Bash tool by a CLAUDE_CODE_SHELL wrapper so bash itself loads termux-exec and `#!/usr/bin/env` scripts run). No self-update; update with `install.sh`.
- Chinese input = fcitx5 + 自由大新 table (`ime/newcj.cin`, built by install.sh into `~/.local/share/fcitx5/table/`).
  Start it only via `bin/omp-ime`: fcitx5 treats Termux as Android (on-screen-keyboard mode) and never shows the
  candidate window unless a fake `org.fcitx.Fcitx5.VirtualKeyboard` D-Bus owner exists. Do not mark classicui
  `UIType=OnScreenKeyboard` (segfaults in updateVirtualKeyboardVisibility). Restarting fcitx5 breaks IBus in
  already-open kitty windows (open a new one). Check state: `CurrentUI` on `org.fcitx.Fcitx5 /controller` should be `classicui`.
- Tailscale MagicDNS names don't resolve in Termux; use IPs (Mac = `MAC=` in `~/.config/omarchy-pad/env`).

## Workflow

Edit in the repo, apply (table above), verify on screen, then `git commit` and `git push`; the other machine does `git pull`.
Shell scripts target Termux bash (`#!/data/data/com.termux/files/usr/bin/bash`); no `/bin/sh`, no `/usr/bin/env` paths in configs.
Moving the tablet checkout breaks every symlink in `~/.config` (i3 then falls back to its default config: no bar, gaps or workspaces); re-run `install.sh` from the new path.
