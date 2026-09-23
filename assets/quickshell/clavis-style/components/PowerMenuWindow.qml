import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// 全屏电源菜单（Clavis PowerMenu 风格）：暗背景 + 居中一排大按钮
// Esc 关闭，←/→ 选择，Enter 执行
PanelWindow {
    id: root

    required property var shell

    readonly property bool shown: shell.powerMenuOpen && screen && screen.name === shell.powerMenuScreen

    readonly property var actions: [
        {
            "action": "screenoff",
            "icon": "󰶐", // md-monitor_off
            "label": "熄屏",
            "danger": false
        },
        {
            "action": "lock",
            "icon": "󰌾", // md-lock
            "label": "锁定",
            "danger": false
        },
        {
            "action": "logout",
            "icon": "󰍃", // md-logout
            "label": "注销",
            "danger": false
        },
        {
            "action": "suspend",
            "icon": "󰒲", // md-sleep
            "label": "睡眠",
            "danger": false
        },
        {
            "action": "hibernate",
            "icon": "󰜗", // md-snowflake
            "label": "休眠",
            "danger": false
        },
        {
            "action": "reboot",
            "icon": "󰜉", // md-restart
            "label": "重启",
            "danger": false
        },
        {
            "action": "poweroff",
            "icon": "󰐥", // md-power
            "label": "关机",
            "danger": true
        }
    ]

    property int selectedIndex: 0

    visible: shown
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-clavis-powermenu"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    onShownChanged: {
        if (shown) {
            root.selectedIndex = 0;
            keyCatcher.forceActiveFocus();
        }
    }

    // 键盘（放在最底层，不挡鼠标）
    Item {
        id: keyCatcher

        anchors.fill: parent
        focus: root.shown
        Keys.onEscapePressed: root.shell.closePowerMenu()
        Keys.onLeftPressed: root.selectedIndex = (root.selectedIndex + root.actions.length - 1) % root.actions.length
        Keys.onRightPressed: root.selectedIndex = (root.selectedIndex + 1) % root.actions.length
        Keys.onReturnPressed: root.shell.powerAction(root.actions[root.selectedIndex].action)
        Keys.onEnterPressed: root.shell.powerAction(root.actions[root.selectedIndex].action)
    }

    // 暗背景（点击关闭）
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)

        MouseArea {
            anchors.fill: parent
            onClicked: root.shell.closePowerMenu()
        }
    }

    // 居中卡片
    Rectangle {
        id: card

        anchors.centerIn: parent
        width: row.implicitWidth + 48
        height: row.implicitHeight + 48
        radius: 24
        color: Qt.rgba(0.96, 0.97, 0.93, 0.98)
        border.width: 1
        border.color: root.shell.cBorder

        // 吞掉卡片区域的点击，避免穿透到背景把菜单关掉
        MouseArea {
            anchors.fill: parent
        }

        RowLayout {
            id: row

            anchors.centerIn: parent
            spacing: 12

            Repeater {
                model: root.actions

                delegate: Rectangle {
                    id: btn

                    required property int index
                    required property var modelData

                    readonly property bool selected: root.selectedIndex === index

                    width: 96
                    height: 96
                    radius: 20
                    color: (selected || mouse.containsMouse) ? root.shell.cSurfaceHover : root.shell.cSurface
                    border.width: selected ? 2 : 1
                    border.color: selected ? root.shell.cAccent : root.shell.cBorder

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: btn.modelData.icon
                            color: btn.modelData.danger ? root.shell.cRed : root.shell.cFg
                            font.family: root.shell.fontFam
                            font.pixelSize: 34
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: btn.modelData.label
                            color: root.shell.cFgDim
                            font.family: root.shell.fontFam
                            font.pixelSize: 12
                        }
                    }

                    MouseArea {
                        id: mouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.shell.powerAction(btn.modelData.action)
                    }
                }
            }
        }
    }
}
