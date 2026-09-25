import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// 通知（消息弹窗）管理器：接管 org.freedesktop.Notifications
// ⚠️ 系统里同时只能有一个通知守护进程。niri 现在不再起 mako，由这个 shell
// 独占；如果手动跑了别的通知守护进程，要先停掉它。
Item {
    id: root

    required property var shell

    // 正在弹的通知（最新的在前）
    property var items: []
    // 历史（快照成普通 JS 对象，Notification 关闭后就销毁了）
    property var history: []
    property int unread: 0

    readonly property int maxVisible: 4
    readonly property int historyLimit: 50

    function snapshot(n) {
        return {
            "id": n.id,
            "appName": String(n.appName || ""),
            "appIcon": String(n.appIcon || ""),
            "image": String(n.image || ""),
            "summary": String(n.summary || ""),
            "body": String(n.body || ""),
            "urgency": n.urgency,
            "time": Date.now()
        };
    }

    function removeHistory(id) {
        const out = [];
        for (let i = 0; i < root.history.length; ++i) {
            if (root.history[i].id !== id)
                out.push(root.history[i]);
        }
        root.history = out;
    }

    function clearHistory() {
        root.history = [];
        root.unread = 0;
    }

    function markRead() {
        root.unread = 0;
    }

    function add(n) {
        n.tracked = true;

        const h = root.history.slice();
        h.unshift(root.snapshot(n));
        root.history = h.slice(0, root.historyLimit);
        root.unread += 1;

        const list = root.items.slice();
        list.unshift(n);
        // 超出上限就把最旧的收掉（dismiss 后会通过 closed → remove 从列表里消失）
        while (list.length > root.maxVisible) {
            list.pop().dismiss();
        }
        root.items = list;
    }

    function remove(id) {
        const list = [];
        for (let i = 0; i < root.items.length; ++i) {
            if (root.items[i].id !== id)
                list.push(root.items[i]);
        }
        if (list.length !== root.items.length)
            root.items = list;
    }

    function dismissAll() {
        const list = root.items;
        root.items = [];
        for (let i = 0; i < list.length; ++i)
            list[i].dismiss();
    }

    NotificationServer {
        id: server

        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: false
        imageSupported: true
        actionsSupported: true
        actionIconsSupported: false
        inlineReplySupported: false
        keepOnReload: false
        persistenceSupported: false
        onNotification: (notification) => root.add(notification)
    }
}
