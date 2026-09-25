import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

// 通知中心：右侧抽屉，列出历史通知
// 打开时把屏幕名固定（和电源菜单/启动器一样），避免多屏时抖动
PanelWindow {
    id: root

    required property var shell
    required property var manager

    readonly property bool onThisScreen: screen && screen.name === shell.notifCenterScreen

    function timeText(ms) {
        const d = new Date(ms);
        const now = new Date();
        if (d.toDateString() === now.toDateString())
            return Qt.formatDateTime(d, "HH:mm");
        return Qt.formatDateTime(d, "MM-dd HH:mm");
    }

    function iconSource(item) {
        if (item.image)
            return String(item.image).indexOf("/") === 0 ? "file://" + item.image : String(item.image);
        if (item.appIcon)
            return String(item.appIcon).indexOf("/") === 0 ? "file://" + item.appIcon : Quickshell.iconPath(String(item.appIcon), true);
        return "";
    }

    // 关闭时先播完退场动画再真正隐藏窗口
    readonly property bool shown: shell.notifCenterOpen && onThisScreen
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
    WlrLayershell.namespace: "qs-clavis-notifcenter"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    // Esc 关闭
    Item {
        anchors.fill: parent
        focus: root.visible
        Keys.onEscapePressed: root.shell.closeNotifCenter()
    }

    // 点空白处关闭
    Rectangle {
        id: backdrop

        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.15)
        opacity: root.shown ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: root.shown ? root.shell.durEnter : root.shell.durExit
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.shell.closeNotifCenter()
        }
    }

    Rectangle {
        id: panel

        opacity: root.shown ? 1 : 0
        onOpacityChanged: if (!root.shown && opacity === 0) root.closing = false

        transform: Translate {
            x: root.shown ? 0 : 24

            Behavior on x {
                NumberAnimation {
                    duration: root.shown ? root.shell.durEnter : root.shell.durExit
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.shell.easeEnter
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: root.shown ? root.shell.durEnter : root.shell.durExit
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.shell.easeEnter
            }
        }

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 8
        anchors.rightMargin: 8
        anchors.bottomMargin: 8
        width: Math.min(400, root.width - 16)
        radius: 18
        color: Qt.rgba(0.96, 0.97, 0.93, 0.97)
        border.width: 1
        border.color: root.shell.cBorder
        clip: true

        // 吞掉面板内的点击
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "通知"
                    color: root.shell.cFg
                    font.family: root.shell.fontFam
                    font.pixelSize: 15
                    font.bold: true
                }

                Text {
                    Layout.fillWidth: true
                    text: root.manager.history.length > 0 ? root.manager.history.length + " 条" : ""
                    color: root.shell.cComment
                    font.family: root.shell.fontFam
                    font.pixelSize: 11
                }

                Rectangle {
                    implicitWidth: clearText.implicitWidth + 20
                    implicitHeight: 28
                    radius: 14
                    color: clearHover.containsMouse ? root.shell.cSurfaceHover : root.shell.cSurface
                    border.width: 1
                    border.color: root.shell.cBorder

                    Text {
                        id: clearText

                        anchors.centerIn: parent
                        text: "清空"
                        color: root.shell.cFgDim
                        font.family: root.shell.fontFam
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: clearHover

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.manager.clearHistory()
                    }
                }

                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 14
                    color: closeHover.containsMouse ? root.shell.cSurfaceHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖" // md-close
                        color: root.shell.cComment
                        font.family: root.shell.fontFam
                        font.pixelSize: 15
                    }

                    MouseArea {
                        id: closeHover

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.shell.closeNotifCenter()
                    }
                }
            }

            ListView {
                id: list

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 8
                model: root.manager.history
                boundsBehavior: Flickable.StopAtBounds
                visible: root.manager.history.length > 0

                delegate: Rectangle {
                    id: item

                    required property var modelData

                    width: list.width
                    height: itemContent.implicitHeight + 20
                    radius: 12
                    color: itemHover.containsMouse ? root.shell.cSurfaceHover : root.shell.cSurface
                    border.width: 1
                    border.color: item.modelData.urgency === NotificationUrgency.Critical ? root.shell.cRed : root.shell.cBorder

                    MouseArea {
                        id: itemHover

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.manager.removeHistory(item.modelData.id)

                        Rectangle {
                            visible: itemHover.containsMouse
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 8
                            width: 20
                            height: 20
                            radius: 10
                            color: root.shell.cSurface

                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                color: root.shell.cComment
                                font.family: root.shell.fontFam
                                font.pixelSize: 12
                            }
                        }
                    }

                    ColumnLayout {
                        id: itemContent

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Image {
                                Layout.preferredWidth: 18
                                Layout.preferredHeight: 18
                                sourceSize: Qt.size(18, 18)
                                smooth: true
                                source: root.iconSource(item.modelData)
                            }

                            Text {
                                Layout.fillWidth: true
                                text: item.modelData.appName
                                color: root.shell.cComment
                                font.family: root.shell.fontFam
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }

                            Text {
                                text: root.timeText(item.modelData.time)
                                color: root.shell.cComment
                                font.family: root.shell.fontFam
                                font.pixelSize: 10
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: item.modelData.summary
                            color: root.shell.cFg
                            font.family: root.shell.fontFam
                            font.pixelSize: 13
                            font.bold: true
                            elide: Text.ElideRight
                            maximumLineCount: 2
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: String(item.modelData.body || "").replace(/<img\b[^>]*>/gi, "")
                            textFormat: Text.StyledText
                            color: root.shell.cFgDim
                            font.family: root.shell.fontFam
                            font.pixelSize: 11
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.manager.history.length === 0
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: "暂无通知"
                color: root.shell.cComment
                font.family: root.shell.fontFam
                font.pixelSize: 13
            }
        }
    }
}
