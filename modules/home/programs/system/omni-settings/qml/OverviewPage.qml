// The Overview: what this computer runs, updates, maintenance and earlier versions
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: page
    required property var view
    property var ov: null
    property string error: ""
    property bool checking: false
    property var updates: null  // checkUpdates' reply
    property string updateError: ""
    property var picked: ({})  // source name -> ticked
    property int compareNumber: 0
    readonly property bool admin: !!view.info && view.info.admin
    readonly property int pickedCount: updates ? updates.changes.filter(c => picked[c.name]).length : 0
    spacing: 6

    function load() {
        Backend.call("overview", {}, reply => {
            if (reply.ok)
                ov = reply.data
            else
                error = reply.error
        })
    }

    Component.onCompleted: load()
    Connections {
        target: Jobs
        function onEnded() { page.load() }
    }

    //--- Whether a job may start now; says why not
    function ready() {
        if (!view.info.canApply || !admin)
            return false
        if (view.pendingCount) {
            view.say("Apply or discard your changes first")
            return false
        }
        if (Jobs.running) {
            view.say("Another job is running; wait for it to finish")
            return false
        }
        return true
    }

    function restart() {
        view.ask({ heading: "Restart now?", body: "Save your work in other apps first.",
                   buttons: [{ label: "Restart", value: "restart" }] },
                 () => Quickshell.execDetached(["systemctl", "reboot"]))
    }

    function rebuild() {
        if (!ready())
            return
        view.ask({
            heading: "Rebuild now?",
            body: "Rebuilds from your settings files as they are (nixos-rebuild switch). At Next "
                  + "Restart uses nixos-rebuild boot; Preview only builds and shows what would change.",
            buttons: [{ label: "Preview", value: "build", quiet: true },
                      { label: "At Next Restart", value: "boot", quiet: true },
                      { label: "Rebuild Now", value: "switch" }]
        }, mode => view.startJob("rebuild", { mode }))
    }

    function collect() {
        if (!ready())
            return
        const c = ov.cleanUp
        const kept = `the newest ${c.keep}` + (c.since ? ` and any made in the last ${c.since}` : "")
        const first = c.doomed.length
            ? `This deletes ${c.doomed.length} of the ${c.total} system generations `
              + `(${c.doomed[0]} to ${c.doomed[c.doomed.length - 1]}), keeping ${kept}. `
            : `No generation is old enough to delete yet; the clean-up keeps ${kept}. `
        let body = first + "Home-manager generations follow the same rule.\n\n"
            + "Garbage collection then deletes every store path no remaining generation uses, "
            + "and the boot menu drops the deleted ones. You can't switch back to them."
        if (c.schedule)
            body += `\n\nThe same clean-up also runs on its own (${c.schedule}).`
        view.ask({
            heading: "Clean up old versions?",
            body: body + (c.doomed.length ? "\n\nWorking out how much space it frees…" : ""),
            buttons: [{ label: "Clean Up", value: "clean", danger: true }]
        }, () => view.startJob("collect", {}))
        if (c.doomed.length)
            Backend.call("freed", {}, reply => {
                if (view.dialog.visible && view.dialog.heading === "Clean up old versions?")
                    view.dialog.body = body + (reply.ok && reply.data
                        ? `\n\nThe old system generations alone free about ${Fmt.size(reply.data)}, `
                          + "more with other unused store paths." : "")
            })
    }

    function check() {
        checking = true
        updates = null
        updateError = ""
        Backend.call("checkUpdates", {}, reply => {
            checking = false
            if (!reply.ok) {
                updateError = reply.error
                return
            }
            updates = reply.data
            const p = {}
            for (const c of updates.changes)
                p[c.name] = true
            picked = p
        })
    }

    function update() {
        if (!ready())
            return
        const names = updates.changes.filter(c => picked[c.name]).map(c => c.name)
        if (!names.length) {
            view.say("Pick at least one source to update")
            return
        }
        const some = names.length < updates.changes.length
        const which = some ? `${names.length} of the ${updates.changes.length} sources`
                           : `${updates.changes.length} sources`
        view.ask({
            heading: "Update this computer?",
            body: `${which} move to their newest versions (nix flake update), then the system `
                  + "rebuilds and switches. If systemd, glibc, niri or xwayland-satellite change, it "
                  + "switches at the next restart instead, since switching those live has frozen the "
                  + "desktop.\n\nPreview only builds and shows what would change, then puts "
                  + "flake.lock back.",
            buttons: [{ label: "Preview", value: "build", quiet: true },
                      { label: "At Next Restart", value: "boot", quiet: true },
                      { label: "Update Now", value: "auto" }]
        }, mode => view.startJob("update", some ? { mode, inputs: names } : { mode, lock: updates.lock }))
    }

    function rollback(g) {
        if (!ready())
            return
        view.ask({
            heading: `Switch to version ${g.number}?`,
            body: `Rolls back to generation ${g.number}, made ${Fmt.when(g.when).toLowerCase()}. Your `
                  + "settings files stay as they are, so the next rebuild goes back to them.",
            buttons: [{ label: "At Next Restart", value: "boot", quiet: true },
                      { label: "Switch Now", value: "auto" }]
        }, mode => view.startJob("activate", { mode, number: g.number, generation: g.path }))
    }

    Text {
        visible: !page.ov
        text: page.error || "Loading…"
        color: page.error ? Theme.error : Theme.dim
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        Layout.margins: 6
    }

    //--- Hero
    Rectangle {
        visible: !!page.ov
        Layout.fillWidth: true
        implicitHeight: hero.implicitHeight + 28
        radius: 16
        color: Theme.card
        RowLayout {
            id: hero
            anchors.fill: parent
            anchors.margins: 14
            spacing: 14
            Badge {
                implicitWidth: 64
                implicitHeight: 64
                radius: 32
                icon: "ac_unit"
                app: ["distributor-logo-nixos", "nix-snowflake"]
            }
            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                Text {
                    text: page.ov ? page.ov.hostname : ""
                    color: Theme.text
                    font.pixelSize: 22
                    font.weight: Font.Bold
                }
                Text { text: page.ov ? page.ov.pretty : ""; color: Theme.dim }
                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    Chip { text: page.view.info.wm; accent: true }
                    Chip { text: page.ov ? `Linux ${page.ov.kernel}` : "" }
                    Chip {
                        visible: !!page.ov && page.ov.generation > 0
                        text: page.ov ? `Version ${page.ov.generation}` : ""
                    }
                }
            }
        }
    }

    //--- Waiting for a restart
    ListRow {
        visible: !!page.ov && (page.ov.pending > 0 || page.ov.newKernel !== "")
        icon: "restart_alt"
        title: page.ov && page.ov.pending ? "Restart to finish" : "Restart to use the new kernel"
        subtitle: !page.ov ? "" : page.ov.pending ? `Version ${page.ov.pending} starts the next time you restart.`
                                                  : `Linux ${page.ov.newKernel} is installed.`
        button: "Restart"
        onClicked: page.restart()
    }

    //--- Updates
    Section { visible: !!page.ov; text: "Updates" }
    ListRow {
        visible: !!page.ov
        icon: page.checking ? "progress_activity" : "update"
        title: "Sources"
        subtitle: !page.ov ? ""
            : page.checking ? "Looking up the newest version of each source; this takes about half a minute."
            : page.updateError ? `Couldn't check: ${page.updateError}`
            : !page.updates ? `Flake inputs, locked ${Fmt.day(page.ov.updated)} (${Fmt.ago(page.ov.updated)})`
            : !page.updates.changes.length ? `Up to date. Sources from ${Fmt.day(page.ov.updated)}.`
            : `${page.updates.changes.length} of this config's sources have newer versions, up to `
              + Fmt.day(Math.max(...page.updates.changes.map(c => c.new))) + "."
        button: page.checking || !page.admin ? "" : page.updates ? "Check Again" : "Check"
        onClicked: if (!page.checking && page.admin) page.check()
    }
    Text {
        visible: !!page.ov && !page.admin
        text: "Only an admin can update this computer."
        color: Theme.dim
        font.pixelSize: 12
        Layout.leftMargin: 6
    }
    Repeater {
        model: page.updates ? page.updates.changes : []
        Rectangle {
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: 52
            radius: 14
            color: srcHover.hovered ? Theme.cardHover : Theme.card
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 10
                spacing: 12
                Icon {
                    icon: page.picked[modelData.name] ? "check_box" : "check_box_outline_blank"
                    fill: !!page.picked[modelData.name]
                    color: page.picked[modelData.name] ? Theme.primary : Theme.dim
                }
                ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true
                    Text { text: modelData.name; color: Theme.text; font.pixelSize: 14; font.weight: Font.DemiBold }
                    Text {
                        text: `${Fmt.day(modelData.old)}  →  ${Fmt.day(modelData.new)}`
                        color: Theme.dim
                        font.pixelSize: 12
                    }
                }
                IconButton {
                    visible: modelData.link !== ""
                    icon: "open_in_new"
                    onClicked: Qt.openUrlExternally(modelData.link)
                }
            }
            HoverHandler { id: srcHover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                onTapped: {
                    const p = Object.assign({}, page.picked)
                    p[modelData.name] = !p[modelData.name]
                    page.picked = p
                }
            }
        }
    }
    Pill {
        visible: !!page.updates && page.updates.changes.length > 0
        Layout.alignment: Qt.AlignRight
        enabled: page.pickedCount > 0
        text: !page.updates || page.pickedCount === page.updates.changes.length ? "Update Now"
            : `Update ${page.pickedCount} of ${page.updates.changes.length}`
        onClicked: page.update()
    }

    //--- Maintenance
    Section { visible: !!page.ov; text: "Maintenance" }
    ListRow {
        visible: !!page.ov
        enabled: page.admin
        icon: "refresh"
        title: "Rebuild Now"
        subtitle: "nixos-rebuild switch on your settings files as they are"
        chevron: true
        onClicked: page.rebuild()
    }
    ListRow {
        visible: !!page.ov
        enabled: page.admin
        icon: "delete_sweep"
        title: "Clean Up Old Versions"
        subtitle: page.ov && page.ov.diskFree
            ? `Garbage collection · ${Fmt.size(page.ov.diskFree)} free of ${Fmt.size(page.ov.diskTotal)}`
            : "Garbage collection"
        chevron: true
        bar: page.ov && page.ov.diskTotal ? 1 - page.ov.diskFree / page.ov.diskTotal : -1
        onClicked: page.collect()
    }
    ListRow {
        visible: !!page.ov
        icon: "folder_open"
        title: "Open the Config Folder"
        subtitle: page.view.info.flake
        trailing: "open_in_new"
        onClicked: Qt.openUrlExternally("file://" + page.view.info.flake)
    }
    ListRow {
        visible: !!page.ov && !!page.ov.lastFailed
        icon: "warning"
        title: "Last Failed Run"
        subtitle: page.ov && page.ov.lastFailed
            ? `${page.ov.lastFailed.title}, ${Fmt.when(page.ov.lastFailed.when).toLowerCase()}: ${page.ov.lastFailed.heading}`
            : ""
        chevron: true
        onClicked: page.view.sheet = failedSheet
    }

    //--- Shell settings; under niri they're on the Niri tab's Shell page
    QuickLinks {
        visible: !!page.ov && page.view.info.wm !== "niri" && shown.length > 0
        Layout.fillWidth: true
        links: page.view.links
        order: page.view.info.quick
    }

    //--- Earlier versions
    Section { visible: !!page.ov && page.ov.generations.length > 0; text: "Versions" }
    Text {
        visible: !!page.ov && page.ov.generations.length > 0
        text: "Generations: each rebuild saves one, and the boot menu keeps the last ten. "
              + "Switching back leaves your settings files as they are."
        color: Theme.dim
        font.pixelSize: 12
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        Layout.leftMargin: 6
    }
    Repeater {
        model: page.ov ? page.ov.generations : []
        Rectangle {
            required property var modelData
            readonly property var g: modelData
            Layout.fillWidth: true
            implicitHeight: genRow.implicitHeight + 22
            radius: 14
            color: Theme.card
            RowLayout {
                id: genRow
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10
                Badge { icon: g.running ? "radio_button_checked" : "history" }
                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true
                    Text {
                        text: `Version ${g.number}`
                        color: Theme.text
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: [Fmt.when(g.when),
                               g.version ? "NixOS " + g.version.split(".").slice(0, 2).join(".") : "",
                               g.kernel ? `Linux ${g.kernel}` : ""].filter(t => t).join(" · ")
                        color: Theme.dim
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Flow {
                        visible: g.running || g.next || g.booted
                        Layout.fillWidth: true
                        spacing: 4
                        Chip { visible: g.running; accent: true; text: "Running" }
                        Chip { visible: g.next && !g.running; accent: true; text: "Next start" }
                        Chip { visible: g.booted && !g.running; text: "Started with" }
                    }
                }
                IconButton {
                    visible: !g.running
                    icon: "difference"
                    onClicked: {
                        page.compareNumber = g.number
                        page.view.sheet = compareSheet
                    }
                }
                Pill {
                    visible: !g.running
                    enabled: page.admin
                    quiet: true
                    text: "Switch"
                    onClicked: page.rollback(g)
                }
            }
        }
    }

    //--------------------------------------------------------------------//
    //-- Sheets
    //--------------------------------------------------------------------//
    Component {
        id: compareSheet
        Sheet {
            id: cmp
            property var diff: null
            property string err: ""
            title: `Version ${page.compareNumber} and Now`
            onBack: page.view.sheet = null
            Component.onCompleted: Backend.call("compare", { number: page.compareNumber }, reply => {
                if (reply.ok) diff = reply.data
                else err = reply.error
            })
            Text {
                text: `What switching from the running version to version ${page.compareNumber} would change.`
                color: Theme.dim
                font.pixelSize: 13
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                Layout.margins: 6
            }
            Text {
                visible: !cmp.diff
                text: cmp.err ? `Couldn't compare: ${cmp.err}` : "Comparing…"
                color: cmp.err ? Theme.error : Theme.dim
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                Layout.margins: 6
            }
            Loader {
                active: !!cmp.diff
                Layout.fillWidth: true
                sourceComponent: DiffView { diff: cmp.diff }
            }
        }
    }

    Component {
        id: failedSheet
        Sheet {
            id: failed
            property var run: null
            title: "Last Failed Run"
            onBack: page.view.sheet = null
            Component.onCompleted: Backend.call("failedLog", {}, reply => run = reply.ok ? reply.data : null)
            actions: [
                Pill {
                    quiet: true
                    text: "Copy the Log"
                    enabled: !!failed.run
                    onClicked: {
                        Quickshell.clipboardText = failed.run.log
                        page.view.say("Log copied")
                    }
                },
                Pill {
                    danger: true
                    text: "Forget It"
                    onClicked: Backend.call("forgetFailed", {}, () => {
                        page.view.sheet = null
                        page.load()
                    })
                }
            ]
            Text {
                text: failed.run ? failed.run.heading : "Loading…"
                color: Theme.text
                font.pixelSize: 15
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                Layout.leftMargin: 6
            }
            Text {
                visible: !!failed.run
                text: failed.run ? `${failed.run.title}, ${Fmt.when(failed.run.when).toLowerCase()}. ${failed.run.reason}` : ""
                color: Theme.dim
                font.pixelSize: 13
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                Layout.leftMargin: 6
            }
            Section { text: "Log" }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: logText.implicitHeight + 20
                radius: 14
                color: Theme.card
                TextEdit {
                    id: logText
                    x: 12
                    y: 10
                    width: parent.width - 24
                    readOnly: true
                    selectByMouse: true
                    text: failed.run ? failed.run.log : ""
                    color: Theme.dim
                    selectionColor: Theme.primary
                    font.family: "monospace"
                    font.pixelSize: 11
                    wrapMode: TextEdit.WrapAnywhere
                }
            }
        }
    }
}
