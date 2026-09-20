import QtQuick
import QtQuick.Layouts

// niri 工作区指示器（Clavis 风：小圆点，激活/悬停时拉长成胶囊）
Rectangle {
    id: root

    required property var shell
    required property string screenName

    readonly property var list: {
        const all = root.shell.workspaces || [];
        const out = [];
        for (let i = 0; i < all.length; ++i) {
            if (all[i].output === root.screenName)
                out.push(all[i]);
        }
        return out;
    }

    implicitWidth: row.implicitWidth + 20
    implicitHeight: root.shell.pillH
    radius: root.shell.pillRadius
    color: root.shell.cSurface

    Row {
        id: row

        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: root.list

            delegate: Item {
                id: dot

                required property var modelData

                readonly property bool active: modelData.is_active
                readonly property bool hasWindows: modelData.active_window_id !== null

                width: (active || hover.hovered) ? 24 : 9
                height: 20

                Behavior on width {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: dot.width
                    height: 9
                    radius: height / 2
                    color: dot.active ? root.shell.cAccent : dot.hasWindows ? root.shell.cFg : root.shell.cFgDim

                    Behavior on color {
                        ColorAnimation {
                            duration: 180
                        }
                    }
                }

                MouseArea {
                    id: hover

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.shell.focusWorkspace(dot.modelData.id)
                }
            }
        }
    }
}
