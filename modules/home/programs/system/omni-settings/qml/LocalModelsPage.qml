// Local Models (AI tab): the machine's localModels setting. Its GPU profile,
// each model llama-swap can serve with how it loads here (api.py's
// localModels), and the files LM Studio downloaded that nothing lists yet.
// Models are tuned in LocalModelEditor.qml and added in LocalModelAdd.qml,
// both as pending changes like any other.
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var view
    readonly property var lm: view.info ? view.info.localModels : null
    property var info: null  // {gpu, profile, profiles, models, files, canTest}
    property string error: ""
    readonly property bool ready: !!info || error !== ""
    readonly property bool locked: !view.info || !view.info.direct
    spacing: 6

    //--- The setting with pending changes
    readonly property var profileNow: lm ? view.valueOf(lm.profile) : null
    readonly property var modelsNow: {
        const v = lm ? view.valueOf(lm.models) : null
        return v && typeof v === "object" && !Array.isArray(v) ? v : {}
    }
    function pendingValue() { return { profile: profileNow, models: modelsNow } }
    function setModel(id, entry) {
        const out = Object.assign({}, modelsNow)
        if (entry && Object.keys(entry).length)
            out[id] = entry
        else
            delete out[id]
        view.change(lm.models, out)
    }

    Component.onCompleted: load()
    onProfileNowChanged: load()
    onModelsNowChanged: load()
    function load() {
        Backend.call("localModels", { localModels: pendingValue() }, reply => {
            if (!page)
                return
            if (reply.ok) {
                page.info = reply.data
                page.error = ""
            } else
                page.error = reply.error
        })
    }

    function gb(bytes) { return (bytes / 1073741824).toFixed(1) + " GB" }
    function contextLabel(c) { return c >= 1024 ? Math.round(c / 1024) + "K" : String(c) }
    function profileName(id) {
        const p = info ? info.profiles.find(p => p.id === id) : null
        return p ? p.name : "none"
    }

    property var editing: null
    function edit(m) {
        if (!m.file) {
            view.say(`Download ${m.name} in LM Studio first`)
            return
        }
        editing = m
        view.sheet = editorSheet
    }
    Component {
        id: editorSheet
        LocalModelEditor { view: page.view; models: page; model: page.editing }
    }
    property var adding: null
    function add(f) {
        adding = f
        view.sheet = addSheet
    }
    Component {
        id: addSheet
        LocalModelAdd { view: page.view; models: page; file: page.adding }
    }

    //--- The GPU profile, a machine setting like any other
    SettingGroup {
        visible: !!page.lm
        view: page.view
        // Shared memory only matters where the GPU shares RAM
        settings: !page.lm ? [] : page.info && page.info.gpu.memory === "unified" && page.lm.gpuSharedGB
                  ? [page.lm.profile, page.lm.gpuSharedGB] : [page.lm.profile]
        locked: page.locked
        Layout.fillWidth: true
    }
    ListRow {
        visible: !!page.info
        icon: "memory"
        title: !page.info || !page.info.gpu.pci ? "No GPU memory found"
               : page.info.gpu.profile ? page.profileName(page.info.gpu.profile) : `GPU ${page.info.gpu.pci}`
        subtitle: !page.info || !page.info.gpu.vram ? ""
                  : page.info.gpu.memory === "unified"
                    ? `${page.gb(page.info.gpu.vram)} set aside, ${page.gb(page.info.gpu.gtt)} more shared from RAM`
                    : `${page.gb(page.info.gpu.vram)} VRAM, ${page.gb(page.info.gpu.others)} in use by other apps`
        info: "Other apps (the desktop, browsers, an animated wallpaper) hold VRAM too; the fit "
              + "estimates count what they use right now."
        alert: page.info && page.info.gpu.profile && page.info.gpu.profile !== page.profileNow
               ? `This looks like ${page.profileName(page.info.gpu.profile)}` : ""
        button: page.info && page.info.gpu.profile && page.info.gpu.profile !== page.profileNow
                && !page.locked ? "Use It" : ""
        onClicked: page.view.change(page.lm.profile, page.info.gpu.profile)
    }
    ListRow {
        visible: page.error !== ""
        icon: "error"
        title: "Couldn't read the models"
        alert: page.error
    }

    Section {
        visible: !!page.info
        text: "Models"
        info: "The models llama-swap can serve. Open one to change how it loads on this computer; "
              + "turn them on for apps under Local AI, Models."
    }
    Repeater {
        model: page.info ? page.info.models : []
        ListRow {
            required property var modelData
            icon: modelData.category === "code" ? "code" : "chat"
            title: modelData.name
            subtitle: (modelData.file ? modelData.file : "Not downloaded")
                      + (modelData.bytes ? ` · ${page.gb(modelData.bytes)}` : "")
            value: page.contextLabel(modelData.effective.context)
            tag: modelData.added ? "Added Here" : Object.keys(modelData.own).length ? "Tuned Here" : ""
            tone: modelData.file ? "" : "caution"
            chevron: true
            onClicked: page.edit(modelData)
        }
    }

    Section {
        visible: !!page.info && page.newFiles.length > 0
        text: "Downloaded in LM Studio"
        info: "Model files in ~/.lmstudio/models that no model lists yet. Add one to serve it "
              + "through llama-swap on this computer."
    }
    readonly property var newFiles: info ? info.files.filter(f => !f.id) : []
    Repeater {
        model: page.newFiles
        ListRow {
            required property var modelData
            icon: "download_done"
            title: modelData.file
            subtitle: `${modelData.dir} · ${page.gb(modelData.bytes)}`
            button: page.locked ? "" : "Add"
            onClicked: page.add(modelData)
        }
    }
}
