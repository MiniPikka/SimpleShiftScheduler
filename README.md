# Shift Scheduler (倒班助手)

Shift worker assistant — track rotations, plan leave, find common rest days, calculate shift premiums. Android (Kotlin + Compose) and Cross-Platform (Flutter + Riverpod). Supports Chinese, Japanese, Korean, and English.

---

## Project Structure

```
SimpleShiftScheduler/
├── android/        ← Android 原生版 (Kotlin + Compose, 完成, 162 tests)
├── flutter/        ← Flutter CP 版 (主力开发, 107 tests)
├── memory-bank/    ← 共享文档
└── README.md
```

- **Android 版**：功能完整，作为算法参考和产品验证基础，不再活跃开发。
- **Flutter CP 版**：主力开发目标，跨 Android / iOS / Web / Desktop。

---

## Features (Flutter CP)

### Core
- **Home Dashboard** — Today's shift, team, cycle progress, rest countdown, work intensity
- **Calendar View** — 7×7 monthly grid with color-coded shifts, per-type stats (早/中/休/夜/学)
- **Custom Shift Rules** — Single-page editor: cycle length, presets (42/7/14 day), add/delete shift chips, date picker, team selector
- **6-Team Support** — Automatic phase offset calculation, custom cycles scale evenly
- **Shift Reminders** — Dual system: `flutter_local_notifications` (notification bar) + Calendar Provider (system calendar events with alerts). Dedup logic prevents duplicates
- **Home Screen Widget** — 4×1 RemoteViews widget: today's shift badge, rest countdown, tomorrow preview

### Differentiators
- **Leave Planner** — Analyzes shift schedule + China public holidays to find optimal leave strategies
- **Colleague Mode** — Input two teams to find common rest days. Share as image with QR code
- **Shift Premium Calculator** — Per-shift premiums with inline editing, month navigation, auto-persisting

### Design
- **Dark / Light Theme** — Auto-follows system dark mode. Design Token system
- **Bottom Navigation** — Home / Calendar / Profile tabs
- **Multi-Language** — Chinese (default), English, Japanese, Korean

---

## Tech Stack

### Flutter CP
| Layer | Technology |
|-------|-----------|
| UI | Flutter |
| State | Riverpod (StateNotifier + FutureProvider) |
| Routing | GoRouter (StatefulShellRoute) |
| Storage | Hive |
| Domain | Pure Dart (no platform deps) |
| Calendar | Android Calendar Provider (MethodChannel) |
| Notifications | flutter_local_notifications + permission_handler |
| Widget | RemoteViews (Android) |
| i18n | flutter gen-l10n (.arb) |
| Testing | flutter_test (107 tests) |

### Android (Reference)
| Layer | Technology |
|-------|-----------|
| Language | Kotlin 1.9.24 |
| UI | Jetpack Compose + Material3 |
| Architecture | MVVM + StateFlow |
| Storage | DataStore Preferences |
| Widget | Jetpack Glance 1.1.0 |
| Testing | JUnit 4 + Robolectric (162 tests) |

---

## Quick Start

### Flutter CP
```bash
cd flutter
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
# Or use: ./install.sh
```

### Android (Reference)
```bash
cd android
./gradlew assembleDebug
./gradlew testDebugUnitTest
```

---

## Domain Algorithm Sync

Both projects share the same algorithm logic. When changing one, update the other:

| Android (`android/.../domain/`) | Flutter (`flutter/lib/domain/algorithms/`) |
|---|---|
| `shift_calculator.kt` | `shift_calculator.dart` |
| `calendar_generator.kt` | `calendar_generator.dart` |
| `shift_metrics.kt` | `shift_metrics.dart` |
| `leave_optimizer.kt` | `leave_optimizer.dart` |
| `colleague_mode.kt` | `colleague_mode.dart` |
| `salary_calculator.kt` | `salary_calculator.dart` |
| `holiday_data.kt` | `holiday_data.dart` |

Core constants: `REFERENCE_DATE = 2025-12-15`, `CYCLE_LENGTH = 42`, 6 teams.

---

## Architecture

Both projects follow the same layered architecture:

```
UI Layer (Compose / Flutter Widget)
  └── State Management (ViewModel+StateFlow / Riverpod Notifier)
        └── Domain Layer (Pure Kotlin / Pure Dart, zero platform deps)
              └── Data Layer (DataStore / Hive, Calendar Provider)
```

**Key principle**: All shift calculation is pure domain logic. Flutter CP's `CalendarEventManager.kt` (Android native code) receives pre-computed events from Dart via MethodChannel — the algorithm lives in only one place.

---

## Recent Changelog (Flutter CP)

| Date | Change |
|------|--------|
| 2026-05-21 | Shift rule editor (single-page, presets, inline editing) |
| 2026-05-21 | Salary predictor (persistence, inline editing, month/team nav) |
| 2026-05-21 | Calendar dedup + date fix + widget robustness |
| 2026-05-21 | Algorithm refactor: Dart single source, Kotlin platform glue |
| 2026-05-20 | Phase 3.3 Widget upgrade + 3.2 Notifications + 3.1 i18n |
| 2026-05-20 | Phase 2: Core features migration complete |

---

## Permissions (Flutter CP Android)

| Permission | Purpose |
|------------|---------|
| `POST_NOTIFICATIONS` | Notification bar reminders |
| `READ_CALENDAR` | Query system calendar |
| `WRITE_CALENDAR` | Write shift reminder events |

---

## License

MIT
