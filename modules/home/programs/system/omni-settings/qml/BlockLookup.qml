// Was This Blocked?, under Ad & Tracker Blocking: which of the lists this build
// blocks hold a domain, and whether /etc/hosts blocks it now (api.py's blockLookup)
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: lookup
    property var found: null  // {domain, lists, allowed, blocked, enabled}
    property string error: ""
    property bool busy: false
    spacing: 6

    function check() {
        if (!field.text.trim())
            return
        busy = true
        Backend.call("blockLookup", { domain: field.text }, reply => {
            if (!lookup)
                return
            busy = false
            found = reply.ok ? reply.data : null
            error = reply.ok ? "" : reply.error
        })
    }

    function verdict() {
        if (!found)
            return ""
        if (found.blocked)
            return found.lists.length ? `Blocked by ${found.lists.join(", ")}` : "Blocked on this computer"
        if (found.allowed)
            return "Let through by Never Block"
        if (found.lists.length)
            return `On ${found.lists.join(", ")}, not blocked until Apply`
        return found.enabled ? "Not on any list" : "Not blocked: blocking is off"
    }

    Section {
        text: "Was This Blocked?"
        info: "Looks a domain up in the lists this computer blocks. Pending changes above show up "
              + "after Apply."
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Field {
            id: field
            Layout.fillWidth: true
            icon: "search"
            placeholder: "example.com"
            onAccepted: lookup.check()
        }
        Pill { text: lookup.busy ? "Looking…" : "Look Up"; enabled: !lookup.busy; onClicked: lookup.check() }
    }
    ListRow {
        visible: !!lookup.found || lookup.error !== ""
        icon: lookup.found && lookup.found.blocked ? "block" : "check_circle"
        tone: lookup.error ? "" : lookup.found && lookup.found.blocked ? "caution" : "success"
        title: lookup.found ? lookup.found.domain : "Couldn't look it up"
        subtitle: lookup.verdict()
        alert: lookup.error
    }
}
