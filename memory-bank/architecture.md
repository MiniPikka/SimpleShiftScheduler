# 倒班助手架构说明（当前阶段）

## 1. 当前架构阶段

阶段 1-21 全部完成。应用功能完整，架构采用单模块 Android 应用，技术路线为 Kotlin + Jetpack Compose + MVVM + StateFlow。

已完成的功能：
- 阶段 1-15：全部功能（项目骨架、数据模型、核心算法、首页 UI、测试、日历页、班组切换 + 月度统计、设置页、日历提醒、代码加固、桌面 Widget）
- 阶段 16：首页精品化升级（NewHomeScreen + 组件化 UI）
- 2026-05-14a：日历独立路由（NavHost 三路由）、TodayShiftCard 横向重设计、Widget 美化（距休 + 简化进度）
- 阶段 17：V2 UI 设计系统（Design Token + 深色主题 + 底部导航栏 + Profile 页 + 牛马指数）
- 夜班提醒日期修复（NIGHT 班次日历事件前移一天）

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
    val shiftPremiums: Map<ShiftType, Int> = emptyMap()
)

data class SalaryBreakdown(
    val month: YearMonth,
    val shiftCounts: Map<ShiftType, Int>,
    val shiftPremiumTotal: Int
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
