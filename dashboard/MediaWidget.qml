pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs

Rectangle {
    id: root
    color: "#1c1c1c"
    radius: Theme.radius
    border.color: Theme.sptr
    border.width: 1

    property string artist: ""
    property string title: "Nothing playing"
    property string status: "Stopped"
    property string artUrl: ""
    property real positionUs: 0
    property real lengthUs: 0
    readonly property bool isPlaying: status === "Playing"
    readonly property bool hasArt: artUrl !== ""

    readonly property string iconPrev: String.fromCodePoint(0xF048)
    readonly property string iconPlay: String.fromCodePoint(0xF04B)
    readonly property string iconPause: String.fromCodePoint(0xF04C)
    readonly property string iconNext: String.fromCodePoint(0xF050)

    Timer {
        interval: 1000
        running: root.isPlaying && root.lengthUs > 0
        repeat: true
        onTriggered: root.positionUs = Math.min(root.positionUs + 1000000, root.lengthUs)
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            mediaProc.running = false;
            mediaProc.running = true;
        }
    }

    Process {
        id: mediaProc
        command: ["playerctl", "metadata", "--format", "{{artist}}|{{title}}|{{status}}|{{mpris:length}}|{{position}}|{{mpris:artUrl}}"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = this.text.trim().split("|");
                if (parts.length < 5 || !parts[1]) {
                    root.title = "Nothing playing";
                    root.artist = "";
                    root.status = "Stopped";
                    root.lengthUs = 0;
                    root.artUrl = "";
                    return;
                }
                root.artist = parts[0];
                root.title = parts[1];
                root.status = parts[2];
                root.lengthUs = parseFloat(parts[3]) || 0;
                root.positionUs = parseFloat(parts[4]) || 0;
                root.artUrl = parts[5] || "";
            }
        }
    }

    function fmt(us) {
        var s = Math.floor(us / 1000000);
        return Math.floor(s / 60) + ":" + (s % 60).toString().padStart(2, "0");
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        Text {
            text: "Now Playing"
            color: Theme.txt1
            font.pixelSize: 15
            font.bold: true
            font.family: Theme.font
        }

        // Art + track info
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Album art
            Rectangle {
                visible: root.hasArt
                width: 72
                height: 72
                radius: 8
                color: "#2a2a2a"
                clip: true

                Image {
                    anchors.fill: parent
                    source: root.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    Layout.fillWidth: true
                    text: root.title
                    color: Theme.txt1
                    font.pixelSize: 13
                    font.bold: true
                    font.family: Theme.font
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.artist || root.status
                    color: Theme.txt2
                    font.pixelSize: 12
                    font.family: Theme.font
                    elide: Text.ElideRight
                }
            }
        }

        // Progress bar — only when length is known
        ColumnLayout {
            visible: root.lengthUs > 0
            Layout.fillWidth: true
            spacing: 3

            Rectangle {
                Layout.fillWidth: true
                height: 4
                radius: 2
                color: "#2a2a2a"
                Rectangle {
                    width: root.lengthUs > 0 ? parent.width * (root.positionUs / root.lengthUs) : 0
                    height: parent.height
                    radius: parent.radius
                    color: Theme.pfle
                    Behavior on width {
                        NumberAnimation {
                            duration: 1000
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: root.fmt(root.positionUs)
                    color: Theme.txt2
                    font.pixelSize: 10
                    font.family: Theme.font
                }
                Item {
                    Layout.fillWidth: true
                }
                Text {
                    text: root.fmt(root.lengthUs)
                    color: Theme.txt2
                    font.pixelSize: 10
                    font.family: Theme.font
                }
            }
        }

        // Controls
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 28

            Text {
                text: root.iconPrev
                color: Theme.txt2
                font.pixelSize: 18
                font.family: Theme.font
                verticalAlignment: Text.AlignVCenter
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    onClicked: Quickshell.execDetached(["playerctl", "previous"])
                }
            }
            Text {
                text: root.isPlaying ? root.iconPause : root.iconPlay
                color: Theme.txt1
                font.pixelSize: 18
                font.family: Theme.font
                verticalAlignment: Text.AlignVCenter
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    onClicked: Quickshell.execDetached(["playerctl", "play-pause"])
                }
            }
            Text {
                text: root.iconNext
                color: Theme.txt2
                font.pixelSize: 18
                font.family: Theme.font
                verticalAlignment: Text.AlignVCenter
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    onClicked: Quickshell.execDetached(["playerctl", "next"])
                }
            }
        }

        // Item { Layout.fillHeight: true }
    }
}
