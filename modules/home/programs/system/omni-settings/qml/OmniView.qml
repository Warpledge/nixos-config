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
    property string tab: "main"
    property string page: "overview"
    property var lastPage: ({})
    property bool picking: false
    property bool reviewing: false
    property bool running: false
    property bool attached: false
    property string toast: ""

    property var pending: ({})
    readonly property int pendingCount: Object.keys(pending).length
    property string scope: ""  // a machine, or "" for all of them
    property var lists: ({})

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
        return out
    }
    readonly property var navItems: {
        const out = []
        if (info)
            for (const t of info.tabs)
                for (const g of info.nav[t.id])
                    for (const it of g.items)
                        out.push(Object.assign({ tab: t.id, group: g.title }, it))
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
                return
            }
            loadError = ""
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
            lastJob = { kind, args }
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
        search.text = ""
        bodyFlick.contentY = 0
    }

    function openFile(rel) {
        let editor = {}
        try {
            editor = JSON.parse(Quickshell.env("OMNI_SETTINGS_EDITOR") || "{}")
        } catch (e) {}
        Quickshell.execDetached((editor.launch || ["xdg-open"]).concat([`${info.flake}/${rel}`]))
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
        else if (reviewing) reviewing = false
        else if (running) running = false
        else omni.closeRequested()
    }

    //--------------------------------------------------------------------//
    //-- Layout
    //--------------------------------------------------------------------//
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10
        visible: !omni.reviewing && !omni.running && omni.sheet === null

        //--- Header
        RowLayout {
            Layout.fillWidth: true
            Item { implicitWidth: 32 }
            Text {
                text: "Omni Settings"
                color: Theme.text
                font.pixelSize: 16
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
            font.pixelSize: 12
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            Layout.leftMargin: 6
        }

        //--- Top tabs
        Rectangle {
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
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: active ? Theme.inkPrimary : Theme.dim
                            }
                        }
                        HoverHandler { id: tabHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: omni.go(modelData.id) }
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
                        Badge { icon: Theme.glyph(omni.current ? omni.current.icon : []); strong: true }
                        ColumnLayout {
                            spacing: 1
                            Layout.fillWidth: true
                            Text {
                                text: omni.current ? omni.current.title : omni.info ? "" : "Loading…"
                                color: Theme.text
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                            }
                            Text {
                                visible: text !== ""
                                text: omni.info && omni.info.pages[omni.page] ? omni.info.pages[omni.page].description
                                    : omni.current ? omni.current.subtitle || omni.current.group : ""
                                color: Theme.dim
                                font.pixelSize: 12
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
                                         icon: i.icon, subtitle: (omni.info.pages[i.id] || {}).description || i.subtitle || "" }))

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
            opacity: omni.picking ? 0.35 : 1
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

                Text {
                    visible: omni.loadError !== ""
                    text: omni.loadError
                    color: Theme.error
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    Layout.margins: 6
                }

                //--- What's New: template settings the user's files leave out
                Rectangle {
                    visible: !!omni.info && omni.info.whatsNew.length > 0 && omni.tab === "main"
                    Layout.fillWidth: true
                    implicitHeight: whatsNew.implicitHeight + 24
                    radius: 16
                    color: Theme.primaryContainer
                    ColumnLayout {
                        id: whatsNew
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8
                        Text {
                            readonly property int n: omni.info ? omni.info.whatsNew.length : 0
                            text: `${n} new setting${n === 1 ? "" : "s"} your files don't list yet`
                            color: Theme.inkContainer
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

                Loader {
                    Layout.fillWidth: true
                    active: !!omni.info && !!omni.info.pages[omni.page]
                    sourceComponent: SettingsPage {
                        model: omni.info.pages[omni.page]
                        view: omni
                    }
                }

                //--- Pages not made from the templates
                Loader {
                    Layout.fillWidth: true
                    active: !!omni.info && omni.custom[omni.page] !== undefined
                    sourceComponent: omni.custom[omni.page] || null
                }

                //--- Pages not ported yet
                ColumnLayout {
                    visible: !!omni.info && !omni.info.pages[omni.page] && omni.custom[omni.page] === undefined
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

    ConfirmDialog { id: confirm; anchors.fill: parent; z: 2 }

    //--- Custom pages by id; each is ported from the GTK app in turn
    readonly property var custom: ({ overview: overviewPage, shell: shellPage })
    Component { id: overviewPage; OverviewPage { view: omni } }
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
