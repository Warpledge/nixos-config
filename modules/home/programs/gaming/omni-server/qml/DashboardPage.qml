// Stats, dimensions and quick commands, with console and chat beside them when wide
import QtQuick
import QtQuick.Layouts

Flickable {
    id: page
    property var app
    readonly property var s: app ? app.stats : null
    readonly property bool wide: app ? app.wide : true
    property string graph: ""  // the tile opened into the big graph
    property string range: "1h"
    property var history: ({ tps: [], cpu: [], heap: [], players: [] })
    property var big: []
    contentHeight: col.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    function gib(bytes) { return (bytes / (1 << 30)).toFixed(1) + " GB" }
    function tpsColor(t) {
        return t === null || t === undefined ? Theme.text : t >= 19 ? Theme.success : t >= 15 ? Theme.caution : Theme.error
    }
    //--- A field's value as 0 to 1, for the graphs
    function scaled(field, v) {
        if (field === "tps")
            return v / 20
        if (field === "cpu")
            return v
        if (field === "heap")
            return v / ((s && s.heapMax) || Math.max(...big.map(p => p[1]), v, 1))
        if (field === "players")
            return v / Math.max(1, (s && s.maxPlayers) || 1)
        return v
    }
    function refresh() {
        if (!app || !app.currentId)
            return
        for (const field of ["tps", "cpu", "heap", "players"])
            app.call("series", { field, range: "1h" }, reply => {
                const copy = Object.assign({}, page.history)
                copy[field] = reply.points.map(p => page.scaled(field, p[1]))
                page.history = copy
            })
        if (graph)
            app.call("series", { field: graph, range }, reply => { page.big = reply.points })
    }
    onAppChanged: refresh()
    onGraphChanged: refresh()
    onRangeChanged: refresh()
    Timer { interval: 15000; running: true; repeat: true; onTriggered: page.refresh() }
    Connections {
        target: page.app
        function onCurrentIdChanged() {
            page.history = ({ tps: [], cpu: [], heap: [], players: [] })
            page.big = []
            page.refresh()
        }
    }

    ColumnLayout {
        id: col
        width: page.width
        spacing: 10

        Banner {
            visible: !!page.s && page.s.statsVia === "stdin"
            text: "TPS updates every 30 s through the console. Turn on live stats to poll it silently over RCON."
            action: "Turn on"
            onActed: page.app.call("rcon_set", { on: true }, () =>
                page.app.showError("Live stats start with the next server restart"))
        }
        Banner {
            visible: page.app ? page.app.state_ === "failed" : false
            tone: "error"
            icon: "error"
            text: "The server crashed and stopped restarting. Check its crash report on the Mods tab."
        }
        Banner {
            visible: page.app ? page.app.state_ === "outside" : false
            text: "This server is running outside Omni Server. Stop it there before starting it here."
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            StatTile {
                label: "TPS"
                value: page.s && page.s.tps !== null ? page.s.tps.toFixed(1) : "–"
                ink: page.s ? page.tpsColor(page.s.tps) : Theme.text
                sub: page.s && page.s.mspt !== null ? `${page.s.mspt.toFixed(1)} ms tick` : ""
                points: page.history.tps
                selected: page.graph === "tps"
                onTapped: page.graph = page.graph === "tps" ? "" : "tps"
            }
            StatTile {
                label: "CPU"
                value: page.s && page.s.cpu !== null ? `${Math.round(page.s.cpu * 100)}%` : "–"
                sub: page.s && page.s.cores !== null ? `${page.s.cores.toFixed(1)} cores` : ""
                points: page.history.cpu
                selected: page.graph === "cpu"
                onTapped: page.graph = page.graph === "cpu" ? "" : "cpu"
            }
            StatTile {
                label: "Heap"
                value: page.s && page.s.heapUsed ? page.gib(page.s.heapUsed) : "–"
                sub: page.s && page.s.heapMax ? `of ${page.gib(page.s.heapMax)}, ${page.gib(page.s.rss)} RSS` : ""
                points: page.history.heap
                lineColor: Theme.caution
                selected: page.graph === "heap"
                onTapped: page.graph = page.graph === "heap" ? "" : "heap"
            }
            StatTile {
                label: "Players"
                value: page.s ? `${page.s.players.length} / ${page.s.maxPlayers}` : "–"
                sub: page.s ? page.s.players.join(", ") : ""
                points: page.history.players
                selected: page.graph === "players"
                onTapped: page.graph = page.graph === "players" ? "" : "players"
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: page.wide ? 2 : 1
            columnSpacing: 10
            rowSpacing: 10

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: 10

                Card {
                    visible: page.graph !== ""
                    title: ({ tps: "TPS", cpu: "CPU", heap: "Heap", players: "Players" })[page.graph] || ""
                    headerExtras: Segmented {
                        options: ["5m", "1h", "24h", "7d", "30d"].map(r => ({ value: r, label: r }))
                        current: page.range
                        onPicked: value => page.range = value
                    }
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 150
                        readonly property var vals: page.big.map(p => page.scaled(page.graph, p[1]))
                        LineGraph {
                            anchors.fill: parent
                            values: parent.vals
                            count: Math.max(2, parent.vals.length)
                        }
                        Text {
                            visible: parent.vals.length === 0
                            anchors.centerIn: parent
                            text: "No samples in this range yet"
                            color: Theme.dim
                            font.pixelSize: 13
                        }
                    }
                }

                Card {
                    title: "Dimensions"
                    info: "Tick time and TPS per dimension, worst first. Tap a name to rename it. GTNH's names are learned at the first clean stop."
                    headerExtras: [
                        Chip {
                            visible: !!page.s && page.s.lagWarnings > 0
                            tappable: false
                            tone: "caution"
                            text: page.s ? `${page.s.lagWarnings} lag warning${page.s.lagWarnings > 1 ? "s" : ""}` : ""
                        },
                        Chip {
                            visible: !!page.s && page.s.dims.length > 0
                            tappable: false
                            text: page.s ? `${page.s.dims.length} loaded` : ""
                        }
                    ]
                    Text {
                        visible: !page.s || page.s.dims.length === 0
                        text: !page.s ? "Shows once the server is running." : "Waiting for the first reading."
                        color: Theme.dim
                        font.pixelSize: 13
                    }
                    Repeater {
                        model: page.s ? page.s.dims.slice(0, page.wide ? 12 : 8) : []
                        RowLayout {
                            id: dimRow
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                Layout.preferredWidth: 130
                                text: dimRow.modelData.name
                                textFormat: Text.PlainText
                                color: Theme.text
                                font.pixelSize: 13
                                elide: Text.ElideRight
                                HoverHandler { cursorShape: Qt.PointingHandCursor }
                                TapHandler {
                                    gesturePolicy: TapHandler.ReleaseWithinBounds
                                    onTapped: page.app.askText(`Name for dimension ${dimRow.modelData.id}`,
                                                               [{ key: "name", label: "Name", value: dimRow.modelData.name }],
                                                               a => page.app.call("dim_rename", { dim: dimRow.modelData.id, name: a.name }))
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 5
                                radius: 3
                                color: Qt.alpha(Theme.bg, 0.55)
                                Rectangle {
                                    height: parent.height
                                    radius: 3
                                    width: parent.width * Math.min(1, dimRow.modelData.ms / 50)
                                    color: Theme.loadColor(dimRow.modelData.ms / 50)
                                }
                            }
                            Text {
                                Layout.preferredWidth: 58
                                horizontalAlignment: Text.AlignRight
                                text: `${dimRow.modelData.ms.toFixed(dimRow.modelData.ms < 10 ? 2 : 1)} ms`
                                color: Theme.dim
                                font.pixelSize: 12
                            }
                            Text {
                                Layout.preferredWidth: 34
                                horizontalAlignment: Text.AlignRight
                                text: dimRow.modelData.tps.toFixed(1)
                                color: page.tpsColor(dimRow.modelData.tps)
                                font.pixelSize: 12
                            }
                        }
                    }
                }

                Card {
                    title: "Quick commands"
                    QuickCommands { Layout.fillWidth: true; app: page.app; pinnedOnly: true }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: 10

                Card {
                    title: "Console"
                    Layout.preferredHeight: 310
                    headerExtras: OutlineButton { text: "Open"; onClicked: page.app.tab = "console" }
                    ConsoleView { app: page.app; fontSize: 11 }
                    CommandLine { app: page.app }
                }
                Card {
                    title: "Chat"
                    Layout.preferredHeight: 190
                    ChatView { app: page.app }
                }
            }
        }
    }
}
