# 倒班助手架构说明（当前阶段）

## 1. 当前架构阶段

项目处于 **阶段 8：设置页（自定义倒班规则）** 已完成。架构采用单模块 Android 应用，技术路线为 Kotlin + Jetpack Compose + MVVM + StateFlow。

已完成的阶段：
- 阶段 1-8：全部功能（项目骨架、数据模型、核心算法、首页 UI、测试、日历页、班组切换 + 月度统计、设置页）

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
- 承载 Compose `setContent` 容器并装配 `HomeScreen` + `CalendarScreen` 同屏布局
- 使用 Activity 级 ViewModel（`HomeViewModel`、`CalendarViewModel`）作为状态来源
- 在 `onResume()` 中触发 `refreshToday()` + `refresh()`，确保应用回到前台时刷新数据
- **班组切换接线**：当 `HomeScreen` 触发 `onTeamSelected` 时，同步调用 `homeViewModel.selectTeam()` 和 `calendarViewModel.setTeam()`

### `app/src/main/java/com/simpleshift/scheduler/ui/home/`

- 首页 UI 模块目录
- 已实现 `HomeScreen`，展示四类核心信息：
  - 班组下拉框（`ExposedDropdownMenuBox`，6 个班组选项）
  - 今日日期（本地化可读格式）
  - 今日班次（`早/中/休/夜/学`）
  - 周期进度（`dayOfCycle / 42`）
- 保持“纯展示 + 事件上抛”职责，不放排班计算逻辑
- `HomeScreen` 接受 `onTeamSelected: (Int) -> Unit` 回调通知班组切换
- 当前调整为可嵌入布局（`fillMaxWidth`），支持与日历模块同屏展示

### `app/src/main/java/com/simpleshift/scheduler/ui/calendar/`

- 日历 UI 模块目录
- 已实现 `CalendarScreen`：
  - 顶部“上月/下月”切换按钮 + "统计"按钮
  - 周标题（`日~六`）
  - 42 格（6×7）日历，每格展示“日期 + 班次简写”
  - 统计按钮点击后弹出 `AlertDialog`（`StatsDialog`），展示当月早/中/休/夜/学天数
- 接受回调：`onPreviousMonthClick`、`onNextMonthClick`、`onStatsClick`、`onDismissStats`

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

## 9. 阶段 15 架构更新：桌面小组件（规划中）

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
  - 今日班次（大字彩色）
  - 周期进度（当前/总天数 + 简易进度条）
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
