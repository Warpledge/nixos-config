// Drives (Hardware tab): each disk's volumes, free space and SMART health
// (api.py's `drives`), mounting through udisks (`driveMount`), and the machine's
// drives.mounts setting. Encrypted volumes only ever show; nothing here formats.
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var view
    property var drives: null
    property string error: ""
    property string busy: ""  // the device path being mounted or unmounted
    property string adding: ""  // the volume whose mount point field is open
    readonly property bool ready: !!drives || error !== ""
    readonly property bool admin: !!view.info && !!view.info.admin
    readonly property var setting: view.info ? view.info.driveMounts : null
    readonly property var mounts: {
        const v = setting ? view.valueOf(setting) : null
        return Array.isArray(v) ? v : []
    }
    spacing: 6

    function load() {
        Backend.call("drives", {}, reply => {
            if (!page)
                return  // the tab was left before the reply came
            if (reply.ok) {
                error = ""
                drives = reply.data
            } else {
                error = reply.error
            }
        })
    }

    function mount(vol, on) {
        busy = vol.path
        Backend.call("driveMount", { path: vol.path, mount: on }, reply => {
            if (!page)
                return
            busy = ""
            if (!reply.ok)
                view.say(reply.error)
            load()
        })
    }

    function entryFor(vol) {
        return mounts.find(m => m.uuid === vol.uuid)
    }

    //--- Why this mount point can't be used, or ""
    function pointProblem(point) {
        if (!/^\/mnt\/[A-Za-z0-9][A-Za-z0-9._-]*$/.test(point))
            return "Use a folder directly under /mnt, like /mnt/backup"
        if (mounts.some(m => m.mountPoint === point) || (drives && drives.claimed.includes(point)))
            return `${point} is already in use`
        return ""
    }

    function addMount(vol, point) {
        const problem = pointProblem(point)
        if (problem) {
            view.say(problem)
            return
        }
        view.change(setting, mounts.concat([{ uuid: vol.uuid, mountPoint: point, fsType: vol.fstype }]))
        adding = ""
    }

    function removeMount(uuid) {
        view.change(setting, mounts.filter(m => m.uuid !== uuid))
    }

    function healthText(h) {
        if (!h || h.passed === null || h.passed === undefined)
            return "Not read yet"
        return h.passed ? "Healthy" : "Failing"
    }

    function healthDetail(h) {
        if (!h)
            return ""
        const out = []
        if (h.temperature !== null && h.temperature !== undefined)
            out.push(`${h.temperature} °C`)
        if (h.hours !== null && h.hours !== undefined)
            out.push(`${h.hours.toLocaleString()} hours on`)
        if (h.wear !== null && h.wear !== undefined)
            out.push(`${h.wear}% worn`)
        if (h.reallocated)
            out.push(`${h.reallocated} reallocated sectors`)
        if (h.pending)
            out.push(`${h.pending} pending sectors`)
        return out.join(" · ")
    }

    function bytes(n) {
        const units = ["B", "KB", "MB", "GB", "TB", "PB"]
        let v = Number(n) || 0, i = 0
        while (v >= 1000 && i < units.length - 1) {
            v /= 1000
            i++
        }
        return `${v >= 100 || i === 0 ? Math.round(v) : v.toFixed(1)} ${units[i]}`
    }

    function volumeLine(v) {
        const out = [v.fstype || "No filesystem", bytes(v.size)]
        if (v.mounted)
            out.unshift(v.mounted)
        if (v.free !== null && v.free !== undefined)
            out.push(`${bytes(v.free)} free`)
        return out.join(" · ")
    }

    Component.onCompleted: load()

    RowLayout {
        Layout.fillWidth: true
        Section {
            text: "Disks"
            info: "Health comes from each drive's SMART data, read every hour. A sleeping disk keeps "
                  + "its last reading."
            Layout.fillWidth: true
        }
        IconButton {
            icon: "refresh"
            tip: "Check again"
            Layout.topMargin: 10
            onClicked: page.load()
        }
    }
    ListRow {
        visible: page.error !== ""
        icon: "error"
        tone: "caution"
        title: "Couldn't read the drives"
        alert: page.error
    }
    Repeater {
        model: page.drives ? page.drives.disks : []
        ColumnLayout {
            id: disk
            required property var modelData
            Layout.fillWidth: true
            spacing: 4
            ListRow {
                icon: disk.modelData.removable ? "usb" : "hard_drive"
                title: disk.modelData.model
                subtitle: [page.bytes(disk.modelData.size), page.healthDetail(disk.modelData.health)]
                          .filter(t => t).join(" · ")
                tag: page.healthText(disk.modelData.health)
                tagSuccess: !!disk.modelData.health && disk.modelData.health.passed === true
                tone: !!disk.modelData.health && disk.modelData.health.passed === false ? "error" : ""
            }
            Repeater {
                model: disk.modelData.volumes
                ColumnLayout {
                    id: vol
                    required property var modelData
                    readonly property var entry: page.entryFor(modelData)
                    readonly property bool can: !modelData.refused
                    Layout.fillWidth: true
                    Layout.leftMargin: 16
                    spacing: 4
                    ListRow {
                        icon: vol.modelData.encrypted ? "lock" : "folder"
                        compact: true
                        title: vol.modelData.label || vol.modelData.name
                        subtitle: page.volumeLine(vol.modelData)
                        tag: vol.modelData.encrypted ? "Encrypted" : ""
                        info: vol.modelData.refused
                        bar: vol.modelData.used === null ? -1 : vol.modelData.used / 100
                        button: !vol.can || page.busy === vol.modelData.path ? ""
                                : vol.modelData.mounted ? "Unmount" : "Mount"
                        onClicked: page.mount(vol.modelData, !vol.modelData.mounted)
                    }
                    RowLayout {
                        visible: page.admin && vol.can && !!vol.modelData.uuid && page.adding !== vol.modelData.path
                        Layout.leftMargin: 50
                        Layout.rightMargin: 12
                        Text {
                            text: vol.entry ? `Mounts at ${vol.entry.mountPoint} on startup` : ""
                            visible: !!vol.entry
                            color: Theme.dim
                            font.pixelSize: 12
                            Layout.fillWidth: true
                        }
                        Item { visible: !vol.entry; Layout.fillWidth: true }
                        OutlineButton {
                            text: vol.entry ? "Remove" : "Mount at startup"
                            onClicked: {
                                if (vol.entry) {
                                    page.removeMount(vol.modelData.uuid)
                                } else {
                                    pointField.text = vol.modelData.suggest
                                    page.adding = vol.modelData.path
                                }
                            }
                        }
                    }
                    RowLayout {
                        visible: page.adding === vol.modelData.path
                        Layout.leftMargin: 50
                        Layout.rightMargin: 12
                        Field {
                            id: pointField
                            placeholder: "/mnt/backup"
                            onAccepted: page.addMount(vol.modelData, text.trim())
                            onEscaped: page.adding = ""
                        }
                        OutlineButton {
                            text: "Add"
                            filled: true
                            onClicked: page.addMount(vol.modelData, pointField.text.trim())
                        }
                        OutlineButton { text: "Cancel"; onClicked: page.adding = "" }
                    }
                }
            }
        }
    }
    //--- Saved entries whose drive isn't plugged in, so they can still be removed
    Repeater {
        model: page.mounts.filter(m => !page.drives || !page.drives.disks.some(
                                      d => d.volumes.some(v => v.uuid === m.uuid)))
        ListRow {
            required property var modelData
            icon: "folder_off"
            compact: true
            title: modelData.mountPoint
            subtitle: "Mounts at startup, but this drive isn't connected"
            button: page.admin ? "Remove" : ""
            onClicked: page.removeMount(modelData.uuid)
        }
    }
}
