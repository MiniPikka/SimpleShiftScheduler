# 倒班助手 (SimpleShiftScheduler)

一个专为轮班制工作者设计的 Android 应用，帮助你轻松追踪和规划倒班安排。

## 功能特性

### 核心功能

- **首页仪表盘** — 一眼看到今日班次、当前班组、周期进度、牛马指数（工作强度）
- **月历视图** — 7×7 网格日历，不同班次类型用不同颜色区分，支持月份切换与班组切换
- **自定义排班规则** — 两步向导式编辑器：自由编辑班次序列和起始参考日期
- **多班组支持** — 内置 6 个班组，切换班组自动偏移排班相位
- **日历提醒** — 通过系统 Calendar Provider 写入日程提醒，兼容小米/华为/OPPO/Vivo/三星，重启自动恢复，Material3 TimePicker 时钟表盘设置
- **月度统计** — 查看当月每种班次的天数分布

### 差异化功能

- **拼假神器** — 结合倒班表 + 中国法定节假日（含调休），自动分析最佳请假方案（请最少假、连休最久），按综合评分排序
- **同事模式** — 输入两个人班组，自动计算下次同时休息日期和共同休息天数，支持生成分享长图（含二维码）发送微信/QQ
- **倒班津贴计算器** — 设置各班次补贴金额，自动统计当月津贴总额，支持"多上 X 天某班次"假设分析
- **桌面小组件** — 4×1 桌面 Widget，无需打开 App 即可查看今日班次、距休天数，每小时自动刷新

### 设计系统

- **深色/浅色双主题** — 自动跟随系统深色模式，Design Token 统一管理颜色/字体/圆角
- **底部导航栏** — 首页/日历/我的三 Tab 导航，我的页集中管理规则、提醒、津贴、拼假、同事模式入口
- **V3 首页** — 大卡片 Hero Banner + 距休倒计时 + 月度概览 + 功能枢纽 + 情境化消息

## 班次类型

| 类型 | 日历颜色 |
|------|----------|
| 早班 | 橙色 |
| 中班 | 蓝色 |
| 休息 | 绿色 |
| 夜班 | 紫色 |
| 学习 | 浅黄 |

## 技术栈

- **语言** — Kotlin 1.9.24
- **UI** — Jetpack Compose + Material3 1.2.x
- **架构** — MVVM (Model-View-ViewModel)
- **状态管理** — Kotlin StateFlow
- **数据持久化** — DataStore Preferences
- **日历集成** — Android Calendar Provider
- **桌面小组件** — Jetpack Glance
- **二维码** — ZXing 3.5.3
- **导航** — Navigation Compose
- **测试** — JUnit 4 + Robolectric

## 构建要求

- Android Studio Hedgehog (2023.1.1) 或更新版本
- Gradle 8.4
- Android Gradle Plugin 8.2.0
- Compose Compiler 1.5.14
- Compose BOM 2024.04.00
- compileSdk / targetSdk: 34
- minSdk: 24 (Android 7.0)
- JDK 17

## 快速开始

```bash
# 克隆仓库
git clone git@gitee.com:MiniPikka/simple-shift-scheduler.git

# 用 Android Studio 打开项目目录，等待 Gradle 同步完成后运行
```

## 项目结构

```
com.simpleshift.scheduler/
├── MainActivity.kt                    # 应用入口，NavHost 路由 + 状态共享
├── calendar/                          # 日历提醒模块
│   ├── CalendarEventManager.kt        # Calendar Provider CRUD 封装
│   ├── CalendarResolver.kt            # ContentResolver 抽象（可测试）
│   └── CalendarSyncManager.kt         # 三流 combine 自动同步 + Mutex 防竞态
├── data/repository/
│   └── SettingsRepository.kt          # DataStore 持久化（规则/提醒/日程ID/津贴配置）
├── domain/                            # 核心业务逻辑（纯 Kotlin，零 Android 依赖）
│   ├── shift_calculator.kt            # 排班计算算法
│   ├── calendar_generator.kt          # 42 格月历网格生成
│   ├── shift_metrics.kt              # 月度统计与趋势指标
│   ├── leave_optimizer.kt            # 拼假神器算法（间隙桥接 + 评分排序）
│   ├── colleague_mode.kt             # 同事模式算法（双班组交叉对比）
│   ├── salary_calculator.kt          # 倒班津贴计算
│   ├── holiday_data.kt               # 中国法定节假日内置数据
│   ├── qr_code_generator.kt          # 二维码生成（ZXing）
│   ├── widget_data.kt                # 桌面小组件数据计算
│   └── model/                         # 领域模型（18 个数据类）
├── ui/                                # Compose UI
│   ├── home/                          # 首页（V1/V2/V3 三代共存，编译时常量切换）
│   │   └── components/                # 独立 UI 组件（18 个，含 V2/V3 变体）
│   ├── calendar/CalendarScreen.kt     # 日历页（内联统计卡 + 班组切换）
│   ├── settings/                      # 设置页
│   │   ├── ShiftRuleEditorScreen.kt   # 两步向导式规则编辑器
│   │   └── AlarmSettingsScreen.kt     # 提醒时间设置（Material3 TimePicker）
│   ├── profile/ProfileScreen.kt       # 我的页（功能入口菜单）
│   ├── leave_optimizer/               # 拼假神器页
│   ├── colleague_mode/                # 同事模式页 + 分享图 Layout
│   ├── salary_predictor/              # 倒班津贴页
│   ├── theme/                         # Design Token（Color/Type/Shape/Theme）
│   └── common/CommonComponents.kt     # 共用组件（TeamDropdown 等）
├── viewmodel/                         # ViewModel 层（8 个 ViewModel）
├── widget/                            # 桌面小组件（Glance）
│   ├── ShiftWidget.kt                 # GlanceAppWidget 实现
│   └── ShiftWidgetReceiver.kt         # 系统 BroadcastReceiver
└── util/                              # 工具类
    ├── ShareImageRenderer.kt          # ComposeView 离屏渲染分享图
    └── ShiftLabelMapper.kt            # 班次类型 → 中文映射
```

## 权限

| 权限 | 用途 |
|------|------|
| `READ_CALENDAR` | 读取系统日历账户和日程 |
| `WRITE_CALENDAR` | 写入日历提醒日程 |

## 默认排班规则

默认周期为 42 天，参考起始日为 2025-12-15（可自定义），6 个班组之间相位偏移 7 天。

```
早早中中休夜夜休休早早中中休夜休休休早早中休夜夜休休休早中中休夜夜休休学学学学学休休
```

## 测试

```bash
# 运行全部单元测试（150+ 用例）
./gradlew testDebugUnitTest

# 运行单个测试类
./gradlew testDebugUnitTest --tests "com.simpleshift.scheduler.domain.ShiftCalculatorTest"
```

## License

MIT
