// A page generated from the settings templates (api.py's `load`)
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: page
    required property var model
    required property var view
    readonly property string glyph: Theme.glyph(model.icon)
    spacing: 6

    Text {
        visible: text !== ""
        text: Theme.rich(page.model.intro || page.model.description)
        textFormat: Text.StyledText
        color: Theme.dim
        font.pixelSize: 13
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        Layout.leftMargin: 6
        Layout.rightMargin: 6
        Layout.bottomMargin: 4
    }

    //--- Change For: this computer, another listing the user, or all of them
    ColumnLayout {
        visible: page.model.changeFor
        Layout.fillWidth: true
        spacing: 4
        Section { text: "Change For" }
        Flow {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            spacing: 6
            Repeater {
                model: page.view.scopes
                Chip {
                    required property var modelData
                    text: modelData.title
                    accent: page.view.scope === modelData.id
                    opacity: page.view.pendingCount && !accent ? 0.5 : 1
                    onTapped: page.view.setScope(modelData.id)
                }
            }
        }
    }

    Repeater {
        model: page.model.groups
        ColumnLayout {
            id: group
            required property var modelData
            Layout.fillWidth: true
            spacing: 6
            Section { visible: text !== ""; text: group.modelData.title }
            Text {
                visible: text !== ""
                text: Theme.rich(group.modelData.description)
                textFormat: Text.StyledText
                color: Theme.dim
                font.pixelSize: 12
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                Layout.leftMargin: 6
            }
            Text {
                visible: group.modelData.locked
                text: "Only an admin can change these."
                color: Theme.caution
                font.pixelSize: 12
                Layout.leftMargin: 6
            }
            Repeater {
                model: group.modelData.settings
                SettingRow {
                    required property var modelData
                    setting: modelData
                    view: page.view
                    locked: group.modelData.locked
                    pageGlyph: page.glyph
                }
            }
            //--- DMS settings tabs this group links to
            Repeater {
                model: group.modelData.links
                ListRow {
                    required property var modelData
                    icon: Theme.glyph(modelData.icon, "open_in_new")
                    title: modelData.title
                    subtitle: modelData.subtitle
                    trailing: "open_in_new"
                    onClicked: Quickshell.execDetached(["dms", "ipc", "call", "settings", "openWith", modelData.tab])
                }
            }
        }
    }
}
