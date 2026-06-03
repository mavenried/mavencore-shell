pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs

Item {
    id: root

    required property bool connecting
    required property string pendingSsid
    required property string statusMessage

    signal connectRequested(string ssid, string bssid, bool secure)
    signal disconnectRequested

    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        anchors {
            left: parent.left
            right: parent.right
        }
        spacing: 12

        // ── Header ───────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: String.fromCodePoint(0xF05A9) + "  Network"
                font.pixelSize: 18
                font.family: Theme.font
                font.bold: true
                color: Theme.mmry
            }
            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                width: wifiToggleLbl.width + 24
                height: wifiToggleLbl.height + 10
                radius: Theme.radius
                color: Network.wifiEnabled ? Theme.mmry : Theme.sptr
                border.color: Theme.acct
                border.width: 2
                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }

                Text {
                    id: wifiToggleLbl
                    anchors.centerIn: parent
                    text: Network.wifiEnabled ? String.fromCodePoint(0xF05A9) + "  Wi-Fi ON" : String.fromCodePoint(0xF05AA) + "  Wi-Fi OFF"
                    font.pixelSize: 13
                    font.family: Theme.font
                    color: Theme.bgnd
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: Network.toggleWifi(cb => {})
                }
            }

            Rectangle {
                width: 120
                height: scanLbl.height + 10
                radius: Theme.radius
                color: Theme.bgnd
                border.color: Network.scanning ? Theme.mmry : Theme.acct
                border.width: 2

                Text {
                    id: scanLbl
                    anchors.centerIn: parent
                    text: Network.scanning ? String.fromCodePoint(0xF0450) + "  scanning" + String.fromCodePoint(0x2026) : String.fromCodePoint(0xF0450) + "  scan"
                    font.pixelSize: 13
                    font.family: Theme.font
                    color: Network.scanning ? Theme.mmry : Theme.txt2
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: !Network.scanning
                    onClicked: Network.rescanWifi()
                }
            }
        }

        // ── Status message ────────────────────────────────────────────
        Text {
            visible: root.statusMessage.length > 0
            text: root.statusMessage
            font.pixelSize: 13
            font.family: Theme.font
            color: root.statusMessage.startsWith(String.fromCodePoint(0x2717)) ? Theme.bat5 : Theme.bat1
            Layout.fillWidth: true
        }

        // ── Network list ──────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: Math.min(wifiList.contentHeight, 220)
            color: "transparent"
            visible: Network.wifiEnabled
            clip: true

            ListView {
                id: wifiList
                anchors.fill: parent
                model: Network.networks
                spacing: 4
                clip: true

                delegate: Rectangle {
                    id: netItem
                    required property var modelData
                    required property int index

                    width: wifiList.width
                    height: netRow.implicitHeight + 14
                    radius: Theme.radius
                    color: "transparent"
                    border.color: modelData.active ? Theme.mmry : "transparent"
                    border.width: 1
                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }

                    RowLayout {
                        id: netRow
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 12
                            rightMargin: 12
                        }
                        spacing: 8

                        Text {
                            text: {
                                const s = netItem.modelData.strength;
                                if (s >= 75)
                                    return String.fromCodePoint(0xF0928);
                                if (s >= 50)
                                    return String.fromCodePoint(0xF0925);
                                if (s >= 25)
                                    return String.fromCodePoint(0xF0922);
                                return String.fromCodePoint(0xF091F);
                            }
                            font.pixelSize: 16
                            font.family: Theme.font
                            color: netItem.modelData.active ? Theme.mmry : Theme.txt2
                        }

                        Text {
                            text: netItem.modelData.ssid
                            font.pixelSize: 14
                            font.family: Theme.font
                            font.bold: netItem.modelData.active
                            color: netItem.modelData.active ? Theme.mmry : Theme.txt1
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: Network.hasSavedProfile(netItem.modelData.ssid) && !netItem.modelData.active
                            text: String.fromCodePoint(0xF012C)
                            font.pixelSize: 12
                            font.family: Theme.font
                            color: Theme.bat1
                        }

                        Text {
                            visible: netItem.modelData.security && netItem.modelData.security !== "--" && netItem.modelData.security.length > 0
                            text: String.fromCodePoint(0xF033E)
                            font.pixelSize: 12
                            font.family: Theme.font
                            color: Theme.txt2
                        }

                        Text {
                            text: netItem.modelData.strength + "%"
                            font.pixelSize: 12
                            font.family: Theme.font
                            color: Theme.txt2
                            width: 36
                            horizontalAlignment: Text.AlignRight
                        }

                        Rectangle {
                            width: 90
                            height: btnLbl.height + 8
                            radius: Theme.radius
                            color: netItem.modelData.active ? Theme.bat5 : root.connecting && root.pendingSsid === netItem.modelData.ssid ? Theme.sptr : Theme.bgnd
                            border.color: netItem.modelData.active ? Theme.bat5 : Theme.acct
                            border.width: 1
                            Behavior on color {
                                ColorAnimation {
                                    duration: 100
                                }
                            }

                            Text {
                                id: btnLbl
                                anchors.centerIn: parent
                                text: netItem.modelData.active ? "disconnect" : root.connecting && root.pendingSsid === netItem.modelData.ssid ? "connecting" + String.fromCodePoint(0x2026) : "connect"
                                font.pixelSize: 12
                                font.family: Theme.font
                                color: netItem.modelData.active ? Theme.txt1 : Theme.txt2
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: !root.connecting
                                onClicked: {
                                    if (netItem.modelData.active) {
                                        root.disconnectRequested();
                                    } else {
                                        const secure = netItem.modelData.security && netItem.modelData.security !== "--" && netItem.modelData.security.length > 0;
                                        root.connectRequested(netItem.modelData.ssid, netItem.modelData.bssid || "", secure);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Text {
            visible: !Network.wifiEnabled
            text: String.fromCodePoint(0xF05AA) + "  Wi-Fi is disabled"
            font.pixelSize: 14
            font.family: Theme.font
            color: Theme.txt2
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
