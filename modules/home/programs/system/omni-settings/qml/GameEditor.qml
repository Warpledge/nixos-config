// Edits one Steam game's entry in the user's steamGames setting: its Proton
// build, and its launch options built from the option groups (api.py's
// steamGames) or typed. The string is the truth: each chip reads its state
// from it and toggling one edits it.
import QtQuick
import QtQuick.Layouts

Sheet {
    id: ed
    required property var view
    required property var games  // GamesPage: steam, now, setGame
    required property var game  // {id, name, icon, steam}
    readonly property var entry: games.now[game.id] || null
    readonly property var steam: game.steam || {}
    title: game.name
    onBack: view.sheet = null

    property string launch: ""
    property string proton: ""  // "" leaves Steam's choice alone

    Component.onCompleted: {
        launch = entry && entry.launchOptions !== undefined ? entry.launchOptions : (steam.launchOptions || "")
        proton = entry && entry.proton ? entry.proton : ""
        launchField.text = launch
    }
    onLaunchChanged: if (!launchField.input.activeFocus) launchField.text = launch

    function save() {
        const out = { launchOptions: launch.trim() }
        if (proton)
            out.proton = proton
        games.setGame(game.id, out)
        view.sheet = null
    }

    //--------------------------------------------------------------------//
    //-- Reading and writing the launch string
    //--------------------------------------------------------------------//
    //--- Words, keeping quoted parts whole so the string comes back unchanged
    function words(s) {
        return s.match(/(?:[^\s"']+|"(?:\\.|[^"\\])*"|'[^']*')+/g) || []
    }
    function isVar(w) { return /^[A-Za-z_][A-Za-z0-9_]*=/.test(w) }
    function varName(w) { return w.slice(0, w.indexOf("=")) }

    //--- {vars, wrap, args, command}: what goes before %command% split into
    //--- variables and the commands wrapping the game, and its arguments after
    function split(s) {
        const w = words(s)
        const at = w.indexOf("%command%")
        if (at < 0)
            return { vars: [], wrap: [], args: w, command: false }
        const pre = w.slice(0, at)
        let n = 0
        while (n < pre.length && isVar(pre[n]))
            n++
        return { vars: pre.slice(0, n), wrap: pre.slice(n), args: w.slice(at + 1), command: true }
    }
    function join(p) {
        if (!p.vars.length && !p.wrap.length && !p.command)
            return p.args.join(" ")
        return p.vars.concat(p.wrap, ["%command%"], p.args).join(" ")
    }
    //--- An option's own parts: an option without %command% is variables or arguments
    function optionParts(o) {
        if (o.includes("%command%"))
            return split(o)
        const w = words(o)
        return w.every(isVar) ? { vars: w, wrap: [], args: [], command: false }
                              : { vars: [], wrap: [], args: w, command: false }
    }
    function find(list, seq) {
        for (let i = 0; seq.length && i + seq.length <= list.length; i++)
            if (seq.every((x, j) => list[i + j] === x))
                return i
        return -1
    }

    readonly property var parts: split(launch)
    readonly property var mains: games.steam ? [].concat(...games.steam.groups.map(g => g.options.filter(o => o.main)))
                                            : []

    function isOn(o) {
        const p = parts, q = optionParts(o.option)
        return q.vars.every(v => p.vars.includes(v)) && (!q.wrap.length || find(p.wrap, q.wrap) >= 0)
               && q.args.every(a => p.args.includes(a))
    }
    function dropWrap(p, seq) {
        const i = find(p.wrap, seq)
        if (i >= 0)
            p.wrap.splice(i, seq.length)
    }
    function toggle(o) {
        const p = split(launch), q = optionParts(o.option)
        if (isOn(o)) {
            p.vars = p.vars.filter(v => !q.vars.includes(v))
            dropWrap(p, q.wrap)
            p.args = p.args.filter(a => !q.args.includes(a))
        } else {
            for (const v of q.vars) {
                const i = p.vars.findIndex(x => varName(x) === varName(v))
                if (i >= 0) p.vars[i] = v
                else p.vars.push(v)
            }
            if (o.main) {
                // One wrapper runs the game: drop the others and nix-gamescope
                for (const m of mains)
                    dropWrap(p, optionParts(m.option).wrap)
                setGamescope(p, null)
                p.wrap = p.wrap.concat(q.wrap)
            } else if (q.wrap.length)
                p.wrap = q.wrap.concat(p.wrap)
            p.args = p.args.concat(q.args.filter(a => !p.args.includes(a)))
            if (q.wrap.length || q.vars.length)
                p.command = true
        }
        launch = join(p)
    }

    //--------------------------------------------------------------------//
    //-- nix-gamescope
    //--------------------------------------------------------------------//
    //--- [start, length, flags] of nix-gamescope in `wrap`, or null
    function gamescopeAt(wrap) {
        const i = wrap.indexOf("nix-gamescope")
        if (i < 0)
            return null
        if (i + 1 < wrap.length && wrap[i + 1].startsWith("-") && wrap[i + 1] !== "--") {
            const end = wrap.indexOf("--", i)
            if (end > 0)
                return [i, end - i + 1, wrap.slice(i + 1, end)]
        }
        return [i, wrap[i + 1] === "--" ? 2 : 1, []]
    }
    //--- {w, h, r, filter, mangoapp, grab, extra} from the flags
    readonly property var gs: {
        const at = gamescopeAt(parts.wrap)
        if (!at)
            return null
        const f = at[2], out = { w: "", h: "", r: "", filter: "", mangoapp: false, grab: false, extra: [] }
        for (let i = 0; i < f.length; i++) {
            const k = { "-w": "w", "-h": "h", "-r": "r", "-F": "filter" }[f[i]]
            if (k && i + 1 < f.length)
                out[k] = f[++i]
            else if (f[i] === "--mangoapp")
                out.mangoapp = true
            else if (f[i] === "--force-grab-cursor")
                out.grab = true
            else
                out.extra.push(f[i])
        }
        return out
    }
    //--- Puts nix-gamescope with settings `g` in place of the old one; null takes it out
    function setGamescope(p, g) {
        const at = gamescopeAt(p.wrap)
        let flags = []
        if (g) {
            if (g.w) flags.push("-w", g.w)
            if (g.h) flags.push("-h", g.h)
            if (g.r) flags.push("-r", g.r)
            if (g.filter) flags.push("-F", g.filter)
            if (g.mangoapp) flags.push("--mangoapp")
            if (g.grab) flags.push("--force-grab-cursor")
            flags = flags.concat(g.extra || [])
        }
        const seq = !g ? [] : flags.length ? ["nix-gamescope"].concat(flags, ["--"]) : ["nix-gamescope"]
        if (at)
            p.wrap.splice(at[0], at[1], ...seq)
        else if (g) {
            for (const m of mains)
                dropWrap(p, optionParts(m.option).wrap)
            p.wrap = p.wrap.concat(seq)
            p.command = true
        }
    }
    function gamescope(change) {
        const p = split(launch)
        setGamescope(p, change === null ? null : Object.assign({}, gs || { extra: [] }, change))
        launch = join(p)
    }

    //--------------------------------------------------------------------//
    //-- The Form
    //--------------------------------------------------------------------//
    actions: [
        Pill { text: "Cancel"; quiet: true; onClicked: ed.view.sheet = null },
        Pill {
            visible: !!ed.entry
            text: "Remove"
            quiet: true
            danger: true
            onClicked: { ed.games.setGame(ed.game.id, null); ed.view.sheet = null }
        },
        Pill { text: "Done"; onClicked: ed.save() }
    ]

    Text {
        text: `Saved for ${ed.view.scopeTitle()}. Steam gets it once it's closed.`
        color: Theme.dim
        font.pixelSize: 14
        Layout.leftMargin: 6
    }

    Section {
        text: "Launch Options"
        info: "Everything below edits this. Variables go before %command%, wrappers next, and the "
              + "game's own arguments after it."
    }
    Field {
        id: launchField
        placeholder: "Empty: Steam runs the game as it is"
        input.onTextEdited: ed.launch = text
    }
    Text {
        visible: !!ed.steam.launchOptions && ed.steam.launchOptions !== ed.launch
        text: `Steam has now: ${ed.steam.launchOptions || ""}`
        color: Theme.dim
        font.pixelSize: 13
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        Layout.leftMargin: 6
    }

    Section {
        text: "Proton Version"
        info: "The build Steam runs this game with. Left as Steam has it, the game keeps its own pick, "
              + "or Steam's default under Settings, Compatibility."
    }
    Flow {
        Layout.fillWidth: true
        spacing: 6
        Chip {
            text: ed.steam.proton ? `As Steam Has It (${ed.steam.proton})`
                  : `Steam's Default${ed.games.steam && ed.games.steam.default ? ` (${ed.games.steam.default})` : ""}`
            accent: ed.proton === ""
            onTapped: ed.proton = ""
        }
        Repeater {
            model: ed.games.steam ? ed.games.steam.tools : []
            Chip {
                required property var modelData
                text: modelData.title
                accent: ed.proton === modelData.name
                onTapped: ed.proton = modelData.name
            }
        }
    }

    Section {
        text: "Gamescope"
        info: "nix-gamescope runs the game fullscreen in gamescope at the monitor's resolution and "
              + "refresh rate, with nix-performance inside. Fields left empty use the monitor's."
    }
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 6
        Text {
            text: "Run in gamescope"
            color: Theme.text
            font.pixelSize: 15
            Layout.fillWidth: true
        }
        Toggle { checked: !!ed.gs; onToggled: on => ed.gamescope(on ? {} : null) }
    }
    ColumnLayout {
        visible: !!ed.gs
        Layout.fillWidth: true
        spacing: 6
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Field {
                id: gsWidth
                placeholder: "Render width"
                text: ed.gs ? ed.gs.w : ""
                input.onTextEdited: ed.gamescope({ w: text.trim() })
            }
            Field {
                placeholder: "Render height"
                text: ed.gs ? ed.gs.h : ""
                input.onTextEdited: ed.gamescope({ h: text.trim() })
            }
            Field {
                placeholder: "FPS cap"
                text: ed.gs ? ed.gs.r : ""
                input.onTextEdited: ed.gamescope({ r: text.trim() })
            }
        }
        Flow {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: [["", "No Upscaling Filter", "Gamescope's own scaling."],
                        ["fsr", "FSR 1", "AMD FidelityFX Super Resolution 1: sharpens while upscaling."],
                        ["nis", "NIS", "NVIDIA Image Scaling: sharpens while upscaling."],
                        ["pixel", "Pixel", "Whole-pixel scaling, for pixel art."],
                        ["linear", "Linear", "Plain smooth scaling."]]
                Chip {
                    required property var modelData
                    text: modelData[1]
                    tip: modelData[2]
                    accent: !!ed.gs && ed.gs.filter === modelData[0]
                    onTapped: ed.gamescope({ filter: modelData[0] })
                }
            }
            Chip {
                text: "Gamescope FPS Overlay"
                tip: "--mangoapp: gamescope's own overlay, which replaces MangoHud inside it."
                accent: !!ed.gs && ed.gs.mangoapp
                onTapped: ed.gamescope({ mangoapp: !ed.gs.mangoapp })
            }
            Chip {
                text: "Lock the Pointer"
                tip: "--force-grab-cursor: keeps the pointer inside the game, for mouse-look that escapes."
                accent: !!ed.gs && ed.gs.grab
                onTapped: ed.gamescope({ grab: !ed.gs.grab })
            }
        }
    }

    Repeater {
        model: ed.games.steam ? ed.games.steam.groups : []
        ColumnLayout {
            id: group
            required property var modelData
            Layout.fillWidth: true
            spacing: 6
            Section { text: group.modelData.title; info: group.modelData.description || "" }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: group.modelData.options
                    Chip {
                        required property var modelData
                        text: modelData.option.replace(" %command%", "").replace("%command% ", "")
                        tip: modelData.text
                        accent: ed.isOn(modelData)
                        onTapped: ed.toggle(modelData)
                    }
                }
            }
        }
    }
}
