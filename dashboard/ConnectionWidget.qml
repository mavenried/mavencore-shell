pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs
import "../network" as NetworkComponents

WidgetCard {
    id: root

    property int selectedTab: 0
    property string pendingSsid: ""
    property string pendingBssid: ""
    property bool connecting: false
    property string statusMessage: ""
    property bool bluetoothEnabled: false
    property list<var> btDevices: []

    function refreshBluetooth() {
        btDevicesProc.running = true;
        btPowerProc.running = true;
    }

    function connectWifi(ssid, bssid, secure) {
        root.pendingSsid = ssid;
        root.pendingBssid = bssid;
        root.connecting = true;
        Network.connectToNetworkWithPasswordCheck(ssid, secure, result => {
            root.connecting = false;
            if (result.needsPassword) {
                passwordPopup.visible = true;
                return;
            }
            root.statusMessage = result.success ? "Connected to " + ssid : (result.error || "Connection failed");
            root.pendingSsid = "";
            statusTimer.restart();
        }, bssid);
    }

    Process {
        id: btPowerProc
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: root.bluetoothEnabled = this.text.includes("Powered: yes")
        }
    }

    Process {
        id: btDevicesProc
        command: ["bluetoothctl", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n").filter(line => line.length > 0);
                const devices = lines.map(line => {
                    const parts = line.split(" ");
                    return {
                        mac: parts[1] || "",
                        name: parts.slice(2).join(" ") || parts[1] || "",
                        connected: false
                    };
                });
                btConnectedProc.pendingDevices = devices;
                btConnectedProc.index = 0;
                if (devices.length > 0)
                    btConnectedProc.running = true;
                else
                    root.btDevices = [];
            }
        }
    }

    Process {
        id: btConnectedProc
        property var pendingDevices: []
        property int index: 0
        command: index < pendingDevices.length ? ["bluetoothctl", "info", pendingDevices[index].mac] : []
        stdout: StdioCollector {
            onStreamFinished: {
                const device = btConnectedProc.pendingDevices[btConnectedProc.index];
                if (device)
                    device.connected = this.text.includes("Connected: yes");
                btConnectedProc.index++;
                if (btConnectedProc.index < btConnectedProc.pendingDevices.length)
                    btConnectedProc.running = true;
                else
                    root.btDevices = btConnectedProc.pendingDevices;
            }
        }
    }

    Process {
        id: btActionProc
        stdout: StdioCollector {
            onStreamFinished: root.refreshBluetooth()
        }
    }

    Timer {
        interval: 5000
        running: root.selectedTab === 1
        repeat: true
        onTriggered: root.refreshBluetooth()
    }

    Timer {
        id: statusTimer
        interval: 3000
        onTriggered: root.statusMessage = ""
    }

    Component.onCompleted: root.refreshBluetooth()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Connections"
                color: Theme.txt1
                font.pixelSize: 18
                font.bold: true
                font.family: Theme.font
            }
            Item {
                Layout.fillWidth: true
            }
            Text {
                text: Network.active ? Network.active.ssid : "Offline"
                color: Network.active ? Theme.mmry : Theme.txt2
                font.pixelSize: 12
                font.family: Theme.font
                elide: Text.ElideRight
                Layout.maximumWidth: 130
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: ["Wi-Fi", "Bluetooth"]
                delegate: Rectangle {
                    required property string modelData
                    required property int index
                    Layout.fillWidth: true
                    height: 30
                    radius: Theme.radius
                    color: root.selectedTab === index ? Theme.mmry : "transparent"
                    border.color: root.selectedTab === index ? Theme.mmry : Theme.sptr
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: root.selectedTab === index ? Theme.bgnd : Theme.txt2
                        font.pixelSize: 11
                        font.family: Theme.font
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.selectedTab = index
                    }
                }
            }

            Rectangle {
                width: 30
                height: 30
                radius: Theme.radius
                color: "transparent"
                border.color: Theme.sptr
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: String.fromCodePoint(0xF0450)
                    color: Network.scanning ? Theme.mmry : Theme.txt2
                    font.pixelSize: 14
                    font.family: Theme.font
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: !Network.scanning
                    onClicked: Network.rescanWifi()
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.selectedTab === 0

            ListView {
                id: wifiList
                anchors.fill: parent
                model: Network.networks
                spacing: 3
                clip: true

                delegate: Rectangle {
                    required property var modelData
                    width: wifiList.width
                    height: 30
                    radius: Theme.radius
                    color: modelData.active ? Qt.rgba(0.35, 0.8, 0.56, 0.12) : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 4
                        spacing: 6
                        Text {
                            text: modelData.active ? String.fromCodePoint(0xF0928) : String.fromCodePoint(0xF0922)
                            color: modelData.active ? Theme.mmry : Theme.txt2
                            font.pixelSize: 14
                            font.family: Theme.font
                        }
                        Text {
                            text: modelData.ssid
                            color: modelData.active ? Theme.mmry : Theme.txt1
                            font.pixelSize: 11
                            font.bold: modelData.active
                            font.family: Theme.font
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: modelData.strength + "%"
                            color: Theme.txt2
                            font.pixelSize: 10
                            font.family: Theme.font
                        }
                        Rectangle {
                            width: 58
                            height: 24
                            radius: Theme.radius
                            color: modelData.active ? Theme.bat5 : Theme.bgnd
                            border.color: Theme.sptr
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: modelData.active ? "off" : "connect"
                                color: Theme.txt2
                                font.pixelSize: 10
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
                                        root.connectWifi(modelData.ssid, modelData.bssid || "", modelData.security && modelData.security !== "--");
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
                font.pixelSize: 11
                font.family: Theme.font
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.selectedTab === 1

            ListView {
                id: btList
                anchors.fill: parent
                model: root.btDevices
                spacing: 3
                clip: true
                delegate: Rectangle {
                    required property var modelData
                    width: btList.width
                    height: 30
                    radius: Theme.radius
                    color: modelData.connected ? Qt.rgba(0.35, 0.8, 0.56, 0.12) : "transparent"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 4
                        Text {
                            text: modelData.name
                            color: modelData.connected ? Theme.mmry : Theme.txt1
                            font.pixelSize: 11
                            font.family: Theme.font
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Rectangle {
                            width: 58
                            height: 24
                            radius: Theme.radius
                            color: Theme.bgnd
                            border.color: Theme.sptr
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: modelData.connected ? "off" : "connect"
                                color: Theme.txt2
                                font.pixelSize: 10
                                font.family: Theme.font
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    btActionProc.command = ["bluetoothctl", modelData.connected ? "disconnect" : "connect", modelData.mac];
                                    btActionProc.running = true;
                                }
                            }
                        }
                    }
                }
            }
            Text {
                anchors.centerIn: parent
                visible: root.btDevices.length === 0
                text: root.bluetoothEnabled ? "No paired devices" : "Bluetooth is disabled"
                color: Theme.txt2
                font.pixelSize: 11
                font.family: Theme.font
            }
        }

        Text {
            text: root.statusMessage
            visible: root.statusMessage.length > 0
            color: root.statusMessage.includes("failed") ? Theme.bat5 : Theme.mmry
            font.pixelSize: 10
            font.family: Theme.font
            elide: Text.ElideRight
            Layout.fillWidth: true
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
                root.statusMessage = result.success ? "Connected to " + root.pendingSsid : (result.error || "Connection failed");
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
