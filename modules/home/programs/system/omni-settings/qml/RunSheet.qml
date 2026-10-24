// A job's steps, progress and log, from the job service; it keeps running when closed
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: sheet
    required property var view
    readonly property var job: Jobs.job
    readonly property var p: Jobs.progress
    readonly property bool done: !!job && !!job.ended
    property bool showLog: false
    color: Theme.bg

    readonly property var stepGlyph: ({ waiting: "radio_button_unchecked", running: "progress_activity",
                                        done: "check_circle", failed: "error", skipped: "remove_circle" })

    function size(b) {
        const units = ["B", "KiB", "MiB", "GiB"]
        let i = 0
        while (b >= 1024 && i < units.length - 1) { b /= 1024; i++ }
        return `${b.toFixed(i ? 1 : 0)} ${units[i]}`
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            IconButton { icon: "arrow_back"; onClicked: sheet.view.running = false }
            Text {
                text: sheet.job ? sheet.job.title : ""
                color: Theme.text
                font.pixelSize: 16
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }
        }

        //--- Outcome
        Rectangle {
            visible: sheet.done
            Layout.fillWidth: true
            implicitHeight: outcome.implicitHeight + 24
            radius: 16
            color: sheet.job && sheet.job.outcome === "failed" ? Theme.error : Theme.primaryContainer
            readonly property color ink: sheet.job && sheet.job.outcome === "failed" ? Theme.inkError : Theme.inkContainer
            ColumnLayout {
                id: outcome
                anchors.fill: parent
                anchors.margins: 12
                spacing: 4
                Text {
                    text: sheet.job ? (sheet.job.heading || sheet.job.done) : ""
                    color: parent.parent.ink
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
                Text {
                    visible: text !== ""
                    text: sheet.job ? (sheet.job.detail || "") : ""
                    color: parent.parent.ink
                    font.pixelSize: 13
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
        }

        //--- Steps
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: steps.implicitHeight + 20
            radius: 16
            color: Theme.card
            ColumnLayout {
                id: steps
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                spacing: 6
                Repeater {
                    model: sheet.job ? sheet.job.steps : []
                    RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 10
                        Icon {
                            icon: sheet.stepGlyph[modelData.state] || "radio_button_unchecked"
                            fill: modelData.state === "done"
                            color: modelData.state === "failed" ? Theme.error
                                 : modelData.state === "waiting" || modelData.state === "skipped" ? Theme.dim
                                 : Theme.primary
                            RotationAnimation on rotation {
                                running: modelData.state === "running"
                                from: 0; to: 360; duration: 1200; loops: Animation.Infinite
                            }
                        }
                        ColumnLayout {
                            spacing: 0
                            Layout.fillWidth: true
                            Text {
                                text: modelData.title
                                color: modelData.state === "waiting" ? Theme.dim : Theme.text
                                font.pixelSize: 13
                                font.weight: modelData.state === "running" ? Font.DemiBold : Font.Normal
                            }
                            Text {
                                visible: text !== ""
                                text: modelData.detail || ""
                                color: Theme.dim
                                font.pixelSize: 12
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }

        //--- Build progress
        ColumnLayout {
            visible: !!sheet.p && !sheet.done
            Layout.fillWidth: true
            spacing: 4
            Rectangle {
                Layout.fillWidth: true
                height: 6
                radius: 3
                color: Theme.cardHover
                Rectangle {
                    height: parent.height
                    radius: 3
                    width: parent.width * Math.max(0, Math.min(1, sheet.p ? sheet.p.fraction || 0 : 0))
                    color: Theme.primary
                    Behavior on width { NumberAnimation { duration: 300 } }
                }
            }
            Text {
                text: !sheet.p ? "" : sheet.p.evaluating ? `Evaluating · ${sheet.p.evalFiles} files`
                    : [`Built ${sheet.p.builds[0]} of ${sheet.p.builds[1]}`,
                       `downloaded ${sheet.p.downloads[0]} of ${sheet.p.downloads[1]}`
                         + (sheet.p.bytes[1] ? ` (${sheet.size(sheet.p.bytes[0])} of ${sheet.size(sheet.p.bytes[1])})` : ""),
                       sheet.p.deleted ? `deleted ${sheet.p.deleted}` : ""].filter(t => t).join(" · ")
                color: Theme.dim
                font.pixelSize: 12
                Layout.leftMargin: 4
            }
            Repeater {
                model: sheet.p ? sheet.p.running.slice(0, 4) : []
                Text {
                    required property var modelData
                    text: `${modelData.name} · ${Math.round(modelData.seconds)} s`
                    color: Theme.dim
                    font.pixelSize: 12
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                }
            }
        }

        //--- Errors nix reported
        Repeater {
            model: sheet.job ? sheet.job.errors.slice(0, 3) : []
            Text {
                required property string modelData
                text: modelData
                color: Theme.error
                font.family: "monospace"
                font.pixelSize: 12
                wrapMode: Text.Wrap
                maximumLineCount: 8
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        //--- Log
        Chip {
            text: sheet.showLog ? "Hide the log" : `Show the log (${Jobs.log.count} lines)`
            onTapped: sheet.showLog = !sheet.showLog
        }
        //--- What changed, once compared; the log takes its place when shown
        Flickable {
            visible: !sheet.showLog
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: diffLoader.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Loader {
                id: diffLoader
                width: parent.width
                active: !!sheet.job && !!sheet.job.diff
                sourceComponent: DiffView { diff: sheet.job.diff }
            }
        }
        Rectangle {
            visible: sheet.showLog
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 14
            color: Theme.card
            ListView {
                id: log
                anchors.fill: parent
                anchors.margins: 10
                clip: true
                model: sheet.showLog ? Jobs.log : null
                onCountChanged: if (atYEnd || count < 50) positionViewAtEnd()
                delegate: Text {
                    required property var model
                    width: log.width
                    text: model.text
                    font.family: "monospace"
                    font.pixelSize: 11
                    wrapMode: Text.WrapAnywhere
                    color: model.style === "error" ? Theme.error : Theme.dim
                }
            }
        }

        //--- Actions
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Item { Layout.fillWidth: true }
            Pill {
                visible: !!sheet.job && sheet.job.cancellable
                quiet: true
                text: "Stop"
                onClicked: Jobs.request("cancel")
            }
            Pill {
                visible: !!sheet.job && !!sheet.job.undo
                quiet: true
                text: sheet.job ? (sheet.job.undo || "") : ""
                onClicked: Jobs.request("undo", {}, reply => {
                    sheet.view.say(reply.ok ? reply.data : reply.error)
                    sheet.view.reload()
                })
            }
            Pill {
                readonly property var labels: ({ apply: "Apply Now", rebuild: "Rebuild Now", update: "Update Now" })
                visible: sheet.done && sheet.job.preview && sheet.job.outcome === "ok"
                         && !!sheet.view.lastJob && sheet.view.lastJob.kind === sheet.job.kind
                         && (sheet.job.kind !== "apply" || sheet.view.pendingCount > 0)
                quiet: true
                text: labels[sheet.job ? sheet.job.kind : ""] || ""
                onClicked: sheet.view.runPreviewed()
            }
            Pill {
                visible: sheet.done
                text: "Done"
                onClicked: sheet.view.closeRun()
            }
        }
    }
}
