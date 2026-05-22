# 班伴 · ShiftMate

**倒班人群的生活伴侣** — shift schedule engine written in Rust.

```
banban today          →  🟣 夜班 · 一值 · 第 33/42 天 · 明天休息
banban leave -m 3     →  🏖️ 请 2 天 → 连休 15 天 (中秋+国庆)
banban export --ics   →  生成日历文件，导入 Thunderbird
```

---

## Project Structure

```
SimpleShiftScheduler/
├── shift-core/        ← Rust workspace (主力开发, 111 tests)
│   ├── crates/        ← algorithm, statistics, holidays, leave-opt, ICS export
│   └── cli/           ← banban CLI (9 commands)
├── flutter/           ← Flutter 移动端 (110 tests, dart:ffi → Rust)
├── android/           ← Android 原版 (参考实现, 162 tests)
└── memory-bank/       ← 详细设计文档
```

- **shift-core**：所有排班算法、拼假、统计、ICS 导出，Rust 纯函数
- **banban CLI**：命令行工具，`banban today` / `banban leave` / `banban export --ics`
- **Flutter**：Android/iOS UI，通过 `dart:ffi` 调用 Rust，纯 Dart fallback
- **Android**：功能完整的参考原型，算法已迁移到 Rust

---

## Quick Start

### CLI (Linux)

```bash
cd shift-core
cargo build
cargo run --bin banban -- today
cargo run --bin banban -- calendar
cargo run --bin banban -- leave -m 3
```

### Install

```bash
cargo install --path cli --root ~/.local
~/.local/bin/banban today
```

### Mobile (Flutter)

```bash
cd flutter
flutter test                    # 110 tests
./build_rust_android.sh --run   # Build Rust for ARM64 + deploy to phone
```

### API Docs

```bash
cd shift-core
cargo doc --no-deps --open
```

---

## Features

| 功能 | CLI | Flutter | ICS |
|------|-----|---------|-----|
| 今日班次 + 距休倒计时 | `banban today` | ✅ | — |
| 月历（彩色 ANSI） | `banban calendar` | ✅ | ✅ |
| 月度统计 | `banban stats` | ✅ | — |
| 拼假神器 | `banban leave -m 3` | ✅ | — |
| 同事模式 | `banban colleague 1 3` | ✅ | — |
| ICS 日历导出 | `banban export --ics` | — | ✅ |
| Waybar 状态栏 | `banban waybar` | — | — |
| 桌面 Widget | — | ✅ | — |

---

## Algorithm

42-day cycle, 6 teams, reference date 2025-12-15. All platforms share the same Rust implementation.

| Constant | Value |
|----------|-------|
| Reference date | 2025-12-15 (day 1) |
| Cycle length | 42 days |
| Total teams | 6 (一值～六值) |
| Team offset | (team_id - 1) × 7 days |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Core Domain | Rust (shift-algorithm, shift-statistics, leave-optimizer, holiday-engine, export-engine) |
| CLI | Rust + clap (binary: `banban`) |
| Mobile UI | Flutter + Riverpod + GoRouter |
| FFI Bridge | dart:ffi + package:ffi (JSON over C) |
| Calendar Export | ICS RFC 5545 (hand-rolled, zero deps) |
| Linux Desktop | KDE Plasma Widget, Waybar, DBus (planned) |

---

## Test Summary

| Component | Tests | Status |
|-----------|-------|--------|
| shift-core (Rust) | 111 (82 unit + 29 doctest) | ✅ |
| Flutter FFI bridge | 5 | ✅ |
| Flutter (Dart) | 110 | ✅ |
| Android (reference) | 162 | ✅ archived |
| **Total** | **388** | |

---

## License

MIT
