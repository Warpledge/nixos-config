// Adds a downloaded .gguf as a model in the machine's localModels.models:
// its kind (code or chat), name and id, with llama.cpp fitting it until it's tuned.
import QtQuick
import QtQuick.Layouts

Sheet {
    id: ed
    required property var view
    required property var models  // LocalModelsPage: modelsNow, setModel, info
    required property var file  // {path, dir, file, bytes, quant, suggest}
    title: file.file
    info: `Add a model · ${view.info.machine} · waits for Apply`
    onBack: view.sheet = null

    property string category: "chat"
    property string vision: file.vision && file.vision.length ? file.vision[0] : ""  // "" for none
    readonly property string mid: idField.text.trim()
    readonly property string problem: {
        if (!/^[a-z0-9][a-z0-9.-]*$/.test(mid))
            return "The id takes lowercase letters, digits, dots and dashes"
        if (models.info && models.info.models.some(m => m.id === mid))
            return "Another model has that id"
        if (nameField.text.trim() === "")
            return "Give it a name"
        return ""
    }

    Component.onCompleted: {
        idField.text = file.suggest.id
        nameField.text = file.suggest.name
    }

    function save() {
        if (problem) {
            view.say(problem)
            return
        }
        const entry = { category, name: nameField.text.trim(), dir: file.dir, match: file.suggest.match }
        if (vision)
            entry.mmproj = vision
        models.setModel(mid, entry)
        view.say(`${nameField.text.trim()} added; turn it on under Local AI, Models after Apply`)
        view.sheet = null
    }

    Section {
        text: "Used For"
        info: "Coding models show in opencode and Zed's agent panel; chat models in Open WebUI "
              + "and llama-swap's Playground."
    }
    Flow {
        Layout.fillWidth: true
        spacing: 6
        Chip { text: "Coding"; accent: ed.category === "code"; onTapped: ed.category = "code" }
        Chip { text: "Chat"; accent: ed.category === "chat"; onTapped: ed.category = "chat" }
    }
    Section {
        visible: !!ed.file.vision && ed.file.vision.length > 0
        text: "Vision"
        info: "The folder has a vision projector (mmproj), which lets the model read images. It "
              + "loads beside the model and takes some VRAM; without it, the model reads text only."
    }
    Flow {
        visible: !!ed.file.vision && ed.file.vision.length > 0
        Layout.fillWidth: true
        spacing: 6
        Chip { text: "Text Only"; accent: ed.vision === ""; onTapped: ed.vision = "" }
        Repeater {
            model: ed.file.vision || []
            Chip {
                required property string modelData
                text: modelData
                accent: ed.vision === modelData
                onTapped: ed.vision = modelData
            }
        }
    }
    Section { text: "Name"; info: "What apps show in their model lists." }
    Field { id: nameField; Layout.fillWidth: true; placeholder: "Display name" }
    Section { text: "Id"; info: "The name apps ask llama-swap for, and the key in the settings file." }
    Field { id: idField; Layout.fillWidth: true; placeholder: "model-id" }
    Text {
        visible: ed.problem !== ""
        text: ed.problem
        color: Theme.caution
        font.pixelSize: 13
        Layout.leftMargin: 6
    }
    Text {
        text: `Folder ${ed.file.dir}, file ${ed.file.suggest.match}. llama.cpp fits it to the GPU `
              + "until you tune it, and sampling is llama.cpp's own."
        color: Theme.dim
        font.pixelSize: 13
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        Layout.leftMargin: 6
    }

    actions: [
        Pill { text: "Cancel"; quiet: true; onClicked: ed.view.sheet = null },
        Pill { text: "Add"; onClicked: ed.save() }
    ]
}
