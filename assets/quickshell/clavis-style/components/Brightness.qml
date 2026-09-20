import QtQuick
import Quickshell
import Quickshell.Io

// 亮度胶囊：滚轮 ±5%（brightnessctl），左键打开 slider-popup（内置+外接屏 ddcutil）
Rectangle {
    id: root

    required property var shell

    property real raw: 0
    readonly property int pct: Math.round(raw)

    implicitWidth: txt.implicitWidth + 24
    implicitHeight: root.shell.pillH
    radius: root.shell.pillRadius
    color: hover.containsMouse ? root.shell.cSurfaceHover : root.shell.cSurface

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    // brightnessctl -m 输出: 设备,class,当前,百分比%,最大
    Process {
        id: getProc

        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",");
                if (parts.length >= 4) {
                    const p = parseFloat(String(parts[3]).replace("%", ""));
                    if (!isNaN(p))
                        root.raw = p;
                }
            }
        }
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!getProc.running)
                getProc.running = true;
        }
    }

    function setPct(p) {
        const v = Math.max(1, Math.min(100, Math.round(p)));
        root.raw = v; // 立即反馈
        Quickshell.execDetached(["brightnessctl", "set", v + "%"]);
    }

    // 和 waybar 的 format-icons 一致：󰃝 󰃞 󰃟 󰃠
    function glyph() {
        if (root.pct < 25)
            return "󰃝"; // brightness_4
        if (root.pct < 50)
            return "󰃞"; // brightness_5
        if (root.pct < 75)
            return "󰃟"; // brightness_6
        return "󰃠"; // brightness_7
    }

    Text {
        id: txt

        anchors.centerIn: parent
        text: root.glyph() + "  " + root.pct + "%"
        color: root.shell.cYellow
        font.family: root.shell.fontFam
        font.pixelSize: 13
        font.bold: true
    }

    MouseArea {
        id: hover

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/waybar/slider-popup", "brightness"])
        onWheel: (w) => root.setPct(root.raw + (w.angleDelta.y > 0 ? 5 : -5))
    }
}
