# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test

```bash
# Build debug APK
./gradlew assembleDebug

# Run all unit tests
./gradlew testDebugUnitTest

# Run a single test class
./gradlew testDebugUnitTest --tests "com.simpleshift.scheduler.domain.ShiftCalculatorTest"

# Clean and re-run all tests
./gradlew cleanTestDebugUnitTest testDebugUnitTest
```

Tests use JUnit 4 + Robolectric. `testOptions.unitTests.isIncludeAndroidResources = true` is required in `app/build.gradle.kts` for tests that access Android resources (e.g., string resource mapping in ViewModel tests).

## Architecture

**Stack**: Kotlin + Jetpack Compose + MVVM + StateFlow + DataStore Preferences

**Layers** (`app/src/main/java/com/simpleshift/scheduler/`):
- `domain/model/` — Pure Kotlin business models (`ShiftType` enum, `ShiftCycleConfig`, `ShiftInfo`, `CalendarDayInfo`, `Team`, `MonthlyStats`, `RuntimeShiftSettings`, `AlarmSettings`, `CalendarEventIds`). No Android dependencies.
- `domain/` — Pure functions: `shift_calculator.kt` (date offset → cycle index → shift type lookup) and `calendar_generator.kt` (42-cell 7×7 month grid generation). All functions accept optional `teamPhaseOffset`/`customCycle` parameters.
- `viewmodel/` — `HomeViewModel`, `CalendarViewModel`, `SettingsViewModel`. Expose `StateFlow<UiState>`. ViewModels accept injectable `currentDateProvider`/`localeProvider` for testability.
- `ui/` — Compose screens: `HomeScreen`, `CalendarScreen`, `SettingsScreen`. Pure display + event callbacks, no business logic.
- `calendar/` — `CalendarEventManager` (Calendar Provider CRUD via ContentResolver) and `CalendarSyncManager` (auto-sync via `combine` of three DataStore flows + Mutex guard).
- `data/repository/` — `SettingsRepository`: DataStore persistence for shift cycle config, alarm settings, and calendar event ID tracking. Uses comma-separated `ShiftType` enum names for serialization (no extra serialization library).

**Key data flow**: `SettingsRepository` → `MutableStateFlow<RuntimeShiftSettings>` in `MainActivity` → `HomeViewModel.customCycle` / `CalendarViewModel.customCycle` → domain functions. SettingsViewModel writes back through a callback.

**Navigation**: `MainActivity` uses Navigation Compose with two routes: `"main"` (Home + Calendar stacked) and `"settings"`. The `runtimeSettingsFlow` bridges state across ViewModels — no event bus or DI framework.

## Core Algorithm

Shift calculation in `shift_calculator.kt`:
1. `calculateDayOffset(date)` — days between `REFERENCE_DATE` (2025-12-15) and target date
2. `normalizeCycleIndex(offsetDays)` — `(offset % cycleLength + cycleLength) % cycleLength` into `0..cycleLength-1`
3. `getShiftTypeForDate(date, teamPhaseOffset, customCycle)` — offset + phase → lookup in cycle list
4. `getShiftInfo(date, teamPhaseOffset, customCycle)` — aggregate output with `dayOfCycle = cycleIndex + 1`

Default cycle: 42 days, 6 teams, phase offset = `(teamId - 1) * 7`. Custom cycles use `teamPhaseStepFor()` which divides the custom cycle length by 6.

## Calendar Sync

`CalendarSyncManager` watches three DataStore flows via `combine`: settings, alarm settings, and calendar event IDs. Any change triggers a Mutex-guarded sync of the next 7 days' shift events into the system Calendar Provider using a local account (`ACCOUNT_TYPE_LOCAL`). Events persist in the system calendar DB across reboots. Permissions: `READ_CALENDAR` + `WRITE_CALENDAR` (requested at runtime).

## Project Memory

Before writing code, read `memory-bank/architecture.md` (complete file-by-file architecture) and `memory-bank/app-design-document.md` (full design spec). After completing a major feature, update `memory-bank/architecture.md`.
