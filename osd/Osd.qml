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
            root.show_osd("wpctl get-volume @DEFAULT_SINK@ | awk '{print $2 * 100}'");
        }
        function volume_down() {
            console.debug("Volume Down");
            tmr.running = false;
            tmr.running = true;
        }
        function volume_mute() {
            console.debug("Volume Mute Toggle");
            tmr.running = false;
            tmr.running = true;
        }
        function brightness_up() {
            // brightnessctl -m | awk -F ',' '{gsub(/%/, "");print $4}'
            console.debug("Brightness Up");
            tmr.running = false;
            tmr.running = true;
        }
        function brightness_down() {
            console.debug("Brightness Down");
            tmr.running = false;
            tmr.running = true;
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
                width: 250
                height: 75
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        text: root.icon
                        onTextChanged: console.info("Icon: " + this.text)
                        font.pixelSize: 32
                        leftPadding: 20
                    }
                }
            }
        }
    }
}
