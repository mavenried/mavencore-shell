pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs

Scope {
    id: root

    // ── Overlay lifecycle ────────────────────────────────────────────
    OverlayToggle {
        id: ot
        loader: loader
        closeDelay: 250
    }

    IpcHandler {
        target: "network-manager"
        function toggle() {
            ot.toggle();
            if (ot.open) {
                Network.rescanWifi();
                btRefreshTimer.start();
            }
        }
    }

    // ── Bluetooth data ───────────────────────────────────────────────
    property bool bluetoothEnabled: false
    property list<var> btDevices: []

    Timer {
        id: btRefreshTimer
        interval: 1000
        repeat: true
        running: ot.open
        onTriggered: btRefreshProc.running = true
    }

    Process {
        id: btRefreshProc
        command: [
            "sh", "-c",
            "echo \"POWER:$(bluetoothctl show | grep -q 'Powered: yes' && echo 1 || echo 0)\"; " +
            "bluetoothctl devices | while read -r _ mac name; do " +
            "echo \"DEV:$mac|$name|$(bluetoothctl info \"$mac\" | grep -q 'Connected: yes' && echo 1 || echo 0)\"; " +
            "done"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n").filter(l => l.length > 0);
                let powered = false;
                const devs = [];

                for (const line of lines) {
                    if (line.startsWith("POWER:")) {
                        powered = line.substring(6) === "1";
                    } else if (line.startsWith("DEV:")) {
                        const parts = line.substring(4).split("|");
                        if (parts.length >= 3) {
                            devs.push({
                                mac: parts[0],
                                name: parts[1] || parts[0],
                                connected: parts[2] === "1"
                            });
                        }
                    }
                }

                root.bluetoothEnabled = powered;
                root.btDevices = devs;
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: btActionProc
        stdout: StdioCollector {
            onStreamFinished: btRefreshProc.running = true
        }
    }

    function btConnect(mac) {
        btActionProc.command = ["bluetoothctl", "connect", mac];
        btActionProc.running = true;
    }

    function btDisconnect(mac) {
        btActionProc.command = ["bluetoothctl", "disconnect", mac];
        btActionProc.running = true;
    }

    function btTogglePower() {
        btActionProc.command = ["bluetoothctl", "power", root.bluetoothEnabled ? "off" : "on"];
        btActionProc.running = true;
    }

    // ── WiFi connection state ────────────────────────────────────────
    property string pendingSsid: ""
    property string pendingBssid: ""
    property bool showPasswordDialog: false
    property string statusMessage: ""
    property bool connecting: false
    property int selectedTab: 0

    // ── UI ───────────────────────────────────────────────────────────
    LazyLoader {
        id: loader

        PanelWindow {
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: ot.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            anchors {
                top: true
                left: true
                bottom: true
                right: true
            }
            exclusiveZone: -1
            color: "transparent"

            Component.onCompleted: Qt.callLater(() => focusCatcher.forceActiveFocus())

            Item {
                id: focusCatcher
                anchors.fill: parent
                focus: true

                Keys.onPressed: function (e) {
                    if (e.key === Qt.Key_Escape) {
                        ot.setOpen(false);
                        e.accepted = true;
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: ot.setOpen(false)
                }

                Rectangle {
                    id: panel
                    anchors.centerIn: parent
                    width: 860
                    height: Math.min(mainLayout.implicitHeight + 40, parent.height - 48)
                    implicitHeight: mainLayout.implicitHeight + 40
                    radius: Theme.radius
                    color: Theme.bgnd
                    border.color: Theme.acct
                    border.width: 2
                    opacity: ot.open ? 1 : 0
                    scale: ot.open ? 1 : 0.96
                    Behavior on opacity {
                        OpacityAnimator {
                            duration: 200
                        }
                    }
                    Behavior on scale {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                    }

                    ColumnLayout {
                        id: mainLayout
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 24
                            topMargin: 20
                        }
                        spacing: 16

                        RowLayout {
                            Layout.fillWidth: true

                            ColumnLayout {
                                spacing: 2
                                Text {
                                    text: "Connections"
                                    font.pixelSize: 22
                                    font.family: Theme.font
                                    font.bold: true
                                    color: Theme.txt1
                                }
                           }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                text: Network.active ? Network.active.ssid : "Disconnected"
                                font.pixelSize: 22
                                font.family: Theme.font
                                color: Network.active ? Theme.mmry : Theme.txt2
                                elide: Text.ElideRight
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: ["Wi-Fi", "Bluetooth"]
                                delegate: Rectangle {
                                    required property string modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    height: 38
                                    radius: Theme.radius
                                    color: root.selectedTab === index ? Theme.mmry : "transparent"
                                    border.color: root.selectedTab === index ? Theme.mmry : Theme.sptr
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: (index === 0 ? String.fromCodePoint(0xF05A9) : String.fromCodePoint(0xF00AF)) + "  " + modelData
                                        font.pixelSize: 13
                                        font.family: Theme.font
                                        font.bold: root.selectedTab === index
                                        color: root.selectedTab === index ? Theme.bgnd : Theme.txt2
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: root.selectedTab = index
                                    }
                                }
                            }
                        }


                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.mmry
                        }
                        WifiPanel {
                            Layout.fillWidth: true
                            visible: root.selectedTab === 0
                            Layout.preferredHeight: visible ? implicitHeight : 0
                            connecting: root.connecting
                            pendingSsid: root.pendingSsid
                            statusMessage: root.statusMessage
                            onConnectRequested: function (ssid, bssid, secure) {
                                root.pendingSsid = ssid;
                                root.pendingBssid = bssid;
                                root.connecting = true;
                                Network.connectToNetworkWithPasswordCheck(ssid, secure, result => {
                                    if (result.needsPassword) {
                                        root.connecting = false;
                                        root.showPasswordDialog = true;
                                    } else {
                                        root.connecting = false;
                                        root.pendingSsid = "";
                                        root.statusMessage = result.success ? String.fromCodePoint(0x2713) + " Connected to " + ssid : String.fromCodePoint(0x2717) + " " + (result.error || "Failed");
                                        msgTimer.restart();
                                    }
                                }, bssid);
                            }
                            onDisconnectRequested: {
                                const iface = Network.wirelessInterfaces.length > 0 ? Network.wirelessInterfaces[0].device : "";
                                Network.disconnect(iface, cb => {
                                    root.statusMessage = cb.success ? String.fromCodePoint(0x2713) + " Disconnected" : String.fromCodePoint(0x2717) + " " + (cb.error || "Failed");
                                    msgTimer.restart();
                                });
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.mmry
                            visible: root.selectedTab === 0
                        }

                        BluetoothPanel {
                            Layout.fillWidth: true
                            visible: root.selectedTab === 1
                            Layout.preferredHeight: visible ? implicitHeight : 0
                            btEnabled: root.bluetoothEnabled
                            btDevices: root.btDevices
                            onConnectRequested: mac => root.btConnect(mac)
                            onDisconnectRequested: mac => root.btDisconnect(mac)
                            onTogglePowerRequested: root.btTogglePower()
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.mmry
                            visible: root.selectedTab === 1
                        }
                    }

                    PasswordPopup {
                        anchors.fill: parent
                        z: 1
                        visible: root.showPasswordDialog
                        ssid: root.pendingSsid
                        onPasswordAccepted: function (pwd) {
                            root.showPasswordDialog = false;
                            root.connecting = true;
                            Network.connectToNetwork(root.pendingSsid, pwd, root.pendingBssid, result => {
                                root.connecting = false;
                                root.statusMessage = result.success ? String.fromCodePoint(0x2713) + " Connected to " + root.pendingSsid : String.fromCodePoint(0x2717) + " " + (result.error || "Failed to connect");
                                msgTimer.restart();
                                root.pendingSsid = "";
                            });
                        }
                        onDismissed: {
                            root.showPasswordDialog = false;
                            root.pendingSsid = "";
                        }
                    }

                    Timer {
                        id: msgTimer
                        interval: 3000
                        onTriggered: root.statusMessage = ""
                    }
                }
            }
        }
    }
}
