// The mods folder, and crash reports
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    property var app
    property var mods: []
    property var crashes: []
    property bool loading: true
    property string query: ""
    property string which: "all"
    readonly property bool canChange: !!app && !app.status.active
    readonly property var shown: mods.filter(m =>
        (which === "all" || (which === "off") === !m.on)
        && (!query || m.name.toLowerCase().includes(query) || m.file.toLowerCase().includes(query)))
    spacing: 10

    function refresh() {
        if (app && app.currentId)
            app.call("mods_get", {}, reply => {
                page.mods = reply.mods
                page.crashes = reply.crashes
                page.loading = false
            })
    }
    onAppChanged: refresh()
    Connections {
        target: page.app
        function onCurrentIdChanged() { page.refresh() }
    }

    Card {
        visible: page.crashes.length > 0
        title: "Crash reports"
        Repeater {
            model: page.crashes.slice(0, 5)
            RowLayout {
                id: crashRow
                required property var modelData
                Layout.fillWidth: true
                spacing: 8
                Text {
                    text: Fmt.when(crashRow.modelData.time)
                    color: Theme.caution
                    font.pixelSize: 13
                }
                Text {
                    Layout.fillWidth: true
                    text: crashRow.modelData.title || crashRow.modelData.name
                    textFormat: Text.PlainText
                    color: Theme.text
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }
                OutlineButton {
                    text: "Read"
                    onClicked: page.app.openSheet("CrashViewer.qml", sheet => {
                        sheet.app = page.app
                        sheet.open(crashRow.modelData.name)
                    })
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Field {
            placeholder: page.loading ? "Reading mods" : `Search ${page.mods.length} mods`
            icon: "search"
            input.onTextChanged: page.query = input.text.toLowerCase()
        }
        Segmented {
            options: [{ value: "all", label: "All" }, { value: "on", label: "On" }, { value: "off", label: "Off" }]
            current: page.which
            onPicked: value => page.which = value
        }
    }
    Banner {
        visible: !page.canChange
        icon: "lock"
        text: "Stop the server to turn mods on or off."
    }
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 14
        color: Theme.card
        ListView {
            id: list
            anchors.fill: parent
            anchors.margins: 10
            clip: true
            spacing: 2
            model: page.shown
            boundsBehavior: Flickable.StopAtBounds
            delegate: RowLayout {
                id: modRow
                required property var modelData
                width: list.width
                spacing: 10
                Text {
                    Layout.fillWidth: true
                    text: modRow.modelData.name
                    textFormat: Text.PlainText
                    color: modRow.modelData.on ? Theme.text : Theme.dim
                    font.pixelSize: 14
                    elide: Text.ElideRight
                }
                Text {
                    text: modRow.modelData.version
                    textFormat: Text.PlainText
                    color: Theme.dim
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    Layout.maximumWidth: 180
                }
                Toggle {
                    enabled: page.canChange
                    checked: modRow.modelData.on
                    tip: modRow.modelData.file
                    onToggled: on => page.app.call("mod_toggle", { file: modRow.modelData.file, on }, page.refresh)
                }
            }
        }
    }
}
