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
    // niri 会把 margin 叠加到 exclusiveZone 上，顶部实际预留 = margin + exclusiveZone。
    //   可见间距 = (margin + exclusiveZone) + niri gaps(8) - (margin + barH)
    //            = exclusiveZone + 8 - barH
    // 之前写 barH + margin 相当于把 margin 算了两遍 → 间距 16。
    // 现在 = barH → 间距 8，和 niri 的 gaps / waybar 一致。
    // 想再紧/松一点就 shell.barH ± N（N=3 → 间距 11，N=-3 → 间距 5）。
    exclusiveZone: shell.barH
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

        Network {
            shell: bar.shell
            Layout.alignment: Qt.AlignVCenter
        }

        Bluetooth {
            shell: bar.shell
            Layout.alignment: Qt.AlignVCenter
        }

        Volume {
            shell: bar.shell
            Layout.alignment: Qt.AlignVCenter
        }

        Brightness {
            shell: bar.shell
            Layout.alignment: Qt.AlignVCenter
        }

        Battery {
            shell: bar.shell
            Layout.alignment: Qt.AlignVCenter
        }

        Clock {
            shell: bar.shell
            Layout.alignment: Qt.AlignVCenter
        }

        Power {
            shell: bar.shell
            screenName: bar.screenName
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // 只让圆角条区域可点
    mask: Region {
        item: bg
    }
}
