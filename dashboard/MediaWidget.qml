pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell
import qs

WidgetCard {
    id: root

    property string artist: ""
    property string title: "Nothing playing"
    property string status: "Stopped"
    property string artUrl: ""
    property real positionUs: 0
    property real lengthUs: 0
    property bool seeking: false
    property real seekRatio: 0
    property real seekTargetUs: 0

    onPositionUsChanged: {
        if (seeking && Math.abs(positionUs - seekTargetUs) < 2000000)
            seeking = false;
    }
    readonly property bool isPlaying: status === "Playing"
    readonly property bool hasArt: artUrl !== ""

    readonly property string iconPrev: String.fromCodePoint(0xF048)
    readonly property string iconPlay: String.fromCodePoint(0xF04B)
    readonly property string iconPause: String.fromCodePoint(0xF04C)
    readonly property string iconNext: String.fromCodePoint(0xF050)

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
            font.pixelSize: 20
            font.bold: true
            font.family: Theme.font
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            Rectangle {
                visible: root.hasArt
                width: 120
                height: 120
                radius: 8
                color: Theme.bgnd
                clip: true
                Layout.alignment: Qt.AlignTop

                ClippingRectangle {
                    anchors.fill: parent
                    radius: Theme.radius - 10

                    Image {
                        anchors.fill: parent
                        source: root.artUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Text {
                        Layout.fillWidth: true
                        text: root.title
                        color: Theme.txt1
                        font.pixelSize: 16
                        font.bold: true
                        font.family: Theme.font
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.artist || root.status
                        color: Theme.txt2
                        font.pixelSize: 14
                        font.family: Theme.font
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                ColumnLayout {
                    visible: root.lengthUs > 0
                    Layout.fillWidth: true
                    spacing: 3

                    Rectangle {
                        id: progressTrack
                        Layout.fillWidth: true
                        height: 4
                        radius: 2
                        color: Qt.rgba(0, 0, 0, 0.2)

                        Rectangle {
                            width: root.seeking ? progressTrack.width * root.seekRatio : (root.lengthUs > 0 ? progressTrack.width * (root.positionUs / root.lengthUs) : 0)
                            height: parent.height
                            radius: parent.radius
                            color: Theme.pfle
                            Behavior on width {
                                enabled: !root.seeking
                                NumberAnimation {
                                    duration: 200
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.topMargin: -10
                            anchors.bottomMargin: -10
                            cursorShape: Qt.PointingHandCursor

                            Timer {
                                id: seekFallback
                                interval: 1500
                                onTriggered: root.seeking = false
                            }

                            function updateRatio(mx) {
                                root.seekRatio = Math.max(0, Math.min(1, mx / progressTrack.width));
                            }

                            onPressed: mouse => {
                                root.seeking = true;
                                seekFallback.stop();
                                updateRatio(mouse.x);
                            }
                            onPositionChanged: mouse => {
                                if (pressed)
                                    updateRatio(mouse.x);
                            }
                            onReleased: mouse => {
                                updateRatio(mouse.x);
                                root.seekTargetUs = root.seekRatio * root.lengthUs;
                                Quickshell.execDetached(["playerctl", "position", (root.seekTargetUs / 1000000).toString()]);
                                seekFallback.restart();
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
            }
        }
    }
}
