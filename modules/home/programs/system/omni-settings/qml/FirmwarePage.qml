// Firmware (Hardware tab): the devices fwupd knows and updates waiting
// (api.py's `firmware`); Update installs them as a `firmware` job
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var view
    property var fw: null
    property string error: ""
    property bool checking: false
    readonly property bool ready: !!fw || error !== ""
    readonly property var waiting: fw ? fw.devices.filter(d => d.available) : []
    spacing: 6

    function load(fresh) {
        checking = true
        Backend.call("firmware", { fresh: !!fresh }, reply => {
            if (!page)
                return  // the tab was left before the reply came
            checking = false
            if (reply.ok) {
                error = ""
                fw = reply.data
                view.firmwareUpdates = fw.updates
            } else {
                error = reply.error
            }
        })
    }

    function update() {
        if (!view.canStart())
            return
        view.ask({
            heading: "Install firmware updates?",
            body: "Keep the computer plugged in. Some devices finish installing while the computer "
                  + "restarts, so save your work before restarting afterwards.",
            buttons: [{ label: "Update", value: true }]
        }, () => view.startJob("firmware", {}))
    }

    Component.onCompleted: load(false)

    RowLayout {
        Layout.fillWidth: true
        Section {
            text: "Updates"
            info: "New firmware from the Linux Vendor Firmware Service. The list refreshes on its own "
                  + "every day."
            Layout.fillWidth: true
        }
        IconButton {
            icon: page.checking ? "progress_activity" : "refresh"
            tip: "Check again"
            enabled: !page.checking
            Layout.topMargin: 10
            onClicked: page.load(true)
        }
    }
    ListRow {
        visible: !page.waiting.length
        icon: "verified"
        title: !page.fw && !page.error ? "Checking…" : "Everything is up to date"
        alert: page.error
    }
    ListRow {
        visible: page.waiting.length > 0
        icon: "system_update"
        tone: "caution"
        title: `${page.waiting.length} update${page.waiting.length === 1 ? "" : "s"} waiting`
        button: page.view.info && page.view.info.admin ? "Update" : ""
        caution: page.view.info && page.view.info.admin ? "" : "Only an admin can install firmware"
        onClicked: page.update()
    }
    Repeater {
        model: page.waiting
        ListRow {
            required property var modelData
            icon: "memory"
            title: modelData.name
            subtitle: `${modelData.vendor ? modelData.vendor + " · " : ""}${modelData.version} → ${modelData.available}`
            info: modelData.summary
        }
    }

    Section { text: "Devices"; info: "Everything fwupd found. Only updatable devices can get new firmware." }
    Repeater {
        model: page.fw ? page.fw.devices.filter(d => !d.available) : []
        ListRow {
            required property var modelData
            icon: "memory"
            compact: true
            title: modelData.name
            subtitle: [modelData.vendor, modelData.version].filter(t => t).join(" · ")
            tag: modelData.updatable ? "" : "Not updatable"
        }
    }
}
