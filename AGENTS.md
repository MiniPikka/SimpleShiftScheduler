# SimpleShiftScheduler (倒班助手)

Android shift scheduling application for managing rotating shift schedules.

## Project Overview

- **Platform**: Android
- **Language**: Kotlin
- **UI Framework**: Jetpack Compose
- **Architecture**: MVVM with StateFlow

## Key Features

- **Home Page**: Display today's shift info and progress (e.g., "进度 / 本轮天数")
- **Shift Calendar**: 7×7 calendar showing monthly shift schedule
- **Team Management**: Support 6 teams with rotating shifts
- **Statistics**: Count shift types (早班/中班/休息班/夜班/学习班) per month

## Shift Rotation Pattern

One cycle = 42 days, 6 teams. Pattern:
```
早早中中休夜夜休休早早中中休夜休休休早早中休夜夜休休休早中中休夜夜休休学学学学学休休
```

Shift types: 早班 (morning), 中班 (afternoon), 休息班 (rest), 夜班 (night), 学习班 (study)

## Build Commands

```bash
# Build debug APK
./gradlew assembleDebug

# Build release APK
./gradlew assembleRelease
```

## Important Files

| File | Purpose |
|------|---------|
| `memory-bank/app-design-document.md` | Full app design specification |
| `memory-bank/tech-stack.md` | Technology choices and rationale |

## Development Notes

- All planned stages (1-8) are complete: home page, shift calendar, team management, statistics, and settings page with custom shift rules
- Follow the tech-stack.md guidelines: Kotlin + Jetpack Compose + MVVM + StateFlow
- Keep UI simple: calendar grid + dropdown for team selection + statistics button

# 重要提示：
# 写任何代码前必须完整阅读 memory-bank/architecture.md（包含完整项目架构和文件职责）
# 写任何代码前必须完整阅读 memory-bank/app-design-document.md
# 每完成一个重大功能或里程碑后，必须更新 memory-bank/architecture.md