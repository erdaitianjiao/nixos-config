import QtQuick
import Quickshell

// 电源按钮胶囊：点击打开全屏电源菜单
Rectangle {
    id: root

    required property var shell
    required property string screenName

    implicitWidth: txt.implicitWidth + 24
    implicitHeight: root.shell.pillH
    radius: root.shell.pillRadius
    color: hover.containsMouse ? root.shell.cSurfaceHover : root.shell.cSurface

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    Text {
        id: txt

        anchors.centerIn: parent
        text: "󰐥" // md-power
        color: root.shell.cRed
        font.family: root.shell.fontFam
        font.pixelSize: 16
        font.bold: true
    }

    MouseArea {
        id: hover

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.shell.togglePowerMenu(root.screenName)
    }
}
