pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
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
        loader.active = true;
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
            root.icons = ["󰝟", ["󰖀", "󰕾"]];
            // proc2.exec(["wpctl", "set-volume", "@DEFAULT_SINK@", "5%+"]);
            root.show_osd("wpctl set-volume --limit 1.0 @DEFAULT_SINK@ 5%+; wpctl get-volume @DEFAULT_SINK@ | awk '/MUTED/ {print 0; next} {print $2 * 100}'");
        }
        function volume_down() {
            console.debug("Volume Down");
            root.icons = ["󰝟", ["󰖀", "󰕾"]];
            // proc2.exec(["wpctl", "set-volume", "@DEFAULT_SINK@", "5%-"]);
            root.show_osd("wpctl set-volume @DEFAULT_SINK@ 5%-; wpctl get-volume @DEFAULT_SINK@ | awk '/MUTED/ {print 0; next} {print $2 * 100}'");
        }
        function volume_mute() {
            console.debug("Volume Mute Toggle");
            root.icons = ["󰝟", ["󰖀", "󰕾"]];
            // proc2.exec(["wpctl", "set-mute", "@DEFAULT_SINK@", "toggle"]);
            root.show_osd("wpctl set-mute @DEFAULT_SINK@ toggle; wpctl get-volume @DEFAULT_SINK@ | awk '/MUTED/ {print 0; next} {print $2 * 100}'");
        }
        function brightness_up() {
            console.debug("Brightness Up");
            root.icons = ["󰃞", ["󰃟", "󰃠"]];
            // proc2.exec(["brightnessctl", "s", "+5%"]);
            root.show_osd("brightnessctl s +5% > /dev/null; brightnessctl -m | awk -F ',' '{gsub(/%/, \"\");print $4}'");
        }
        function brightness_down() {
            console.debug("Brightness Down");
            root.icons = ["󰃞", ["󰃟", "󰃠"]];
            // proc2.exec(["brightnessctl", "s", "5%-"]);
            root.show_osd("brightnessctl s 5%- > /dev/null; brightnessctl -m | awk -F ',' '{gsub(/%/, \"\");print $4}'");
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
            closeTimer.start();
        }
    }
    Timer {
        id: closeTimer
        interval: 250
        running: false
        onTriggered: {
            loader.active = false;
        }
    }

    LazyLoader {
        id: loader
        PanelWindow {

            color: "transparent"

            anchors {
                right: true
                top: true
                bottom: true
            }

            exclusiveZone: -1
            width: 85
            WlrLayershell.layer: WlrLayer.Overlay
            Rectangle {
                radius: Theme.radius
                border.width: 2
                border.color: Theme.acct
                color: Theme.bgnd
                opacity: root.showing ? 1 : 0

                Behavior on opacity {
                    OpacityAnimator {
                        duration: 200
                    }
                }

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                // width: 250
                width: 75
                height: icon.height + rect.height + 60
                Column {
                    // width: icon.width + rect.width
                    anchors.centerIn: parent
                    spacing: 15
                    Rectangle {
                        id: rect
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: 165
                        width: 10
                        radius: 5
                        color: Qt.rgba(55, 55, 55, 0.2)

                        Rectangle {
                            anchors.bottom: parent.bottom
                            height: parent.height * (root.pct / 100)
                            width: 10
                            radius: 5
                            color: Theme.clck
                        }
                    }

                    Text {
                        id: icon
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.icon
                        font.pixelSize: 36
                        bottomPadding: -10
                        color: Theme.clck
                    }
                }
            }
        }
    }
}
