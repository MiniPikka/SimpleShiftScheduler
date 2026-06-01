// Banban Shift — KDE Plasma 6 Plasmoid
// Fetches shift data from banban HTTP API (localhost:11451).
// Zero subprocess calls — pure HTTP via XMLHttpRequest.

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // ── State ──
    property var shiftData: null
    property var weekData: null
    property string fetchState: "loading"  // "loading" | "ok" | "error"
    property string errorMsg: ""
    property int retryCount: 0

    // ── Display helpers ──
    function shiftEmoji(type) {
        var t = String(type || "").toLowerCase();
        const map = {morning:"🟠", afternoon:"🔵", rest:"🟢", night:"🟣", study:"🟡"};
        return map[t] || "⚪";
    }
    function shiftLabel(type) {
        var t = String(type || "").toLowerCase();
        const map = {morning:"早", afternoon:"中", rest:"休", night:"夜", study:"学"};
        return map[t] || "?";
    }
    function shiftColor(type) {
        var t = String(type || "").toLowerCase();
        const map = {morning:"#FFB347", afternoon:"#4DA3FF", rest:"#35D07F", night:"#7C5CFF", study:"#F2D94E"};
        return map[t] || "#999";
    }
    function weekdayZh(ds) {
        const wd = ["周日","周一","周二","周三","周四","周五","周六"];
        var d = new Date(String(ds) + "T00:00:00");
        return wd[isNaN(d.getDay()) ? 0 : d.getDay()];
    }

    // ── HTTP fetch ──
    function httpGet(url, onOk, onErr) {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try { onOk(JSON.parse(xhr.responseText)); }
                    catch (e) { onErr("parse: " + e.message); }
                } else if (xhr.status === 0) {
                    onErr("server_down");
                } else {
                    // Try to extract server error message from response body
                    var msg = "HTTP " + xhr.status;
                    try {
                        var body = JSON.parse(xhr.responseText);
                        if (body.error) msg = body.error;
                    } catch (_) {}
                    onErr(msg);
                }
            }
        };
        xhr.open("GET", url); xhr.timeout = 5000;
        xhr.ontimeout = function() { onErr("timeout"); };
        xhr.send();
    }

    function fetchAll() {
        var hadData = fetchState === "ok" && shiftData !== null;
        if (!hadData) fetchState = "loading";
        errorMsg = "";
        httpGet("http://localhost:11451/shift",
            function(d) { shiftData = d; fetchState = "ok"; retryCount = 0; },
            function(e) {
                fetchState = "error";
                errorMsg = e === "server_down"
                    ? "banban API 服务未启动。\n运行: systemctl --user start banban-serve"
                    : "获取数据失败: " + e;
                if (!hadData) { retryCount++; if (retryCount <= 3) retryTimer.start(); }
            }
        );
        httpGet("http://localhost:11451/week",
            function(d) { weekData = d; },
            function(e) { /* week data is optional, ignore errors */ }
        );
    }

    Timer { id: retryTimer; interval: 5000; repeat: false; onTriggered: fetchAll() }
    Timer { id: refreshTimer; interval: 300000; running: true; repeat: true; triggeredOnStart: true; onTriggered: fetchAll() }

    // ── Tooltip ──
    toolTipMainText: {
        if (fetchState === "loading") return "加载中...";
        if (fetchState === "error") return "⚠️ API 错误";
        if (shiftData) return shiftEmoji(shiftData.shift_type) + " " + shiftData.shift_label_zh + "班";
        return "ShiftMate";
    }
    toolTipSubText: {
        if (fetchState === "loading") return "";
        if (fetchState === "error") return errorMsg.split("\n")[0];
        if (shiftData) return shiftData.team + " | 第 " + shiftData.day_of_cycle + "/" + shiftData.total_days + " 天 | 距休 " + shiftData.days_until_rest + " 天";
        return "";
    }

    // ══════════════════════════════════════════════════════════════
    // Compact representation (panel)
    // ══════════════════════════════════════════════════════════════

    compactRepresentation: MouseArea {
        id: compactArea
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        implicitWidth: compactRow.implicitWidth + Kirigami.Units.smallSpacing * 2
        implicitHeight: Kirigami.Units.iconSizes.smallMedium
        acceptedButtons: Qt.LeftButton
        onClicked: root.expanded = !root.expanded

        RowLayout {
            id: compactRow
            anchors.centerIn: parent; spacing: 2

            PlasmaComponents3.Label {
                text: fetchState === "loading" ? "⏳" : (fetchState === "error" ? "⚠️" : (shiftData ? shiftEmoji(shiftData.shift_type) : "⚪"))
                font.pixelSize: Math.min(compactArea.height * 0.65, Kirigami.Theme.defaultFont.pixelSize * 1.2)
            }
            PlasmaComponents3.Label {
                text: fetchState === "loading" ? "…" : (fetchState === "error" ? "!" : (shiftData ? shiftLabel(shiftData.shift_type) : "?"))
                font.pixelSize: Math.min(compactArea.height * 0.6, Kirigami.Theme.defaultFont.pixelSize * 1.0)
                font.bold: true
                color: shiftData ? shiftColor(shiftData.shift_type) : Kirigami.Theme.textColor
            }
        }
    }

    // ══════════════════════════════════════════════════════════════
    // Full representation (popup in panel, full widget on desktop)
    // Uses PlasmaExtras.Representation for standard Plasma 6 look.
    // ══════════════════════════════════════════════════════════════

    fullRepresentation: PlasmaExtras.Representation {
        id: fullRep

        Layout.minimumWidth: Kirigami.Units.gridUnit * 20
        Layout.minimumHeight: Kirigami.Units.gridUnit * 24
        Layout.preferredWidth: Kirigami.Units.gridUnit * 24
        Layout.preferredHeight: Kirigami.Units.gridUnit * 30

        collapseMarginsHint: true

        // ── Loading / Error states ──
        PlasmaExtras.PlaceholderMessage {
            anchors.centerIn: parent
            width: parent.width - Kirigami.Units.gridUnit * 4
            visible: fetchState === "loading"
            iconName: "view-refresh"
            text: "加载中..."
        }

        PlasmaExtras.PlaceholderMessage {
            anchors.centerIn: parent
            width: parent.width - Kirigami.Units.gridUnit * 4
            visible: fetchState === "error"
            iconName: "dialog-error"
            text: errorMsg
            helpfulAction: QQC2.Action {
                text: "重试"
                icon.name: "view-refresh"
                onTriggered: fetchAll()
            }
        }

        // ── Data content ──
        PlasmaComponents3.ScrollView {
            anchors.fill: parent
            visible: fetchState === "ok" && shiftData !== null

            // HACK: workaround for QTBUG-83890
            PlasmaComponents3.ScrollBar.horizontal.policy: PlasmaComponents3.ScrollBar.AlwaysOff

            contentItem: ColumnLayout {
                id: dataColumn
                spacing: 0

                // Header card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: headerRow.implicitHeight + Kirigami.Units.largeSpacing * 2
                    radius: Kirigami.Units.smallSpacing
                    color: shiftData ? shiftColor(shiftData.shift_type) : "#999"
                    opacity: 0.12

                    RowLayout {
                        id: headerRow
                        anchors.centerIn: parent
                        spacing: Kirigami.Units.gridUnit

                        PlasmaComponents3.Label {
                            text: shiftData ? shiftEmoji(shiftData.shift_type) : "⚪"
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 2.5
                        }
                        ColumnLayout {
                            spacing: 2
                            PlasmaComponents3.Label {
                                text: shiftData ? shiftData.shift_label_zh + "班" : ""
                                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.8
                                font.bold: true
                                color: shiftData ? shiftColor(shiftData.shift_type) : Kirigami.Theme.textColor
                            }
                            PlasmaComponents3.Label {
                                text: shiftData ? shiftData.team + " · 第" + shiftData.day_of_cycle + "/" + shiftData.total_days + "天" : ""
                                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.85
                                opacity: 0.7
                            }
                            PlasmaComponents3.Label {
                                text: shiftData ? shiftData.date : ""
                                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.85
                                opacity: 0.6
                            }
                        }
                    }
                }

                // Stats row
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Kirigami.Units.largeSpacing
                    Layout.bottomMargin: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.gridUnit

                    Item { Layout.fillWidth: true }
                    ColumnLayout {
                        spacing: 0
                        PlasmaComponents3.Label {
                            text: shiftData ? String(shiftData.days_until_rest) : "—"
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.5
                            font.bold: true
                            color: shiftData && shiftData.days_until_rest === 0 ? "#35D07F" : Kirigami.Theme.textColor
                            Layout.alignment: Qt.AlignHCenter
                        }
                        PlasmaComponents3.Label {
                            text: "距休"
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.7
                            opacity: 0.5
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                    Item { Layout.fillWidth: true }
                    ColumnLayout {
                        spacing: 0
                        PlasmaComponents3.Label {
                            text: shiftData ? String(shiftData.consecutive_work_days) : "—"
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.5
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                        PlasmaComponents3.Label {
                            text: "连续上班"
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.7
                            opacity: 0.5
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                    Item { Layout.fillWidth: true }
                    ColumnLayout {
                        spacing: 0
                        PlasmaComponents3.Label {
                            text: shiftData ? shiftData.day_of_cycle + "/" + shiftData.total_days : "—"
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.5
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                        PlasmaComponents3.Label {
                            text: "周期进度"
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.7
                            opacity: 0.5
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                    Item { Layout.fillWidth: true }
                }

                // ── Separator ──
                Kirigami.Separator {
                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Units.largeSpacing
                    Layout.rightMargin: Kirigami.Units.largeSpacing
                }

                // Week section header
                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    Layout.topMargin: Kirigami.Units.smallSpacing
                    text: "本周排班"
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.85
                    opacity: 0.5
                    horizontalAlignment: Text.AlignHCenter
                }

                // Week day rows
                Repeater {
                    model: weekData && weekData.days ? weekData.days : []
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: Kirigami.Units.largeSpacing
                        Layout.rightMargin: Kirigami.Units.largeSpacing
                        Layout.topMargin: Kirigami.Units.smallSpacing / 2
                        Layout.bottomMargin: Kirigami.Units.smallSpacing / 2
                        spacing: Kirigami.Units.smallSpacing

                        // Shift type dot
                        Rectangle {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 1.8
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 1.8
                            radius: width / 2
                            color: shiftColor(modelData.shift_type)
                            opacity: modelData.is_today ? 1.0 : 0.7

                            PlasmaComponents3.Label {
                                anchors.centerIn: parent
                                text: shiftEmoji(modelData.shift_type)
                                font.pixelSize: parent.height * 0.55
                            }
                        }

                        PlasmaComponents3.Label {
                            text: shiftLabel(modelData.shift_type)
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.1
                            font.bold: modelData.is_today
                            color: shiftColor(modelData.shift_type)
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 1.5
                        }

                        PlasmaComponents3.Label {
                            text: weekdayZh(modelData.date)
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.85
                            opacity: 0.6
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                        }

                        PlasmaComponents3.Label {
                            text: String(modelData.date).slice(5)
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.85
                            opacity: modelData.is_today ? 1.0 : 0.5
                            font.bold: modelData.is_today
                        }

                        PlasmaComponents3.Label {
                            text: modelData.is_today ? "◀ 今天" : ""
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.8
                            color: "#FACC15"
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }
                    }
                }

                Item { Layout.preferredHeight: Kirigami.Units.largeSpacing }
            }
        }

        // ── Footer with refresh button ──
        footer: PlasmaExtras.PlasmoidHeading {
            contentItem: RowLayout {
                PlasmaComponents3.ToolButton {
                    icon.name: "view-refresh"
                    text: "刷新"
                    onClicked: fetchAll()
                    Layout.alignment: Qt.AlignLeft
                }
                Item { Layout.fillWidth: true }
                PlasmaComponents3.Label {
                    visible: fetchState === "ok" && shiftData !== null
                    text: shiftData ? shiftData.date : ""
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.8
                    opacity: 0.5
                    Layout.alignment: Qt.AlignRight
                }
            }
        }
    }
}
