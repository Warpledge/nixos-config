// Right Now, under Mullvad on the VPN page: the tunnel's state and the relay
// it goes through (api.py's mullvadStatus, from `mullvad status --json`)
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: vpn
    property var status: null  // {state, relay, location, entry, entryLocation, features}, null without mullvad
    property bool loaded: false
    property string error: ""
    spacing: 6
    visible: !loaded || !!status || error !== ""

    Component.onCompleted: load()
    function load() {
        Backend.call("mullvadStatus", {}, reply => {
            if (!vpn)
                return
            loaded = true
            status = reply.ok ? reply.data : null
            error = reply.ok ? "" : reply.error
        })
    }

    readonly property var look: ({ connected: ["Connected", "success"], connecting: ["Connecting", "caution"],
                                   disconnecting: ["Disconnecting", "caution"], error: ["Blocked", "error"],
                                   disconnected: ["Disconnected", "caution"] })

    RowLayout {
        Layout.fillWidth: true
        Section {
            text: "Right Now"
            info: "The tunnel as Mullvad reports it. Pick a relay in the Mullvad app; the config "
                  + "leaves that choice to you."
            Layout.fillWidth: true
        }
        IconButton { icon: "refresh"; tip: "Check again"; Layout.topMargin: 10; onClicked: vpn.load() }
    }
    ListRow {
        icon: "vpn_lock"
        title: "Tunnel"
        tone: vpn.status ? (vpn.look[vpn.status.state] || ["", ""])[1] : ""
        value: vpn.status ? (vpn.look[vpn.status.state] || [vpn.status.state])[0] : ""
        alert: vpn.error
    }
    ListRow {
        visible: !!vpn.status && vpn.status.relay !== ""
        icon: "public"
        title: "Exit Relay"
        value: vpn.status ? vpn.status.relay : ""
        subtitle: vpn.status ? vpn.status.location : ""
    }
    ListRow {
        visible: !!vpn.status && vpn.status.entry !== ""
        icon: "alt_route"
        title: "Entry Relay"
        info: "Multihop: traffic enters Mullvad here and leaves through the exit relay."
        value: vpn.status ? vpn.status.entry : ""
        subtitle: vpn.status ? vpn.status.entryLocation : ""
    }
}
