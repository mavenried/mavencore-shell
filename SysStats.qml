pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property real cpu: 0
    property real ram: 0
    property var diskValues: ({})

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

    Process {
        id: diskProc
        command: ["sh", "-c", Conf.diskPaths.map(p => "mavencore disk '" + p + "'").join(";")]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n").filter(l => l.trim());
                var vals = {};
                for (var i = 0; i < lines.length && i < Conf.diskPaths.length; i++) {
                    var v = parseFloat(lines[i].trim());
                    if (!isNaN(v))
                        vals[Conf.diskPaths[i]] = v / 100;
                }
                root.diskValues = vals;
            }
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
            diskProc.running = false;
            diskProc.running = true;
        }
    }
}
