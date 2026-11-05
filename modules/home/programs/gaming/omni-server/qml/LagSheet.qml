// The server's "Can't keep up!" warnings since it started, newest first
import QtQuick
import QtQuick.Layouts

Sheet {
    id: sheet
    property var app
    readonly property var stats: app ? app.stats : null
    readonly property int total: stats ? stats.lagWarnings : 0
    readonly property var events: stats && stats.lagEvents ? stats.lagEvents.slice().reverse() : []
    readonly property var worst: events.reduce((top, e) => !top || e.behindMs > top.behindMs ? e : top, null)
    title: "Lag warnings"
    info: "The server fell this far behind and skipped ticks to catch up. A warning or two as it starts is normal, since that's when it loads the most."
    onBack: app.closeSheet()

    Text {
        Layout.fillWidth: true
        Layout.topMargin: 8
        text: sheet.worst ? `${sheet.total} since the server started. Worst: ${sheet.worst.behindMs} ms behind at ${sheet.worst.time}.`
            : sheet.total ? `${sheet.total} since the server started. Details start with the next server start.`
            : "None since the server started."
        color: Theme.dim
        font.pixelSize: 14
        wrapMode: Text.Wrap
    }
    Text {
        visible: sheet.total > sheet.events.length && sheet.events.length > 0
        text: `Showing the latest ${sheet.events.length}.`
        color: Theme.dim
        font.pixelSize: 13
    }
    Repeater {
        model: sheet.events
        RowLayout {
            id: lagRow
            required property var modelData
            Layout.fillWidth: true
            spacing: 16
            Text {
                Layout.preferredWidth: 70
                text: lagRow.modelData.time
                color: Theme.text
                font.pixelSize: 14
            }
            Text {
                Layout.preferredWidth: 110
                text: `${lagRow.modelData.behindMs} ms behind`
                color: Theme.caution
                font.pixelSize: 14
            }
            Text {
                Layout.fillWidth: true
                text: `Skipped ${lagRow.modelData.ticks} tick${lagRow.modelData.ticks === 1 ? "" : "s"}`
                color: Theme.dim
                font.pixelSize: 14
            }
        }
    }
}
