// The Backups page: `nixm backup` behind buttons, the backups.* settings, what each
// run wrote and copying it back out (api.py's `backups`, `backup`, `backupRestore`)
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
    property var restored: null  // the last copy out: { title, folder, files, how }
    readonly property var settings: view.info ? view.info.backupSettings || {} : {}
    // Pending values included, so a toggle shows at once; nixm follows after a rebuild
    readonly property string wantFolder: settings.folder ? view.valueOf(settings.folder) : ""
    readonly property var skip: settings.skip ? view.valueOf(settings.skip) || [] : []
    // The saved or pending folder when it isn't where this build writes yet
    readonly property bool folderWaits: !!bk && wantFolder !== ""
        && wantFolder.replace(/^~/, bk.home).replace(/\/+$/, "") !== bk.root.replace(/\/+$/, "")
    spacing: 6

    function setSkip(name, skipped) {
        if (!settings.skip)
            return
        const others = skip.filter(n => n !== name)
        view.change(settings.skip, skipped ? others.concat([name]) : others)
    }

    function pickFolder() {
        Backend.call("pickFolder", {}, reply => {
            if (!page)
                return
            if (!reply.ok)
                view.say(reply.error)
            else if (reply.data && settings.folder)
                view.change(settings.folder, reply.data)
        })
    }

    function restore(kind, run, file) {
        Backend.call("backupRestore", { command: kind.command, host: run.host, stamp: run.stamp, file }, reply => {
            if (!page)
                return
            if (reply.ok)
                restored = reply.data
            else
                view.say(reply.error)
        })
    }

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
                spacing: 8
                Text {
                    text: page.bk ? page.bk.base.replace(/^\/home\/[^/]+/, "~") : "~/SyncBackups"
                    color: Theme.text
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    elide: Text.ElideMiddle
                    Layout.maximumWidth: hero.width
                    TitleTip {
                        tip: "Copies of app data the config can't rebuild, in dated folders here. Syncthing "
                             + "carries ~/SyncBackups to your other computers, and the newest ten of each are kept."
                    }
                }
                Item { Layout.fillWidth: true }
                OutlineButton {
                    visible: !!page.settings.folder
                    text: "Change"
                    tip: "Choose another folder. Existing backups stay where they are, and Syncthing "
                         + "only follows if you point it there."
                    onClicked: page.pickFolder()
                }
                IconButton {
                    visible: !!page.bk && page.wantFolder !== "" && page.wantFolder !== page.bk.defaultFolder
                    icon: "restart_alt"
                    tip: `Back to ${page.bk ? page.bk.defaultFolder : ""}`
                    onClicked: page.view.change(page.settings.folder, page.bk.defaultFolder)
                }
            }
            // Live alert: the page lists where this build's nixm writes
            Text {
                visible: page.folderWaits
                text: `New backups go to ${page.wantFolder} after the next rebuild`
                color: Theme.caution
                font.pixelSize: 12
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
            Pill {
                visible: !!page.bk && page.bk.kinds.some(k => page.skip.indexOf(k.name) < 0)
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
        info: "FreeTube and Zen are the apps with backups, and neither is on."
    }
    Repeater {
        model: page.bk ? page.bk.kinds : []
        KindRow { required property var modelData; kind: modelData }
    }
    ListRow {
        visible: !!page.bk && page.bk.ludusavi
        icon: "sports_esports"
        title: "Game Saves"
        info: "Ludusavi backs up to this folder too, every day. Restore them from Ludusavi."
    }

    //--- The last copy out: where it is and how to import it
    Section { visible: !!page.restored; text: "Restored Copy" }
    Rectangle {
        visible: !!page.restored
        Layout.fillWidth: true
        implicitHeight: restoredCol.implicitHeight + 20
        radius: 14
        color: Theme.card
        ColumnLayout {
            id: restoredCol
            x: 12
            y: 10
            width: parent.width - 24
            spacing: 8
            TextEdit {
                readOnly: true
                selectByMouse: true
                text: page.restored ? page.restored.folder : ""
                color: Theme.text
                selectionColor: Theme.primary
                font.family: "monospace"
                font.pixelSize: 12
                wrapMode: TextEdit.WrapAnywhere
                Layout.fillWidth: true
            }
            Text {
                text: page.restored ? page.restored.how : ""
                color: Theme.dim
                font.pixelSize: 12
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
            OutlineButton {
                text: "Open Folder"
                tip: "This copy is gone after a reboot"
                onClicked: Qt.openUrlExternally("file://" + page.restored.folder)
            }
        }
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

    //--- One backup: what it saves, when it last ran, Back Up and its folder, its runs below
    component KindRow: Rectangle {
        id: kindRow
        property var kind
        property bool open: false
        readonly property bool working: page.busy === kind.command || page.busy === "backup"
        readonly property bool skipped: page.skip.indexOf(kind.name) >= 0
        Layout.fillWidth: true
        implicitHeight: kindCol.implicitHeight + 22
        radius: 14
        color: Qt.alpha(Theme.bg, 0.55)
        border.width: 1
        border.color: Theme.rule
        ColumnLayout {
            id: kindCol
            y: 11
            x: 10
            width: parent.width - 20
            spacing: 8
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                // Green within a week of the last backup, yellow after that or before the first
                Badge {
                    icon: kindRow.working ? "progress_activity" : "save"
                    tone: kindRow.working ? "" : kindRow.kind.last && Date.now() / 1000 - kindRow.kind.last < 7 * 86400
                        ? "success" : "caution"
                    implicitWidth: 32
                    implicitHeight: 32
                }
                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true
                    opacity: kindRow.skipped ? 0.5 : 1
                    RowLayout {
                        spacing: 6
                        Layout.fillWidth: true
                        Text {
                            id: kindTitle
                            text: kindRow.kind.title
                            color: Theme.text
                            font.pixelSize: 15
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                            Layout.maximumWidth: Math.ceil(kindTitleWidth.advanceWidth) + 1
                            Layout.fillWidth: true
                            TextMetrics { id: kindTitleWidth; font: kindTitle.font; text: kindTitle.text }
                            TitleTip { tip: kindRow.kind.what }
                        }
                        Hint {
                            tip: kindRow.kind.command === "freetube-backup" && page.bk.freetubeOpen
                                ? "Close FreeTube first, so its data is all on disk." : ""
                        }
                        Item { Layout.fillWidth: true }
                    }
                    // When it last ran
                    Text {
                        text: kindRow.working ? "Backing up…"
                            : kindRow.kind.last ? `Last backed up ${Fmt.when(kindRow.kind.last).replace(/^(Today|Yesterday)/,
                                                                                                        w => w.toLowerCase())}`
                            : "Never backed up"
                        color: Theme.dim
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
                ToggleChip {
                    visible: !!page.settings.skip
                    text: "Included"
                    tip: "Whether Back Up Everything saves this app. Its old backups stay either way."
                    checked: !kindRow.skipped
                    onToggled: page.setSkip(kindRow.kind.name, !kindRow.skipped)
                }
                OutlineButton {
                    visible: !kindRow.skipped
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
                Chevron {
                    visible: kindRow.kind.runs.length > 0
                    open: kindRow.open
                    TapHandler {
                        gesturePolicy: TapHandler.ReleaseWithinBounds
                        onTapped: kindRow.open = !kindRow.open
                    }
                }
            }
            Reveal {
                id: kindReveal
                open: kindRow.open
                gap: kindCol.spacing
                Repeater {
                    model: kindReveal.shown ? kindRow.kind.runs : []
                    RunRow {
                        required property var modelData
                        kind: kindRow.kind
                        run: modelData
                    }
                }
            }
        }
    }

    //--- One dated run: when, how big, from which computer; its files below
    component RunRow: ColumnLayout {
        id: runRow
        property var kind
        property var run
        property bool open: false
        Layout.fillWidth: true
        spacing: 4
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                text: Fmt.when(runRow.run.when) + (runRow.run.host !== page.bk.host ? ` · ${runRow.run.host}` : "")
                color: Theme.text
                font.pixelSize: 13
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Text {
                text: Fmt.size(runRow.run.size)
                color: Theme.dim
                font.pixelSize: 12
            }
            OutlineButton {
                text: "Restore All"
                tip: "Copies this run to a new scratch folder to import from. Your live data isn't touched."
                onClicked: page.restore(runRow.kind, runRow.run, null)
            }
            Chevron {
                open: runRow.open
                size: 24
                TapHandler {
                    gesturePolicy: TapHandler.ReleaseWithinBounds
                    onTapped: runRow.open = !runRow.open
                }
            }
        }
        Reveal {
            id: runReveal
            open: runRow.open
            gap: runRow.spacing
            Repeater {
                model: runReveal.shown ? runRow.run.files : []
                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        text: modelData.name
                        color: Theme.dim
                        font.pixelSize: 12
                        font.family: "monospace"
                        elide: Text.ElideMiddle
                        Layout.fillWidth: true
                    }
                    Text {
                        text: Fmt.size(modelData.size)
                        color: Theme.dim
                        font.pixelSize: 12
                    }
                    OutlineButton {
                        text: "Restore"
                        tip: "Copies this file to a new scratch folder to import from. Your live data isn't touched."
                        onClicked: page.restore(runRow.kind, runRow.run, modelData.name)
                    }
                }
            }
        }
    }
}
