pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs

Item {
    id: root
    visible: false

    property string ssid: ""
    signal passwordAccepted(string password)
    signal dismissed()

    // Dark scrim behind the form
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)
        radius: Theme.radius

        MouseArea { anchors.fill: parent }

        Rectangle {
            anchors.centerIn: parent
            width: 340
            height: form.implicitHeight + 40
            radius: Theme.radius
            color: Theme.bgnd2
            border.color: Theme.mmry
            border.width: 2

            Keys.onEscapePressed: function(e) { root.dismissed(); e.accepted = true }

            ColumnLayout {
                id: form
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 18
                    topMargin: 18
                }
                spacing: 10

                Text {
                    text: String.fromCodePoint(0xF033E) + "  Password for <b>" + root.ssid + "</b>"
                    font.pixelSize: 14
                    font.family: Theme.font
                    color: Theme.txt1
                    textFormat: Text.RichText
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: pwdInput.implicitHeight + 12
                    radius: Theme.radius
                    color: Theme.bgnd
                    border.color: pwdInput.activeFocus ? Theme.mmry : Theme.sptr
                    border.width: 2

                    TextInput {
                        id: pwdInput
                        anchors { fill: parent; margins: 8 }
                        echoMode: TextInput.Password
                        font.pixelSize: 14
                        font.family: Theme.font
                        color: Theme.txt1
                        focus: root.visible
                        Keys.onEscapePressed: function(e) { root.dismissed(); e.accepted = true }
                        onAccepted: root.passwordAccepted(pwdInput.text)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: cancelLbl.width + 20
                        height: cancelLbl.height + 8
                        radius: Theme.radius
                        color: "transparent"
                        border.color: Theme.sptr
                        border.width: 1
                        Text {
                            id: cancelLbl
                            anchors.centerIn: parent
                            text: "cancel"
                            font.pixelSize: 13
                            font.family: Theme.font
                            color: Theme.txt2
                        }
                        MouseArea { anchors.fill: parent; onClicked: root.dismissed() }
                    }

                    Rectangle {
                        width: connectLbl.width + 20
                        height: connectLbl.height + 8
                        radius: Theme.radius
                        color: Theme.mmry
                        Text {
                            id: connectLbl
                            anchors.centerIn: parent
                            text: "connect"
                            font.pixelSize: 13
                            font.family: Theme.font
                            color: Theme.bgnd
                        }
                        MouseArea { anchors.fill: parent; onClicked: root.passwordAccepted(pwdInput.text) }
                    }
                }
            }
        }
    }

    onVisibleChanged: if (!visible) pwdInput.text = ""
}
