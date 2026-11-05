// Makes and changes quick commands. A step's {word} is asked for when it runs, its
// delay waits before it, and @restart or @stop restart or stop the server
import QtQuick
import QtQuick.Layouts

Sheet {
    id: sheet
    property var app
    property var all: []
    property int index: -1
    property var item: ({ name: "", icon: "bolt", pinned: false, confirm: false, steps: [{ command: "", delay: 0 }] })
    property var icons: []
    title: index < 0 ? "New quick command" : "Quick commands"
    info: "A {word} in a command is asked for when you run it. A delay waits that many seconds before the step. @restart and @stop restart or stop the server, saving first."
    onBack: app.closeSheet()

    function begin(start) {
        all = JSON.parse(JSON.stringify(app.quick))
        Backend.call("quick_icons", {}, reply => { if (reply.ok) sheet.icons = reply.icons })
        pick(start)
    }
    //--- The one being edited, into the list, so switching to another doesn't lose it
    function keep() {
        sheet.forceActiveFocus()
        const edited = JSON.parse(JSON.stringify(item))
        edited.name = nameField.text.trim()
        const list = JSON.parse(JSON.stringify(all))
        if (index >= 0)
            list[index] = edited
        else if (edited.name)
            list.push(edited)
        all = list
    }
    function pick(i) {
        if (nameField.text)
            keep()
        index = i
        item = i >= 0 ? JSON.parse(JSON.stringify(all[i]))
                      : { name: "", icon: "bolt", pinned: false, confirm: false, steps: [{ command: "", delay: 0 }] }
        nameField.text = item.name
    }
    function changed(fn) {
        const copy = JSON.parse(JSON.stringify(item))
        fn(copy)
        item = copy
    }
    function save(list) {
        app.call("quick_save", { quick: list }, reply => {
            app.quick = reply.quick
            app.closeSheet()
        })
    }

    RowLayout {
        visible: sheet.all.length > 0
        Layout.fillWidth: true
        Flow {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: sheet.all
                Chip {
                    required property var modelData
                    required property int index
                    text: modelData.name
                    accent: index === sheet.index
                    onTapped: sheet.pick(index)
                }
            }
            Chip { text: "New"; icon: "add"; accent: sheet.index < 0; onTapped: sheet.pick(-1) }
        }
    }

    Field {
        id: nameField
        placeholder: "Name"
        Layout.topMargin: 8
    }

    Section { text: "Icon" }
    Flow {
        Layout.fillWidth: true
        spacing: 4
        Repeater {
            model: sheet.icons
            IconButton {
                required property string modelData
                icon: modelData
                filled: sheet.item.icon === modelData
                tint: sheet.item.icon === modelData ? Theme.primary : Theme.dim
                onClicked: sheet.changed(c => c.icon = modelData)
            }
        }
    }

    Section { text: "Steps" }
    Repeater {
        model: sheet.item.steps
        RowLayout {
            id: stepRow
            required property var modelData
            required property int index
            Layout.fillWidth: true
            spacing: 8
            Field {
                placeholder: "Command, like say Hello {player}"
                Component.onCompleted: text = stepRow.modelData.command
                input.onEditingFinished: sheet.item.steps[stepRow.index].command = text
            }
            Field {
                Layout.fillWidth: false
                Layout.preferredWidth: 110
                placeholder: "Wait (s)"
                Component.onCompleted: text = stepRow.modelData.delay ? String(stepRow.modelData.delay) : ""
                input.validator: IntValidator { bottom: 0; top: 86400 }
                input.onEditingFinished: sheet.item.steps[stepRow.index].delay = parseInt(text) || 0
            }
            IconButton {
                icon: "close"
                tip: "Remove this step"
                onClicked: sheet.changed(c => c.steps.splice(stepRow.index, 1))
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        OutlineButton {
            text: "Add a step"
            onClicked: sheet.changed(c => c.steps.push({ command: "", delay: 0 }))
        }
        Item { Layout.fillWidth: true }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 8
        Text { text: "Show on the Dashboard"; color: Theme.text; font.pixelSize: 14; Layout.fillWidth: true }
        Toggle { checked: sheet.item.pinned; onToggled: on => sheet.changed(c => c.pinned = on) }
    }
    RowLayout {
        Layout.fillWidth: true
        Text { text: "Ask before running"; color: Theme.text; font.pixelSize: 14; Layout.fillWidth: true }
        Toggle { checked: sheet.item.confirm; onToggled: on => sheet.changed(c => c.confirm = on) }
    }

    actions: [
        OutlineButton {
            visible: sheet.index >= 0
            tint: Theme.error
            text: "Delete"
            onClicked: sheet.save(sheet.all.filter((_, i) => i !== sheet.index))
        },
        Item { Layout.fillWidth: true },
        OutlineButton {
            filled: true
            text: "Save"
            onClicked: {
                sheet.keep()
                sheet.save(sheet.all)
            }
        }
    ]
}
