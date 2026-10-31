// Launch Options: options to copy for Steam, Heroic and Lutris (api.py's launchOptions),
// and the upscaling option for a picked game window (upscalePick)
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: page
    required property var view
    property var lo: null
    property string error: ""
    readonly property bool ready: !!lo || error !== ""
    spacing: 6

    Component.onCompleted: Backend.call("launchOptions", {}, reply => {
        if (reply.ok)
            lo = reply.data
        else
            error = reply.error
    })

    function copy(option) {
        Quickshell.clipboardText = option
        view.say(`Copied ${option}`)
    }

    //--- Upscaling: a game window picked in niri (api.py's upscalePick)
    property var picked: null
    property bool picking: false
    function pick() {
        picking = true
        view.say("Click the game's window")
        Backend.call("upscalePick", {}, reply => {
            if (!page)
                return
            picking = false
            if (!reply.ok)
                view.say(reply.error)
            else if (reply.data)
                picked = reply.data
        })
    }

    //--- The game's launch options with the wrapper swapped in: a nix-vn, nix-rpgm or
    //--- nix-performance wrapper already there is replaced, else it goes first
    readonly property var gamesSetting: view.info ? view.info.steamGames : null
    function staged(game, wrapper) {
        const all = gamesSetting ? view.valueOf(gamesSetting) || {} : {}
        const entry = all[game.id] || {}
        let launch = (entry.launchOptions !== undefined ? entry.launchOptions : game.launch).trim()
        const old = /(^|\s)nix-(vn|rpgm|performance)[\w-]*(\s+-r\s+\d+x\d+)?(?=\s|$)/
        if (old.test(launch))
            launch = launch.replace(old, (m, lead) => lead + wrapper)
        else if (launch === "")
            launch = `${wrapper} %command%`
        else
            launch = launch.includes("%command%") ? `${wrapper} ${launch}` : `${wrapper} %command% ${launch}`
        return launch
    }
    function stage(game, wrapper) {
        const all = Object.assign({}, view.valueOf(gamesSetting) || {})
        all[game.id] = Object.assign({}, all[game.id] || {}, { launchOptions: staged(game, wrapper) })
        view.change(gamesSetting, all)
        view.say(`${game.name}: staged for Apply`)
    }

    Text {
        visible: page.error !== ""
        text: page.error
        color: Theme.error
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        Layout.margins: 6
    }

    //--- Upscaling
    Group {
        title: "Upscale a Game"
        description: "Start the game windowed with no launch options, then pick its window. The engine and "
                     + "window size give the nix-vn or nix-rpgm option to run it upscaled with NVL."
    }
    ListRow {
        icon: page.picking ? "progress_activity" : "ads_click"
        title: page.picked ? page.picked.title : "Pick a Game Window"
        subtitle: !page.picked ? ""
            : [page.picked.engine || "Engine not recognised", page.picked.size].join(" · ")
        info: page.picked ? page.picked.dir : ""
        caution: page.picked ? page.picked.note : ""
        alert: page.picked ? page.picked.alert : ""
        button: page.picking ? "" : page.picked ? "Pick Again" : "Pick"
        onClicked: page.pick()
    }
    OptionRow {
        visible: !!page.picked && page.picked.wrapper !== ""
        option: page.picked ? `${page.picked.wrapper} %command%` : ""
        text: (page.picked ? page.picked.why + " " : "") + "For Steam's launch options."
    }
    OptionRow {
        visible: !!page.picked && page.picked.wrapper !== ""
        option: page.picked ? page.picked.wrapper : ""
        text: "For Heroic's or Lutris's wrapper field."
    }
    ListRow {
        visible: !!page.picked && !!page.picked.steam && page.picked.wrapper !== "" && !!page.gamesSetting
        icon: "sports_esports"
        title: page.picked && page.picked.steam ? page.picked.steam.name : ""
        subtitle: page.picked && page.picked.steam ? page.staged(page.picked.steam, page.picked.wrapper) : ""
        info: "Sets these launch options on the Games page; Steam gets them after Apply, once it's closed."
        button: "Stage"
        onClicked: page.stage(page.picked.steam, page.picked.wrapper)
    }

    //--- Where they go
    Group {
        title: "Where They Go"
        description: "In Steam, right-click a game, then Properties, then Launch Options. Variables go before "
                     + "%command% and game arguments after it. Heroic and Lutris take variables in their "
                     + "environment table and a wrapper in their wrapper field, both without %command%."
    }
    OptionRow {
        option: "PROTON_ENABLE_WAYLAND=0 nix-performance %command% -dx11"
        text: "An example with all three, to start from."
    }

    //--- Already set for every game
    Group {
        visible: !!page.lo && page.lo.session.length > 0
        title: "Set for Every Game"
        description: "Already in this session's environment; a value in a game's options overrides one."
    }
    Flow {
        visible: !!page.lo && page.lo.session.length > 0
        Layout.fillWidth: true
        Layout.leftMargin: 4
        spacing: 6
        Repeater {
            model: page.lo ? page.lo.session : []
            Chip { tappable: false; required property var modelData; text: modelData }
        }
    }

    Repeater {
        model: page.lo ? page.lo.groups : []
        ColumnLayout {
            id: group
            required property var modelData
            Layout.fillWidth: true
            spacing: 6
            Group { title: group.modelData.title; description: group.modelData.description }
            Repeater {
                model: group.modelData.options
                OptionRow { required property var modelData; option: modelData.option; text: modelData.text }
            }
        }
    }

    component Group: ColumnLayout {
        id: head
        property string title
        property string description
        Layout.fillWidth: true
        spacing: 2
        Section { text: head.title; info: head.description }
    }

    //--- One option in monospace, its text under it; a click copies it
    component OptionRow: Rectangle {
        id: row
        property string option
        property string text
        Layout.fillWidth: true
        implicitHeight: optionCol.implicitHeight + 22
        radius: 14
        color: hover.hovered ? Theme.hover : Theme.card
        RowLayout {
            id: optionCol
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 14
            anchors.rightMargin: 12
            spacing: 10
            Text {
                text: row.option
                color: Theme.text
                font.family: "monospace"
                font.pixelSize: 16
                wrapMode: Text.WrapAnywhere
                Layout.fillWidth: true
                TitleTip { tip: row.text }
            }
            Icon { icon: "content_copy"; size: 18 }
        }
        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: page.copy(row.option) }
    }
}
