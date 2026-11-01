// Face Auth (Security tab): the faceAuth settings, the saved faces (api.py's faceAuth,
// changed through omni-face-auth) and a live view of the camera (omni-face-preview)
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: page
    required property var view
    property var face: null  // {applied, cameras, faces}
    property string error: ""
    property bool pickCamera: false
    property bool viewing: false
    property real darkness: -1
    property int frame: 0
    property string viewError: ""
    property string testResult: ""
    readonly property bool ready: !!face || error !== ""
    readonly property var setting: view.info.pages["faceauth"]
    readonly property var settings: setting ? setting.groups[0].settings : []
    readonly property var deviceSetting: find("machine:faceAuth.device")
    readonly property var thresholdSetting: find("machine:faceAuth.darkThreshold")
    readonly property string device: deviceSetting ? (view.valueOf(deviceSetting) || "") : ""
    readonly property int threshold: thresholdSetting ? view.valueOf(thresholdSetting) : 90
    readonly property string framePath: Quickshell.env("XDG_RUNTIME_DIR") + "/omni-settings/ir-preview.jpg"
    readonly property bool applied: !!face && face.applied
    spacing: 6

    function find(key) {
        return settings.find(s => s.key === key) || null
    }
    function load() {
        Backend.call("faceAuth", {}, reply => {
            if (!page)
                return
            if (reply.ok)
                face = reply.data
            else
                error = reply.error
        })
    }
    function cameraName() {
        if (!face || !device)
            return "/dev/video2"
        const c = face.cameras.find(c => c.path === device)
        return c ? c.name : device
    }
    //--- Add, remove and Test need the camera or a polkit scan, so the view lets go first
    function run(args) {
        viewing = false
        tool.command = ["/run/wrappers/bin/pkexec", face.tool].concat(args)
        tool.running = true
    }

    Component.onCompleted: load()
    Connections {
        target: Jobs
        function onEnded() { page.load() }
    }
    onVisibleChanged: if (!visible) viewing = false
    Component.onDestruction: viewing = false

    Process {
        id: tool
        property var args: command.slice(2)
        onExited: code => {
            const testing = args[0] === "test"
            if (testing)
                page.testResult = code === 0
                    ? "Approved. If it didn't ask for your password, your face matched."
                    : "Not approved."
            else if (code !== 0)
                page.view.say(args[0] === "add" ? "Couldn't add that face." : "Couldn't remove that face.")
            page.load()
        }
    }

    Process {
        id: preview
        running: page.viewing
        command: ["/run/current-system/sw/bin/omni-face-preview", page.device || "/dev/video2"]
        stdout: SplitParser {
            onRead: line => {
                const msg = JSON.parse(line)
                if (msg.error) {
                    page.viewError = msg.error
                    page.viewing = false
                } else {
                    page.darkness = msg.darkness
                    page.frame++
                }
            }
        }
    }

    Repeater {
        model: page.setting ? page.setting.groups : []
        SettingGroup {
            required property var modelData
            settings: modelData.settings.filter(s => s.key === "machine:faceAuth.enable")
            view: page.view
            locked: modelData.locked
            pageGlyph: "face"
        }
    }

    Text {
        visible: !!page.face && !page.applied
        text: "Turn it on and rebuild to set up your face here."
        color: Theme.dim
        font.pixelSize: 13
        Layout.leftMargin: 6
    }

    ColumnLayout {
        visible: page.applied
        Layout.fillWidth: true
        spacing: 6

        ListRow {
            icon: "photo_camera"
            title: "IR Camera"
            info: "The camera Howdy scans with. A change applies after a rebuild."
            trailing: page.cameraName()
            expandable: true
            expanded: page.pickCamera
            onClicked: page.pickCamera = !page.pickCamera
        }
        Reveal {
            open: page.pickCamera
            gap: 6
            spacing: 6
            Repeater {
                model: page.face ? page.face.cameras : []
                ListRow {
                    required property var modelData
                    compact: true
                    icon: page.device === modelData.path ? "check_circle" : "photo_camera"
                    title: modelData.name
                    subtitle: modelData.path.split("/").pop()
                    onClicked: {
                        page.view.change(page.deviceSetting, modelData.path)
                        page.pickCamera = false
                    }
                }
            }
        }

        Section {
            text: "Faces"
            info: "Add one for each look or angle you use, such as with and without glasses."
        }
        Repeater {
            model: page.face ? page.face.faces : []
            ListRow {
                required property var modelData
                icon: "face"
                title: modelData.label
                button: "Remove"
                onClicked: page.run(["remove", String(modelData.id)])
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Field {
                id: label
                Layout.fillWidth: true
                placeholder: "Name this face"
                onAccepted: add.clicked()
            }
            Pill {
                id: add
                text: "Add"
                enabled: label.text.trim() !== "" && !tool.running
                onClicked: {
                    page.run(["add", label.text.trim()])
                    label.text = ""
                }
            }
        }

        Section {
            text: "Camera View"
            info: "What Howdy sees, live. Nothing is saved, and it stops when you leave this page."
        }
        ListRow {
            icon: page.viewing ? "videocam" : "videocam_off"
            title: page.viewing ? "Camera On" : "Camera Off"
            alert: page.viewError
            button: page.viewing ? "Stop" : "Start"
            onClicked: {
                page.viewError = ""
                page.viewing = !page.viewing
            }
        }
        Image {
            visible: page.viewing && page.frame > 0
            Layout.fillWidth: true
            Layout.preferredHeight: width * 0.75
            fillMode: Image.PreserveAspectFit
            cache: false
            asynchronous: true
            source: page.viewing && page.frame > 0 ? `file://${page.framePath}?${page.frame}` : ""
        }
        ListRow {
            visible: page.viewing && page.darkness >= 0
            icon: page.darkness > page.threshold ? "visibility_off" : "visibility"
            title: page.darkness > page.threshold ? "Too Dark: Howdy Skips This Frame" : "Howdy Can Use This Frame"
            tone: page.darkness > page.threshold ? "caution" : "success"
            value: `${Math.round(page.darkness)}%`
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            spacing: 4
            Text {
                text: `Dark Threshold: ${page.threshold}%`
                color: Theme.text
                font.pixelSize: 15
                TitleTip {
                    tip: "Howdy skips frames darker than this. A change applies after a rebuild. "
                         + "If every frame is too dark, your camera's IR emitter may be off."
                }
            }
            Item {
                id: slider
                Layout.fillWidth: true
                implicitHeight: 28
                function set(x) {
                    const percent = Math.round(Math.max(0, Math.min(1, x / width)) * 100)
                    page.view.change(page.thresholdSetting, percent)
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 6
                    radius: 3
                    color: Theme.rule
                    Rectangle {
                        width: parent.width * page.threshold / 100
                        height: parent.height
                        radius: 3
                        color: Theme.primary
                    }
                    //--- This frame's darkness against the threshold
                    Rectangle {
                        visible: page.viewing && page.darkness >= 0
                        x: parent.width * page.darkness / 100 - 1
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2
                        height: 16
                        color: Theme.text
                    }
                }
                Rectangle {
                    x: parent.width * page.threshold / 100 - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: 16
                    height: 16
                    radius: 8
                    color: Theme.primary
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: mouse => slider.set(mouse.x)
                    onPositionChanged: mouse => { if (pressed) slider.set(mouse.x) }
                }
            }
        }

        ListRow {
            icon: "verified_user"
            title: "Test"
            info: "Opens a confirmation prompt. Look at the camera when it appears."
            alert: page.testResult
            button: "Test"
            onClicked: {
                page.testResult = ""
                page.run(["test"])
            }
        }
    }

    Text {
        visible: page.error !== ""
        text: page.error
        color: Theme.caution
        font.pixelSize: 13
        Layout.leftMargin: 6
    }
}
