pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool active: false

    Process {
        id: proc
        command: ["sh", "-c", "cat /sys/class/leds/*capslock/brightness 2>/dev/null | head -1"]
        stdout: StdioCollector {
            onStreamFinished: root.active = this.text.trim() === "1"
        }
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            proc.running = false;
            proc.running = true;
        }
    }
}
