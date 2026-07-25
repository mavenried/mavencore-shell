pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs

Singleton {
    id: root
    property real level: 0
    property real watts: 0
    property string icon: String.fromCodePoint(0xF007E)

    readonly property color levelColor: {
        if (level <= 10)
            return "#ab4642";
        if (level <= 25)
            return "#f7ca88";
        if (level <= 50)
            return "#7cafc2";
        if (level <= 75)
            return "#59cd90";
        return "#a1b56c";
    }

    Process {
        id: levelProc
        command: ["mavencore", "battery", Conf.batteryPath]
        stdout: StdioCollector {
            onStreamFinished: root.level = parseFloat(this.text.trim()) || 0
        }
    }

    Process {
        id: iconProc
        command: ["mavencore", "battery-icon", Conf.batteryPath]
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
            iconProc.running = false;
            iconProc.running = true;
        }
    }
}
