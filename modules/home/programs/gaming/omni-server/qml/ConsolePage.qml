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
        IconButton {
            icon: "content_copy"
            tip: "Copy what's shown"
            onClicked: Quickshell.clipboardText = view.copyAll()
        }
    }
    ConsoleView {
        id: view
        app: page.app
        filter: filter.current
    }
    CommandLine { app: page.app }
    Card {
        title: "Quick commands"
        info: "Right-click one to edit it. A {word} in a command is asked for when you run it."
        QuickCommands { Layout.fillWidth: true; app: page.app }
    }
}
