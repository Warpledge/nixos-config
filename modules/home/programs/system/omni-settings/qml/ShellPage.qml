// The Niri tab's start page: DankMaterialShell's settings in one place
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var view
    spacing: 6

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
