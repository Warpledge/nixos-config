// How the app looks, as its Preferences set it: ~/.config/<Config.appId>/appearance.json,
// one file per app. Theme reads these; a missing file or key keeps the default.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: prefs

    property alias motion: store.motion  // full, reduced, off
    property alias accent: store.accent  // the matugen role used as primary
    property alias cards: store.cards  // solid, translucent, outlined
    property alias graphs: store.graphs  // line, filled
    property alias corners: store.corners  // sharp, default, round
    property alias density: store.density  // compact, comfortable
    //--- Omni Server's console and tab bar
    property alias consoleSize: store.consoleSize
    property alias consoleWrap: store.consoleWrap
    property alias timestamps: store.timestamps
    property alias tabLabels: store.tabLabels  // always, selected

    //--- Puts every preference back to its default
    function reset() {
        motion = "full"
        accent = "primary"
        cards = "solid"
        graphs = "filled"
        corners = "default"
        density = "comfortable"
        consoleSize = 12
        consoleWrap = true
        timestamps = true
        tabLabels = "always"
    }

    // Not watched: a reload set off by one write can land between two quick changes and
    // undo the second. Only this app writes the file.
    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/" + Config.appId + "/appearance.json"
        printErrors: false
        // Writes only once a preference changes, until then the defaults stand. Batched:
        // a finished write puts its own copy back in the adapter, which would undo a
        // change made in the same moment (reset() makes ten)
        onAdapterUpdated: saveSoon.restart()
        JsonAdapter {
            id: store
            property string motion: "full"
            property string accent: "primary"
            property string cards: "solid"
            property string graphs: "filled"
            property string corners: "default"
            property string density: "comfortable"
            property int consoleSize: 12
            property bool consoleWrap: true
            property bool timestamps: true
            property string tabLabels: "always"
        }
    }
    Timer { id: saveSoon; interval: 250; onTriggered: file.writeAdapter() }
}
