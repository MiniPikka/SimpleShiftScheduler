# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with this monorepo.

## Project Structure

```
SimpleShiftScheduler/          ← git repo root
├── CLAUDE.md                  ← this file
├── README.md                  ← project overview
├── memory-bank/               ← detailed docs (architecture, design, progress, plans)
├── shift-core/                ← Rust workspace — the single source of truth for all algorithms
├── android/                   ← Android 原版 (Kotlin + Compose, 参考实现, 不再活跃开发)
└── flutter/                   ← Flutter 移动端 (通过 dart:ffi 调用 Rust)
```

- **shift-core (Rust)**：主力开发目标。6 个 crate：shift-algorithm, shift-statistics, holiday-engine, leave-optimizer, shift-export, shift-cli。CLI 工具 `banban`。
- **Flutter 移动端**：Android/iOS UI。Domain 层已通过 dart:ffi 接入 Rust，纯 Dart 保留为 fallback。
- **Android 原版**：参考实现，148 tests，不再活跃开发。算法已验证。

---

## shift-core (Rust 工作区)

### Build & Test

```bash
cd shift-core
cargo build                    # 编译所有 crate + CLI
cargo test                     # 全部测试 (109 tests)
cargo test --doc               # 文档示例测试
cargo doc --no-deps --open     # 生成并打开 API 文档
cargo clippy --all-targets     # Lint 检查
cargo run --bin banban -- today  # 运行 CLI
```

### Architecture

**Workspace crates** (`shift-core/crates/`):

| Crate | 职责 | Tests |
|-------|------|-------|
| `shift-algorithm` | 核心排班算法：date → offset → index → shift type | 27 |
| `shift-statistics` | 月度统计、连续上班、距休、同事模式 | 18 |
| `holiday-engine` | 2026-2027 中国法定节假日 + 调休数据 | 12 |
| `leave-optimizer` | 间隙桥接法拼假算法 | 14 |
| `shift-export` | ICS (RFC 5545) 日历导出 | 11 |

**CLI** (`shift-core/cli/`)：二进制名为 `banban`（产品同名，避免与 bash `shift` 冲突）。

**算法常量**（与 Android/Flutter 一致）：
- REFERENCE_DATE = 2025-12-15（第 1 天）
- CYCLE_LENGTH = 42 天
- TOTAL_TEAMS = 6（一值～六值）
- Team offset = (team_id - 1) × 7 天

### 关键规则

- **所有 domain 算法只在 Rust 中维护**。Android/Flutter 调用 Rust，不存在多语言同步问题。
- `cargo test --doc` 编译运行文档示例——修改函数签名时必须更新对应的 doc example。
- 公开 API 变更后运行 `cargo doc --no-deps` 确认文档无 broken links。
- CLI 二进制名是 `banban`，不是 `shift`（bash 内置命令冲突）。

---

## Flutter 移动端 (`flutter/`)

### Build & Test

```bash
cd flutter
flutter pub get
flutter analyze
flutter test                   # 110 tests
flutter build apk --debug
```

### Android 部署

```bash
cd flutter
./build_rust_android.sh        # Rust → ARM64 .so
flutter run -d <device_id>     # 或者 ./build_rust_android.sh --run
```

### Linux Desktop 部署

```bash
cd flutter
./build.sh                     # Rust FFI + Flutter Linux release，.so 自动打包
./package.sh                   # 生成 tar.gz 分发包
./install_linux.sh             # 安装到 /usr/local
```

Linux 桌面版特性：
- 响应式 UI：`NavigationRail` 侧边栏（≥720px）/ `NavigationBar` 底部栏（<720px）
- 键盘快捷键：Ctrl+1/2/3 切标签、Ctrl+Q 退出、Esc 返回
- ICS 自动导出到 `~/.local/share/banban/shifts.ics`
- 系统通知通过 DBus libnotify
- `banban` CLI 功能（Waybar、systemd、DBus）不重复实现

### Architecture

```
Flutter (Dart)                          Rust
─────────────                           ────
lib/domain/algorithms/
  shift_calculator.dart ──dart:ffi──►   flutter/rust/ (cdylib)
  shift_metrics.dart    ──dart:ffi──►     └── shift-core crates
  colleague_mode.dart   ──dart:ffi──►
  leave_optimizer.dart  ──dart:ffi──►

lib/domain/bridge/
  ffi_bridge.dart       ← Dart FFI 绑定层 (JSON over C)
```

**FFI 策略**：每个 migrated 函数优先走 Rust FFI，失败时自动回退纯 Dart（Web 平台或库未编译）。

### 关键规则

- FFI 返回 null 时调用方必须 fallback 到纯 Dart 实现。
- 修改 Rust 函数签名后需同步更新 `flutter/rust/src/lib.rs` 和 `ffi_bridge.dart`。
- 新增 FFI 函数后在 `flutter/rust/` 中加测试，然后 `cargo test`。

---

## Android 原版 (`android/`)

### Build & Test

```bash
cd android
./gradlew assembleDebug
./gradlew testDebugUnitTest    # 148 tests
```

**状态**：参考实现。算法已验证正确，不再活跃开发。domain 层代码已全部迁移到 Rust。

---

## 文档体系

| 文件 | 用途 |
|------|------|
| `CLAUDE.md` | Claude Code 工作指导（本文件） |
| `README.md` | 项目概览（给人看） |
| `shift-core/README.md` | Rust workspace 说明 |
| `memory-bank/architecture.md` | 完整架构文档 |
| `memory-bank/app-design-document.md` | 产品设计文档 |
| `memory-bank/progress.md` | 开发进度记录 |
| `memory-bank/implementation-plan.md` | 实施计划 |
| `memory-bank/tech-stack.md` | 技术栈详情 |
| `cargo doc --no-deps` | Rust API 文档（自动生成） |

### AI 工作流程

1. 写代码前：读 `memory-bank/architecture.md` + `memory-bank/progress.md`
2. 改算法：只改 `shift-core/`，然后同步更新 Flutter FFI bridge
3. 完成后：更新 `memory-bank/progress.md`，如有架构变化更新 `memory-bank/architecture.md`
4. Rust 代码改动后必跑：`cargo test && cargo clippy --all-targets && cargo doc --no-deps`
5. Flutter 代码改动后必跑：`flutter test && flutter analyze`
