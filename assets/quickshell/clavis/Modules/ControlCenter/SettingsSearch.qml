pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.Components
import qs.Widgets.common
import "../../Common/functions/SpotlightLocalSearch.js" as LocalSearch

Item {
    id: root

    required property Item barSlot
    property real sideMargin: 112
    property bool expanded: false
    property real expansion: expanded ? 1 : 0
    property real contentReveal: expanded ? 1 : 0
    readonly property string query: input.text
    readonly property var matches: {
        const available = SpotlightCatalog.settings.filter(entry => SpotlightCatalog.available(entry));
        return query.trim() ? LocalSearch.matchCatalog(available, query) : available.filter(entry =>
        !entry.anchor);
    }
    readonly property rect barGeometry: {
        const viewportWidth = root.width;
        const viewportHeight = root.height;
        const slotX = barSlot.x;
        const slotY = barSlot.y;
        return barSlot.mapToItem(root, 0, 0, barSlot.width, barSlot.height);
    }
    readonly property real expandedWidth: Math.min(720, Math.max(0, width - sideMargin * 2))
    readonly property real expandedHeight: Math.min(600, height - barGeometry.y - Metrics.spacingL)

    signal collapsed

    function open() {
        expanded = true;
        input.forceActiveFocus(Qt.ShortcutFocusReason);
    }

    function close() {
        if (!expanded)
            return;
        expanded = false;
        input.focus = false;
        collapsed();
    }

    function activate(index) {
        const entry = matches[index];
        if (entry && SpotlightCatalog.available(entry) && ControlCenterService.openSearch(entry.id))
            close();
    }

    function moveSelection(offset) {
        if (matches.length)
            results.currentIndex = (results.currentIndex + offset + matches.length) % matches.length;
    }

    onMatchesChanged: results.currentIndex = matches.length ? 0 : -1

    // Material's emphasized multi-segment curve moves the surface quickly,
    // then settles it while the content and navigation icon arrive separately.
    Behavior on expansion {
        NumberAnimation {
            id: morph
            duration: root.expanded ? 500 : 250
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Animations.curves.emphasized
            onRunningChanged: {
                if (!running && !root.expanded)
                    input.clear();
            }
        }
    }

    Behavior on contentReveal {
        SequentialAnimation {
            PauseAnimation {
                duration: root.expanded ? 100 : 0
            }
            NumberAnimation {
                duration: root.expanded ? 150 : 100
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Animations.curves.standard
            }
        }
    }

    Rectangle {
        y: root.barGeometry.y + root.barGeometry.height + Metrics.spacingS
        width: root.width
        height: Math.max(0, root.height - y)
        visible: root.expansion > 0
        color: Appearance.applyAlpha(Appearance.colors.colOnSurface, 0.08 * root.expansion)

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
            onWheel: wheel => wheel.accepted = true
        }
    }

    Rectangle {
        id: surface

        x: root.barGeometry.x + ((root.width - root.expandedWidth) / 2 - root.barGeometry.x) * root.expansion
        y: root.barGeometry.y
        width: root.barGeometry.width + (root.expandedWidth - root.barGeometry.width) * root.expansion
        height: root.barGeometry.height + (root.expandedHeight - root.barGeometry.height) * root.expansion
        radius: root.barGeometry.height / 2 + (Metrics.cornerL - root.barGeometry.height / 2) * root.expansion
        color: Appearance.m3colors.m3surfaceContainerHigh
        clip: true

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (!root.expanded)
                    root.open();
            }
            onWheel: wheel => wheel.accepted = true
        }

        Rectangle {
            anchors.fill: parent
            radius: surface.radius
            color: Appearance.m3colors.m3surfaceContainerLow
            opacity: root.expansion
        }

        Rectangle {
            width: parent.width
            height: root.barGeometry.height
            radius: height / 2
            color: Appearance.m3colors.m3surfaceContainerHigh

            RippleButton {
                id: navigation
                x: Metrics.spacingS
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: Metrics.controlHeightS
                implicitHeight: Metrics.controlHeightS
                buttonRadius: height / 2
                hoverStateLayerOpacity: Appearance.interaction.hoverStateLayerOpacity
                pressedStateLayerOpacity: Appearance.interaction.pressedStateLayerOpacity
                focusStateLayerOpacity: Appearance.interaction.focusStateLayerOpacity
                Accessible.name: root.expanded ? qsTr("Back") : qsTr("Search settings")
                onClicked: root.expanded ? root.close() : root.open()

                contentItem: Item {
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "search"
                        iconSize: Metrics.iconS + Metrics.spacingXS
                        color: Appearance.colors.colOnSurfaceVariant
                        opacity: 1 - root.expansion
                        rotation: -45 * root.expansion
                        scale: 1 - 0.2 * root.expansion
                    }
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "arrow_back"
                        iconSize: Metrics.iconS + Metrics.spacingXS
                        color: Appearance.colors.colOnSurface
                        opacity: root.expansion
                        rotation: 45 * (1 - root.expansion)
                        scale: 0.8 + 0.2 * root.expansion
                    }
                }

                StyledToolTip {
                    text: navigation.Accessible.name
                    visible: navigation.hovered
                }
            }

            TextInput {
                id: input
                anchors.left: navigation.right
                anchors.right: clearButton.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Metrics.spacingS
                anchors.rightMargin: Metrics.spacingS
                color: Appearance.colors.colOnSurface
                selectionColor: Appearance.colors.colPrimaryContainer
                selectedTextColor: Appearance.colors.colOnPrimaryContainer
                font.family: Typography.bodyMedium.family
                font.pixelSize: Typography.bodyMedium.pixelSize
                clip: true
                selectByMouse: true
                activeFocusOnPress: true
                inputMethodHints: Qt.ImhNoPredictiveText
                Accessible.name: qsTr("Search settings")
                onActiveFocusChanged: {
                    if (activeFocus)
                        root.expanded = true;
                }
                Keys.onEscapePressed: root.close()
                Keys.onDownPressed: root.moveSelection(1)
                Keys.onUpPressed: root.moveSelection(-1)
                Keys.onReturnPressed: root.activate(results.currentIndex)
                Keys.onEnterPressed: root.activate(results.currentIndex)

                Text {
                    anchors.fill: parent
                    visible: input.text.length === 0
                    text: qsTr("Search settings")
                    color: Appearance.colors.colOnSurfaceVariant
                    font: input.font
                }
            }

            RippleButton {
                id: clearButton
                anchors.right: parent.right
                anchors.rightMargin: Metrics.spacingS
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: Metrics.controlHeightS
                implicitHeight: Metrics.controlHeightS
                opacity: root.contentReveal
                enabled: root.expanded
                buttonRadius: height / 2
                hoverStateLayerOpacity: Appearance.interaction.hoverStateLayerOpacity
                pressedStateLayerOpacity: Appearance.interaction.pressedStateLayerOpacity
                focusStateLayerOpacity: Appearance.interaction.focusStateLayerOpacity
                Accessible.name: qsTr("Clear search")
                onClicked: {
                    input.clear();
                    input.forceActiveFocus();
                }
                contentItem: MaterialSymbol {
                    text: "close"
                    iconSize: Metrics.iconS + Metrics.spacingXS
                    color: Appearance.colors.colOnSurfaceVariant
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                StyledToolTip {
                    text: clearButton.Accessible.name
                    visible: clearButton.hovered
                }
            }
        }

        ColumnLayout {
            x: Metrics.spacingS
            y: root.barGeometry.height + Metrics.spacingM + 12 * (1 - root.contentReveal)
            width: surface.width - Metrics.spacingS * 2
            height: Math.max(0, surface.height - y - Metrics.spacingS)
            spacing: Metrics.spacingS
            opacity: root.contentReveal
            visible: root.expansion > 0
            enabled: root.expanded

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: Metrics.spacingM
                text: root.query.trim() ? qsTr("Results") : qsTr("Browse settings")
                color: Appearance.colors.colOnSurfaceVariant
                font.family: Typography.labelLarge.family
                font.pixelSize: Typography.labelLarge.pixelSize
                font.weight: Typography.labelLarge.weight
            }

            ListView {
                id: results
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.matches
                currentIndex: count ? 0 : -1
                keyNavigationEnabled: false
                boundsBehavior: Flickable.StopAtBounds
                spacing: Metrics.spacingXXS
                ScrollBar.vertical: StyledScrollBar {}
                onCurrentIndexChanged: {
                    if (currentIndex >= 0)
                        positionViewAtIndex(currentIndex, ListView.Contain);
                }

                delegate: RippleButton {
                    id: result
                    required property int index
                    required property var modelData
                    width: ListView.view.width
                    implicitHeight: 64
                    leftPadding: Metrics.spacingM
                    rightPadding: Metrics.spacingM
                    buttonRadius: Metrics.cornerM
                    containerColor: results.currentIndex === index ? Appearance.colors.colSecondaryContainer :
                                                                     "transparent"
                    hoverStateLayerOpacity: Appearance.interaction.hoverStateLayerOpacity
                    pressedStateLayerOpacity: Appearance.interaction.pressedStateLayerOpacity
                    focusStateLayerOpacity: Appearance.interaction.focusStateLayerOpacity
                    Accessible.name: modelData.title
                    Accessible.description: modelData.breadcrumb
                    Accessible.selected: results.currentIndex === index
                    onClicked: root.activate(index)
                    onHoveredChanged: {
                        if (hovered)
                            results.currentIndex = index;
                    }

                    contentItem: RowLayout {
                        spacing: Metrics.spacingM
                        MaterialSymbol {
                            text: result.modelData.icon
                            iconSize: Metrics.iconM
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Metrics.spacingXXS
                            Text {
                                Layout.fillWidth: true
                                text: result.modelData.title
                                textFormat: Text.PlainText
                                elide: Text.ElideRight
                                color: Appearance.colors.colOnSurface
                                font.family: Typography.bodyLarge.family
                                font.pixelSize: Typography.bodyLarge.pixelSize
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: result.modelData.path.length > 1 || !!result.modelData.anchor
                                text: result.modelData.breadcrumb
                                textFormat: Text.PlainText
                                elide: Text.ElideRight
                                color: Appearance.colors.colOnSurfaceVariant
                                font.family: Typography.bodySmall.family
                                font.pixelSize: Typography.bodySmall.pixelSize
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: results.count === 0
                    text: qsTr("No settings found")
                    color: Appearance.colors.colOnSurfaceVariant
                    font.family: Typography.bodyLarge.family
                    font.pixelSize: Typography.bodyLarge.pixelSize
                }
            }
        }
    }
}
