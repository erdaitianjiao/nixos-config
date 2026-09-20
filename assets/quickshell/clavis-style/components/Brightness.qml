import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// 亮度胶囊：
//  · 左键：在胶囊正下方弹出原生滑块（拖动即时生效，松手/无操作 1.8s 自动隐藏）
//  · 滚轮：±5%
//  · 右键：老的字幕 slider-popup（内置屏 + 外接屏 ddcutil 精细调）
Rectangle {
    id: root

    required property var shell

    property real raw: 0
    readonly property int pct: Math.round(raw)

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
        root.raw = v; // 立刻反馈，不等 1.5s 轮询
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

    // brightnessctl -m 输出: 设备,class,当前,百分比%,最大
    Process {
        id: getProc

        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",");
                if (parts.length >= 4) {
                    const p = parseFloat(String(parts[3]).replace("%", ""));
                    if (!isNaN(p) && !sliderHover.pressed && !slider.visible)
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
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (m) => {
            if (m.button === Qt.LeftButton)
                slider.toggle();
            else
                Quickshell.execDetached([Quickshell.env("HOME") + "/.config/waybar/slider-popup", "brightness"]);
        }
        onWheel: (w) => root.setPct(root.raw + (w.angleDelta.y > 0 ? 5 : -5))
    }

    // ── 原生滑块弹窗：锚在胶囊正下方 ──
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
        implicitWidth: 264
        implicitHeight: 56
        color: "transparent"

        Timer {
            id: hideTimer

            interval: 1800
            onTriggered: {
                // 鼠标还在胶囊或滑块上就先不关
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

            Item {
                id: trackArea

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                height: 22

                // 轨道
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

                // 已填充部分
                Rectangle {
                    anchors.left: track.left
                    anchors.verticalCenter: track.verticalCenter
                    width: track.width * root.pct / 100
                    height: track.height
                    radius: track.radius
                    color: root.shell.cYellow
                }

                // 滑块
                Rectangle {
                    id: knob

                    anchors.verticalCenter: track.verticalCenter
                    x: Math.max(0, Math.min(track.width - width, track.width * root.pct / 100 - width / 2))
                    width: 16
                    height: 16
                    radius: 8
                    color: "#ffffff"
                    border.width: 2
                    border.color: root.shell.cYellow
                }

                // 轨道（±6px 加大命中区，好点）
                MouseArea {
                    anchors.fill: parent
                    anchors.topMargin: -6
                    anchors.bottomMargin: -6
                    cursorShape: Qt.PointingHandCursor
                    onPressed: (m) => applyAt(m.x)
                    onPositionChanged: (m) => {
                        if (pressed)
                            applyAt(m.x);
                    }
                    function applyAt(mx) {
                        root.setPct(track.width > 0 ? Math.round(mx / track.width * 100) : root.pct);
                        slider.poke();
                    }
                }
            }
        }
    }
}
