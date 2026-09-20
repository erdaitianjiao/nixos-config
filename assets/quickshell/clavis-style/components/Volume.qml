import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// 音量胶囊（点击打开 pavucontrol）
Rectangle {
    id: root

    required property var shell

    readonly property var node: Pipewire.defaultAudioSink
    readonly property var audio: node ? node.audio : null
    readonly property real vol: audio ? Math.max(0, Math.min(1, audio.volume)) : 0
    readonly property bool muted: audio ? audio.muted : false

    implicitWidth: txt.implicitWidth + 24
    implicitHeight: root.shell.pillH
    radius: root.shell.pillRadius
    color: hover.containsMouse ? root.shell.cSurfaceHover : root.shell.cSurface

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    function glyph() {
        if (root.muted)
            return "󰝟"; // volume off
        if (root.vol > 0.66)
            return "󰕾"; // volume high
        if (root.vol > 0.33)
            return "󰖀"; // volume medium
        return "󰕿"; // volume low
    }

    Text {
        id: txt

        anchors.centerIn: parent
        text: root.glyph() + "  " + Math.round(root.vol * 100) + "%"
        color: root.muted ? root.shell.cComment : root.shell.cAccent2
        font.family: root.shell.fontFam
        font.pixelSize: 13
        font.bold: true
    }

    MouseArea {
        id: hover

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["pavucontrol"])
    }
}
