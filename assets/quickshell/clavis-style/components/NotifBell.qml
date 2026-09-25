import QtQuick
import Quickshell

// 通知中心入口胶囊：有未读时变黄并显示数量
Rectangle {
    id: root

    required property var shell

    readonly property int unread: root.shell.notifUnread

    implicitWidth: txt.implicitWidth + 24
    implicitHeight: root.shell.pillH
    radius: root.shell.pillRadius
    color: (hover.containsMouse || root.shell.notifCenterOpen) ? root.shell.cSurfaceHover : root.shell.cSurface

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    Text {
        id: txt

        anchors.centerIn: parent
        text: "󰂚" + (root.unread > 0 ? "  " + root.unread : "") // md-bell
        color: root.unread > 0 ? root.shell.cYellow : root.shell.cComment
        font.family: root.shell.fontFam
        font.pixelSize: 14
    }

    MouseArea {
        id: hover

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.shell.toggleNotifCenter()
    }
}
