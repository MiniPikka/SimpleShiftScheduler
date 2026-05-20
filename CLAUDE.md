# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with this monorepo.

## Project Structure

```
SimpleShiftScheduler/          ← git repo root
├── CLAUDE.md                  ← this file
├── memory-bank/               ← shared documentation (both projects)
├── android/                   ← Android 原版 (Kotlin + Compose, Phase 1 完成)
└── flutter/                   ← CP 跨平台版 (Flutter + Riverpod, 迁移进行中)
```

- **Android 版**：功能完整的参考实现，162 tests，不再活跃开发。作为算法参考和产品验证基础。
- **Flutter CP 版**：主力开发目标，72 tests，正在从 Android 版逐步迁移功能。跨 Android / iOS / Web / Desktop。

---

## Android 项目 (`android/`)

### Build & Test

```bash
cd android
./gradlew assembleDebug                    # Build debug APK
./gradlew testDebugUnitTest                # Run all unit tests
./gradlew testDebugUnitTest --tests "com.simpleshift.scheduler.domain.ShiftCalculatorTest"
./gradlew cleanTestDebugUnitTest testDebugUnitTest
```

Tests use JUnit 4 + Robolectric. `testOptions.unitTests.isIncludeAndroidResources = true` is required.

### Architecture

**Stack**: Kotlin + Jetpack Compose + MVVM + StateFlow + DataStore Preferences

**Layers** (`android/app/src/main/java/com/simpleshift/scheduler/`):
- `domain/model/` — Pure Kotlin data classes, no Android deps
- `domain/` — Pure functions: shift_calculator, calendar_generator, shift_metrics, colleague_mode, leave_optimizer, salary_calculator, holiday_data
- `viewmodel/` — HomeViewModel, CalendarViewModel, etc. StateFlow<UiState>
- `ui/` — Compose screens, pure display + callbacks
- `calendar/` — CalendarEventManager (Calendar Provider CRUD), CalendarSyncManager
- `data/repository/` — SettingsRepository (DataStore persistence)

**Core algorithm**: `shift_calculator.kt` — date offset → cycle index → shift type. Default cycle: 42 days, 6 teams, REFERENCE_DATE = 2025-12-15.

### i18n

4 languages (zh/ja/ko/en) via Android resource qualifiers. Always use `stringResource(R.string.xxx)` in Compose, never hardcode user-facing strings.

---

## Flutter CP 项目 (`flutter/`)

### Build & Test

```bash
cd flutter
flutter analyze                # Static analysis
flutter test                   # Run all tests
flutter test --name "produces correct offset"
dart run build_runner build --delete-conflicting-outputs  # After model changes
```

Tests use `flutter_test` + manual assertions, no mocking framework.

### Architecture

**Stack**: Dart/Flutter + Riverpod + GoRouter + Hive + Freezed

**Layers** (`flutter/lib/`):
- `domain/models/` — Pure Dart data classes (same models as Android, Freezed-free)
- `domain/algorithms/` — Pure Dart functions (1:1 migrated from Android domain/)
- `data/repositories/` — SettingsRepository abstract interface + HiveSettingsRepository
- `data/providers.dart` — Riverpod FutureProvider for async Hive init
- `features/` — StateNotifier + ConsumerWidget per feature
- `core/theme/` — Design Token system (colors, typography, spacing, shapes, theme)
- `core/utils/l10n.dart` — Centralized localization helpers
- `app/routes.dart` — GoRouter with StatefulShellRoute (3-tab bottom nav)
- `l10n/` — flutter gen-l10n output (zh/en/ja/ko)

**Key data flow**: HiveSettingsRepository → SettingsNotifier (Riverpod) → homeProvider → domain functions. `selectedTeamProvider` bridges team selection.

### i18n

4 languages via `flutter gen-l10n` + `.arb` files. Never hardcode strings — use `context.l10n` extension or `AppLocalizations.of(context)`.

---

## Domain Algorithm Sync

Both projects share the **same algorithm logic**. When changing one, update the other:

| Android (`android/app/.../domain/`) | Flutter (`flutter/lib/domain/algorithms/`) |
|---|---|
| `shift_calculator.kt` | `shift_calculator.dart` |
| `calendar_generator.kt` | `calendar_generator.dart` |
| `shift_metrics.kt` | `shift_metrics.dart` |
| `leave_optimizer.kt` | `leave_optimizer.dart` |
| `colleague_mode.kt` | `colleague_mode.dart` |
| `salary_calculator.kt` | `salary_calculator.dart` |
| `holiday_data.kt` | `holiday_data.dart` |

Core constants (REFERENCE_DATE=2025-12-15, CYCLE_LENGTH=42, 6 teams) must stay identical.

---

## Project Memory

Before writing code, read:
- `memory-bank/architecture.md` — complete file-by-file architecture
- `memory-bank/app-design-document.md` — full design spec
- `memory-bank/progress.md` — current progress and recent changes

After completing a major feature, update `memory-bank/architecture.md` and `memory-bank/progress.md`.

# 重要提示：
# 写任何代码前必须完整阅读 memory-bank/architecture.md
# 写任何代码前必须完整阅读 memory-bank/app-design-document.md
# 每完成一个重大功能或里程碑后，必须更新 memory-bank/architecture.md 和 progress.md
# 两个项目的 domain 算法必须保持同步
