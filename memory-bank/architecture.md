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
