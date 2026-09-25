import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// 应用启动器（Spotlight 风格）：全屏暗背景 + 居中卡片，输入即搜，回车启动
// 数据来自 Quickshell 的 DesktopEntries（freedesktop .desktop 索引）
PanelWindow {
    id: root

    required property var shell

    readonly property bool onThisScreen: screen && screen.name === shell.launcherScreen

    property string query: ""
    property int chosen: 0

    readonly property var apps: DesktopEntries.applications ? DesktopEntries.applications.values : []
    readonly property var results: {
        const q = root.query.trim().toLowerCase();
        let list;
        if (q === "") {
            list = root.apps.slice().sort((a, b) => String(a.name || "").localeCompare(String(b.name || "")));
        } else {
            const scored = [];
            for (let i = 0; i < root.apps.length; ++i) {
                const s = root.score(root.apps[i], q);
                if (s > 0)
                    scored.push([s, root.apps[i]]);
            }
            scored.sort((a, b) => b[0] - a[0]);
            list = scored.map(x => x[1]);
        }
        return list.slice(0, 80);
    }

    // 简单的模糊打分：完全相等 > 前缀 > 子串 > 子序列 > 其它字段命中
    function score(e, q) {
        const name = String(e.name || "").toLowerCase();
        if (name === q)
            return 100000;
        if (name.startsWith(q))
            return 80000 - name.length;
        const idx = name.indexOf(q);
        if (idx >= 0)
            return 60000 - idx * 10 - name.length;

        let i = 0;
        let gaps = 0;
        let last = -1;
        for (let k = 0; k < name.length && i < q.length; ++k) {
            if (name[k] === q[i]) {
                if (last >= 0)
                    gaps += k - last - 1;
                last = k;
                ++i;
            }
        }
        if (i === q.length)
            return 30000 - gaps * 5 - name.length;

        const hay = (String(e.genericName || "") + " " + String(e.comment || "") + " " + (e.keywords || []).join(" ") + " " + String(e.execString || "")).toLowerCase();
        if (hay.indexOf(q) >= 0)
            return 10000 - name.length;
        return -1;
    }

    function move(d) {
        const n = root.results.length;
        if (n === 0)
            return;
        root.chosen = Math.max(0, Math.min(n - 1, root.chosen + d));
    }

    function launch(index) {
        const entry = root.results[index];
        if (!entry)
            return;
        root.shell.closeLauncher();
        entry.execute();
    }

    function iconSource(icon) {
        const s = String(icon || "");
        if (s === "")
            return "";
        if (s.indexOf("/") === 0)
            return "file://" + s;
        return Quickshell.iconPath(s, true);
    }

    onVisibleChanged: {
        if (visible) {
            root.query = "";
            root.chosen = 0;
            input.forceActiveFocus();
        }
    }
    onQueryChanged: root.chosen = 0
    onChosenChanged: list.positionViewAtIndex(root.chosen, ListView.Contain)

    // 关闭时先播完退场动画再真正隐藏窗口
    readonly property bool shown: shell.launcherOpen && onThisScreen
    property bool closing: false

    visible: shown || closing

    onShownChanged: {
        if (shown)
            root.closing = false;
        else if (root.visible)
            root.closing = true;
    }

    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-clavis-launcher"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    // 点背景关闭
    Rectangle {
        id: backdrop

        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.35)
        opacity: root.shown ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: root.shown ? root.shell.durEnter : root.shell.durExit
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.shell.closeLauncher()
        }
    }

    Rectangle {
        id: card

        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.98
        transformOrigin: Item.Top
        onOpacityChanged: if (!root.shown && opacity === 0) root.closing = false

        Behavior on opacity {
            NumberAnimation {
                duration: root.shown ? root.shell.durEnter : root.shell.durExit
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.shell.easeEnter
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: root.shown ? root.shell.durEnter : root.shell.durExit
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.shell.easeEnter
            }
        }

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.round(root.height * 0.13)
        width: Math.min(620, root.width - 80)
        implicitHeight: searchRow.height + list.height
        radius: 20
        color: Qt.rgba(0.96, 0.97, 0.93, 0.98)
        border.width: 1
        border.color: root.shell.cBorder
        clip: true

        // 吞掉卡片内的点击，避免穿透关闭
        MouseArea {
            anchors.fill: parent
        }

        // ── 搜索行 ──
        Item {
            id: searchRow

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 56

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: root.shell.cBorder
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 10

                Text {
                    text: "󰍉" // md-magnify
                    color: root.shell.cComment
                    font.family: root.shell.fontFam
                    font.pixelSize: 18
                }

                TextInput {
                    id: input

                    Layout.fillWidth: true
                    color: root.shell.cFg
                    font.family: root.shell.fontFam
                    font.pixelSize: 16
                    selectByMouse: true
                    clip: true
                    onTextChanged: root.query = text
                    Keys.onDownPressed: root.move(1)
                    Keys.onUpPressed: root.move(-1)
                    Keys.onReturnPressed: root.launch(root.chosen)
                    Keys.onEnterPressed: root.launch(root.chosen)
                    Keys.onEscapePressed: root.shell.closeLauncher()

                    Text {
                        visible: input.text === ""
                        text: "搜索应用…"
                        color: root.shell.cComment
                        font: input.font
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        // ── 结果列表 ──
        ListView {
            id: list

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: searchRow.bottom
            height: root.results.length === 0 ? 56 : Math.min(root.results.length * 46 + 8, 8 * 46 + 8)
            clip: true
            model: root.results
            boundsBehavior: Flickable.StopAtBounds

            Text {
                visible: root.results.length === 0
                anchors.centerIn: parent
                text: "无匹配"
                color: root.shell.cComment
                font.family: root.shell.fontFam
                font.pixelSize: 13
            }

            delegate: Rectangle {
                id: row

                required property var modelData
                required property int index

                width: list.width
                height: 46
                color: index === root.chosen ? root.shell.cSurface : "transparent"

                Rectangle {
                    visible: index === root.chosen
                    width: 3
                    height: parent.height
                    color: root.shell.cGreen
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12

                    Image {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        sourceSize: Qt.size(24, 24)
                        smooth: true
                        source: root.iconSource(row.modelData ? row.modelData.icon : "")
                    }

                    Text {
                        Layout.fillWidth: true
                        text: row.modelData ? String(row.modelData.name || "") : ""
                        color: root.shell.cFg
                        font.family: root.shell.fontFam
                        font.pixelSize: 14
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: text !== ""
                        text: row.modelData ? String(row.modelData.genericName || "") : ""
                        color: root.shell.cComment
                        font.family: root.shell.fontFam
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.chosen = row.index
                    onClicked: root.launch(row.index)
                }
            }
        }
    }
}
