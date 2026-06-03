pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property string text: ""

    Process {
        id: proc
        command: ["mavencore", "uptime"]
        stdout: StdioCollector {
            onStreamFinished: root.text = this.text.trim()
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            proc.running = false;
            proc.running = true;
        }
    }
}
