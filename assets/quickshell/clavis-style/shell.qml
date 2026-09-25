// Clavis 风格的 niri shell（Quickshell）
// 试运行：  qs -p ~/nixos-config/assets/quickshell/clavis-style
//
// 指定图标主题：否则 QIcon::fromTheme 找不到托盘里的 symbolic 图标
// （如 fcitx 的 input-keyboard-symbolic 只在 Tela 里有）。
//@ pragma IconTheme Tela

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
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
            case "screenoff":
                // DPMS 关屏；动一下键盘/鼠标 niri 会自动点亮，且不锁屏。
                Quickshell.execDetached(["niri", "msg", "action", "power-off-monitors"]);
                break;
            case "lock":
                locker.open();
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

        // ── 启动器（Mod+D）──
        property bool launcherOpen: false
        property string launcherScreen: ""

        function openLauncher() {
            // 和电源菜单一样：打开时把屏幕名固定，否则 focusedOutput()
            // 每 500ms 轮询一变，窗口会在两块屏之间跳。
            app.launcherScreen = app.focusedOutput();
            app.launcherOpen = true;
        }
        function closeLauncher() {
            app.launcherOpen = false;
        }
        function toggleLauncher() {
            if (app.launcherOpen)
                app.closeLauncher();
            else
                app.openLauncher();
        }

        // ── OSD（音量 / 亮度按键提示）──
        property bool osdVisible: false
        property string osdKind: "" // "volume" | "brightness"
        property real osdValue: 0
        property string osdScreen: ""
        property bool osdArmed: false // 启动后过几秒才开始弹，避免初始化时误弹

        function showOsd(kind, value) {
            app.osdKind = kind;
            app.osdValue = Math.max(0, Math.min(100, value));
            app.osdScreen = app.focusedOutput();
            app.osdVisible = true;
            osdHideTimer.restart();
        }

        Timer {
            id: osdHideTimer

            interval: 1500
            onTriggered: app.osdVisible = false
        }

        Timer {
            interval: 2500
            running: true
            onTriggered: app.osdArmed = true
        }

        // ── 通知中心（右侧抽屉）──
        property bool notifCenterOpen: false
        property string notifCenterScreen: ""

        function openNotifCenter() {
            app.notifCenterScreen = app.focusedOutput();
            app.notifCenterOpen = true;
            notifs.markRead();
        }
        function closeNotifCenter() {
            app.notifCenterOpen = false;
        }
        function toggleNotifCenter() {
            if (app.notifCenterOpen)
                app.closeNotifCenter();
            else
                app.openNotifCenter();
        }

        // 音量：监听 PipeWire 默认 sink（覆盖 wpctl 快捷键 / 滑块 / 其它程序）
        readonly property var audioNode: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
        readonly property real audioVolume: audioNode ? audioNode.volume : -1
        readonly property bool audioMuted: audioNode ? audioNode.muted : false

        onAudioVolumeChanged: {
            if (app.osdArmed && app.audioVolume >= 0)
                app.showOsd("volume", app.audioVolume * 100);
        }
        onAudioMutedChanged: {
            if (app.osdArmed && app.audioNode)
                app.showOsd("volume", app.audioMuted ? 0 : Math.max(0, app.audioVolume) * 100);
        }

        // 亮度：轮询 brightnessctl（sysfs 没有标准的变更信号）
        property real lastBrightness: -1

        Process {
            id: osdBrightness

            command: ["brightnessctl", "-m"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const parts = text.trim().split(",");
                    if (parts.length < 4)
                        return;
                    const p = parseFloat(String(parts[3]).replace("%", ""));
                    if (isNaN(p))
                        return;
                    if (app.osdArmed && app.lastBrightness >= 0 && Math.abs(p - app.lastBrightness) >= 1)
                        app.showOsd("brightness", p);
                    app.lastBrightness = p;
                }
            }
        }

        Timer {
            interval: 600
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                if (!osdBrightness.running)
                    osdBrightness.running = true;
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

        // ── 锁屏（Quickshell 会话锁，替代 hyprlock）──
        // 触发：`qs ipc call lock open`，见 ~/.config/niri/lock.sh
        Lock {
            id: locker
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

        IpcHandler {
            target: "lock"

            function open(): string {
                return locker.open();
            }
            function isLocked(): bool {
                return locker.isLocked();
            }
        }

        IpcHandler {
            target: "notif-center"

            function open(): void {
                app.openNotifCenter();
            }
            function close(): void {
                app.closeNotifCenter();
            }
            function toggle(): void {
                app.toggleNotifCenter();
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

        // ── IPC：Mod+D 走 `qs ipc call launcher toggle` 触发 ──
        IpcHandler {
            target: "launcher"

            function open(): void {
                app.openLauncher();
            }
            function close(): void {
                app.closeLauncher();
            }
            function toggle(): void {
                app.toggleLauncher();
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

        // ── 启动器 ──
        Variants {
            model: Quickshell.screens

            Launcher {
                required property var modelData

                screen: modelData
                shell: app
            }
        }

        // ── 音量 / 亮度 OSD ──
        Variants {
            model: Quickshell.screens

            Osd {
                required property var modelData

                screen: modelData
                shell: app
            }
        }

        // ── 通知中心 ──
        Variants {
            model: Quickshell.screens

            NotifCenter {
                required property var modelData

                screen: modelData
                shell: app
                manager: notifs
            }
        }

        // ── 通知（接管 org.freedesktop.Notifications，需先停 mako）──
        NotificationManager {
            id: notifs

            shell: app
        }

        // bar 的铃铛用（未读数）
        readonly property int notifUnread: notifs.unread

        Variants {
            model: Quickshell.screens

            NotifPopups {
                required property var modelData

                screen: modelData
                shell: app
                manager: notifs
            }
        }
    }
}
