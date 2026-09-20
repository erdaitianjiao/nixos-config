import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

// 系统托盘（StatusNotifier）
Rectangle {
    id: root

    required property var shell

    readonly property var items: SystemTray.items ? SystemTray.items.values : []

    visible: items.length > 0
    implicitWidth: visible ? row.implicitWidth + 20 : 0
    implicitHeight: root.shell.pillH
    radius: root.shell.pillRadius
    color: root.shell.cSurface

    Row {
        id: row

        anchors.centerIn: parent
        spacing: 8

        Repeater {
            model: root.items

            delegate: Image {
                id: icon

                required property var modelData

                width: 16
                height: 16
                sourceSize: Qt.size(16, 16)
                smooth: true
                source: (modelData.icon && modelData.icon.indexOf("/") === 0) ? "file://" + modelData.icon : Quickshell.iconPath(
                                                                                    modelData.icon || "", true)

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (m) => {
                        if (m.button === Qt.LeftButton)
                            icon.modelData.activate();
                        else
                            icon.modelData.secondaryActivate();
                    }
                }
            }
        }
    }
}
