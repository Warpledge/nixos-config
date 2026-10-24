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
    color: danger ? Theme.error : quiet ? (hover.hovered ? Theme.line : Theme.cardHover)
         : Theme.primary
    Text {
        id: pillText
        anchors.centerIn: parent
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: pill.danger ? Theme.inkError : pill.quiet ? Theme.text : Theme.inkPrimary
    }
    HoverHandler { id: hover; cursorShape: pill.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
    TapHandler { onTapped: pill.clicked() }
}
