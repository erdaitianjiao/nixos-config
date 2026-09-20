import QtQuick
import Quickshell
import Quickshell.Networking

// 网络胶囊：WiFi 信号 + SSID / 有线 / 断开
Rectangle {
    id: root

    required property var shell

    readonly property var devices: Networking.devices ? Networking.devices.values : []
    readonly property var activeDevice: {
        for (let i = 0; i < devices.length; ++i) {
            if (devices[i].connected)
                return devices[i];
        }
        return null;
    }
    readonly property bool isWifi: activeDevice ? activeDevice.type === DeviceType.Wifi : false
    readonly property var activeNetwork: {
        if (!isWifi || !activeDevice)
            return null;
        const nets = activeDevice.networks ? activeDevice.networks.values : [];
        for (let i = 0; i < nets.length; ++i) {
            if (nets[i].connected)
                return nets[i];
        }
        return null;
    }
    readonly property real signal: activeNetwork ? Math.max(0, Math.min(1, activeNetwork.signalStrength)) : 0
    readonly property string ssid: activeNetwork ? (activeNetwork.name || "") : ""

    function signalIcon() {
        const idx = Math.max(0, Math.min(4, Math.floor(signal * 5)));
        // 和 waybar 的 format-icons 一致
        return ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"][idx];
    }
    function label() {
        if (!activeDevice)
            return "󰤮"; // disconnected
        if (!isWifi)
            return "󰈀"; // ethernet
        return signalIcon() + (ssid ? "  " + ssid : "");
    }

    implicitWidth: txt.implicitWidth + 24
    implicitHeight: root.shell.pillH
    radius: root.shell.pillRadius
    color: hover.containsMouse ? root.shell.cSurfaceHover : root.shell.cSurface

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    Text {
        id: txt

        anchors.centerIn: parent
        text: root.label()
        color: root.activeDevice ? root.shell.cCyan : root.shell.cComment
        font.family: root.shell.fontFam
        font.pixelSize: 13
    }

    MouseArea {
        id: hover

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (m) => {
            if (m.button === Qt.LeftButton)
                Quickshell.execDetached([Quickshell.env("HOME") + "/.config/waybar/wifi-menu.sh"]);
            else
                Quickshell.execDetached(["nm-connection-editor"]);
        }
    }
}
