// The People page: who can log in, and for admins adding someone (api.py's
// `people` and `checkPerson`, then the job service's `person` job)
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var view
    property var people: null
    property string error: ""
    property string problem: ""
    property bool existing: false  // users/<name>/ is set up already, from another computer
    property bool admin: false
    readonly property bool allowed: view.info.direct && view.info.canApply
    readonly property string name: nameField.text.trim()
    readonly property bool mismatch: !!passField.text && !!againField.text && passField.text !== againField.text
    readonly property bool addable: name !== "" && problem === "" && !mismatch && !!passField.text
                                    && passField.text === againField.text
    spacing: 6

    function load() {
        Backend.call("people", {}, reply => {
            if (reply.ok) {
                people = reply.data
                error = ""
            } else {
                error = reply.error
            }
        })
    }

    Component.onCompleted: load()

    //--- Checks the name once typing pauses; a reply for an older name is dropped
    Timer {
        id: checkTimer
        interval: 250
        onTriggered: {
            const asked = page.name
            if (!asked) {
                page.problem = ""
                page.existing = false
                return
            }
            Backend.call("checkPerson", { name: asked }, reply => {
                if (asked !== page.name)
                    return
                page.problem = reply.ok ? reply.data.problem : reply.error
                page.existing = reply.ok && reply.data.existing
            })
        }
    }

    function add() {
        if (view.pendingCount) {
            view.say("Apply or discard your changes first")
            return
        }
        if (Jobs.running) {
            view.say("Another job is running; wait for it to finish")
            return
        }
        const args = existing ? { name, password: passField.text }
            : { name, password: passField.text, admin, gitName: gitNameField.text, gitEmail: gitEmailField.text }
        view.startJob("person", args)
        passField.text = againField.text = ""
    }

    //--- Hero
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: hero.implicitHeight + 28
        radius: 16
        color: Theme.card
        RowLayout {
            id: hero
            anchors.fill: parent
            anchors.margins: 14
            spacing: 14
            Badge { implicitWidth: 56; implicitHeight: 56; radius: 28; icon: "group" }
            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                Text { text: "People"; color: Theme.text; font.pixelSize: 20; font.weight: Font.Bold }
                Text {
                    text: "Who can log in to this computer. Each person picks their own apps by opening "
                          + "Omni Settings on their own account."
                    color: Theme.dim
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
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

    //--- Who's here
    Section { visible: !!page.people; text: "On This Computer" }
    Repeater {
        model: page.people || []
        Rectangle {
            id: personRow
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: personLayout.implicitHeight + 22
            radius: 14
            color: Theme.card
            RowLayout {
                id: personLayout
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 10
                anchors.rightMargin: 12
                spacing: 10
                Badge { icon: "person" }
                ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true
                    Text {
                        text: personRow.modelData.name
                        color: Theme.text
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: `users/${personRow.modelData.name}/settings.nix`
                        color: Theme.dim
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
                Chip { visible: personRow.modelData.you; accent: true; text: "You" }
                Chip { visible: personRow.modelData.owner; text: "Owns the config" }
                Chip { visible: personRow.modelData.admin; text: "Admin" }
            }
        }
    }

    //--- Add a person
    Section { text: "Add a Person" }
    Text {
        text: page.allowed ? "Makes their settings file from the template, lets them log in here, and rebuilds. "
                             + "They can change their apps afterwards from their own account."
                           : "Only an admin can add people."
        color: Theme.dim
        font.pixelSize: 12
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        Layout.leftMargin: 6
    }
    Rectangle {
        visible: page.allowed
        Layout.fillWidth: true
        implicitHeight: form.implicitHeight + 24
        radius: 14
        color: Theme.card
        ColumnLayout {
            id: form
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 8
            Field {
                id: nameField
                placeholder: "Login name"
                icon: "person"
                border.width: input.activeFocus || page.problem !== "" ? 2 : 0
                border.color: page.problem !== "" ? Theme.error : Theme.primary
                onTextChanged: checkTimer.restart()
            }
            RowLayout {
                Layout.fillWidth: true
                opacity: page.existing ? 0.45 : 1
                spacing: 10
                ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true
                    Text { text: "Admin"; color: Theme.text; font.pixelSize: 14; font.weight: Font.DemiBold }
                    Text {
                        text: "Can use sudo, rebuild and change this computer's settings"
                        color: Theme.dim
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
                Toggle {
                    enabled: !page.existing
                    checked: page.admin
                    onToggled: on => page.admin = on
                }
            }
            Field {
                id: gitNameField
                enabled: !page.existing
                opacity: enabled ? 1 : 0.45
                placeholder: "Name on git commits (optional)"
            }
            Field {
                id: gitEmailField
                enabled: !page.existing
                opacity: enabled ? 1 : 0.45
                placeholder: "Email on git commits (optional)"
            }
            Field {
                id: passField
                placeholder: "Password"
                icon: "key"
                input.echoMode: TextInput.Password
            }
            Field {
                id: againField
                placeholder: "Password again"
                icon: "key"
                input.echoMode: TextInput.Password
                onAccepted: if (page.addable) page.add()
            }
            Text {
                readonly property string message: page.problem !== "" ? page.problem
                    : page.mismatch ? "The passwords don't match."
                    : page.existing ? `users/${page.name}/ is already set up, from another computer. Adding them `
                                      + "here uses it as it is." : ""
                visible: message !== ""
                text: message
                color: page.problem !== "" || page.mismatch ? Theme.error : Theme.dim
                font.pixelSize: 12
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
            Pill {
                Layout.alignment: Qt.AlignRight
                enabled: page.addable
                text: "Add and Rebuild"
                onClicked: page.add()
            }
        }
    }
}
