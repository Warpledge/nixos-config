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
    signal clicked
    Layout.fillWidth: true
    implicitHeight: rowLayout.implicitHeight + (compact ? 14 : 22)
    radius: 14
    color: selected ? Theme.selected : hover.hovered ? Theme.cardHover : compact ? "transparent" : Theme.card
    Behavior on color { ColorAnimation { duration: 120 } }
    RowLayout {
        id: rowLayout
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 10
        anchors.rightMargin: 12
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
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Text {
                visible: text !== ""
                text: row.subtitle
                color: Theme.dim
                font.pixelSize: 12
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
        Chip { visible: row.tag !== ""; text: row.tag; accent: true }
        Pill { visible: row.button !== ""; text: row.button; onClicked: row.clicked() }
        Icon { visible: row.chevron; icon: "chevron_right" }
        Icon { visible: row.trailing !== ""; icon: row.trailing; size: 18 }
    }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: row.clicked() }
}
