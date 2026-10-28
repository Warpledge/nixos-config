// Startup (Main tab): environment variables and autostart programs, the user's
// env and autostart settings as pending changes like any other
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var view
    readonly property var envSetting: view.info ? view.info.env : null
    readonly property var autostartSetting: view.info ? view.info.autostart : null
    readonly property var env: items(envSetting)
    readonly property var autostart: items(autostartSetting)
    spacing: 6

    //--- A grouped setting's pending value (or the saved one) as a plain object
    function items(setting, saved) {
        const v = !setting ? null : saved ? view.scopedValue(setting) : view.valueOf(setting)
        const out = {}
        if (v && typeof v === "object" && !Array.isArray(v))
            for (const k of Object.keys(v))
                out[k] = v[k]
        return out
    }

    function put(setting, name, value) {
        if (!setting)
            return
        const out = items(setting, false)
        if (value === null)
            delete out[name]
        else
            out[name] = value
        view.change(setting, out)
    }

    function addEnv() {
        const name = envName.text.trim()
        const value = envValue.text
        if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(name)) {
            view.say("A variable name has letters, digits and _ only")
            return
        }
        if (page.env[name] !== undefined) {
            view.say(`${name} is already set; remove it first`)
            return
        }
        put(page.envSetting, name, value)
        envName.text = ""
        envValue.text = ""
    }

    function addAutostart() {
        const name = autoName.text.trim()
        const text = autoCommand.text
        if (!name || !text.trim()) {
            view.say("Give the program a name and a command")
            return
        }
        if (page.autostart[name] !== undefined) {
            view.say(`${name} is already listed; remove it first`)
            return
        }
        Backend.call("splitCommand", {text}, reply => {
            if (!reply.ok) {
                view.say(reply.error)
                return
            }
            put(page.autostartSetting, name, reply.data)
            autoName.text = ""
            autoCommand.text = ""
            view.say(`${name} starts the next time you log in`)
        })
    }

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
            Text {
                text: "Variables every program you start sees, and programs started with your desktop "
                      + "session. Both apply on the next rebuild; autostart programs run the next time "
                      + "you log in. Changing one the desktop already sets (PATH, QT_QPA_PLATFORM) can "
                      + "stop apps from starting."
                color: Theme.dim
                font.pixelSize: 13
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
        }
    }

    Text {
        text: `Saved for ${page.view.scopeTitle()}.`
        color: Theme.dim
        font.pixelSize: 13
        Layout.leftMargin: 6
    }

    //--- Environment variables
    Section { text: "Environment Variables" }
    ListRow {
        visible: Object.keys(page.env).length === 0
        icon: "terminal"
        title: "No variables of your own"
        subtitle: "Apps fall back to the session's variables until you add one here."
    }
    Repeater {
        model: Object.keys(page.env).sort((a, b) => a.localeCompare(b))
        RowLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 8
            Text {
                text: modelData
                color: Theme.text
                font.pixelSize: 15
                font.weight: Font.DemiBold
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            Text {
                text: String(page.env[modelData])
                color: Theme.dim
                font.pixelSize: 13
                Layout.fillWidth: true
                elide: Text.ElideMiddle
            }
            IconButton {
                icon: "delete"
                tip: "Remove"
                onClicked: page.put(page.envSetting, modelData, null)
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Field {
            id: envName
            placeholder: "NAME"
            Layout.preferredWidth: 180
        }
        Field {
            id: envValue
            placeholder: "Value"
            onAccepted: page.addEnv()
        }
        Pill { text: "Add"; onClicked: page.addEnv() }
    }

    //--- Autostart
    Section { text: "Autostart" }
    ListRow {
        visible: Object.keys(page.autostart).length === 0
        icon: "rocket_launch"
        title: "No programs of your own"
        subtitle: "Programs listed here start with your desktop session."
    }
    Repeater {
        model: Object.keys(page.autostart).sort((a, b) => a.localeCompare(b))
        RowLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 8
            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true
                Text {
                    text: modelData
                    color: Theme.text
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                Text {
                    text: page.autostart[modelData].join(" ")
                    color: Theme.dim
                    font.pixelSize: 13
                    Layout.fillWidth: true
                    elide: Text.ElideMiddle
                }
            }
            IconButton {
                icon: "delete"
                tip: "Remove"
                onClicked: page.put(page.autostartSetting, modelData, null)
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Field {
            id: autoName
            placeholder: "Name"
            Layout.preferredWidth: 180
        }
        Field {
            id: autoCommand
            placeholder: "Command, as you would type it in a terminal"
            onAccepted: page.addAutostart()
        }
        Pill { text: "Add"; onClicked: page.addAutostart() }
    }
}
