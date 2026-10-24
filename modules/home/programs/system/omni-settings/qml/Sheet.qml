// A page over the whole view with a back button, a scrolling body and a button row
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: sheet
    property string title
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
            IconButton { icon: "arrow_back"; onClicked: sheet.back() }
            Text {
                text: sheet.title
                color: Theme.text
                font.pixelSize: 18
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

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

        RowLayout {
            id: actionRow
            visible: children.length > 0
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight
            spacing: 8
        }
    }
}
