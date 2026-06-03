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

    required property string savePath
    property bool open: false
    property string scratchContent: ""

    Component.onCompleted: {
        scratchContent = fv.text()
    }

    IpcHandler {
        id: handler
        target: "scratchpad"
        function toggle() {
            root.open = !root.open
            loader.active = true
            if (!root.open) {
                fv.setText(root.scratchContent)
                closeTimer.start()
            }
        }
    }
    Timer {
        id: closeTimer
        interval: 250
        onTriggered: {
            loader.active = root.open
        }
    }
    FileView {
        id: fv
        path: root.savePath
        blockLoading: true
    }

    LazyLoader {
        id: loader

        PanelWindow {
            id: runnerWindow
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

            Component.onCompleted: Qt.callLater(function() { text.forceActiveFocus() })

            Rectangle {
                id: inner
                anchors.centerIn: parent
                width: parent.width * 0.8
                height: parent.height * 0.8
                anchors.margins: 50
                anchors.top: parent.top
                radius: Theme.radius
                color: Theme.bgnd
                border.color: Theme.acct
                border.width: 2

                opacity: root.open ? 1 : 0

                Behavior on opacity {
                    OpacityAnimator {
                        duration: 200
                    }
                }

                ScrollView {
                    anchors.fill: parent
                    TextArea {
                        id: text
                        focus: true
                        padding: 20
                        font.pixelSize: 20
                        font.family: Theme.font
                        color: Theme.txt1
                        background: Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.color: Theme.acct
                            radius: 15
                            border.width: 2
                        }

                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Escape) {
                                handler.toggle()
                                event.accepted = true
                            }
                        }

                        Component.onCompleted: {
                            this.text = root.scratchContent
                            cursorPosition = this.text.length
                        }

                        onTextChanged: root.scratchContent = this.text
                    }
                }
            }
        }
    }
}
