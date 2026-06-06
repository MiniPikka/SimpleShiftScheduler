# Changelog

## 1.0.0 (2026-06-02)

Initial release.

### Features

- Top bar display: colored emoji + shift label (e.g. 🟠早)
- Click popup menu:
  - Today's shift details with team name and cycle progress
  - Days-until-rest countdown + consecutive work days
  - 7-day week preview with colored shift indicators and "today" marker
- Auto-refresh every 60 seconds
- Graceful error handling: helpful messages when banban CLI is missing or unconfigured
- Works with GNOME Shell 45 through 50

### Requirements

- GNOME Shell 45+ (tested on 50)
- [banban CLI](https://github.com/MiniPikka/SimpleShiftScheduler) installed (`cargo install shift-cli`)
