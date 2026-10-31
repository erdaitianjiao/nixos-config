import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.Widgets.common

TopBarPill {
    id: root

    property bool vertical: false

    implicitHeight: vertical ? buttonRow.implicitHeight + 2 * root.pillPadding : root.pillThickness
    implicitWidth: vertical ? root.pillThickness : buttonRow.implicitWidth + 2 * root.pillPadding

    GridLayout {
        id: buttonRow

        anchors.centerIn: parent
        rowSpacing: Sizes.barItemSpacing
        columnSpacing: Sizes.barItemSpacing
        columns: root.vertical ? 1 : 3

        SidebarPillButton {
            viewName: "info"
            sidebarIconName: "notifications"
        }

        SidebarPillButton {
            viewName: "drawer"
            sidebarIconName: "widgets"
        }

        SidebarWeatherButton {
            vertical: root.vertical
        }
    }
}
