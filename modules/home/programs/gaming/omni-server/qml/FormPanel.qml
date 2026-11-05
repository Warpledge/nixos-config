// An add-on's form panel: typed fields, buttons that send a command, and a live status
import QtQuick
import QtQuick.Layouts

Card {
    id: panel
    property bool active: false
    property var app
    property var addon: ({})
    property var spec: ({})
    property string statusText: ""
    property string statusError: ""
    property bool rconOff: false
    readonly property bool running: !!app && app.status.active
    title: `${addon.name}: ${spec.title || spec.id}`
    info: spec.description || ""

    function values() {
        const found = {}
        for (let i = 0; i < inputs.count; i++) {
            const row = inputs.itemAt(i)
            found[row.modelData.id] = row.value
        }
        return found
    }
    function run(action) {
        const send = () => app.call("addon_action", {
            addon: addon.id, panel: spec.id, action: action.label, values: values()
        }, readStatus)
        if (action.confirm)
            app.ask({ heading: `${action.label}: ${spec.title || spec.id}?`, body: addon.name,
                      buttons: [{ label: action.label, value: 1 }] }, send)
        else
            send()
    }
    //--- Polled, so a failure shows on the panel instead of a toast every few seconds
    function readStatus() {
        if (!active || !spec.status || !running)
            return
        Backend.call("addon_query", { id: app.currentId, addon: addon.id, panel: spec.id }, reply => {
            panel.statusError = reply.ok ? "" : reply.error
            if (reply.ok) {
                panel.rconOff = !reply.rcon
                panel.statusText = reply.text || ""
            }
        })
    }

    onActiveChanged: readStatus()
    Component.onCompleted: readStatus()
    Timer {
        interval: 5000
        repeat: true
        running: panel.active && panel.running && !!panel.spec.status && !panel.rconOff
        onTriggered: panel.readStatus()
    }

    Flow {
        Layout.fillWidth: true
        spacing: 8
        Repeater {
            id: inputs
            model: panel.spec.fields || []
            ColumnLayout {
                id: fieldRow
                required property var modelData
                readonly property bool isChoice: modelData.type === "choice"
                property string picked: String(modelData.default ?? "")
                readonly property string value: isChoice ? picked : box.text
                //--- The numeric ids a server's own poll named, for fields that take one
                readonly property var matches: {
                    const dims = panel.app && panel.app.stats ? panel.app.stats.dims || [] : []
                    const typed = box.text.toLowerCase()
                    if (!modelData.suggest || !box.input.activeFocus)
                        return []
                    return dims.filter(d => String(d.name).toLowerCase().includes(typed)
                                            || String(d.id) === typed).slice(0, 6)
                }
                spacing: 4
                Text {
                    text: fieldRow.modelData.label || fieldRow.modelData.id
                    textFormat: Text.PlainText
                    color: Theme.dim
                    font.pixelSize: 12
                }
                Field {
                    id: box
                    visible: !fieldRow.isChoice
                    Layout.preferredWidth: fieldRow.modelData.type === "int" ? 110 : 220
                    implicitHeight: 32
                    Component.onCompleted: text = String(fieldRow.modelData.default ?? "")
                }
                Segmented {
                    visible: fieldRow.isChoice
                    options: fieldRow.modelData.options || []
                    current: fieldRow.picked
                    onPicked: value => { fieldRow.picked = String(value) }
                }
                Repeater {
                    model: fieldRow.matches
                    OutlineButton {
                        required property var modelData
                        text: `${modelData.name} (${modelData.id})`
                        onClicked: box.text = String(modelData.id)
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Repeater {
            model: panel.spec.actions || []
            OutlineButton {
                required property var modelData
                text: modelData.label
                onClicked: panel.run(modelData)
            }
        }
        Text {
            Layout.fillWidth: true
            visible: !!panel.spec.status
            text: !panel.running ? "The server isn't running"
                : panel.statusError || (panel.rconOff ? "" : panel.statusText)
            textFormat: Text.PlainText
            color: panel.statusError ? Theme.toneColor("error") : Theme.dim
            font.pixelSize: 13
            wrapMode: Text.Wrap
        }
    }

    Banner {
        visible: panel.rconOff && panel.running
        tone: "info"
        text: "Live stats are off, so the status can't show here. Its reply goes to the console instead."
        action: "Send"
        onActed: panel.app.call("addon_query", { addon: panel.addon.id, panel: panel.spec.id, console: true })
    }
}
