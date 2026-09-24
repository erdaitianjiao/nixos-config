// 上锁前的桌面抓拍。
//
// 每个输出起一个短命 quickshell 子进程（capture/LockSnapshot.qml）抓一帧，
// 存成 `<XDG_RUNTIME_DIR>/clavis-lock-<输出>.bmp`，然后主 shell 用隐藏的
// Image 同步预解码这张图——等它 Ready 后再真正 WlSessionLock.locked = true，
// 这样锁屏第一帧底下就已经有桌面，不会闪黑。
//
// 抓拍失败/超时（1800ms）也会继续上锁，锁屏退化成「纯模糊」背景。

import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    readonly property bool busy: pendingCount > 0
    property int requestId: 0
    property int pendingCount: 0
    property var pendingScreens: ({})
    property var frames: ({})
    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") || Quickshell.env("TMPDIR") || "/tmp"

    signal captureRequested(int requestId)
    signal completed(int requestId)
    signal releaseFrames

    function screenKey(screen) {
        return screen && screen.name ? String(screen.name) : "";
    }

    function pathFor(screenName) {
        return runtimeDir + "/clavis-lock-" + screenName.replace(/[^A-Za-z0-9_.-]/g, "_") + ".bmp";
    }

    function urlFor(screenName) {
        return "file://" + pathFor(screenName);
    }

    function capturePath() {
        return Quickshell.shellDir + "/capture/LockSnapshot.qml";
    }

    function isPending(screenName) {
        return pendingScreens[screenName] === true;
    }

    function capture() {
        if (busy)
            return 0;

        releaseFrames();
        requestId += 1;
        frames = {};
        pendingScreens = {};
        pendingCount = 0;
        for (const screen of Quickshell.screens) {
            const key = screenKey(screen);
            if (key === "" || pendingScreens[key])
                continue;
            pendingScreens[key] = true;
            pendingCount += 1;
        }
        const currentRequest = requestId;
        if (pendingCount === 0) {
            Qt.callLater(() => root.completed(currentRequest));
            return currentRequest;
        }
        deadline.restart();
        captureRequested(currentRequest);
        return currentRequest;
    }

    function finishScreen(screenName, captureRequestId, result) {
        if (captureRequestId !== requestId || !isPending(screenName))
            return;

        delete pendingScreens[screenName];
        pendingCount -= 1;
        if (result && result.url) {
            const nextFrames = Object.assign({}, frames);
            nextFrames[screenName] = result;
            frames = nextFrames;
        }
        if (pendingCount === 0)
            finishRequest(captureRequestId);
    }

    function finishRequest(captureRequestId) {
        if (captureRequestId !== requestId)
            return;

        deadline.stop();
        pendingCount = 0;
        pendingScreens = {};
        // 绝不在 captureRequested 里同步 emit：调用方要先拿到 requestId。
        Qt.callLater(() => root.completed(captureRequestId));
    }

    function cancel() {
        if (!busy)
            return;
        pendingCount = 0;
        pendingScreens = {};
        deadline.stop();
        releaseFrames();
    }

    function snapshot(screen) {
        const key = screenKey(screen);
        return key !== "" ? (frames[key] || null) : null;
    }

    function clear() {
        if (!busy) {
            frames = {};
            releaseFrames();
        }
    }

    Timer {
        id: deadline

        interval: 1800
        repeat: false
        onTriggered: {
            console.warn("锁屏抓拍超时，用已有画面继续上锁");
            root.finishRequest(root.requestId);
        }
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: worker

            required property var modelData
            readonly property string screenName: root.screenKey(modelData)
            property int activeRequestId: 0
            property bool published: false
            property string snapshotUrl: ""

            function startRequest(captureRequestId) {
                if (captureRequestId !== root.requestId || !root.isPending(screenName))
                    return;
                activeRequestId = captureRequestId;
                published = false;
                snapshotUrl = "";
                preload.source = "";
                captureProcess.running = true;
            }

            function release() {
                snapshotUrl = "";
                preload.source = "";
                if (screenName !== "") {
                    cleanup.command = ["rm", "-f", root.pathFor(screenName)];
                    cleanup.running = true;
                }
            }

            function publish() {
                if (published || preload.status === Image.Loading)
                    return;
                if (activeRequestId !== root.requestId || !root.isPending(screenName)) {
                    release();
                    return;
                }
                published = true;
                if (preload.status === Image.Ready) {
                    snapshotUrl = preload.source;
                    root.finishScreen(screenName, activeRequestId, {
                                          url: snapshotUrl
                                      });
                } else {
                    console.warn("输出 " + screenName + " 的锁屏抓拍失败，退化为纯模糊背景");
                    release();
                    root.finishScreen(screenName, activeRequestId, null);
                }
            }

            Connections {
                target: root

                function onReleaseFrames() {
                    worker.release();
                }

                function onCaptureRequested(captureRequestId) {
                    if (!root.isPending(worker.screenName) || captureProcess.running)
                        return;
                    worker.startRequest(captureRequestId);
                }
            }

            // 先同步解码好 BMP，再让主进程上锁；锁屏里的 Image 用同一 URL + cache
            // 复用这张已解码的 pixmap。
            Image {
                id: preload

                source: ""
                asynchronous: false
                cache: true
                visible: false
                onStatusChanged: Qt.callLater(worker.publish)
            }

            Process {
                id: captureProcess

                command: ["quickshell", "--path", root.capturePath()]
                environment: ({
                    "CLAVIS_SNAPSHOT_OUTPUT": worker.screenName,
                    "CLAVIS_SNAPSHOT_PATH": root.pathFor(worker.screenName)
                })
                onExited: {
                    if (!worker.published) {
                        preload.source = root.urlFor(worker.screenName);
                        Qt.callLater(worker.publish);
                    }
                }
                stderr: StdioCollector {}
            }

            Process {
                id: cleanup
            }

            Component.onDestruction: root.finishScreen(screenName, activeRequestId, null)
        }
    }
}
