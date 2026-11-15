// One of a page's key numbers: a small label, the value large, a line under it
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: tile
    property string label
    property string value
    property string sub: ""
    property color ink: Theme.text
    property bool tappable: false
    signal tapped()
    Layout.fillWidth: true
    Layout.preferredWidth: 1
    implicitHeight: col.implicitHeight + Theme.pad(20)
    radius: Theme.r(12)
    color: tappable && hover.hovered ? Theme.hover : Qt.alpha(Theme.bg, 0.55)
    border.width: 1
    border.color: tappable && hover.hovered ? Qt.alpha(Theme.primary, 0.4) : Theme.rule
    Behavior on color { ColorAnimation { duration: Theme.ms(120) } }
    Behavior on border.color { ColorAnimation { duration: Theme.ms(160) } }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 3
        Text {
            Layout.fillWidth: true
            text: tile.label
            color: Theme.dim
            font.pixelSize: 10
            font.weight: Font.Bold
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 0.5
            elide: Text.ElideRight
        }
        Text {
            Layout.fillWidth: true
            text: tile.value
            color: tile.ink
            font.pixelSize: 19
            font.weight: Font.Bold
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: 13
        }
        Text {
            visible: tile.sub !== ""
            Layout.fillWidth: true
            text: tile.sub + (tile.tappable ? " ›" : "")
            color: Theme.dim
            font.pixelSize: 11
            elide: Text.ElideRight
        }
    }
    HoverHandler { id: hover; enabled: tile.tappable; cursorShape: Qt.PointingHandCursor }
    TapHandler {
        enabled: tile.tappable
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: tile.tapped()
    }
}
