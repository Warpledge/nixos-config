// Review: each pending change, the lines it changes in each file, and how to apply it
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: sheet
    required property var view
    property var review: null
    property string error: ""
    readonly property int count: view.pendingCount
    readonly property bool elsewhere: view.elsewhere()
    readonly property bool restart: view.needsRestart()
    color: Theme.bg

    function load() {
        review = null
        error = ""
        Backend.call("review", { changes: view.pending, machine: view.machineArg() }, reply => {
            if (reply.ok)
                review = reply.data
            else
                error = reply.error
        })
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            IconButton { icon: "arrow_back"; onClicked: sheet.view.reviewing = false }
            Text {
                text: `${sheet.elsewhere ? "Save" : "Apply"} ${sheet.count} Change${sheet.count === 1 ? "" : "s"}`
                color: Theme.text
                font.pixelSize: 18
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: body.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: body
                width: parent.width
                spacing: 6

                Text {
                    visible: !sheet.review && !sheet.error
                    text: "Checking…"
                    color: Theme.dim
                }
                Text {
                    visible: sheet.error !== ""
                    text: sheet.error
                    color: Theme.error
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }

                Repeater {
                    model: sheet.review ? sheet.review.changes : []
                    ListRow {
                        required property var modelData
                        icon: Theme.glyph(modelData.icon)
                        app: modelData.icon
                        title: modelData.title
                        subtitle: modelData.before === modelData.after ? "Saved as it is"
                                : `${modelData.before} → ${modelData.after}`
                    }
                }

                Text {
                    visible: !!sheet.review
                    text: [
                        !!sheet.view.info && sheet.view.info.userMachines.length > 1 && Object.keys(sheet.view.pending).some(k => k.startsWith("user:"))
                            ? `App changes are saved for ${sheet.view.scopeTitle()}.` : "",
                        sheet.restart ? "Kernel and window manager changes take effect after a restart." : "",
                        sheet.elsewhere ? `They take effect the next time ${sheet.view.scope} rebuilds.`
                            : "Preview builds it and shows what would change, without switching or saving."
                    ].filter(t => t).join("\n\n")
                    color: Theme.dim
                    font.pixelSize: 15
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    Layout.margins: 6
                }

                //--- What each file would look like
                Repeater {
                    model: sheet.review ? sheet.review.files : []
                    ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 4
                        Section { text: `${modelData.file}  +${modelData.added} −${modelData.removed}` }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: diff.implicitHeight + 20
                            radius: 14
                            color: Theme.card
                            Column {
                                id: diff
                                x: 12
                                y: 10
                                width: parent.width - 24
                                Repeater {
                                    model: modelData.diff
                                    Text {
                                        required property string modelData
                                        width: diff.width
                                        text: modelData
                                        font.family: "monospace"
                                        font.pixelSize: 13
                                        wrapMode: Text.WrapAnywhere
                                        color: modelData.startsWith("+") ? Theme.primary
                                             : modelData.startsWith("-") ? Theme.error
                                             : modelData.startsWith("@@") ? Theme.caution : Theme.dim
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Item { Layout.fillWidth: true }
            Pill {
                visible: !sheet.elsewhere
                quiet: true
                text: "Preview"
                enabled: !!sheet.review && !Jobs.running
                onClicked: sheet.view.apply("build")
            }
            Pill {
                visible: !sheet.elsewhere
                quiet: !sheet.restart
                text: "At Next Restart"
                enabled: !!sheet.review && !Jobs.running
                onClicked: sheet.view.apply("boot")
            }
            Pill {
                quiet: sheet.restart && !sheet.elsewhere
                text: sheet.elsewhere ? "Save" : "Apply Now"
                enabled: !!sheet.review && !Jobs.running
                onClicked: sheet.view.apply("switch")
            }
        }
    }
}
