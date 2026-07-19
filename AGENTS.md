# SimpleShiftScheduler (班伴 · ShiftMate)

**倒班人群的生活伴侣** — 多平台倒班排班应用生态。

## Project Overview

- **Rust Core** (`shift-core/`): 算法唯一来源，6 crates + CLI + TUI + HTTP API
- **Flutter** (`flutter/`): 移动端 + Linux Desktop，dart:ffi 调用 Rust
- **HarmonyOS** (`harmony/`): 华为鸿蒙原生版，ArkTS + ArkUI，纯 ArkTS 算法实现。hvigor modelVersion 6.0.0，DevEco Studio 26 构建中
- **Desktop Widgets** (`plasma/`, `gnome/`): KDE Plasma + GNOME Shell 桌面小组件

> 注：最早的 Kotlin + Jetpack Compose 原生 Android 参考实现（`android/`）已于 2026-07-19 移除，见 git 历史。

## Architecture

Rust 是算法唯一来源（single source of truth）。各平台通过不同方式调用：
- Flutter → dart:ffi (JSON over C)，Dart fallback
- HarmonyOS → 纯 ArkTS 算法实现（不依赖 Rust）
- CLI/TUI → 直接调用 Rust
- Desktop Widgets → HTTP API 或 CLI subprocess

## Shift Rotation Pattern

42-day cycle, 6 teams. Reference date: 2025-12-15.
```
早早中中休夜夜休休早早中中休夜休休休早早中休夜夜休休休早中中休夜夜休休学学学学学休休
```

Shift types: 早班(morning), 中班(afternoon), 休息班(rest), 夜班(night), 学习班(study)

## Build Commands

```bash
# Rust CLI
cd shift-core && cargo build --release

# Flutter
cd flutter && flutter build apk

# Flutter + Rust FFI for Android (先构建 Rust .so, 再 build apk)
# 需要: ANDROID_HOME 已设置, cargo-ndk 已安装, Rust Android targets 已添加
cd flutter
# 设置环境变量（若未设置）
export ANDROID_HOME=/home/zxl/Android/Sdk
export PATH=$PATH:/home/zxl/flutter-sdk/flutter/bin
# 构建 Rust 库 for Android arm64
./build_rust_android.sh
# 或构建全部 4 个 ABI
./build_rust_android.sh --all
# 构建 APK
flutter build apk --debug
# 或安装
./install.sh

# Flutter + Rust FFI for Linux Desktop
cd flutter && ./build.sh

# HarmonyOS (需要 DevEco Studio 26+, Windows/macOS)
# 用 DevEco 打开 harmony/ 目录，Build → Build Hap(s)
# hvigor modelVersion 6.0.0, plugin 6.26.1
```

## Important Files

| File | Purpose |
|------|---------|
| `memory-bank/architecture.md` | 完整项目架构和文件职责 |
| `memory-bank/app-design-document.md` | 详细设计规范 |
| `memory-bank/tech-stack.md` | 技术选型和理由 |

## Development Notes

- 阅读 `memory-bank/architecture.md` 了解完整架构
- 阅读 `memory-bank/app-design-document.md` 了解设计规范
- 每完成重大功能后更新 `memory-bank/architecture.md`
