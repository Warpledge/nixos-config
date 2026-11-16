// World backups: list, make, restore
import QtQuick
import QtQuick.Layouts

Flickable {
    id: page
    property var app
    property var info: ({ backups: [], liveBackup: "", setAside: [] })
    property string progress: ""
    property bool busy: false
    property var disk: null  // {free, total} of the drive the server's folder is on
    readonly property real total: info.backups.reduce((sum, b) => sum + b.size, 0)
    readonly property real largest: info.backups.reduce((most, b) => Math.max(most, b.size), 0)
    readonly property var newest: info.backups.reduce((n, b) => !n || b.time > n.time ? b : n, null)
    //--- Short on room: under a tenth free, or not enough for two more of the newest
    readonly property bool tight: !!disk && (disk.free < disk.total * 0.1
                                            || (!!newest && disk.free < newest.size * 2))
    contentHeight: col.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    function refresh() {
        if (!app || !app.currentId)
            return
        app.call("backups_get", {}, reply => { page.info = reply })
        app.call("disk", {}, reply => { page.disk = reply })
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
            if (reply.via === "addon") {
                later.restart()
                page.app.toast("Asked the server to back up; it shows here once written", "info")
            } else {
                page.app.toast("Backup made", "success")
            }
        })
    }
    function restore(name) {
        app.ask({
            heading: `Restore ${name}?`,
            body: "The current world is moved aside, not deleted, and listed here afterwards.",
            buttons: [{ label: "Restore", value: 1 }]
        }, () => longJob("backup_restore", { name }, () => page.app.toast(`Restored ${name}`, "success")))
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
        Banner {
            visible: page.tight && !page.busy
            icon: "warning"
            text: page.disk ? `Only ${Fmt.size(page.disk.free)} free on this drive. Delete old backups before the next one fails.` : ""
        }

        //--- The drive the server and its backups are on
        Card {
            visible: !!page.disk
            title: "Disk"
            info: "The drive holding the server's folder, where backups/ goes."
            headerExtras: Text {
                text: page.disk ? `${Fmt.size(page.disk.free)} free of ${Fmt.size(page.disk.total)}` : ""
                color: page.tight ? Theme.caution : Theme.dim
                font.pixelSize: 13
            }
            Rectangle {
                id: diskBar
                readonly property real used: page.disk && page.disk.total ? 1 - page.disk.free / page.disk.total : 0
                readonly property real backups: page.disk && page.disk.total ? page.total / page.disk.total : 0
                Layout.fillWidth: true
                implicitHeight: 10
                radius: 5
                color: Qt.alpha(Theme.bg, 0.55)
                //--- Everything used, then the backups' share of it in primary
                Rectangle {
                    height: parent.height
                    radius: 5
                    width: parent.width * Math.min(1, diskBar.used)
                    color: Qt.alpha(Theme.loadColor(diskBar.used), 0.45)
                    Behavior on width { NumberAnimation { duration: Theme.ms(600); easing.type: Easing.OutCubic } }
                }
                Rectangle {
                    height: parent.height
                    radius: 5
                    width: parent.width * Math.min(1, diskBar.backups)
                    color: Theme.loadColor(diskBar.used)
                    Behavior on width { NumberAnimation { duration: Theme.ms(600); easing.type: Easing.OutCubic } }
                }
            }
            RowLayout {
                spacing: 14
                Repeater {
                    model: [{ label: "Backups", strong: true }, { label: "Everything else", strong: false }]
                    Row {
                        required property var modelData
                        spacing: 6
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 8
                            height: 8
                            radius: 4
                            color: parent.modelData.strong ? Theme.loadColor(diskBar.used)
                                : Qt.alpha(Theme.loadColor(diskBar.used), 0.45)
                        }
                        Text { text: parent.modelData.label; color: Theme.dim; font.pixelSize: 12 }
                    }
                }
            }
        }

        Card {
            visible: page.info.backups.length > 0
            title: "Backups"
            Repeater {
                model: page.info.backups
                RowLayout {
                    id: backupRow
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        text: Fmt.when(backupRow.modelData.time)
                        color: Theme.text
                        font.pixelSize: 14
                    }
                    Chip {
                        visible: !!page.newest && page.newest.name === backupRow.modelData.name
                        tappable: false
                        tone: "success"
                        text: "Newest"
                    }
                    //--- Its size beside the largest backup's
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 40
                        implicitHeight: 4
                        radius: 2
                        color: Qt.alpha(Theme.bg, 0.55)
                        Rectangle {
                            height: parent.height
                            radius: 2
                            width: page.largest ? parent.width * backupRow.modelData.size / page.largest : 0
                            color: Qt.alpha(Theme.primary, 0.7)
                            Behavior on width { NumberAnimation { duration: Theme.ms(500); easing.type: Easing.OutCubic } }
                        }
                    }
                    Text {
                        Layout.preferredWidth: 64
                        horizontalAlignment: Text.AlignRight
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
                        }, () => page.app.call("backup_delete", { name: backupRow.modelData.name }, () => {
                            page.app.toast("Backup deleted", "success")
                            page.refresh()
                        }))
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
