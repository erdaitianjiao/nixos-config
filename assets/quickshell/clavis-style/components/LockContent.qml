// 锁屏中央内容：大时钟 + 头像 + 密码框。
// 配色对齐 clavis-style 的 Matcha 浅绿（半透明压在压暗的模糊桌面之上）。
// 组件只依赖 Quickshell 内置能力，不依赖完整 Clavis 仓库的服务。

import QtQuick
import QtQuick.Controls
import Quickshell

FocusScope {
    id: root

    required property var context

    property date now: new Date()

    readonly property bool authenticating: root.context ? root.context.authRevealed : false
    readonly property bool busy: root.context ? root.context.unlockInProgress : false
    readonly property bool failed: root.context ? root.context.showFailure : false
    readonly property string userName: Quickshell.env("USER") || "user"

    // ── 配色 ──
    readonly property color cAccent: "#4f9d57"
    readonly property color cText: "#ffffff"
    readonly property color cSubText: "#d8e6dc"
    readonly property color cFieldBg: "#D6DCE0"
    readonly property color cFieldText: "#20252B"
    readonly property color cPlaceholder: "#4D5861"
    readonly property color cFieldBorder: "#647078"
    readonly property color cError: "#d86666"
    readonly property color cShadow: "#66000000"
    readonly property string fontUi: "Sarasa Gothic SC"
    readonly property string fontNum: "CaskaydiaCove Nerd Font"

    readonly property real uiScale: Math.min(1, (width - 48) / 420, height / 760)

    property real clockOpacity: authenticating ? 0 : 1
    property real clockOffset: authenticating ? -96 * uiScale : 0
    property real clockScale: authenticating ? 0.72 : 1
    property real authOpacity: authenticating ? 1 : 0
    property real authOffset: authenticating ? 0 : 72 * uiScale
    property real authScale: authenticating ? 1 : 0.94

    function forceAuthFocus() {
        input.forceActiveFocus();
    }

    Behavior on clockOpacity {
        NumberAnimation {
            duration: 240
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.3, 0, 0.8, 0.15, 1, 1]
        }
    }
    Behavior on clockOffset {
        NumberAnimation {
            duration: 380
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1]
        }
    }
    Behavior on clockScale {
        NumberAnimation {
            duration: 380
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1]
        }
    }
    Behavior on authOpacity {
        NumberAnimation {
            duration: 360
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1]
        }
    }
    Behavior on authOffset {
        NumberAnimation {
            duration: 460
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.16, 1, 0.3, 1, 1, 1]
        }
    }
    Behavior on authScale {
        NumberAnimation {
            duration: 460
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.16, 1, 0.3, 1, 1, 1]
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    // 点击任意处 → 展开密码框。
    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (root.context) {
                root.context.authRevealed = true;
                root.forceAuthFocus();
            }
        }
    }

    // ── 时钟 ──
    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -24 * root.uiScale + root.clockOffset
        width: parent.width - 48
        spacing: 12 * root.uiScale
        opacity: root.clockOpacity
        scale: root.clockScale

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(root.now, "HH:mm")
            color: root.cText
            font.family: root.fontNum
            font.pixelSize: Math.min(root.width * 0.19, root.height * 0.24, 220)
            font.weight: Font.DemiBold
            renderType: Text.NativeRendering
            style: Text.Outline
            styleColor: root.cShadow
        }

        Text {
            width: parent.width
            text: root.now.toLocaleDateString(Qt.locale(Qt.uiLanguage), qsTr("yyyy年M月d日 dddd"))
            color: root.cSubText
            font.family: root.fontUi
            font.pixelSize: Math.min(26, root.width * 0.032)
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            style: Text.Outline
            styleColor: root.cShadow
        }
    }

    // ── 认证区 ──
    Column {
        id: authColumn

        anchors.centerIn: parent
        anchors.verticalCenterOffset: -24 * root.uiScale + root.authOffset
        width: 320 * root.uiScale
        spacing: 20 * root.uiScale
        opacity: root.authOpacity
        scale: root.authScale

        Rectangle {
            width: 108 * root.uiScale
            height: width
            radius: width / 2
            color: "#53616B"
            anchors.horizontalCenter: parent.horizontalCenter
            border.width: 2 * root.uiScale
            border.color: "#80FFFFFF"

            Text {
                anchors.centerIn: parent
                text: root.userName.slice(0, 1).toUpperCase()
                color: "#F5F7FA"
                font.family: root.fontUi
                font.pixelSize: parent.width * 0.42
                font.weight: Font.Medium
            }
        }

        Text {
            width: parent.width
            height: 44 * root.uiScale
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: root.userName
            color: root.cText
            font.family: root.fontUi
            font.pixelSize: 32 * root.uiScale
            font.weight: Font.Medium
            elide: Text.ElideRight
            style: Text.Outline
            styleColor: root.cShadow
        }

        Rectangle {
            id: field

            anchors.horizontalCenter: parent.horizontalCenter
            width: 300 * root.uiScale
            height: 56 * root.uiScale
            radius: height / 2
            color: root.cFieldBg
            border.width: 2 * root.uiScale
            border.color: root.cFieldBorder

            TextInput {
                id: input

                anchors.fill: parent
                anchors.leftMargin: 26 * root.uiScale
                anchors.rightMargin: 26 * root.uiScale
                color: "transparent"
                selectionColor: "transparent"
                selectedTextColor: "transparent"
                echoMode: TextInput.NoEcho
                inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                readOnly: root.busy
                focus: true
                activeFocusOnPress: true
                cursorVisible: false
                maximumLength: 4096
                Accessible.name: qsTr("密码")
                Accessible.description: root.failed ? qsTr("密码错误") : ""

                onCursorVisibleChanged: {
                    if (cursorVisible)
                        cursorVisible = false;
                }
                onTextChanged: {
                    if (root.context && root.context.currentText !== text)
                        root.context.currentText = text;
                    if (text.length > 0 && root.context) {
                        root.context.authRevealed = true;
                        root.context.showFailure = false;
                    }
                    while (dots.count < text.length)
                        dots.append({});
                    while (dots.count > text.length)
                        dots.remove(dots.count - 1);
                }
                onAccepted: {
                    if (root.context) {
                        root.context.authRevealed = true;
                        root.context.tryUnlock();
                    }
                }
                Keys.onEscapePressed: {
                    if (!root.busy) {
                        text = "";
                        if (root.context) {
                            root.context.showFailure = false;
                            root.context.authRevealed = false;
                        }
                    }
                }
                Component.onCompleted: text = root.context ? root.context.currentText : ""
            }

            Text {
                anchors.centerIn: parent
                visible: input.text.length === 0 && !root.busy
                text: qsTr("输入密码解锁…")
                font.family: root.fontUi
                font.pixelSize: 18 * root.uiScale
                color: root.cPlaceholder
            }

            ListModel {
                id: dots
            }

            ListView {
                id: dotsView

                readonly property real dotSize: 14 * root.uiScale
                readonly property real naturalWidth: count > 0 ? count * (dotSize + spacing) - spacing : 0

                anchors.centerIn: parent
                width: Math.min(field.width - 52 * root.uiScale, naturalWidth)
                height: 24 * root.uiScale
                orientation: ListView.Horizontal
                interactive: false
                clip: true
                spacing: 10 * root.uiScale
                model: dots

                delegate: Item {
                    width: dotsView.dotSize
                    height: dotsView.height

                    Rectangle {
                        id: dotCircle

                        anchors.centerIn: parent
                        width: dotsView.dotSize
                        height: width
                        radius: width / 2
                        color: root.cFieldText
                        scale: 0
                        opacity: 0
                        Component.onCompleted: popIn.start()

                        NumberAnimation {
                            id: popIn

                            // 必须显式指向 dotCircle；写 target: parent 会被解析成 delegate 的
                            // Item，动画就跑到了错的物体上，圆圈永远停在 scale:0/opacity:0。
                            target: dotCircle
                            properties: "scale,opacity"
                            to: 1
                            duration: 200
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.16, 1, 0.3, 1, 1, 1]
                        }
                    }
                }
            }

            // 密码错误时红框闪一下
            Rectangle {
                id: errorBorder

                anchors.fill: parent
                radius: field.radius
                color: "transparent"
                border.width: 3 * root.uiScale
                border.color: root.cError
                opacity: 0

                SequentialAnimation {
                    id: failureFlash

                    loops: 2

                    NumberAnimation {
                        target: errorBorder
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 120
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.2, 0, 0, 1, 1, 1]
                    }
                    PauseAnimation {
                        duration: 80
                    }
                    NumberAnimation {
                        target: errorBorder
                        property: "opacity"
                        to: 0
                        duration: 180
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.3, 0, 1, 1, 1, 1]
                    }
                    PauseAnimation {
                        duration: 80
                    }
                }
            }
        }

        BusyIndicator {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 28 * root.uiScale
            height: width
            running: root.busy
            visible: running
            palette.accent: root.cAccent
        }
    }

    Connections {
        target: root.context

        function onCurrentTextChanged() {
            if (root.context && input.text !== root.context.currentText)
                input.text = root.context.currentText;
        }
        function onUnlockFailed() {
            failureFlash.restart();
            root.forceAuthFocus();
        }
    }
}
