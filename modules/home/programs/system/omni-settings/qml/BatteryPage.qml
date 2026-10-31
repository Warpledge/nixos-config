// Battery (Hardware tab): the machine's battery.chargeLimit setting above each
// battery's live state (api.py's `battery`)
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var view
    property var bat: null
    property string error: ""
    readonly property bool ready: !!bat || error !== ""
    readonly property var setting: view.info.pages["battery"]
    spacing: 6

    function load() {
        Backend.call("battery", {}, reply => {
            if (!page)
                return  // the tab was left before the reply came
            if (reply.ok)
                bat = reply.data
            else
                error = reply.error
        })
    }

    // What the hardware is doing now, which lags the setting until a rebuild
    function limitNow() {
        if (!bat)
            return ""
        if (bat.conservation !== null)
            return bat.conservation ? "Conservation mode" : "Charges to full"
        const t = bat.batteries.map(b => b.threshold).find(t => t)
        return t && t !== "100" ? `Stops at ${t}%` : "Charges to full"
    }

    Component.onCompleted: load()

    //--- The charge limit, a machine setting like any other
    Repeater {
        model: page.setting ? page.setting.groups : []
        SettingGroup {
            required property var modelData
            settings: modelData.settings
            view: page.view
            locked: !page.view.info.direct
            pageGlyph: "battery_full"
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Section {
            text: "Right Now"
            info: "The battery as the kernel reports it. A new charge limit shows here after Apply."
            Layout.fillWidth: true
        }
        IconButton { icon: "refresh"; tip: "Check again"; Layout.topMargin: 10; onClicked: page.load() }
    }
    ListRow {
        visible: !!page.bat
        icon: "battery_charging_full"
        title: "Charge Limit"
        info: "Lenovo laptops stop at a point their firmware picks (often 60 or 80%) in "
              + "conservation mode, whatever number is set above."
        value: page.limitNow()
    }
    ListRow {
        visible: !page.bat
        icon: "battery_unknown"
        title: page.error ? "Couldn't read the battery" : "Checking…"
        alert: page.error
    }
    Repeater {
        model: page.bat ? page.bat.batteries : []
        ColumnLayout {
            id: one
            required property var modelData
            Layout.fillWidth: true
            spacing: 6
            ListRow {
                icon: "battery_full"
                title: one.modelData.name
                subtitle: one.modelData.status
                value: `${one.modelData.capacity}%`
                bar: one.modelData.capacity / 100
            }
            ListRow {
                visible: one.modelData.health !== null
                icon: "health_and_safety"
                compact: true
                title: "Health"
                info: "How much charge it holds now, compared with when it was new."
                value: one.modelData.health !== null ? `${one.modelData.health}%` : ""
            }
            ListRow {
                visible: one.modelData.cycles !== null
                icon: "autorenew"
                compact: true
                title: "Charge Cycles"
                value: one.modelData.cycles !== null ? `${one.modelData.cycles}` : ""
            }
        }
    }
}
