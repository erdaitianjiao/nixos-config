import QtQuick

// 时钟胶囊
Rectangle {
    id: root

    required property var shell

    property date now: new Date()

    implicitWidth: txt.implicitWidth + 24
    implicitHeight: root.shell.pillH
    radius: root.shell.pillRadius
    color: root.shell.cSurface

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Text {
        id: txt

        anchors.centerIn: parent
        text: Qt.formatDateTime(root.now, "ddd MM-dd  HH:mm")
        color: root.shell.cFg
        font.family: root.shell.fontFam
        font.pixelSize: 13
        font.bold: true
    }
}
