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
    property var apps: []
    property var searchText: ""
    property var filteredApps: {
        if (searchText.trim() === "")
            return [];
        return root.apps.filter(a => a.name.toLowerCase().trim().includes(this.text.toLowerCase().trim()));
    }

    Process {
        id: proc
        command: ["sh", "-c", "mavencore apps-list"]
        running: true
        stdout: SplitParser {
            onRead: function (data) {
                // console.log(data);
                try {
                    root.apps = root.apps.concat([JSON.parse(data)]);
                    // console.log(JSON.stringify(root.apps));
                } catch (e) {
                    console.error(e);
                }
            }
        }
    }
    IpcHandler {
        target: "launcher"
        function open() {
            console.log("opening runner.");
            root.open = true;
            proc.running = true;
        }

        function close() {
            console.log("closing runner.");
            root.open = false;
        }
    }
    LazyLoader {
        active: root.open
        PanelWindow {
            id: runnerWindow
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            implicitHeight: inner.height + 100
            anchors {
                bottom: true
                left: true
                right: true
            }
            exclusiveZone: -1
            color: "transparent"
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 700
                implicitHeight: inner.height
                anchors.margins: 10
                anchors.bottom: parent.bottom
                radius: Theme.radius
                color: Theme.bgnd
                border.color: Theme.acct
                border.width: 2
                Keys.onPressed: function (event) {
                    console.log("Key pressed:", event.key);
                    if (event.key === Qt.Key_Escape) {
                        console.log("Escape pressed!");
                        root.open = false;
                    }
                }
                ColumnLayout {
                    id: inner

                    Rectangle {
                        Layout.margins: 5
                        implicitHeight: text.implicitHeight
                        TextField {
                            id: text
                            padding: 10
                            focus: true
                            placeholderText: "Search..."
                            placeholderTextColor: Theme.txt2
                            cursorVisible: false
                            font.pixelSize: 20
                            font.family: "JetbrainsMono Nerd Font"
                            color: Theme.txt1
                            background: Rectangle {
                                color: Theme.bgnd
                                border.color: Theme.accent
                                radius: 10
                                width: 690
                            }
                            onTextChanged: function () {
                                root.searchText = this.text;
                            }
                        }
                    }

                    ListView {
                        id: list
                        Layout.margins: 5
                        width: 690
                        height: 500
                        clip: true

                        model: root.filteredApps
                        currentIndex: 0

                        delegate: Rectangle {
                            required property var modelData

                            width: ListView.view.width
                            height: 50
                            color: ListView.isCurrentItem ? Theme.accent : "transparent"

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                leftPadding: 10
                                text: modelData.name
                                font.pixelSize: 20
                                font.family: "JetbrainsMono Nerd Font"
                                color: Theme.txt1
                            }
                        }
                    }
                }
            }
        }
    }
}
