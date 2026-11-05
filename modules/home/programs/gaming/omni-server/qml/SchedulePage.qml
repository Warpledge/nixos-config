// Daily restarts, with countdown warnings in chat
import QtQuick
import QtQuick.Layouts

Flickable {
    id: page
    property var app
    readonly property var schedule: app ? app.schedule : ({})
    readonly property var times: schedule.times || []
    readonly property var warnings: schedule.warnings || []
    readonly property var choices: [1800, 900, 300, 60, 30, 10]
    contentHeight: col.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    function save(changes) {
        app.call("schedule_set", { schedule: Object.assign({}, schedule, changes) },
                 reply => { page.app.schedule = reply.schedule })
    }
    function word(seconds) { return seconds >= 60 ? `${seconds / 60} min` : `${seconds} s` }
    function addTime() {
        const text = timeField.text.trim().padStart(5, "0")
        if (!/^([01]\d|2[0-3]):[0-5]\d$/.test(text))
            return app.showError("Enter a time as HH:MM, like 04:00")
        save({ times: times.concat([text]) })
        timeField.text = ""
    }

    ColumnLayout {
        id: col
        width: Math.min(page.width, 640)
        spacing: 10

        Card {
            title: "Daily restarts"
            info: "The server restarts at these times each day while it's running. The world saves first."
            headerExtras: Toggle {
                checked: !!page.schedule.enabled
                onToggled: on => page.save({ enabled: on })
            }
            Text {
                visible: !!page.app && !!page.app.stats && page.app.stats.nextRestart > 0
                text: page.app && page.app.stats ? `Next restart: ${Fmt.when(page.app.stats.nextRestart)}` : ""
                color: Theme.primary
                font.pixelSize: 13
            }
            Repeater {
                model: page.times
                RowLayout {
                    id: timeRow
                    required property string modelData
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: timeRow.modelData
                        color: Theme.text
                        font.pixelSize: 15
                    }
                    IconButton {
                        icon: "close"
                        tip: "Remove this time"
                        onClicked: page.save({ times: page.times.filter(t => t !== timeRow.modelData) })
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Field {
                    id: timeField
                    placeholder: "04:00"
                    onAccepted: page.addTime()
                }
                OutlineButton { text: "Add a time"; onClicked: page.addTime() }
            }
        }
        Card {
            title: "Warnings in chat"
            info: "Said to everyone this long before each restart."
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: page.choices
                    Chip {
                        required property int modelData
                        readonly property bool chosen: page.warnings.includes(modelData)
                        text: page.word(modelData)
                        accent: chosen
                        onTapped: page.save({ warnings: chosen ? page.warnings.filter(w => w !== modelData)
                                                               : page.warnings.concat([modelData]) })
                    }
                }
            }
            Field {
                id: messageField
                placeholder: "Server restarts in {time}"
                Component.onCompleted: text = page.schedule.message || ""
                onAccepted: input.focus = false
                input.onEditingFinished: if (text !== page.schedule.message) page.save({ message: text })
            }
        }
    }
}
