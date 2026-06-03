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

    FileView {
        id: fv
        path: root.savePath
        blockLoading: true
    }

    // Debounce: save 1s after the last keystroke
    Timer {
        id: saveTimer
        interval: 1000
        onTriggered: fv.setText(editor.text)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        Text {
            text: "Notes"
            color: Theme.txt1
            font.pixelSize: 15
            font.bold: true
            font.family: Theme.font
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            radius: Theme.radius

            ScrollView {
                anchors.fill: parent
                clip: true

                TextArea {
                    id: editor
                    padding: 4
                    color: Theme.txt1
                    font.pixelSize: 14
                    font.family: Theme.font
                    wrapMode: TextArea.Wrap
                    background: null
                    selectByMouse: true

                    Component.onCompleted: {
                        this.text = fv.text()
                        cursorPosition = this.text.length
                    }

                    onTextChanged: saveTimer.restart()
                }
            }
        }
    }
}
