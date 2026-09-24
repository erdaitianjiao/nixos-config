// 独立的锁屏截图配置：只做一件事——抓一帧目标输出的画面并存成 BMP。
//
// 之所以单独起一个短命 Quickshell 进程，而不是在主 shell 里直接建
// ScreencopyView：原生 screencopy 的 output 对象在输出热插拔/挂起时会破坏
// 主进程长命的 Wayland 连接（上层 Qt 会 SIGSEGV）。把它隔离到独立连接，
// 抓完即退，主 shell 的 Wayland 连接不受影响。
//
// 用法（由主 shell 的 PreLockCapture 用 Process 调起）：
//   CLAVIS_SNAPSHOT_OUTPUT=<输出名> CLAVIS_SNAPSHOT_PATH=<保存路径> \
//       quickshell --path .../capture/LockSnapshot.qml

import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property string outputName: Quickshell.env("CLAVIS_SNAPSHOT_OUTPUT")
    readonly property string outputPath: Quickshell.env("CLAVIS_SNAPSHOT_PATH")
    readonly property var output: Quickshell.screens.find(screen => screen.name === outputName) || null
    property bool grabbing: false

    // 兜底：1.2s 内没抓到也要退出，避免 Process 一直挂着。
    Timer {
        interval: 1200
        running: true
        onTriggered: Qt.quit()
    }

    PanelWindow {
        id: host

        screen: root.output
        visible: root.output !== null
        implicitWidth: 1
        implicitHeight: 1
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "clavis-lock-snapshot"
        mask: Region {}

        ScreencopyView {
            id: capture

            width: Math.max(1, sourceSize.width)
            height: Math.max(1, sourceSize.height)
            captureSource: root.output
            live: false
            paintCursor: false
            onHasContentChanged: {
                if (hasContent)
                    Qt.callLater(root.grab);
            }
        }
    }

    function grab() {
        if (grabbing || !capture.hasContent)
            return;
        grabbing = true;
        if (!capture.grabToImage(result => {
            result.saveToFile(root.outputPath);
            Qt.callLater(() => Qt.quit());
        }, capture.sourceSize))
            Qt.quit();
    }
}
