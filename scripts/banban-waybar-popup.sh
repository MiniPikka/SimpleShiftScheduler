#!/bin/bash
# Waybar on-click popup — show full shift details in a floating terminal
# Usage: add to Waybar config:
#   "on-click": "/path/to/banban-waybar-popup.sh"

# Prefer foot, fallback to alacritty, kitty, or xterm
if command -v foot &>/dev/null; then
    exec foot --window-size=420x560 --title="班伴 ShiftMate" banban -l zh waybar-popup
elif command -v alacritty &>/dev/null; then
    exec alacritty --title "班伴 ShiftMate" -e banban -l zh waybar-popup
elif command -v kitty &>/dev/null; then
    exec kitty --title "班伴 ShiftMate" banban -l zh waybar-popup
else
    exec xterm -title "班伴 ShiftMate" -e "banban -l zh waybar-popup; read -p 'Press Enter to close...'"
fi
