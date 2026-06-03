pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

Rectangle {
    id: root
    color: "#1c1c1c"
    radius: Theme.radius
    border.color: Theme.sptr
    border.width: 1

    property var today: new Date()
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        onDateChanged: root.today = new Date()
    }

    function daysInMonth(y, m) {
        return new Date(y, m + 1, 0).getDate()
    }

    // Monday-first offset: 0=Mon … 6=Sun
    function firstWeekday(y, m) {
        return (new Date(y, m, 1).getDay() + 6) % 7
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        // Month navigation
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "‹"
                color: Theme.txt2
                font.pixelSize: 20
                font.family: Theme.font
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (root.viewMonth === 0) { root.viewMonth = 11; root.viewYear-- }
                        else root.viewMonth--
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: Qt.formatDate(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy")
                color: Theme.txt1
                font.pixelSize: 15
                font.bold: true
                font.family: Theme.font
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "›"
                color: Theme.txt2
                font.pixelSize: 20
                font.family: Theme.font
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (root.viewMonth === 11) { root.viewMonth = 0; root.viewYear++ }
                        else root.viewMonth++
                    }
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 7
            columnSpacing: 2
            rowSpacing: 3

            // Day-of-week headers
            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                Text {
                    required property string modelData
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: Theme.txt2
                    font.pixelSize: 11
                    font.family: Theme.font
                }
            }

            // 6-week grid (42 cells)
            Repeater {
                model: 42
                delegate: Rectangle {
                    required property int index

                    property int day: index - root.firstWeekday(root.viewYear, root.viewMonth) + 1
                    property bool inMonth: day >= 1 && day <= root.daysInMonth(root.viewYear, root.viewMonth)
                    property bool isToday: inMonth
                        && day === root.today.getDate()
                        && root.viewMonth === root.today.getMonth()
                        && root.viewYear === root.today.getFullYear()

                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    radius: 5
                    color: isToday ? Theme.wifi : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: parent.inMonth ? parent.day : ""
                        color: parent.isToday ? Theme.bgnd : parent.inMonth ? Theme.txt1 : "transparent"
                        font.pixelSize: 12
                        font.bold: parent.isToday
                        font.family: Theme.font
                    }
                }
            }
        }
    }
}
