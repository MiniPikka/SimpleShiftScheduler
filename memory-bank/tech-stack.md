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