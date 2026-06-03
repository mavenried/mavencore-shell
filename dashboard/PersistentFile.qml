import QtQuick
import Quickshell.Io

Item {
    id: root
    required property string path
    property int saveInterval: 1000

    width: 0
    height: 0
    visible: false

    function read() { return fv.text() }
    function save(text) { _pending = text; _saveTimer.restart() }

    property string _pending: ""

    FileView {
        id: fv
        path: root.path
        blockLoading: true
    }

    Timer {
        id: _saveTimer
        interval: root.saveInterval
        onTriggered: fv.setText(root._pending)
    }
}
