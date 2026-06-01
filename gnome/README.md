# ShiftMate — GNOME Shell Extension

A GNOME Shell panel indicator showing today's rotating shift schedule from `banban` CLI.

## Features

- **Panel indicator**: Emoji + shift label in the GNOME top bar (e.g., 🟠早)
- **Popup menu**: Detailed shift info, 7-day week preview, days until rest, consecutive work days
- **Auto-refresh**: Updates every 60 seconds
- **Error handling**: Gracefully shows messages if banban CLI is missing or unconfigured

## Requirements

- **GNOME Shell 45+** (Wayland or X11)
- **[banban CLI](https://github.com/MiniPikka/SimpleShiftScheduler)** installed (`cargo install shift-cli`)

## Installation

```bash
cd gnome
./install.sh
```

Then restart GNOME Shell and enable:

```bash
# X11: Alt+F2 → r → Enter
# Wayland: Log out and log back in

gnome-extensions enable banban-shift@simpleshift.scheduler
```

## Debugging

```bash
# See extension logs
journalctl -f -o cat /usr/bin/gnome-shell | grep -i banban

# Check extension status
gnome-extensions info banban-shift@simpleshift.scheduler

# Disable
gnome-extensions disable banban-shift@simpleshift.scheduler
```

## Uninstall

```bash
gnome-extensions disable banban-shift@simpleshift.scheduler
rm -rf ~/.local/share/gnome-shell/extensions/banban-shift@simpleshift.scheduler
```

## Architecture

The extension calls `banban --json --lang zh today|week|next-rest` via `Gio.Subprocess` (non-blocking async). Zero business logic duplication — all shift calculation is in the Rust shift-core library.
