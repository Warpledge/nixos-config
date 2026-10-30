// A page over the whole view with a back button, a scrolling body and a button row
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: sheet
    property string title
    property string subtitle: ""  // what's being edited and where it's saved
    default property alias content: body.data
    property alias actions: actionRow.data
    signal back
    color: Theme.bg

    Keys.onEscapePressed: back()

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            IconButton { icon: "arrow_back"; tip: "Back"; onClicked: sheet.back() }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: sheet.title
                    color: Theme.text
                    font.pixelSize: 17
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    visible: sheet.subtitle !== ""
                    text: sheet.subtitle
                    color: Theme.dim
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.rule }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: body.implicitHeight + 8
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ColumnLayout {
                id: body
                width: parent.width
                spacing: 6
            }
        }

        Rectangle {
            visible: actionRow.visible
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.rule
        }
        RowLayout {
            id: actionRow
            visible: children.length > 0
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight
            spacing: 8
        }
    }
}
