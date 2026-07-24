pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import qs

Scope {
    id: root
    property bool showing: false
    property var icons: [String.fromCodePoint(0xF075F), [String.fromCodePoint(0xF0580), String.fromCodePoint(0xF057E)]]
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

    readonly property real volumeStep: 0.05

    function reveal() {
        loader.active = true;
        root.showing = true;

        tmr.running = false;
        tmr.running = true;
    }

    function show_osd(command) {
        root.reveal();
        proc.command = ["sh", "-c", command];

        proc.running = false;
        proc.running = true;
    }

    function updateVolumePct() {
        const sink = Pipewire.defaultAudioSink;
        if (!sink || !sink.ready || !sink.audio) {
            root.pct = 0;
            return;
        }
        root.pct = sink.audio.muted ? 0 : Math.round(sink.audio.volume * 100);
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
        target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
        function onMutedChanged() {
            root.updateVolumePct();
        }
        function onVolumesChanged() {
            root.updateVolumePct();
        }
    }

    IpcHandler {
        target: "osd"
        function volume_up() {
            console.debug("Volume Up");
            root.icons = [String.fromCodePoint(0xF075F), [String.fromCodePoint(0xF0580), String.fromCodePoint(0xF057E)]];
            const sink = Pipewire.defaultAudioSink;
            if (sink && sink.ready && sink.audio)
                sink.audio.volume = Math.min(1.0, sink.audio.volume + root.volumeStep);
            root.updateVolumePct();
            root.reveal();
        }
        function volume_down() {
            console.debug("Volume Down");
            root.icons = [String.fromCodePoint(0xF075F), [String.fromCodePoint(0xF0580), String.fromCodePoint(0xF057E)]];
            const sink = Pipewire.defaultAudioSink;
            if (sink && sink.ready && sink.audio)
                sink.audio.volume = Math.max(0.0, sink.audio.volume - root.volumeStep);
            root.updateVolumePct();
            root.reveal();
        }
        function volume_mute() {
            console.debug("Volume Mute Toggle");
            root.icons = [String.fromCodePoint(0xF075F), [String.fromCodePoint(0xF0580), String.fromCodePoint(0xF057E)]];
            const sink = Pipewire.defaultAudioSink;
            if (sink && sink.ready && sink.audio)
                sink.audio.muted = !sink.audio.muted;
            root.updateVolumePct();
            root.reveal();
        }
        function brightness_up() {
            console.debug("Brightness Up");
            root.icons = [String.fromCodePoint(0xF00DE), [String.fromCodePoint(0xF00DF), String.fromCodePoint(0xF00E0)]];
            root.show_osd("brightnessctl s +5% > /dev/null; brightnessctl -m | awk -F ',' '{gsub(/%/, \"\");print $4}'");
        }
        function brightness_down() {
            console.debug("Brightness Down");
            root.icons = [String.fromCodePoint(0xF00DE), [String.fromCodePoint(0xF00DF), String.fromCodePoint(0xF00E0)]];
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
                left: true
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
                anchors.right: parent.right
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
