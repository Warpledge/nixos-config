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
        { id: "addons", icon: "widgets", title: "Add-ons" }
    ]

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
        const go = answers => call("quick_run", { name: item.name, steps: item.steps, answers })
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

    function showError(text) {
        toastText.text = text
        toast.visible = true
        toastTimer.restart()
    }

    function statusWord() {
        const s = state_
        if (s === "running") {
            if (!stats || !stats.ready)
                return "Starting"
            const up = Math.max(0, Date.now() / 1000 - stats.startedAt)
            const hours = Math.floor(up / 3600), minutes = Math.floor(up / 60) % 60
            return `Running ${hours ? hours + "h " : ""}${minutes}m`
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
            Column {
                id: railCol
                width: parent.width
                spacing: 8
                Repeater {
                    model: app.servers
                    Rectangle {
                        id: railItem
                        required property var modelData
                        readonly property bool chosen: modelData.id === app.currentId
                        readonly property string st: modelData.status.state
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 40
                        height: 40
                        radius: 12
                        color: chosen ? Qt.alpha(Theme.primary, 0.3) : itemHover.hovered ? Theme.hover : "transparent"
                        border.width: 1
                        border.color: chosen ? Theme.primary : Theme.rule
                        Text {
                            anchors.centerIn: parent
                            text: railItem.modelData.tag
                            textFormat: Text.PlainText
                            color: railItem.chosen ? Theme.text : Theme.dim
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                        Rectangle {
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
                        }
                        HoverHandler {
                            id: itemHover
                            cursorShape: Qt.PointingHandCursor
                            onHoveredChanged: hovered
                                ? Tip.request(railItem, railItem.modelData.name, point.scenePosition)
                                : Tip.cancel(railItem)
                        }
                        TapHandler {
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
            visible: app.loaded && !app.server
            anchors.centerIn: parent
            spacing: 12
            Icon { Layout.alignment: Qt.AlignHCenter; icon: "dns"; size: 48; color: Theme.primary }
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
            OutlineButton {
                Layout.alignment: Qt.AlignHCenter
                filled: true
                text: "Choose a folder"
                onClicked: app.addServer()
            }
        }

        ColumnLayout {
            visible: !!app.server
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            //--- Header
            Card {
                pad: 10
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

            //--- Tabs
            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                Repeater {
                    model: app.tabs
                    Rectangle {
                        id: tabItem
                        required property var modelData
                        readonly property bool chosen: app.tab === modelData.id
                        implicitWidth: tabRow.implicitWidth + 20
                        implicitHeight: 34
                        radius: 11
                        color: chosen ? Qt.alpha(Theme.primary, 0.3) : tabHover.hovered ? Theme.hover : "transparent"
                        Row {
                            id: tabRow
                            anchors.centerIn: parent
                            spacing: 6
                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                icon: tabItem.modelData.icon
                                size: 19
                                fill: tabItem.chosen
                                color: tabItem.chosen ? Theme.primary : Theme.dim
                            }
                            Text {
                                visible: tabItem.chosen || app.wide
                                anchors.verticalCenter: parent.verticalCenter
                                text: tabItem.modelData.title
                                color: tabItem.chosen ? Theme.text : Theme.dim
                                font.pixelSize: 13
                                font.weight: tabItem.chosen ? Font.Bold : Font.Medium
                            }
                        }
                        HoverHandler {
                            id: tabHover
                            cursorShape: Qt.PointingHandCursor
                            onHoveredChanged: hovered && !app.wide
                                ? Tip.request(tabItem, tabItem.modelData.title, point.scenePosition)
                                : Tip.cancel(tabItem)
                        }
                        TapHandler {
                            gesturePolicy: TapHandler.ReleaseWithinBounds
                            onTapped: app.tab = tabItem.modelData.id
                        }
                    }
                }
                Item { Layout.fillWidth: true }
            }

            //--- Page
            Loader {
                id: pageLoader
                Layout.fillWidth: true
                Layout.fillHeight: true
                active: !!app.server
                //--- `app` goes in at creation, as pages read it as soon as they load
                function show() {
                    setSource(({ dash: "DashboardPage.qml", console: "ConsolePage.qml", players: "PlayersPage.qml",
                                 settings: "ServerSettingsPage.qml", backups: "BackupsPage.qml", mods: "ModsPage.qml",
                                 schedule: "SchedulePage.qml", addons: "AddonsPage.qml" })[app.tab], { app })
                }
                Component.onCompleted: show()
                Connections {
                    target: app
                    function onTabChanged() { pageLoader.show() }
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

    //--- Errors
    Rectangle {
        id: toast
        visible: false
        z: 9
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 16
        width: Math.min(toastText.implicitWidth + 28, parent.width - 48)
        height: toastText.implicitHeight + 20
        radius: 12
        color: Theme.error
        Text {
            id: toastText
            anchors.centerIn: parent
            width: Math.min(implicitWidth, toast.parent.width - 76)
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            color: Theme.inkError
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }
        TapHandler { onTapped: toast.visible = false }
    }
    Timer { id: toastTimer; interval: 7000; onTriggered: toast.visible = false }

    //--- Tooltips (Tip.qml)
    Rectangle {
        id: tipBox
        readonly property point at: app.mapFromItem(null, Tip.at.x, Tip.at.y)
        z: 10
        visible: opacity > 0
        opacity: Tip.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
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
