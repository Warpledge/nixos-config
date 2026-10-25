// The Git page: where the config repo stands, read-only (api.py's `git`)
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var view
    property var repo: null
    property string error: ""
    readonly property bool ready: !!repo || error !== ""
    property bool loading: false
    readonly property string web: repo && repo.repo ? `https://github.com/${repo.repo}` : ""
    spacing: 6

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
        icon: "sync"
        tone: page.repo && page.repo.fetchErr ? "error" : ""
        title: "Last Fetched"
        subtitle: !page.repo ? "" : (page.repo.fetched ? Fmt.when(page.repo.fetched) : "Never")
                  + (page.repo.fetchErr ? `\nCouldn't fetch now: ${page.repo.fetchErr}` : "")
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

    //--- Commits to push and pull
    Section { visible: !!page.repo && page.repo.outgoing.length > 0; text: "To Push" }
    Repeater {
        model: page.repo ? page.repo.outgoing : []
        CommitRow { required property var modelData; commit: modelData; web: page.web }
    }
    Section { visible: !!page.repo && page.repo.incoming.length > 0; text: "To Pull" }
    Repeater {
        model: page.repo ? page.repo.incoming : []
        CommitRow { required property var modelData; commit: modelData; web: page.web }
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

    //--- Recent commits
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
    Repeater {
        model: page.repo ? page.repo.recent : []
        CommitRow { required property var modelData; commit: modelData; web: page.web }
    }

    component CommitRow: ListRow {
        property var commit
        property string web
        icon: "commit"
        titleLines: 2
        title: commit.subject
        subtitle: `${commit.short} · ${commit.author} · ${Fmt.when(commit.when)}`
        trailing: web ? "open_in_new" : ""
        onClicked: if (web) Qt.openUrlExternally(`${web}/commit/${commit.hash}`)
    }
}
