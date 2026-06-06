# GNOME Extensions Store Description

## English

**ShiftMate — Rotating Shift Schedule**

Display your rotating shift schedule in the GNOME top bar. Designed for workers on rotating shifts (manufacturing, healthcare, energy, etc.).

**Features:**
- Top bar: colored emoji + shift label (🟠 AM / 🔵 PM / 🟢 Off / 🟣 Night / 🟡 Training)
- Click to expand: shift details, days-until-rest countdown, consecutive work days, 7-day week preview
- Auto-refresh every 60 seconds
- Graceful error handling with install instructions

**Requirements:**
- GNOME Shell 45+ (tested on 50)
- [banban CLI](https://github.com/MiniPikka/SimpleShiftScheduler) — the shift calculation engine (`cargo install shift-cli`)

**Quick Start:**
```bash
# 1. Install banban CLI
cargo install shift-cli

# 2. Configure your shift schedule
banban config --team 1

# 3. Enable the extension
gnome-extensions enable banban-shift@simpleshift.scheduler
```

The extension calls `banban --json` CLI for data — zero business logic duplication. All shift calculation is handled by the Rust-based banban CLI.

---

## 中文

**班伴 — 倒班排班顶栏扩展**

在 GNOME 顶栏显示倒班排班信息。专为轮班工作者设计（制造业、医疗、能源等行业）。

**功能特性：**
- 顶栏显示：彩色 emoji + 班次标签（🟠早 / 🔵中 / 🟢休 / 🟣夜 / 🟡学）
- 点击展开：班次详情、距休倒计时、连续上班天数、7 天周预览
- 每 60 秒自动刷新
- 友好错误提示（CLI 缺失/未配置）

**依赖要求：**
- GNOME Shell 45+（已在 50 上验证）
- [banban CLI](https://github.com/MiniPikka/SimpleShiftScheduler) — 排班计算引擎（`cargo install shift-cli`）

**快速开始：**
```bash
# 1. 安装 banban CLI
cargo install shift-cli

# 2. 配置排班
banban config --team 1

# 3. 启用扩展
gnome-extensions enable banban-shift@simpleshift.scheduler
```

扩展通过 `banban --json` CLI 获取数据——零业务逻辑重复。所有排班计算由 Rust 编写的 banban CLI 处理。
