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
    implicitHeight: col.implicitHeight + 20
    radius: 12
    color: hover.hovered ? Theme.hover : Qt.alpha(Theme.bg, 0.55)
    border.width: 1
    border.color: selected ? Theme.primary : Theme.rule
    Behavior on color { ColorAnimation { duration: 120 } }

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
            Layout.preferredHeight: 22
            Layout.topMargin: 4
            values: tile.points
            count: Math.max(2, tile.points.length)
            color: tile.lineColor
        }
    }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: tile.tapped() }
}
