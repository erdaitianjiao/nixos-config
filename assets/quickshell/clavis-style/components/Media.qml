import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// 媒体胶囊：显示正在播放的曲目
//   左键：播放/暂停    中键：唤起播放器    滚轮：上/下一首
Rectangle {
    id: root

    required property var shell

    readonly property var players: Mpris.players ? Mpris.players.values : []
    // 优先选正在播放的，否则第一个
    readonly property var player: {
        for (let i = 0; i < players.length; ++i) {
            if (players[i].isPlaying)
                return players[i];
        }
        return players.length > 0 ? players[0] : null;
    }
    readonly property string title: player ? (String(player.trackTitle || "") || String(player.identity || "")) : ""
    readonly property string artist: player ? String(player.trackArtist || "") : ""

    visible: player !== null
    implicitWidth: visible ? Math.min(400, row.width + 28) : 0
    implicitHeight: root.shell.pillH
    radius: root.shell.pillRadius
    color: hover.containsMouse ? root.shell.cSurfaceHover : root.shell.cSurface

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: (root.player && root.player.isPlaying) ? "󰏤" : "󰐊" // md-pause / md-play
            color: (root.player && root.player.isPlaying) ? root.shell.cGreen : root.shell.cFg
            font.family: root.shell.fontFam
            font.pixelSize: 15
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 220)
            text: root.title
            elide: Text.ElideRight
            color: root.shell.cFg
            font.family: root.shell.fontFam
            font.pixelSize: 13
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.artist !== ""
            width: Math.min(implicitWidth, 140)
            text: root.artist
            elide: Text.ElideRight
            color: root.shell.cComment
            font.family: root.shell.fontFam
            font.pixelSize: 11
        }
    }

    MouseArea {
        id: hover

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: (m) => {
            if (!root.player)
                return;
            if (m.button === Qt.LeftButton) {
                if (root.player.canTogglePlaying)
                    root.player.togglePlaying();
            } else if (m.button === Qt.MiddleButton) {
                if (root.player.canRaise)
                    root.player.raise();
            }
        }
        onWheel: (w) => {
            if (!root.player)
                return;
            if (w.angleDelta.y > 0) {
                if (root.player.canGoNext)
                    root.player.next();
            } else if (root.player.canGoPrevious) {
                root.player.previous();
            }
        }
    }
}
