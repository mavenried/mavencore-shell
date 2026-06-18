import QtQuick
import Quickshell.Io

Item {
    id: root
    required property string path
    property int saveInterval: 1000

    width: 0
    height: 0
    visible: false

    property string pending: ""

    function read() {
        return fv.text();
    }

    function save(content) {
        pending = content;
        saveTimer.restart();
    }

    Component.onDestruction: {
        if (saveTimer.running)
            fv.setText(root.pending);
    }

    FileView {
        id: fv
        path: root.path
        blockLoading: true
    }

    Timer {
        id: saveTimer
        interval: root.saveInterval
        onTriggered: fv.setText(root.pending)
    }
}
