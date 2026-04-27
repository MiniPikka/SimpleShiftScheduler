# 倒班助手开发进度记录

## 2026-04-27：全项目文件审查与 memory-bank 同步

### 审查结论

- 已完整阅读所有 memory-bank 文件（app-design-document.md、architecture.md、implementation-plan.md、tech-stack.md）和所有项目源文件（26 个文件）
- 确认所有阶段 1-8 的代码实现与 architecture.md 文档描述一致
- 29 个单元测试覆盖核心算法、ViewModel 状态、日历生成、自定义周期等场景
- 更新 AGENTS.md：去掉"early planning phase"描述，修正文档引用路径
- 更新 tech-stack.md：补充阶段 8 完成状态
- architecture.md 和 implementation-plan.md 内容准确，无需修改

### 项目文件清单（共 26 个源文件）

| 层 | 文件 | 状态 |
|----|------|------|
| Domain 模型 | ShiftType.kt, ShiftCycleConfig.kt, ShiftInfo.kt, CalendarDayInfo.kt, Team.kt, MonthlyStats.kt, RuntimeShiftSettings.kt | ✅ |
| Domain 算法 | shift_calculator.kt, calendar_generator.kt | ✅ |
| ViewModel | HomeViewModel.kt, CalendarViewModel.kt, SettingsViewModel.kt | ✅ |
| UI | HomeScreen.kt, CalendarScreen.kt, SettingsScreen.kt | ✅ |
| Data | SettingsRepository.kt | ✅ |
| 入口 | MainActivity.kt | ✅ |
| 配置 | build.gradle.kts (root+app), settings.gradle.kts, AndroidManifest.xml, strings.xml | ✅ |
| 测试 | ShiftCalculatorTest.kt, CalendarGeneratorTest.kt, HomeViewModelTest.kt, SettingsViewModelTest.kt | ✅ |

---

## 2026-04-27：实施计划第 8 步完成

### 本次完成内容

- 已完成阶段 8（设置页：自定义倒班规则）全部 9 个子步骤：
  - Step 8.1：添加 Navigation Compose + DataStore 依赖到 `build.gradle.kts`
  - Step 8.2：新增 `RuntimeShiftSettings` 运行时配置模型
  - Step 8.3：`shift_calculator` 全部函数新增 `customCycle` 参数（默认 null 回退 `ShiftCycleConfig`）
  - Step 8.4：`calendar_generator` 新增 `customCycle` 参数透传
  - Step 8.5：新增 `SettingsViewModel`（`updateCycleLength/setDayShift/selectDefaultTeam/save/cancel`）
  - Step 8.6：新增 `SettingsScreen`（`LazyVerticalGrid(4列)` 班次编辑器 + 周期长度输入 + 默认班组下拉）
  - Step 8.7：`MainActivity` 改造为 Navigation Compose（Main ↔ Settings 两个路由）
  - Step 8.8：新增 `SettingsRepository`（DataStore Preferences 持久化，逗号分隔枚举名序列化）
  - Step 8.9：新增 `SettingsViewModelTest`（8 个测试）+ `ShiftCalculatorTest` 追加 3 个 customCycle 测试

### 关键结果

- 新增文件：
  - `app/src/main/java/com/simpleshift/scheduler/domain/model/RuntimeShiftSettings.kt`
  - `app/src/main/java/com/simpleshift/scheduler/viewmodel/SettingsViewModel.kt`
  - `app/src/main/java/com/simpleshift/scheduler/ui/settings/SettingsScreen.kt`
  - `app/src/main/java/com/simpleshift/scheduler/data/repository/SettingsRepository.kt`
  - `app/src/test/java/com/simpleshift/scheduler/viewmodel/SettingsViewModelTest.kt`
- 改造文件：
  - `app/build.gradle.kts` — 新增 navigation-compose + datastore-preferences 依赖
  - `app/src/main/java/com/simpleshift/scheduler/domain/shift_calculator.kt` — `customCycle` 参数
  - `app/src/main/java/com/simpleshift/scheduler/domain/calendar_generator.kt` — `customCycle` 参数
  - `app/src/main/java/com/simpleshift/scheduler/viewmodel/HomeViewModel.kt` — `customCycle` 字段 + 动态 `teamPhaseStep()`
  - `app/src/main/java/com/simpleshift/scheduler/viewmodel/CalendarViewModel.kt` — `customCycle` 字段 + 动态 `teamPhaseStep()`
  - `app/src/main/java/com/simpleshift/scheduler/MainActivity.kt` — NavHost 路由 + SettingsRepository + 状态共享
  - `app/src/test/java/com/simpleshift/scheduler/domain/ShiftCalculatorTest.kt` — 追加 3 个 customCycle 测试
- 跨 ViewModel 通信：`MainActivity` 持有 `MutableStateFlow<RuntimeShiftSettings>`，SettingsViewModel 写入，HomeViewModel/CalendarViewModel 读取
- 持久化方案：`ShiftType` 枚举名逗号分隔字符串（如 `"MORNING,AFTERNOON,REST"`），不引入额外序列化库

### 构建与测试说明

- 已执行完整单元测试：`./gradlew testDebugUnitTest`
- 结果：`BUILD SUCCESSFUL`（29 个测试全部通过）
- 阶段 8 变更未引入单测回归

### 下一步

- 所有规划阶段（1-8）已完成，应用功能完整

### 本次完成内容

- 已完成阶段 7（班组切换 + 月度统计）全部子步骤：
  - Step 7.1：新增 `Team` 数据模型（6 个固定班组）和 `MonthlyStats` 统计模型
  - Step 7.2：`shift_calculator` 和 `calendar_generator` 支持 `teamPhaseOffset` 参数
  - Step 7.3：`HomeViewModel` 新增 `selectedTeamId`/`availableTeams` 状态，`selectTeam()` 方法
  - Step 7.4：`HomeScreen` 新增班组下拉框（`ExposedDropdownMenuBox`）
  - Step 7.5：`CalendarViewModel` 新增 `setTeam()`/`computeStats()`/`dismissStats()` 方法
  - Step 7.6：`CalendarScreen` 新增统计按钮 + `AlertDialog` 显示 5 类班次天数
  - `MainActivity` 接线：班组切换同步更新首页和日历

### 关键结果

- 新增文件：
  - `app/src/main/java/com/simpleshift/scheduler/domain/model/Team.kt`
  - `app/src/main/java/com/simpleshift/scheduler/domain/model/MonthlyStats.kt`
- 改造文件：
  - `app/src/main/java/com/simpleshift/scheduler/domain/shift_calculator.kt`
  - `app/src/main/java/com/simpleshift/scheduler/domain/calendar_generator.kt`
  - `app/src/main/java/com/simpleshift/scheduler/viewmodel/HomeViewModel.kt`
  - `app/src/main/java/com/simpleshift/scheduler/viewmodel/CalendarViewModel.kt`
  - `app/src/main/java/com/simpleshift/scheduler/ui/home/HomeScreen.kt`
  - `app/src/main/java/com/simpleshift/scheduler/ui/calendar/CalendarScreen.kt`
  - `app/src/main/java/com/simpleshift/scheduler/MainActivity.kt`
  - `app/src/test/java/com/simpleshift/scheduler/domain/ShiftCalculatorTest.kt`
  - `app/src/test/java/com/simpleshift/scheduler/domain/CalendarGeneratorTest.kt`
  - `app/src/test/java/com/simpleshift/scheduler/viewmodel/HomeViewModelTest.kt`
- 班组切换：`teamPhaseOffset = (teamId - 1) * 7`（42 天 / 6 班组 = 7 天间隔）
- 统计功能：按月统计当前选中班组的早/中/休/夜/学天数，弹窗展示

### 构建与测试说明

- 已执行完整单元测试：`./gradlew testDebugUnitTest`
- 结果：`BUILD SUCCESSFUL`
- 阶段 7 变更未引入单测回归

### 下一步

- **阶段 8**：设置页（自定义倒班规则）— 已规划 9 个 Step（详见 `implementation-plan.md`）
  - 依赖：Navigation Compose + DataStore（均未引入 `build.gradle.kts`）
  - 核心改造：`shift_calculator` 增加 `customCycle` 参数、新增 `RuntimeShiftSettings` 模型
  - 新增文件：`SettingsViewModel`、`SettingsScreen`、`SettingsRepository`

---

## 2026-04-27：ViewModel 构造函数修复

### 问题

- 应用启动时闪退
- 错误：`NoSuchMethodException: HomeViewModel.<init> [class android.app.Application]`

### 根因

- `HomeViewModel` 和 `CalendarViewModel` 有多个构造函数参数（含默认参数）
- Android ViewModelProvider 通过反射创建时无法匹配

### 修复方案

- 添加辅助构造函数（secondary constructor）

### 修复结果

- 应用可正常启动和交互
- 日志确认无崩溃

---

## 2026-04-27：实施计划第 1 步完成

### 本次完成内容
  - Step 1.1：Android Compose 项目已可启动，包名与配置符合计划
  - Step 1.2：目录结构补齐，新增 `data/model/` 目录

### 关键结果

- 项目配置满足计划口径：
  - `namespace = com.simpleshift.scheduler`
  - `applicationId = com.simpleshift.scheduler`
  - `minSdk = 24`
- `MainActivity` 可正常启动并显示默认文本（骨架验证通过）
- 目录结构当前为：
  - `app/src/main/java/com/simpleshift/scheduler/MainActivity.kt`
  - `app/src/main/java/com/simpleshift/scheduler/ui/home/`
  - `app/src/main/java/com/simpleshift/scheduler/viewmodel/`
  - `app/src/main/java/com/simpleshift/scheduler/domain/model/`
  - `app/src/main/java/com/simpleshift/scheduler/data/model/`

### 未开始内容（按计划）

- 阶段 2：数据模型定义
- 阶段 3：核心算法实现
- 阶段 4：首页 UI
- 阶段 5：测试与验收实现（由后续开发迭代完成）

### 给后续开发者的注意事项

- 当前仅完成“可启动骨架 + 目录规范”，尚未引入业务模型和算法代码。
- 请严格遵循 `implementation-plan.md` 中“实施约束（已确认）”后再进入第 2 步。
- 班次显示与枚举策略已统一：英文枚举 + 资源映射中文简写。

## 2026-04-27：实施计划第 2 步完成

### 本次完成内容

- 已完成阶段 2（数据模型定义）全部子步骤：
  - Step 2.1：新增 `ShiftType` 英文枚举（`MORNING/AFTERNOON/REST/NIGHT/STUDY`）
  - Step 2.2：新增 42 天固定周期数组 `SHIFT_CYCLE: List<ShiftType>`
  - Step 2.3：新增固定起始参考日期 `REFERENCE_DATE = 2025-12-15`
- 补充 UI 展示资源映射所需文案：
  - `shift_label_morning = 早`
  - `shift_label_afternoon = 中`
  - `shift_label_rest = 休`
  - `shift_label_night = 夜`
  - `shift_label_study = 学`

### 关键结果

- 新增文件：
  - `app/src/main/java/com/simpleshift/scheduler/domain/model/ShiftType.kt`
  - `app/src/main/java/com/simpleshift/scheduler/domain/model/ShiftCycleConfig.kt`
- `ShiftCycleConfig` 包含以下核心常量：
  - `CYCLE_LENGTH = 42`
  - `REFERENCE_DATE = LocalDate.of(2025, 12, 15)`
  - `SHIFT_CYCLE`（长度校验 `require(cycle.size == CYCLE_LENGTH)`）
- 周期起止验证口径满足计划：
  - `SHIFT_CYCLE[0] == MORNING`
  - `SHIFT_CYCLE[41] == REST`

### 下一步

- 阶段 3：实现核心算法（偏移计算、索引归一化、`getShiftInfo(date)`）

## 2026-04-27：实施计划第 3 步完成

### 本次完成内容

- 已完成阶段 3（核心算法实现）全部子步骤：
  - Step 3.1：实现日期偏移计算 `calculateDayOffset(date)`
  - Step 3.2：实现周期索引归一化 `normalizeCycleIndex(offsetDays)`
  - Step 3.3：实现按日期取班次 `getShiftTypeForDate(date)`
  - Step 3.4：实现统一入口 `getShiftInfo(date): ShiftInfo`
- 新增核心业务模型：
  - `ShiftInfo(date, dayOfCycle, shiftType)`
- 新增单元测试覆盖阶段 3 验证点（偏移、索引、班次、统一入口输出）

### 关键结果

- 新增文件：
  - `app/src/main/java/com/simpleshift/scheduler/domain/model/ShiftInfo.kt`
  - `app/src/main/java/com/simpleshift/scheduler/domain/shift_calculator.kt`
  - `app/src/test/java/com/simpleshift/scheduler/domain/ShiftCalculatorTest.kt`
- `dayOfCycle` 输出范围已按计划定义为 `1..42`（由 `cycleIndex + 1` 计算）
- 算法严格基于 `REFERENCE_DATE = 2025-12-15` 与 `CYCLE_LENGTH = 42`

### 构建与测试说明

- 已补充 `app/build.gradle.kts` 的测试依赖：`testImplementation("junit:junit:4.13.2")`
- 当前仓库缺失 `gradle/wrapper/gradle-wrapper.jar`，本地无法直接执行 `./gradlew test`，待补齐 wrapper 后可运行验证

### 下一步

- 阶段 4：首页 UI（`HomeViewModel`、`HomeScreen`、前后台刷新整合）

## 2026-04-27：实施计划第 4 步完成

### 本次完成内容

- 已完成阶段 4（首页 UI）全部子步骤：
  - Step 4.1：新增 `HomeViewModel` 与 `HomeUiState`，以 `StateFlow` 输出首页状态
  - Step 4.2：新增 `HomeScreen`，展示“今日日期 / 今日班次 / 周期进度”
  - Step 4.3：`MainActivity` 接入 ViewModel + UI，并在 `onResume()` 自动刷新今日数据
- 同步更新 `memory-bank/architecture.md`，记录阶段 4 架构状态与边界变化

### 关键结果

- 新增文件：
  - `app/src/main/java/com/simpleshift/scheduler/viewmodel/HomeViewModel.kt`
  - `app/src/main/java/com/simpleshift/scheduler/ui/home/HomeScreen.kt`
- 改造文件：
  - `app/src/main/java/com/simpleshift/scheduler/MainActivity.kt`
- 首页状态字段已对齐计划目标：
  - `todayDate`（本地化可读）
  - `shiftType`（英文枚举）
  - `shiftLabel`（资源映射：`早/中/休/夜/学`）
  - `dayOfCycle`（1..42）
  - `totalDays`（42）

### 构建与测试说明

- 已执行静态检查：本次变更文件无 IDE linter 报错
- 仍无法执行 `./gradlew testDebugUnitTest`：
  - 缺少 `gradle/wrapper/gradle-wrapper.jar`
  - 错误：`Could not find or load main class org.gradle.wrapper.GradleWrapperMain`

### 下一步

- 阶段 5：测试与验收
  - 补齐 `HomeViewModel` 状态单元测试
  - 在补齐 Gradle wrapper 后执行完整单元测试验证

## 2026-04-27：实施计划第 5 步完成

### 本次完成内容

- 已完成阶段 5 中“当前可执行”的全部工作：
  - Step 5.1：核心算法单元测试已在 `ShiftCalculatorTest` 覆盖并保持通过口径
  - Step 5.2：新增 `HomeViewModelTest`，覆盖初始化产出、刷新更新、班次文案映射
- 为保证 `HomeViewModel` 测试稳定性，新增轻量可测性注入点：
  - `currentDateProvider: () -> LocalDate`
  - `localeProvider: () -> Locale`
  - 生产默认行为保持不变（等价于 `LocalDate.now()` + `Locale.getDefault()`）
- 同步更新测试依赖，新增：
  - `testImplementation("org.robolectric:robolectric:4.13")`
  - `testImplementation("androidx.test:core:1.5.0")`
- 已同步更新 `memory-bank/architecture.md`，记录阶段 5 架构状态与测试边界

### 关键结果

- 新增文件：
  - `app/src/test/java/com/simpleshift/scheduler/viewmodel/HomeViewModelTest.kt`
- 改造文件：
  - `app/src/main/java/com/simpleshift/scheduler/viewmodel/HomeViewModel.kt`
  - `app/build.gradle.kts`
- `HomeViewModelTest` 覆盖点：
  - 初始化状态字段：`todayDate/shiftType/shiftLabel/dayOfCycle/totalDays`
  - 刷新行为：日期变化后 `refreshToday()` 触发状态更新
  - 文案映射：`MORNING/AFTERNOON/REST/NIGHT/STUDY` 对应 `早/中/休/夜/学`

### 构建与测试说明

- 已执行完整单元测试：`./gradlew testDebugUnitTest`
- 首次执行失败原因：
  - `HomeViewModelTest` 报错 `Resources$NotFoundException`（JVM 单测未开启 Android 资源支持）
- 修复动作：
  - 在 `app/build.gradle.kts` 增加 `testOptions.unitTests.isIncludeAndroidResources = true`
- 修复后复测结果：
  - `BUILD SUCCESSFUL`
  - `app:testDebugUnitTest` 通过
  - 当前阶段 5 验收项已闭环

## 2026-04-27：实施计划第 6 步完成

### 本次完成内容

- 已完成阶段 6（日历页基础实现）全部子步骤：
  - Step 6.1：新增月历网格生成逻辑 `generateMonthCalendarDays(yearMonth)`
  - Step 6.2：新增 `CalendarViewModel` 与 `CalendarUiState`
  - Step 6.3：新增 `CalendarScreen` 并接入 `MainActivity`
- 首页与日历页已实现同屏展示：
  - 首页继续展示“今日日期/班次/进度”
  - 日历展示“月标题 + 周标题 + 42 格日期班次”
- 完成阶段 6 对应单元测试：
  - 新增 `CalendarGeneratorTest`（42 格、周起始、当月标记）

### 关键结果

- 新增文件：
  - `app/src/main/java/com/simpleshift/scheduler/domain/model/CalendarDayInfo.kt`
  - `app/src/main/java/com/simpleshift/scheduler/domain/calendar_generator.kt`
  - `app/src/main/java/com/simpleshift/scheduler/viewmodel/CalendarViewModel.kt`
  - `app/src/main/java/com/simpleshift/scheduler/ui/calendar/CalendarScreen.kt`
  - `app/src/test/java/com/simpleshift/scheduler/domain/CalendarGeneratorTest.kt`
- 改造文件：
  - `app/src/main/java/com/simpleshift/scheduler/MainActivity.kt`
  - `app/src/main/java/com/simpleshift/scheduler/ui/home/HomeScreen.kt`
- `CalendarViewModel` 能力：
  - 支持 `goToPreviousMonth()/goToNextMonth()/refresh()`
  - 输出 `monthLabel/weekLabels/days`
  - 使用资源映射输出 `早/中/休/夜/学`

### 构建与测试说明

- 已执行完整单元测试：`./gradlew testDebugUnitTest`
- 结果：`BUILD SUCCESSFUL`
- 阶段 6 变更未引入单测回归
