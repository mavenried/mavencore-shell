pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs

Rectangle {
    id: root
    color: "#1c1c1c"
    radius: Theme.radius
    border.color: Theme.sptr
    border.width: 1

    property string iface: "wlan0"
    property real rxSpeed: 0
    property real txSpeed: 0
    property real rxPrev: -1
    property real txPrev: -1
    property real prevTime: 0

    function formatSpeed(bps) {
        if (bps >= 1048576) return (bps / 1048576).toFixed(1) + " MB/s"
        if (bps >= 1024)    return (bps / 1024).toFixed(0)    + " KB/s"
        return "0 KB/s"
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { netProc.running = false; netProc.running = true }
    }

    Process {
        id: netProc
        command: ["sh", "-c", "grep '" + root.iface + ":' /proc/net/dev | awk '{print $2, $10}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = this.text.trim().split(/\s+/)
                if (parts.length < 2) return
                var rx = parseFloat(parts[0])
                var tx = parseFloat(parts[1])
                var now = Date.now()
                if (root.rxPrev >= 0 && root.prevTime > 0) {
                    var dt = (now - root.prevTime) / 1000
                    if (dt > 0) {
                        root.rxSpeed = Math.max(0, (rx - root.rxPrev) / dt)
                        root.txSpeed = Math.max(0, (tx - root.txPrev) / dt)
                    }
                }
                root.rxPrev = rx
                root.txPrev = tx
                root.prevTime = now
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        Text {
            text: "Network"
            color: Theme.txt1
            font.pixelSize: 15
            font.bold: true
            font.family: Theme.font
        }

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "↓  " + root.iface
                color: Theme.wifi
                font.pixelSize: 13
                font.family: Theme.font
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.formatSpeed(root.rxSpeed)
                color: Theme.wifi
                font.pixelSize: 13
                font.family: Theme.font
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "↑  " + root.iface
                color: Theme.uptm
                font.pixelSize: 13
                font.family: Theme.font
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.formatSpeed(root.txSpeed)
                color: Theme.uptm
                font.pixelSize: 13
                font.family: Theme.font
            }
        }

        Item { Layout.fillHeight: true }
    }
}
