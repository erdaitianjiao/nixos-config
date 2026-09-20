import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// 悬浮在屏幕顶部的圆角状态条，每个输出一条
PanelWindow {
    id: bar

    required property var shell

    readonly property string screenName: bar.screen ? bar.screen.name : ""

    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: shell.margin
        left: shell.margin
        right: shell.margin
    }
    implicitHeight: shell.barH
    color: "transparent"
    exclusiveZone: shell.barH + shell.margin
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "qs-clavis-bar"

    // 悬浮条背景
    Rectangle {
        id: bg

        anchors.fill: parent
        radius: shell.radius
        color: shell.cBg
        border.width: 1
        border.color: shell.cBorder
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8

        Workspaces {
            shell: bar.shell
            screenName: bar.screenName
            Layout.alignment: Qt.AlignVCenter
        }

        ActiveWindow {
            shell: bar.shell
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }

        Tray {
            shell: bar.shell
            Layout.alignment: Qt.AlignVCenter
        }

        Battery {
            shell: bar.shell
            Layout.alignment: Qt.AlignVCenter
        }

        Volume {
            shell: bar.shell
            Layout.alignment: Qt.AlignVCenter
        }

        Clock {
            shell: bar.shell
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // 只让圆角条区域可点
    mask: Region {
        item: bg
    }
}
