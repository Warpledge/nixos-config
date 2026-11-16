// A key number with a small line of its recent past; tapping opens the big graph
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: tile
    property string label
    property string value: "–"
    property string sub: ""
    property color ink: Theme.text
    property var points: []  // 0 to 1, oldest first
    property color lineColor: Theme.primary
    property bool selected: false
    signal tapped
    Layout.fillWidth: true
    Layout.preferredWidth: 1
    implicitHeight: col.implicitHeight + Theme.pad(20)
    radius: Theme.r(12)
    color: hover.hovered ? Theme.hover : Qt.alpha(Theme.bg, 0.55)
    border.width: selected ? 2 : 1
    border.color: selected ? Theme.primary : hover.hovered ? Qt.alpha(Theme.primary, 0.4) : Theme.rule
    // Lifts a touch under the cursor, and dips when pressed
    scale: tap.pressed ? 0.98 : hover.hovered ? 1.015 : 1
    Behavior on scale { NumberAnimation { duration: Theme.ms(160); easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: Theme.ms(140) } }
    Behavior on border.color { ColorAnimation { duration: Theme.ms(180) } }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: 12
        spacing: 2
        Text {
            text: tile.label
            color: Theme.dim
            font.pixelSize: 10
            font.weight: Font.Bold
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 0.5
        }
        Text {
            Layout.fillWidth: true
            text: tile.value
            color: tile.ink
            Behavior on color { ColorAnimation { duration: Theme.ms(400) } }
            font.pixelSize: 22
            font.weight: Font.Bold
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: 13
        }
        Text {
            Layout.fillWidth: true
            text: tile.sub
            textFormat: Text.PlainText
            color: Theme.dim
            font.pixelSize: 11
            elide: Text.ElideRight
        }
        LineGraph {
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            Layout.topMargin: 4
            values: tile.points
            count: Math.max(2, tile.points.length)
            color: tile.lineColor
        }
    }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { id: tap; gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: tile.tapped() }
}
