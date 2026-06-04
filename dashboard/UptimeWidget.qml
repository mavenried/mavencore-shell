pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

WidgetCard {
    id: root

    RowLayout {
        anchors.fill: parent
        spacing: 20
        Item {
            Layout.fillWidth: parent
        }
        ColumnLayout {
            spacing: 4
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: String.fromCodePoint(0xF102)
                color: Theme.uptm
                font.pixelSize: 64
                font.family: Theme.font
                visible: Uptime.text !== ""
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "UPTIME"
                color: Theme.uptm
                font.pixelSize: 16
                font.family: Theme.font
                visible: Uptime.text !== ""
            }
        }
        Item {
            Layout.fillWidth: parent
        }
        ColumnLayout {
            spacing: 4

            Text {
                Layout.alignment: Qt.AlignLeft

                text: {
                    Uptime.text.split(':')[0] + " days";
                }
                color: Theme.uptm
                font.pixelSize: 24
                font.family: Theme.font
                visible: Uptime.text !== ""
            }

            Text {
                Layout.alignment: Qt.AlignLeft
                text: {
                    Uptime.text.split(':')[1] + " hour";
                }
                color: Theme.uptm
                font.pixelSize: 24
                font.family: Theme.font
                visible: Uptime.text !== ""
            }

            Text {
                Layout.alignment: Qt.AlignLeft
                text: {
                    Uptime.text.split(':')[2] + " mins";
                }
                color: Theme.uptm
                font.pixelSize: 24
                font.family: Theme.font
                visible: Uptime.text !== ""
            }

            Text {
                Layout.alignment: Qt.AlignLeft
                text: {
                    Uptime.text.split(':')[3] + " secs";
                }
                color: Theme.uptm
                font.pixelSize: 24
                font.family: Theme.font
                visible: Uptime.text !== ""
            }
        }
        Item {
            Layout.fillWidth: parent
        }
    }
}
