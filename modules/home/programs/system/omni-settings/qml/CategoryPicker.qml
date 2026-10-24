// A window rule's category: typed, or one already in use picked from its chips
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: picker
    property alias text: field.text
    property var options: []
    Layout.fillWidth: true
    spacing: 6

    Field { id: field; placeholder: "None, or a name like Games or Dialogs" }
    Flow {
        visible: picker.options.length > 0
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: picker.options
            Chip {
                required property var modelData
                text: modelData
                accent: field.text.trim().toLowerCase() === modelData.toLowerCase()
                onTapped: field.text = accent ? "" : modelData
            }
        }
    }
}
