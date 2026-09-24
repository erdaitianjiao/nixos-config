// 每个输出的锁屏画面（Default 风格）：
//   底层  = 上锁前抓拍的桌面快照（清晰）
//   上层  = 同一张图模糊 + 压暗 + 中央 UI，用圆形遮罩从左上角扩散揭开
// 效果：先看到冻结的桌面，再从左上角「揭开」模糊的锁屏界面；解锁时反向淡出。

import QtQuick
import QtQuick.Effects
import Quickshell.Wayland

WlSessionLockSurface {
    id: root

    required property var lock
    property var context: null
    property var snapshotProvider: null

    readonly property var snapshotResult: (snapshotProvider && screen) ? snapshotProvider.snapshot(screen) : null

    color: "#15191D"

    property bool started: false
    property bool exiting: false
    property real reveal: 0
    property real sceneOpacity: 1

    function startReveal() {
        if (started || !screen)
            return;
        if (snapshotResult && snapshotImage.status !== Image.Ready && snapshotImage.status !== Image.Error)
            return;
        started = true;
        reveal = 0;
        entrance.start();
        if (content)
            content.forceAuthFocus();
    }

    onScreenChanged: Qt.callLater(startReveal)
    Component.onCompleted: Qt.callLater(startReveal)

    Connections {
        target: root.lock

        function onUnlock() {
            if (root.exiting)
                return;
            root.exiting = true;
            entrance.stop();
            exitAnimation.start();
        }
    }

    // 底层：冻结的桌面
    Image {
        id: snapshotImage

        anchors.fill: parent
        source: root.snapshotResult ? root.snapshotResult.url : ""
        fillMode: Image.Stretch
        asynchronous: false
        cache: true
        onStatusChanged: Qt.callLater(root.startReveal)
    }

    // 白色圆盘，作为 scene 的遮罩
    Item {
        id: discMask

        anchors.fill: parent
        visible: false
        layer.enabled: true

        Rectangle {
            readonly property real discRadius: Math.hypot(root.width, root.height) * root.reveal

            x: -discRadius
            y: -discRadius
            width: discRadius * 2
            height: width
            radius: discRadius
            color: "white"
        }
    }

    // 上层：模糊桌面 + 压暗 + UI，被圆盘遮罩裁切
    Item {
        id: scene

        anchors.fill: parent
        opacity: root.started ? root.sceneOpacity : 0
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: discMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 0.5
        }

        Rectangle {
            anchors.fill: parent
            color: "#15191D"
        }

        Image {
            anchors.fill: parent
            source: root.snapshotResult ? root.snapshotResult.url : ""
            fillMode: Image.Stretch
            asynchronous: false
            cache: true
            layer.enabled: true
            layer.effect: MultiEffect {
                autoPaddingEnabled: false
                blurEnabled: true
                blurMax: 64
                blur: 1
                blurMultiplier: 1
                saturation: -0.2
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#66000000"
        }

        LockContent {
            id: content

            anchors.fill: parent
            context: root.context
            enabled: !root.exiting
        }
    }

    NumberAnimation {
        id: entrance

        target: root
        property: "reveal"
        from: 0
        to: 1
        duration: 850
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.2, 0, 0, 1, 1, 1]
    }

    NumberAnimation {
        id: exitAnimation

        target: root
        property: "sceneOpacity"
        to: 0
        duration: 300
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.3, 0, 1, 1, 1, 1]
        onFinished: {
            if (root.context)
                root.context.finishUnlock();
            else
                root.lock.locked = false;
        }
    }
}
