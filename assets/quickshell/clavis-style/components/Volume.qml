import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// 音量胶囊：滚轮 ±5%，左键静音开关，右键 pavucontrol
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

    // ⚠️ PwNodeAudio 的 volume / muted 只有在节点被 PwObjectTracker 绑定后才有效，
    // 否则读到 0 且设置无效（上游 qml.hpp 里的 WARNING）。
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    function step(delta) {
        if (!root.audio)
            return;
        root.audio.volume = Math.max(0, Math.min(1, root.audio.volume + delta));
        if (root.audio.muted && delta > 0)
            root.audio.muted = false;
    }

    function glyph() {
        if (root.muted)
            return "󰝟"; // volume off
        if (root.vol > 0.66)
            return "󰕾"; // high
        if (root.vol > 0.33)
            return "󰖀"; // medium
        return "󰕿"; // low
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
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (m) => {
            if (!root.audio)
                return;
            if (m.button === Qt.LeftButton)
                root.audio.muted = !root.audio.muted;
            else
                Quickshell.execDetached(["pavucontrol"]);
        }
        onWheel: (w) => root.step(w.angleDelta.y > 0 ? 0.05 : -0.05);
    }
}
