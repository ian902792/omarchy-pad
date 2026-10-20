# omarchy-pad

OPPO Pad 4 Pro（ColorOS / Android 16）上的鍵盤導向開發桌面：**Termux 原生 + Termux:X11 + i3**，Omarchy 風格（Tokyo Night、平鋪、Super 快捷鍵）。
用途：mosh 回 MacBook 開 herdr、在平板上跑 Claude Code。瀏覽器用 Android Chrome。

> Omarchy 本體是 Hyprland（Wayland），Termux:X11 是 X server 跑不了；這裡是 i3 版的同款長相與操作。

## 組成

| 部分 | 選擇 | 原因 |
|---|---|---|
| 視窗管理 | i3 + i3bar/i3status | 一個設定檔包含快捷鍵、配色、狀態列 |
| 終端機 | alacritty（llvmpipe 軟體 GL） | zink（Adreno）會畫出黑色雜訊帶；llvmpipe 清晰且夠快 |
| 啟動器 / 通知 | rofi / dunst | |
| 字型 | JetBrainsMono Nerd Font | |
| 縮放 | `Xft.dpi: 240`（2.5x，約 1357×960 邏輯解析度） | 315 ppi 面板用 2x 太小；GTK 用 `GDK_SCALE=2 GDK_DPI_SCALE=0.5` |
| 遠端 | mosh → Mac（Tailscale IP）→ `herdr` | |
| Claude Code | linux-arm64 glibc 版，經 glibc-runner 的 loader 執行 | 沒有 Android 版；見 `bin/claude` |

## 安裝（在 Termux app 前景執行）

```sh
git clone <this repo> ~/omarchy-pad   # 或從 Mac 複製
bash ~/omarchy-pad/install.sh         # 可重複執行；也用來更新 Claude Code
```

install.sh 會：裝套件 → 字型 → 把 `config/*` symlink 到 `~/.config/`（原有的改名 `*.bak.<時間>`）→ `bin/*` 連到 `~/.local/bin` →
建立 Termux:Widget 捷徑 → 下載 Claude Code → 產生 `~/.ssh/id_ed25519`（把印出的公鑰加到 Mac 的 `~/.ssh/authorized_keys`）。

Mac 端需要：系統設定開「遠端登入」、`brew install mosh`、第一次連線時防火牆允許 `mosh-server`。
連線目標在 `~/.config/omarchy-pad/env` 的 `MAC=`（用 Tailscale IP；Termux 解析不到 MagicDNS 名稱）。

## 啟動 / 停止

- Termux:Widget → **Desktop Start** / **Desktop Stop**
- 或 `bash ~/omarchy-pad/start.sh`（會先停掉舊的 session）/ `stop.sh`

## 快捷鍵（Super）

| 鍵 | 動作 |
|---|---|
| Super+Return | 終端機 |
| Super+Space / Super+Tab | 應用程式啟動器 / 視窗切換 |
| **Super+M** | mosh 到 Mac 並接上 herdr |
| Super+E | Thunar |
| Super+W | 關閉視窗 |
| Super+F / V / J / S | 全螢幕 / 浮動 / 切換分割方向 / 分頁版面 |
| Super+方向鍵（+Shift） | 移動焦點（移動視窗） |
| Super+-/=（+Shift） | 調整寬度（高度） |
| Super+1…6（+Shift） | 切換桌面（把視窗移過去） |
| Super+Shift+R / Super+Escape | 重新載入 i3 / 離開 |

**Super 鍵需要實體鍵盤驗證**：已啟用 Termux:X11 的 KeyInterceptor 無障礙服務與 `dexMetaKeyCapture`，
但 adb 注入的 Super 會被 ColorOS 拿走，所以只確認了 X 端（xdotool）快捷鍵可用。
如果實體鍵盤的 Super 也被吃掉：把 `config/i3/config` 的 `set $mod Mod4` 改成 `Mod1`（Alt），在終端機執行 `i3-msg restart`。

## Claude Code

`claude` 是 `bin/claude` 包裝：用 `$PREFIX/glibc/lib/ld-linux-aarch64.so.1` 直接啟動 glibc 版本。
Termux 的 `LD_PRELOAD`（bionic 函式庫）無法載入 glibc 程序，所以只對 claude 本身拿掉，再透過 `CLAUDE_ENV_FILE`
在 Claude 的每個 Bash 指令前補回（`#!/usr/bin/env` 腳本需要它）。不用 `grun`：它會把 glibc 的 coreutils 放到 PATH 前面。
自動更新已關閉（會覆蓋包裝）；更新 = 重跑 `install.sh`，或 `CLAUDE_VER=2.x.y bash install.sh` 指定版本。

## Termux:X11 / Android 設定（install 時沒有自動做，已在本機手動設定過）

- Termux:X11 偏好：`fullscreen:true hideCutout:true showAdditionalKbd:false dexMetaKeyCapture:true`（`termux-x11-preference`，X 執行中才能設）
- 無障礙：`com.termux.x11/.utils.KeyInterceptor`（攔截 Super 等系統快捷鍵）
- 電池：Termux、Termux:X11 設為「不限制」，否則背景會被殺

## 已知限制

- 狀態列只有 RAM 與 SoC 溫度：Android 不讓 Termux 讀電池、網路、CPU 使用率。
- Termux 在背景時 ColorOS 不准它開 Android app（`termux-open-url` 無效），所以沒有「開瀏覽器」快捷鍵；用 Android 的多工切換到 Chrome。
- Termux:X11 必須保留 `-noreset`：否則 xrdb 寫入的 DPI 會在 X server 重置時消失。
