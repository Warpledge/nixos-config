// A DMS-style switch
import QtQuick

Rectangle {
    id: toggle
    property bool checked: false
    signal toggled(bool on)
    implicitWidth: 46
    implicitHeight: 26
    radius: 13
    opacity: enabled ? 1 : 0.45
    color: checked ? (switchHover.hovered ? Qt.lighter(Theme.primary, 1.12) : Theme.primary)
         : switchHover.hovered ? Theme.hover : Theme.cardHover
    border.width: checked ? 0 : 2
    border.color: Theme.line
    Behavior on color { ColorAnimation { duration: 120 } }
    Rectangle {
        width: toggle.checked ? 18 : 14
        height: width
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        x: toggle.checked ? parent.width - width - 4 : 6
        color: toggle.checked ? Theme.inkPrimary : Theme.dim
        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    }
    HoverHandler { id: switchHover; cursorShape: toggle.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
    TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: toggle.toggled(!toggle.checked) }
}
