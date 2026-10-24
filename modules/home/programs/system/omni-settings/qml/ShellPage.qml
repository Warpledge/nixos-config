// The Niri tab's start page: DankMaterialShell's settings in one place
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var view
    spacing: 6

    Text {
        text: "DankMaterialShell, the bar, launcher and lock screen niri runs with. "
              + "The pages below hold the rest of its settings."
        color: Theme.dim
        font.pixelSize: 15
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        Layout.leftMargin: 6
        Layout.rightMargin: 6
    }
    QuickLinks {
        Layout.fillWidth: true
        links: page.view.links
        order: page.view.info.quick
    }
}
