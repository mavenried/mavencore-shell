pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property real cpu: 0
    property real ram: 0

    Process {
        id: cpuProc
        command: ["mavencore", "cpu"]
        stdout: StdioCollector {
            onStreamFinished: root.cpu = parseFloat(this.text.trim())
        }
    }

    Process {
        id: ramProc
        command: ["mavencore", "memory"]
        stdout: StdioCollector {
            onStreamFinished: root.ram = parseFloat(this.text.trim())
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuProc.running = false;
            cpuProc.running = true;
            ramProc.running = false;
            ramProc.running = true;
        }
    }
}
