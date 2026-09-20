import QtQuick
import QtQuick.Layouts
import Quickshell

// 当前聚焦窗口：图标 + 标题（超长省略）
Item {
    id: root

    required property var shell

    readonly property var win: root.shell.focusedWindow
    readonly property string title: win ? (win.title || win.app_id || "") : ""
    readonly property string appId: win ? (win.app_id || "") : ""

    implicitHeight: root.shell.pillH

    RowLayout {
        anchors.fill: parent
        spacing: 8

        Image {
            id: icon

            visible: root.appId !== ""
            source: visible ? Quickshell.iconPath(root.appId, true) : ""
            sourceSize: Qt.size(16, 16)
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            Layout.alignment: Qt.AlignVCenter
            smooth: true
        }

        Text {
            id: label

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: root.title
            color: root.shell.cFgDim
            font.family: root.shell.fontFam
            font.pixelSize: 13
            elide: Text.ElideRight
        }
    }
}
