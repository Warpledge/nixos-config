// Above the tabs: Rebuild, this computer and who's logged in, then live CPU, memory
// and disk use (api.py's `status` and `usage`)
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: header
    required property var view
    property var status: null
    property var usage: null
    property real cpu: -1  // 0 to 1, once two samples are in
    property var lastTicks: null
    readonly property bool canRebuild: !!view.info && view.info.admin && view.info.canApply
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

    //--- Rebuild, the computer's name and the user
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: headCol.implicitHeight + 24
        radius: 22
        color: Theme.card
        border.width: 1
        border.color: Qt.alpha(Theme.primary, 0.12)

        ColumnLayout {
            id: headCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            Item {
                id: topLine
                Layout.fillWidth: true
                implicitHeight: 34
                // The name stays centred on the card, clear of whichever side is wider
                readonly property real side: Math.max(rebuildBtn.visible ? rebuildBtn.width : 0, userChip.width) + 10

                Rectangle {
                    id: rebuildBtn
                    visible: header.canRebuild
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: rebuildRow.implicitWidth + 26
                    height: 34
                    radius: 17
                    readonly property bool lit: rebuildHover.hovered && !Jobs.running
                    opacity: Jobs.running ? 0.45 : 1
                    color: lit ? Qt.lighter(Theme.primary, 1.12) : Theme.primary
                    scale: lit ? 1.03 : 1
                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Row {
                        id: rebuildRow
                        anchors.centerIn: parent
                        spacing: 6
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            icon: Jobs.running ? "progress_activity" : "build"
                            size: 18
                            fill: true
                            color: Theme.inkPrimary
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Rebuild"
                            font.pixelSize: 15
                            font.weight: Font.Bold
                            color: Theme.inkPrimary
                        }
                    }
                    HoverHandler { id: rebuildHover; cursorShape: Jobs.running ? Qt.ArrowCursor : Qt.PointingHandCursor }
                    TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: header.view.rebuild() }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Icon {
                        id: flake
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "ac_unit"
                        size: 20
                        color: Theme.primary
                    }
                    Text {
                        id: hostName
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.max(0, Math.min(Math.ceil(hostWidth.advanceWidth) + 1,
                                                    topLine.width - 2 * topLine.side - flake.width - 8))
                        text: header.status ? header.status.hostname : ""
                        color: Theme.text
                        font.pixelSize: 19
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                        TextMetrics { id: hostWidth; font: hostName.font; text: hostName.text }
                    }
                }

                Rectangle {
                    id: userChip
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: userRow.implicitWidth + 24
                    height: 34
                    radius: 17
                    color: Qt.alpha(Theme.primary, 0.14)
                    border.width: 1
                    border.color: Qt.alpha(Theme.primary, 0.3)
                    Row {
                        id: userRow
                        anchors.centerIn: parent
                        spacing: 6
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            icon: "person"
                            size: 18
                            fill: true
                            color: Theme.primary
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: header.view.info ? header.view.info.user : ""
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            color: Theme.primary
                        }
                    }
                }
            }

            //--- What it runs
            Row {
                visible: !!header.status
                Layout.alignment: Qt.AlignHCenter
                spacing: 6
                Chip { tappable: false; accent: true; text: header.view.info ? header.view.info.wm : "" }
                Chip { tappable: false; text: header.status ? header.status.release : "" }
                Chip { tappable: false; text: header.status ? `Linux ${header.status.kernel}` : "" }
                Chip {
                    tappable: false
                    visible: !!header.status && header.status.generation > 0
                    text: header.status ? `Version ${header.status.generation}` : ""
                }
            }
        }
    }

    //--- CPU, memory and disk
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 32
        radius: 16
        color: Theme.card
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
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

    component Meter: RowLayout {
        id: meter
        property string icon
        property string label
        property real value: -1
        property string tip: ""
        readonly property color tint: value >= 0.9 ? Theme.error : value >= 0.75 ? Theme.caution : Theme.primary
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
