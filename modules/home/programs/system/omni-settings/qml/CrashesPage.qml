// Crashes (Gaming tab): every crash of the user's programs in the last 30
// days, games first (CrashList.qml, src/crashstate.py)
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var view
    readonly property bool ready: crashList.ready
    spacing: 6

    Section {
        text: "Last 30 Days"
        info: "Programs that crashed, from systemd-coredump. A game's report also holds its launch "
              + "options and the end of its Proton log, when PROTON_LOG=1 made one."
    }
    CrashList { id: crashList; view: page.view; Layout.fillWidth: true }
}
