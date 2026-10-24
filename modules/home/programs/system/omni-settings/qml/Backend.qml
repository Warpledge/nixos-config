// omni-settings-backend (src/api.py): one process per command, its JSON reply to `done`
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: backend

    readonly property string bin: Quickshell.env("OMNI_SETTINGS_BACKEND") || "omni-settings-backend"

    function call(cmd, args, done) {
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
