// Running Now on the Services page: each service's state, last log lines and
// a restart (api.py's `services`, `serviceLog` and `serviceRestart`)
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: running
    required property var view
    property var units: null
    property string error: ""
    spacing: 6

    function load() {
        Backend.call("services", {}, reply => {
            if (!running)
                return  // the tab was left before the reply came
            if (!reply.ok) {
                error = reply.error
                return
            }
            error = ""
            units = reply.data
            view.servicesRunning = units.filter(u => u.active === "active").length
        })
    }

    Component.onCompleted: load()

    RowLayout {
        Layout.fillWidth: true
        Section {
            text: "Running Now"
            info: "The services this computer runs right now. Changes above show up here after Apply."
            Layout.fillWidth: true
        }
        IconButton { icon: "refresh"; tip: "Check again"; Layout.topMargin: 10; onClicked: running.load() }
    }
    ListRow {
        visible: running.units === null || !running.units.length
        icon: "dns"
        title: running.units === null && !running.error ? "Checking…" : "None of them is on"
        alert: running.error
    }
    Repeater {
        model: running.units || []
        UnitRow { required property var modelData; unit: modelData }
    }

    //--- One service; tapping it shows its last log lines
    component UnitRow: Rectangle {
        id: unitRow
        property var unit
        property bool open: false
        property string log: ""
        property bool restarting: false
        readonly property var look: ({ active: ["Running", "success"], failed: ["Failed", "error"],
                                        activating: ["Starting", "caution"], deactivating: ["Stopping", "caution"],
                                        reloading: ["Reloading", "caution"] })[unit.active] || ["Stopped", ""]
        readonly property bool mayRestart: unit.scope === "user" || running.view.info.admin
        // systemd's "Thu 2026-10-29 18:19:54 CDT" as "Thu 18:19"
        readonly property string since: {
            const p = (unit.since || "").split(" ")
            return p.length >= 3 ? `${p[0]} ${p[2].slice(0, 5)}` : unit.since || ""
        }
        Layout.fillWidth: true
        implicitHeight: unitCol.implicitHeight + 22
        radius: 14
        color: Qt.alpha(Theme.bg, 0.55)
        border.width: 1
        border.color: Theme.rule
        readonly property color ink: unitRow.look[1] ? Theme.toneColor(unitRow.look[1]) : Theme.dim
        ColumnLayout {
            id: unitCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 11
            anchors.leftMargin: 14
            anchors.rightMargin: 12
            spacing: 8
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Rectangle { implicitWidth: 9; implicitHeight: 9; radius: 4.5; color: unitRow.ink }
                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true
                    Text {
                        text: unitRow.unit.name
                        color: Theme.text
                        font.pixelSize: 15
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: unitRow.unit.unit + (unitRow.unit.scope === "user" ? " (yours)" : "")
                              + (unitRow.unit.active === "active" && unitRow.unit.since
                                 ? ` · since ${unitRow.since}` : "")
                        color: Theme.dim
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
                Text {
                    text: unitRow.look[0]
                    color: unitRow.ink
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }
                IconButton {
                    icon: unitRow.restarting ? "progress_activity" : "restart_alt"
                    tip: unitRow.mayRestart ? "Restart it" : "Only an admin can restart it"
                    enabled: unitRow.mayRestart && !unitRow.restarting
                    opacity: enabled ? 1 : 0.45
                    onClicked: {
                        unitRow.restarting = true
                        Backend.call("serviceRestart", { scope: unitRow.unit.scope, unit: unitRow.unit.unit },
                                     reply => {
                            unitRow.restarting = false
                            running.view.say(reply.ok ? `${unitRow.unit.name} restarted`
                                                      : `${unitRow.unit.name}: ${reply.error}`)
                            reloadTimer.start()
                        })
                    }
                }
                Chevron {
                    open: unitRow.open
                }
            }
            Reveal {
                open: unitRow.open
                gap: unitCol.spacing
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: logText.implicitHeight + 16
                    radius: 10
                    color: Theme.cardHover
                    TextEdit {
                        id: logText
                        x: 10
                        y: 8
                        width: parent.width - 20
                        readOnly: true
                        selectByMouse: true
                        text: unitRow.log || "Loading…"
                        color: Theme.dim
                        selectionColor: Theme.primary
                        font.family: "monospace"
                        font.pixelSize: 12
                        wrapMode: TextEdit.WrapAnywhere
                    }
                }
            }
        }
        TapHandler {
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: {
                unitRow.open = !unitRow.open
                if (unitRow.open)
                    Backend.call("serviceLog", { scope: unitRow.unit.scope, unit: unitRow.unit.unit },
                                 reply => unitRow.log = reply.ok ? reply.data : reply.error)
            }
        }
    }

    // The state a moment after a restart, once systemd has caught up
    Timer { id: reloadTimer; interval: 800; onTriggered: running.load() }
}
