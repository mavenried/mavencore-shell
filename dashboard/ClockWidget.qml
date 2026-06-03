pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs

Rectangle {
    id: root
    color: "#1c1c1c"
    radius: Theme.radius
    border.color: Theme.sptr
    border.width: 1

    property string uptimeStr: ""

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Process {
        id: uptimeProc
        command: ["mavencore", "uptime"]
        stdout: StdioCollector {
            onStreamFinished: root.uptimeStr = this.text.trim()
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { uptimeProc.running = false; uptimeProc.running = true }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 4

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatTime(clock.date, "hh:mm")
            color: Theme.txt1
            font.pixelSize: 68
            font.bold: true
            font.family: Theme.font
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDate(clock.date, "dddd, MMMM d")
            color: Theme.txt2
            font.pixelSize: 14
            font.family: Theme.font
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: String.fromCodePoint(0xF102) + " " + root.uptimeStr
            color: Theme.uptm
            font.pixelSize: 13
            font.family: Theme.font
            visible: root.uptimeStr !== ""
        }
    }
}
