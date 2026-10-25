// omni-settings-backend (src/api.py): one process per command, its JSON reply to `done`
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: backend

    readonly property string bin: Config.backend

    //--- A `--serve` backend answers in a few ms, as it has its imports done; it stops
    //--- after 5 idle minutes, and calls while it's down run as their own process
    property int lastId: 0
    property var waiting: ({})  // request id -> done; changed in place
    function call(cmd, args, done) {
        if (!server.up) {
            server.running = true
            spawn(cmd, args, done)
            return
        }
        idle.restart()
        const id = ++lastId
        waiting[id] = done || null
        server.write(JSON.stringify({ id, cmd, args: args || {} }) + "\n")
    }

    function answer(line) {
        let msg
        try {
            msg = JSON.parse(line)
        } catch (e) {
            return
        }
        const done = waiting[msg.id]
        delete waiting[msg.id]
        if (done)
            done(msg.reply)
    }

    Process {
        id: server
        property bool up: false
        command: [backend.bin, "--serve"]
        stdinEnabled: true
        stdout: SplitParser { onRead: line => backend.answer(line) }
        onStarted: {
            up = true
            idle.restart()
        }
        onExited: {
            up = false
            const lost = backend.waiting
            backend.waiting = {}
            for (const id in lost)
                if (lost[id])
                    lost[id]({ ok: false, error: "omni-settings-backend stopped" })
        }
    }

    Timer {
        id: idle
        interval: 300000
        onTriggered: {
            if (Object.keys(backend.waiting).length)
                restart()
            else
                server.running = false
        }
    }

    function spawn(cmd, args, done) {
        const p = runner.createObject(backend, {
            command: [bin, cmd, JSON.stringify(args || {})],
            done: done || null
        })
        p.running = true
    }

    //--- As call(), with each line the command prints to stderr given to onLine
    function stream(cmd, args, onLine, done) {
        const p = streamer.createObject(backend, {
            command: [bin, cmd, JSON.stringify(args || {})],
            done: done || null,
            each: onLine
        })
        p.running = true
    }

    Component {
        id: streamer
        Process {
            id: sproc
            property var done
            property var each  // not onLine: QML reads on<Capital> names as handlers
            property var last: []  // stderr's last lines, for a reply that never came
            stderr: SplitParser {
                onRead: line => {
                    sproc.last = sproc.last.slice(-5).concat([line])
                    sproc.each(line)
                }
            }
            stdout: StdioCollector {
                onStreamFinished: {
                    let reply
                    try {
                        reply = JSON.parse(text)
                    } catch (e) {
                        reply = { ok: false, error: "omni-settings-backend gave no answer\n\n" + sproc.last.join("\n") }
                    }
                    if (sproc.done)
                        sproc.done(reply)
                    sproc.destroy()
                }
            }
        }
    }

    Component {
        id: runner
        Process {
            id: proc
            property var done
            stdout: StdioCollector {
                onStreamFinished: {
                    let reply
                    try {
                        reply = JSON.parse(text)
                    } catch (e) {
                        reply = { ok: false, error: err.text.trim() || "omni-settings-backend gave no answer" }
                    }
                    if (proc.done)
                        proc.done(reply)
                    proc.destroy()
                }
            }
            stderr: StdioCollector { id: err }
        }
    }
}
