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
    implicitWidth: row.implicitWidth + 20
    implicitHeight: 26
    radius: 13
    readonly property bool lit: tappable && hover.hovered
    readonly property color pageColour: Theme.accentOf(chip)
    readonly property color tint: tone ? Theme.toneColor(tone) : pageColour
    color: tone || accent ? Qt.alpha(tint, lit ? 0.32 : 0.18)
         : Qt.alpha(tint, lit ? 0.14 : 0.06)
    border.width: 1
    border.color: Qt.alpha(tint, tone || accent ? 0.35 : 0.12)
    Behavior on color { ColorAnimation { duration: 120 } }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4
        Text {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 13
            font.weight: chip.tone || chip.accent ? Font.DemiBold : Font.Normal
            color: chip.tone || chip.accent ? chip.tint : Theme.dim
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
    // A label leaves the tap to what's under it
    TapHandler { enabled: chip.tappable; gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: chip.tapped() }
}
