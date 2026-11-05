// A page's card: a raised surface holding a column; `title` adds a heading row, and
// `headerExtras` go to its right
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: card
    property string title: ""
    property string info: ""  // shown on hovering the title
    default property alias content: body.data
    property alias headerExtras: extras.data
    property alias spacing: body.spacing
    property int pad: 12
    Layout.fillWidth: true
    implicitHeight: outer.implicitHeight + pad * 2
    radius: 14
    color: Theme.card

    ColumnLayout {
        id: outer
        anchors.fill: parent
        anchors.margins: card.pad
        spacing: 8
        RowLayout {
            visible: card.title !== ""
            Layout.fillWidth: true
            spacing: 6
            Text {
                text: card.title
                textFormat: Text.PlainText
                color: Theme.text
                font.pixelSize: 14
                font.weight: Font.Bold
                TitleTip { tip: card.info }
            }
            Item { Layout.fillWidth: true }
            RowLayout { id: extras; spacing: 6 }
        }
        ColumnLayout {
            id: body
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
        }
    }
}
