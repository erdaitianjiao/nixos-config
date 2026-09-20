import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// 亮度胶囊：
//  · 左键：胶囊正下方弹出原生滑块 —— 内置屏(brightnessctl) + 外接屏(ddcutil)
//  · 滚轮：内置屏 ±5%
Rectangle {
    id: root

    required property var shell

    // 内置屏
    property real raw: 0
    readonly property int pct: Math.round(raw)

    // 外接屏（DDC/CI）
    property int ddcDisplay: 0 // 0 = 没有可 DDC 的屏
    property real extRaw: 0
    property bool extDragging: false

    implicitWidth: txt.implicitWidth + 24
    implicitHeight: root.shell.pillH
    radius: root.shell.pillRadius
    color: (hover.containsMouse || slider.visible) ? root.shell.cSurfaceHover : root.shell.cSurface

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    function setPct(p) {
        const v = Math.max(1, Math.min(100, Math.round(p)));
        root.raw = v; // 立刻反馈
        Quickshell.execDetached(["brightnessctl", "set", v + "%"]);
    }

    function setExt(v) {
        const val = Math.max(0, Math.min(100, Math.round(v)));
        root.extRaw = val;
        if (root.ddcDisplay <= 0)
            return;
        ddcSet.command = ["ddcutil", "--display", String(root.ddcDisplay), "setvcp", "10", String(val)];
        ddcSet.running = true;
    }

    // 和 waybar 的 format-icons 一致：󰃝 󰃞 󰃟 󰃠
    function glyph() {
        if (root.pct < 25)
            return "󰃝";
        if (root.pct < 50)
            return "󰃞";
        if (root.pct < 75)
            return "󰃟";
        return "󰃠";
    }

    // ── 读内置：brightnessctl -m = 设备,class,当前,百分比%,最大 ──
    Process {
        id: getProc

        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",");
                if (parts.length >= 4) {
                    const p = parseFloat(String(parts[3]).replace("%", ""));
                    if (!isNaN(p) && !slider.visible)
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

    // ── 外接屏：检测（慢，60s 一次）──
    Process {
        id: ddcDetect

        command: ["ddcutil", "detect", "--brief"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/Display\s+(\d+)/);
                root.ddcDisplay = m ? parseInt(m[1]) : 0;
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!ddcDetect.running && !ddcGet.running && !ddcSet.running)
                ddcDetect.running = true;
        }
    }

    // ── 外接屏：读 ──
    Process {
        id: ddcGet

        command: ["ddcutil", "--display", String(root.ddcDisplay), "getvcp", "10"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/current value\s*=\s*(\d+)/);
                if (m && !root.extDragging)
                    root.extRaw = parseInt(m[1]);
            }
        }
    }

    Timer {
        interval: 3000
        running: slider.visible && root.ddcDisplay > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!ddcGet.running && !ddcSet.running && !ddcDetect.running && !root.extDragging)
                ddcGet.running = true;
        }
    }

    // ── 外接屏：写（松手才写，ddcutil 很慢）──
    Process {
        id: ddcSet
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
        onClicked: slider.toggle()
        onWheel: (w) => root.setPct(root.raw + (w.angleDelta.y > 0 ? 5 : -5))
    }

    // ── 滑块弹窗，锚在胶囊正下方 ──
    PopupWindow {
        id: slider

        function toggle() {
            if (visible) {
                visible = false;
                return;
            }
            visible = true;
            hideTimer.restart();
        }
        function poke() {
            visible = true;
            hideTimer.restart();
        }

        anchor {
            item: root
            edges: Edges.Bottom
            gravity: Edges.Bottom
        }

        visible: false
        implicitWidth: 340
        implicitHeight: rows.implicitHeight + 28
        color: "transparent"

        Timer {
            id: hideTimer

            interval: 1800
            onTriggered: {
                if (hover.containsMouse || sliderHover.containsMouse) {
                    restart();
                    return;
                }
                slider.visible = false;
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: Qt.rgba(0.96, 0.97, 0.93, 0.98)
            border.width: 1
            border.color: root.shell.cBorder

            MouseArea {
                id: sliderHover

                anchors.fill: parent
                hoverEnabled: true
            }

            Column {
                id: rows

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                spacing: 10

                SliderRow {
                    width: rows.width
                    shell: root.shell
                    icon: "󰃟"
                    label: "内置屏"
                    value: root.pct
                    onMoved: (v) => {
                        root.setPct(v);
                        slider.poke();
                    }
                    onCommitted: (v) => root.setPct(v)
                }

                // 有可 DDC 的外接屏时才显示
                SliderRow {
                    width: rows.width
                    visible: root.ddcDisplay > 0
                    shell: root.shell
                    icon: "󰍹"
                    label: "外接屏"
                    value: root.extRaw
                    onMoved: (v) => {
                        root.extDragging = true;
                        root.extRaw = v;
                        slider.poke();
                    }
                    onCommitted: (v) => {
                        root.setExt(v);
                        root.extDragging = false;
                        slider.poke();
                    }
                }
            }
        }
    }
}
