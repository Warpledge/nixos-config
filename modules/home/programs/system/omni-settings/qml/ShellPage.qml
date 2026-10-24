// The Niri tab's start page: DankMaterialShell's settings in one place
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var view
    spacing: 6

    Text {
        text: "DankMaterialShell, the bar, launcher and lock screen niri runs with. "
              + "Each tile opens its settings on that page."
        color: Theme.dim
        font.pixelSize: 15
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        Layout.leftMargin: 6
        Layout.rightMargin: 6
    }
    Repeater {
        model: page.view.info.shellLinks
        QuickLinks {
            required property var modelData
            Layout.fillWidth: true
            title: modelData.title
            description: ""
            links: modelData.links
        }
    }
}
