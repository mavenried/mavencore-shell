pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs
import "../network" as NetworkComponents

WidgetCard {
    id: root

    property string pendingSsid: ""
    property string pendingBssid: ""
    property bool connecting: false
    property string statusMessage: ""

    function connectTo(modelData) {
        root.pendingSsid = modelData.ssid;
        root.pendingBssid = modelData.bssid || "";
        root.connecting = true;
        Network.connectToNetworkWithPasswordCheck(modelData.ssid, modelData.security && modelData.security !== "--", result => {
            root.connecting = false;
            if (result.needsPassword) {
                passwordPopup.visible = true;
                return;
            }
            root.statusMessage = result.success ? "Connected" : (result.error || "Connection failed");
            root.pendingSsid = "";
            statusTimer.restart();
        }, root.pendingBssid);
    }

    Timer {
        id: statusTimer
        interval: 3000
        onTriggered: root.statusMessage = ""
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: String.fromCodePoint(0xF05A9) + "  WiFi"
                color: Theme.txt1
                font.pixelSize: 20
                font.bold: true
                font.family: Theme.font
            }
            Item {
                Layout.fillWidth: true
            }
            // Text {
            //     text: Network.active ? Network.active.ssid : "Offline"
            //     color: Network.active ? Theme.mmry : Theme.txt2
            //     font.pixelSize: 13
            //     font.family: Theme.font
            //     elide: Text.ElideRight
            //     Layout.maximumWidth: 110
            // }


            Rectangle {
                width: 60
                height: 27
                radius: Theme.radius
                color: Network.wifiEnabled ? Theme.mmry : Theme.sptr
                Text {
                    anchors.centerIn: parent
                    text: Network.wifiEnabled ? "on" : "off"
                    color: Theme.bgnd
                    font.pixelSize: 13
                    font.family: Theme.font
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: Network.toggleWifi(() => {})
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: networkList
                anchors.fill: parent
                model: Network.networks
                spacing: 2
                clip: true
                delegate: Rectangle {
                    required property var modelData
                    width: networkList.width
                    height: 28
                    radius: Theme.radius
                    color: modelData.active ? Qt.rgba(0.35, 0.8, 0.56, 0.12) : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 4
                        spacing: 5
                        Text {
                            text: modelData.active ? String.fromCodePoint(0xF0928) : String.fromCodePoint(0xF0922)
                            color: modelData.active ? Theme.mmry : Theme.txt2
                            font.pixelSize: 13
                            font.family: Theme.font
                        }
                        Text {
                            text: modelData.ssid
                            color: modelData.active ? Theme.mmry : Theme.txt1
                            font.pixelSize: 13
                            font.family: Theme.font
                            font.bold: modelData.active
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: modelData.strength + "%"
                            color: Theme.txt2
                            font.pixelSize: 12
                            font.family: Theme.font
                        }
                        Rectangle {
                            width: 52
                            height: 22
                            radius: Theme.radius
                            color: modelData.active ? Theme.mmry : Theme.bgnd
                            border.color: Theme.sptr
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: modelData.active ? "dcnt" : "cnt"
                                color: modelData.active ? Theme.bg : Theme.txt2
                                font.pixelSize: 12
                                font.family: Theme.font
                            }
                            MouseArea {
                                anchors.fill: parent
                                enabled: !root.connecting
                                onClicked: {
                                    if (modelData.active) {
                                        const iface = Network.wirelessInterfaces.length > 0 ? Network.wirelessInterfaces[0].device : "";
                                        Network.disconnect(iface, result => {
                                            root.statusMessage = result.success ? "Disconnected" : (result.error || "Disconnect failed");
                                            statusTimer.restart();
                                        });
                                    } else {
                                        root.connectTo(modelData);
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Text {
                anchors.centerIn: parent
                visible: Network.networks.length === 0
                text: Network.wifiEnabled ? "No networks found" : "Wi-Fi is disabled"
                color: Theme.txt2
                font.pixelSize: 13
                font.family: Theme.font
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root.statusMessage.length > 0
            text: root.statusMessage
            color: root.statusMessage.includes("failed") ? Theme.bat5 : Theme.mmry
            font.pixelSize: 12
            font.family: Theme.font
            elide: Text.ElideRight
        }
    }

    NetworkComponents.PasswordPopup {
        id: passwordPopup
        anchors.fill: parent
        z: 2
        ssid: root.pendingSsid
        onPasswordAccepted: function (password) {
            visible = false;
            root.connecting = true;
            Network.connectToNetwork(root.pendingSsid, password, root.pendingBssid, result => {
                root.connecting = false;
                root.statusMessage = result.success ? "Connected" : (result.error || "Connection failed");
                root.pendingSsid = "";
                statusTimer.restart();
            });
        }
        onDismissed: {
            visible = false;
            root.pendingSsid = "";
        }
    }
}
