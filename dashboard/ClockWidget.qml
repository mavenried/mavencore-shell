pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

WidgetCard {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
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
            text: String.fromCodePoint(0xF102) + " " + Uptime.text
            color: Theme.uptm
            font.pixelSize: 13
            font.family: Theme.font
            visible: Uptime.text !== ""
        }
    }
}
