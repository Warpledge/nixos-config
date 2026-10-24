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
