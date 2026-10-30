// Above the tabs: this computer and who's logged in, its version and Rebuild, a row of
// facts, then CPU and memory over the last 5 minutes (api.py's `status` and `usage`)
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: header
    required property var view
    property var status: null
    property var usage: null
    property var lastTicks: null
    property var cpuHistory: []  // 0 to 1, one sample every 2 s, oldest first
    property var memHistory: []
    readonly property int samples: 150  // 5 minutes
    readonly property real cpu: cpuHistory.length ? cpuHistory[cpuHistory.length - 1] : -1
    readonly property real mem: memHistory.length ? memHistory[memHistory.length - 1] : -1
    readonly property bool canRebuild: !!view.info && view.info.admin && view.info.canApply
    readonly property int waiting: view.pendingCount
    property bool barOnly: false  // just the graphs, as over the run page
    spacing: 8

    function refresh() {
        Backend.call("status", {}, reply => { if (reply.ok) header.status = reply.data })
    }
    function push(list, v) { return list.concat([v]).slice(-samples) }
    Component.onCompleted: refresh()
    Connections {
        target: Jobs
        function onEnded(job) { header.refresh() }
    }
    Timer {
        interval: 2000
        repeat: true
        running: header.view.shown
        triggeredOnStart: true
        onTriggered: Backend.call("usage", {}, reply => {
            if (!reply.ok)
                return
            const u = reply.data
            const last = header.lastTicks
            if (last && u.cpuTotal > last.total)
                header.cpuHistory = header.push(header.cpuHistory,
                                                1 - (u.cpuIdle - last.idle) / (u.cpuTotal - last.total))
            header.lastTicks = { total: u.cpuTotal, idle: u.cpuIdle }
            header.memHistory = header.push(header.memHistory, u.memUsed / u.memTotal)
            header.usage = u
        })
    }

    //--- "7.2.11-zen1" reads as "zen 7.2.11"; anything else stays as it is
    function kernelName(k) {
        const m = /^([\d.]+)-([a-z]+)\d*$/.exec(k || "")
        return m ? `${m[2]} ${m[1]}` : k
    }
    readonly property var facts: {
        const out = []
        const info = view.info
        const st = status
        const git = view.gitCounts
        if (info && info.wm)
            out.push({ icon: "view_column", text: info.wm })
        if (st)
            out.push({ icon: "memory", text: kernelName(st.kernel) },
                     { icon: "", text: st.release, tone: "info" })
        if (usage)
            out.push({ icon: "hard_drive", text: `${Fmt.size(usage.diskFree)} free` })
        // Git as its icon and what's waiting; the branch and the words are in its tip
        if (git && git.branch)
            out.push({ icon: "fork_right", text: "",
                       trail: [git.changed ? `±${git.changed}` : "", git.ahead ? `↑${git.ahead}` : "",
                               git.behind ? `↓${git.behind}` : ""].filter(t => t).join(" "),
                       tip: [`On ${git.branch}`, git.changed ? `${git.changed} changed` : "",
                             git.ahead ? `${git.ahead} to push` : "",
                             git.behind ? `${git.behind} to pull` : ""].filter(t => t).join(" · ") })
        return out
    }

    //--- The computer and the person, the version and its state, and the facts under
    //--- them; Rebuild runs down the right of all three
    RowLayout {
        visible: !header.barOnly
        Layout.fillWidth: true
        spacing: 8

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            GridLayout {
                Layout.fillWidth: true
                columns: header.width < 420 ? 1 : 2
                columnSpacing: 8
                rowSpacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    implicitHeight: 46
                    radius: 12
                    color: Theme.card
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8
                        Image {
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30
                            sourceSize: Qt.size(60, 60)
                            source: Qt.resolvedUrl("icon.svg")
                        }
                        Tag {
                            icon: "computer"
                            text: header.status ? header.status.hostname : ""
                            big: true
                            fill: Qt.alpha(Theme.away, 0.2)
                            ink: Theme.away
                            tip: "This computer"
                        }
                        Item { Layout.fillWidth: true }
                        // Opens Users
                        Tag {
                            icon: "person"
                            text: header.view.info ? header.view.info.user : ""
                            big: true
                            fill: Qt.alpha(Theme.primary, userHover.hovered ? 0.34 : 0.2)
                            ink: Theme.primary
                            HoverHandler { id: userHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                gesturePolicy: TapHandler.ReleaseWithinBounds
                                onTapped: header.view.go("system", "people")
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    implicitHeight: 46
                    radius: 12
                    color: Theme.card
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8
                        Tag {
                            visible: !!header.status && header.status.generation > 0
                            icon: "history"
                            text: header.status ? `v. ${header.status.generation}` : ""
                            big: true
                            fill: Theme.cardHover
                            ink: Theme.text
                            tip: "The running system version (generation)"
                        }
                        Item { Layout.fillWidth: true }
                        // Changes not yet applied open Review
                        Tag {
                            readonly property bool pending: header.waiting > 0
                            icon: ""
                            dot: true
                            big: true
                            text: pending ? `${header.waiting} change${header.waiting === 1 ? "" : "s"}` : "Up to date"
                            fill: Qt.alpha(pending ? Theme.caution : Theme.success, 0.14)
                            ink: pending ? Theme.caution : Theme.success
                            HoverHandler { enabled: parent.pending; cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                enabled: parent.pending
                                gesturePolicy: TapHandler.ReleaseWithinBounds
                                onTapped: header.view.startReview()
                            }
                        }
                    }
                }
            }

            //--- Facts as pills, centred; a line that runs out wraps
            Rectangle {
                visible: header.facts.length > 0
                Layout.fillWidth: true
                implicitHeight: factFlow.implicitHeight + 8
                radius: 10
                color: Theme.card
                Flow {
                    id: factFlow
                    // As wide as the pills when they fit on one line, so they centre
                    readonly property real natural: {
                        let w = -6
                        for (let i = 0; i < children.length; i++)
                            if (children[i].visible)
                                w += children[i].implicitWidth + 6
                        return w
                    }
                    width: Math.min(parent.width - 12, natural)
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    Repeater {
                        model: header.facts
                        Tag {
                            required property var modelData
                            icon: modelData.icon
                            text: modelData.text
                            trail: modelData.trail || ""
                            tip: modelData.tip || ""
                            fill: modelData.tone ? Qt.alpha(Theme.toneColor(modelData.tone), 0.16) : Theme.cardHover
                            ink: modelData.tone ? Theme.toneColor(modelData.tone) : Theme.dim
                        }
                    }
                }
            }
        }

                Rectangle {
                    id: rebuildBtn
                    visible: header.canRebuild
                    Layout.fillHeight: true
                    implicitWidth: 46
                    radius: 12
                    readonly property bool lit: rebuildHover.hovered && !Jobs.running
                    opacity: Jobs.running ? 0.45 : 1
                    color: lit ? Qt.lighter(Theme.primary, 1.12) : Theme.primary
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Icon {
                        anchors.centerIn: parent
                        icon: Jobs.running ? "progress_activity" : "autorenew"
                        size: 24
                        color: Theme.inkPrimary
                    }
                    // Changes waiting: Review takes them, then rebuilds
                    Rectangle {
                        visible: header.waiting > 0
                        x: parent.width - width + 5
                        y: -5
                        width: Math.max(18, badgeText.implicitWidth + 8)
                        height: 18
                        radius: 9
                        color: Theme.caution
                        border.width: 2
                        border.color: Theme.bg
                        Text {
                            id: badgeText
                            anchors.centerIn: parent
                            text: header.waiting
                            color: Theme.bg
                            font.pixelSize: 11
                            font.weight: Font.ExtraBold
                        }
                    }
                    readonly property point cursor: rebuildHover.point.scenePosition
                    onCursorChanged: Tip.move(rebuildBtn, cursor)
                    HoverHandler {
                        id: rebuildHover
                        cursorShape: Jobs.running ? Qt.ArrowCursor : Qt.PointingHandCursor
                        onHoveredChanged: hovered
                            ? Tip.request(rebuildBtn, header.waiting ? "Review and apply your changes" : "Rebuild",
                                          point.scenePosition)
                            : Tip.cancel(rebuildBtn)
                    }
                    TapHandler {
                        gesturePolicy: TapHandler.ReleaseWithinBounds
                        onTapped: header.waiting ? header.view.startReview() : header.view.rebuild()
                    }
                }
    }

    //--- CPU and memory, each a value and its last 5 minutes
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Graph { label: "CPU"; values: header.cpuHistory; value: header.cpu }
        Graph {
            label: "RAM"
            values: header.memHistory
            value: header.mem
            tip: header.usage ? `${Fmt.size(header.usage.memUsed)} of ${Fmt.size(header.usage.memTotal)}` : ""
        }
    }

    component Tag: Rectangle {
        id: pill
        property string icon: ""
        property string text: ""
        property string trail: ""  // in caution after the text
        property bool dot: false
        property bool big: false  // the larger pills in the header's top cards
        property string tip: ""
        property color fill: Theme.cardHover
        property color ink: Theme.dim
        implicitWidth: pillRow.implicitWidth + (big ? 22 : 16)
        implicitHeight: big ? 30 : 22
        radius: height / 2
        color: fill
        Behavior on color { ColorAnimation { duration: 120 } }
        readonly property point cursor: tipHover.point.scenePosition
        onCursorChanged: Tip.move(pill, cursor)
        HoverHandler {
            id: tipHover
            onHoveredChanged: hovered && pill.tip ? Tip.request(pill, pill.tip, point.scenePosition) : Tip.cancel(pill)
        }
        Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: 5
            Rectangle {
                visible: pill.dot
                anchors.verticalCenter: parent.verticalCenter
                width: 6; height: 6; radius: 3
                color: pill.ink
            }
            Icon {
                visible: pill.icon !== ""
                anchors.verticalCenter: parent.verticalCenter
                icon: pill.icon
                size: pill.big ? 16 : 13
                color: pill.ink
            }
            Text {
                visible: pill.text !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: pill.text
                color: pill.ink
                font.pixelSize: pill.big ? 14 : 11
                font.weight: pill.big ? Font.Bold : Font.DemiBold
            }
            Text {
                visible: pill.trail !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: pill.trail
                color: Theme.caution
                font.pixelSize: 11
                font.weight: Font.Bold
            }
        }
    }

    component Graph: Rectangle {
        id: graph
        property string label
        property var values: []
        property real value: -1
        property string tip: ""
        readonly property color tint: value < 0 ? Theme.dim : Theme.loadColor(value)
        Layout.fillWidth: true
        Layout.preferredWidth: 1  // equal halves
        implicitHeight: 34
        radius: 10
        color: Theme.card
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8
            Text {
                text: graph.label
                color: Theme.dim
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }
            Text {
                text: graph.value < 0 ? "–" : `${Math.round(graph.value * 100)}%`
                color: graph.tint
                font.pixelSize: 13
                font.weight: Font.Bold
                font.features: { "tnum": 1 }
                Layout.preferredWidth: 32
            }
            LineGraph {
                Layout.fillWidth: true
                Layout.preferredHeight: 14
                values: graph.values
                count: header.samples
                color: graph.tint
            }
        }
        readonly property point cursor: hover.point.scenePosition
        onCursorChanged: Tip.move(graph, cursor)
        HoverHandler {
            id: hover
            onHoveredChanged: hovered && graph.tip ? Tip.request(graph, graph.tip, point.scenePosition) : Tip.cancel(graph)
        }
    }
}
