# ShiftMate — KDE Plasma 6 Plasmoid

A Plasma 6 panel widget showing today's rotating shift schedule from `banban` CLI.

## Features

- **Compact panel view**: Colored emoji + shift label (e.g., 🟠早)
- **Expanded popup**: Detailed shift info, stats (days until rest, consecutive work days), 7-day week preview with colored indicators
- **Tooltip**: Team, cycle progress, rest countdown on hover
- **Auto-refresh**: Updates every 5 minutes
- **Click to expand**: Click panel icon to see full popup
- **Error handling**: Shows helpful messages if banban CLI is missing or unconfigured

## Requirements

- **KDE Plasma 6** (6.0+)
- **[banban CLI](https://github.com/MiniPikka/SimpleShiftScheduler)** installed (`cargo install shift-cli`)
- `plasma-sdk` (optional, for `plasmoidviewer` testing)

## Installation

```bash
cd plasma
./install.sh
```

Then restart Plasma and add to panel:

```bash
systemctl --user restart plasma-plasmashell
# Right-click panel → Add Widgets → Search "ShiftMate"
```

## Development & Testing

```bash
# Test without installing (from source directory):
plasmoidviewer -a ./banban-shift@simpleshift.scheduler/

# Test as panel widget:
plasmoidviewer --applet ./banban-shift@simpleshift.scheduler/

# Test installed version:
plasmoidviewer --applet banban-shift@simpleshift.scheduler

# View debug output:
journalctl -f -o cat /usr/bin/plasmashell | grep -i banban
```

## Uninstall

```bash
kpackagetool6 --remove com.simpleshift.banban
```

## Architecture

The plasmoid calls `banban --json --lang zh today|week|next-rest` via `Plasma5Support.DataSource` (executable engine). Zero business logic duplication — all shift calculation is in the Rust shift-core library. QML handles only display.
