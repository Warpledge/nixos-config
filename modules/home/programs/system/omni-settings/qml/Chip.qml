// A small rounded label; with `onTapped` connected it's a toggle chip
import QtQuick

Rectangle {
    id: chip
    property alias text: label.text
    property bool accent: false
    property bool success: false
    property string tone: success ? "success" : ""
    property string icon: ""
    signal tapped
    implicitWidth: row.implicitWidth + 16
    implicitHeight: 26
    radius: 13
    color: tone ? Qt.alpha(Theme.toneColor(tone), 0.2) : accent ? Theme.primaryContainer
         : hover.hovered ? Theme.line : Theme.cardHover
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4
        Text {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 12
            color: chip.tone ? Theme.toneColor(chip.tone) : chip.accent ? Theme.inkContainer : Theme.dim
        }
        Icon {
            visible: chip.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            icon: chip.icon
            size: 14
            color: label.color
        }
    }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: chip.tapped() }
}
