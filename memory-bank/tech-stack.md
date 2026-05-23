# tech-stack.md

## 0. 项目双阶段概述

- **Phase 1（已完成）**：Android 原生版 — Kotlin + Jetpack Compose + MVVM + StateFlow + DataStore
- **Phase 2（规划中）**：CP（Cross Platform）版 — Flutter + Riverpod + GoRouter + Freezed + Hive

---

# Part A：CP（Cross Platform）版技术栈

## A.1 总体方向

CP 版本目标：Android / iOS / Web（后期）/ Desktop（后期）。统一代码架构，降低平台维护成本。

---

## A.2 技术栈总览

| 层级 | 技术 |
|------|------|
| UI | Flutter |
| 状态管理 | Riverpod |
| 路由 | GoRouter |
| 数据模型 | Freezed |
| 本地存储 | Hive / Isar |
| 国际化 | intl |
| 动画 | Flutter Animation |
| 网络 | Dio |
| 后端（后期） | Supabase |
| 高性能逻辑（后期） | Rust |

---

## A.3 为什么选择 Flutter

### A.3.1 真跨平台

一套 UI：Android / iOS / Web / Desktop。一致性极强。

### A.3.2 UI 开发效率极高

适合 Dashboard、日历、卡片、动画、数据展示。

### A.3.3 AI 支持极强

Claude、ChatGPT、Gemini 对 Flutter 支持远强于 Kotlin Multiplatform、Slint、React Native、SwiftUI。

### A.3.4 生态成熟

插件生态丰富：通知、Widget、分享、本地存储、动画、图表、日历。

---

## A.4 各层技术详解

### A.4.1 UI 层：Flutter

高性能、UI 一致性强、动画强、开发效率高、热重载优秀。统一 Design System：色彩、圆角、间距、动画、字体层级。Design Token：spacing / radius / typography / colors / elevation。

### A.4.2 状态管理：Riverpod

相比 Provider / Bloc / GetX，Riverpod 更现代、类型安全、测试友好、生命周期清晰。UI 使用 ConsumerWidget / HookConsumerWidget，业务逻辑使用 StateNotifier / AsyncNotifier。

### A.4.3 路由：GoRouter

官方推荐方向，Deep Link 友好，Web 兼容好，ShellRoute 适合 Bottom Navigation。

### A.4.4 数据层

- **Hive（MVP）**：简单、快、本地优先、学习成本低
- **Isar（后期）**：更强查询能力、索引、关系模型

### A.4.5 国际化：intl

支持中文（默认）、English、日本語、한국어。

### A.4.6 通知系统：flutter_local_notifications

本地通知、定时提醒、Android/iOS 支持。

### A.4.7 Widget

- Android: home_widget / android widget
- iOS: WidgetKit bridge

### A.4.8 分享系统

分享不是附属功能，而是增长核心。能力：长图生成、分享卡片、截图模板、QR Code。

### A.4.9 动画系统

动画服务于信息层级、状态变化、高级感，不是炫技。技术：AnimatedContainer、Hero、Custom Animation、Implicit Animation。

### A.4.10 Domain 层

纯函数、无平台依赖、无 UI 依赖。内容：倒班算法、拼假算法、日期计算、津贴统计、工作强度分析。

### A.4.11 Rust（后期）

Flutter 负责 UI，Rust 负责高性能算法、本地服务、复杂计算。适合：拼假优化器、AI 分析、大规模计算、Desktop Companion。

### A.4.12 后端（后期）：Supabase

开发快、Auth 简单、PostgreSQL、Realtime。后期功能：用户同步、云备份、分享社区、班组分享。

---

## A.5 不推荐技术

| 技术 | 原因 |
|------|------|
| React Native | UI 一致性弱、动画体验一般、Android 兼容性复杂 |
| Kotlin Multiplatform | AI 支持弱、生态碎片化、iOS 调试复杂 |
| Electron | 太重、内存占用高、移动端能力弱 |

---

## A.6 CP 项目结构

```text
lib/
 ├── app/
 ├── core/
 │    ├── theme/
 │    ├── constants/
 │    ├── utils/
 │    ├── services/
 ├── features/
 │    ├── home/
 │    ├── calendar/
 │    ├── leave_optimizer/
 │    ├── colleague_mode/
 │    ├── salary_predictor/
 │    ├── profile/
 ├── domain/
 │    ├── models/
 │    ├── algorithms/
 ├── data/
 │    ├── repositories/
 │    ├── datasources/
 └── main.dart
```

---

## A.7 开发原则

- **MVP 第一**：功能完整、用户增长、快速上线优先，不过度架构、不技术炫技
- **单人开发友好**：AI 友好、文档成熟、社区大、调试简单
- **产品优先**：重点不是"用了什么框架"，而是"有没有用户愿意天天打开"

---

# Part B：Phase 1 Android 版技术栈（已完成）

## B.1 设计目标

本技术栈遵循两个核心原则：

* **简单优先**：降低学习成本，快速开发上线
* **足够健壮**：可维护、可扩展、不容易踩坑

---

## 2. 总体架构

**推荐架构：**

* MVVM（官方推荐，简单稳定）
* 单模块（MVP阶段避免过度设计）

---

## 3. 技术选型

### 3.1 开发语言

* **Kotlin**

  * Android 官方首选
  * 空安全，减少崩溃
  * 协程支持异步

---

### 3.2 UI 框架

* **Jetpack Compose（强烈推荐）**

  * 声明式 UI，代码量少
  * 不需要 XML
  * 非常适合你这种“日历 + 状态展示”应用

---

### 3.3 架构组件

* **ViewModel**

  * 管理 UI 状态
* **StateFlow**

  * 响应式数据流，替代 LiveData（更现代）

---

### 3.4 数据存储

#### MVP 推荐：

* **DataStore（Preferences）**

  * 替代 SharedPreferences
  * 异步 + 类型安全
  * 足够应对倒班规则存储

#### 已引入：

* **Calendar Provider（`CalendarContract`，Android 平台 API）**

  * 写入/读取设备本地日历日程（`ContentResolver` + `CalendarContract.Events`）
  * 日程提醒通过 `CalendarContract.Reminders.METHOD_ALERT` 实现（系统自动弹出通知）
  * 使用 `ACCOUNT_TYPE_LOCAL` 本地日历账户，日程仅存储设备本地
  * 日程持久化在系统日历数据库，跨重启自动恢复

#### 未来扩展：

* **Room（可选）**

  * 如果后续需要历史记录/复杂查询再引入

---

### 3.5 日期处理

* **java.time（内置）**

  * LocalDate / DayOfWeek
  * 不要用旧 Date API

---

### 3.6 导航

* **Navigation Compose**

  * 官方方案
  * 适合3个页面的小应用

---

### 3.7 异步处理

* **Kotlin Coroutines**

  * 轻量、直观
  * 与 Flow 完美配合

---

## 4. 依赖最小集合（核心）

```kotlin
// Compose
implementation("androidx.compose.ui:ui")
implementation("androidx.compose.material3:material3")

// Lifecycle
implementation("androidx.lifecycle:lifecycle-viewmodel-ktx")

// Navigation
implementation("androidx.navigation:navigation-compose")

// DataStore
implementation("androidx.datastore:datastore-preferences")

// Coroutines
implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android")
```

---

## 5. 项目结构（极简但清晰）

```id="structure1"
app/
 ├── ui/
 │    ├── theme/              # 阶段 17 新增：Design Token 系统
 │    ├── home/
 │    │    ├── components/    # V1 组件（阶段 16）+ V2 组件（阶段 17）
 │    │    ├── NewHomeScreenV2.kt   # 阶段 17：V2 首页
 │    ├── calendar/
 │    ├── settings/
 │    ├── leave_optimizer/    # 阶段 19：拼假神器
 │    ├── colleague_mode/     # 阶段 20：同事模式
 │    ├── salary_predictor/   # 阶段 21 规划：倒班津贴
 │    ├── profile/            # 阶段 17 新增
 │    ├── common/             # 共享组件（TeamDropdown）
 │
 ├── viewmodel/
 │
 ├── calendar/                # Calendar Provider 日程管理
 │
 ├── widget/                  # Glance AppWidget
 │
 ├── data/
 │    ├── repository/         # DataStore 持久化仓储
 │    ├── model/              # 数据库实体、持久化扩展模型
 │
 ├── domain/
 │    ├── model/              # 核心业务模型（如 ShiftType/ShiftInfo）
 │    ├── shift_calculator.kt
 │    ├── calendar_generator.kt
 │    └── shift_metrics.kt
 │
 └── MainActivity.kt
```

---

## 5.1 分层与建模约束（执行口径）

- `ShiftType` 采用英文枚举（如 `MORNING/AFTERNOON/REST/NIGHT/STUDY`）
- UI 展示文案通过资源映射为 `早/中/休/夜/学`
- 核心排班计算逻辑位于 domain 层，ViewModel 负责状态编排
- 日期计算以设备本地时区为准，使用 `LocalDate.now()` 即时生效

## 6. 为什么这是“最优解”

### ✔ 简单

* 无 XML
* 无复杂 DI（不引入 Hilt）
* 单模块结构

### ✔ 健壮

* Flow + ViewModel 不容易内存泄漏
* DataStore 避免 SharedPreferences 的坑
* Kotlin 空安全降低崩溃率

### ✔ 可扩展

以后要加：

* Room（历史记录）
* WorkManager（闹钟/提醒）
* Widget（桌面组件）

都可以无缝接入

---

## 7. 明确不推荐（当前阶段）

❌ Hilt / Dagger
→ 过度设计，小项目没必要

❌ 多模块架构
→ 会显著增加复杂度

❌ LiveData
→ 已被 StateFlow 更优替代

❌ XML + ViewBinding
→ 比 Compose 繁琐

---

## 8. 一句话总结

👉 **Kotlin + Compose + MVVM + StateFlow + DataStore**

这是目前 Android 上：

* 学习成本最低
* 出错概率最低
* 开发体验最好的组合

---

## 11. V2 UI 设计系统（阶段 17）

### 设计语言

* **Dark Productivity Design**（深色高级 + 克制 + 效率感）
  * 页面底色 `#0B0D10`，次级区域 `#15181D`，卡片表面 `#1B1F26`
  * 强调金色 `#FACC15`
  * 班次色：早=橙 `#FFB347`、中=蓝 `#4DA3FF`、夜=紫 `#7C5CFF`、休=绿 `#35D07F`、学=黄 `#F2D94E`

### 双轨制

* **`USE_NEW_HOME`** — 控制 V1 升级版首页 vs 旧首页
* **`USE_NEW_HOME_V2`** — 控制深色主题 + 底部导航 + 全 App V2 体验
* 两级编译时常量，改值即刻切换回滚，V1 字节码完全不变

### 导航

* **底部导航栏（V2）**：`NavigationBar` + 3 个 `NavigationBarItem`（首页 / 日历 / 我的）
* **NavHost 保留**：子页面（设置等）通过 `navigate()` 推入，底部导航仅在 3 个顶级路由时显示
* **路由结构**：`home` / `calendar` / `profile`（顶级）+ `settings`（子级）

### 动画

* `AnimatedVisibility` + `fadeIn` + `slideInVertically`（450ms 错步入场）

---

## 9. 当前进度与后续建议

已完成（阶段 1-14，功能完整 + 代码加固；阶段 15 桌面 Widget 已完成）：
1. 搭项目（Compose 模板）✅
2. 做首页（班组下拉框 + 今日班次 + 进度）✅
3. 实现"倒班计算核心逻辑"（含班组偏移支持）✅
4. 接入日历 UI（7×7 网格 + 上月/下月切换）✅
5. 班组切换 + 月度统计 ✅
6. 设置页（自定义倒班规则 + DataStore 持久化 + Navigation Compose 导航）✅
7. 日历提醒（Calendar Provider 本地日历日程 + 每班次独立时间 + 系统提醒 + 跨品牌兼容 + 365 天覆盖）✅
8. 代码加固与测试补全（阶段 11-14，已完成）✅
9. 桌面小组件（阶段 15，已完成）—— Jetpack Glance 实现 Compose 式 Widget，在桌面显示今日班次与进度
10. 夜班提醒日期修复（已完成）—— NIGHT 班次日历事件前移一天
11. 首页精品化升级（阶段 16，已完成）—— 组件化 UI 升级，双轨制渐进接入
12. 日历独立路由（2026-05-14，已完成）—— 日历从首页拆分为独立导航页面，Scaffold + TopAppBar + TeamDropdown
13. TodayShiftCard 重设计（2026-05-14，已完成）—— 横向布局 + 进度条 + 圆形班次徽章 + 距休标识
14. Widget 美化（2026-05-14，已完成）—— 对齐首页卡片风格，简化设计，新增距休信息
15. V2 完整 UI 设计系统（阶段 17，已完成）—— Design Token 系统 + Dark Productivity Design + 底部导航（首页/日历/我的）+ 牛马指数 + Profile 页
16. 倒班规则编辑器重设计（阶段 18，已完成）—— 两步向导式规则编辑（按钮构建序列 + 日期保存）+ 规则/提醒拆分为独立页面
17. 首页精简 —— 移除与底部导航重复的 `TeamDropdown` / `QuickActionsRow`
18. 拼假神器（阶段 19）—— 结合倒班表 + 法定节假日，自动分析最佳请假方案（差异化功能）
19. 同事模式（阶段 20）—— 输入两人班组，自动计算共同休息日（社交裂变功能）
20. 倒班津贴（阶段 21）—— 输入各班次补贴金额，自动统计班次并计算本月津贴 + 假设分析（高频刚需功能）
21. 图片分享（阶段 22）—— 同事模式结果生成分享长图 + QR 码，调起系统分享面板（社交传播功能）
22. 提醒时间选择器改进（阶段 23）—— 升级 BOM + Material3 TimePicker 替代 AlertDialog 文本输入框

23. Deprecation cleanup（阶段 24）—— 13 个 Material3 1.2.x deprecation warnings 全部清零，编译零警告

全部规划功能（阶段 1-24）已完成。Kotlin 1.9.24 + Compose BOM 2024.04.00 + Material3 1.2.1。编译零警告。应用功能完整，150 个单元测试全部通过（BUILD SUCCESSFUL）。

阶段 27（多语言支持）：中文（默认）、日本語、한국어、English 四种语言。Android 标准资源限定符方案。新增 `TeamNameMapper`、`HolidayNameMapper`、Context-based `ShiftLabelMapper`。首页 V1-V4 多轨合并为单一 `HomeScreen.kt`。

---

## 16. 多语言支持技术选型（阶段 27）

### 方案

* **Android 标准资源限定符** — `values/strings.xml`（zh 默认）+ `values-ja/`、`values-ko/`、`values-en/`
  * 无第三方 i18n 库依赖
  * Compose 中用 `stringResource(R.string.xxx)`
  * 非 Compose 代码中用 `context.getString(R.string.xxx)`
  * Widget 在 `provideGlance()` 中预解析字符串

### i18n 工具层

* **`ShiftLabelMapper.toLabel(context, shiftType)`** — 班次短标签（早/AM/조/早）
* **`ShiftLabelMapper.toFullLabel(context, shiftType)`** — 班次全称（早班/Morning/조번/早番）
* **`TeamNameMapper.toName(teamId, context)`** — 班组名（一值/Shift A/1조/一値）
* **`HolidayNameMapper.toLocalizedName(chineseName, context)`** — 节假日名本地化

### 设计原则

* Domain 层保持纯函数，通过 resolver 函数参数传入显示字符串
* `Team` 数据类仅存储 `id`，不含 `name`
* Widget 字符串预解析（Glance 不支持 `stringResource()`）
* 测试不断言特定语言的字符串值，改为检查非空/结构正确

---

## 10. 桌面 Widget 技术选型（阶段 15）

### 框架选择

* **Jetpack Glance（`androidx.glance:glance-appwidget:1.1.0`）**
  * Google 官方推荐的 Compose 式 AppWidget 框架
  * 声明式 UI，与项目现有 Compose 代码风格一致
  * 底层编译为 RemoteViews，100% 兼容系统 Widget
  * Min SDK 23，项目 Min SDK 24 满足要求
  * 配合 `glance-material3` 使用 Material 3 主题

### Widget 架构

```
SettingsRepository (DataStore)
       │
       ▼
computeWidgetShiftData()   ← domain 层纯函数，复用 getShiftInfo() + daysUntilNextRest()
       │
       ▼
ShiftWidget.provideGlance()  ← GlanceAppWidget，读取 DataStore + 计算 + 渲染
       │
       ▼
ShiftWidgetReceiver         ← 系统 Receiver，注册在 AndroidManifest
```

Widget 布局对齐首页卡片：圆角 Box 徽章（白字班次）+ 班组名/"第 X/Y 天" + 距休/休息日标识 + 日期页脚。进度用纯文字（Glance 不支持进度条组件）。

### 更新策略

* **系统周期**：`updatePeriodMillis=3600000`（1小时）
* **App 内主动**：设置保存后 + onResume 广播 `ACTION_APPWIDGET_UPDATE`
* **用户触发**：点击 Widget 打开 App → onResume → 刷新
* **Widget 尺寸**：`minWidth=250dp`, `minHeight=40dp`, `targetCellWidth=4`, `targetCellHeight=1`

---

## 12. 拼假神器技术选型（阶段 19 规划）

### 算法选型

* **间隙桥接法（Gap-Merging）** — 核心算法
  * 扫描今日至年底（最多 365 天），识别休息块和工作间隙
  * 对每个 ≤ maxLeaveDays 的工作间隙：请假桥接 → 合并相邻休息块
  * O(n) 复杂度，毫秒级完成
  * 覆盖 95%+ 真实请假场景（连续请假）

### 节假日数据

* **本地内置**（`domain/holiday_data.kt`）
  * 中国国务院发布的法定节假日 + 调休工作日
  * 每年发布下一年安排后更新此文件即可（约 150 行数据）
  * 不引入网络请求、不依赖第三方 API
  * 2027 年数据基于农历推算，标记"待确认"

### 评分体系

```
综合分 = 0.50 × 效率分 + 0.25 × 长度分 + 0.25 × 家庭分
```
* **效率分**：连休天数 ÷ 请假天数（核心指标）
* **长度分**：连休绝对天数（长假期有独立价值）
* **家庭分**：与节假日/周末的重叠天数（家庭团聚时间）

### 数据流

```
SettingsRepository (DataStore)
       │
       ▼
getShiftTypeForDate()        ← domain 层纯函数
       │
       ▼
buildDailyStatus()           ← 构建今日至年底状态数组
       │
       ▼
findBestLeavePlans()         ← 间隙检测 + 策略评分
       │
       ▼
LeaveOptimizerViewModel      ← StateFlow 暴露策略列表
       │
       ▼
LeaveOptimizerScreen         ← LazyColumn 卡片列表
```

### 导航

* 入口：ProfileScreen → "拼假神器"菜单项
* 路由：`navController.navigate("leave_optimizer")`
* 返回：`navController.popBackStack()`（回到"我的"页）
* 不在底部导航栏新增 Tab（避免导航栏过于拥挤）

---

## 13. 同事模式技术选型（阶段 20 规划）

### 算法选型

* **双班组逐日交叉对比** — O(n)，n ≤ 365
  * 对每一天分别计算两人的 `getShiftTypeForDate()`
  * 两天均为 REST/STUDY → 共同休息日
  * 算法约 30 行纯函数，比拼假神器简单一个量级
  * 复用 `teamPhaseOffsetFor()` + `getShiftTypeForDate()`

### 社交传播设计

* **信息即内容**："下次同时休息：5月28日" 是大字体具体日期，天然对话素材
* **截图即分享**：结果页面信息密度高，一屏展示关键数据
* **零操作门槛**：默认值（"我"=当前班组，"他"=相邻班组）让用户打开即见结果
* **V2 扩展**：分享按钮生成带二维码的分享图

### 数据流

```
teamAId, teamBId
       │
       ▼
teamPhaseOffsetFor()         ← 计算两队相位偏移
       │
       ▼
getShiftTypeForDate()        ← 对每天分别计算两人班次
       │
       ▼
findCommonRestDays()         ← 取交集，统计
       │
       ▼
ColleagueModeViewModel       ← StateFlow 暴露结果
       │
       ▼
ColleagueModeScreen          ← 主卡片 + 统计行 + 日期列表
```

### 导航

* 入口：ProfileScreen → "同事模式"菜单项（拼假神器下方）
* 路由：`navController.navigate("colleague_mode")`
* 返回：`navController.popBackStack()`（回到"我的"页）

---

## 14. 倒班津贴技术选型（阶段 21 规划）

### 核心理念

* **只算倒班直接决定的**：班次补贴，不涉及基本工资/餐补/五险一金/个税
* **算得准、零维护**：不依赖任何企业差异化政策

### 算法选型

* **班次统计 × 补贴单价** — 纯算术，纯函数，零外部依赖
  * 复用 `countShiftTypeInMonth()` 逐类型统计
  * 本月倒班津贴 = Σ(每种班次补贴 × 当月天数)，每种班次补贴可单独配置（默认 0）
  * 假设分析 = 增量计算（多上 X 天某班次 → +X×该班次补贴），班次类型可选

### 数据持久化

* **DataStore**（SettingsRepository 新增 1 个 key）
  * `shift_premiums` 以逗号分隔格式序列化（如 `"MORNING=0,AFTERNOON=50,NIGHT=200,STUDY=0"`），与现有 `shift_cycle` 序列化风格一致

### 数据流

```
Shift Schedule (getShiftTypeForDate)
       │
       ▼
countAllShiftTypesInMonth()   ← 统计当月各班次天数
       │
       ▼
calculateSalaryBreakdown()    ← 班次 × 津贴参数 = 津贴明细
       │
       └──→ simulateExtraShifts() ← 假设分析（可选班次类型）
              │
              ▼
       SalaryPredictorViewModel  ← StateFlow
              │
              ▼
       SalaryPredictorScreen     ← 津贴卡片 + 班次统计 + 假设分析
```

### 导航

* 入口：ProfileScreen → "倒班津贴"菜单项（同事模式下方）
* 路由：`navController.navigate("salary_predictor")`
* 返回：`navController.popBackStack()`（回到"我的"页）

---

## 15. 图片分享技术选型（阶段 22 规划）

### 离屏渲染选型

* **ComposeView 离屏渲染** — 因 Compose BOM 2023.10.01 无 `GraphicsLayer.toBitmap()`
  * 创建未 attach 的 `ComposeView` → `setContent` → `measure/layout` → `draw(Canvas(Bitmap))`
  * 必须在 `Dispatchers.Main` 执行（`ComposeView.setContent` 要求 Looper）
  * 已在 Android 5.0+（API 21+）验证可行
  * 输出分辨率：1080px 宽（360dp × 3x），主流通用分享图分辨率

### QR 码生成

* **`com.google.zxing:core:3.5.3`**（纯编码，无相机扫描）
  * `QRCodeWriter.encode()` → `BitMatrix` → 逐像素写入 `Bitmap`
  * 纯函数，`Dispatchers.Default` 执行
  * 相比 `zxing-android-embedded`：体积更小、无多余 Activity、无相机权限需求
  * QR URL 常量 `SHARE_QR_URL`，上架后替换为应用商店链接

### FileProvider

* **`androidx.core.content.FileProvider`**（AndroidX 内置，无额外依赖）
  * `cache-path` → `share_images/` 子目录
  * `exported="false"` + `grantUriPermissions="true"` 安全模型
  * `FLAG_GRANT_READ_URI_PERMISSION` 临时授权给微信/QQ

### 缓存管理

* 无 WorkManager 依赖 — `MainActivity.onCreate()` + 分享前调用 `cleanupOldShareImages()`
* TTL：24 小时
* 目录：`context.cacheDir/share_images/`（系统清理缓存时自动删除，应用卸载时一并清除）

### 数据流

```
用户点击分享按钮
       │
       ▼
ColleagueModeViewModel.startShare(context)
       │
       ├── Dispatchers.Default: 构建 ShareCardData + generateQrCodeBitmap()
       ├── Dispatchers.Main:    renderComposableToBitmap(ShareCardLayout)
       ├── Dispatchers.IO:      saveBitmapToShareCache() → content:// Uri
       └── Main (implicit):     shareUri = uri → LaunchedEffect → Intent.ACTION_SEND
```

### 分享 Intent 构造

```kotlin
Intent(Intent.ACTION_SEND).apply {
    type = "image/png"
    putExtra(Intent.EXTRA_STREAM, shareUri)
    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
}
startActivity(Intent.createChooser(intent, "分享到"))
```

### 首期覆盖范围

* ✅ 同事模式分享（传播价值最高，一次渲染无分页）
* ❌ 拼假神器分享（暂缓：需分页渲染多条策略卡片）
* ❌ 倒班津贴分享（暂缓：收入隐私敏感）

---

# Part C：新技术栈 — Rust 中心（2026-05-22 起）

## C.1 总体方向

从"Flutter 跨平台 App"升级为以 Rust 为核心、协议优先的架构。最终技术栈是一个以 Rust 为中心、多前端（CLI/Flutter/Plasma Widget/WebAssembly）的架构。

## C.2 最终推荐技术栈

| 层 | 技术 | 说明 |
|------|------|------|
| **Core Domain** | **Rust** | 真跨平台、零成本 FFI、CLI/TUI/WASM 全支持 |
| **Mobile UI** | **Flutter** | 最佳移动端 UI 框架，通过 flutter_rust_bridge 调用 Rust |
| **Linux Integration** | **ICS / CalDAV** | 标准日历协议，零 UI 成本兼容全部日历软件 |
| **Linux Automation** | **CLI (Rust + clap)** | 工程师用户、易测试、易自动化、稳定性高 |
| **Linux GUI** | **Plasma Widget (QML)** | Glanceable info，不是窗口式 App |
| **Desktop IPC** | **DBus (zbus)** | 系统级广播班次变化 |
| **Local API** | **axum HTTP** | localhost HTTP API 供脚本/自动化消费 |
| **Cloud（后期）** | **Supabase** | 可选云同步，非必选 |

## C.3 Rust Workspace 技术选型

### C.3.1 Core Domain crates

```toml
[workspace]
members = [
    "shift-algorithm",
    "shift-statistics",
    "leave-optimizer",
    "holiday-engine",
    "export-engine",
]
```

| Crate | 依赖 | 功能 |
|-------|------|------|
| `shift-algorithm` | `chrono` | 日期偏移计算、周期索引归一化、get_shift_type_for_date |
| `shift-statistics` | `chrono`, `shift-algorithm` | 月度统计、连续上班、距休、同事模式 |
| `leave-optimizer` | `chrono`, `shift-algorithm`, `holiday-engine` | 间隙桥接法拼假算法、综合评分 |
| `holiday-engine` | `chrono` | 2026-2027 中国法定节假日 + 调休数据 |
| `export-engine` | `icalendar`, `chrono`, `rrule`, `shift-algorithm` | ICS 文件生成、RRULE 压缩、CalDAV 同步 |

### C.3.2 关键 Rust 依赖

```toml
[dependencies]
chrono = { version = "0.4", features = ["serde"] }  # 日期时间（java.time 等价）
icalendar = "0.15"         # ICS RFC 5545 生成
rrule = "0.14"             # 周期重复规则（RRULE 生成/展开）
serde = { version = "1.0", features = ["derive"] }  # 序列化
serde_json = "1.0"         # JSON 输出（CLI/API）
clap = { version = "4.5", features = ["derive"] }   # CLI 参数解析
zbus = { version = "5.0", default-features = false } # DBus 服务
axum = "0.8"               # HTTP 服务（Local API）
tokio = { version = "1.0", features = ["full"] }     # 异步运行时
toml = "0.8"               # 配置文件解析
dirs = "5.0"               # XDG 目录规范

[dev-dependencies]
tempfile = "3.0"           # 临时文件（测试用）
```

## C.4 Flutter ↔ Rust FFI 技术选型

### dart:ffi + package:ffi (JSON over C)

| 特性 | 说明 |
|------|------|
| 自动代码生成 | Dart ↔ Rust 类型映射、FFI 胶水代码自动生成 |
| 类型安全 | 编译期保证 Dart/Rust 类型一致 |
| 异步支持 | Rust async fn → Dart Future |
| 零拷贝 | 复杂类型通过指针传递，无需序列化/反序列化 |
| 错误传递 | Rust Result<T,E> → Dart try/catch |
| Stream 支持 | Rust Stream → Dart Stream |

### 替代方案对比

| 方案 | 评价 |
|------|------|
| `flutter_rust_bridge` | **推荐** — 最成熟、社区最活跃、类型安全 |
| 手动 FFI (dart:ffi) | 灵活但工作量大、易出错、类型不安全 |
| JSON over MethodChannel | 每步都要序列化/反序列化、性能差 |
| Protobuf over FFI | 需要 proto 定义、增加构建复杂度 |

## C.5 CLI 技术选型

### clap derive

```rust
use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "shift", about = "倒班助手 CLI")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    Today,              // shift today
    NextRest,           // shift next-rest
    Calendar { month: Option<String> },  // shift calendar [month]
    Stats { month: Option<String> },     // shift stats [month]
    Leave { max_days: Option<u32> },     // shift leave [--max-days 5]
    Colleague { team_a: u8, team_b: u8 }, // shift colleague 1 3
    Export {
        #[arg(long)]
        ics: bool,      // shift export --ics
        #[arg(long)]
        caldav: bool,   // shift export --caldav
    },
    Config {
        #[command(subcommand)]
        action: ConfigAction,
    },
}
```

### 输出格式

CLI 默认输出人类可读文本（ANSI 颜色），支持 `--json` 全局 flag 输出机器可读 JSON：

```bash
shift today
# 🟠 早班 · 一值 · 第 12/42 天 · 距休 3 天

shift today --json
# {"date":"2026-05-22","shift_type":"MORNING","shift_label":"早班","team":"一值","day_of_cycle":12,"total_days":42,"days_until_rest":3}
```

## C.6 ICS/CalDAV 技术选型

### ICS 标准 (RFC 5545)

为什么选择 ICS 而非自建协议：
- **零 UI 成本**：生成 `.ics` 文件即可被所有主流日历软件导入
- **自动兼容**：Thunderbird、KDE Calendar、GNOME Calendar、Evolution、Nextcloud、Apple Calendar、Google Calendar、Outlook
- **RRULE 支持**：倒班是严格周期性的，RRULE 可将 365 个 VEVENT 压缩为 ~6 个
- **VALARM 支持**：日历提醒自动由系统日历 App 管理，无需自建通知系统

### ICS 生成方案

```rust
use icalendar::{Calendar, CalendarComponent, Component, Alarm, Event};
use chrono::{NaiveDate, NaiveDateTime, FixedOffset};

fn generate_shift_ics(
    start: NaiveDate,
    end: NaiveDate,
    config: &ShiftConfig,
) -> Calendar {
    let mut cal = Calendar::new();
    cal.name("倒班助手 - 排班表");
    cal.timezone("Asia/Shanghai");

    for (shift_type, days) in group_by_shift_type(start, end, config) {
        let mut event = Event::new();
        event.summary(&format!("{}班", shift_label(shift_type)));
        event.description("倒班助手 · 自动生成排班");
        // RRULE: FREQ=DAILY;INTERVAL=42（42天循环）
        // DTSTART 为第一个该班次的日期
        event.starts(start_datetime);
        event.ends(end_datetime);
        event.add_property("RRULE", "FREQ=DAILY;INTERVAL=42");

        // VALARM
        if let Some(alarm_time) = config.alarms.get(&shift_type) {
            let mut alarm = Alarm::display(
                &format!("{}班提醒", shift_label(shift_type)),
                &format!("-PT{}H{}M", alarm_time.hour, alarm_time.minute),
            );
            event.alarms.push(alarm);
        }

        cal.push(event);
    }
    cal
}
```

### CalDAV 同步（Phase 2 后期）

- 协议：CalDAV (RFC 4791) over HTTPS
- 客户端库：`reqwest` + 手写 XML body（CalDAV XML 较简单）
- 目标：Nextcloud Calendar / Radicale / Baikal
- 操作：PROPFIND 查询、PUT 上传、DELETE 删除

## C.7 Linux Desktop 技术选型

### KDE Plasma Widget

- 语言：QML (Qt Modeling Language)
- 数据源：DBus 服务 (`com.simpleshift.ShiftDaemon`) 或文件监控 (~/.local/share/shift/current.json)
- 显示内容：今日班次标签（彩色大字）、班组名、距休倒计时
- 刷新：系统启动 + 跨天 DBus 信号

### Waybar 模块

- Waybar 通过执行命令并读取 stdout JSON 来渲染模块
- `banban waybar` 输出 JSON：`{"text": "🌙 夜", "class": "night", "tooltip": "夜班 · 一值 · Day 12/42 · 距休 2 天"}`
- 支持 `--lang en/zh` 切换语言
- Waybar 显示文字可通过 `~/.config/banban/config.toml` 的 `[display]` 段自定义
- 配置：Waybar config.jsonc 中添加 `"custom/banban": {"exec": "banban -l zh waybar", "interval": 3600, "return-type": "json"}`

### DBus 服务

- 框架：`zbus`（纯 Rust、异步、Tokio 集成）
- 服务名：`com.simpleshift.ShiftDaemon`
- 接口：`/com/simpleshift/Shift` — GetTodayShift / GetUpcomingRest / ShiftChanged signal
- 启动：systemd user service 或 KDE autostart

### Local HTTP API

- 框架：`axum`（轻量、高性能、Tokio 生态）
- 端口：`11451`（非特权端口）
- 格式：JSON
- 用途：脚本消费、自动化、curl 调试

## C.8 不推荐的技术

| 技术 | 原因 |
|------|------|
| GTK | 太复杂、与 KDE Plasma 风格不一致、Rust 绑定不够成熟 |
| Slint | 小众、AI 支持弱、生态不完整 |
| Electron | 太重、内存占用高、倒班信息不值得一个完整浏览器 |
| Flutter Desktop | 维护爆炸、桌面端体验不如原生 Widget |
| Kotlin Multiplatform | AI 支持弱、iOS 调试复杂、与 Linux 生态不兼容 |
| Go | Rust 更适合 FFI + WASM + 嵌入场景 |

## C.9 开发工具链

```
shift-core/          ← Rust workspace（主要工作区）
  ├── Cargo.toml
  └── crates/

flutter/             ← Flutter 移动端（保留，Phase 4 接入 Rust FFI）
  └── lib/

~/.config/shift/     ← CLI 配置文件
  └── config.toml

~/.local/share/shift/ ← 数据目录（ICS 输出、缓存等）
  └── my_shift_schedule.ics
```

### 常用命令

```bash
# Rust
cargo test                        # 运行全部 Rust 测试
cargo build --release             # Release 构建
cargo run -- today                # CLI 测试
cargo run -- export --ics         # ICS 导出测试

# Flutter（Phase 4 接入 Rust 后）
flutter pub run build_runner build  # FFI 绑定重新生成
flutter test                        # Flutter 测试
flutter build apk                   # Android 构建
```

## C.10 一句话总结

👉 **Rust Domain + ICS/CalDAV 协议 + CLI 自动化 + Flutter 移动 UI + Plasma Widget 桌面**

这是目前倒班助手作为"个人时间操作系统"的最优技术组合：核心稳定、协议标准、平台覆盖广、维护成本低、AI 支持极好。