// A page's card: a raised surface holding a column; `title` adds a heading row, and
// `headerExtras` go to its right. `overlay` items sit over the whole card, outside the
// layout (the header's progress shimmer). Its look follows Preferences' Cards, Corners
// and Density.
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: card
    property string title: ""
    property string info: ""  // shown on hovering the title
    default property alias content: body.data
    property alias headerExtras: extras.data
    property alias overlay: overlayHolder.data
    property alias spacing: body.spacing
    property int pad: 12
    Layout.fillWidth: true
    implicitHeight: outer.implicitHeight + Theme.pad(pad) * 2
    radius: Theme.r(14)
    color: Theme.cardFill(Theme.card)
    border.width: Theme.cardEdged ? 1 : 0
    border.color: Theme.cardEdge()
    Behavior on color { ColorAnimation { duration: Theme.ms(200) } }

    Item { id: overlayHolder; anchors.fill: parent; z: 2 }

    ColumnLayout {
        id: outer
        anchors.fill: parent
        anchors.margins: Theme.pad(card.pad)
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
