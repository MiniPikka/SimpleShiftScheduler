## 2026-07-19：交接班跨天修正 + ICS 夜班日期修正（Rust / Flutter / HarmonyOS 三端）✅

### 问题（用户实报）

7-19 夜班（一值）实际 7-18 晚 22:00 上岗、7-19 早 08:00 下班。旧交接班按日历日查前序/后继，导致：
- 夜班显示的"接三值的班（中）"错误——三值是 7-19 中班，在你下班后才上岗；实际 7-18 22:00 接的是 **7-18 中班（二值）** 的班
- 中班显示的"一值接我的班（夜）"错误——22:00 来接的是 **7-20 夜班（二值）**；一值那时已在家休息
- 同一个班（18 日 22:00 → 19 日 08:00）期间卡片在 0 点翻页，且 22:00–24:00 显示的是当天早上已结束的那个班的信息

**根因**：班次按**结束日**标记，中→夜 交接（~22:00）跨日历日。夜班提醒 2026-05-13 已按此约定修正（提前一天提醒），交接班和 ICS 导出漏改。

### 修正（约定统一为"按结束日标记"）

| 端 | 变更 |
|----|------|
| Rust `shift-algorithm` | `shift_handover()` 跨天查找：本班跨午夜（夜班）→ 前序查 date−1；后继班跨午夜（中班的后继是夜班）→ 后继查 date+1；早班不受影响。新增 `crosses_midnight()`（自定义时间 end ≤ start 即跨午夜，否则用默认 早08–16/中16–22/夜22–08），自定义时间不跨午夜时自动退回同日查找。返回值从 `Option<(u32,u32)>` 改为 `Option<ShiftHandover>`（含交接时刻双方班次类型），根除 4 个消费方（today/waybar/waybar-popup/TUI/serve）"按今天反查对方班次"的二次错误 |
| Rust `shift-export` | 夜班事件 DTSTART 从"标记日 22:00"改为"前一日 22:00 → 标记日 08:00"；早/中班时间对齐为 08:00–16:00 / 16:00–22:00（消除原 07–15/14–22 的重叠），VALARM start_min 同步 |
| Flutter Dart | `findShiftHandover()` 同样跨天修正，返回 record `(predTeam, predShift, succTeam, succShift)`；`home_state.dart` 改用返回的班次类型（移除按今天反查）；`colleague_mode_screen.dart` 适配 |
| HarmonyOS | `shiftHandover()` 同样修正，返回新接口 `ShiftHandoverResult`（ShiftModels.ets）；`HomeScreen.ets` 适配；`verify-harmony.sh` 字段访问适配 |

### 验证

- Rust：57 lib tests（新增 5：三班次真实日期用例 + 120 天×6 班组交接双方对称性不变量 + 非跨午夜自定义时间回退）+ 21 doctests 全过，clippy 零警告
- shift-export：11 tests 全过（夜班事件日期断言 + 防回归断言）
- Flutter：115 tests 全过（新增 5），analyze 零新增问题
- HarmonyOS ↔ Rust 交叉验证：185/185 PASS（verify-harmony.sh）
- 实测 `banban -t 1 today`（7-19 夜班）：接二值（中班）· 四值接我的班（早班）✓ 与物理交接一致

### 已知遗留（未改，记录在案）

- `banban notify`：夜班提醒仍在标记日 21:45 触发（物理上相当于给"次日夜班"提醒，连班时巧合正确； Flutter 端已正确提前一天）。如需对齐需改 systemd timer 语义，另行评估
- 首页"今天"概念仍按日历日：夜班下班当天（08:00 后）和上岗当晚（22:00 后）显示的仍是标记日班次。改为"当前进行中的班"属更大产品决策，影响所有视图/小组件，未动

---

## 2026-06-30：HarmonyOS DevEco Studio 构建修复 + 双系统环境

### HarmonyOS 构建错误修复 ✅

在 Windows 11 + DevEco Studio 26 环境中实际编译 HarmonyOS 项目，修复了 22 个 ArkTS 编译错误（SDK 26 严格模式）。

**提交 `b89fc77`**：修复鸿蒙构建错误并清理警告

| 修复项 | 详情 |
|--------|------|
| targetSdkVersion 格式非法 (00306042) | `"1"` → `"5.0.0(12)"` |
| AppScope 目录缺失 | 创建 `app.json5` + `string.json` + `app_icon.png` (216×216) |
| ArkTS 编译错误 (22 个) | `Array.from`/解构/`Flex space`/`ForEach const` 等不兼容写法 |
| Select.fontSize | → `font({ size })` (SDK 26 API 变更) |
| TextAlign.Right | → `End` (ArkTS 对齐枚举) |
| Circle.fill | → `backgroundColor` (SDK 兼容) |
| SettingsStorage | 全量 try-catch 异常处理 |
| 交接班措辞 | "正在上X班" → "今天X班" |
| .gitignore | 排除鸿蒙构建产物 |

**提交 `2da6e50`**：升级 hvigor modelVersion

| 文件 | 旧 | 新 |
|------|----|----|
| `hvigor/hvigor-config.json5` | modelVersion 5.0.0, plugin 5.0.0 | modelVersion 6.0.0, plugin 6.26.1 |
| `oh-package.json5` | modelVersion 5.0.0 | modelVersion 6.0.0 |

### 开发环境：KVM/QEMU VM → 双系统 ✅

**背景**：KVM/QEMU Windows 虚拟机网络配置困难（UFW 阻止 libvirt NAT 规则注入、virbr0 NO-CARRIER、Windows DHCP 请求被丢弃）。决定改用双系统方案。

**磁盘分区调整**：

| 分区 | 之前 | 之后 |
|------|------|------|
| nvme0n1p1 (EFI) | 1G | 1G（不变） |
| nvme0n1p2 (Linux btrfs) | 475.9G | 176G（btrfs 缩到 175G） |
| nvme0n1p3 (Windows NTFS) | — | 299.9G（新建） |

**操作步骤**：
1. 清理 VM 相关文件和包（~57G）：qemu-full、libvirt、virt-manager 等 159 个包 + VM 镜像
2. `btrfs filesystem resize 175G /` 在线缩小文件系统
3. `sfdisk` 重建 GPT 分区表，缩小分区2 + 创建分区3（Microsoft Basic Data）
4. Ventoy U盘安装 Windows 11
5. `bootctl install` 修复 systemd-boot 引导（Windows 可能覆盖 EFI 启动项）

**恢复脚本**：`fix-boot.sh`（放在 Ventoy U盘），Arch live USB 环境中运行

### 后续待办

- 在 DevEco Studio 中继续构建，验证是否还有编译错误
- 跑 hypium 测试
- 生成 HAP 包

---

## 2026-06-28：HarmonyOS 算法交叉验证 + 6类Bug修复

### HarmonyOS ArkTS 算法 ↔ Rust 交叉验证 ✅

**方法**：HarmonyOS 的 7 个算法文件均为纯 TypeScript（无 @State/@Component/@kit 平台依赖），可在 Node.js + tsx 中运行。通过 `banban serve` HTTP API 和 `banban --json` CLI 生成 Rust 真值，与 HarmonyOS ArkTS 算法输出逐字段对比。验证脚本 `scripts/verify-harmony.sh` 可重复运行，185 个测试用例覆盖 8 个维度。

**验证维度（185 tests）**：getShiftInfo（8日期×4字段）、shiftHandover（4日期×2字段）、多Team今天（6 team×3字段）、月历生成（4月×team×3维度）、月度统计（3月×team×5班次）、拼假策略（Top10×8字段）、同事模式（3配对×4字段）、节假日数据（5日期）。

### 修复 6 类 Bug（4 文件）

| 文件 | Bug | 修复 |
|------|-----|------|
| `ShiftMetrics.ets` | `daysUntilNextRest` off-by-one（比 Rust 多1） | 改 count 模式：从 `return i`(i≥1) 改为 count 从0递增，对齐 Rust 语义（明天休息=0） |
| `LeaveOptimizer.ets` | leaveLen 从1开始（应从2）、restBefore/restAfter 缺周末判断、score 未归一化、holiday 权重错(1应2)、slice(0,10) 丢策略、efficiency/score 多余 round | 完全重写对齐 Rust `find_best_leave_plans`：预计算 restBefore/restAfter 用 isOff、minLeaveDays=2、score 归一化（max_efficiency/max_break/max_family_bonus）、holiday*2、返回全部、排序加 break_start tiebreaker |
| `ColleagueMode.ets` | countIn30/60 off-by-one（`i<=30` 应 `i<30`）、next_date 排除今天（`i>0` 条件导致今天共同休息时返回错误日期） | `i<30`/`i<60` 对齐 Rust `diff<30`；去掉 `i>0` 条件，`nextDate` 包含今天 |
| `HolidayData.ets` | 2026 中秋10月8日(应9月25日)、春节2月17日(应2月15日)、元旦3天(应1天)、清明3天(应2天)、劳动节调休4月26日(应5月9日)、2027 多处错 | 重写对齐 Rust `holiday-engine` 2026/2027 数据；数据结构从数组改 Map（确保调休覆盖节假日的 HashMap 行为） |

### hypium 单元测试

新增 `harmony/entry/src/test/Algorithm.test.ets` + `List.test.ets`，覆盖 6 个算法模块（ShiftCalculator/ShiftMetrics/CalendarGenerator/LeaveOptimizer/ColleagueMode/HolidayData），约 30 个用例。需在 DevEco Studio 中运行（HarmonyOS 运行时）。

### 后续待办

- 恢复 VM 环境（libvirtd 当前 inactive，harmony-dev VM 配置不存在）→ 安装 DevEco Studio 5.0+
- 在 DevEco 中构建 HarmonyOS 项目，验证编译和 UI
- 模拟器/真机运行验证

---

## 2026-06-26：交接班算法修正 + Waybar 升级 + 同事模式增强

### 交接班算法修正（Rust / Flutter / HarmonyOS 三端）✅

**根因**：之前的 `successor_team_id` / `predecessor_team_id` 按班组编号 ±1 计算，与实际交接班完全无关。真实交接班是同一天内不同班次类型之间的：夜 → 早 → 中 → 夜。

**修正**：
- Rust：新增 `ShiftCycleConfig::shift_handover(date, team_id)` — 遍历所有班组，找到今天上前序/后继班次类型的班组
- Flutter：新增 `findShiftHandover()` 函数，首页 `_ShiftRelayCard` 双向显示（← 接X值的班(夜) · Y值接我的班(中) →），休/学日隐藏卡片
- 同事模式新增 `_ShiftRelayRow`，并排显示双方班次和交接关系
- i18n：`shiftRelayStatus` 从"正在上X班"改为"今天X班"
- 14 新 Rust 测试 + 全部 128 tests pass

### Waybar 升级（对齐 KDE Plasmoid）✅

**之前**：`banban waybar` 输出 3 字段 JSON，tooltip 仅 1 行。

**现在**：
- Tooltip 丰富为 6 行：班次+团队+日期 / 统计（周期+距休+连续上班）/ 交接班信息 / 7 天周预览
- 新增 `banban waybar-popup` 命令 —— ANSI 彩色终端弹窗，KDE 风格布局
- 新增 `scripts/banban-waybar-popup.sh` —— foot→alacritty→kitty→xterm 终端降级链
- 用户 Waybar 配置已安装（`~/.config/waybar/config.jsonc` + `style.css`），Catppuccin 配色
- Waybar 功能与 KDE Plasmoid 完全对齐（除了 KDE 原生弹窗 vs 终端弹窗的技术差异）

### Android 构建环境搭建 ✅

从零搭建完整构建链：JDK 21、Android SDK（platform-tools、build-tools 34、platform 34-35、NDK 28、CMake）、Flutter 3.44.0。Gradle 镜像（阿里云/腾讯云优先）、Kotlin 2.2.20、禁用 `checkDebugDuplicateClasses`。首次构建 44s，后续 9s。

### CLI 命令总数: 17 → 18 (新增 waybar-popup)

---

## 2026-06-23：KVM/QEMU Windows VM + LLM API 双配置

### KVM/QEMU Windows 虚拟机配置 ✅

**背景**：HarmonyOS 开发需要 DevEco Studio（仅 Windows/macOS），用户在 Arch Linux 上通过 KVM/QEMU 虚拟机解决。

**安装的软件包**：

| 包 | 用途 |
|----|------|
| `qemu-full` | 完整 QEMU 虚拟化 |
| `virt-manager` | 图形化虚拟机管理 |
| `libvirt` | 虚拟化 API |
| `edk2-ovmf` | UEFI 固件 |
| `dnsmasq` | NAT 网络 DHCP |
| `virt-viewer` | 轻量级 VM 控制台 |

**虚拟机配置**：

| 配置项 | 值 |
|--------|-----|
| 名称 | `harmony-dev` |
| 内存 | 4GB（8GB 导致 15GB 宿主机 OOM） |
| CPU | 4 核 |
| 磁盘 | 100GB (qcow2) |
| 机器类型 | Q35 |
| 显示 | Spice (127.0.0.1:5900) |
| 网络 | NAT (192.168.122.0/24) |
| ISO | `Win10_22H2_Chinese_Simplified_x64v1.iso` (5.7GB) |

**关键发现**：
- `bridge-utils` 包已从 Arch 移除，桥接支持内置在 `iproute2` 中
- VirtIO 驱动从 fedorapeople.org 下载极慢（无国内 CDN 镜像）
- Windows ISO 需要浏览器交互下载（命令行获取 CDN 链接会 403）
- `sudo -A` 配合 `SUDO_ASKPASS=/tmp/askpass.sh`（zenity 弹密码框），重启后需重建

**VM 管理命令**：

```bash
virsh start harmony-dev        # 启动
virsh shutdown harmony-dev     # 优雅关机
virsh destroy harmony-dev      # 强制关闭
virt-viewer harmony-dev        # 打开控制台
virt-manager                   # 图形管理界面
```

### LLM API 双配置可切换 ✅

**需求**：在 DeepSeek 和 MiMo（小米）两个 LLM API 之间灵活切换。

**配置方案**：

| API | 端点 | 模型 |
|-----|------|------|
| DeepSeek | `https://api.deepseek.com/anthropic` | `deepseek-v4-pro[1m]` |
| MiMo | `https://token-plan-sgp.xiaomimimo.com/anthropic` | `mimo-v2.5-pro` |

**切换脚本**：`~/switch-llm.sh`

```bash
source ~/switch-llm.sh deepseek  # 切换到 DeepSeek
source ~/switch-llm.sh mimo      # 切换到 MiMo
source ~/switch-llm.sh status    # 查看当前状态
```

**关键发现**：
- MiMo API 可直连，无需本地代理（mimo-proxy）—— Claude Code 能容忍 `/v1/models` 端点 404
- 配置存储在 `~/.bashrc.llm-current`，`.bashrc` 自动加载
- MiMo 代理（localhost:18923）保留备用但不再必需
- `~/.bashrc` 启用了 `noclobber`，覆盖文件需用 `>|` 而非 `>`

---

## 2026-06-06：Flutter Bug 修复 + 工具链全面升级

### Bug 修复：提醒设置加载失败 ✅

**根因**：`AlarmSettingsNotifier` 使用 `StateNotifier` + `FutureProvider.whenData` 存在竞态。App 启动时 `hiveRepoProvider` 尚未解析（`AsyncLoading`），`whenData` 对 `AsyncLoading` 是空操作，导致 Hive 中保存的提醒设置永远无法加载——所有提醒静默丢失。

**三个 Bug 及修复：**

| Bug | 文件 | 根因 | 修复 |
|-----|------|------|------|
| 设置加载失败 | `alarm_settings_notifier.dart` | `whenData` 对 `AsyncLoading` 空操作 | 改为 `AsyncNotifier`，`await ref.read(hiveRepoProvider.future)` 确保 repo 就绪 |
| updateAlarmTime 竞态 | 同上 | 同一竞态导致保存静默失败 | 缓存 `_repo` 引用 + state 先更新 UI 再持久化 |
| 通知每天重复 | `notification_service.dart:89` | `matchDateTimeComponents: DateTimeComponents.time` | 改为 `null` |

**连带修复：**
- `main.dart`：`_performSync` 提取 `_doSync` 消除重复代码；`AsyncValue.valueOrNull` → `.value`
- `home_state.dart`：`_ref.read(alarmSettingsProvider).valueOrNull` → `.value` + null-safe
- `alarm_settings_screen.dart`：适配 `AsyncNotifierProvider`，处理 loading/error 三态

**验证**：110/110 测试通过，真机验证提醒设置持久化正常。

### 工具链全面升级 ✅

**Flutter/Dart**：3.44.0 / 3.12.0（已是最新 stable）

**Riverpod 2.x → 3.x 迁移（核心变更）：**

| 变更 | 说明 |
|------|------|
| `StateNotifierProvider` → `NotifierProvider` | 4 个 provider 全部迁移 |
| `StateNotifier` → `Notifier` | `Ref _ref` 构造注入 → 继承 `ref`；构造函数 → `build()` |
| `StateProvider` → `NotifierProvider` | `selectedTeamProvider` |
| `.valueOrNull` → `.value` | Riverpod 3.x `AsyncValue.value` 返回 `ValueT?` |
| `mounted` 移除 | Notifier 无 `mounted`，延迟回调改为无条件执行 |
| `await whenData` bug 修复 | `salary_config_notifier.dart` 移除对 `AsyncValue` 的错误 `await` |

**依赖版本变更：**

| 包 | 旧 | 新 |
|----|----|----|
| `flutter_riverpod` | 2.6.1 | **3.3.1** |
| `freezed_annotation` | 2.4.4 | **3.1.0** |
| `freezed` | 2.5.8 | **3.2.5** |
| `go_router` | 17.2.3 | 17.3.0 |
| `json_annotation` | 4.9.0 | 4.12.0 |
| `json_serializable` | 6.9.5 | 6.14.0 |
| `build_runner` | 2.5.4 | 2.15.0 |
| `permission_handler` | 11.4.0 | **12.0.3** |
| Dart SDK constraint | `^3.10.7` | `^3.12.0` |

**移除未使用依赖**：`riverpod_annotation`、`riverpod_generator`（从未使用代码生成）

**改动文件汇总：**

| 文件 | 改动 |
|------|------|
| `pubspec.yaml` | SDK + 全部依赖版本升级，移除未使用依赖 |
| `lib/features/home/alarm_settings_notifier.dart` | 重写：`StateNotifier` → `AsyncNotifier` |
| `lib/features/home/home_state.dart` | 迁移 3 个 provider 到 `Notifier` API |
| `lib/features/settings/shift_rule_notifier.dart` | 迁移到 `Notifier` API |
| `lib/features/salary_predictor/salary_config_notifier.dart` | 迁移到 `Notifier` API + 修复 await bug |
| `lib/core/services/notification_service.dart` | `matchDateTimeComponents` → `null` |
| `lib/features/alarm_settings/alarm_settings_screen.dart` | 适配 `AsyncNotifierProvider` |
| `lib/main.dart` | 适配 `AsyncValue` API + `_doSync` 消除重复 |

**验证**：`flutter analyze` 零新增 issues，`flutter test` 110/110 通过，真机安装验证正常。

---

## 2026-06-02：Desktop Widgets 商店上架准备

### KDE Store + GNOME Extensions 提交材料准备 ✅

两个 Desktop Widget 的商店提交材料全部准备就绪。

**新增文件汇总：**

| 文件 | 用途 |
|------|------|
| `plasma/banban-shift@simpleshift.scheduler/LICENSE` | MIT 许可证 |
| `plasma/banban-shift@simpleshift.scheduler/CHANGELOG.md` | 版本历史 (v1.0.0) |
| `plasma/package.sh` | KDE 打包脚本 → `banban-shift.plasmoid` (8KB) |
| `plasma/STORE_DESCRIPTION.md` | KDE Store 中英文描述 |
| `plasma/SUBMISSION_CHECKLIST.md` | KDE 提交清单 |
| `gnome/banban-shift@simpleshift.scheduler/LICENSE` | MIT 许可证 |
| `gnome/banban-shift@simpleshift.scheduler/CHANGELOG.md` | 版本历史 (v1.0.0) |
| `gnome/banban-shift@simpleshift.scheduler/STORE_DESCRIPTION.md` | GNOME Extensions 中英文描述 |
| `gnome/package.sh` | GNOME 打包脚本 → `banban-shift.zip` (8KB) |
| `gnome/SUBMISSION_CHECKLIST.md` | GNOME 提交清单 |
| `package-widgets.sh` | 统一打包脚本 (KDE + GNOME) |

**打包验证：**

```bash
./package-widgets.sh
# KDE:   plasma/banban-shift.plasmoid (8KB, 6 files)
# GNOME: gnome/banban-shift.zip (8KB, 6 files)
```

**待用户操作：**
1. 截图（1920×1080）：面板 compact 视图 + 弹出 popup 视图
2. KDE Store：注册 identity.kde.org → 上传 .plasmoid
3. GNOME Extensions：注册 gitlab.gnome.org → 上传 .zip

---

## 2026-06-01～02：Desktop Integration — GNOME Shell Extension ✅ + KDE Plasma 6 Plasmoid

### 决策背景

Flutter Linux Desktop（2026-05-25）是完整 App 窗口的"暴力移植"，不适合桌面日常使用场景。决定转向原生 Desktop Widgets 策略。

### GNOME Shell 50 Extension ✅（已验证）

- 面板显示：🟠早（emoji + 短标签）
- 点击弹出菜单：今日班次详情 + 距休/连续上班 + 7 天周预览 + 刷新按钮
- 60s 定时刷新，`Gio.Subprocess` 异步调用 banban CLI
- GNOME 50 真机验证通过

GNOME 50 踩坑：
1. `GObject.registerClass` 不自动创建自定义信号 → 改用回调函数传参
2. PanelMenu.Button 菜单为空时不弹出 → 构造时预填占位项
3. `shell-version` 需显式包含 "50"
4. Wayland 下 `gnome-extensions disable/enable` 不重载 JS 代码 → 需注销重登

### KDE Plasma 6 Plasmoid（✅ 全功能正常）

- 面板显示：🟠早（emoji + 短标签）+ 悬停 tooltip + 手型光标
- 点击弹出：`PlasmaExtras.Representation` 标准弹窗（头卡片 + 统计行 + 7 天周预览 + 刷新按钮）
- 数据获取：`XMLHttpRequest` → `banban serve` HTTP API（localhost:11451）
- 5min 定时刷新（静默刷新不闪 UI），server_down 错误提示 + 自动重试

弹窗问题解决（2026-06-02）：
- 根因：之前用 `QtQuick.Controls.Popup`，与 Plasma 6 面板 popup 系统不兼容，内容不渲染
- 方案：参考 KDE 官方 plasmoid（vault、systemmonitor），改用 `PlasmoidItem` 内建 `expanded` + `fullRepresentation` 机制
- 关键：`compactRepresentation` 中 `onClicked: root.expanded = !root.expanded`，无需手动管理 Popup 生命周期

后续修复的 bug：
1. `PlasmaComponents` → `PlasmaComponents3`（Plasma 6 命名规范）
2. `state` 属性名遮蔽 QML 保留字 → 改为 `fetchState`
3. 面板图标无鼠标手势 → 加 `cursorShape: Qt.PointingHandCursor`
4. 每次刷新闪 "加载中..." → 只在首次加载时显示，静默刷新保持数据可见
5. HTTP 400 错误只显示 "HTTP 400" → 解析响应 body 展示服务端错误信息
6. 清理死代码 `banban_wrapper.sh`（旧 subprocess 方案遗留）

### banban CLI 改进

- 新增 `GET /week` HTTP 端点（serve.rs +52行）
- systemd user service：`banban-serve.service`（开机自启 HTTP API）

### systemd 集成

```ini
# ~/.config/systemd/user/banban-serve.service
[Service]
Type=simple
ExecStart=/home/zxl/.cargo/bin/banban serve
Restart=on-failure
```

### 架构演进

初版尝试 Plasma5Support.DataSource（executable engine）subprocess 方案，遇到三类根本问题后改为 HTTP：
1. plasmashell 的 PATH 不包含 `~/.cargo/bin`，导致 banban 找不到
2. DataEngine 按空格拆分参数直接传 argv（不经过 shell），无法使用 `sh -c` 包装
3. `PlasmaCore.Units`/`Theme` 在 Plasma 6.6 中不可用，需改用 `Kirigami`

**最终架构**：QML `XMLHttpRequest` → `banban serve` HTTP API（localhost:11451）。零 subprocess、零 PATH 依赖、零 DataEngine 兼容层。

### banban CLI 改进

新增 `GET /week` 端点（`serve.rs` +52行）— 返回今日起 7 天周视图：
```json
{"team":"一值","days":[{"date":"2026-06-01","shift_type":"Morning","shift_label_zh":"早",...}]}
```
HTTP API 现共 7 个端点：/health /shift /shift/{date} /week /calendar /leave /colleague

### systemd 集成

新增 `banban-serve.service`（systemd user unit）— 开机自启 HTTP API 服务器。
`install.sh` 自动创建、enable、start。

### KDE Plasma 6 Plasmoid（✅ 已验证）

| 文件 | 用途 |
|------|------|
| `metadata.json` | KPackageStructure: Plasma/Applet, Id: com.simpleshift.banban |
| `contents/ui/main.qml` | XMLHttpRequest → localhost:11451/shift + /week, Kirigami UI |
| `install.sh` | 安装 plasmoid + systemd 服务 |

- 数据层：两个并行 XMLHttpRequest（/shift + /week），5 秒超时，自动重试
- UI：PlasmoidItem + compactRepresentation（emoji + 标签）+ fullRepresentation（头卡片 + 统计行 + 7 天周预览）
- 错误处理：server_down → "banban API 服务未启动" + systemctl 指引，transient → 5 秒自动重试最多 3 次
- 刷新：Timer 5 分钟

### GNOME Shell 45+ Extension

| 文件 | 用途 |
|------|------|
| `metadata.json` | UUID: banban-shift@simpleshift.scheduler, shell-version: [45,46,47] |
| `extension.js` | PanelMenu.Button + Gio.Subprocess + PopupMenu |
| `stylesheet.css` | 面板标签 + 弹出菜单样式 |

- 仍用 subprocess 方式（GNOME Shell 的 `Gio.Subprocess` 支持完整 argv 传递，无 Plasma 的 PATH/拆分问题）
- 60s 定时刷新

### 新增/修改文件汇总

| 新增（10 个） | 修改（5 个） |
|-------------|-------------|
| `plasma/.../metadata.json` | `CLAUDE.md` |
| `plasma/.../contents/ui/main.qml` | `memory-bank/architecture.md` |
| `plasma/README.md` | `memory-bank/progress.md` |
| `plasma/.../install.sh` | `memory-bank/implementation-plan.md` |
| `plasma/README.md` | `shift-core/cli/src/serve.rs` (+/week) |
| `gnome/.../metadata.json` | |
| `gnome/.../extension.js` | |
| `gnome/.../stylesheet.css` | |
| `gnome/.../install.sh` | |
| `gnome/README.md` | |

### 验证

- `plasmoidviewer -a` — 零 QML 错误，server 停/启状态切换正确
- Plasma 6.6.5 真机面板 — compact 显示🟠早，tooltip 正常，**弹窗内容完整渲染**（头卡片 + 统计 + 7 天周预览）
- `cargo test` — 109 + 7 doctest 全部通过
- `cargo clippy` — 零警告
- GNOME Extension：代码语法正确，待 GNOME 环境真机测试

---

## 2026-05-29：F-Droid 准备 + GitHub Releases CI

### 变更

- **移除 `supabase_flutter`**：死代码 stub，所有方法 throw UnimplementedError，零功能影响
  - 删除 `lib/core/services/supabase_service.dart`
  - `main.dart` 移除 import + init() 调用
  - `pubspec.yaml` 移除依赖
- **F-Droid fastlane 元数据**：`fastlane/metadata/android/en-US/`（title、description、changelog）
- **GitHub Actions 自动发布**：`.github/workflows/release.yml`
  - 触发：push tag `v*`
  - 构建链：Rust toolchain + cargo-ndk → FFI bridge (all ABIs) → Flutter APK
  - 发布：`softprops/action-gh-release@v2`，附带 APK + 自动生成 changelog
  - 签名：debug key（deferred，加了 release signing 注释）
- **F-Droid 元数据模板**：`fdroid/com.simpleshift.scheduler.yml`

### 发布工作流

1. 编辑 `pubspec.yaml` version（如 `1.3.0+3`）
2. commit → `git tag v1.3.0` → `git push && git push --tags`
3. CI 自动构建 + 创建 GitHub Release

### 待办

- 生成 release keystore，配置 GitHub Secrets 实现正式签名
- 提交 F-Droid MR 到 fdroiddata 仓库 — metadata 已就绪: `metadata/com.simpleshift.scheduler_cp.yml`
- 真机截图已就绪 ✅: `fastlane/metadata/android/en-US/images/phoneScreenshots/1-6.png`
- Tag 已创建 ✅: `app-v1.0.0`
- Push tag 并提交 MR 到 fdroiddata（`git push origin app-v1.0.0`）
- 添加 512x512 PNG icon 到 `fastlane/metadata/android/en-US/images/icon.png`

### Tag 命名规范

采用前缀区分产品：
- `app-vX.Y.Z` — Flutter APK 发布（F-Droid + GitHub Release）
- `cli-vX.Y.Z` — banban CLI 发布（crates.io + AUR）
- `v1.0` `v1.1.0` `v1.2.0` — Android 原版（历史，保留不动）
- `v0.1.x` — banban CLI 早期（历史，保留不动）

---

## 2026-05-25：Flutter Linux Desktop — 全功能迁移 ✅

### 目标达成

将 Flutter 移动端 App 迁移到 Linux 桌面，作为第一公民平台。Rust shift-core 继续作为唯一算法核心，Flutter 负责 UI 和平台集成。`banban` CLI 的已有功能（Waybar、systemd、DBus、通知、shell 补全）不重复实现。

### Phase 0：启用 Linux 桌面 + FFI 构建

- `flutter config --enable-linux-desktop` + `flutter create --platforms=linux .`
- 生成 `linux/` 目录（13 个文件：CMake + GTK3 runner + 插件注册）
- `cargo build --release` → `libshift_flutter_bridge.so`（750KB, x86_64 ELF）
- 窗口标题"倒班助手"，默认大小 960x700，最小 480x400

### Phase 0：平台适配守卫

| 文件 | 变更 |
|------|------|
| `calendar_service.dart` | `syncShiftEvents()` / `deleteAllEvents()` 非 Android 直接返回（MethodChannel 无 Linux handler） |
| `widget_service.dart` | `update()` 非 Android 直接返回（桌面小组件不存在） |
| `notification_service.dart` | Linux 使用 `LinuxInitializationSettings`（DBus `org.freedesktop.Notifications`） |
| `main.dart` | `Hive.init()` 在 Linux 上用 `$XDG_DATA_HOME/scheduler_cp`，不用 `~/Documents` |
| `main.dart` | 权限请求只在 Android/iOS 执行，Linux 跳过 |

### Phase 1：桌面 UI 适配

- **响应式断点**：`spacing.dart` 新增 `desktopBreakpoint = 720`、`desktopContentWidth = 900`
- **新文件**：`lib/core/utils/responsive.dart` — `isDesktopLayout(context)` + `contentMaxWidth(context)`
- **AppShell** 改造：`LayoutBuilder` → ≥720px 显示 `NavigationRail` 左侧栏，<720px 显示 `NavigationBar` 底部栏
- **4 个页面**（home/calendar/profile/alarm_settings）：`maxWidth` 从硬编码 600 → `contentMaxWidth(context)`
- **键盘快捷键**：Ctrl+1/2/3 切标签、Ctrl+Q 退出、Esc 返回 — 集成在 `AppShell` 中

### Phase 2：Linux 平台集成

- **新文件**：`lib/core/services/linux_calendar_sync.dart`
  - `sync()` — 通过 FFI `ffiGenerateIcs()` 生成 ICS → 写入 `~/.local/share/banban/shifts.ics`
  - `openWithDefaultApp()` — `xdg-open` 调用系统默认日历
  - `isSystemdTimerActive()` — 检查 `banban-ics.timer` 状态
- **`_performSync()`** 中：设置变更时自动触发 ICS 同步（Linux only）
- **Profile 页**：新增 Linux 专区 — "Export ICS"、"Open in Calendar"、"Auto-sync status"（FutureBuilder）
- **通知**：`flutter_local_notifications_linux` 通过 DBus libnotify 工作

### Phase 3：构建与分发

| 脚本 | 功能 |
|------|------|
| `build_rust_linux.sh` | 构建 Rust FFI `.so`，可选 `--run` 一键启动 |
| `build.sh` | 一体化构建：Rust FFI → Flutter Linux → `.so` 自动打包到 bundle |
| `package.sh` | 生成 `shiftmate-x86_64.tar.gz`（12MB），可选 AppImage（需 linuxdeploy） |
| `install_linux.sh` | 系统级安装到 `/usr/local`（二进制 + .so + 图标 + .desktop），`--uninstall` 清理 |

- **FFI 加载路径增强**：新增 3 条基于 `Platform.resolvedExecutable` 的路径，覆盖 bundle/AppImage/FHS 安装布局
- **应用图标**：`linux_icon.png`（256x256 PNG，深色生产风格）
- **桌面入口**：`shiftmate.desktop`（XDG 规范，`StartupWMClass=scheduler_cp`）

### Bug 修复

- **ICS 导出失败**：Rust FFI 返回的 JSON 中没有 `count` 字段 → `LinuxCalendarSync.sync()` 总是返回 0 → 显示"Check FFI bridge"
  - 修复：统计 ICS 字符串中 `BEGIN:VEVENT\r\n` 出现次数替代 `result['count']`
- **Hive 路径错误**：`Hive.initFlutter()` 在 Linux 上使用 `~/Documents/` → 改为 `$XDG_DATA_HOME/scheduler_cp`
- **clippy 警告**：`serve.rs` 修复 3 处 `manual_range_contains`

### 验证

- `flutter analyze` — 零错误零警告（仅 15 个已有 info lint）
- `flutter test` — 全部 110 个测试通过
- `cargo test` — 全部 109 + 7 doctest 通过
- `cargo clippy --all-targets` — 零警告
- `./build.sh` → 发布版二进制启动正常，FFI 加载成功，ICS 同步：222 events, 40KB

### 新增/修改文件汇总

| 新增（22 个） | 修改（13 个） |
|-------------|-------------|
| `flutter/linux/` — 平台目录（9 个文件） | `flutter/lib/app/routes.dart` |
| `flutter/lib/core/utils/responsive.dart` | `flutter/lib/main.dart` |
| `flutter/lib/core/services/linux_calendar_sync.dart` | `flutter/lib/domain/bridge/ffi_bridge.dart` |
| `flutter/build_rust_linux.sh` | `flutter/lib/core/services/calendar_service.dart` |
| `flutter/build.sh` | `flutter/lib/core/services/notification_service.dart` |
| `flutter/package.sh` | `flutter/lib/core/services/widget_service.dart` |
| `flutter/install_linux.sh` | `flutter/lib/core/theme/spacing.dart` |
| `flutter/shiftmate.desktop` | `flutter/lib/features/home/home_screen.dart` |
| `flutter/linux_icon.png` | `flutter/lib/features/calendar/calendar_screen.dart` |
| | `flutter/lib/features/profile/profile_screen.dart` |
| | `flutter/lib/features/alarm_settings/alarm_settings_screen.dart` |
| | `flutter/pubspec.lock` |
| | `shift-core/cli/src/serve.rs` |

### 下一步

- Phase 4：手动测试（Wayland/X11、KDE/GNOME 行为、CJK 字体、快捷键响应）
- 修复真机测试发现的问题
- **Desktop Widget 商店上架**：KDE Store + extensions.gnome.org + Pling（详见 implementation-plan.md C.9 step 10）
  - 准备：截图、LICENSE、中英文描述、首次使用引导
  - KDE：KDE Identity 账号 → store.kde.org 上传 .plasmoid
  - GNOME：GNOME GitLab 账号 → extensions.gnome.org 上传 .zip
- 可选：Google Play 上架 / Web 前端

---

## 2026-05-24：crates.io v0.1.4 + AUR 打包 ✅

- `cargo install shift-cli` → v0.1.4 已发布到 crates.io
- AUR 包 `banban` 已推送: https://aur.archlinux.org/packages/banban
- 安装：`yay -S banban` 或 `paru -S banban`

---

## 2026-05-24：DBus 服务 ✅

- `banban dbus` — 注册 session bus 服务 `com.simpleshift.ShiftDaemon`
- 4 个查询方法（JSON 返回）：
  - `GetTodayShift()` — 今日班次
  - `GetShiftForDate(s)` — 指定日期班次
  - `GetUpcomingRest()` — 距休倒计时
  - `GetConfig()` — 当前排班配置
- 跨天自动检测（30s 轮询），发射 `ShiftChanged` / `DayChanged` 信号
- 依赖 zbus 5（已有），零新增外部依赖
- CLI 命令总数: 16 → 17

---

## 2026-05-24：Local HTTP API ✅

- `banban serve` — 启动 localhost:11451 HTTP API 服务器（axum + tokio）
- 端点：
  - `GET /health` — 健康检查
  - `GET /shift` — 今日班次
  - `GET /shift/YYYY-MM-DD` — 指定日期班次
  - `GET /calendar/YYYY/MM` — 月历
  - `GET /leave?max_days=N` — 拼假策略
  - `GET /colleague/A/B` — 同事共同休息日
- CLI 命令总数: 15 → 16
- 零新增 crate（直接集成到 CLI 二进制）

---

## 2026-05-24：Shell 自动补全 ✅

- `banban completions <SHELL>` — 生成 bash/zsh/fish 补全脚本
- 依赖 `clap_complete` 4.5，零额外运行时开销
- CLI 命令总数: 14 → 15
- 用法：
  ```bash
  banban completions bash | sudo tee /usr/share/bash-completion/completions/banban
  banban completions zsh > ~/.zsh/completions/_banban
  banban completions fish > ~/.config/fish/completions/banban.fish
  ```

---

## 2026-05-23：v0.1.3 — i18n 完善 + FFI 扩展 + 批量模式 + banban week ✅

### 版本迭代

| 版本 | 主要变更 |
|------|---------|
| v0.1.0 | 初始发布：6 crates + banban CLI (12 commands) + Flutter FFI |
| v0.1.1 | 英文默认 + 自定义周期 config + 配置生成器 |
| v0.1.2 | TUI 全英文化 + 日历 CJK 对齐修复 + crates.io 发布 |
| v0.1.3 | FFI 扩展 (+4 函数) + 批量模式 + i18n 全消除硬编码 + banban week |

### v0.1.3 详细变更

**FFI 扩展** (flutter/rust + flutter/lib):
- Rust FFI 函数: 6 → 10 (+4: shift_type_for_date, holidays, ics, range)
- 批量模式: calendar_generator (42次→1次), calendar_service (365次→1次), notification_scheduler (30次→1次)
- 消除 holiday_data.dart Dart/Rust 双重数据
- ICS 导出从 CLI-only → Flutter 端可调用
- shift-export 路径修复 (export-engine → shift-export in Cargo.toml)

**i18n 全消除硬编码中文** (flutter/lib/l10n + 5 files):
- leave_optimizer_screen.dart: +6 keys, 全 l10n
- colleague_mode_screen.dart: +5 keys (monthDay, monthDayWeekday 等)
- share_card_layout.dart: +4 keys (slogan, analysisRange, countTimes, scanToDownload)
- home_screen.dart: +2 keys (fullDateFormat, monthDayWeekday)
- notification_scheduler.dart: 通知文案英文化
- 4 语言 (.arb): zh/en/ja/ko 全部同步

**CLI 新增**:
- `banban week` — 7 天周视图，支持 --json 和 --lang en/zh

**代码质量**:
- 修复: shift_rule_notifier.dart const 构造 error, 3 个 unused import, unused _fmt
- 废弃 API 迁移: Share → SharePlus, red/green/blue → this.r/g/b
- flutter analyze: 0 errors, 0 warnings

### 测试总览

| Component | Tests |
|-----------|-------|
| Rust FFI bridge (shift-flutter-bridge) | 9 |
| shift-core (5 crates) | 109 |
| Flutter (Dart) | 110 |
| **Total** | **228** |
| Android ARM64 真机 | ✅ 构建+安装+运行成功 |

## 2026-05-23：v0.1.2 — TUI i18n, crates.io 发布, 全面审查 ✅

（略，详见 v0.1.3 条目）

## 2026-05-23：Flutter FFI 扩展 — 领域算法全面 Rust 化 ✅

### 目标：Flutter 端所有领域算法优先走 Rust FFI，Dart 纯作 fallback

| FFI 函数 | 新增/已有 | 覆盖的 Dart 文件 |
|---------|----------|-----------------|
| `shift_get_shift_info` | 已有 | `shift_calculator.dart` → `getShiftInfo()` |
| `shift_get_shift_type_for_date` | **新增** | `shift_calculator.dart` → `getShiftTypeForDate()` |
| `shift_get_days_until_rest` | 已有 | `shift_metrics.dart` → `daysUntilNextRest()` |
| `shift_get_consecutive_work_days` | 已有 | `shift_metrics.dart` → `consecutiveWorkDays()` |
| `shift_get_monthly_stats` | 已有 | `shift_metrics.dart` + **`salary_calculator.dart`**（新接线）|
| `shift_get_common_rest_days` | 已有 | `colleague_mode.dart` → `findCommonRestDays()` |
| `shift_get_best_leave_plans` | 已有 | `leave_optimizer.dart` → `findBestLeavePlans()` |
| `shift_get_holidays` | **新增** | `holiday_data.dart` → `getChinaHolidays()` |
| `shift_generate_ics` | **新增** | `ffi_bridge.dart` → `ffiGenerateIcs()` |

### 变更文件

| 类型 | 文件 |
|------|------|
| 新增 Rust FFI 函数 (3) | `flutter/rust/src/lib.rs` → `shift_get_shift_type_for_date`, `shift_get_holidays`, `shift_generate_ics` |
| 新增 Dart FFI 包装 (3) | `flutter/lib/domain/bridge/ffi_bridge.dart` → `ffiGetShiftTypeForDate`, `ffiGetHolidays`, `ffiGenerateIcs` |
| 改造 Dart 算法 (3) | `shift_calculator.dart` → `getShiftTypeForDate` FFI 优先 |
|       | `salary_calculator.dart` → `countAllShiftTypesInMonth` 复用已有 FFI |
|       | `holiday_data.dart` → `getChinaHolidays` FFI 优先，消除重复数据 |
| 修复 (1) | `flutter/rust/Cargo.toml` → `export-engine` 路径改为 `shift-export` |
| 启用代理 (1) | `~/.bashrc` → Clash 代理取消注释 |

### 效果

- **FFI 覆盖**: 5 → 9 Rust FFI 函数，4 → 6 Dart 算法文件有 FFI 优先路径
- **测试**: 120 (9 FFI + 111 shift-core) Rust + 110 Flutter, clippy 0 warnings
- **关键收益**: `salary_calculator.dart` 从零 FFI → FFI 覆盖；`holiday_data.dart` 消除 Dart/Rust 双重数据维护
- **ICS 导出**: 从 CLI-only → Flutter 端可调用

### 2026-05-23：FFI 批量模式 — 减少跨语言调用开销 ✅

新增 `shift_get_shift_info_range`：一个 FFI 调用返回日期范围内所有班次数据。

| 消费者 | 之前 | 之后 |
|--------|------|------|
| `calendar_generator.dart` | 42 次单独调用 | 1 次批量调用 |
| `calendar_service.dart` | 365 次单独调用 | 1 次批量调用 |
| `notification_scheduler.dart` | 30 次单独调用 | 1 次批量调用 |

### 2026-05-23：Android ARM64 真机重建验证 ✅

- `cargo-ndk` 交叉编译 `libshift_flutter_bridge.so` (806KB ARM64)
- `flutter build apk --debug` 构建成功
- `adb install` + 启动验证：零崩溃，零 FFI 错误

### v0.1.0 → v0.1.2 迭代

| 版本 | 主要变更 |
|------|---------|
| v0.1.0 | 初始发布：6 crates + banban CLI (12 commands) + Flutter FFI |
| v0.1.1 | 英文默认 + 自定义周期 config + 配置生成器 (banban config) |
| v0.1.2 | TUI 全英文化 + 日历 CJK 对齐修复 + clippy clean |

### v0.1.2 详细变更

- CLI + TUI 全面支持 `--lang en/zh`，默认英文
- `banban config` 生成示例配置文件，用户可自定义排班周期
- 日历中英文精确对齐（unicode-width 感知 CJK 双宽）
- 桌面通知 + systemd 定时器（按班次提醒时间智能过滤）
- TUI 交互式控制：+/- 调请假天数，方向键切换班组，t/T 换默认班组
- crate 重命名：export-engine → shift-export（crates.io 名称冲突）
- 6 crates 全部发布到 crates.io，`cargo install shift-cli` 一键安装
- GitHub Release v0.1.0 + v0.1.1 + v0.1.2（含预编译 Linux x86_64 二进制）
- Android ARM64 真机部署验证通过（cargo-ndk + Flutter FFI）
- 226 tests (111 Rust + 110 Flutter + 5 FFI), clippy zero warnings

### 当前版本

crates.io: shift-cli v0.1.3 (`cargo install shift-cli`)
GitHub: https://github.com/MiniPikka/SimpleShiftScheduler

---

# 倒班助手开发进度记录

## 2026-05-22：架构转型完成 — 班伴/ShiftMate 全栈 Rust 化 ✅

### CLI 命名：`banban`

`shift` 命令与 bash 内置命令冲突，经分析改为产品同名 `banban`：
- 命令名 `banban` — 零冲突，和产品名一致，好记
- 配置文件 `~/.config/banban/config.toml`
- 内部 crate 名仍保留 `shift-cli`（开发者视角）
- 内部源码标识仍用 `shift-*`（crate names, function names）

## 2026-05-22：CP 版本 App 命名与图标统一 + Widget 暗亮适配 ✅

### 变更动机

Flutter CP 项目使用默认 Flutter PNG 图标和 `scheduler_cp` 启动器标签，与 Android 参考版不一致。桌面 Widget 颜色硬编码为深色值，浅色系统模式下显示不协调。

### App 命名

| 操作 | 文件 | 说明 |
|------|------|------|
| 修改 | `android/.../AndroidManifest.xml` | `android:label` 从 `"scheduler_cp"` 改为 `"倒班助手"` |

### App 自适应图标（暗/亮模式适配）

沿用 Android 参考版三 S 三曲臂（triskelion）矢量图标，通过 `drawable-night/` 资源限定符实现暗色模式下背景色自适应。

| 操作 | 文件 | 说明 |
|------|------|------|
| 新建 | `drawable/ic_launcher_background.xml` | 深海军蓝背景（浅色模式） |
| 新建 | `drawable-night/ic_launcher_background.xml` | 略浅海军蓝背景（深色模式） |
| 新建 | `drawable/ic_launcher_foreground.xml` | triskelion 前景（双模式共用） |
| 新建 | `mipmap-anydpi-v26/ic_launcher.xml` | API 26+ adaptive-icon |
| 新建 | `mipmap-anydpi-v26/ic_launcher_round.xml` | API 26+ 圆形 adaptive-icon |
| 新建 | `mipmap-hdpi/ic_launcher.xml` | pre-API 26 合并兜底 |
| 新建 | `mipmap-hdpi/ic_launcher_round.xml` | pre-API 26 圆形兜底 |
| 删除 | `mipmap-*/ic_launcher.png`（5 个） | 移除默认 Flutter PNG 图标 |

### Widget 暗/亮模式适配

通过 `values/values-night` 颜色资源限定符，Widget 背景和文字色随系统主题自动切换。

| 颜色资源 | 浅色模式 | 深色模式 |
|---------|---------|---------|
| `widget_background` | `#F8F9FA` | `#1B1F26` |
| `widget_text_primary` | `#1A1D23` | `#F5F7FA` |
| `widget_text_secondary` | `#6B7280` | `#9CA3AF` |
| `widget_text_dim` | `#9CA3AF` | `#6B7280` |
| `widget_rest_green` | `#16A34A` | `#35D07F` |

| 操作 | 文件 | 说明 |
|------|------|------|
| 新建 | `values/colors.xml` | 浅色模式 Widget 颜色 |
| 新建 | `values-night/colors.xml` | 深色模式 Widget 颜色 |
| 修改 | `layout/shift_widget_layout.xml` | 硬编码颜色 → `@color/widget_*` 引用 |

### 验证

```bash
flutter analyze    # 零新增问题
flutter test       # 110/110 全部通过
flutter build apk  # 构建成功
```

APK label 确认为"倒班助手"，自适应图标 + Widget 颜色资源正确打包。

---

## 2026-05-21：CP 版本全项目审查 + 鲁棒性修复 ✅

### P0 修复（数据安全）

| # | 问题 | 修复 |
|---|------|------|
| 1 | `alarm_settings_notifier.dart` 保存缺少 `await` | 添加 `await`，确保 Hive 写入完成 |
| 2 | `salary_config_notifier.dart` 同上 | 同上 |
| 3 | Hive 反序列化 `ShiftType.values.byName` 异常静默丢弃 | 改为 per-entry try-catch，有效条目保留 |
| 4 | Hive 加载失败后永不重试日历同步 | 移除 `repoAsync.hasValue` 前置条件，添加 error listener |

### P1 修复（国际化）

- `shift_rule_screen.dart`：全部 15+ 处硬编码中文替换为 l10n
- `salary_predictor_screen.dart`：月份格式、单位标签替换
- `calendar_screen.dart`：月份标题替换
- `.arb` 文件：4 语言新增 22 个翻译键

### 改造文件

| 类型 | 文件 |
|------|------|
| P0 | `alarm_settings_notifier.dart`, `salary_config_notifier.dart`, `settings_repository_hive.dart`, `main.dart` |
| P1 | `shift_rule_screen.dart`, `salary_predictor_screen.dart`, `calendar_screen.dart` |
| l10n | `app_zh.arb`, `app_en.arb`, `app_ja.arb`, `app_ko.arb` + 生成的 `.dart` 文件 |

### 已知遗留（后续 i18n 专项处理）

- `leave_optimizer_screen.dart` — 策略卡片日期格式
- `colleague_mode_screen.dart` — 日期格式
- `share_card_layout.dart` — 整个分享卡布局
- `home_screen.dart` — 日期格式
- `notification_scheduler.dart` — 通知标题

---

## 2026-05-21：CP 版本倒班规则自定义 ✅

### 功能实现

Profile 页"倒班规则"按钮原为死链接，现已完全实现。

| 功能 | 实现 |
|------|------|
| 单页滚动 UI | 周期长度 + 预设 + 添加按钮 + Chip 列表 + 日期 + 班组 + 预览 + 保存 |
| 快捷预设 | 默认42天 / 7天轮转 / 14天轮转 / 清空 |
| 编辑方式 | 加载当前周期 → 增删改 Chip → 保存 |
| 周期长度 | 独立设置 + 不足自动填充 REST + 超出截断 |
| referenceDate 持久化 fix | Hive save/load 遗漏字段，重启后日期不丢失 |
| 防误退 | `PopScope` + `isDirty`，未保存时弹确认框 |
| 保存副作用 | `settingsProvider` → 首页/日历自动刷新 + 日历日程重排 |

### 新增/改造文件

| 新增（2 个） | 改造（3 个） |
|-------------|-------------|
| `features/settings/shift_rule_notifier.dart` | `data/repositories/settings_repository_hive.dart` |
| `features/settings/shift_rule_screen.dart` | `app/routes.dart` |
| | `features/profile/profile_screen.dart` |

---

## 2026-05-21：CP 版本倒班津贴功能完善 ✅

### 功能补齐

倒班津贴页原有实现仅显示固定标签+硬编码金额，无编辑能力、无月份切换、无持久化。假设分析功能移除（用户反馈不需要）。

| 补齐项 | 内容 |
|--------|------|
| 配置持久化 | `HiveSettingsRepository` + `salary_config` Box，序列化 `"MORNING=50.0,..."` |
| StateNotifier | `SalaryConfigNotifier` + `salaryConfigProvider`，修改即自动保存 |
| 内联编辑津贴 | 点击行→原地展开 TextField + ✅❌按钮，支持小数，零 dialog |
| 月份切换 | ← → 箭头浏览，非当月显示"今天" |
| 班组切换 | 页面内 DropdownButton |

### 输入方案演进

AlertDialog + TextField → 国产键盘兼容问题。最终采用**原地内联编辑**：`_editingType` 状态控制，setState 切换，回车提交，点击空白取消。

### 新增/改造文件

| 新增（2 个） | 改造（3 个） |
|-------------|-------------|
| `features/salary_predictor/salary_config_notifier.dart` | `data/repositories/settings_repository.dart` |
| `test/features/salary_predictor/salary_predictor_test.dart`（8 用例） | `data/repositories/settings_repository_hive.dart` |
| | `features/salary_predictor/salary_predictor_screen.dart` |

### 验证

```bash
flutter analyze    # 0 errors
flutter test       # 全部通过
flutter build apk  # 构建成功
```

---

## 2026-05-21：CP 版本架构重构 — 算法统一到 Dart ✅

### 重构动机

`CalendarEventManager.kt` 中复制了排班计算逻辑（`ChronoUnit.DAYS.between` + cycle index），与 `shift_calculator.dart` 形成双源。上次 `Period.days` bug 的根因就是 Kotlin 侧独立实现算法导致两边不一致。

### 重构方案

**Dart 统一计算 → Kotlin 只做平台胶水**。

- `calendar_service.dart`：用 Dart `getShiftTypeForDate()` 预计算未来 365 天所有 (日期, 班次, 提醒时间) 元组，一次性传 list 给 Kotlin
- `CalendarEventManager.kt`：移除 shiftCycle/teamPhaseOffset/referenceDate 参数和计算循环，改为接收预计算好的事件列表，只处理日历 CRUD + 去重
- `MainActivity.kt`：简化 calendar channel handler

### 效果

- 排班算法只在 `shift_calculator.dart` 一处维护（95 个测试保护）
- `CalendarEventManager.kt` 从 ~220 行缩减到 ~170 行，逻辑更清晰
- 未来算法修改只需改 Dart，Kotlin 侧自动一致

---

## 2026-05-21：CP 版本 Bug 修复（第二轮）— 日历去重 + Widget 改进

### Bug 2 补充：日历日程重复 ✅

真机测试发现：早班提醒在同一天出现 3 次，中班 2 次。根因分析：

1. **冷启动时 `_reschedule()` 被调用 ≥2 次**：`alarmSettingsProvider` listener 和 `hiveRepoProvider` listener 分别在 Hive 加载完成后触发
2. **`CalendarEventManager.syncShiftEvents()` 无去重逻辑**：`cleanOldEvents()` 仅删除过去事件，未来 365 天事件每次盲目 INSERT，无查重

**修复方案（对齐 Android 参考版 CalendarEventManager 去重模式）**：

| 文件 | 改动 |
|------|------|
| 新增 `CalendarEventIds.kt` | Event ID 追踪数据模型（`Map<String, Long>`） |
| 新增 `EventIdStorage.kt` | SharedPreferences 持久化（序列化格式 `"key=id,key=id"`） |
| 改造 `CalendarEventManager.kt` | 两层去重：① 追踪 ID map 查重 ② `findExistingEvent()` 按标题+日期查系统日历；过期事件自动清理；返回 `Pair<Int, CalendarEventIds>` |
| 改造 `MainActivity.kt` | 日历 channel 接入 EventIdStorage load→sync→save 流程 |
| 改造 `main.dart` | 300ms 去抖 + `_isSyncingCalendar` 并发 guard + `_needsResync` 排队标记 + `isAnyEnabled()` 前置检查 |

### Bug 3 补充：Widget 方案决策 ✅

**Glance 迁移尝试失败**：Glance 1.1.0 编译时 `LocalContext.current` 内联失败（`CompositionLocal` 在 Glance 中不支持内联），且 Glance 对 Compose API 支持有限。

**结论**：保留 RemoteViews 方案 + 精准修复。RemoteViews 是 Android API 1+ 标准组件，全球无数 App 使用——不应因配置问题而更换框架。真正的根因分析：

| 可能根因 | 修复 |
|---------|------|
| 裸 `<View>` 小圆点无背景，反射 `setBackgroundColor` 不可靠 | 改为 `<TextView>` + `android:background` |
| `getLaunchIntentForPackage` 返回 null 时 PendingIntent 静默失败 | 添加 fallback 显式 Intent |
| 仅徽章可点击，未配置状态下无可点击区域 | 根布局设置点击 |
| 所有反射调用不稳定 | try-catch 包裹（已完成） |

**实施**：
- 删除 Glance 文件：`ShiftWidget.kt`（Glance）、`ShiftWidgetReceiver.kt`（Glance）
- 移除 `build.gradle.kts` 中 Glance 依赖
- 重建 `ShiftWidgetProvider.kt`（RemoteViews + 鲁棒性改进）
- 重建 `shift_widget_layout.xml`（小圆点改为 TextView）
- 恢复 `AndroidManifest.xml` receiver 为 `ShiftWidgetProvider`
- 恢复 `shift_widget_info.xml` initialLayout 为 `@layout/shift_widget_layout`
- 恢复 `MainActivity.kt` widget 刷新为 `ShiftWidgetProvider.updateWidgets()`

### 改造文件汇总

| 新增（2 个） | 改造（6 个） | 删除（2 个） |
|-------------|-------------|-------------|
| `calendar/CalendarEventIds.kt` | `calendar/CalendarEventManager.kt` | `widget/ShiftWidget.kt`（Glance） |
| `calendar/EventIdStorage.kt` | `MainActivity.kt` | `widget/ShiftWidgetReceiver.kt`（Glance） |
| | `main.dart` | |
| | `ShiftWidgetProvider.kt`（重建） | |
| | `shift_widget_layout.xml`（重建） | |
| | `AndroidManifest.xml` | |
| | `build.gradle.kts` | |
| | `shift_widget_info.xml` | |

### 验证

```bash
flutter analyze    # 0 errors
flutter test       # 全部通过
flutter build apk  # 构建成功
```

### 下一步

真机验证：Widget 加载正常、日历日程不重复、日期与班次正确对应。

### Bug 2 补充（关键修复）：日历日程日期错位 ✅

根因：`CalendarEventManager.kt` 第 126 行 `referenceDate.until(date).days` 使用了 `java.time.Period.days`——它只返回日期的"天"分量（0~30），而非总天数。

例如：`LocalDate.of(2025,12,15).until(LocalDate.of(2026,5,21))` 返回 `Period(P5M6D)`，`.days` = 6，而非正确的 158。

修复：改用 `ChronoUnit.DAYS.between(referenceDate, date).toInt()`，返回精确的总天数。

---

## 2026-05-21：CP 版本 Bug 修复（第一轮）

### Bug 1：倒班日历班次统计不全 ✅

日历页底部统计卡片原来显示：上班（早+中+夜合计）、休班、夜班、学习。早班和中班数量被隐藏在合计中，用户无法看到各自的计数。

修复：新增 `statMorning`/`statAfternoon` 本地化键（4 种语言），统计卡片改为分别显示早/中/休/夜/学五种班次的独立计数。

### Bug 2：日历权限缺失 + 日历日程集成 ✅

**问题一**：首次进入 App 未请求通知权限（Android 13+ 需要运行时请求 `POST_NOTIFICATIONS`），也未声明日历权限。

**问题二**：Flutter CP 版使用 `flutter_local_notifications` 本地通知方案，未将提醒写入系统日历。用户设置提醒后，手机日历 App 中没有对应日程。

**修复**：
1. `AndroidManifest.xml` 新增 `READ_CALENDAR` + `WRITE_CALENDAR` 权限声明
2. 新增 `permission_handler` 依赖，在 `main()` 启动时请求通知权限和日历权限
3. 新增 native `CalendarEventManager.kt`（~170 行）— 从 Android 参考版移植 Calendar Provider 集成，管理本地日历账户 + 日程 CRUD + 提醒设置
4. 新增 Dart `calendar_service.dart` — MethodChannel 桥接到原生日历管理器
5. 改造 `MainActivity.kt` — 新增 `com.simpleshift.scheduler_cp/calendar` MethodChannel，处理 `syncShiftEvents`/`deleteAllEvents`
6. 改造 `main.dart` — `_reschedule()` 中同时调用 `scheduleShiftNotifications()`（本地通知）和 `CalendarService.syncShiftEvents()`（日历日程），双重保障

### Bug 3：桌面 Widget 载入错误 ✅

Widget 放置时报"载入窗口小部件时出现问题"。

**修复**：
1. `shift_widget_info.xml` 新增 `android:initialLayout="@layout/shift_widget_layout"` — 为系统提供 Widget 初始占位布局
2. `ShiftWidgetProvider.kt` 中所有反射式 `setInt("setBackgroundColor", ...)` 调用均包裹 try-catch，防止部分设备上 RemoteViews 反射失败导致崩溃
3. 移除未使用的 `GradientDrawable` 死代码

### 改造文件汇总

| 新增（2 个） | 改造（13 个） |
|-------------|-------------|
| `android/.../calendar/CalendarEventManager.kt` | `lib/features/calendar/calendar_screen.dart` |
| `lib/core/services/calendar_service.dart` | `lib/l10n/app_localizations.dart` |
| | `lib/l10n/app_localizations_zh.dart` |
| | `lib/l10n/app_localizations_en.dart` |
| | `lib/l10n/app_localizations_ja.dart` |
| | `lib/l10n/app_localizations_ko.dart` |
| | `lib/main.dart` |
| | `android/.../MainActivity.kt` |
| | `android/.../widget/ShiftWidgetProvider.kt` |
| | `android/.../res/xml/shift_widget_info.xml` |
| | `android/.../AndroidManifest.xml` |
| | `pubspec.yaml`（+permission_handler） |

### 验证

```bash
flutter analyze    # 0 errors（仅预存 info）
flutter test       # 全部通过，零回归
```

---

## 2026-05-20：CP 版本 — 阶段 3.3 Widget 升级完成

### 阶段 3.3：桌面小组件升级 ✅

Flutter CP 原有 Widget（MethodChannel + RemoteViews XML）功能简陋。本次升级对齐 Android 参考版（Jetpack Glance）的设计水平。

**3.3.1 Domain 层**
- 新增：`domain/models/widget_shift_data.dart` — `WidgetShiftData` 数据模型（9 字段：今日+明日班次、距休等）+ `computeWidgetShiftData()` 纯函数，复用 `getShiftInfo()` + `daysUntilNextRest()`
- 新增：`core/theme/colors.dart` — `CpColorHex.toHex()` 扩展，Color → #RRGGBB 字符串（供 Widget 颜色传递）

**3.3.2 Widget 布局升级**
- 改造：`res/layout/shift_widget_layout.xml` — 从 3 行纯文本 → 双行富布局：
  - Row 1: 彩色班次徽章（圆角有色背景） + 班组名/周期进度 + 休息倒计时
  - Row 2: 日期 + 明日预览（彩色圆点 + "明日: X班"）
- 深色背景 `#1B1F26` 保持

**3.3.3 数据通道增强**
- 改造：`widget_service.dart` — 新增 `tomorrowShiftLabel`、`shiftBadgeColor`、`tomorrowDotColor` 参数，错误日志从静默改为 `debugPrint`
- 改造：`MainActivity.kt` — 新增 `tomorrow_shift_label`、`shift_badge_color`、`tomorrow_dot_color` 的 SharedPreferences 写入
- 改造：`ShiftWidgetProvider.kt` — 绑定新布局 view IDs，动态设置徽章/圆点颜色，未配置状态改进

**3.3.4 鲁棒性**
- 改造：`home_screen.dart` — 使用 `computeWidgetShiftData()` 纯函数 + `_lastWidgetFingerprint` dedup guard（数据不变时跳过 SharedPreferences 写入和 Widget 更新）

**3.3.5 单元测试** — 5 个新测试全部通过
- 新增：`widget_shift_data_test.dart`（5 用例）— 未配置兜底、默认设置、非法设置、明日差异、dateFormatter

### 新增/改造文件汇总

| 新增（2 个） | 改造（5 个） |
|-------------|-------------|
| `domain/models/widget_shift_data.dart` | `res/layout/shift_widget_layout.xml` |
| `test/domain/models/widget_shift_data_test.dart`（5 用例） | `core/services/widget_service.dart` |
| | `core/theme/colors.dart`（+toHex 扩展） |
| | `features/home/home_screen.dart` |
| | `ShiftWidgetProvider.kt` |
| | `MainActivity.kt` |

### 构建与测试

```bash
flutter analyze    # 0 errors
flutter test       # 95/95 passed（+5 新测试）
flutter build apk  # 21.5s
adb install        # Success
```

### Widget 使用方式

长按桌面 → 添加小部件 → 找到 "scheduler_cp" → 放置 4×1 Widget。Widget 显示今日班次（彩色徽章）、周期进度、距休倒计时、明日班次预览。点击打开 App。

### 下一步

阶段 3 全部完成（3.1 本地通知 + 3.2 分享长图 + 3.3 Widget + 3.4 多语言）。下一步进入阶段 4：产品化（Supabase 集成、数据同步）。

---

## 2026-05-20：Bug 修复与真机测试

### 拼假神器算法修复 ✅

真机测试发现 3 个 Bug，逐一修复：

**Bug 1：`isOff` 死代码 —— 周末/节假日未被算法利用**
- 文件：`domain/algorithms/leave_optimizer.dart`
- `DayStatus.isOff` getter 已定义（综合班次休+节假日+周末），但算法中从未使用
- `restBefore`/`restAfter` 预计算只用 `isRest`（仅班次休），周末和节假日不参与桥接
- 修复：`restBefore`/`restAfter` 改用 `isOff`，正确将周末/节假日纳入休息块计算
- 请假过滤仍用 `isRest`（允许跨周末请假，周末自然桥接不需请假）

**Bug 2：DateTime 时间分量导致节假日匹配失败**
- `DateTime.now()` 带时分秒（如 `15:30:00`），节假日 Map key 是午夜（`00:00:00`）
- Dart `DateTime` 判等包含时间分量 → `holidays[date]` 永远返回 `null`
- 影响：法定节假日从未被检测到，策略卡片不显示节日标记
- 修复：`findBestLeavePlans` 入口规范化 `today` 为午夜；`isNaturallyOff` 查询前同样处理

**Bug 3：分析范围跨年导致 2027 待确认数据泄露**
- `daysToAnalyze=365` 从 5 月算起跨到 2027 年，2027 节假日标记 `[待确认]` 显示在 UI 中
- 设计文档要求不跨年
- 修复：UI 层计算今天到 12 月 31 日实际天数传入

### 拼假神器最少请假天数调整
- 请假天数循环起点从 1 改为 2（`maxLeaveDays==1` 例外）
- 原因：请 1 天假效率分极高（10x+），挤占所有 Top 10 位

### 验证

```bash
flutter analyze    # 0 errors
flutter test       # 90/90 passed
flutter build apk  # 10s, 零警告
adb install        # Success
```

### 新增脚本
- `flutter/install.sh` — 一键编译+安装脚本（含镜像配置）

### 全部变更文件汇总

| 类型 | 文件 |
|------|------|
| 新增 (12) | `domain/models/alarm_time.dart`, `domain/models/alarm_settings.dart`, `features/home/alarm_settings_notifier.dart`, `core/services/notification_scheduler.dart`, `features/alarm_settings/alarm_settings_screen.dart`, `features/colleague_mode/share_card_data.dart`, `features/colleague_mode/share_card_layout.dart`, `test/domain/models/alarm_time_test.dart`, `test/domain/models/alarm_settings_test.dart`, `test/features/colleague_mode/share_card_data_test.dart`, `install.sh` |
| 改造 (18) | `domain/algorithms/leave_optimizer.dart`, `domain/algorithms/holiday_data.dart`, `features/leave_optimizer/leave_optimizer_screen.dart`, `features/colleague_mode/colleague_mode_screen.dart`, `core/services/notification_service.dart`, `core/services/share_service.dart`, `app/routes.dart`, `features/profile/profile_screen.dart`, `features/home/home_state.dart`, `main.dart`, `data/repositories/settings_repository.dart`, `data/repositories/settings_repository_hive.dart`, `pubspec.yaml`, `AndroidManifest.xml`, 4 个 `.arb` 文件 |

---

## 2026-05-20：CP 版本 — 阶段 3.3 分享长图完成

### 阶段 3.3：分享长图（Share Image）✅

Flutter CP 版实现同事模式分享长图功能。通过 `RepaintBoundary` 离屏渲染 + `qr_flutter` QR 码 + `share_plus` 系统分享面板，与 Android 版功能对齐。

对应 Android 版的阶段 22 图片分享（ComposeView 离屏渲染 → ZXing QR → FileProvider → Intent）。

**3.3.1 依赖**
- 新增：`qr_flutter: ^4.1.0` — QR 码 Widget，通过 RepaintBoundary 捕获

**3.3.2 数据模型**
- 新增：`features/colleague_mode/share_card_data.dart` — `ShareCardData` 纯数据类（10 字段）：双班组名、下次共同休息日期/星期、距今、30/60 天次数、日期列表（最多 12 项）、分析范围

**3.3.3 分享长图布局**
- 新增：`features/colleague_mode/share_card_layout.dart`（~230 行）— 1080×1920px 深色主题分享卡：
  - 背景 `#0B0D10` + 48dp 内边距
  - 主结果卡片：`#7C5CFF`(40%)→`#4DA3FF`(25%) 渐变 + 28dp 圆角
  - 日期：48sp Bold 白色、距今：20sp 金色 `#FACC15`
  - 统计卡片行：30 天/60 天（`#1B1F26` 背景 + 32sp Bold 计数）
  - 共同休息日列表：2 列 Wrap，最多 12 项
  - QR 码：200×200dp `QrImageView`（白色背景 + 16dp 圆角）
  - 页脚：Slogan + 分析范围

**3.3.4 分享流程改造**
- 改造：`colleague_mode_screen.dart` — 文本分享 → 图片分享：
  1. 点击分享按钮 → `_isSharing = true`（按钮变 CircularProgressIndicator）
  2. 构建 `ShareCardData` → 通过 `Opacity(opacity:0)` + `RepaintBoundary` 离屏构建 Widget
  3. `renderToImage(pixelRatio: 1.0)` → PNG bytes
  4. `saveToCache(bytes, 'colleague_$timestamp.png')` → 缓存文件
  5. `shareImageFile(path)` → 调起系统分享面板（`share_plus`）
  6. 异常：显示错误 SnackBar（可关闭）

**3.3.5 缓存清理**
- 改造：`share_service.dart` — 新增 `cleanupOldShareImages()`：删除 `share_images/` 子目录中 24 小时前的 PNG
- 改造：`main.dart` — 启动时调用 `cleanupOldShareImages()`

**3.3.6 单元测试** — 5 个新测试全部通过
- 新增：`share_card_data_test.dart`（5 用例）— 构造、空列表、不可变性、12 项上限、daysUntilNext=0 边界

### 新增/改造文件汇总

| 新增（4 个） | 改造（3 个） |
|-------------|-------------|
| `features/colleague_mode/share_card_data.dart` | `features/colleague_mode/colleague_mode_screen.dart` |
| `features/colleague_mode/share_card_layout.dart` | `core/services/share_service.dart`（+cleanup） |
| `test/features/colleague_mode/share_card_data_test.dart`（5 用例） | `main.dart`（+cleanup 调用） |
| | `pubspec.yaml`（+qr_flutter） |

### 构建与测试

```bash
flutter analyze    # 0 errors
flutter test       # 90/90 passed（+5 新测试）
```

零回归。测试覆盖从 85 扩展到 90 个用例，11 个测试文件。

### 技术要点

- **离屏渲染**：`Opacity(opacity:0)` + `RepaintBoundary` 在 `Stack` 中，确保 Widget 已布局但不可见
- **免 FileProvider**：Flutter `share_plus` 直接使用文件路径分享，无需 Android FileProvider 配置
- **QR 码**：`qr_flutter` 的 `QrImageView` 直接嵌入分享卡 Widget 树，RepaintBoundary 一次性捕获
- **Robustness**：`image.dispose()` 防止内存泄漏；`cleanupOldShareImages()` 防止磁盘积累

### 下一步

按实施计划，阶段 3 最后一步：
- Step 3.3：Widget（home_widget 插件）— Android 桌面小组件 + iOS WidgetKit bridge

---

## 2026-05-20：CP 版本 — 阶段 3.2 本地通知完成

### 阶段 3.2：本地通知（Local Notifications）✅

Flutter CP 版实现完整的班次提醒通知系统。采用 `flutter_local_notifications` v21 + `timezone` 方案，跨 Android / iOS 双平台。

对应 Android 版的 Calendar Provider 提醒系统，Flutter 版使用本地通知直接调度。

**3.2.1 数据模型**
- 新增：`domain/models/alarm_time.dart` — `AlarmTime(hour, minute)` 纯数据类，含 `serialize()` / `deserialize()` 序列化
- 新增：`domain/models/alarm_settings.dart` — `AlarmSettings(alarms: Map<ShiftType, AlarmTime?>)` 每个班次独立配置

**3.2.2 持久化扩展**
- 改造：`SettingsRepository` 抽象接口新增 `loadAlarmSettings()` / `saveAlarmSettings()`
- 改造：`HiveSettingsRepository` 新增 `alarm_settings` 独立 Hive Box，5 个 key（`alarm_time_morning/afternoon/rest/night/study`），序列化格式 `"HH:mm"` 与 Android 版一致

**3.2.3 Riverpod 状态管理**
- 新增：`alarm_settings_notifier.dart` — `AlarmSettingsNotifier` + `alarmSettingsProvider`，自动加载 + `updateAlarmTime()` 立即保存

**3.2.4 NotificationService 实现**
- 改造：`core/services/notification_service.dart` — 从 stub 升级为完整实现：
  - `init()` 初始化时区数据库 + 通知插件
  - `scheduleShiftReminder()` 使用 `zonedSchedule()` 调度（TZDateTime）
  - `cancelShiftReminder()` / `cancelAllShiftReminders()`
  - Android 通知渠道：`shift_reminders`（高重要性 + 振动 + 声音）

**3.2.5 通知调度器**
- 新增：`core/services/notification_scheduler.dart` — `scheduleShiftNotifications()`
  - 遍历未来 30 天，按倒班表计算每日班次 → 查找提醒时间 → 调度通知
  - NIGHT 班次前移一天（夜班前一天晚上提醒）
  - 确定性通知 ID：`(daysSinceEpoch * 10) + shiftType.index`
  - 每次调用先取消全部旧通知再重新调度
- 改造：`main.dart` — `_NotificationScheduler` ConsumerStatefulWidget 监听 `alarmSettingsProvider` 变化自动重新调度

**3.2.6 AlarmSettingsScreen UI**
- 新增：`features/alarm_settings/alarm_settings_screen.dart`（~170 行）
  - 说明卡片 + 5 个班次提醒行（彩色圆点 + 班次名 + 时间/未设置 + 删除按钮）
  - Material 3 `showTimePicker()` 24 小时制
  - 自动保存（无需保存按钮）

**3.2.7 导航接线**
- 改造：`routes.dart` — 新增 `/alarm-settings` 路由
- 改造：`profile_screen.dart` — "提醒设置" `onTap` 接线到新路由
- 改造：`home_state.dart` — `HomeNotifier.refresh()` 从 AlarmSettings 读取今日提醒时间并填充 `alarmTime` 字段

**3.2.8 权限**
- 改造：`AndroidManifest.xml` — 新增 `POST_NOTIFICATIONS` 权限

**3.2.9 多语言**
- 改造：4 个 `.arb` 文件 — 新增 `alarmSettingsInfo` + `alarmNotSet` 字符串

**3.2.10 单元测试** — 13 个新测试全部通过
- 新增：`alarm_time_test.dart`（8 用例）— 构造、序列化、反序列化、边界、相等性
- 新增：`alarm_settings_test.dart`（5 用例）— 默认全禁用、启用检测、更新替换、禁用、相等性

### 新增/改造文件汇总

| 新增（7 个） | 改造（8 个） |
|-------------|-------------|
| `domain/models/alarm_time.dart` | `data/repositories/settings_repository.dart` |
| `domain/models/alarm_settings.dart` | `data/repositories/settings_repository_hive.dart` |
| `features/home/alarm_settings_notifier.dart` | `core/services/notification_service.dart` |
| `core/services/notification_scheduler.dart` | `app/routes.dart` |
| `features/alarm_settings/alarm_settings_screen.dart` | `features/profile/profile_screen.dart` |
| `test/domain/models/alarm_time_test.dart`（8 用例） | `features/home/home_state.dart` |
| `test/domain/models/alarm_settings_test.dart`（5 用例） | `main.dart` |
| | `pubspec.yaml`（+timezone 依赖） |

### 构建与测试

```bash
flutter analyze    # 0 errors（仅 info 级别的枚举命名等已有警告）
flutter test       # 85/85 passed（+13 新测试）
```

零回归。测试覆盖从 72 扩展到 85 个用例，10 个测试文件。

### 技术选型

采用 `flutter_local_notifications` v21 + `timezone` 方案（而非 Android Calendar Provider），理由：
- 跨平台：Android + iOS 统一 API
- 无需日历读写权限（Calendar Provider 需要 READ/WRITE_CALENDAR）
- 通知直接由系统通知栏展示，用户感知更强
- 与 Android 版架构对应：CalendarEventManager → NotificationService + NotificationScheduler

### 下一步

按实施计划，阶段 3 剩余步骤：
- Step 3.2：分享长图（RepaintBoundary + QR 码 + share_plus）
- Step 3.3：Widget（home_widget 插件）

---

## 2026-05-20：Monorepo 重构

将 Android 原版与 Flutter CP 版合并为单一 monorepo，统一管理。

### 新结构

```
SimpleShiftScheduler/
├── CLAUDE.md          ← 统一指导文件
├── memory-bank/       ← 共享文档
├── android/           ← Android 原版 (Kotlin + Compose, Phase 1 完成, 148 tests)
└── flutter/           ← Flutter CP 版 (主力开发, 72 tests, 迁移进行中)
```

### 变更
- Android 项目文件移入 `android/` 子目录
- Flutter 项目文件移入 `flutter/` 子目录
- 统一 `CLAUDE.md` 指导两个子项目
- 统一 `.gitignore`
- `memory-bank/` 为共享文档，不再在两个项目中各存一份
- 原 `scheduler_cp/` 独立 repo 可归档

---

## 2026-05-20：CP 版本 — 阶段 2 核心功能迁移完成

### 阶段 2：核心功能迁移 ✅

**2.1 Domain 模型** — 11 个 Freezed 等价数据类：
- `ShiftType` 枚举 + `ShiftCycleConfig`（42天常量）+ `ShiftInfo` + `CalendarDayInfo`
- `Team` + `MonthlyStats` + `RuntimeShiftSettings`（isValid + teamPhaseStep）
- `LeaveStrategy` + `CommonRestResult` + `SalaryConfig` + `SalaryBreakdown`
- 所有模型从 Android 版直接翻译，行为一致

**2.2 Domain 算法** — 5 个纯函数文件：
- `shift_calculator.dart`（calculateDayOffset / normalizeCycleIndex / getShiftTypeForDate / getShiftInfo / teamPhaseOffsetFor）
- `calendar_generator.dart`（generateMonthCalendarDays，42格）
- `shift_metrics.dart`（countShiftTypeInMonth / countWorkDaysInMonth / consecutiveWorkDays / daysUntilNextRest）
- `colleague_mode.dart`（findCommonRestDays，双班组交叉对比）
- `salary_calculator.dart`（countAllShiftTypesInMonth / calculateSalaryBreakdown / simulateExtraShifts）

**2.3 数据层**：
- `SettingsRepository` 抽象接口 + `serializeShiftCycle()` / `deserializeShiftCycle()` 序列化工具
- 保持与 Android 版一致的逗号分隔枚举名格式

**2.4 HomeNotifier 接入真实算法**：
- 替换演示数据，`refresh()` 调用 domain 层 getShiftInfo() + shift_metrics
- 新增纯辅助函数：`teamIdToName()`、`weekDayLabel()`、`workloadLabelFor()`、`consecutiveStatusFor()`、`contextualMessage()`
- `selectedTeamProvider` + `settingsProvider` 支持班组切换

**2.5 单元测试** — 67 个测试全部通过：
| 测试文件 | 用例数 | 覆盖范围 |
|---------|--------|---------|
| `shift_calculator_test.dart` | 16 | offset/normalize/getShiftType/getShiftInfo/teamPhase |
| `shift_metrics_test.dart` | 8 | count/countWork/consecutive/daysUntilRest |
| `calendar_generator_test.dart` | 6 | 42格/跨月/ShiftType/currentMonth/teamPhase |
| `colleague_mode_test.dart` | 7 | sameTeam/differentTeam/nextDate/count30/count60 |
| `salary_calculator_test.dart` | 5 | countAllTypes/zeroConfig/premiumCalc/extraShifts |
| `home_state_test.dart` | 18 | greeting/shiftLabel/teamName/weekday/workload/status/contextual |

### 构建结果

```
flutter analyze    # 0 errors, 0 warnings
flutter test       # 67/67 passed
```

### CP 项目文件清单（共 42 个文件）

| 层 | 文件数 | 关键文件 |
|----|--------|---------|
| Domain models | 11 | shift_type, shift_cycle_config, shift_info, team, ... |
| Domain algorithms | 5 | shift_calculator, calendar_generator, shift_metrics, colleague_mode, salary_calculator |
| Core/theme | 5 | colors, typography, spacing, shapes, theme |
| Features/home | 6 | home_state, home_screen, hero_card, stats_row, tools_row, message_banner |
| Features/其他 | 5 | calendar, profile, leave_opt, colleague_mode, salary (占位) |
| Data | 1 | settings_repository |
| App | 2 | routes, main |
| Tests | 7 | 67 用例 |

---## 2026-05-20：CP 版本 — 阶段 3.1 多语言支持完成

### 阶段 3.1：多语言 i18n ✅

Flutter `flutter_localizations` + `intl` + `flutter gen-l10n`。4 种语言：中文（默认）、English、日本語、한국어。100+ 字符串覆盖全部 UI。`lib/core/utils/l10n.dart` 集中式本地化辅助层（`localizedGreeting()`, `localizedShiftLabel()`, `localizedTeamName()`, `localizedWeekday()` 等）。`HomeState` 简化：移除硬编码展示字符串，改为存储域类型，展示由 UI 通过 l10n 计算。全部 9 个页面已国际化。72 测试全部通过。

### 后续补充（同日完成）

**Step 2.6**: `holiday_data.dart` + `leave_optimizer.dart` — 全功能拼假算法迁移完成。
- `holiday_data.dart`：2026-2027 中国法定节假日 + 调休日
- `leave_optimizer.dart`：间隙桥接法（Gap-Merging），~170行 Dart 纯函数
- 测试：`holiday_data_test.dart`（6 用例）+ `leave_optimizer_test.dart`（9 用例）

**Step 2.7**: Calendar 页 — 7×7 月历网格 + 班组下拉 + 月份导航 + 内联统计卡片

**Step 2.8**: Profile 页 — 卡片式菜单（当前班组 + 拼假神器/同事模式/津贴入口）

**Step 2.9**: Feature 页面全部接入 domain 算法
- `LeaveOptimizerScreen`：策略卡片列表 + FilterChip 筛选
- `ColleagueModeScreen`：双班组选择 + 共同休息主卡片 + 日期列表
- `SalaryPredictorScreen`：津贴总额大卡片 + 班次统计 + 假设分析

### 最终验证

```
flutter analyze    # 0 errors, 0 warnings (仅 info 级别的枚举命名)
flutter test       # 87/87 passed
```

### CP 版本阶段 2 完整交付清单

| 层 | 文件数 | 说明 |
|----|--------|------|
| Domain models | 11 | 全部 Android 版模型 |
| Domain algorithms | 7 | shift_calc + calendar_gen + shift_metrics + colleague_mode + salary_calc + holiday_data + leave_optimizer |
| Core/theme | 5 | Design Token 系统 |
| UI features | 9 | Home + Calendar + Profile + LeaveOpt + Colleague + Salary |
| Data | 1 | SettingsRepository 抽象接口 |
| App | 2 | routes + main |
| Tests | 8 | 87 用例（domain algo + utils） |
| **总计** | **43 文件** | **Android 版核心功能完整迁移** |

---

## 2026-05-20：CP（Cross Platform）版本 — 阶段 1 Flutter 骨架完成

### 阶段 1：Flutter 骨架 ✅

**1.1 Flutter 项目创建**
- `flutter create --org com.simpleshift --project-name scheduler_cp`
- 项目路径：`/home/zxl/Documents/myprojects/scheduler_cp/`
- Flutter 3.38.7 · Dart 3.10.7 · 平台：Android + iOS

**1.2 核心依赖**
- 状态管理：`flutter_riverpod: ^2.6.1` + `riverpod_annotation: ^2.6.1`
- 路由：`go_router: ^17.2.3`
- 数据模型：`freezed_annotation: ^2.4.4` + `json_annotation: ^4.9.0`
- 本地存储：`hive: ^2.2.3` + `hive_flutter: ^1.1.0`
- 国际化：`intl: ^0.20.2`
- 代码生成：`build_runner: ^2.5.4` + `freezed: ^2.5.8` + `json_serializable: ^6.9.5` + `riverpod_generator: ^2.6.4`

**1.3 Design Token 系统（core/theme/）**
| 文件 | 内容 |
|------|------|
| `colors.dart` | Dark Productivity Design 颜色 Token（3背景 + 3文字 + 5班次色 + 4语义色 + shiftColor() 辅助函数） |
| `typography.dart` | 5级字体规格（28/20/16/13/36sp）+ TextTheme |
| `spacing.dart` | 4级间距（xs=12/sm=16/md=20/lg=24） |
| `shapes.dart` | 4级圆角（Button 18dp/Card 24dp/MainCard 28dp/Sheet 32dp） |
| `theme.dart` | 深色/浅色双主题 ThemeData，自动跟随系统 `isSystemInDarkTheme()` |

**1.4 GoRouter 路由**
- `lib/app/routes.dart` — `StatefulShellRoute.indexedStack` + 底部三 Tab（首页/日历/我的）
- 子页面 push 进入：leave-optimizer / colleague-mode / salary-predictor
- `AppShell` widget 管理 NavigationBar 的选中状态切换

**1.5 首页 UI（HomeScreen + 4 Widgets）**
- `home_state.dart` — HomeState（16 字段）+ HomeNotifier（Riverpod）+ greetingForHour() 纯函数
- `widgets/hero_card.dart` — 64dp 圆形徽章 + 班组详情 + 休息倒计时胶囊 + 周期进度条
- `widgets/stats_row.dart` — 两等宽指标卡片（本月上班/连续上班）
- `widgets/tools_row.dart` — 三个特色功能入口（拼假神器/同事模式/倒班津贴）
- `widgets/message_banner.dart` — 上下文共情文案卡片
- `home_screen.dart` — 组装全部组件，SafeArea + SingleChildScrollView + ConstrainedBox(maxWidth: 600)

### 构建与测试

```bash
$ flutter analyze    # No issues found!
$ flutter test       # All tests passed!
```

### 新增文件清单

| 路径 | 用途 |
|------|------|
| `lib/main.dart` | App 入口 + ProviderScope + MaterialApp.router |
| `lib/app/routes.dart` | GoRouter + AppShell + 底部导航 |
| `lib/core/theme/colors.dart` | 颜色 Token |
| `lib/core/theme/typography.dart` | 字体层级 |
| `lib/core/theme/spacing.dart` | 间距系统 |
| `lib/core/theme/shapes.dart` | 圆角系统 |
| `lib/core/theme/theme.dart` | ThemeData 组装 |
| `lib/features/home/home_state.dart` | HomeState + HomeNotifier |
| `lib/features/home/home_screen.dart` | 首页组装 |
| `lib/features/home/widgets/hero_card.dart` | HeroCard 主卡片 |
| `lib/features/home/widgets/stats_row.dart` | 指标统计行 |
| `lib/features/home/widgets/tools_row.dart` | 功能入口行 |
| `lib/features/home/widgets/message_banner.dart` | 共情文案卡片 |
| `lib/features/calendar/calendar_screen.dart` | 日历页（占位） |
| `lib/features/profile/profile_screen.dart` | 我的页（占位） |
| `lib/features/leave_optimizer/leave_optimizer_screen.dart` | 拼假神器（占位） |
| `lib/features/colleague_mode/colleague_mode_screen.dart` | 同事模式（占位） |
| `lib/features/salary_predictor/salary_predictor_screen.dart` | 倒班津贴（占位） |

### 下一步：阶段 2 — 核心功能迁移

Domain 算法从 Android 版翻译为 Dart 纯函数：
1. `shift_calculator.dart`（偏移计算 + 周期索引 + getShiftTypeForDate）
2. `calendar_generator.dart`（42格月历生成）
3. `shift_metrics.dart`（月度统计 + 连续上班 + 距休）
4. `holiday_data.dart` + `leave_optimizer.dart`（拼假算法）
5. `colleague_mode.dart`（双班组交叉对比）
6. `salary_calculator.dart`（津贴计算）

---

## 2026-05-20：CP（Cross Platform）版本规划

### 重大决策：启动 CP 版本

倒班助手从 Android 原生工具 App 正式升级为 **Cross Platform 产品**。Phase 1 Android 版（阶段 1-27）已完成并稳定，作为 CP 版的算法参考和产品验证基础。

### CP 版本核心目标

- **平台**：Android / iOS / Web（后期）/ Desktop（后期）
- **技术栈**：Flutter + Riverpod + GoRouter + Freezed + Hive
- **设计语言**：Dark Productivity Design（统一 Design Token 系统）
- **核心战略**：从"Android 工具"升级为"倒班人群的生活助手"

### CP 版本 5 阶段规划

| 阶段 | 目标 | 关键交付 |
|------|------|---------|
| 阶段 1：Flutter 骨架 | 跑通 Flutter、Design Token、路由、首页 | 项目初始化 + 首页 UI |
| 阶段 2：核心功能迁移 | 倒班算法、日历、拼假神器、同事模式 | Domain 纯函数 + 核心页面 |
| 阶段 3：平台能力 | 本地通知、分享长图、Widget、多语言 | 平台适配 |
| 阶段 4：产品化 | 数据同步、云备份、登录、用户系统 | Supabase 集成 |
| 阶段 5：增长阶段 | 社交传播、应用商店上架 | ASO + 裂变 |

### 算法迁移策略

Android 版 domain 层全部为纯函数（零 Android 依赖），可直接翻译为 Dart：
- `shift_calculator.kt` → `shift_calculator.dart`
- `calendar_generator.kt` → `calendar_generator.dart`
- `shift_metrics.kt` → `shift_metrics.dart`
- `leave_optimizer.kt` → `leave_optimizer.dart`
- `colleague_mode.kt` → `colleague_mode.dart`
- `salary_calculator.kt` → `salary_calculator.dart`
- `holiday_data.kt` → `holiday_data.dart`

### 文档更新

- `app-design-document.md`：新增 Part A（CP 版设计文档）
- `tech-stack.md`：新增 Part A（CP 版 Flutter 技术栈）
- `architecture.md`：新增 Part A（CP 版架构 + 项目结构 + 迁移映射）
- `implementation-plan.md`：新增 Part A（CP 版 5 阶段实施计划）

### Android 版状态

Phase 1 Android 版（阶段 1-27）功能完整、稳定。162 个单元测试全部通过，编译零警告。Android 版作为产品验证基础保留，CP 版在其算法和产品经验上重构。

---

## 2026-05-18：多语言支持（阶段 27）

### 功能概述

支持中文（默认）、日本語、한국어、English 四种语言。采用 Android 标准资源方案，`values/strings.xml`（zh 默认）+ `values-ja/`、`values-ko/`、`values-en/` 三个语言覆盖。

### 架构清理

移除首页多轨并行策略（V1/V2/V3/V4），删除 22 个旧文件（4 个旧版首页、16 个 V1/V2/V3 组件、旧 SettingsScreen/SettingsViewModel 及测试）。`HomeScreen.kt` 为唯一首页，所有 Composable 内联。

### i18n 工具层

- `ShiftLabelMapper.toLabel(context, shiftType)` — 班次标签映射（早/中/休/夜/学 → AM/PM/Off/NT/TR 等）
- `TeamNameMapper.toName(teamId, context)` — 班组名本地化（一值…六值 → Shift A…F 等）
- `HolidayNameMapper.toLocalizedName(chineseName, context)` — 节假日名本地化
- `Team` 数据类仅存 `id`，移除硬编码 `name` 字段
- `computeWidgetShiftData()` 接受 `shiftLabelResolver` / `teamNameResolver` 函数参数

### 新增文件

| 文件 | 用途 |
|------|------|
| `values-ja/strings.xml` | 日语字符串资源 |
| `values-ko/strings.xml` | 韩语字符串资源 |
| `values-en/strings.xml` | 英语字符串资源 |
| `util/TeamNameMapper.kt` | 班组名本地化 |
| `util/HolidayNameMapper.kt` | 节假日名本地化 |

### 改造文件

约 20 个文件：`values/strings.xml`（完整重写）、`ShiftLabelMapper`（Context-based）、`Team`（移除 name）、`widget_data`（接受 resolver）、`ShiftWidget`（context.getString）、`CalendarEventManager`（资源化标题）、`HomeScreen`（stringResource 全面替换）、`CalendarViewModel`（本地化日期格式）、所有 ViewModel（Context-based 标签）、`MainActivity`（底部导航本地化）、多个 UI 屏幕。

### 测试

150 个测试全部通过。测试更新：`HomeViewModelTest`、`WidgetDataTest`、`ContextualMessageTest` 适配新 API。

---

## 2026-05-13：桌面小组件规划

### 功能概述

在设备桌面添加小组件（Widget），用户无需打开 App 即可查看今日班次和周期进度。使用 Jetpack Glance 框架实现 Compose 式 Widget 开发。

**Widget 显示内容**：
- 班组名称（一值～六值）
- 当前日期（本地化可读）
- 今日班次（大字彩色：早/中/休/夜/学）
- 周期进度（当前天数 / 总天数 + 简易进度条）

### 技术方案

| 项 | 选择 |
|---|------|
| 框架 | Jetpack Glance 1.1.0（`glance-appwidget` + `glance-material3`） |
| 数据读取 | Widget 内直接通过 `SettingsRepository` 读取 DataStore |
| 计算复用 | domain 层新增 `computeWidgetShiftData()`，复用 `getShiftInfo()` |
| 更新机制 | 系统 1h 周期 + App 内主动广播 + 点击打开 App 触发 onResume |
| Widget 尺寸 | 4×1（默认），自适应 3×1 / 4×2 |

### 实施步骤（阶段 15）

| Step | 内容 | 新增文件 | 改造文件 |
|------|------|---------|---------|
| 15.1 | 添加 Glance 依赖 | — | `build.gradle.kts` |
| 15.2 | 创建 Widget 数据模型 + 计算函数 | `domain/widget_data.kt` | — |
| 15.3 | 实现 Glance Widget UI | `widget/ShiftWidget.kt`, `widget/ShiftWidgetReceiver.kt` | — |
| 15.4 | 注册 Widget（Manifest + XML） | `res/xml/shift_widget_info.xml` | `AndroidManifest.xml`, `strings.xml` |
| 15.5 | Widget 更新触发机制 | — | `MainActivity.kt` |
| 15.6 | Widget 单元测试 | `WidgetDataTest.kt`（4 用例） | — |
| 15.7 | 文档更新 | — | memory-bank 全部 5 文件 |

### 预期新增

- 新增文件：5 个（domain/widget_data.kt, widget/ShiftWidget.kt, widget/ShiftWidgetReceiver.kt, res/xml/shift_widget_info.xml, WidgetDataTest.kt）
- 改造文件：4 个（build.gradle.kts, AndroidManifest.xml, MainActivity.kt, strings.xml）
- 新增测试：4 个用例
- 总测试：75 → 79

### 详细规划

参见 `implementation-plan.md` 阶段 15。

---

## 2026-05-13：阶段 15 实施完成

### 阶段 15：桌面小组件 ✅

**15.1 添加 Glance 依赖**
- 文件：`app/build.gradle.kts`
- 新增：`glance-appwidget:1.1.0` + `glance-material3:1.1.0`

**15.2 Widget 数据模型与计算函数**
- 新增：`domain/widget_data.kt`
- `WidgetShiftData(dateLabel, shiftLabel, shiftType, dayOfCycle, totalDays, teamName)`
- `computeWidgetShiftData(today, settings, locale)` — 纯函数，复用 `getShiftInfo()` + `ShiftLabelMapper.toLabel()`
- `!isValid` 时返回兜底数据（shiftLabel="?"）

**15.3 Glance Widget UI**
- 新增：`widget/ShiftWidget.kt` — GlanceAppWidget 实现
- 新增：`widget/ShiftWidgetReceiver.kt` — 系统 Receiver
- Widget 显示：班组名 + 日期 + 今日班次（大字）+ 进度文本 + Unicode 进度条
- 点击 Widget 打开 MainActivity
- 注意：Glance 1.1.0 中 `provideContent` 是扩展函数，需显式 import `androidx.glance.appwidget.provideContent`

**15.4 Widget 注册**
- 新增：`res/xml/shift_widget_info.xml` — 4×1 Widget，每小时刷新
- 改造：`AndroidManifest.xml` — 注册 ShiftWidgetReceiver
- 改造：`res/values/strings.xml` — widget_description

**15.5 Widget 更新触发**
- 改造：`MainActivity.kt`
- 新增 `notifyWidgetUpdate()` — 使用 Glance `updateAll()` API 刷新 Widget
- 触发点：`onResume()` + `onSettingsSaved()` 回调

**15.6 Widget 测试** — 4 个测试全部通过
- 新增：`WidgetDataTest.kt`
- 覆盖：默认设置、自定义周期、非法设置兜底、班组选择

### Glance 1.1.0 API 要点

- `provideContent` 是扩展函数，位于 `androidx.glance.appwidget.provideContent`
- `ColorProvider` 通过工厂函数创建，inline `Color` 类需要 proper import
- `LocalContext.current` 获取 Context（在 `@Composable` 作用域内）
- `actionStartActivity(intent)` 接受 `Intent` 参数
- Glance 不支持 `remember`/`LazyColumn`/动画/Canvas
- 进度条使用 Unicode 字符 `█░` 文本实现

### 新增/改造文件汇总

| 新增（6 个） | 改造（4 个） |
|-------------|-------------|
| `domain/widget_data.kt` | `app/build.gradle.kts` |
| `widget/ShiftWidget.kt` | `AndroidManifest.xml` |
| `widget/ShiftWidgetReceiver.kt` | `MainActivity.kt` |
| `res/xml/shift_widget_info.xml` | `res/values/strings.xml` |
| `WidgetDataTest.kt`（4 用例） | |
| memory-bank 更新（已在上步完成） | |

### 构建与测试

```bash
./gradlew assembleDebug        # BUILD SUCCESSFUL
./gradlew testDebugUnitTest    # BUILD SUCCESSFUL（79 个测试全部通过）
```

零回归。测试覆盖从 75 扩展到 79 个用例，10 个测试文件。

---

## 2026-05-13：全项目审查与改进规划

### 审查范围

- 完整阅读 memory-bank 全部 5 个文件
- 完整审查 26 个源文件 + 7 个测试文件
- 执行 `./gradlew testDebugUnitTest` — BUILD SUCCESSFUL（全部通过）

### 审查结论

项目整体健康度良好：MVVM 分层清晰、domain 层纯函数可测试性强、Calendar Provider 方案跨品牌兼容、DataStore 持久化稳健。发现 8 个改进点，按严重程度和组织方式规划为 4 个阶段（11-14）。

### 发现的问题与对应阶段

| # | 问题 | 严重度 | 对应阶段 |
|---|------|--------|---------|
| 1 | `SettingsViewModel.cancel()` 回退到初始值而非最后保存值 | 高（用户数据丢失） | 阶段 11.1 |
| 2 | `CalendarSyncManager` 异常静默吞掉 | 中（用户无法感知失败） | 阶段 11.2 |
| 3 | `CalendarViewModel` 直接调用 `LocalDate.now()` | 中（测试性不一致） | 阶段 11.3 |
| 4 | 日历网格高度硬编码 `430.dp` | 中（多屏适配不稳） | 阶段 11.4 |
| 5 | 日历页缺"回到今天"按钮 | 低（UX 摩擦） | 阶段 11.5 |
| 6 | `CalendarViewModel`/`SettingsRepository`/`CalendarSyncManager` 零测试覆盖 | 高（核心组件无测试） | 阶段 12.1-12.3 |
| 7 | 三处重复 `mapShiftLabel` + 两处重复 `TeamDropdown` | 低（代码整洁） | 阶段 13.1-13.2 |
| 8 | memory-bank 文档描述过时（syncNextSevenDays→syncShiftEvents 365天） | 低（文档一致性） | 阶段 14.1-14.3 |

### 改进阶段总览

- **阶段 11**：Bug 修复与代码加固（5 个 Step）—— 修复 cancel()、错误可见化、测试性对齐、响应式布局、回到今天
- **阶段 12**：测试覆盖补全（3 个 Step）—— CalendarViewModelTest (9 用例)、SettingsRepositoryTest (7 用例)、CalendarSyncManagerTest (可选)
- **阶段 13**：代码简洁性提升（2 个 Step）—— 去重包装函数、提取共用 TeamDropdown
- **阶段 14**：文档同步（3 个 Step）—— architecture.md、tech-stack.md、progress.md 更新

### 预期新增测试

- 阶段 11: `SettingsViewModelTest` 追加 1 个取消逻辑测试
- 阶段 12: `CalendarViewModelTest`（9 用例）、`SettingsRepositoryTest`（7 用例）
- 总计新增约 17 个测试用例

### 详细规划

参见 `implementation-plan.md` 阶段 11-14。

---

## 2026-05-13：阶段 11-13 实施完成

### 阶段 11：Bug 修复与代码加固 ✅

**11.1 修复 SettingsViewModel.cancel() 回退逻辑**
- 文件：`SettingsViewModel.kt`
- 改动：`savedSettings` 从 `val` 改为 `var`，`save()` 中更新 `savedSettings = settings`
- 测试：新增 `cancel after multiple saves restores last-saved state not initial state`

**11.2 CalendarSyncManager 错误状态可见化**
- 文件：`CalendarSyncManager.kt`、`MainActivity.kt`
- 改动：新增 `syncErrorFlow: StateFlow<String?>` + `clearSyncError()`；`syncFromCurrentState()` 和 `startAutoSync()` 中的 `catch (_: Exception) {}` 替换为错误发射 + 成功时清除
- UI：`MainActivity` 底部显示可关闭的错误 Snackbar（10 秒自动消失）

**11.3 CalendarViewModel 测试性对齐**
- 文件：`CalendarViewModel.kt`
- 改动：新增 `todayProvider: () -> LocalDate` 构造参数（默认 `{ LocalDate.now() }`），`refresh()` 中使用 `todayProvider()` 替代硬编码 `LocalDate.now()`

**11.4 日历网格响应式高度**（已修复运行时崩溃）
- 文件：`CalendarScreen.kt`
- 改动：`LazyVerticalGrid(height=430.dp)` → 常规 `Column` + `Row` 布局（7 行 × 7 列），`CalendarDayCell` 使用 `Modifier.aspectRatio(0.85f)` 自适应宽高比
- 修正：初版尝试保留 `LazyVerticalGrid` 只移除高度导致 `IllegalStateException`（无限高度约束），改用非 lazy 布局从根本上解决

**11.5 日历页"回到今天"按钮**
- 文件：`CalendarViewModel.kt`、`CalendarScreen.kt`、`MainActivity.kt`
- 改动：新增 `goToToday()` 方法、`CalendarUiState.isCurrentMonth` 字段；非当前月时显示"今天"按钮

### 阶段 12：测试覆盖补全 ✅

**12.1 CalendarViewModelTest** — 9 个测试全部通过
- 新增文件：`CalendarViewModelTest.kt`
- 覆盖：初始状态、weekLabels、月份导航、goToToday、isToday 标记、computeStats、dismissStats、setTeam

**12.2 SettingsRepositoryTest** — 7 个测试全部通过
- 新增文件：`SettingsRepositoryTest.kt`
- 覆盖：默认 flow、保存/读取往返（settings/alarm/eventIds）、清空闹钟、空 eventIds

**12.3 CalendarSyncManagerTest** — 跳过（依赖 3 层 Android 组件，mock 成本过高；CalendarEventManager 已有独立测试覆盖核心逻辑）

### 阶段 13：代码简洁性提升 ✅

**13.1 移除重复 ShiftLabel 映射包装**
- 文件：`HomeViewModel.kt`、`CalendarViewModel.kt`、`SettingsScreen.kt`
- 改动：删除 3 处 `mapShiftLabel()`/`shiftTypeToLabel()` 包装函数，全改为直接调用 `ShiftLabelMapper.toLabel()`
- 验证：`grep -r "mapShiftLabel\|shiftTypeToLabel" app/src/main/` 无匹配

**13.2 提取共用 TeamDropdown 组件**
- 新增文件：`ui/common/CommonComponents.kt`
- 改动：`HomeScreen` 和 `SettingsScreen` 均使用共享 `TeamDropdown`，各自删除私有实现
- `HomeScreen` 额外清理：移除未使用的 import（DropdownMenuItem、ExperimentalMaterial3Api 等 7 个）

### 关键结果

- 新增文件：
  - `ui/common/CommonComponents.kt`
  - `CalendarViewModelTest.kt`（9 用例）
  - `SettingsRepositoryTest.kt`（7 用例）
- 改造文件：
  - `SettingsViewModel.kt` — cancel() 回退逻辑修复
  - `CalendarSyncManager.kt` — 错误状态流
  - `MainActivity.kt` — 错误 Snackbar + onTodayClick 接线
  - `CalendarViewModel.kt` — todayProvider 注入 + goToToday() + isCurrentMonth
  - `CalendarScreen.kt` — 响应式高度 + 今天按钮
  - `HomeViewModel.kt` — 删除 mapShiftLabel
  - `HomeScreen.kt` — 使用共享 TeamDropdown + 清理 imports
  - `SettingsScreen.kt` — 使用共享 TeamDropdown + 删除 shiftTypeToLabel
- `SettingsViewModelTest.kt` — 追加 1 个取消逻辑测试

### 构建与测试

```bash
./gradlew testDebugUnitTest   # BUILD SUCCESSFUL（全部测试通过）
```

未引入回归。测试覆盖从 7 个测试文件扩展到 9 个测试文件。

---

## 2026-05-09：实施计划第 10 步（闹钟改为日历日程）

### 迁移原因

- AlarmManager 在国产手机上被各厂商杀后台机制严重影响，闹钟延迟或丢失
- Calendar Provider 是 AOSP 标准 API，所有 Android 品牌必须支持，提醒更可靠
- 日历日程持久化在系统日历数据库，重启自动恢复，无需 BootReceiver
- 减少权限依赖：3 个 → 2 个

### 本次完成内容

- 阶段 10（闹钟改为日历日程）全部子步骤：
  - 新增 `CalendarEventManager` 替代 `AlarmScheduler`：管理本地日历 + 日程 CRUD + 提醒设置
  - 删除 `AlarmScheduler`、`AlarmReceiver`、`BootReceiver`（日历日程不需要自定义 Receiver）
  - 新增 `CalendarEventIds` 数据模型：持久化追踪每个日期+班次的日程 eventId
  - 改造 `SettingsRepository`：新增 `calendarEventIdsFlow` + `saveCalendarEventIds()` + `calendarSettingsFlow`（合并 alarm settings + event ids）
  - 改造 `MainActivity`：移除通知渠道 + 闹钟 `combine`，改为日历日程同步 + 权限请求
  - 改造 `AndroidManifest.xml`：移除 3 个闹钟权限，新增 `READ_CALENDAR` + `WRITE_CALENDAR`
  - `SettingsScreen`/`SettingsViewModel` UI 与逻辑基本不变，底层从 AlarmManager → Calendar Provider
  - 删除旧的 Alarm 相关测试文件

### 关键结果

- 新增文件：
  - `app/src/main/java/com/simpleshift/scheduler/calendar/CalendarEventManager.kt`
  - `app/src/main/java/com/simpleshift/scheduler/calendar/CalendarResolver.kt`（ContentResolver 抽象接口，开启测试能力）
  - `app/src/main/java/com/simpleshift/scheduler/calendar/CalendarSyncManager.kt`（combine 三流自动同步）
  - `app/src/main/java/com/simpleshift/scheduler/domain/model/CalendarEventIds.kt`
  - `app/src/test/java/com/simpleshift/scheduler/calendar/CalendarEventManagerTest.kt`
- 删除文件：
  - `app/src/main/java/com/simpleshift/scheduler/alarm/AlarmScheduler.kt`
  - `app/src/main/java/com/simpleshift/scheduler/alarm/AlarmReceiver.kt`
  - `app/src/main/java/com/simpleshift/scheduler/alarm/BootReceiver.kt`
  - `app/src/main/res/drawable/ic_alarm.xml`
  - `app/src/test/java/com/simpleshift/scheduler/alarm/AlarmSchedulerTest.kt`
  - `app/src/test/java/com/simpleshift/scheduler/alarm/AlarmReceiverTest.kt`
- 改造文件：
  - `app/src/main/AndroidManifest.xml` — 权限替换
  - `app/src/main/java/com/simpleshift/scheduler/MainActivity.kt` — 日程同步替代闹钟调度
  - `app/src/main/java/com/simpleshift/scheduler/data/repository/SettingsRepository.kt` — 新增 eventId 追踪
  - `app/src/main/res/values/strings.xml` — 移除通知相关字符串
- 跨品牌兼容：Calendar Provider 是 AOSP 必选项（API 14+），小米/华为/OPPO/Vivo/三星/原生 Android 全支持
- 本地日历策略：使用检测/创建本地日历账户，日程存储在设备本地不同步云端
- 权限：运行时请求 `READ_CALENDAR` + `WRITE_CALENDAR`

### 下一步

- 所有规划阶段（1-10）已完成，应用功能完整

---

## 2026-05-06：实施计划第 9 步完成（闹钟提醒）

### 本次完成内容

- 已完成阶段 9（闹钟提醒：每班次独立闹钟时间设置）全部 7 个子步骤：
  - Step 9.1：新增 `AlarmTime` 和 `AlarmSettings` 数据模型（含 0..23/0..59 校验）
  - Step 9.2：扩展 `SettingsRepository` 新增 5 个 `stringPreferencesKey` + `alarmSettingsFlow` + `saveAlarmSettings()`
  - Step 9.3：新增 `AlarmScheduler` 闹钟调度引擎（7 天前瞻、确定性 request code、API 31+ 降级策略）
  - Step 9.4：新增 `AlarmReceiver`（通知构建 + API 33+ 权限检查）+ `BootReceiver`（设备重启恢复）+ 通知渠道
  - Step 9.5：扩展 `SettingsViewModel`（`SettingsUiState.alarmSettings` + `updateAlarmTime()` + 自动保存回调）、`cancel()` 不重置闹钟
  - Step 9.6：扩展 `SettingsScreen`（闹钟设置卡片区 + `ShiftAlarmRow` + `AlarmTimePickerDialog`）
  - Step 9.7：`MainActivity` 集成（通知渠道创建 + `combine` 双流自动调度 + `rescheduleAlarms` 辅助方法 + `onResume` 重调度）

### 关键结果

- 新增文件：
  - `app/src/main/java/com/simpleshift/scheduler/domain/model/AlarmTime.kt`
  - `app/src/main/java/com/simpleshift/scheduler/domain/model/AlarmSettings.kt`
  - `app/src/main/java/com/simpleshift/scheduler/alarm/AlarmScheduler.kt`
  - `app/src/main/java/com/simpleshift/scheduler/alarm/AlarmReceiver.kt`
  - `app/src/main/java/com/simpleshift/scheduler/alarm/BootReceiver.kt`
  - `app/src/main/res/drawable/ic_alarm.xml`
  - `app/src/test/java/com/simpleshift/scheduler/domain/model/AlarmTimeTest.kt`
  - `app/src/test/java/com/simpleshift/scheduler/domain/model/AlarmSettingsTest.kt`
  - `app/src/test/java/com/simpleshift/scheduler/alarm/AlarmSchedulerTest.kt`
  - `app/src/test/java/com/simpleshift/scheduler/alarm/AlarmReceiverTest.kt`
- 改造文件：
  - `app/src/main/java/com/simpleshift/scheduler/data/repository/SettingsRepository.kt` — 新增 5 个 alarm DataStore key + flow + save
  - `app/src/main/java/com/simpleshift/scheduler/viewmodel/SettingsViewModel.kt` — `alarmSettings` 字段 + `updateAlarmTime()` + 回调注入
  - `app/src/main/java/com/simpleshift/scheduler/ui/settings/SettingsScreen.kt` — 闹钟 UI 区 + 时间选择对话框
  - `app/src/main/java/com/simpleshift/scheduler/MainActivity.kt` — 通知渠道 + `combine` 双流 + `rescheduleAlarms` + 工厂扩展
  - `app/src/main/AndroidManifest.xml` — 3 个权限 + 2 个 receiver
  - `app/src/main/res/values/strings.xml` — 12 个新字符串
  - `app/src/test/java/com/simpleshift/scheduler/viewmodel/SettingsViewModelTest.kt` — 5 个闹钟测试
- 闹钟调度策略：每次设置变更或启动时自动调度未来 7 天闹钟，设备重启后 `BootReceiver` 恢复
- 权限策略：`SCHEDULE_EXACT_ALARM`（API 31+ 降级）、`POST_NOTIFICATIONS`（API 33+ 静默跳过）、`RECEIVE_BOOT_COMPLETED`（启动恢复）
- 闹钟设置独立自动保存（不纳入周期设置的 save/cancel 流程），确保闹钟不丢失

### 构建与测试说明

- 已执行完整单元测试：`./gradlew testDebugUnitTest`
- 结果：`BUILD SUCCESSFUL`（全部测试通过）
- 阶段 9 变更未引入单测回归

### 下一步

- 所有规划阶段（1-9）已完成，应用功能完整

---

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

---

## 2026-05-13：夜班提醒日期修复

### 问题

排班表显示某日是夜班，实际夜班班车在前一天晚上发车（如5月13日夜班→5月12日22:40发车），夜班在当天早上8:00结束。但日历提醒设置在班次日期当天触发——等提醒响起时夜班早已结束。

### 修复

`CalendarEventManager.syncShiftEvents()` 中，对 `ShiftType.NIGHT` 将事件日期前移一天（`date.minusDays(1)`）。事件 key 仍使用原始班次日期。

- 改造：`CalendarEventManager.kt`（3 处 `date` → `eventDate`）
- 新增测试：`night shift events are created on previous day`
- 全部 80 个测试通过

---

## 2026-05-13：阶段 16 规划（首页精品化升级）

### 背景

当前首页仅为功能骨架：班组下拉框 + 日期文本 + 班次文本 + 进度文本，四行平铺无层次。计划将首页升级为精品级产品首页，增加视觉层次和信息密度。

### 外部方案评估

收到了一份"首页精品化升级"实施建议（双轨制 + 组件化 + 10 步渐进），评审后发现以下问题已修正：

1. **"牛马指数"无定义** → 替换为"本月上班 X 天"（有明确公式的指标）
2. **"距离休班"写死占位无实现** → 新增 `domain/shift_metrics.kt` 提供 `daysUntilNextRest()` 真实计算
3. **domain 层禁止触碰但需计算连续上班** → 新增独立文件而非修改已有函数
4. **QuickActionsRow 死按钮** → 日历→滚动到日历区，提醒/设置→导航
5. **HomeUiState 缺少 teamName** → 派生字段补充
6. **无测试验证步骤** → 每步增加 `./gradlew testDebugUnitTest` 检查点

### 技术方案

| 项 | 选择 |
|---|------|
| 升级策略 | 双轨制（旧 HomeScreen 保留，NewHomeScreen 新建，USE_NEW_HOME 开关） |
| UI 结构 | 5 个独立组件 + 1 个组合页面 |
| 指标计算 | 新增 `domain/shift_metrics.kt`（4 个纯函数） |
| 数据流 | HomeUiState 扩展 5 个字段，refreshToday 计算 |
| 回滚 | 改 `USE_NEW_HOME = false` 即刻回滚，零风险 |

### 实施步骤（阶段 16）

| Step | 内容 | 新增文件 | 改造文件 |
|------|------|---------|---------|
| 16.1 | HomeUiState 扩展 + domain 指标函数 | `domain/shift_metrics.kt`, `ShiftMetricsTest.kt` | `HomeViewModel.kt` |
| 16.2 | GreetingHeader 组件 | `ui/home/components/GreetingHeader.kt` | — |
| 16.3 | TodayShiftCard 组件 | `ui/home/components/TodayShiftCard.kt` | — |
| 16.4 | StatsGrid 组件 | `ui/home/components/StatsGrid.kt` | — |
| 16.5 | QuickActionsRow 组件 | `ui/home/components/QuickActionsRow.kt` | — |
| 16.6 | MotivationFooter 组件 | `ui/home/components/MotivationFooter.kt` | — |
| 16.7 | 组装 NewHomeScreen + HomeViewModel 接入 | `ui/home/NewHomeScreen.kt` | `HomeViewModel.kt` |
| 16.8 | MainActivity 双轨接入 + 开关 | — | `MainActivity.kt` |
| 16.9 | 扩展测试覆盖 | — | `HomeViewModelTest.kt` |
| 16.10 | 切换默认首页 | — | `MainActivity.kt` |

### 预期新增

- 新增文件：8 个（1 domain + 5 components + 1 page + 1 test）
- 改造文件：3 个（HomeViewModel.kt, MainActivity.kt, HomeViewModelTest.kt）
- 新增测试：约 8 个用例（ShiftMetricsTest）
- 总测试：80 → 约 88

### 详细规划

参见 `implementation-plan.md` 阶段 16。

---

## 2026-05-13：阶段 16 实施完成

### 阶段 16：首页精品化升级 ✅

**16.1 HomeUiState 扩展 + domain 指标函数**
- 新增：`domain/shift_metrics.kt` — 4 个统计纯函数（`countShiftTypeInMonth`, `countWorkDaysInMonth`, `consecutiveWorkDays`, `daysUntilNextRest`）
- 新增：`ShiftMetricsTest.kt`（15 用例）
- 改造：`HomeViewModel.kt` — `HomeUiState` 新增 `teamName` 字段

**16.2-16.6 五个 UI 组件**
- 新增：`ui/home/components/GreetingHeader.kt` — 时段问候（早上好/下午好/晚上好/夜班辛苦了）
- 新增：`ui/home/components/TodayShiftCard.kt` — 今日班次主卡片（大字着色 + 进度 + 距休）
- 新增：`ui/home/components/StatsGrid.kt` — 三宫格指标卡片
- 新增：`ui/home/components/QuickActionsRow.kt` — 快捷操作按钮行
- 新增：`ui/home/components/MotivationFooter.kt` — 底部随机文案

**16.7 组装 NewHomeScreen + HomeViewModel 扩展**
- 新增：`ui/home/NewHomeScreen.kt` — 组合所有组件
- 改造：`HomeViewModel.kt` — `HomeUiState` 新增 `daysUntilRest`, `consecutiveWorkDays`, `monthlyWorkDays`, `totalDaysInMonth`；`refreshToday()` 调用 `shift_metrics.kt` 计算指标

**16.8 MainActivity 双轨接入**
- 改造：`MainActivity.kt` — 新增 `USE_NEW_HOME` 编译时常量，`composable("main")` 分支渲染旧/新首页

**16.9 扩展测试覆盖**
- 改造：`HomeViewModelTest.kt` — 新增 `teamName` 派生验证 + 指标字段填充验证（2 用例）

**16.10 切换默认首页**
- 改造：`MainActivity.kt` — `USE_NEW_HOME` 改为 `true`

### 新增/改造文件汇总

| 新增（8 个） | 改造（3 个） |
|-------------|-------------|
| `domain/shift_metrics.kt` | `viewmodel/HomeViewModel.kt` |
| `ShiftMetricsTest.kt`（15 用例） | `MainActivity.kt` |
| `ui/home/components/GreetingHeader.kt` | `HomeViewModelTest.kt`（+2 用例） |
| `ui/home/components/TodayShiftCard.kt` | |
| `ui/home/components/StatsGrid.kt` | |
| `ui/home/components/QuickActionsRow.kt` | |
| `ui/home/components/MotivationFooter.kt` | |
| `ui/home/NewHomeScreen.kt` | |

### 构建与测试

```bash
./gradlew assembleDebug        # BUILD SUCCESSFUL
./gradlew testDebugUnitTest    # BUILD SUCCESSFUL（97 个测试全部通过）
```

零回归。测试覆盖从 80 扩展到 97 个用例，11 个测试文件。

### 回滚

`MainActivity.kt` 中将 `USE_NEW_HOME` 改为 `false` 即恢复旧首页。

---

## 2026-05-14：首页日历分离 + TodayShiftCard 重设计 + Widget 美化

### 问题背景

1. **日历不应在首页**：设计文档中日历是独立页面，但 `"main"` 路由同时渲染首页和日历，且日历按钮无跳转
2. **今日班次卡片布局不合理**：纯纵向堆叠文字，无进度条，无横向空间利用，无班次颜色视觉区分
3. **桌面小部件样式落后**：新首页已升级但 Widget 仍是旧样式

### 日历分离

**改造文件**：

| 文件 | 改动 |
|------|------|
| `CalendarViewModel.kt` | `CalendarUiState` 新增 `selectedTeamId: Int = 1` 字段 |
| `CalendarScreen.kt` | 包装 `Scaffold` + `TopAppBar`（返回按钮 + 标题"倒班日历"）+ `TeamDropdown`；`StatsDialog` 移到 Scaffold 外部 |
| `MainActivity.kt` | `"main"` 路由移除 `CalendarScreen` 和 `calendarUiState` 收集；新增 `"calendar"` 独立路由；日历按钮 `onCalendarClick` → `navController.navigate("calendar")`；日历页班组切换同步 `homeViewModel` + `calendarViewModel` |

**导航结构**：`"main"`（首页）→ `"calendar"`（日历页）→ `"settings"`（设置页），各路由独立。

### TodayShiftCard 重设计

**文件**：`ui/home/components/TodayShiftCard.kt`

新布局（横向）：
```
┌──────────────────────────────────────┐
│ ▌ ┌──────┐                           │  左侧强调条(4dp) + 渐变背景
│ ▌ │  早  │  今日班次        距休 2天  │  圆形徽章(64dp) + 标题 + 休班徽章
│ ▌ │ 白字 │  周期进度                   │
│ ▌ └──────┘  ████████████░░  10/42    │  LinearProgressIndicator + 分数
└──────────────────────────────────────┘
```

- Card 背景：班次颜色 6% 透明度
- 左侧 4dp 强调条：班次强调色
- 圆形 Surface(64dp)：班次强调色底 + 白色班次大字
- `RestBadge`：距休=0 显示绿色"休息日"，>0 显示"距休 X天"
- 进度条：`LinearProgressIndicator` 使用班次颜色

### Widget 美化

**新增文件**：`res/values/colors.xml` 新增 5 个强调色 + 1 个进度轨道色

**改造文件**：

| 文件 | 改动 |
|------|------|
| `domain/widget_data.kt` | `WidgetShiftData` 新增 `daysUntilRest` 字段；`computeWidgetShiftData()` 调用 `daysUntilNextRest()` |
| `widget/ShiftWidget.kt` | 新布局：圆形徽章(圆角Box) + "今日班次"标题 + 距休标识 + 24段Text进度条(撑满宽度) + 日期页脚 |
| `res/xml/shift_widget_info.xml` | `minHeight`: 40→80dp, `targetCellHeight`: 1→2 |
| `WidgetDataTest.kt` | 新增 `daysUntilRest` 字段断言 |

Widget 新布局（最终采用）：
```
┌──────────────────────────────────────┐ ← 淡色班次背景
│  ┌───────┐                           │
│  │  早   │  一值          距休 2天   │ ← 圆角徽章 + 班组名 + 距休
│  │ 白字  │  第 10/42 天              │
│  └───────┘                           │
│  2026年5月14日 星期三                 │ ← 日期页脚
└──────────────────────────────────────┘
```

Glance 限制应对：
- 无 `LinearProgressIndicator`、无 `fillMaxWidth(fraction)`、`defaultWeight()` 不支持加权比例
- 放弃进度条，改用文字 "第 X/Y 天" 简洁表达
- 徽章：`cornerRadius(12.dp)` 圆角 Box + `background(accentColor)`

### 构建与测试

```bash
./gradlew assembleDebug        # BUILD SUCCESSFUL
./gradlew testDebugUnitTest    # BUILD SUCCESSFUL（全部测试通过）
```

零回归。Widget 尺寸恢复 4×1（`targetCellHeight=1`）。

---

## 2026-05-14：倒班助手 V2 首页精品化规划

### 设计方向

收到 V2 首页视觉提案：**深色高级 + 科技感 + 情绪治愈**。参考 Notion/Spotify/TickTick/Apple 的设计气质。

### V2 vs V1 关键变化

| 方面 | V1（当前） | V2（规划） |
|------|----------|----------|
| 设计语言 | 默认 Material3 浅色 | Dark Productivity Design（深色 + 克制高级感） |
| 主题 | 无自定义 Theme | Design Token 系统（Color/Type/Shape/Spacing） |
| 导航 | NavHost 三路由独立 | 底部导航栏（首页/日历/我的） |
| 班次色 | 橙/蓝/绿/紫/黄 | 夜=#7C5CFF、早=#FFB347、中=#4DA3FF、休=#35D07F、学=#F2D94E |
| 首页 | 横向卡片 + 进度条 | 240dp 渐变主卡 + 牛马指数 + 情境文案 |
| 日历页 | 彩色格子 + 统计弹窗 | 深色适配 + 底部统计常驻 + 今天高亮 |
| 设置页 | 独立路由 | 合并到"我的"页，卡片式菜单 |
| 动画 | 无 | fadeIn + slideUp 450ms |

### 实施策略（更新）

- **双轨制**：新增 `USE_NEW_HOME_V2` 标志，V1 组件全部保留不动
- **Design Token 先行**：`ui/theme/` 目录（Color.kt + Type.kt + Shape.kt + Theme.kt）作为全局基础设施
- **分 6 个 Phase**：Token + 首页 + 底部导航 + 日历页 + 我的页 + 全局主题
- **新增 V2 组件**：`V2GreetingHeader`, `V2TodayShiftCard`, `V2StatsGrid`, `V2QuickActionsRow`, `V2MotivationFooter`
- **扩展 HomeUiState**：`shiftTimeRange`（来自 AlarmSettings）、`monthlyShiftTypeCount`、`workIntensity`（牛马指数）
- **牛马指数**：`monthlyWorkDays * 100 / today.dayOfMonth`，≤40绿/41-70黄/>70红

### 预期新增/改造文件（更新）

| 类型 | 文件数 | 关键文件 |
|------|--------|---------|
| 新增 | 14 | `ui/theme/*` (4) + `V2*` 组件 (6) + `NewHomeScreenV2.kt` + `ProfileScreen.kt` + 测试 |
| 改造 | 5 | `HomeViewModel.kt`, `HomeViewModelTest.kt`, `MainActivity.kt`, `CalendarScreen.kt`, `SettingsScreen.kt` |
| 不变 | — | 所有 V1 组件、CalendarViewModel、SettingsViewModel、domain 层、Widget |

### 暂缓（V2.1+）

- 工资页（需独立 domain 逻辑 + 趋势图）、数据/统计页（需图表库）
- 骨架屏、数字滚动动画、页面水平滑动切换

### 详细规划

参见 `implementation-plan.md` 阶段 17。

---

## 2026-05-14：阶段 17 实施完成

### 阶段 17：V2 完整 UI 设计系统 ✅

**Phase 1：Design Token + 数据层扩展**

- 新增 `ui/theme/` 目录（Color.kt + Type.kt + Shape.kt + Theme.kt）
- Color.kt：Dark Productivity Design 颜色系统（3 背景 + 3 文字 + 5 班次色 + 4 语义色 + `v2ShiftColor()`）
- Type.kt：5 级自定义字体规格（28/20/16/13/36sp）
- Shape.kt：4 级圆角（Button 18dp / Card 24dp / MainCard 28dp / Sheet 32dp）
- Theme.kt：`ShiftSchedulerTheme`（基于 `darkColorScheme` + 自定义 Typography）

**Phase 2：HomeViewModel 扩展**
- `HomeUiState` 新增 3 个 V2 字段：`shiftTimeRange`（来自 AlarmSettings）、`monthlyShiftTypeCount`、`workIntensity`（牛马指数）
- `HomeViewModel` 新增 `updateAlarmSettings()` 方法
- `refreshToday()` 自动计算新字段
- `HomeViewModelTest` 追加 4 个 V2 测试用例

**Phase 3：MainActivity V2 接线**
- 新增 `USE_NEW_HOME_V2 = false` 编译时常量（双轨制安全开关）
- `alarmSettingsFlow` 收集时同步调用 `homeViewModel.updateAlarmSettings()`
- V2 路径：`ShiftSchedulerTheme` 包裹 + 底部 `NavigationBar`（首页/日历/我的）

**Phase 4：V2 首页组件**
- 新增 5 个 V2 组件（V2GreetingHeader / V2TodayShiftCard / V2StatsGrid / V2QuickActionsRow / V2MotivationFooter）
- V2TodayShiftCard：240dp 主卡，圆形班次徽章(72dp) + 牛马指数（≤40绿/41-70黄/>70红）+ `LinearProgressIndicator`
- `NewHomeScreenV2.kt` 组装全部组件，带 `fadeIn` + `slideInVertically` 动效

**Phase 5：日历页深色适配**
- `CalendarDayCell` 颜色从硬编码浅色改为主题感知：班次色 12% 透明度背景 + 彩色文字
- 今天描边：蓝色 → V2Accent 金色
- 统计从 `AlertDialog` 弹窗改为日历下方内联 `StatsCard`（5 列均布）
- `computeStats()` 改为 toggle 模式（再次点击关闭）
- 移除 `StatsDialog` / `StatsRow` 和 `onDismissStats` 参数

**Phase 6：ProfileScreen + 全局主题**
- 新增 `ui/profile/ProfileScreen.kt`：卡片式菜单（当前班组 + 倒班规则 + 提醒设置 + 给个好评 + 关于）
- V2 路径已通过 `ShiftSchedulerTheme` 全局应用深色主题
- 非 V2 路径（`USE_NEW_HOME_V2 = false`）完全不变

### 新增/改造文件汇总

| 新增（11 个） | 改造（5 个） |
|-------------|-------------|
| `ui/theme/Color.kt` | `viewmodel/HomeViewModel.kt` |
| `ui/theme/Type.kt` | `viewmodel/CalendarViewModel.kt` |
| `ui/theme/Shape.kt` | `MainActivity.kt` |
| `ui/theme/Theme.kt` | `ui/calendar/CalendarScreen.kt` |
| `ui/home/components/V2GreetingHeader.kt` | `HomeViewModelTest.kt`（+4 用例） |
| `ui/home/components/V2TodayShiftCard.kt` | |
| `ui/home/components/V2StatsGrid.kt` | |
| `ui/home/components/V2QuickActionsRow.kt` | |
| `ui/home/components/V2MotivationFooter.kt` | |
| `ui/home/NewHomeScreenV2.kt` | |
| `ui/profile/ProfileScreen.kt` | |

### 构建与测试

```bash
./gradlew assembleDebug        # BUILD SUCCESSFUL
./gradlew testDebugUnitTest    # BUILD SUCCESSFUL（全部测试通过）
```

零回归。V1 路径（`USE_NEW_HOME_V2 = false`）字节码完全不变。

### 启用 V2

`MainActivity.kt` 中将 `USE_NEW_HOME_V2` 改为 `true` 即启用完整 V2 体验（底部导航 + 新首页 + 牛马指数 + Profile 页）。主题自动跟随系统深色模式：浅色模式下卡片白底黑字、深色模式下暗底白字，功能完全一致。

---

## 2026-05-14：浅色/深色主题统一

### 问题

此前 `ShiftSchedulerTheme` 只定义了 `darkColorScheme`，浅色模式下退回 V1 布局（无底部导航、无 Profile），功能和深色模式不一致。

### 修复

- `Theme.kt`：新增 `LightColors`（`lightColorScheme`），`ShiftSchedulerTheme` 通过 `isSystemInDarkTheme()` 自动选择
- 所有 V2 组件（V2GreetingHeader / V2TodayShiftCard / V2StatsGrid / V2MotivationFooter / ProfileScreen）从硬编码 `V2PrimaryText`/`V2CardSurface` 等暗色常量改为引用 `MaterialTheme.colorScheme.onBackground`/`.surface`/`.onSurfaceVariant`
- `CalendarScreen` 的今天描边从 `V2Accent` 改为 `MaterialTheme.colorScheme.primary`
- `MainActivity.kt`：V2 路径条件恢复为 `USE_NEW_HOME_V2`（不再自身检查系统深色），主题切换由 `ShiftSchedulerTheme` 内部处理
- `USE_NEW_HOME_V2` 默认改为 `true`

### 结果

系统开深色 → 暗底白字 V2；系统关深色 → 白底黑字 V2。功能、布局、导航完全一致。

---

## 2026-05-14：首页精简（去重）

### 问题

首页 `NewHomeScreenV2` 中的 `QuickActionsRow`（日历/提醒/设置）和 `TeamDropdown`（班组选择）与底部导航栏及"我的"页功能重复。

### 修复

- `NewHomeScreenV2.kt`：移除 `V2QuickActionsRow` + `TeamDropdown` 组件，去掉 `onCalendarClick`/`onSettingsClick`/`onTeamSelected` 三个参数
- `MainActivity.kt`：`NewHomeScreenV2` 调用点去掉对应回调参数和 lambda

### 结果

首页只保留核心信息展示：问候语 + 今日班次卡片 + 三宫格指标 + 底部文案。班组切换在"我的"页，日历和设置通过底部导航栏访问。

---

## 2026-05-14：阶段 18 实施完成

### 阶段 18：倒班规则编辑器重设计 ✅

**Phase A：Domain/Data 基础**
- `RuntimeShiftSettings` 新增 `referenceDate: LocalDate` 字段（默认 `REFERENCE_DATE`）
- `shift_calculator.kt`：`getShiftTypeForDate()` / `getShiftInfo()` 新增 `referenceDate` 参数
- `shift_metrics.kt`：4 个函数各新增 `referenceDate` 参数
- `calendar_generator.kt`：`generateMonthCalendarDays()` 新增 `referenceDate` 参数
- `widget_data.kt`：透传 `settings.referenceDate`
- `SettingsRepository.kt`：新增 `reference_date` key，持久化/加载/回退

**Phase B：ViewModel 传播**
- `HomeViewModel` / `CalendarViewModel`：新增 `customReferenceDate` 字段，透传所有 domain 调用
- `CalendarEventManager` / `CalendarSyncManager`：`syncShiftEvents()` 新增 `referenceDate` 参数
- `MainActivity`：`settingsFlow` 收集器传播 `referenceDate` 到各 ViewModel

**Phase C：新 ViewModel**
- 新建 `ShiftRuleViewModel.kt`：两步向导状态管理（`ShiftRuleUiState`：step/rotationSequence/startDate/endDate/defaultTeamId）
  - 方法：`addToSequence` / `removeFromSequence` / `goToStep2` / `goBackToStep1` / `setStartDate` / `setEndDate` / `setDefaultTeam` / `save`
- 新建 `AlarmSettingsViewModel.kt`：纯闹钟管理（`updateAlarmTime` → 立即回调自动保存）

**Phase D：新 UI**
- 新建 `ShiftRuleEditorScreen.kt`（~230 行）：
  - Step 1：5 个彩色班次按钮 + FlowRow 序列展示（Chip + 红色 X 删除）+ 下一步
  - Step 2：Material3 DatePickerDialog 日期选择 + 结束日期 toggle + TeamDropdown + 序列预览 + 保存
- 新建 `AlarmSettingsScreen.kt`（~200 行）：从旧 SettingsScreen 提取闹钟 UI，无保存/取消按钮
- 旧 `SettingsScreen.kt` / `SettingsViewModel.kt` 保留（`USE_NEW_SETTINGS = false` 时使用）

**Phase E：导航接线**
- 新增 `USE_NEW_SETTINGS = true` 编译时常量
- V2 NavHost 新增 `"shift_rule_editor"` + `"alarm_settings"` 路由
- ProfileScreen 回调：`onRulesClick` → `"shift_rule_editor"`，`onAlarmClick` → `"alarm_settings"`

### 新增/改造文件汇总

| 新增（4 个） | 改造（11 个） |
|-------------|-------------|
| `viewmodel/ShiftRuleViewModel.kt` | `domain/model/RuntimeShiftSettings.kt` |
| `viewmodel/AlarmSettingsViewModel.kt` | `domain/shift_calculator.kt` |
| `ui/settings/ShiftRuleEditorScreen.kt` | `domain/shift_metrics.kt` |
| `ui/settings/AlarmSettingsScreen.kt` | `domain/calendar_generator.kt` |
| | `domain/widget_data.kt` |
| | `data/repository/SettingsRepository.kt` |
| | `viewmodel/HomeViewModel.kt` |
| | `viewmodel/CalendarViewModel.kt` |
| | `calendar/CalendarEventManager.kt` |
| | `calendar/CalendarSyncManager.kt` |
| | `MainActivity.kt` |

### 构建与测试

```bash
./gradlew assembleDebug        # BUILD SUCCESSFUL
./gradlew testDebugUnitTest    # BUILD SUCCESSFUL（全部测试通过）
```

零回归。所有 domain 新参数均为默认值，旧调用点无需修改。

---

## 2026-05-14：阶段 19 规划（拼假神器）

### 功能概述

拼假神器（请假优化器）是差异化核心功能。自动分析今日至年底，结合用户的倒班表 + 中国法定节假日，找到"请最少假、连休最久"的最佳请假方案。

**核心价值**：倒班人员的妻儿老小遵循正常节假日作息。拼假神器帮助用户用最少的年假，在家人放假时最大化团聚时间。

**输出示例**：
- 请假 2 天 → 连休 6 天（含端午节假期，效率 3.0x）
- 请假 1 天 → 连休 4 天（含周末，效率 4.0x）
- 请假 3 天 → 连休 9 天（含国庆节假期，效率 3.0x）

### 技术方案

| 项 | 选择 |
|---|------|
| 算法 | 间隙桥接法（Gap-Merging），O(365) 复杂度 |
| 分析范围 | 今日至当年 12 月 31 日（不跨年） |
| 节假日数据 | 本地内置 `holiday_data.kt`，无需网络请求 |
| 最大请假天数 | 默认 5 天，可筛选 |
| 评分体系 | 效率分(50%) + 长度分(25%) + 家庭分(25%) |
| UI 入口 | "我的"页 → "拼假神器"菜单项 |
| 主题 | 复用 V2 Design Token，自适应深色/浅色 |

### 算法核心：间隙桥接法

1. 生成 365 天每日状态（isRest + isHoliday + isWeekend + isAdjustedWorkDay）
2. 识别"休息块"（连续休班日）和"工作间隙"（两块休息之间的连续工作日）
3. 对于每个工作间隙 ≤ maxLeaveDays：请假桥接 → 左右休息块合并 = 一个长连休
4. 补充延伸策略：在休息块前后请 N 天延长休息
5. 综合评分排序（效率 + 长度 + 家庭重叠）
6. 去重，输出策略列表

### 法定节假日数据

- 2026 年：官方已发布（元旦/春节/清明/劳动节/端午/中秋/国庆 + 调休日）
- 2027 年：基于农历推算，标记"待国务院确认"
- 数据文件 `domain/holiday_data.kt`，每年更新一次即可
- 同时检测周末（周六/周日），使家庭重叠计算准确

### 实施步骤（阶段 19）

| Step | 内容 | 新增文件 | 改造文件 |
|------|------|---------|---------|
| 19.1 | 数据模型 + 节假日数据 | `LeaveStrategy.kt`, `holiday_data.kt`, `HolidayDataTest.kt` | — |
| 19.2 | 核心拼假算法 | `leave_optimizer.kt`, `LeaveOptimizerTest.kt` | — |
| 19.3 | LeaveOptimizerViewModel | `LeaveOptimizerViewModel.kt` | — |
| 19.4 | LeaveOptimizerScreen UI | `LeaveOptimizerScreen.kt` | — |
| 19.5 | 导航集成 | — | `MainActivity.kt`, `ProfileScreen.kt` |
| 19.6 | 单元测试（已完成在 19.1-19.2 中） | — | — |
| 19.7 | 文档更新 | — | memory-bank 全部 5 文件 |

### 预期新增

- 新增文件：7 个（domain/model/LeaveStrategy.kt, domain/holiday_data.kt, domain/leave_optimizer.kt, viewmodel/LeaveOptimizerViewModel.kt, ui/leave_optimizer/LeaveOptimizerScreen.kt, LeaveOptimizerTest.kt, HolidayDataTest.kt）
- 改造文件：2 个（MainActivity.kt, ProfileScreen.kt）
- 新增测试：约 19 个用例（LeaveOptimizerTest 15 用例 + HolidayDataTest 4 用例）
- 总测试：97 → 约 116

### 详细规划

参见 `implementation-plan.md` 阶段 19。

---

## 2026-05-14：阶段 19 实施完成

### 阶段 19：拼假神器（请假优化器）✅

**19.1 数据模型 + 节假日数据**
- 新增：`domain/model/LeaveStrategy.kt` — LeaveStrategy 数据模型（10 个字段含综合评分）
- 新增：`domain/holiday_data.kt` — 中国法定节假日数据：
  - 2026 年全部节假日（元旦/春节/清明/劳动节/端午/中秋/国庆）+ 调休工作日
  - 2027 年节假日（基于农历推算，标记"[待确认]"）
  - `HolidayInfo(date, name, isHoliday)` + `isWeekend()` + `isNaturallyOff()` 辅助函数

**19.2 核心拼假算法**
- 新增：`domain/leave_optimizer.kt` — 间隙桥接法（Gap-Merging）：
  - `buildDailyStatus()`：构建 365 天每日状态（isRest/isHoliday/isWeekend/isAdjustedWorkDay）
  - `findBestLeavePlans()`：主入口，扫描工作间隙 → 请假桥接 → 评分排序
  - 预计算 restBefore/restAfter 数组，O(365 × maxLeaveDays) 复杂度
  - 综合评分：效率分(50%) + 长度分(25%) + 家庭分(25%)
  - 同一连休区间自动去重（保留请假天数最少方案）
  - `teamPhaseOffsetFor()` 辅助函数

**19.3 LeaveOptimizerViewModel**
- 新增：`viewmodel/LeaveOptimizerViewModel.kt` — StateFlow 状态管理
  - `LeaveOptimizerUiState`：strategies/selectedTeamId/maxLeaveDays/analyzedDateRange/isLoading
  - `refresh(customCycle, referenceDate, teamId)`：调用算法并发射状态
  - `setMaxLeaveDays(days)`：切换筛选天数并重新计算
  - 支持 `todayProvider` 注入（测试性）

**19.4 LeaveOptimizerScreen UI**
- 新增：`ui/leave_optimizer/LeaveOptimizerScreen.kt`（~340 行 Compose）
  - TopAppBar "拼假神器" + 返回按钮
  - 说明区（分析范围 + 班组信息）
  - FilterChip 行：1-5 天筛选
  - LazyColumn 策略卡片列表（入场动画 fadeIn + slideInVertically）
  - StrategyCard：前三名金/银/铜边框 + 大字体"请假N天→连休M天" + 日期范围 + 节日徽章 + 效率标签 + MiniCalendarBar
  - MiniCalendarBar：24 天缩略窗，请假日实心圆、休息日半透明、其他日浅灰
  - 加载中（CircularProgressIndicator）和空状态处理

**19.5 导航集成**
- 改造：`MainActivity.kt` — 新增 `"leave_optimizer"` 路由 + LeaveOptimizerViewModel factory + LaunchedEffect 自动刷新
- 改造：`ui/profile/ProfileScreen.kt` — 新增 `onLeaveOptimizerClick` 参数 + "拼假神器"菜单项（在提醒设置下方）

**19.6 单元测试** — 23 个新测试全部通过
- 新增：`LeaveOptimizerTest.kt`（17 用例）
  - buildDailyStatus 基本属性（大小/日期/isRest/周末/节假日/调休）
  - 间隙桥接（2天间隙/1天间隙/间隙超限/全休息无方案）
  - 去重验证、评分排序验证、节日重叠加分
  - 自定义周期、班组偏移、边界参数
  - 策略字段完整性、节日名称捕获
- 新增：`HolidayDataTest.kt`（6 用例）
  - 无重复日期、覆盖未来365天、调休日标记、主要节日存在
  - isWeekend 检测、isNaturallyOff 综合判断

### 新增/改造文件汇总

| 新增（7 个） | 改造（2 个） |
|-------------|-------------|
| `domain/model/LeaveStrategy.kt` | `MainActivity.kt`（+50 行） |
| `domain/holiday_data.kt`（~110 行） | `ui/profile/ProfileScreen.kt`（+12 行） |
| `domain/leave_optimizer.kt`（~170 行） | |
| `viewmodel/LeaveOptimizerViewModel.kt`（~80 行） | |
| `ui/leave_optimizer/LeaveOptimizerScreen.kt`（~340 行） | |
| `LeaveOptimizerTest.kt`（17 用例） | |
| `HolidayDataTest.kt`（6 用例） | |

### 构建与测试

```bash
./gradlew assembleDebug        # BUILD SUCCESSFUL（零警告）
./gradlew testDebugUnitTest    # BUILD SUCCESSFUL（124 个测试全部通过）
```

零回归。测试覆盖从 97 扩展到 124 个用例（+27），13 个测试文件。

### 分析范围调整

分析范围从"未来 365 天（跨年）"改为"今日至当年 12 月 31 日（不跨年）"，确保策略卡片中所有日期均在同年，显示"6月15日 — 6月20日"无需年份即可无歧义。

### 入口

"我的"页 → "拼假神器"菜单项（在提醒设置下方）。不在底部导航栏新增 Tab。

### 节假日数据维护

每年 11-12 月国务院发布下一年节假日安排后，更新 `domain/holiday_data.kt` 中的 2027 年数据（去除 `[待确认]` 标记），并追加 2028 年推算数据。

---

## 2026-05-14：阶段 20 规划（同事模式）

### 功能概述

同事模式是社交裂变功能。输入两个人的班组，自动计算下次同时休息日期和共同休息天数。情侣、朋友、同事都会使用，结果截图天然适合社交传播。

**核心价值**：不同班组的倒班人员休息日不同。"下次同时休息：5月28日"是天然对话素材。传播力极强。

**输出示例**：
- 我是一值，他是三值
- 下次同时休息：5月28日 星期三（距今 14 天）
- 未来30天共同休息：3 次
- 未来60天共同休息：7 次
- 完整共同休息日列表

### 技术方案

| 项 | 选择 |
|---|------|
| 算法 | 双班组逐日交叉对比，O(n)，比拼假神器简单一个量级 |
| 分析范围 | 今日至当年 12 月 31 日（与拼假神器一致，不跨年） |
| 默认值 | "我"=用户当前班组，"他"=相邻班组 |
| UI 入口 | "我的"页 → "同事模式"菜单项（在拼假神器下方） |
| 主题 | 复用 V2 Design Token |

### 算法核心：双班组交叉对比

```
对每一天 date：
  shiftA = getShiftTypeForDate(date, phaseOffsetA, cycle)
  shiftB = getShiftTypeForDate(date, phaseOffsetB, cycle)
  if (shiftA is REST or STUDY) and (shiftB is REST or STUDY):
    → 共同休息日
```
O(n)，n ≤ 365。约 30 行纯函数。

### 社交传播设计

- "下次同时休息：5月28日" 是大字体具体日期 → 天然对话素材
- 结果页面信息密度高 → 截图即社交分享内容
- 两个人一起看屏幕 → 主卡片视觉冲击力强
- 默认值降低操作门槛（零操作即可看到有意义结果）

### 实施步骤（阶段 20）

| Step | 内容 | 新增文件 | 改造文件 |
|------|------|---------|---------|
| 20.1 | 数据模型 | `CommonRestResult.kt` | — |
| 20.2 | 核心算法 | `colleague_mode.kt`, `ColleagueModeTest.kt` | — |
| 20.3 | ViewModel | `ColleagueModeViewModel.kt` | — |
| 20.4 | UI | `ColleagueModeScreen.kt` | — |
| 20.5 | 导航集成 | — | `MainActivity.kt`, `ProfileScreen.kt` |
| 20.6 | 单元测试 | — | — |
| 20.7 | 文档更新 | — | memory-bank 全部 5 文件 |

### 预期新增

- 新增文件：5 个（domain/model/CommonRestResult.kt, domain/colleague_mode.kt, viewmodel/ColleagueModeViewModel.kt, ui/colleague_mode/ColleagueModeScreen.kt, ColleagueModeTest.kt）
- 改造文件：2 个（MainActivity.kt, ProfileScreen.kt）
- 新增测试：8 个用例（ColleagueModeTest）
- 总测试：124 → 132（实际结果）

### 详细规划

参见 `implementation-plan.md` 阶段 20。

---

## 2026-05-14：阶段 20 实施完成

### 阶段 20：同事模式（社交裂变）✅

**20.1 数据模型**
- 新增：`domain/model/CommonRestResult.kt` — CommonRestResult 数据模型（10 个字段：双班组名/下次日期/距今/列表/计数）

**20.2 核心算法**
- 新增：`domain/colleague_mode.kt` — 双班组逐日交叉对比：
  - `findCommonRestDays(teamAId, teamBId, today, daysToAnalyze, customCycle, referenceDate)` — 逐日计算两人班次，取 REST/STUDY 交集
  - O(n) 复杂度，~40 行纯函数
  - 复用 `getShiftTypeForDate()` + `teamPhaseOffsetFor()`

**20.3 ColleagueModeViewModel**
- 新增：`viewmodel/ColleagueModeViewModel.kt` — 双班组选择 + 结果刷新
  - `setTeamA(id)` / `setTeamB(id)` / `swapTeams()` — 班组切换即刷新
  - `refresh(customCycle, referenceDate)` — 分析范围"今日至年底"
  - 同一班组自动提示

**20.4 ColleagueModeScreen UI**
- 新增：`ui/colleague_mode/ColleagueModeScreen.kt`（~290 行 Compose）
  - TopAppBar "同事模式" + 返回按钮
  - 双班组选择区：两个 TeamDropdown 并排（"我是"/"他是"）+ SwapHoriz 交换按钮
  - NextRestCard 主结果卡片：渐变背景 + 大字体"X月X日" + 星期 + 倒计时
  - StatCard 统计行（30天/60天共同休息次数）
  - CommonRestDateRow 日期列表（每行日期 + 星期 + "X天后"）
  - 同班组提示、无交集空状态

**20.5 导航集成**
- 改造：`MainActivity.kt` — 新增 `"colleague_mode"` 路由 + ColleagueModeViewModel factory
  - 默认"我"使用当前用户班组
- 改造：`ui/profile/ProfileScreen.kt` — 新增"同事模式"菜单项（拼假神器下方，People 图标）

**20.6 单元测试** — 8 个新测试全部通过
- 新增：`ColleagueModeTest.kt`（8 用例）
  - 同班组=全部休息日、不同班组=取交集、nextCommonRestDate=最早
  - daysUntilNext=0 当天、30/60天计数准确、自定义周期、无交集空结果、字段完整性

### 新增/改造文件汇总

| 新增（5 个） | 改造（2 个） |
|-------------|-------------|
| `domain/model/CommonRestResult.kt` | `MainActivity.kt`（+45 行） |
| `domain/colleague_mode.kt`（~40 行） | `ui/profile/ProfileScreen.kt`（+12 行） |
| `viewmodel/ColleagueModeViewModel.kt`（~90 行） | |
| `ui/colleague_mode/ColleagueModeScreen.kt`（~290 行） | |
| `ColleagueModeTest.kt`（8 用例） | |

### 构建与测试

```bash
./gradlew assembleDebug        # BUILD SUCCESSFUL（零警告）
./gradlew testDebugUnitTest    # BUILD SUCCESSFUL（132 个测试全部通过）
```

零回归。测试覆盖从 124 扩展到 132 个用例（+8），14 个测试文件。

### 社交传播亮点

- "下次同时休息：5月28日" 是大字体具体日期 → 天然对话素材
- 双班组并排下拉 + 交换按钮 → 两个人一起操作体验好
- 结果页面信息密度高 → 截图即社交分享内容
- 默认值（"我"=当前班组，"他"=相邻班组）→ 零操作即可看到有意义结果

---

## 2026-05-14：阶段 21 实施完成

### 阶段 21：倒班津贴计算器 ✅

**21.1 数据模型**
- 新增：`domain/model/SalaryConfig.kt` — 津贴配置模型（`shiftPremiums: Map<ShiftType, Int>`）
- 新增：`domain/model/SalaryBreakdown.kt` — 津贴明细模型（`month/shiftCounts/shiftPremiumTotal`）

**21.2 SettingsRepository 扩展**
- 改造：`SettingsRepository.kt` — 新增 `KEY_SHIFT_PREMIUMS` + `salaryConfigFlow` + `saveSalaryConfig()`
  - 序列化格式：`"MORNING=0,AFTERNOON=50,NIGHT=200,STUDY=0"`（逗号分隔键值对）
- 改造：`SettingsRepositoryTest.kt` — 追加 2 个测试用例（读写往返 + 默认空）

**21.3 核心算法**
- 新增：`domain/salary_calculator.kt` — 3 个纯函数（~50 行）：
  - `countAllShiftTypesInMonth()` — 统计当月全部 5 种班次出现次数
  - `calculateSalaryBreakdown()` — 班次统计 × 补贴单价 = 津贴明细
  - `simulateExtraShifts()` — 假设分析：多上 X 天某班次的增量
- 新增：`SalaryCalculatorTest.kt`（8 用例）

**21.4 SalaryPredictorViewModel**
- 新增：`viewmodel/SalaryPredictorViewModel.kt`（~110 行）
  - `SalaryPredictorUiState`：salaryConfig/breakdown/simulatedBreakdown/selectedTeamId/currentMonth/extraShiftsCount/extraShiftType/isLoading/isSettingsExpanded
  - 方法：`updateConfig`/`setTeam`/`setMonth`/`setExtraShiftsCount`/`setExtraShiftType`/`toggleSettingsExpanded`/`refresh`
  - `updateConfig()` 立即写入 DataStore 并自动重新计算

**21.5 SalaryPredictorScreen UI**
- 新增：`ui/salary_predictor/SalaryPredictorScreen.kt`（~310 行 Compose）
  - TopAppBar "倒班津贴" + 返回按钮
  - `SettingsSection`：可折叠津贴设置区（早/中/夜/学 4 行 × OutlinedTextField）
  - `MonthTeamRow`：月份左右切换 + 班组下拉
  - `PremiumTotalCard`：大字体 ¥金额（36sp Bold）+ 主色背景
  - `ShiftBreakdownSection`：彩色班次标签行 + 各津贴贡献明细
  - `SimulationCard`：FilterChip 0-5 天 + 班次类型下拉 + 增量结果

**21.6 导航集成**
- 改造：`MainActivity.kt` — 新增 `"salary_predictor"` 路由 + SalaryPredictorViewModel factory + `currentSalaryConfig` 状态流收集
- 改造：`ui/profile/ProfileScreen.kt` — 新增"倒班津贴"菜单项（同事模式下方，AttachMoney 图标）+ `onSalaryPredictorClick` 回调

### 新增/改造文件汇总

| 新增（6 个） | 改造（4 个） |
|-------------|-------------|
| `domain/model/SalaryConfig.kt` | `data/repository/SettingsRepository.kt` |
| `domain/model/SalaryBreakdown.kt` | `MainActivity.kt` |
| `domain/salary_calculator.kt` | `ui/profile/ProfileScreen.kt` |
| `viewmodel/SalaryPredictorViewModel.kt` | `SettingsRepositoryTest.kt`（+2 用例） |
| `ui/salary_predictor/SalaryPredictorScreen.kt` | |
| `SalaryCalculatorTest.kt`（8 用例） | |

### 构建与测试

```bash
./gradlew assembleDebug        # BUILD SUCCESSFUL（零警告）
./gradlew testDebugUnitTest    # BUILD SUCCESSFUL（142 个测试全部通过）
```

零回归。测试覆盖从 132 扩展到 142 个用例（+10），15 个测试文件。

### 为何只算班次补贴

基本工资、餐补、五险一金、个税——每个企业发放方式不同，算不准反而失信。班次补贴是唯一 100% 由倒班表决定的收入，算得准、零维护、普适所有倒班企业。

---

## 2026-05-14：阶段 22 实施完成

### 阶段 22：图片分享功能（社交传播）✅

**22.1 ZXing 依赖 + FileProvider 配置**
- 新增：`res/xml/file_paths.xml` — cache-path 定义
- 改造：`app/build.gradle.kts` — 新增 `zxing:core:3.5.3`
- 改造：`AndroidManifest.xml` — 新增 FileProvider `<provider>`

**22.2 Domain 层 QR 码生成**
- 新增：`domain/qr_code_generator.kt`（~35 行）— QRCodeWriter 编码 + BitMatrix → Bitmap
- 常量 `SHARE_QR_URL = "https://www.bilibili.com"` 集中管理，上架后替换

**22.3 图片渲染工具**
- 新增：`util/ShareImageRenderer.kt`（~80 行）
  - `renderComposableToBitmap()` — suspend 函数，临时 attach ComposeView 到 Activity decorView（alpha=0），用 `suspendCoroutine` + `LaunchedEffect(Unit)` 等待首帧，measure/layout/draw 后 finally 移除
  - `saveBitmapToShareCache()` — PNG 写入 cacheDir → FileProvider Uri
  - `cleanupOldShareImages()` — 24h TTL 过期文件清理

**22.4 分享图 Composable 布局**
- 新增：`ui/colleague_mode/ShareCardLayout.kt`（~220 行）— ShareCardData 数据模型 + ShareCardLayout @Composable
- 1080px 宽固定像素级布局，V2 Dark Productivity Design 风格

**22.5 ViewModel 分享状态**
- 改造：`viewmodel/ColleagueModeViewModel.kt`
- `ColleagueModeUiState` 新增：`isSharing`/`shareUri`/`shareError`
- 新增方法：`startShare(activity)`/`onShareComplete()`/`clearShareError()`/`buildShareCardData()`

**22.6 UI 分享按钮 + 触发系统分享**
- 改造：`ui/colleague_mode/ColleagueModeScreen.kt`
- TopAppBar 新增 Share IconButton（有结果且不同班组时可用）
- `LaunchedEffect(shareUri)` → `Intent.ACTION_SEND` + `FLAG_GRANT_READ_URI_PERMISSION`
- `SnackbarHost` + error 显示

**22.7 缓存清理**
- 改造：`MainActivity.kt` — `onCreate()` 中调用 `cleanupOldShareImages()`

**22.8 单元测试** — 8 个测试全部通过
- 新增：`ShareImageTest.kt`（8 用例）
- 覆盖：QR 非空/尺寸/黑白像素/不同内容差异/URL 合法性/ShareCardData 构造/缓存过期清理/空目录处理

### 离线渲染修复

初版 `renderComposableToBitmap` 直接创建未 attach 的 `ComposeView`，报错 `Cannot locate windowRecomposer; View is not attached to a window`。

**修复**：改为 `suspend fun Activity.renderComposableToBitmap()`：
1. `decorView.addView(composeView)` 临时 attach（alpha=0 不可见）
2. `setContent { LaunchedEffect(Unit) { resume() } }` 等待首帧组合
3. `measure/layout` → `draw(Canvas(bitmap))`
4. `finally { decorView.removeView(composeView) }`

### 新增/改造文件汇总

| 新增（5 个） | 改造（5 个） |
|-------------|-------------|
| `domain/qr_code_generator.kt` | `app/build.gradle.kts` |
| `util/ShareImageRenderer.kt` | `AndroidManifest.xml` |
| `ui/colleague_mode/ShareCardLayout.kt` | `viewmodel/ColleagueModeViewModel.kt` |
| `res/xml/file_paths.xml` | `ui/colleague_mode/ColleagueModeScreen.kt` |
| `ShareImageTest.kt`（8 用例） | `MainActivity.kt` |

### 构建与测试

```bash
./gradlew assembleDebug        # BUILD SUCCESSFUL（零警告）
./gradlew testDebugUnitTest    # BUILD SUCCESSFUL（150 个测试全部通过）
```

零回归。测试覆盖从 142 扩展到 150 个用例（+8），16 个测试文件。

### 线程安全编排

```
用户点击分享 → isSharing = true (UI loading)
  → Dispatchers.Default: buildShareCardData + generateQrCodeBitmap
  → Main (suspend):      Activity.renderComposableToBitmap (decorView attach + 等待首帧 + draw)
  → Dispatchers.IO:      saveBitmapToShareCache (PNG 写入)
  → LaunchedEffect:      Intent.ACTION_SEND 弹出系统分享面板
```

### 分享图 Layout 尺寸

- 宽：1080px 固定（360dp × 3x），微信朋友圈标准分辨率
- 高：~1920px（内容自适应，9:16 比例）
- 格式：PNG 无损

### 暂缓（V2.2+）

- 拼假神器分享图（需分页渲染策略卡片列表）
- 倒班津贴分享图（收入隐私敏感）
- 多分辨率适配（动态缩放）
- SHARE_QR_URL 远程配置（Firebase Remote Config）

---

## 2026-05-14：阶段 23 实施完成

### 阶段 23：提醒时间选择器改进 ✅

**方案决策**：经对比 Android 原生 `TimePickerDialog` vs 升级 BOM + Material3 `TimePicker`，**选择方案 B（升级 BOM）**。理由：升级路径全在 Kotlin 1.9.x / Compiler 1.5.x 同主版本内，风险可控；一次升级长期受益（后续开发不受 BOM 2023.10.01 限制）；Material3 TimePicker 视觉与 V2 Design Token 完全一致。

**23.1 工具链升级**
- 改造：`build.gradle.kts` (root) — Kotlin `1.9.20` → `1.9.24`
- 改造：`app/build.gradle.kts` — Compose Compiler `1.5.4` → `1.5.14`；BOM `2023.10.01` → `2024.04.00`
- Material3 自动从 `1.1.2` → `1.2.1`（TimePicker + AutoMirrored icons 等新 API）
- AGP 8.2.0 / Gradle 8.4 保持不变

**23.2 构建 + 测试验证**（安全检查点）
- `./gradlew assembleDebug` — BUILD SUCCESSFUL（6 个新 deprecation warnings：`LinearProgressIndicator` lambda 形式、`ArrowBack` AutoMirrored、`KeyboardArrowLeft/Right` AutoMirrored，均为 Material3 1.2.x 正常 API 迁移）
- `./gradlew testDebugUnitTest` — BUILD SUCCESSFUL（150 测试全部通过，零回归）

**23.3 Material3 TimePicker 实现**
- 改造：`ui/settings/AlarmSettingsScreen.kt`
  - 删除 `AlarmTimePickerDialog` composable（~70 行，两个 `OutlinedTextField` 时/分分离输入）
  - `ShiftAlarmRow` 中改用 `rememberTimePickerState` + `TimePicker` + `AlertDialog`
  - "关闭提醒"：`dismissButton` Row 中两个按钮（红色"关闭提醒" + "取消"）
  - `ArrowBack` 迁移至 `Icons.AutoMirrored.Filled.ArrowBack`（消除新 BOM 的 deprecation warning）
  - 新增 `@OptIn(ExperimentalMaterial3Api::class)`（TimePicker 在 Material3 1.2.x 为实验性 API）

**23.4 最终验证**
- `./gradlew assembleDebug` — BUILD SUCCESSFUL（零警告）
- `./gradlew testDebugUnitTest` — BUILD SUCCESSFUL（150 测试全部通过）

### 升级汇总

| 组件 | 旧版本 | 新版本 |
|------|--------|--------|
| Kotlin | 1.9.20 | 1.9.24 |
| Compose Compiler | 1.5.4 | 1.5.14 |
| Compose BOM | 2023.10.01 | 2024.04.00 |
| Material3 | 1.1.2 | 1.2.1 |
| Compose UI | 1.5.4 | 1.6.1 |

### 改造成果

| 文件 | 改动 | 净效果 |
|------|------|--------|
| `build.gradle.kts` (root) | Kotlin 版本号 | 1 行 |
| `app/build.gradle.kts` | Compiler + BOM 版本号 | 2 行 |
| `AlarmSettingsScreen.kt` | AlarmTimePickerDialog → Material3 TimePicker | 删除 ~70 行，新增 ~40 行，净减 ~30 行 |

---

## 2026-05-14：阶段 24 实施完成

### 阶段 24：Material3 1.2.x deprecation cleanup ✅

阶段 23 BOM 升级后 Material3 1.2.x 引入了 13 个 deprecation warnings（分布在 9 个文件中），全部清零。

**ArrowBack → Icons.AutoMirrored.Filled.ArrowBack**（6 文件）：
- `CalendarScreen.kt`、`ColleagueModeScreen.kt`、`LeaveOptimizerScreen.kt`、`SalaryPredictorScreen.kt`、`SettingsScreen.kt`、`ShiftRuleEditorScreen.kt`

**KeyboardArrowLeft/Right → AutoMirrored**（2 文件）：
- `CalendarScreen.kt`、`SalaryPredictorScreen.kt`

**LinearProgressIndicator(Float) → lambda**（2 文件）：
- `V2TodayShiftCard.kt`：`progress = progress` → `progress = { progress }`
- `TodayShiftCard.kt`：`progress = dayOfCycle.toFloat() / totalDays.toFloat()` → `progress = { dayOfCycle.toFloat() / totalDays.toFloat() }`

**测试 "No cast needed"**（1 文件）：
- `AlarmSettingsTest.kt`：`null as AlarmTime?` → `null`（+ 显式类型声明）

### 构建与测试

```bash
./gradlew clean assembleDebug     # BUILD SUCCESSFUL（零警告！）
./gradlew testDebugUnitTest       # BUILD SUCCESSFUL（150 测试零回归）
```

全部机械替换，零逻辑变更，零风险。

---

## 2026-05-15：首页 V2 精品化重构规划

### 背景

当前首页（V2）已完成组件化和 Design Token 体系，但存在"工程页面"感——信息层级扁平、休息日无氛围差异、"牛马指数"命名不专业、距休倒计时埋在主卡片内部视觉权重不足。需要进行一轮精品化审计和重构规划。

### 审计范围

- 完整阅读 memory-bank 全部文件（progress.md、implementation-plan.md、architecture.md、app-design-document.md）
- 完整审查当前首页链路：`NewHomeScreenV2.kt` + 5 个 V2 组件 + `HomeViewModel.kt` + `MainActivity.kt` + theme 文件
- 检查 `HomeUiState` 21 个字段的使用情况和信息层级

### 审计结论

**优点**（7 项）：组件化架构成熟、Design Token 完整、双轨制安全网、Domain 纯函数、导航清晰、深浅色双主题、动画已有基础。

**问题**（17 项）：
- UI 层级问题 5 项：240dp 卡片过高、信息重复（距休两处出现）、间距均匀无分组、底部文案无上下文、班组名占首行
- 组件耦合问题 3 项：参数列表过长、无语义化聚合对象、数据共享缺语义
- 可维护性问题 3 项：refreshToday() 过长、牛马指数内联、三轨并存复杂度
- 工程页面感 7 项："牛马指数"命名、数字无解读、休息日无氛围切换、进度条冷冰冰、无 0.5 秒信息层级、主卡片空间低效、缺少每日必看锚点

### V3 规划核心决策

1. **距休倒计时独立强化**：从 TodayShiftCard 内部提升为独立 RestCountdownCard，作为"每日必看锚点"
2. **融合问候+班次为氛围横幅**：ShiftHeroBanner 替代 GreetingHeader + TodayShiftCard，休息日/工作日氛围不同
3. **"牛马指数"重新定义为"劳逸比"**：去掉负面命名，移入月度概览折叠区
4. **底部文案从随机池改为上下文决策树**：根据班次类型 + 距休 + 连续上班天数匹配文案
5. **信息间距分 3 级**（12/16/24dp）替代统一 20dp
6. **零新字段**：HomeUiState 无需扩展，V3 是纯 UI 层重构
7. **不改 domain 层、不改 HomeViewModel 逻辑**

### V3 组件结构

```
NewHomeScreenV3
├── V3ShiftHeroBanner       全宽氛围横幅（48sp 班次大字 + 渐变背景）
├── V3RestCountdownCard     距休倒计时独立卡片（每日必看锚点）
├── V3FeatureHub            特色功能入口行（拼假神器 / 同事模式 / 倒班津贴）
├── V3ProgressIndicator     轻量周期进度（一行高度）
├── V3MonthlyOverview       月度概览（折叠/展开）
└── V3ContextualMessage     上下文共情文案（决策树匹配）
```

### 实施策略

- 双轨制：`USE_NEW_HOME_V3` 编译时常量，V2 全部保留
- 10 个 Step，每步 build + test 可通过
- 新增 7-8 个文件（~480 行），改造 2-3 个文件（~15 行）
- 不变：domain 层、HomeViewModel、theme 体系、所有 V1/V2 组件
- FeatureHub 入口在首页，但"我的"页保留相同的三个菜单项作为次级入口

### 详细规划

参见 `memory-bank/implementation-plan.md` 阶段 25。

---

## 2026-05-15：阶段 25 实施完成 — 首页 V3 精品化重构

### 阶段 25：首页 V3 精品化重构 ✅

**V3.1 V3ShiftHeroBanner**
- 新增：`ui/home/components/V3ShiftHeroBanner.kt`（~85 行）
- 全宽氛围横幅：班次颜色渐变背景 + 时段问候 + 日期 + 48sp 大字班次 + 可选提醒时间
- 替代 V2GreetingHeader + V2TodayShiftCard 上半部分

**V3.2 V3RestCountdownCard**
- 新增：`ui/home/components/V3RestCountdownCard.kt`（~120 行）
- 三态卡片：今日休息（绿色氛围）/ 明天休息（预提醒）/ 距休 N 天 + 预计日期
- 从今日班次卡片中独立出来，作为"每日必看锚点"强化视觉权重

**V3.3 V3FeatureHub**
- 新增：`ui/home/components/V3FeatureHub.kt`（~110 行）
- 三列等宽特色功能入口卡片（拼假神器 / 同事模式 / 倒班津贴）
- 从"我的"页二级菜单提升到首页直接曝光，一次点击可达
- Primary 色图标 + 诱惑文案（"请最少假·连休最久"等）

**V3.4 V3ProgressIndicator**
- 新增：`ui/home/components/V3ProgressIndicator.kt`（~65 行）
- 轻量周期进度：一行"本轮周期 · 第 X 天 · 共 Y 天" + 4dp 进度条

**V3.5 V3MonthlyOverview**
- 新增：`ui/home/components/V3MonthlyOverview.kt`（~120 行）
- 折叠/展开月度概览："本月上班 X/Y 天 · 劳逸充裕/平衡/辛苦劳作"
- "牛马指数"重新定义为"劳逸比"，展开显示连续上班 + 上班占比 + 月度评价

**V3.6 V3ContextualMessage**
- 新增：`ui/home/components/V3ContextualMessage.kt`（~80 行）
- 上下文共情文案决策树（5 个优先级 × 多文本池），替代随机池
- 提取 `getContextualMessage()` 纯函数，可独立单元测试

**V3.7 NewHomeScreenV3 组装**
- 新增：`ui/home/NewHomeScreenV3.kt`（~80 行）
- 6 组件组装，4 级差异化间距（12/16/20/24dp），stagger 入场动画

**V3.8 MainActivity 双轨接入**
- 改造：`MainActivity.kt`（+15 行）
- 新增 `USE_NEW_HOME_V3 = true` 编译时常量
- `composable("home")` 内 V2/V3 分支 + 3 个导航回调

**V3.9 测试覆盖**
- 新增：`ContextualMessageTest.kt`（10 用例）
- 覆盖：休息日/夜班/连续上班5+天/距休0-1天/普通工作日/优先级覆盖/多种子遍历

**V3.10 切换默认首页**
- `USE_NEW_HOME_V3` 改为 `true`

### 新增/改造文件汇总

| 新增（8 个） | 改造（2 个） |
|-------------|-------------|
| `ui/home/components/V3ShiftHeroBanner.kt`（~85 行） | `MainActivity.kt`（+15 行） |
| `ui/home/components/V3RestCountdownCard.kt`（~120 行） | memory-bank 更新 |
| `ui/home/components/V3FeatureHub.kt`（~110 行） | |
| `ui/home/components/V3ProgressIndicator.kt`（~65 行） | |
| `ui/home/components/V3MonthlyOverview.kt`（~120 行） | |
| `ui/home/components/V3ContextualMessage.kt`（~80 行） | |
| `ui/home/NewHomeScreenV3.kt`（~80 行） | |
| `ContextualMessageTest.kt`（10 用例） | |

### 构建与测试

```bash
./gradlew clean assembleDebug     # BUILD SUCCESSFUL（零警告）
./gradlew testDebugUnitTest       # BUILD SUCCESSFUL（160 个测试全部通过）
```

零回归。测试覆盖从 150 扩展到 160 个用例（+10），17 个测试文件。

### 回滚

`MainActivity.kt` 中将 `USE_NEW_HOME_V3` 改为 `false` 即恢复 V2 首页。所有 V2 组件完整保留不变。

### V2 vs V3 关键变化

| 方面 | V2 | V3 |
|------|----|----|
| 顶部区域 | GreetingHeader + TodayShiftCard 两个区块 | ShiftHeroBanner 一个融合氛围横幅 |
| 今日班次 | 72dp 圆形徽章 | 48sp 全宽大字 + 渐变背景 |
| 距休信息 | 卡片内一行正文 | 独立 RestCountdownCard（三态视觉） |
| 特色功能入口 | "我的"页二级菜单 | 首页 FeatureHub 直接曝光 |
| 进度展示 | LinearProgressIndicator + 分数 | 轻量一行 + 自然语言 |
| 月度指标 | 三宫格 | 折叠摘要 + 劳逸比（替代牛马指数） |
| 底部文案 | 随机池 7 条 | 上下文决策树 5 级优先级 |
| 间距 | 统一 20dp | 4 级差异化（12/16/20/24dp） |

---

## 2026-05-15：阶段 26 规划（提醒设置增强）

### 背景

当前提醒设置页（`AlarmSettingsScreen`）无说明文字，用户不知道设置提醒后会发生什么。此外，日历提醒是通知级别，部分用户希望有更强烈的"闹钟式"提醒。

### 方案（2026-05-15 更新：基于跨厂商日历提醒能力实测）

经实测：`METHOD_ALARM`（值=4）在任何 Android 品牌上都不会被系统处理。不同厂商 `METHOD_ALERT` 表现差异巨大——小米仅底部弹窗、三星/Pixel 通知栏提醒、华为/OPPO 严重受限。基于此调整为**三层提醒体系**：

**Part A（说明卡片）**：提醒设置页顶部新增说明卡片，解释三层提醒机制。纯 UI 新增。

**Part B1（小米 ExtendedProperties 修复）**：`CalendarEventManager.insertEvent()` 额外写入 `ExtendedProperties` 表（`{"need_alarm":true}`）。小米用户提醒从底部弹窗升级为闹钟响铃。非小米设备静默跳过。

**Part B2（系统闹钟增强）**：AlarmManager `setAlarmClock()` 独立通道（所有品牌统一强提醒）。用户可选开启，默认关闭，权限缺失时优雅降级。

### 实施步骤（8 步）

| Step | 内容 | 新增文件 | 改造文件 |
|------|------|---------|---------|
| 26.1 | 说明卡片 | 0 | `AlarmSettingsScreen.kt`, `strings.xml` |
| 26.2 | 小米 ExtendedProperties 修复 | 0 | `CalendarEventManager.kt` |
| 26.3 | B2 数据层（useSystemAlarm） | 0 | `AlarmSettings.kt`, `SettingsRepository.kt` |
| 26.4 | B2 闹钟调度引擎 | `alarm/SystemAlarmScheduler.kt`, `alarm/SystemAlarmReceiver.kt` | 0 |
| 26.5 | B2 Manifest + 权限 + 通知渠道 | 0 | `AndroidManifest.xml`, `MainActivity.kt` |
| 26.6 | B2 ViewModel + UI + CalendarSyncManager 接线 | 0 | `AlarmSettingsViewModel.kt`, `AlarmSettingsScreen.kt`, `CalendarSyncManager.kt` |
| 26.7 | 单元测试 | `SystemAlarmSchedulerTest.kt` | `SettingsRepositoryTest.kt`, `AlarmSettingsTest.kt` |
| 26.8 | 文档更新 | 0 | memory-bank |

### 预期新增

- 新增文件：3 个（~180 行）
- 改造文件：10-12 个（~120 行净增）
- 新增测试：约 8 用例
- 总测试：160 → 约 168

### 详细规划

参见 `memory-bank/implementation-plan.md` 阶段 26。

---

## 2026-05-15：阶段 26 实施完成

### 阶段 26：提醒设置增强 ✅

**26.1 Part A：说明卡片**
- 改造：`AlarmSettingsScreen.kt`（+40 行）
- 新增信息卡片：解释日历提醒机制、夜班前移、小米自动响铃、系统闹钟增强

**26.2 Part B1：小米 ExtendedProperties 修复**
- 改造：`CalendarEventManager.kt`（+20 行）
- `insertExtendedProperties()` 写入 `{"need_alarm":true}`，小米用户提醒从底部弹窗升级为闹钟响铃
- 非小米设备 insert 失败静默跳过

**26.3 Part B2：数据层（useSystemAlarm）**
- 改造：`AlarmSettings.kt` — 新增 `useSystemAlarm: Boolean = false`
- 改造：`SettingsRepository.kt` — 新增 `KEY_USE_SYSTEM_ALARM` 布尔 key + 读写

**26.4 Part B2：闹钟调度引擎**
- 新增：`alarm/SystemAlarmScheduler.kt`（~95 行）— `setAlarmClock()` 调度 + 确定性 requestCode + 权限降级
- 新增：`alarm/SystemAlarmReceiver.kt`（~55 行）— 高优先级通知 + 点击打开 App

**26.5 Part B2：Manifest + 权限 + 通知渠道**
- 改造：`AndroidManifest.xml` — `SCHEDULE_EXACT_ALARM` + `POST_NOTIFICATIONS` 权限 + `SystemAlarmReceiver` 注册
- 改造：`MainActivity.kt` — 创建闹钟通知渠道

**26.6 Part B2：ViewModel + UI + CalendarSyncManager 接线**
- 改造：`AlarmSettingsViewModel.kt` — 新增 `toggleSystemAlarm()` + `useSystemAlarm` 状态
- 改造：`AlarmSettingsScreen.kt` — 新增系统闹钟增强开关卡片（Switch）
- 改造：`CalendarSyncManager.kt` — 同步后若 `useSystemAlarm=true` 则调度闹钟，否则取消全部闹钟

**26.7 单元测试**
- 改造：`AlarmSettingsTest.kt` — 追加 2 个 `useSystemAlarm` 测试用例
- 改造：`SettingsRepositoryTest.kt` — 追加 1 个 `useSystemAlarm` 读写往返测试用例

### 新增/改造文件汇总

| 新增（2 个） | 改造（8 个） |
|-------------|-------------|
| `alarm/SystemAlarmScheduler.kt`（~95 行） | `AlarmSettingsScreen.kt`（+65 行） |
| `alarm/SystemAlarmReceiver.kt`（~55 行） | `CalendarEventManager.kt`（+18 行） |
| | `AlarmSettings.kt`（+1 字段） |
| | `SettingsRepository.kt`（+8 行） |
| | `AlarmSettingsViewModel.kt`（+10 行） |
| | `CalendarSyncManager.kt`（+10 行） |
| | `MainActivity.kt`（+3 行） |
| | `AndroidManifest.xml`（+3 行） |
| | `AlarmSettingsTest.kt`（+2 用例） |
| | `SettingsRepositoryTest.kt`（+1 用例） |

### 构建与测试

```bash
./gradlew assembleDebug        # BUILD SUCCESSFUL（零警告）
./gradlew testDebugUnitTest    # BUILD SUCCESSFUL（162 个测试全部通过）
```

零回归。测试覆盖从 160 扩展到 162 个用例（+3），17 个测试文件。

### 阶段 26 最终方案：回归最简 Calendar Provider

**最终决定**：ExtendedProperties 在部分 MIUI 版本仍然无法稳定让日历闹钟默认开启，属于非标准 hack。AlarmManager 权限门槛高、厂商兼容性差。最终选择最干净的方案——仅用 Calendar Provider 创建日程 + METHOD_ALERT 提醒，不附加任何非标准行为。

**保留内容**：
- `AlarmSettingsScreen` 顶部说明卡片（解释提醒机制、夜班前移、建议用户在系统日历 App 中管理通知）
- 日历日程创建 + METHOD_ALERT 提醒（核心功能，跨品牌兼容）

**已移除**：
- `alarm/SystemAlarmScheduler.kt`、`alarm/SystemAlarmReceiver.kt`
- `AndroidManifest.xml` 中 SCHEDULE_EXACT_ALARM、POST_NOTIFICATIONS、Receiver
- `AlarmSettings.useSystemAlarm` 字段及所有接线
- `CalendarEventManager.insertExtendedProperties()` 方法
- 闹钟开关卡片、通知渠道
- 相关 2 个测试用例
