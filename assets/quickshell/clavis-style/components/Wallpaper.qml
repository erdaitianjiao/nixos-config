import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Quickshell 原生壁纸（替代 swaybg）。
//
// wallpaper.sh 只负责挑图 + 把路径写进 ~/.cache/niri-wallpaper；
// 这里 watchChanges 盯着那个文件，一变就交叉淡入到新图。
//
// ── 交叉淡入怎么做的 ────────────────────────────────────────
// 固定两层，谁也不换「正在显示那一层」的 source：
//   below：当前这张，始终不透明；
//   above：待切的新图，从 0 淡入到 1。
// 淡入结束后才动作：把 below 换成同一张 → 再把 above 直接置 0。
// 换 below 时 above 正不透明地盖在上面，看不见；把 above 置 0 时两层
// 又已经是同一张图，所以整个过程不会闪出「第三张画面」。
//
// 之前是两张图互相换 source —— 切图时可见的那层也在换 source，解码/
// 上传那几帧就会停在或闪出别的图；快速连按更明显。
//
// ── 卡顿怎么处理 ───────────────────────────────────────────
// sourceSize 把解码尺寸压到「显示分辨率 × 缩放」，4K/8K 原图不再全尺寸
// 解码 + 上传大纹理；cache 用默认的 true，切回看过的图是瞬时的。
//
// ── 另一个坑（踩过）───────────────────────────────────────
// 千万不要在这里写 `required property var screen`：PanelWindow（QsWindow）
// 自带 screen，另声明会把真实 screen 遮成 null，合成器只好自己挑输出，
// 结果两个背景层全堆到当前聚焦的那块屏（niri 里 DP-1 x2、eDP-1 没有）。
// Bar.qml 就是直接用继承来的 screen，不另声明。
PanelWindow {
    id: root

    required property var shell

    readonly property string statePath: String(Quickshell.env("HOME") || "") + "/.cache/niri-wallpaper"
    readonly property int fadeDuration: 380
    // 解码尺寸 = 显示分辨率 × dpr（避免全尺寸解码）。
    // 窗口尺寸还没定下来时给 -1，交给 Qt 用原始尺寸。
    readonly property real dpr: screen ? screen.devicePixelRatio : 1
    readonly property int decodeW: width > 1 ? Math.round(width * dpr) : -1
    readonly property int decodeH: height > 1 ? Math.round(height * dpr) : -1

    property string belowSource: ""
    property string aboveSource: ""
    property string pendingSource: ""

    // 从状态文件读到的裸路径
    function setSource(p) {
        p = String(p || "").trim();
        if (p === "")
            return;
        root.request("file://" + p);
    }

    function request(target) {
        if (target === root.belowSource || target === root.aboveSource)
            return;
        // 正在淡入 → 排队，等这一轮结束再上（避免抢可见层）
        if (fade.running) {
            root.pendingSource = target;
            return;
        }
        root.aboveSource = target;
        if (above.status === Image.Ready)
            fade.restart();
    }

    // 淡入结束：把结果沉淀到 below，回收 above
    function commit() {
        root.belowSource = root.aboveSource;
        above.opacity = 0; // 两层此刻是同一张图，置 0 不会看到变化
        root.aboveSource = "";
        if (root.pendingSource !== "") {
            const next = root.pendingSource;
            root.pendingSource = "";
            // 下一轮（等这一帧渲染完）再开始，避免和上面的回收抢帧
            Qt.callLater(function () {
                root.request(next);
            });
        }
    }

    color: "black"
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "qs-clavis-wallpaper"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    // 空输入区域 → 点击穿透（背景层不该吃事件）
    mask: Region {}

    FileView {
        id: stateFile

        path: root.statePath
        watchChanges: true
        onFileChanged: reload()
        // ⚠️ Quickshell 0.3 里 text 是 Q_INVOKABLE 方法而不是属性，
        // 直接写 `text` 会拿到函数对象本身，必须调用 text()。
        onTextChanged: root.setSource(stateFile.text())
    }

    // 当前图（始终不透明）
    Image {
        id: below

        anchors.fill: parent
        source: root.belowSource
        sourceSize.width: root.decodeW
        sourceSize.height: root.decodeH
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    // 新图（加载完再淡入）
    Image {
        id: above

        anchors.fill: parent
        source: root.aboveSource
        sourceSize.width: root.decodeW
        sourceSize.height: root.decodeH
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: 0

        onStatusChanged: {
            if (status === Image.Ready && root.aboveSource !== "")
                fade.restart();
        }
    }

    NumberAnimation {
        id: fade

        target: above
        property: "opacity"
        from: 0
        to: 1
        duration: root.fadeDuration
        easing.type: Easing.InOutCubic
        onFinished: root.commit()
    }
}
