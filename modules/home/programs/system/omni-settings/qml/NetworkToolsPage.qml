// Tools (Network tab): a connection check and speed test streamed from the backend
// (api.py's netTest, as `nixm ping` and `nixm speedtest` run them), and how DNS is
// resolved now (dnsStatus)
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var view
    property var dns: null  // {tls, server, servers}
    property string dnsError: ""
    readonly property bool ready: !!dns || dnsError !== ""
    spacing: 6

    Component.onCompleted: loadDns()
    function loadDns() {
        Backend.call("dnsStatus", {}, reply => {
            if (!page)
                return
            if (reply.ok)
                dns = reply.data
            else
                dnsError = reply.error
        })
    }

    Section {
        text: "Checks"
        info: "Each runs from this computer, through the VPN when Mullvad is on."
    }
    TestRow {
        kind: "ping"
        icon: "network_ping"
        title: "Connection Check"
        info: "Sends 5 pings to 8.8.8.8 and times the answers."
        summarise: lines => {
            const loss = lines.map(l => l.match(/(\d+(?:\.\d+)?)% packet loss/)).find(m => m)
            const rtt = lines.map(l => l.match(/= [\d.]+\/([\d.]+)\//)).find(m => m)
            return rtt ? `${Math.round(Number(rtt[1]))} ms` + (loss && loss[1] !== "0" ? `, ${loss[1]}% lost` : "")
                       : loss ? `${loss[1]}% lost` : ""
        }
    }
    TestRow {
        kind: "speedtest"
        icon: "speed"
        title: "Speed Test"
        info: "Downloads and uploads test data from the nearest speedtest.net server. Takes about "
              + "half a minute."
        summarise: lines => {
            const get = name => {
                const m = lines.map(l => l.match(new RegExp(`^${name}: ([\\d.]+)`))).find(m => m)
                return m ? Math.round(Number(m[1])) : null
            }
            const down = get("Download"), up = get("Upload")
            return down === null ? "" : `${down} down, ${up} up Mbit/s`
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Section {
            text: "DNS"
            info: "How this computer looks up site names. systemd-resolved encrypts lookups with "
                  + "DNS over TLS when the server supports it."
            Layout.fillWidth: true
        }
        IconButton { icon: "refresh"; tip: "Check again"; Layout.topMargin: 10; onClicked: page.loadDns() }
    }
    ListRow {
        icon: "lock"
        title: "Encrypted Lookups"
        info: "DNS over TLS. When possible means a server that can't encrypt still answers in the clear."
        value: !page.dns ? "" : ({ yes: "Always", opportunistic: "When possible", no: "Off" })[page.dns.tls]
                                  || page.dns.tls
        alert: page.dnsError
    }
    ListRow {
        visible: !!page.dns
        icon: "dns"
        title: "Server in Use"
        value: page.dns ? page.dns.server || "None" : ""
        subtitle: page.dns && page.dns.servers.length > 1
                  ? `Also known: ${page.dns.servers.filter(s => s !== page.dns.server).join(", ")}` : ""
    }

    //--- One streamed test: Run, its live line, a summary, and the full output
    component TestRow: Rectangle {
        id: test
        property string kind
        property string icon
        property string title
        property string info
        property var summarise
        property bool running: false
        property bool open: false
        property var lines: []
        property string line: ""
        property string result: ""
        property string failed: ""
        Layout.fillWidth: true
        implicitHeight: testCol.implicitHeight + 22
        radius: 16
        color: Theme.card

        function run() {
            running = true
            failed = ""
            result = ""
            lines = []
            Backend.stream("netTest", { kind }, l => {
                test.line = l
                test.lines = test.lines.concat([l])
            }, reply => {
                if (!test)
                    return
                test.running = false
                test.line = ""
                if (reply.ok) {
                    test.lines = reply.data
                    test.result = test.summarise(reply.data)
                } else {
                    test.failed = reply.error
                }
            })
        }

        ColumnLayout {
            id: testCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 11
            anchors.leftMargin: 10
            anchors.rightMargin: 12
            spacing: 8
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Badge { icon: test.icon; tone: test.failed ? "error" : test.result ? "success" : "" }
                ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true
                    Text {
                        text: test.title
                        color: Theme.text
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                        TitleTip { tip: test.info }
                    }
                    Elided {
                        visible: text !== ""
                        text: test.running ? test.line || "Starting…" : ""
                        color: Theme.dim
                        font.pixelSize: 14
                        Layout.fillWidth: true
                    }
                    Text {
                        visible: text !== ""
                        text: test.failed.split("\n")[0]
                        color: Theme.caution
                        font.pixelSize: 14
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
                Text {
                    visible: test.result !== ""
                    text: test.result
                    color: Theme.toneColor("success")
                    font.pixelSize: 20
                    font.weight: Font.Bold
                }
                Pill {
                    text: test.running ? "Running…" : test.lines.length ? "Run Again" : "Run"
                    enabled: !test.running
                    onClicked: test.run()
                }
                IconButton {
                    visible: test.lines.length > 0 || test.failed !== ""
                    icon: "terminal"
                    tip: test.open ? "Hide the output" : "Show the output"
                    onClicked: test.open = !test.open
                }
            }
            Reveal {
                open: test.open
                gap: testCol.spacing
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: outText.implicitHeight + 16
                    radius: 10
                    color: Theme.cardHover
                    TextEdit {
                        id: outText
                        x: 10
                        y: 8
                        width: parent.width - 20
                        readOnly: true
                        selectByMouse: true
                        text: test.failed || test.lines.join("\n")
                        color: Theme.dim
                        selectionColor: Theme.primary
                        font.family: "monospace"
                        font.pixelSize: 12
                        wrapMode: TextEdit.WrapAnywhere
                    }
                }
            }
        }
    }
}
