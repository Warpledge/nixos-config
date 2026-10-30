// Run on dGPU (Hardware tab): the user's gpuOffload setting, apps whose
// launcher entry starts them through nvidia-offload (modules/home/gpu-offload.nix)
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var view
    readonly property var setting: view.info ? view.info.gpuOffload : null
    readonly property var picked: {
        const v = setting ? view.valueOf(setting) : null
        return Array.isArray(v) ? v : []
    }
    property var apps: []
    property bool loaded: false
    property string error: ""
    readonly property bool ready: loaded
    readonly property var shown: {
        const q = search.text.trim().toLowerCase()
        const match = apps.filter(a => !q || a.name.toLowerCase().includes(q) || a.id.toLowerCase().includes(q))
        // Switched-on apps first, then by name as mimeApps sorts them
        return match.filter(a => picked.includes(a.id)).concat(match.filter(a => !picked.includes(a.id)))
    }
    spacing: 6

    function put(id, on) {
        if (!setting)
            return
        const out = picked.filter(p => p !== id)
        if (on)
            out.push(id)
        view.change(setting, out.sort())
    }

    Component.onCompleted: Backend.call("mimeApps", {}, reply => {
        if (!page)
            return
        page.loaded = true
        if (reply.ok)
            page.apps = reply.data
        else
            page.error = reply.error
    })

    Text {
        text: `Saved for ${page.view.scopeTitle()}.`
        color: Theme.dim
        font.pixelSize: 14
        Layout.leftMargin: 6
    }
    Section {
        text: "Apps"
        info: "A switched-on app starts on the NVIDIA GPU when opened from the launcher. Everything "
              + "else stays on the integrated one, which saves battery."
    }
    Field {
        id: search
        Layout.fillWidth: true
        icon: "search"
        placeholder: "Search apps"
    }
    ListRow {
        visible: page.error !== "" || (page.loaded && !page.shown.length)
        icon: "apps"
        title: page.error ? "Couldn't list the apps" : "No app matches"
        alert: page.error
    }
    Repeater {
        model: page.shown.slice(0, 80)
        Rectangle {
            id: appRow
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: appLayout.implicitHeight + 18
            radius: 14
            color: Theme.card
            RowLayout {
                id: appLayout
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 10
                anchors.rightMargin: 12
                spacing: 10
                Badge { icon: "apps"; app: [appRow.modelData.id] }
                ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true
                    Text {
                        text: appRow.modelData.name
                        color: Theme.text
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: appRow.modelData.id
                        color: Theme.dim
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
                Toggle {
                    checked: page.picked.includes(appRow.modelData.id)
                    onToggled: on => page.put(appRow.modelData.id, on)
                }
            }
        }
    }
    Text {
        visible: page.shown.length > 80
        text: `${page.shown.length - 80} more; search to find one`
        color: Theme.dim
        font.pixelSize: 13
        Layout.leftMargin: 6
    }
}
