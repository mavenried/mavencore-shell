pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs

WidgetCard {
    id: root

    required property string phase       // "idle" | "work" | "break" | "longBreak"
    required property bool   paused
    required property int    secondsLeft
    required property int    totalSeconds
    required property int    sessions

    signal startPauseClicked
    signal resetClicked
    signal skipClicked

    readonly property color phaseColor: {
        if (phase === "work")       return "#ba8baf"
        if (phase === "break")      return "#59cd90"
        if (phase === "longBreak")  return "#7cafc2"
        return "#585b70"
    }

    readonly property string phaseLabel: {
        if (phase === "work")      return paused ? "PAUSED" : "WORK"
        if (phase === "break")     return "BREAK"
        if (phase === "longBreak") return "LONG BREAK"
        return "POMODORO"
    }

    readonly property string iconPlay:  String.fromCodePoint(0xF04B)
    readonly property string iconPause: String.fromCodePoint(0xF04C)
    readonly property string iconReset: String.fromCodePoint(0xF0E2)
    readonly property string iconSkip:  String.fromCodePoint(0xF050)

    function fmtTime(s) {
        var m = Math.floor(s / 60)
        return m.toString().padStart(2, "0") + ":" + (s % 60).toString().padStart(2, "0")
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // Progress ring + overlay text
        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 130
            implicitHeight: 130

            Canvas {
                id: arc
                anchors.fill: parent

                readonly property real progress: root.totalSeconds > 0
                    ? root.secondsLeft / root.totalSeconds : 1.0
                property string phase: root.phase

                onProgressChanged: requestPaint()
                onPhaseChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    var cx = width / 2, cy = height / 2, r = cx - 9
                    var start = -Math.PI / 2

                    ctx.beginPath()
                    ctx.arc(cx, cy, r, 0, 2 * Math.PI)
                    ctx.strokeStyle = Theme.bgnd3.toString()
                    ctx.lineWidth = 8
                    ctx.stroke()

                    if (progress > 0.001) {
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, start, start + progress * 2 * Math.PI)
                        ctx.strokeStyle = root.phaseColor
                        ctx.lineWidth = 8
                        ctx.lineCap = "round"
                        ctx.stroke()
                    }
                }

                Component.onCompleted: requestPaint()
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.fmtTime(root.secondsLeft)
                    color: Theme.txt1
                    font.pixelSize: 24
                    font.bold: true
                    font.family: Theme.font
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.phaseLabel
                    color: root.phaseColor
                    font.pixelSize: 10
                    font.family: Theme.font
                }
            }
        }

        // Session dots — filled = completed sessions in current set of 4
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8
            Repeater {
                model: 4
                Rectangle {
                    required property int index
                    width: 8; height: 8; radius: 4
                    color: {
                        if (root.phase === "longBreak") return root.phaseColor
                        return (root.sessions % 4) > index ? root.phaseColor : Theme.bgnd3
                    }
                }
            }
        }

        // Controls
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 24

            Text {
                text: root.iconReset
                color: Theme.txt2
                font.pixelSize: 16; font.family: Theme.font
                verticalAlignment: Text.AlignVCenter
                MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: root.resetClicked() }
            }

            Text {
                text: (root.phase === "idle" || root.paused) ? root.iconPlay : root.iconPause
                color: root.phaseColor
                font.pixelSize: 22; font.family: Theme.font
                verticalAlignment: Text.AlignVCenter
                MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: root.startPauseClicked() }
            }

            Text {
                text: root.iconSkip
                color: Theme.txt2
                font.pixelSize: 16; font.family: Theme.font
                verticalAlignment: Text.AlignVCenter
                MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: root.skipClicked() }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
