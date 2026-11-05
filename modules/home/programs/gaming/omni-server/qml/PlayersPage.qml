// Who's online, chat, the whitelist, ops and bans
import QtQuick
import QtQuick.Layouts

Flickable {
    id: page
    property var app
    property var info: ({ whitelistOn: false, whitelist: [], ops: [], bans: [], ipBans: [] })
    readonly property var online: app && app.stats ? app.stats.players : []
    contentHeight: col.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    function refresh() {
        if (app && app.currentId)
            app.call("players_get", {}, reply => { page.info = reply })
    }
    //--- A command's change reaches the file a moment after the server runs it
    function changed(reply) {
        if (reply.live)
            later.restart()
        else
            refresh()
    }
    function setListed(list, name, on) {
        app.call("player_set", { list, name, on }, changed)
    }
    function isOp(name) { return info.ops.some(o => o.name === name) }

    onAppChanged: refresh()
    Timer { id: later; interval: 1500; onTriggered: page.refresh() }
    Timer { interval: 10000; running: true; repeat: true; onTriggered: page.refresh() }
    Connections {
        target: page.app
        function onCurrentIdChanged() { page.refresh() }
    }

    component NameRow: RowLayout {
        id: nameRow
        required property var modelData
        default property alias extras: holder.data
        readonly property string name: modelData.name || modelData.ip || ""
        Layout.fillWidth: true
        spacing: 8
        Text {
            Layout.fillWidth: true
            text: nameRow.name
            textFormat: Text.PlainText
            color: Theme.text
            font.pixelSize: 14
            elide: Text.ElideRight
        }
        RowLayout { id: holder; spacing: 2 }
    }

    component AddBox: RowLayout {
        id: addBox
        property string list
        property string hint
        Layout.fillWidth: true
        spacing: 8
        Field {
            id: addField
            placeholder: addBox.hint
            onAccepted: addBox.submit()
        }
        OutlineButton { text: "Add"; onClicked: addBox.submit() }
        function submit() {
            const name = addField.text.trim()
            if (!name)
                return
            page.setListed(addBox.list, name, true)
            addField.text = ""
        }
    }

    ColumnLayout {
        id: col
        width: page.width
        spacing: 10

        GridLayout {
            Layout.fillWidth: true
            columns: page.app && page.app.wide ? 2 : 1
            columnSpacing: 10
            rowSpacing: 10

            Card {
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                title: page.app && page.app.stats ? `Online, ${page.online.length} of ${page.app.stats.maxPlayers}` : "Online"
                Text {
                    visible: page.online.length === 0
                    text: page.app && page.app.running ? "Nobody's on right now." : "Start the server to see who's on."
                    color: Theme.dim
                    font.pixelSize: 13
                }
                Repeater {
                    model: page.online.map(n => ({ name: n }))
                    NameRow {
                        id: row
                        Chip {
                            visible: page.isOp(row.name)
                            tappable: false
                            text: "Op"
                        }
                        IconButton {
                            icon: "chat"
                            tip: "Send a private message"
                            onClicked: page.app.askText(`Message ${row.name}`, [{ key: "text", label: "Message" }],
                                                        a => page.app.send(`tell ${row.name} ${a.text}`))
                        }
                        IconButton {
                            icon: "shield_person"
                            tip: page.isOp(row.name) ? "Remove op" : "Make op"
                            onClicked: page.setListed("ops", row.name, !page.isOp(row.name))
                        }
                        IconButton {
                            icon: "logout"
                            tip: "Kick"
                            onClicked: page.app.ask({ heading: `Kick ${row.name}?`, buttons: [{ label: "Kick", value: 1 }] },
                                                    () => page.app.send(`kick ${row.name}`))
                        }
                        IconButton {
                            icon: "block"
                            tint: Theme.error
                            tip: "Ban"
                            onClicked: page.app.ask({ heading: `Ban ${row.name}?`, buttons: [{ label: "Ban", value: 1, danger: true }] },
                                                    () => page.setListed("bans", row.name, true))
                        }
                    }
                }
            }

            Card {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 260
                title: "Chat"
                ChatView { app: page.app }
            }

            Card {
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                title: "Whitelist"
                info: "With this on, only listed players can join."
                headerExtras: Toggle {
                    checked: page.info.whitelistOn
                    tip: "Only listed players can join"
                    onToggled: on => page.app.call("whitelist_set", { on }, page.changed)
                }
                AddBox { list: "whitelist"; hint: "Add a player" }
                Repeater {
                    model: page.info.whitelist
                    NameRow {
                        id: wlRow
                        IconButton {
                            icon: "close"
                            tip: "Remove from the whitelist"
                            onClicked: page.setListed("whitelist", wlRow.name, false)
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: 10

                Card {
                    title: "Ops"
                    AddBox { list: "ops"; hint: "Add an op" }
                    Repeater {
                        model: page.info.ops
                        NameRow {
                            id: opRow
                            Text {
                                text: opRow.modelData.level !== undefined ? `Level ${opRow.modelData.level}` : ""
                                color: Theme.dim
                                font.pixelSize: 12
                            }
                            IconButton {
                                icon: "close"
                                tip: "Remove op"
                                onClicked: page.setListed("ops", opRow.name, false)
                            }
                        }
                    }
                }
                Card {
                    title: "Bans"
                    AddBox { list: "bans"; hint: "Ban a player" }
                    Text {
                        visible: page.info.bans.length === 0 && page.info.ipBans.length === 0
                        text: "Nobody's banned."
                        color: Theme.dim
                        font.pixelSize: 13
                    }
                    Repeater {
                        model: page.info.bans
                        NameRow {
                            id: banRow
                            Text {
                                text: banRow.modelData.reason || ""
                                textFormat: Text.PlainText
                                color: Theme.dim
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                Layout.maximumWidth: 180
                            }
                            IconButton {
                                icon: "close"
                                tip: "Remove the ban"
                                onClicked: page.setListed("bans", banRow.name, false)
                            }
                        }
                    }
                    Repeater {
                        model: page.info.ipBans
                        NameRow {
                            Text { text: "IP ban"; color: Theme.dim; font.pixelSize: 12 }
                        }
                    }
                }
            }
        }
    }
}
