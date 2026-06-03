pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs

Item {
    id: root

    required property bool btEnabled
    required property list<var> btDevices
    signal connectRequested(string mac)
    signal disconnectRequested(string mac)
    signal togglePowerRequested()

    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right }
        spacing: 12

        // ── Header ───────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: String.fromCodePoint(0xF00AF) + "  Bluetooth"
                font.pixelSize: 18
                font.family: Theme.font
                font.bold: true
                color: Theme.mmry
            }
            Item { Layout.fillWidth: true }

            Rectangle {
                width: btToggleLbl.width + 24
                height: btToggleLbl.height + 10
                radius: Theme.radius
                color: root.btEnabled ? Theme.mmry : Theme.sptr
                border.color: Theme.acct
                border.width: 2
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    id: btToggleLbl
                    anchors.centerIn: parent
                    text: root.btEnabled
                        ? String.fromCodePoint(0xF00AF) + "  BT ON"
                        : String.fromCodePoint(0xF00B2) + "  BT OFF"
                    font.pixelSize: 13
                    font.family: Theme.font
                    color: Theme.bgnd
                }
                MouseArea { anchors.fill: parent; onClicked: root.togglePowerRequested() }
            }
        }

        // ── Device list ───────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: Math.min(Math.max(btList.contentHeight, 36), 160)
            color: "transparent"
            clip: true
            visible: root.btEnabled

            ListView {
                id: btList
                anchors.fill: parent
                model: root.btDevices
                spacing: 4
                clip: true

                delegate: Rectangle {
                    id: btItem
                    required property var modelData
                    required property int index

                    width: btList.width
                    height: btRow.implicitHeight + 14
                    radius: Theme.radius
                    color: "transparent"
                    border.color: modelData.connected ? Theme.mmry : "transparent"
                    border.width: 1

                    RowLayout {
                        id: btRow
                        anchors {
                            left: parent.left; right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 12; rightMargin: 12
                        }
                        spacing: 8

                        Text {
                            text: btItem.modelData.connected
                                ? String.fromCodePoint(0xF00B1)
                                : String.fromCodePoint(0xF00B2)
                            font.pixelSize: 16
                            font.family: Theme.font
                            color: btItem.modelData.connected ? Theme.mmry : Theme.txt2
                        }

                        Text {
                            text: btItem.modelData.name
                            font.pixelSize: 14
                            font.family: Theme.font
                            font.bold: btItem.modelData.connected
                            color: btItem.modelData.connected ? Theme.mmry : Theme.txt1
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            width: 90
                            height: btBtnLbl.height + 8
                            radius: Theme.radius
                            color: btItem.modelData.connected ? Theme.bat5 : Theme.bgnd
                            border.color: btItem.modelData.connected ? Theme.bat5 : Theme.acct
                            border.width: 1

                            Text {
                                id: btBtnLbl
                                anchors.centerIn: parent
                                text: btItem.modelData.connected ? "disconnect" : "connect"
                                font.pixelSize: 12
                                font.family: Theme.font
                                color: btItem.modelData.connected ? Theme.txt1 : Theme.txt2
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: btItem.modelData.connected
                                    ? root.disconnectRequested(btItem.modelData.mac)
                                    : root.connectRequested(btItem.modelData.mac)
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.btDevices.length === 0
                    text: "No paired devices"
                    font.pixelSize: 13
                    font.family: Theme.font
                    color: Theme.txt2
                }
            }
        }

        Text {
            visible: !root.btEnabled
            text: String.fromCodePoint(0xF00B2) + "  Bluetooth is disabled"
            font.pixelSize: 14
            font.family: Theme.font
            color: Theme.txt2
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
