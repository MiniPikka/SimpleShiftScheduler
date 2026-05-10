# 倒班助手 (SimpleShiftScheduler)

一个专为轮班制工作者设计的 Android 应用，帮助你轻松追踪和规划倒班安排。

## 功能特性

- **首页仪表盘** — 一眼看到今日班次、当前班组、周期进度
- **月历视图** — 7×7 网格日历，不同班次类型用不同颜色区分，支持月份切换
- **自定义排班规则** — 自由编辑周期长度（1-100 天）和每天班次类型
- **多班组支持** — 内置 6 个班组，切换班组自动偏移排班相位
- **日历提醒** — 通过系统日历实现提醒，兼容小米/华为/OPPO/Vivo，重启自动恢复
- **月度统计** — 查看当月每种班次的天数分布

## 班次类型

| 类型 | 日历颜色 |
|------|----------|
| 早班 | 🟠 橙色 |
| 中班 | 🔵 蓝色 |
| 休息 | 🟢 绿色 |
| 夜班 | 🟣 紫色 |
| 学习 | 🟡 浅黄 |

## 技术栈

- **语言** — Kotlin
- **UI** — Jetpack Compose + Material3
- **架构** — MVVM (Model-View-ViewModel)
- **状态管理** — Kotlin StateFlow
- **数据持久化** — DataStore Preferences
- **日历集成** — Android Calendar Provider
- **测试** — JUnit 4 + Robolectric

## 构建要求

- Android Studio Hedgehog (2023.1.1) 或更新版本
- Gradle 8.4
- Android Gradle Plugin 8.2.0
- compileSdk / targetSdk: 34
- minSdk: 24 (Android 7.0)
- JDK 17

## 快速开始

```bash
# 克隆仓库
git clone git@gitee.com:<your-username>/SimpleShiftScheduler.git

# 用 Android Studio 打开项目目录，等待 Gradle 同步完成后运行
```

## 项目结构

```
com.simpleshift.scheduler/
├── MainActivity.kt                 # 应用入口
├── calendar/                       # 日历提醒模块
│   ├── CalendarEventManager.kt     # Calendar Provider 封装
│   ├── CalendarResolver.kt         # ContentResolver 抽象
│   └── CalendarSyncManager.kt      # 自动同步管理器
├── data/repository/
│   └── SettingsRepository.kt       # DataStore 持久化仓储
├── domain/                         # 核心业务逻辑（纯 Kotlin）
│   ├── shift_calculator.kt         # 排班计算算法
│   ├── calendar_generator.kt       # 月历网格生成
│   └── model/                      # 领域模型
├── ui/                             # Compose UI
│   ├── home/HomeScreen.kt          # 首页
│   ├── calendar/CalendarScreen.kt  # 日历页
│   └── settings/SettingsScreen.kt  # 设置页
├── viewmodel/                      # ViewModel 层
└── util/                           # 工具类
```

## 权限

| 权限 | 用途 |
|------|------|
| `READ_CALENDAR` | 读取系统日历账户和日程 |
| `WRITE_CALENDAR` | 写入日历提醒日程 |

## 默认排班规则

默认周期为 42 天，参考起始日为 2025-12-15，6 个班组之间相位偏移 7 天。

```
早早中中休夜夜休休早早中中休夜休休休早早中休夜夜休休休早中中休夜夜休休学学学学学休休
```

## License

MIT
