import QtQuick

QtObject {
    id: root
    property bool open: false
    property int closeDelay: 300
    property var loader: null

    function toggle() { _setOpen(!open) }
    function setOpen(v) { _setOpen(v) }

    function _setOpen(v) {
        open = v
        if (loader) loader.active = true
        if (!v) _closeTimer.start()
    }

    property Timer _closeTimer: Timer {
        interval: root.closeDelay
        onTriggered: if (root.loader) root.loader.active = root.open
    }
}
