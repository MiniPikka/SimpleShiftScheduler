// Banban Shift — KDE Plasma 6 Plasmoid
// Fetches shift data from banban HTTP API (localhost:11451).
// Zero subprocess calls — pure HTTP via XMLHttpRequest.

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

PlasmoidItem {
    id: root

    switchWidth: 9999
    switchHeight: 9999
    preferredRepresentation: compactRepresentation

    // ── State ──
    property var shiftData: null
    property var weekData: null
    property string state: "loading"
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
                } else if (xhr.status === 0) onErr("server_down");
                else onErr("HTTP " + xhr.status);
            }
        };
        xhr.open("GET", url); xhr.timeout = 5000;
        xhr.ontimeout = function() { onErr("timeout"); };
        xhr.send();
    }

    function fetchAll() {
        state = "loading"; errorMsg = "";
        httpGet("http://localhost:11451/shift",
            function(d) { shiftData = d; state = "ok"; retryCount = 0; },
            function(e) {
                state = "error";
                errorMsg = e === "server_down" ? "banban API 服务未启动。\n运行: systemctl --user start banban-serve" : "获取数据失败: " + e;
                retryCount++; if (retryCount <= 3) retryTimer.start();
            }
        );
        httpGet("http://localhost:11451/week",
            function(d) { weekData = d; }, function(e) {}
        );
    }

    Timer { id: retryTimer; interval: 5000; repeat: false; onTriggered: fetchAll() }
    Timer { id: refreshTimer; interval: 300000; running: true; repeat: true; triggeredOnStart: true; onTriggered: fetchAll() }

    // ── Tooltip ──
    toolTipMainText: {
        if (state === "loading") return "加载中...";
        if (state === "error") return "⚠️ API 错误";
        if (shiftData) return shiftEmoji(shiftData.shift_type) + " " + shiftData.shift_label_zh + "班";
        return "ShiftMate";
    }
    toolTipSubText: {
        if (state === "loading") return "";
        if (state === "error") return errorMsg.split("\n")[0];
        if (shiftData) return shiftData.team + " | 第 " + shiftData.day_of_cycle + "/" + shiftData.total_days + " 天 | 距休 " + shiftData.days_until_rest + " 天";
        return "";
    }

    // ══════════════════════════════════════════════════════════════
    // Compact (panel)
    // ══════════════════════════════════════════════════════════════

    compactRepresentation: MouseArea {
        id: compactArea
        hoverEnabled: true
        implicitWidth: compactRow.implicitWidth + Kirigami.Units.smallSpacing * 2
        implicitHeight: Kirigami.Units.iconSizes.smallMedium
        acceptedButtons: Qt.LeftButton
        onClicked: detailPopup.open()

        RowLayout {
            id: compactRow
            anchors.centerIn: parent; spacing: 2

            PlasmaComponents.Label {
                text: state === "loading" ? "⏳" : (state === "error" ? "⚠️" : (shiftData ? shiftEmoji(shiftData.shift_type) : "⚪"))
                font.pixelSize: Math.min(parent.parent.height * 0.65, Kirigami.Theme.defaultFont.pixelSize * 1.2)
            }
            PlasmaComponents.Label {
                text: state === "loading" ? "…" : (state === "error" ? "!" : (shiftData ? shiftLabel(shiftData.shift_type) : "?"))
                font.pixelSize: Math.min(parent.parent.height * 0.6, Kirigami.Theme.defaultFont.pixelSize * 1.0)
                font.bold: true
                color: shiftData ? shiftColor(shiftData.shift_type) : Kirigami.Theme.textColor
            }
        }
    }

    // ══════════════════════════════════════════════════════════════
    // Popup — loaded on demand to avoid panel height clipping
    // ══════════════════════════════════════════════════════════════

    Popup {
        id: detailPopup
        width: 500; height: 600
        padding: Kirigami.Units.smallSpacing
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { color: Kirigami.Theme.backgroundColor; radius: Kirigami.Units.smallSpacing }

        // State handling
        Rectangle { visible: state === "loading" || state === "error"; anchors.fill: parent; color: "transparent"
            PlasmaComponents.Label { anchors.centerIn: parent; visible: state === "loading"; text: "⏳ 加载中..."; font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.5 }
            ColumnLayout { anchors.centerIn: parent; visible: state === "error"; spacing: Kirigami.Units.gridUnit
                PlasmaComponents.Label { text: "⚠️\n" + errorMsg; font.pixelSize: Kirigami.Theme.defaultFont.pixelSize; horizontalAlignment: Text.AlignHCenter; Layout.alignment: Qt.AlignHCenter }
                PlasmaComponents.Button { text: "🔄 重试"; Layout.alignment: Qt.AlignHCenter; onClicked: fetchAll() }
            }
        }

        // Data
        ScrollView { visible: state === "ok" && shiftData !== null; anchors.fill: parent; clip: true
            ColumnLayout { spacing: 0; width: parent.width - detailPopup.padding * 2

                // Header
                Item { Layout.fillWidth: true; Layout.preferredHeight: Kirigami.Units.gridUnit * 6
                    Rectangle { anchors.fill: parent; color: shiftColor(shiftData.shift_type); opacity: 0.12; radius: Kirigami.Units.smallSpacing }
                    RowLayout { anchors.centerIn: parent; spacing: Kirigami.Units.gridUnit
                        PlasmaComponents.Label { text: shiftEmoji(shiftData.shift_type); font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 2.5 }
                        ColumnLayout { spacing: 0
                            PlasmaComponents.Label { text: shiftData.shift_label_zh + "班"; font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.8; font.bold: true; color: shiftColor(shiftData.shift_type) }
                            PlasmaComponents.Label { text: shiftData.team + " · 第" + shiftData.day_of_cycle + "/" + shiftData.total_days + "天"; font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.8; opacity: 0.7 }
                        }
                    }
                }

                // Stats
                RowLayout { Layout.fillWidth: true; Layout.topMargin: Kirigami.Units.smallSpacing; Layout.bottomMargin: Kirigami.Units.smallSpacing
                    Item { Layout.fillWidth: true }
                    ColumnLayout { spacing: 0
                        PlasmaComponents.Label { text: String(shiftData.days_until_rest); font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.3; font.bold: true; color: shiftData.days_until_rest === 0 ? "#35D07F" : Kirigami.Theme.textColor; Layout.alignment: Qt.AlignHCenter }
                        PlasmaComponents.Label { text: "距休"; font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.7; opacity: 0.5; Layout.alignment: Qt.AlignHCenter }
                    }
                    Item { Layout.fillWidth: true }
                    ColumnLayout { spacing: 0
                        PlasmaComponents.Label { text: String(shiftData.consecutive_work_days); font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.3; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                        PlasmaComponents.Label { text: "连续上班"; font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.7; opacity: 0.5; Layout.alignment: Qt.AlignHCenter }
                    }
                    Item { Layout.fillWidth: true }
                }

                // Week
                PlasmaComponents.Label { Layout.fillWidth: true; text: "── 本周排班 ──"; font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.8; opacity: 0.4; horizontalAlignment: Text.AlignHCenter }
                Repeater {
                    model: weekData && weekData.days ? weekData.days : []
                    RowLayout { Layout.fillWidth: true; Layout.topMargin: 1; Layout.bottomMargin: 1
                        PlasmaComponents.Label { text: shiftEmoji(modelData.shift_type); Layout.preferredWidth: Kirigami.Units.gridUnit * 2 }
                        PlasmaComponents.Label { text: shiftLabel(modelData.shift_type); font.bold: modelData.is_today; color: shiftColor(modelData.shift_type); Layout.preferredWidth: Kirigami.Units.gridUnit * 1.5 }
                        PlasmaComponents.Label { text: weekdayZh(modelData.date); font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.8; opacity: 0.6; Layout.preferredWidth: Kirigami.Units.gridUnit * 3 }
                        PlasmaComponents.Label { text: String(modelData.date).slice(5); font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.8; font.bold: modelData.is_today }
                        Item { Layout.fillWidth: true }
                    }
                }
                PlasmaComponents.Button { Layout.alignment: Qt.AlignHCenter; Layout.topMargin: Kirigami.Units.smallSpacing; text: "🔄 刷新"; flat: true; onClicked: fetchAll() }
            }
        }
    }

    // ══════════════════════════════════════════════════════════════
    // Full representation (popup in panel, full widget on desktop)
    // ══════════════════════════════════════════════════════════════

    fullRepresentation: Rectangle {
        implicitWidth: Kirigami.Units.gridUnit * 20
        implicitHeight: Kirigami.Units.gridUnit * 28
        color: Kirigami.Theme.backgroundColor

        ScrollView {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            clip: true

            ColumnLayout {
                spacing: 0
                width: parent.width - Kirigami.Units.smallSpacing * 2

                // State handling
                PlasmaComponents.Label { visible: state === "loading"; Layout.fillWidth: true; text: "⏳ 加载中..."; font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.2; horizontalAlignment: Text.AlignHCenter; Layout.topMargin: Kirigami.Units.gridUnit * 4 }
                PlasmaComponents.Label { visible: state === "error"; Layout.fillWidth: true; text: "⚠️\n" + errorMsg; font.pixelSize: Kirigami.Theme.defaultFont.pixelSize; horizontalAlignment: Text.AlignHCenter; Layout.topMargin: Kirigami.Units.gridUnit * 4 }

                // Data
                Item { visible: state === "ok" && shiftData !== null; Layout.fillWidth: true; implicitHeight: dataColumn.implicitHeight
                    ColumnLayout {
                        id: dataColumn
                        spacing: 0; width: parent.width

                        // Header
                        Item { Layout.fillWidth: true; Layout.preferredHeight: Kirigami.Units.gridUnit * 7
                            Rectangle { anchors.fill: parent; color: shiftColor(shiftData.shift_type); opacity: 0.12; radius: Kirigami.Units.gridUnit }
                            RowLayout { anchors.centerIn: parent; spacing: Kirigami.Units.gridUnit * 1.5
                                PlasmaComponents.Label { text: shiftEmoji(shiftData.shift_type); font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 3 }
                                ColumnLayout { spacing: 2
                                    PlasmaComponents.Label { text: shiftData.shift_label_zh + "班"; font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 2; font.bold: true; color: shiftColor(shiftData.shift_type) }
                                    PlasmaComponents.Label { text: shiftData.team + " · 第 " + shiftData.day_of_cycle + "/" + shiftData.total_days + " 天"; font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.85; opacity: 0.7 }
                                    PlasmaComponents.Label { text: shiftData.date; font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.85; opacity: 0.6 }
                                }
                            }
                        }

                        // Stats
                        RowLayout { Layout.fillWidth: true; Layout.topMargin: Kirigami.Units.gridUnit; Layout.bottomMargin: Kirigami.Units.gridUnit; spacing: Kirigami.Units.gridUnit
                            Item { Layout.fillWidth: true }
                            ColumnLayout { spacing: 0
                                PlasmaComponents.Label { text: String(shiftData.days_until_rest); font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.5; font.bold: true; color: shiftData.days_until_rest === 0 ? "#35D07F" : Kirigami.Theme.textColor; Layout.alignment: Qt.AlignHCenter }
                                PlasmaComponents.Label { text: "距休"; font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.7; opacity: 0.5; Layout.alignment: Qt.AlignHCenter }
                            }
                            Item { Layout.fillWidth: true }
                            ColumnLayout { spacing: 0
                                PlasmaComponents.Label { text: String(shiftData.consecutive_work_days); font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.5; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                                PlasmaComponents.Label { text: "连续上班"; font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.7; opacity: 0.5; Layout.alignment: Qt.AlignHCenter }
                            }
                            Item { Layout.fillWidth: true }
                            ColumnLayout { spacing: 0
                                PlasmaComponents.Label { text: shiftData.day_of_cycle + "/" + shiftData.total_days; font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.5; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                                PlasmaComponents.Label { text: "周期进度"; font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.7; opacity: 0.5; Layout.alignment: Qt.AlignHCenter }
                            }
                            Item { Layout.fillWidth: true }
                        }

                        // Week
                        PlasmaComponents.Label { Layout.fillWidth: true; text: "──  本周排班  ──"; font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.8; opacity: 0.4; horizontalAlignment: Text.AlignHCenter }

                        Repeater {
                            model: weekData && weekData.days ? weekData.days : []
                            RowLayout { Layout.fillWidth: true; Layout.topMargin: 2; Layout.bottomMargin: 2; spacing: Kirigami.Units.smallSpacing
                                Rectangle { Layout.preferredWidth: Kirigami.Units.gridUnit * 2; Layout.preferredHeight: Kirigami.Units.gridUnit * 2; radius: Kirigami.Units.gridUnit; color: shiftColor(modelData.shift_type); opacity: modelData.is_today ? 1.0 : 0.7
                                    PlasmaComponents.Label { anchors.centerIn: parent; text: shiftEmoji(modelData.shift_type); font.pixelSize: parent.height * 0.6 }
                                }
                                PlasmaComponents.Label { text: shiftLabel(modelData.shift_type); font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.1; font.bold: modelData.is_today; color: shiftColor(modelData.shift_type); Layout.preferredWidth: Kirigami.Units.gridUnit * 1.5 }
                                PlasmaComponents.Label { text: weekdayZh(modelData.date); font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.85; opacity: 0.6; Layout.preferredWidth: Kirigami.Units.gridUnit * 3 }
                                PlasmaComponents.Label { text: String(modelData.date).slice(5); font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.85; opacity: modelData.is_today ? 1.0 : 0.5; font.bold: modelData.is_today }
                                PlasmaComponents.Label { text: modelData.is_today ? "◀ 今天" : ""; font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.8; color: "#FACC15"; font.bold: true; visible: modelData.is_today }
                                Item { Layout.fillWidth: true }
                            }
                        }

                        PlasmaComponents.Button { Layout.alignment: Qt.AlignHCenter; Layout.topMargin: Kirigami.Units.gridUnit; text: "🔄 刷新"; flat: true; onClicked: fetchAll() }
                    }
                }
            }
        }
    }
}
