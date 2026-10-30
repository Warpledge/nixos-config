// MangoHud (Gaming tab): the user's mangohud settings, which
// gaming/default.nix writes into MangoHud.conf, and a test window
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var view
    readonly property var setting: view.info.pages["mangohud"]
    spacing: 6

    Repeater {
        model: page.setting ? page.setting.groups : []
        ColumnLayout {
            id: group
            required property var modelData
            Layout.fillWidth: true
            spacing: 6
            Section { text: group.modelData.title }
            Repeater {
                model: group.modelData.settings
                SettingRow {
                    required property var modelData
                    setting: modelData
                    view: page.view
                    locked: group.modelData.locked
                    pageGlyph: "monitoring"
                }
            }
        }
    }

    ListRow {
        icon: "deployed_code"
        title: "Try It"
        info: "Opens a spinning cube with the overlay, as last applied: pending changes show after Apply."
        button: "Open Test Window"
        onClicked: Backend.call("mangohudTest", {}, reply => {
            if (!reply.ok)
                page.view.say(`Couldn't open the test window: ${reply.error}`)
        })
    }
}
