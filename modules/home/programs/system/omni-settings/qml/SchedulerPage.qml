// CPU Scheduler (Hardware tab): the sched_ext scheduler running now (api.py's
// scheduler), and a `scheduler` job that switches or stops it until the next boot
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var view
    property var sched: null  // {running, ops, active, override, choices}
    property string error: ""
    readonly property bool ready: !!sched || error !== ""
    readonly property bool admin: !!view.info && view.info.admin
    spacing: 6

    Component.onCompleted: load()
    Connections {
        target: Jobs
        function onEnded() { page.load() }
    }
    function load() {
        Backend.call("scheduler", {}, reply => {
            if (!page)
                return
            if (reply.ok)
                sched = reply.data
            else
                error = reply.error
        })
    }

    //--- "lavd_1.1.4_x86_64…" is scx_lavd
    function runningName() {
        if (!sched || !sched.running)
            return ""
        return "scx_" + sched.ops.split("_")[0]
    }

    function run(name, heading, body) {
        if (!view.canStart())
            return
        view.ask({ heading, body, buttons: [{ label: "Switch", value: true }] },
                 () => view.startJob("scheduler", { name }))
    }

    ListRow {
        icon: "memory"
        title: "Running Now"
        info: "sched_ext loads a CPU scheduler as a BPF program. When none is running, the kernel's "
              + "own scheduler (EEVDF) takes over."
        value: !page.sched ? "" : page.sched.running ? page.runningName() : "Kernel's own"
        alert: page.error || (page.sched && page.sched.override
                              ? "Switched here until the next restart" : "")
    }

    Section {
        text: "Switch Until Restart"
        info: "Runs another scheduler until the computer restarts, then the config's own starts again. "
              + "Change the one it starts in the config."
    }
    Repeater {
        model: page.sched ? page.sched.choices : []
        ListRow {
            required property var modelData
            icon: page.runningName() === modelData.name ? "check_circle" : "speed"
            title: modelData.name
            info: modelData.text
            button: page.admin && page.runningName() !== modelData.name ? "Switch" : ""
            onClicked: page.run(modelData.name, `Switch to ${modelData.name}?`,
                                "It runs until the next restart. Games keep running while it switches.")
        }
    }
    RowLayout {
        visible: page.admin && !!page.sched
        Layout.fillWidth: true
        spacing: 8
        Pill {
            visible: !!page.sched && (!!page.sched.override || !page.sched.running)
            text: "Back to the Default"
            quiet: true
            onClicked: page.run("default", "Go back to the default scheduler?",
                                "Starts the one the config sets.")
        }
        Pill {
            visible: !!page.sched && page.sched.running
            text: "Stop Until Restart"
            quiet: true
            danger: true
            onClicked: page.run("stop", "Stop the scheduler?",
                                "The kernel's own scheduler takes over until the next restart.")
        }
    }
    Text {
        visible: !page.admin
        text: "Only an admin can switch the scheduler."
        color: Theme.dim
        font.pixelSize: 13
        Layout.leftMargin: 6
    }
}
