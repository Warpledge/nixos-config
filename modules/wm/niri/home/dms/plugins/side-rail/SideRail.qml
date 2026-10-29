// DMS plugin: the Mod+A side rail (apps.nix), `dms ipc call sideRail toggle|show <id>|hide`.
// Each app is a real niri window docked floating beside the rail; hidden ones wait on a
// stash workspace. Moves go over DMS's own niri socket, so nothing spawns per click.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Common
import qs.Services
import qs.Widgets
import qs.DCommon.Widgets

Item {
    id: root

    // What PluginService hands a daemon
    property string pluginId
    property var pluginService

    // {geometry, apps} from apps.nix, substituted at build time
    readonly property var config: @config@
    readonly property var geo: config.geometry

    property bool shown: false
    property string activeId: ""
    // An app launched but whose window hasn't opened yet
    property string pendingId: ""
    // Workspace hidden apps wait on, kept so stashing doesn't spread them out
    property int stashWs: -1

    function app(id) {
        return config.apps.find(a => a.id === id) ?? null;
    }

    function windowOf(a) {
        return a ? NiriService.windows.find(w => w.app_id === a.appId) ?? null : null;
    }

    function state(key, fallback) {
        return pluginService ? pluginService.loadPluginState(pluginId, key, fallback) : fallback;
    }

    function saveState(key, value) {
        if (pluginService)
            pluginService.savePluginState(pluginId, key, value);
    }

    function widthOf(a) {
        return state("widths", {})[a.id] ?? a.width;
    }

    function setWidth(a, px) {
        const widths = Object.assign({}, state("widths", {}));
        if (px === null)
            delete widths[a.id];
        else
            widths[a.id] = px;
        saveState("widths", widths);
        const w = windowOf(a);
        if (w)
            act({SetWindowWidth: {id: w.id, change: {SetFixed: widthOf(a)}}});
    }

    function act(action) {
        NiriService.send({Action: action});
    }

    function focusedWs() {
        return NiriService.workspaces[NiriService.focusedWorkspaceId] ?? null;
    }

    //--- The last workspace of the focused output, as nirius's scratchpad uses
    function stashTarget() {
        const focused = focusedWs();
        const known = NiriService.workspaces[stashWs];
        if (known && !known.is_active && (!focused || known.id !== focused.id))
            return stashWs;
        const onOutput = NiriService.allWorkspaces.filter(ws => ws.output === focused?.output && !ws.is_active);
        if (onOutput.length === 0)
            return -1;
        stashWs = onOutput.reduce((a, b) => (b.idx > a.idx ? b : a)).id;
        return stashWs;
    }

    function stash(id) {
        const w = windowOf(app(id));
        const target = stashTarget();
        if (!w || target < 0)
            return;
        rememberWidth(id, w);
        act({MoveWindowToWorkspace: {window_id: w.id, reference: {Id: target}, focus: false}});
    }

    function rememberWidth(id, w) {
        const px = Math.round(w.layout?.window_size?.[0] ?? 0);
        const a = app(id);
        if (!a || px <= 0 || px === widthOf(a))
            return;
        const widths = Object.assign({}, state("widths", {}));
        widths[id] = px;
        saveState("widths", widths);
    }

    //--- Docks a window beside the rail on the focused workspace, at the app's width
    function place(a, w) {
        const ws = focusedWs();
        const screen = railScreen();
        if (ws && w.workspace_id !== ws.id)
            act({MoveWindowToWorkspace: {window_id: w.id, reference: {Id: ws.id}, focus: true}});
        if (!w.is_floating)
            act({MoveWindowToFloating: {id: w.id}});
        const width = widthOf(a);
        if (Math.round(w.layout?.window_size?.[0] ?? 0) !== width)
            act({SetWindowWidth: {id: w.id, change: {SetFixed: width}}});
        if (screen) {
            const top = ShellLayout.edge(screen, "top")?.occupancy ?? 0;
            const bottom = ShellLayout.edge(screen, "bottom")?.occupancy ?? 0;
            const height = Math.round(screen.height - top - bottom - geo.gap * 2);
            if (Math.round(w.layout?.window_size?.[1] ?? 0) !== height)
                act({SetWindowHeight: {id: w.id, change: {SetFixed: height}}});
        }
        act({MoveFloatingWindow: {id: w.id, x: {SetFixed: geo.rail + geo.gap}, y: {SetFixed: geo.gap}}});
        act({FocusWindow: {id: w.id}});
    }

    function open(id) {
        const a = app(id);
        if (!a)
            return;
        if (activeId && activeId !== id)
            stash(activeId);
        activeId = id;
        saveState("lastId", id);
        shown = true;
        const w = windowOf(a);
        if (w) {
            place(a, w);
        } else {
            pendingId = id;
            pendingTimeout.restart();
            Quickshell.execDetached(a.command);
        }
    }

    function hide() {
        if (activeId)
            stash(activeId);
        pendingId = "";
        shown = false;
    }

    function toggle() {
        if (shown) {
            hide();
            return;
        }
        const last = state("lastId", "");
        open(app(last) ? last : (config.apps[0]?.id ?? ""));
    }

    function railScreen() {
        const output = focusedWs()?.output;
        return Quickshell.screens.find(s => s.name === output) ?? Quickshell.screens[0] ?? null;
    }

    //--- A launched app's window: dock it once it opens
    Timer {
        id: pendingTimeout
        interval: 20000
        onTriggered: root.pendingId = ""
    }

    //--- Saves a drag-resized width a moment after the resize settles
    Timer {
        id: widthSaver
        interval: 600
        onTriggered: {
            const w = root.windowOf(root.app(root.activeId));
            if (w)
                root.rememberWidth(root.activeId, w);
        }
    }

    Connections {
        target: NiriService
        enabled: root.shown

        function onWindowsChanged() {
            if (root.pendingId) {
                const a = root.app(root.pendingId);
                const w = root.windowOf(a);
                if (w) {
                    root.pendingId = "";
                    pendingTimeout.stop();
                    if (a.id === root.activeId)
                        root.place(a, w);
                }
            } else if (!NiriService.titleOnlyWindowsUpdate) {
                widthSaver.restart();
            }
        }

        //--- The docked app follows a workspace switch
        function onFocusedWorkspaceIdChanged() {
            const w = root.windowOf(root.app(root.activeId));
            const ws = root.focusedWs();
            if (w && ws && w.workspace_id !== ws.id && ws.id !== root.stashWs)
                root.act({MoveWindowToWorkspace: {window_id: w.id, reference: {Id: ws.id}, focus: true}});
        }
    }

    //--- The rail itself, only alive while shown
    LazyLoader {
        active: root.shown

        PanelWindow {
            id: rail
            screen: root.railScreen()
            WlrLayershell.namespace: "dms:side-rail"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusiveZone: 0
            anchors {
                left: true
                top: true
                bottom: true
            }
            implicitWidth: root.geo.rail
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                anchors.topMargin: root.geo.gap
                anchors.bottomMargin: root.geo.gap
                anchors.leftMargin: root.geo.gap / 2
                radius: Theme.cornerRadius
                color: Theme.withAlpha(Theme.surfaceContainer, Theme.popupTransparency)

                Column {
                    anchors.top: parent.top
                    anchors.topMargin: Theme.spacingS
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.spacingS

                    Repeater {
                        model: root.config.apps

                        Rectangle {
                            id: entry
                            required property var modelData
                            readonly property bool active: modelData.id === root.activeId
                            readonly property bool running: root.windowOf(modelData) !== null
                            readonly property string iconPath: Quickshell.iconPath(modelData.icon, true)
                            width: root.geo.rail - root.geo.gap - Theme.spacingS
                            height: width
                            radius: Theme.cornerRadius
                            color: active ? Theme.withAlpha(Theme.primary, 0.25) : (mouse.containsMouse ? Theme.withAlpha(Theme.surfaceText, 0.08) : "transparent")

                            IconImage {
                                visible: entry.iconPath !== ""
                                source: entry.iconPath
                                implicitSize: parent.width * 0.62
                                anchors.centerIn: parent
                            }

                            DIcon {
                                visible: entry.iconPath === ""
                                name: entry.modelData.icon
                                size: parent.width * 0.55
                                color: entry.active ? Theme.primary : Theme.surfaceText
                                anchors.centerIn: parent
                            }

                            // Running, but not the one shown
                            Rectangle {
                                visible: entry.running && !entry.active
                                width: 4
                                height: 4
                                radius: 2
                                color: Theme.primary
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            MouseArea {
                                id: mouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: event => {
                                    if (event.button === Qt.RightButton) {
                                        const p = entry.mapToItem(null, entry.width, 0);
                                        menu.target = entry.modelData;
                                        menu.open(rail.screen, p.x, p.y, false);
                                    } else if (entry.active) {
                                        root.hide();
                                    } else {
                                        root.open(entry.modelData.id);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            //--- Width presets for one app, and back to its default
            DContextMenu {
                id: menu
                property var target: null
                layerNamespace: "dms:side-rail-menu"
                menuItems: {
                    const t = target;
                    if (!t)
                        return [];
                    const items = Object.keys(root.geo.presets).map(name => ({
                                type: "item",
                                icon: "width",
                                text: name + " (" + root.geo.presets[name] + "px)",
                                action: () => root.setWidth(t, root.geo.presets[name])
                            }));
                    items.push({type: "separator"}, {
                        type: "item",
                        icon: "restart_alt",
                        text: "Reset to default (" + t.width + "px)",
                        action: () => root.setWidth(t, null)
                    });
                    return items;
                }
            }
        }
    }

    IpcHandler {
        target: "sideRail"

        function toggle(): string {
            root.toggle();
            return root.shown ? "OPENED" : "CLOSED";
        }

        function show(id: string): string {
            if (!root.app(id))
                return "NO APP " + id;
            root.open(id);
            return "OPENED";
        }

        function hide(): string {
            root.hide();
            return "CLOSED";
        }
    }
}
