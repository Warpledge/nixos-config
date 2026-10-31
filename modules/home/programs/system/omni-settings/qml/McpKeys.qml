// API Keys, under MCP Servers on the Claude Tools page: whether each keyed server's
// owner-only file in ~/.nixos-config-mcp holds a key (api.py's mcpKeys), and a
// field that writes a new one (setMcpKey, through stdin only). A saved key is
// never read back or shown.
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: keys
    required property var view
    property var found: null  // [{server, title, set}]
    property string editing: ""  // the server whose field is open
    spacing: 6

    Component.onCompleted: load()
    function load() {
        Backend.call("mcpKeys", {}, reply => {
            if (keys)
                found = reply.ok ? reply.data : []
        })
    }

    function save(server, key) {
        Backend.callPrivate("setMcpKey", { server, key }, reply => {
            if (!keys)
                return
            view.say(reply.ok ? (key ? "Key saved. Restart Claude Code or OpenCode to use it"
                                     : "Key cleared") : reply.error)
            if (reply.ok)
                editing = ""
            load()
        })
    }

    Section {
        visible: !!keys.found && keys.found.length > 0
        text: "API Keys"
        info: "Each is saved to its own file in ~/.nixos-config-mcp that only you can read, "
              + "never the repo. A saved key isn't shown again."
        Layout.fillWidth: true
    }
    Repeater {
        model: keys.found || []
        ColumnLayout {
            id: keyRow
            required property var modelData
            readonly property bool open: keys.editing === modelData.server
            spacing: 6
            Layout.fillWidth: true
            ListRow {
                icon: "key"
                title: keyRow.modelData.title
                value: keyRow.modelData.set ? "Set" : "Not set"
                tone: keyRow.modelData.set ? "" : "caution"
                expandable: true
                expanded: keyRow.open
                Layout.fillWidth: true
                onClicked: {
                    keys.editing = keyRow.open ? "" : keyRow.modelData.server
                    keyField.text = ""
                }
            }
            Reveal {
                open: keyRow.open
                gap: keyRow.spacing
                RowLayout {
                    spacing: 8
                    Layout.fillWidth: true
                    Field {
                        id: keyField
                        placeholder: keyRow.modelData.set ? "Paste a new key to replace it" : "Paste the key"
                        icon: "key"
                        input.echoMode: TextInput.Password
                        Layout.fillWidth: true
                        onAccepted: if (text.trim()) keys.save(keyRow.modelData.server, text)
                        onEscaped: keys.editing = ""
                    }
                    Pill {
                        text: "Save"
                        enabled: keyField.text.trim() !== ""
                        onClicked: keys.save(keyRow.modelData.server, keyField.text)
                    }
                    Pill {
                        visible: keyRow.modelData.set
                        text: "Clear"
                        danger: true
                        onClicked: keys.view.ask({ heading: `Clear the ${keyRow.modelData.title} key?`,
                                                   body: "Its MCP server stops working until a new key is saved.",
                                                   buttons: [{ label: "Clear", value: true }] },
                                                 () => keys.save(keyRow.modelData.server, ""))
                    }
                }
            }
        }
    }
}
