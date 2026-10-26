pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs

WidgetCard {
    id: root

    required property double targetEpoch
    required property string targetDate
    required property bool dashboardOpen

    property double nowEpoch: Date.now() / 1000

    readonly property real secondsRemaining: Math.max(0, targetEpoch - nowEpoch)
    readonly property int secondsLeft: Math.floor(secondsRemaining)
    // readonly property color phaseColor: secondsLeft > 0 ? "#7cafc2" : "#59cd90"
    readonly property color phaseColor: Theme.mmry

    property string countdownName: "TARGET"

    function syncClock() {
        nowEpoch = Date.now() / 1000;
    }

    onDashboardOpenChanged: {
        if (dashboardOpen)
            syncClock();
    }

    Timer {
        interval: 16
        running: root.dashboardOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: root.nowEpoch = Date.now() / 1000
    }

    Component.onCompleted: syncClock()

    function fmtTime(s) {
        var days = Math.floor(s / 86400);
        var hours = Math.floor((s % 86400) / 3600);
        var minutes = Math.floor((s % 3600) / 60);
        if (days > 0)
            return days + "d " + hours.toString().padStart(2, "0") + "h";
        return hours.toString().padStart(2, "0") + ":" + minutes.toString().padStart(2, "0");
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 40
            Item {
                Layout.fillWidth: true
            }

            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 180
                implicitHeight: 180

                Canvas {
                    id: arc
                    anchors.fill: parent
                    readonly property real progress: (root.secondsRemaining % 60) / 60
                    onProgressChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        var cx = width / 2, cy = height / 2, r = cx - 9;
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                        ctx.strokeStyle = Qt.rgba(0, 0, 0, 0.2).toString();
                        ctx.lineWidth = 8;
                        ctx.stroke();
                        if (progress > 0.001) {
                            ctx.beginPath();
                            ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + progress * 2 * Math.PI);
                            ctx.strokeStyle = root.phaseColor;
                            ctx.lineWidth = 8;
                            ctx.lineCap = "round";
                            ctx.stroke();
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
                        text: root.countdownName
                        color: root.phaseColor
                        font.pixelSize: 18
                        font.family: Theme.font
                    }
                }
            }
            ColumnLayout {
                Text {

                    // text: {
                    //     var num = root.targetDate.split(" ")[0];
                    //     var last = num[-1];
                    //     num += "<sup>";
                    //     if (last == "1") {
                    //         num = num + "rd";
                    //     } else if (last == "2") {
                    //         num = num + "nd";
                    //     } else if (last == "3") {
                    //         num = num + "rd";
                    //     } else {
                    //         num = num + "th";
                    //     }

                    //     num += "</sup>";
                    //     return num;
                    // }
                    // textFormat: Text.RichText

                    text: root.targetDate.split(" ")[0]
                    color: Theme.txt2
                    font.pixelSize: 30
                    font.family: Theme.font
                }

                Text {
                    text: root.targetDate.split(" ")[1]
                    color: Theme.txt2
                    font.pixelSize: 30
                    font.family: Theme.font
                }

                Text {
                    text: root.targetDate.split(" ")[2]
                    color: Theme.txt2
                    font.pixelSize: 30
                    font.family: Theme.font
                }
            }
        }
        Item {
            Layout.fillWidth: true
        }
    }
}
