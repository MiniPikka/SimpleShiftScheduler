# 倒班助手架构说明

## 0. 项目双阶段概述

- **Phase 1（已完成）**：Android 原生版 — 单模块 Kotlin + Jetpack Compose + MVVM + StateFlow + DataStore。阶段 1-27 全部完成，150+ 单元测试全部通过。
- **Phase 2（规划中）**：CP（Cross Platform）版 — Flutter + Riverpod + GoRouter，跨 Android / iOS / Web / Desktop。算法从 Android 版直接迁移（纯 Domain 层）。

---

# Part A：CP（Cross Platform）版架构

## A.1 总体架构

```
┌──────────────────────────────────────────┐
│ UI Layer (Flutter)                       │
│ ├── features/ (home/calendar/...)       │
│ ├── core/theme/ (Design Token)          │
│ └── app/ (GoRouter + MaterialApp)       │
├──────────────────────────────────────────┤
│ State Management (Riverpod)             │
│ ├── StateNotifier / AsyncNotifier       │
│ └── ConsumerWidget / HookConsumerWidget │
├──────────────────────────────────────────┤
│ Domain Layer (Pure Dart)                │
│ ├── models/ (Freezed data classes)      │
│ ├── algorithms/ (shift/leave/colleague) │
│ └── 零平台依赖、零 UI 依赖               │
├──────────────────────────────────────────┤
│ Data Layer                              │
│ ├── repositories/ (抽象接口)             │
│ ├── datasources/ (Hive/Isar 实现)       │
│ └── services/ (通知/分享/权限)           │
└──────────────────────────────────────────┘
```

## A.2 核心架构原则

### A.2.1 UI 与业务彻底解耦

UI：Flutter Widget + 页面状态 + 动画。Domain：排班算法、拼假算法、日期计算、统计逻辑——全部纯函数化。保证 Android / iOS / Web / Desktop 行为完全一致。

### A.2.2 Domain 纯函数化

所有核心逻辑无平台依赖、无 UI 依赖、无生命周期依赖。从 Android 版 Java/Kotlin domain 层直接翻译为 Dart 纯函数。

### A.2.3 平台能力抽象

平台相关能力（通知、Widget、分享、本地存储、权限）全部通过抽象接口实现，各平台有独立实现。

## A.3 CP 项目结构

```text
lib/
 ├── app/
 │    ├── app.dart              # MaterialApp + GoRouter + Theme
 │    └── routes.dart            # GoRouter 路由定义
 │
 ├── core/
 │    ├── theme/
 │    │    ├── colors.dart       # Design Token 颜色
 │    │    ├── typography.dart   # 字体层级
 │    │    ├── spacing.dart      # 间距系统
 │    │    ├── shapes.dart       # 圆角系统
 │    │    └── theme.dart        # ThemeData 组装
 │    ├── constants/
 │    │    └── app_constants.dart
 │    ├── utils/
 │    │    └── date_utils.dart
 │    ├── services/
 │    │    ├── notification_service.dart
 │    │    ├── share_service.dart
 │    │    └── storage_service.dart
 │
 ├── features/
 │    ├── home/
 │    │    ├── home_screen.dart
 │    │    ├── widgets/          # HeroCard, StatsGrid, ToolsRow
 │    │    └── home_notifier.dart (Riverpod)
 │    ├── calendar/
 │    │    ├── calendar_screen.dart
 │    │    └── calendar_notifier.dart
 │    ├── leave_optimizer/
 │    │    ├── leave_optimizer_screen.dart
 │    │    └── leave_optimizer_notifier.dart
 │    ├── colleague_mode/
 │    │    ├── colleague_mode_screen.dart
 │    │    └── colleague_mode_notifier.dart
 │    ├── salary_predictor/
 │    │    ├── salary_predictor_screen.dart
 │    │    └── salary_predictor_notifier.dart
 │    ├── profile/
 │    │    ├── profile_screen.dart
 │    │    └── profile_notifier.dart
 │
 ├── domain/
 │    ├── models/
 │    │    ├── shift_type.dart         # Freezed 枚举
 │    │    ├── shift_cycle_config.dart
 │    │    ├── shift_info.dart
 │    │    ├── leave_strategy.dart
 │    │    ├── common_rest_result.dart
 │    │    ├── salary_config.dart
 │    │    └── salary_breakdown.dart
 │    ├── algorithms/
 │    │    ├── shift_calculator.dart   # 从 Android 版迁移
 │    │    ├── calendar_generator.dart
 │    │    ├── shift_metrics.dart
 │    │    ├── leave_optimizer.dart
 │    │    ├── colleague_mode.dart
 │    │    ├── salary_calculator.dart
 │    │    └── holiday_data.dart
 │
 ├── data/
 │    ├── repositories/
 │    │    ├── settings_repository.dart  # 抽象接口
 │    │    └── settings_repository_hive.dart  # Hive 实现
 │    ├── datasources/
 │    │    └── local_datasource.dart
 │
 └── main.dart
```

## A.4 从 Android 版到 CP 版的迁移映射

| Android 版 | CP 版 |
|-----------|-------|
| `domain/model/ShiftType.kt` | `domain/models/shift_type.dart` (Freezed) |
| `domain/shift_calculator.kt` | `domain/algorithms/shift_calculator.dart` |
| `domain/leave_optimizer.kt` | `domain/algorithms/leave_optimizer.dart` |
| `domain/colleague_mode.kt` | `domain/algorithms/colleague_mode.dart` |
| `domain/salary_calculator.kt` | `domain/algorithms/salary_calculator.dart` |
| `domain/holiday_data.kt` | `domain/algorithms/holiday_data.dart` |
| `viewmodel/HomeViewModel.kt` | `features/home/home_notifier.dart` (Riverpod) |
| `data/repository/SettingsRepository.kt` | `data/repositories/settings_repository.dart` |
| `ui/theme/` (Compose) | `core/theme/` (Flutter ThemeData) |
| `ui/home/NewHomeScreenV3.kt` | `features/home/home_screen.dart` |
| Jetpack Glance Widget | `home_widget` plugin |
| Calendar Provider (Android) | `flutter_local_notifications` |
| DataStore Preferences | Hive / Isar |

## A.5 CP 版本阶段规划

| 阶段 | 内容 | 关键产出 |
|------|------|---------|
| **阶段 1** | Flutter 骨架 | Design Token + GoRouter + 首页 |
| **阶段 2** | 核心功能迁移 | 倒班算法 + 日历 + 拼假神器 + 同事模式 |
| **阶段 3** | 平台能力 | 通知 + 分享长图 + Widget + 多语言 |
| **阶段 4** | 产品化 | Supabase 集成 + Auth + 数据同步 |
| **阶段 5** | 增长 | ASO + 分享裂变 + 应用商店上架 |

## A.6 CP 版日历日程集成（新增）

### 架构决策

Flutter CP 版同时使用两套提醒系统，互补保障：
- **本地通知**（`flutter_local_notifications`）：通知栏弹出，用户实时感知
- **系统日历日程**（Calendar Provider）：写入手机日历 App，持久化 + 系统提醒

### Dart ↔ Kotlin 数据流

```
main.dart _reschedule()
  ├── scheduleShiftNotifications()          ← 本地通知（Dart 纯 Flutter）
  └── CalendarService.syncShiftEvents()     ← MethodChannel 桥接
        └── MainActivity.kt (CALENDAR_CHANNEL)
              └── CalendarEventManager.syncShiftEvents()
                    ├── EventIdStorage.load()    ← 读取已追踪 event ID
                    ├── 两层去重：
                    │     Tier 1: tracked ID map 查重
                    │     Tier 2: findExistingEvent() 按标题+日期查系统日历
                    ├── insertEvent()             ← 仅新建未追踪事件
                    └── EventIdStorage.save()     ← 持久化更新后 ID
```

### 去重机制

对齐 Android 参考版 `CalendarEventManager` 设计：

1. **Event ID 追踪**：`CalendarEventIds`（`Map<String, Long>`），key = `"yyyy-MM-dd_X"`（X = 班次索引 0~4），value = 系统日历 event ID
2. **持久化**：`EventIdStorage` 用 SharedPreferences 存储（因 Flutter CP 无 DataStore），序列化格式 `"key=id,key=id"`
3. **两层查重**：① 内存 map 命中 → 跳过 ② 系统日历查询（按 CALENDAR_ID + TITLE + DTSTART 当天范围）→ 找到则记录跳过
4. **过期清理**：sync 完成后删除 tracked ID 中不再需要的旧事件
5. **并发防护**：`main.dart` 中 300ms 去抖 + `_isSyncingCalendar` guard + `_needsResync` 排队

### 新增文件

| 文件 | 用途 |
|------|------|
| `android/.../calendar/CalendarEventIds.kt` | Event ID 追踪数据模型 |
| `android/.../calendar/EventIdStorage.kt` | SharedPreferences 持久化 |
| `lib/core/services/calendar_service.dart` | Dart → Kotlin MethodChannel 桥接 |

---

## A.7 CP 版 Widget 架构（RemoteViews）

### 架构决策

Widget 使用 **RemoteViews**（Android 标准 AppWidget API），不使用 Glance。原因：

- RemoteViews 是 API 1+ 标准组件，所有 Android 启动器必须支持
- Glance 编译为 RemoteViews 底层同一机制，额外增加 Compose 编译层复杂度
- Glance 对某些 Compose API（如 `LocalContext.current`）不支持内联，编译易失败
- 当前项目 RemoteViews 方案逻辑正确，问题在配置细节而非框架选择

### Widget 数据流

```
Flutter Dart (home_screen.dart)
  → WidgetService.update() [MethodChannel]
    → MainActivity.kt
      → SharedPreferences("widget_prefs")
      → sendBroadcast(ACTION_APPWIDGET_UPDATE)
        → ShiftWidgetProvider.onUpdate()
          → 读取 SharedPreferences
          → 构建 RemoteViews (R.layout.shift_widget_layout)
          → AppWidgetManager.updateAppWidget()
```

### 鲁棒性措施

| 措施 | 说明 |
|------|------|
| `android:initialLayout` | 指向 `@layout/shift_widget_layout`，系统放置 Widget 时立即可见 |
| 小圆点改用 TextView | 替代裸 `<View>` + 反射设置背景色，使用 `android:background` 声明式颜色 |
| PendingIntent fallback | `getLaunchIntentForPackage` 返回 null 时用显式 Intent |
| 根布局可点击 | 未配置状态下点击任何位置可打开 App |
| try-catch 包裹反射调用 | 所有 `setInt("setBackgroundColor")` 防崩溃 |

## A.8 CP 版倒班津贴架构

### 数据流

```
SalaryConfigNotifier (Riverpod StateNotifier)
  ├── 构造时从 Hive salary_config Box 加载
  ├── updatePremium(type, value) → 即时写入 Hive
  └── salaryConfigProvider → UI ConsumerWidget 订阅

SalaryPredictorScreen
  ├── 读取 salaryConfigProvider（津贴金额）
  ├── 读取 settingsProvider（倒班周期 + referenceDate）
  ├── 本地状态：_year, _month, _teamId, _extraCount, _extraType
  ├── countAllShiftTypesInMonth() → 各班次次数
  ├── calculateSalaryBreakdown() → 本月津贴
  └── simulateExtraShifts() → 假设分析
```

### 组件结构

| 组件 | 功能 |
|------|------|
| 可折叠设置卡片 | 展开后 4 行编辑区（早/中/夜/学），OutlinedTextField + 小数输入 |
| 月份班组行 | ← 上月 / 当月标签 / 下月 → + 班组 DropdownButton |
| 津贴总额卡片 | 渐变背景 + 大字体 ¥金额 |
| 班次统计行 | 5 行彩色圆点 + 次数 + 小计金额 |
| 假设分析卡片 | 0~5 FilterChip + 班次类型下拉 + 增量结果 |

## A.9 CP 版倒班规则自定义架构

### 数据流

```
ShiftRuleNotifier (Riverpod StateNotifier)
  ├── 构造时 loadSettings() 初始化状态
  ├── addShift/removeShift/setCycleLength → isDirty=true
  └── save() → 构建 RuntimeShiftSettings
        → settingsProvider.notifier.update(settings)
        → Hive 持久化 → 首页/日历/津贴页自动刷新 + 日历日程重排

ShiftRuleScreen
  ├── 读取 shiftRuleProvider（周期长度/序列/日期/班组）
  ├── 本地 TextEditingController 同步周期长度
  └── PopScope + isDirty 防误退
```

### 组件结构

| 组件 | 功能 |
|------|------|
| 周期长度 TextField | 数字键盘，修改后自动 REST 填充/截断 |
| 预设 ActionChip | 默认42天/7天/14天/清空 |
| 添加按钮行 | 5 个彩色 FilledTonalButton（早/中/休/夜/学） |
| Chip 列表 | Wrap 展示，序号+彩色圆点+label，X 删除 |
| 日期+班组卡片 | showDatePicker + DropdownButton |
| 预览卡片 | 前 20 项彩色圆点 + 班组间隔信息 |
| 保存按钮 | isDirty 可点击 → isSaved 绿色确认 → 2秒后消失 |

---

# Part B：Phase 1 Android 版架构（已完成）

## B.1 当前架构阶段

阶段 1-27 全部完成。应用功能完整，架构采用单模块 Android 应用，技术路线为 Kotlin + Jetpack Compose + MVVM + StateFlow。

### 2026-05-18：多语言支持（阶段 27）

支持中文（默认）、日本語、한국어、English 四种语言。采用 Android 标准资源方案：`values/strings.xml`（zh 默认）、`values-ja/`、`values-ko/`、`values-en/`。

**i18n 架构要点**：
- `ShiftLabelMapper.toLabel(context, shiftType)` — Context-based 班次标签映射
- `TeamNameMapper.toName(teamId, context)` — 班组名本地化
- `HolidayNameMapper.toLocalizedName(chineseName, context)` — 节假日名本地化
- Domain 层 `computeWidgetShiftData()` 接受 `shiftLabelResolver` / `teamNameResolver` 函数参数，保持纯函数
- `Team` 数据类仅存 `id`，移除硬编码 `name` 字段
- Widget 字符串在 `provideGlance()` 中通过 `context.getString()` 预解析
- `CalendarEventManager` 日历日程标题使用 `R.string.calendar_event_*` 资源

### 首页架构简化

移除多轨并行策略（V1/V2/V3/V4），所有旧版首页及组件已删除。`HomeScreen.kt` 为唯一首页，所有 Composable 内联。

已完成的功能：
- 阶段 1-15：全部功能（项目骨架、数据模型、核心算法、首页 UI、测试、日历页、班组切换 + 月度统计、设置页、日历提醒、代码加固、桌面 Widget）
- 阶段 16：首页精品化升级（NewHomeScreen + 组件化 UI）
- 2026-05-14a：日历独立路由（NavHost 三路由）、TodayShiftCard 横向重设计、Widget 美化（距休 + 简化进度）
- 阶段 17：V2 UI 设计系统（Design Token + 深色主题 + 底部导航栏 + Profile 页 + 牛马指数）
- 阶段 18：倒班规则编辑器重设计（两步向导 + referenceDate 贯穿全栈）
- 阶段 19：拼假神器（请假优化器）
- 阶段 20：同事模式（社交裂变）
- 阶段 21：倒班津贴计算器
- 阶段 22：图片分享功能（社交传播）
- 阶段 23：提醒时间选择器改进（Material3 TimePicker）
- 阶段 24：Material3 1.2.x deprecation cleanup
- 夜班提醒日期修复（NIGHT 班次日历事件前移一天）
- 2026-05-15：V3 首页精品化重构已完成（`NewHomeScreenV3` + 6 个 V3 组件，`USE_NEW_HOME_V3 = true`）
- 2026-05-15：阶段 26 提醒设置增强已完成（说明卡片 + 小米 ExtendedProperties 修复 + 系统闹钟增强）
- 阶段 25-26 详细规划见 `memory-bank/implementation-plan.md`
- 2026-05-17：App 图标重设计（三 S 三曲臂 triskelion 图案）+ V4 首页协调化重设计（统一卡片语言、圆形徽章英雄卡片）+ 倒班津贴支持小数输入（Int → Double）+ 性能优化（@Immutable 注解、runBlocking 移除、日历同步反馈循环修复、R8 开启）+ Widget V2 升级（深色主题、明日预览、回退数据改善）+ Widget 更新优化（快照比较去重、实例复用、异常日志）

### 阶段 26 架构更新：提醒设置增强（已完成，最简方案）

#### 说明卡片

`AlarmSettingsScreen` 顶部新增信息说明卡片，解释 Calendar Provider 提醒机制、夜班前移、重启不丢失，引导用户在系统日历 App 中管理通知设置。

#### 设计原则

保持最简 Calendar Provider 方案（日程 + METHOD_ALERT 提醒），不附加非标准厂商 hack 或自建 AlarmManager。提醒方式由系统日历 App 管理。

当前原则：

- 先完成最小可运行骨架，再逐步填充领域模型与业务逻辑
- 业务计算放在 domain 层，UI 仅负责状态展示
- 数据模型职责明确分层，避免 UI/Domain/Data 混杂
- 每次增量修改后执行单元测试验证

---

## 2. 目录与文件职责

以下仅描述当前已存在的关键路径与文件作用。

### `app/src/main/java/com/simpleshift/scheduler/MainActivity.kt`

- 应用入口 Activity
- 使用 Navigation Compose 管理三个独立路由：`"main"`（首页）→ `"calendar"`（日历页）→ `"settings"`（设置页）
- 在 `onResume()` 中触发 `refreshToday()` + `refresh()` + `syncFromCurrentState()` + `notifyWidgetUpdate()`
- 持有 `MutableStateFlow<RuntimeShiftSettings>` 作为跨 ViewModel 共享状态
- 通过编译时常量 `USE_NEW_HOME` 控制首页走 NewHomeScreen（当前 `true`）或旧 HomeScreen
- 底部显示日历同步错误 Snackbar（10 秒自动消失）

### `app/src/main/java/com/simpleshift/scheduler/ui/home/`

- 首页 UI 模块目录
- **旧首页** `HomeScreen`（保留，`USE_NEW_HOME=false` 时启用）：四行平铺班组下拉框 + 日期 + 班次 + 进度
- **新首页** `NewHomeScreen`（默认，`USE_NEW_HOME=true`）：组件化布局
  - `TeamDropdown` — 班组下拉框（6 班组）
  - `GreetingHeader` — 时段问候 + 班组名 + 日期
  - `TodayShiftCard` — 横向班次主卡片（4dp 左侧强调条 + 64dp 圆形徽章 + 距休标识 + `LinearProgressIndicator`）
  - `StatsGrid` — 三宫格指标（本月上班/连续上班/距休班）
  - `QuickActionsRow` — 快捷操作（日历/提醒/设置）
  - `MotivationFooter` — 底部随机励志文案
- `components/` 子目录存放 5 个独立 UI 组件，各有独立 Preview
- 保持”纯展示 + 事件上抛”职责，不放排班计算逻辑

### `app/src/main/java/com/simpleshift/scheduler/ui/calendar/`

- 日历 UI 模块目录
- 已实现 `CalendarScreen`：
  - `Scaffold` + `TopAppBar`（返回箭头 + 标题”倒班日历”）
  - `TeamDropdown` 班组下拉框（切换同步首页 ViewModel）
  - 月份导航栏（上月/下月 + “今天”按钮（非当前月时显示）+ 统计按钮）
  - 周标题（`日~六`）
  - 42 格（6×7）日历，每格展示”日期 + 班次简写”，`aspectRatio(0.85f)` 自适应
  - `StatsDialog`（`AlertDialog`）展示当月早/中/休/夜/学天数
- 接受回调：`onPreviousMonthClick`、`onNextMonthClick`、`onTodayClick`、`onStatsClick`、`onDismissStats`、`onNavigateBack`、`onTeamSelected`

### `app/src/main/java/com/simpleshift/scheduler/viewmodel/`

- ViewModel 层目录
- 已实现 `HomeViewModel` 与 `HomeUiState`
- `HomeUiState` 结构：`todayDate/shiftType/shiftLabel/dayOfCycle/totalDays/selectedTeamId/availableTeams`
- `selectTeam(teamId)`：更新班组选择并刷新今日班次
- `refreshToday()` 每次调用时：
  - 使用 `LocalDate.now()` 获取今日
  - 基于 `(selectedTeamId - 1) * 7` 计算 `teamPhaseOffset`
  - 调用 domain 层 `getShiftInfo(today, teamPhaseOffset)` 获取计算结果
  - 将 `ShiftType` 通过资源映射为 `早/中/休/夜/学`
  - 更新 `StateFlow<HomeUiState>` 供 Compose 订阅
- 为提升可测性，`HomeViewModel` 支持注入日期与 Locale 提供器：
  - `currentDateProvider: () -> LocalDate`
  - `localeProvider: () -> Locale`
- 已实现 `CalendarViewModel` 与 `CalendarUiState`
  - 管理当前显示月份（`YearMonth`）和选中班组（`selectedTeamId`）
  - 输出 `monthLabel/weekLabels/days/stats`
  - 提供 `goToPreviousMonth()/goToNextMonth()/refresh()`
  - 提供 `setTeam(teamId)` 同步班组选择
  - 提供 `computeStats()` 统计当月班次、`dismissStats()` 关闭统计弹窗
- `CalendarUiState.stats: MonthlyStats?`（null 表示不显示弹窗）

### `app/src/main/java/com/simpleshift/scheduler/domain/model/`

- 核心业务模型目录（Domain Model）
- 已实现 `ShiftType`（英文枚举）、`ShiftCycleConfig`（周期配置）
- 已实现 `ShiftInfo`（`date/dayOfCycle/shiftType`）
- 已实现 `CalendarDayInfo`（`date/shiftType/isCurrentMonth`）
- **阶段 7 新增**：
  - `Team`（`id/name`，含 `companion object` 提供 `TOTAL_TEAMS=6` 和 `ALL_TEAMS`）
  - `MonthlyStats`（5 个 Int 字段：早/中/休/夜/学计数）
- **阶段 8 新增**：
  - `RuntimeShiftSettings`（`cycleLength/shiftCycle/defaultTeamId` + `isValid` 校验）
  - 默认值等于 `ShiftCycleConfig`（42 天、固定数组、班组 1）
- `ShiftCycleConfig` 持有固定业务基线：
  - `CYCLE_LENGTH = 42`
  - `REFERENCE_DATE = 2025-12-15`
  - `SHIFT_CYCLE: List<ShiftType>`（42 天固定轮转数组）
- 这些模型不依赖 Android UI 细节，强调可测试性与稳定性
- 班组偏移公式：`teamPhaseOffset = (teamId - 1) * (CYCLE_LENGTH / TOTAL_TEAMS)` = `(teamId - 1) * 7`

### `app/src/main/java/com/simpleshift/scheduler/domain/shift_calculator.kt`

- 核心排班算法统一入口文件（domain 层）
- 提供纯函数能力：
  - `calculateDayOffset(date)`：计算目标日期相对起始日的偏移天数
  - `normalizeCycleIndex(offsetDays)`：将偏移归一化到 `0..41`
  - `getShiftTypeForDate(date, teamPhaseOffset = 0)`：按周期索引得到班次
  - `getShiftInfo(date, teamPhaseOffset = 0)`：聚合输出 `ShiftInfo(date, dayOfCycle, shiftType)`
- 全部函数接受 `teamPhaseOffset` 和 `customCycle` 默认参数（默认值保证向后兼容）
- 统一使用 `ShiftCycleConfig` 作为默认配置源，`customCycle` 非 null 时优先使用
- 班组偏移计算：`calculateDayOffset(date) + teamPhaseOffset` → 归一化(cycle.size) → 索引查表(cycle)
- **阶段 8**：`customCycle` 参数使设置页的自定义规则直接生效于计算层

### `app/src/main/java/com/simpleshift/scheduler/domain/calendar_generator.kt`

- 新增月历网格生成函数 `generateMonthCalendarDays(yearMonth, firstDayOfWeek, teamPhaseOffset = 0)`
- 以周日为起始生成固定 42 天网格，用于 7×7 日历渲染
- 每格产出 `CalendarDayInfo(date, shiftType, isCurrentMonth)`，并复用 `getShiftTypeForDate(date, teamPhaseOffset)` 计算班次
- 接受 `teamPhaseOffset` 支持班组感知的日历生成

### `app/src/test/java/com/simpleshift/scheduler/domain/ShiftCalculatorTest.kt`

- 覆盖阶段 5.1 核心算法验收点：
  - 偏移计算（正向/负向/跨周期）
  - 周期索引归一化（`0..41`）
  - `getShiftInfo(date)` 对 `dayOfCycle/shiftType` 的输出稳定性
- **阶段 7 新增**：`teamPhaseOffset` 参数测试（偏移 7/14/35 的班组切换场景）

### `app/src/test/java/com/simpleshift/scheduler/domain/CalendarGeneratorTest.kt`

- 覆盖阶段 6.1 核心验收点：
  - 输出固定 42 格
  - 默认首格为周日
  - `isCurrentMonth` 标记正确
- **阶段 7 新增**：`teamPhaseOffset` 参数不影响日期和数量，仅偏移班次类型

### `app/src/test/java/com/simpleshift/scheduler/viewmodel/HomeViewModelTest.kt`

- 覆盖阶段 5.2 首页状态验收点：
  - 初始化状态是否正确产出 `todayDate/shiftType/shiftLabel/dayOfCycle/totalDays`
  - `refreshToday()` 在日期变更后是否刷新状态
  - 班次文案映射是否固定为 `早/中/休/夜/学`
- **阶段 7 新增**：
  - `selectedTeamId` 和 `availableTeams` 初始化验证
  - `selectTeam(teamId)` 切换后班次和数据流刷新验证

### `app/build.gradle.kts`（测试配置 + 阶段 8 依赖）

- 单元测试已开启 Android 资源支持：
  - `testOptions.unitTests.isIncludeAndroidResources = true`
- **阶段 8 新增依赖**：
  - `navigation-compose:2.7.6` — Navigation Compose 页面路由
  - `datastore-preferences:1.0.0` — DataStore 持久化

### `app/src/main/java/com/simpleshift/scheduler/data/repository/SettingsRepository.kt`

- **阶段 8 新增**：DataStore Preferences 持久化仓储
- 保存/加载 `RuntimeShiftSettings`（cycleLength, shiftCycle 逗号分隔串, defaultTeamId）
- 解析失败自动回退到默认值
- 提供 `settingsFlow: Flow<RuntimeShiftSettings>` 和 `suspend saveSettings()`

### `app/src/main/java/com/simpleshift/scheduler/ui/leave_optimizer/`（阶段 19）

- 拼假神器 UI 模块
- `LeaveOptimizerScreen.kt`：策略卡片列表 + 说明区

### `app/src/main/java/com/simpleshift/scheduler/ui/colleague_mode/`（阶段 20）

- 同事模式 UI 模块
- `ColleagueModeScreen.kt`：双班组选择 + 共同休息结果卡片 + 日期列表

### `app/src/main/java/com/simpleshift/scheduler/ui/salary_predictor/`（阶段 21 规划）

- 工资预测 UI 模块
- `SalaryPredictorScreen.kt`：津贴设置区 + 倒班津贴主卡片 + 班次统计 + 假设分析

### `app/src/main/java/com/simpleshift/scheduler/ui/settings/`

- **阶段 8 新增**：设置页 UI 模块
- 已实现 `SettingsScreen`：
  - `TopAppBar` + 返回按钮（`isDirty` 时弹出确认对话框）
  - 周期长度输入框（`OutlinedTextField`，数字键盘）
  - 班次网格编辑器（`LazyVerticalGrid(4列)`，每格: 第N天 + ShiftType 下拉框）
  - 默认班组下拉框（`ExposedDropdownMenuBox`）
  - 保存/取消按钮
  - 保存成功提示文字

### `app/src/main/java/com/simpleshift/scheduler/data/model/`

- 数据层模型目录（Data Model）
- 预留给数据库实体、持久化扩展模型、数据源映射对象
- 与 `domain/model` 分离，避免把存储形态直接暴露给业务层

### `app/src/main/res/values/strings.xml`

- 已承载首页班次文案资源：
  - `shift_label_morning/afternoon/rest/night/study`
- ViewModel 通过资源 ID 映射，保证领域枚举与展示文案解耦

---

## 3. 新的架构洞察（阶段 6 迭代）

### 洞察 A：模型分层先于功能开发

在第 1 步就建立 `domain/model` 与 `data/model` 双目录，可提前锁定边界，减少后续返工。即使 data 层尚未实现，目录预留也能约束代码落位，避免“先写先乱”。

### 洞察 B：入口文件尽量轻量化但承担生命周期刷新

`MainActivity` 保持轻量装配职责，同时在 `onResume()` 触发刷新，能用最低复杂度满足“前后台切换自动更新今日班次”的需求，不需要额外引入复杂生命周期中间层。

### 洞察 C：先验证“可启动”再推进算法

先确保项目配置、包名、最小 SDK 与基础目录均稳定，再进入枚举/周期算法阶段，可降低“环境问题干扰业务实现”的概率。

### 洞察 D：展示与计算分离带来稳定演进路径

“英文枚举 + 资源映射中文简写”已在首页落地，Domain 保持稳定英文语义，文案可在资源层独立调整，不会影响核心算法。

### 洞察 E：周期与起点配置集中化

将周期数组、周期长度和起始参考日集中在 `ShiftCycleConfig`，避免分散硬编码。后续算法实现只依赖这一个配置入口，可降低索引计算和维护过程中的口径偏差。

### 洞察 F：算法拆分后可被 ViewModel 直接复用

将偏移、归一化、取班次、聚合输出拆为独立函数后，ViewModel 可直接调用统一入口 `getShiftInfo()`，避免在 UI 层重复实现日期与索引计算细节。

### 洞察 G：通过“可注入时间源”稳定 ViewModel 测试

在不改变生产行为的前提下，为 ViewModel 注入可替换的日期来源，可让单元测试稳定覆盖“初始化”和“刷新”路径，避免对真实系统时间产生耦合。

### 洞察 H：资源映射应有端到端测试保护

`ShiftType -> 文案资源 -> UI 字符串` 的链路不仅是展示细节，也属于用户可见契约。为 `早/中/休/夜/学` 建立测试，可降低后续重构或文案调整导致的回归风险。

### 洞察 I：日历网格应固定 42 格，UI 简化明显

将月历统一为 6×7 固定格数，可减少 Compose 布局分支判断，保持渲染稳定，也方便后续叠加“选中态/统计态”等交互。

### 洞察 J：日历与首页复用同一 domain 算法

`CalendarViewModel` 不单独维护班次规则，而是复用 `getShiftTypeForDate()`，可以保证首页与日历页班次口径完全一致，降低跨页面不一致风险。

---

## 4. 阶段 7 架构更新：班组切换 + 月度统计（已完成）

### 洞察 K：班组切换通过 `teamPhaseOffset` 参数实现，不改变核心算法

班组切换本质是给日期偏移量加一个 `teamPhaseOffset`（`=(teamId-1)*7`），6 个班组之间各间隔 7 天。`shift_calculator` 和 `calendar_generator` 均接受 `teamPhaseOffset` 参数（默认 0），向后兼容。

### 洞察 L：月度统计是日历数据的聚合

统计功能对 `generateMonthCalendarDays(currentMonth)` 的结果按 `ShiftType` 分组计数，通过 `AlertDialog` 展示。`CalendarUiState` 新增 `stats: MonthlyStats?` 字段控制弹窗显隐。

### 洞察 M：班组选择在首页，同步到日历

`HomeScreen` 新增 `ExposedDropdownMenuBox` 班组下拉框。选中班组后通过 `MainActivity` 同步调用 `homeViewModel.selectTeam()` 和 `calendarViewModel.setTeam()`，保证首页和日历班次口径一致。

### 洞察 N：默认参数保证向后兼容

所有 domain 函数新增 `teamPhaseOffset: Int = 0`，原有调用点无需修改，测试用例无需批量重构。

### 洞察 O：ViewState 用可空字段控制 UI 弹窗

`CalendarUiState.stats: MonthlyStats?` — null 表示隐藏弹窗，非 null 表示显示。这是 Compose 中控制 AlertDialog 显隐的惯用模式，避免额外 `Boolean` 标志。

### 阶段 7 新增文件

- `app/src/main/java/com/simpleshift/scheduler/domain/model/Team.kt` — 班组数据模型（6 个固定班组）
- `app/src/main/java/com/simpleshift/scheduler/domain/model/MonthlyStats.kt` — 月度统计模型

### 阶段 7 改造文件

- `HomeViewModel` — 新增 `selectedTeamId`/`availableTeams` 状态和 `selectTeam()` 方法
- `HomeScreen` — 新增班组下拉框
- `CalendarViewModel` — 新增 `setTeam()`/`computeStats()`/`dismissStats()` 方法
- `CalendarScreen` — 新增统计按钮和 `StatsDialog`
- `shift_calculator` — 全部函数新增 `teamPhaseOffset` 默认参数
- `calendar_generator` — 新增 `teamPhaseOffset` 默认参数
- `MainActivity` — 接线班组切换事件和统计回调

---

## 5. 阶段 9 架构更新：闹钟提醒（已完成，后续被阶段 10 替换）

阶段 9 实现了 AlarmManager + BroadcastReceiver 闹钟方案（每班次独立时间、7 天前瞻调度、BootReceiver 重启恢复），随后在阶段 10 被 Calendar Provider 方案替换以解决国产手机杀后台问题。数据模型 `AlarmTime` / `AlarmSettings` 保留，UI 基本不变。

---

## 6. 阶段 8 架构更新：设置页自定义规则（已完成）

### 洞察 P：默认值分层保证向后兼容

`ShiftCycleConfig` 保持不可变默认值，`RuntimeShiftSettings` 承载用户修改。所有 domain 函数用 `customCycle: List<ShiftType>? = null` 模式：null 时回退默认，非 null 时使用自定义。修改不影响已有测试和代码路径。

### 洞察 Q：Activity 级 StateFlow 实现跨 ViewModel 通信

`MainActivity` 持有 `MutableStateFlow<RuntimeShiftSettings>`，SettingsViewModel 写入，HomeViewModel/CalendarViewModel 通过读取 `customCycle` 字段消费。避免事件总线或接口注入的复杂度，对小应用足够。

### 洞察 R：DataStore 用逗号分隔枚举名简化序列化

不引入 `kotlinx.serialization` 依赖，`ShiftType` 枚举名用逗号拼接（如 `"MORNING,AFTERNOON,REST"`）存入 DataStore 字符串 key。反序列化时 `ShiftType.valueOf()` + 捕获异常回退默认值。缺点是 42 天周期时字符串较长（约 350 字符），但在 DataStore 容量范围内。

### 洞察 S：LazyVerticalGrid 适合动态周期编辑

4 列网格使 42 天周期约 10 行，每个单元格内嵌 `ExposedDropdownMenuBox`。修改周期长度时列表自动截断或 REST 填充，无需额外 UI 分支。

### 阶段 8 新增文件

- `app/src/main/java/com/simpleshift/scheduler/domain/model/RuntimeShiftSettings.kt` — 运行时周期配置
- `app/src/main/java/com/simpleshift/scheduler/viewmodel/SettingsViewModel.kt` — 设置页 ViewModel
- `app/src/main/java/com/simpleshift/scheduler/ui/settings/SettingsScreen.kt` — 设置页 UI
- `app/src/main/java/com/simpleshift/scheduler/data/repository/SettingsRepository.kt` — DataStore 持久化
- `app/src/test/java/com/simpleshift/scheduler/viewmodel/SettingsViewModelTest.kt` — 设置页 ViewModel 测试

### 阶段 8 改造文件

- `build.gradle.kts` — 新增 navigation-compose + datastore-preferences
- `shift_calculator.kt` — 全部函数新增 `customCycle` 参数
- `calendar_generator.kt` — 新增 `customCycle` 参数透传
- `HomeViewModel.kt` — `customCycle` 字段 + 动态 `teamPhaseStep()`
- `CalendarViewModel.kt` — `customCycle` 字段 + 动态 `teamPhaseStep()`
- `MainActivity.kt` — NavHost 双路由 + SettingsRepository 集成 + 状态共享
- `ShiftCalculatorTest.kt` — 追加 customCycle 测试用例

---

## 7. 阶段 10 架构更新：闹钟改为日历日程（已完成）

阶段 9 原有的 AlarmManager 方案已替换为 Calendar Provider 方案。

### 迁移原因

- AlarmManager 在国产手机上被各厂商杀后台机制严重影响，闹钟延迟或丢失
- Calendar Provider 是 AOSP 标准 API（API 14+），所有 Android 品牌必须支持，提醒由系统日历同步适配器管理，优先级高于普通闹钟
- 日历日程持久化在系统日历数据库，重启自动恢复，无需 `BootReceiver`
- 减少权限依赖：`SCHEDULE_EXACT_ALARM` + `POST_NOTIFICATIONS` + `RECEIVE_BOOT_COMPLETED` → `READ_CALENDAR` + `WRITE_CALENDAR`

### 新增 calendar 包

`app/src/main/java/com/simpleshift/scheduler/calendar/` 替代原有的 `alarm/` 包。

### `CalendarEventManager.kt`

日历日程管理器（非 Android 组件，纯 Kotlin 类包装 ContentResolver）：
- `getOrCreateLocalCalendar()` — 查询现有本地日历账户，不存在则用 `ACCOUNT_TYPE_LOCAL` 创建，返回 calendarId
- `syncShiftEvents(alarmSettings, shiftCycle, teamPhaseOffset, existingEventIds, daysAhead = 365)` — 计算未来 365 天（一整年）日程并同步到系统日历，已有的日程跳过，stale 的日程移除
- 同步策略：对比日程变化 → 有变化删旧插新、无变化跳过、窗口外的 stale 日程自动清理
- 每个日程设置 `CalendarContract.Reminders.METHOD_ALERT`（准时提醒，系统弹出通知）
- 日程标题："早班提醒"，时长 15 分钟
- 返回 `CalendarEventIds`（date+shiftType → eventId 映射）供持久化
- `deleteEvents(eventIds)` — 按 eventId 批量删除日程
- `deleteAllEventsForTypes(eventIds)` — 删除所有已追踪日程

### `CalendarEventIds.kt`

日程事件 ID 追踪模型：
```kotlin
data class CalendarEventIds(
    val eventIds: Map<String, Long> = emptyMap()  // key = "yyyy-MM-dd_SHIFT_TYPE"
)
```
存储于 DataStore，格式：`"2026-05-09_MORNING=42,2026-05-10_MORNING=43"`

### 保留的模型

- `AlarmTime.kt` — 保留，仅表示提醒时间（hour, minute），语义不变
- `AlarmSettings.kt` — 保留，仅表示每个班次的提醒时间设置

### 删除的组件

- `AlarmScheduler.kt` → 被 `CalendarEventManager` 替代
- `AlarmReceiver.kt` → 日历系统自动触发提醒，不再需要自定义 BroadcastReceiver
- `BootReceiver.kt` → 日程持久化在日历数据库，重启无需恢复
- `ic_alarm.xml` → 不再需要自定义通知图标
- 旧测试：`AlarmSchedulerTest.kt`、`AlarmReceiverTest.kt`

### 洞察 T：提醒设置独立自动保存（保留）

提醒时间修改通过 `onAlarmSettingsChanged` 回调立即自动保存到 DataStore + 触发日历日程同步。`cancel()` 只还原倒班周期设置，不重置提醒时间。即使用户修改提醒后直接返回而不保存周期设置，提醒也不会丢失。

### 洞察 U：CalendarSyncManager 封装 combine 三流自动同步

`CalendarSyncManager` 封装 `combine(settingsRepository.settingsFlow, settingsRepository.alarmSettingsFlow, settingsRepository.calendarEventIdsFlow)` 三流合并逻辑，任一流变化时自动调用 `CalendarEventManager.syncShiftEvents(daysAhead = 365)` 更新系统日历日程。`syncFromCurrentState()` 提供按需强制同步入口（`onResume` 调用 + 设置保存后调用），使用 Mutex 防止并发同步。

### 洞察 V：提醒使用默认班组计算日期（保留）

日历日程的日期计算使用 `RuntimeShiftSettings.defaultTeamId`，而非首页的瞬时班组选择。提醒设置是用户全局配置，不受临时班组切换影响。

### 洞察 W：跨品牌本地日历策略

使用 `CalendarContract.Calendars` 查询后创建本地日历账户（`ACCOUNT_TYPE_LOCAL`），日程存储在设备本地，不依赖 Google 账户、不同步云端。小米/华为/OPPO/Vivo/三星/原生 Android 全支持。

### 阶段 10 新增文件

- `app/src/main/java/com/simpleshift/scheduler/calendar/CalendarEventManager.kt` — 日历日程管理器
- `app/src/main/java/com/simpleshift/scheduler/calendar/CalendarResolver.kt` — ContentResolver 抽象接口 + 实现（开启测试能力）
- `app/src/main/java/com/simpleshift/scheduler/calendar/CalendarSyncManager.kt` — 自动同步调度器（combine 三流 + Mutex 防竞态）
- `app/src/main/java/com/simpleshift/scheduler/domain/model/CalendarEventIds.kt` — 日程 ID 追踪模型
- `app/src/test/java/com/simpleshift/scheduler/calendar/CalendarEventManagerTest.kt` — 日程管理器测试（含 FakeCalendarResolver）

### 阶段 10 删除的文件

- `app/src/main/java/com/simpleshift/scheduler/alarm/AlarmScheduler.kt`
- `app/src/main/java/com/simpleshift/scheduler/alarm/AlarmReceiver.kt`
- `app/src/main/java/com/simpleshift/scheduler/alarm/BootReceiver.kt`
- `app/src/main/res/drawable/ic_alarm.xml`
- `app/src/test/java/com/simpleshift/scheduler/alarm/AlarmSchedulerTest.kt`
- `app/src/test/java/com/simpleshift/scheduler/alarm/AlarmReceiverTest.kt`

### 阶段 10 改造文件

- `SettingsRepository.kt` — 新增 `calendarEventIdsFlow` + `saveCalendarEventIds()` + eventId 键值
- `MainActivity.kt` — 移除通知渠道、AlarmScheduler、combine 双流闹钟调度，替换为 CalendarEventManager + 权限请求
- `AndroidManifest.xml` — 移除 3 个闹钟权限 + 2 个 receiver，新增日历读写权限
- `strings.xml` — 移除通知相关字符串（渠道名、通知标题/正文）

---

## 8. 阶段 11-14 架构更新：鲁棒性加固与完善（已完成）

2026-05-13 全项目审查后规划 4 个改进阶段，覆盖 Bug 修复、测试补全、代码整洁和文档同步。

### 审查发现的架构问题

1. **`SettingsViewModel.cancel()` 回退逻辑缺陷** — `savedSettings` 是 `val`，永远指向构造函数初始值。多次保存后取消会回退到最初状态而非最后保存状态。修复：改为 `var` 并在 `save()` 中更新。

2. **`CalendarSyncManager` 异常静默吞掉** — `syncFromCurrentState()` 中 `catch (_: Exception) {}` 使日历同步失败完全不可见。修复：新增 `syncErrorFlow: StateFlow<String?>` 暴露错误。

3. **`CalendarViewModel` 测试性不一致** — `refresh()` 中直接调用 `LocalDate.now()`，而 `HomeViewModel` 已建立注入模式。修复：新增 `todayProvider: () -> LocalDate` 构造参数。

4. **日历网格高度硬编码** — `Modifier.height(430.dp)` 在不同密度屏幕下布局不稳。修复：`LazyVerticalGrid` → 常规 `Column`+`Row` 7×7 布局，每个日期格使用 `aspectRatio(0.85f)` 自适应宽高比。`LazyVerticalGrid` 在 `verticalScroll` 父容器中产生无限高度约束 Crash，非 lazy 布局从根本上解决。

5. **缺失"回到今天"按钮** — 用户无限切换月份后无法一键返回。修复：`CalendarViewModel` 新增 `goToToday()`。

6. **测试覆盖盲区** — `CalendarViewModel`（零覆盖）、`SettingsRepository`（零覆盖）、`CalendarSyncManager`（零覆盖）。

7. **重复代码** — 三处 `mapShiftLabel`/`shiftTypeToLabel` 包装 + 两处内联 `TeamDropdown` 实现。

8. **文档过时** — architecture.md 中 `syncNextSevenDays` 描述与实际 365 天不符；tech-stack.md 阶段 9/10 混淆。

### 洞察 X：savedSettings 应为可变引用

`SettingsViewModel` 的 `savedSettings` 必须在每次 `save()` 成功时更新为当前已保存值。`cancel()` 的语义是"回退到最近一次保存状态"，而非"回退到进入页面时的状态"。这是状态管理模式的基础要求。

### 洞察 Y：系统性异常静默是鲁棒性反模式

`CalendarSyncManager` 中的 `catch (_: Exception) {}` 违反了"至少记录、最好上报"原则。对于后台同步类操作，应在不影响主流程的前提下将错误状态暴露给 UI 层，让用户有机会通过重试或检查权限来修复。

### 洞察 Z：测试性不应对齐不一致

`HomeViewModel` 已实现 `currentDateProvider` 注入模式，`CalendarViewModel` 也应统一使用 `todayProvider`。项目中任何需要"今天"概念的组件都应支持注入，否则测试只能依赖真实系统时间，导致测试不稳定或无法覆盖特定日期的边界情况。

### 计划新增/改造文件（阶段 11-13）

| 阶段 | 新增文件 | 改造文件 |
|------|---------|---------|
| 11 | — | `SettingsViewModel.kt`, `CalendarSyncManager.kt`, `CalendarViewModel.kt`, `CalendarScreen.kt`, `MainActivity.kt` |
| 12 | `CalendarViewModelTest.kt`, `SettingsRepositoryTest.kt` | `SettingsViewModelTest.kt`（追加 1 个取消测试） |
| 13 | `ui/common/CommonComponents.kt`（可选） | `HomeViewModel.kt`, `CalendarViewModel.kt`, `SettingsScreen.kt`, `HomeScreen.kt` |
| 14 | — | memory-bank 全部 4 个文件 |

### 预期最终状态

- 所有已知 Bug 修复，cancel() 行为正确
- 日历同步失败对用户可见（Snackbar 提示）
- `CalendarViewModel` 支持日期注入，测试覆盖 9 个用例
- `SettingsRepository` 序列化/反序列化测试覆盖 7 个用例
- 日历网格响应式适配不同屏幕
- 日历页支持一键回到今天
- 代码无重复包装函数，共用组件提取
- memory-bank 文档准确反映代码状态

---

## 9. 阶段 15 架构更新：桌面小组件（已完成）

2026-05-13 规划桌面 Widget 功能，使用 Jetpack Glance 实现 Compose 式 Widget 开发。

### 技术选型：Jetpack Glance

Glance 提供 Compose 式 API 开发 AppWidget，底层编译为 RemoteViews，保证系统兼容性。相比传统 RemoteViews XML 方式，Glance 与项目现有 Compose 代码风格一致，学习成本低。

### 新增 widget 包

`app/src/main/java/com/simpleshift/scheduler/widget/` 承载 Widget 相关代码。

### `widget_data.kt`

Widget 专用数据计算（domain 层）：
- `WidgetShiftData` — Widget 显示数据：`dateLabel/shiftLabel/shiftType/dayOfCycle/totalDays/teamName`
- `computeWidgetShiftData(today, settings, locale)` — 纯函数，复用 `getShiftInfo()` + `ShiftLabelMapper.toLabel()`
- `settings.isValid == false` 时返回兜底数据（shiftLabel="?"）

### `ShiftWidget.kt`

GlanceAppWidget 实现：
- `ShiftWidget : GlanceAppWidget` — `provideGlance()` 中从 `SettingsRepository` 读取最新配置，调用 `computeWidgetShiftData()` 计算数据
- `ShiftWidgetContent(data, context)` — Widget UI 布局（Compose 风格但使用 GlanceModifier）
  - 班组名 + 日期
  - 今日班次（圆角徽章 + 彩色底白字）
  - 周期进度文本"第 X/Y 天" + 距休信息
  - 点击打开 `MainActivity`

### `ShiftWidgetReceiver.kt`

`GlanceAppWidgetReceiver` 子类，系统通过它实例化 `ShiftWidget`。

### Widget 更新策略

更新触发源（三重保障）：
1. **系统周期更新**：`updatePeriodMillis = 3600000`（1 小时），通过 `shift_widget_info.xml` 声明
2. **App 内主动刷新**：设置保存后 + App 回到前台时，通过 `ACTION_APPWIDGET_UPDATE` 广播触发
3. **用户交互**：点击 Widget → 打开 App → `onResume()` → 刷新

### 洞察 AA：Widget 数据计算是纯函数，与 ViewModel 模式一致

`computeWidgetShiftData()` 接受可注入参数（today、settings、locale），与 `HomeViewModel(currentDateProvider, localeProvider)` 模式一致。Widget 自身不管理状态，每次 `provideGlance()` 调用时从 DataStore 读取最新配置并计算。

### 洞察 BB：DataStore 直达避免跨进程通信复杂度

Widget 通过 `SettingsRepository(context)` 直接读取 DataStore，而非通过 App 进程 IPC。DataStore 支持多进程访问（文件锁），Widget 在系统进程中运行可安全读取。

### 洞察 CC：Glance 限制需要轻量 UI 策略

Glance 不支持 `LazyColumn`、动画、Canvas、`remember` 等 Compose 动态特性。进度条用两个固定比例的 Box 并排实现，颜色映射用纯色列表匹配。Widget 本质是静态快照，交互只能通过 `clickable` 打开 Activity/BroadcastReceiver。

### 阶段 15 新增文件

- `app/src/main/java/com/simpleshift/scheduler/domain/widget_data.kt` — Widget 数据模型 + 计算函数
- `app/src/main/java/com/simpleshift/scheduler/widget/ShiftWidget.kt` — GlanceAppWidget + UI
- `app/src/main/java/com/simpleshift/scheduler/widget/ShiftWidgetReceiver.kt` — 系统 Receiver
- `app/src/main/res/xml/shift_widget_info.xml` — Widget 元数据配置
- `app/src/test/java/com/simpleshift/scheduler/domain/WidgetDataTest.kt` — 4 个单元测试

### 阶段 15 改造文件

- `app/build.gradle.kts` — 新增 `glance-appwidget:1.1.0` + `glance-material3:1.1.0`
- `AndroidManifest.xml` — 注册 `ShiftWidgetReceiver`
- `MainActivity.kt` — 新增 `notifyWidgetUpdate()`，在设置保存/onResume 中调用
- `res/values/strings.xml` — 新增 widget_description / widget_name

---

## 10. 阶段 16 架构更新：首页精品化升级（已完成）

### 架构决策

采用"双轨制"渐进升级首页 UI：保留 `HomeScreen.kt`，新增 `NewHomeScreen.kt` + `ui/home/components/` 组件包。`MainActivity` 通过编译时常量 `USE_NEW_HOME` 控制走新/旧路径。

### 新增组件包

`app/src/main/java/com/simpleshift/scheduler/ui/home/components/` 承载首页独立组件：

- `GreetingHeader.kt` — 欢迎头部（时段问候 + 班组名 + 日期）
- `TodayShiftCard.kt` — 今日班次主卡片（横向布局：左侧4dp强调条 + 圆形徽章(64dp)白字班次 + 标题/距休徽章 + LinearProgressIndicator + 分数）
- `StatsGrid.kt` — 三宫格指标（本月上班、连续上班、距休天数）
- `QuickActionsRow.kt` — 快捷操作按钮行（日历/提醒/设置）
- `MotivationFooter.kt` — 底部随机文案

### 新增 domain 指标函数

`domain/shift_metrics.kt` 承载跨月份统计和趋势计算：

- `countShiftTypeInMonth(yearMonth, shiftType, teamPhaseOffset, customCycle)` — 月度某班次计数
- `countWorkDaysInMonth(yearMonth, teamPhaseOffset, customCycle)` — 月度上班天数
- `consecutiveWorkDays(today, teamPhaseOffset, customCycle)` — 连续上班天数（往前回溯）
- `daysUntilNextRest(today, teamPhaseOffset, customCycle)` — 距下次休息天数（往后查找）

所有函数复用 `getShiftTypeForDate()`，纯函数、可独立测试。

### HomeUiState 扩展

新增 5 个字段：
```kotlin
val teamName: String        // 从 selectedTeamId + availableTeams 派生
val daysUntilRest: Int      // 距下次休班天数
val consecutiveWorkDays: Int // 连续上班天数
val monthlyWorkDays: Int    // 本月上班天数
val totalDaysInMonth: Int   // 本月总天数
```

### 洞察 DD：双轨制降低 UI 升级风险

保留旧 `HomeScreen.kt` 完整不变，新 `NewHomeScreen.kt` 渐进开发，通过 `USE_NEW_HOME` 编译时常量控制分支。任意一步出问题，改回 `false` 即可回滚。新旧代码无耦合，旧路径字节码完全不变。

### 洞察 EE：domain 纯函数使指标计算可独立测试

`consecutiveWorkDays` 和 `daysUntilNextRest` 作为 domain 纯函数（接受可注入参数），可在 `ShiftMetricsTest` 中独立验证，不依赖 ViewModel 或 Android 框架。

### 洞察 FF：组件化 UI 使 Preview 可逐个验证

每个 component 独立接受参数、独立 Preview，无需启动完整 App 即可验证视觉效果。`NewHomeScreen` 仅做组装，不包含业务逻辑。

### 阶段 16 新增文件

- `domain/shift_metrics.kt` — 4 个统计纯函数
- `ui/home/components/GreetingHeader.kt`
- `ui/home/components/TodayShiftCard.kt`
- `ui/home/components/StatsGrid.kt`
- `ui/home/components/QuickActionsRow.kt`
- `ui/home/components/MotivationFooter.kt`
- `ui/home/NewHomeScreen.kt`
- `ShiftMetricsTest.kt` — 约 8 个用例

### 阶段 16 改造文件

- `viewmodel/HomeViewModel.kt` — HomeUiState 扩展 + refreshToday 计算
- `MainActivity.kt` — USE_NEW_HOME 开关 + NewHomeScreen 接线
- `HomeViewModelTest.kt` — 扩展覆盖新字段

---

## 11. 阶段 16 后续（2026-05-14）：日历独立路由 + Widget 美化

### 日历独立路由

`"main"` 路由不再包含 `CalendarScreen`。日历通过 NavHost 新路由 `"calendar"` 独立访问：

```
NavHost: "main" → "calendar" → "settings"
```

**导航变化**：
- `QuickActionsRow.onCalendarClick` → `navController.navigate("calendar")`
- `CalendarScreen` 新增 `onNavigateBack`（`popBackStack()`）、`onTeamSelected`、`availableTeams` 参数
- `CalendarScreen` 包装 `Scaffold` + `TopAppBar`（返回按钮 + 标题"倒班日历"）+ `TeamDropdown`
- 日历页班组切换同步更新 `homeViewModel.selectTeam()` 和 `calendarViewModel.setTeam()`

**CalendarUiState 扩展**：
- 新增 `selectedTeamId: Int = 1` 字段，供日历页 `TeamDropdown` 读取

### TodayShiftCard 重设计

将纵向堆叠文字改为横向信息卡片：

- **左侧强调条**：4dp 宽 `Box`，班次强调色背景，`fillMaxHeight()`
- **圆形徽章**：64dp `Surface(CircleShape)`，班次强调色底 + 白色大字
- **标题行**：`Text("今日班次")` + `RestBadge`（距休=0 → 绿色"休息日"，>0 → "距休 X天"）
- **进度区**：`LinearProgressIndicator`（班次颜色）+ "X / Y" 文本
- **Card 背景**：班次颜色 6% 透明度

### Widget 美化

对齐首页卡片风格，但避免 Glance 不支持的特性：

- **`WidgetShiftData`** 新增 `daysUntilRest: Int` 字段（由 `daysUntilNextRest()` 计算）
- **布局重设计**：圆角 Box 徽章（`cornerRadius(12.dp)` + 彩色底 + 白字）+ 班组名/"第 X/Y 天" + 距休/休息日标识 + 日期页脚
- **`colors.xml`** 新增 5 个强调色 + 5 个背景色（`_accent` / 无后缀）
- **无进度条**：Glance 没有 `LinearProgressIndicator`、没有 `fillMaxWidth(fraction)`、`defaultWeight()` 不支持分数，用文字"第 X/Y 天"表达
- **Widget 尺寸**：4×1（`targetCellWidth=4`, `targetCellHeight=1`）

### 洞察 GG：Glance Widget 应比 App UI 更克制

Glance 编译到 RemoteViews，能力远弱于 Compose。强行在 Widget 上复刻 App 的进度条、圆形、分层背景等效果会导致跨设备不一致。Widget 设计应优先保证**信息清晰 + 渲染可靠**，而非像素级对齐 App UI。

---

## 12. 阶段 17 架构更新：V2 UI 设计系统（已完成）

2026-05-14 实施深色主题 + 底部导航 + 组件化首页升级。

### 设计语言

Dark Productivity Design — 深色背景（`#0B0D10`）、卡片表面（`#1B1F26`）、金色强调（`#FACC15`）、5 色班次系统。全部通过 `ui/theme/` 目录的 Design Token 系统管理。

### 新增 theme 包

`app/src/main/java/com/simpleshift/scheduler/ui/theme/` 承载全局 Design Token：

- `Color.kt` — 15 个颜色 Token + `v2ShiftColor(ShiftType): Color` 辅助函数
- `Type.kt` — 5 级字体规格（`ShiftSchedulerTypography`）
- `Shape.kt` — 4 级圆角（Button/Card/MainCard/Sheet）
- `Theme.kt` — `ShiftSchedulerTheme`（`darkColorScheme` + 自定义 Typography）

### 底部导航栏

V2 路径使用 `NavigationBar` + 3 个 `NavigationBarItem`（首页/日历/我的）替代平级 NavHost。子页面（如设置）仍通过 NavHost `navigate()` 推入。

```
Scaffold(bottomBar = NavigationBar { ... })
  └── NavHost(startDestination = "home")
       ├── "home" → NewHomeScreenV2
       ├── "calendar" → CalendarScreen
       ├── "profile" → ProfileScreen
       └── "settings" → SettingsScreen
```

### V2 首页组件

`app/src/main/java/com/simpleshift/scheduler/ui/home/components/` 新增 5 个 V2 组件：

- `V2GreetingHeader.kt` — 时段问候 + 班组名 + 提醒时间
- `V2TodayShiftCard.kt` — 240dp 横向主卡：72dp 圆形徽章 + 牛马指数（≤40绿/41-70黄/>70红）+ `LinearProgressIndicator`
- `V2StatsGrid.kt` — 三宫格指标卡片
- `V2QuickActionsRow.kt` — `FilledTonalButton` 三个快捷操作
- `V2MotivationFooter.kt` — 随机励志文案

`NewHomeScreenV2.kt` 组装全部 V2 组件，带 `fadeIn` + `slideInVertically` 进场动效。

### HomeUiState V2 扩展

```kotlin
val shiftTimeRange: String?        // 今日班次的提醒时间（来自 AlarmSettings），格式 "HH:MM"
val monthlyShiftTypeCount: Int     // 今日班次类型在本月出现天数
val workIntensity: Int             // 牛马指数 = monthlyWorkDays * 100 / today.dayOfMonth
```

`HomeViewModel.updateAlarmSettings()` 接收 `AlarmSettings` 并触发 `refreshToday()` 重新计算。

### 浅色/深色双主题

`ShiftSchedulerTheme` 同时定义 `LightColors`（`lightColorScheme`）和 `DarkColors`（`darkColorScheme`），通过 `isSystemInDarkTheme()` 自动选择。所有 V2 组件使用 `MaterialTheme.colorScheme.onBackground`/`.surface`/`.onSurfaceVariant` 等主题引用替代硬编码暗色常量。系统切换深色模式时 App 即时响应，功能与布局不变。

### 日历页适配

- `CalendarDayCell` 背景改为班次色 12% 透明度，文字改为班次色着色（亮暗双主题自适应）
- 今天边框：`MaterialTheme.colorScheme.primary`（金色）
- 统计从 `AlertDialog` 弹窗改为日历下方内联 `StatsCard`（5 列均布）
- `computeStats()` 改为 toggle 模式

### Profile 页

`app/src/main/java/com/simpleshift/scheduler/ui/profile/ProfileScreen.kt`：

- 卡片式菜单布局（`V2CardShape` + `V2CardSurface`）
- 当前班组选择（`TeamDropdown` 内嵌）
- 倒班规则 → `navController.navigate("settings")`
- 提醒设置 → `navController.navigate("settings")`
- 给个好评 / 关于（占位）

### 双轨制安全策略

- `USE_NEW_HOME_V2 = true`（默认）— 启用 V2 布局（底部导航 + 新首页 + Profile），主题跟随系统深色模式
- `USE_NEW_HOME_V2 = false` — 完全回退 V1 路径
- `USE_NEW_HOME = true`（默认）— V1 路径中使用升级版首页（NewHomeScreen）
- V1 全部组件完整保留，改值即刻回滚

### 洞察 HH：Design Token 先行降低视觉漂移

将颜色、字体、圆角定义为全局 Token 后，所有 V2 组件统一引用 Token 而非硬编码，避免了"每个组件各自调色"导致的视觉不一致。后续添加新页面只需引用 Token 即可自动融入设计系统。

### 洞察 II：双轨制让大型 UI 重构风险可控

`USE_NEW_HOME`（阶段 16 开关）和 `USE_NEW_HOME_V2`（阶段 17 开关）两级编译时常量实现了渐进升级。每个阶段的回滚都是改一个布尔值，V1 字节码完全不受影响。

### 洞察 JJ：主题感知色优于硬编码色

最初 V2 组件直接引用 `V2PrimaryText`（#F5F7FA，白色）、`V2CardSurface`（#1B1F26，暗蓝灰）等暗色常量。浅色模式下这些颜色完全不可用。改为 `MaterialTheme.colorScheme.onBackground`/`.surface` 后，组件自动适配当前主题。原则：组件层只引用语义 Token（`onBackground`、`surface`、`onSurfaceVariant`），具体色值由 `ColorScheme` 定义，实现"换主题不改组件"。

### 阶段 17 新增文件

- `ui/theme/Color.kt`、`Type.kt`、`Shape.kt`、`Theme.kt`
- `ui/home/components/V2GreetingHeader.kt`、`V2TodayShiftCard.kt`、`V2StatsGrid.kt`、`V2QuickActionsRow.kt`、`V2MotivationFooter.kt`
- `ui/home/NewHomeScreenV2.kt`
- `ui/profile/ProfileScreen.kt`

### 阶段 17 改造文件

- `HomeViewModel.kt` — HomeUiState +3 V2 字段 + `updateAlarmSettings()`
- `MainActivity.kt` — `USE_NEW_HOME_V2` 开关 + 底部导航 + V2 路由 + alarm 接线
- `CalendarViewModel.kt` — `computeStats()` toggle
- `CalendarScreen.kt` — 深色颜色 + 内联统计 + 移除 dialog 代码

---

## 13. 阶段 18 架构更新：倒班规则编辑器重设计（已完成）

2026-05-14 实施规则编辑器两步向导式重设计，同时拆分规则与提醒为独立页面。

### 核心改动：referenceDate 贯穿全栈

`RuntimeShiftSettings` 新增 `referenceDate: LocalDate` 字段，作为可配置的轮班起始日期。所有 domain 函数（`getShiftTypeForDate`、`getShiftInfo`、4 个 metrics 函数、`generateMonthCalendarDays`、`syncShiftEvents`）新增 `referenceDate` 参数（默认 `REFERENCE_DATE`），零调用点改动。

### 设置页拆分

```
ProfileScreen
  ├── "倒班规则" → ShiftRuleEditorScreen（两步向导）
  └── "提醒设置" → AlarmSettingsScreen（纯闹钟 UI）
```

**ShiftRuleEditorScreen** 两步向导流程：
- Step 1：5 个彩色 `FilledTonalButton`（早/中/休/夜/学）→ 点击添加 → `FlowRow` Chip 展示（右上角红色 X 删除）→ "下一步"
- Step 2：Material3 `DatePickerDialog` 起始日期 + 可选结束日期（日历同步截止）+ `TeamDropdown` + 序列预览 + "保存并生成排班表"

**AlarmSettingsScreen**：从旧 SettingsScreen 提取闹钟 UI，无保存/取消按钮（闹钟即时生效）。

### 新 ViewModel

- `ShiftRuleViewModel`：管理两步状态（step/rotationSequence/startDate/endDate/defaultTeamId），`save()` 构造完整的 `RuntimeShiftSettings`（含 `referenceDate`）
- `AlarmSettingsViewModel`：纯闹钟管理，`updateAlarmTime()` 立即回调自动保存

### 导航

```
"shift_rule_editor" → ShiftRuleEditorScreen + ShiftRuleViewModel factory
"alarm_settings" → AlarmSettingsScreen + AlarmSettingsViewModel factory
"settings" → 旧 SettingsScreen（USE_NEW_SETTINGS=false 时使用）
```

### 首页精简

`NewHomeScreenV2` 移除 `TeamDropdown`（与"我的"页重复）和 `V2QuickActionsRow`（与底部导航栏重复），只保留核心信息展示：问候语 + 班次卡片 + 指标 + 文案。

### 洞察 KK：默认参数是向后兼容的最强工具

Phase A 在 6 个 domain/data 层文件中新增 `referenceDate` 参数，全部使用默认值，约 20 处现有调用点无需修改。所有现有测试直接通过，零回归。

### 阶段 18 新增文件

- `viewmodel/ShiftRuleViewModel.kt`、`viewmodel/AlarmSettingsViewModel.kt`
- `ui/settings/ShiftRuleEditorScreen.kt`、`ui/settings/AlarmSettingsScreen.kt`

### 阶段 18 改造文件

- `domain/model/RuntimeShiftSettings.kt`、`domain/shift_calculator.kt`、`domain/shift_metrics.kt`、`domain/calendar_generator.kt`、`domain/widget_data.kt`
- `data/repository/SettingsRepository.kt`
- `viewmodel/HomeViewModel.kt`、`viewmodel/CalendarViewModel.kt`
- `calendar/CalendarEventManager.kt`、`calendar/CalendarSyncManager.kt`
- `MainActivity.kt`

---

## 14. 阶段 19 架构规划：拼假神器（请假优化器）

### 核心目标

自动分析今日至当年 12 月 31 日，结合用户倒班表 + 中国法定节假日，找到最佳请假方案（请最少假、连休最久）。不跨年，日期显示无需年份即可无歧义。差异化核心功能，竞品少有。

### 核心算法：间隙桥接法（Gap-Merging）

**第一步**：构建未来 365 天的每日状态数组 `DayStatus`：
- `isRest`: 倒班表当天为休或学 → true
- `isHoliday`: 当天为法定节假日 → true
- `isWeekend`: 当天为周六或周日 → true
- `isAdjustedWorkDay`: 当天为调休工作日 → true（节假日数据中 `isHoliday=false` 的条目）

**第二步**：识别"休息块"（连续 isRest 日）和"工作间隙"（两休息块之间的连续工作日）。

**第三步**：对于每个工作间隙 ≤ 最大请假天数（默认 5 天）：
- 请假桥接此间隙 → 左右休息块 + 间隙 = 一个长连休
- 记录策略：`LeaveStrategy(leaveDays=间隙天数, breakDays=总连休)`

**第四步**：补充"延伸策略"——在休息块前后请 1~N 天（N = maxLeaveDays），延长休息块。

**第五步**：综合评分排序：
```
score = 0.50 * efficiencyScore + 0.25 * lengthScore + 0.25 * familyScore
```
- `efficiencyScore`: breakDays / leaveDays 归一化（最高者 1.0）
- `lengthScore`: breakDays / maxBreakDays 归一化
- `familyScore`: (holidayOverlap * 2 + weekendOverlap) / maxFamilyBonus 归一化

**第六步**：去重（同一连休区间仅保留最优方案），按评分降序输出。

### 新增 `domain/leave_optimizer.kt`

纯函数文件，不依赖 Android：

```kotlin
// 构建每日状态数组
fun buildDailyStatus(
    startDate: LocalDate,
    days: Int,
    teamPhaseOffset: Int,
    customCycle: List<ShiftType>?,
    referenceDate: LocalDate,
    holidays: Map<LocalDate, HolidayInfo>
): List<DayStatus>

// 主入口：查找最佳请假方案
fun findBestLeavePlans(
    today: LocalDate = LocalDate.now(),
    daysToAnalyze: Int = 365,
    teamPhaseOffset: Int = 0,
    customCycle: List<ShiftType>? = null,
    referenceDate: LocalDate = ShiftCycleConfig.REFERENCE_DATE,
    holidays: Map<LocalDate, HolidayInfo> = getChinaHolidays(),
    maxLeaveDays: Int = 5
): List<LeaveStrategy>
```

### 新增 `domain/holiday_data.kt`

内置中国法定节假日数据：

```kotlin
data class HolidayInfo(
    val date: LocalDate,
    val name: String,
    val isHoliday: Boolean  // true=放假, false=调休上班
)

fun getChinaHolidays(): Map<LocalDate, HolidayInfo>
```

数据覆盖范围：当前日期起未来 365 天。每年国务院发布下一年节假日安排后更新此文件即可。

2026 年法定节假日（官方已发布）：
- 元旦：1月1日
- 春节：2月16日-22日（农历正月初一为2月17日）
- 清明节：4月5日
- 劳动节：5月1日-5日
- 端午节：6月19日-21日（农历五月初五为6月19日）
- 中秋节：9月25日-27日（农历八月十五为9月25日）
- 国庆节：10月1日-7日

各节假日均有对应的调休工作日（周末补班）。

2027 年节假日（基于农历推算，待官方确认）：
- 元旦、春节（农历正月初一约2月5日）、清明、劳动节、端午、中秋、国庆
- 调休工作日按历史规律推算

数据文件中标注官方已确认 vs 推算待确认。

### 新增 `domain/model/LeaveStrategy.kt`

```kotlin
data class LeaveStrategy(
    val leaveDays: Int,                      // 需要请假天数
    val totalBreakDays: Int,                 // 连休总天数
    val leaveDates: List<LocalDate>,         // 需请假的具体日期
    val breakStart: LocalDate,               // 连休起始日
    val breakEnd: LocalDate,                 // 连休结束日
    val holidayOverlap: Int,                 // 与法定节假日重叠天数
    val weekendOverlap: Int,                 // 与周末重叠天数
    val overlappingHolidayNames: List<String>, // 重叠的节假日名称
    val efficiency: Float,                   // 效率 = breakDays / leaveDays
    val score: Float                         // 综合评分 0~1
)
```

### 新增 `viewmodel/LeaveOptimizerViewModel.kt`

```kotlin
class LeaveOptimizerViewModel(
    application: Application,
    private val todayProvider: () -> LocalDate = { LocalDate.now() }
) : AndroidViewModel(application) {

    data class LeaveOptimizerUiState(
        val strategies: List<LeaveStrategy> = emptyList(),
        val selectedTeamId: Int = 1,
        val maxLeaveDays: Int = 5,
        val isLoading: Boolean = true
    )

    fun refresh(customCycle: List<ShiftType>?, referenceDate: LocalDate, teamId: Int)
    fun setMaxLeaveDays(days: Int)
}
```

从 `SettingsRepository` 读取最新配置，调用 `findBestLeavePlans()`，发射 `LeaveOptimizerUiState`。

### 新增 `ui/leave_optimizer/LeaveOptimizerScreen.kt`

- `TopAppBar`：标题"拼假神器" + 返回按钮
- 说明区域：功能简介文字
- 策略卡片列表（`LazyColumn`）：
  - 推荐方案高亮（前 3 名金色边框）
  - 每张卡片：请假 X 天 → 连休 Y 天（大字）+ 日期范围 + 节日标识 + 效率标签 + 周进度示意
- 底部筛选区（可选）：最大请假天数滑块

### 导航集成

- `MainActivity.kt`：新增 `"leave_optimizer"` 路由 + `LeaveOptimizerViewModel` factory
- `ProfileScreen.kt`：新增"拼假神器"菜单项，点击 `onLeaveOptimizerClick` → `navController.navigate("leave_optimizer")`
- 不在底部导航栏新增 Tab（功能入口在"我的"页内）

### 洞察 LL：法定节假日数据是唯一的外部依赖

拼假神器的核心算法是纯数学问题（数组扫描 + 间隙检测），完全可单元测试。唯一的"外部依赖"是法定节假日数据，但这些数据每年仅变化一次（国务院发布），内置在 `holiday_data.kt` 中即可。不引入网络请求、不依赖第三方 API、不需要用户手动输入。

### 洞察 MM：间隙桥接法覆盖 95%+ 的真实请假场景

真实世界中，人们请假几乎总是连续的（一个假期），"桥接两个休息块"是最常见的拼假模式。算法专注于检测 ≤5 天的工作间隙并桥接，既高效（O(365) 复杂度）又覆盖了绝大多数实用场景。间歇式请假（每周请一天）虽然理论上可能产生更长连休，但实际几乎无人采用。

### 阶段 19 新增文件

- `domain/model/LeaveStrategy.kt` — LeaveStrategy 数据模型
- `domain/leave_optimizer.kt` — 拼假核心算法
- `domain/holiday_data.kt` — 中国法定节假日数据
- `viewmodel/LeaveOptimizerViewModel.kt` — 拼假页 ViewModel
- `ui/leave_optimizer/LeaveOptimizerScreen.kt` — 拼假页 UI
- `LeaveOptimizerTest.kt` — 核心算法测试（约 12 用例）
- `HolidayDataTest.kt` — 节假日数据验证（约 4 用例）

### 阶段 19 改造文件

- `MainActivity.kt` — 新增路由 + ViewModel factory
- `ui/profile/ProfileScreen.kt` — 新增"拼假神器"入口

---

## 15. 阶段 20 架构规划：同事模式（社交裂变）

### 核心目标

输入两个人的班组，自动计算下次同时休息日期和共同休息天数。情侣、朋友、同事都会使用，截图传播力极强。社交裂变功能。

### 核心算法：双班组交叉对比

对分析范围内每一天，分别计算两人的班次类型：
```
isRestA = (shiftA == REST || shiftA == STUDY)
isRestB = (shiftB == REST || shiftB == STUDY)
if isRestA && isRestB → 共同休息日
```
O(n)，n ≤ 365。比拼假神器的间隙桥接法更简单直接。

### 新增 `domain/colleague_mode.kt`

纯函数文件，不依赖 Android：

```kotlin
fun findCommonRestDays(
    teamAId: Int,
    teamBId: Int,
    today: LocalDate = LocalDate.now(),
    daysToAnalyze: Int = 365,
    customCycle: List<ShiftType>? = null,
    referenceDate: LocalDate = ShiftCycleConfig.REFERENCE_DATE
): CommonRestResult
```

### 新增 `domain/model/CommonRestResult.kt`

```kotlin
data class CommonRestResult(
    val teamAName: String,
    val teamBName: String,
    val nextCommonRestDate: LocalDate?,
    val daysUntilNext: Int?,
    val commonRestDates: List<LocalDate>,
    val totalCount: Int,
    val countIn30Days: Int,
    val countIn60Days: Int
)
```

### 新增 `viewmodel/ColleagueModeViewModel.kt`

```kotlin
class ColleagueModeViewModel(
    application: Application,
    private val todayProvider: () -> LocalDate = { LocalDate.now() }
) : AndroidViewModel(application) {

    data class ColleagueModeUiState(
        val teamAId: Int = 1,
        val teamBId: Int = 3,
        val result: CommonRestResult? = null,
        val analyzedDateRange: String = "",
        val isLoading: Boolean = true
    )

    fun setTeamA(teamId: Int)
    fun setTeamB(teamId: Int)
    fun refresh(customCycle: List<ShiftType>?, referenceDate: LocalDate)
}
```

### 新增 `ui/colleague_mode/ColleagueModeScreen.kt`

- TopAppBar："同事模式" + 返回按钮
- 双班组选择区：两个 TeamDropdown 并排（"我是"/"他是"）
- 主结果卡片（大字体日期 + 倒计时 + 渐变背景）
- 统计卡片行（30天/60天次数）
- 共同休息日列表（LazyColumn）

### 社交传播设计

- "下次同时休息：5月28日" 是大字体具体日期 → 天然对话素材
- 结果页面信息密度高 → 截图即社交分享内容
- 两个人一起看屏幕 → 主卡片视觉冲击力强
- V2 可加入分享按钮（生成带二维码的分享图）

### 导航集成

- `MainActivity.kt`：新增 `"colleague_mode"` 路由
- `ProfileScreen.kt`：新增"同事模式"菜单项（在拼假神器下方）
- 不在底部导航栏新增 Tab

### 洞察 NN：双班组对比是 O(n) 问题，比拼假神器简单一个量级

拼假神器需要间隙检测 + 评分排序 + 去重，算法约 170 行。同事模式只需逐天对比两个班次，核心算法约 30 行。技术复杂度低，但产品价值高（社交裂变）。适合快速实施验证传播效果。

### 洞察 OO：默认值设计降低使用门槛

"我是"默认用户当前班组（从 RuntimeShiftSettings），"他是"默认相邻班组（teamId+2）。多数用户无需手动选择即可看到有意义的共同休息结果。零操作成本 = 更高的使用率和传播率。

### 阶段 20 新增文件

- `domain/model/CommonRestResult.kt` — 共同休息结果模型
- `domain/colleague_mode.kt` — 双班组对比算法
- `viewmodel/ColleagueModeViewModel.kt` — 同事模式 ViewModel
- `ui/colleague_mode/ColleagueModeScreen.kt` — 同事模式 UI
- `ColleagueModeTest.kt` — 核心算法测试（约 8 用例）

### 阶段 20 改造文件

- `MainActivity.kt` — 新增路由 + ViewModel factory
- `ui/profile/ProfileScreen.kt` — 新增"同事模式"入口

---

## 16. 阶段 21 架构更新：倒班津贴计算器（已完成）

2026-05-14 实施倒班津贴计算器，高频刚需功能——自动统计当月班次 × 补贴单价 = 精确津贴。

### 核心目标

只算倒班直接决定的收入——班次补贴。基本工资/餐补/五险一金/个税涉及企业差异化政策，算不准反而失信。班次补贴 100% 由倒班表决定，普适所有倒班企业。

### 核心算法：班次统计 × 补贴单价

```
1. countAllShiftTypesInMonth(month) → {早:M, 中:A, 夜:N, 休:R, 学:S}

2. 本月倒班津贴 = Σ(每种班次补贴 × 该班次当月天数)
   每个班次补贴由用户自行设置，默认 0

3. 假设分析：多上 X 天某班次（用户可选早/中/夜/学）
   → +X×该班次补贴
```

### 新增 `domain/salary_calculator.kt`

3 个纯函数：
- `countAllShiftTypesInMonth(yearMonth, teamPhaseOffset, customCycle, referenceDate): Map<ShiftType, Int>` — 遍历当月每天，统计 5 种班次出现次数
- `calculateSalaryBreakdown(config, shiftCounts, yearMonth): SalaryBreakdown` — Σ(补贴 × 次数) = 津贴总额
- `simulateExtraShifts(current, extraCount, extraShiftType, config): SalaryBreakdown` — 假设多上 X 天某班次的增量

### 新增 `domain/model/SalaryConfig.kt` / `SalaryBreakdown.kt`

```kotlin
data class SalaryConfig(
    val shiftPremiums: Map<ShiftType, Double> = emptyMap()
)

data class SalaryBreakdown(
    val month: YearMonth,
    val shiftCounts: Map<ShiftType, Int>,
    val shiftPremiumTotal: Double
)
```

### DataStore 持久化

`SettingsRepository` 新增 1 个 key：
```
KEY_SHIFT_PREMIUMS = stringPreferencesKey("shift_premiums")
// 序列化格式："MORNING=0,AFTERNOON=50,NIGHT=200,STUDY=0"
```
新增 `salaryConfigFlow: Flow<SalaryConfig>` + `suspend saveSalaryConfig()`。

### `SalaryPredictorViewModel`

管理：薪资配置（自动保存）/ 月份切换 / 班组选择 / 假设分析参数（天数 0-5 + 班次类型可选）。
`updateConfig()` 立即写入 DataStore 并触发重算。`refresh()` 从 MainActivity 调用传入最新 settings。

### `SalaryPredictorScreen`

- 可折叠津贴设置区（早/中/夜/学 OutlinedTextField + 彩色圆点标签）
- 月份左右切换 + 班组下拉（`MonthTeamRow`）
- `PremiumTotalCard`：大字体 ¥1,750（36sp Bold）+ primary 色背景
- `ShiftBreakdownSection`：彩色班次标签行（早班 8次...）+ 各津贴贡献明细
- `SimulationCard`：FilterChip 0-5 + 班次类型下拉 + 增量结果

### 导航

- 路由：`"salary_predictor"`（不在底部导航栏）
- 入口：ProfileScreen → "倒班津贴"菜单项（同事模式下方，AttachMoney 图标）

### 洞察 PP：倒班津贴是唯一完全由倒班表决定的收入

只有班次补贴直接取决于当月排班。基本工资、餐补、五险一金、个税都和倒班表无关。只算班次补贴：算得准、零维护、普适所有倒班企业。

### 洞察 QQ：假设分析帮助换班决策

"如果多上两天夜班能多拿 ¥400"——假设分析让用户在做换班决策时有数据支撑。拼假神器帮找"什么时候休"，倒班津贴帮算"多上班能多拿多少"，两者互补。

### 阶段 21 新增文件

- `domain/model/SalaryConfig.kt` — 津贴配置模型
- `domain/model/SalaryBreakdown.kt` — 津贴明细模型
- `domain/salary_calculator.kt` — 津贴计算纯函数（~50 行）
- `viewmodel/SalaryPredictorViewModel.kt` — 倒班津贴 ViewModel（~110 行）
- `ui/salary_predictor/SalaryPredictorScreen.kt` — 倒班津贴 UI（~310 行）
- `SalaryCalculatorTest.kt` — 核心算法测试（8 用例）

### 阶段 21 改造文件

- `data/repository/SettingsRepository.kt` — 新增 1 个 DataStore key + salaryConfigFlow + saveSalaryConfig()
- `SettingsRepositoryTest.kt` — 追加 2 个津贴配置测试用例
- `MainActivity.kt` — 新增 `"salary_predictor"` 路由 + ViewModel factory + `currentSalaryConfig` 状态流
- `ui/profile/ProfileScreen.kt` — 新增"倒班津贴"入口 + `onSalaryPredictorClick` 回调

---

## 17. 阶段 22 架构更新：图片分享功能（已完成）

将同事模式的共同休息结果转化为一张精美的分享长图（含 QR 码），调起系统原生分享面板。首期仅覆盖同事模式。

### 技术背景：Compose BOM 2023.10.01 约束

Compose BOM 2023.10.01 对应 Compose UI ~1.5.x，**不支持 `GraphicsLayer.toBitmap()`**（1.7+ 才加入）。最终采用的离屏渲染方案：
1. `suspend fun Activity.renderComposableToBitmap()` — 临时 attach ComposeView 到 decorView（alpha=0）
2. `setContent { LaunchedEffect(Unit) { resume() } }` 等待首帧组合完成
3. `measure(EXACTLY)` + `layout(0, 0, w, h)` 强制像素布局
4. `draw(Canvas(bitmap))` 绘制到目标 Bitmap
5. `finally { decorView.removeView(composeView) }` 保证清理

初版尝试 `ComposeView` 不 attach 到 Window 直接 `setContent`，结果报错 `Cannot locate windowRecomposer; View is not attached to a window`。`ComposeView` 必须附着到 Window 才能获取 `WindowRecomposer`。

### 架构分层

```
domain/qr_code_generator.kt        ← 纯函数：String → Bitmap（ZXing QRCodeWriter）
       │
       ▼
util/ShareImageRenderer.kt         ← ComposeView 离屏渲染 + 文件缓存 + 清理
       │
       ▼
ui/colleague_mode/ShareCardLayout.kt ← @Composable 分享图布局 + ShareCardData 数据模型
       │
       ▼
ColleagueModeViewModel.startShare()  ← 状态管理（isSharing/shareUri/shareError）+ 异步流程
       │
       ▼
ColleagueModeScreen ShareButton      ← LaunchedEffect 监听 shareUri → 弹出系统分享面板
```

### FileProvider 安全模型

```
App 私有目录 (cacheDir/share_images/)
       │
       ▼
FileProvider.getUriForFile() → content://com.simpleshift.scheduler.fileprovider/share_images/xxx.png
       │
       ▼
Intent + FLAG_GRANT_READ_URI_PERMISSION → 微信/QQ 等第三方 App 获得临时读取权限
```

- `exported="false"`：外部 App 不可直接访问 FileProvider
- `grantUriPermissions="true"`：允许通过 Intent Flag 临时授权
- `cache-path`：存入缓存目录，系统空间不足时自动清理

### ShareCardData 数据模型（ViewModel-agnostic）

```kotlin
data class ShareCardData(
    val teamAName: String,
    val teamBName: String,
    val nextCommonRestDate: String,    // "5月28日"
    val nextCommonRestWeekday: String, // "星期三"
    val daysUntilNext: Int,
    val countIn30Days: Int,
    val countIn60Days: Int,
    val commonRestDateItems: List<String>, // 最多 12 项
    val dateRange: String,
    val qrCodeBitmap: Bitmap
)
```

> 数据模型不含任何 ViewModel/Context 引用，`ShareCardLayout` 可独立 Preview 和离屏渲染。

### ColleagueModeViewModel 分享状态

```kotlin
data class ColleagueModeUiState(
    // ... 现有字段 ...
    val isSharing: Boolean = false,   // 正在生成分享图（UI 显示 loading）
    val shareUri: Uri? = null,        // 非 null → LaunchedEffect 弹出分享
    val shareError: String? = null    // 生成失败时显示错误
)
```

### 线程编排

```
用户点击分享
  → isSharing = true（UI 立即反馈）
  → viewModelScope.launch {
        Dispatchers.Default: 构建 ShareCardData + generateQrCodeBitmap()
        Dispatchers.Main:    renderComposableToBitmap(1080, 1920)
        Dispatchers.IO:      saveBitmapToShareCache() → content:// Uri
        Main (implicit):     shareUri = uri, isSharing = false
    }
  → LaunchedEffect(shareUri): startActivity(Intent.ACTION_SEND)
  → onShareComplete(): shareUri = null
```

### 缓存清理策略

- 触发点：`MainActivity.onCreate()` + 每次 `startShare()` 前
- 策略：删除 24 小时前修改的文件
- 位置：`context.cacheDir/share_images/`
- 权限：无额外权限需求（`cacheDir` 是 App 私有目录）

### 分享图 Layout 关键参数

- 宽度：固定 1080px（360dp × 3x，主流分享图分辨率，微信朋友圈适配好）
- 高度：约 1920px（9:16 比例，内容自适应）
- 背景：V2 `DarkBackground`（`#0B0D10`）
- 主卡片：V2 渐变背景 + `V2CardShape` 28dp 圆角
- 日期字号：48sp Bold（与 V2TodayShiftCard 的吨位一致）
- QR 码：200×200dp，居中展示
- 字体：使用 `MaterialTheme.typography`（自动跟随系统深浅模式不会影响 Bitmap 输出——Bitmap 没有主题切换概念）

### 洞察 RR：离屏渲染要避开 View 生命周期

`ComposeView` 在未 attach 到 Window 时不会有 `onDraw` 回调，但 `setContent` 会立即触发 Compose 组合。`measure/layout` 强制执行后，`draw(Canvas)` 能将已组合的内容同步绘制到 Bitmap。整个过程不依赖 Choreographer、不等待下一帧。

### 洞察 SS：QR 码 URL 集中管理是低耦合关键

`SHARE_QR_URL` 常量在 `qr_code_generator.kt` 顶部，全 App 唯一引用点。上架后替换为应用商店链接时只需改一行。后续可持续为远程配置（Firebase Remote Config / API 下发）——改动范围仍局限在该文件内。

### 洞察 TT：首期只做同事模式是最优范围决策

同事模式的 `CommonRestResult` 数据模型扁平（一个日期 + 列表 + 两个计数），一张图即可覆盖全部信息。拼假神器需要处理"多条策略 + MiniCalendarBar"的分页渲染、倒班津贴涉及收入隐私。先验证同事模式的传播效果，再决定是否扩展到其他页面。

### 阶段 22 新增文件

- `domain/qr_code_generator.kt` — QR 码生成纯函数（~35 行）
- `util/ShareImageRenderer.kt` — ComposeView 离屏渲染 + 缓存管理（~70 行）
- `ui/colleague_mode/ShareCardLayout.kt` — 分享图 Composable + ShareCardData（~180 行）
- `res/xml/file_paths.xml` — FileProvider 路径配置
- `ShareImageTest.kt` — 8 个单元测试

### 阶段 22 改造文件

- `app/build.gradle.kts` — 新增 `zxing:core:3.5.3`
- `AndroidManifest.xml` — 新增 FileProvider `<provider>`
- `viewmodel/ColleagueModeViewModel.kt` — isSharing/shareUri/shareError + startShare/onShareComplete
- `ui/colleague_mode/ColleagueModeScreen.kt` — 分享按钮 + LaunchedEffect 弹出分享
- `MainActivity.kt` — cleanupOldShareImages() 调用

---

## 18. 2026-05-17 架构更新：V4 首页协调化重设计

### 问题诊断

V3 首页存在以下不协调问题：
- 英雄横幅渐变色几乎不可见（透明度假高）
- 休息倒计时卡片使用独特的左侧强调条，与其他卡片风格不一致
- 功能中心卡片内边距过小（12dp），副标题缩放到 85% 导致拥挤
- 进度指示器无卡片容器，悬浮感强
- 月度概览展开/折叠无视觉提示
- 上下文消息使用 outline 颜色，像事后补充的内容
- 各区块间距不一致（16/20/12/24/16/24）

### V4 设计原则

- **统一的卡片语言**：所有内容块使用相同的 `Surface` + `V2CardShape`（24dp 圆角）
- **一致间距**：所有主区块间距统一 16dp，水平内边距 16dp
- **圆形徽章英雄模式**：左侧 64dp 彩色圆形徽章（班组首字 "早/午/夜/休/学"）+ 右侧班组详情
- **清晰的信息层次**：英雄卡片 → 统计卡片行 → 工具行 → 消息横幅

### V4 组件结构

`NewHomeScreenV4.kt`（~450 行）包含所有私有 composable：

| 组件 | 功能 |
|------|------|
| `V4GreetingRow` | 时段问候 + 班组名 + 日期，简洁左对齐 |
| `V4HeroCard` | 64dp 圆形徽章 + 班组标签 + 提醒时间 + 休息倒计时胶囊 + 周期进度条 |
| `V4StatsRow` | 两张等宽卡片："本月上班"（含工作强度）+ "连续上班"（含状态标签） |
| `V4ToolsRow` | 三个工具卡片（28dp 彩色图标 + 标签，无副标题） |
| `V4MessageBanner` | 上下文消息置于半透明 Surface 卡片中 |

### 导航

`MainActivity.kt` 新增 `USE_NEW_HOME_V4 = true`，`"home"` 路由优先渲染 `NewHomeScreenV4`。

### 洞察 WW：统一卡片语言消除视觉碎片

V3 有 6 种不同的视觉模式（渐变 Box、左侧强调条 Row、12dp 小卡片、裸文字+进度条、可折叠卡片、outline 文字）。V4 统一为一种：`Surface(V2CardShape)` + 16-20dp 内边距。视觉碎片从 6 降到 1，用户扫视时认知负担显著降低。

### 洞察 XX：圆形徽章是高效的班次识别符号

64dp 彩色圆形徽章 + 单个汉字（早/午/夜/休/学）比纯文字标题识别速度更快。颜色 + 形状 + 文字三重编码，即使在小尺寸（48dp 启动器图标尺寸）下也能快速区分班次类型。

---

## 19. 2026-05-17 架构更新：App 图标重设计

### 设计理念

将原日历+日月+箭头图标替换为三 S 三曲臂（triskelion）图案。三条 S 形曲线以 120° 旋转排列，分别代表 "Simple"、"Shift"、"Scheduler"，同时寓意轮班轮转的周期性。

### 颜色方案

| 臂 | 颜色 | 含义 |
|----|------|------|
| S 臂 1 (0°) | 琥珀色 `#FF8F00` | "Simple" / 早班 |
| S 臂 2 (120°) | 青色 `#26A69A` | "Shift" / 中班 |
| S 臂 3 (240°) | 紫罗兰色 `#7E57C2` | "Scheduler" / 夜班 |

背景为深海军蓝渐变，中央有浅色圆点连结三条 S 臂。

### 技术实现

全部 4 个矢量图标文件更新：
- `drawable/ic_launcher_background.xml` — 深海军蓝径向渐变
- `drawable/ic_launcher_foreground.xml` — 三条 S 曲线（7.5dp 描边宽度，round cap）+ 中央圆点
- `mipmap-hdpi/ic_launcher.xml` — 合并版（pre-API 26 兜底）
- `mipmap-hdpi/ic_launcher_round.xml` — 合并版 + 圆形裁剪

每条 S 臂使用 `<group android:rotation="N" android:pivotX="54" android:pivotY="54">` 旋转，路径数据仅定义一次。

---

## 20. 阶段 23 架构更新：提醒时间选择器改进（已完成）

### 问题

`AlarmSettingsScreen.AlarmTimePickerDialog` 使用两个独立 `OutlinedTextField`（时/分分离输入），键盘弹出遮挡、易出错、不符合用户习惯。

### 方案决策

经对比 Android 原生 `TimePickerDialog` vs 升级 Compose BOM + Material3 `TimePicker`，**选择方案 B**：
- Kotlin `1.9.20→1.9.24` + Compiler `1.5.4→1.5.14` + BOM `2023.10.01→2024.04.00`
- Material3 `1.1.2→1.2.1` → 获得 `TimePicker` + `rememberTimePickerState` + `AutoMirrored` icons
- 升级路径全在同主版本内（Kotlin 1.9.x / Compiler 1.5.x），非跨大版本，150 个测试零回归

### Material3 TimePicker 实现

`ShiftAlarmRow` 中：
```kotlin
val state = rememberTimePickerState(
    initialHour = alarmTime?.hour ?: 7,
    initialMinute = alarmTime?.minute ?: 0,
    is24Hour = true
)

AlertDialog(
    title = { Text("${label}班 提醒时间") },
    text = { TimePicker(state = state) },
    confirmButton = { TextButton { onEdit(AlarmTime(state.hour, state.minute)) } },
    dismissButton = {
        Row {
            if (alarmTime != null) {
                TextButton(onClick = onRemove) { Text("关闭提醒", color = error) }
            }
            TextButton(onClick = { showDialog = false }) { Text("取消") }
        }
    }
)
```

`TimePicker` 自动应用 V2 Design Token 主题色，`rememberTimePickerState` 管理时钟状态。删除整个 `AlarmTimePickerDialog` composable（~70 行）。

### 工具链升级

| 组件 | 旧 | 新 |
|------|----|----|
| Kotlin | 1.9.20 | 1.9.24 |
| Compose Compiler | 1.5.4 | 1.5.14 |
| Compose BOM | 2023.10.01 | 2024.04.00 |
| Material3 | 1.1.2 | 1.2.1 |

AGP 8.2.0 / Gradle 8.4 不变。所有升级在同主版本内，零编译错误、零测试回归。

### 洞察 UU：升级 BOM 的一次投入、长期受益

BOM 2023.10.01 是 2023 年 10 月版本，一年半未更新。升级到 2024.04.00 后：
- Material3 `TimePicker` / `DateRangePicker` / `BottomSheet` 改进等新 API 开放
- `AutoMirrored` icons 自动处理 RTL 布局（之前用的 `ArrowBack` 不会在 RTL 下翻转）
- Compose 1.6.x 渲染管线性能提升（`LazyColumn` / `LazyVerticalGrid` 滚动优化）
- 解锁后续：`GraphicsLayer.toBitmap()` 在 Compose 1.7+ 可用，图片分享可省去 `suspendCoroutine` 等待

### 洞察 VV：TimePicker 实验性 API 标记不影响生产使用

Material3 1.2.x 中 `TimePicker` / `rememberTimePickerState` 标记 `@ExperimentalMaterial3Api`，但 Material3 的实验性 API 通常在次版本变为稳定。加 `@OptIn` 即可编译通过，不影响运行时行为。

---

## 21. 2026-05-17 架构更新：性能优化（已完成）

### 优化策略

采用四阶段渐进式优化，每阶段独立可交付、独立可回滚。"稳健鲁棒"原则优先——最高收益、最低风险项先做。

### Phase 1：Compose 稳定性标注 + UI 微修复

**1A：@Immutable 注解（21 个数据类，9 个文件）**

Compose 编译器将包含 `List`、`Map`、`LocalDate` 的数据类视为"不稳定"，导致每次状态变更时全面重组。添加 `@Immutable` 告知编译器这些类不可变，启用智能重组（跳过未变更的子节点）。

| 层 | 文件 | 数据类 |
|----|------|--------|
| ViewModel | `HomeViewModel.kt` | `HomeUiState` |
| ViewModel | `CalendarViewModel.kt` | `CalendarDayUiState`, `CalendarUiState` |
| ViewModel | `SalaryPredictorViewModel.kt` | `SalaryPredictorUiState` |
| ViewModel | `ColleagueModeViewModel.kt` | `ColleagueModeUiState` |
| ViewModel | `LeaveOptimizerViewModel.kt` | `LeaveOptimizerUiState` |
| ViewModel | `SettingsViewModel.kt` | `SettingsUiState` |
| ViewModel | `AlarmSettingsViewModel.kt` | `AlarmSettingsUiState` |
| ViewModel | `ShiftRuleViewModel.kt` | `ShiftRuleUiState` |
| Domain | `RuntimeShiftSettings.kt` | `RuntimeShiftSettings` |
| Domain | `SalaryConfig.kt` | `SalaryConfig` |
| Domain | `SalaryBreakdown.kt` | `SalaryBreakdown` |
| Domain | `AlarmSettings.kt` | `AlarmSettings` |
| Domain | `AlarmTime.kt` | `AlarmTime` |
| Domain | `CalendarEventIds.kt` | `CalendarEventIds` |
| Domain | `MonthlyStats.kt` | `MonthlyStats` |
| Domain | `LeaveStrategy.kt` | `LeaveStrategy` |
| Domain | `CommonRestResult.kt` | `CommonRestResult` |
| Domain | `CalendarDayInfo.kt` | `CalendarDayInfo` |
| Domain | `ShiftInfo.kt` | `ShiftInfo` |
| Domain | `Team.kt` | `Team` |

每项变更：添加 `import androidx.compose.runtime.Immutable` + 在 `data class` 前加 `@Immutable`。行为零变更。

**1B：V4HeroCard 双重组合修复**

`NewHomeScreenV4.kt:183-184`：`animatedVisible = true`（每次组合都写入状态并触发第二次组合）改为 `LaunchedEffect(Unit) { animatedVisible = true }`（仅触发一次）。

**1C：DateTimeFormatter 提升**

`SalaryPredictorScreen.kt:340`：`DateTimeFormatter.ofPattern("yyyy年M月")` 移入 `remember {}`，避免每次重组都重新分配。

### Phase 2：协程修复 + 日历同步

**2A：移除 runBlocking**

`SalaryPredictorViewModel.kt:47`：`runBlocking { saveSalaryConfig() }` 替换为 `viewModelScope.launch { saveSalaryConfig() }`。`recalculate()` 仅读取内存状态，无需等待保存完成。移除 `import kotlinx.coroutines.runBlocking`。

**2B：打破日历同步反馈循环**

`CalendarSyncManager.startAutoSync()`：`calendarEventIdsFlow` 从 3 路 `combine` 中移除，改为在 collect 内部通过 `.first()` 一次性读取。打破 `saveCalendarEventIds → flow 发射 → combine 重新触发 → 再次同步` 的循环。

`SettingsRepository.saveCalendarEventIds()`：移除写入前的 `dataStore.data.first()` 守卫检查（`edit` 本身是原子操作，反馈循环已解除后无需守卫）。

### Phase 3：构建配置

**3A：启用 R8 混淆**

`app/build.gradle.kts`：Release 构建设置 `isMinifyEnabled = true` + `isShrinkResources = true`。

**新增 `app/proguard-rules.pro`**：Compose 安全保留规则（Compose 类、枚举 values/valueOf、domain/viewmodel 数据类、ViewModel 子类）。Release APK 体积约 7.2MB（压缩显著）。

**3B：Baseline Profile 推迟**

尝试直接放置 `baseline-prof.txt` 失败（AGP 8.2.0 解析错误：需要完整 HRF 格式或 Baseline Profile Gradle Plugin）。推迟至后续阶段，届时通过完整的 `androidx.baselineprofile` 插件 + 生成器测试模块实施。

### Phase 4：推迟

日历 `ContentProviderOperation.applyBatch()` 批处理推迟。`CalendarEventManager.syncShiftEvents` 中每次插入依赖 `findExistingEvent` 查询（无法与插入批量合并），且提醒插入需要事件 ID。改为 `applyBatch` 需彻底重构。同步已在后台协程中运行，不影响 UI，投入产出比低。

### 洞察 WW：@Immutable 是性能优化中投入产出比最高的单项变更

21 个数据类，每个仅添加 2 行代码（import + 注解），行为零变更，但对 Compose 重组效率影响深远——编译器从"保守全面重组"变为"跳过不变子节点"。

### 洞察 XX：runBlocking 在主线程上是隐蔽的性能杀手

DataStore `edit` 内部调度至 `Dispatchers.IO`，但 `runBlocking` 阻塞调用线程等待其完成。用户快速切换津贴设置时，每次键盘输入都触发 `updateConfig()`，导致主线程频繁阻塞。改为 `viewModelScope.launch` 后写入异步进行，UI 保持响应。

### 洞察 YY：Flow combine 包含自写键会形成反馈循环

`combine(settingsFlow, alarmSettingsFlow, calendarEventIdsFlow)` 的第三个流在同步完成后被自身写入，导致重新触发。Mutex 能防止并发执行，但无法防止冗余触发。将自写流移出 combine 并改为按需 `.first()` 读取，可彻底消除循环。

### 改造文件

| 阶段 | 新增文件 | 改造文件 |
|------|---------|---------|
| 1 | — | 9 个 ViewModel 文件 + 12 个 domain/model 文件（添加 @Immutable） |
| 1 | — | `NewHomeScreenV4.kt`（LaunchedEffect 动画修复） |
| 1 | — | `SalaryPredictorScreen.kt`（remember formatter） |
| 2 | — | `SalaryPredictorViewModel.kt`（runBlocking → viewModelScope.launch） |
| 2 | — | `CalendarSyncManager.kt`（combine 3 路 → 2 路 + .first()） |
| 2 | — | `SettingsRepository.kt`（移除 saveCalendarEventIds 守卫） |
| 3 | `proguard-rules.pro` | `build.gradle.kts`（R8 开启 + 资源压缩） |

---

## 22. 2026-05-17 架构更新：Widget V2 升级 + 更新优化（已完成）

### 设计目标

全面提升桌面组件的外观、功能和鲁棒性：
- **外观**：从浅色柔和色彩升级为 V2 深色主题（对齐 App 内设计语言）
- **功能**：新增明日班次预览（彩色圆点 + 标签）、休息倒计时、未配置兜底
- **鲁棒性**：避免无变化时的冗余更新、异常日志记录、回退数据显式提示

### Widget V2 设计

#### 深色主题颜色

Widget 使用硬编码深色常量（Glance 不支持 `MaterialTheme.colorScheme`）：
- `WidgetBackground = Color(0xFF1B1F26)` — 对齐 `V2CardSurface`
- `WidgetTextPrimary = Color(0xFFF5F7FA)` — 对齐 `V2PrimaryText`
- `WidgetTextSecondary = Color(0xFF9CA3AF)` — 对齐 `V2SecondaryText`
- `shiftAccentColor(ShiftType): Color` — 五色班次映射（早橙/中蓝/休绿/夜紫/学黄）

旧 `colors.xml` 中的 widget 纯色资源已全部移除，颜色定义集中在 `ShiftWidget.kt` 内。

#### 新布局结构

```
Row 1: [大号班次徽章] + [班组名/第X/Y天] + [休息倒计时/距休X天]
Row 2: [日期标签（含中文星期）] + [● 明日: 早]
```

- **班次徽章**：圆角 10dp Box + 班次强调色背景 + 20sp Bold 白字
- **明日预览**：6dp 彩色圆点（`cornerRadius(3.dp)`）+ "明日: " + 班次标签
- **休息倒计时**：休班显示绿色"休息日"，距休 1 天显示"明天休息"，其余"距休X天"
- **日期格式**：`M月d日 周X`（如"5月17日 周三"），使用 `DateTimeFormatter.ofPattern` + 中文星期映射

#### 未配置状态

设置无效时显示简洁的引导信息：
- 主文字"未配置"（白色 Bold 15sp）
- 副文字"请先设置排班规则"（灰色 11sp）
- 深色背景一致，视觉上明显不同于正常状态

旧版回退数据 `shiftLabel="?"` 在绿色 REST 背景下会误导用户以为今日休息，已升级为显式引导文案。

### WidgetShiftData 扩展

```kotlin
data class WidgetShiftData(
    val dateLabel: String,           // "5月17日 周三"
    val shiftLabel: String,          // "早"/"中"/"休"/"夜"/"学"
    val shiftType: ShiftType,        // 枚举值
    val dayOfCycle: Int,             // 周期第几天
    val totalDays: Int,              // 周期总天数（0=未配置）
    val teamName: String,            // 班组名
    val daysUntilRest: Int,          // 距下次休息天数（-1=未配置/无休班）
    val tomorrowShiftLabel: String,  // 明日班次标签
    val tomorrowShiftType: ShiftType // 明日班次类型
)
```

新增 `tomorrowShiftLabel` 和 `tomorrowShiftType` 字段，通过 `getShiftInfo(today.plusDays(1), ...)` 计算。`computeWidgetShiftData()` 新增 `dateOfWeekChinese()` 辅助函数。

### Widget 更新优化

**问题 1：无条件冗余更新**

`MainActivity.onResume()` 和三个位置（快速操作删除、设置保存、CalendarSyncManager）无条件调用 `notifyWidgetUpdate()`，即使设置未变化。每次更新触发 DataStore 读取 + Glance 重组。

**方案**：`MainActivity` 缓存 `lastWidgetSettings: RuntimeShiftSettings?`（data class 的 `==` 比较所有字段），未变化时跳过：

```kotlin
private val shiftWidget = ShiftWidget()
private var lastWidgetSettings: RuntimeShiftSettings? = null

private fun notifyWidgetUpdate() {
    val current = runtimeSettingsFlow.value
    if (current == lastWidgetSettings) return
    lastWidgetSettings = current
    lifecycleScope.launch {
        try {
            shiftWidget.updateAll(this@MainActivity)
        } catch (e: Exception) {
            Log.e("MainActivity", "Widget update failed", e)
        }
    }
}
```

**问题 2：异常静默吞没**

旧代码 `catch (_: Exception) {}` 使所有 widget 更新失败不可见。已添加 `Log.e` 记录异常信息。

**问题 3：每次创建新实例**

`ShiftWidget().updateAll()` 每次调用都新建 GlanceAppWidget 实例。已将 `ShiftWidget()` 提取为 Activity 的 `private val shiftWidget`。

### 改造文件

| 文件 | 改动 |
|------|------|
| `MainActivity.kt` | 添加 `shiftWidget` val + `lastWidgetSettings` 快照比较 + `Log.e` 异常记录 |
| `domain/widget_data.kt` | `WidgetShiftData` 新增 `tomorrowShiftLabel`/`tomorrowShiftType`；日期格式改用 `M月d日` + 中文星期；回退数据改为"未配置"/"请先设置排班规则" |
| `widget/ShiftWidget.kt` | 全面重写：V2 深色主题 + 新布局（明日预览、休息倒计时、未配置状态） |
| `res/values/colors.xml` | 移除旧 widget 纯色资源 |
| `WidgetDataTest.kt` | 更新测试覆盖新字段（`tomorrowShiftLabel`/`tomorrowShiftType`）+ 回退数据验证 |

### 洞察 ZZ：Glance Widget 颜色必须内联

Glance 编译为 RemoteViews，不支持 `androidx.compose.ui.graphics.Color` 的资源引用或主题系统。所有颜色必须以 `Color(0xFFxxxxxx)` 内联在 Kotlin 代码中。`colors.xml` 保留仅用于 App 内 Compose UI（若被引用），但 Widget 相关颜色已全部迁移至 `ShiftWidget.kt`。

### 洞察 AAA：快照比较是零成本去重机制

`RuntimeShiftSettings` 是 data class，Kotlin 编译器自动生成 `equals()`。`current == lastWidgetSettings` 一次对象比较即可避免整个 DataStore 读取 + Glance 更新流程。相比每次 onResume 都无条件更新，这是投入产出比最高的单行优化。
