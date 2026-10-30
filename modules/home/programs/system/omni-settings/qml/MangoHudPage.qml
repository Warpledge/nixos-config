// MangoHud (Gaming tab): the user's mangohud settings, which
// gaming/default.nix writes into MangoHud.conf, and a test window that follows
// the page's values live (api.py's mangohudPreview)
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var view
    readonly property var setting: view.info.pages["mangohud"]
    spacing: 6

    //--- The values with pending changes, {show, position, …}, and the items it knows
    readonly property var all: setting ? [].concat(...setting.groups.map(g => g.settings)) : []
    readonly property var hud: {
        const out = {}
        for (const s of all)
            out[s.key.split(".").pop()] = view.valueOf(s)
        return out
    }
    readonly property var items: {
        const s = all.find(x => x.key.endsWith(".show"))
        return s && s.options ? s.options : []
    }
    property bool testing: false  // a test window was opened from here
    onHudChanged: if (testing) Backend.call("mangohudPreview", { hud, items }, () => {})

    function test() {
        Backend.call("mangohudTest", { hud, items }, reply => {
            if (reply.ok)
                page.testing = true
            else
                page.view.say(`Couldn't open the test window: ${reply.error}`)
        })
    }

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
        info: "Opens a spinning cube with the overlay as set here, changes not yet applied too. It "
              + "follows each change while open; games get them after Apply."
        button: "Open Test Window"
        onClicked: page.test()
    }
}
