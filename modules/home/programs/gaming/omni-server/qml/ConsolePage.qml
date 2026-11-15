// The console at full size, with every quick command
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: page
    property var app
    spacing: 10

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Segmented {
            id: filter
            options: [{ value: "all", label: "All" }, { value: "warn", label: "Warnings" }, { value: "chat", label: "Chat" }]
            current: "all"
            onPicked: value => current = value
        }
        Item { Layout.fillWidth: true }
        //--- Find in the console (Ctrl+F): Enter or Up for the match before, Down
        //--- for the one after; a one-line TextInput passes the arrows up to here
        Field {
            id: search
            Layout.fillWidth: false
            Layout.preferredWidth: search.input.activeFocus || search.text ? 300 : 200
            Behavior on Layout.preferredWidth { NumberAnimation { duration: Theme.ms(220); easing.type: Easing.OutCubic } }
            implicitHeight: 32
            icon: "search"
            placeholder: "Find"
            onTextChanged: view.query = text
            onEscaped: {
                text = ""
                search.input.focus = false
            }
            onAccepted: view.find(-1)
            Keys.onUpPressed: view.find(-1)
            Keys.onDownPressed: view.find(1)
        }
        Text {
            visible: search.text !== ""
            text: view.matches ? `${view.matches} match${view.matches === 1 ? "" : "es"}` : "No matches"
            color: view.matches ? Theme.dim : Theme.caution
            font.pixelSize: 12
        }
        IconButton {
            visible: search.text !== ""
            icon: "keyboard_arrow_up"
            tip: "Earlier match (Enter or Up)"
            onClicked: view.find(-1)
        }
        IconButton {
            visible: search.text !== ""
            icon: "keyboard_arrow_down"
            tip: "Later match (Down)"
            onClicked: view.find(1)
        }
        IconButton {
            icon: "content_copy"
            tip: "Copy what's shown"
            onClicked: {
                Quickshell.clipboardText = view.copyAll()
                page.app.toast("Copied the console", "success")
            }
        }
    }
    ConsoleView {
        id: view
        app: page.app
        filter: filter.current
    }
    //--- Ctrl+F from anywhere lands here
    function takeSearch() {
        if (app && app.searchWanted) {
            app.searchWanted = false
            search.input.forceActiveFocus()
            search.input.selectAll()
        }
    }
    Component.onCompleted: Qt.callLater(takeSearch)
    Connections {
        target: page.app
        function onSearchWantedChanged() { page.takeSearch() }
    }
    CommandLine { app: page.app }
    Card {
        title: "Quick commands"
        info: "Right-click one to edit it. A {word} in a command is asked for when you run it."
        QuickCommands { Layout.fillWidth: true; app: page.app }
    }
}
