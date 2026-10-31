import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Components
import qs.Widgets.common

RowLayout {
    id: root

    property bool maximized: false
    readonly property bool groupHovered: groupHover.hovered

    signal closeRequested
    signal minimizeRequested
    signal maximizeRequested

    implicitHeight: 28
    spacing: 0

    HoverHandler {
        id: groupHover
    }

    component TrafficButton: RippleButton {
        id: button

        required property color lightColor
        required property color ringColor
        required property color glyphColor
        required property string glyph
        required property string label

        implicitWidth: 24
        implicitHeight: 28
        padding: 0
        buttonRadius: Appearance.rounding.full
        stateLayerEnabled: false
        rippleColor: "transparent"
        Accessible.name: button.label

        contentItem: Item {
            Rectangle {
                anchors.centerIn: parent
                width: 14
                height: 14
                radius: 7
                color: button.down ? Qt.darker(button.lightColor, 1.15) : button.lightColor
                border.width: 1
                border.color: button.ringColor
                antialiasing: true

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: button.glyph
                    iconSize: 11
                    color: button.glyphColor
                    visible: root.groupHovered || button.visualFocus
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 22
                height: 22
                radius: 11
                color: "transparent"
                border.width: 2
                border.color: Appearance.colors.colPrimary
                visible: button.visualFocus
            }
        }

        StyledToolTip {
            text: button.label
            extraVisibleCondition: button.pointerHovered
            alternativeVisibleCondition: button.visualFocus
        }
    }

    TrafficButton {
        lightColor: "#fe6254"
        ringColor: "#cb4e43"
        glyphColor: "#7a2018"
        glyph: "close"
        label: qsTr("Close")
        onClicked: root.closeRequested()
    }

    TrafficButton {
        lightColor: "#fdc92d"
        ringColor: "#caa124"
        glyphColor: "#805900"
        glyph: "remove"
        label: qsTr("Minimize")
        onClicked: root.minimizeRequested()
    }

    TrafficButton {
        lightColor: "#28d33f"
        ringColor: "#20a932"
        glyphColor: "#0b6418"
        glyph: root.maximized ? "close_fullscreen" : "open_in_full"
        label: root.maximized ? qsTr("Restore") : qsTr("Maximize")
        onClicked: root.maximizeRequested()
    }
}
