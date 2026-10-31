import QtQuick
import QtQuick.Window
import qs.Common
import qs.Services

// An explicit declaration attached to the actual section. The build consumes
// only this JSON literal; its ID is also the runtime registration key.
Item {
    id: root
    required property string declaration
    required property Item target
    readonly property var entry: JSON.parse(declaration)
    readonly property string title: {
        const language = Qt.uiLanguage;
        return SpotlightCatalog.title(entry.id);
    }
    property bool registerAnchor: true
    property bool wholePage: false
    property int requestSerial: -1
    property real highlightOpacity: 0
    readonly property Item highlightHost: {
        // A section can itself be a layout. Its highlight must never become
        // one of the children that contribute to that layout's geometry.
        for (let item = target; item; item = item.parent) {
            if (item instanceof Flickable)
                return item.contentItem;
        }
        return target && target.Window.window ? target.Window.window.contentItem : null;
    }
    visible: false
    width: 0
    height: 0

    function polishTarget() {
        const ancestors = [];
        for (let item = target; item; item = item.parent)
            ancestors.push(item);
        for (let index = ancestors.length - 1; index >= 0; --index)
            ancestors[index].ensurePolished();
    }

    function updateHighlightGeometry() {
        if (!target || !highlightHost)
            return;
        const point = target.mapToItem(highlightHost, 0, 0);
        highlight.x = point.x;
        highlight.y = point.y;
    }

    function reveal(serial) {
        if (!target || !target.visible || target.width <= 0 || target.height <= 0)
            return false;
        requestSerial = serial;
        if (wholePage && target instanceof Flickable)
            target.contentY = target.originY;
        // Each enclosing scroll viewport is handled in its own coordinates.
        for (let item = target.parent; item; item = item.parent) {
            if (item instanceof Flickable) {
                item.cancelFlick();
                const point = target.mapToItem(item.contentItem, 0, 0);
                item.contentY = Math.max(item.originY, Math.min(point.y - Metrics.spacingM, item.originY + Math.max(
                                                                    0, item.contentHeight - item.height)));
            }
        }
        updateHighlightGeometry();
        highlightOpacity = 1;
        hold.restart();
        return true;
    }
    Component.onCompleted: {
        if (registerAnchor)
            ControlCenterService.registerSearchAnchor(root);
    }
    Component.onDestruction: {
        if (registerAnchor)
            ControlCenterService.unregisterSearchAnchor(root);
    }
    Connections {
        target: root.target
        function onWidthChanged() {
            ControlCenterService.retrySearch();
        }
        function onHeightChanged() {
            ControlCenterService.retrySearch();
        }
        function onYChanged() {
            ControlCenterService.retrySearch();
        }
        function onVisibleChanged() {
            ControlCenterService.retrySearch();
        }
    }
    Connections {
        target: ControlCenterService
        function onSearchSerialChanged() {
            if (root.requestSerial !== ControlCenterService.searchSerial) {
                hold.stop();
                root.highlightOpacity = 0;
            }
        }
    }
    Rectangle {
        id: highlight
        parent: root.highlightHost
        width: root.target ? root.target.width : 0
        height: root.target ? root.target.height : 0
        radius: Metrics.cornerM
        color: Appearance.applyAlpha(Appearance.colors.colPrimary, 0.10)
        border.width: 1
        border.color: Appearance.applyAlpha(Appearance.colors.colPrimary, 0.38)
        opacity: root.highlightOpacity
        visible: opacity > 0 && root.target && root.target.visible && parent
        z: 100
        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.animation.expressiveDefaultEffects.duration
            }
        }
    }
    FrameAnimation {
        running: highlight.visible
        // Keep the overlay aligned while scrolling, resizing or animating an
        // ancestor without adding it to the section's own layout.
        onTriggered: root.updateHighlightGeometry()
    }
    Timer {
        id: hold
        interval: 1100
        onTriggered: root.highlightOpacity = 0
    }
}
