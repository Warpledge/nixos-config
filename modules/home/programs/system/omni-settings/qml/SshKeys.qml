// Your Keys, under Authorized Keys on the SSH page: the public keys in ~/.ssh
// (api.py's sshKeys), copied, added to GitHub through gh (sshGithub), or made
// with ssh-keygen in a terminal so it asks for the passphrase there (sshGenerate)
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: keys
    required property var view
    property var found: null  // [{file, type, bits, fingerprint, comment, key}]
    property string error: ""
    property string adding: ""  // the key being sent to GitHub
    spacing: 6

    Component.onCompleted: load()
    function load() {
        Backend.call("sshKeys", {}, reply => {
            if (!keys)
                return
            found = reply.ok ? reply.data : []
            error = reply.ok ? "" : reply.error
        })
    }

    function toGithub(key) {
        view.ask({ heading: `Add ${key.file} to GitHub?`,
                   body: "Adds the public key to the account gh is signed in to, so it can push and "
                         + "pull over SSH. Remove it on GitHub under Settings, SSH and GPG keys.",
                   buttons: [{ label: "Add", value: true }] }, () => {
            adding = key.file
            Backend.call("sshGithub", { file: key.file }, reply => {
                if (!keys)
                    return
                adding = ""
                view.say(reply.ok ? `${key.file} added to GitHub` : reply.error)
            })
        })
    }

    RowLayout {
        Layout.fillWidth: true
        Section {
            text: "Your Keys"
            info: "Public keys in ~/.ssh, which prove it's you when this computer logs in elsewhere. "
                  + "The private halves never leave this computer."
            Layout.fillWidth: true
        }
        IconButton { icon: "refresh"; tip: "Check again"; Layout.topMargin: 10; onClicked: keys.load() }
        IconButton {
            icon: "add"
            tip: "Make a new key in a terminal, which asks for its passphrase"
            Layout.topMargin: 10
            onClicked: Backend.call("sshGenerate", {}, reply => {
                if (keys)
                    keys.view.say(reply.ok ? "Finish in the terminal, then check again" : reply.error)
            })
        }
    }
    ListRow {
        visible: keys.error !== "" || (!!keys.found && !keys.found.length)
        icon: "key"
        title: keys.error ? "Couldn't read ~/.ssh" : "No keys yet"
        info: keys.error ? "" : "Make one with the + above."
        alert: keys.error
    }
    Repeater {
        model: keys.found || []
        Rectangle {
            id: keyRow
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: keyLayout.implicitHeight + 18
            radius: 14
            color: Theme.card
            RowLayout {
                id: keyLayout
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 10
                anchors.rightMargin: 12
                spacing: 10
                Badge { icon: "key" }
                ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true
                    Text {
                        text: keyRow.modelData.file
                        color: Theme.text
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Elided {
                        text: `${keyRow.modelData.type} · ${keyRow.modelData.comment} · ${keyRow.modelData.fingerprint}`
                        color: Theme.dim
                        font.pixelSize: 12
                        Layout.fillWidth: true
                    }
                }
                IconButton {
                    icon: "content_copy"
                    tip: "Copy the public key"
                    onClicked: {
                        Quickshell.clipboardText = keyRow.modelData.key
                        keys.view.say("Public key copied")
                    }
                }
                IconButton {
                    icon: keys.adding === keyRow.modelData.file ? "progress_activity" : "cloud_upload"
                    tip: "Add it to your GitHub account"
                    enabled: keys.adding === ""
                    onClicked: keys.toGithub(keyRow.modelData)
                }
            }
        }
    }
}
