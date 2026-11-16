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
    radius: Math.min(height / 2, Theme.r(19))
    color: fieldHover.hovered && !input.activeFocus ? Theme.hover : Theme.cardHover
    // Fades the focus ring in rather than snapping it on
    border.width: 2
    border.color: input.activeFocus ? Theme.primary : Qt.alpha(Theme.primary, 0)
    Behavior on color { ColorAnimation { duration: Theme.ms(140) } }
    Behavior on border.color { ColorAnimation { duration: Theme.ms(180) } }
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
