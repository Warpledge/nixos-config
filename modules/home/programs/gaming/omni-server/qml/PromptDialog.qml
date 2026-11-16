// Asks for a few short answers. open() takes a heading, fields (a placeholder's name, or
// {key, label, value}) and a callback given {key: answer}
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: dialog
    property string heading
    property var fields: []
    property var done: null
    //--- Fades in and its card grows into place, as ConfirmDialog does
    property bool showing: false
    visible: opacity > 0
    opacity: showing ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.ms(180); easing.type: Easing.OutQuad } }
    color: Qt.rgba(0, 0, 0, 0.5)

    function open(title, items, callback) {
        heading = title
        fields = items.map(f => typeof f === "string"
            ? { key: f, label: f[0].toUpperCase() + f.slice(1), value: "" } : f)
        done = callback
        showing = true
        forceActiveFocus()
    }
    function dismiss() { showing = false }

    function finish() {
        const answers = {}
        for (let i = 0; i < inputs.count; i++) {
            const row = inputs.itemAt(i)
            answers[row.modelData.key] = row.answer
        }
        showing = false
        const callback = done
        done = null
        if (callback)
            Qt.callLater(callback, answers)
    }

    Keys.onEscapePressed: dismiss()
    MouseArea { anchors.fill: parent; enabled: dialog.showing; onClicked: dialog.dismiss() }

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
            spacing: 12
            Text {
                text: dialog.heading
                textFormat: Text.PlainText
                color: Theme.text
                font.pixelSize: 20
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
            Repeater {
                id: inputs
                model: dialog.fields
                Field {
                    required property var modelData
                    required property int index
                    readonly property string answer: text
                    placeholder: modelData.label
                    Component.onCompleted: {
                        text = modelData.value || ""
                        if (index === 0)
                            input.forceActiveFocus()
                    }
                    onAccepted: dialog.finish()
                    onEscaped: dialog.dismiss()
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Item { Layout.fillWidth: true }
                Pill { quiet: true; text: "Cancel"; onClicked: dialog.dismiss() }
                Pill { text: "OK"; onClicked: dialog.finish() }
            }
        }
    }
}
