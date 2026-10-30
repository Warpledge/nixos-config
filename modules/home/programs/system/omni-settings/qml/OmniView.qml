// Omni Settings' content, the same in the window and (later) DMS's slideout.
// Pending changes live here until Review hands them to api.py and the job service.
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: omni

    signal closeRequested

    property int edge: 6  // gap between the view and the window's edges, as the page frame's
    property int gutter: 8  // the part of `edge` left of the pages that holds their band
    property int frameInset: 6  // the page body inside its frame; clears the frame's corners
    readonly property int railGap: 30  // above each later group on the rail, room for its name
    readonly property int railItem: 36  // each page's icon on the rail, and its name's row
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
        onTriggered: {
            Backend.call("gitSummary", {}, reply => { if (reply.ok) omni.gitCounts = reply.data })
            Backend.call("firmwareSummary", {}, reply => { if (reply.ok) omni.firmwareUpdates = reply.data })
            Backend.call("summaries", {}, reply => { if (reply.ok) omni.summaries = reply.data })
        }
    }
    //--- api.py's `summaries`: cached update counts, crashes and backups, every minute
    property var summaries: null
    //--- Tabs with a page that has something waiting get a dot
    readonly property var tabAlerts: {
        const c = gitCounts || {}
        const u = summaries && summaries.updates
        return { main: !!(c.changed || c.ahead || c.behind || (u && (u.upstream || u.fixed))),
                 hardware: firmwareUpdates > 0 }
    }
    //--- Firmware updates waiting, for the page list; the Firmware page updates it too
    property int firmwareUpdates: 0

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
        if (info && info.sideRail)
            out[info.sideRail.key] = info.sideRail
        if (info && info.env)
            out[info.env.key] = info.env
        if (info && info.autostart)
            out[info.autostart.key] = info.autostart
        if (info && info.mimeTypes)
            out[info.mimeTypes.key] = info.mimeTypes
        if (info && info.gpuOffload)
            out[info.gpuOffload.key] = info.gpuOffload
        if (info && info.steamGames)
            out[info.steamGames.key] = info.steamGames
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
                subtitle: `${userPackages(false)[c] ? userPackages(false)[c].length : 0} installed. `
                          + "Move one to list it under another category." })))
        return out
    }
    readonly property var current: navItems.find(i => i.id === page) || null
    //--- The current tab's pages, in its scroll order. Search sits pinned above the
    //--- Packages scroll, and All user packages shows only while there's no category
    readonly property var tabPages: navItems.filter(i => i.tab === tab && i.id !== "packages"
                                                    && !(i.id === "userpackages" && packageCategories.length))
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
                openPages = set(ui.openPages)
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

    //--- Whether a job may start now; says why not
    function canStart() {
        if (!info || !info.canApply || !info.admin)
            return false
        if (pendingCount) {
            say("Apply or discard your changes first")
            return false
        }
        if (Jobs.running) {
            say("Another job is running; wait for it to finish")
            return false
        }
        return true
    }

    function rebuild() {
        if (!canStart())
            return
        ask({
            heading: "Rebuild now?",
            body: "Rebuilds from your settings files as they are (nixos-rebuild switch). At Next "
                  + "Restart uses nixos-rebuild boot; Preview only builds and shows what would change.",
            buttons: [{ label: "Preview", value: "build", quiet: true },
                      { label: "At Next Restart", value: "boot", quiet: true },
                      { label: "Rebuild Now", value: "switch" }]
        }, mode => startJob("rebuild", { mode }))
    }

    //--- A page's settings that differ from the template's default, leaving out locked ones
    function changedOn(model) {
        const out = []
        if (model)
            for (const g of model.groups)
                if (!g.locked)
                    for (const s of g.settings)
                        for (const t of s.pair ? [s, s.pair] : [s])
                            if (!same(valueOf(t), t.default))
                                out.push(t)
        return out
    }
    function resetPage(model) {
        const list = changedOn(model)
        ask({ heading: `Reset ${model.title}?`,
              body: `Puts ${list.length === 1 ? "one setting" : `${list.length} settings`} back to the `
                    + "default, as changes waiting for Apply.",
              buttons: [{ label: "Reset", value: "reset" }] },
            () => { for (const s of list) change(s, s.default) })
    }

    //--- The line under a collapsed page's title: {text, alert}, or null for its description
    function pageSummary(pid, model) {
        const plural = (n, word) => `${n} ${word}${n === 1 ? "" : "s"}`
        if (pid === "git" && gitCounts) {
            const c = gitCounts
            return { text: `${c.branch ? c.branch + " · " : ""}${gitTag}`, alert: !!(c.changed || c.ahead || c.behind) }
        }
        if (pid === "updates" && summaries) {
            const u = summaries.updates
            if (!u)
                return { text: "Not checked yet", alert: false }
            const parts = [u.upstream ? `${plural(u.upstream, "update")} upstream` : "",
                           u.fixed ? `${plural(u.fixed, "disabled package")} fixed` : ""].filter(p => p)
            return { text: parts.join(" · ") || "Up to date", alert: parts.length > 0 }
        }
        if (pid === "backups" && summaries && summaries.backups.length) {
            const last = Math.max(...summaries.backups.map(b => b.last || 0))
            return { text: summaries.backups.map(b => b.title).join(", ")
                           + (last ? ` · last ${Fmt.ago(last)}` : " · none yet"), alert: false }
        }
        if (pid === "overview" && summaries && summaries.crashes)
            return { text: `${plural(summaries.crashes, "crash")} in 30 days`, alert: false }
        if (pid === "firmware" && firmwareUpdates > 0)
            return { text: `${plural(firmwareUpdates, "update")} waiting`, alert: true }
        if (pid === "page:Services" && servicesRunning >= 0)
            return { text: `${servicesRunning} running`, alert: false }
        // A generated page: its first values, a switch by its name while it's on
        if (model && !pid.startsWith("doc:")) {
            const parts = []
            for (const g of model.groups)
                for (const s of g.settings) {
                    const v = valueOf(s)
                    if (s.kind === "bool") {
                        if (v)
                            parts.push(s.title)
                    } else if (!(s.kind === "list" && !(v || []).length)) {
                        parts.push(s.kind === "number" ? `${s.title} ${shownOf(s, v)}` : shownOf(s, v))
                    }
                }
            if (parts.length)
                return { text: parts.slice(0, 3).join(" · ") + (parts.length > 3 ? " …" : ""), alert: false }
        }
        return null
    }

    //--- Scrolls the tab bar so the current tab shows whole
    function showTab(item) {
        const f = tabsFlick
        if (f.contentWidth <= f.width)
            return
        const left = item.x - 24, right = item.x + item.width + 24
        if (left < f.contentX)
            f.contentX = Math.max(0, left)
        else if (right > f.contentX + f.width)
            f.contentX = Math.min(f.contentWidth - f.width, right - f.width)
    }

    function startReview() {
        if (!info || !info.canApply || Jobs.running)
            return
        reviewing = true
        review.load()
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
        else if (pageId && !openPages[pageId])
            setPageOpen(pageId, true)
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
        const top = topSection()
        if (!top)
            return
        anchorPage = top.pid
        anchorOffset = bodyFlick.contentY - top.y
    }
    //--- The section under the view's top edge
    function topSection() {
        const y = bodyFlick.contentY
        let top = null
        for (let i = 0; i < sections.count; i++) {
            const s = sections.itemAt(i)
            if (s && s.visible && (s.y <= y || !top))
                top = s
        }
        return top
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

    //--- Open pages and open group cards, kept in api.py's UI_STATE; both start shut
    property var openPages: ({})
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
    function setPageOpen(pid, open) {
        const c = Object.assign({}, openPages)
        if (open)
            c[pid] = true
        else
            delete c[pid]
        openPages = c
        saveUi()
    }
    function saveUi() {
        Backend.call("saveUi", { openPages: Object.keys(openPages), open: Object.keys(openCards) }, () => {})
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
    //--- The border the page scrolls under, drawn round the body Flickable
    Rectangle {
        id: bodyFrame
        visible: mainCol.visible && bodyFlick.visible
        x: mainCol.x + bodyFlick.x - omni.frameInset
        y: mainCol.y + bodyFlick.y - omni.frameInset
        width: bodyFlick.width + 2 * omni.frameInset
        height: bodyFlick.height + 2 * omni.frameInset
        radius: 20
        color: "transparent"
        border.width: 1
        border.color: Qt.alpha(Theme.primary, 0.22)
    }
    //--- Holds the pinned page header (stickyHead) to the frame, so it can be pushed up
    //--- out of sight at its page's end
    Item {
        id: stickyClip
        visible: bodyFrame.visible
        x: bodyFrame.x
        y: bodyFrame.y
        width: bodyFrame.width
        height: bodyFrame.height
        clip: true
        z: 3
    }

    //--- Across the whole width, over the rail too
    StatusHeader {
        id: statusHeader
        view: omni
        visible: mainCol.visible || runSheet.visible
        barOnly: runSheet.visible
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: omni.edge
    }

    ColumnLayout {
        id: mainCol
        anchors.top: statusHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: omni.edge
        anchors.topMargin: 10
        anchors.rightMargin: omni.edge + rail.width + 6
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

        //--- Top tabs: icons, the current one a filled pill with its name. Spread across
        //--- the width when they fit, else scrolled sideways with faded edges
        Rectangle {
            id: tabsBar
            Layout.fillWidth: true
            implicitHeight: 54
            radius: 16
            color: Theme.card
            Flickable {
                id: tabsFlick
                anchors.fill: parent
                anchors.margins: 4
                contentWidth: tabsRow.width
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                // A wheel scrolls sideways here
                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: event => {
                        const d = event.angleDelta.y || event.angleDelta.x
                        tabsFlick.contentX = Math.max(0, Math.min(tabsFlick.contentWidth - tabsFlick.width,
                                                                  tabsFlick.contentX - d))
                    }
                }
                Row {
                    id: tabsRow
                    readonly property real cells: {
                        let w = 0
                        for (let i = 0; i < children.length; i++)
                            if (children[i].visible)
                                w += children[i].width
                        return w
                    }
                    readonly property int n: omni.info ? omni.info.tabs.length : 1
                    height: tabsFlick.height
                    spacing: Math.max(2, (tabsFlick.width - cells) / Math.max(1, n - 1))
                    Repeater {
                        model: omni.info ? omni.info.tabs : []
                        Rectangle {
                            id: tab
                            required property var modelData
                            readonly property bool active: omni.tab === modelData.id
                            onActiveChanged: if (active) omni.showTab(tab)
                            width: active ? tabLabel.x + tabLabel.implicitWidth + 16 : 46
                            height: 46
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            radius: 13
                            clip: true
                            color: active ? Qt.alpha(Theme.primary, 0.28) : tabHover.hovered ? Theme.hover : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Icon {
                                id: tabIcon
                                x: tab.active ? 13 : 11
                                anchors.verticalCenter: parent.verticalCenter
                                icon: Theme.glyph(tab.modelData.icon)
                                size: 24
                                fill: tab.active
                                color: tab.active ? Theme.primary : tabHover.hovered ? Theme.text : Theme.dim
                                // Something waiting on one of the tab's pages
                                Rectangle {
                                    visible: !!omni.tabAlerts[tab.modelData.id]
                                    x: parent.width - 5
                                    y: -1
                                    width: 8; height: 8; radius: 4
                                    color: Theme.caution
                                    border.width: 1.5
                                    border.color: Theme.card
                                }
                            }
                            Text {
                                id: tabLabel
                                x: 45
                                anchors.verticalCenter: parent.verticalCenter
                                text: tab.modelData.title
                                font.pixelSize: 14
                                font.weight: Font.Bold
                                color: Theme.primary
                                opacity: tab.active ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }
                            readonly property point cursor: tabHover.point.scenePosition
                            onCursorChanged: Tip.move(tab, cursor)
                            HoverHandler {
                                id: tabHover
                                cursorShape: Qt.PointingHandCursor
                                onHoveredChanged: hovered && !tab.active
                                    ? Tip.request(tab, tab.modelData.title, point.scenePosition) : Tip.cancel(tab)
                            }
                            TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: omni.go(tab.modelData.id) }
                        }
                    }
                }
            }
            //--- Where more tabs are scrolled out of sight: a fade and an arrow that pans
            //--- that way, each only while there's more that way
            TabArrow { toLeft: true; shown: tabsFlick.contentX > 1 }
            TabArrow { toLeft: false; shown: tabsFlick.contentX + tabsFlick.width < tabsFlick.contentWidth - 1 }
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
                            if (!omni.openPages[r.page])
                                omni.setPageOpen(r.page, true)
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
                                 ? `${omni.servicesRunning} running`
                                 : modelData.page === "firmware" && omni.firmwareUpdates > 0
                                 ? `${omni.firmwareUpdates} update${omni.firmwareUpdates === 1 ? "" : "s"}` : ""
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

        //--- Page body, inset in its frame (bodyFrame)
        Flickable {
            id: bodyFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: omni.frameInset  // the frame lines up with the header and tabs
            Layout.rightMargin: omni.frameInset
            Layout.topMargin: omni.frameInset
            Layout.bottomMargin: omni.frameInset
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

            //--- The open page's header, pinned while its own has scrolled away; pushed
            //--- up by the page's end
            Rectangle {
                id: stickyHead
                readonly property var sec: {
                    const y = bodyFlick.contentY
                    const s = sections.count ? omni.topSection() : null
                    return s && s.open && s.headed && y > s.y + s.headBottom ? s : null
                }
                // The last page pinned, kept while it fades out
                property var shown: null
                onSecChanged: if (sec) shown = sec
                // Flush with the frame's top and sides (stickyClip), over the inset too
                parent: stickyClip
                width: stickyClip.width
                height: stickyRow.implicitHeight + 16 + omni.frameInset
                y: shown ? Math.min(0, shown.y + shown.height - bodyFlick.contentY + omni.frameInset - height) : 0
                visible: opacity > 0
                opacity: sec ? (omni.picking || packageSearch.open ? 0.35 : 1) : 0
                Behavior on opacity { NumberAnimation { duration: 120 } }
                radius: bodyFrame.radius
                color: Qt.tint(Theme.bg, Qt.alpha(Theme.text, stickyHover.hovered ? 0.09 : 0.06))
                border.width: 1
                border.color: bodyFrame.border.color
                // Square bottom corners, keeping the frame's side edges
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: parent.radius
                    color: parent.color
                    Rectangle { width: 1; height: parent.height; color: stickyHead.border.color }
                    Rectangle { x: parent.width - 1; width: 1; height: parent.height; color: stickyHead.border.color }
                }
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Theme.rule
                }
                RowLayout {
                    id: stickyRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: omni.frameInset / 2
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 12
                    Rectangle {
                        implicitWidth: 30
                        implicitHeight: 30
                        radius: 15
                        color: Theme.primary
                        Icon {
                            anchors.centerIn: parent
                            icon: stickyHead.shown ? Theme.glyph(stickyHead.shown.modelData.icon, "description") : ""
                            size: 17
                            fill: true
                            color: Theme.inkPrimary
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: stickyHead.shown ? stickyHead.shown.modelData.title : ""
                        color: Theme.text
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }
                    Chevron { open: true; lit: stickyHover.hovered }
                }
                HoverHandler { id: stickyHover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    gesturePolicy: TapHandler.ReleaseWithinBounds
                    onTapped: {
                        const s = stickyHead.sec
                        if (!s)
                            return
                        omni.scrollTo(s.pid)
                        s.toggle()
                    }
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
                    onClicked: omni.startReview()
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
        anchors.topMargin: mainCol.y + tabsBar.y + tabsBar.height  // level with the tabs' foot
        // As tall as its icons, up to the window's bottom margin
        height: Math.min(railList.contentHeight + 8, parent.height - anchors.topMargin - omni.edge)
        width: omni.railItem + 8
        radius: width / 2
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
                width: railList.width
                //--- A line where the page list starts a new group; its name shows here
                //--- with the page names (railNames)
                Item {
                    visible: !!railItem.prev && railItem.prev.group !== railItem.modelData.group
                    width: parent.width
                    height: omni.railGap
                    Rectangle {
                        anchors.centerIn: parent
                        width: 26
                        height: 1
                        color: Qt.alpha(Theme.primary, 0.35)
                    }
                }
                Rectangle {
                    width: parent.width
                    height: omni.railItem
                    radius: height / 2
                    color: railItem.active ? Theme.primary : railHover.hovered ? Theme.hover : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Icon {
                        anchors.centerIn: parent
                        icon: Theme.glyph(railItem.modelData.icon)
                        size: 20
                        fill: railItem.active
                        color: railItem.active ? Theme.inkPrimary : Theme.primary
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
        // The gap to the rail counts as hovering the names; the fade sits left of them
        width: namesCol.implicitWidth + 8 + fade
        readonly property real fade: 36
        clip: true
        HoverHandler { id: namesArea }
        // Hides the page behind the names so they read on any page
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: railNames.fade / railNames.width; color: Qt.alpha(Theme.bg, 0.96) }
                GradientStop { position: 1; color: Theme.bg }
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
                    //--- The group's name over the rail's line
                    // Each part right-aligned, so a wide caption doesn't push its name left
                    Item {
                        visible: !!nameItem.prev && nameItem.prev.group !== nameItem.modelData.group
                        x: nameItem.width - width
                        width: groupCaption.implicitWidth + 8
                        height: omni.railGap
                        Text {
                            id: groupCaption
                            anchors.right: parent.right
                            anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter  // level with the rail's line
                            text: nameItem.modelData.group
                            color: Theme.dim
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            font.capitalization: Font.AllUppercase
                            font.letterSpacing: 0.6
                        }
                    }
                    Item {
                        x: nameItem.width - width
                        width: namePill.width
                        height: omni.railItem
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
        id: runSheet
        anchors.top: statusHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: omni.edge
        anchors.topMargin: 10
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
                                      flatpaks: flatpaksPage, backups: backupsPage, updates: updatesPage,
                                      people: peoplePage,
                                      userpackages: userPackagesPage,
                                      proton: protonPage, protonversions: protonVersionsPage,
                                      games: gamesPage, mangohud: mangoHudPage,
                                      windowrules: windowRulesPage, keybinds: keybindsPage,
                                      siderail: sideRailPage,
                                      startup: startupPage, filetypes: fileTypesPage,
                                      firmware: firmwarePage, battery: batteryPage, dgpu: dgpuPage,
                                      scheduler: schedulerPage,
                                      nettools: networkToolsPage, apparmor: appArmorPage })
    Component { id: networkToolsPage; NetworkToolsPage { view: omni } }
    Component { id: appArmorPage; AppArmorPage { view: omni } }
    Component { id: firmwarePage; FirmwarePage { view: omni } }
    Component { id: batteryPage; BatteryPage { view: omni } }
    Component { id: dgpuPage; DgpuPage { view: omni } }
    Component { id: schedulerPage; SchedulerPage { view: omni } }
    Component { id: windowRulesPage; WindowRulesPage { view: omni } }
    Component { id: sideRailPage; SideRailPage { view: omni } }
    Component { id: keybindsPage; KeybindsPage { view: omni } }
    Component { id: startupPage; StartupPage { view: omni } }
    Component { id: fileTypesPage; FileTypesPage { view: omni } }
    Component { id: protonPage; ProtonPage { view: omni } }
    Component { id: protonVersionsPage; ProtonVersionsPage { view: omni } }
    Component { id: gamesPage; GamesPage { view: omni } }
    Component { id: mangoHudPage; MangoHudPage { view: omni } }
    component TabArrow: Rectangle {
        id: arrow
        property bool toLeft
        property bool shown
        visible: opacity > 0
        opacity: shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
        anchors.left: toLeft ? tabsFlick.left : undefined
        anchors.right: toLeft ? undefined : tabsFlick.right
        anchors.top: tabsFlick.top
        anchors.bottom: tabsFlick.bottom
        width: 34
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: arrow.toLeft ? Theme.card : Qt.alpha(Theme.card, 0) }
            GradientStop { position: arrow.toLeft ? 0.6 : 0.4; color: Theme.card }
            GradientStop { position: 1; color: arrow.toLeft ? Qt.alpha(Theme.card, 0) : Theme.card }
        }
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            x: arrow.toLeft ? 0 : parent.width - width
            icon: arrow.toLeft ? "chevron_left" : "chevron_right"
            size: 20
            color: arrowHover.hovered ? Theme.primary : Theme.dim
        }
        HoverHandler { id: arrowHover; cursorShape: Qt.PointingHandCursor }
        TapHandler {
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: {
                const f = tabsFlick
                f.contentX = Math.max(0, Math.min(f.contentWidth - f.width,
                                                  f.contentX + (arrow.toLeft ? -1 : 1) * f.width * 0.6))
            }
        }
    }

    //--- One page in the tab's scroll: its section's divider when it starts one, then
    //--- the page in a card whose header collapses it; a note starts collapsed
    component PageSection: ColumnLayout {
        id: section
        required property var modelData
        required property int index
        readonly property string pid: modelData.id
        readonly property bool note: pid.startsWith("doc:")
        readonly property bool userPkgs: pid.startsWith("userpackages:")
        readonly property bool open: note ? !!omni.openNotes[pid] : !!omni.openPages[pid]
        readonly property var model: omni.info.pages[pid] || null
        readonly property var comp: note ? notePage : userPkgs ? userPkgsPage
            : omni.custom[pid] || (model ? settingsPage : null)
        readonly property bool ready: !loader.item || loader.item.ready !== false
        readonly property var summary: omni.pageSummary(pid, model)
        readonly property var changed: omni.changedOn(model)
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
                omni.setPageOpen(pid, !open)
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
        // Where the header ends, for the sticky copy over the scroll (stickyHead)
        readonly property real headBottom: card.y + head.y + head.height
        visible: !!comp
        Layout.fillWidth: true
        Layout.topMargin: index === 0 ? 0 : divided ? 22 : 14
        spacing: 6

        //--- The section's name, then a rule to the edge
        RowLayout {
            visible: section.divided && section.sectionTitle !== ""
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.bottomMargin: 6
            spacing: 10
            Text {
                text: section.sectionTitle
                color: Theme.text
                font.pixelSize: 15
                font.weight: Font.Bold
            }
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.rule }
        }

        //--- The page's card, reaching into the gutter; every other card a shade lighter
        Rectangle {
            id: card
            Layout.fillWidth: true
            Layout.leftMargin: -omni.gutter
            implicitHeight: frameCol.implicitHeight
            radius: 20
            color: Qt.alpha(Theme.text, (section.index % 2 ? 0.075 : 0.035)
                                        + (section.headed && headHover.hovered && !section.open ? 0.03 : 0))
            // An open page is edged in primary; the one under the cursor gets a firmer
            // ring like niri's focus ring, so the page being read is easy to find
            border.width: !section.headed ? 0 : cardHover.hovered ? 2 : 1
            border.color: cardHover.hovered ? Theme.primary
                : section.open ? Qt.alpha(Theme.primary, 0.45) : Theme.rule
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }
            HoverHandler { id: cardHover; enabled: section.headed }

            ColumnLayout {
                id: frameCol
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 0

                //--- Header: icon, name, one line under it, then what's changed and the
                //--- chevron; tapping it collapses
                RowLayout {
                    id: head
                    visible: section.headed
                    Layout.fillWidth: true
                    Layout.margins: 12
                    spacing: 12
                    Rectangle {
                        implicitWidth: 34
                        implicitHeight: 34
                        radius: 17
                        color: section.open ? Theme.primary : Theme.cardHover
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Icon {
                            anchors.centerIn: parent
                            icon: Theme.glyph(section.modelData.icon, "description")
                            size: 19
                            fill: section.open
                            color: section.open ? Theme.inkPrimary : Theme.primary
                        }
                    }
                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        Text {
                            id: pageTitle
                            Layout.fillWidth: true
                            text: section.modelData.title
                            color: Theme.text
                            font.pixelSize: section.open ? 17 : 15
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }
                        // Collapsed, what's inside (pageSummary); open, what the page is for
                        Text {
                            readonly property var sum: section.open ? null : section.summary
                            readonly property string about: section.modelData.subtitle
                                || (section.model ? section.model.description : "")
                            visible: text !== ""
                            Layout.fillWidth: true
                            text: sum ? sum.text : about
                            color: sum && sum.alert ? Theme.caution : Theme.dim
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }
                    // Settings away from their default, and putting them back
                    Rectangle {
                        visible: section.changed.length > 0
                        implicitWidth: changedText.implicitWidth + 18
                        implicitHeight: 24
                        radius: 8
                        color: Qt.alpha(Theme.primary, resetHover.hovered ? 0.3 : 0.18)
                        Text {
                            id: changedText
                            anchors.centerIn: parent
                            text: `${section.changed.length} changed · Reset`
                            color: Theme.primary
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                        HoverHandler { id: resetHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            gesturePolicy: TapHandler.ReleaseWithinBounds
                            onTapped: omni.resetPage(section.model)
                        }
                    }
                    Chevron { open: section.open; lit: headHover.hovered }
                    HoverHandler { id: headHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: section.toggle() }
                }
                Rectangle {
                    visible: section.headed && body.height > 0
                    Layout.fillWidth: true
                    implicitHeight: 1
                    opacity: body.opacity
                    color: Theme.rule
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
    Component { id: updatesPage; UpdatesPage { view: omni } }
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
        width: Math.min(tipText.implicitWidth, 340) + 22
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
            width: Math.min(implicitWidth, 340)
            text: Tip.text
            textFormat: Tip.rich ? Text.StyledText : Text.PlainText
            color: Theme.inkToast
            font.pixelSize: 14
            lineHeight: 1.1
            wrapMode: Text.Wrap
        }
    }
}
