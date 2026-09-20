// Clavis 风格的 niri shell（Quickshell）
// 试运行：  qs -p ~/nixos-config/assets/quickshell/clavis-style
import QtQuick
import Quickshell
import Quickshell.Io
import "components"

ShellRoot {
    Item {
        id: app

        // ── 配色 / 尺寸（Clavis 风：悬浮圆角条 + Material 3 半透明表面）──
        readonly property color cBg: Qt.rgba(0.055, 0.067, 0.114, 0.80)
        readonly property color cSurface: Qt.rgba(0.145, 0.169, 0.259, 0.92)
        readonly property color cSurfaceHover: Qt.rgba(0.216, 0.247, 0.373, 0.96)
        readonly property color cFg: "#c0caf5"
        readonly property color cFgDim: "#7f87b3"
        readonly property color cAccent: "#7aa2f7"
        readonly property color cAccent2: "#bb9af7"
        readonly property color cGreen: "#9ece6a"
        readonly property color cYellow: "#e0af68"
        readonly property color cRed: "#f7768e"
        readonly property color cBorder: Qt.rgba(1, 1, 1, 0.08)

        readonly property int radius: 19
        readonly property int barH: 38
        readonly property int margin: 8
        readonly property int pillH: 30
        readonly property int pillRadius: 15
        readonly property string fontFam: "CaskaydiaCove Nerd Font, JetBrainsMono Nerd Font, Noto Sans CJK SC, sans-serif"

        // ── niri 状态 ──
        property var workspaces: []
        property var focusedWindow: null
        property bool niriOk: false

        function focusWorkspace(id) {
            Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(id)]);
        }
        function focusWindow(id) {
            Quickshell.execDetached(["niri", "msg", "action", "focus-window", "--id", String(id)]);
        }

        Process {
            id: wsProc

            command: ["niri", "msg", "--json", "workspaces"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        app.workspaces = JSON.parse(text);
                        app.niriOk = true;
                    } catch (e) {
                        app.niriOk = false;
                    }
                }
            }
        }

        Process {
            id: winProc

            command: ["niri", "msg", "--json", "focused-window"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        const t = text.trim();
                        app.focusedWindow = (t === "" || t === "null") ? null : JSON.parse(t);
                    } catch (e) {
                        app.focusedWindow = null;
                    }
                }
            }
        }

        Timer {
            interval: 500
            running: true
            repeat: true
            onTriggered: {
                if (!wsProc.running)
                    wsProc.running = true;
                if (!winProc.running)
                    winProc.running = true;
            }
        }

        // ── 每个输出一条 bar ──
        Variants {
            model: Quickshell.screens

            Bar {
                required property var modelData

                screen: modelData
                shell: app
            }
        }
    }
}
