import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Quickshell 原生壁纸（替代 swaybg）。
//
// wallpaper.sh 只负责挑图 + 把路径写进 ~/.cache/niri-wallpaper；
// 这里 watchChanges 盯着那个文件，一变就交叉淡入到新图。
//
// 好处：切壁纸有过渡、少一个常驻进程、也不用再踩 home-manager
// wrapper 改名（comm 变成 .swaybg-wrapped，pkill -x swaybg 打不着）
// 那个坑。
PanelWindow {
    id: root

    // ⚠️ 千万不要在这里写 `required property var screen`：
    // PanelWindow（QsWindow）自己就有 screen 属性，另声明一个会把它遮住，
    // 窗口真实 screen 一直是 null → 合成器自己挑输出（两个背景层全堆到
    // 当前聚焦的那块屏）。Bar.qml 就是直接用继承来的 bar.screen，不另声明。
    required property var shell

    readonly property string statePath: String(Quickshell.env("HOME") || "") + "/.cache/niri-wallpaper"

    property string curSource: ""
    property string prevSource: ""

    function setSource(p) {
        p = String(p || "").trim();
        if (p === "" || p === root.curSource)
            return;
        root.prevSource = root.curSource;
        root.curSource = "file://" + p;
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

    // 旧图（淡出期间垫在下面）
    Image {
        anchors.fill: parent
        source: root.prevSource
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
    }

    // 新图（加载完再淡入）
    Image {
        id: front

        anchors.fill: parent
        source: root.curSource
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        opacity: 0

        onStatusChanged: {
            if (status === Image.Ready && root.curSource !== "")
                fadeIn.restart();
        }
    }

    NumberAnimation {
        id: fadeIn

        target: front
        property: "opacity"
        from: 0
        to: 1
        duration: 450
        easing.type: Easing.InOutCubic
        onFinished: root.prevSource = ""
    }
}
