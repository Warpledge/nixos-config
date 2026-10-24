// A pill button; `quiet` for the secondary actions beside the main one
import QtQuick

Rectangle {
    id: pill
    property alias text: pillText.text
    property bool quiet: false
    property bool danger: false
    signal clicked
    implicitWidth: pillText.implicitWidth + 28
    implicitHeight: 34
    radius: 17
    opacity: enabled ? 1 : 0.45
    color: danger ? (hover.hovered ? Qt.lighter(Theme.error, 1.12) : Theme.error)
         : quiet ? (hover.hovered ? Theme.hover : Theme.cardHover)
         : hover.hovered ? Qt.lighter(Theme.primary, 1.12) : Theme.primary
    Text {
        id: pillText
        anchors.centerIn: parent
        font.pixelSize: 15
        font.weight: Font.Bold
        color: pill.danger ? Theme.inkError : pill.quiet ? Theme.text : Theme.inkPrimary
    }
    HoverHandler { id: hover; cursorShape: pill.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
    // Takes the press, so a dialog closing on release doesn't hand it to what's below
    TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: pill.clicked() }
}
