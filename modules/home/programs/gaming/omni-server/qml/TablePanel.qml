// An add-on's table panel: a read-only command's reply, split into rows by the backend
import QtQuick
import QtQuick.Layouts

Card {
    id: panel
    property bool active: false
    property var app
    property var addon: ({})
    property var spec: ({})
    property var rows: []
    property string raw: ""
    property bool rconOff: false
    property bool loaded: false
    readonly property bool running: !!app && app.status.active
    readonly property var columns: spec.columns || []
    title: `${addon.name}: ${spec.title || spec.id}`
    info: spec.description || ""
    headerExtras: [
        OutlineButton {
            enabled: panel.running
            text: "Read"
            tip: panel.running ? "" : "The server isn't running"
            onClicked: panel.read()
        }
    ]

    function read() {
        app.call("addon_query", { addon: addon.id, panel: spec.id }, reply => {
            panel.rconOff = !reply.rcon
            panel.rows = reply.rows || []
            panel.raw = reply.text || ""
            panel.loaded = reply.rcon
        })
    }

    Banner {
        visible: panel.rconOff
        tone: "info"
        text: "Live stats are off, so this can't show here. Its reply goes to the console instead."
        action: "Send"
        onActed: panel.app.call("addon_query", { addon: panel.addon.id, panel: panel.spec.id, console: true })
    }
    RowLayout {
        visible: panel.rows.length > 0
        Layout.fillWidth: true
        spacing: 10
        Repeater {
            model: panel.columns
            Text {
                required property var modelData
                required property int index
                Layout.fillWidth: index === 0
                Layout.preferredWidth: index === 0 ? -1 : 70
                text: modelData.title || modelData.key
                textFormat: Text.PlainText
                color: Theme.dim
                font.pixelSize: 12
            }
        }
    }
    ListView {
        id: rowList
        readonly property int rowHeight: 24
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(count, 10) * rowHeight
        visible: count > 0
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: panel.rows
        delegate: RowLayout {
            id: tableRow
            required property var modelData
            width: rowList.width
            height: rowList.rowHeight
            spacing: 10
            Repeater {
                model: panel.columns
                Text {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: index === 0
                    Layout.preferredWidth: index === 0 ? -1 : 70
                    text: tableRow.modelData[modelData.key] ?? ""
                    textFormat: Text.PlainText
                    color: Theme.text
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }
            }
        }
    }
    //--- A reply the rows pattern doesn't fit is shown as it came
    Text {
        Layout.fillWidth: true
        visible: panel.loaded && panel.rows.length === 0
        text: panel.raw || "Nothing to show."
        textFormat: Text.PlainText
        color: Theme.dim
        font.pixelSize: 13
        wrapMode: Text.Wrap
    }
}
