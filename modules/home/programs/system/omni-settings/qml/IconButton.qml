// A round icon-only button
import QtQuick

Rectangle {
    id: btn
    property string icon
    property bool filled: false
    property string tip: ""
    property color tint: Theme.dim
    signal clicked
    implicitWidth: 32
    implicitHeight: 32
    radius: 16
    color: filled || hover.hovered ? Theme.cardHover : "transparent"
    Icon { anchors.centerIn: parent; icon: btn.icon; size: 18; color: btn.tint }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: btn.clicked() }
}
