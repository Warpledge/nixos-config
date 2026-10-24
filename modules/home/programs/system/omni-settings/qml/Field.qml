// A rounded one-line text field; `accepted` on Enter
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: field
    property alias text: input.text
    property alias input: input
    property string placeholder: ""
    property string icon: ""
    signal accepted
    signal escaped
    Layout.fillWidth: true
    implicitHeight: 38
    radius: 19
    color: fieldHover.hovered && !input.activeFocus ? Theme.hover : Theme.cardHover
    border.width: input.activeFocus ? 2 : 0
    border.color: Theme.primary
    HoverHandler { id: fieldHover; cursorShape: Qt.IBeamCursor }
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8
        Icon { visible: field.icon !== ""; icon: field.icon; size: 18 }
        TextInput {
            id: input
            Layout.fillWidth: true
            color: Theme.text
            selectionColor: Theme.primary
            selectedTextColor: Theme.inkPrimary
            font.pixelSize: 15
            clip: true
            onAccepted: field.accepted()
            Keys.onEscapePressed: field.escaped()
            Text {
                visible: !parent.text && !parent.preeditText
                text: field.placeholder
                color: Theme.dim
                font.pixelSize: 15
            }
        }
    }
    TapHandler { onTapped: input.forceActiveFocus() }
}
