# 班伴 · ShiftMate

**倒班人群的生活伴侣** — shift schedule engine written in Rust.

```bash
banban today          →  🟣 夜班 · 一值 · 第 33/42 天 · 明天休息
banban leave -m 3     →  🏖️  请 2 天 → 连休 15 天 (中秋+国庆桥接)
banban export --ics   →  生成 ICS 日历文件，导入 Thunderbird
banban waybar         →  {"text":"🌙 夜","class":"night","tooltip":"..."}  Waybar JSON
banban tui            →  全屏终端界面，btop/lazygit 风格
banban serve          →  HTTP API 服务器 (localhost:11451)
```

## Install

```bash
cargo install shift-cli     # from crates.io
banban today
```

[![crates.io](https://img.shields.io/crates/v/shift-cli)](https://crates.io/crates/shift-cli)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

### Arch Linux (AUR)

```bash
yay -S banban
```

## Quick Start

```bash
banban today                    # 看看今天什么班
banban -l zh today              # 中文输出
banban --team 2 today           # 你是二值？试试这个
banban calendar                 # 这个月的排班日历
banban stats                    # 本月统计
banban leave -m 3               # 今年怎么请假最划算
banban colleague 1 3            # 一值和三值哪天能一起休
banban waybar                   # Waybar 状态栏输出 (--lang 切换语言)
banban export --ics --open      # 导出日历并打开 Thunderbird
banban tui                      # 全屏交互界面
banban serve                    # 启动 HTTP API 服务器
banban install                  # 安装 systemd 每日定时提醒
```

## Features

| 功能 | CLI | TUI | Flutter | ICS | Desktop Widget |
|------|-----|-----|---------|-----|----------------|
| 今日班次 + 距休倒计时 | `banban today` | ✅ | ✅ | — | ✅ |
| 明日班次 | `banban tomorrow` | ✅ | ✅ | — | — |
| 周视图 | `banban week` | ✅ | — | — | ✅ |
| 月历（彩色 ANSI/CJK 对齐） | `banban calendar` | ✅ | ✅ | ✅ | — |
| 月度统计 | `banban stats` | ✅ | ✅ | — | — |
| 拼假神器 | `banban leave -m 3` | ✅ + - | ✅ | — | — |
| 同事模式 | `banban colleague 1 3` | ✅ ←→↑↓ | ✅ | — | — |
| ICS 日历导出 | `banban export --ics` | — | — | ✅ | — |
| 全屏 TUI | `banban tui` | ✅ | — | — | — |
| 桌面通知 | `banban notify` | — | — | — | — |
| systemd 定时器 | `banban install` | — | — | — | — |
| Waybar 状态栏 | `banban waybar` | — | — | — | — |
| 桌面 Widget | — | — | ✅ | — | ✅ |

## Desktop Widgets

原生桌面 Widget，零算法重复——直接调用 `banban` CLI 或 `banban serve` HTTP API。

### KDE Plasma 6 Panel Widget

```bash
cd plasma
./install.sh    # 安装 plasmoid + systemd 服务
# 右键面板 → 添加部件 → 搜索 "ShiftMate"
```

- 🟠早 🔵中 🟢休 🟣夜 🟡学 — 彩色 emoji 面板显示
- 点击展开：今日详情 + 距休/连续上班 + 7 天周预览
- 悬停 tooltip：班组、周期进度、距休天数
- 5 分钟自动刷新，`banban serve` HTTP API 通信

### GNOME Shell 45+ Extension

```bash
cd gnome
./install.sh    # 安装扩展
gnome-extensions enable banban-shift@simpleshift.scheduler
```

- 面板 emoji + 短标签，点击弹出菜单
- 60 秒自动刷新，`Gio.Subprocess` 异步调用 CLI

## Waybar Integration

Add to `~/.config/waybar/config.jsonc`:

```json
"custom/banban": {
    "exec": "banban -l zh waybar",
    "interval": 3600,
    "return-type": "json"
}
```

Style with CSS (`~/.config/waybar/style.css`):

```css
#custom-banban.morning { color: #FFB347; }
#custom-banban.afternoon { color: #4DA3FF; }
#custom-banban.rest { color: #35D07F; }
#custom-banban.night { color: #7C5CFF; }
#custom-banban.study { color: #F2D94E; }
```

## Architecture

```
SimpleShiftScheduler/
├── shift-core/        ← Rust workspace (109 tests, 6 crates)
│   ├── crates/        ← algorithm, statistics, holidays, leave-opt, ICS export
│   └── cli/           ← banban CLI + TUI + HTTP serve
├── flutter/           ← Flutter 移动端 + Linux Desktop (110 tests, dart:ffi → Rust)
├── plasma/            ← KDE Plasma 6 面板小部件 (QML, HTTP API)
├── gnome/             ← GNOME Shell 45+ 顶栏扩展 (JS, subprocess CLI)
├── android/           ← Android 参考实现 (148 tests, archived)
└── memory-bank/       ← 详细设计文档
```

**Rust is the single source of truth.** All platforms call the same Rust crates.

| 消费方 | 通信方式 | 刷新间隔 |
|--------|---------|---------|
| CLI / TUI | 直接调用 Rust | — |
| Flutter (FFI) | `dart:ffi` JSON over C | — |
| Flutter (Dart fallback) | 纯 Dart 实现 | — |
| KDE Plasmoid | `XMLHttpRequest` → `banban serve` HTTP API | 5 min |
| GNOME Extension | `Gio.Subprocess` → `banban --json` CLI | 60 s |
| Waybar | `banban waybar` JSON stdout | 用户配置 |

## Algorithm

42-day cycle, 6 teams (一值 ~ 六值), reference date 2025-12-15.

| Constant | Value |
|----------|-------|
| Reference date | 2025-12-15 (day 1) |
| Cycle length | 42 days |
| Total teams | 6 |
| Team offset | (team_id - 1) × 7 days |

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Core Domain | Rust (6 crates) |
| CLI + TUI | Rust + clap + ratatui + crossterm |
| HTTP API | Rust + axum + tokio |
| Calendar Export | ICS RFC 5545 (hand-rolled) |
| Mobile UI | Flutter + Riverpod + GoRouter |
| FFI Bridge | dart:ffi (JSON over C) |
| KDE Widget | QML + PlasmaExtras + XMLHttpRequest |
| GNOME Widget | GJS + PanelMenu.Button + Gio.Subprocess |

## Test Summary

| Component | Tests |
|-----------|-------|
| shift-core (Rust) | 109 |
| Flutter FFI bridge | 9 |
| Flutter (Dart) | 110 |
| Android (reference) | 148 |
| **Total** | **376** |

```bash
cd shift-core && cargo test        # Rust
cd flutter && flutter test         # Flutter
```

## API Docs

```bash
cd shift-core
cargo doc --no-deps --open
```

## License

MIT
