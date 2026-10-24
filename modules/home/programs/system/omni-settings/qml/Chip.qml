// A small rounded label; with `onTapped` connected it's a toggle chip
import QtQuick

Rectangle {
    id: chip
    property alias text: label.text
    property bool accent: false
    property bool success: false
    property string tone: success ? "success" : ""
    property string icon: ""
    property bool tappable: true  // false for a label: no hover or hand cursor
    signal tapped
    implicitWidth: row.implicitWidth + 16
    implicitHeight: 26
    radius: 13
    readonly property bool lit: tappable && hover.hovered
    color: tone ? Qt.alpha(Theme.toneColor(tone), lit ? 0.34 : 0.2)
         : accent ? Qt.alpha(Theme.primary, lit ? 0.34 : 0.2)
         : lit ? Theme.hover : Theme.cardHover
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4
        Text {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 13
            color: chip.tone ? Theme.toneColor(chip.tone) : chip.accent ? Theme.primary : Theme.dim
        }
        Icon {
            visible: chip.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            icon: chip.icon
            size: 14
            color: label.color
        }
    }
    HoverHandler { id: hover; cursorShape: chip.tappable ? Qt.PointingHandCursor : Qt.ArrowCursor }
    TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: chip.tapped() }
}
