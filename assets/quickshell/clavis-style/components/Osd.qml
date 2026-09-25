import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// 音量 / 亮度 OSD：居中偏下的小卡片，1.5s 自动消失。
// 纯展示 —— 用空 mask 让鼠标点击穿透过去，不挡操作。
PanelWindow {
    id: root

    required property var shell

    readonly property bool onThisScreen: screen && screen.name === shell.osdScreen

    function glyph() {
        if (root.shell.osdKind === "brightness") {
            const p = root.shell.osdValue;
            if (p < 25)
                return "󰃝";
            if (p < 50)
                return "󰃞";
            if (p < 75)
                return "󰃟";
            return "󰃠";
        }
        const v = root.shell.osdValue;
        if (v <= 0)
            return "󰝟";
        if (v > 66)
            return "󰕾";
        if (v > 33)
            return "󰖀";
        return "󰕿";
    }

    // 关闭时先播完退场动画再真正隐藏窗口
    readonly property bool shown: shell.osdVisible && onThisScreen
    property bool closing: false

    visible: shown || closing

    onShownChanged: {
        if (shown)
            root.closing = false;
        else if (root.visible)
            root.closing = true;
    }

    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-clavis-osd"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // 空输入区域 → 点击穿透
    mask: Region {}

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    Rectangle {
        id: card

        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.96
        onOpacityChanged: if (!root.shown && opacity === 0) root.closing = false

        Behavior on opacity {
            NumberAnimation {
                duration: root.shown ? root.shell.durEnter : root.shell.durExit
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.shell.easeEnter
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: root.shown ? root.shell.durEnter : root.shell.durExit
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.shell.easeEnter
            }
        }

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: Math.round(root.height * 0.13)
        width: 260
        height: 66
        radius: 18
        color: Qt.rgba(0.96, 0.97, 0.93, 0.96)
        border.width: 1
        border.color: root.shell.cBorder

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 14

            Text {
                text: root.glyph()
                color: root.shell.cFg
                font.family: root.shell.fontFam
                font.pixelSize: 26
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: root.shell.osdKind === "brightness" ? "亮度" : "音量"
                    color: root.shell.cFgDim
                    font.family: root.shell.fontFam
                    font.pixelSize: 11
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 8
                    radius: 4
                    color: root.shell.cSurface
                    border.width: 1
                    border.color: root.shell.cBorder

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * Math.max(0, Math.min(1, root.shell.osdValue / 100))
                        radius: 4
                        color: root.shell.cGreen

                        Behavior on width {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }

            Text {
                Layout.preferredWidth: 44
                horizontalAlignment: Text.AlignRight
                text: Math.round(root.shell.osdValue) + "%"
                color: root.shell.cFg
                font.family: root.shell.fontFam
                font.pixelSize: 14
                font.bold: true
            }
        }
    }
}
