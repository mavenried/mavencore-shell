pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import qs

Rectangle {
    id: root
    required property string savePath

    color: "#1c1c1c"
    radius: Theme.radius
    border.color: Theme.sptr
    border.width: 1

    implicitHeight: layout.implicitHeight + 28

    property var items: []

    FileView {
        id: fv
        path: root.savePath
        blockLoading: true
    }

    Timer {
        id: saveTimer
        interval: 400
        onTriggered: {
            var lines = root.items.map(function (i) {
                if (i.type === "group")
                    return "# " + i.text;
                return (i.done ? "[x] " : "[ ] ") + i.text;
            });
            var text = lines.join("\n");
            fv.setText(text.length ? text + "\n" : "");
        }
    }

    Component.onCompleted: {
        var lines = fv.text().split("\n").filter(l => l.trim());
        root.items = lines.map(function (l) {
            if (l.startsWith("# "))
                return {
                    type: "group",
                    text: l.slice(2)
                };
            if (l.startsWith("[x] "))
                return {
                    type: "item",
                    done: true,
                    text: l.slice(4)
                };
            if (l.startsWith("[ ] "))
                return {
                    type: "item",
                    done: false,
                    text: l.slice(4)
                };
            return {
                type: "item",
                done: false,
                text: l
            };
        });
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 14
        spacing: 4

        Text {
            text: "Todo"
            color: Theme.txt1
            font.pixelSize: 20
            font.bold: true
            font.family: Theme.font
            Layout.bottomMargin: 4
        }

        Repeater {
            model: root.items
            delegate: Item {
                id: entry
                required property var modelData
                required property int index

                Layout.fillWidth: true
                // Height follows whichever row is active — no fixed size
                implicitHeight: modelData.type === "group" ? groupRow.implicitHeight + (index > 0 ? 12 : 0) : itemRow.implicitHeight + 4

                // ── Group header ─────────────────────────────────────
                RowLayout {
                    id: groupRow
                    visible: entry.modelData.type === "group"
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    anchors.top: parent.top
                    anchors.topMargin: entry.index > 0 ? 12 : 0
                    spacing: 8

                    Text {
                        text: entry.modelData.text.toUpperCase()
                        color: Theme.wifi
                        font.pixelSize: 11
                        font.bold: true
                        font.family: Theme.font
                        font.letterSpacing: 1
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Theme.sptr
                        opacity: 0.6
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Text {
                        text: "×"
                        color: Theme.sptr
                        font.pixelSize: 13
                        font.family: Theme.font
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            onClicked: {
                                var a = root.items.slice();
                                a.splice(entry.index, 1);
                                root.items = a;
                                saveTimer.restart();
                            }
                        }
                    }
                }

                // ── Todo item ─────────────────────────────────────────
                RowLayout {
                    id: itemRow
                    visible: entry.modelData.type === "item"
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                    }
                    anchors.leftMargin: 2
                    anchors.rightMargin: 2
                    spacing: 8

                    Rectangle {
                        width: 16
                        height: 16
                        radius: 4
                        Layout.alignment: Qt.AlignTop
                        color: entry.modelData.done ? Theme.pfle : "transparent"
                        border.color: entry.modelData.done ? Theme.pfle : Theme.sptr
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "✓"
                            color: Theme.bgnd
                            font.pixelSize: 12
                            visible: entry.modelData.done
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: entry.modelData.text
                        color: entry.modelData.done ? Theme.txt2 : Theme.txt1
                        font.pixelSize: 16
                        font.family: Theme.font
                        font.strikeout: entry.modelData.done
                        wrapMode: Text.Wrap   // expands vertically instead of cutting off
                    }

                    Text {
                        text: "×"
                        color: Theme.sptr
                        font.pixelSize: 16
                        font.family: Theme.font
                        Layout.alignment: Qt.AlignTop
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            onClicked: {
                                var a = root.items.slice();
                                a.splice(entry.index, 1);
                                root.items = a;
                                saveTimer.restart();
                            }
                        }
                    }
                }

                MouseArea {
                    enabled: entry.modelData.type === "item"
                    anchors {
                        fill: parent
                        rightMargin: 28
                    }
                    onClicked: {
                        var a = root.items.slice();
                        a[entry.index] = {
                            type: "item",
                            done: !entry.modelData.done,
                            text: entry.modelData.text
                        };
                        root.items = a;
                        saveTimer.restart();
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            TextField {
                id: inputField
                Layout.fillWidth: true
                placeholderText: "#group [task] or just type a task"
                placeholderTextColor: Theme.txt2
                color: Theme.txt1
                font.pixelSize: 16
                font.family: Theme.font
                leftPadding: 8
                background: Rectangle {
                    color: "#252525"
                    radius: 6
                }
                Keys.onReturnPressed: addBtn.add()
            }

            Rectangle {
                id: addBtn
                width: 28
                height: 28
                radius: 6
                color: Theme.pfle

                function add() {
                    var t = inputField.text.trim();
                    if (!t)
                        return;
                    var m = t.match(/^#(\S+)(?:\s+(.+))?$/);
                    if (m) {
                        var groupName = m[1];
                        var taskText = m[2] || null;
                        var a = root.items.slice();

                        // Find existing group (case-insensitive)
                        var groupIdx = -1;
                        for (var i = 0; i < a.length; i++) {
                            if (a[i].type === "group" && a[i].text.toLowerCase() === groupName.toLowerCase()) {
                                groupIdx = i;
                                break;
                            }
                        }

                        // Create group at end if missing
                        if (groupIdx === -1) {
                            a.push({
                                type: "group",
                                text: groupName
                            });
                            groupIdx = a.length - 1;
                        }

                        if (taskText) {
                            // Insert after the last item belonging to this group
                            var insertAt = groupIdx + 1;
                            while (insertAt < a.length && a[insertAt].type !== "group")
                                insertAt++;
                            a.splice(insertAt, 0, {
                                type: "item",
                                done: false,
                                text: taskText
                            });
                        }

                        root.items = a;
                    } else {
                        root.items = root.items.concat([
                            {
                                type: "item",
                                done: false,
                                text: t
                            }
                        ]);
                    }

                    inputField.text = "";
                    saveTimer.restart();
                }

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    color: Theme.bgnd
                    font.pixelSize: 18
                    font.bold: true
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: addBtn.add()
                }
            }
        }
    }
}
