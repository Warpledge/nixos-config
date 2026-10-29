// Omni Settings' content, the same in the window and (later) DMS's slideout.
// Pending changes live here until Review hands them to api.py and the job service.
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: omni

    signal closeRequested

    property int edge: 14  // gap between the view and the window's edges
    property int gutter: 8  // the part of `edge` left of the pages that holds their band
    property var info: null
    property string loadError: ""
    property var stale: null  // api.py's `stale`, when the settings files don't evaluate
    property string tab: "main"
    property string page: "overview"
    property bool picking: false
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
    // False while DMS's panel is hidden, which keeps the view loaded
    readonly property bool shown: !!Window.window && Window.window.visible
    Timer {
        interval: 60000
        repeat: true
        running: !!omni.info && omni.shown
        triggeredOnStart: true
        onTriggered: Backend.call("gitSummary", {}, reply => { if (reply.ok) omni.gitCounts = reply.data })
    }

    //--- Services running now, for the page list; Running Now updates it too
    property int servicesRunning: -1
    onInfoChanged: {
        if (info && servicesRunning < 0)
            Backend.call("services", {}, reply => {
                if (reply.ok)
                    servicesRunning = reply.data.filter(u => u.active === "active").length
            })
        // Looked up in the background, so the Packages tab has its icons ready
        if (info)
            Theme.queueIcons(Object.values(info.pages).reduce((all, pg) => pg.groups
                .reduce((acc, g) => acc.concat((g.settings || []).map(s => s.icon)), all), []))
    }

    //--- Every DMS link the pages carry
    readonly property var links: !info ? [] : Object.values(info.pages)
        .reduce((all, pg) => pg.groups.reduce((acc, g) => acc.concat(g.links), all), [])
        .concat(info.shellLinks.reduce((acc, c) => acc.concat(c.links), []))

    readonly property var settings: {
        const out = {}
        if (info)
            for (const pg of Object.values(info.pages))
                for (const g of pg.groups)
                    for (const s of g.settings) {
                        out[s.key] = s
                        if (s.pair)
                            out[s.pair.key] = s.pair
                    }
        if (info && info.userPackages)
            out[info.userPackages.key] = info.userPackages
        if (info && info.keybinds)
            out[info.keybinds.key] = info.keybinds
        if (info && info.windowRules)
            out[info.windowRules.key] = info.windowRules
        if (info && info.env)
            out[info.env.key] = info.env
        if (info && info.autostart)
            out[info.autostart.key] = info.autostart
        if (info && info.mimeTypes)
            out[info.mimeTypes.key] = info.mimeTypes
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
    //--- The current tab's pages, in its scroll order. Search sits pinned above the
    //--- Packages scroll, and All user packages shows only while there's no category
    readonly property var tabPages: navItems.filter(i => i.tab === tab && i.id !== "packages"
                                                    && !(i.id === "userpackages" && packageCategories.length))
    //--- Each page's colour by id; a page that would match the one above takes the
    //--- next, and a run of notes shares the first one's
    readonly property var pageAccents: {
        const out = {}
        let prev = -1
        tabPages.forEach((p, i) => {
            const runOn = p.id.startsWith("doc:") && i > 0 && tabPages[i - 1].id.startsWith("doc:")
            let n = runOn ? prev : Theme.accentIndex(p.id)
            if (!runOn && n === prev)
                n = (n + 1) % Theme.accentHues.length
            out[p.id] = Theme.pageAccent(n)
            prev = n
        })
        return out
    }
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
            if (first) {
                scope = info.machine
                const ui = info.ui || {}
                const set = keys => (keys || []).reduce((o, k) => (o[k] = true, o), {})
                collapsedPages = set(ui.collapsed)
                openCards = set(ui.open)
            }
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
        Jobs.setShown(shown)
    }
    onShownChanged: Jobs.setShown(shown)

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

    //--- How many nixpkgs names Search has (api.py's packageNames), once per window;
    //--- -1 until its index is read
    property int packageCount: -1
    property string packageError: ""
    function loadPackageNames() {
        if (packageCount >= 0 || packageError)
            return
        Backend.call("packageNames", {}, reply => {
            if (!reply.ok)
                packageError = reply.error
            else if (reply.data.missing)
                packageError = reply.data.missing
            else
                packageCount = reply.data.count
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
            const values = Object.values(v)
            if (!values.every(x => Array.isArray(x)))
                return values.length ? `${values.length} entr${values.length === 1 ? "y" : "ies"}` : "Not set"
            const n = values.reduce((a, x) => a + x.length, 0)
            const c = Object.keys(v).length
            return n ? `${n} in ${c} categor${c === 1 ? "y" : "ies"}` : "Not set"
        }
        const nullChoice = v === null && s.kind === "choice" && s.choices.find(c => c.value === null)
        if (nullChoice && nullChoice.label !== "None")
            return nullChoice.label
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
            startJob(kind, Object.assign({}, lastJob.args,
                                        { mode: kind === "update" || kind === "pull" ? "auto" : "switch" }))
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
    //--- A tab is one scroll of its pages: go() to another tab builds its pages out
    //--- of sight, to a page in this tab scrolls there
    function go(tabId, pageId) {
        picking = false
        search.text = ""
        omni.forceActiveFocus()
        if (pageId === "packages") {
            if (tabId !== tab)
                go(tabId)
            packageSearch.focusField()
            return
        }
        if (pageId && pageId.startsWith("doc:"))
            openNote(pageId, true)
        if (tabId === tab) {
            if (pageId)
                scrollTo(pageId)
            return
        }
        packageSearch.close()
        const ts = Object.assign({}, tabState)
        ts[tab] = { page, offset: anchorOffset }
        tabState = ts
        pageIn.stop()
        scrollAnim.stop()
        reveal = 0
        rise = 14
        tab = tabId
        const kept = tabState[tabId]
        const target = pageId || (kept ? kept.page : "")
        page = tabPages.some(i => i.id === target) ? target : tabPages.length ? tabPages[0].id : ""
        anchorPage = page
        anchorOffset = !pageId && kept && kept.page === page ? kept.offset : 0
        setY(0)
        waiting = true
        revealCap.restart()
        Qt.callLater(showPage)
        if (tabId === "packages")
            packageSearch.focusField()
    }

    //--- The scroll: the page whose section holds the top of the view is `page`, and
    //--- that section stays still while sections above it load or change height
    property var tabState: ({})  // tab -> {page, offset} for coming back to it
    property string anchorPage: "overview"
    property real anchorOffset: 0  // contentY less the anchor section's y
    property bool adjusting: false
    function section(pid) {
        for (let i = 0; i < sections.count; i++) {
            const s = sections.itemAt(i)
            if (s && s.pid === pid)
                return s
        }
        return null
    }
    function maxY() { return Math.max(0, bodyFlick.contentHeight - bodyFlick.height) }
    function setY(y) {
        adjusting = true
        bodyFlick.contentY = Math.max(0, Math.min(y, maxY()))
        adjusting = false
    }
    function snapToAnchor() {
        const s = section(anchorPage)
        if (s && s.visible)
            setY(s.y + anchorOffset)
    }
    function sectionMoved(s) {
        if (s.pid === anchorPage && !bodyFlick.dragging && !bodyFlick.flicking && !scrollAnim.running)
            snapToAnchor()
    }
    //--- After the user scrolls: the page now at the top, or the last one at the bottom
    function spy() {
        if (adjusting || scrollAnim.running)
            return
        const y = bodyFlick.contentY
        let hit = null
        for (let i = 0; i < sections.count; i++) {
            const s = sections.itemAt(i)
            if (s && s.visible && (s.y <= y + bodyFlick.height / 4 || !hit))
                hit = s
        }
        if (!hit)
            return
        if (y >= maxY() - 2 && maxY() > 0)
            for (let i = sections.count - 1; i >= 0; i--) {
                const s = sections.itemAt(i)
                if (s && s.visible) {
                    hit = s
                    break
                }
            }
        page = hit.pid
        anchorTop()
    }
    //--- The section under the view's top edge stays put, so a dropdown opened
    //--- anywhere in view pushes what's below it down instead of what's above up
    function anchorTop() {
        const y = bodyFlick.contentY
        let top = null
        for (let i = 0; i < sections.count; i++) {
            const s = sections.itemAt(i)
            if (s && s.visible && (s.y <= y || !top))
                top = s
        }
        if (!top)
            return
        anchorPage = top.pid
        anchorOffset = y - top.y
    }
    function scrollTo(pid) {
        const s = section(pid)
        if (!s)
            return
        page = pid
        anchorPage = pid
        anchorOffset = 0
        scrollAnim.stop()
        scrollAnim.to = Math.max(0, Math.min(s.y, maxY()))
        scrollAnim.start()
    }
    NumberAnimation {
        id: scrollAnim
        target: bodyFlick
        property: "contentY"
        duration: 380
        easing.type: Easing.OutCubic
        // A section above that grew meanwhile moved the target
        onFinished: omni.anchorTop()
    }

    //--- Collapsed pages and open group cards, kept in api.py's UI_STATE
    property var collapsedPages: ({})
    property var openCards: ({})
    function setCardOpen(key, open) {
        const c = Object.assign({}, openCards)
        if (open)
            c[key] = true
        else
            delete c[key]
        openCards = c
        saveUi()
    }
    function setPageCollapsed(pid, collapsed) {
        const c = Object.assign({}, collapsedPages)
        if (collapsed)
            c[pid] = true
        else
            delete c[pid]
        collapsedPages = c
        saveUi()
    }
    function saveUi() {
        Backend.call("saveUi", { collapsed: Object.keys(collapsedPages), open: Object.keys(openCards) }, () => {})
    }

    //--- Notes on the Docs tab show only their title until opened
    property var openNotes: ({})
    function openNote(pid, open) {
        const n = Object.assign({}, openNotes)
        if (open)
            n[pid] = true
        else
            delete n[pid]
        openNotes = n
    }

    //--- A new tab fades in and rises into place once its pages have their data
    //--- (each page's `ready`)
    property real reveal: 1
    property real rise: 0
    property bool waiting: false
    function tabReady() {
        for (let i = 0; i < sections.count; i++) {
            const s = sections.itemAt(i)
            if (s && !s.ready)
                return false
        }
        return true
    }
    function showPage() {
        if (!waiting || !tabReady() && revealCap.running)
            return
        waiting = false
        revealCap.stop()
        snapToAnchor()
        pageIn.start()
    }
    // A slow backend call shows the page's own "Loading…" after this long
    Timer { id: revealCap; interval: 700; onTriggered: omni.showPage() }
    ParallelAnimation {
        id: pageIn
        NumberAnimation { target: omni; property: "reveal"; to: 1; duration: 220; easing.type: Easing.OutQuad }
        NumberAnimation { target: omni; property: "rise"; to: 0; duration: 300; easing.type: Easing.OutCubic }
    }

    function openFile(rel) {
        const path = rel.startsWith("/") ? rel : `${info.flake}/${rel}`
        Quickshell.execDetached((Config.editor.launch || ["xdg-open"]).concat([path]))
    }

    //--- A toast; `action` ({label, run}) adds a button and keeps it up longer
    property var toastAction: null
    function say(text, action) {
        toast = text
        toastAction = action || null
        toastTimer.interval = action ? 6000 : 3000
        toastTimer.restart()
    }

    Timer { id: toastTimer; interval: 3000; onTriggered: { omni.toast = ""; omni.toastAction = null } }

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
                                   subtitle: `${g.collapsed ? g.title : pg.title} · ${s.subtitle}`,
                                   icon: s.icon, app: s.icon,
                                   card: g.collapsed ? (g.card || `${pid}|${g.title}`) : "" })
        }
        for (const e of info.dmsSearch)
            if (e.label.toLowerCase().includes(q) || e.keywords.includes(q))
                out.push({ kind: "dms", tab: e.tab, title: e.label, subtitle: `DankMaterialShell · ${e.page}`,
                           icon: ["preferences-desktop-theme"] })
        return out.slice(0, 60)
    }

    //--- Typing opens search; keys only get here when no field has focus
    Keys.onPressed: event => {
        const t = event.text
        if (t.length !== 1 || t <= " " || t === "\x7f" || !mainCol.visible
                || event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
            return
        picking = true
        search.text = t
        search.input.forceActiveFocus()
        search.input.cursorPosition = t.length
        event.accepted = true
    }

    Keys.onEscapePressed: {
        if (picking) picking = false
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
        anchors.margins: omni.edge
        anchors.rightMargin: omni.edge + rail.width + 10
        spacing: 10
        visible: !omni.reviewing && !omni.running && omni.sheet === null

        Text {
            visible: !!omni.info && omni.info.banner !== ""
            text: omni.info ? omni.info.banner : ""
            color: Theme.caution
            font.pixelSize: 13
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            Layout.leftMargin: 6
        }

        //--- Top tabs: icons, the hovered one stretching right to show its name
        Rectangle {
            id: tabsBar
            z: 3  // a hovered tab's name hangs below it, over the page
            Layout.preferredWidth: tabsRow.implicitWidth + 6
            implicitHeight: 44
            radius: 22
            color: Theme.card
            RowLayout {
                id: tabsRow
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 3
                spacing: 2
                Repeater {
                    model: omni.info ? omni.info.tabs : []
                    // Only the current tab shows its name in the row; a hovered tab's name
                    // shows below its icon, so no tab moves under the cursor
                    Item {
                        id: tab
                        required property var modelData
                        readonly property bool active: omni.tab === modelData.id
                        readonly property bool open: active
                        readonly property real full: tabLabel.x + tabLabel.implicitWidth + 14
                        Layout.preferredWidth: active ? full : 38
                        Layout.preferredHeight: 38
                        Behavior on Layout.preferredWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        z: tabHover.hovered ? 2 : 0
                        HoverHandler { id: tabHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: omni.go(tab.modelData.id) }
                        Rectangle {
                            readonly property var modelData: tab.modelData
                            readonly property bool active: tab.active
                            readonly property bool open: tab.open
                            width: open ? tab.full : 38
                            height: 38
                            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            radius: 19
                            clip: true
                            color: active ? Theme.primary : tabHover.hovered ? Theme.hover : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Icon {
                                x: 9
                                anchors.verticalCenter: parent.verticalCenter
                                icon: Theme.glyph(modelData.icon)
                                size: 20
                                fill: active
                                color: active ? Theme.inkPrimary : tabHover.hovered ? Theme.inkSelected : Theme.dim
                            }
                            Text {
                                id: tabLabel
                                x: 36
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.title
                                font.pixelSize: 15
                                font.weight: Font.Bold
                                color: active ? Theme.inkPrimary : Theme.inkSelected
                                opacity: parent.open ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }
                        }
                        Rectangle {
                            visible: tabHover.hovered && !tab.active
                            anchors.top: parent.bottom
                            anchors.topMargin: 8
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: tabTip.implicitWidth + 20
                            height: tabTip.implicitHeight + 10
                            radius: height / 2
                            color: Theme.toast
                            border.width: 1
                            border.color: Theme.line
                            Text {
                                id: tabTip
                                anchors.centerIn: parent
                                text: tab.modelData.title
                                color: Theme.inkToast
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }
            }
        }

        //--- Search, opened from the header, pushing the dimmed page down
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: omni.picking ? Math.min(pickerCol.implicitHeight, omni.height * 0.72) : 0
            visible: Layout.preferredHeight > 0
            radius: 16
            color: Theme.card
            clip: true
            Behavior on Layout.preferredHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            ColumnLayout {
                id: pickerCol
                anchors.fill: parent
                spacing: 0

                Field {
                    id: search
                    Layout.margins: 8
                    Layout.bottomMargin: search.text.trim() ? 4 : 8
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
                    visible: count > 0
                    model: omni.results

                    function pick(r) {
                        if (r.kind === "dms") {
                            Quickshell.execDetached(["dms", "ipc", "call", "settings", "openWith", r.tab])
                        } else {
                            // A setting in a card or a collapsed page shows open
                            if (omni.collapsedPages[r.page])
                                omni.setPageCollapsed(r.page, false)
                            if (r.card && !omni.openCards[r.card])
                                omni.setCardOpen(r.card, true)
                            omni.go(r.tab, r.page)
                        }
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
                            selected: modelData.kind === "page" && omni.page === modelData.page
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

        PackagesPage {
            id: packageSearch
            view: omni
            visible: omni.tab === "packages"
            z: 2  // its results hang over the page
            Layout.fillWidth: true
        }

        //--- Page body
        Flickable {
            id: bodyFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: -omni.gutter
            contentHeight: body.implicitHeight + 16
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: !omni.picking && !packageSearch.open
            // A page that got shorter, or came back from a run, keeps no blank space
            onContentHeightChanged: omni.setY(contentY)
            onVisibleChanged: if (visible) omni.setY(contentY)
            onContentYChanged: omni.spy()
            opacity: omni.picking || packageSearch.open ? 0.35 : 1
            Behavior on opacity { NumberAnimation { duration: 150 } }

            //--- A tap on the dimmed page closes the picker or the package results
            MouseArea {
                z: 1
                parent: bodyFlick
                anchors.fill: parent
                enabled: omni.picking || packageSearch.open
                onClicked: {
                    omni.picking = false
                    search.text = ""
                    packageSearch.close()
                    omni.forceActiveFocus()
                }
            }

            ColumnLayout {
                id: body
                x: omni.gutter
                width: parent.width - omni.gutter
                spacing: 6
                opacity: omni.reveal
                transform: Translate { y: omni.rise }

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

                //--- The tab's pages, one after another
                Repeater {
                    id: sections
                    model: omni.info ? omni.tabPages : []
                    PageSection {}
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

    //--- Page rail: the current tab's pages as icons down the right edge
    Rectangle {
        id: rail
        visible: mainCol.visible
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: omni.edge
        anchors.topMargin: omni.edge + 44  // starts an icon below the top tabs
        // As tall as its icons, up to the window's bottom margin
        height: Math.min(railList.contentHeight + 8, parent.height - anchors.topMargin - omni.edge)
        width: 48
        radius: 24
        color: Theme.card
        HoverHandler { id: railArea }

        ListView {
            id: railList
            anchors.fill: parent
            anchors.margins: 4
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: omni.tabPages

            delegate: Column {
                id: railItem
                required property var modelData
                required property int index
                readonly property var prev: index > 0 ? railList.model[index - 1] : null
                readonly property bool active: omni.page === modelData.id
                readonly property color accent: omni.pageAccents[modelData.id] || Theme.primary
                width: railList.width
                //--- A line where the page list starts a new group
                Item {
                    visible: !!railItem.prev && railItem.prev.group !== railItem.modelData.group
                    width: parent.width
                    height: 13
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width - 12
                        height: 1
                        color: Qt.alpha(Theme.primary, 0.35)
                    }
                }
                Rectangle {
                    width: parent.width
                    height: 40
                    radius: 20
                    color: railItem.active ? railItem.accent : railHover.hovered ? Theme.hover : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Icon {
                        anchors.centerIn: parent
                        icon: Theme.glyph(railItem.modelData.icon)
                        size: 20
                        fill: railItem.active
                        color: railItem.active ? Theme.inkPrimary : railItem.accent
                    }
                    HoverHandler { id: railHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        gesturePolicy: TapHandler.ReleaseWithinBounds
                        onTapped: omni.go(omni.tab, railItem.modelData.id)
                    }
                }
            }
        }
    }

    //--- Every page's name, left of its icon, while the cursor is on the rail or the names
    Item {
        id: railNames
        visible: rail.visible && (railArea.hovered || namesArea.hovered)
        z: 4
        anchors.right: rail.left
        y: rail.y + railList.y
        height: railList.height
        width: namesCol.implicitWidth + 8  // the gap to the rail counts as hovering the names
        clip: true
        HoverHandler { id: namesArea }
        // Mutes the page behind the names so they read on any page
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.35; color: Qt.alpha(Theme.bg, 0.85) }
                GradientStop { position: 1; color: Qt.alpha(Theme.bg, 0.95) }
            }
        }
        // Laid out like the rail's list and scrolled with it
        Column {
            id: namesCol
            y: -railList.contentY
            Repeater {
                model: railList.model
                Column {
                    id: nameItem
                    required property var modelData
                    required property int index
                    readonly property var prev: index > 0 ? railList.model[index - 1] : null
                    readonly property bool active: omni.page === modelData.id
                    x: namesCol.width - width
                    Item {
                        visible: !!nameItem.prev && nameItem.prev.group !== nameItem.modelData.group
                        width: 1
                        height: 13
                    }
                    Item {
                        width: namePill.width
                        height: 40
                        Rectangle {
                            id: namePill
                            anchors.verticalCenter: parent.verticalCenter
                            width: nameText.implicitWidth + 24
                            height: 28
                            radius: 14
                            color: nameItem.active ? Theme.primary : Theme.toast
                            border.width: 1
                            border.color: Theme.line
                            Text {
                                id: nameText
                                anchors.centerIn: parent
                                text: nameItem.modelData.title
                                color: nameItem.active ? Theme.inkPrimary : Theme.inkToast
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                gesturePolicy: TapHandler.ReleaseWithinBounds
                                onTapped: omni.go(omni.tab, nameItem.modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }

    ReviewSheet {
        id: review
        anchors.fill: parent
        anchors.margins: omni.edge
        visible: omni.reviewing
        view: omni
    }

    RunSheet {
        anchors.fill: parent
        anchors.margins: omni.edge
        visible: omni.running && !!Jobs.job
        view: omni
    }

    Loader {
        anchors.fill: parent
        anchors.margins: omni.edge
        active: omni.sheet !== null
        sourceComponent: omni.sheet
        onLoaded: item.forceActiveFocus()
    }

    CategorySheet {
        id: categories
        anchors.fill: parent
        anchors.margins: omni.edge
        z: 1
        view: omni
    }

    ConfirmDialog { id: confirm; anchors.fill: parent; z: 2 }

    //--- Custom pages by id
    readonly property var custom: ({ overview: overviewPage, shell: shellPage, git: gitPage,
                                      flatpaks: flatpaksPage, backups: backupsPage, people: peoplePage,
                                      userpackages: userPackagesPage,
                                      proton: protonPage, protonversions: protonVersionsPage,
                                      windowrules: windowRulesPage, keybinds: keybindsPage,
                                      startup: startupPage, filetypes: fileTypesPage })
    Component { id: windowRulesPage; WindowRulesPage { view: omni } }
    Component { id: keybindsPage; KeybindsPage { view: omni } }
    Component { id: startupPage; StartupPage { view: omni } }
    Component { id: fileTypesPage; FileTypesPage { view: omni } }
    Component { id: protonPage; ProtonPage { view: omni } }
    Component { id: protonVersionsPage; ProtonVersionsPage { view: omni } }
    //--- One page in the tab's scroll: its section's divider when it starts one, then
    //--- the page in a card whose header collapses it; a note starts collapsed
    component PageSection: ColumnLayout {
        id: section
        required property var modelData
        required property int index
        readonly property string pid: modelData.id
        //--- This page's own colour, which its headings and badges read (Theme.accentOf)
        readonly property color pageAccent: omni.pageAccents[pid] || Theme.primary
        readonly property bool note: pid.startsWith("doc:")
        readonly property bool userPkgs: pid.startsWith("userpackages:")
        readonly property bool open: note ? !!omni.openNotes[pid] : !omni.collapsedPages[pid]
        readonly property var model: omni.info.pages[pid] || null
        readonly property var comp: note ? notePage : userPkgs ? userPkgsPage
            : omni.custom[pid] || (model ? settingsPage : null)
        readonly property bool ready: !loader.item || loader.item.ready !== false
        onReadyChanged: {
            if (ready && loader.item && !omni.waiting)
                arrived.restart()
            omni.showPage()
        }
        onYChanged: omni.sectionMoved(section)
        function toggle() {
            if (note)
                omni.openNote(pid, !open)
            else
                omni.setPageCollapsed(pid, open)
        }
        // The rail's group this page starts; the untitled first group takes the tab's name
        readonly property var prev: index > 0 ? omni.tabPages[index - 1] : null
        readonly property var next: index + 1 < omni.tabPages.length ? omni.tabPages[index + 1] : null
        readonly property bool divided: !prev || prev.group !== modelData.group
        readonly property string sectionTitle: modelData.group
            || (omni.info.tabs.find(t => t.id === omni.tab) || { title: "" }).title
        // A section holding one page of its own name shows only the divider
        readonly property bool headed: !(divided && modelData.title === modelData.group
                                         && (!next || next.group !== modelData.group))
        visible: !!comp
        Layout.fillWidth: true
        Layout.topMargin: index === 0 ? 0 : divided ? 22 : 4
        spacing: 6

        //--- The section's name in a pill, lines fading out to both sides
        RowLayout {
            visible: section.divided && section.sectionTitle !== ""
            Layout.fillWidth: true
            Layout.bottomMargin: 8
            spacing: 8
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 2
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 1; color: section.pageAccent }
                }
            }
            Rectangle { implicitWidth: 7; implicitHeight: 7; rotation: 45; color: section.pageAccent }
            Rectangle {
                implicitWidth: dividerName.implicitWidth + 40
                implicitHeight: 46
                radius: 23
                color: Qt.tint(Theme.card, Qt.alpha(section.pageAccent, 0.35))
                border.width: 2
                border.color: section.pageAccent
                Text {
                    id: dividerName
                    anchors.centerIn: parent
                    text: section.sectionTitle
                    color: Theme.inkContainer
                    font.pixelSize: 22
                    font.weight: Font.ExtraBold
                }
            }
            Rectangle { implicitWidth: 7; implicitHeight: 7; rotation: 45; color: section.pageAccent }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 2
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: section.pageAccent }
                    GradientStop { position: 1; color: "transparent" }
                }
            }
        }

        //--- The page's card, reaching into the gutter
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: -omni.gutter
            implicitHeight: frameCol.implicitHeight
            radius: 20
            color: Qt.alpha(section.pageAccent, section.headed && headHover.hovered && !section.open ? 0.1 : 0.05)
            border.width: section.headed ? 1 : 0
            border.color: Qt.alpha(section.pageAccent, section.open ? 0.22 : 0.15)
            Behavior on color { ColorAnimation { duration: 150 } }

            ColumnLayout {
                id: frameCol
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 0

                //--- Header: icon, name, a short line and the chevron; tapping it collapses
                RowLayout {
                    visible: section.headed
                    Layout.fillWidth: true
                    Layout.margins: 12
                    spacing: 12
                    Rectangle {
                        implicitWidth: 36
                        implicitHeight: 36
                        radius: 18
                        color: section.pageAccent
                        Icon {
                            anchors.centerIn: parent
                            icon: Theme.glyph(section.modelData.icon, "description")
                            size: 20
                            fill: true
                            color: Theme.inkPrimary
                        }
                    }
                    ColumnLayout {
                        spacing: 1
                        Layout.fillWidth: true
                        Text {
                            text: section.modelData.title
                            color: Theme.text
                            font.pixelSize: 17
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        // A generated page's blurb, or a custom page's line from the rail
                        Text {
                            visible: text !== ""
                            text: section.modelData.subtitle || (section.model ? section.model.description : "")
                            color: Theme.dim
                            font.pixelSize: 13
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                    // Words, not a Chevron, so it reads apart from the dropdowns inside
                    Chip {
                        tappable: false  // the whole header takes the tap
                        text: section.open ? "Hide" : "Show"
                        accent: headHover.hovered
                    }
                    HoverHandler { id: headHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: section.toggle() }
                }
                Rectangle {
                    visible: section.headed && body.height > 0
                    Layout.fillWidth: true
                    Layout.leftMargin: 14
                    Layout.rightMargin: 14
                    implicitHeight: 1
                    opacity: body.opacity
                    color: Qt.alpha(section.pageAccent, 0.25)
                }

                // Height from the page itself, as a layout-set one would loop with wrapped
                // text; it slides open and shut (Reveal.qml does the same for smaller content)
                Item {
                    id: body
                    property bool armed: false
                    Connections { target: section; function onOpenChanged() { body.armed = true } }
                    Layout.fillWidth: true
                    Layout.leftMargin: omni.gutter
                    Layout.rightMargin: omni.gutter
                    Layout.topMargin: section.headed && section.open ? 8 : 0
                    Layout.bottomMargin: section.open ? 10 : 0
                    Layout.preferredHeight: loader.item && section.open ? loader.item.implicitHeight : 0
                    clip: true
                    opacity: section.open ? 1 : 0
                    Behavior on Layout.preferredHeight {
                        enabled: body.armed
                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                    }
                    Behavior on opacity { enabled: body.armed; NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }
                    Loader {
                        id: loader
                        width: parent.width
                        active: (section.open || body.height > 0) && !!section.comp
                        sourceComponent: section.comp
                        // Data that came after the tab showed eases in
                        NumberAnimation on opacity { id: arrived; running: false; from: 0.3; to: 1; duration: 260 }
                    }
                }
            }
        }

        Component { id: settingsPage; SettingsPage { model: section.model; view: omni } }
        Component { id: userPkgsPage; UserPackagesPage { view: omni; category: section.pid.slice(13) } }
        Component { id: notePage; DocPage { view: omni; key: section.pid; titled: false } }
    }

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
        readonly property real actionWidth: omni.toastAction ? toastButton.implicitWidth + 12 : 0
        width: Math.min(toastText.implicitWidth + actionWidth + 28, omni.width - 32)
        height: toastText.implicitHeight + 16
        radius: 18
        color: Theme.toast
        Row {
            anchors.centerIn: parent
            spacing: 12
            Text {
                id: toastText
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, omni.width - 60 - parent.parent.actionWidth)
                text: omni.toast
                color: Theme.inkToast
                wrapMode: Text.Wrap
            }
            Text {
                id: toastButton
                visible: !!omni.toastAction
                anchors.verticalCenter: parent.verticalCenter
                text: omni.toastAction ? omni.toastAction.label : ""
                color: Theme.toast.hslLightness > 0.5 ? Theme.primaryContainer : Theme.primary
                font.weight: Font.Bold
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const run = omni.toastAction.run
                        omni.toast = ""
                        omni.toastAction = null
                        run()
                    }
                }
            }
        }
        // The toast stays while the cursor is on it
        HoverHandler { onHoveredChanged: hovered ? toastTimer.stop() : toastTimer.restart() }
    }

    //--- The tooltip a button or indicator asked for (Tip.qml), beside the cursor and
    //--- kept inside the view
    Rectangle {
        id: tipBox
        readonly property point at: omni.mapFromItem(null, Tip.at.x, Tip.at.y)
        z: 10
        visible: opacity > 0
        opacity: Tip.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
        width: Math.min(tipText.implicitWidth, 300) + 22
        height: tipText.implicitHeight + 14
        x: Math.max(4, Math.min(at.x + 14, omni.width - width - 4))
        y: at.y + 22 + height > omni.height - 4 ? at.y - height - 8 : at.y + 22
        radius: 10
        color: Theme.toast
        border.width: 1
        border.color: Qt.alpha(Theme.primary, 0.35)
        Text {
            id: tipText
            anchors.centerIn: parent
            width: Math.min(implicitWidth, 300)
            text: Tip.text
            color: Theme.inkToast
            font.pixelSize: 13
            wrapMode: Text.Wrap
        }
    }
}
