import QtQuick
import Quickshell.Io

Item {
    id: root
    required property list<string> command
    property int interval: 2000
    signal received(string data)

    width: 0
    height: 0
    visible: false

    Process {
        id: proc
        command: root.command
        stdout: StdioCollector {
            onStreamFinished: root.received(this.text.trim())
        }
    }

    Timer {
        interval: root.interval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            proc.running = false;
            proc.running = true;
        }
    }
}
