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
    property bool cmdMode: false

    property var apps: []
    property var searchText: ""
    property var filtered: {
        if (searchText.trim() === "" || root.cmdMode)
            return [];
        return root.apps.filter(a => a.name.toLowerCase().trim().includes(searchText.toLowerCase().trim()));
    }

    Process {
        id: proc
        command: ["sh", "-c", "mavencore apps-list"]
        running: false
        stdout: SplitParser {
            onRead: function (data) {
                try {
                    root.apps = root.apps.concat([JSON.parse(data)]);
                } catch (e) {
                    console.error(e);
                }
            }
        }
    }

    IpcHandler {
        id: handler
        target: "launcher"
        function open() {
            root.open = true;
            proc.running = true;
            root.apps = [];
        }

        function close() {
            root.open = false;
            root.apps = [];
            root.searchText = "";
        }
    }
    LazyLoader {
        active: root.open
        PanelWindow {
            id: runnerWindow
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            implicitHeight: 600

            anchors {
                bottom: true
                left: true
                right: true
            }
            exclusiveZone: -1
            color: "transparent"
            Rectangle {
                id: inner
                anchors.horizontalCenter: parent.horizontalCenter
                width: 700
                implicitHeight: col.height//search.implicitHeight + list.implicitHeight
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
                        handler.close();
                    } else if (event.key === Qt.Key_Return) {
                        if (!root.cmdMode) {
                            let path = root.filtered[list.currentIndex].path;
                            Quickshell.execDetached(["gio", "launch", path]);
                        } else {
                            Quickshell.execDetached(["sh", "-c", root.searchText.slice(1)]);
                        }
                        handler.close();
                    } else if (event.key === Qt.Key_Tab) {
                        list.currentIndex = (list.currentIndex + 1) % list.count;
                    } else if (event.key === Qt.Key_Backtab) {
                        list.currentIndex = (list.currentIndex - 1) % list.count;
                        if (list.currentIndex < 0)
                            list.currentIndex = list.count - 1;
                    }
                }
                ColumnLayout {
                    id: col
                    spacing: list.count > 0 ? 5 : 0
                    ListView {
                        id: list
                        implicitWidth: 700
                        implicitHeight: this.count < 10 ? this.count * 50 : 500
                        clip: true

                        Behavior on implicitHeight {
                            NumberAnimation {
                                duration: 100
                                easing.type: Easing.InOutQuad
                            }
                        }
                        model: root.filtered
                        currentIndex: 0

                        delegate: Rectangle {
                            id: item
                            required property var modelData

                            width: ListView.view.width
                            height: 50
                            color: ListView.isCurrentItem ? Qt.rgba(0, 0, 0, 0.5) : "transparent"
                            radius: 15
                            border.width: 2
                            border.color: ListView.isCurrentItem ? Theme.acct : "transparent"
                            Row {
                                height: name.implicitHeight
                                anchors.verticalCenter: parent.verticalCenter
                                width: name.implicitWidth
                                leftPadding: 10

                                Image {
                                    property string iconName: item.modelData.icon
                                    fillMode: Image.PreserveAspectFit
                                    source: "image://icon/" + iconName
                                    height: name.implicitHeight
                                    width: name.implicitHeight
                                }
                                Text {
                                    id: name
                                    leftPadding: 10
                                    text: item.modelData.name
                                    font.pixelSize: 20
                                    font.family: "JetbrainsMono Nerd Font"
                                    color: item.ListView.isCurrentItem ? Theme.txt1 : Theme.txt1
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: search
                        implicitHeight: text.implicitHeight
                        color: "transparent"
                        TextField {
                            id: text
                            padding: 10
                            focus: true
                            placeholderText: "Search..."
                            placeholderTextColor: Theme.txt2
                            font.pixelSize: 20
                            font.family: "JetbrainsMono Nerd Font"
                            color: Theme.txt1
                            background: Rectangle {
                                color: Qt.rgba(0, 0, 0, 0.5)
                                radius: 15
                                border.color: root.cmdMode ? Theme.wifi : Theme.acct
                                border.width: 2
                                width: 700
                            }
                            onTextChanged: function () {
                                root.searchText = this.text;
                                if (root.searchText.startsWith(":")) {
                                    root.cmdMode = true;
                                } else {
                                    root.cmdMode = false;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
