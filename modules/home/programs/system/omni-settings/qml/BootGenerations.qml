// The default generation on the Boot page: pick one from the Overview's list
// rather than typing its number into the setting row above
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: boot
    required property var view
    property var generations: []
    property bool loaded: false
    readonly property var setting: view.settings["machine:boot.menu.default"] || null
    readonly property var entries: view.settings["machine:boot.menu.entries"] || null
    readonly property bool canEdit: !!view.info && view.info.direct && !!setting
    readonly property var chosen: setting ? view.valueOf(setting) : 0
    spacing: 6

    function load() {
        Backend.call("overview", {}, reply => {
            boot.loaded = true
            if (reply.ok)
                boot.generations = reply.data.generations
        })
    }

    Component.onCompleted: load()

    //--- A rebuild writes a new generation
    Connections {
        target: Jobs
        function onEnded() { boot.load() }
    }

    readonly property var rows: {
        //--- Only the generations the menu keeps: an older pick has no entry left
        const keep = boot.entries ? Number(view.valueOf(boot.entries)) : 0
        const gens = keep > 0 ? boot.generations.slice(0, keep) : boot.generations
        const out = [{number: 0, title: "Newest", subtitle: "The version the next rebuild writes"}]
        for (const g of gens)
            out.push({number: g.number, title: `Version ${g.number}`,
                      subtitle: `${g.when} · ${g.version}`})
        return out
    }

    function choose(number) {
        if (!boot.canEdit)
            return
        view.change(boot.setting, number)
        view.say(number ? `Version ${number} starts at boot after a rebuild`
                        : "The boot menu starts the newest version after a rebuild")
    }

    Section { text: "Start By Default" }
    Text {
        visible: !boot.canEdit
        text: "Only an admin who can edit the config files can change this."
        color: Theme.caution
        font.pixelSize: 13
        Layout.leftMargin: 6
    }
    Text {
        visible: !boot.loaded
        text: "Reading the versions…"
        color: Theme.dim
        font.pixelSize: 13
        Layout.leftMargin: 6
    }
    Repeater {
        model: boot.loaded ? boot.rows : []
        ListRow {
            required property var modelData
            enabled: boot.canEdit
            icon: modelData.number === 0 ? "new_releases" : "history"
            title: modelData.title
            subtitle: modelData.subtitle
            tag: JSON.stringify(modelData.number) === JSON.stringify(boot.chosen)
                ? "Starts at boot" : ""
            tagSuccess: true
            onClicked: boot.choose(modelData.number)
        }
    }
}
