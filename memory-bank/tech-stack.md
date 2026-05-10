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
 │    ├── home/
 │    ├── calendar/
 │    ├── settings/
 │
 ├── viewmodel/
 │
 ├── data/
 │    ├── datastore/
 │    ├── model/            # 数据库实体、持久化扩展模型
 │
 ├── domain/
 │    ├── model/            # 核心业务模型（如 ShiftType/ShiftInfo）
 │    └── shift_calculator.kt
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

## 9. 当前进度与后续建议

已完成（阶段 1-9）：
1. 搭项目（Compose 模板）✅
2. 做首页（班组下拉框 + 今日班次 + 进度）✅
3. 实现"倒班计算核心逻辑"（含班组偏移支持）✅
4. 接入日历 UI（7×7 网格 + 上月/下月切换）✅
5. 班组切换 + 月度统计 ✅
6. 设置页（自定义倒班规则 + DataStore 持久化 + Navigation Compose 导航）✅
7. 日历提醒（Calendar Provider 本地日历日程 + 每班次独立时间 + 系统提醒 + 跨品牌兼容）✅

全部规划功能已完成，应用功能完整，单元测试全部通过。