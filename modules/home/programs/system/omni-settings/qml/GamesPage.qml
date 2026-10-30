// Games (Gaming tab): Steam's installed games and the user's steamGames
// setting, each game's launch options and Proton build (api.py's steamGames),
// edited in GameEditor.qml as a pending change like any other.
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var view
    readonly property var setting: view.info ? view.info.steamGames : null
    property var steam: null  // {games, tools, default, groups}
    property string error: ""
    readonly property bool ready: !!steam || error !== ""
    spacing: 6

    property var crashCount: ({})  // app id: crashes in the last 30 days

    Component.onCompleted: load()
    function load() {
        Backend.call("steamGames", {}, reply => {
            if (!page)
                return
            if (reply.ok)
                page.steam = reply.data
            else
                page.error = reply.error
        })
        Backend.call("crashes", {}, reply => {
            if (!page || !reply.ok)
                return
            const out = {}
            for (const c of reply.data)
                if (c.app)
                    out[c.app] = (out[c.app] || 0) + 1
            page.crashCount = out
        })
    }

    //--- The steamGames setting with pending changes
    readonly property var now: {
        const v = setting ? view.valueOf(setting) : null
        return v && typeof v === "object" && !Array.isArray(v) ? v : {}
    }
    function setGame(id, entry) {
        const out = Object.assign({}, now)
        if (entry)
            out[id] = entry
        else
            delete out[id]
        view.change(setting, out)
    }

    readonly property var shown: {
        if (!steam)
            return []
        const q = search.text.trim().toLowerCase()
        const match = steam.games.filter(g => !q || g.name.toLowerCase().includes(q) || g.id.includes(q))
        // Games with a setting first, then ones that crashed
        const rank = g => g.id in now ? 0 : crashCount[g.id] ? 1 : 2
        return [0, 1, 2].map(r => match.filter(g => rank(g) === r)).reduce((a, b) => a.concat(b), [])
    }

    //--- The game's setup as chips: its Proton build and the repo's wrappers it runs
    //--- through (nix-vn-720p, nix-gamescope), or one chip for other launch options
    function tags(g) {
        const e = now[g.id]
        const launch = e && e.launchOptions !== undefined ? e.launchOptions : (g.steam.launchOptions || "")
        const proton = e && e.proton ? e.proton : g.steam.proton || ""
        const wrappers = launch.split(/\s+/).filter(t => /^nix-[a-z0-9-]+$/.test(t))
        const other = launch.trim() !== "" && !wrappers.length ? ["Launch options"] : []
        return [proton].concat(wrappers, other).filter(x => x)
    }

    property var editing: null
    function edit(g) {
        editing = g
        view.sheet = editorSheet
    }
    Component {
        id: editorSheet
        GameEditor { view: page.view; games: page; game: page.editing }
    }

    Text {
        visible: !!page.setting
        text: `Saved for ${page.view.scopeTitle()}.`
        color: Theme.dim
        font.pixelSize: 14
        Layout.leftMargin: 6
    }
    Field {
        id: search
        Layout.fillWidth: true
        icon: "search"
        placeholder: "Search games"
    }
    ListRow {
        visible: page.error !== "" || (!!page.steam && !page.shown.length)
        icon: "sports_esports"
        title: page.error ? "Couldn't list the games" : page.steam && page.steam.games.length ? "No game matches"
                                                                             : "No Steam games installed"
        alert: page.error
    }
    Repeater {
        model: page.shown
        Rectangle {
            id: gameRow
            required property var modelData
            readonly property bool hasEntry: modelData.id in page.now
            Layout.fillWidth: true
            implicitHeight: gameLayout.implicitHeight + 16
            radius: 14
            color: rowHover.hovered ? Theme.hover : Qt.alpha(Theme.bg, 0.55)
            border.width: 1
            border.color: Theme.rule
            HoverHandler { id: rowHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: page.edit(gameRow.modelData) }
            RowLayout {
                id: gameLayout
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 10
                anchors.rightMargin: 12
                spacing: 10
                Rectangle {
                    implicitWidth: 86
                    implicitHeight: 40
                    radius: 8
                    clip: true
                    color: Theme.cardHover
                    Image {
                        anchors.fill: parent
                        visible: gameRow.modelData.icon !== ""
                        source: gameRow.modelData.icon ? "file://" + gameRow.modelData.icon : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 172
                    }
                    Icon {
                        visible: gameRow.modelData.icon === ""
                        anchors.centerIn: parent
                        icon: "sports_esports"
                        size: 20
                    }
                }
                ColumnLayout {
                    spacing: 4
                    Layout.fillWidth: true
                    Text {
                        text: gameRow.modelData.name
                        color: Theme.text
                        font.pixelSize: 15
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 5
                        Repeater {
                            model: page.tags(gameRow.modelData)
                            Rectangle {
                                required property var modelData
                                implicitWidth: tagText.implicitWidth + 14
                                implicitHeight: 20
                                radius: 6
                                color: Theme.cardHover
                                Text {
                                    id: tagText
                                    anchors.centerIn: parent
                                    text: parent.modelData
                                    color: Theme.dim
                                    font.pixelSize: 11
                                }
                            }
                        }
                        Text {
                            visible: page.tags(gameRow.modelData).length === 0
                            text: "As it comes"
                            color: Theme.dim
                            font.pixelSize: 11
                        }
                    }
                }
                Chip {
                    readonly property int count: page.crashCount[gameRow.modelData.id] || 0
                    visible: count > 0
                    text: count === 1 ? "Crashed" : `Crashed ${count}×`
                    icon: "bug_report"
                    tone: "caution"
                    tip: "Crashes in the last 30 days. Edit the game to see them and copy a report."
                    onTapped: page.edit(gameRow.modelData)
                }
                Chip { visible: gameRow.hasEntry; text: "Set Here"; accent: true; tappable: false }
                // The row opens the editor
                Icon { icon: "chevron_right"; size: 20; color: rowHover.hovered ? Theme.primary : Theme.dim }
            }
        }
    }
}
