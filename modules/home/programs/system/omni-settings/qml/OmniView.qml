// Omni Settings' content, the same in the window and (later) DMS's slideout.
// Pending changes live here until Review hands them to api.py and the job service.
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: omni

    signal closeRequested

    property var info: null
    property string loadError: ""
    property var stale: null  // api.py's `stale`, when the settings files don't evaluate
    property string tab: "main"
    property string page: "overview"
    property var lastPage: ({})
    property bool picking: false
    //--- The top tab whose page list the hover flyout shows, and the one under the cursor
    property string flyTab: ""
    property string hoverTab: ""
    property var railTip: null  // { title, y } of the rail icon under the cursor
    property bool reviewing: false
    property bool running: false
    property bool attached: false
    property string toast: ""

    property var pending: ({})
    readonly property int pendingCount: Object.keys(pending).length
    property string scope: ""  // a machine, or "" for all of them
    property var lists: ({})

    //--- Git's counts for the page list (changed, ahead, behind, prs), every minute
    property var gitCounts: null
    readonly property string gitTag: {
        const c = gitCounts
        if (!c)
            return ""
        const parts = [c.changed ? `${c.changed} changed` : "", c.ahead ? `${c.ahead} to push` : "",
                       c.behind ? `${c.behind} to pull` : "", c.prs ? `${c.prs} PR${c.prs === 1 ? "" : "s"}` : ""]
        return parts.filter(p => p).join(" · ") || "In step"
    }
    Timer {
        interval: 60000
        repeat: true
        running: !!omni.info
        triggeredOnStart: true
        onTriggered: Backend.call("gitSummary", {}, reply => { if (reply.ok) omni.gitCounts = reply.data })
    }

    //--- Services running now, for the page list; Running Now updates it too
    property int servicesRunning: -1
    onInfoChanged: if (info && servicesRunning < 0)
        Backend.call("services", {}, reply => {
            if (reply.ok)
                servicesRunning = reply.data.filter(u => u.active === "active").length
        })

    //--- Every DMS link the pages carry
    readonly property var links: !info ? [] : Object.values(info.pages)
        .reduce((all, pg) => pg.groups.reduce((acc, g) => acc.concat(g.links), all), [])

    readonly property var settings: {
        const out = {}
        if (info)
            for (const pg of Object.values(info.pages))
                for (const g of pg.groups)
                    for (const s of g.settings)
                        out[s.key] = s
        if (info && info.userPackages)
            out[info.userPackages.key] = info.userPackages
        return out
    }
    readonly property var navItems: {
        const out = []
        if (info)
            for (const t of info.tabs)
                for (const g of info.nav[t.id])
                    for (const it of g.items)
                        out.push(Object.assign({ tab: t.id, group: g.title }, it))
        // User Packages: one item per category, saved or pending, after All
        const at = out.findIndex(i => i.id === "userpackages") + 1
        if (at > 0)
            out.splice(at, 0, ...packageCategories.map(c => ({ tab: "packages", group: "User Packages",
                id: `userpackages:${c}`, title: c, icon: ["folder"], custom: true,
                subtitle: `${userPackages(false)[c] ? userPackages(false)[c].length : 0} installed` })))
        return out
    }
    readonly property var current: navItems.find(i => i.id === page) || null
    readonly property var scopes: !info ? [] : [{ id: info.machine, title: `This computer (${info.machine})` }]
        .concat(info.userMachines.filter(m => m !== info.machine).map(m => ({ id: m, title: m })))
        .concat([{ id: "", title: "All computers" }])

    //--------------------------------------------------------------------//
    //-- Loading
    //--------------------------------------------------------------------//
    function reload() {
        Backend.call("load", {}, reply => {
            if (!reply.ok) {
                loadError = reply.error
                if (reply.settings)
                    Backend.call("stale", {}, r => stale = r.ok && r.data.items.length ? r.data : null)
                return
            }
            loadError = ""
            stale = null
            const first = !info
            info = reply.data
            if (first)
                scope = info.machine
            // Keep changes that still differ from what the files now hold
            const kept = {}
            for (const [k, v] of Object.entries(pending))
                if (settings[k] && !same(v, scopedValue(settings[k])))
                    kept[k] = v
            pending = kept
        })
    }

    function loadList(name) {
        if (lists[name] !== undefined)
            return
        Backend.call("list", { name }, reply => {
            lists = Object.assign({}, lists, { [name]: reply.ok ? reply.data : [] })
            if (!reply.ok)
                say(reply.error)
        })
    }

    Component.onCompleted: {
        reload()
        Jobs.setShown(true)
    }

    Connections {
        target: Jobs
        function onEnded(job) {
            if (job.kind === "apply" && job.outcome === "ok" && !job.preview)
                omni.pending = {}
            omni.reload()
        }
        function onJobChanged() {
            // A job already running when the view opened
            if (!omni.attached) {
                omni.attached = true
                if (Jobs.running)
                    omni.running = true
            }
        }
    }

    //--------------------------------------------------------------------//
    //-- Values and Pending Changes
    //--------------------------------------------------------------------//
    function same(a, b) { return JSON.stringify(a) === JSON.stringify(b) }

    //--- What a row shows: user settings as on the computer picked in Change For
    function scopedValue(s) {
        if (s.key.startsWith("user:") && scope && info && scope !== info.machine
                && s.elsewhere && scope in s.elsewhere)
            return s.elsewhere[scope]
        return s.value
    }

    function valueOf(s) { return s.key in pending ? pending[s.key] : scopedValue(s) }

    function change(s, v) {
        const p = Object.assign({}, pending)
        if (same(v, scopedValue(s)))
            delete p[s.key]
        else
            p[s.key] = v
        pending = p
    }

    function discard() { pending = {} }

    //--- Settings the templates dropped: an admin who can edit the files removes
    //--- them here, anyone else through the helper as a job
    function removeStale() {
        if (!stale.direct) {
            startJob("clean", {})
            return
        }
        Backend.call("removeStale", {}, reply => {
            say(reply.ok ? "Old settings removed" : reply.error)
            reload()
        })
    }

    //--- An app switch's reset (api.py's resetApp)
    function resetApp(s) {
        const r = s.resettable
        ask({ heading: `Reset ${r.app} settings?`,
              body: `Every setting the config sets for ${r.app} goes back to the config's value, losing `
                    + `what was changed in ${r.app}; settings the config leaves alone stay as they are. `
                    + `The old file is kept as ${r.file}.old.${r.extra}`,
              buttons: [{ label: "Reset", value: "reset", danger: true }] },
            () => Backend.call("resetApp", { key: s.key },
                               reply => say(reply.ok ? `${r.app} settings reset` : reply.error)))
    }

    //--------------------------------------------------------------------//
    //-- User Packages
    //--------------------------------------------------------------------//

    //--- The userPackages categories, {name: [packages]}, with pending changes or as saved
    function userPackages(saved) {
        const s = info ? info.userPackages : null
        const v = !s ? null : saved ? scopedValue(s) : valueOf(s)
        const out = {}
        if (v && typeof v === "object" && !Array.isArray(v))
            for (const [c, n] of Object.entries(v))
                out[c] = n.slice()
        return out
    }

    function setUserPackages(groups) {
        const out = {}
        for (const [c, n] of Object.entries(groups))
            if (n.length)
                out[c] = n
        change(info.userPackages, out)
    }

    function flatPackages(groups) { return Object.values(groups).reduce((all, n) => all.concat(n), []) }

    function categoryOf(groups, attr) { return Object.keys(groups).find(c => groups[c].includes(attr)) || "" }

    //--- Where attr stands: "installed", "adding" (on Apply), "removing", or ""
    function packageState(attr) {
        const now = flatPackages(userPackages(false)).includes(attr)
        const saved = flatPackages(userPackages(true)).includes(attr)
        return now ? (saved ? "installed" : "adding") : saved ? "removing" : ""
    }

    function pickCategory(attr, current, done) { categories.open(attr, current, done) }

    readonly property var packageCategories: {
        const now = userPackages(false), saved = userPackages(true)
        const cats = Object.keys(now).filter(c => now[c].length)
        for (const c of Object.keys(saved))
            if (saved[c].length && !cats.includes(c))
                cats.push(c)
        return cats.sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()))
    }

    //--- Search's index of nixpkgs names (api.py's packageNames), read once per window
    property var packageNames: null
    property var packageLower: []
    property string packageError: ""
    function loadPackageNames() {
        if (packageNames !== null || packageError)
            return
        Backend.call("packageNames", {}, reply => {
            if (!reply.ok)
                packageError = reply.error
            else if (reply.data.missing)
                packageError = reply.data.missing
            else {
                packageLower = reply.data.names.map(n => n.toLowerCase())
                packageNames = reply.data.names
            }
        })
    }

    //--- Package details (api.py's packagePreviews) by name, kept for the window
    property var packageInfo: ({})
    function describe(attrs) {
        const missing = attrs.filter(a => !(a in packageInfo))
        if (!missing.length)
            return
        Backend.stream("packagePreviews", { attrs: missing }, line => {
            let d
            try {
                d = JSON.parse(line)
            } catch (e) {
                return
            }
            packageInfo = Object.assign({}, packageInfo, { [d.attr]: d })
        })
    }

    //--- As api.py's shown()
    function shownOf(s, v) {
        if (s.kind === "bool")
            return v ? "On" : "Off"
        if (v !== null && typeof v === "object" && !Array.isArray(v)) {
            const n = Object.values(v).reduce((a, x) => a + x.length, 0)
            const c = Object.keys(v).length
            return n ? `${n} in ${c} categor${c === 1 ? "y" : "ies"}` : "Not set"
        }
        if (v === null || v === undefined || v === "" || (Array.isArray(v) && !v.length))
            return "Not set"
        if (Array.isArray(v))
            return v.join(", ")
        const pool = s.kind === "choice" ? s.choices : s.kind === "pick" ? (lists[s.data] || []) : []
        const hit = pool.find(c => same(c.value, v))
        return hit ? hit.label : String(v)
    }

    function setScope(id) {
        if (id === scope)
            return
        if (pendingCount) {
            say("Apply or discard your changes first")
            return
        }
        scope = id
    }

    function scopeTitle() {
        return scope === "" ? "all your computers" : scope === info.machine ? "this computer" : scope
    }

    //--- Review's machine: the Change For pick for app settings, null for all of them
    function machineArg() {
        if (!Object.keys(pending).some(k => k.startsWith("user:")))
            return info.machine
        return scope === "" ? null : scope
    }

    //--- Every change is for another computer, so nothing here rebuilds
    function elsewhere() {
        return !!info && scope !== "" && scope !== info.machine && pendingCount > 0
            && Object.keys(pending).every(k => k.startsWith("user:"))
    }

    function needsRestart() {
        return Object.keys(pending).some(k => k.startsWith("machine:") && settings[k]
                                              && /restart/i.test(settings[k].note))
    }

    function apply(mode) {
        if (elsewhere() && info.direct) {
            Backend.call("save", { changes: pending, machine: scope }, reply => {
                if (!reply.ok) {
                    say(`Nothing was saved: ${reply.error}`)
                    return
                }
                reviewing = false
                say(`Saved for ${scope}; it takes effect when ${scope} rebuilds`)
                pending = {}
                reload()
            })
            return
        }
        startJob("apply", { changes: pending, machine: machineArg(), mode })
    }

    //--- Starts a job service job and shows its run page; lastJob lets a
    //--- finished preview start the same job for real
    property var lastJob: null
    function startJob(kind, args) {
        Jobs.start(kind, args, reply => {
            if (!reply.ok) {
                say(reply.error)
                return
            }
            lastJob = kind === "person" ? null : { kind, args }  // not kept: a password
            reviewing = false
            running = true
        })
    }

    //--- Runs the previewed job again, switching
    function runPreviewed() {
        const kind = lastJob.kind
        if (kind === "apply")
            apply("switch")
        else
            startJob(kind, Object.assign({}, lastJob.args, { mode: kind === "update" ? "auto" : "switch" }))
    }

    //--- A modal question: ask({heading, body, buttons}, done(value))
    function ask(spec, done) { dialog.open(spec, done) }
    readonly property alias dialog: confirm

    //--- A Sheet component shown over everything; null closes it
    property Component sheet: null

    function closeRun() {
        if (Jobs.job && Jobs.job.ended)
            Jobs.request("dismiss")
        running = false
    }

    //--------------------------------------------------------------------//
    //-- Navigation and Small Actions
    //--------------------------------------------------------------------//
    function go(tabId, pageId) {
        const lp = Object.assign({}, lastPage)
        lp[tab] = page
        lastPage = lp
        tab = tabId
        if (pageId)
            page = pageId
        else {
            const first = navItems.find(i => i.tab === tabId)
            page = lastPage[tabId] || (first ? first.id : "")
        }
        picking = false
        flyTab = ""
        search.text = ""
        bodyFlick.contentY = 0
    }

    function openFile(rel) {
        let editor = {}
        try {
            editor = JSON.parse(Quickshell.env("OMNI_SETTINGS_EDITOR") || "{}")
        } catch (e) {}
        const path = rel.startsWith("/") ? rel : `${info.flake}/${rel}`
        Quickshell.execDetached((editor.launch || ["xdg-open"]).concat([path]))
    }

    function say(text) {
        toast = text
        toastTimer.restart()
    }

    Timer { id: toastTimer; interval: 3000; onTriggered: omni.toast = "" }

    //--- Search: pages, then settings, then DMS's own settings
    readonly property var results: {
        const q = search.text.trim().toLowerCase()
        if (!q || !info)
            return []
        const out = navItems.filter(i => i.title.toLowerCase().includes(q))
            .map(i => ({ kind: "page", tab: i.tab, page: i.id, title: i.title, subtitle: i.group, icon: i.icon }))
        for (const [pid, pg] of Object.entries(info.pages)) {
            const item = navItems.find(i => i.id === pid)
            if (!item)
                continue
            for (const g of pg.groups)
                for (const s of g.settings)
                    if (s.title.toLowerCase().includes(q) || s.subtitle.toLowerCase().includes(q))
                        out.push({ kind: "page", tab: item.tab, page: pid, title: s.title,
                                   subtitle: `${pg.title} · ${s.subtitle}`, icon: s.icon, app: s.icon })
        }
        for (const e of info.dmsSearch)
            if (e.label.toLowerCase().includes(q) || e.keywords.includes(q))
                out.push({ kind: "dms", tab: e.tab, title: e.label, subtitle: `DankMaterialShell · ${e.page}`,
                           icon: ["preferences-desktop-theme"] })
        return out.slice(0, 60)
    }

    Keys.onEscapePressed: {
        if (picking) picking = false
        else if (flyTab) flyTab = ""
        else if (reviewing) reviewing = false
        else if (running) running = false
        else omni.closeRequested()
    }

    //--------------------------------------------------------------------//
    //-- Layout
    //--------------------------------------------------------------------//
    ColumnLayout {
        id: mainCol
        anchors.fill: parent
        anchors.margins: 14
        anchors.leftMargin: rail.width + 10
        spacing: 10
        visible: !omni.reviewing && !omni.running && omni.sheet === null

        //--- Header
        RowLayout {
            Layout.fillWidth: true
            Item { implicitWidth: 32 }
            Text {
                text: "Omni Settings"
                color: Theme.text
                font.pixelSize: 18
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }
            IconButton { icon: "close"; filled: true; onClicked: omni.closeRequested() }
        }

        Text {
            visible: !!omni.info && omni.info.banner !== ""
            text: omni.info ? omni.info.banner : ""
            color: Theme.caution
            font.pixelSize: 13
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            Layout.leftMargin: 6
        }

        //--- Top tabs
        Rectangle {
            id: tabsBar
            Layout.fillWidth: true
            implicitHeight: 40
            radius: 20
            color: Theme.card
            RowLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 2
                Repeater {
                    model: omni.info ? omni.info.tabs : []
                    Rectangle {
                        required property var modelData
                        readonly property bool active: omni.tab === modelData.id
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 16
                        color: active ? Theme.primary : tabHover.hovered ? Theme.cardHover : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            Icon {
                                icon: Theme.glyph(modelData.icon)
                                size: 16
                                fill: active
                                color: active ? Theme.inkPrimary : Theme.dim
                            }
                            Text {
                                text: modelData.title
                                font.pixelSize: 15
                                font.weight: Font.Bold
                                color: active ? Theme.inkPrimary : Theme.dim
                            }
                        }
                        HoverHandler {
                            id: tabHover
                            cursorShape: Qt.PointingHandCursor
                            onHoveredChanged: {
                                if (hovered) {
                                    omni.hoverTab = modelData.id
                                    if (omni.flyTab) omni.flyTab = modelData.id
                                    else flyOpen.restart()
                                } else if (omni.hoverTab === modelData.id) {
                                    omni.hoverTab = ""
                                    flyClose.restart()
                                }
                            }
                        }
                        TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: omni.go(modelData.id) }
                    }
                }
            }
        }

        //--- Page picker: the current page, opening into the page list and search
        Rectangle {
            Layout.fillWidth: true
            // Opens in place, pushing the dimmed page down
            Layout.preferredHeight: omni.picking ? Math.min(pickerCol.implicitHeight, omni.height * 0.72) : 60
            radius: 16
            color: Theme.card
            clip: true
            Behavior on Layout.preferredHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            ColumnLayout {
                id: pickerCol
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 60
                    radius: 16
                    color: currentHover.hovered ? Theme.cardHover : "transparent"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 14
                        spacing: 12
                        Badge { icon: Theme.glyph(omni.current ? omni.current.icon : []) }
                        ColumnLayout {
                            spacing: 1
                            Layout.fillWidth: true
                            Text {
                                text: omni.current ? omni.current.title : omni.info ? "" : omni.loadError ? "Not loaded" : "Loading…"
                                color: Theme.text
                                font.pixelSize: 16
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                            }
                            Text {
                                visible: text !== ""
                                text: omni.current ? omni.current.subtitle || omni.current.group : ""
                                color: Theme.dim
                                font.pixelSize: 13
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                        Icon {
                            icon: "expand_more"
                            rotation: omni.picking ? 180 : 0
                            Behavior on rotation { NumberAnimation { duration: 200 } }
                        }
                    }
                    HoverHandler { id: currentHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        gesturePolicy: TapHandler.ReleaseWithinBounds
                        onTapped: {
                            omni.picking = !omni.picking
                            if (omni.picking)
                                search.input.forceActiveFocus()
                        }
                    }
                }

                Field {
                    id: search
                    Layout.margins: 8
                    Layout.bottomMargin: 4
                    icon: "search"
                    placeholder: "Search settings"
                    onEscaped: { text = ""; omni.picking = false; omni.forceActiveFocus() }
                    onAccepted: {
                        const r = omni.results[0]
                        if (r) list.pick(r)
                    }
                }

                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8
                    Layout.bottomMargin: 8
                    implicitHeight: contentHeight
                    clip: true
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds
                    model: search.text.trim() ? omni.results
                        : omni.navItems.filter(i => i.tab === omni.tab)
                            .map(i => ({ kind: "page", tab: i.tab, page: i.id, title: i.title, group: i.group,
                                         icon: i.icon, subtitle: i.subtitle || "" }))

                    function pick(r) {
                        if (r.kind === "dms")
                            Quickshell.execDetached(["dms", "ipc", "call", "settings", "openWith", r.tab])
                        else
                            omni.go(r.tab, r.page)
                        omni.forceActiveFocus()
                    }

                    delegate: ColumnLayout {
                        required property var modelData
                        required property int index
                        width: list.width
                        spacing: 2
                        Section {
                            readonly property var prev: index > 0 ? list.model[index - 1] : null
                            visible: !!modelData.group && (!prev || prev.group !== modelData.group)
                            text: modelData.group || ""
                            Layout.leftMargin: 8
                        }
                        ListRow {
                            icon: Theme.glyph(modelData.icon)
                            app: modelData.app || []
                            title: modelData.title
                            subtitle: modelData.subtitle || ""
                            selected: modelData.kind === "page" && omni.page === modelData.page && !search.text
                            trailing: modelData.kind === "dms" ? "open_in_new" : ""
                            tag: modelData.page === "git" ? omni.gitTag
                                 : modelData.page === "page:Services" && omni.servicesRunning > 0
                                 ? `${omni.servicesRunning} running` : ""
                            tagSuccess: modelData.page === "page:Services"
                            compact: true
                            onClicked: list.pick(modelData)
                        }
                    }
                }
            }
        }

        //--- Page body
        Flickable {
            id: bodyFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: body.implicitHeight + 16
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: !omni.picking
            // A page that got shorter, or came back from a run, keeps no blank space
            onContentHeightChanged: returnToBounds()
            onVisibleChanged: if (visible) returnToBounds()
            opacity: omni.picking || omni.flyTab ? 0.35 : 1
            Behavior on opacity { NumberAnimation { duration: 150 } }

            //--- A tap on the dimmed page closes the picker
            MouseArea {
                z: 1
                parent: bodyFlick
                anchors.fill: parent
                enabled: omni.picking
                onClicked: omni.picking = false
            }

            ColumnLayout {
                id: body
                width: parent.width
                spacing: 6

                //--- The settings files don't evaluate
                Rectangle {
                    visible: omni.loadError !== ""
                    Layout.fillWidth: true
                    implicitHeight: failed.implicitHeight + 28
                    radius: 16
                    color: Theme.toneFill("error", Theme.card)
                    ColumnLayout {
                        id: failed
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10
                        readonly property var mine: omni.stale ? omni.stale.items.filter(i => i.mine) : []
                        function where(i) {
                            const file = `machines/${omni.stale.machine}/settings.nix`
                            return { user: `users/${i.user}/settings.nix`, machine: file,
                                     override: `${file}, ${i.user}'s block` }[i.where]
                        }
                        RowLayout {
                            spacing: 14
                            Badge { implicitWidth: 56; implicitHeight: 56; radius: 28; icon: "error"; tone: "error" }
                            Text {
                                text: "Couldn't read the settings"
                                color: Theme.text
                                font.pixelSize: 22
                                font.weight: Font.Bold
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                            }
                        }
                        Text {
                            text: !omni.stale ? omni.loadError
                                : "These settings aren't in the templates any more, so the files can't be read:\n"
                                  + omni.stale.items.map(i => `• ${i.key}  (${failed.where(i)})`).join("\n")
                                  + (failed.mine.length < omni.stale.items.length
                                     ? "\n\nAn admin needs to remove the computer-wide ones." : "")
                            color: omni.stale ? Theme.text : Theme.error
                            font.pixelSize: 15
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 12
                            Pill { text: "Try Again"; quiet: true; onClicked: omni.reload() }
                            Pill {
                                visible: failed.mine.length > 0 && (omni.stale.direct || omni.stale.helper)
                                text: "Remove Them"
                                onClicked: omni.removeStale()
                            }
                        }
                    }
                }

                //--- What's New: template settings the user's files leave out
                Rectangle {
                    visible: !!omni.info && omni.info.whatsNew.length > 0 && omni.tab === "main"
                    Layout.fillWidth: true
                    implicitHeight: whatsNew.implicitHeight + 24
                    radius: 16
                    color: Theme.toneFill("", Theme.card)
                    ColumnLayout {
                        id: whatsNew
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8
                        Text {
                            readonly property int n: omni.info ? omni.info.whatsNew.length : 0
                            text: `${n} new setting${n === 1 ? "" : "s"} your files don't list yet`
                            color: Theme.text
                            font.weight: Font.DemiBold
                        }
                        RowLayout {
                            spacing: 8
                            Pill {
                                text: "Add Them"
                                onClicked: {
                                    const p = Object.assign({}, omni.pending)
                                    for (const n of omni.info.whatsNew)
                                        p[n.key] = n.value
                                    omni.pending = p
                                }
                            }
                            Pill {
                                quiet: true
                                text: "Dismiss"
                                onClicked: Backend.call("dismiss", { keys: omni.info.whatsNew.map(n => n.key) },
                                                        () => omni.reload())
                            }
                        }
                    }
                }

                // Height from the page itself: one set by the layout would carry over
                // to the next page loaded, leaving blank space above a shorter one
                Loader {
                    Layout.fillWidth: true
                    Layout.preferredHeight: item ? item.implicitHeight : 0
                    active: !!omni.info && !!omni.info.pages[omni.page] && omni.pageComponent === undefined
                    sourceComponent: SettingsPage {
                        model: omni.info.pages[omni.page]
                        view: omni
                    }
                }

                //--- Pages not made from the templates
                Loader {
                    Layout.fillWidth: true
                    Layout.preferredHeight: item ? item.implicitHeight : 0
                    active: !!omni.info && omni.pageComponent !== undefined
                    sourceComponent: omni.pageComponent || null
                }

                //--- Pages not ported yet
                ColumnLayout {
                    visible: !!omni.info && !omni.info.pages[omni.page] && omni.pageComponent === undefined
                    Layout.fillWidth: true
                    Layout.topMargin: 40
                    spacing: 12
                    Text {
                        text: `${omni.current ? omni.current.title : "This page"} isn't in the QML version yet.`
                        color: Theme.dim
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                    }
                    Pill {
                        Layout.alignment: Qt.AlignHCenter
                        quiet: true
                        text: "Open the GTK Version"
                        onClicked: Quickshell.execDetached(["omni-settings"])
                    }
                }
            }
        }

        //--- A job running while its page is closed
        ListRow {
            visible: !!Jobs.job && !omni.running
            icon: Jobs.running ? "progress_activity" : Jobs.job && Jobs.job.outcome === "failed" ? "error" : "check_circle"
            title: Jobs.job ? Jobs.job.title : ""
            subtitle: !Jobs.job ? "" : Jobs.running ? "Running" : (Jobs.job.heading || Jobs.job.done)
            tone: !Jobs.job || Jobs.running ? "" : Jobs.job.outcome === "failed" ? "error"
                : Jobs.job.outcome === "ok" ? "success" : ""
            chevron: true
            onClicked: omni.running = true
        }

        //--- Pending changes
        Rectangle {
            visible: omni.pendingCount > 0
            Layout.fillWidth: true
            implicitHeight: 54
            radius: 27
            color: Theme.card
            border.width: 1
            border.color: Theme.line
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 10
                spacing: 8
                Text {
                    text: `${omni.pendingCount} change${omni.pendingCount === 1 ? "" : "s"}`
                    color: Theme.text
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }
                Pill { quiet: true; text: "Discard"; onClicked: omni.discard() }
                Pill {
                    text: "Review"
                    enabled: !!omni.info && omni.info.canApply && !Jobs.running
                    onClicked: {
                        omni.reviewing = true
                        review.load()
                    }
                }
            }
        }
    }

    //--- Page rail: the current tab's pages as icons on the window's left edge
    Rectangle {
        id: rail
        visible: mainCol.visible
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: mainCol.y + tabsBar.y
        anchors.bottomMargin: 14
        width: 52
        color: Theme.card
        topRightRadius: 20
        bottomRightRadius: 20
        opacity: omni.flyTab ? 0.35 : 1

        ListView {
            id: railList
            anchors.fill: parent
            anchors.topMargin: 6
            anchors.bottomMargin: 6
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: omni.navItems.filter(i => i.tab === omni.tab)
            onContentYChanged: omni.railTip = null

            delegate: Column {
                id: railItem
                required property var modelData
                required property int index
                readonly property var prev: index > 0 ? railList.model[index - 1] : null
                readonly property bool active: omni.page === modelData.id
                width: railList.width
                //--- A short line where the page list starts a new group
                Item {
                    visible: !!railItem.prev && railItem.prev.group !== railItem.modelData.group
                    width: parent.width
                    height: 9
                    Rectangle {
                        anchors.centerIn: parent
                        width: 22
                        height: 1
                        color: Theme.line
                    }
                }
                Item {
                    width: parent.width
                    height: 42
                    Rectangle {
                        anchors.centerIn: parent
                        width: 38
                        height: 38
                        radius: 19
                        color: railItem.active ? Theme.primary : railHover.hovered ? Theme.cardHover : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Icon {
                            anchors.centerIn: parent
                            icon: Theme.glyph(railItem.modelData.icon)
                            size: 20
                            fill: railItem.active
                            color: railItem.active ? Theme.inkPrimary : Theme.dim
                        }
                    }
                    HoverHandler {
                        id: railHover
                        cursorShape: Qt.PointingHandCursor
                        onHoveredChanged: {
                            if (hovered)
                                omni.railTip = { title: railItem.modelData.title,
                                                 y: parent.mapToItem(omni, 0, 0).y + 21 }
                            else if (omni.railTip && omni.railTip.title === railItem.modelData.title)
                                omni.railTip = null
                        }
                    }
                    TapHandler {
                        gesturePolicy: TapHandler.ReleaseWithinBounds
                        onTapped: omni.go(omni.tab, railItem.modelData.id)
                    }
                }
            }
        }
    }

    //--- The rail icon's name, flown out over the page
    Rectangle {
        visible: !!omni.railTip && rail.visible
        x: rail.width + 4
        y: omni.railTip ? omni.railTip.y - height / 2 : 0
        z: 1
        width: tipText.implicitWidth + 24
        height: 32
        radius: 16
        color: Theme.toast
        Text {
            id: tipText
            anchors.centerIn: parent
            text: omni.railTip ? omni.railTip.title : ""
            color: Theme.inkToast
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }
    }

    //--- Tab flyout: hovering a top tab lists its pages over the dimmed page
    Timer { id: flyOpen; interval: 250; onTriggered: if (omni.hoverTab) omni.flyTab = omni.hoverTab }
    Timer { id: flyClose; interval: 300; onTriggered: if (!omni.hoverTab && !flyHover.hovered) omni.flyTab = "" }
    Rectangle {
        id: flyout
        visible: omni.flyTab !== "" && mainCol.visible
        x: mainCol.x
        y: mainCol.y + tabsBar.y + tabsBar.height + 6
        z: 1
        width: mainCol.width
        height: Math.min(flyList.contentHeight + 16, omni.height - y - 14)
        radius: 16
        color: Theme.card
        border.color: Theme.line
        HoverHandler {
            id: flyHover
            onHoveredChanged: if (!hovered) flyClose.restart()
        }

        ListView {
            id: flyList
            anchors.fill: parent
            anchors.margins: 8
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            model: omni.navItems.filter(i => i.tab === omni.flyTab)

            delegate: ColumnLayout {
                required property var modelData
                required property int index
                width: flyList.width
                spacing: 2
                Section {
                    readonly property var prev: index > 0 ? flyList.model[index - 1] : null
                    visible: !!modelData.group && (!prev || prev.group !== modelData.group)
                    text: modelData.group || ""
                    Layout.leftMargin: 8
                }
                ListRow {
                    icon: Theme.glyph(modelData.icon)
                    title: modelData.title
                    subtitle: modelData.subtitle || ""
                    selected: omni.page === modelData.id
                    tag: modelData.id === "git" ? omni.gitTag
                         : modelData.id === "page:Services" && omni.servicesRunning > 0
                         ? `${omni.servicesRunning} running` : ""
                    tagSuccess: modelData.id === "page:Services"
                    compact: true
                    onClicked: omni.go(modelData.tab, modelData.id)
                }
            }
        }
    }

    ReviewSheet {
        id: review
        anchors.fill: parent
        anchors.margins: 14
        visible: omni.reviewing
        view: omni
    }

    RunSheet {
        anchors.fill: parent
        anchors.margins: 14
        visible: omni.running && !!Jobs.job
        view: omni
    }

    Loader {
        anchors.fill: parent
        anchors.margins: 14
        active: omni.sheet !== null
        sourceComponent: omni.sheet
        onLoaded: item.forceActiveFocus()
    }

    CategorySheet {
        id: categories
        anchors.fill: parent
        anchors.margins: 14
        z: 1
        view: omni
    }

    ConfirmDialog { id: confirm; anchors.fill: parent; z: 2 }

    //--- Custom pages by id; each is ported from the GTK app in turn
    readonly property var custom: ({ overview: overviewPage, shell: shellPage, git: gitPage,
                                      flatpaks: flatpaksPage, backups: backupsPage, people: peoplePage,
                                      packages: packagesPage, userpackages: userPackagesPage,
                                      proton: protonPage, protonversions: protonVersionsPage })
    Component { id: protonPage; ProtonPage { view: omni } }
    Component { id: docPage; DocPage { view: omni } }
    Component { id: protonVersionsPage; ProtonVersionsPage { view: omni } }
    readonly property var pageComponent: custom[page]
        || (page.startsWith("userpackages:") ? userPackagesPage
            : page.startsWith("doc:") ? docPage : undefined)
    Component { id: packagesPage; PackagesPage { view: omni } }
    Component { id: userPackagesPage; UserPackagesPage { view: omni } }
    Component { id: peoplePage; PeoplePage { view: omni } }
    Component { id: backupsPage; BackupsPage { view: omni } }
    Component { id: flatpaksPage; FlatpaksPage { view: omni } }
    Component { id: overviewPage; OverviewPage { view: omni } }
    Component { id: gitPage; GitPage { view: omni } }
    Component { id: shellPage; ShellPage { view: omni } }

    //--- Toast
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 80
        visible: omni.toast !== ""
        width: Math.min(toastText.implicitWidth + 28, omni.width - 32)
        height: toastText.implicitHeight + 16
        radius: 18
        color: Theme.toast
        Text {
            id: toastText
            anchors.centerIn: parent
            width: Math.min(implicitWidth, omni.width - 60)
            text: omni.toast
            color: Theme.inkToast
            wrapMode: Text.Wrap
        }
    }
}
