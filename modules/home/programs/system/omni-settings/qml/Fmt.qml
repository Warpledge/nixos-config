// Dates and sizes as the pages word them
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property var months: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep",
                                   "Oct", "Nov", "Dec"]

    function pad(n) { return String(n).padStart(2, "0") }

    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth()
            && a.getDate() === b.getDate()
    }

    //--- "Today, 01:55", "Yesterday, 18:20" or "14 Oct, 09:12"
    function when(epoch) {
        const t = new Date(epoch * 1000)
        const today = new Date()
        const yesterday = new Date(today.getTime() - 86400000)
        const clock = `${pad(t.getHours())}:${pad(t.getMinutes())}`
        if (sameDay(t, today))
            return `Today, ${clock}`
        if (sameDay(t, yesterday))
            return `Yesterday, ${clock}`
        return `${t.getDate()} ${months[t.getMonth()]}, ${clock}`
    }

    function day(epoch) {
        if (!epoch)
            return "?"
        const t = new Date(epoch * 1000)
        return `${t.getDate()} ${months[t.getMonth()]} ${t.getFullYear()}`
    }

    function ago(epoch) {
        if (!epoch)
            return "unknown"
        const days = Math.floor((Date.now() / 1000 - epoch) / 86400)
        if (days <= 0)
            return "today"
        if (days === 1)
            return "yesterday"
        if (days < 14)
            return `${days} days ago`
        if (days < 60)
            return `${Math.floor(days / 7)} weeks ago`
        return `${Math.floor(days / 30)} months ago`
    }

    function size(n, signed) {
        if (n === null || n === undefined)
            return ""
        const sign = signed ? (n > 0 ? "+" : n < 0 ? "−" : "") : ""
        let v = Math.abs(n)
        const units = ["B", "KiB", "MiB", "GiB", "TiB"]
        let i = 0
        while (v >= 1024 && i < units.length - 1) {
            v /= 1024
            i++
        }
        return `${sign}${v.toFixed(i ? 1 : 0)} ${units[i]}`
    }
}
