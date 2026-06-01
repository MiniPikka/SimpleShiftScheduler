// -*- mode: js2; js-indent-level: 4 -*-
// Banban Shift — GNOME Shell Extension (45+)
// Shows today's rotating shift schedule in the top bar.
// Calls banban CLI for data; zero duplicate algorithm logic.

import GObject from 'gi://GObject';
import St from 'gi://St';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Clutter from 'gi://Clutter';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';

// ── Display mapping ──────────────────────────────────────────────

const SHIFT_DISPLAY = {
    morning:   { emoji: '🟠', label: '早', color: '#FFB347' },
    afternoon: { emoji: '🔵', label: '中', color: '#4DA3FF' },
    rest:      { emoji: '🟢', label: '休', color: '#35D07F' },
    night:     { emoji: '🟣', label: '夜', color: '#7C5CFF' },
    study:     { emoji: '🟡', label: '学', color: '#F2D94E' },
};

const WEEKDAY_ZH = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];

const REFRESH_SECONDS = 60;

// ── Helpers ──────────────────────────────────────────────────────

function shiftDisplay(type) {
    return SHIFT_DISPLAY[type] || { emoji: '⚪', label: '?', color: '#999' };
}

function weekdayZh(dateStr) {
    const d = new Date(dateStr + 'T00:00:00');
    return WEEKDAY_ZH[d.getDay()] || '';
}

// ── Async command execution ──────────────────────────────────────
// GNOME Shell's PATH is minimal — use absolute path to banban.

const BANBAN_BIN = GLib.find_program_in_path('banban')
    || GLib.get_home_dir() + '/.cargo/bin/banban';

function execBanban(args) {
    return new Promise((resolve, reject) => {
        try {
            const proc = Gio.Subprocess.new(
                [BANBAN_BIN, ...args],
                Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE
            );
            proc.communicate_utf8_async(null, null, (p, res) => {
                try {
                    const [, stdout, stderr] = p.communicate_utf8_finish(res);
                    if (!p.get_successful()) {
                        reject(new Error(stderr?.trim() || 'Command failed'));
                        return;
                    }
                    resolve(stdout.trim());
                } catch (e) {
                    reject(e);
                }
            });
        } catch (e) {
            reject(e);
        }
    });
}

// ── Panel indicator ──────────────────────────────────────────────

const BanbanIndicator = GObject.registerClass(
class BanbanIndicator extends PanelMenu.Button {
    _init(uuid) {
        super._init(0.0, 'Banban Shift', false);

        this._uuid = uuid;
        this._shiftData = null;
        this._weekData = null;
        this._restData = null;
        this._error = null;
        this._loading = true;

        // Panel button: just emoji + short label
        this._buttonLabel = new St.Label({
            text: '⏳',
            y_align: Clutter.ActorAlign.CENTER,
            style_class: 'banban-panel-label',
        });
        this.add_child(this._buttonLabel);

        // Build popup when menu is opened
        this.menu.connect('open-state-changed', (menu, isOpen) => {
            if (isOpen) {
                this._rebuildPopup();
            }
        });
    }

    // Update from fetched data
    update(shiftData, weekData, restData, error, loading) {
        this._shiftData = shiftData;
        this._weekData = weekData;
        this._restData = restData;
        this._error = error;
        this._loading = loading;
        this._updatePanelLabel();
    }

    _updatePanelLabel() {
        if (this._error && !this._shiftData) {
            this._buttonLabel.set_text('⚠️ ?');
            this._buttonLabel.set_style('color: #EF4444;');
            return;
        }
        if (this._loading) {
            this._buttonLabel.set_text('⏳');
            return;
        }
        if (this._shiftData) {
            const d = shiftDisplay(this._shiftData.shift_type);
            this._buttonLabel.set_text(`${d.emoji} ${d.label}`);
            this._buttonLabel.set_style(`color: ${d.color};`);
        }
    }

    _rebuildPopup() {
        const menu = this.menu;
        menu.removeAll();

        // ── Error state ──
        if (this._error && !this._shiftData) {
            const errItem = new PopupMenu.PopupMenuItem(
                `⚠️ ${this._error}`
            );
            errItem.setSensitive(false);
            menu.addMenuItem(errItem);
            const helpItem = new PopupMenu.PopupMenuItem(
                'Install: cargo install shift-cli\nConfig: banban config'
            );
            helpItem.setSensitive(false);
            menu.addMenuItem(helpItem);
            this._addRefreshFooter(menu);
            return;
        }

        // ── Loading state ──
        if (this._loading || !this._shiftData) {
            const loadItem = new PopupMenu.PopupMenuItem('⏳ Loading...');
            loadItem.setSensitive(false);
            menu.addMenuItem(loadItem);
            return;
        }

        // ── Today section ──
        const d = shiftDisplay(this._shiftData.shift_type);
        const todayItem = new PopupMenu.PopupMenuItem(
            `${d.emoji}  ${this._shiftData.shift_label}`
        );
        menu.addMenuItem(todayItem);

        const detailItem = new PopupMenu.PopupMenuItem(
            `${this._shiftData.team}  ·  ` +
            `第 ${this._shiftData.day_of_cycle}/${this._shiftData.total_days} 天  ·  ` +
            `${this._shiftData.date}`
        );
        detailItem.setSensitive(false);
        menu.addMenuItem(detailItem);

        // ── Stats row ──
        let restText = '';
        if (this._restData) {
            if (this._restData.days_until === 0) {
                restText = '🎉 今天休息！';
            } else {
                restText = `距休 ${this._restData.days_until} 天 (${this._restData.rest_date.slice(5)})`;
            }
        } else {
            restText = `距休 ${this._shiftData.days_until_rest} 天`;
        }
        const statsItem = new PopupMenu.PopupMenuItem(
            `${restText}  ·  连续上班 ${this._shiftData.consecutive_work_days} 天`
        );
        statsItem.setSensitive(false);
        menu.addMenuItem(statsItem);

        menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        // ── Week preview section ──
        if (this._weekData && this._weekData.days) {
            const weekHeader = new PopupMenu.PopupMenuItem('──  本周排班  ──');
            weekHeader.setSensitive(false);
            menu.addMenuItem(weekHeader);

            for (const day of this._weekData.days) {
                const dd = shiftDisplay(day.shift_type);
                const marker = day.is_today ? ' ▶' : '   ';
                const wd = weekdayZh(day.date);
                const text = `${marker} ${dd.emoji} ${dd.label}   ${day.date.slice(5)} ${wd}`;
                const dayItem = new PopupMenu.PopupMenuItem(text);
                dayItem.setSensitive(false);
                // Highlight today
                if (day.is_today) {
                    // We can't easily style individual menu items, but the ▶ marks it
                }
                menu.addMenuItem(dayItem);
            }
        }

        menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        // ── Refresh footer ──
        this._addRefreshFooter(menu);
    }

    _addRefreshFooter(menu) {
        const refreshItem = new PopupMenu.PopupMenuItem('🔄 刷新');
        refreshItem.connect('activate', () => {
            this.emit('refresh-requested');
        });
        menu.addMenuItem(refreshItem);
    }
});

// ── Extension class ──────────────────────────────────────────────

export default class BanbanExtension extends Extension {
    enable() {
        this._indicator = null;
        this._timeoutId = null;

        this._indicator = new BanbanIndicator(this.uuid);
        this._indicator.connect('refresh-requested', () => this._refresh());

        Main.panel.addToStatusArea(this.uuid, this._indicator);

        // Periodic refresh every 60 seconds
        this._timeoutId = GLib.timeout_add_seconds(
            GLib.PRIORITY_DEFAULT,
            REFRESH_SECONDS,
            () => {
                this._refresh();
                return GLib.SOURCE_CONTINUE;
            }
        );

        // Immediate first fetch
        this._refresh();
    }

    disable() {
        if (this._timeoutId) {
            GLib.source_remove(this._timeoutId);
            this._timeoutId = null;
        }
        if (this._indicator) {
            this._indicator.destroy();
            this._indicator = null;
        }
    }

    _refresh() {
        // Fetch today data (required)
        execBanban(['--json', '--lang', 'zh', 'today'])
            .then(data => {
                const parsed = JSON.parse(data);
                this._indicator.update(parsed, null, null, null, false);
                // Fetch week and next-rest in parallel after today succeeds
                this._fetchSupplementary();
            })
            .catch(err => {
                const msg = this._friendlyError(err);
                this._indicator.update(null, null, null, msg, false);
            });
    }

    _fetchSupplementary() {
        // Week data
        execBanban(['--json', '--lang', 'zh', 'week'])
            .then(data => {
                const parsed = JSON.parse(data);
                this._indicator.update(this._indicator._shiftData, parsed, this._indicator._restData, null, false);
            })
            .catch(() => {}); // Silently ignore — week is non-critical

        // Next rest
        execBanban(['--json', '--lang', 'zh', 'next-rest'])
            .then(data => {
                const parsed = JSON.parse(data);
                this._indicator.update(this._indicator._shiftData, this._indicator._weekData, parsed, null, false);
            })
            .catch(() => {}); // Silently ignore — rest info is non-critical
    }

    _friendlyError(err) {
        const msg = err.message || String(err);
        if (msg.includes('Failed to execute') || msg.includes('No such file') || msg.includes('not found')) {
            return 'banban CLI 未安装。运行: cargo install shift-cli';
        }
        if (msg.includes('config')) {
            return 'banban 未配置。运行: banban config';
        }
        return `获取数据失败: ${msg}`;
    }
}
