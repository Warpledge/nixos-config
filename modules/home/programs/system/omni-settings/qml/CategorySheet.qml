// Which User Packages category a package goes under: one in use, a starter one
// (api.py's `starter`) or a typed name; open(attr, current, done) calls done(name)
import QtQuick
import QtQuick.Layouts

Sheet {
    id: picker
    required property var view
    property string attr: ""
    property string current: ""
    property var done: null
    visible: false
    title: current ? "Move To" : "Install Under"
    onBack: visible = false

    readonly property var groups: visible ? view.userPackages(false) : ({})
    readonly property var used: Object.keys(groups).filter(c => groups[c].length)
        .sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()))
    readonly property var names: {
        const taken = used.map(c => c.toLowerCase())
        return used.concat((view.info ? view.info.starter : []).filter(c => !taken.includes(c.toLowerCase())))
    }

    function open(a, cur, cb) {
        attr = a
        current = cur || ""
        done = cb
        newName.text = ""
        visible = true
        forceActiveFocus()
    }

    function choose(name) {
        name = name.trim().slice(0, 40)
        if (!name || name === current)
            return
        visible = false
        done(used.find(c => c.toLowerCase() === name.toLowerCase()) || name)
    }

    Text {
        text: `The User Packages category ${picker.attr} is listed under.`
        color: Theme.dim
        font.pixelSize: 13
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        Layout.margins: 6
    }
    Repeater {
        model: picker.names
        ListRow {
            required property var modelData
            icon: "folder"
            title: modelData
            subtitle: picker.groups[modelData] ? `${picker.groups[modelData].length} installed` : ""
            tag: modelData === picker.current ? "Now" : ""
            enabled: modelData !== picker.current
            onClicked: picker.choose(modelData)
        }
    }
    Field {
        id: newName
        Layout.topMargin: 6
        icon: "create_new_folder"
        placeholder: "New category, then Enter"
        onAccepted: picker.choose(text)
        onEscaped: picker.visible = false
    }
}
