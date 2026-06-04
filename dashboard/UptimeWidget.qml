pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

WidgetCard {
    id: root

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 4

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: String.fromCodePoint(0xF102) + " " + Uptime.text
            color: Theme.uptm
            font.pixelSize: 32
            font.family: Theme.font
            visible: Uptime.text !== ""
        }
    }
}
