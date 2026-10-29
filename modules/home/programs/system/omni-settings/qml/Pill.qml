// A pill button; `quiet` for the secondary actions beside the main one
import QtQuick

Rectangle {
    id: pill
    property alias text: pillText.text
    property bool quiet: false
    property bool danger: false
    readonly property color accent: Theme.accentOf(pill)
    readonly property bool lit: hover.hovered && enabled
    signal clicked
    implicitWidth: pillText.implicitWidth + 28
    implicitHeight: 34
    radius: 17
    opacity: enabled ? 1 : 0.45
    // Lifts a little under the cursor, like the cards' hover
    scale: lit ? 1.03 : 1
    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: 120 } }
    color: danger ? (lit ? Qt.lighter(Theme.error, 1.12) : Theme.error)
         : quiet ? Qt.alpha(accent, lit ? 0.26 : 0.14)
         : lit ? Qt.lighter(accent, 1.12) : accent
    border.width: quiet ? 1 : 0
    border.color: Qt.alpha(accent, 0.3)
    Text {
        id: pillText
        anchors.centerIn: parent
        font.pixelSize: 15
        font.weight: Font.Bold
        color: pill.danger ? Theme.inkError : pill.quiet ? pill.accent : Theme.inkPrimary
    }
    HoverHandler { id: hover; cursorShape: pill.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
    // Takes the press, so a dialog closing on release doesn't hand it to what's below
    TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: pill.clicked() }
}
