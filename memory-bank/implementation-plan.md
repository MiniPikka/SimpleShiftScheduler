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
### ✅ 阶段 10：闹钟改为日历日程（已完成）

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

# ✅ 阶段 11：Bug 修复与代码加固

**核心目标**：修复已发现的逻辑缺陷和架构不一致问题，提升应用鲁棒性。

**前置条件**：阶段 1-10 已完成。2026-05-13 全项目审查通过（26 个源文件 + 7 个测试文件，`BUILD SUCCESSFUL`）。

**审查发现**：
1. `SettingsViewModel.cancel()` 回退到构造函数初始值，而非最后保存值 —— 用户多次保存后取消会丢失中间状态
2. `CalendarSyncManager.syncFromCurrentState()` 静默吞掉所有异常 —— 用户无法感知日历同步失败
3. `CalendarViewModel` 直接调用 `LocalDate.now()` —— 与 `HomeViewModel` 的注入模式不一致，不可测试
4. 日历网格高度硬编码 `430.dp` —— 不同屏幕密度下布局异常
5. 日历页无"回到今天"按钮 —— 用户浏览到远处月份后无法一键返回

---

## Step 11.1：修复 SettingsViewModel.cancel() 回退逻辑

**目标**：`cancel()` 必须回退到最近一次保存的状态，而非 ViewModel 构造时的初始状态。

**当前问题**（`SettingsViewModel.kt:43,99-107`）：
```kotlin
private val savedSettings = initialSettings  // val，永远不会更新

fun cancel() {
    _uiState.value = SettingsUiState(
        cycleLength = savedSettings.cycleLength,   // 永远是 initialSettings
        shiftCycle = savedSettings.shiftCycle,
        defaultTeamId = savedSettings.defaultTeamId,
        alarmSettings = current.alarmSettings
    )
}
```

**场景复现**：
1. 用户进入设置页 → 初始周期 42 天
2. 用户改为 30 天 → 保存 → 生效（savedSettings 仍为 42 天初始值）
3. 用户再改为 20 天 → 不保存 → 点取消
4. **错误结果**：回退到 42 天（初始值），丢失了步骤 2 保存的 30 天
5. **正确结果**：应回退到 30 天（最近一次保存值）

**修复方案**：`savedSettings` 改为 `var`，在 `save()` 中更新引用。

**改造文件**：`viewmodel/SettingsViewModel.kt`

**改造内容**：
```kotlin
// 将 val savedSettings 改为 var，并在 save() 中更新
private var savedSettings: RuntimeShiftSettings = initialSettings

fun save() {
    // ... 现有构建 settings 逻辑不变
    savedSettings = settings  // 新增：更新已保存状态引用
    onSettingsSaved(settings)
    _uiState.value = current.copy(isDirty = false, isSaved = true)
}
```

**验证**：
- `SettingsViewModelTest` 新增：`cancel after two saves restores last-saved state`
- 步骤：初始 42 → 改为 30 → save → 改为 20 → cancel → 断言 = 30

---

## Step 11.2：CalendarSyncManager 错误状态可见化

**目标**：日历同步失败时通过 StateFlow 暴露错误，让 UI 有机会展示提示。

**当前问题**（`CalendarSyncManager.kt:71-82`）：
```kotlin
fun syncFromCurrentState() {
    if (!hasCalendarPermissions()) return
    scope.launch {
        syncMutex.withLock {
            try {
                // ... 同步逻辑
            } catch (_: Exception) {}  // 静默吞掉所有异常
        }
    }
}
```

**影响**：ContentProvider 异常、日历账户创建失败、日程写入失败——所有错误用户完全无感知。

**修复方案**：新增 `syncErrorFlow: StateFlow<String?>`，同步失败发射错误消息，成功发射 null。`MainActivity` 可选消费但不阻塞主流程。

**改造文件**：
- `CalendarSyncManager.kt` — 新增 `_syncError` MutableStateFlow + `syncErrorFlow` + `clearSyncError()`
- `MainActivity.kt` — 收集 `syncErrorFlow`，在 UI 中展示 Snackbar（非阻塞、不干扰用户操作）

**新增属性**：
```kotlin
private val _syncError = MutableStateFlow<String?>(null)
val syncErrorFlow: StateFlow<String?> = _syncError.asStateFlow()

fun clearSyncError() { _syncError.value = null }
```

**异常处理改为**：
```kotlin
} catch (e: Exception) {
    _syncError.value = "日历提醒同步失败: ${e.localizedMessage ?: "请检查日历权限"}"
}
```

**验证**：
- 权限未授予时不触发错误（`hasCalendarPermissions()` 提前返回）
- 同步成功不产生错误
- syncMutex 竞态不产生重复错误

---

## Step 11.3：CalendarViewModel 测试性对齐

**目标**：`CalendarViewModel` 支持注入日期提供器，与 `HomeViewModel` 注入 `currentDateProvider` 的模式一致。

**当前问题**（`CalendarViewModel.kt:111`）：
```kotlin
isToday = day.date == LocalDate.now()  // 硬编码，无法在测试中控制
```

`CalendarViewModel` 已有 `monthProvider` 注入，但"今天"标记仍然硬编码。

**修复方案**：新增 `todayProvider: () -> LocalDate` 构造函数参数，默认 `{ LocalDate.now() }`。行为零变化，仅开启测试能力。

**改造文件**：`CalendarViewModel.kt`

**改造内容**：
```kotlin
class CalendarViewModel(
    application: Application,
    private val localeProvider: () -> Locale = { Locale.getDefault() },
    private val monthProvider: () -> YearMonth = { YearMonth.now() },
    private val todayProvider: () -> LocalDate = { LocalDate.now() }  // 新增
) : AndroidViewModel(application) {

    // 在 secondary constructor 中传入默认值
    constructor(application: Application) : this(
        application = application,
        localeProvider = { Locale.getDefault() },
        monthProvider = { YearMonth.now() },
        todayProvider = { LocalDate.now() }
    )

    fun refresh() {
        val today = todayProvider()
        // ... days.map 中使用 today 替代 LocalDate.now()
    }
}
```

**验证**：
- 现有调用方（`MainActivity` 通过 `by viewModels()` 使用 secondary constructor）零改动
- 阶段 12 的 `CalendarViewModelTest` 可注入固定日期验证 `isToday`

---

## Step 11.4：日历网格响应式高度

**目标**：日历网格高度根据内容自适应，不再硬编码 `430.dp`。

**当前问题**（`CalendarScreen.kt:78-79`）：
```kotlin
LazyVerticalGrid(
    modifier = Modifier.height(430.dp),  // 硬编码
```

低密度大屏上格子过高、高密度小屏上内容裁剪。

**修复方案**：每个日期格使用 `Modifier.aspectRatio(0.85f)` 保持合理宽高比，`LazyVerticalGrid` 本身不再限定高度（使用 `fillMaxWidth()` + 内容撑开）。

**改造文件**：`CalendarScreen.kt`

**改造内容**：
- `CalendarDayCell` 的 Card 增加 `Modifier.aspectRatio(0.85f)`
- `LazyVerticalGrid` 移除 `Modifier.height(430.dp)`
- 评估是否需要将 `LazyVerticalGrid` 的 `userScrollEnabled = false` 改为允许滚动（当屏幕不足以显示 6 行时）

**验证**：
- 在 3 种屏幕密度下确认日历网格无裁剪、无异常留白
- 42 格均在可见范围内

---

## Step 11.5：日历页添加"回到今天"按钮

**目标**：用户在浏览历史/未来月份后能一键返回当前月。

**改造文件**：`CalendarViewModel.kt` + `CalendarScreen.kt` + `MainActivity.kt`

**改造内容**：
- `CalendarViewModel` 新增 `goToToday()` 方法——重置 `currentMonth` 为 `monthProvider()` 并 `refresh()`
- `CalendarScreen` 月份导航栏添加"今天"文本按钮，点击通知 ViewModel（仅在非当前月时显示）

**验证**：
- 切换到 5 个月前 → 点击"今天" → 回到当前月
- 当前月时按钮不显示（无多余 UI）

---

## 验收命令

```bash
./gradlew testDebugUnitTest   # 全部通过，阶段 11 不引入回归
```

---

# ✅ 阶段 12：测试覆盖补全

**核心目标**：为核心 ViewModel、持久化仓储补充单元测试，消除测试盲区。

**前置条件**：阶段 11 完成（CalendarViewModel 测试性改造是 CalendarViewModelTest 的前置条件）。

**当前测试覆盖现状**：

| 被测试组件 | 测试文件 | 覆盖状态 |
|-----------|---------|---------|
| shift_calculator + calendar_generator | ShiftCalculatorTest + CalendarGeneratorTest | ✅ 充分 |
| HomeViewModel | HomeViewModelTest | ✅ 充分 |
| SettingsViewModel | SettingsViewModelTest | ✅ 充分（阶段 11.1 后追加 1 个取消测试） |
| CalendarEventManager | CalendarEventManagerTest | ✅ 充分（含 FakeCalendarResolver） |
| **CalendarViewModel** | **无** | ❌ 零覆盖 |
| **SettingsRepository** | **无** | ❌ 零覆盖 |
| **CalendarSyncManager** | **无** | ❌ 零覆盖 |

---

## Step 12.1：CalendarViewModelTest

**新增文件**：`app/src/test/java/com/simpleshift/scheduler/viewmodel/CalendarViewModelTest.kt`

**覆盖点**（共 9 个测试用例）：

| # | 测试用例 | 验证内容 |
|---|---------|---------|
| 1 | `initial state produces 42 days` | 初始化后 days 非空、size == 42、monthLabel 非空 |
| 2 | `weekLabels contain correct order` | 7 个周标签 = ["日","一","二","三","四","五","六"] |
| 3 | `goToPreviousMonth decrements month` | monthLabel 反映上一个月 |
| 4 | `goToNextMonth increments month` | monthLabel 反映下一个月 |
| 5 | `goToToday resets to current month` | 浏览远处后 goToToday() 回到设定月份 |
| 6 | `isToday marks correct cell` | 注入固定 todayProvider，验证有一个 day.isToday = true |
| 7 | `computeStats produces non-null stats` | stats 触发后 UiState.stats != null，计数正确 |
| 8 | `dismissStats clears stats to null` | dismiss 后 stats == null |
| 9 | `setTeam changes shift labels` | 切换班组后 days 的 shiftLabel 变化 |

**测试技术**：Robolectric + 注入 `localeProvider`/`monthProvider`/`todayProvider`。`monthProvider` 固定为 `YearMonth.of(2026, 5)`。

**验证**：
```bash
./gradlew testDebugUnitTest --tests "*CalendarViewModelTest"
```

---

## Step 12.2：SettingsRepositoryTest

**新增文件**：`app/src/test/java/com/simpleshift/scheduler/data/repository/SettingsRepositoryTest.kt`

**覆盖点**（共 7 个测试用例）：

| # | 测试用例 | 验证内容 |
|---|---------|---------|
| 1 | `default flow returns RuntimeShiftSettings()` | 首次无数据时 flow 发射默认值 |
| 2 | `save and read roundtrip` | 保存自定义 30 天周期后 flow 产出匹配 |
| 3 | `mismatched cycle length falls back` | cycle_length=50 但 shift_cycle 只有 42 个 → 回退默认 |
| 4 | `invalid shift_cycle string falls back` | 非法枚举名 → deserializeShiftCycle 返回 null → 回退默认 |
| 5 | `alarmSettings save and read roundtrip` | 设置 3 个闹钟时间后 flow 产出匹配，null 的为空字符串 |
| 6 | `calendarEventIds save and read roundtrip` | 多条目 eventId 映射序列化往返正确 |
| 7 | `empty alarmSettings and eventIds first launch` | 空字符串解析为 AlarmSettings() 和 CalendarEventIds() |

**测试技术**：Robolectric + `ApplicationProvider.getApplicationContext()` + 内存 DataStore。

**验证**：
```bash
./gradlew testDebugUnitTest --tests "*SettingsRepositoryTest"
```

---

## Step 12.3：CalendarSyncManager 关键路径测试（可选）

**目标**：验证 `combine` 三流和非权限路径逻辑。

**复杂度评估**：`CalendarSyncManager` 依赖 3 层外部组件（Context、SettingsRepository、CalendarEventManager），完整单元测试需要 mock 全部三层。考虑到：
- `CalendarEventManager` 已有 `CalendarEventManagerTest` 完整覆盖
- `SettingsRepository` 在 Step 12.2 中将有独立测试
- `CalendarSyncManager` 核心逻辑 = 三流组合 + Mutex 防竞态 + 权限判断

**最小可行方案**：如果 mock 成本可接受（约 50 行 mock 设置），覆盖：
- 权限未授予时不启动同步
- 权限授予后 combine 收集触发 `syncShiftEvents` 调用
- `syncFromCurrentState` 在无权限时直接返回

**如果 mock 难度过高，可跳过此步骤**，将验证重点放在 Step 12.1 和 12.2。

---

## 验收命令

```bash
./gradlew testDebugUnitTest   # 全部通过（新增约 16+ 个测试，不引入回归）
```

---

# ✅ 阶段 13：代码简洁性提升

**核心目标**：消除重复代码，提取共用组件。小范围重构，不改变任何行为。

**前置条件**：阶段 11-12 完成（确保重构前测试覆盖充分）。

---

## Step 13.1：移除重复的 ShiftLabel 映射包装

**当前问题**：三处存在仅一行、完全相同的包装函数：
- `HomeViewModel.mapShiftLabel()` (line 72-73)
- `CalendarViewModel.mapShiftLabel()` (line 123-124)
- `SettingsScreen.shiftTypeToLabel()` (line 301-302)

三者都是 `ShiftLabelMapper.toLabel(shiftType)` 的别名。

**修复方案**：在所有调用点直接使用 `ShiftLabelMapper.toLabel()`，删除中间包装函数。

**改造文件**：
- `HomeViewModel.kt` — `mapShiftLabel(shiftInfo.shiftType)` → `ShiftLabelMapper.toLabel(shiftInfo.shiftType)`, 删除 `mapShiftLabel` 方法
- `CalendarViewModel.kt` — `mapShiftLabel(day.shiftType)` → `ShiftLabelMapper.toLabel(day.shiftType)`, 删除 `mapShiftLabel` 方法
- `SettingsScreen.kt` — `shiftTypeToLabel(type)` → `ShiftLabelMapper.toLabel(type)`, 删除 `shiftTypeToLabel` 函数

**验证**：
- `grep -r "mapShiftLabel\|shiftTypeToLabel" app/src/main/` 无匹配
- 所有现有测试通过

---

## Step 13.2：提取共用 TeamDropdown 组件

**当前问题**：`HomeScreen` 内联实现班组下拉框（约 25 行），`SettingsScreen` 有几乎相同的私有 `TeamDropdown`（约 24 行），逻辑完全重复。

**修复方案**：提取为顶层 Composable，放在 `ui/` 目录下。

**新增/修改文件**：
- 新建 `app/src/main/java/com/simpleshift/scheduler/ui/common/CommonComponents.kt`，包含 `TeamDropdown` Composable
- `HomeScreen.kt` — 替换内联 `ExposedDropdownMenuBox` 逻辑为 `TeamDropdown` 调用
- `SettingsScreen.kt` — 删除私有 `TeamDropdown`，改为 import 共用组件

**组件签名**：
```kotlin
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TeamDropdown(
    selectedTeamId: Int,
    availableTeams: List<Team>,
    onTeamSelected: (Int) -> Unit,
    modifier: Modifier = Modifier
)
```

**验证**：
- 首页班组下拉框外观和行为不变
- 设置页默认班组下拉框外观和行为不变
- 编译通过，无 import 错误

---

## 验收命令

```bash
./gradlew testDebugUnitTest   # 全部通过，重构不引入回归
```

---

# ✅ 阶段 14：文档同步

**核心目标**：修正 memory-bank 文档中的过时描述和不一致内容，使文档准确反映 2026-05-13 代码状态。

**前置条件**：阶段 11-13 完成。

---

## Step 14.1：architecture.md 更新

**更新内容**：
1. "阶段 10" 章节中 `syncNextSevenDays` → 更新为 `syncShiftEvents(daysAhead = 365)`，描述从"未来 7 天"改为"默认未来 365 天（一整年）"
2. 阶段编号补充：在阶段 10 之后，追加阶段 11-13 的架构洞察（新增/改造文件清单、关键架构决策）
3. 更新文件清单映射

---

## Step 14.2：tech-stack.md 更新

**更新内容**：
1. "当前进度与后续建议"中，"已完成（阶段 1-9）" → "已完成（阶段 1-13）"
2. 列表项 7（"日历提醒"）的描述明确为 Calendar Provider 方案，去掉 AlarmManager 相关表述
3. 末尾状态更新："全部规划功能已完成，应用功能完整，单元测试全部通过" → 追加"阶段 11-13 代码加固与测试补全已完成"

---

## Step 14.3：progress.md 记录

**更新内容**：
- 新增 2026-05-13 条目：代码审查与改进规划
- 记录审查发现的 8 个问题及对应的 4 个改进阶段
- 列出当前项目整体健康度评估（测试覆盖、代码质量、文档一致性）

---

## 验收

- 所有 memory-bank 文件内容一致、无矛盾
- `grep -r "阶段 9" memory-bank/` 仅在 implementation-plan.md 的历史记录中出现（属于正常）
- 文档反映 2026-05-13 实际代码状态

---

# ✅ 阶段 15：桌面小组件（Widget）

**核心目标**：在设备桌面上显示今日班次信息，用户无需打开 App 即可查看当前班次和周期进度。使用 Jetpack Glance 框架实现 Compose 式 Widget 开发。

**前置条件**：阶段 1-14 已完成。Min SDK 24 满足 Glance 最低要求（API 23）。

**技术选型**：

| 方案 | 优点 | 缺点 | 选择 |
|------|------|------|------|
| **Glance (Compose)** | 声明式 UI、与现有 Compose 代码风格一致、轻量 | 功能受限于 RemoteViews 能力 | ✅ 推荐 |
| RemoteViews (XML) | 完整 RemoteViews 功能 | 代码冗长、XML 维护、与现有 Compose 风格不一致 | ❌ |

Glance 已 1.1+ 稳定版本，Google 官方推荐，支持 Material 3 主题。Widget 的 UI 由 Glance 编译为 RemoteViews，本质与系统 Widget 兼容。

**Widget 设计**：

```
┌──────────────────────────────────────┐
│  ┌───────┐                           │
│  │  早   │  一值          距休 2天   │
│  │ 白字  │  第 10/42 天              │
│  └───────┘                           │
│  2026年5月14日 星期三                 │
└──────────────────────────────────────┘
```

- **尺寸**：4×1（`targetCellWidth=4`, `targetCellHeight=1`）
- **内容**：班组名、日期、今日班次（圆角徽章彩色大字）、距休信息、周期进度文字
- **交互**：点击 Widget 打开 App 主界面
- **更新**：`updatePeriodMillis = 3600000`（每小时）+ App 内数据变更时主动刷新
- **注意**：Glance 不支持 `LinearProgressIndicator`/`fillMaxWidth(fraction)`/`defaultWeight()` 加权比例，最终采用纯文字"第 X/Y 天"替代进度条

---

## Step 15.1：添加 Glance 依赖

**目标**：在 `app/build.gradle.kts` 中添加 Glance AppWidget 依赖。

**依赖**：
```kotlin
implementation("androidx.glance:glance-appwidget:1.1.0")
implementation("androidx.glance:glance-material3:1.1.0")
```

`glance-appwidget` 提供 `GlanceAppWidget`、`GlanceAppWidgetReceiver` 等核心类。
`glance-material3` 提供 Material 3 主题 ColorScheme 适配。

**验证**：Gradle sync 成功，无依赖冲突。

---

## Step 15.2：创建 Widget 数据与计算

**目标**：在 domain 层新增 Widget 专用数据模型和纯计算函数，复用现有 `getShiftInfo()`。

**新增文件**：`app/src/main/java/com/simpleshift/scheduler/domain/widget_data.kt`

**数据模型**：
```kotlin
data class WidgetShiftData(
    val dateLabel: String,        // "2026年5月13日 星期三"
    val shiftLabel: String,       // "早"
    val shiftType: ShiftType,     // MORNING
    val dayOfCycle: Int,          // 10
    val totalDays: Int,           // 42
    val teamName: String          // "一值"
)

fun computeWidgetShiftData(
    today: LocalDate = LocalDate.now(),
    settings: RuntimeShiftSettings = RuntimeShiftSettings(),
    locale: Locale = Locale.getDefault()
): WidgetShiftData {
    if (!settings.isValid) {
        return WidgetShiftData(
            dateLabel = "",
            shiftLabel = "?",
            shiftType = ShiftType.REST,
            dayOfCycle = 0,
            totalDays = 0,
            teamName = ""
        )
    }
    val teamPhaseOffset = (settings.defaultTeamId - 1) *
        (settings.shiftCycle.size / Team.TOTAL_TEAMS)
    val shiftInfo = getShiftInfo(today, teamPhaseOffset, settings.shiftCycle)
    val team = Team.ALL_TEAMS.find { it.id == settings.defaultTeamId }
        ?: Team.ALL_TEAMS.first()
    val dateFormatter = DateTimeFormatter
        .ofLocalizedDate(FormatStyle.FULL)
        .withLocale(locale)
    return WidgetShiftData(
        dateLabel = today.format(dateFormatter),
        shiftLabel = ShiftLabelMapper.toLabel(shiftInfo.shiftType),
        shiftType = shiftInfo.shiftType,
        dayOfCycle = shiftInfo.dayOfCycle,
        totalDays = settings.shiftCycle.size,
        teamName = team.name
    )
}
```

**设计要点**：
- 纯函数，接受注入参数（date、settings、locale），与 ViewModel 注入模式一致
- 复用 `getShiftInfo()` 和 `ShiftLabelMapper.toLabel()` 保证口径统一
- `settings.isValid == false` 时返回兜底数据（显示"?"）

**验证**：快速单元测试覆盖正常路径和非法 settings 兜底。

---

## Step 15.3：实现 Glance Widget UI

**目标**：使用 Glance API 实现 Widget 的 Compose 式 UI。

**新增文件**：`app/src/main/java/com/simpleshift/scheduler/widget/ShiftWidget.kt`

**Widget 结构**：

```kotlin
class ShiftWidget : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val settingsRepository = SettingsRepository(context)
        val settings = settingsRepository.settingsFlow.first()
        val data = computeWidgetShiftData(settings = settings)

        provideContent {
            ShiftWidgetContent(data, context)
        }
    }
}

@Composable
fun ShiftWidgetContent(data: WidgetShiftData, context: Context) {
    Column(
        modifier = GlanceModifier
            .fillMaxWidth()
            .padding(12.dp)
            .clickable(actionStartActivity<MainActivity>())
    ) {
        // Row 1: Team name + refresh indicator
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            horizontalAlignment = Alignment.SpaceBetween
        ) {
            Text(text = "🏷️ ${data.teamName}", style = TextStyle(fontWeight = FontWeight.Bold))
            Text(text = data.dateLabel, style = TextStyle(fontSize = 12.sp))
        }
        Spacer(modifier = GlanceModifier.height(4.dp))
        // Row 2: Shift label (large, colored) + progress
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = data.shiftLabel,
                style = TextStyle(
                    fontSize = 32.sp,
                    fontWeight = FontWeight.Bold,
                    color = shiftTypeColor(data.shiftType)
                ),
                modifier = GlanceModifier.defaultWeight()
            )
            Column {
                Text("进度: ${data.dayOfCycle} / ${data.totalDays}")
                // Simple progress bar via colored Box
                ProgressBar(data.dayOfCycle, data.totalDays)
            }
        }
    }
}

@Composable
private fun ProgressBar(current: Int, total: Int) {
    val fraction = if (total > 0) current.toFloat() / total else 0f
    Row(modifier = GlanceModifier.fillMaxWidth().height(8.dp).cornerRadius(4.dp)) {
        Box(GlanceModifier.defaultWeight().fillMaxHeight()
            .background(shiftColor(Color(0xFF4CAF50))),
            modifier = GlanceModifier.fillMaxWidth(fraction))
        Box(GlanceModifier.defaultWeight().fillMaxHeight()
            .background(shiftColor(Color(0xFFE0E0E0))),
            modifier = GlanceModifier.fillMaxWidth(1f - fraction))
    }
}
```

**新增文件**：`app/src/main/java/com/simpleshift/scheduler/widget/ShiftWidgetReceiver.kt`

```kotlin
class ShiftWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = ShiftWidget()
}
```

**设计要点**：
- Widget 通过 `SettingsRepository` 直接从 DataStore 读取最新配置
- 点击 Widget 打开 `MainActivity`（深层链接到首页）
- 进度条用两个不同颜色的 Box 按比例分割，避免 Glance 不支持 Canvas 的限制
- 班次标签使用对应颜色（早=橙、中=蓝、休=绿、夜=紫、学=黄），与日历页保持一致

**Glance 限制注意**：
- 不支持 `LazyColumn`/`LazyRow`
- 不支持动画、Canvas 绘制
- 不支持自定义 Composable 修饰符（只支持 `GlanceModifier`）
- 不支持 `remember` / `mutableStateOf`（Widget 是静态快照）

---

## Step 15.4：注册 Widget（Manifest + XML 配置）

**目标**：在 AndroidManifest 中注册 Widget Receiver，创建 Widget 描述 XML。

**新增文件**：`app/src/main/res/xml/shift_widget_info.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="250dp"
    android:minHeight="40dp"
    android:targetCellWidth="4"
    android:targetCellHeight="1"
    android:updatePeriodMillis="3600000"
    android:initialLayout="@layout/glance_default_loading_layout"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen"
    android:widgetFeatures="reconfigurable"
    android:description="@string/widget_description" />
```

**改造文件**：`AndroidManifest.xml`

在 `<application>` 内注册：
```xml
<receiver
    android:name=".widget.ShiftWidgetReceiver"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/shift_widget_info" />
</receiver>
```

**新增字符串资源**：`res/values/strings.xml`
```xml
<string name="widget_description">在桌面显示今日班次信息，无需打开应用即可查看。</string>
<string name="widget_name">倒班助手 · 今日班次</string>
```

---

## Step 15.5：Widget 更新触发机制

**目标**：确保 App 内数据变更时 Widget 实时刷新。

**改造文件**：`MainActivity.kt`

在 `settingsRepository.saveSettings()` 调用后，追加 Widget 更新广播：
```kotlin
private fun notifyWidgetUpdate() {
    val intent = Intent(this, ShiftWidgetReceiver::class.java).apply {
        action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
    }
    sendBroadcast(intent)
}
```

调用点：
1. `onSettingsSaved` 回调中 — 用户保存设置后
2. `onAlarmSettingsChanged` 回调中 — 闹钟设置变更后（虽然不影响 Widget 显示，但保持一致性）
3. `onResume()` — App 回到前台时（处理跨天场景）

Widget 补充更新机制：
- **系统周期刷新**：`updatePeriodMillis = 3600000`（1 小时）
- **跨天自动更新**：`onResume` 触发刷新
- **用户主动操作**：点击 Widget 打开 App → `onResume` → 刷新

---

## Step 15.6：Widget 单元测试

**目标**：验证 `computeWidgetShiftData()` 数据计算逻辑。

**新增文件**：`app/src/test/java/com/simpleshift/scheduler/domain/WidgetDataTest.kt`

**覆盖点**（4 个用例）：

| # | 测试用例 | 验证内容 |
|---|---------|---------|
| 1 | `produces correct data for default settings` | 固定日期 + 默认 42 天周期 → dateLabel/shiftLabel/dayOfCycle 正确 |
| 2 | `produces correct data for custom cycle` | 10 天自定义周期 → totalDays=10 |
| 3 | `returns fallback for invalid settings` | `isValid=false` → shiftLabel="?" |
| 4 | `respects default team selection` | defaultTeamId=3 → teamName 为对应班组 |

**验证**：
```bash
./gradlew testDebugUnitTest --tests "*WidgetDataTest"
```

---

## Step 15.7：Memory-bank 文档更新

**更新内容**：
- `app-design-document.md`：新增 2.5 桌面小组件章节
- `architecture.md`：新增阶段 15 架构洞察
- `tech-stack.md`：追加 Glance 依赖和 Widget 技术说明
- `progress.md`：记录阶段 15 规划与实施结果

---

## 验收命令

```bash
# 编译 + 测试
./gradlew assembleDebug
./gradlew testDebugUnitTest   # 全部通过（约 79 个测试）

# Widget 功能验证（设备/模拟器）：
# 1. 长按桌面 → 添加小部件 → 找到"倒班助手 · 今日班次"
# 2. 放置到桌面，确认显示今日班次、日期、进度
# 3. 打开 App 修改班组 → 返回桌面确认 Widget 更新
# 4. 过夜后（或改系统时间）确认 Widget 自动显示新日期班次
```

---

### 阶段 15 文件变更汇总

| 类型 | 文件 |
|------|------|
| 新增 | `domain/widget_data.kt` — Widget 数据模型 + 计算函数 |
| 新增 | `widget/ShiftWidget.kt` — GlanceAppWidget + Glance UI |
| 新增 | `widget/ShiftWidgetReceiver.kt` — 系统 Receiver |
| 新增 | `res/xml/shift_widget_info.xml` — Widget 元数据 |
| 新增 | `WidgetDataTest.kt` — 4 个单元测试 |
| 改造 | `app/build.gradle.kts` — 新增 2 个 Glance 依赖 |
| 改造 | `AndroidManifest.xml` — 注册 Widget Receiver |
| 改造 | `MainActivity.kt` — Widget 更新触发逻辑 |
| 改造 | `res/values/strings.xml` — Widget 相关字符串 |

---

# ✅ 阶段 16：首页精品化升级（已完成）

**核心目标**：将首页从"功能骨架"升级为"精品级产品首页"，提升视觉层次和信息密度。不破坏现有功能、可随时回滚。

**前置条件**：阶段 1-15 已完成。阶段 11-14 代码加固完成。阶段 15 Widget 已完成。

**风险策略**：双轨制（旧 `HomeScreen` 保留，新增 `NewHomeScreen` 渐进接入，`useNewHome` 调试开关一键回滚）。

---

## 原方案评估

原方案整体思路正确：双轨制、小步迭代、组件先行、每步可验证。但存在以下需修正的问题：

| # | 问题 | 修正 |
|---|------|------|
| 1 | "牛马指数"无定义，无法实现 | 替换为"本月上班 X/Y 天"（有明确公式） |
| 2 | "距离休班：2天"只写死占位，无后续实现 | 新增 domain 函数 `daysUntilNextRest()` 计算真实值 |
| 3 | "连续上班天数"属 domain 层但原方案禁止触碰 | 新增 `domain/shift_metrics.kt`（新文件），不改已有域函数 |
| 4 | QuickActionsRow 按钮无跳转，死按钮体验差 | 日历→滚动到日历区块，提醒/设置→导航到设置页 |
| 5 | `GreetingHeader` 需要 `teamName` 但 `HomeUiState` 无此字段 | `HomeUiState` 新增 `teamName` 派生字段 |
| 6 | 无测试验证步骤 | 每步完成后运行 `./gradlew testDebugUnitTest` |
| 7 | 时间范围 23:00-04:59 跨午夜 | 实现时使用 `||` 逻辑正确判断跨夜时段 |

---

## Step 16.1：扩展 HomeUiState + 新增 domain 指标函数

**目标**：为后续 UI 组件准备好数据基础。不改已有逻辑，只新增字段和纯函数。

**改造文件**：`viewmodel/HomeViewModel.kt`
**新增文件**：`domain/shift_metrics.kt` + 对应测试

**HomeUiState 新增字段**：
```kotlin
val teamName: String = ""  // 从 selectedTeamId + availableTeams 派生
```

**新增 domain 纯函数**（`domain/shift_metrics.kt`）：
```kotlin
// 统计指定月份内某班次类型的出现天数
fun countShiftTypeInMonth(
    yearMonth: YearMonth,
    shiftType: ShiftType,
    teamPhaseOffset: Int = 0,
    customCycle: List<ShiftType>? = null
): Int

// 从今天往前数，连续上班天数（非休且非学 = 上班）
fun consecutiveWorkDays(
    today: LocalDate,
    teamPhaseOffset: Int = 0,
    customCycle: List<ShiftType>? = null
): Int

// 从今天往后数（不含今天），距离下一个休息日的天数
fun daysUntilNextRest(
    today: LocalDate,
    teamPhaseOffset: Int = 0,
    customCycle: List<ShiftType>? = null
): Int

// 统计月份内上班天数（非休且非学）
fun countWorkDaysInMonth(
    yearMonth: YearMonth,
    teamPhaseOffset: Int = 0,
    customCycle: List<ShiftType>? = null
): Int
```

这些函数使用已有的 `getShiftTypeForDate()` 循环计算，纯函数、可独立测试。

**验证**：`./gradlew testDebugUnitTest` 全部通过，新增测试覆盖 4 个函数。

---

## Step 16.2：新增 GreetingHeader 组件

**新增文件**：`ui/home/components/GreetingHeader.kt`

**输入参数**：
```kotlin
@Composable
fun GreetingHeader(teamName: String, dateText: String)
```

**时段问候逻辑**：
| 时间段 | 文案 |
|--------|------|
| 05:00-11:59 | 早上好 |
| 12:00-17:59 | 下午好 |
| 18:00-22:59 | 晚上好 |
| 23:00-04:59 | 夜班辛苦了 |

**UI**：两行文本。第一行大字（`headlineMedium`）："{时段问候}，{teamName}"。第二行弱化色（`bodyMedium` + `onSurfaceVariant`）：日期文本。

**验证**：build 成功 + Preview 可显示。

---

## Step 16.3：新增 TodayShiftCard 组件

**新增文件**：`ui/home/components/TodayShiftCard.kt`

**输入参数**：
```kotlin
@Composable
fun TodayShiftCard(
    shiftLabel: String,
    shiftType: ShiftType,
    dayOfCycle: Int,
    totalDays: Int,
    daysUntilRest: Int
)
```

**内容**：
- 班次名称大字（`displaySmall`），按 `shiftType` 着色（早=橙、中=蓝、休=绿、夜=紫、学=黄）
- 进度文字："进度 {dayOfCycle} / {totalDays}"
- 距离休班："距休 {daysUntilRest} 天"（daysUntilRest = 0 时显示"今天休息 🎉"）

**UI**：`Card(shape = MaterialTheme.shapes.large)` + `elevation = 2.dp`，内边距充足。

**验证**：build 成功 + Preview 可显示。

---

## Step 16.4：新增 StatsGrid 组件

**新增文件**：`ui/home/components/StatsGrid.kt`

**输入参数**：
```kotlin
@Composable
fun StatsGrid(
    monthlyWorkDays: Int,
    monthlyTotalDays: Int,
    consecutiveWorkDays: Int,
    daysUntilRest: Int
)
```

**三宫格内容**：
| 宫格 | 数字 | 说明 |
|------|------|------|
| 本月上班 | `monthlyWorkDays` | / 本月已过天数 |
| 连续上班 | `consecutiveWorkDays` | 天 |
| 距离休班 | `daysUntilRest` | 天 |

**UI**：`Row` 三等分，每格一个小 `Card`（`tonalElevation`），上排大数字 + 下排小字标签。

**验证**：build 成功 + Preview 可显示。

---

## Step 16.5：新增 QuickActionsRow 组件

**新增文件**：`ui/home/components/QuickActionsRow.kt`

**输入参数**：
```kotlin
@Composable
fun QuickActionsRow(
    onCalendarClick: () -> Unit,
    onSettingsClick: () -> Unit
)
```

**按钮**：三个 `FilledTonalButton`（含 Icon）：
- "📅 日历" → `onCalendarClick`
- "⏰ 提醒" → `onSettingsClick`
- "⚙️ 设置" → `onSettingsClick`

**验证**：build 成功。

---

## Step 16.6：新增 MotivationFooter 组件

**新增文件**：`ui/home/components/MotivationFooter.kt`

**输入参数**：无（内部从随机种子选文案）

**文案池**：取当日 `(dayOfYear % 文案数)` 保证同日一致：
```
休息是为了走更远的路
坚持就是胜利
注意身体，早点休息
安全第一，平安回家
```

**UI**：弱化色居中文字（`bodySmall` + `onSurfaceVariant`），上下留白各 `8.dp`。

**验证**：build 成功。

---

## Step 16.7：组装 NewHomeScreen + HomeViewModel 接入

**新增文件**：`ui/home/NewHomeScreen.kt`
**改造文件**：`viewmodel/HomeViewModel.kt`

**HomeViewModel 改动**：
1. `HomeUiState` 新增：`teamName`, `daysUntilRest`, `consecutiveWorkDays`, `monthlyWorkDays`, `totalDaysInMonth`
2. `refreshToday()` 中调用 `shift_metrics.kt` 函数计算并填充上述字段
3. 默认值保证向后兼容

**NewHomeScreen 组合**：
```kotlin
@Composable
fun NewHomeScreen(
    uiState: HomeUiState,
    onTeamSelected: (Int) -> Unit,
    onCalendarClick: () -> Unit,
    onSettingsClick: () -> Unit
) {
    Column(verticalScroll, spacedBy) {
        TeamDropdown(...)
        GreetingHeader(uiState.teamName, uiState.todayDate)
        TodayShiftCard(uiState.shiftLabel, uiState.shiftType, ...)
        StatsGrid(...)
        QuickActionsRow(onCalendarClick, onSettingsClick)
        MotivationFooter()
    }
}
```

**验证**：build 成功 + `./gradlew testDebugUnitTest` 全部通过。

---

## Step 16.8：MainActivity 双轨接入 + 调试开关

**改造文件**：`MainActivity.kt`

**改动**：
1. 文件顶部新增常量：`private const val USE_NEW_HOME = false`
2. `composable("main")` 中根据 `USE_NEW_HOME` 分支：
   - `true` → `NewHomeScreen(...)` + 日历区块（保留，在下方）
   - `false` → 现有布局（完全不变）
3. `NewHomeScreen.onCalendarClick` → 滚动到日历 (`scrollState.animateScrollTo(scrollState.maxValue)`)
4. `NewHomeScreen.onSettingsClick` → `navController.navigate("settings")`

**重要**：`USE_NEW_HOME = false` 时字节码路径与当前完全一致，零风险。

**验证**：
- `USE_NEW_HOME = false` → 行为与当前完全一致
- `USE_NEW_HOME = true` → 新首页正常渲染，日历在下方可滚动到达
- `./gradlew testDebugUnitTest` 全部通过

---

## Step 16.9：扩展测试覆盖

**新增/改造测试**：
- `ShiftMetricsTest.kt`（新增）— 覆盖 `countShiftTypeInMonth`, `consecutiveWorkDays`, `daysUntilNextRest`, `countWorkDaysInMonth`，约 8 个用例
- `HomeViewModelTest.kt`（改造）— 追加新字段验证（teamName、daysUntilRest 等）

**验证**：`./gradlew testDebugUnitTest` 全部通过。

---

## Step 16.10：切换默认首页

**改造文件**：`MainActivity.kt`

**改动**：`USE_NEW_HOME` 改为 `true`

**验收清单**：
- [ ] 首页视觉层次明显提升
- [ ] 原排班逻辑无变化（domain 层已有函数未变）
- [ ] `./gradlew testDebugUnitTest` 全部通过
- [ ] 启动无崩溃
- [ ] `USE_NEW_HOME = false` 可即刻回滚

---

## 回滚策略

任意一步出问题：
1. `USE_NEW_HOME = false` → 立即恢复旧首页（编译时常量，非运行时切换）
2. 所有新文件独立，不影响旧代码路径
3. 旧 `HomeScreen.kt` 保留不删，稳定运行至少一个版本周期后再考虑移除

---

## 阶段 16 文件变更汇总

| 类型 | 文件 |
|------|------|
| 新增 | `domain/shift_metrics.kt` — 4 个统计纯函数 |
| 新增 | `ui/home/components/GreetingHeader.kt` |
| 新增 | `ui/home/components/TodayShiftCard.kt` |
| 新增 | `ui/home/components/StatsGrid.kt` |
| 新增 | `ui/home/components/QuickActionsRow.kt` |
| 新增 | `ui/home/components/MotivationFooter.kt` |
| 新增 | `ui/home/NewHomeScreen.kt` — 组装新首页 |
| 新增 | `ShiftMetricsTest.kt` — domain 指标函数测试（约 8 用例） |
| 改造 | `viewmodel/HomeViewModel.kt` — HomeUiState 新增 5 字段 + refreshToday 扩展 |
| 改造 | `MainActivity.kt` — USE_NEW_HOME 开关 + NewHomeScreen 接线 |
| 改造 | `HomeViewModelTest.kt` — 扩展覆盖新字段 |

---

# ✅ 阶段 17：V2 完整 UI 设计系统（已完成）

**核心目标**：建立统一 Design Token 系统，升级首页、日历页、设置页，引入底部导航栏。品牌感 + 统一体验 + 高级质感。

**设计语言**：Dark Productivity Design（深色高级 + 克制 + 效率感 + 有温度）

**前置条件**：阶段 1-16 已完成。采用双轨制（`USE_NEW_HOME_V2`），V1 组件全部保留。

---

## Design Token 系统（全局基础设施）

### 颜色

| Token | 值 | 用途 |
|-------|-----|------|
| PrimaryBackground | `#0B0D10` | 页面底色 |
| SecondaryBackground | `#15181D` | 次级区域 |
| CardSurface | `#1B1F26` | 卡片表面 |
| PrimaryText | `#F5F7FA` | 主文字 |
| SecondaryText | `#9CA3AF` | 辅助文字 |
| HintText | `#6B7280` | 提示文字 |
| Morning | `#FFB347` | 早班 |
| Afternoon | `#4DA3FF` | 中班 |
| Night | `#7C5CFF` | 夜班 |
| Rest | `#35D07F` | 休班 |
| Study | `#F2D94E` | 学习 |
| Success | `#22C55E` | 成功/绿灯 |
| Warning | `#F59E0B` | 警告/黄灯 |
| Danger | `#EF4444` | 危险/红灯 |
| Accent | `#FACC15` | 强调金 |

### 字体

| 用途 | 规格 |
|------|------|
| 页标题 | 28sp Bold |
| 卡片主数字 | 36sp Bold |
| 二级标题 | 20sp SemiBold |
| 正文 | 16sp Regular |
| 辅助说明 | 13sp Medium |

### 圆角

| 用途 | 值 |
|------|-----|
| 按钮 | 18dp |
| 卡片 | 24dp |
| 主卡片 | 28dp |
| 底部弹窗 | 32dp |

### 间距

| 用途 | 值 |
|------|-----|
| 页面左右边距 | 20dp |
| 页面上下边距 | 16dp |
| 组件间距 | 16dp |
| 区块间距 | 24dp |

---

## 实施步骤（6 个 Phase）

### Phase 1：Design Token + 数据层扩展

**Step 17.1：新建 `ui/theme/` 系统**
- `Color.kt`：全部 Token 颜色 + `v2ShiftColor()` 辅助函数
- `Type.kt`：`ShiftSchedulerTypography`（5 级字体）
- `Shape.kt`：`ShiftSchedulerShapes`（4 级圆角）
- `Theme.kt`：`ShiftSchedulerTheme`（`darkColorScheme` + 自定义 Typography + Shapes）

**Step 17.2：扩展 HomeUiState + HomeViewModel**
- 新增 `shiftTimeRange: String?`、`monthlyShiftTypeCount: Int`、`workIntensity: Int`
- 新增 `updateAlarmSettings(settings)` 方法
- `refreshToday()` 计算新字段

**Step 17.3：MainActivity 接线**
- 新增 `USE_NEW_HOME_V2 = false` 开关
- alarm 收集 → `homeViewModel.updateAlarmSettings()`
- V2 路由分支

**Step 17.4：扩展测试**
- `HomeViewModelTest` 新增 4 用例

### Phase 2：首页 V2

**Step 17.5-17.9：5 个 V2 组件**（同原计划）
- `V2GreetingHeader`、`V2TodayShiftCard`、`V2StatsGrid`、`V2QuickActionsRow`、`V2MotivationFooter`

**Step 17.10：NewHomeScreenV2 组装**
- 动画、间距、组件拼接

### Phase 3：底部导航栏 🆕

**Step 17.11：NavigationBar 改造**
- `MainActivity` NavHost 根路由从 `"main"` → 底部导航 scaffold
- `NavigationBar` + 3 个 `NavigationBarItem`：首页（dashboard）/ 日历（calendar_month）/ 我的（person）
- 点击切换 composable，保留 NavHost 用于子页面（如从首页进设置）

### Phase 4：日历页 V2 🆕

**Step 17.12：CalendarScreen 深色适配**
- `CalendarDayCell` 改用 V2 暗色底 + 淡色标记（替代过去彩色背景）
- 今天高亮描边（已有逻辑，改用 PrimaryText 色）
- 底部常驻统计（`computeStats` 结果不用弹窗，直接显示在日历下方）

### Phase 5：我的页 V2 🆕

**Step 17.13：ProfileScreen 新建**
- 卡片式菜单：班组 / 倒班规则 / 提醒 / 反馈 / 关于
- 点击导航到对应子页面（复用现有 SettingsScreen）
- 深色主题适配

### Phase 6：全局主题应用 🆕

**Step 17.14：统一所有页面主题**
- `ShiftSchedulerTheme` 包裹根 `setContent`
- 日历页、设置页自动继承深色
- 移除各页面内联颜色硬编码，改用 Token

**Step 17.15：构建 + 测试验证** ✅

```bash
./gradlew assembleDebug        # BUILD SUCCESSFUL
./gradlew testDebugUnitTest    # BUILD SUCCESSFUL（全部测试通过，零回归）
```
- `USE_NEW_HOME_V2 = false` 恢复 V1（默认安全状态）
- `USE_NEW_HOME_V2 = true` 启用完整 V2

---

## 阶段 17 文件变更汇总（更新）

| 类型 | 文件数 | 文件 |
|------|--------|------|
| 新增 | 14 | `ui/theme/Color.kt`, `Type.kt`, `Shape.kt`, `Theme.kt`; `ui/home/components/V2GreetingHeader.kt`, `V2TodayShiftCard.kt`, `V2StatsGrid.kt`, `V2QuickActionsRow.kt`, `V2MotivationFooter.kt`; `ui/home/NewHomeScreenV2.kt`; `ui/profile/ProfileScreen.kt`; 测试追加 |
| 改造 | 5 | `viewmodel/HomeViewModel.kt`, `HomeViewModelTest.kt`, `MainActivity.kt`, `CalendarScreen.kt`, `SettingsScreen.kt` |
| 不变 | — | 所有 V1 组件、ViewModel 层、domain 层、data 层、Widget |

## 实施结果（2026-05-14）

实际新增 11 个文件、改造 5 个文件。全部编译通过，单元测试零回归。

- Phase 1-6 全部完成
- `USE_NEW_HOME_V2 = false`（默认），V1 路径字节码不变
- 改 `true` 即启用深色主题 + 底部导航 + V2 首页 + Profile 页

---

# ✅ 阶段 18：倒班规则编辑器重设计（已完成）

**核心目标**：将倒班规则和提醒设置拆分为两个独立页面，规则编辑改为两步向导式（按钮构建序列 → 设置日期保存）。

## 实施结果（2026-05-14）

实际新增 4 个文件、改造 11 个文件。全部编译通过，单元测试零回归。

- Phase A-E 全部完成
- `USE_NEW_SETTINGS = true`（默认），启用新编辑器；`false` 回退旧 SettingsScreen
- Domain 层 `referenceDate` 贯穿全栈，支持用户自定义轮班起始日期

### 文件变更

| 类型 | 文件 |
|------|------|
| 新增 | `viewmodel/ShiftRuleViewModel.kt`, `viewmodel/AlarmSettingsViewModel.kt`, `ui/settings/ShiftRuleEditorScreen.kt`, `ui/settings/AlarmSettingsScreen.kt` |
| 改造 | `domain/model/RuntimeShiftSettings.kt`, `domain/shift_calculator.kt`, `domain/shift_metrics.kt`, `domain/calendar_generator.kt`, `domain/widget_data.kt`, `data/repository/SettingsRepository.kt`, `viewmodel/HomeViewModel.kt`, `viewmodel/CalendarViewModel.kt`, `calendar/CalendarEventManager.kt`, `calendar/CalendarSyncManager.kt`, `MainActivity.kt` |

# 🔲 阶段 19：拼假神器（请假优化器）

**核心目标**：自动分析未来 365 天，结合倒班表 + 中国法定节假日，找到"请最少假、连休最久"的最佳请假方案。差异化核心功能，竞品少有。

**前置条件**：阶段 1-18 已完成。现有 `shift_calculator`、`shift_metrics`、`RuntimeShiftSettings`（含 `referenceDate`/`customCycle`）全部可用。

---

## 设计决策

| 问题 | 决策 |
|------|------|
| 分析范围 | 未来 365 天（一整年），从今天开始 |
| 最大请假天数 | 默认 5 天，可配置 |
| 节假日数据 | 内置 `holiday_data.kt`，每年更新一次 |
| 请假策略类型 | 连续请假（覆盖 95%+ 真实场景） |
| 算法 | 间隙桥接法（Gap-Merging）—— O(365) |
| 入口位置 | "我的"页 → "拼假神器"菜单项 |
| 主题 | 复用 V2 Design Token，自适应深色/浅色 |

---

## Step 19.1：数据模型 + 节假日数据

**目标**：定义请假策略模型，内置中国法定节假日数据。

**新增文件**：
- `domain/model/LeaveStrategy.kt` — `LeaveStrategy` 数据类
- `domain/holiday_data.kt` — `HolidayInfo` + `getChinaHolidays()` + 辅助查询函数

**`LeaveStrategy` 字段**：
```kotlin
data class LeaveStrategy(
    val leaveDays: Int,                      // 需要请假天数
    val totalBreakDays: Int,                 // 连休总天数
    val leaveDates: List<LocalDate>,         // 需请假的具体日期
    val breakStart: LocalDate,               // 连休起始日
    val breakEnd: LocalDate,                 // 连休结束日（含）
    val holidayOverlap: Int,                 // 与法定节假日重叠天数
    val weekendOverlap: Int,                 // 与周末重叠天数
    val overlappingHolidayNames: List<String>, // 重叠的节假日名称
    val efficiency: Float,                   // 连休/请假 = N倍
    val score: Float                         // 综合评分 0~1
)
```

**`HolidayInfo` 字段**：
```kotlin
data class HolidayInfo(
    val date: LocalDate,
    val name: String,        // "春节"、"国庆节"等
    val isHoliday: Boolean   // true = 放假, false = 调休上班
)
```

**节假日数据覆盖**：
- 2026 年全部法定节假日（官方已发布）+ 对应调休工作日
- 2027 年节假日（基于农历推算，标记为"待确认"）
- 数据函数：`getChinaHolidays(): Map<LocalDate, HolidayInfo>`
- 辅助函数：`isWeekend(date)`, `isHolidayOrRest(date, holidays)`

**具体数据（2026 年官方）**：
| 节日 | 放假日期 | 调休上班 |
|------|---------|---------|
| 元旦 | 1月1日 | — |
| 春节 | 2月16-22日 | 2月14日(六)、2月28日(六) |
| 清明节 | 4月5-6日 | — |
| 劳动节 | 5月1-5日 | 5月9日(六) |
| 端午节 | 6月19-21日 | — |
| 中秋节 | 9月25-27日 | — |
| 国庆节 | 10月1-7日 | 9月27日(日)、10月10日(六) |

2027 年数据基于农历推算 + 历史规律，标注为"待国务院确认"。

**验证**：
- `HolidayDataTest`：节假日数据无重复 key、调休日标记正确、覆盖范围 ≥ 365 天
- 周末检测函数正确（周六/周日）

---

## Step 19.2：核心拼假算法

**目标**：实现间隙桥接算法，纯函数、可独立测试。

**新增文件**：
- `domain/leave_optimizer.kt` — 全部纯函数

**函数清单**：

```kotlin
// 每日状态结构（内部使用，不暴露到 model 包）
internal data class DayStatus(
    val date: LocalDate,
    val isRest: Boolean,         // 倒班休或学
    val isHoliday: Boolean,      // 法定节假日
    val isWeekend: Boolean,      // 周六日
    val isAdjustedWorkDay: Boolean, // 调休上班
    val holidayName: String?     // 节假日名称
)

// 构建每日状态数组
internal fun buildDailyStatus(
    startDate: LocalDate,
    days: Int,
    teamPhaseOffset: Int,
    customCycle: List<ShiftType>?,
    referenceDate: LocalDate,
    holidays: Map<LocalDate, HolidayInfo>
): List<DayStatus>

// 主入口
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

**算法步骤**：

1. **构建每日状态**：`buildDailyStatus` 遍历未来 365 天，对每天调用 `getShiftTypeForDate()` + 查节假日表 + 判断周末。
   - `isOff = isRest || (isHoliday && !isAdjustedWorkDay) || (isWeekend && !isAdjustedWorkDay)`
   - 注意：调休工作日（周末补班）在计算"自然休息"时要排除。

2. **间隙桥接**（核心）：
   ```
   扫描 isOff 数组，找到所有"工作间隙"（连续 isOff=false 的天数 ≤ maxLeaveDays）
   对于间隙左右有休息块的情况：间隙 = 请假天数，总连休 = 左休息块 + 间隙 + 右休息块
   对于间隙在数组开头/结尾：总连休 = 间隙 + 单侧休息块
   ```

3. **延伸策略**（补充）：
   ```
   对于每个休息块的左边界和右边界：
   - 向左延伸 N 天（N=1..maxLeaveDays）：请 N 天 → 连休 = N + 休息块大小
   - 向右延伸 N 天：同上
   去重：已在间隙桥接中覆盖的跳过
   ```

4. **去重**：按 `(breakStart, breakEnd, leaveDays)` 去重，同一连休区间保留 leaveDays 最少的。

5. **评分排序**：
   ```
   效率分 = efficiency / maxEfficiency  （efficiency = breakDays / leaveDays）
   长度分 = totalBreakDays / maxBreakDays
   家庭分 = (holidayOverlap * 2 + weekendOverlap) / maxFamilyBonus
   综合分 = 0.50 * 效率分 + 0.25 * 长度分 + 0.25 * 家庭分
   按综合分降序排列
   ```

**验证**：
- `LeaveOptimizerTest`（约 12 用例，详见 Step 19.6）

---

## Step 19.3：LeaveOptimizerViewModel

**目标**：管理拼假页状态，协调数据加载和策略计算。

**新增文件**：
- `viewmodel/LeaveOptimizerViewModel.kt`

**状态设计**：
```kotlin
data class LeaveOptimizerUiState(
    val strategies: List<LeaveStrategy> = emptyList(),
    val selectedTeamId: Int = 1,
    val maxLeaveDays: Int = 5,
    val isLoading: Boolean = true,
    val analyzedDays: Int = 365,
    val analyzedDateRange: String = ""  // "2026/05/14 - 2027/05/14"
)

class LeaveOptimizerViewModel(
    application: Application,
    private val todayProvider: () -> LocalDate = { LocalDate.now() }
) : AndroidViewModel(application) {

    private val _uiState = MutableStateFlow(LeaveOptimizerUiState())
    val uiState: StateFlow<LeaveOptimizerUiState> = _uiState.asStateFlow()

    fun refresh(
        customCycle: List<ShiftType>?,
        referenceDate: LocalDate,
        teamId: Int
    )

    fun setMaxLeaveDays(days: Int)
}
```

**刷新逻辑**：
1. 从 `teamId` 计算 `teamPhaseOffset = (teamId - 1) * (cycle.size / 6)`
2. 调用 `findBestLeavePlans(today, 365, teamPhaseOffset, customCycle, referenceDate, ...)`
3. 更新 `_uiState`

**构造**：通过 `AndroidViewModelFactory` 注入 `todayProvider` 以便测试。

**验证**：编译通过 + `findBestLeavePlans` 在真实数据上产出结果。

---

## Step 19.4：LeaveOptimizerScreen UI

**目标**：实现拼假策略卡片列表。

**新增文件**：
- `ui/leave_optimizer/LeaveOptimizerScreen.kt`

**布局设计**：
```
┌──────────────────────────────────────┐
│  ← 拼假神器                           │  TopAppBar + 返回
├──────────────────────────────────────┤
│  基于你的倒班表 + 法定节假日             │  说明区
│  未来365天 · 一值 · 8月15日截止         │  分析范围信息
├──────────────────────────────────────┤
│  ┌────────────────────────────────┐  │
│  │ 🥇 最佳方案                      │  │  前三名卡片
│  │ 请假 2 天 ──→ 连休 6 天          │  │  金色/银色/铜色边框
│  │ 6/16 — 6/21                     │  │
│  │ ● 含端午节  3.0x                │  │
│  │ ▁▁▁▁▁▁█▁▁▁▁▁▁▁▁▁▁▁▁▁▁      │  │  日历缩略条（6 天高亮）
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │ 请假 1 天 ──→ 连休 4 天          │  │
│  │ 5/16 — 5/19  4.0x               │  │
│  │ ● 含周末                         │  │
│  │ ▁▁▁▁█▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁      │  │
│  └────────────────────────────────┘  │
│  ...                                 │
├──────────────────────────────────────┤
│ 最多请假天数: [1] [2] [3] [4] [5+]   │  筛选芯片行
└──────────────────────────────────────┘
```

**关键 UI 组件**：
- `StrategyCard`：单张策略卡片（Card + 左侧颜色条 + 内容）
  - 前三名特殊样式（金/银/铜左边框色）
  - 正文：请假 N 天 → 连休 M 天（大字）
  - 副行：日期范围 + 节日标签 + 效率标签
  - 底部：缩略日历条（30 天窗口，连休区高亮）
- `MiniCalendarBar`：30 天缩略条（彩色方块展示休息/请假/连休）
- `FilterChipRow`：最大请假天数筛选芯片
- `EmptyState`：无结果时的空状态（当所有间隙 > maxLeaveDays）

**状态处理**：
- 加载中：`CircularProgressIndicator`
- 无结果：提示"当前倒班表下未找到高效请假方案，尝试增加请假天数"
- 有结果：策略卡片列表

**验证**：编译通过 + Preview 可显示。

---

## Step 19.5：导航集成

**目标**：在"我的"页增加入口，MainActivity 注册路由。

**改造文件**：
- `MainActivity.kt`
- `ui/profile/ProfileScreen.kt`

**MainActivity 改动**：
1. 新增 `LeaveOptimizerViewModel` factory（同现有 ViewModel 模式）
2. 在 V2 NavHost 中新增 `composable("leave_optimizer")` 路由
3. 传递 `runtimeSettings.shiftCycle`、`runtimeSettings.referenceDate`、`homeUiState.selectedTeamId`

**ProfileScreen 改动**：
1. 新增参数 `onLeaveOptimizerClick: () -> Unit`
2. 在菜单卡片中新增一项"拼假神器"（图标 + 说明"智能请假方案"）
3. 建议放在"倒班规则"和"提醒设置"之后

**导航流**：
```
ProfileScreen
  └── "拼假神器" → navController.navigate("leave_optimizer")
                       └── LeaveOptimizerScreen
                              └── 返回 → navController.popBackStack()
```

**验证**：
- "我的"页可见"拼假神器"入口
- 点击后跳转到 LeaveOptimizerScreen
- 返回按钮回到"我的"页
- 编译通过

---

## Step 19.6：单元测试

**目标**：核心算法全覆盖，节假日数据验证。

**新增文件**：
- `LeaveOptimizerTest.kt`（约 12 用例）
- `HolidayDataTest.kt`（约 4 用例）

**`LeaveOptimizerTest` 覆盖点**：

| # | 测试用例 | 验证内容 |
|---|---------|---------|
| 1 | `buildDailyStatus produces correct size` | 生成 365 天，首日为 today |
| 2 | `buildDailyStatus isRest matches shift schedule` | 休/学 → isRest=true，早/中/夜 → false |
| 3 | `buildDailyStatus marks weekends` | 周六日 isWeekend=true |
| 4 | `buildDailyStatus marks holidays` | 传入节假日 → isHoliday=true |
| 5 | `buildDailyStatus marks adjusted work days` | 调休日 isAdjustedWorkDay=true, isOff=false |
| 6 | `gap bridging: 2-day gap between rests` | 请假 2 天 → 连休 = 左休息 + 2 + 右休息 |
| 7 | `gap bridging: single work day bridge` | 请假 1 天 → 连休 4 天 |
| 8 | `extension: leave before rest block` | 在休息块前请假 → 连休延长 |
| 9 | `extension: leave after rest block` | 在休息块后请假 → 连休延长 |
| 10 | `no strategy when gap > maxLeaveDays` | 6 天间隙、maxLeaveDays=5 → 不产出该策略 |
| 11 | `deduplication: same break keeps minimal leave` | 同一连休区间，只保留请假最少的 |
| 12 | `scoring: holiday overlap ranks higher` | 两个效率相同的策略，节日重叠多的排前面 |
| 13 | `scoring: higher efficiency ranks first` | 效率高的排前面 |
| 14 | `custom cycle respected` | 自定义 7 天周期后策略与默认不同 |
| 15 | `referenceDate offset respected` | 修改起始日后策略偏移 |

**`HolidayDataTest` 覆盖点**：

| # | 测试用例 | 验证内容 |
|---|---------|---------|
| 1 | `no duplicate dates` | 节假日 Map 无重复 key |
| 2 | `covers at least 365 days from today` | 覆盖未来一年 |
| 3 | `adjusted work days correctly marked` | 调休日 isHoliday=false |
| 4 | `major holidays present` | 春节/国庆/劳动节等主要节日存在 |

**验证**：
```bash
./gradlew testDebugUnitTest --tests "*LeaveOptimizerTest"
./gradlew testDebugUnitTest --tests "*HolidayDataTest"
./gradlew testDebugUnitTest   # 全部通过，零回归
```

---

## Step 19.7：文档更新

**改造文件**：
- `app-design-document.md` — 新增 2.6 拼假神器章节
- `architecture.md` — 新增阶段 19 架构章节
- `tech-stack.md` — 追加拼假神器相关技术说明
- `progress.md` — 记录阶段 19 规划

---

## 验收命令

```bash
# 编译
./gradlew assembleDebug

# 全部测试
./gradlew testDebugUnitTest   # 全部通过（新增约 16 个测试，不引入回归）
```

---

## 阶段 19 文件变更汇总

| 类型 | 文件 |
|------|------|
| 新增 | `domain/model/LeaveStrategy.kt` — LeaveStrategy 数据模型 |
| 新增 | `domain/holiday_data.kt` — 中国法定节假日数据（~150 行） |
| 新增 | `domain/leave_optimizer.kt` — 拼假核心算法（~180 行纯函数） |
| 新增 | `viewmodel/LeaveOptimizerViewModel.kt` — 拼假页 ViewModel（~80 行） |
| 新增 | `ui/leave_optimizer/LeaveOptimizerScreen.kt` — 拼假页 UI（~250 行） |
| 新增 | `LeaveOptimizerTest.kt` — 核心算法测试（~15 用例） |
| 新增 | `HolidayDataTest.kt` — 节假日数据验证（~4 用例） |
| 改造 | `MainActivity.kt` — 新增路由 + ViewModel factory（+40 行） |
| 改造 | `ui/profile/ProfileScreen.kt` — 新增"拼假神器"入口（+10 行） |
| 改造 | memory-bank 全部 5 文件 — 文档同步 |

---

# 🔲 阶段 20：同事模式（社交裂变）

**核心目标**：输入两个人的班组，自动计算下次同时休息日期和共同休息天数。技术简单但产品价值高——情侣、朋友、同事都会使用，截图天然适合社交传播。

**前置条件**：阶段 1-19 已完成。现有 `shift_calculator`、`teamPhaseOffsetFor()`、`TeamDropdown` 全部可用。

---

## 设计决策

| 问题 | 决策 |
|------|------|
| 算法 | 双班组逐日对比，O(n)，比拼假神器简单一个量级 |
| 分析范围 | 今日至当年 12 月 31 日（与拼假神器一致，不跨年） |
| "休息"定义 | REST 或 STUDY（与现有代码一致） |
| 默认值 | "我"=用户当前班组，"他"=相邻班组（降低操作门槛） |
| UI 入口 | "我的"页 → "同事模式"菜单项（在拼假神器下方） |
| 主题 | 复用 V2 Design Token |
| 社交传播 | 大字体具体日期 = 天然对话素材，截图即内容 |

---

## Step 20.1：数据模型

**目标**：定义共同休息结果模型。

**新增文件**：`domain/model/CommonRestResult.kt`

**数据模型**：
```kotlin
data class CommonRestResult(
    val teamAName: String,              // "一值"
    val teamBName: String,              // "三值"
    val nextCommonRestDate: LocalDate?, // 最近一次共同休息日
    val daysUntilNext: Int?,            // 距今天数
    val commonRestDates: List<LocalDate>, // 所有共同休息日（按日期排序）
    val totalCount: Int,                // 分析范围内总次数
    val countIn30Days: Int,             // 未来 30 天次数
    val countIn60Days: Int              // 未来 60 天次数
)
```

**验证**：编译通过。

---

## Step 20.2：核心算法

**目标**：实现双班组交叉对比，纯函数。

**新增文件**：`domain/colleague_mode.kt`

**函数清单**：
```kotlin
fun findCommonRestDays(
    teamAId: Int,
    teamBId: Int,
    today: LocalDate = LocalDate.now(),
    daysToAnalyze: Int = 365,
    customCycle: List<ShiftType>? = null,
    referenceDate: LocalDate = ShiftCycleConfig.REFERENCE_DATE
): CommonRestResult {
    val offsetA = teamPhaseOffsetFor(teamAId, customCycle)
    val offsetB = teamPhaseOffsetFor(teamBId, customCycle)
    val teamAName = Team.ALL_TEAMS.find { it.id == teamAId }?.name ?: "班组$teamAId"
    val teamBName = Team.ALL_TEAMS.find { it.id == teamBId }?.name ?: "班组$teamBId"

    val commonDates = (0 until daysToAnalyze)
        .map { today.plusDays(it.toLong()) }
        .filter { date ->
            val shiftA = getShiftTypeForDate(date, offsetA, customCycle, referenceDate)
            val shiftB = getShiftTypeForDate(date, offsetB, customCycle, referenceDate)
            val isRestA = shiftA == ShiftType.REST || shiftA == ShiftType.STUDY
            val isRestB = shiftB == ShiftType.REST || shiftB == ShiftType.STUDY
            isRestA && isRestB
        }

    val next = commonDates.firstOrNull()
    val daysUntil = next?.let { ChronoUnit.DAYS.between(today, it).toInt() }
    val count30 = commonDates.count { ChronoUnit.DAYS.between(today, it).toInt() < 30 }
    val count60 = commonDates.count { ChronoUnit.DAYS.between(today, it).toInt() < 60 }

    return CommonRestResult(
        teamAName = teamAName,
        teamBName = teamBName,
        nextCommonRestDate = next,
        daysUntilNext = daysUntil,
        commonRestDates = commonDates,
        totalCount = commonDates.size,
        countIn30Days = count30,
        countIn60Days = count60
    )
}
```

**验证**：`ColleagueModeTest`（约 8 用例，详见 Step 20.6）

---

## Step 20.3：ColleagueModeViewModel

**目标**：管理双班组选择和结果状态。

**新增文件**：`viewmodel/ColleagueModeViewModel.kt`

**状态设计**：
```kotlin
data class ColleagueModeUiState(
    val teamAId: Int = 1,
    val teamBId: Int = 3,
    val result: CommonRestResult? = null,
    val analyzedDateRange: String = "",
    val isLoading: Boolean = true,
    val errorMessage: String? = null
)

class ColleagueModeViewModel(
    application: Application,
    private val todayProvider: () -> LocalDate = { LocalDate.now() }
) : AndroidViewModel(application) {

    fun setTeamA(teamId: Int)
    fun setTeamB(teamId: Int)
    fun refresh(customCycle: List<ShiftType>?, referenceDate: LocalDate)
    fun swapTeams()  // 便捷交换"我"和"他"
}
```

**验证**：编译通过。

---

## Step 20.4：ColleagueModeScreen UI

**目标**：实现双班组下拉 + 结果卡片 + 日期列表。

**新增文件**：`ui/colleague_mode/ColleagueModeScreen.kt`

**布局设计**：
```
┌──────────────────────────────────────┐
│  ← 同事模式                           │  TopAppBar
├──────────────────────────────────────┤
│  我是 [一值 ▼]     他是 [三值 ▼]  ⇄  │  双 TeamDropdown + 交换按钮
├──────────────────────────────────────┤
│  ┌──────────────────────────────┐    │
│  │       下次同时休息               │    │
│  │         5月28日                 │    │  36sp Bold
│  │         星期三                  │    │
│  │       距今 14 天                │    │
│  └──────────────────────────────┘    │
│  ┌────────────┬────────────┐         │
│  │ 未来30天    │ 未来60天    │         │
│  │  共同休息   │  共同休息    │         │
│  │   3 次     │   7 次     │         │
│  └────────────┴────────────┘         │
│  共同休息日（共 N 次）                  │
│  ┌──────────────────────────────┐    │
│  │ 5月28日 星期三          14天后│    │
│  │ 6月03日 星期二          20天后│    │
│  │ ...                          │    │
│  └──────────────────────────────┘    │
│  2026/05/14 — 12/31                  │
└──────────────────────────────────────┘
```

**关键 UI 组件**：
- `NextRestCard`：主结果卡片（渐变背景 + 大字体日期 + 倒计时）
- `StatsRow`：两个统计卡片（30天/60天次数）
- `CommonRestDateList`：LazyColumn 日期列表，每行日期 + 星期 + 距今天数
- `SwapButton`：交换"我"和"他"的班组

**状态处理**：
- 加载中：CircularProgressIndicator
- 同一班组：提示"你们是同一个班组，休息日完全一致"
- 无共同休息：提示"在分析范围内未找到共同休息日"
- 有结果：完整展示

**验证**：编译通过 + Preview 可显示。

---

## Step 20.5：导航集成

**目标**：新增路由，在"我的"页增加入口。

**改造文件**：
- `MainActivity.kt`
- `ui/profile/ProfileScreen.kt`

**MainActivity 改动**：
1. 新增 `ColleagueModeViewModel` factory
2. 在 V2 NavHost 新增 `composable("colleague_mode")` 路由
3. 传递 `runtimeSettings.shiftCycle`、`runtimeSettings.referenceDate`、`homeUiState.selectedTeamId`

**ProfileScreen 改动**：
1. 新增参数 `onColleagueModeClick: () -> Unit`
2. 在菜单卡片中"拼假神器"下方新增"同事模式"项（图标 + "查看共同休息日"）

**验证**：
- "我的"页可见"同事模式"入口
- 点击跳转，返回回到"我的"页
- 编译通过

---

## Step 20.6：单元测试

**目标**：核心算法全覆盖。

**新增文件**：`ColleagueModeTest.kt`（约 8 用例）

**覆盖点**：

| # | 测试用例 | 验证内容 |
|---|---------|---------|
| 1 | `same team produces all common rest days` | 同班组 = 所有休日都是共同休息 |
| 2 | `different teams find intersection` | 不同班组 = 只取交集 |
| 3 | `nextCommonRestDate is earliest` | 下一次 = 列表中第一个 |
| 4 | `daysUntilNext correct` | 距今天数正确 |
| 5 | `countIn30Days accurate` | 30天内计数正确 |
| 6 | `countIn60Days accurate` | 60天内计数正确 |
| 7 | `custom cycle respected` | 自定义周期产出不同结果 |
| 8 | `empty result when no overlap` | 无交集时返回空列表 |

**验证**：
```bash
./gradlew testDebugUnitTest --tests "*ColleagueModeTest"
./gradlew testDebugUnitTest   # 全部通过，零回归
```

---

## 阶段 20 文件变更汇总

| 类型 | 文件 |
|------|------|
| 新增 | `domain/model/CommonRestResult.kt` — 共同休息结果模型 |
| 新增 | `domain/colleague_mode.kt` — 双班组对比算法（~40 行纯函数） |
| 新增 | `viewmodel/ColleagueModeViewModel.kt` — 同事模式 ViewModel（~90 行） |
| 新增 | `ui/colleague_mode/ColleagueModeScreen.kt` — 同事模式 UI（~300 行） |
| 新增 | `ColleagueModeTest.kt` — 核心算法测试（~8 用例） |
| 改造 | `MainActivity.kt` — 新增路由 + ViewModel factory（+40 行） |
| 改造 | `ui/profile/ProfileScreen.kt` — 新增"同事模式"入口（+10 行） |

## 暂缓（V2.1+）

| 功能 | 原因 |
|------|------|
| 工资页 | 需独立薪资 domain + 趋势图 |
| 数据/统计页 | 需图表库 + 历史数据 |
| 骨架屏/滚动动画 | 复杂度高，非核心 |
