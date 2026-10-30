// Crashes from systemd-coredump (api.py's crashes), each with a button that
// copies a report for troubleshooting. Shared by the Maintenance page
// (OverviewPage.qml) and, for one game's crashes, GameEditor.qml.
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: list
    required property var view
    property string app: ""  // one Steam game's crashes only
    property string launch: ""  // that game's launch options as edited, for the report
    property bool quiet: false  // no row of its own saying nothing crashed
    property var crashes: null
    property string error: ""
    readonly property bool ready: !!crashes || error !== ""
    spacing: 6

    Component.onCompleted: load()
    function load() {
        Backend.call("crashes", { app }, reply => {
            if (!list)
                return
            if (reply.ok)
                list.crashes = reply.data
            else
                list.error = reply.error
        })
    }

    function copy(c) {
        Backend.call("crashReport", { pid: c.pid, app: c.app, launch: c.app === list.app ? list.launch : "" },
                     reply => {
            if (!reply.ok) {
                list.view.say(`Couldn't make the report: ${reply.error}`)
                return
            }
            Quickshell.clipboardText = reply.data
            list.view.say(`Copied the report on ${c.name}`)
        })
    }

    ListRow {
        visible: list.error !== "" || (!list.quiet && !!list.crashes && !list.crashes.length)
        icon: "check_circle"
        title: list.error ? "Couldn't read the crashes" : list.app ? "No crashes in the last 30 days"
                                                                   : "Nothing crashed in the last 30 days"
        alert: list.error
    }
    Repeater {
        model: list.crashes || []
        ListRow {
            required property var modelData
            icon: modelData.game ? "sports_esports" : "bug_report"
            title: modelData.name
            subtitle: `${modelData.when} · ${modelData.signal}${modelData.game && !list.app ? " · game" : ""}`
            info: modelData.exe
            button: "Copy for Troubleshooting"
            onClicked: list.copy(modelData)
        }
    }
}
