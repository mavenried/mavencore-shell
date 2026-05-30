pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Wayland
import qs

Scope {
    id: root

    property bool open: false

    IpcHandler {
        target: "network-manager"
        function toggle() {
            loader.active = true;
            root.open = !root.open;
            if (!root.open) {
                closeTimer.start();
            } else {
                Network.rescanWifi();
                btRefreshTimer.start();
            }
        }
    }

    Timer {
        id: closeTimer
        interval: 250
        onTriggered: loader.active = root.open
    }

    // Bluetooth polling
    Timer {
        id: btRefreshTimer
        interval: 3000
        repeat: true
        running: root.open
        onTriggered: btDevicesProc.running = true
    }

    // --- Bluetooth data ---
    property bool bluetoothEnabled: false
    property list<var> btDevices: []

    Process {
        id: btPowerProc
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.bluetoothEnabled = this.text.includes("Powered: yes");
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: btDevicesProc
        command: ["bluetoothctl", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n").filter(l => l.length > 0);
                const devs = lines.map(line => {
                    const parts = line.split(" ");
                    const mac = parts[1] ?? "";
                    const name = parts.slice(2).join(" ") || mac;
                    return {
                        mac,
                        name,
                        connected: false
                    };
                });
                // Check connected status
                btConnectedProc.pendingDevices = devs;
                btConnectedProc.index = 0;
                if (devs.length > 0) {
                    btConnectedProc.running = true;
                } else {
                    root.btDevices = [];
                }
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: btConnectedProc
        property var pendingDevices: []
        property int index: 0
        command: index < pendingDevices.length ? ["bluetoothctl", "info", pendingDevices[index]?.mac ?? ""] : []
        stdout: StdioCollector {
            onStreamFinished: {
                const dev = btConnectedProc.pendingDevices[btConnectedProc.index];
                if (dev) {
                    dev.connected = this.text.includes("Connected: yes");
                }
                btConnectedProc.index++;
                if (btConnectedProc.index < btConnectedProc.pendingDevices.length) {
                    btConnectedProc.running = true;
                } else {
                    root.btDevices = btConnectedProc.pendingDevices;
                }
            }
        }
    }

    Process {
        id: btActionProc
        property string pendingMac: ""
        property bool pendingConnect: true
        stdout: StdioCollector {
            onStreamFinished: btDevicesProc.running = true
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
        btActionProc.command = ["bluetoothctl", root.bluetoothEnabled ? "power off" : "power on"];
        btActionProc.running = true;
        Qt.callLater(() => {
            btPowerProc.running = true;
        }, 500);
    }

    // --- Password dialog state ---
    property string pendingSsid: ""
    property string pendingBssid: ""
    property bool showPasswordDialog: false
    property string statusMessage: ""
    property bool connecting: false

    LazyLoader {
        id: loader

        PanelWindow {
            id: win
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            anchors {
                top: true
                left: true
                bottom: true
                right: true
            }
            exclusiveZone: -1
            color: "transparent"

            // Click outside to close
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.open = false;
                    closeTimer.start();
                }
            }

            Rectangle {
                id: panel
                anchors.centerIn: parent
                width: 800
                height: mainLayout.implicitHeight + 40
                radius: Theme.radius
                color: Theme.bgnd
                border.color: Theme.acct
                border.width: 2

                opacity: root.open ? 1 : 0
                scale: root.open ? 1 : 0.96

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

                // Consume clicks so they don't close the panel
                MouseArea {
                    anchors.fill: parent
                }

                Keys.onPressed: function (event) {
                    if (event.key === Qt.Key_Escape) {
                        if (root.showPasswordDialog) {
                            root.showPasswordDialog = false;
                            root.pendingSsid = "";
                        } else {
                            root.open = false;
                            closeTimer.start();
                        }
                    }
                }

                ColumnLayout {
                    id: mainLayout
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: 20
                        topMargin: 20
                    }
                    spacing: 12

                    // ── Header ──────────────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "󰖩  Network"
                            font.pixelSize: 18
                            font.family: Theme.font
                            font.bold: true
                            color: Theme.mmry
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        // WiFi toggle
                        Rectangle {
                            width: toggle.width + 24
                            height: toggle.height + 10
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
                                id: toggle
                                anchors.centerIn: parent
                                text: Network.wifiEnabled ? "󰖩  Wi-Fi ON" : "󰖪  Wi-Fi OFF"
                                font.pixelSize: 13
                                font.family: Theme.font
                                color: Theme.bgnd
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: Network.toggleWifi(cb => {})
                            }
                        }
                        // Rescan
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
                                text: Network.scanning ? "󰑐  scanning…" : "󰑐  scan"
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

                    // Status message
                    Text {
                        visible: root.statusMessage.length > 0
                        text: root.statusMessage
                        font.pixelSize: 13
                        font.family: Theme.font
                        color: root.statusMessage.startsWith("✗") ? Theme.bat5 : Theme.bat1
                        Layout.fillWidth: true
                    }

                    // ── WiFi network list ────────────────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        height: wifiList.contentHeight > 220 ? 220 : wifiList.contentHeight
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

                                HoverHandler {
                                    id: hov
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

                                    // Signal icon
                                    Text {
                                        text: {
                                            const s = netItem.modelData.strength;
                                            if (s >= 75)
                                                return "󰤨";
                                            if (s >= 50)
                                                return "󰤥";
                                            if (s >= 25)
                                                return "󰤢";
                                            return "󰤟";
                                        }
                                        font.pixelSize: 16
                                        font.family: Theme.font
                                        color: netItem.modelData.active ? Theme.mmry : Theme.txt2
                                    }

                                    // SSID
                                    Text {
                                        text: netItem.modelData.ssid
                                        font.pixelSize: 14
                                        font.family: Theme.font
                                        font.bold: netItem.modelData.active
                                        color: netItem.modelData.active ? Theme.mmry : Theme.txt1
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    // Saved indicator
                                    Text {
                                        visible: Network.hasSavedProfile(netItem.modelData.ssid) && !netItem.modelData.active
                                        text: "󰄬"
                                        font.pixelSize: 12
                                        font.family: Theme.font
                                        color: Theme.bat1
                                    }

                                    // Lock icon
                                    Text {
                                        visible: netItem.modelData.security && netItem.modelData.security !== "--" && netItem.modelData.security.length > 0
                                        text: "󰌾"
                                        font.pixelSize: 12
                                        font.family: Theme.font
                                        color: Theme.txt2
                                    }

                                    // Signal %
                                    Text {
                                        text: netItem.modelData.strength + "%"
                                        font.pixelSize: 12
                                        font.family: Theme.font
                                        color: Theme.txt2
                                        width: 36
                                        horizontalAlignment: Text.AlignRight
                                    }

                                    // Connect / Disconnect button
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
                                            text: netItem.modelData.active ? "disconnect" : root.connecting && root.pendingSsid === netItem.modelData.ssid ? "connecting…" : "connect"
                                            font.pixelSize: 12
                                            font.family: Theme.font
                                            color: netItem.modelData.active ? "#eeeeee" : Theme.txt2
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: !root.connecting
                                            onClicked: {
                                                if (netItem.modelData.active) {
                                                    const iface = Network.wirelessInterfaces.length > 0 ? Network.wirelessInterfaces[0].device : "";
                                                    Network.disconnect(iface, cb => {
                                                        root.statusMessage = cb.success ? "✓ Disconnected" : "✗ " + (cb.error || "Failed");
                                                        msgTimer.restart();
                                                    });
                                                } else {
                                                    root.pendingSsid = netItem.modelData.ssid;
                                                    root.pendingBssid = netItem.modelData.bssid ?? "";
                                                    const secure = netItem.modelData.security && netItem.modelData.security !== "--" && netItem.modelData.security.length > 0;
                                                    root.connecting = true;
                                                    Network.connectToNetworkWithPasswordCheck(netItem.modelData.ssid, secure, result => {
                                                        if (result.needsPassword) {
                                                            root.connecting = false;
                                                            root.showPasswordDialog = true;
                                                        } else {
                                                            root.connecting = false;
                                                            root.pendingSsid = "";
                                                            root.statusMessage = result.success ? "✓ Connected to " + netItem.modelData.ssid : "✗ " + (result.error || "Failed");
                                                            msgTimer.restart();
                                                        }
                                                    }, netItem.modelData.bssid ?? "");
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Wifi disabled notice
                    Text {
                        visible: !Network.wifiEnabled
                        text: "󰖪  Wi-Fi is disabled"
                        font.pixelSize: 14
                        font.family: Theme.font
                        color: Theme.txt2
                        Layout.alignment: Qt.AlignHCenter
                    }

                    // ── Password dialog ──────────────────────────────────
                    Rectangle {
                        visible: root.showPasswordDialog
                        Layout.fillWidth: true
                        height: pwdCol.implicitHeight + 20
                        radius: Theme.radius
                        color: Qt.rgba(1, 1, 1, 0.04)
                        border.color: Theme.mmry
                        border.width: 1

                        ColumnLayout {
                            id: pwdCol
                            anchors {
                                fill: parent
                                margins: 12
                            }
                            spacing: 8

                            Text {
                                text: "󰌾  Password for <b>" + root.pendingSsid + "</b>"
                                font.pixelSize: 13
                                font.family: Theme.font
                                color: Theme.txt1
                                textFormat: Text.RichText
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: pwdInput.implicitHeight + 10
                                radius: Theme.radius
                                color: Theme.bgnd
                                border.color: pwdInput.activeFocus ? Theme.mmry : Theme.acct
                                border.width: 2

                                TextInput {
                                    id: pwdInput
                                    anchors {
                                        fill: parent
                                        margins: 8
                                    }
                                    echoMode: TextInput.Password
                                    font.pixelSize: 14
                                    font.family: Theme.font
                                    color: Theme.txt1
                                    focus: root.showPasswordDialog
                                    onAccepted: connectWithPassword()
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Item {
                                    Layout.fillWidth: true
                                }

                                Rectangle {
                                    width: cancelLbl.width + 20
                                    height: cancelLbl.height + 8
                                    radius: Theme.radius
                                    color: "transparent"
                                    border.color: Theme.acct
                                    border.width: 1
                                    Text {
                                        id: cancelLbl
                                        anchors.centerIn: parent
                                        text: "cancel"
                                        font.pixelSize: 13
                                        font.family: Theme.font
                                        color: Theme.txt2
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            root.showPasswordDialog = false;
                                            pwdInput.text = "";
                                            root.pendingSsid = "";
                                        }
                                    }
                                }

                                Rectangle {
                                    width: connectLbl.width + 20
                                    height: connectLbl.height + 8
                                    radius: Theme.radius
                                    color: Theme.mmry
                                    Text {
                                        id: connectLbl
                                        anchors.centerIn: parent
                                        text: "connect"
                                        font.pixelSize: 13
                                        font.family: Theme.font
                                        color: Theme.bgnd
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: connectWithPassword()
                                    }
                                }
                            }
                        }
                    }

                    // ── Divider ──────────────────────────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Theme.mmry
                    }

                    // ── Bluetooth header ─────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "󰂯  Bluetooth"
                            font.pixelSize: 18
                            font.family: Theme.font
                            font.bold: true
                            color: Theme.mmry
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        Rectangle {
                            width: btToggleLbl.width + 24
                            height: btToggleLbl.height + 10
                            radius: Theme.radius
                            color: root.bluetoothEnabled ? Theme.mmry : Theme.sptr
                            border.color: Theme.acct
                            border.width: 2
                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }
                            Text {
                                id: btToggleLbl
                                anchors.centerIn: parent
                                text: root.bluetoothEnabled ? "󰂯  BT ON" : "󰂲  BT OFF"
                                font.pixelSize: 13
                                font.family: Theme.font
                                color: Theme.bgnd
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    const cmd = root.bluetoothEnabled ? ["bluetoothctl", "power", "off"] : ["bluetoothctl", "power", "on"];
                                    btActionProc.command = cmd;
                                    btActionProc.running = true;
                                    Qt.callLater(() => {
                                        btPowerProc.running = true;
                                    }, 600);
                                }
                            }
                        }
                    }

                    // ── Bluetooth device list ────────────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        height: btList.contentHeight > 160 ? 160 : Math.max(btList.contentHeight, 36)
                        color: "transparent"
                        clip: true
                        visible: root.bluetoothEnabled

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

                                HoverHandler {
                                    id: btHov
                                }

                                RowLayout {
                                    id: btRow
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        verticalCenter: parent.verticalCenter
                                        leftMargin: 12
                                        rightMargin: 12
                                    }
                                    spacing: 8

                                    Text {
                                        text: btItem.modelData.connected ? "󰂱" : "󰂲"
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
                                            color: btItem.modelData.connected ? "#eeeeee" : Theme.txt2
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                if (btItem.modelData.connected) {
                                                    btActionProc.command = ["bluetoothctl", "disconnect", btItem.modelData.mac];
                                                } else {
                                                    btActionProc.command = ["bluetoothctl", "connect", btItem.modelData.mac];
                                                }
                                                btActionProc.running = true;
                                            }
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
                        visible: !root.bluetoothEnabled
                        text: "󰂲  Bluetooth is disabled"
                        font.pixelSize: 14
                        font.family: Theme.font
                        color: Theme.txt2
                        Layout.alignment: Qt.AlignHCenter
                    }

                    // Bottom spacer
                    Item {
                        height: 4
                    }
                }

                // Status auto-dismiss
                Timer {
                    id: msgTimer
                    interval: 3000
                    onTriggered: root.statusMessage = ""
                }
            }

            function connectWithPassword() {
                const pwd = pwdInput.text;
                pwdInput.text = "";
                root.showPasswordDialog = false;
                root.connecting = true;
                Network.connectToNetwork(root.pendingSsid, pwd, root.pendingBssid, result => {
                    root.connecting = false;
                    root.statusMessage = result.success ? "✓ Connected to " + root.pendingSsid : "✗ " + (result.error || "Failed to connect");
                    msgTimer.restart();
                    root.pendingSsid = "";
                });
            }
        }
    }
}
