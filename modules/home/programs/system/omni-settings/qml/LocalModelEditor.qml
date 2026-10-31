// Tunes one model for this machine: its localModels.models entry's tuning
// fields over the profile's measured values, with a fit estimate that follows
// each change (api.py's localModelEstimate), presets, and a test that runs
// llama-server with the unsaved tuning (localModelTest).
import QtQuick
import QtQuick.Layouts

Sheet {
    id: ed
    required property var view
    required property var models  // LocalModelsPage: modelsNow, profileNow, setModel
    required property var model  // a model from api.py's localModels
    title: model.name
    info: `How it loads · ${view.info.machine} · waits for Apply`
    onBack: view.sheet = null

    readonly property var tuningKeys: ["context", "cache", "gpuLayers", "cpuMoe", "batch", "cacheRam",
                                       "fitTarget", "loadMode"]
    property var own: ({})
    property var fit: null  // the estimate
    property string fitError: ""
    property var log: []
    property var result: null
    property bool testing: false
    readonly property bool unified: models.info && models.info.gpu.memory === "unified"
    readonly property bool moe: !!fit && fit.model.moe

    Component.onCompleted: {
        own = Object.assign({}, models.modelsNow[model.id] || {})
        estimate()
    }

    //--- A field's value: this machine's, else the profile's measured, else llama.cpp's default
    function value(key, fallback) {
        if (key in own)
            return own[key]
        if (own.gpuLayers === "auto" && key === "cpuMoe")
            return fallback
        return key in model.measured ? model.measured[key] : fallback
    }
    function set(key, v) {
        const o = Object.assign({}, own)
        if (v === undefined)
            delete o[key]
        else
            o[key] = v
        own = o
        result = null
        estimateTimer.restart()
    }
    function useTuning(t) {
        const o = {}
        for (const k in own)
            if (!tuningKeys.includes(k))
                o[k] = own[k]  // an added model's name, folder and file stay
        own = Object.assign(o, t || {})
        result = null
        estimateTimer.restart()
    }
    function merged() {
        const m = Object.assign({}, models.modelsNow)
        if (Object.keys(own).length)
            m[model.id] = own
        else
            delete m[model.id]
        return { profile: models.profileNow, models: m }
    }

    Timer { id: estimateTimer; interval: 250; onTriggered: ed.estimate() }
    function estimate() {
        Backend.call("localModelEstimate", { id: model.id, localModels: merged() }, reply => {
            if (!ed)
                return
            if (reply.ok) {
                ed.fit = reply.data
                ed.fitError = ""
                // The last test, while these are the settings it ran with
                if (!ed.testing)
                    ed.result = reply.data.lastTest ? reply.data.lastTest.result : null
            } else
                ed.fitError = reply.error
        })
    }
    function runTest() {
        testing = true
        log = []
        result = null
        Backend.stream("localModelTest", { id: model.id, localModels: merged() },
                       line => ed.log = ed.log.slice(-5).concat([line]), reply => {
            if (!ed)
                return
            ed.testing = false
            if (reply.ok) {
                ed.result = reply.data
                ed.estimate()  // picks up the saved test's date
            } else
                ed.view.ask({ heading: "The test didn't finish", body: reply.error, cancel: false,
                              buttons: [{ label: "OK", value: true }] }, () => {})
        })
    }
    function save() {
        models.setModel(model.id, own)
        view.sheet = null
    }

    function gb(b) { return (b / 1073741824).toFixed(1) }
    function contextLabel(c) { return c >= 1024 ? Math.round(c / 1024) + "K tokens" : `${c} tokens` }

    //--- A setting whose choices open below it, like the generated pages' rows
    component Choice: ColumnLayout {
        id: choice
        property string title
        property string tip
        property var options: []  // [{value, label}]
        property var current
        property bool open: false
        signal picked(var value)
        Layout.fillWidth: true
        spacing: 6
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 6
            spacing: 8
            Text {
                text: choice.title
                color: Theme.text
                font.pixelSize: 15
                TitleTip { tip: choice.tip }
            }
            Item { Layout.fillWidth: true }
            Text {
                readonly property var hit: choice.options.find(o => JSON.stringify(o.value) === JSON.stringify(choice.current))
                text: hit ? hit.label : String(choice.current)
                color: Theme.primary
                font.pixelSize: 14
            }
            Chevron { open: choice.open; lit: rowHover.hovered }
            HoverHandler { id: rowHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: choice.open = !choice.open }
        }
        Reveal {
            open: choice.open
            gap: choice.spacing
            Flow {
                Layout.fillWidth: true
                Layout.leftMargin: 6
                spacing: 6
                Repeater {
                    model: choice.options
                    Chip {
                        required property var modelData
                        text: modelData.label
                        tip: modelData.tip || ""
                        accent: JSON.stringify(modelData.value) === JSON.stringify(choice.current)
                        onTapped: {
                            choice.picked(modelData.value)
                            choice.open = false
                        }
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------//
    //-- Fit
    //--------------------------------------------------------------------//
    Section {
        text: "Fit"
        info: "An estimate from the model file and this GPU. Test These Settings loads it for real."
    }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 14
        radius: 7
        color: Theme.cardHover
        visible: !!ed.fit
        readonly property real total: ed.fit ? ed.fit.gpuTotal : 1
        Row {
            anchors.fill: parent
            Rectangle {
                height: parent.height
                width: ed.fit ? parent.width * Math.min(1, ed.fit.others / parent.parent.total) : 0
                color: Theme.dim
                opacity: 0.5
                radius: 7
            }
            Rectangle {
                height: parent.height
                width: ed.fit ? parent.width * Math.min(1, ed.fit.gpu / parent.parent.total) : 0
                color: ed.fit && ed.fit.status === "fits" ? Theme.primary
                       : ed.fit && ed.fit.status === "tight" ? Theme.caution : Theme.error
                radius: 7
            }
        }
    }
    Text {
        visible: !!ed.fit
        Layout.fillWidth: true
        Layout.leftMargin: 6
        wrapMode: Text.Wrap
        color: Theme.text
        font.pixelSize: 14
        text: !ed.fit ? ""
              : `About ${ed.gb(ed.fit.gpu)} GB of ${ed.gb(ed.fit.gpuTotal)} GB`
                + (ed.fit.others ? `, with ${ed.gb(ed.fit.others)} GB used by other apps` : "")
                + (ed.unified ? "" : ` · ${ed.gb(ed.fit.ram)} GB in RAM`)
                + (ed.fit.status === "fits" ? " · Fits"
                   : ed.fit.status === "tight" ? " · Fits, with little room left" : " · Too big")
    }
    Text {
        visible: !!ed.fit && ed.fit.auto
        Layout.fillWidth: true
        Layout.leftMargin: 6
        wrapMode: Text.Wrap
        color: Theme.dim
        font.pixelSize: 13
        text: !ed.fit || !ed.fit.auto ? ""
              : "llama.cpp picks the split when it loads: "
                + (ed.fit.picked.cpuMoe !== undefined
                   ? (ed.fit.picked.cpuMoe ? `about ${ed.fit.picked.cpuMoe} layers' experts in RAM` : "everything on the GPU")
                   : ed.fit.picked.gpuLayers === "all" ? "everything on the GPU"
                   : `about ${ed.fit.picked.gpuLayers} layers on the GPU`)
    }
    Text {
        visible: !!ed.fit && ed.fit.status !== "fits" && ed.fit.others > 1073741824 && !ed.unified
        Layout.fillWidth: true
        Layout.leftMargin: 6
        wrapMode: Text.Wrap
        color: Theme.caution
        font.pixelSize: 13
        text: "Closing apps that use the GPU (browsers, an animated wallpaper) frees room for the model."
    }
    Text {
        visible: !!ed.fit && ed.fit.ramOver
        Layout.fillWidth: true
        Layout.leftMargin: 6
        wrapMode: Text.Wrap
        color: Theme.caution
        font.pixelSize: 13
        text: "This needs most of the computer's RAM; lower the prompt cache or the experts in RAM."
    }
    Text {
        visible: ed.fitError !== ""
        Layout.fillWidth: true
        text: ed.fitError
        color: Theme.caution
        wrapMode: Text.Wrap
    }

    //--- Presets: Measured puts back the profile's tested values
    Flow {
        Layout.fillWidth: true
        spacing: 6
        visible: !!ed.fit
        Repeater {
            model: ed.fit ? ed.fit.presets : []
            Chip {
                required property var modelData
                text: modelData.title
                tip: ({ measured: "The values tested on this GPU profile.",
                        speed: "Keeps the context and puts as much on the GPU as fits: fastest replies.",
                        context: "The longest context that still fits, moving more to RAM: slower.",
                        auto: "Leaves the split to llama.cpp, which fits the model when it loads." })[modelData.id] || ""
                onTapped: ed.useTuning(modelData.tuning)
            }
        }
    }

    //--------------------------------------------------------------------//
    //-- Tuning
    //--------------------------------------------------------------------//
    Section { text: "Tuning"; info: "Each value shows what loads now; hover a name for what it does." }
    Choice {
        title: "Context"
        tip: "How much text the model holds at once: your prompt, files and its reply. More context "
             + "takes more memory for its cache."
        current: ed.value("context", ed.model.context)
        options: {
            const top = ed.fit ? ed.fit.model.trainedContext || 32768 : ed.model.context
            const out = []
            for (let c = 4096; c < top; c *= 2)
                out.push({ value: c, label: ed.contextLabel(c) })
            out.push({ value: top, label: ed.contextLabel(top) + " (most it knows)" })
            return out
        }
        onPicked: v => ed.set("context", v)
    }
    Choice {
        title: "Context Cache"
        tip: "How precisely the context is kept. Half size barely changes answers and doubles the "
             + "context that fits; quarter size can hurt long answers."
        current: ed.value("cache", ed.model.cache)
        options: [{ value: "f16", label: "Full (f16)" }, { value: "q8_0", label: "Half Size (q8_0)" },
                  { value: "q4_0", label: "Quarter Size (q4_0)" }]
        onPicked: v => ed.set("cache", v)
    }
    Choice {
        title: "Layers on the GPU"
        tip: "Auto lets llama.cpp decide when it loads. All is fastest when it fits; fewer layers "
             + "move the rest to the CPU, which is much slower."
        current: ed.value("gpuLayers", "auto")
        options: {
            const out = [{ value: "auto", label: "Auto" }, { value: "all", label: "All" }]
            if (ed.fit && !ed.moe)
                for (let n = ed.fit.model.layers - 4; n > 0; n -= 4)
                    out.push({ value: n, label: String(n) })
            const n = ed.value("gpuLayers", "auto")
            // -ngl 99, as the catalog writes it, is every layer
            if (typeof n === "number" && !out.some(o => o.value === n))
                out.push({ value: n, label: ed.fit && n >= ed.fit.model.layers ? `All (${n})` : String(n) })
            return out
        }
        onPicked: v => ed.set("gpuLayers", v)
    }
    RowLayout {
        visible: ed.moe && !ed.unified && ed.value("gpuLayers", "auto") !== "auto"
        Layout.fillWidth: true
        Layout.leftMargin: 6
        spacing: 8
        Text {
            text: "Experts in RAM"
            color: Theme.text
            font.pixelSize: 15
            TitleTip {
                tip: "This model is a mixture of experts: each layer's experts can sit in RAM while the "
                     + "rest stays on the GPU. More in RAM frees VRAM for context but replies slower."
            }
        }
        Item { Layout.fillWidth: true }
        IconButton {
            icon: "remove"
            tip: "One fewer layer's experts in RAM"
            onClicked: ed.set("cpuMoe", Math.max(0, ed.value("cpuMoe", 0) - 1))
        }
        Text {
            text: `${ed.value("cpuMoe", 0)} of ${ed.fit ? ed.fit.model.layers : "?"} layers`
            color: Theme.primary
            font.pixelSize: 14
        }
        IconButton {
            icon: "add"
            tip: "One more layer's experts in RAM"
            onClicked: ed.set("cpuMoe", Math.min(ed.fit ? ed.fit.model.layers : 99, ed.value("cpuMoe", 0) + 1))
        }
    }
    Choice {
        title: "Prompt Batch"
        tip: "How many tokens of a prompt it reads per step. Bigger reads long prompts and files "
             + "faster but needs more VRAM."
        current: ed.value("batch", 512)
        options: [256, 512, 1024, 2048, 4096].map(n => ({ value: n, label: String(n) }))
        onPicked: v => ed.set("batch", v)
    }
    Choice {
        title: "Prompt Cache in RAM"
        tip: "Earlier conversations kept in RAM, so going back to one doesn't reread it. Lower it "
             + "when RAM runs short."
        current: ed.value("cacheRam", 8192)
        options: [{ value: 0, label: "Off" }, { value: 2048, label: "2 GB" }, { value: 4096, label: "4 GB" },
                  { value: 8192, label: "8 GB" }, { value: 16384, label: "16 GB" }]
        onPicked: v => ed.set("cacheRam", v)
    }

    //--------------------------------------------------------------------//
    //-- Test
    //--------------------------------------------------------------------//
    Section {
        text: "Test"
        info: "Loads the model with these settings, sends a short prompt and measures it. It unloads "
              + "llama-swap's model first; llama-swap loads it again the next time an app asks."
    }
    ListRow {
        visible: ed.models.info && ed.models.info.canTest
        icon: ed.testing ? "progress_activity" : "speed"
        title: ed.testing ? "Testing…" : ed.result ? `${ed.result.tokensPerSecond} tokens a second`
                                                    + (ed.fit && ed.fit.lastTest ? ` · tested ${ed.fit.lastTest.at}` : "")
                                                  : "Test These Settings"
        subtitle: ed.testing ? (ed.log.length ? ed.log[ed.log.length - 1] : "Loading the model")
                  : ed.result ? `Reads prompts at ${ed.result.promptPerSecond} tokens a second · VRAM peak `
                                + `${ed.gb(ed.result.vramPeak)} of ${ed.gb(ed.result.vramTotal)} GB · `
                                + `${ed.gb(ed.result.ramUsed)} GB more RAM`
                  : "Loading takes up to a minute"
        tone: ed.result && ed.result.vramPeak > ed.result.vramTotal * 0.97 ? "caution" : ""
        button: ed.testing ? "" : ed.result ? "Again" : "Test"
        onClicked: ed.runTest()
    }

    actions: [
        Pill { text: "Cancel"; quiet: true; onClicked: ed.view.sheet = null },
        Pill { text: "Save"; onClicked: ed.save() }
    ]
}
