# KDE Store Description

## English

**ShiftMate — Rotating Shift Schedule Widget**

A Plasma 6 panel widget that displays your rotating shift schedule at a glance. Designed for workers on rotating shifts (manufacturing, healthcare, energy, etc.).

**Features:**
- Panel display: colored emoji + shift label (🟠 AM / 🔵 PM / 🟢 Off / 🟣 Night / 🟡 Training)
- Click to expand: detailed shift info, days-until-rest countdown, consecutive work days, 7-day week preview
- Hover tooltip: team name, cycle progress, rest countdown
- Auto-refresh every 5 minutes
- Dark/light theme compatible

**Requirements:**
- KDE Plasma 6.0+
- [banban CLI](https://github.com/MiniPikka/SimpleShiftScheduler) — the shift calculation engine (`cargo install shift-cli`)
- banban HTTP API service running (`banban serve` on localhost:11451)

**Quick Start:**
```bash
# 1. Install banban CLI
cargo install shift-cli

# 2. Configure your shift schedule
banban config --team 1

# 3. Start the HTTP API service
banban serve &

# 4. Install the plasmoid
# Right-click panel → Add Widgets → Search "ShiftMate"
```

The plasmoid fetches data via HTTP from the local banban API — zero subprocess calls, zero business logic duplication. All shift calculation is handled by the Rust-based banban CLI.

---

## 中文

**班伴 — 倒班排班面板小组件**

KDE Plasma 6 面板小组件，一目了然显示倒班排班信息。专为轮班工作者设计（制造业、医疗、能源等行业）。

**功能特性：**
- 面板显示：彩色 emoji + 班次标签（🟠早 / 🔵中 / 🟢休 / 🟣夜 / 🟡学）
- 点击展开：班次详情、距休倒计时、连续上班天数、7 天周预览
- 悬停提示：班组名、周期进度、距休天数
- 每 5 分钟自动刷新
- 深色/浅色主题自适应

**依赖要求：**
- KDE Plasma 6.0+
- [banban CLI](https://github.com/MiniPikka/SimpleShiftScheduler) — 排班计算引擎（`cargo install shift-cli`）
- banban HTTP API 服务运行中（`banban serve`，localhost:11451）

**快速开始：**
```bash
# 1. 安装 banban CLI
cargo install shift-cli

# 2. 配置排班
banban config --team 1

# 3. 启动 HTTP API 服务
banban serve &

# 4. 安装小组件
# 右键面板 → 添加小组件 → 搜索 "ShiftMate"
```

小组件通过 HTTP 从本地 banban API 获取数据——零子进程调用、零业务逻辑重复。所有排班计算由 Rust 编写的 banban CLI 处理。
