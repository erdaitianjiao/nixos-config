import QtQuick
import Quickshell.Services.UPower

// 电池胶囊（无电池则隐藏）
Rectangle {
    id: root

    required property var shell

    readonly property var dev: UPower.displayDevice
    readonly property bool present: dev !== null && dev.isPresent
    readonly property int pct: present ? Math.round(dev.percentage) : -1
    readonly property bool charging: present && !UPower.onBattery

    visible: present
    implicitWidth: visible ? txt.implicitWidth + 24 : 0
    implicitHeight: root.shell.pillH
    radius: root.shell.pillRadius
    color: root.shell.cSurface

    Text {
        id: txt

        anchors.centerIn: parent
        text: (root.charging ? "󰂄 " : "") + root.pct + "%"
        color: (root.pct <= 15) ? root.shell.cRed : (root.pct <= 30) ? root.shell.cYellow : root.shell.cGreen
        font.family: root.shell.fontFam
        font.pixelSize: 13
        font.bold: true
    }
}
