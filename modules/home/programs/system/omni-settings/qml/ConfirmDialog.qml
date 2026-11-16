// A modal question over the whole view: heading, body and a row of buttons.
// open() takes {heading, body, buttons: [{label, value, quiet, danger}]} and a
// callback given the picked value; body can change while it's open. With
// cancel: false it has no Cancel button, for a message.
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: dialog
    property string heading
    property string body
    property var buttons: []
    property bool cancel: true
    property var done: null
    //--- Fades in and its card grows into place; it stays visible until faded out
    property bool showing: false
    visible: opacity > 0
    opacity: showing ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.ms(180); easing.type: Easing.OutQuad } }
    color: Qt.rgba(0, 0, 0, 0.5)

    function open(spec, callback) {
        heading = spec.heading
        body = spec.body || ""
        buttons = spec.buttons
        cancel = spec.cancel !== false
        done = callback
        showing = true
        forceActiveFocus()
    }

    function close(value) {
        showing = false
        const callback = done
        done = null
        // After the click that closed it has been handled
        if (callback && value !== undefined)
            Qt.callLater(callback, value)
    }

    Keys.onEscapePressed: close()
    // Swallows clicks on the dimmed view; a click outside the card cancels
    MouseArea { anchors.fill: parent; enabled: dialog.showing; onClicked: dialog.close() }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width - 32, 440)
        implicitHeight: col.implicitHeight + 40
        radius: Theme.r(24)
        scale: dialog.showing ? 1 : 0.94
        Behavior on scale { NumberAnimation { duration: Theme.ms(240); easing.type: Easing.OutCubic } }
        color: Theme.card
        border.width: 1
        border.color: Theme.line
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14
            Text {
                text: dialog.heading
                textFormat: Text.PlainText
                color: Theme.text
                font.pixelSize: 20
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
            Text {
                visible: text !== ""
                text: dialog.body
                textFormat: Text.PlainText
                color: Theme.dim
                font.pixelSize: 15
                wrapMode: Text.Wrap
                lineHeight: 1.15
                Layout.fillWidth: true
            }
            Flow {
                Layout.fillWidth: true
                layoutDirection: Qt.RightToLeft
                spacing: 8
                // Listed last-first so the main button sits at the right
                Repeater {
                    model: dialog.buttons.slice().reverse()
                    Pill {
                        required property var modelData
                        text: modelData.label
                        quiet: !!modelData.quiet
                        danger: !!modelData.danger
                        onClicked: dialog.close(modelData.value)
                    }
                }
                Pill { visible: dialog.cancel; quiet: true; text: "Cancel"; onClicked: dialog.close() }
            }
        }
    }
}
