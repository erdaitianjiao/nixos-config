import QtQuick
import Quickshell
import Quickshell.Wayland

// 通知弹窗层：每个输出一个，只在「当前聚焦输出」上显示
// 位置/配色对齐 mako：右上角、margin 48,10，卡片宽度 360
PanelWindow {
    id: root

    required property var shell
    required property var manager

    readonly property bool onThisScreen: screen && screen.name === shell.focusedOutput()

    visible: manager.items.length > 0 && onThisScreen
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-clavis-notifs"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        right: true
    }
    margins {
        top: 48
        right: 10
    }
    implicitWidth: 360
    implicitHeight: list.implicitHeight

    Column {
        id: list

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 8

        Repeater {
            model: root.manager.items

            delegate: NotifCard {
                required property var modelData

                width: list.width
                shell: root.shell
                notif: modelData
                onClosed: root.manager.remove(modelData.id)
            }
        }
    }
}
