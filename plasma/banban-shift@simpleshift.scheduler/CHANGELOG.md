# Changelog

## 1.0.0 (2026-06-02)

Initial release.

### Features

- Panel compact view: colored emoji + shift label (e.g. 🟠早)
- Expanded popup with PlasmaExtras.Representation:
  - Header card with shift type, team name, cycle progress
  - Stats row: days until rest, consecutive work days, cycle progress
  - 7-day week preview with colored indicators and "today" marker
- Hover tooltip: team, cycle progress, rest countdown
- Auto-refresh every 5 minutes (silent, no UI flash)
- Click to expand/collapse popup
- Error handling: helpful messages when banban API is not running
- Auto-retry (up to 3 times, 5s interval) on transient errors

### Requirements

- KDE Plasma 6.0+
- banban CLI installed (`cargo install shift-cli`)
- banban HTTP API running (`systemctl --user start banban-serve`)
