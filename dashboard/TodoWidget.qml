pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

WidgetCard {
    id: root
    required property string savePath

    implicitHeight: layout.implicitHeight + 28

    property var items: []

    PersistentFile {
        id: pf
        path: root.savePath
        saveInterval: 400
    }

    function _serialize() {
        var lines = root.items.map(function (i) {
            if (i.type === "group")
                return "# " + i.text;
            return (i.done ? "[x] " : "[ ] ") + i.text;
        });
        var text = lines.join("\n");
        pf.save(text.length ? text + "\n" : "");
    }

    Component.onCompleted: {
        var lines = pf.read().split("\n").filter(l => l.trim());
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
                    spacing: 10

                    Text {
                        text: entry.modelData.text.toUpperCase()
                        color: Theme.mmry
                        font.pixelSize: 14
                        font.bold: true
                        font.family: Theme.font
                        font.letterSpacing: 1
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Theme.mmry
                        opacity: 0.6
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Text {
                        text: String.fromCodePoint(0xD7)
                        color: Theme.acct
                        font.pixelSize: 13
                        font.family: Theme.font
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            onClicked: {
                                var a = root.items.slice();
                                a.splice(entry.index, 1);
                                root.items = a;
                                root._serialize();
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
                    spacing: 10

                    Rectangle {
                        width: 20
                        height: 20
                        radius: 4
                        Layout.alignment: Qt.AlignTop
                        color: entry.modelData.done ? Theme.pfle : "transparent"
                        border.color: entry.modelData.done ? Theme.pfle : Qt.rgba(1, 1, 1, 0.2)
                        border.width: 2
                        Text {
                            anchors.centerIn: parent
                            text: String.fromCodePoint(0x00d7)
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
                        wrapMode: Text.Wrap
                    }

                    Text {
                        text: String.fromCodePoint(0xD7)
                        color: Theme.acct
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
                                root._serialize();
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
                        root._serialize();
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            TextField {
                id: inputField
                Layout.fillWidth: true
                placeholderText: "#<group> [task] or [task]"
                placeholderTextColor: Theme.txt2
                color: Theme.txt1
                font.pixelSize: 20
                font.family: Theme.font
                leftPadding: 8
                background: Rectangle {
                    radius: 6
                    color: Qt.rgba(0, 0, 0, 0.2)
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

                        var groupIdx = -1;
                        for (var i = 0; i < a.length; i++) {
                            if (a[i].type === "group" && a[i].text.toLowerCase() === groupName.toLowerCase()) {
                                groupIdx = i;
                                break;
                            }
                        }

                        if (groupIdx === -1) {
                            a.push({
                                type: "group",
                                text: groupName
                            });
                            groupIdx = a.length - 1;
                        }

                        if (taskText) {
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
                        // Ungrouped tasks go to the top
                        root.items = [
                            {
                                type: "item",
                                done: false,
                                text: t
                            }
                        ].concat(root.items);
                    }

                    inputField.text = "";
                    root._serialize();
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
