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

    function summary(g) {
        const e = now[g.id]
        const launch = e && e.launchOptions !== undefined ? e.launchOptions : (g.steam.launchOptions || "")
        const proton = e && e.proton ? e.proton : g.steam.proton || ""
        return [proton, launch].filter(x => x).join(" · ") || "As it comes"
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
            color: rowHover.hovered ? Theme.cardHover : Theme.card
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
                    spacing: 1
                    Layout.fillWidth: true
                    Text {
                        text: gameRow.modelData.name
                        color: Theme.text
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: page.summary(gameRow.modelData)
                        color: Theme.dim
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        Layout.fillWidth: true
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
                // Words, as the page headers' Show and Hide, not a dropdown's arrow
                Chip { text: "Edit"; tappable: false; accent: rowHover.hovered }
            }
        }
    }
}
