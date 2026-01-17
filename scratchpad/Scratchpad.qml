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

    property string path: "/mnt/DATA/Documents/scratches/.mavencore-scratchpad" // pass in your path from shell.qml only. do not edit here :)
    property bool open: false

    IpcHandler {
        id: handler
        target: "scratchpad"
        function open() {
            root.open = true;
            loader.active = true;
        }

        function close() {
            root.open = false;
            closeTimer.start();
        }
    }
    Timer {
        id: closeTimer
        interval: 300
        onTriggered: {
            loader.active = root.open;
        }
    }
    FileView {
        id: fv
        path: Qt.resolvedUrl(root.path)
        onFileChanged: text.text = fv.text()
        onLoaded: {
            console.log(fv.text());
        }
        blockLoading: true
    }

    LazyLoader {
        id: loader

        PanelWindow {
            id: runnerWindow
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            implicitHeight: 700

            anchors {
                top: true
                left: true
                right: true
            }
            exclusiveZone: -1
            color: "transparent"
            Rectangle {
                id: inner
                anchors.horizontalCenter: parent.horizontalCenter
                width: 700
                height: 500
                // implicitHeight: col.height
                anchors.margins: 50
                anchors.top: parent.top
                radius: Theme.radius
                color: Theme.bgnd
                border.color: Theme.acct
                border.width: 2

                opacity: root.open ? 1 : 0

                Behavior on opacity {
                    OpacityAnimator {
                        duration: 100
                    }
                }

                Keys.onPressed: function (event) {
                    console.log("Key pressed:", event.key);
                    if (event.key === Qt.Key_Escape) {
                        console.log("Escape pressed!");
                        fv.setText(text.text)
                        handler.close();
                    }
                }

                ScrollView {
                    anchors.fill: parent
                    focus: true
                    TextArea {
                        id: text
                        focus: true
                        padding: 10
                        text: fv.text()

                        font.pixelSize: 20
                        font.family: "JetbrainsMono Nerd Font"
                        color: Theme.txt1
                        background: Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            radius: 15
                            border.width: 2
                        }
                        Component.onCompleted: {
                            cursorPosition = text.text.length;
                        }
                    }
                }
            }
        }
    }
}
