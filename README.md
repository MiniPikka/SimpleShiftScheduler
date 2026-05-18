# Shift Scheduler (倒班助手)

An Android app for shift workers — track rotations, plan leave, find common rest days with colleagues, and calculate shift premiums. Supports Chinese, Japanese, Korean, and English.

## Features

### Core

- **Home Dashboard** — Today's shift type, team name, cycle progress, rest countdown, and work intensity score at a glance
- **Calendar View** — 7×7 monthly grid with color-coded shift types, team switching, and per-type stats
- **Custom Shift Rules** — Two-step wizard editor: build any shift sequence, set a reference start date, choose default team
- **6-Team Support** — Built-in 6 teams with automatic phase offset calculation; custom cycles scale evenly
- **Calendar Reminders** — System Calendar Provider integration with per-shift reminder times via Material3 TimePicker. Survives reboots. Compatible with Xiaomi / Huawei / OPPO / Vivo / Samsung / stock Android
- **Monthly Stats** — Count each shift type in the current month

### Differentiators

- **Leave Planner** — Analyzes your shift schedule + China public holidays (including adjusted workdays) to find optimal leave strategies (fewest leave days → longest break). Scored and ranked
- **Colleague Mode** — Enter two team IDs to find common rest days, next shared day off, and 30/60-day counts. Generate a share card (1080px, with QR code) for WeChat / QQ
- **Shift Premium Calculator** — Set per-shift premiums; auto-calculates monthly total from your schedule. "What-if" simulation for extra shifts
- **Home Screen Widget** — 4×1 Glance widget showing today's shift, rest countdown, and tomorrow preview. Dark themed. Auto-refreshes

### Design

- **Light / Dark Theme** — Auto-follows system dark mode. Design Token system for colors, typography, and shapes
- **Bottom Navigation** — Home / Calendar / Profile tabs. Profile consolidates settings, reminders, and all feature entries
- **Multi-Language** — Chinese (default), Japanese, Korean, English. Android standard resource qualifiers (`values-ja`, `values-ko`, `values-en`)

## Shift Types

| Type | Color |
|------|-------|
| Morning | Orange |
| Afternoon | Blue |
| Rest | Green |
| Night | Purple |
| Training | Yellow |

## Tech Stack

- **Language** — Kotlin 1.9.24
- **UI** — Jetpack Compose + Material3 1.2.x
- **Architecture** — MVVM (Model-View-ViewModel)
- **State** — Kotlin StateFlow
- **Storage** — DataStore Preferences
- **Calendar** — Android Calendar Provider
- **Widget** — Jetpack Glance 1.1.0
- **QR Code** — ZXing 3.5.3
- **Navigation** — Navigation Compose
- **i18n** — Android resource qualifiers (no third-party i18n library)
- **Testing** — JUnit 4 + Robolectric (150+ tests)

## Build Requirements

- Android Studio Hedgehog (2023.1.1) or later
- Gradle 8.4 / AGP 8.2.0
- Compose Compiler 1.5.14 / BOM 2024.04.00
- compileSdk / targetSdk: 34 / minSdk: 24
- JDK 17

## Quick Start

```bash
git clone git@gitee.com:MiniPikka/simple-shift-scheduler.git
# Open in Android Studio, wait for Gradle sync, then run
```

## Project Structure

```
com.simpleshift.scheduler/
├── MainActivity.kt                    # App entry, NavHost routing, cross-VM state sharing
├── calendar/                          # Calendar Provider integration
│   ├── CalendarEventManager.kt        # CRUD wrapper over ContentResolver
│   ├── CalendarResolver.kt            # ContentResolver abstraction (testable)
│   └── CalendarSyncManager.kt         # 2-flow combine auto-sync + Mutex guard
├── data/repository/
│   └── SettingsRepository.kt          # DataStore persistence (rules, alarms, event IDs, premiums)
├── domain/                            # Pure Kotlin business logic (zero Android deps)
│   ├── shift_calculator.kt            # Date→offset→cycle index→shift type
│   ├── calendar_generator.kt          # 42-cell 7×7 month grid
│   ├── shift_metrics.kt              # Monthly stats & streak calculations
│   ├── leave_optimizer.kt            # Gap-merging leave strategy algorithm
│   ├── colleague_mode.kt             # Dual-team cross-comparison
│   ├── salary_calculator.kt          # Premium = Σ(count × rate)
│   ├── holiday_data.kt               # China public holidays (built-in)
│   ├── qr_code_generator.kt          # QR code generation (ZXing)
│   ├── widget_data.kt                # Widget data computation
│   └── model/                         # Domain models (18 data classes, all @Immutable)
├── ui/                                # Compose UI
│   ├── home/HomeScreen.kt             # Single unified home screen (V1–V4 consolidated)
│   ├── calendar/CalendarScreen.kt     # 7×7 calendar + inline stats
│   ├── settings/
│   │   ├── ShiftRuleEditorScreen.kt   # Two-step wizard rule editor
│   │   └── AlarmSettingsScreen.kt     # Material3 TimePicker per shift
│   ├── profile/ProfileScreen.kt       # Feature menu
│   ├── leave_optimizer/               # Leave Planner screen
│   ├── colleague_mode/                # Colleague Mode + ShareCardLayout
│   ├── salary_predictor/              # Shift Premium screen
│   ├── theme/                         # Design Token system (Color/Type/Shape/Theme)
│   └── common/CommonComponents.kt     # Shared TeamDropdown
├── viewmodel/                         # 8 ViewModels (Home, Calendar, Settings, Alarm, ShiftRule,
│                                      #   LeaveOptimizer, ColleagueMode, SalaryPredictor)
├── widget/                            # Glance AppWidget
│   ├── ShiftWidget.kt
│   └── ShiftWidgetReceiver.kt
└── util/                              # Utilities
    ├── ShiftLabelMapper.kt            # ShiftType → localized label (Context-aware)
    ├── TeamNameMapper.kt              # Team ID → localized name
    ├── HolidayNameMapper.kt           # Holiday name → localized display
    └── ShareImageRenderer.kt          # Off-screen ComposeView → Bitmap
```

## Permissions

| Permission | Purpose |
|------------|---------|
| `READ_CALENDAR` | Query system calendar accounts and events |
| `WRITE_CALENDAR` | Write shift reminder events |

## Default Shift Cycle

Default cycle is 42 days with reference date 2025-12-15 (customizable). Six teams, each offset by 7 days.

```
早早中中休夜夜休休早早中中休夜休休休早早中休夜夜休休休早中中休夜夜休休学学学学学休休
```

## i18n

Multi-language support via Android resource qualifiers. To add a new locale:

1. Create `values-<qualifier>/strings.xml` with translated strings
2. All user-facing strings go through `stringResource(R.string.xxx)` (Compose) or `context.getString(R.string.xxx)` (non-Compose)
3. Shift labels: `ShiftLabelMapper.toLabel(context, shiftType)`
4. Team names: `TeamNameMapper.toName(teamId, context)`
5. Holiday names: `HolidayNameMapper.toLocalizedName(chineseName, context)`
6. Domain layer functions use resolver parameters (e.g., `shiftLabelResolver: (ShiftType) -> String`) — never depend on Context

## Testing

```bash
# Run all unit tests (150+)
./gradlew testDebugUnitTest

# Run a single test class
./gradlew testDebugUnitTest --tests "com.simpleshift.scheduler.domain.ShiftCalculatorTest"

# Build debug APK
./gradlew assembleDebug
```

## License

MIT
