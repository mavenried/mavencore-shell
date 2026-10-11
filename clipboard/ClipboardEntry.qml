pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs

Rectangle {
    id: root

    required property var entry
    required property bool selected
    required property int rowIndex

    signal clicked
    signal deleteRequested

    implicitHeight: 52
    radius: Theme.radius
    color: selected ? Qt.rgba(0, 0, 0, 0.5) : "transparent"
    border.color: selected ? Theme.acct : "transparent"
    border.width: selected ? 2 : 0

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 8
        spacing: 10

        Text {
            Layout.fillWidth: true
            text: root.entry.preview
            color: Theme.txt1
            font.family: Theme.font
            font.pixelSize: 14
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        Rectangle {
            id: deleteButton

            Layout.preferredWidth: deleteLabel.implicitWidth + 20
            Layout.preferredHeight: 30
            radius: Theme.radius
            color: "transparent"
            border.color: Theme.sptr
            border.width: 1

            Text {
                id: deleteLabel
                anchors.centerIn: parent
                text: "del"
                color: Theme.txt2
                font.family: Theme.font
                font.pixelSize: 11
            }

            MouseArea {
                id: deleteMouse
                anchors.fill: parent
                onClicked: root.deleteRequested()
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.rightMargin: deleteButton.width + 8
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
