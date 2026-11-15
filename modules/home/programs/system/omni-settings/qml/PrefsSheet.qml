// Omni Settings' own look (Prefs.qml), opened from the gear under the page rail
import QtQuick
import QtQuick.Layouts

Sheet {
    id: sheet
    required property var view
    title: "Preferences"
    info: "How Omni Settings looks. Saved in ~/.config/omni-settings/appearance.json, apart from your NixOS settings."
    onBack: view.sheet = null

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: prefs.implicitHeight + Theme.pad(24)
        radius: Theme.r(14)
        color: Qt.alpha(Theme.bg, 0.55)
        border.width: 1
        border.color: Theme.rule
        AppearancePrefs {
            id: prefs
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.pad(12)
        }
    }
}
