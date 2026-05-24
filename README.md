# 班伴 · ShiftMate

**倒班人群的生活伴侣** — shift schedule engine written in Rust.

```bash
banban today          →  🟣 夜班 · 一值 · 第 33/42 天 · 明天休息
banban leave -m 3     →  🏖️  请 2 天 → 连休 15 天 (中秋+国庆桥接)
banban export --ics   →  生成 ICS 日历文件，导入 Thunderbird
banban waybar         →  {"text":"🌙 夜","class":"night","tooltip":"..."}  Waybar JSON
banban tui            →  全屏终端界面，btop/lazygit 风格
```

## Install

```bash
cargo install shift-cli     # from crates.io
banban today
```

[![crates.io](https://img.shields.io/crates/v/shift-cli)](https://crates.io/crates/shift-cli)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

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
banban install                  # 安装 systemd 每日定时提醒
```

## Features

| 功能 | CLI | TUI | Flutter | ICS |
|------|-----|-----|---------|-----|
| 今日班次 + 距休倒计时 | `banban today` | ✅ | ✅ | — |
| 明日班次 | `banban tomorrow` | ✅ | ✅ | — |
| 周视图 | `banban week` | ✅ | — | — |
| 月历（彩色 ANSI/CJK 对齐） | `banban calendar` | ✅ | ✅ | ✅ |
| 月度统计 | `banban stats` | ✅ | ✅ | — |
| 拼假神器 | `banban leave -m 3` | ✅ + - | ✅ | — |
| 同事模式 | `banban colleague 1 3` | ✅ ←→↑↓ | ✅ | — |
| ICS 日历导出 | `banban export --ics` | — | — | ✅ |
| 全屏 TUI | `banban tui` | ✅ | — | — |
| 桌面通知 | `banban notify` | — | — | — |
| systemd 定时器 | `banban install` | — | — | — |
| Waybar 状态栏 | `banban waybar` | — | — | — |
| 桌面 Widget | — | — | ✅ | — |

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

Customize display labels in `~/.config/banban/config.toml`:

```toml
[display]
waybar_morning = "🌅 早"
waybar_afternoon = "☀️ 中"
waybar_rest = "🌿 休"
waybar_night = "🌙 夜"
waybar_study = "📚 学"
```

Run `banban -l en waybar` for English output, or set `--lang zh` for Chinese.

## Architecture

```
SimpleShiftScheduler/
├── shift-core/        ← Rust workspace (109 tests)
│   ├── crates/        ← algorithm, statistics, holidays, leave-opt, ICS export
│   └── cli/           ← banban CLI + TUI (17 commands)
├── flutter/           ← Flutter 移动端 (110 tests, dart:ffi → Rust)
├── android/           ← Android 参考实现 (148 tests, archived)
└── memory-bank/       ← 详细设计文档
```

**Rust is the single source of truth.** All platforms (CLI, TUI, Flutter, ICS export) call the same Rust crates.

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
| Core Domain | Rust (5 crates) |
| CLI + TUI | Rust + clap + ratatui + crossterm |
| Calendar Export | ICS RFC 5545 (hand-rolled) |
| Notifications | notify-rust + DBus + systemd |
| Mobile UI | Flutter + Riverpod + GoRouter |
| FFI Bridge | dart:ffi (JSON over C) |

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
