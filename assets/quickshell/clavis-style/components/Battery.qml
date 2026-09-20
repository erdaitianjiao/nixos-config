import QtQuick
import Quickshell.Services.UPower

// 电池胶囊（无电池则隐藏）
Rectangle {
    id: root

    required property var shell

    readonly property var dev: UPower.displayDevice
    readonly property bool present: dev !== null && dev.isPresent
    // Quickshell 的 UPowerDevice.percentage 是 0–1 的比例（= energy / energyCapacity），
    // 不是 0–100，所以换算成百分比。
    readonly property real pct: present ? (dev.percentage <= 1 ? dev.percentage * 100 : dev.percentage) : -1
    readonly property bool charging: present && !UPower.onBattery

    visible: present
    implicitWidth: visible ? txt.implicitWidth + 24 : 0
    implicitHeight: root.shell.pillH
    radius: root.shell.pillRadius
    color: root.shell.cSurface

    Text {
        id: txt

        anchors.centerIn: parent
        text: (root.charging ? "󰂄 " : "") + Math.round(root.pct) + "%"
        color: (root.pct <= 15) ? root.shell.cRed : (root.pct <= 30) ? root.shell.cYellow : root.shell.cGreen
        font.family: root.shell.fontFam
        font.pixelSize: 13
        font.bold: true
    }
}
