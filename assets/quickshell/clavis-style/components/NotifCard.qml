import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications

// 单条通知卡片（风格对齐 mako：浅色卡片、圆角 12、绿色边框；urgent 红边）
Item {
    id: root

    required property var shell
    required property var notif

    signal dismissRequested()

    readonly property bool urgent: notif.urgency === NotificationUrgency.Critical
    readonly property int timeoutMs: notif.expireTimeout > 0 ? notif.expireTimeout : (urgent ? 0 : 6000)
    readonly property var actions: notif.actions ? notif.actions : []

    function iconSource() {
        if (notif.image)
            return notif.image.indexOf("/") === 0 ? "file://" + notif.image : notif.image;
        if (notif.appIcon)
            return notif.appIcon.indexOf("/") === 0 ? "file://" + notif.appIcon : Quickshell.iconPath(notif.appIcon, true);
        return "";
    }

    implicitHeight: card.implicitHeight

    Timer {
        interval: root.timeoutMs
        running: root.timeoutMs > 0
        onTriggered: root.notif.dismiss()
    }

    Rectangle {
        id: card

        anchors.left: parent.left
        anchors.right: parent.right
        implicitHeight: content.implicitHeight + 24 + 3
        radius: 12
        color: Qt.rgba(0.949, 0.965, 0.925, 0.96)
        border.width: 2
        border.color: root.urgent ? root.shell.cRed : root.shell.cGreen
        clip: true

        // 点卡片 = 触发默认动作（没有就关掉）；右键 = 直接关
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (m) => {
                if (m.button === Qt.RightButton) {
                    root.notif.dismiss();
                    return;
                }
                // 先触发默认动作（如果有），然后无论如何都关掉
                for (let i = 0; i < root.actions.length; ++i) {
                    if (root.actions[i].identifier === "default") {
                        root.actions[i].invoke();
                        break;
                    }
                }
                root.notif.dismiss();
            }
        }

        ColumnLayout {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 12
            anchors.topMargin: 12
            // 右边给关闭按钮留位置
            anchors.rightMargin: 36
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    Layout.alignment: Qt.AlignTop
                    radius: root.urgent ? 8 : 20
                    color: root.shell.cSurface

                    Image {
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        sourceSize: Qt.size(24, 24)
                        smooth: true
                        source: root.iconSource()
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: root.notif.appName || ""
                        color: root.shell.cComment
                        font.family: root.shell.fontFam
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: root.notif.summary || ""
                        color: root.shell.cFg
                        font.family: root.shell.fontFam
                        font.pixelSize: 13
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: text !== ""
                        // 去掉 <img>，其余按 StyledText 渲染
                        text: (root.notif.body || "").replace(/<img\b[^>]*>/gi, "")
                        textFormat: Text.StyledText
                        color: root.shell.cFgDim
                        font.family: root.shell.fontFam
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                        maximumLineCount: 4
                        elide: Text.ElideRight
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: root.actions.length > 0

                Repeater {
                    model: root.actions

                    delegate: Rectangle {
                        required property var modelData

                        implicitWidth: actText.implicitWidth + 22
                        implicitHeight: 26
                        radius: 13
                        color: actHover.containsMouse ? root.shell.cSurfaceHover : root.shell.cSurface
                        border.width: 1
                        border.color: root.shell.cBorder

                        Text {
                            id: actText

                            anchors.centerIn: parent
                            text: modelData.text
                            color: root.shell.cFg
                            font.family: root.shell.fontFam
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: actHover

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.invoke()
                        }
                    }
                }
            }
        }

        // 关闭按钮（右上角）
        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            width: 20
            height: 20
            radius: 10
            color: closeHover.containsMouse ? root.shell.cSurfaceHover : "transparent"

            Text {
                anchors.centerIn: parent
                text: "󰅖" // md-close
                color: root.shell.cComment
                font.family: root.shell.fontFam
                font.pixelSize: 14
            }

            MouseArea {
                id: closeHover

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.notif.dismiss()
            }
        }

        // 自动关闭进度条
        Rectangle {
            visible: root.timeoutMs > 0
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            height: 3
            color: root.shell.cGreen
            width: card.width

            NumberAnimation on width {
                from: card.width
                to: 0
                duration: root.timeoutMs
                running: root.timeoutMs > 0
            }
        }
    }
}
