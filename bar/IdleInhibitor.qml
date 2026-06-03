import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property color labelColor

    width: content.width
    height: content.height

    Module {
        id: content

        label: IdleInhibitorState.active ? String.fromCodePoint(0xF0F4) + "   on" : String.fromCodePoint(0xF0F4) + "  off"
        labelColor: root.labelColor
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            IdleInhibitorState.active = !IdleInhibitorState.active;
        }
    }
}
