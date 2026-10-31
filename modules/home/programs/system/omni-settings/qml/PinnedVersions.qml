// Pinned Versions, on the Maintenance page: upstream versions past the config's hand-made
// pins (api.py's `upstream`)
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var view
    property var up: null  // { checked, rows }
    property string error: ""
    property bool loading: false
    property bool open: false  // whether the pins are listed
    readonly property bool ready: !!up || error !== ""
    readonly property var groups: [
        { kind: "disabled", title: "Disabled Packages",
          info: "Packages switched off in docs/nixpkgs/disabled-packages.md, checked against nixos-unstable's binary cache" },
        { kind: "release", title: "App Releases", info: "AppImages, .debs, jars and tarballs pinned to an upstream release" },
        { kind: "nightly", title: "Nightly Builds", info: "Apps pinned to a rolling nightly release, compared by date" },
        { kind: "input", title: "Flake Inputs on a Tag", info: "Inputs locked to a version tag, which a flake update never moves" },
        { kind: "commit", title: "Pinned Commits", info: "Sources pinned to one commit, with how many upstream has added since" },
        { kind: "local", title: "Local Bundles", info: "Apps unpacked into ~/.local/opt, outside the config" }
    ]
    readonly property int updates: up ? up.rows.filter(r => r.status === "update").length : 0
    spacing: 6

    //--- force: check now; cached: only the last check's results, so the page shows at once
    function load(force, cached) {
        if (!cached)
            loading = true
        Backend.call("upstream", { force: !!force, cached: !!cached }, reply => {
            if (!page)
                return  // the tab was left before the reply came
            if (!cached)
                loading = false
            if (reply.ok) {
                if (!cached || reply.data.checked)
                    up = reply.data
                error = ""
            } else {
                error = reply.error
            }
            if (cached && !(reply.ok && reply.data.checked))
                load(false, false)
        })
    }

    Component.onCompleted: load(false, true)

    function shown(r) {
        if (r.status === "error" || r.status === "unknown")
            return r.current || "?"
        if (r.kind === "disabled")
            return r.status === "update" ? "Fixed" : "Broken"
        return r.status === "update" ? `${r.current} → ${r.latest}` : "Up to date"
    }

    ListRow {
        icon: page.loading ? "progress_activity" : "push_pin"
        title: "Pinned Versions"
        info: "Hand-pinned apps and disabled packages, against upstream. Read-only: nothing here "
              + "changes a pin. Checked at most once an hour unless you check now. Also in a "
              + "terminal as `nixm check-updates`."
              + (page.up && page.up.checked ? ` Checked ${Fmt.when(page.up.checked)}.` : "")
        value: page.loading ? "Checking…" : !page.up ? "Not checked"
            : page.updates ? `${page.updates} upstream` : "Up to date"
        alert: page.error ? `Couldn't check: ${page.error}` : ""
        expandable: true
        expanded: page.open
        onClicked: page.open = !page.open
    }

    Reveal {
        id: reveal
        open: page.open
        gap: page.spacing
        spacing: 6

        Pill {
            Layout.alignment: Qt.AlignRight
            enabled: !page.loading
            text: page.loading ? "Checking…" : "Check Now"
            onClicked: page.load(true, false)
        }

        Repeater {
            model: page.up && reveal.shown ? page.groups : []
            ColumnLayout {
                id: group
                required property var modelData
                readonly property var rows: page.up.rows.filter(r => r.kind === modelData.kind)
                visible: rows.length > 0
                spacing: 6
                Layout.fillWidth: true
                Section { text: group.modelData.title; info: group.modelData.info }
                Repeater {
                    model: group.rows
                    ListRow {
                        required property var modelData
                        icon: modelData.status === "update" ? "upgrade"
                            : modelData.status === "ok" ? (modelData.kind === "disabled" ? "block" : "check") : modelData.status === "error" ? "error" : "help"
                        tone: modelData.status === "update" ? "success"
                            : modelData.status === "error" ? "error" : modelData.status === "unknown" ? "caution" : ""
                        title: modelData.name
                        info: modelData.file ? `Pinned in ${modelData.file}` : ""
                        alert: modelData.status === "ok" ? "" : modelData.note
                        value: page.shown(modelData)
                        trailing: "open_in_new"
                        onClicked: Qt.openUrlExternally(modelData.link)
                    }
                }
            }
        }
    }
}
