// File Types (Main tab): one MIME type to one app, the user's mimeTypes
// setting, on top of the Default Apps choices
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var view
    readonly property var setting: view.info ? view.info.mimeTypes : null
    readonly property var entries: saved()
    property var apps: []
    property bool loaded: false
    property string error: ""
    spacing: 6

    function saved() {
        const v = !setting ? null : view.valueOf(setting)
        const out = {}
        if (v && typeof v === "object" && !Array.isArray(v))
            for (const k of Object.keys(v))
                out[k] = v[k]
        return out
    }

    function put(type, app) {
        if (!setting)
            return
        const out = saved()
        if (app === null)
            delete out[type]
        else
            out[type] = app
        view.change(setting, out)
    }

    function add() {
        const type = typeField.text.trim()
        if (!/^[A-Za-z0-9.+-]+\/[A-Za-z0-9.+-]+$/.test(type)) {
            view.say("A type looks like application/x-cbz")
            return
        }
        const app = page.picked
        if (!app) {
            view.say("Pick the app to open it")
            return
        }
        put(type, app)
        typeField.text = ""
        page.picked = ""
        view.say(`${page.nameOf(app)} opens ${type} when you apply`)
    }

    function nameOf(id) {
        const found = page.apps.find(a => a.id === id)
        return found ? found.name : id
    }

    property string picked: ""

    Component.onCompleted: Backend.call("mimeApps", {}, reply => {
        page.loaded = true
        if (reply.ok)
            page.apps = reply.data
        else
            page.error = reply.error
    })

    //--- Hero
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: hero.implicitHeight + 28
        radius: 16
        color: Theme.card
        ColumnLayout {
            id: hero
            anchors.fill: parent
            anchors.margins: 14
            Text {
                text: "Which app opens one file type, in front of the Default Apps choices. For example "
                      + "application/x-cbz to Moku, or video/x-matroska to mpv. A file's type is shown in "
                      + "its properties window."
                color: Theme.dim
                font.pixelSize: 13
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
        }
    }

    Text {
        text: `Saved for ${page.view.scopeTitle()}.`
        color: Theme.dim
        font.pixelSize: 13
        Layout.leftMargin: 6
    }

    //--- Types of your own
    Section { text: "File Types" }
    ListRow {
        visible: Object.keys(page.entries).length === 0
        icon: "description"
        title: "No types of your own"
        subtitle: "The Default Apps choices apply until you add one here."
    }
    Repeater {
        model: Object.keys(page.entries).sort((a, b) => a.localeCompare(b))
        RowLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 8
            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true
                Text {
                    text: modelData
                    color: Theme.text
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                Text {
                    text: page.nameOf(page.entries[modelData])
                    color: Theme.dim
                    font.pixelSize: 13
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
            IconButton {
                icon: "delete"
                tip: "Remove"
                onClicked: page.put(modelData, null)
            }
        }
    }

    //--- Adding one
    Section { text: "Add One" }
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Field {
            id: typeField
            icon: "tag"
            placeholder: "application/x-cbz"
        }
        Pill {
            text: "Add"
            onClicked: page.add()
        }
    }
    ListRow {
        visible: page.loaded && page.error !== ""
        icon: "error"
        title: "Couldn't list the installed apps"
        subtitle: page.error
    }
    Text {
        visible: !page.loaded
        text: "Reading the installed apps…"
        color: Theme.dim
        font.pixelSize: 13
        Layout.leftMargin: 6
    }
    Field {
        id: filter
        visible: page.apps.length > 8
        icon: "search"
        placeholder: "Filter apps"
    }
    ListView {
        id: appList
        visible: page.apps.length > 0
        Layout.fillWidth: true
        implicitHeight: Math.min(contentHeight, 280)
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: page.apps.filter(a => {
            const q = filter.text.toLowerCase()
            return !q || a.name.toLowerCase().includes(q) || a.id.toLowerCase().includes(q)
        })
        delegate: ListRow {
            required property var modelData
            width: appList.width
            compact: true
            icon: "apps"
            title: modelData.name
            subtitle: modelData.id
            tag: modelData.id === page.picked ? "Picked" : ""
            tagSuccess: modelData.id === page.picked
            onClicked: page.picked = modelData.id
        }
    }
}
