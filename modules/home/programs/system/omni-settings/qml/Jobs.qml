// The job service (src/jobs.py) over its socket: the running job, its log and progress
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: jobs

    property var job: null
    property var progress: null
    property bool shown: false
    readonly property bool running: job !== null && !job.ended
    readonly property alias log: logModel

    property int nextId: 1
    property var waiting: ({})
    property var queue: []
    property int refusals: 0

    //--- A job ended while attached: (job)
    signal ended(var job)

    function request(cmd, args, done) {
        const id = nextId++
        if (done)
            waiting[id] = done
        const line = JSON.stringify({ id, cmd, args: args || {} }) + "\n"
        if (sock.connected) {
            sock.write(line)
            sock.flush()
        } else {
            queue.push(line)
            sock.connected = true
        }
    }

    //--- Requests waiting for a socket that keeps refusing get an error
    function refused() {
        if (++refusals < 3)
            return
        refusals = 0
        for (const line of queue) {
            const done = waiting[JSON.parse(line).id]
            if (done)
                done({ ok: false, error: "The Omni Settings job service isn't running" })
        }
        queue = []
    }

    function start(kind, args, done) {
        // Cleared first: the service can send the new job's first lines before its reply
        logModel.clear()
        progress = null
        request("start", Object.assign({ kind }, args || {}), reply => {
            // A job event may already have brought a newer snapshot
            if (reply.ok && (!job || job.id !== reply.data.id))
                job = reply.data
            if (done)
                done(reply)
        })
    }

    function setShown(on) {
        shown = on
        if (sock.connected)
            request("shown", { shown: on })
    }

    function handle(raw) {
        let msg
        try {
            msg = JSON.parse(raw)
        } catch (e) {
            return
        }
        if (msg.event === "job") {
            const was = job
            job = msg.job
            if (msg.job.ended && (!was || was.id !== msg.job.id || !was.ended))
                ended(msg.job)
        } else if (msg.event === "log") {
            for (const [style, text] of msg.lines)
                logModel.append({ style, text })
            if (logModel.count > 6000)
                logModel.remove(0, logModel.count - 6000)
        } else if (msg.event === "progress") {
            progress = msg.progress
        } else if (msg.id !== undefined && waiting[msg.id]) {
            const done = waiting[msg.id]
            delete waiting[msg.id]
            done(msg)
        }
    }

    ListModel { id: logModel }

    Socket {
        id: sock
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/omni-settings/jobs.sock"
        connected: true
        parser: SplitParser { onRead: data => jobs.handle(data) }
        onError: { jobs.refused(); retry.start() }
        onConnectedChanged: {
            if (!connected) {
                retry.start()
                return
            }
            jobs.refusals = 0
            for (const line of jobs.queue)
                write(line)
            jobs.queue = []
            flush()
            // The service replays the running job's log after this reply
            jobs.request("attach", {}, reply => {
                if (reply.ok) {
                    logModel.clear()
                    jobs.job = reply.data
                }
            })
            jobs.request("shown", { shown: jobs.shown })
        }
    }

    //--- Retry while requests wait; the socket starts the service
    Timer {
        id: retry
        interval: 3000
        onTriggered: if (jobs.queue.length) { sock.connected = false; sock.connected = true }
    }
}
