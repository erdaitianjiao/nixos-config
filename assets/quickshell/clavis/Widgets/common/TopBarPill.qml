import QtQuick
import QtQuick.Effects
import qs.Common
import qs.Services

Item {
    id: root

    default property alias contentData: contentViewport.data
    property bool animateResize: true
    property bool backgroundVisible: true
    readonly property real pillThickness: backgroundVisible ? PersonalizationConfig.barThickness :
                                                              Sizes.barPillThickness
    readonly property real pillPadding: backgroundVisible ? PersonalizationConfig.barInnerPadding :
                                                            Sizes.barPillHorizontalPadding
    readonly property real radius: Math.min(width / 2, height / 2, backgroundVisible
                                            ? PersonalizationConfig.barModuleRadius : Math.min(width, height)
                                              / 2)

    // Animate the size consumed by the bar layout so the surface, shadow and
    // neighbouring pills follow the same geometry throughout a resize.
    property bool resizeAnimationReady: false
    Component.onCompleted: resizeAnimationReady = true

    // Keep the shadow outside the clipped content subtree.
    data: [
        TopBarPillBackground {
            anchors.fill: parent
            visible: root.backgroundVisible
            cornerRadius: root.radius
        },
        Rectangle {
            id: contentMask
            width: root.width
            height: root.height
            radius: root.radius
            color: "white"
            visible: false
            layer.enabled: true
        },
        Item {
            id: contentViewport
            anchors.fill: parent
            clip: true
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: contentMask
            }
        }
    ]

    Behavior on implicitWidth {
        enabled: root.resizeAnimationReady && root.animateResize
        NumberAnimation {
            duration: Appearance.animation.standard.duration
            easing.type: Appearance.animation.standard.type
            easing.bezierCurve: Appearance.animation.standard.bezierCurve
        }
    }

    Behavior on implicitHeight {
        enabled: root.resizeAnimationReady && root.animateResize
        NumberAnimation {
            duration: Appearance.animation.standard.duration
            easing.type: Appearance.animation.standard.type
            easing.bezierCurve: Appearance.animation.standard.bezierCurve
        }
    }
}
