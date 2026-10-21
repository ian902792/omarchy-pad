# omarchy-pad

把 Android 平板變成**用鍵盤操作的 Linux 桌面**，外觀仿 [Omarchy](https://omarchy.org)（Tokyo Night 配色、平鋪視窗）。
不用 root，平板上直接跑 **Claude Code**、Neovim、lazygit，也能一鍵連回 Mac。

[English](README.md) · **繁體中文**

![桌面：Claude Code、lazygit、Neovim 並排](docs/screenshots/desktop.jpg)

## 它是怎麼組成的

```mermaid
flowchart LR
    KB["⌨️ 實體鍵盤"] --> X11
    subgraph Pad["📱 Android 平板（Termux App 裡）"]
        X11["Termux:X11<br>顯示畫面"] --> I3["i3<br>平鋪視窗桌面"]
        I3 --> K["kitty 終端機"]
        K --> T["Claude Code · Neovim · lazygit"]
        I3 --> L["啟動器 · 月曆 · 狀態列 · 中文輸入"]
    end
    I3 -->|"Super+M"| Mac["💻 你的 Mac（選用）"]
```

## 特色

| | |
|---|---|
| 🪟 **平鋪視窗** | 預設每個視窗全螢幕；按 Super+S 自動並排 |
| 🤖 **Claude Code** | 在平板上原生執行；等你回應時會用語音提醒 |
| 🔎 **快捷鍵表** | 忘了就按 Super+Space，可搜尋、按 Enter 直接執行 |
| 🀄 **中文輸入** | 自由大新倉頡，Ctrl+Space 切換 |
| 📅 **月曆** | 台灣假日、補班、美股休市 |
| 🔋 **狀態列** | 電池、中／英、Mac 連線、記憶體、溫度 |
| ⚡ **GPU 加速** | 終端機用 GPU 繪製，省電又順 |

<table>
<tr>
<td width="50%"><img src="docs/screenshots/keys.jpg" alt="快捷鍵表"><br>Super+Space → 快捷鍵表與系統資訊</td>
<td width="50%"><img src="docs/screenshots/calendar.jpg" alt="月曆"><br>月曆：台灣假日、補班、美股休市</td>
</tr>
</table>

![新桌面：只有桌布和狀態列](docs/screenshots/empty.jpg)
<sub>新桌面：只有桌布和狀態列（桌面編號、中／英、Mac、記憶體、溫度、電池、時間）</sub>

## 需要準備

```mermaid
flowchart LR
    A["📱 Android 12+ 平板<br>（Adreno GPU 最好）"] --- B["⌨️ 實體鍵盤<br>（有 Super/⌘ 鍵最好）"] --- C["💻 一台電腦<br>（裝 adb，只用一次）"]
```

再到 GitHub 下載四個 App（**不要用 Play 商店版**，彼此會連不起來）：
[Termux](https://github.com/termux/termux-app/releases) ·
[Termux:X11](https://github.com/termux/termux-x11/releases) ·
[Termux:API](https://github.com/termux/termux-api/releases) ·
[Termux:Widget](https://github.com/termux/termux-widget/releases)

> 只在 OPPO Pad 4 Pro 實測過。其他平板大多能用，遇到不同的地方交給 AI agent 調整最快。

## 最簡單的方法：交給 AI agent

這個 repo 全是文字設定，[`AGENTS.md`](AGENTS.md) 記錄了每個檔案的用途和踩過的坑，所以 Claude Code 這類 agent 可以幫你從安裝做到客製化。
把下面這段貼給它，改掉 `< >` 就好：

```text
幫我在 Android 平板上安裝並客製化 https://github.com/ian902792/omarchy-pad 。
先讀 README.md 和 AGENTS.md，動手前告訴我你要改什麼。
我的平板：<型號>
我想改：<例：配色換成 Catppuccin、拿掉月曆、不需要連 Mac>
```

## 自己安裝：4 步

```mermaid
flowchart TD
    S1["① 平板 Termux<br>下載並執行 install.sh"] --> S2["② 電腦<br>插 USB，執行 android-setup.sh"]
    S2 --> S3["③ 平板設定<br>手動改 2 個選項"]
    S3 --> S4["④ Termux:Widget<br>按 CREATE SHORTCUTS"]
    S4 --> Done(["🎉 可以啟動桌面了"])
```

**① 在 Termux 裡**（安裝時讓 Termux 留在前景）

```sh
pkg install -y git
git clone https://github.com/ian902792/omarchy-pad ~/GitHub/omarchy-pad
bash ~/GitHub/omarchy-pad/install.sh
termux-setup-storage
```

**② 在電腦上**（平板開「USB 偵錯」並插上 USB）

```sh
git clone https://github.com/ian902792/omarchy-pad && cd omarchy-pad
./android-setup.sh
```

**③ 在平板設定裡**
- 電池 → Termux、Termux:X11 設為「**不限制**」
- 應用程式 → Termux → 預設開啟 → 「**在瀏覽器中開啟**」

**④ 打開 Termux:Widget App**，按一次 **CREATE SHORTCUTS**。

> 想用 Super+M 連回 Mac？請 AI agent 幫你設定，或看 `env.example`。

## 每天使用

```mermaid
flowchart LR
    W["長按 Termux:Widget 圖示"] --> St["Desktop Start"]
    St -->|"等 3 秒"| X["點 Termux:X11 圖示"]
    X --> D["🖥️ 桌面"]
    D -->|"Super+Escape<br>或 Desktop Stop"| Off["關閉"]
    D -.->|"切去別的 App 後"| X
```

## 快捷鍵

Super 就是鍵盤上的 Windows／⌘ 鍵。**記不住就按 Super+Space**，第一項就是完整清單。

| 鍵 | 動作 |
|---|---|
| Super+T | 開新終端機 |
| Super+Space | 啟動器（快捷鍵表、月曆、App） |
| Super+W | 關閉視窗 |
| Super+S | 切換「全螢幕分頁」和「並排」 |
| Super+←／→ | 切換視窗 |
| Super+1…6 | 切換桌面 |
| Super+E | 檔案管理器 |
| Super+Shift+S | 截圖 |
| Super+C／V | 複製／貼上 |
| Ctrl+Space | 中／英切換 |
| Super+M | 連回 Mac |

並排時會自動排版：

```text
 2 個          3 個          4 個
┌────┬────┐  ┌────┬────┐  ┌────┬────┐
│    │    │  │    │    │  │    │    │
│    │    │  │    ├────┤  ├────┼────┤
│    │    │  │    │    │  │    │    │
└────┴────┘  └────┴────┘  └────┴────┘
```

終端機裡已裝好：`claude`、`lg`（lazygit）、`nvim`、`z`（快速跳資料夾）、`fd`（找檔案）。

## 出問題時

```mermaid
flowchart TD
    P{"發生什麼事？"}
    P -->|"Super 鍵沒反應<br>打字游標亂跳"| F1["電腦重跑 android-setup.sh"]
    P -->|"桌面突然被關掉"| F1
    P -->|"系統更新之後怪怪的"| F1
    P -->|"點網址沒反應"| F2["設定 → Termux → 預設開啟<br>改成「在瀏覽器中開啟」"]
    P -->|"畫面錯亂（非 Adreno GPU）"| F3["start.sh 改用軟體繪圖<br>（問 AI agent）"]
    P -->|"其他"| F4["把狀況貼給 AI agent<br>它會查 AGENTS.md"]
```

## 想改成自己的樣子

建議先 **fork** 成自己的 repo。每樣東西都可以改、換或刪掉：

```mermaid
flowchart LR
    Me(("我想改…"))
    Me --> K["快捷鍵"] --> f1["config/i3/config"]
    Me --> C["配色"] --> f2["config/ 下各程式設定<br>i3 · kitty · rofi · dunst"]
    Me --> B["狀態列"] --> f3["bin/omp-status"]
    Me --> W["桌布"] --> f4["~/.local/share/omarchy-pad/wallpaper.jpg"]
    Me --> R["畫面清晰／延遲"] --> f5["~/.config/omarchy-pad/env<br>OMP_SCALE"]
```

不想自己找檔案？直接跟 AI agent 說「我想把 ___ 改成 ___」。

<details>
<summary>repo 和平板設定的關係（進階）</summary>

```mermaid
flowchart LR
    GH["GitHub"] <-->|"git push / pull"| Repo["平板上的 repo"]
    GH <--> Other["另一台電腦的 repo"]
    Repo -->|"config/ 連結到"| home["~/.config/"]
    Repo -->|"bin/ 連結到"| lb["~/.local/bin/"]
```

改 repo 裡的檔案就等於改了平板上的設定；每個檔案改完怎麼生效，查 [`AGENTS.md`](AGENTS.md) 的表格。

</details>

## 授權

[MIT](LICENSE)。`ime/newcj.cin`（自由大新倉頡）為 Public Domain；桌布由 install.sh 從 Omarchy 下載，不包含在 repo 中。
