# tech-stack.md

## 1. 设计目标

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

全部规划功能已完成，应用功能完整，单元测试全部通过（BUILD SUCCESSFUL）。
V2 UI 设计系统已实施，设置页已拆分重构。

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