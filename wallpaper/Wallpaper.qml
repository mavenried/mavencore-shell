import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs

Scope {
    id: scope
    required property string wallpaperPath
    property bool showTime: false
    property var timeXOffset: 0.5
    property var timeYOffset: 0.75

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root
            exclusiveZone: -1
            WlrLayershell.layer: WlrLayer.Background

            required property var modelData

            screen: modelData
            color: "transparent"

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            Image {
                id: img
                anchors.centerIn: parent
                fillMode: Image.PreserveAspectCrop
                source: scope.wallpaperPath
                clip: true
            }

            Rectangle {
                id: rect
                visible: scope.showTime

                x: parent.width * scope.timeXOffset - inner.width / 2
                y: parent.height * scope.timeYOffset - inner.height / 2

                width: inner.width
                height: inner.height
                color: "transparent"
                Column {
                    id: inner
                    anchors.margins: 10
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(clock.date, "<b>hh:mm</b>")
                        font.family: Theme.font
                        color: Theme.mmry
                        font.pointSize: 20
                        horizontalAlignment: center
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(clock.date, "dd|MM|yy")
                        font.family: Theme.font
                        color: Theme.mmry
                        font.pointSize: 10
                    }
                }
            }

            SystemClock {
                id: clock
            }

            OpacityAnimator {
                id: fadeIn
                target: img
                duration: 1000
                from: 0
                to: 1
                easing.type: Easing.InQuad
            }

            OpacityAnimator {
                id: fadeInTime
                target: rect
                duration: 1000
                from: 0
                to: 1
                easing.type: Easing.InQuad
            }

            IpcHandler {
                id: ipc
                target: "wallpaper"
                function reload() {
                    img.source = "";
                    img.opacity = 0;
                    img.source = scope.wallpaperPath;

                    fadeIn.start();

                    rect.opacity = 0;
                    fadeInTime.start();
                }
            }

            FileView {
                id: fv
                path: Qt.resolvedUrl(scope.wallpaperPath)
                watchChanges: true
                onFileChanged: ipc.reload()
            }

            Component.onCompleted: {
                ipc.reload();
            }
        }
    }
}
