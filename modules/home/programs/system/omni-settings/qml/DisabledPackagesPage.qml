// Disabled Packages: docs/nixpkgs/disabled-packages.md's rows, whether each builds on
// nixos-unstable again, and a switch back on that waits for Apply (api.py's
// disabledPackages and disabledCheck; the job service drops the row once it's applied)
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var view
    property var dp: null
    property string error: ""
    readonly property bool ready: !!dp || error !== ""
    property var checking: ({})  // name -> true while its check runs
    property var checks: ({})  // name -> a check made on this page
    spacing: 6

    function load() {
        Backend.call("disabledPackages", {}, reply => {
            if (!page)
                return
            if (reply.ok) {
                dp = reply.data
                error = ""
            } else {
                error = reply.error
            }
        })
    }

    Component.onCompleted: load()

    function check(name) {
        checking = Object.assign({}, checking, { [name]: true })
        Backend.call("disabledCheck", { name }, reply => {
            if (!page)
                return
            const c = Object.assign({}, checking)
            delete c[name]
            checking = c
            if (reply.ok)
                checks = Object.assign({}, checks, { [name]: reply.data })
            else
                view.say(reply.error)
        })
    }

    function result(r) { return checks[r.name] || r.check }
    function waiting(r) { return !!r.setting && r.setting.key in view.pending && view.pending[r.setting.key] === true }

    //--- Fixed builds on unstable; unfree ones Hydra never builds, so they're tried
    function turnOn(r) {
        const unfree = result(r) && result(r).status === "unknown"
        view.ask({ heading: `Turn ${r.name} back on?`,
                   body: unfree ? "Hydra doesn't build unfree packages, so this only tries it: use Preview "
                                  + "under Apply to build it first. If it still fails, discard the change."
                                : "It waits for Apply. Once that rebuild works, its row leaves "
                                  + "disabled-packages.md.",
                   buttons: [{ label: unfree ? "Try It" : "Turn On", value: "on" }] },
                 () => view.change(r.setting, true))
    }

    Text {
        visible: page.error !== ""
        text: page.error
        color: Theme.error
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        Layout.margins: 6
    }
    Text {
        visible: !page.dp && !page.error
        text: "Loading…"
        color: Theme.dim
        Layout.margins: 6
    }

    Section {
        visible: !!page.dp
        text: "Switched Off"
        info: "From docs/nixpkgs/disabled-packages.md. Check asks cache.nixos.org whether nixos-unstable "
              + "builds it now."
    }
    ListRow {
        visible: !!page.dp && !page.dp.rows.length
        icon: "check_circle"
        title: "Nothing switched off"
    }
    Repeater {
        model: page.dp ? page.dp.rows : []
        ListRow {
            id: pkgRow
            required property var modelData
            readonly property var r: modelData
            readonly property var c: page.result(r)
            readonly property bool busy: !!page.checking[r.name]
            readonly property bool fixed: !!c && c.status === "update"
            readonly property bool unfree: !!c && c.status === "unknown"
            readonly property bool canFlip: (fixed || unfree) && !!r.setting && !page.waiting(r)
            icon: busy ? "progress_activity" : fixed ? "check_circle" : unfree ? "help" : "block"
            tone: fixed ? "success" : c && c.status === "error" ? "error" : ""
            title: r.name
            subtitle: r.date
            info: r.reason
            value: page.waiting(r) ? "Waiting for Apply" : busy ? "Checking…" : !c ? ""
                 : fixed ? "Builds again" : unfree ? "Unfree" : c.status === "error" ? "Error" : "Still broken"
            alert: page.waiting(r) ? ""
                 : c && c.status === "error" ? c.note
                 : (fixed || unfree) && !r.setting
                     ? (r.why || `Not a switch: add it back where it was taken out (${r.where.replace(/`/g, "")}), `
                                + "then delete its row.")
                 : ""
            button: busy || page.waiting(r) ? "" : canFlip ? (unfree ? "Try It" : "Turn Back On")
                  : (fixed || unfree) && !r.setting ? "Open List" : "Check"
            onClicked: canFlip ? page.turnOn(r)
                     : (fixed || unfree) && !r.setting ? page.view.openFile(page.dp.doc)
                     : page.check(r.name)
        }
    }
}
