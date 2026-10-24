// Rough Omni Settings as a right-edge slideout in DMS's style. Esc or × closes it.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    property var c: ({})
    property var info: null
    property string toast: ""
    property string tab: "Main"
    property string page: "Overview"
    property bool picking: false

    readonly property var tabs: [
        { name: "Main", icon: "home" },
        { name: "Packages", icon: "package_2" },
        { name: "Niri", icon: "view_quilt" },
        { name: "AI", icon: "science" },
        { name: "Docs", icon: "menu_book" }
    ]
    // Main tab's pages, as the GTK app's sidebar groups them
    readonly property var pages: [
        { group: "", name: "Overview", icon: "dashboard", sub: "Updates, rebuild, versions" },
        { group: "", name: "Git", icon: "commit", sub: "Changes, commits, history" },
        { group: "", name: "Flatpaks", icon: "widgets", sub: "Installed apps, permissions" },
        { group: "", name: "Backups", icon: "backup", sub: "Snapshots, restore" },
        { group: "", name: "People", icon: "group", sub: "Users on this computer" },
        { group: "This Computer", name: "System", icon: "computer", sub: "Kernel, boot, power" },
        { group: "This Computer", name: "Language & Input", icon: "language", sub: "Locale, keyboard, IME" },
        { group: "This Computer", name: "Devices", icon: "devices", sub: "Bluetooth, printers, GPU" },
        { group: "This Computer", name: "Network & Firewall", icon: "lan", sub: "DNS, ports, VPN" },
        { group: "This Computer", name: "Services", icon: "dns", sub: "Background services" },
        { group: "Personal", name: "Account", icon: "person", sub: "Shell, groups, admin" },
        { group: "Personal", name: "Default Apps", icon: "apps", sub: "Browser, editor, terminal" }
    ]

    function col(name, fallback) { return c[name] || fallback }
    function gib(b) { return (b / 1073741824).toFixed(0) + " GiB" }
    function say(text) { toast = text; toastTimer.restart() }
    function pageInfo(name) { return pages.find(p => p.name === name) }

    // matugen colours, as DMS writes them
    FileView {
        path: Quickshell.env("HOME") + "/.cache/DankMaterialShell/dms-colors.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const d = JSON.parse(text())
            root.c = d.colors[d.mode] || d.colors.dark
        }
    }

    Process {
        command: ["python3", "-I", Qt.resolvedUrl("dump.py").toString().replace("file://", "")]
        running: true
        stdout: StdioCollector { onStreamFinished: root.info = JSON.parse(this.text) }
    }

    Timer { id: toastTimer; interval: 2500; onTriggered: root.toast = "" }

    PanelWindow {
        id: win
        anchors { top: true; right: true; bottom: true }
        margins { top: 8; right: 8; bottom: 8 }
        implicitWidth: 480
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "omni-panel"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Rectangle {
            id: sheet
            width: parent.width
            height: parent.height
            x: parent.width + 16
            radius: 20
            color: root.col("surface_container", "#1e1e2e")
            border.color: root.col("outline_variant", "#45475a")
            border.width: 1
            clip: true
            focus: true
            Keys.onEscapePressed: root.picking ? root.picking = false : closeAnim.start()

            Component.onCompleted: openAnim.start()
            NumberAnimation on x { id: openAnim; running: false; to: 0; duration: 260; easing.type: Easing.OutCubic }
            SequentialAnimation {
                id: closeAnim
                NumberAnimation { target: sheet; property: "x"; to: win.width + 16; duration: 200; easing.type: Easing.InCubic }
                ScriptAction { script: Qt.quit() }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                //--- Header
                RowLayout {
                    Layout.fillWidth: true
                    Item { width: 68 }
                    Text {
                        text: "Omni Settings"
                        color: root.col("on_surface", "white")
                        font.pixelSize: 16; font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                    }
                    IconButton { icon: "open_in_new"; onClicked: { Quickshell.execDetached(["omni-settings"]); closeAnim.start() } }
                    IconButton { icon: "close"; filled: true; onClicked: closeAnim.start() }
                }

                //--- Top tabs
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 40
                    radius: 20
                    color: root.col("surface_container_high", "#313244")
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 2
                        Repeater {
                            model: root.tabs
                            Rectangle {
                                required property var modelData
                                readonly property bool active: root.tab === modelData.name
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 16
                                color: active ? root.col("primary", "violet")
                                     : tabHover.hovered ? root.col("surface_container_highest", "#45475a") : "transparent"
                                Behavior on color { ColorAnimation { duration: 150 } }
                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Icon { icon: modelData.icon; size: 16; fill: active; color: active ? root.col("on_primary", "black") : root.col("on_surface_variant", "gray") }
                                    Text {
                                        text: modelData.name
                                        font.pixelSize: 12; font.weight: Font.DemiBold
                                        color: active ? root.col("on_primary", "black") : root.col("on_surface_variant", "gray")
                                    }
                                }
                                HoverHandler { id: tabHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler { onTapped: { root.tab = modelData.name; root.picking = false } }
                            }
                        }
                    }
                }

                //--- Page picker: the current page, opening into the page list
                Rectangle {
                    Layout.fillWidth: true
                    visible: root.tab === "Main"
                    implicitHeight: pickerCol.implicitHeight
                    radius: 16
                    color: root.col("surface_container_high", "#313244")
                    clip: true
                    Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                    ColumnLayout {
                        id: pickerCol
                        width: parent.width
                        spacing: 0

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 60
                            radius: 16
                            color: currentHover.hovered ? root.col("surface_container_highest", "#45475a") : "transparent"
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10; anchors.rightMargin: 14
                                spacing: 12
                                Badge { icon: root.pageInfo(root.page).icon; strong: true }
                                ColumnLayout {
                                    spacing: 1
                                    Layout.fillWidth: true
                                    Text { text: root.page; color: root.col("on_surface", "white"); font.pixelSize: 15; font.weight: Font.DemiBold }
                                    Text { text: root.pageInfo(root.page).sub; color: root.col("on_surface_variant", "gray"); font.pixelSize: 12 }
                                }
                                Icon {
                                    icon: "expand_more"
                                    color: root.col("on_surface_variant", "gray")
                                    rotation: root.picking ? 180 : 0
                                    Behavior on rotation { NumberAnimation { duration: 200 } }
                                }
                            }
                            HoverHandler { id: currentHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: { root.picking = !root.picking; if (root.picking) search.forceActiveFocus() } }
                        }

                        ColumnLayout {
                            visible: root.picking
                            Layout.fillWidth: true
                            Layout.margins: 8
                            spacing: 2

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 38
                                radius: 19
                                color: root.col("surface_container_highest", "#45475a")
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12; anchors.rightMargin: 12
                                    Icon { icon: "search"; size: 18; color: root.col("on_surface_variant", "gray") }
                                    TextInput {
                                        id: search
                                        Layout.fillWidth: true
                                        color: root.col("on_surface", "white")
                                        selectionColor: root.col("primary", "violet")
                                        font.pixelSize: 13
                                        Keys.onEscapePressed: { text = ""; root.picking = false; sheet.forceActiveFocus() }
                                        Text {
                                            visible: !parent.text
                                            text: "Search settings"
                                            color: root.col("on_surface_variant", "gray")
                                            font.pixelSize: 13
                                        }
                                    }
                                }
                            }

                            Repeater {
                                model: root.pages.filter(p => p.name.toLowerCase().includes(search.text.toLowerCase()))
                                ColumnLayout {
                                    required property var modelData
                                    required property int index
                                    readonly property var list: root.pages.filter(p => p.name.toLowerCase().includes(search.text.toLowerCase()))
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Section {
                                        visible: modelData.group !== "" && (index === 0 || list[index - 1].group !== modelData.group)
                                        text: modelData.group
                                        Layout.leftMargin: 8
                                    }
                                    Row_ {
                                        icon: modelData.icon
                                        title: modelData.name
                                        subtitle: modelData.sub
                                        selected: root.page === modelData.name
                                        compact: true
                                        onClicked: { root.page = modelData.name; root.picking = false; search.text = ""; sheet.forceActiveFocus() }
                                    }
                                }
                            }
                        }
                    }
                }

                //--- Page body
                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: body.implicitHeight
                    clip: true
                    opacity: root.picking ? 0.35 : 1
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    ColumnLayout {
                        id: body
                        width: parent.width
                        spacing: 6

                        Text {
                            visible: !(root.tab === "Main" && root.page === "Overview")
                            Layout.fillWidth: true
                            Layout.topMargin: 40
                            horizontalAlignment: Text.AlignHCenter
                            text: `${root.tab === "Main" ? root.page : root.tab}: not in the prototype`
                            color: root.col("on_surface_variant", "gray")
                        }

                        ColumnLayout {
                            visible: root.tab === "Main" && root.page === "Overview"
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                visible: !root.info
                                text: "Loading…"
                                color: root.col("on_surface_variant", "gray")
                            }

                            //--- Hero
                            Rectangle {
                                visible: !!root.info
                                Layout.fillWidth: true
                                implicitHeight: hero.implicitHeight + 28
                                radius: 16
                                color: root.col("surface_container_high", "#313244")
                                RowLayout {
                                    id: hero
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 14
                                    Rectangle {
                                        width: 64; height: 64; radius: 32
                                        color: root.col("primary_container", "violet")
                                        Icon { anchors.centerIn: parent; icon: "ac_unit"; size: 38; color: root.col("on_primary_container", "black") }
                                    }
                                    ColumnLayout {
                                        spacing: 4
                                        Layout.fillWidth: true
                                        Text { text: root.info?.hostname ?? ""; color: root.col("on_surface", "white"); font.pixelSize: 22; font.weight: Font.Bold }
                                        Text { text: root.info?.pretty ?? ""; color: root.col("on_surface_variant", "gray") }
                                        Flow {
                                            Layout.fillWidth: true
                                            spacing: 6
                                            Chip { text: "niri"; accent: true }
                                            Chip { text: "Linux " + (root.info?.kernel ?? "") }
                                            Chip { visible: (root.info?.generation ?? 0) > 0; text: "Version " + root.info?.generation }
                                        }
                                    }
                                }
                            }

                            //--- Waiting for a restart
                            Row_ {
                                visible: !!root.info && (root.info.pending > 0 || root.info.newKernel !== "")
                                icon: "restart_alt"
                                title: root.info?.pending ? "Restart to finish" : "Restart to use the new kernel"
                                subtitle: root.info?.pending ? `Version ${root.info.pending} starts the next time you restart.`
                                                             : `Linux ${root.info?.newKernel} is installed.`
                                button: "Restart"
                                onClicked: root.say("Prototype: Restart isn't wired")
                            }

                            //--- Updates
                            Section { text: "Updates" }
                            Row_ {
                                icon: "update"
                                title: "Sources"
                                subtitle: `Flake inputs, locked ${root.info?.updated ?? ""}`
                                button: "Check"
                                onClicked: root.say("Prototype: Check for updates isn't wired")
                            }

                            //--- Maintenance
                            Section { text: "Maintenance" }
                            Row_ { icon: "refresh"; title: "Rebuild Now"; subtitle: "nixos-rebuild switch on your settings files as they are"; chevron: true; onClicked: root.say("Prototype: Rebuild isn't wired") }
                            Row_ {
                                icon: "delete_sweep"
                                title: "Clean Up Old Versions"
                                subtitle: root.info ? `Garbage collection · ${root.gib(root.info.diskFree)} free of ${root.gib(root.info.diskTotal)}` : "Garbage collection"
                                chevron: true
                                bar: root.info ? 1 - root.info.diskFree / root.info.diskTotal : -1
                                onClicked: root.say("Prototype: Clean Up isn't wired")
                            }
                            Row_ { icon: "folder_open"; title: "Open the Config Folder"; subtitle: root.info?.flake ?? ""; trailing: "open_in_new"; onClicked: Quickshell.execDetached(["xdg-open", root.info.flake]) }

                            //--- Versions
                            Section { text: "Versions" }
                            Repeater {
                                model: root.info?.generations ?? []
                                Row_ {
                                    required property var modelData
                                    icon: modelData.running ? "radio_button_checked" : "history"
                                    title: "Version " + modelData.number
                                    subtitle: `${modelData.when} · Linux ${modelData.kernel}`
                                    tag: modelData.running ? "Running" : (modelData.booted ? "Started with" : "")
                                    button: modelData.running ? "" : "Switch"
                                    onClicked: root.say("Prototype: switching versions isn't wired")
                                }
                            }
                        }
                    }
                }
            }

            //--- Toast
            Rectangle {
                anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 16 }
                visible: root.toast !== ""
                width: toastText.implicitWidth + 28; height: 36; radius: 18
                color: root.col("inverse_surface", "white")
                Text { id: toastText; anchors.centerIn: parent; text: root.toast; color: root.col("inverse_on_surface", "black") }
            }
        }
    }

    //-- Small parts
    component Icon: Text {
        property string icon
        property int size: 22
        property bool fill: false
        text: icon
        font.family: "Material Symbols Rounded"
        font.pixelSize: size
        font.variableAxes: { "FILL": fill ? 1 : 0 }
    }

    component Badge: Rectangle {
        property string icon
        property bool strong: false
        width: 38; height: 38; radius: 19
        color: strong ? root.col("primary", "violet") : root.col("primary_container", "violet")
        Icon {
            anchors.centerIn: parent
            icon: parent.icon; size: 20
            color: parent.strong ? root.col("on_primary", "black") : root.col("on_primary_container", "black")
        }
    }

    component IconButton: Rectangle {
        id: btn
        property string icon
        property bool filled: false
        signal clicked
        width: 32; height: 32; radius: 16
        color: filled ? root.col("surface_container_highest", "#45475a")
             : hover.hovered ? root.col("surface_container_highest", "#313244") : "transparent"
        Icon { anchors.centerIn: parent; icon: btn.icon; size: 18; color: root.col("on_surface_variant", "gray") }
        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: btn.clicked() }
    }

    component Section: Text {
        color: root.col("primary", "violet")
        font.pixelSize: 13; font.weight: Font.DemiBold
        Layout.topMargin: 8
        Layout.leftMargin: 6
    }

    component Chip: Rectangle {
        property alias text: label.text
        property bool accent: false
        width: label.implicitWidth + 16; height: 24; radius: 12
        color: accent ? root.col("primary_container", "violet") : root.col("surface_container_highest", "#45475a")
        Text {
            id: label
            anchors.centerIn: parent
            font.pixelSize: 12
            color: parent.accent ? root.col("on_primary_container", "black") : root.col("on_surface_variant", "gray")
        }
    }

    component Pill: Rectangle {
        property alias text: pillText.text
        width: pillText.implicitWidth + 28; height: 34; radius: 17
        color: root.col("primary", "violet")
        Text { id: pillText; anchors.centerIn: parent; font.weight: Font.DemiBold; color: root.col("on_primary", "black") }
    }

    // One DMS-style row: its own rounded block, icon badge, title and subtitle
    component Row_: Rectangle {
        id: row
        property string icon
        property string title
        property string subtitle
        property string tag: ""
        property string button: ""
        property string trailing: ""
        property bool chevron: false
        property bool selected: false
        property bool compact: false
        property real bar: -1
        signal clicked
        Layout.fillWidth: true
        implicitHeight: rowCol.implicitHeight + (compact ? 14 : 22)
        radius: 14
        color: selected ? root.col("secondary_container", "#45475a")
             : rowHover.hovered ? root.col("surface_container_highest", "#45475a")
             : compact ? "transparent" : root.col("surface_container_high", "#313244")
        Behavior on color { ColorAnimation { duration: 120 } }

        ColumnLayout {
            id: rowCol
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left; anchors.right: parent.right
            anchors.leftMargin: 10; anchors.rightMargin: 12
            spacing: 8
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Badge { icon: row.icon }
                ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true
                    Text { text: row.title; color: root.col("on_surface", "white"); font.pixelSize: 14; font.weight: Font.DemiBold }
                    Text { text: row.subtitle; color: root.col("on_surface_variant", "gray"); font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
                }
                Chip { visible: row.tag !== ""; text: row.tag; accent: true }
                Pill { visible: row.button !== ""; text: row.button }
                Icon { visible: row.chevron; icon: "chevron_right"; color: root.col("on_surface_variant", "gray") }
                Icon { visible: row.trailing !== ""; icon: row.trailing; size: 18; color: root.col("on_surface_variant", "gray") }
            }
            Rectangle {
                visible: row.bar >= 0
                Layout.fillWidth: true
                Layout.leftMargin: 50
                height: 6; radius: 3
                color: root.col("surface_container_highest", "#45475a")
                Rectangle {
                    height: parent.height; radius: 3
                    width: parent.width * Math.max(0, row.bar)
                    color: root.col("primary", "violet")
                }
            }
        }
        HoverHandler { id: rowHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: row.clicked() }
    }
}
