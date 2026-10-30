// AppArmor (Security tab): each profile's mode as the running system loaded it,
// what complain mode let through since boot (api.py's `apparmor`), and the
// machine's apparmor.enforce setting, staged once a profile compiles (apparmorCheck)
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var view
    property var profiles: null  // [{name, mode, count, lines}]
    property string error: ""
    property string checking: ""  // the profile being compile-tested
    readonly property bool ready: !!profiles || error !== ""
    readonly property var setting: {
        const p = view.info.pages["apparmor"]
        return p && p.groups.length ? p.groups[0].settings[0] : null
    }
    readonly property var enforced: {
        const v = setting ? view.valueOf(setting) : null
        return Array.isArray(v) ? v : []
    }
    readonly property bool canEdit: !!setting && view.info.direct
    spacing: 6

    Component.onCompleted: load()
    function load() {
        Backend.call("apparmor", {}, reply => {
            if (!page)
                return
            if (reply.ok)
                profiles = reply.data || []
            else
                error = reply.error
        })
    }

    function put(name, on) {
        const out = enforced.filter(n => n !== name)
        if (!on) {
            view.change(setting, out)
            return
        }
        checking = name
        Backend.call("apparmorCheck", { name }, reply => {
            if (!page)
                return
            checking = ""
            if (!reply.ok) {
                view.say(`${name} didn't compile: ${reply.error.split("\n")[0]}`)
                return
            }
            out.push(name)
            view.change(setting, out.sort())
        })
    }

    RowLayout {
        Layout.fillWidth: true
        Section {
            text: "Profiles"
            info: "In complain mode a profile blocks nothing and logs what its rules would have "
                  + "blocked. Enforce one once its count stays at zero through normal use."
            Layout.fillWidth: true
        }
        IconButton { icon: "refresh"; tip: "Check again"; Layout.topMargin: 10; onClicked: page.load() }
    }
    ListRow {
        visible: page.error !== "" || (!!page.profiles && !page.profiles.length)
        icon: "shield"
        title: page.error ? "Couldn't read the profiles" : "No profiles are loaded"
        alert: page.error
    }
    Repeater {
        model: page.profiles || []
        ProfileRow { required property var modelData; profile: modelData }
    }
    Text {
        visible: !!page.setting && !page.canEdit
        text: "Only an admin can change which profiles are enforced."
        color: Theme.dim
        font.pixelSize: 13
        Layout.leftMargin: 6
    }

    //--- One profile; tapping it shows the lines it logged
    component ProfileRow: Rectangle {
        id: row
        property var profile
        property bool open: false
        readonly property bool want: page.enforced.includes(profile.name)
        readonly property bool pending: want !== (profile.mode === "enforce")
        Layout.fillWidth: true
        implicitHeight: rowCol.implicitHeight + 22
        radius: 14
        color: Theme.card
        ColumnLayout {
            id: rowCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 11
            anchors.leftMargin: 10
            anchors.rightMargin: 12
            spacing: 8
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Badge {
                    icon: "shield"
                    tone: row.profile.count > 0 ? "caution" : row.profile.mode === "enforce" ? "success" : ""
                }
                ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true
                    Text {
                        text: row.profile.name
                        color: Theme.text
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }
                    Text {
                        visible: text !== ""
                        text: row.pending ? (row.want ? "Enforced after Apply" : "Back to complain after Apply") : ""
                        color: Theme.caution
                        font.pixelSize: 14
                    }
                }
                Text {
                    text: `${row.profile.count}`
                    color: Theme.toneColor(row.profile.count > 0 ? "caution" : "success")
                    font.pixelSize: 24
                    font.weight: Font.Bold
                    TitleTip { tip: "Times since boot its rules would have blocked something" }
                }
                Chip {
                    tappable: false
                    text: row.profile.mode === "enforce" ? "Enforce" : "Complain"
                    tone: row.profile.mode === "enforce" ? "success" : ""
                }
                Toggle {
                    visible: page.canEdit
                    // Enforcing waits for a clean log; going back to complain never does
                    enabled: page.checking === "" && (row.want || row.profile.count === 0)
                    opacity: enabled ? 1 : 0.45
                    checked: row.want
                    onToggled: on => page.put(row.profile.name, on)
                }
                Chevron {
                    visible: row.profile.count > 0
                    open: row.open
                }
            }
            Reveal {
                open: row.open
                gap: rowCol.spacing
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: logText.implicitHeight + 16
                    radius: 10
                    color: Theme.cardHover
                    TextEdit {
                        id: logText
                        x: 10
                        y: 8
                        width: parent.width - 20
                        readOnly: true
                        selectByMouse: true
                        text: row.profile.lines.join("\n")
                        color: Theme.dim
                        selectionColor: Theme.primary
                        font.family: "monospace"
                        font.pixelSize: 12
                        wrapMode: TextEdit.WrapAnywhere
                    }
                }
            }
        }
        TapHandler {
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: if (row.profile.count > 0) row.open = !row.open
        }
    }
}
