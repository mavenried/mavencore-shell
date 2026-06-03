pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs

Singleton {
    id: root
    property string batteryPath: "/sys/class/power_supply/BAT1"
    property real level: 0
    property real watts: 0
    property string icon: String.fromCodePoint(0xF007E)

    readonly property color levelColor: {
        if (level <= 10)
            return Theme.bat5;
        if (level <= 25)
            return Theme.bat4;
        if (level <= 50)
            return Theme.bat3;
        if (level <= 75)
            return Theme.bat2;
        return Theme.bat1;
    }

    Process {
        id: levelProc
        command: ["mavencore", "battery", root.batteryPath]
        stdout: StdioCollector {
            onStreamFinished: root.level = parseFloat(this.text.trim()) || 0
        }
    }

    Process {
        id: powerProc
        command: ["mavencore", "power", root.batteryPath]
        stdout: StdioCollector {
            onStreamFinished: root.watts = parseFloat(this.text.trim()) || 0
        }
    }

    Process {
        id: iconProc
        command: ["mavencore", "battery-icon", root.batteryPath]
        stdout: StdioCollector {
            onStreamFinished: root.icon = this.text.trim()
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            levelProc.running = false;
            levelProc.running = true;
            powerProc.running = false;
            powerProc.running = true;
            iconProc.running = false;
            iconProc.running = true;
        }
    }
}
