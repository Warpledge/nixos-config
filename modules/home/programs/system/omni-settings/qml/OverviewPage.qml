// The Maintenance page (id "overview"): updates, freeing space and earlier versions
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: page
    required property var view
    property var ov: null
    property var boot: null  // systemd-analyze's last startup, asked for apart
    property bool bootOpen: false  // whether the startup's details are shown
    property bool versionsOpen: false  // whether the older generations are listed
    readonly property var versions: ov ? ov.generations : []
    readonly property var current: versions.find(g => g.running) || versions[0] || null
    readonly property var older: versions.filter(g => !!current && g.number !== current.number)
    property string error: ""
    readonly property bool ready: !!ov || error !== ""
    property bool checking: false
    property var updates: null  // checkUpdates' reply
    property string updateError: ""
    property var picked: ({})  // source name -> ticked
    property var notesSource: null  // the source whose release notes are open
    property var notes: null  // changelog's reply
    property string notesError: ""
    property int compareNumber: 0
    readonly property bool admin: !!view.info && view.info.admin
    readonly property int behind: view.gitCounts ? view.gitCounts.behind : 0  // as of the last fetch
    readonly property int pickedCount: updates ? updates.changes.filter(c => picked[c.name]).length : 0
    spacing: 6

    function load() {
        Backend.call("overview", {}, reply => {
            if (!page)
                return  // the tab was left before the reply came
            if (reply.ok)
                ov = reply.data
            else
                error = reply.error
        })
    }

    Component.onCompleted: {
        load()
        loadBoot()
    }

    //--- The startup chart takes a call of its own, so the rest shows meanwhile
    function loadBoot() {
        Backend.call("boot", {}, reply => {
            if (page && reply.ok)
                page.boot = reply.data
        })
    }
    Connections {
        target: Jobs
        function onEnded(job) {
            // The checked versions are in flake.lock now
            if (job.kind === "update" && job.outcome === "ok" && !job.preview)
                page.updates = null
            if (job.kind === "pull")
                Backend.call("gitSummary", {}, reply => { if (reply.ok) page.view.gitCounts = reply.data })
            page.load()
        }
    }

    function canStart() { return view.canStart() }

    function restart() {
        view.ask({ heading: "Restart now?", body: "Save your work in other apps first.",
                   buttons: [{ label: "Restart", value: "restart" }] },
                 () => Quickshell.execDetached(["systemctl", "reboot"]))
    }

    function collect() {
        if (!canStart())
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

    function optimise() {
        if (!canStart())
            return
        view.ask({
            heading: "Optimize the Nix store?",
            body: "Replaces identical files in the store with hard links, so each copy takes space "
                  + "once. Nothing is deleted and every app keeps working. It can take a few "
                  + "minutes; the space it freed is shown when it finishes.",
            buttons: [{ label: "Optimize", value: "optimise" }]
        }, () => view.startJob("optimise", {}))
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

    //--- One source's release notes, read from GitHub when the row asks for them
    function showNotes(src) {
        notesSource = src
        notes = null
        notesError = ""
        view.sheet = notesSheet
        Backend.call("changelog", { repo: src.repo, before: src.before, after: src.after,
                                    old: src.old, new: src.new }, reply => {
            if (!page)
                return
            if (reply.ok)
                page.notes = reply.data
            else
                page.notesError = reply.error
        })
    }

    function update() {
        if (!canStart())
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

    function pull() {
        if (!canStart())
            return
        const n = behind
        view.ask({
            heading: "Get the config's new commits?",
            body: `Pulls ${n} new commit${n === 1 ? "" : "s"} into the config (git pull --rebase, `
                  + "or a merge once you've merged upstream yourself), keeping your own commits, "
                  + "then the system rebuilds and switches. If "
                  + "systemd, glibc, niri or xwayland-satellite change, it switches at the next restart "
                  + "instead.\n\nPreview only builds and shows what would change, then puts the "
                  + "config back.",
            buttons: [{ label: "Preview", value: "build", quiet: true },
                      { label: "At Next Restart", value: "boot", quiet: true },
                      { label: "Pull Now", value: "auto" }]
        }, mode => view.startJob("pull", { mode }))
    }

    function rollback(g) {
        if (!canStart())
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

    //--- Waiting for a restart
    ListRow {
        visible: !!page.ov && (page.ov.pending > 0 || page.ov.newKernel !== "")
        icon: "restart_alt"
        title: page.ov && page.ov.pending ? "Restart to finish" : "Restart to use the new kernel"
        alert: !page.ov ? "" : page.ov.pending ? `Version ${page.ov.pending} starts the next time you restart.`
                                               : `Linux ${page.ov.newKernel} is installed.`
        button: "Restart"
        onClicked: page.restart()
    }
    ListRow {
        visible: !!page.ov && !!page.ov.lastFailed
        icon: "warning"
        tone: "error"
        title: "Last Failed Run"
        alert: page.ov && page.ov.lastFailed
            ? `${page.ov.lastFailed.title}, ${Fmt.when(page.ov.lastFailed.when).toLowerCase()}: ${page.ov.lastFailed.heading}`
            : ""
        chevron: true
        onClicked: page.view.sheet = failedSheet
    }

    //--- Updates
    Section { visible: !!page.ov; text: "Updates" }
    ListRow {
        visible: !!page.ov && page.behind > 0
        icon: "download"
        title: "Config"
        alert: `${page.behind} new commit${page.behind === 1 ? "" : "s"} to pull into the config`
        tone: "caution"
        button: page.admin ? "Pull" : ""
        onClicked: if (page.admin) page.pull()
    }
    ListRow {
        visible: !!page.ov
        icon: page.checking ? "progress_activity" : "update"
        title: "Sources"
        info: page.ov ? "The flake inputs this config is built from, such as nixpkgs. Locked "
                        + `${Fmt.day(page.ov.updated)} (${Fmt.ago(page.ov.updated)}).` : ""
        caution: page.admin ? "" : "Only an admin can update this computer"
        value: !page.ov ? ""
            : page.checking ? "Checking…"
            : !page.updates ? Fmt.day(page.ov.updated)
            : !page.updates.changes.length ? "Up to date"
            : `${page.updates.changes.length} newer`
        alert: page.updateError ? `Couldn't check: ${page.updateError}` : ""
        button: page.checking || !page.admin ? "" : page.updates ? "Check Again" : "Check"
        onClicked: if (!page.checking && page.admin) page.check()
    }
    Repeater {
        model: page.updates ? page.updates.changes : []
        Rectangle {
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: 52
            radius: 14
            color: srcHover.hovered ? Theme.hover : Theme.card
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
                    Text { text: modelData.name; color: Theme.text; font.pixelSize: 16; font.weight: Font.DemiBold }
                    Text {
                        text: `${Fmt.day(modelData.old)}  →  ${Fmt.day(modelData.new)}`
                        color: Theme.dim
                        font.pixelSize: 13
                    }
                }
                IconButton {
                    visible: modelData.repo !== ""
                    icon: "notes"
                    onClicked: page.showNotes(modelData)
                }
                IconButton {
                    visible: modelData.link !== ""
                    icon: "open_in_new"
                    onClicked: Qt.openUrlExternally(modelData.link)
                }
            }
            HoverHandler { id: srcHover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                gesturePolicy: TapHandler.ReleaseWithinBounds
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

    //--- Free Up Space
    Section { visible: !!page.ov; text: "Free Up Space" }
    ListRow {
        visible: !!page.ov
        enabled: page.admin
        icon: "delete_sweep"
        title: "Clean Up Old Versions"
        info: "Garbage collection: deletes old system versions and the packages only they use"
              + (page.ov && page.ov.diskTotal ? `. ${Fmt.size(page.ov.diskTotal)} disk.` : ".")
        value: page.ov && page.ov.diskFree ? `${Fmt.size(page.ov.diskFree)} free` : ""
        chevron: true
        bar: page.ov && page.ov.diskTotal ? 1 - page.ov.diskFree / page.ov.diskTotal : -1
        onClicked: page.collect()
    }
    ListRow {
        visible: !!page.ov
        enabled: page.admin
        icon: "compress"
        title: "Optimize the Nix Store"
        info: "Frees space by hard-linking identical files in the Nix store. Deletes nothing."
        chevron: true
        onClicked: page.optimise()
    }

    //--- Shell settings; under niri they're on the Niri tab's Shell page
    QuickLinks {
        visible: !!page.ov && page.view.info.wm !== "niri" && shown.length > 0
        Layout.fillWidth: true
        links: page.view.links
        order: page.view.info.quick
    }

    //--- Earlier versions; the row keeps the running one and opens the rest
    Section { visible: page.versions.length > 0; text: "Versions" }
    ListRow {
        visible: !!page.current
        icon: page.current && page.current.running ? "radio_button_checked" : "history"
        tone: page.current && page.current.running ? "success" : ""
        title: page.current ? `Version ${page.current.number}` : ""
        info: !page.current ? ""
            : "Generations: each rebuild saves one, and the boot menu keeps the last ten. "
              + "Switching back leaves your settings files as they are."
              + [page.older.length
                     ? `${page.older.length} earlier `
                       + (page.older.length === 1 ? "generation" : "generations") : "",
                 // The header shows the running one's
                 page.current.version && !page.current.running
                     ? "NixOS " + page.current.version.split(".").slice(0, 2).join(".") : "",
                 page.current.kernel && !page.current.running ? `Linux ${page.current.kernel}` : ""]
                .filter(t => t).map(t => `\n${t}`).join("")
        value: page.current ? Fmt.when(page.current.when) : ""
        tag: !page.current ? "" : page.current.running ? "Running"
            : page.current.next ? "Next start" : ""
        tagSuccess: true
        expandable: page.older.length > 0
        expanded: page.versionsOpen
        onClicked: if (page.older.length) page.versionsOpen = !page.versionsOpen
    }
    Reveal {
        id: olderList
        open: page.versionsOpen && page.older.length > 0
        gap: page.spacing
        spacing: page.spacing
        Repeater {
            model: olderList.shown ? page.older : []
            Rectangle {
                required property var modelData
                readonly property var g: modelData
                Layout.fillWidth: true
                implicitHeight: genRow.implicitHeight + 22
                radius: 14
                color: g.running ? Theme.toneFill("success", Theme.card) : Theme.card
                RowLayout {
                    id: genRow
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10
                    Badge { icon: g.running ? "radio_button_checked" : "history"; tone: g.running ? "success" : "" }
                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        Text {
                            text: `Version ${g.number}`
                            color: Theme.text
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: [Fmt.when(g.when),
                                   g.version ? "NixOS " + g.version.split(".").slice(0, 2).join(".") : "",
                                   g.kernel ? `Linux ${g.kernel}` : ""].filter(t => t).join(" · ")
                            color: Theme.dim
                            font.pixelSize: 13
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Flow {
                            visible: g.running || g.next || g.booted
                            Layout.fillWidth: true
                            spacing: 4
                            Chip { tappable: false; visible: g.running; tone: "success"; text: "Running" }
                            Chip { tappable: false; visible: g.next && !g.running; accent: true; text: "Next start" }
                            Chip { tappable: false; visible: g.booted && !g.running; text: "Started with" }
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
    }

    //--- How the last startup went, from systemd-analyze; the row keeps it to
    //--- the total until the details are wanted
    Section { visible: !!page.boot && page.boot.stages.total > 0; text: "Startup" }
    ListRow {
        visible: !!page.boot && page.boot.stages.total > 0
        icon: "timer"
        title: "Last Startup"
        info: !page.boot ? ""
            : page.boot.graphical ? `From power on to ${page.boot.graphical.target}`
            : "From power on"
        value: page.boot ? Fmt.duration(page.boot.stages.total) : ""
        expandable: true
        expanded: page.bootOpen
        onClicked: page.bootOpen = !page.bootOpen
    }
    Reveal {
        open: page.bootOpen && !!page.boot && page.boot.stages.total > 0
        gap: page.spacing
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: bootColumn.implicitHeight + 28
            radius: 16
            color: Theme.card
            ColumnLayout {
                id: bootColumn
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 14
                spacing: 10
                Text {
                    Layout.fillWidth: true
                    text: !page.boot ? ""
                        : page.boot.graphical
                            ? `The desktop was up ${Fmt.duration(page.boot.graphical.seconds)} into `
                              + "userspace."
                            : "From power on to the desktop."
                    color: Theme.dim
                    font.pixelSize: 13
                    wrapMode: Text.Wrap
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: ["firmware", "loader", "kernel", "initrd", "userspace"]
                        delegate: Chip {
                            required property string modelData
                            visible: !!page.boot && !!page.boot.stages[modelData]
                            tappable: false
                            text: page.boot ? `${modelData} ${Fmt.duration(page.boot.stages[modelData])}` : ""
                        }
                    }
                }
                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    text: "The slowest units to start:"
                    color: Theme.dim
                    font.pixelSize: 13
                }
                Repeater {
                    model: page.boot ? page.boot.blame.units : []
                    delegate: ColumnLayout {
                        id: blameRow
                        required property var modelData
                        readonly property var units: page.boot.blame.units
                        readonly property real share: units.length
                            ? modelData.seconds / Math.max(units[0].seconds, 0.001) : 0
                        Layout.fillWidth: true
                        spacing: 4
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            Text {
                                Layout.fillWidth: true
                                text: blameRow.modelData.unit
                                color: Theme.text
                                font.pixelSize: 13
                                elide: Text.ElideRight
                            }
                            Text {
                                text: Fmt.duration(blameRow.modelData.seconds)
                                color: Theme.dim
                                font.pixelSize: 13
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 6
                            radius: 3
                            color: Theme.line
                            Rectangle {
                                width: parent.width * blameRow.share
                                height: parent.height
                                radius: 3
                                color: Theme.primary
                            }
                        }
                    }
                }
                Text {
                    visible: !!page.boot && page.boot.blame.devices !== null
                    Layout.fillWidth: true
                    text: page.boot && page.boot.blame.devices !== null
                        ? `Device units took up to ${Fmt.duration(page.boot.blame.devices)}; one wait `
                          + "shows up under many device names." : ""
                    color: Theme.dim
                    font.pixelSize: 13
                    wrapMode: Text.Wrap
                }
                Text {
                    visible: page.boot && page.boot.chain.length > 0
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    text: "The chain the desktop waited on, each indent waiting for the one above:"
                    color: Theme.dim
                    font.pixelSize: 13
                    wrapMode: Text.Wrap
                }
                Repeater {
                    model: page.boot ? page.boot.chain : []
                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.leftMargin: Math.min(modelData.depth, 4) * 14
                        spacing: 10
                        Text {
                            Layout.fillWidth: true
                            text: modelData.unit
                            color: Theme.text
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                        Text {
                            visible: modelData.took !== null
                            text: modelData.took !== null ? `+${Fmt.duration(modelData.took)}` : ""
                            color: Theme.dim
                            font.pixelSize: 13
                        }
                        Text {
                            text: `@${Fmt.duration(modelData.at)}`
                            color: Theme.dim
                            font.pixelSize: 13
                        }
                    }
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
                font.pixelSize: 15
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
        id: notesSheet
        Sheet {
            id: rel
            property int open: -1  // the release whose notes are shown
            readonly property var data: page.notes
            title: page.notesSource ? `${page.notesSource.name} notes` : "Release notes"
            onBack: page.view.sheet = null
            actions: [
                Pill {
                    quiet: true
                    visible: !!page.notesSource && !!page.notesSource.link
                    text: "All the Changes"
                    onClicked: Qt.openUrlExternally(page.notesSource.link)
                }
            ]
            Text {
                Layout.fillWidth: true
                Layout.margins: 6
                text: !page.notesSource ? ""
                    : `What ${page.notesSource.name} says changed between `
                      + `${Fmt.day(page.notesSource.old)} and ${Fmt.day(page.notesSource.new)}.`
                color: Theme.dim
                font.pixelSize: 15
                wrapMode: Text.Wrap
            }
            Text {
                visible: !rel.data && !page.notesError
                Layout.fillWidth: true
                Layout.margins: 6
                text: "Reading GitHub…"
                color: Theme.dim
            }
            Text {
                visible: page.notesError !== ""
                Layout.fillWidth: true
                Layout.margins: 6
                text: page.notesError
                color: Theme.error
                wrapMode: Text.Wrap
            }
            Text {
                visible: !!rel.data && !rel.data.releases.length && !rel.data.commits
                Layout.fillWidth: true
                Layout.margins: 6
                text: "Nothing was published between these two versions."
                color: Theme.dim
                wrapMode: Text.Wrap
            }
            Section {
                visible: !!rel.data && rel.data.releases.length > 0
                text: rel.data && rel.data.releases.length === 1 ? "Release"
                    : `${rel.data ? rel.data.releases.length : 0} releases`
            }
            Repeater {
                model: rel.data && rel.data.releases ? rel.data.releases : []
                Rectangle {
                    id: release
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: releaseCol.implicitHeight + 20
                    radius: 14
                    color: Theme.card
                    ColumnLayout {
                        id: releaseCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        anchors.leftMargin: 14
                        spacing: 4
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text {
                                    text: release.modelData.tag
                                    color: Theme.text
                                    font.pixelSize: 16
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    text: [release.modelData.name !== release.modelData.tag
                                           ? release.modelData.name : "",
                                           Fmt.day(release.modelData.when)].filter(t => t).join(" · ")
                                    color: Theme.dim
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                            IconButton {
                                visible: release.modelData.url !== ""
                                icon: "open_in_new"
                                onClicked: Qt.openUrlExternally(release.modelData.url)
                            }
                            Chevron {
                                open: rel.open === release.index
                            }
                        }
                        Reveal {
                            open: rel.open === release.index
                            gap: releaseCol.spacing
                            Text {
                                Layout.fillWidth: true
                                text: release.modelData.body || "The release has no notes."
                                color: Theme.dim
                                font.pixelSize: 13
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        gesturePolicy: TapHandler.ReleaseWithinBounds
                        onTapped: rel.open = rel.open === release.index ? -1 : release.index
                    }
                }
            }
            Section {
                visible: !!rel.data && !!rel.data.commits
                text: rel.data && rel.data.commits
                    ? `${rel.data.commits.total} commit${rel.data.commits.total === 1 ? "" : "s"}`
                    : ""
            }
            Repeater {
                model: rel.data && rel.data.commits ? rel.data.commits.items : []
                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: commit.implicitHeight + 18
                    radius: 14
                    color: Theme.card
                    RowLayout {
                        id: commit
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 10
                        anchors.leftMargin: 14
                        spacing: 10
                        Text {
                            text: modelData.sha
                            color: Theme.primary
                            font.family: "monospace"
                            font.pixelSize: 13
                        }
                        Text {
                            text: modelData.subject
                            color: Theme.text
                            font.pixelSize: 13
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        IconButton {
                            visible: modelData.url !== ""
                            icon: "open_in_new"
                            onClicked: Qt.openUrlExternally(modelData.url)
                        }
                    }
                }
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
                    text: "Copy the Errors"
                    visible: !!failed.run && !!failed.run.errors
                    onClicked: {
                        Quickshell.clipboardText = failed.run.errors
                        page.view.say("Errors copied")
                    }
                },
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
                font.pixelSize: 16
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                Layout.leftMargin: 6
            }
            Text {
                visible: !!failed.run
                text: failed.run ? `${failed.run.title}, ${Fmt.when(failed.run.when).toLowerCase()}. ${failed.run.reason}` : ""
                color: Theme.dim
                font.pixelSize: 15
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
                    font.pixelSize: 12
                    wrapMode: TextEdit.WrapAnywhere
                }
            }
        }
    }
}
