# GNOME Extensions Submission Checklist

## Package

- [x] `metadata.json` — uuid, name, description, shell-version (45-50), url
- [x] `extension.js` — extension source code
- [x] `stylesheet.css` — panel + popup styles
- [x] `LICENSE` — MIT license
- [x] `CHANGELOG.md` — version history
- [x] `package.sh` — packaging script (generates `banban-shift.zip`)

## Before Submitting

- [ ] **Screenshots** (1920×1080):
  - [ ] Top bar compact view (showing emoji + shift label)
  - [ ] Expanded popup menu (showing shift details + week preview)
- [ ] **GNOME GitLab account** — register at https://gitlab.gnome.org
- [ ] **Test on GNOME 45+** — install from .zip, verify:
  - [ ] Extension appears in Extensions app
  - [ ] Top bar shows shift label
  - [ ] Click opens popup with data
  - [ ] Error state shows when banban is not installed
  - [ ] Auto-refresh works (wait 60s)

## Submit

1. Go to https://extensions.gnome.org/upload/
2. Upload `banban-shift.zip`
3. Fill in description (from `STORE_DESCRIPTION.md`)
4. Add screenshots
5. Submit for review

## Post-Submission

- [ ] Update README.md with GNOME Extensions link
- [ ] Update progress.md
- [ ] Track review feedback
- [ ] Update `shell-version` when new GNOME versions release
