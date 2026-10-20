# omarchy-pad

OPPO Pad 4 Pro（ColorOS / Android 16）上的鍵盤導向開發桌面：**Termux 原生 + Termux:X11 + i3**，Omarchy 風格（Tokyo Night、平鋪、Super 快捷鍵）。
用途：mosh 回 MacBook 開 herdr、在平板上跑 Claude Code。瀏覽器用 Android Chrome。

> Omarchy 本體是 Hyprland（Wayland），Termux:X11 是 X server 跑不了；這裡是 i3 版的同款長相與操作。

## 組成

| 部分 | 選擇 | 原因 |
|---|---|---|
| 視窗管理 | i3 + i3bar/i3status | 一個設定檔包含快捷鍵、配色、狀態列 |
| 終端機 | kitty（zink：Adreno GPU） | 支援背景圖：快捷鍵浮水印（`bin/omp-watermark` 產生，改快捷鍵後重跑）。用 GPU 比軟體 GL（llvmpipe）省約 9 倍 CPU |
| 啟動器 / 通知 | rofi / dunst | |
| 字型 | JetBrainsMono Nerd Font | |
| 解析度 / 縮放 | X 以原生的 `OMP_SCALE`%（預設 75% = 2544×1800）繪製，DPI 跟著換算 | 延遲跟像素數成正比：100% 最清晰、50% 最快；改 `~/.config/omarchy-pad/env` 後重開桌面。GTK 用 `GDK_SCALE=2 GDK_DPI_SCALE=0.5` |
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

- **長按 Termux:Widget 的 app 圖示** → **Desktop Start** / **Desktop Stop**（install 之後要開 Termux:Widget 按一次 CREATE SHORTCUTS 才會更新清單）
- 或桌面上的 Termux:Widget 小工具（`~/.shortcuts/tasks/`，背景執行）
- 或在 Termux 裡 `bash ~/omarchy-pad/start.sh`（會先停掉舊的 session）/ `stop.sh`
- 桌面已在跑、只是切走了：直接點 **Termux:X11** app（或從多工切回去）即可，不用重新 Start
- Start 同時會啟動 sshd（port 8022，只收金鑰）並取得 wake lock，所以桌面開著時 Mac 可以 `ssh -p 8022 <pad 的 Tailscale IP>` 連進來；Stop 會放開 wake lock

## 同步

GitHub private repo `ian902792/omarchy-pad`。平板與 Mac 都是 clone，改完 `git commit && git push`，另一邊 `git pull`。
給 Claude 的說明在 `CLAUDE.md`（檔案位置對照表、套用方式、已驗證的限制）。

## 快捷鍵（Super）

每個桌面預設是**分頁（tabbed）**：每個視窗一個分頁、各自全螢幕，上方是分頁列；Super+←/→ 切換分頁。
要並排就在該桌面按 Super+S（再按一次回到分頁）。

| 鍵 | 動作 |
|---|---|
| Super+T | 新終端機分頁（Super+Return 實體鍵盤會被 ColorOS 攔走） |
| Super+Space / Super+Tab | 應用程式啟動器 / 視窗切換 |
| **Super+M** | 切到 herdr 分頁；還沒開就 mosh 到 Mac 開一個（只會有一條連線） |
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
