// One crash report, as plain text that can be selected and copied
import QtQuick
import QtQuick.Layouts
import Quickshell

Sheet {
    id: sheet
    property var app
    property string body: ""
    onBack: app.closeSheet()

    function open(name) {
        title = name
        app.call("crash_read", { name }, reply => { sheet.body = reply.text })
    }

    TextEdit {
        Layout.fillWidth: true
        text: sheet.body
        textFormat: TextEdit.PlainText
        readOnly: true
        selectByMouse: true
        wrapMode: TextEdit.Wrap
        color: Theme.text
        selectionColor: Theme.primary
        selectedTextColor: Theme.inkPrimary
        font.family: "monospace"
        font.pixelSize: 12
    }

    actions: [
        Item { Layout.fillWidth: true },
        OutlineButton {
            text: "Copy"
            onClicked: Quickshell.clipboardText = sheet.body
        }
    ]
}
