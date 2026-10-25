// The Flatpaks page: Flatpak's own switch, the apps and runtimes installed,
// updates and clean-up. An app's switch uninstalls or reinstalls it right away.
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var view
    property var fp: null  // api.py's `flatpaks`
    property string error: ""
    readonly property bool ready: !!fp || error !== ""
    property string busy: ""  // the running job: an app's key, "update", "unused" or "repair"
    property string progress: ""  // its latest line from flatpak
    property bool checking: false
    property var found: null  // flatpakUpdates' names
    property string checkError: ""
    property bool runtimesOpen: false
    readonly property var setting: view.info.pages["flatpaks"]
    spacing: 6

    function load() {
        Backend.call("flatpaks", {}, reply => {
            if (!page)
                return  // the tab was left before the reply came
            if (reply.ok)
                fp = reply.data
            else
                error = reply.error
        })
    }

    Component.onCompleted: load()

    function run(action, key) {
        if (busy) {
            view.say("Wait for the running Flatpak job to finish")
            return
        }
        busy = key || action
        progress = ""
        Backend.stream("flatpakRun", { action, key }, line => progress = line, reply => {
            busy = ""
            if (reply.ok) {
                view.say(reply.data)
                if (action === "update")
                    found = []
            } else {
                const [heading, ...rest] = reply.error.split("\n\n")
                view.ask({ heading, body: rest.join("\n\n"), cancel: false,
                           buttons: [{ label: "OK", value: true }] }, () => {})
            }
            load()
        })
    }

    function check() {
        checking = true
        found = null
        checkError = ""
        Backend.call("flatpakUpdates", {}, reply => {
            checking = false
            if (reply.ok)
                found = reply.data
            else
                checkError = reply.error
        })
    }

    function toggle(app, on) {
        if (on) {
            run("install", app.key)
            return
        }
        view.ask({
            heading: `Uninstall ${app.name}?`,
            body: app.bundle
                ? `It came from a downloaded file, so to get it back you install that file again. `
                  + `Its settings and files in ~/.var/app/${app.id} stay.`
                : `Its settings and files in ~/.var/app/${app.id} stay, so switching it on brings it back as it was.`,
            buttons: [{ label: "Uninstall", value: true, danger: true }]
        }, () => run("uninstall", app.key))
    }

    function where(ref) { return ref.installation === "system" ? "Everyone" : "Just you" }

    Text {
        text: "Apps nixpkgs doesn't have: update them, clean up, and switch each one on or off."
        color: Theme.dim
        font.pixelSize: 15
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        Layout.leftMargin: 6
        Layout.bottomMargin: 4
    }

    //--- Flatpak's own switch, a machine setting like any other
    Repeater {
        model: page.setting ? page.setting.groups : []
        ColumnLayout {
            id: group
            required property var modelData
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: group.modelData.settings
                SettingRow {
                    required property var modelData
                    setting: modelData
                    view: page.view
                    locked: !page.view.info.direct
                    pageGlyph: "widgets"
                }
            }
        }
    }
    Text {
        visible: !page.view.info.direct
        text: "Only an admin can turn Flatpak on or off. It's on or off for everyone who uses this computer."
        color: Theme.caution
        font.pixelSize: 13
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        Layout.leftMargin: 6
    }

    Text {
        visible: !page.fp
        text: page.error || "Loading…"
        color: page.error ? Theme.error : Theme.dim
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        Layout.margins: 6
    }
    ListRow {
        visible: !!page.fp && !page.fp.installed
        icon: "info"
        title: "Flatpak isn't installed"
        subtitle: "Turn Flatpak on and apply, and its apps show up here. "
                  + "It starts working after the rebuild that turns it on."
    }

    ColumnLayout {
        visible: !!page.fp && page.fp.installed
        Layout.fillWidth: true
        spacing: 6

        //--- Flatseal
        Section { text: "Permissions" }
        ListRow {
            icon: "shield"
            app: ["com.github.tchx84.Flatseal.desktop", "com.github.tchx84.Flatseal"]
            title: "Flatseal"
            subtitle: page.fp && page.fp.flatseal ? "Change what each app may reach."
                : "Not installed yet. It installs in the background after the rebuild that turned Flatpak on."
            button: page.fp && page.fp.flatseal ? "Open" : ""
            onClicked: if (page.fp.flatseal) Backend.call("flatseal", {})
        }

        //--- Updates
        Section { text: "Updates" }
        ListRow {
            icon: page.checking || page.busy === "update" ? "progress_activity" : "update"
            title: "Apps and Runtimes"
            tone: page.busy === "update" || page.checking ? "" : page.checkError ? "error"
                : page.found === null ? "" : page.found.length ? "caution" : "success"
            subtitle: page.busy === "update" ? (page.progress || "Updating…")
                : page.checking ? "Asking each source for its newest versions…"
                : page.checkError ? `Couldn't check: ${page.checkError}`
                : page.found === null ? "Look for newer versions."
                : !page.found.length ? "Everything is up to date."
                : `${page.found.length} to update: ${page.found.slice(0, 6).join(", ")}${page.found.length > 6 ? "…" : ""}`
            button: page.checking || page.busy ? "" : page.found && page.found.length ? "Update All"
                  : page.found ? "Check Again" : "Check"
            onClicked: {
                if (page.checking || page.busy)
                    return
                if (page.found && page.found.length)
                    page.run("update")
                else
                    page.check()
            }
        }

        //--- Apps
        Section { text: "Installed Apps" }
        Text {
            text: "Switching an app off uninstalls it and keeps its settings and files, so switching it on "
                  + "brings it back as it was."
            color: Theme.dim
            font.pixelSize: 13
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            Layout.leftMargin: 6
        }
        Repeater {
            model: page.fp && page.fp.installed ? page.fp.apps.concat(page.fp.off.map(a => Object.assign({ off: true }, a))) : []
            AppRow { required property var modelData; app: modelData }
        }
        ListRow {
            visible: !!page.fp && page.fp.installed && !page.fp.apps.length && !page.fp.off.length
            icon: "widgets"
            title: "No Flatpak apps yet"
            subtitle: "Find one on flathub.org, then install it with: flatpak install flathub <its id>"
            trailing: "open_in_new"
            onClicked: Qt.openUrlExternally("https://flathub.org")
        }

        //--- Runtimes
        Rectangle {
            visible: !!page.fp && page.fp.installed && page.fp.runtimes.length > 0
            Layout.fillWidth: true
            implicitHeight: rtCol.implicitHeight + 22
            radius: 14
            color: Theme.card
            ColumnLayout {
                id: rtCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 11
                anchors.leftMargin: 10
                anchors.rightMargin: 12
                spacing: 6
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Badge { icon: "extension" }
                    ColumnLayout {
                        spacing: 1
                        Layout.fillWidth: true
                        Text {
                            text: page.fp && page.fp.installed ? `Runtimes (${page.fp.runtimes.length})` : ""
                            color: Theme.text
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                        }
                        Text {
                            text: page.fp && page.fp.installed
                                ? `Shared parts the apps run on, ${Fmt.size(page.fp.runtimeBytes)} in all` : ""
                            color: Theme.dim
                            font.pixelSize: 13
                            Layout.fillWidth: true
                        }
                    }
                    Icon { icon: "expand_more"; rotation: page.runtimesOpen ? 180 : 0 }
                    TapHandler {
                        gesturePolicy: TapHandler.ReleaseWithinBounds
                        onTapped: page.runtimesOpen = !page.runtimesOpen
                    }
                }
                Repeater {
                    model: page.runtimesOpen && page.fp && page.fp.installed ? page.fp.runtimes : []
                    ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.leftMargin: 50
                        spacing: 0
                        Text {
                            text: modelData.id
                            color: Theme.text
                            font.pixelSize: 15
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: [modelData.branch, page.where(modelData), modelData.size].filter(t => t).join(" · ")
                            color: Theme.dim
                            font.pixelSize: 13
                        }
                    }
                }
            }
        }

        //--- Maintenance
        Section { text: "Maintenance" }
        ListRow {
            icon: page.busy === "unused" ? "progress_activity" : "delete_sweep"
            title: "Remove Unused Runtimes"
            subtitle: page.busy === "unused" ? (page.progress || "Removing…")
                : "Uninstalls runtimes and extensions that no installed app needs any more."
            button: page.busy ? "" : "Remove"
            onClicked: if (!page.busy) page.run("unused")
        }
        ListRow {
            icon: page.busy === "repair" ? "progress_activity" : "build"
            title: "Repair"
            subtitle: page.busy === "repair" ? (page.progress || "Repairing…")
                : "Checks every installed file and downloads again any that are missing or damaged."
            button: page.busy ? "" : "Repair"
            onClicked: if (!page.busy) page.run("repair")
        }
    }

    //--- One app: installed, or switched off here
    component AppRow: Rectangle {
        id: appRow
        property var app
        readonly property bool working: page.busy === app.key
        readonly property bool flatsealItself: app.id === "com.github.tchx84.Flatseal" && app.installation === "system"
        Layout.fillWidth: true
        implicitHeight: appLayout.implicitHeight + 22
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
            Badge {
                icon: appRow.working ? "progress_activity" : "widgets"
                app: appRow.working ? [] : [appRow.app.id + ".desktop", appRow.app.id]
            }
            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true
                Text {
                    text: appRow.app.name
                    color: Theme.text
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: appRow.working ? (page.progress || "Working…")
                        : appRow.app.off ? `${page.where(appRow.app)}\nSwitched off. Switch it on to install it again.`
                        : [appRow.app.version, page.where(appRow.app), appRow.app.size].filter(t => t).join(" · ")
                          + (appRow.app.bundle ? " · from a downloaded file" : "")
                    color: Theme.dim
                    font.pixelSize: 13
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    visible: !!appRow.app.missing
                    text: `Can't start: it needs the ${appRow.app.runtime} runtime, which isn't installed`
                    color: Theme.caution
                    font.pixelSize: 13
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
            Pill {
                visible: !!appRow.app.missing && !page.busy
                text: "Install Runtime"
                onClicked: page.run("runtime", appRow.app.key)
            }
            IconButton {
                visible: !appRow.app.off && !!page.fp && page.fp.flatseal && !appRow.flatsealItself
                icon: "shield"
                onClicked: Backend.call("flatseal", { app: appRow.app.id })
            }
            Chip { tappable: false; visible: appRow.flatsealItself; accent: true; text: "Comes with Flatpak" }
            IconButton {
                visible: !!appRow.app.off
                icon: "close"
                onClicked: Backend.call("flatpakForget", { key: appRow.app.key }, () => page.load())
            }
            Toggle {
                visible: !appRow.flatsealItself
                enabled: !page.busy
                checked: !appRow.app.off
                onToggled: on => page.toggle(appRow.app, on)
            }
        }
    }
}
