import QtQuick
import QtQuick.Layouts

// 一行滑块：图标+名称 | 轨道(可点可拖) | 百分比
Item {
    id: root

    property var shell
    property string icon: ""
    property string label: ""
    property real value: 0 // 0..100

    signal moved(real value) // 拖动中
    signal committed(real value) // 松手

    implicitHeight: 26

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Text {
            Layout.preferredWidth: 78
            text: root.icon + " " + root.label
            color: root.shell.cFgDim
            font.family: root.shell.fontFam
            font.pixelSize: 12
            elide: Text.ElideRight
        }

        Item {
            id: trackArea

            Layout.fillWidth: true
            Layout.preferredHeight: 22

            readonly property real frac: Math.max(0, Math.min(1, root.value / 100))

            Rectangle {
                id: track

                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 8
                radius: 4
                color: root.shell.cSurface
                border.width: 1
                border.color: root.shell.cBorder
            }

            Rectangle {
                anchors.left: track.left
                anchors.verticalCenter: track.verticalCenter
                width: track.width * trackArea.frac
                height: track.height
                radius: track.radius
                color: root.shell.cYellow
            }

            Rectangle {
                anchors.verticalCenter: track.verticalCenter
                x: Math.max(0, Math.min(track.width - width, track.width * trackArea.frac - width / 2))
                width: 16
                height: 16
                radius: 8
                color: "#ffffff"
                border.width: 2
                border.color: root.shell.cYellow
            }

            MouseArea {
                anchors.fill: parent
                anchors.topMargin: -6
                anchors.bottomMargin: -6
                cursorShape: Qt.PointingHandCursor

                function valueAt(mx) {
                    return track.width > 0 ? Math.round(Math.max(0, Math.min(1, mx / track.width)) * 100) : root.value;
                }
                onPressed: (m) => root.moved(valueAt(m.x))
                onPositionChanged: (m) => {
                    if (pressed)
                        root.moved(valueAt(m.x));
                }
                onReleased: (m) => root.committed(valueAt(m.x))
            }
        }

        Text {
            Layout.preferredWidth: 38
            horizontalAlignment: Text.AlignRight
            text: Math.round(root.value) + "%"
            color: root.shell.cFg
            font.family: root.shell.fontFam
            font.pixelSize: 12
            font.bold: true
        }
    }
}
