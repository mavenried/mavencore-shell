pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs

Scope {
    id: root
    property bool showing: false
    property var icons
    property string icon: {
        if (pct == 0)
            return root.icons[0];
        let len = root.icons[1].length;
        let idx = Math.floor((root.pct / 100) * len);
        idx = idx == len ? idx - 1 : idx;
        console.log("idx:" + idx + " len: " + len);
        return root.icons[1][idx];
    }
    property int pct: 0

    function show_osd(command) {
        proc.command = ["sh", "-c", command];

        proc.running = false;
        proc.running = true;

        root.showing = true;

        tmr.running = false;
        tmr.running = true;
    }

    IpcHandler {
        target: "osd"
        function volume_up() {
            // wpctl get-volume @DEFAULT_SINK@ | awk '{print $2 * 100}'
            console.debug("Volume Up");
            root.icons = ["󰝟 ", ["󰖀 ", "󰕾 "]];
            proc2.exec(["wpctl", "set-volume", "@DEFAULT_SINK@", "5%+"]);
            root.show_osd("wpctl get-volume @DEFAULT_SINK@ | awk '/MUTED/ {print 0; next} {print $2 * 100}'");
        }
        function volume_down() {
            console.debug("Volume Down");
            root.icons = ["󰝟 ", ["󰖀 ", "󰕾 "]];
            proc2.exec(["wpctl", "set-volume", "@DEFAULT_SINK@", "5%-"]);
            root.show_osd("wpctl get-volume @DEFAULT_SINK@ | awk '/MUTED/ {print 0; next} {print $2 * 100}'");
        }
        function volume_mute() {
            console.debug("Volume Mute Toggle");
            root.icons = ["󰝟 ", ["󰖀 ", "󰕾 "]];
            proc2.exec(["wpctl", "set-mute", "@DEFAULT_SINK@", "toggle"]);
            root.show_osd("wpctl get-volume @DEFAULT_SINK@ | awk '/MUTED/ {print 0; next} {print $2 * 100}'");
        }
        function brightness_up() {
            console.debug("Brightness Up");
            root.icons = ["󰃞 ", ["󰃟 ", "󰃠 "]];
            proc2.exec(["brightnessctl", "s", "+5%"]);
            root.show_osd("brightnessctl -m | awk -F ',' '{gsub(/%/, \"\");print $4}'");
        }
        function brightness_down() {
            console.debug("Brightness Down");
            root.icons = ["󰃞 ", ["󰃟 ", "󰃠 "]];
            proc2.exec(["brightnessctl", "s", "5%-"]);
            root.show_osd("brightnessctl -m | awk -F ',' '{gsub(/%/, \"\");print $4}'");
        }
    }

    Process {
        id: proc
        running: false
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                console.debug("Process returned: " + parseInt(this.text));
                root.pct = parseInt(this.text);
            }
        }
    }

    Process {
        id: proc2
        running: false
        command: []
    }

    Timer {
        id: tmr
        interval: 2000
        running: false

        onTriggered: {
            console.debug("timer triggered");
            root.showing = false;
        }
    }

    LazyLoader {
        active: root.showing
        PanelWindow {

            color: "transparent"

            anchors {
                bottom: true
                left: true
                right: true
            }

            exclusiveZone: -1
            height: 100
            Rectangle {
                radius: Theme.radius
                border.width: 2
                border.color: Theme.acct
                color: Theme.bgnd

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                // width: 250
                height: 75
                width: icon.width + rect.width + 30
                Row {
                    // width: icon.width + rect.width
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    Text {
                        id: icon
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.icon
                        onTextChanged: console.info("Icon: " + this.text)
                        font.pixelSize: 36
                        leftPadding: 20
                        color: Theme.clck
                    }
                    Rectangle {
                        id: rect
                        anchors.verticalCenter: parent.verticalCenter
                        width: 165
                        height: 5
                        radius: 2
                        color: Qt.rgba(0, 0, 0, 0.2)

                        Rectangle {

                            width: parent.width * (root.pct / 100)
                            height: 5
                            radius: 2
                        }
                    }
                }
            }
        }
    }
}
