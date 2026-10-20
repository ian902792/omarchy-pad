# omarchy-pad

OPPO Pad 4 Pro（ColorOS / Android 16）上的鍵盤導向開發桌面：**Termux 原生 + Termux:X11 + i3**，Omarchy 風格（Tokyo Night、平鋪、Super 快捷鍵）。
用途：mosh 回 MacBook 開 herdr、在平板上跑 Claude Code。瀏覽器用 Android Chrome。

> Omarchy 本體是 Hyprland（Wayland），Termux:X11 是 X server 跑不了；這裡是 i3 版的同款長相與操作。

## 組成

| 部分 | 選擇 | 原因 |
|---|---|---|
| 視窗管理 | i3 + i3bar/i3status | 一個設定檔包含快捷鍵、配色、狀態列 |
| 終端機 | kitty（zink：Adreno GPU） | 支援背景圖：快捷鍵浮水印（由 `config/i3/config` 裡的 `#:` 註解產生，桌面啟動或 Super+Shift+R 時自動更新）。用 GPU 比軟體 GL（llvmpipe）省約 9 倍 CPU |
| 啟動器 / 通知 | rofi / dunst | |
| 字型 | JetBrainsMono Nerd Font | |
| 解析度 / 縮放 | X 以原生的 `OMP_SCALE`%（預設 75% = 2544×1800）繪製，DPI 跟著換算 | 延遲跟像素數成正比：100% 最清晰、50% 最快；改 `~/.config/omarchy-pad/env` 後重開桌面。GTK 用 `GDK_SCALE=2 GDK_DPI_SCALE=0.5` |
| 遠端 | mosh → Mac（Tailscale IP）→ `herdr` | |
| 狀態列 | i3status + `bin/omp-status`（電池，來自 Termux:API） | 沒接電源、電量低於 25% 時電池顯示紅色 |
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

- **長按 Termux:Widget 的 app 圖示** → **Desktop Start**，約 3 秒後**點 Termux:X11 圖示**進入桌面（ColorOS 不准 Widget 自動把它叫到前景）；**Desktop Stop** 關閉。install 之後要開 Termux:Widget 按一次 CREATE SHORTCUTS 才會更新清單
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
| Super+E | Thunar（側邊欄有 下載 / 圖片 / 截圖 / 相機；照片用 ristretto 開） |
| Super+Shift+S | 截圖，存到 Android 的 圖片/Screenshots |
| Super+W | 關閉視窗 |
| Super+C / Super+V | 終端機裡複製 / 貼上（與 Android 剪貼簿同步；其他 App 用 Ctrl+C / Ctrl+V） |
| Super+F / Shift+V / J / S | 全螢幕 / 浮動 / 切換分割方向 / 分頁版面 |
| Super+方向鍵（+Shift） | 移動焦點（移動視窗） |
| Super+-/=（+Shift） | 調整寬度（高度） |
| Super+1…6（+Shift） | 切換桌面（把視窗移過去） |
| Super+Shift+R / Super+Escape | 重新載入 i3 / 離開 |

**Super 鍵需要實體鍵盤驗證**：已啟用 Termux:X11 的 KeyInterceptor 無障礙服務與 `dexMetaKeyCapture`，
但 adb 注入的 Super 會被 ColorOS 拿走，所以只確認了 X 端（xdotool）快捷鍵可用。
如果實體鍵盤的 Super 也被吃掉：把 `config/i3/config` 的 `set $mod Mod4` 改成 `Mod1`（Alt），在終端機執行 `i3-msg restart`。

## 終端機工具

install.sh 會裝好並設定（設定在 `config/bashrc`、`config/gitconfig`、`config/lazygit/config.yml`）：

| 指令 | 用途 | 常用 |
|---|---|---|
| `lg`（lazygit） | 選單式 git：看改動、分段 commit、切 branch、push | 方向鍵選、空白鍵 stage、`c` commit、`P` push、`?` 說明、`q` 離開 |
| `ls` / `ll` / `tree`（eza） | 有顏色和圖示的 ls；`ll` 會顯示 git 狀態 | `ll`、`tree -L 2` |
| `cat`（bat） | 有語法高亮的 cat；要行號和捲動用 `bat 檔名` | `bat install.sh` |
| `z`（zoxide） | 跳到常去的資料夾，只要打一部分名稱 | `z omarchy`、`zi`（用選單挑） |
| `fd` | 找檔案，比 find 快、語法簡單 | `fd watermark`、`fd -e sh` |
| `git diff`（delta） | diff 有語法高亮和行號；`n` / `N` 跳到下一個 / 上一個檔案 | `git diff`、`git show` |
| `uv` | Python 版本、套件、虛擬環境 | `uv venv`、`uv pip install x`、`uv run script.py` |

原本的指令都還在：`command ls`、`command cat`、`\cat`。

## Claude Code

`claude` 是 `bin/claude` 包裝：用 `$PREFIX/glibc/lib/ld-linux-aarch64.so.1` 直接啟動 glibc 版本。
Termux 的 `LD_PRELOAD`（bionic 函式庫）無法載入 glibc 程序，所以只對 claude 本身拿掉；Claude 的 Bash 工具改用
`CLAUDE_CODE_SHELL` 指向的小包裝，啟動 bash 前補回（bash 本身要載入它，`#!/usr/bin/env` 腳本才跑得動）。不用 `grun`：它會把 glibc 的 coreutils 放到 PATH 前面。
自動更新已關閉（會覆蓋包裝）；更新 = 重跑 `install.sh`，或 `CLAUDE_VER=2.x.y bash install.sh` 指定版本。

## Android 端設定：`android-setup.sh`（在 Mac 上、平板插 USB 執行）

這些設定在 Termux 之外，install.sh 碰不到。`./android-setup.sh` 逐項檢查並修正，列出修了什麼（`--check` 只檢查）：

- 無障礙 `com.termux.x11/.utils.KeyInterceptor`：沒有它 Super 鍵失效，而且 Android 輸入法（LIME）會先吃掉按鍵、游標亂跳
- 子程序限制（Android 12+ 全部 App 合計 32 個，超過就把整個桌面連 sshd 一起殺掉）：關閉
- Doze 省電豁免：Termux、Termux:X11、Tailscale
- Termux:X11 偏好：全螢幕、隱藏瀏海、Meta 鍵攔截、剪貼簿同步、縮放模式等

**什麼時候跑**：ColorOS 更新後、重裝 App 後、Super 鍵又失效或桌面莫名被關掉時。
adb 改不了、要在平板上手動確認的：電池「不限制」（Termux、Termux:X11、Tailscale），Tailscale 設為「永遠開啟的 VPN」。

## 已知限制

- 狀態列：RAM、SoC 溫度、電池（電池要裝 Termux:API App，GitHub 版，跟 Termux 同簽章）。Android 不讓 Termux 讀網路、CPU 使用率。
- Termux 在背景時 ColorOS 不准它開 Android app（`termux-open-url` 無效），所以沒有「開瀏覽器」快捷鍵；用 Android 的多工切換到 Chrome。
- Termux:X11 必須保留 `-noreset`：否則 xrdb 寫入的 DPI 會在 X server 重置時消失。
