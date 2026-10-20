# omarchy-pad

在 OPPO Pad 4 Pro（ColorOS / Android 16，Snapdragon 8 Elite，Adreno 830）上，用 **Termux 原生套件 + Termux:X11**
建立 Omarchy 風格的平鋪式桌面：bspwm + sxhkd + Polybar + Rofi，主題 Catppuccin Mocha / Tokyo Night。
不需要 root、不解鎖 Bootloader，保留 Android 與 XFCE 備援桌面。

> 這是 Omarchy-*inspired* 的設定，不是 Omarchy（Arch + Hyprland）本體。

## 環境區分（不要混用）

| 環境 | 本專案用法 |
|---|---|
| Android shell（`adb shell`） | 只用於偵測與除錯，不執行 install.sh |
| **Termux 原生 shell** | **所有腳本都在這裡執行**；套件管理器是 `apt`/`pkg`，prefix 為 `/data/data/com.termux/files/usr` |
| DroidDesk 獨立 APK 私有環境 | 不使用、不修改 |
| proot（Ubuntu/Debian/Arch） | 不使用；`lib/common.sh` 偵測到會拒絕執行 |

DroidDesk 的 `termux-linux-setup.sh` **沒有整支執行**（它會 `apt upgrade`、安裝 Firefox、建立 Ubuntu proot、並寫入 `~/start-x11.sh`）。
本專案只取其中同樣的 Termux 套件來源（x11-repo、`termux-x11-nightly`、Mesa/Turnip），啟動器使用獨立檔名，不覆蓋 DroidDesk 的任何檔案。

## 安裝

1. 在平板上開 Termux，保持在**前景**（ColorOS 會封鎖背景 App 的網路）。
2. 取得本資料夾到 `~/omarchy-pad`，然後：

```sh
cd ~/omarchy-pad
bash install.sh            # 可重複執行；--no-xfce / --no-gpu 可略過對應套件群組
bash doctor.sh
```

install.sh 的步驟：環境偵測 → 確認套件存在於 Termux repo → **備份** → 安裝（只裝缺的）→ 寫入 `~/.config/omarchy-pad/env`
（已存在則保留）→ 渲染設定 → 靜態驗證。任何一步失敗就停止，不執行後續依賴步驟。日誌：`~/.omarchy-pad/logs/`。

## 啟動 / 停止 / 切換

```sh
bash ~/omarchy-pad/start-omarchy.sh        # bspwm 桌面（然後切到 Termux:X11 app）
bash ~/omarchy-pad/stop-omarchy.sh         # 停止桌面與 X server
bash ~/omarchy-pad/start-xfce.sh           # XFCE 備援桌面（會先停掉 bspwm）
bash ~/omarchy-pad/set-theme.sh toggle     # catppuccin <-> tokyo-night；也可指定名稱 / list
```

預設修飾鍵是 **Alt**（見下方「已知限制」）。快捷鍵（`~/.config/sxhkd/sxhkdrc`，模板在 `configs/sxhkd/`）：

| 快捷鍵 | 動作 |
|---|---|
| Alt+Return | 終端機（xfce4-terminal） |
| Alt+Space / Alt+d | Rofi 應用程式啟動器；Alt+Tab 視窗切換；Alt+Shift+Space 執行指令 |
| Alt+h/j/k/l 或方向鍵 | 移動焦點；加 Shift = 交換視窗；加 Ctrl = 調整大小 |
| Alt+1…6 | 切換到桌面 1–6；加 Shift = 把視窗移過去 |
| Alt+f / Alt+v / Alt+t | 全螢幕 / 浮動 / 還原平鋪；Alt+m 切換 monocle |
| Alt+w / Alt+Shift+w | 關閉 / 強制結束視窗 |
| Alt+Shift+t | 切換主題 |
| Alt+Shift+r / c / e | 重啟 bspwm / 重載 sxhkd / 結束桌面 |

## 設定（`~/.config/omarchy-pad/env`，改完執行 `render.sh`）

| 變數 | 預設 | 說明 |
|---|---|---|
| `OMP_THEME` | `catppuccin` | `catppuccin` 或 `tokyo-night`（新增主題：複製 `themes/<name>/colors.sh`） |
| `OMP_MOD` | `alt` | 改 `super` 可重試 Super 鍵 |
| `OMP_DPI` | `192` | 13.2" 3392×2400 約 315 ppi；要更多可用空間改 144 |
| `OMP_GPU` | `llvmpipe` | `zink` = Turnip 硬體加速，見下 |

主題統一範圍：bspwm 邊框、Polybar、Rofi、xfce4-terminal、GTK3（`gtk.css` 覆寫色票 + dark）、背景（純色，或放 `themes/<name>/wallpaper.png` 由 feh 顯示）。
**不保證所有應用一致**：Qt 應用、Firefox、已開啟的終端機視窗不會即時換色；GTK 只覆寫部分色票，沒有安裝 Catppuccin GTK 主題包。

## GPU（在本機實測，2026-10-20）

`gpu-probe.sh` 結果（Mesa 26.2.5）：

| 模式 | OpenGL renderer | glxgears |
|---|---|---|
| llvmpipe（預設） | `llvmpipe (LLVM 21.1.8, 128 bits)` | ≈ 15 FPS |
| zink | `zink Vulkan 1.4(Adreno (TM) 830 (MESA_TURNIP))` | ≈ 228 FPS |

Vulkan：`Adreno (TM) 830` / `turnip Mesa driver` / API 1.4.354，`/dev/kgsl-3d0` 存在。
只驗證了 glxgears（一張畫面無黑畫面/撕裂），沒有測 Firefox、Electron 等大型 GL 應用，所以預設仍用較穩的 llvmpipe。
要啟用：在 env 設 `OMP_GPU=zink` 後重新 `start-omarchy.sh`；若出現黑畫面/閃爍改回 `llvmpipe`。
`vulkan-loader-android` 與 Mesa 依賴的 `vulkan-loader-generic` 互相衝突，安裝腳本不使用前者（DroidDesk 使用前者；此處 generic loader + freedreno ICD 實測可用）。

## 回滾

```sh
bash ~/omarchy-pad/rollback.sh          # 停止桌面 → 還原「安裝前」的設定 → 還原 Termux:X11 方向設定
bash ~/omarchy-pad/rollback.sh --xfce   # 同上並啟動 XFCE
bash ~/omarchy-pad/rollback.sh --backup DIR   # 還原指定備份
```

- 備份在 `~/.omarchy-pad/backups/<時間>[-label]/`，第一份備份記為 `ORIGINAL`（安裝前狀態）。回滾前會先對當前狀態再做一份 `pre-rollback` 備份。
- 只動本專案管理的路徑（見 `lib/common.sh` 的 `OMP_MANAGED_PATHS`）。使用者檔案、Android 設定、DroidDesk 啟動器不碰。
- 新增的套件**只記錄不移除**：`~/.omarchy-pad/installed-packages.txt`（與 ORIGINAL 備份的 dpkg 清單比對）。共用相依套件請自行逐一 `pkg uninstall`。

## 驗證（doctor.sh）

`PASS` 實際執行成功｜`FAIL` 實際失敗｜`SKIP` 缺前置條件（例如 X 未啟動）｜`UNVERIFIED` 需要人工或未實測。
標示 `(static)` 的只代表檔案存在/語法正確，不代表圖形桌面可用。

### 需要人工驗證

1. **實體藍牙鍵盤**：按 `Alt+Return` 是否開終端機（本專案只用 adb 注入按鍵驗證過 Alt 路徑）。
2. **觸控**：Termux:X11 目前是 Trackpad 模式（已讀取設定值）。依 Termux:X11 文件：單指移動游標、單指點 = 左鍵、雙指點 = 右鍵（**文件行為，未在本機實測**）；要直接觸控改 Termux:X11 設定 → Touch mode。
3. **視覺**：版面、字級（DPI 192）是否合你的視距。
4. **中文輸入**：本專案未安裝輸入法；Termux:X11 可使用 Android 輸入法（Gboard）輸入，fcitx5 在 repo 內但未設定。

## 已知限制

- **Super/Meta 被 ColorOS 攔截**：adb 注入 Super+Return 時，Android 桌面直接收到（回主畫面），X11 沒收到。所以預設 Alt。實體鍵盤是否不同未驗證。Alt 與終端機內的 Alt 組合鍵可能衝突。
- **Polybar 的電池/網路模組**：Android 不保證開放 sysfs 電池/網路介面。`scripts/status-*.sh` 讀不到就不顯示（本機實測兩者都沒有顯示）；安裝 Termux:API app + `pkg install termux-api` 後電池可顯示。
- 網路：ColorOS 封鎖背景 App 網路，`install.sh` 時 Termux 必須在前景；腳本會先檢查並明確報錯。
- 電源/背景限制：請在 設定 → 電池 把 Termux、Termux:X11 設為「不限制」，否則桌面在背景可能被殺（本專案未更動任何 Android 設定）。
- XFCE 備援：已用 xfconf 把 DPI 與面板高度依 `OMP_DPI` 放大，但圖示與桌面圖示仍偏小，只當備援。啟動時 xfwm4 提示 "Another compositing manager is running"（Termux:X11 自帶 composite），無實際影響。
- 啟動 XFCE 會在 `$HOME` 建立 `.gnupg`、`.config/xfce4/*` 等；回滾只還原 `OMP_MANAGED_PATHS`。
- 桌面 X 解析度跟 Termux:X11 視窗大小走（橫向約 3392×2056，扣掉狀態列與額外按鍵列）。

## 目錄

```
install.sh doctor.sh backup.sh rollback.sh start-omarchy.sh stop-omarchy.sh   # 規格要求的入口
start-xfce.sh set-theme.sh render.sh gpu-probe.sh
lib/common.sh            共用函式、路徑、受管路徑清單
configs/<tool>/*.tpl     模板（@TOKEN@ 由 render.sh 填入）
themes/<name>/colors.sh  色票
scripts/                 polybar 啟動、電池/網路狀態、桌布、Termux:X11 偏好
```
