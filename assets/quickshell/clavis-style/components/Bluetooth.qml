import QtQuick
import Quickshell
import Quickshell.Bluetooth

// 蓝牙胶囊：关/开/已连接（左键开关，右键菜单）
Rectangle {
    id: root

    required property var shell

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool present: adapter !== null
    readonly property bool on: present && adapter.enabled
    readonly property int connectedCount: {
        if (!present || !adapter.devices)
            return 0;
        const ds = adapter.devices.values;
        let n = 0;
        for (let i = 0; i < ds.length; ++i) {
            if (ds[i].connected)
                n++;
        }
        return n;
    }

    function label() {
        if (!on)
            return "󰂲"; // off / disabled
        if (connectedCount > 0)
            return "󰂱  " + connectedCount; // connected
        return "󰂯"; // on
    }

    visible: present
    implicitWidth: visible ? txt.implicitWidth + 24 : 0
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
        color: root.on ? root.shell.cBlue : root.shell.cComment
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
                Quickshell.execDetached([Quickshell.env("HOME") + "/.config/niri/bluetooth-toggle.sh"]);
            else
                Quickshell.execDetached([Quickshell.env("HOME") + "/.config/niri/bluetooth-menu.sh"]);
        }
    }
}
