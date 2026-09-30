pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs

WidgetCard {
    id: root

    property bool bluetoothEnabled: false
    property list<var> devices: []

    function refresh() {
        powerProcess.running = true;
        devicesProcess.running = true;
    }

    Process {
        id: powerProcess
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: root.bluetoothEnabled = this.text.includes("Powered: yes")
        }
    }

    Process {
        id: devicesProcess
        command: ["bluetoothctl", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n").filter(line => line.length > 0);
                const found = lines.map(line => {
                    const parts = line.split(" ");
                    return {
                        mac: parts[1] || "",
                        name: parts.slice(2).join(" ") || parts[1] || "",
                        connected: false
                    };
                });
                connectedProcess.pending = found;
                connectedProcess.index = 0;
                if (found.length > 0)
                    connectedProcess.running = true;
                else
                    root.devices = [];
            }
        }
    }

    Process {
        id: connectedProcess
        property var pending: []
        property int index: 0
        command: index < pending.length ? ["bluetoothctl", "info", pending[index].mac] : []
        stdout: StdioCollector {
            onStreamFinished: {
                const device = connectedProcess.pending[connectedProcess.index];
                if (device)
                    device.connected = this.text.includes("Connected: yes");
                connectedProcess.index++;
                if (connectedProcess.index < connectedProcess.pending.length)
                    connectedProcess.running = true;
                else
                    root.devices = connectedProcess.pending;
            }
        }
    }

    Process {
        id: actionProcess
        stdout: StdioCollector {
            onStreamFinished: root.refresh()
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: String.fromCodePoint(0xF00AF) + "  Bluetooth"
                color: Theme.txt1
                font.pixelSize: 20
                font.bold: true
                font.family: Theme.font
            }
            Item {
                Layout.fillWidth: true
            }
            Rectangle {
                width: 60
                height: 27
                radius: Theme.radius
                color: root.bluetoothEnabled ? Theme.mmry : Theme.sptr
                Text {
                    anchors.centerIn: parent
                    text: root.bluetoothEnabled ? "on" : "off"
                    color: Theme.bgnd
                    font.pixelSize: 13
                    font.family: Theme.font
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        actionProcess.command = root.bluetoothEnabled ? ["bluetoothctl", "power", "off"] : ["bluetoothctl", "power", "on"];
                        actionProcess.running = true;
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            ListView {
                id: deviceList
                anchors.fill: parent
                model: root.devices
                spacing: 2
                clip: true
                delegate: Rectangle {
                    required property var modelData
                    width: deviceList.width
                    height: 28
                    radius: Theme.radius
                    color: modelData.connected ? Qt.rgba(0.35, 0.8, 0.56, 0.12) : "transparent"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 4
                        spacing: 5
                        Text {
                            text: String.fromCodePoint(0xF00AF) + " " + modelData.name
                            color: modelData.connected ? Theme.mmry : Theme.txt1
                            font.pixelSize: 13
                            font.family: Theme.font
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Rectangle {
                            width: 52
                            height: 22
                            radius: Theme.radius
                            color: modelData.connected? Theme.mmry : Theme.bgnd
                            border.color: Theme.sptr
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: modelData.connected ? "dcnt" : "cnt"
                                color: modelData.connected ? Theme.bgnd : Theme.txt2
                                font.pixelSize: 12
                                font.family: Theme.font
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    actionProcess.command = ["bluetoothctl", modelData.connected ? "disconnect" : "connect", modelData.mac];
                                    actionProcess.running = true;
                                }
                            }
                        }
                    }
                }
            }
            Text {
                anchors.centerIn: parent
                visible: root.devices.length === 0
                text: root.bluetoothEnabled ? "No paired devices" : "Bluetooth is disabled"
                color: Theme.txt2
                font.pixelSize: 13
                font.family: Theme.font
            }
        }
    }
}
