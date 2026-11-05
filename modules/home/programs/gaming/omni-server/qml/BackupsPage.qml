// World backups: list, make, restore
import QtQuick
import QtQuick.Layouts

Flickable {
    id: page
    property var app
    property var info: ({ backups: [], liveBackup: "", setAside: [] })
    property string progress: ""
    property bool busy: false
    readonly property real total: info.backups.reduce((sum, b) => sum + b.size, 0)
    contentHeight: col.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    function refresh() {
        if (app && app.currentId)
            app.call("backups_get", {}, reply => { page.info = reply })
    }
    function longJob(cmd, args, finished) {
        busy = true
        progress = "Starting"
        Backend.stream(cmd, Object.assign({ id: app.currentId }, args), line => { page.progress = line }, reply => {
            page.busy = false
            page.progress = ""
            if (!reply.ok)
                page.app.showError(reply.error)
            else if (finished)
                finished(reply)
            page.refresh()
        })
    }
    function backUp() {
        longJob("backup_create", {}, reply => {
            //--- The mod writes the zip itself, a little after it's asked
            if (reply.via === "addon")
                later.restart()
        })
    }
    function restore(name) {
        app.ask({
            heading: `Restore ${name}?`,
            body: "The current world is moved aside, not deleted, and listed here afterwards.",
            buttons: [{ label: "Restore", value: 1 }]
        }, () => longJob("backup_restore", { name }))
    }

    onAppChanged: refresh()
    Timer { id: later; interval: 15000; onTriggered: page.refresh() }
    Connections {
        target: page.app
        function onCurrentIdChanged() { page.refresh() }
    }

    ColumnLayout {
        id: col
        width: page.width
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                Layout.fillWidth: true
                text: `${page.info.backups.length} backup${page.info.backups.length === 1 ? "" : "s"}, ${Fmt.size(page.total)}`
                    + (page.info.liveBackup ? `, made with ${page.info.liveBackup} while running` : "")
                color: Theme.dim
                font.pixelSize: 13
            }
            OutlineButton {
                filled: true
                enabled: !page.busy
                text: "Back up now"
                onClicked: page.backUp()
            }
        }
        Banner {
            visible: page.busy
            tone: "info"
            icon: "hourglass_top"
            text: page.progress
        }
        Card {
            visible: page.info.backups.length > 0
            Repeater {
                model: page.info.backups
                RowLayout {
                    id: backupRow
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        Layout.fillWidth: true
                        text: Fmt.when(backupRow.modelData.time)
                        color: Theme.text
                        font.pixelSize: 14
                    }
                    Text {
                        text: Fmt.size(backupRow.modelData.size)
                        color: Theme.dim
                        font.pixelSize: 13
                    }
                    OutlineButton {
                        enabled: !page.busy && !(page.app && page.app.running)
                        text: "Restore"
                        tip: page.app && page.app.running ? "Stop the server to restore" : ""
                        onClicked: page.restore(backupRow.modelData.name)
                    }
                    IconButton {
                        icon: "delete"
                        tip: "Delete this backup"
                        onClicked: page.app.ask({
                            heading: `Delete ${backupRow.modelData.name}?`,
                            body: "This can't be undone.",
                            buttons: [{ label: "Delete", value: 1, danger: true }]
                        }, () => page.app.call("backup_delete", { name: backupRow.modelData.name }, page.refresh))
                    }
                }
            }
        }
        Card {
            visible: page.info.setAside.length > 0
            title: "Worlds moved aside by a restore"
            Repeater {
                model: page.info.setAside
                RowLayout {
                    id: asideRow
                    required property string modelData
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: asideRow.modelData
                        textFormat: Text.PlainText
                        color: Theme.text
                        font.pixelSize: 14
                        elide: Text.ElideRight
                    }
                    IconButton {
                        icon: "delete"
                        tip: "Delete this world"
                        onClicked: page.app.ask({
                            heading: `Delete ${asideRow.modelData}?`,
                            body: "This world is gone for good afterwards.",
                            buttons: [{ label: "Delete", value: 1, danger: true }]
                        }, () => page.app.call("set_aside_delete", { name: asideRow.modelData }, page.refresh))
                    }
                }
            }
        }
    }
}
