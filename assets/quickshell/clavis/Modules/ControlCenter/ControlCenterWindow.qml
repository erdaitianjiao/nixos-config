import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Clavis.Niri
import qs.Common
import qs.Services
import qs.Components
import qs.Widgets.common

FloatingWindow {
    id: root

    property bool _wasShown: false
    property real contentPadding: 8
    property int currentPage: 0
    property bool navExpanded: width > 900
    property string pendingPageSection: ""
    readonly property var pages: SpotlightCatalog.routes.filter(entry => entry.path.length === 1).map(entry
                                                                                                      => Object.assign(
                                                                                                             {}, entry,
                                                                                                             {
                                                                                                                 title: SpotlightCatalog.title(
                                                                                                                            entry.id)
                                                                                                             }))
    property int searchRequestSerial: -1
    property var searchLeaf: null
    readonly property var searchPageAnchor: pageSearchAnchor
    function toggleMaximize() {
        root.maximized = !root.maximized;
    }

    function minimizeWindow() {
        const window = Niri.searchWindows(root.title).find(entry => entry.title === root.title);
        if (window && Niri.supportsMinimize && Niri.minimizeWindow(window.id))
            return;
        root.minimized = true;
    }

    function prepareSearchTarget(entry, serial) {
        searchRequestSerial = serial;
        root.openPage(entry.path[0]);
        root.advanceSearchTarget(entry, serial);
    }

    function advanceSearchTarget(entry, serial) {
        if (searchRequestSerial !== serial)
            return "cancelled";
        if (pages[currentPage].id !== entry.path[0])
            return "cancelled";
        if (!pageLoader.ready || !pageLoader.item)
            return "loading";
        const page = pageLoader.item;
        const state = typeof page.openSearchPath === "function" ? page.openSearchPath(entry.path.slice(1),
                                                                                      serial) : "ready";
        searchLeaf = page.searchLeaf || page;
        return state;
    }

    SettingsSearchAnchor {
        id: pageSearchAnchor
        registerAnchor: false
        declaration: JSON.stringify({
                                        id: "page"
                                    })
        target: root.searchLeaf
        wholePage: true
    }

    signal popoutClosed

    function showWindow() {
        root._wasShown = true;
        root.visible = true;
        root.minimized = false;
    }

    function hideWindow() {
        if (root.visible) {
            settingsSearch.close();
            root.closeChildWindows();
            root.visible = false;
        }
    }

    function toggleWindow() {
        if (root.visible)
            root.hideWindow();
        else
            root.showWindow();
    }

    function pageSource(index) {
        if (index < 0 || index >= pages.length)
            return Qt.resolvedUrl("AccountPage.qml");

        return Qt.resolvedUrl(pages[index].source);
    }

    function openPage(pageId) {
        if (pageId === "language-region")
            return root.openPageSection("general", "language-region");

        for (let index = 0; index < pages.length; ++index) {
            if (pages[index].id === pageId) {
                currentPage = index;
                return true;
            }
        }
        return false;
    }

    function openPageSection(pageId, section) {
        root.pendingPageSection = section;
        if (!root.openPage(pageId)) {
            root.pendingPageSection = "";
            return false;
        }
        root.applyPendingPageSection();
        return true;
    }

    function applyPendingPageSection() {
        if (!root.pendingPageSection || !pageLoader.item)
            return;

        if (root.pages[root.currentPage].id !== "general" || typeof pageLoader.item.openSection
                !== "function")

            return;

        const section = root.pendingPageSection;
        root.pendingPageSection = "";
        pageLoader.item.openSection(section);
    }

    function closeChildWindows() {
        const page = pageLoader.item;
        if (page && typeof page.closeChildWindows === "function")
            page.closeChildWindows();
    }

    function openConfig() {
        ApplicationService.openUrl(Paths.fileUrl(PersonalizationConfig.filePath));
    }

    function copyConfigPath() {
        Quickshell.clipboardText = PersonalizationConfig.filePath;
        copiedTimer.restart();
    }

    visible: false
    title: "clavis-control-center"
    implicitWidth: 1100
    implicitHeight: 750
    minimumSize: Qt.size(760, 520)
    color: Appearance.m3colors.m3background
    Material.theme: PersonalizationConfig.themeMode === "light" ? Material.Light : Material.Dark
    Material.accent: Appearance.colors.colPrimary
    onVisibleChanged: {
        if (!root.visible && root._wasShown) {
            ControlCenterService.cancelSearch();
            root.closeChildWindows();
            root._wasShown = false;
            root.popoutClosed();
        }
    }
    onCurrentPageChanged: {
        if (ControlCenterService.searchTarget && !ControlCenterService.applyingSearch && searchRequestSerial
                === ControlCenterService.searchSerial)
            ControlCenterService.cancelSearch();
        root.closeChildWindows();
        ControlCenterService.retrySearch();
    }

    Timer {
        id: copiedTimer

        interval: 1400
    }

    Item {
        id: focusBoundary
        anchors.fill: parent

        Shortcut {
            sequence: "Ctrl+F"
            enabled: root.visible && focusBoundary.Window.active
            onActivated: settingsSearch.open()
        }

        Shortcut {
            sequence: "Escape"
            enabled: root.visible && settingsSearch.expanded
            onActivated: settingsSearch.close()
        }

        function releaseInputFocus(position) {
            const input = focusBoundary.Window.activeFocusItem;
            if (!(input instanceof TextInput) && !(input instanceof TextEdit))
                return;
            if (input.contains(input.mapFromItem(focusBoundary, position)))
                return;
            // Clear the field's local focus as well as the window's active focus:
            // otherwise a nested FocusScope can restore the field immediately.
            input.focus = false;
            focusBoundary.forceActiveFocus(Qt.MouseFocusReason);
        }

        MouseArea {
            anchors.fill: parent
            z: 1000
            acceptedButtons: Qt.AllButtons
            // Inspect presses before page controls handle them, then let the
            // original press through for text selection, buttons and dragging.
            onPressed: mouse => {
                focusBoundary.releaseInputFocus(Qt.point(mouse.x, mouse.y));
                mouse.accepted = false;
            }
            onWheel: wheel => wheel.accepted = false
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.contentPadding
            spacing: root.contentPadding

            Item {
                id: titlebar

                Layout.fillWidth: true
                Layout.preferredHeight: 40

                SettingsWindowControls {
                    id: windowControls

                    x: PersonalizationConfig.settingsWindowControlsSide === "right" ? parent.width - width : 0
                    anchors.top: parent.top
                    maximized: root.maximized
                    onCloseRequested: root.hideWindow()
                    onMinimizeRequested: root.minimizeWindow()
                    onMaximizeRequested: root.toggleMaximize()
                }

                Item {
                    id: searchBarSlot
                    anchors.centerIn: parent
                    width: Math.min(360, parent.width - windowControls.width * 2 - Metrics.spacingL * 2)
                    height: 36
                }

                DragHandler {
                    target: null
                    acceptedButtons: Qt.LeftButton
                    onActiveChanged: {
                        if (active)
                            root.startSystemMove();
                    }
                }

                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onDoubleTapped: root.toggleMaximize()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: root.contentPadding

                Item {
                    id: navRailWrapper

                    Layout.fillHeight: true
                    Layout.margins: 5
                    implicitWidth: root.navExpanded ? 150 : configButton.baseSize

                    ColumnLayout {
                        id: navRail

                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        spacing: 10

                        NavigationRailExpandButton {
                            expanded: root.navExpanded
                            onClicked: root.navExpanded = !root.navExpanded
                        }

                        FloatingActionButton {
                            id: configButton

                            property bool justCopied: copiedTimer.running

                            iconText: justCopied ? "check" : "edit"
                            buttonText: justCopied ? qsTr("Path copied") : qsTr("config file")
                            expanded: root.navExpanded
                            onClicked: root.openConfig()
                            onAltClicked: root.copyConfigPath()
                        }

                        NavigationRailTabArray {
                            currentIndex: root.currentPage
                            expanded: root.navExpanded

                            Repeater {
                                model: root.pages

                                NavigationRailButton {
                                    required property int index
                                    required property var modelData

                                    active: root.currentPage === index
                                    expanded: root.navExpanded
                                    buttonIcon: modelData.icon
                                    buttonText: modelData.title
                                    showToggledHighlight: false
                                    onPressed: root.currentPage = index
                                }
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                        }
                    }

                    Behavior on implicitWidth {
                        NumberAnimation {
                            duration: Appearance.animation.elementMoveFast.duration
                            easing.type: Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                        }
                    }
                }

                Rectangle {
                    id: bodyBackground

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Math.max(0, Appearance.rounding.large - root.contentPadding)
                    color: root.currentPage === 0 ? "transparent" : Appearance.m3colors.m3surfaceContainerLow
                    clip: true

                    InlineStatusBanner {
                        z: 200
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: Metrics.spacingM
                        visible: ControlCenterService.searchError !== ""
                        tone: "error"
                        message: ControlCenterService.searchError
                    }

                    SettingsPageHost {
                        id: pageLoader

                        property var parentModal: root

                        anchors.fill: parent
                        source: root.pageSource(root.currentPage)
                        presentationActive: root.visible
                        onLoaded: {
                            if (item && "parentModal" in item)
                                item.parentModal = parentModal;

                            const page = item;
                            if (page && "presentationActive" in page)
                                page.presentationActive = Qt.binding(function () {
                                    return root.visible && pageLoader.item === page;
                                });

                            root.applyPendingPageSection();
                            ControlCenterService.retrySearch();
                        }
                    }

                    Connections {
                        function onNavigateRequested(pageId) {
                            if (pageId === "connected-devices" || pageId === "network" || pageId
                                    === "shortcuts") {
                                root.openPageSection("general", pageId);
                                return;
                            }
                            root.openPage(pageId);
                        }

                        target: pageLoader.item
                        ignoreUnknownSignals: true
                    }
                }
            }
        }

        SettingsSearch {
            id: settingsSearch
            anchors.fill: parent
            z: 500
            barSlot: searchBarSlot
            sideMargin: root.contentPadding + windowControls.width + Metrics.spacingXL
            onCollapsed: focusBoundary.forceActiveFocus(Qt.OtherFocusReason)
        }
    }
}
