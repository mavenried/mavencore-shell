pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

WidgetCard {
    id: root
    required property string savePath

    PersistentFile {
        id: pf
        path: root.savePath
        saveInterval: 1000
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Text {
            text: "󰈚 Notes"
            Layout.margins: 4
            color: Theme.txt1
            font.pixelSize: 20
            font.bold: true
            font.family: Theme.font
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Qt.rgba(0, 0, 0, 0.2)
            radius: Theme.radius

            ScrollView {
                anchors.fill: parent
                clip: true

                TextArea {
                    id: editor
                    padding: 10
                    color: Theme.txt1
                    font.pixelSize: 16
                    font.family: Theme.font
                    wrapMode: TextArea.Wrap
                    background: null
                    selectByMouse: true

                    Component.onCompleted: {
                        this.text = pf.read();
                        cursorPosition = this.text.length;
                    }

                    onTextChanged: pf.save(editor.text)
                }
            }
        }
    }
}
