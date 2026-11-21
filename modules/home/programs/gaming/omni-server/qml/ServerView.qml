// The app: server rail, header and tabs, and the live data every page reads. Live data
// comes from one `watch` backend process for the selected server.
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: app

    property var servers: []
    property string currentId: ""
    readonly property var server: servers.find(s => s.id === currentId) || null
    property string tab: "dash"
    property bool loaded: false

    //--- From systemd: state, pid, boot, result; from the monitor: stats while it runs
    property var status: ({ state: "stopped", active: false })
    property var stats: null
    property var pending: ({})
    property var quick: []
    property var addonSuggestions: []
    property var schedule: ({})
    property real dimThreshold: 1  // ms; kept here as the Dashboard is rebuilt on each tab
    property var watcher: null
    readonly property string state_: status.state || "stopped"
    readonly property bool running: state_ === "running" || state_ === "starting" || state_ === "stopping"
    readonly property bool wide: width >= 980
    readonly property int railWidth: 56
    readonly property bool busy: state_ === "starting" || state_ === "stopping" || state_ === "restarting"
                                 || (state_ === "running" && !!stats && !stats.ready)
    readonly property bool ready: state_ === "running" && !!stats && !!stats.ready
    property bool bootSeen: false  // saw this server start up, so `ready` is news
    property real now: Date.now() / 1000  // ticks while running, for the uptime
    //--- Ctrl+F and Ctrl+K: the page that has the field picks these up once loaded
    property bool searchWanted: false
    property bool commandWanted: false

    onBusyChanged: if (busy) bootSeen = true
    onReadyChanged: if (ready && bootSeen) {
        bootSeen = false
        readyGlow.restart()
        toast(`${server ? server.name : "The server"} is ready`, "success")
    }

    signal consoleLine()  // a new line reached consoleModel
    ListModel { id: consoleLines }
    ListModel { id: chatLines }
    readonly property alias consoleModel: consoleLines
    readonly property alias chatModel: chatLines
    property int consoleCap: 3000

    readonly property var tabs: [
        { id: "dash", icon: "dashboard", title: "Dashboard" },
        { id: "console", icon: "terminal", title: "Console" },
        { id: "players", icon: "group", title: "Players" },
        { id: "settings", icon: "tune", title: "Settings" },
        { id: "backups", icon: "archive", title: "Backups" },
        { id: "mods", icon: "extension", title: "Mods" },
        { id: "schedule", icon: "event_repeat", title: "Schedule" },
        { id: "addons", icon: "widgets", title: "Add-ons" },
        { id: "prefs", icon: "palette", title: "Preferences" }
    ]
    //--- With no server only Preferences has anything to show
    readonly property var shownTabs: server ? tabs : tabs.filter(t => t.id === "prefs")

    //--------------------------------------------------------------------//
    //-- Backend
    //--------------------------------------------------------------------//

    //--- A call for the selected server; `done` on success, a failure shows the error
    function call(cmd, args, done) {
        Backend.call(cmd, Object.assign({ id: currentId }, args || {}), reply => {
            if (!reply.ok)
                showError(reply.error)
            else if (done)
                done(reply)
        })
    }

    function refreshServers(done) {
        Backend.call("servers_list", {}, reply => {
            if (!reply.ok)
                return
            app.servers = reply.servers
            app.loaded = true
            if (!app.currentId && reply.servers.length)
                app.select(reply.servers[0].id)
            if (done)
                done()
        })
    }

    function refreshServer() {
        if (currentId)
            call("server_get", {}, reply => {
                app.quick = reply.quick
                app.addonSuggestions = reply.addonSuggestions
                app.schedule = reply.schedule
                app.dimThreshold = reply.dimThreshold
            })
    }

    function select(id) {
        if (watcher) {
            watcher.running = false
            watcher = null
        }
        currentId = id
        stats = null
        bootSeen = false
        status = { state: "stopped", active: false }
        pending = {}
        consoleLines.clear()
        chatLines.clear()
        refreshServer()
        if (id)
            watcher = Backend.stream("watch", { id }, line => app.onWatch(line), null)
    }

    function onWatch(line) {
        let msg
        try {
            msg = JSON.parse(line)
        } catch (e) {
            return
        }
        if (msg.type === "status") {
            app.status = msg.status
            app.pending = msg.pending
        } else if (msg.type === "hello") {
            consoleLines.clear()
            chatLines.clear()
            app.stats = msg.state
            addLines(msg.lines)
        } else if (msg.type === "state") {
            app.stats = msg.state
        } else if (msg.type === "lines") {
            addLines(msg.lines)
        } else if (msg.type === "past") {
            addLines(msg.lines)
        } else if (msg.type === "gone") {
            app.stats = null
            refreshServers()
        }
    }

    function addLines(lines) {
        for (const event of lines) {
            if (event.hidden)
                continue
            consoleLines.append({
                time: event.time || "", level: event.level || "", body: event.text || "",
                kind: event.kind || ""
            })
            if (event.kind === "chat" || event.kind === "join" || event.kind === "leave") {
                chatLines.append({
                    time: event.time || "", kind: event.kind, name: event.name || "",
                    message: event.message || ""
                })
            }
        }
        if (consoleLines.count > consoleCap)
            consoleLines.remove(0, consoleLines.count - consoleCap)
        if (chatLines.count > 500)
            chatLines.remove(0, chatLines.count - 500)
        consoleLine()
    }

    function send(text) {
        if (text.trim())
            call("send", { text })
    }

    //--------------------------------------------------------------------//
    //-- Actions
    //--------------------------------------------------------------------//

    function addServer() {
        Backend.call("pick_folder", {}, reply => {
            if (!reply.ok)
                return showError(reply.error)
            if (!reply.folder)
                return
            Backend.call("add", { dir: reply.folder }, added => {
                if (!added.ok)
                    return showError(added.error)
                refreshServers(() => {
                    select(added.server.id)
                    ask({
                        heading: "Turn on live stats?",
                        body: "TPS and player counts are polled over RCON, which keeps them out of the "
                            + "server's log. This sets a generated password in server.properties. "
                            + "RCON listens on every network interface, so keep its port closed in your firewall.",
                        buttons: [{ label: "Turn on", value: "on" }, { label: "Not now", value: "off", quiet: true }],
                        cancel: false
                    }, value => {
                        if (value === "on")
                            call("rcon_set", { on: true })
                    })
                })
            })
        })
    }

    function start() { call("start", {}, () => refreshServers()) }

    function stop() {
        const online = stats ? stats.players.length : 0
        ask({
            heading: "Stop the server?",
            body: online ? `${online} player${online > 1 ? "s are" : " is"} online. The world saves first.`
                         : "The world saves first.",
            buttons: [{ label: "Stop", value: "stop" }]
        }, () => call("stop", {}, () => refreshServers()))
    }

    function restart() {
        ask({
            heading: "Restart the server?",
            body: "Players are disconnected while it restarts. The world saves first.",
            buttons: [{ label: "Restart", value: "restart" }]
        }, () => call("restart", {}, () => refreshServers()))
    }

    function kill() {
        ask({
            heading: "Kill the server?",
            body: "Anything since the last save is lost. Use this only when Stop hangs.",
            buttons: [{ label: "Kill", value: "kill", danger: true }]
        }, () => call("kill", {}, () => refreshServers()))
    }

    //--- Runs a quick command: asks for any {placeholder}, then confirms if it wants to
    function runQuick(item) {
        const found = []
        for (const step of item.steps) {
            const words = /\{([a-z]+)\}/g
            let m
            while ((m = words.exec(step.command)))
                if (!found.includes(m[1]))
                    found.push(m[1])
        }
        const go = answers => call("quick_run", { name: item.name, steps: item.steps, answers },
                                   () => toast(`Ran ${item.name}`, "success"))
        const confirmed = answers => {
            if (!item.confirm)
                return go(answers)
            ask({ heading: `Run ${item.name}?`, body: item.steps.map(s => s.command).join("\n"),
                  buttons: [{ label: "Run", value: "run" }] }, () => go(answers))
        }
        if (found.length)
            prompt.open(item.name, found, confirmed)
        else
            confirmed({})
    }

    function ask(spec, callback) { dialog.open(spec, callback) }
    function askText(heading, fields, callback) { prompt.open(heading, fields, callback) }

    //--- A message at the bottom: tone "error" (the default), "success" or "info"
    function toast(text, tone) {
        toastBox.tone = tone || "error"
        toastBox.text = text
        toastBox.up = true
        toastTimer.interval = toastBox.tone === "error" ? 7000 : 3500
        toastTimer.restart()
    }
    function showError(text) { toast(text, "error") }

    //--- The server's join address on the clipboard: public, or this network's with lan
    function copyAddress(lan) {
        call("join_address", { lan: !!lan }, reply => {
            Quickshell.clipboardText = reply.address
            if (reply.fallback)
                toast(`Couldn't find the public address; copied the LAN one, ${reply.address}`, "info")
            else
                toast(`Copied ${reply.address}`, "success")
        })
    }
    function openFolder() {
        if (server)
            Quickshell.execDetached(["xdg-open", server.dir])
    }

    function statusWord() {
        const s = state_
        if (s === "running") {
            if (!stats || !stats.ready)
                return "Starting"
            const up = Math.max(0, now - stats.startedAt)
            const hours = Math.floor(up / 3600), minutes = Math.floor(up / 60) % 60
            // Seconds only in the first hour, where they still say something
            return hours ? `Running ${hours}h ${minutes}m` : `Running ${minutes}m ${Math.floor(up % 60)}s`
        }
        return ({ starting: "Starting", stopping: "Stopping", restarting: "Restarting after a crash",
                  failed: "Crashed", outside: "Running outside Omni Server", stopped: "Stopped" })[s] || s
    }

    function statusTone() {
        const s = state_
        return s === "running" && stats && stats.ready ? "success"
            : s === "failed" ? "error"
            : s === "stopped" ? "" : "caution"
    }

    Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: app.refreshServers()
    }
    Timer {
        interval: 1000
        running: app.state_ === "running"
        repeat: true
        triggeredOnStart: true
        onTriggered: app.now = Date.now() / 1000
    }

    //--- Ctrl+1 to 9 pick a tab, Ctrl+F searches the console, Ctrl+K goes to the command
    //--- line, Ctrl+, opens Preferences. Fields pass these up, as they don't use them.
    Keys.onPressed: event => {
        if (!(event.modifiers & Qt.ControlModifier))
            return
        const n = event.key - Qt.Key_1
        if (n >= 0 && n < app.shownTabs.length) {
            app.tab = app.shownTabs[n].id
        } else if (event.key === Qt.Key_F && app.server) {
            app.tab = "console"
            app.searchWanted = true
        } else if (event.key === Qt.Key_K && app.server) {
            if (app.tab !== "dash" && app.tab !== "console")
                app.tab = "console"
            app.commandWanted = true
        } else if (event.key === Qt.Key_Comma) {
            app.tab = "prefs"
        } else {
            return
        }
        event.accepted = true
    }

    //--------------------------------------------------------------------//
    //-- Layout
    //--------------------------------------------------------------------//

    Rectangle {
        id: rail
        width: app.railWidth
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        color: Theme.card

        Flickable {
            anchors.fill: parent
            anchors.topMargin: 12
            contentHeight: railCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            //--- A bar at the rail's edge that slides to the chosen server
            Rectangle {
                readonly property int at: app.servers.findIndex(s => s.id === app.currentId)
                readonly property Item item: at >= 0 && railRepeater.count > at ? railRepeater.itemAt(at) : null
                visible: !!item
                x: 0
                y: item ? item.y + (item.height - height) / 2 : 0
                width: 4
                height: item ? 22 : 0
                radius: 2
                color: Theme.primary
                Behavior on y { NumberAnimation { duration: Theme.ms(280); easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: Theme.ms(200); easing.type: Easing.OutBack } }
            }
            Column {
                id: railCol
                width: parent.width
                spacing: 8
                Repeater {
                    id: railRepeater
                    model: app.servers
                    Rectangle {
                        id: railItem
                        required property var modelData
                        readonly property bool chosen: modelData.id === app.currentId
                        readonly property string st: modelData.status.state
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 40
                        height: 40
                        radius: Theme.r(12)
                        color: chosen ? Qt.alpha(Theme.primary, 0.3) : itemHover.hovered ? Theme.hover : "transparent"
                        border.width: 1
                        border.color: chosen ? Theme.primary : Theme.rule
                        scale: railTap.pressed ? 0.94 : itemHover.hovered && !chosen ? 1.06 : 1
                        Behavior on scale { NumberAnimation { duration: Theme.ms(160); easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: Theme.ms(160) } }
                        Behavior on border.color { ColorAnimation { duration: Theme.ms(160) } }
                        Text {
                            anchors.centerIn: parent
                            text: railItem.modelData.tag
                            textFormat: Text.PlainText
                            color: railItem.chosen ? Theme.text : Theme.dim
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                        Rectangle {
                            id: dot
                            readonly property bool changing: ["starting", "stopping", "restarting"].includes(railItem.st)
                            visible: railItem.st !== "stopped"
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: -2
                            width: 12
                            height: 12
                            radius: 6
                            border.width: 2
                            border.color: Theme.card
                            color: railItem.st === "running" ? Theme.success
                                : railItem.st === "failed" ? Theme.error : Theme.caution
                            Behavior on color { ColorAnimation { duration: Theme.ms(300) } }
                            //--- Breathes while the server starts or stops
                            SequentialAnimation on opacity {
                                running: dot.changing && Theme.motion > 0
                                loops: Animation.Infinite
                                alwaysRunToEnd: true
                                NumberAnimation { to: 0.35; duration: 650; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1; duration: 650; easing.type: Easing.InOutSine }
                            }
                        }
                        HoverHandler {
                            id: itemHover
                            cursorShape: Qt.PointingHandCursor
                            onHoveredChanged: hovered
                                ? Tip.request(railItem, railItem.modelData.name, point.scenePosition)
                                : Tip.cancel(railItem)
                        }
                        TapHandler {
                            id: railTap
                            gesturePolicy: TapHandler.ReleaseWithinBounds
                            onTapped: if (!railItem.chosen) app.select(railItem.modelData.id)
                        }
                    }
                }
                IconButton {
                    anchors.horizontalCenter: parent.horizontalCenter
                    icon: "add"
                    tip: "Add a server folder"
                    onClicked: app.addServer()
                }
            }
        }
    }

    Item {
        anchors.left: rail.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        //--- First run: nothing registered yet
        ColumnLayout {
            visible: app.loaded && !app.server && app.tab !== "prefs"
            anchors.centerIn: parent
            spacing: 12
            Icon {
                Layout.alignment: Qt.AlignHCenter
                icon: "dns"
                size: 48
                color: Theme.primary
                // A slow bob, so the empty window doesn't look frozen
                transform: Translate { id: bob }
                SequentialAnimation {
                    running: Theme.motion > 0 && app.loaded && !app.server && app.tab !== "prefs"
                    loops: Animation.Infinite
                    NumberAnimation { target: bob; property: "y"; from: 0; to: -8; duration: 1400; easing.type: Easing.InOutSine }
                    NumberAnimation { target: bob; property: "y"; from: -8; to: 0; duration: 1400; easing.type: Easing.InOutSine }
                }
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Add your first server"
                color: Theme.text
                font.pixelSize: 20
                font.weight: Font.Bold
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Pick the folder a Minecraft server is unpacked in."
                color: Theme.dim
                font.pixelSize: 14
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8
                OutlineButton { text: "Preferences"; onClicked: app.tab = "prefs" }
                OutlineButton {
                    filled: true
                    text: "Choose a folder"
                    onClicked: app.addServer()
                }
            }
        }

        ColumnLayout {
            visible: !!app.server || app.tab === "prefs"
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            //--- Header
            Card {
                id: header
                visible: !!app.server
                pad: 10
                //--- A shimmer along the bottom while the server starts or stops, and a
                //--- green ring that fades out once it's ready
                overlay: [
                    Item {
                        visible: app.busy
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: header.radius
                        anchors.rightMargin: header.radius
                        height: 2
                        clip: true
                        Rectangle { anchors.fill: parent; color: Qt.alpha(Theme.caution, 0.18) }
                        Rectangle {
                            id: sweep
                            width: parent.width * 0.35
                            height: parent.height
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: Qt.alpha(Theme.caution, 0) }
                                GradientStop { position: 0.5; color: Theme.caution }
                                GradientStop { position: 1; color: Qt.alpha(Theme.caution, 0) }
                            }
                            NumberAnimation on x {
                                running: app.busy && Theme.motion > 0
                                loops: Animation.Infinite
                                from: -sweep.width
                                to: sweep.parent.width
                                duration: 1400
                                easing.type: Easing.InOutQuad
                            }
                        }
                    },
                    Rectangle {
                        anchors.fill: parent
                        radius: header.radius
                        color: "transparent"
                        border.width: 2
                        border.color: Theme.success
                        opacity: 0
                        SequentialAnimation on opacity {
                            id: readyGlow
                            running: false
                            NumberAnimation { to: 1; duration: Theme.ms(220); easing.type: Easing.OutQuad }
                            PauseAnimation { duration: Theme.ms(400) }
                            NumberAnimation { to: 0; duration: Theme.ms(1200); easing.type: Easing.InQuad }
                        }
                    }
                ]
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    ColumnLayout {
                        spacing: 0
                        RowLayout {
                            spacing: 10
                            Text {
                                text: app.server ? app.server.name : ""
                                textFormat: Text.PlainText
                                color: Theme.text
                                font.pixelSize: 17
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                                Layout.maximumWidth: 420
                                HoverHandler { cursorShape: Qt.PointingHandCursor }
                                TapHandler {
                                    gesturePolicy: TapHandler.ReleaseWithinBounds
                                    onTapped: app.askText("Rename this server", [{ key: "name", label: "Name", value: app.server.name }],
                                                          a => app.call("rename", { name: a.name }, () => app.refreshServers()))
                                }
                            }
                            Chip {
                                tappable: false
                                tone: app.statusTone()
                                text: app.statusWord()
                            }
                        }
                        Text {
                            text: app.server ? `Port ${app.server.port}, ${app.server.label}, Java ${app.server.java}` : ""
                            textFormat: Text.PlainText
                            color: Theme.dim
                            font.pixelSize: 12
                        }
                    }
                    Item { Layout.fillWidth: true }
                    IconButton { icon: "public"; tip: "Copy the address players online join at"; onClicked: app.copyAddress(false) }
                    IconButton { icon: "lan"; tip: "Copy the address players on this network join at"; onClicked: app.copyAddress(true) }
                    IconButton { icon: "folder_open"; tip: "Open the server's folder"; onClicked: app.openFolder() }
                    Rectangle { implicitWidth: 1; implicitHeight: 22; color: Theme.rule }
                    OutlineButton {
                        visible: !app.running && app.state_ !== "outside" && app.state_ !== "restarting"
                        filled: true
                        text: "Start"
                        onClicked: app.start()
                    }
                    OutlineButton {
                        visible: app.state_ === "running" || app.state_ === "restarting"
                        text: "Restart"
                        onClicked: app.restart()
                    }
                    OutlineButton {
                        visible: app.running || app.state_ === "restarting"
                        tint: Theme.error
                        text: "Stop"
                        onClicked: app.stop()
                    }
                    IconButton {
                        visible: app.state_ === "stopping" || app.state_ === "starting"
                        icon: "dangerous"
                        tint: Theme.error
                        tip: "Kill the server, for when Stop hangs"
                        onClicked: app.kill()
                    }
                }
            }

            //--- Tabs, with one pill that slides to the chosen tab
            Item {
                Layout.fillWidth: true
                implicitHeight: tabBar.implicitHeight
                //--- Labels on every tab once all nine fit, or only the chosen one
                //--- (Preferences)
                readonly property bool labels: app.width >= 1060 && Prefs.tabLabels === "always"

                Rectangle {
                    id: tabPill
                    readonly property int at: app.shownTabs.findIndex(t => t.id === app.tab)
                    readonly property Item item: at >= 0 && tabRepeater.count > at ? tabRepeater.itemAt(at) : null
                    property bool armed: false  // no slide in from the left on load
                    visible: !!item
                    x: item ? item.x : 0
                    width: item ? item.width : 0
                    height: 34
                    radius: Theme.r(11)
                    color: Qt.alpha(Theme.primary, 0.3)
                    Behavior on x {
                        enabled: tabPill.armed
                        NumberAnimation { duration: Theme.ms(260); easing.type: Easing.OutCubic }
                    }
                    Behavior on width {
                        enabled: tabPill.armed
                        NumberAnimation { duration: Theme.ms(260); easing.type: Easing.OutCubic }
                    }
                    Timer { running: true; interval: 400; onTriggered: tabPill.armed = true }
                }
                RowLayout {
                    id: tabBar
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 4
                    Repeater {
                        id: tabRepeater
                        model: app.shownTabs
                        Rectangle {
                            id: tabItem
                            required property var modelData
                            readonly property bool chosen: app.tab === modelData.id
                            readonly property bool labelled: chosen || tabBar.parent.labels
                            implicitWidth: tabRow.implicitWidth + 20
                            implicitHeight: 34
                            radius: Theme.r(11)
                            color: !chosen && tabHover.hovered ? Theme.hover : "transparent"
                            Behavior on color { ColorAnimation { duration: Theme.ms(140) } }
                            Row {
                                id: tabRow
                                anchors.centerIn: parent
                                spacing: tabItem.labelled ? 6 : 0
                                Icon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    icon: tabItem.modelData.icon
                                    size: 19
                                    fill: tabItem.chosen
                                    color: tabItem.chosen ? Theme.primary : Theme.dim
                                    scale: tabTap.pressed ? 0.85 : 1
                                    Behavior on color { ColorAnimation { duration: Theme.ms(200) } }
                                    Behavior on scale { NumberAnimation { duration: Theme.ms(140); easing.type: Easing.OutBack } }
                                }
                                //--- The label widens out of the icon instead of popping in
                                Text {
                                    id: tabLabel
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: tabItem.labelled ? implicitWidth : 0
                                    opacity: tabItem.labelled ? 1 : 0
                                    clip: true
                                    text: tabItem.modelData.title
                                    color: tabItem.chosen ? Theme.text : Theme.dim
                                    font.pixelSize: 13
                                    font.weight: tabItem.chosen ? Font.Bold : Font.Medium
                                    Behavior on width { NumberAnimation { duration: Theme.ms(240); easing.type: Easing.OutCubic } }
                                    Behavior on opacity { NumberAnimation { duration: Theme.ms(200) } }
                                }
                            }
                            HoverHandler {
                                id: tabHover
                                cursorShape: Qt.PointingHandCursor
                                onHoveredChanged: hovered && !tabItem.labelled
                                    ? Tip.request(tabItem, tabItem.modelData.title, point.scenePosition)
                                    : Tip.cancel(tabItem)
                            }
                            TapHandler {
                                id: tabTap
                                gesturePolicy: TapHandler.ReleaseWithinBounds
                                onTapped: app.tab = tabItem.modelData.id
                            }
                        }
                    }
                    Item { Layout.fillWidth: true }
                }
            }

            //--- Page: each one fades in and rises into place, as Omni Settings' tabs do
            Loader {
                id: pageLoader
                Layout.fillWidth: true
                Layout.fillHeight: true
                active: !!app.server || app.tab === "prefs"
                opacity: 0
                transform: Translate { id: pageRise }
                //--- `app` goes in at creation, as pages read it as soon as they load
                function show() {
                    if (!app.server && app.tab !== "prefs")
                        return
                    setSource(({ dash: "DashboardPage.qml", console: "ConsolePage.qml", players: "PlayersPage.qml",
                                 settings: "ServerSettingsPage.qml", backups: "BackupsPage.qml", mods: "ModsPage.qml",
                                 schedule: "SchedulePage.qml", addons: "AddonsPage.qml",
                                 prefs: "PrefsPage.qml" })[app.tab], { app })
                }
                onLoaded: pageIn.restart()
                ParallelAnimation {
                    id: pageIn
                    NumberAnimation { target: pageLoader; property: "opacity"; from: 0; to: 1; duration: Theme.ms(220); easing.type: Easing.OutQuad }
                    NumberAnimation { target: pageRise; property: "y"; from: 12; to: 0; duration: Theme.ms(300); easing.type: Easing.OutCubic }
                }
                Component.onCompleted: show()
                Connections {
                    target: app
                    function onTabChanged() { pageLoader.show() }
                    // Leaving Preferences for the first server, or losing the last one
                    function onServerChanged() {
                        if (!app.server && app.tab !== "prefs")
                            app.tab = "dash"
                        else if (app.server && !pageLoader.item)
                            pageLoader.show()
                    }
                }
            }
        }
    }

    //--- Sheets over everything but the rail's window chrome
    Loader {
        id: sheetLoader
        anchors.fill: parent
        anchors.margins: 12
        z: 5
        active: false
        property var build: null
        onLoaded: {
            item.forceActiveFocus()
            if (build)
                build(item)
        }
    }
    Rectangle { anchors.fill: parent; z: 4; visible: sheetLoader.active; color: Theme.bg }

    function openSheet(source, build) {
        sheetLoader.build = build
        sheetLoader.source = source
        sheetLoader.active = true
    }
    function closeSheet() { sheetLoader.active = false }

    ConfirmDialog { id: dialog; anchors.fill: parent; z: 8 }
    PromptDialog { id: prompt; anchors.fill: parent; z: 8 }

    //--- Toasts (toast()): errors in red, the rest on the toast colour with a tinted
    //--- icon. They rise in and fade; hovering keeps one up, a tap dismisses it.
    Rectangle {
        id: toastBox
        property string text: ""
        property string tone: "error"
        property bool up: false
        readonly property bool isError: tone === "error"
        z: 9
        visible: opacity > 0
        opacity: up ? 1 : 0
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 16
        transform: Translate {
            y: toastBox.up ? 0 : 16
            Behavior on y { NumberAnimation { duration: Theme.ms(280); easing.type: Easing.OutCubic } }
        }
        Behavior on opacity { NumberAnimation { duration: Theme.ms(200) } }
        width: Math.min(toastRow.implicitWidth + 28, parent.width - 48)
        height: toastRow.implicitHeight + 20
        radius: Theme.r(12)
        color: isError ? Theme.error : Theme.toast
        border.width: isError ? 0 : 1
        border.color: Qt.alpha(Theme.toneColor(tone), 0.45)
        Row {
            id: toastRow
            anchors.centerIn: parent
            spacing: 8
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                icon: toastBox.isError ? "error" : toastBox.tone === "success" ? "check_circle" : "info"
                size: 18
                fill: true
                color: toastBox.isError ? Theme.inkError : Theme.toneColor(toastBox.tone)
            }
            Text {
                id: toastText
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, toastBox.parent.width - 102)
                text: toastBox.text
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                color: toastBox.isError ? Theme.inkError : Theme.inkToast
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
        }
        HoverHandler { onHoveredChanged: hovered ? toastTimer.stop() : toastTimer.restart() }
        TapHandler { onTapped: toastBox.up = false }
    }
    Timer { id: toastTimer; interval: 7000; onTriggered: toastBox.up = false }

    //--- Tooltips (Tip.qml)
    Rectangle {
        id: tipBox
        readonly property point at: app.mapFromItem(null, Tip.at.x, Tip.at.y)
        z: 10
        visible: opacity > 0
        opacity: Tip.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.ms(120) } }
        width: Math.min(tipText.implicitWidth, 340) + 22
        height: tipText.implicitHeight + 14
        x: Math.max(4, Math.min(at.x + 14, app.width - width - 4))
        y: at.y + 22 + height > app.height - 4 ? at.y - height - 8 : at.y + 22
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
