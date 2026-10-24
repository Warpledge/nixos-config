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
    color: checked ? Theme.primary : Theme.cardHover
    border.width: checked ? 0 : 2
    border.color: Theme.line
    Behavior on color { ColorAnimation { duration: 120 } }
    Rectangle {
        width: toggle.checked ? 18 : 14
        height: width
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        x: toggle.checked ? parent.width - width - 4 : 6
        color: toggle.checked ? Theme.onPrimary : Theme.dim
        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    }
    HoverHandler { cursorShape: toggle.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
    TapHandler { onTapped: toggle.toggled(!toggle.checked) }
}
