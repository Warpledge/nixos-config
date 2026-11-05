// A command box with history (up and down arrows)
import QtQuick
import QtQuick.Layouts

Field {
    id: box
    property var app
    property var history: []
    property int back: -1
    icon: "chevron_right"
    placeholder: "Enter a command"
    onAccepted: {
        const text = input.text.trim()
        if (!text)
            return
        app.send(text)
        history = [text].concat(history.filter(h => h !== text)).slice(0, 100)
        back = -1
        input.text = ""
    }
    //--- A one-line TextInput passes these up to here
    Keys.onUpPressed: {
        if (back + 1 < history.length)
            input.text = history[++back]
    }
    Keys.onDownPressed: {
        back = Math.max(-1, back - 1)
        input.text = back >= 0 ? history[back] : ""
    }
}
