pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs

PanelWindow {
    id: root

    required property var entries
    required property var filteredEntries
    required property string query
    required property bool open

    signal searchChanged(string searchText)
    signal restoreRequested(var entry)
    signal deleteRequested(var entry)
    signal clearRequested
    signal closeRequested

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.open

    anchors {
        left: true
        right: true
        bottom: true
    }

    exclusiveZone: -1
    implicitHeight: 560
    color: "transparent"

    Rectangle {
        id: card

        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 24
        }

        width: Math.min(720, parent.width - 32)
        height: Math.min(520, parent.height - 32)
        radius: Theme.radius
        color: Theme.bgnd
        border.color: Theme.acct
        border.width: 2
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.94

        Behavior on opacity {
            OpacityAnimator {
                duration: 100
            }
        }

        Behavior on scale {
            ScaleAnimator {
                duration: 100
                easing.type: Easing.OutCubic
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "Clipboard"
                    color: Theme.txt1
                    font.family: Theme.font
                    font.bold: true
                    font.pixelSize: 20
                }

                Item {
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.alignment: Qt.AlignRight
                    Layout.preferredWidth: clearLabel.implicitWidth + 24
                    Layout.preferredHeight: 32
                    radius: Theme.radius
                    color: Theme.mmry

                    Text {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: "clear"
                        color: Theme.bgnd
                        font.family: Theme.font
                        font.pixelSize: 14
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        onClicked: root.clearRequested()
                    }
                }
            }

            TextField {
                id: search

                Layout.fillWidth: true
                placeholderText: "Search clipboard history"
                placeholderTextColor: Theme.txt2
                font.family: Theme.font
                font.pixelSize: 15
                color: Theme.txt1
                padding: 15
                text: root.query
                focus: true
                selectByMouse: true

                background: Rectangle {
                    radius: Theme.radius
                    color: Qt.rgba(0, 0, 0, 0.5)
                    border.color: search.activeFocus ? Theme.acct : Theme.sptr
                    border.width: 2
                }

                onTextChanged: root.searchChanged(text)

                Keys.onPressed: function (event) {
                    if (event.key === Qt.Key_Escape) {
                        root.closeRequested();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down) {
                        historyView.currentIndex = Math.min(historyView.currentIndex + 1, historyView.count - 1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up) {
                        historyView.currentIndex = Math.max(0, historyView.currentIndex - 1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier)) {
                        if (historyView.count > 0)
                            historyView.currentIndex = (historyView.currentIndex + 1) % historyView.count;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && event.modifiers & Qt.ShiftModifier)) {
                        if (historyView.count > 0)
                            historyView.currentIndex = (historyView.currentIndex - 1 + historyView.count) % historyView.count;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (historyView.currentIndex >= 0)
                            root.restoreRequested(root.filteredEntries[historyView.currentIndex]);
                        event.accepted = true;
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.centerIn: parent

                    Text {
                        visible: historyView.count === 0
                        text: ":("
                        Layout.fillWidth: true
                        color: Theme.txt2
                        horizontalAlignment: Text.Center

                        font.family: Theme.font
                        font.pixelSize: 35
                    }

                    Text {
                        visible: historyView.count === 0
                        text: root.entries.length === 0 ? "no history" : "no results"
                        color: Theme.txt2

                        font.family: Theme.font
                        font.pixelSize: 25
                    }
                }

                ListView {
                    id: historyView

                    anchors.fill: parent
                    visible: count > 0
                    clip: true
                    spacing: 4
                    model: root.filteredEntries
                    currentIndex: count > 0 ? 0 : -1
                    ScrollBar.vertical: ScrollBar {}

                    delegate: ClipboardEntry {
                        required property var modelData
                        required property int index

                        width: historyView.width
                        entry: modelData
                        rowIndex: index
                        selected: historyView.currentIndex === index

                        onClicked: {
                            historyView.currentIndex = rowIndex;
                            root.restoreRequested(entry);
                        }
                        onDeleteRequested: root.deleteRequested(entry)
                    }
                }
            }
        }
    }
}
