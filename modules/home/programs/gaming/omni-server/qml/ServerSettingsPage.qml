// server.properties as a form, and how this app starts the server
import QtQuick
import QtQuick.Layouts

Flickable {
    id: page
    property var app
    property var data_: null  // settings_get
    readonly property var startup: data_ ? data_.startup : ({})
    contentHeight: col.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    function refresh() {
        if (app && app.currentId)
            app.call("settings_get", {}, reply => { page.data_ = reply })
    }
    function setProperty(key, value) {
        const changes = {}
        changes[key] = value
        app.call("properties_set", { changes }, refresh)
    }
    function setStartup(key, value) {
        const changes = {}
        changes[key] = value
        app.call("startup_set", { changes }, refresh)
    }

    onAppChanged: refresh()
    Connections {
        target: page.app
        function onCurrentIdChanged() { page.refresh() }
    }

    component Row_: RowLayout {
        id: formRow
        property string label
        property string info: ""
        default property alias control: slot.data
        Layout.fillWidth: true
        Layout.minimumHeight: 34
        spacing: 10
        Text {
            Layout.fillWidth: true
            text: formRow.label
            textFormat: Text.PlainText
            color: Theme.text
            font.pixelSize: 14
            elide: Text.ElideRight
            TitleTip { tip: formRow.info }
        }
        RowLayout { id: slot; spacing: 6 }
    }

    component TextBox: Field {
        id: box
        property string saved
        property bool numeric: false
        signal commit(string value)
        Layout.fillWidth: false
        Layout.preferredWidth: numeric ? 110 : 300
        implicitHeight: 32
        onSavedChanged: text = saved
        Component.onCompleted: text = saved
        onAccepted: input.focus = false
        Connections {
            target: box.input
            function onEditingFinished() {
                if (box.text !== box.saved)
                    box.commit(box.text)
            }
        }
    }

    ColumnLayout {
        id: col
        width: page.width
        spacing: 10

        Banner {
            visible: !!page.data_ && !page.data_.eula
            icon: "gavel"
            text: "This server needs Minecraft's EULA accepted before it can start (aka.ms/MinecraftEULA)."
            action: "Accept"
            onActed: page.app.call("eula_accept", {}, page.refresh)
        }
        Banner {
            visible: !!page.data_ && page.data_.pending.length > 0
            icon: "schedule"
            text: page.data_ ? `${page.data_.pending.length} change${page.data_.pending.length > 1 ? "s" : ""} apply at the next start: ${page.data_.pending.join(", ")}` : ""
            action: page.app && page.app.state_ === "running" ? "Restart now" : ""
            onActed: page.app.restart()
        }
        Banner {
            visible: !!page.data_ && !page.data_.exists
            tone: "info"
            text: "The server writes server.properties the first time it starts. These settings show up after that."
        }

        GridLayout {
            Layout.fillWidth: true
            columns: page.app && page.app.wide ? 2 : 1
            columnSpacing: 10
            rowSpacing: 10

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: 10

                Card {
                    title: "Startup"
                    info: "How Omni Server launches this server. Changes apply at the next start."
                    Row_ {
                        label: "Java"
                        Segmented {
                            options: (page.data_ ? page.data_.javas : []).map(j => ({ value: j, label: j }))
                            current: page.startup.java
                            onPicked: value => page.setStartup("java", value)
                        }
                    }
                    Row_ {
                        label: "Heap"
                        info: "Memory the JVM reserves up front. Modded servers usually want 6 to 12 GB."
                        HeapSlider {
                            Layout.preferredWidth: 220
                            value: page.startup.heapMb || 4096
                            maximum: page.data_ ? page.data_.memoryMb : 16384
                            onPicked: value => page.setStartup("heapMb", value)
                        }
                    }
                    Row_ {
                        label: "JVM flags"
                        info: "G1 is the garbage collector tuning modded servers commonly use."
                        Segmented {
                            options: [{ value: "g1", label: "G1 tuned" }, { value: "none", label: "None" }]
                            current: page.startup.preset
                            onPicked: value => page.setStartup("preset", value)
                        }
                    }
                    Row_ {
                        label: "Extra flags"
                        TextBox {
                            placeholder: "-Duser.language=en"
                            saved: page.startup.extraFlags || ""
                            onCommit: value => page.setStartup("extraFlags", value)
                        }
                    }
                    Row_ {
                        label: "Minecraft version"
                        info: "Add-ons check this. It's read from the server's folder; set it here if that found nothing."
                        TextBox {
                            saved: page.startup.minecraft || ""
                            onCommit: value => page.setStartup("minecraft", value)
                        }
                    }
                    Row_ {
                        label: "Launch target"
                        info: page.data_ ? `Detected: ${page.data_.detected.label}, ${page.data_.detected.launch || "none"}` : ""
                        TextBox {
                            saved: page.startup.launch || ""
                            onCommit: value => page.setStartup("launch", value)
                        }
                    }
                    Row_ {
                        label: "Custom command"
                        info: "Replaces all of the above. A script with its own restart loop stops Stop from working."
                        TextBox {
                            placeholder: "Leave empty"
                            saved: page.startup.command || ""
                            onCommit: value => page.setStartup("command", value)
                        }
                    }
                    Row_ {
                        label: "Restart on crash"
                        info: "Waits 12 s between tries, and gives up after 5 crashes in 10 minutes."
                        Toggle {
                            checked: !!page.startup.restartOnCrash
                            onToggled: on => page.setStartup("restartOnCrash", on)
                        }
                    }
                    Row_ {
                        label: "Start at boot"
                        Toggle {
                            checked: !!page.data_ && page.data_.boot
                            onToggled: on => page.app.call("boot_set", { on }, page.refresh)
                        }
                    }
                    Row_ {
                        label: "Live stats (RCON)"
                        info: "Polls TPS and players silently, keeping them out of the log. Sets a generated password in server.properties. RCON listens on every network interface, so keep its port closed in your firewall."
                        Toggle {
                            checked: !!page.data_ && page.data_.rcon
                            onToggled: on => page.app.call("rcon_set", { on }, page.refresh)
                        }
                    }
                }

                Card {
                    title: "This server"
                    Text {
                        Layout.fillWidth: true
                        text: page.app && page.app.server ? page.app.server.dir : ""
                        textFormat: Text.PlainText
                        color: Theme.dim
                        font.pixelSize: 13
                        wrapMode: Text.WrapAnywhere
                    }
                    RowLayout {
                        Item { Layout.fillWidth: true }
                        OutlineButton {
                            tint: Theme.error
                            text: "Remove from Omni Server"
                            tip: "The server's folder stays as it is. Its stat history and quick commands are deleted."
                            onClicked: page.app.ask({
                                heading: `Remove ${page.app.server.name}?`,
                                body: "The server's folder stays as it is. Its stat history and quick commands are deleted.",
                                buttons: [{ label: "Remove", value: 1, danger: true }]
                            }, () => page.app.call("remove", {}, () => {
                                page.app.select("")
                                page.app.refreshServers()
                            }))
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: 10

                Repeater {
                    model: page.data_ ? page.data_.groups : []
                    Card {
                        id: group
                        required property var modelData
                        title: modelData.title
                        Repeater {
                            model: group.modelData.rows
                            Row_ {
                                id: propRow
                                required property var modelData
                                label: modelData.label
                                info: modelData.key
                                Toggle {
                                    visible: propRow.modelData.kind === "bool"
                                    checked: propRow.modelData.value === "true"
                                    onToggled: on => page.setProperty(propRow.modelData.key, on ? "true" : "false")
                                }
                                Segmented {
                                    visible: propRow.modelData.kind === "choice"
                                    options: propRow.modelData.choices || []
                                    current: propRow.modelData.value
                                    onPicked: value => page.setProperty(propRow.modelData.key, value)
                                }
                                TextBox {
                                    visible: propRow.modelData.kind === "text" || propRow.modelData.kind === "int"
                                    numeric: propRow.modelData.kind === "int"
                                    saved: propRow.modelData.value
                                    onCommit: value => page.setProperty(propRow.modelData.key, value)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
