// The Backups page: `nixm backup` behind buttons (api.py's `backups` and `backup`)
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var view
    property var bk: null
    property string error: ""
    readonly property bool ready: !!bk || error !== ""
    property string busy: ""  // the nixm command running, "backup" for everything
    property var last: null  // the last run: { title, ok, output }
    spacing: 6

    function load() {
        Backend.call("backups", {}, reply => {
            if (!page)
                return  // the tab was left before the reply came
            if (reply.ok) {
                bk = reply.data
                error = ""
            } else {
                error = reply.error
            }
        })
    }

    Component.onCompleted: load()

    function run(command, title) {
        if (!bk.nixm) {
            view.say("nixm isn't installed")
            return
        }
        busy = command
        Backend.call("backup", { command }, reply => {
            busy = ""
            const ok = reply.ok && reply.data.ok
            last = { title, ok, output: reply.ok ? reply.data.output || "(no output)" : reply.error }
            view.say(ok ? `${title} backed up` : `${title}: the backup didn't finish; see below`)
            load()
        })
    }

    //--- Hero
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: hero.implicitHeight + 28
        radius: 16
        color: Theme.card
        ColumnLayout {
            id: hero
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10
            RowLayout {
                spacing: 14
                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true
                    Text {
                        text: "Copies of app data the config can't rebuild, in dated folders under "
                              + (page.bk ? page.bk.base.replace(/^\/home\/[^/]+/, "~") : "~/SyncBackups")
                              + ". Syncthing carries them to your other computers, and the newest ten of each "
                              + "are kept."
                        color: Theme.dim
                        font.pixelSize: 13
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
            }
            Pill {
                visible: !!page.bk && page.bk.kinds.length > 0
                Layout.alignment: Qt.AlignHCenter
                enabled: page.busy === ""
                text: page.busy === "backup" ? "Backing Up…" : "Back Up Everything"
                onClicked: page.run("backup", "Everything")
            }
        }
    }

    Text {
        visible: page.error !== ""
        text: page.error
        color: Theme.error
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        Layout.margins: 6
    }
    Text {
        visible: !page.bk && !page.error
        text: "Loading…"
        color: Theme.dim
        Layout.margins: 6
    }

    //--- What's backed up
    Section { visible: !!page.bk; text: "What's Backed Up" }
    ListRow {
        visible: !!page.bk && !page.bk.kinds.length
        icon: "backup"
        title: "Nothing to back up"
        subtitle: "FreeTube and Zen are the apps with backups, and neither is on."
    }
    Repeater {
        model: page.bk ? page.bk.kinds : []
        KindRow { required property var modelData; kind: modelData }
    }

    //--- What the last run printed
    Section { visible: !!page.last; text: "Last Run" }
    Rectangle {
        visible: !!page.last
        Layout.fillWidth: true
        implicitHeight: outText.implicitHeight + 20
        radius: 14
        color: page.last && !page.last.ok ? Theme.toneFill("error", Theme.card) : Theme.card
        TextEdit {
            id: outText
            x: 12
            y: 10
            width: parent.width - 24
            readOnly: true
            selectByMouse: true
            text: page.last ? page.last.output : ""
            color: page.last && !page.last.ok ? Theme.error : Theme.dim
            selectionColor: Theme.primary
            font.family: "monospace"
            font.pixelSize: 12
            wrapMode: TextEdit.WrapAnywhere
        }
    }

    //--- One backup: what it saves, when it last ran, Back Up and its folder
    component KindRow: Rectangle {
        id: kindRow
        property var kind
        readonly property bool working: page.busy === kind.command || page.busy === "backup"
        Layout.fillWidth: true
        implicitHeight: kindLayout.implicitHeight + 22
        radius: 14
        color: Theme.card
        RowLayout {
            id: kindLayout
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 10
            anchors.rightMargin: 12
            spacing: 10
            // Green within a week of the last backup, yellow after that or before the first
            Badge {
                icon: kindRow.working ? "progress_activity" : "save"
                tone: kindRow.working ? "" : kindRow.kind.last && Date.now() / 1000 - kindRow.kind.last < 7 * 86400
                    ? "success" : "caution"
            }
            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true
                Text {
                    text: kindRow.kind.title
                    color: Theme.text
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: kindRow.kind.what + "\n" + (kindRow.working ? "Backing up…"
                        : kindRow.kind.last ? `Last backed up ${Fmt.when(kindRow.kind.last).toLowerCase()}`
                        : "Not backed up yet")
                    color: Theme.dim
                    font.pixelSize: 13
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
                Text {
                    visible: kindRow.kind.command === "freetube-backup" && page.bk.freetubeOpen
                    text: "Close FreeTube first, so its data is all on disk."
                    color: Theme.caution
                    font.pixelSize: 13
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
            Pill {
                enabled: page.busy === ""
                text: "Back Up"
                onClicked: page.run(kindRow.kind.command, kindRow.kind.title)
            }
            IconButton {
                icon: "folder_open"
                tip: "Open the backups folder"
                onClicked: kindRow.kind.exists ? Qt.openUrlExternally("file://" + kindRow.kind.folder)
                                               : page.view.say("No backups yet")
            }
        }
    }
}
