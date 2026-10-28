// The Git page: where the config repo stands (api.py's `git`), and its backup
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var view
    property var repo: null
    property string error: ""
    readonly property bool ready: !!repo || error !== ""
    property bool loading: false
    property bool saving: false
    property bool pushOpen: false
    property bool recentOpen: false
    readonly property string web: repo && repo.repo ? `https://github.com/${repo.repo}` : ""
    readonly property bool admin: !!view.info && view.info.admin
    spacing: 6

    //--- An empty url turns backups off (api.py's `setBackup`)
    function setBackup(url) {
        saving = true
        Backend.call("setBackup", { url }, reply => {
            if (!page)
                return
            saving = false
            view.say(reply.ok ? (reply.data || "Saved") : reply.error)
            if (reply.ok)
                refresh(true)
        })
    }

    //--- force: Refresh's shorter wait between fetches; cached: the last fetch's results
    //--- without fetching, so the page shows before a fetch that's due
    function refresh(force, cached) {
        if (!cached)
            loading = true
        Backend.call("git", { force, cached: !!cached }, reply => {
            if (!page)
                return  // the tab was left before the reply came
            if (!cached)
                loading = false
            else if (repo)
                return
            if (!reply.ok) {
                error = reply.error
                return
            }
            error = ""
            repo = reply.data
            const counts = { changed: repo.changed.length + repo.moreChanged, ahead: repo.outgoing.length,
                             behind: repo.incoming.length }
            if (repo.prs !== null)
                counts.prs = repo.prs.length
            view.gitCounts = counts
        })
    }

    Component.onCompleted: {
        refresh(false, true)
        refresh(false)
    }
    // The local counts every minute; gitstate decides when to fetch again
    Timer { interval: 60000; repeat: true; running: page.view.shown; onTriggered: page.refresh(false) }

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
            spacing: 10
            RowLayout {
                spacing: 14
                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true
                    Text {
                        text: `Where the config repo stands: ${page.view.info.flake}`
                              + (page.repo && page.repo.repo ? `, on github.com/${page.repo.repo}` : "") + "."
                        color: Theme.dim
                        font.pixelSize: 13
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    Chip { tappable: false; visible: page.error !== ""; tone: "error"; text: "Couldn't read" }
                    Chip {
                        tappable: false
                        visible: !!page.repo && page.repo.changed.length > 0
                        tone: "caution"
                        text: page.repo ? `${page.repo.changed.length + page.repo.moreChanged} changed` : ""
                    }
                    Chip {
                        tappable: false
                        visible: !!page.repo && page.repo.outgoing.length > 0
                        text: page.repo ? `${page.repo.outgoing.length} to push` : ""
                    }
                    Chip {
                        tappable: false
                        visible: !!page.repo && page.repo.incoming.length > 0
                        tone: "caution"
                        text: page.repo ? `${page.repo.incoming.length} to pull` : ""
                    }
                    Chip {
                        tappable: false
                        visible: !!page.repo && !page.repo.changed.length && !page.repo.outgoing.length
                                 && !page.repo.incoming.length
                        icon: "check"
                        tone: "success"
                        text: page.repo && page.repo.upstream ? "Up to date" : "Committed"
                    }
                }
                Pill {
                    quiet: true
                    enabled: !page.loading
                    text: page.loading ? "Reading…" : "Refresh"
                    onClicked: page.refresh(true)
                }
            }
        }
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
        visible: !page.repo && !page.error
        text: "Loading…"
        color: Theme.dim
        Layout.margins: 6
    }

    //--- Status
    Section { visible: !!page.repo; text: "Status" }
    ListRow {
        visible: !!page.repo
        icon: "commit"
        title: "Branch"
        subtitle: !page.repo ? "" : page.repo.upstream ? `${page.repo.branch} → ${page.repo.upstream}`
                                                       : `${page.repo.branch}, not tracking a remote`
    }
    ListRow {
        visible: !!page.repo
        icon: "history"
        title: "Commits"
        subtitle: page.repo && page.repo.total ? `${page.repo.total} in total` : ""
    }
    ListRow {
        visible: !!page.repo
        icon: "sync"
        tone: page.repo && page.repo.fetchErr ? "error" : ""
        title: "Last Fetched"
        subtitle: !page.repo ? "" : (page.repo.fetched ? Fmt.when(page.repo.fetched) : "Never")
                  + (page.repo.fetchErr ? `\nCouldn't fetch now: ${page.repo.fetchErr}` : "")
    }

    //--- Backup
    Section { visible: !!page.repo; text: "Backup" }
    ListRow {
        visible: !!page.repo
        icon: page.repo && page.repo.backup ? "cloud_done" : "cloud_off"
        tone: page.repo && page.repo.backup ? "success" : ""
        title: page.repo && page.repo.backup ? "Backing up to" : "Not backed up"
        subtitle: !page.repo ? ""
            : page.repo.backup ? `${page.repo.backup}\nEach successful rebuild commits and pushes this `
                                 + "computer's and your own settings folders there."
            : "Paste an empty repo you own (e.g. a private GitHub repo) to keep your own settings "
              + "folders there. Updates still come from the repo above."
        titleLines: 1
        button: page.repo && page.repo.backup && page.admin && !page.saving ? "Stop" : ""
        onClicked: if (page.admin && !page.saving && page.repo && page.repo.backup)
            page.view.ask({ heading: "Stop backing up?",
                            body: "Rebuilds stop committing and pushing your settings folders. What's "
                                  + "already in the backup repo stays there.",
                            buttons: [{ label: "Stop Backups", value: "stop", danger: true }] },
                          () => page.setBackup(""))
    }
    RowLayout {
        visible: !!page.repo && page.admin
        Layout.fillWidth: true
        spacing: 8
        Field {
            id: backupField
            icon: "link"
            placeholder: page.repo && page.repo.backup ? "Another repo's address"
                                                       : "https://github.com/you/my-nixos-backup.git"
            onAccepted: if (text.trim()) page.setBackup(text.trim())
        }
        Pill {
            enabled: !page.saving && backupField.text.trim() !== ""
            text: page.saving ? "Backing Up…" : "Back Up Here"
            onClicked: page.setBackup(backupField.text.trim())
        }
    }

    //--- Changed files
    Section { visible: !!page.repo && page.repo.changed.length > 0; text: "Changed Files" }
    Repeater {
        model: page.repo ? page.repo.changed : []
        Rectangle {
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: 40
            radius: 12
            color: Theme.card
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 10
                Text {
                    text: modelData.path
                    color: Theme.text
                    font.pixelSize: 15
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }
                Chip {
                    tappable: false
                    text: modelData.state
                    tone: ({ conflict: "error", deleted: "error", modified: "caution", added: "success",
                             new: "success" })[modelData.state] || ""
                    accent: !tone
                }
            }
        }
    }
    Text {
        visible: !!page.repo && page.repo.moreChanged > 0
        text: page.repo ? `And ${page.repo.moreChanged} more` : ""
        color: Theme.dim
        font.pixelSize: 13
        Layout.leftMargin: 6
    }

    //--- Open pull requests
    RowLayout {
        visible: !!page.repo
        Layout.fillWidth: true
        Section { text: "Open Pull Requests"; Layout.fillWidth: true }
        IconButton {
            visible: page.web !== ""
            icon: "open_in_new"
            onClicked: Qt.openUrlExternally(`${page.web}/pulls`)
        }
    }
    ListRow {
        visible: !!page.repo && (page.repo.prs === null || page.repo.prs.length === 0)
        icon: page.repo && page.repo.prs !== null ? "check" : "cloud_off"
        tone: !page.repo || !page.repo.repo ? "" : page.repo.limited ? "caution" : page.repo.prErr ? "error" : "success"
        title: !page.repo ? "" : !page.repo.repo ? "The origin remote isn't on GitHub"
             : page.repo.limited ? "GitHub's limit for requests without signing in is used up"
             : page.repo.prErr ? "Couldn't reach GitHub"
             : "No open pull requests"
        subtitle: !page.repo ? "" : page.repo.limited ? "Sign in with gh auth login, or try again within the hour."
                : page.repo.prErr || ""
    }
    Repeater {
        model: page.repo && page.repo.prs ? page.repo.prs : []
        ListRow {
            required property var modelData
            icon: "merge"
            titleLines: 2
            title: `#${modelData.number} ${modelData.title}`
            subtitle: [modelData.author, modelData.branch,
                       modelData.updated ? `updated ${Fmt.ago(modelData.updated)}` : ""].filter(t => t).join(" · ")
            tag: modelData.draft ? "Draft" : ""
            trailing: modelData.url ? "open_in_new" : ""
            onClicked: if (modelData.url) Qt.openUrlExternally(modelData.url)
        }
    }

    //--- Commits to push; the newest row opens the rest
    Section {
        visible: !!page.repo && page.repo.outgoing.length > 0
        text: page.repo ? `To Push (${page.repo.outgoing.length})` : "To Push"
    }
    CommitRow {
        visible: !!page.repo && page.repo.outgoing.length > 0
        commit: page.repo && page.repo.outgoing.length ? page.repo.outgoing[0] : null
        web: page.web
        expandable: !!page.repo && page.repo.outgoing.length > 1
        open: page.pushOpen
        onToggled: page.pushOpen = !page.pushOpen
    }
    Repeater {
        model: page.pushOpen && page.repo ? page.repo.outgoing.slice(1) : []
        CommitRow { required property var modelData; commit: modelData; web: page.web }
    }
    Section { visible: !!page.repo && page.repo.incoming.length > 0; text: "To Pull" }
    Repeater {
        model: page.repo ? page.repo.incoming : []
        CommitRow { required property var modelData; commit: modelData; web: page.web }
    }

    //--- Recent commits; the newest row opens the rest
    RowLayout {
        visible: !!page.repo
        Layout.fillWidth: true
        Section { text: "Recent Commits"; Layout.fillWidth: true }
        IconButton {
            visible: page.web !== ""
            icon: "open_in_new"
            onClicked: Qt.openUrlExternally(`${page.web}/commits`)
        }
    }
    CommitRow {
        visible: !!page.repo && page.repo.recent.length > 0
        commit: page.repo && page.repo.recent.length ? page.repo.recent[0] : null
        web: page.web
        expandable: !!page.repo && page.repo.recent.length > 1
        open: page.recentOpen
        onToggled: page.recentOpen = !page.recentOpen
    }
    Repeater {
        model: page.recentOpen && page.repo ? page.repo.recent.slice(1) : []
        CommitRow { required property var modelData; commit: modelData; web: page.web }
    }

    component CommitRow: ListRow {
        property var commit: null
        property string web: ""
        property bool expandable: false
        property bool open: false
        signal toggled
        icon: "commit"
        titleLines: 2
        title: commit ? commit.subject : ""
        subtitle: commit ? `${commit.short} · ${commit.author} · ${Fmt.when(commit.when)}` : ""
        trailing: expandable ? (open ? "expand_less" : "expand_more") : web ? "open_in_new" : ""
        onClicked: {
            if (expandable)
                toggled()
            else if (web)
                Qt.openUrlExternally(`${web}/commit/${commit.hash}`)
        }
    }
}
