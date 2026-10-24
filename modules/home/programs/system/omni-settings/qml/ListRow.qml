// One DMS-style row: its own rounded block, icon badge, title and subtitle
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: row
    property string icon: "settings"
    property var app: []
    property string title
    property string subtitle
    property string tag: ""
    property string button: ""
    property string trailing: ""
    property bool chevron: false
    property bool selected: false
    property bool compact: false
    property int titleLines: 1
    property real bar: -1  // a usage bar under the text, 0 to 1
    signal clicked
    Layout.fillWidth: true
    implicitHeight: rowCol.implicitHeight + (compact ? 14 : 22)
    radius: 14
    opacity: enabled ? 1 : 0.5
    color: selected ? Theme.selected : hover.hovered ? Theme.cardHover : compact ? "transparent" : Theme.card
    Behavior on color { ColorAnimation { duration: 120 } }

    ColumnLayout {
        id: rowCol
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 10
        anchors.rightMargin: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Badge { icon: row.icon; app: row.app }
            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true
                Text {
                    text: row.title
                    color: Theme.text
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                    maximumLineCount: row.titleLines
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    visible: text !== ""
                    text: row.subtitle
                    color: Theme.dim
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                    maximumLineCount: row.compact ? 1 : 3
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
            Chip { visible: row.tag !== ""; text: row.tag; accent: true }
            Pill { visible: row.button !== ""; text: row.button; onClicked: row.clicked() }
            Icon { visible: row.chevron; icon: "chevron_right" }
            Icon { visible: row.trailing !== ""; icon: row.trailing; size: 18 }
        }

        Rectangle {
            visible: row.bar >= 0
            Layout.fillWidth: true
            Layout.leftMargin: 50
            implicitHeight: 6
            radius: 3
            color: Theme.cardHover
            Rectangle {
                height: parent.height
                radius: 3
                width: parent.width * Math.max(0, Math.min(1, row.bar))
                color: Theme.primary
            }
        }
    }

    HoverHandler { id: hover; cursorShape: row.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
    TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: row.clicked() }
}
