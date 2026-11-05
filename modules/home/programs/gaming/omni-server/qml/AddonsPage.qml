// The server's add-ons: which are on, and the panels of those that are
import QtQuick
import QtQuick.Layouts

Flickable {
    id: page
    property var app
    property var addons: []
    readonly property var active: addons.filter(a => a.on)
    contentHeight: col.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    function refresh() {
        if (app && app.currentId)
            app.call("addons_get", {}, reply => { page.addons = reply.addons })
    }
    function open() {
        refresh()
        if (app && app.currentId)
            app.call("addons_seen", {}, () => app.refreshServer())
    }
    function setOn(addon, on) {
        app.call("addon_set", { addon, on }, reply => {
            app.quick = reply.quick
            page.refresh()
        })
    }
    function importAddon() {
        app.call("addon_pick", {}, picked => {
            if (!picked.dir)
                return
            if (picked.problems.length) {
                app.ask({ heading: `Can't import ${picked.name}`, body: picked.problems.join("\n"),
                          buttons: [{ label: "OK", value: 1 }], cancel: false }, () => {})
                return
            }
            const sends = picked.commands.length ? picked.commands.join("\n") : "Nothing."
            app.ask({ heading: `Import ${picked.name}?`,
                      body: `This add-on can send these commands to a server you turn it on for:\n\n${sends}`,
                      buttons: [{ label: "Import", value: 1 }] },
                    () => app.call("addon_import", { dir: picked.dir }, page.refresh))
        })
    }
    function applySetting(key, value) {
        const changes = {}
        changes[key] = value
        app.call("properties_set", { changes }, refresh)
    }

    onAppChanged: open()
    Connections {
        target: page.app
        function onCurrentIdChanged() { page.open() }
    }

    ColumnLayout {
        id: col
        width: page.width
        spacing: 10

        Card {
            title: "This server"
            info: "Add-ons are tools for what a server runs. They're data only, and never download anything."
            headerExtras: [
                OutlineButton {
                    text: "Import"
                    tip: "Add an add-on from a folder holding an addon.json"
                    onClicked: page.importAddon()
                }
            ]
            Repeater {
                model: page.addons
                RowLayout {
                    id: addonRow
                    required property var modelData
                    readonly property bool bad: modelData.problems.length > 0
                    Layout.fillWidth: true
                    spacing: 10
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            Layout.fillWidth: true
                            text: addonRow.modelData.name + (addonRow.modelData.local ? " (imported)" : "")
                            textFormat: Text.PlainText
                            color: Theme.text
                            font.pixelSize: 14
                            elide: Text.ElideRight
                            TitleTip { tip: addonRow.modelData.description }
                        }
                        //--- Only what's in the way shows under a name (Omni Settings' CLAUDE.md)
                        Text {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: addonRow.bad ? addonRow.modelData.problems.join("; ")
                                : addonRow.modelData.needs.length ? `Needs ${addonRow.modelData.needs.join(", ")}` : ""
                            textFormat: Text.PlainText
                            color: addonRow.bad ? Theme.toneColor("error") : Theme.dim
                            font.pixelSize: 12
                            wrapMode: Text.Wrap
                        }
                    }
                    Repeater {
                        model: addonRow.modelData.needs.length && !addonRow.bad ? addonRow.modelData.suggests : []
                        OutlineButton {
                            required property var modelData
                            text: "Get mod"
                            tip: `Opens ${modelData.name}'s page. Add the jar on the Mods tab.`
                            onClicked: Qt.openUrlExternally(modelData.url)
                        }
                    }
                    Toggle {
                        visible: !addonRow.bad && !addonRow.modelData.needs.length
                        checked: addonRow.modelData.on
                        onToggled: on => page.setOn(addonRow.modelData.id, on)
                    }
                }
            }
            Text {
                visible: page.addons.length === 0
                text: "No add-ons found."
                color: Theme.dim
                font.pixelSize: 13
            }
        }

        Repeater {
            model: page.active
            ColumnLayout {
                id: group
                required property var modelData
                Layout.fillWidth: true
                spacing: 10

                Card {
                    visible: group.modelData.settings.length > 0
                    title: `${group.modelData.name}: recommended settings`
                    Repeater {
                        model: group.modelData.settings
                        RowLayout {
                            id: settingRow
                            required property var modelData
                            readonly property bool applied: modelData.current === String(modelData.value)
                            Layout.fillWidth: true
                            spacing: 10
                            Text {
                                Layout.fillWidth: true
                                text: `${settingRow.modelData.key} = ${settingRow.modelData.value}`
                                textFormat: Text.PlainText
                                color: Theme.text
                                font.pixelSize: 13
                                elide: Text.ElideRight
                                TitleTip { tip: settingRow.modelData.why || "" }
                            }
                            OutlineButton {
                                visible: !settingRow.applied
                                text: "Apply"
                                onClicked: page.applySetting(settingRow.modelData.key, settingRow.modelData.value)
                            }
                            Chip {
                                visible: settingRow.applied
                                tone: "success"
                                text: "Set"
                            }
                        }
                    }
                }

                Repeater {
                    model: group.modelData.panels
                    ColumnLayout {
                        id: slot
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 0
                        Card {
                            visible: slot.modelData.needs.length > 0
                            title: `${group.modelData.name}: ${slot.modelData.title || slot.modelData.id}`
                            Text {
                                Layout.fillWidth: true
                                text: `Needs ${slot.modelData.needs.join(", ")}`
                                textFormat: Text.PlainText
                                color: Theme.dim
                                font.pixelSize: 13
                                wrapMode: Text.Wrap
                            }
                        }
                        FormPanel {
                            visible: active
                            active: slot.modelData.type === "form" && slot.modelData.needs.length === 0
                            app: page.app
                            addon: group.modelData
                            spec: slot.modelData
                        }
                        TablePanel {
                            visible: active
                            active: slot.modelData.type === "table" && slot.modelData.needs.length === 0
                            app: page.app
                            addon: group.modelData
                            spec: slot.modelData
                        }
                    }
                }
            }
        }
    }
}
