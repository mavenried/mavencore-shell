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
            ot.toggle()
            if (ot.open) {
                Network.rescanWifi()
                btRefreshTimer.start()
            }
        }
    }

    // ── Bluetooth data ───────────────────────────────────────────────
    property bool bluetoothEnabled: false
    property list<var> btDevices: []

    Timer {
        id: btRefreshTimer
        interval: 3000
        repeat: true
        running: ot.open
        onTriggered: btDevicesProc.running = true
    }

    Process {
        id: btPowerProc
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: root.bluetoothEnabled = this.text.includes("Powered: yes")
        }
        Component.onCompleted: running = true
    }

    Process {
        id: btDevicesProc
        command: ["bluetoothctl", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n").filter(l => l.length > 0)
                const devs = lines.map(line => {
                    const parts = line.split(" ")
                    return { mac: parts[1] || "", name: parts.slice(2).join(" ") || parts[1] || "", connected: false }
                })
                btConnectedProc.pendingDevices = devs
                btConnectedProc.index = 0
                if (devs.length > 0) btConnectedProc.running = true
                else root.btDevices = []
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: btConnectedProc
        property var pendingDevices: []
        property int index: 0
        command: index < pendingDevices.length ? ["bluetoothctl", "info", (pendingDevices[index] ? pendingDevices[index].mac : "") || ""] : []
        stdout: StdioCollector {
            onStreamFinished: {
                const dev = btConnectedProc.pendingDevices[btConnectedProc.index]
                if (dev) dev.connected = this.text.includes("Connected: yes")
                btConnectedProc.index++
                if (btConnectedProc.index < btConnectedProc.pendingDevices.length)
                    btConnectedProc.running = true
                else
                    root.btDevices = btConnectedProc.pendingDevices
            }
        }
    }

    Process {
        id: btActionProc
        stdout: StdioCollector { onStreamFinished: btDevicesProc.running = true }
    }

    function btConnect(mac) { btActionProc.command = ["bluetoothctl", "connect", mac]; btActionProc.running = true }
    function btDisconnect(mac) { btActionProc.command = ["bluetoothctl", "disconnect", mac]; btActionProc.running = true }
    function btTogglePower() {
        btActionProc.command = ["bluetoothctl", root.bluetoothEnabled ? "power off" : "power on"]
        btActionProc.running = true
        Qt.callLater(() => { btPowerProc.running = true }, 600)
    }

    // ── WiFi connection state ────────────────────────────────────────
    property string pendingSsid: ""
    property string pendingBssid: ""
    property bool showPasswordDialog: false
    property string statusMessage: ""
    property bool connecting: false

    // ── UI ───────────────────────────────────────────────────────────
    LazyLoader {
        id: loader

        PanelWindow {
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: ot.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            anchors { top: true; left: true; bottom: true; right: true }
            exclusiveZone: -1
            color: "transparent"

            Component.onCompleted: Qt.callLater(() => focusCatcher.forceActiveFocus())

            Item {
                id: focusCatcher
                anchors.fill: parent
                focus: true

                Keys.onPressed: function(e) {
                    if (e.key === Qt.Key_Escape) { ot.setOpen(false); e.accepted = true }
                }

                MouseArea { anchors.fill: parent; onClicked: ot.setOpen(false) }

                Rectangle {
                    id: panel
                    anchors.centerIn: parent
                    width: 800
                    height: mainLayout.implicitHeight + 40
                    radius: Theme.radius
                    color: Theme.bgnd
                    border.color: Theme.acct
                    border.width: 2
                    opacity: ot.open ? 1 : 0
                    scale: ot.open ? 1 : 0.96
                    Behavior on opacity { OpacityAnimator { duration: 200 } }
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                    MouseArea { anchors.fill: parent }

                    ColumnLayout {
                        id: mainLayout
                        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 20; topMargin: 20 }
                        spacing: 12

                        WifiPanel {
                            Layout.fillWidth: true
                            connecting:    root.connecting
                            pendingSsid:   root.pendingSsid
                            statusMessage: root.statusMessage
                            onConnectRequested: function(ssid, bssid, secure) {
                                root.pendingSsid = ssid
                                root.pendingBssid = bssid
                                root.connecting = true
                                Network.connectToNetworkWithPasswordCheck(ssid, secure, result => {
                                    if (result.needsPassword) {
                                        root.connecting = false
                                        root.showPasswordDialog = true
                                    } else {
                                        root.connecting = false
                                        root.pendingSsid = ""
                                        root.statusMessage = result.success
                                            ? String.fromCodePoint(0x2713) + " Connected to " + ssid
                                            : String.fromCodePoint(0x2717) + " " + (result.error || "Failed")
                                        msgTimer.restart()
                                    }
                                }, bssid)
                            }
                            onDisconnectRequested: {
                                const iface = Network.wirelessInterfaces.length > 0 ? Network.wirelessInterfaces[0].device : ""
                                Network.disconnect(iface, cb => {
                                    root.statusMessage = cb.success
                                        ? String.fromCodePoint(0x2713) + " Disconnected"
                                        : String.fromCodePoint(0x2717) + " " + (cb.error || "Failed")
                                    msgTimer.restart()
                                })
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.mmry }

                        BluetoothPanel {
                            Layout.fillWidth: true
                            btEnabled: root.bluetoothEnabled
                            btDevices: root.btDevices
                            onConnectRequested:     mac => root.btConnect(mac)
                            onDisconnectRequested:  mac => root.btDisconnect(mac)
                            onTogglePowerRequested: root.btTogglePower()
                        }

                        Item { height: 4 }
                    }

                    PasswordPopup {
                        anchors.fill: parent
                        z: 1
                        visible: root.showPasswordDialog
                        ssid: root.pendingSsid
                        onPasswordAccepted: function(pwd) {
                            root.showPasswordDialog = false
                            root.connecting = true
                            Network.connectToNetwork(root.pendingSsid, pwd, root.pendingBssid, result => {
                                root.connecting = false
                                root.statusMessage = result.success
                                    ? String.fromCodePoint(0x2713) + " Connected to " + root.pendingSsid
                                    : String.fromCodePoint(0x2717) + " " + (result.error || "Failed to connect")
                                msgTimer.restart()
                                root.pendingSsid = ""
                            })
                        }
                        onDismissed: {
                            root.showPasswordDialog = false
                            root.pendingSsid = ""
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
