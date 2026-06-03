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

    property list<string> diskPaths: ["/"]

    property real cpuPct: 0
    property real ramPct: 0
    property var diskValues: ({})

    // Same codepoints as the bar (SysInfo.qml)
    readonly property string iconCpu:  String.fromCodePoint(0xF4BC)
    readonly property string iconRam:  String.fromCodePoint(0xEFC5)
    readonly property string iconDisk: String.fromCodePoint(0xF02CA)

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuProc.running = false; cpuProc.running = true
            ramProc.running = false; ramProc.running = true
            dskProc.running = false; dskProc.running = true
        }
    }

    Process {
        id: cpuProc
        command: ["mavencore", "cpu"]
        stdout: StdioCollector {
            onStreamFinished: root.cpuPct = parseFloat(this.text.trim()) / 100
        }
    }

    Process {
        id: ramProc
        command: ["mavencore", "memory"]
        stdout: StdioCollector {
            onStreamFinished: root.ramPct = parseFloat(this.text.trim()) / 100
        }
    }

    // Run all disk checks in one shell invocation; SplitParser fires once per line
    Process {
        id: dskProc
        property int parseIdx: 0
        command: ["sh", "-c", root.diskPaths.map(p => "mavencore disk '" + p + "'").join(";")]
        onRunningChanged: if (running) parseIdx = 0
        stdout: SplitParser {
            onRead: function(line) {
                var v = parseFloat(line.trim())
                if (isNaN(v) || dskProc.parseIdx >= root.diskPaths.length) return
                var path = root.diskPaths[dskProc.parseIdx++]
                var vals = Object.assign({}, root.diskValues)
                vals[path] = v / 100
                root.diskValues = vals
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        Text {
            text: "System"
            color: Theme.txt1
            font.pixelSize: 15
            font.bold: true
            font.family: Theme.font
        }

        StatBar { label: root.iconCpu + " CPU";  pct: root.cpuPct;  barColor: Theme.cpuc }
        StatBar { label: root.iconRam + " RAM";  pct: root.ramPct;  barColor: Theme.mmry }

        Repeater {
            model: root.diskPaths
            delegate: StatBar {
                required property string modelData
                label: root.iconDisk + " " + (modelData === "/" ? "/" : modelData.split("/").filter(Boolean).pop().toUpperCase())
                pct: root.diskValues[modelData] ?? 0
                barColor: Theme.disk
            }
        }

        Item { Layout.fillHeight: true }
    }

    component StatBar: ColumnLayout {
        id: sb
        required property string label
        required property real pct
        required property color barColor
        spacing: 5
        Layout.fillWidth: true

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: sb.label
                color: sb.barColor
                font.pixelSize: 13
                font.family: Theme.font
            }
            Item { Layout.fillWidth: true }
            Text {
                text: Math.round(sb.pct * 100) + "%"
                color: sb.barColor
                font.pixelSize: 13
                font.family: Theme.font
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 6
            radius: 3
            color: "#2a2a2a"
            Rectangle {
                width: parent.width * sb.pct
                height: parent.height
                radius: parent.radius
                color: sb.barColor
                Behavior on width {
                    NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
                }
            }
        }
    }
}
