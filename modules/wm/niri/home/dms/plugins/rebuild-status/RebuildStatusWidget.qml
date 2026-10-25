import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins

// Hidden while no rebuild runs; after one ends it shows how it ended for
// resultMs, or until dismissed from the popout.
PluginComponent {
    id: root

    readonly property int resultMs: 10 * 60 * 1000

    // [{source, label, expects, started}], one per tool running a rebuild
    property var runs: []
    property int builders: 0
    property string generation: ""
    property real now: Date.now()

    // {at, expects}: the oldest start seen for the run, and whether it should
    // leave a new system
    property var start: null
    // {text, tone, icon, secs, generation} for the last run that ended
    property var result: null

    readonly property bool running: runs.length > 0
    readonly property real startedAt: start ? start.at : now

    // ps lines for the rebuild tools, the number of nix build users busy, when
    // the running and boot system links last changed, and the boot generation.
    // A switch restarts DMS, so the run's end is judged by those times rather
    // than by a before/after look. Only the program or its first argument
    // (pkexec's, an interpreter's) counts, not a shell whose text names one.
    readonly property string probe: "ps -eo user:32=,etimes=,args= | awk '"
        + "function base(p) { sub(/.*\\//, \"\", p); return p } "
        + "$1 ~ /^nixbld/ || $1 ~ /^[0-9]+$/ { b[$1] = 1; next } "
        + "{ x = base($3); y = base($4) } "
        + "x ~ /^\\.?nh(-wrapped)?$/ && $4 == \"os\" && $5 ~ /^(switch|boot|test|build)$/ "
        + "|| (x ~ /^(pkexec|sudo|python[0-9.]*|bash|sh)$/ ? y : x) ~ /[n]ixos-rebuild|[o]mni-settings-apply/ "
        + "{ $1 = \"\"; print \"R\" $0 } "
        + "END { n = 0; for (u in b) n++; print \"B \" n }'; "
        + "echo T $(stat -c %Y /run/current-system /nix/var/nix/profiles/system); "
        + "echo G $(readlink /nix/var/nix/profiles/system)"

    function describe(args) {
        if (args.indexOf("omni-settings-apply") >= 0) {
            const mode = (args.match(/"mode": "(\w+)"/) || [])[1] || "switch";
            if (args.indexOf("collectGarbage") >= 0)
                return {source: "Omni Settings", label: "Cleaning up", expects: false};
            if (args.indexOf("\"activate\"") >= 0)
                return {source: "Omni Settings", label: "Switching version", expects: true};
            return {source: "Omni Settings", label: mode === "build" ? "Previewing" : "Rebuilding",
                    expects: mode !== "build"};
        }
        const nh = args.indexOf("nixos-rebuild") < 0;
        const sub = (args.match(/\b(switch|boot|test|dry-build|dry-activate|build)\b/) || [])[1] || "switch";
        const dry = sub.startsWith("dry") || /\s--dry\b/.test(args);
        const labels = {switch: "Rebuilding", boot: "Building for next boot", test: "Testing", build: "Building"};
        return {source: nh ? "nh" : "nixos-rebuild",
                label: dry ? "Dry run" : nh && /\s--update\b/.test(args) ? "Updating" : (labels[sub] || "Rebuilding"),
                expects: !dry && sub !== "build"};
    }

    function parse(text) {
        const found = {};
        let busy = 0, switched = 0, linked = 0, gen = "";
        for (const line of text.split("\n")) {
            const parts = line.trim().split(/\s+/);
            if (parts[0] === "R" && parts.length > 2) {
                const secs = parseInt(parts[1]) || 0;
                const run = describe(parts.slice(2).join(" "));
                run.started = Date.now() - secs * 1000;
                if (!found[run.source] || found[run.source].started > run.started)
                    found[run.source] = run;
            } else if (parts[0] === "B") {
                busy = parseInt(parts[1]) || 0;
            } else if (parts[0] === "T") {
                switched = (parseInt(parts[1]) || 0) * 1000;
                linked = (parseInt(parts[2]) || 0) * 1000;
            } else if (parts[0] === "G") {
                gen = ((parts[1] || "").match(/system-(\d+)-link/) || [])[1] || "";
            }
        }
        const list = Object.values(found);
        if (list.length) {
            const at = Math.min.apply(null, list.map(r => r.started));
            const expects = list.some(r => r.expects);
            start = start ? {at: Math.min(start.at, at), expects: start.expects || expects} : {at, expects};
        } else if (start) {
            finish(switched, linked, gen);
        }
        builders = busy;
        generation = gen;
        runs = list;
    }

    function finish(switched, linked, gen) {
        const secs = Math.round((Date.now() - start.at) / 1000);
        // ps ages are whole seconds
        const since = start.at - 2000;
        if (switched >= since)
            result = {text: "Switched to the new system", tone: "success", icon: "check_circle", secs, generation: gen};
        else if (linked >= since)
            result = {text: "Ready on next boot", tone: "success", icon: "restart_alt", secs, generation: gen};
        else if (!start.expects)
            result = {text: "Finished", tone: "neutral", icon: "task_alt", secs, generation: gen};
        else
            result = {text: "Ended without a new system", tone: "error", icon: "error", secs, generation: gen};
        start = null;
        resultTimer.restart();
    }

    function clock(secs) {
        const m = Math.floor(secs / 60), s = secs % 60;
        return m >= 60 ? Math.floor(m / 60) + ":" + String(m % 60).padStart(2, "0") + ":" + String(s).padStart(2, "0")
                       : m + ":" + String(s).padStart(2, "0");
    }

    function toneColor(tone) {
        return tone === "success" ? Theme.success : tone === "error" ? Theme.error : Theme.surfaceText;
    }

    readonly property string elapsed: clock(Math.max(0, Math.round((now - startedAt) / 1000)))
    readonly property string pillIcon: running ? "autorenew" : result ? result.icon : "autorenew"
    readonly property color pillColor: running ? Theme.primary : result ? toneColor(result.tone) : Theme.surfaceText

    onRunningChanged: setVisibilityOverride(running || result !== null)
    onResultChanged: setVisibilityOverride(running || result !== null)
    Component.onCompleted: setVisibilityOverride(false)

    Process {
        id: poll
        command: ["sh", "-c", root.probe]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!poll.running) poll.running = true
    }

    Timer {
        interval: 1000
        running: root.running
        repeat: true
        onTriggered: root.now = Date.now()
    }

    Timer {
        id: resultTimer
        interval: root.resultMs
        onTriggered: root.result = null
    }

    // The spinner is its own icon: a stopped rotation keeps its last angle
    component PillIcon: Item {
        width: root.iconSize
        height: root.iconSize

        DIcon {
            anchors.centerIn: parent
            visible: root.running
            name: "autorenew"
            size: root.iconSize
            color: root.pillColor
            RotationAnimation on rotation {
                running: root.running
                from: 0
                to: 360
                duration: 1400
                loops: Animation.Infinite
            }
        }

        DIcon {
            anchors.centerIn: parent
            visible: !root.running
            name: root.pillIcon
            size: root.iconSize
            color: root.pillColor
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            PillIcon {
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                visible: root.running
                text: root.elapsed
                font.pixelSize: root.textSize
                font.features: {"tnum": 1}
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: 1

            PillIcon {
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                visible: root.running
                text: root.elapsed
                font.pixelSize: root.textSize * 0.8
                color: Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    popoutWidth: 300
    popoutHeight: 190

    popoutContent: Component {
        PopoutComponent {
            id: pop
            headerText: "Rebuild"
            detailsText: root.generation ? "Boot entry: generation " + root.generation : ""

            Column {
                width: parent.width
                spacing: Theme.spacingS
                leftPadding: Theme.spacingS
                rightPadding: Theme.spacingS

                Repeater {
                    model: root.runs
                    Row {
                        spacing: Theme.spacingS
                        DIcon {
                            name: "autorenew"
                            size: Theme.iconSizeSmall
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        StyledText {
                            text: modelData.label + " · " + modelData.source + " · "
                                + root.clock(Math.max(0, Math.round((root.now - modelData.started) / 1000)))
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeMedium
                        }
                    }
                }

                StyledText {
                    visible: root.running
                    text: root.builders === 1 ? "1 derivation building" : root.builders + " derivations building"
                    color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall
                }

                Row {
                    visible: !root.running && root.result !== null
                    spacing: Theme.spacingS
                    DIcon {
                        name: root.result ? root.result.icon : ""
                        size: Theme.iconSizeSmall
                        color: root.result ? root.toneColor(root.result.tone) : Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    StyledText {
                        text: root.result ? root.result.text + " · " + root.clock(root.result.secs) : ""
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeMedium
                    }
                }

                StyledText {
                    visible: !root.running && root.result !== null && root.result.tone === "error"
                    width: parent.width - Theme.spacingS * 2
                    wrapMode: Text.WordWrap
                    text: "It failed or was cancelled; the terminal or Omni Settings has the log."
                    color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall
                }

                StyledRect {
                    visible: !root.running && root.result !== null
                    width: dismissText.implicitWidth + Theme.spacingM * 2
                    height: 30
                    radius: Theme.cornerRadius
                    color: Theme.chipSurface

                    StyledText {
                        id: dismissText
                        anchors.centerIn: parent
                        text: "Dismiss"
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    StateLayer {
                        anchors.fill: parent
                        onClicked: {
                            root.result = null;
                            if (pop.closePopout)
                                pop.closePopout();
                        }
                    }
                }
            }
        }
    }
}
