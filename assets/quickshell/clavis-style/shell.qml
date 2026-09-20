// Clavis 风格的 niri shell（Quickshell）
// 试运行：  qs -p ~/nixos-config/assets/quickshell/clavis-style
//
// 指定图标主题：否则 QIcon::fromTheme 找不到托盘里的 symbolic 图标
// （如 fcitx 的 input-keyboard-symbolic 只在 Tela 里有）。
//@ pragma IconTheme Tela

import QtQuick
import Quickshell
import Quickshell.Io
import "components"

ShellRoot {
    Item {
        id: app

        // ── 配色 / 尺寸（对齐 light(Matcha) 主题：assets/niri/light/style.css）──
        readonly property color cBg: Qt.rgba(0.949, 0.965, 0.925, 0.78) // #f2f6ec 半透明
        readonly property color cSurface: Qt.rgba(0.902, 0.925, 0.867, 0.95) // #e6ecdd
        readonly property color cSurfaceHover: Qt.rgba(0.855, 0.882, 0.812, 1.0) // #dae1cf
        readonly property color cFg: "#3d4a44"
        readonly property color cFgDim: "#5e7065"
        readonly property color cComment: "#93a48f"
        readonly property color cAccent: "#4f9d57" // green：工作区激活
        readonly property color cAccent2: "#967bc0" // purple：音量
        readonly property color cCyan: "#3fa98e"
        readonly property color cBlue: "#4d87c8"
        readonly property color cGreen: "#4f9d57"
        readonly property color cYellow: "#c39a3f"
        readonly property color cOrange: "#d97848"
        readonly property color cRed: "#d86666"
        readonly property color cBorder: Qt.rgba(0.761, 0.827, 0.682, 0.85) // #c2d3ae

        readonly property int radius: 16
        readonly property int barH: 36
        readonly property int margin: 8
        readonly property int pillH: 28
        readonly property int pillRadius: 14
        readonly property string fontFam: "CaskaydiaCove Nerd Font"

        // ── niri 状态 ──
        property var workspaces: []
        property var focusedWindow: null
        property bool niriOk: false

        // ── 电源菜单 ──
        property bool powerMenuOpen: false
        property string powerMenuScreen: ""

        // 从 niri 工作区状态推断当前聚焦输出（供快捷键触发用）
        function focusedOutput() {
            for (let i = 0; i < app.workspaces.length; ++i) {
                if (app.workspaces[i].is_focused)
                    return app.workspaces[i].output;
            }
            return Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "";
        }
        function togglePowerMenu(screenName) {
            const target = screenName || app.focusedOutput();
            if (app.powerMenuOpen && app.powerMenuScreen === target) {
                app.powerMenuOpen = false;
            } else {
                app.powerMenuScreen = target;
                app.powerMenuOpen = true;
            }
        }
        function closePowerMenu() {
            app.powerMenuOpen = false;
        }
        function powerAction(action) {
            app.powerMenuOpen = false;
            switch (action) {
            case "lock":
                Quickshell.execDetached(["swaylock"]);
                break;
            case "logout":
                Quickshell.execDetached(["niri", "msg", "action", "quit", "--skip-confirmation"]);
                break;
            case "suspend":
                Quickshell.execDetached(["systemctl", "suspend"]);
                break;
            case "hibernate":
                Quickshell.execDetached(["systemctl", "hibernate"]);
                break;
            case "reboot":
                Quickshell.execDetached(["systemctl", "reboot"]);
                break;
            case "poweroff":
                Quickshell.execDetached(["systemctl", "poweroff"]);
                break;
            }
        }

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

        // ── IPC：Super+Backspace 走 `qs ipc call power-menu toggle` 触发 ──
        IpcHandler {
            target: "power-menu"

            function open(): void {
                app.powerMenuScreen = app.focusedOutput();
                app.powerMenuOpen = true;
            }
            function close(): void {
                app.powerMenuOpen = false;
            }
            function toggle(): void {
                app.togglePowerMenu(app.focusedOutput());
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

        // ── 每个输出一个电源菜单（全屏覆盖）──
        Variants {
            model: Quickshell.screens

            PowerMenuWindow {
                required property var modelData

                screen: modelData
                shell: app
            }
        }
    }
}
