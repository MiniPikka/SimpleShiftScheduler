# 倒班助手 App 实施计划（重新版）

## ✅ 实施约束（已确认）

- ShiftType 策略：英文枚举 + 资源文件映射中文，保证数据层稳定
- 首页班次文案：固定使用简写 `早/中/休/夜/学`
- 日期格式：仅要求本地化可读，不强制固定样式
- 刷新时机：App 从后台回到前台时自动刷新首页数据
- 日期计算：使用设备本地时区，`LocalDate.now()` 即时生效
- 分层策略：核心计算放在 domain 层，不在 ViewModel 内直接实现
- 测试范围：覆盖核心算法 + `HomeViewModel` 状态产出
- 目录规范：`domain/model/` 放核心业务模型；`data/model/` 放数据库实体/扩展模型

## 🎯 MVP 核心目标

**只实现最小闭环：给定任意日期 → 输出班次**

- [x] 能计算"任意日期"对应的班次
- [x] 能计算"任意日期"在周期中的位置（第几天）
- [x] 首页展示：今日日期 + 班次 + 周期进度

**已完成超出 MVP 范围：日历页、多班组切换、月度统计、设置页**

**阶段 8 已完成：设置页（自定义倒班规则 + DataStore 持久化）**

---

## 📋 阶段划分

### ✅ 阶段 1：项目骨架（已完成）
### ✅ 阶段 2：数据模型定义（已完成）
### ✅ 阶段 3：核心算法实现（已完成）
### ✅ 阶段 4：首页 UI（已完成）
### ✅ 阶段 5：测试与验收（已完成）
### ✅ 阶段 6：日历页基础实现（已完成）
### ✅ 阶段 7：班组切换 + 月度统计（已完成）
### ✅ 阶段 8：设置页（已完成）
### ✅ 阶段 9：闹钟提醒（已完成，后续被阶段 10 替换）
### ✅ 阶段 10：闹钟改为日历日程（当前阶段）

---

# ✅ 阶段 1：项目骨架

## Step 1.1：创建 Android 项目

| 项目 | 说明 |
|------|------|
| 模板 | Compose Activity |
| 包名 | `com.simpleshift.scheduler` |
| 语言 | Kotlin |
| Min SDK | 24 |

**验证**：App 能启动，显示默认文本

---

## Step 1.2：创建目录结构

```
app/src/main/java/com/simpleshift/scheduler/
├── ui/
│   └── home/
├── viewmodel/
├── data/
│   └── model/
├── domain/
│   └── model/
└── MainActivity.kt
```

**验证**：目录存在，无红色报错

---

# ✅ 阶段 2：数据模型定义

## Step 2.1：定义班次枚举

```kotlin
enum class ShiftType {
    MORNING, AFTERNOON, REST, NIGHT, STUDY
}
```

**展示映射**：
- 通过资源文件映射到 `早/中/休/夜/学`

**验证**：
- 能打印所有 5 种班次
- 无拼写不一致

---

## Step 2.2：定义倒班周期数组

**输入**（来自设计文档）：
```
早早中中休夜夜休休早早中中休夜休休休早早中休夜夜休休休早中中休夜夜休休学学学学学休休
```

**要求**：
- 长度 = 42
- 类型 = `List<ShiftType>`

**验证**：
- `周期.size == 42`
- `周期[0] == MORNING`
- `周期[41] == REST`

---

## Step 2.3：定义起始参考日期

**确定**：2025-12-15 为第 1 天

| 项目 | 值 |
|------|-----|
| 起始日期 | 2025-12-15 |
| 周期数组 | 早早中中休夜夜休休早早中中休夜休休休早早中休夜夜休休休早中中休夜夜休休学学学学学休休 |
| 周期长度 | 42 天 |

**验证**：
- 能打印起始日期
- 日期固定，不随系统变化

---

# ✅ 阶段 3：核心算法

## Step 3.1：计算日期偏移量

**输入**：目标日期（如 today）

**逻辑**：
```
偏移天数 = 目标日期 - 起始日期
```

**验证测试**：

| 输入 | 预期输出 |
|------|----------|
| 起始日期 | 0 |
| 起始日期 + 1 | 1 |
| 起始日期 + 42 | 0（回到起点）|
| 起始日期 - 1 | -1 |

---

## Step 3.2：计算周期索引

**逻辑**：
```
周期索引 = (偏移天数 % 42 + 42) % 42  // 处理负数
```

**范围**：0 ~ 41

**验证测试**：

| 输入 | 预期 |
|------|------|
| 偏移 0 | 0 |
| 偏移 1 | 1 |
| 偏移 41 | 41 |
| 偏移 42 | 0 |
| 偏移 -1 | 41 |

---

## Step 3.3：获取班次

**逻辑**：
```
班次 = 周期[周期索引]
```

**验证测试**：

| 周期索引 | 预期班次 |
|----------|----------|
| 0 | MORNING |
| 1 | MORNING |
| 2 | AFTERNOON |
| 3 | AFTERNOON |
| 4 | REST |
| 40 | STUDY |
| 41 | REST |

---

## Step 3.4：封装统一入口

**函数签名**：
```kotlin
fun getShiftInfo(date: LocalDate, teamPhaseOffset: Int = 0): ShiftInfo
```

**输出**：
```kotlin
data class ShiftInfo(
    val date: LocalDate,
    val dayOfCycle: Int,      // 1 ~ 42
    val shiftType: ShiftType
)
```

**验证测试**：

| 日期 | 预期 dayOfCycle | 预期 shiftType |
|------|-----------------|----------------|
| 起始日 | 1 | MORNING |
| 起始日 + 4 | 5 | REST |
| 起始日 + 41 | 42 | REST |

---

# ✅ 阶段 4：首页 UI

## Step 4.1：创建 HomeViewModel

**状态**：
```kotlin
data class HomeUiState(
    val todayDate: String,           // 本地化可读日期
    val shiftType: ShiftType,        // 今日班次
    val shiftLabel: String,          // 首页展示文案：早/中/休/夜/学
    val dayOfCycle: Int,             // 第几天
    val totalDays: Int = 42          // 周期总天数
)
```

**验证**：StateFlow 能正常发射数据

---

## Step 4.2：创建 HomeScreen

**布局**：
```
┌─────────────────────┐
│  今日日期: 2026年4月26日 星期日    │
│                             │
│  班次: 早                    │
│                             │
│  进度: 10 / 42               │
└─────────────────────┘
```

**验证**：
- 显示今日日期和星期
- 显示今日班次
- 显示"进度: X / 42"

---

## Step 4.3：整合 ViewModel + UI

**验证**：
- App 启动自动显示今日信息
- App 从后台回到前台时自动刷新数据（重新计算 `LocalDate.now()`）

---

# ✅ 阶段 5：测试与验收

## Step 5.1：核心算法单元测试

**覆盖点**：
- 偏移计算（含正数/负数/跨周期）
- 周期索引归一化（0~41）
- `getShiftInfo()` 的 `dayOfCycle` 与 `shiftType` 输出

## Step 5.2：HomeViewModel 状态测试

**覆盖点**：
- 初始状态可产出 `todayDate / shiftType / shiftLabel / dayOfCycle`
- 回到前台触发刷新后状态更新
- `shiftLabel` 映射固定为 `早/中/休/夜/学`

---

# ✅ 阶段 6：日历页基础实现

## Step 6.1：生成 7×7 月历数据

**目标**：
- 输入 `YearMonth`，输出 42 格（6 周 × 7 天）日历数据
- 默认周起始为周日
- 每格包含 `date / shiftType / isCurrentMonth`

**验证**：
- 输出长度固定为 42
- 第 1 格是周日
- `isCurrentMonth` 能正确区分当前月与补全日期

## Step 6.2：创建 CalendarViewModel

**目标**：
- 输出 `monthLabel / weekLabels / days`
- 支持“上月 / 下月”切换
- 复用 domain 层班次计算，不在 UI 写算法

**验证**：
- 初始月份可展示
- 点击上月/下月后数据刷新
- 班次文案映射固定为 `早/中/休/夜/学`

## Step 6.3：创建 CalendarScreen 并接入主界面

**目标**：
- 实现周标题 + 42 格日历 UI
- 每格展示日期与班次简写
- 将 CalendarScreen 接入 `MainActivity`

**验证**：
- 日历可见，显示 7 列
- 可切换上月/下月
- 与首页共存时无崩溃

---

# ✅ 阶段 7：班组切换 + 月度统计

## Step 7.1：定义班组数据模型

**目标**：
- 定义 `Team` 数据类（id, name）
- 支持 6 个固定班组

**数据**：
```kotlin
data class Team(
    val id: Int,
    val name: String  // "班组1" ~ "班组6"
)
```

**验证**：
- 6 个班组对象可正常创建

---

## Step 7.2：修改 HomeViewModel 支持班组切换

**目标**：
- 新增 `selectedTeamId` 状态
- 新增 `selectTeam(teamId)` 方法
- 班组切换后刷新今日班次

**状态扩展**：
```kotlin
data class HomeUiState(
    // ... 现有字段
    val selectedTeamId: Int = 1,
    val availableTeams: List<Team> = listOf(...)
)
```

**验证**：
- 切换班组后 `shiftType` 正确更新

---

## Step 7.3：修改 HomeScreen 添加班组下拉框

**目标**：
- 在首页顶部添加班组选择下拉框
- 下拉框显示 6 个班组选项

**验证**：
- 下拉框可见且可选择
- 选中后班次更新

---

## Step 7.4：实现月度统计功能

**目标**：
- 在日历页添加统计按钮
- 统计当月早/中/休/夜/学天数

**输出**：
```kotlin
data class MonthlyStats(
    val morningCount: Int,
    val afternoonCount: Int,
    val restCount: Int,
    val nightCount: Int,
    val studyCount: Int
)
```

**验证**：
- 统计按钮可点击
- 统计结果正确显示

---

## Step 7.5：添加 DataStore 持久化

**目标**：
- 保存用户选择的班组
- 应用启动时恢复上次选择

**依赖**：
- `androidx.datastore:datastore-preferences`

**验证**：
- 关闭应用后重新打开，班组选择保持

---

# ✅ 阶段 8：设置页（自定义倒班规则）

**核心目标**：用户可在设置页自定义倒班周期长度、每天班次、默认班组，保存后首页和日历页立即生效。

**前置条件**：阶段 1-7 已完成，Navigation Compose 和 DataStore 的依赖尚未引入 `build.gradle.kts`。

---

## Step 8.1：添加依赖（Navigation Compose + DataStore）

**目标**：
- 在 `app/build.gradle.kts` 添加导航和持久化依赖

**依赖**：
```kotlin
implementation("androidx.navigation:navigation-compose:2.7.6")
implementation("androidx.datastore:datastore-preferences:1.0.0")
```

**验证**：
- Gradle sync 成功，无依赖冲突

---

## Step 8.2：创建 RuntimeShiftSettings 运行时配置

**目标**：
- 定义用户可修改的周期配置数据类（区别于硬编码的 `ShiftCycleConfig`）
- 默认值与 `ShiftCycleConfig` 一致
- 支持 JSON 序列化（供 DataStore 持久化）

**新增文件**：
`app/src/main/java/com/simpleshift/scheduler/domain/model/RuntimeShiftSettings.kt`

**数据模型**：
```kotlin
data class RuntimeShiftSettings(
    val cycleLength: Int = 42,
    val shiftCycle: List<ShiftType> = ShiftCycleConfig.SHIFT_CYCLE,
    val defaultTeamId: Int = 1
) {
    val isValid: Boolean
        get() = cycleLength in 1..100 && shiftCycle.size == cycleLength
                && shiftCycle.all { it in ShiftType.entries }
                && defaultTeamId in 1..Team.TOTAL_TEAMS
}
```

**验证**：
- 默认 `RuntimeShiftSettings` 的 `isValid == true`
- 长度不匹配时 `isValid == false`

---

## Step 8.3：Refactor shift_calculator 支持自定义周期

**目标**：
- 所有计算函数增加 `customCycle: List<ShiftType>? = null` 参数
- 传入时使用自定义周期，否则回退到 `ShiftCycleConfig.SHIFT_CYCLE`
- `normalizeCycleIndex` 接受动态 `cycleLength`
- 向后兼容：默认参数保证现有调用无需修改

**改造函数签名**：
```kotlin
fun normalizeCycleIndex(
    offsetDays: Int,
    cycleLength: Int = ShiftCycleConfig.CYCLE_LENGTH
): Int

fun getShiftTypeForDate(
    date: LocalDate,
    teamPhaseOffset: Int = 0,
    customCycle: List<ShiftType>? = null
): ShiftType

fun getShiftInfo(
    date: LocalDate,
    teamPhaseOffset: Int = 0,
    customCycle: List<ShiftType>? = null
): ShiftInfo
```

**实现逻辑**：
```
val cycle = customCycle ?: ShiftCycleConfig.SHIFT_CYCLE
val length = cycle.size
// offset → normalize(index, length) → cycle[index]
```

**验证**：
- 不传 `customCycle` 时行为与当前一致
- 传入 7 天自定义周期后 `dayOfCycle` 范围 1..7
- 自定义周期下 `shiftType` 正确

---

## Step 8.4：改造 calendar_generator 支持自定义周期

**目标**：
- `generateMonthCalendarDays` 增加 `customCycle` 参数透传

**函数签名**：
```kotlin
fun generateMonthCalendarDays(
    yearMonth: YearMonth,
    firstDayOfWeek: DayOfWeek = DayOfWeek.SUNDAY,
    teamPhaseOffset: Int = 0,
    customCycle: List<ShiftType>? = null
): List<CalendarDayInfo>
```

**验证**：
- 不传参数行为不变，传入自定义周期日历反映新规则

---

## Step 8.5：创建 SettingsViewModel

**目标**：
- 管理设置页状态：周期长度、每天班次编辑、默认班组
- `save()` 通过 Activity 级共享 `StateFlow` 通知首页和日历页刷新
- `cancel()` 放弃编辑恢复上次保存状态

**新增文件**：
`app/src/main/java/com/simpleshift/scheduler/viewmodel/SettingsViewModel.kt`

**状态设计**：
```kotlin
data class SettingsUiState(
    val cycleLength: Int = 42,
    val shiftCycle: List<ShiftType> = ShiftCycleConfig.SHIFT_CYCLE,
    val defaultTeamId: Int = 1,
    val availableTeams: List<Team> = Team.ALL_TEAMS,
    val isDirty: Boolean = false,
    val isSaved: Boolean = false
)
```

**方法**：
- `updateCycleLength(n: Int)` — 修改长度，变长以 REST 填充，变短截断
- `setDayShift(dayIndex: Int, shiftType: ShiftType)` — 设置某天班次
- `selectDefaultTeam(teamId: Int)` — 设置默认班组
- `save()` — 写 DataStore + 更新共享 StateFlow
- `cancel()` — 恢复到上次保存状态

**跨 ViewModel 通信方案**：
`MainActivity` 持有 `MutableStateFlow<RuntimeShiftSettings>`，SettingsViewModel 写入，HomeViewModel/CalendarViewModel 在 `refreshToday()/refresh()` 中读取当前值作为 `customCycle` 参数。

**验证**：
- `updateCycleLength(7)` 后 `shiftCycle.size == 7`
- `setDayShift(0, NIGHT)` 后列表首项 = NIGHT
- `save()` → `isSaved = true`, `isDirty = false`
- `cancel()` 恢复到保存前值

---

## Step 8.6：创建 SettingsScreen UI

**目标**：
- 设置页 Compose UI，可编辑所有规则
- 顶部 AppBar + 返回按钮，底部保存/取消按钮
- 周期长度输入框 + 班次网格编辑器 + 默认班组下拉框

**新增文件**：
`app/src/main/java/com/simpleshift/scheduler/ui/settings/SettingsScreen.kt`

**布局设计**：
```
┌──────────────────────────────┐
│  ← 返回    倒班规则设置        │  TopAppBar
├──────────────────────────────┤
│  周期长度: [42] 天             │  OutlinedTextField
│                              │
│  每天班次（共 42 天）           │
│  ┌────┬────┬────┬────┐       │
│  │第1天│第2天│第3天│第4天│      │  LazyVerticalGrid(4 cols)
│  │ 早  │ 早  │ 中  │ 中  │      │  每格: 序号 + Dropdown
│  │ ... │ ... │ ... │ ... │      │
│  └────┴────┴────┴────┘       │
│                              │
│  默认班组: [班组1 ▼]           │  ExposedDropdownMenuBox
│                              │
│  [  保存  ]    [  取消  ]      │  Button + OutlinedButton
└──────────────────────────────┘
```

**交互细节**：
- 修改周期长度时自动调整列表（增长率填充 REST）
- `isDirty = true` 时返回按钮触发确认对话框
- 保存成功后 Snackbar 提示
- 班组偏移步长随周期长度变化：`teamPhaseStep = cycleLength / 6`

**验证**：
- 42 天可在 4 列网格中正常滚动（约 10 行）
- 下拉框可选择 5 种班次
- 返回/取消按钮正常工作

---

## Step 8.7：设置 Navigation Compose 路由 + 改造 MainActivity

**目标**：
- 用 Navigation Compose 管理主页面 ↔ 设置页切换
- 提取当前同屏布局为 `MainScreen` Composable
- 在顶部添加"设置"导航按钮
- 共享 `RuntimeShiftSettings` 的 StateFlow 给各 ViewModel

**改造文件**：
`app/src/main/java/com/simpleshift/scheduler/MainActivity.kt`

**路由**：
```kotlin
sealed class Route(val route: String) {
    object Main : Route("main")
    object Settings : Route("settings")
}
```

**NavHost 结构**：
```kotlin
NavHost(navController, startDestination = Route.Main.route) {
    composable(Route.Main.route) {
        MainScreen(onNavigateToSettings = { navController.navigate(Route.Settings.route) })
    }
    composable(Route.Settings.route) {
        SettingsScreen(onNavigateBack = { navController.popBackStack() })
    }
}
```

**共享状态传递**：
- `RuntimeShiftSettings` 的 `MutableStateFlow` 在 `MainActivity` 中创建
- 构造 SettingsViewModel/HomeViewModel/CalendarViewModel 时注入设置流
- 设置保存时 → 写入 StateFlow → HomeViewModel/CalendarViewModel 自动刷新

**验证**：
- 点击"设置"按钮跳转到设置页
- 设置页返回后状态保持
- 修改设置保存后返回，首页和日历页立刻反映新规则

---

## Step 8.8：实现 DataStore 持久化

**目标**：
- 保存/加载 `RuntimeShiftSettings` 到 DataStore
- 首次启动使用 `ShiftCycleConfig` 默认值
- 解析失败时回退默认值

**新增文件**：
`app/src/main/java/com/simpleshift/scheduler/data/repository/SettingsRepository.kt`

**持久化方案**（简化，不引入 kotlinx.serialization）：
```kotlin
class SettingsRepository(private val dataStore: DataStore<Preferences>) {
    companion object {
        val KEY_CYCLE_LENGTH = intPreferencesKey("cycle_length")
        val KEY_SHIFT_CYCLE = stringPreferencesKey("shift_cycle")    // "MORNING,MORNING,..."
        val KEY_DEFAULT_TEAM = intPreferencesKey("default_team")
    }

    val settingsFlow: Flow<RuntimeShiftSettings> = dataStore.data.map { prefs ->
        try {
            RuntimeShiftSettings(
                cycleLength = prefs[KEY_CYCLE_LENGTH] ?: 42,
                shiftCycle = parseShiftCycle(prefs[KEY_SHIFT_CYCLE] ?: ""),
                defaultTeamId = prefs[KEY_DEFAULT_TEAM] ?: 1
            )
        } catch (e: Exception) { RuntimeShiftSettings() }
    }

    suspend fun saveSettings(settings: RuntimeShiftSettings) { ... }
}
```

**启动恢复流程**：
`MainActivity` 在 `onCreate` 中通过 `settingsRepository.settingsFlow` 加载上次配置，传入共享 StateFlow。

**验证**：
- 关闭应用后重新打开，设置保持
- 首次安装默认使用 42 天周期
- 非法数据回退到默认值

---

## Step 8.9：单元测试与验收

**目标**：
- SettingsViewModel 的 save/cancel/edit 逻辑测试
- 自定义周期在 shift_calculator 中计算正确性测试
- 现有测试全部保持通过

**新增/追加测试**：

| 测试类 | 内容 |
|--------|------|
| `SettingsViewModelTest`（新增） | 默认状态、updateCycleLength、setDayShift、save/cancel、isDirty 标志 |
| `ShiftCalculatorTest`（追加） | 7 天自定义周期、1 天边界、`dayOfCycle` 范围正确 |

**验收命令**：
```bash
./gradlew testDebugUnitTest   # 全部通过
```

---

# 📊 检查清单

## 可执行性检查

- [x] 每个 Step 有明确输入输出
- [x] 每个 Step 有具体验证测试
- [x] 步骤顺序无依赖循环
- [x] 不需要额外知识即可执行

## 完整性检查

- [x] 覆盖 MVP 全部需求
- [x] 排除项明确列出
- [x] 有边界测试用例

---

# ✅ 已确认事项

| 问题 | 答案 |
|------|------|
| 起始日期 | 2025-12-15 为第 1 天 |
| 进度含义 | 周期第几天（1~42） |
| 首页"6 个值" | MVP 暂不显示，只显示"1 值"今日班次 |
| 周期数组 | 正确无误 |
| ShiftType 枚举 | 英文枚举 + 资源映射 |
| 首页班次文案 | `早/中/休/夜/学` |
| 日期格式要求 | 本地化可读即可 |
| 自动刷新时机 | 后台回前台时刷新 |
| 时区规则 | 设备本地时区，`LocalDate.now()` 即时生效 |
| 分层策略 | domain 层负责核心计算 |
| 测试范围 | 核心算法 + HomeViewModel + CalendarGenerator + 班组偏移 + SettingsViewModel + 自定义周期 + 闹钟调度 |
| 目录规范 | `domain/model` 与 `data/model` 分层 |

---

# ✅ 阶段 9：闹钟提醒

**核心目标**：为每个班次类型设置独立的闹钟提醒，使用 Android AlarmManager 实现精确调度。

**前置条件**：阶段 1-8 已完成，所有现有依赖足够（无需新增外部库）。

---

## Step 9.1：创建闹钟数据模型

**新增文件**：
- `domain/model/AlarmTime.kt` — `data class AlarmTime(hour: Int, minute: Int)`，含 0..23/0..59 校验，`toEpochMillis(date)` 方法
- `domain/model/AlarmSettings.kt` — `data class AlarmSettings(alarms: Map<ShiftType, AlarmTime?>)`，含 `isEnabled(shiftType)`/`isAnyEnabled()` 方法，默认为全部 null（禁用）

**测试**：`AlarmTimeTest.kt`（构造边界、校验、toEpochMillis），`AlarmSettingsTest.kt`（默认全禁用、启用检测）

## Step 9.2：扩展 DataStore 持久化

**改造文件**：`SettingsRepository.kt`
- 新增 5 个 `stringPreferencesKey("alarm_time_${type.name.lowercase()}")`
- 新增 `alarmSettingsFlow: Flow<AlarmSettings>` — 以 `"HH:MM"` 格式反序列化，空字符串 = null
- 新增 `suspend saveAlarmSettings(settings: AlarmSettings)` — 写入 DataStore
- 新增 `parseAlarmTime(raw: String): AlarmTime?` — 辅助解析

## Step 9.3：创建 AlarmScheduler 调度引擎

**新增文件**：`alarm/AlarmScheduler.kt`
- `class AlarmScheduler(context: Context)` 包装 AlarmManager
- `scheduleForNextSevenDays(alarmSettings, shiftCycle, teamPhaseOffset)` — 取消并重新调度未来 7 天闹钟
- `cancelAll()` — 清除当前范围内所有闹钟
- Request code: `(date.toEpochDay().toInt() * 10) + shiftType.ordinal`
- API 31+ 精确闹钟降级策略

## Step 9.4：创建 Android 组件

**新增文件**：
- `alarm/AlarmReceiver.kt` — `BroadcastReceiver`，解析 Intent，构建通知（`NotificationCompat.Builder`）
- `alarm/BootReceiver.kt` — `BroadcastReceiver`，`BOOT_COMPLETED` 触发，使用 `goAsync()` + `CoroutineScope(Dispatchers.IO)` 恢复闹钟
- `res/drawable/ic_alarm.xml` — 通知图标（矢量闹钟图标）

**改造文件**：
- `AndroidManifest.xml` — 添加 3 个权限 + 2 个 receiver 声明
- `strings.xml` — 添加 12 个新字符串（闹钟设置、对话框、通知、权限）

## Step 9.5：扩展 SettingsViewModel

**改造文件**：`SettingsViewModel.kt`
- `SettingsUiState` 新增 `alarmSettings: AlarmSettings` 字段
- 构造参数新增 `initialAlarmSettings` 和 `onAlarmSettingsChanged` 回调
- 新增 `updateAlarmTime(shiftType, alarmTime?)` 方法，立即触发回调（自动保存）
- `cancel()` 不重置闹钟设置（仅还原周期设置）

## Step 9.6：扩展 SettingsScreen 闹钟 UI

**改造文件**：`SettingsScreen.kt`
- 新增 `onUpdateAlarmTime: (ShiftType, AlarmTime?) -> Unit` 参数
- 新增闹钟设置区：`ShiftAlarmRow` 列表（标签 + 时间按钮）+ `AlarmTimePickerDialog`（时/分文本输入）
- 每行显示班次名和当前时间或"未设置"

## Step 9.7：MainActivity 集成

**改造文件**：`MainActivity.kt`
- `onCreate` 中创建通知渠道（`createNotificationChannel`）
- 新增 `combine(settingsFlow, alarmSettingsFlow)` 双流监听，自动调度闹钟
- 新增 `rescheduleAlarms(alarmSettings, shiftSettings)` 辅助方法
- SettingsViewModel 工厂扩展：注入 `initialAlarmSettings` + `onAlarmSettingsChanged`
- SettingsScreen 调用传递 `onUpdateAlarmTime`
- `onResume` 中重新调度闹钟（处理时区变更）

## 验收命令

```bash
./gradlew testDebugUnitTest   # 全部通过
```

---

# ✅ 阶段 10：闹钟改为日历日程

**核心目标**：将 AlarmManager + BroadcastReceiver 闹钟方案替换为 Calendar Provider 日历日程方案，提高跨品牌 Android 设备兼容性。

**前置条件**：阶段 1-9 已完成。阶段 9 的 AlarmTime/AlarmSettings 数据模型保留，UI 基本不变。

**迁移原因**：
- AlarmManager 在国产手机（小米/华为/OPPO/Vivo）上被厂商杀后台机制严重影响，闹钟延迟或丢失
- Calendar Provider 是 AOSP 标准 API（API 14+），所有品牌必须支持
- 日历日程持久化在系统日历数据库，跨重启自动恢复，无需 BootReceiver
- 减少权限：3 个（SCHEDULE_EXACT_ALARM + POST_NOTIFICATIONS + RECEIVE_BOOT_COMPLETED）→ 2 个（READ_CALENDAR + WRITE_CALENDAR）

---

## Step 10.1：创建 CalendarEventIds 数据模型

**新增文件**：`domain/model/CalendarEventIds.kt`

**数据模型**：
```kotlin
data class CalendarEventIds(
    val eventIds: Map<String, Long> = emptyMap()  // "yyyy-MM-dd_SHIFT_TYPE" -> eventId
)
```

用于持久化追踪已写入系统日历的日程 eventId，以便后续更新/删除时定位。

---

## Step 10.2：扩展 SettingsRepository 支持日程ID持久化

**改造文件**：`SettingsRepository.kt`

- 新增 DataStore key：`KEY_CALENDAR_EVENT_IDS: stringPreferencesKey("calendar_event_ids")`
- 事件ID序列化格式：`"2026-05-09_MORNING=42,2026-05-10_MORNING=43"`（每个条目用逗号分隔，key=value 用等号分隔）
- 新增 `calendarEventIdsFlow: Flow<CalendarEventIds>` — 从 DataStore 加载已持久化的日程 ID
- 新增 `suspend saveCalendarEventIds(ids: CalendarEventIds)` — 写入 DataStore

---

## Step 10.3：创建 CalendarEventManager

**新增文件**：`calendar/CalendarEventManager.kt`

**职责**：管理系统日历日程的增删改查，替代 AlarmScheduler。

**核心能力**：

1. `getOrCreateLocalCalendar(): Long`
   - 查询系统日历中的本地日历账户（`ACCOUNT_TYPE_LOCAL` + `ownerAccount` 匹配）
   - 不存在则创建：`ContentValues` 写入 `CalendarContract.Calendars.CONTENT_URI`
   - 返回 `calendarId`

2. `syncNextSevenDays(alarmSettings, shiftCycle, teamPhaseOffset, existingEventIds): CalendarEventIds`
   - 计算未来 7 天每天班次
   - 构建预期日程列表（date + shiftType）→ 与已存储日程对比
   - **需要新建的日程** → `insertEvent()`: 写入 `CalendarContract.Events` + 设置 `Reminders.METHOD_ALERT`（准时提醒）
   - **已存在且未变化** → 保留（保留现有 eventId）
   - **不再需要的日程** → `deleteEvent()`: 按 eventId 删除
   - 返回新的 `CalendarEventIds` 供持久化

3. `deleteEvents(eventIds: CalendarEventIds)` — 批量删除已追踪的日程

**日程内容设计**：
- `TITLE` = "{班次标签}班提醒"（如"早班提醒"）
- `DESCRIPTION` = "{班次标签}班 - 倒班助手"
- `DTSTART` = 日期 + 提醒时间
- `DTEND` = DTSTART + 15分钟
- `HAS_ALARM` = 1
- `AVAILABILITY` = `AVAILABILITY_BUSY`
- 提醒：`METHOD_ALERT`, `MINUTES` = 0（准时提醒）

---

## Step 10.4：删除旧闹钟组件

**删除文件**：
- `alarm/AlarmScheduler.kt` — 被 CalendarEventManager 替代
- `alarm/AlarmReceiver.kt` — 日历系统自动触发提醒
- `alarm/BootReceiver.kt` — 日程持久化在日历数据库，重启不丢失
- `res/drawable/ic_alarm.xml` — 不再需要自定义通知图标

**删除测试**：
- `alarm/AlarmSchedulerTest.kt`
- `alarm/AlarmReceiverTest.kt`

---

## Step 10.5：更新 AndroidManifest.xml

**移除**：
- `<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />`
- `<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />`
- `<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />`
- `<receiver android:name=".alarm.AlarmReceiver" />`
- `<receiver android:name=".alarm.BootReceiver" />`

**新增**：
- `<uses-permission android:name="android.permission.READ_CALENDAR" />`
- `<uses-permission android:name="android.permission.WRITE_CALENDAR" />`

---

## Step 10.6：改造 MainActivity

**改造**：`MainActivity.kt`

- 移除 `createNotificationChannel()` 调用和方法
- 移除 `rescheduleAlarms()` 方法（替换为 `syncCalendarEvents()`）
- 移除 `AlarmScheduler` / `AlarmReceiver` / `BootReceiver` 相关 import
- 新增 `CalendarEventManager` 集成
- 新增 `syncCalendarEvents(alarmSettings, shiftSettings, eventIds)` 辅助方法
- `combine` 从双流改为三流：`settingsFlow + alarmSettingsFlow + calendarEventIdsFlow`
- `onResume` 中调用 `syncCalendarEvents` 替代 `rescheduleAlarms`
- 日历权限请求逻辑：在 `onCreate` 中检查并请求 `READ_CALENDAR` + `WRITE_CALENDAR`

---

## Step 10.7：更新 strings.xml

**移除**：通知渠道相关字符串（`channel_name`, `channel_description`, `alarm_notification_title`, `alarm_notification_body`）

**保留**：闹钟设置 UI 字符串（`alarm_section_title`, `alarm_not_set`, `alarm_dialog_*`），这些在设置页的提醒时间 UI 中仍然使用。

---

## Step 10.8：SettingsScreen/SettingsViewModel 适配

**改造**：`SettingsScreen.kt`

- UI 文案从"闹钟"改为"提醒"（可选，保留"闹钟"也可）
- 删除按钮文案从"关闭此班次闹钟"改为"关闭此班次提醒"
- 对话框标题从"设置闹钟时间"改为"设置提醒时间"

**保留**：`SettingsViewModel.kt` 逻辑不变，`updateAlarmTime` 回调仍然触发数据保存和日程同步。

---

## 验收命令

```bash
./gradlew testDebugUnitTest   # 全部通过
```

---

