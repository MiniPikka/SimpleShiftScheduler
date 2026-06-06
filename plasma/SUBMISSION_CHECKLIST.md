# KDE Store Submission Checklist

## Package

- [x] `metadata.json` — all required fields present (Id, Name, Description, Category, Icon, License, Version, Authors, Website)
- [x] `LICENSE` — MIT license file included
- [x] `CHANGELOG.md` — version history
- [x] `contents/ui/main.qml` — widget source code
- [x] `package.sh` — packaging script (generates `banban-shift.plasmoid`)

## Before Submitting

- [ ] **Screenshots** (1920×1080):
  - [ ] Panel compact view (showing emoji + shift label in panel)
  - [ ] Expanded popup (showing full widget with shift details + week preview)
  - [ ] Tooltip hover (optional)
- [ ] **KDE Identity account** — register at https://identity.kde.org
- [ ] **Test on clean Plasma 6** — install from .plasmoid file, verify:
  - [ ] Widget appears in "Add Widgets" search
  - [ ] Panel compact view shows correctly
  - [ ] Popup expands with data
  - [ ] Error state shows when banban serve is not running
  - [ ] Auto-refresh works (wait 5 min or modify timer for testing)

## Submit

1. Go to https://store.kde.org → Upload
2. Category: Utilities
3. Upload `banban-shift.plasmoid`
4. Copy description from `STORE_DESCRIPTION.md` (English section)
5. Add screenshots
6. Submit for review

## Post-Submission

- [ ] Update README.md with KDE Store link
- [ ] Update progress.md
- [ ] Consider GNOME Extensions submission (separate checklist)
