// Window Rules (Niri tab): the config's shared rules with the user's changes
// (their windowRules setting, a pending change like any other) by group, a form
// that adds one for a picked window, and the rules Nix sets (api.py's windowRules)
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var view
    property var wr: null
    property string error: ""
    property bool showIds: false
    property bool picking: false
    property var windows: null  // the Open Windows list, null while closed
    readonly property bool niri: !!view.info && view.info.wm === "niri"
    readonly property var setting: view.info ? view.info.windowRules : null
    readonly property bool editable: !!wr && !!setting
    readonly property bool ready: !niri || !!wr || error !== ""
    spacing: 6

    Component.onCompleted: if (niri) load()
    onNowChanged: if (niri) load()

    //--- A rebuild writes a new copy of what niri got
    Connections {
        target: Jobs
        function onEnded() { if (page.niri) page.load() }
    }

    //--- The windowRules setting with pending changes ({id: change}), or as saved
    function changes(saved) {
        const v = !setting ? null : saved ? view.scopedValue(setting) : view.valueOf(setting)
        return v && typeof v === "object" && !Array.isArray(v) ? v : {}
    }
    readonly property var now: changes(false)

    function setChange(id, change) {
        const out = Object.assign({}, now)
        if (change && Object.keys(change).length)
            out[id] = change
        else
            delete out[id]
        view.change(setting, out)
    }

    function load() {
        Backend.call("windowRules", { now, saved: changes(true) }, reply => {
            if (reply.ok) {
                wr = reply.data
                error = ""
            } else
                error = reply.error
        })
    }

    //--- Group chip kinds as tones
    function tone(kind) {
        return kind === "success" ? "success" : kind === "warning" ? "caution" : kind === "error" ? "error" : ""
    }

    //--------------------------------------------------------------------//
    //-- Picking a window and adding a rule
    //--------------------------------------------------------------------//
    property var picked: null
    property int kindIndex: 0
    property int choiceIndex: 0
    property int sizeIndex: 1
    property int placeIndex: 0
    readonly property var kind: wr ? wr.kinds[kindIndex] : null
    readonly property var places: !kind ? [] : kind.control === "workspace" ? wr.workspaces
                                       : kind.control === "output" ? wr.outputs : []

    function pick() {
        picking = true
        view.say("Click the window to make a rule for")
        Backend.call("pickWindow", {}, reply => {
            picking = false
            if (!reply.ok)
                view.say(`Couldn't pick a window: ${reply.error}`)
            else if (reply.data)
                use(reply.data)
        })
    }

    function listWindows() {
        if (windows) {
            windows = null
            return
        }
        windows = []
        Backend.call("niriWindows", {}, reply => {
            if (reply.ok)
                windows = reply.data
            else {
                windows = null
                view.say(`Couldn't list the windows: ${reply.error}`)
            }
        })
    }

    function regex(text) {
        return "^" + text.replace(/[\\.+*?()|[\]{}^$]/g, "\\$&") + "$"
    }

    function use(w) {
        windows = null
        picked = w
        nameField.text = w.name
        appField.text = w.appId ? regex(w.appId) : ""
        titleField.text = w.title ? regex(w.title) : ""
        matchTitle.checked = !w.appId
        fillPixels()
        view.say(`Picked ${w.name}`)
    }

    function fillPixels() {
        if (picked && kind && kind.control === "size" && picked.size.length === 2)
            pixels.text = String(picked.size[kind.prop === "default-column-width" ? 0 : 1])
    }

    function setKind(i) {
        kindIndex = i
        choiceIndex = 0
        placeIndex = 0
        fillPixels()
    }

    //--- The value the form sets, or undefined (and a toast) when it isn't valid
    function value() {
        const c = kind.control
        if (c === "on")
            return true
        if (c === "choice")
            return kind.choices[choiceIndex].value
        if (c === "size") {
            const v = wr.sizes[sizeIndex].value
            if (v !== null)
                return v
            const px = parseInt(pixels.text)
            if (!(px >= 50 && px <= 8000)) {
                view.say("Type a size from 50 to 8000 pixels")
                return undefined
            }
            return { fixed: px }
        }
        if (c === "opacity") {
            const o = parseFloat(opacityField.text)
            if (!(o >= 0.05 && o <= 1)) {
                view.say("Type an opacity from 0.05 to 1")
                return undefined
            }
            return Math.round(o * 100) / 100
        }
        if (page.places.length)
            return page.places[placeIndex]
        const typed = placeField.text.trim()
        if (!typed)
            view.say("Type the name it should open on")
        return typed || undefined
    }

    function add() {
        const app = appField.text.trim(), title = matchTitle.checked ? titleField.text.trim() : ""
        if (!app && !title) {
            view.say("Pick a window, or type an app ID or title")
            return
        }
        const v = value()
        if (v === undefined)
            return
        Backend.call("addWindowRule", { now, appId: app, title, name: nameField.text, prop: kind.prop, value: v,
                                         category: categoryField.text },
                     staged)
    }

    property var editing: null
    function edit(rule) {
        editing = rule
        view.sheet = editSheet
    }
    Component {
        id: editSheet
        RuleEditor { view: page.view; wr: page.wr; rule: page.editing; now: page.now; onSaved: reply => page.staged(reply) }
    }

    //--- Off: a shared rule keeps its change with enable = false; on drops that
    function toggle(rule, on) {
        const o = Object.assign({}, rule.change || {})
        if (on)
            delete o.enable
        else
            o.enable = false
        setChange(rule.id, o)
    }

    //--- Back to the config's rule, or your own rule removed
    function reset(rule) {
        if (rule.custom)
            view.ask({ heading: `Remove ${rule.title}?`, body: "Your rule comes out on Apply.",
                       buttons: [{ label: "Remove", value: "remove", danger: true }] },
                     () => setChange(rule.id, null))
        else
            setChange(rule.id, null)
    }

    //--------------------------------------------------------------------//
    //-- Search and order
    //--------------------------------------------------------------------//
    property string query: ""
    // category, group (by kind), az (by name) or file (as niri reads them); until
    // one is picked, by category once any rule has one
    property string pickedOrder: ""
    readonly property string order: pickedOrder || (wr && wr.categories.length ? "category" : "group")

    function found(r) {
        const q = query.trim().toLowerCase()
        if (!q)
            return true
        const windows = r.matches.concat(r.excludes).map(m => `${m.name} ${m.pattern}`)
        return [r.title, r.note, r.category].concat(r.tags.map(t => t.text), windows).join("\n").toLowerCase().includes(q)
    }

    readonly property var shownGroups: {
        if (!wr)
            return []
        if (order === "group")
            return wr.groups.map(g => Object.assign({}, g, { rules: g.rules.filter(found) }))
                .filter(g => g.rules.length)
        const all = wr.groups.reduce((acc, g) => acc.concat(g.rules), []).filter(found)
        if (order === "category") {
            all.sort((a, b) => a.index - b.index)
            return wr.categories.concat([""]).map(c => ({
                title: c || "No Category", description: "", icon: "folder", kind: "accent",
                rules: all.filter(r => r.category === c)
            })).filter(g => g.rules.length)
        }
        all.sort(order === "az" ? (a, b) => a.title.toLowerCase().localeCompare(b.title.toLowerCase())
                                : (a, b) => a.index - b.index)
        return all.length ? [{ title: order === "az" ? "By Name" : "In File Order",
                               description: order === "file" ? "Top to bottom, as niri reads them; your own rules come last." : "",
                               icon: "view-continuous", kind: "accent", rules: all }] : []
    }
    readonly property var shownNix: wr ? wr.fromNix.filter(found) : []

    //--- A change's reply: the new windowRules setting, staged until Apply
    function staged(reply) {
        if (!reply.ok) {
            view.say(`Couldn't change the rules: ${reply.error}`)
            return
        }
        view.change(setting, reply.data.value)
        view.say(`${reply.data.text}; it waits for Apply`)
    }

    function rebuild() {
        view.ask({
            heading: "Rebuild now?",
            body: "Rebuilds from your settings files as they are (nixos-rebuild switch), which gives niri "
                  + "the window rules saved here.",
            buttons: [{ label: "Preview", value: "build", quiet: true },
                      { label: "At Next Restart", value: "boot", quiet: true },
                      { label: "Rebuild Now", value: "switch" }]
        }, mode => view.startJob("rebuild", { mode }))
    }

    //--------------------------------------------------------------------//
    //-- Hero
    //--------------------------------------------------------------------//
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: hero.implicitHeight + 28
        radius: 16
        color: Theme.card
        ColumnLayout {
            id: hero
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12
            RowLayout {
                spacing: 14
                Layout.fillWidth: true
                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true
                    Text {
                        text: !page.niri
                            ? `These rules are niri's, and this computer runs ${page.view.info && page.view.info.wm || "another"} window manager.`
                            : "Pick a window and choose what niri should do with it, or change or turn off "
                              + "the config's rules. Changes are yours alone and wait for Apply, like any "
                              + "other setting."
                        color: Theme.dim
                        font.pixelSize: 13
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
            }
            Flow {
                visible: page.editable
                Layout.fillWidth: true
                spacing: 8
                Pill { text: page.picking ? "Click a Window…" : "Pick a Window"; enabled: !page.picking; onClicked: page.pick() }
                Pill { text: page.windows ? "Hide Open Windows" : "Open Windows"; quiet: true; onClicked: page.listWindows() }
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

    //--- The windows open now; a click fills the form
    Section { visible: !!page.windows; text: "Open Windows" }
    Text {
        visible: !!page.windows && page.windows.length === 0
        text: "Loading…"
        color: Theme.dim
        Layout.leftMargin: 6
    }
    Repeater {
        model: page.windows || []
        ListRow {
            required property var modelData
            compact: true
            icon: "view_quilt"
            app: modelData.appId ? [modelData.appId, modelData.appId.toLowerCase()] : []
            title: modelData.title || modelData.name || "Untitled"
            subtitle: modelData.appId || "no app ID"
            onClicked: page.use(modelData)
        }
    }

    //--------------------------------------------------------------------//
    //-- New rule
    //--------------------------------------------------------------------//
    Section { visible: page.editable; text: "New Rule" }
    Rectangle {
        visible: page.editable
        Layout.fillWidth: true
        implicitHeight: form.implicitHeight + 28
        radius: 16
        color: Theme.card
        ColumnLayout {
            id: form
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8
            Text {
                text: "Filled in from the window you pick; the app ID and title are regular expressions."
                color: Theme.dim
                font.pixelSize: 13
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
            Label { text: "Name" }
            Field { id: nameField; placeholder: "What the list calls it" }
            Label { text: "Category" }
            CategoryPicker { id: categoryField; options: page.wr ? page.wr.categories : [] }
            Label { text: "App ID" }
            Field { id: appField; placeholder: "^org\\.example\\.App$" }
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 12
                ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true
                    Text { text: "Match the Title Too"; color: Theme.text; font.pixelSize: 15 }
                    Text {
                        text: page.picked ? (page.picked.title || "This window has no title")
                                          : "For one window of an app, like a dialog or popout"
                        color: Theme.dim
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
                Toggle { id: matchTitle; onToggled: on => checked = on }
            }
            Field { id: titleField; visible: matchTitle.checked; placeholder: "^Title$" }

            Label { text: "Rule"; Layout.topMargin: 4 }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: page.wr ? page.wr.kinds : []
                    Chip {
                        required property var modelData
                        required property int index
                        text: modelData.title
                        accent: index === page.kindIndex
                        onTapped: page.setKind(index)
                    }
                }
            }

            //--- The value, by the rule's control
            Label { visible: !!page.kind && page.kind.control !== "on"; text: "Value"; Layout.topMargin: 4 }
            Flow {
                visible: !!page.kind && ["choice", "size"].includes(page.kind.control) || page.places.length > 0
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: !page.kind ? [] : page.kind.control === "choice" ? page.kind.choices.map(c => c.label)
                         : page.kind.control === "size" ? page.wr.sizes.map(s => s.label) : page.places
                    Chip {
                        required property var modelData
                        required property int index
                        text: modelData
                        accent: index === (page.kind.control === "choice" ? page.choiceIndex
                                         : page.kind.control === "size" ? page.sizeIndex : page.placeIndex)
                        onTapped: {
                            if (page.kind.control === "choice")
                                page.choiceIndex = index
                            else if (page.kind.control === "size")
                                page.sizeIndex = index
                            else
                                page.placeIndex = index
                        }
                    }
                }
            }
            Field {
                id: pixels
                visible: !!page.kind && page.kind.control === "size" && page.wr.sizes[page.sizeIndex].value === null
                text: "800"
                placeholder: page.kind && page.kind.prop === "default-column-width" ? "Width in pixels" : "Height in pixels"
            }
            Field {
                id: opacityField
                visible: !!page.kind && page.kind.control === "opacity"
                text: "0.9"
                placeholder: "0.05 to 1"
            }
            Field {
                id: placeField
                visible: !!page.kind && ["workspace", "output"].includes(page.kind.control) && page.places.length === 0
                placeholder: page.kind && page.kind.control === "workspace" ? "Workspace name" : "Monitor name"
            }
            Pill { text: "Add Rule"; Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 6; onClicked: page.add() }
        }
    }

    ListRow {
        visible: !!page.wr && page.wr.waiting
        Layout.topMargin: 6
        icon: "sync"
        tone: "caution"
        title: "Not Applied Yet"
        subtitle: "Saved window rule changes reach niri with the next rebuild."
        button: page.view.info && page.view.info.canApply && page.view.info.admin ? "Rebuild" : ""
        onClicked: if (button) page.rebuild()
    }

    //--------------------------------------------------------------------//
    //-- The rules
    //--------------------------------------------------------------------//
    RowLayout {
        visible: !!page.wr
        Layout.fillWidth: true
        Section { text: "Rules" }
        Item { Layout.fillWidth: true }
        Chip {
            Layout.topMargin: 10
            text: "Show App IDs"
            icon: page.showIds ? "check" : ""
            accent: page.showIds
            onTapped: page.showIds = !page.showIds
        }
    }
    Text {
        visible: !!page.wr
        text: "Later rules win where two set the same thing."
        color: Theme.dim
        font.pixelSize: 13
        Layout.leftMargin: 6
    }
    Field {
        visible: !!page.wr
        icon: "search"
        placeholder: "Search rules, tags and app IDs"
        onTextChanged: page.query = text
        onEscaped: text = ""
    }
    Flow {
        visible: !!page.wr
        Layout.fillWidth: true
        Layout.leftMargin: 4
        spacing: 6
        Repeater {
            model: [{ id: "category", label: "By Category" }, { id: "group", label: "By Kind" },
                    { id: "az", label: "A to Z" }, { id: "file", label: "File Order" }]
            Chip {
                required property var modelData
                text: modelData.label
                accent: page.order === modelData.id
                onTapped: page.pickedOrder = modelData.id
            }
        }
    }
    Text {
        visible: !!page.wr && page.shownGroups.length === 0 && page.shownNix.length === 0
        text: "No rules match."
        color: Theme.dim
        font.pixelSize: 13
        Layout.leftMargin: 6
        Layout.topMargin: 6
    }

    Repeater {
        model: page.shownGroups
        RuleGroup {
            required property var modelData
            title: modelData.title
            description: modelData.description
            icon: modelData.icon
            tone: page.tone(modelData.kind)
            rules: modelData.rules
        }
    }
    RuleGroup {
        visible: page.shownNix.length > 0
        title: "Set in Nix"
        description: "Theme styling, the translucent app list and this computer's own rules. These are "
                     + "edited in the config's Nix files, not here."
        icon: "applications-system"
        rules: page.shownNix
    }

    component Label: Text {
        color: Theme.dim
        font.pixelSize: 13
        font.weight: Font.DemiBold
        Layout.leftMargin: 4
    }

    //--- A group heading with its count, then its rules
    component RuleGroup: ColumnLayout {
        id: group
        property string title
        property string description
        property string icon
        property string tone: ""
        property var rules: []
        Layout.fillWidth: true
        spacing: 6
        RowLayout {
            Layout.topMargin: 10
            Layout.leftMargin: 6
            spacing: 8
            Icon { icon: Theme.glyph(group.icon, "settings"); size: 18; color: Theme.primary }
            Text { text: group.title; color: Theme.primary; font.pixelSize: 15; font.weight: Font.DemiBold }
            Chip { tappable: false; text: String(group.rules.length); tone: group.tone; accent: group.tone === "" && group.title !== "Set in Nix" }
        }
        Text {
            visible: text !== ""
            text: group.description
            color: Theme.dim
            font.pixelSize: 13
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.bottomMargin: 2
        }
        Repeater {
            model: group.rules
            RuleRow { required property var modelData; rule: modelData }
        }
    }

    //--- One rule: name, tags coloured by group, and the windows it matches when opened
    component RuleRow: Rectangle {
        id: row
        property var rule
        property bool open: false
        readonly property int count: rule.matches.length
        Layout.fillWidth: true
        implicitHeight: ruleCol.implicitHeight + 22
        radius: 14
        color: hover.hovered ? Theme.hover : Theme.card
        opacity: rule.off ? 0.6 : 1
        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: row.open = !row.open }
        ColumnLayout {
            id: ruleCol
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 10
            anchors.rightMargin: 8
            spacing: 6
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Badge { icon: "view_quilt"; app: row.rule.app ? [row.rule.app, row.rule.app.toLowerCase()] : [] }
                ColumnLayout {
                    spacing: 4
                    Layout.fillWidth: true
                    Text {
                        text: row.rule.title
                        color: Theme.text
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 4
                        Repeater {
                            model: row.rule.tags
                            Chip {
                                tappable: false
                                required property var modelData
                                text: modelData.text
                                tone: page.tone(modelData.kind)
                                accent: modelData.kind === "accent"
                            }
                        }
                        Chip { tappable: false; visible: row.rule.custom; text: "Yours" }
                        Chip {
                            tappable: false
                            visible: row.rule.changed && !row.rule.custom
                            text: "Changed"
                            tone: "caution"
                        }
                        Chip { tappable: false; visible: row.rule.pending; text: "Not saved"; tone: "caution" }
                    }
                }
                Text {
                    visible: row.count !== 1
                    text: row.count ? `${row.count} windows` : "all windows"
                    color: Theme.dim
                    font.pixelSize: 13
                }
                IconButton {
                    visible: page.editable && row.rule.id !== null
                    icon: "edit"
                    onClicked: page.edit(row.rule)
                }
                IconButton {
                    visible: page.editable && row.rule.changed
                    icon: row.rule.custom ? "delete" : "undo"
                    onClicked: page.reset(row.rule)
                }
                Toggle {
                    visible: page.editable && row.rule.id !== null
                    checked: !row.rule.off
                    onToggled: on => page.toggle(row.rule, on)
                }
                Icon { icon: row.open ? "expand_less" : "expand_more"; size: 18 }
            }
            Text {
                visible: row.open && row.rule.note !== ""
                text: row.rule.note
                color: Theme.dim
                font.pixelSize: 13
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                Layout.leftMargin: 50
            }
            Repeater {
                model: row.open ? row.rule.matches.map(m => Object.assign({ out: false }, m))
                                  .concat(row.rule.excludes.map(m => Object.assign({ out: true }, m))) : []
                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.leftMargin: 50
                    spacing: 10
                    Badge {
                        implicitWidth: 24
                        implicitHeight: 24
                        radius: 12
                        icon: "view_quilt"
                        app: modelData.app ? [modelData.app, modelData.app.toLowerCase()] : []
                    }
                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true
                        Text {
                            text: modelData.name
                            color: Theme.text
                            font.pixelSize: 15
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            visible: page.showIds
                            text: modelData.pattern
                            color: Theme.dim
                            font.family: "monospace"
                            font.pixelSize: 13
                            wrapMode: Text.WrapAnywhere
                            Layout.fillWidth: true
                        }
                    }
                    Chip { tappable: false; visible: modelData.out; text: "Left out"; tone: "caution" }
                }
            }
        }
    }
}
