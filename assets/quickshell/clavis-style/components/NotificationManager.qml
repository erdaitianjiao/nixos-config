import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// 通知（消息弹窗）管理器：接管 org.freedesktop.Notifications
// ⚠️ 系统里同时只能有一个通知守护进程 —— 起这个 shell 时要先把 mako 停掉
// （shell-switch.sh 里做了），否则抢不到名字，弹窗不会出现。
Item {
    id: root

    required property var shell

    // 正在弹的通知（最新的在前）
    property var items: []

    readonly property int maxVisible: 4

    function add(n) {
        n.tracked = true;
        n.closed.connect(function (reason) {
            root.remove(n.id);
        });
        const list = root.items.slice();
        list.unshift(n);
        // 超出上限就把最旧的收掉（它仍然被 track，只是不弹了）
        while (list.length > root.maxVisible) {
            const old = list.pop();
            old.dismiss();
        }
        root.items = list;
    }

    function remove(id) {
        const list = [];
        for (let i = 0; i < root.items.length; ++i) {
            if (root.items[i].id === id)
                root.items[i].tracked = false;
            else
                list.push(root.items[i]);
        }
        if (list.length !== root.items.length)
            root.items = list;
    }

    function dismissAll() {
        const list = root.items;
        root.items = [];
        for (let i = 0; i < list.length; ++i) {
            list[i].tracked = false;
            list[i].dismiss();
        }
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
