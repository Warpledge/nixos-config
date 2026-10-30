// Above the tabs: Rebuild, this computer and who's logged in, then live CPU, memory
// and disk use (api.py's `status` and `usage`)
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

ColumnLayout {
    id: header
    required property var view
    property var status: null
    property var usage: null
    property real cpu: -1  // 0 to 1, once two samples are in
    property var lastTicks: null
    readonly property bool canRebuild: !!view.info && view.info.admin && view.info.canApply
    property bool barOnly: false  // just the usage bar, as over the run page
    spacing: 8

    function refresh() {
        Backend.call("status", {}, reply => { if (reply.ok) header.status = reply.data })
    }
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
                header.cpu = 1 - (u.cpuIdle - last.idle) / (u.cpuTotal - last.total)
            header.lastTicks = { total: u.cpuTotal, idle: u.cpuIdle }
            header.usage = u
        })
    }

    //--- One card: the computer and Rebuild, then CPU, memory and disk under a rule;
    //--- over the run page only the meters
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: cardCol.implicitHeight + (header.barOnly ? 16 : 24)
        radius: header.barOnly ? 16 : 22
        color: Theme.card
        border.width: 1
        border.color: Qt.alpha(Theme.primary, 0.12)

        ColumnLayout {
            id: cardCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 14
            anchors.rightMargin: 12
            spacing: 10

            RowLayout {
                visible: !header.barOnly
                Layout.fillWidth: true
                spacing: 12

                //--- The computer's name, what it runs and who's logged in
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        // The white logo with its white swapped for primary
                        Image {
                            id: logo
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            sourceSize: Qt.size(44, 44)
                            property string svg: ""
                            source: svg ? "data:image/svg+xml;utf8," + encodeURIComponent(
                                svg.replace(/#ffffff/gi, Theme.primary.toString())) : ""
                            FileView {
                                path: Qt.resolvedUrl("nix-snowflake-white.svg").toString().replace("file://", "")
                                onLoaded: logo.svg = text()
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: header.status ? header.status.hostname : ""
                            color: Theme.text
                            font.pixelSize: 19
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: !!header.status
                        text: header.status ? [header.view.info ? header.view.info.wm : "",
                                               header.status.release,
                                               `Linux ${header.status.kernel}`].filter(s => s).join(" · ") : ""
                        color: Theme.dim
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }
                    Row {
                        spacing: 0
                        Text {
                            visible: !!header.status && header.status.generation > 0
                            text: header.status ? `Version ${header.status.generation} · ` : ""
                            color: Theme.dim
                            font.pixelSize: 13
                        }
                        // Opens Users
                        Row {
                            spacing: 3
                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                icon: "person"
                                size: 15
                                fill: true
                                color: userHover.hovered ? Theme.primary : Theme.dim
                            }
                            Text {
                                text: header.view.info ? header.view.info.user : ""
                                color: userHover.hovered ? Theme.primary : Theme.dim
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                font.underline: userHover.hovered
                            }
                            HoverHandler { id: userHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                gesturePolicy: TapHandler.ReleaseWithinBounds
                                onTapped: header.view.go("system", "people")
                            }
                        }
                    }
                }

                Rectangle {
                    id: rebuildBtn
                    visible: header.canRebuild
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: rebuildRow.implicitWidth + 36
                    implicitHeight: 52
                    radius: 18
                    readonly property bool lit: rebuildHover.hovered && !Jobs.running
                    opacity: Jobs.running ? 0.45 : 1
                    color: lit ? Qt.lighter(Theme.primary, 1.12) : Theme.primary
                    scale: lit ? 1.03 : 1
                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Row {
                        id: rebuildRow
                        anchors.centerIn: parent
                        spacing: 8
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            icon: Jobs.running ? "progress_activity" : "build"
                            size: 22
                            fill: true
                            color: Theme.inkPrimary
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Rebuild"
                            font.pixelSize: 17
                            font.weight: Font.Bold
                            color: Theme.inkPrimary
                        }
                    }
                    HoverHandler { id: rebuildHover; cursorShape: Jobs.running ? Qt.ArrowCursor : Qt.PointingHandCursor }
                    TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: header.view.rebuild() }
                }
            }

            Rectangle {
                visible: !header.barOnly
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.rule
            }

            //--- CPU, memory and disk
            RowLayout {
                Layout.fillWidth: true
                spacing: 16
                Meter { icon: "memory"; label: "CPU"; value: header.cpu }
                Meter {
                    icon: "memory_alt"
                    label: "RAM"
                    value: header.usage ? header.usage.memUsed / header.usage.memTotal : -1
                    tip: header.usage ? `${Fmt.size(header.usage.memUsed)} of ${Fmt.size(header.usage.memTotal)}` : ""
                }
                Meter {
                    icon: "hard_drive"
                    label: "Disk"
                    value: header.usage ? header.usage.diskUsed / header.usage.diskTotal : -1
                    tip: header.usage ? `${Fmt.size(header.usage.diskUsed)} of ${Fmt.size(header.usage.diskTotal)}` : ""
                }
            }
        }
    }

    component Meter: RowLayout {
        id: meter
        property string icon
        property string label
        property real value: -1
        property string tip: ""
        // Primary to 60%, then easing into yellow by 80% and red by 100%
        readonly property color tint: value < 0.6 ? Theme.primary
            : value < 0.8 ? Theme.mix(Theme.primary, Theme.caution, (value - 0.6) / 0.2)
            : Theme.mix(Theme.caution, Theme.error, Math.min(1, (value - 0.8) / 0.2))
        Layout.fillWidth: true
        Layout.preferredWidth: 1  // equal thirds
        spacing: 6
        Icon { icon: meter.icon; size: 16; color: meter.tint }
        Text {
            text: meter.label
            color: Theme.dim
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 4
            radius: 2
            color: Qt.alpha(meter.tint, 0.18)
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, meter.value))
                height: parent.height
                radius: 2
                color: meter.tint
                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            }
        }
        Text {
            text: meter.value < 0 ? "–" : `${Math.round(meter.value * 100)}%`
            color: Theme.text
            font.pixelSize: 12
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: 32
        }
        readonly property point cursor: hover.point.scenePosition
        onCursorChanged: Tip.move(meter, cursor)
        HoverHandler {
            id: hover
            onHoveredChanged: hovered ? Tip.request(meter, meter.tip, point.scenePosition) : Tip.cancel(meter)
        }
    }
}
