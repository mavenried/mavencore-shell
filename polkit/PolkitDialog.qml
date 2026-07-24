import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

PanelWindow {
    id: root

    required property var flow
    property bool open: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusiveZone: -1
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    function submit() {
        if (!root.flow || !root.flow.isResponseRequired || !passwordField.text.length)
            return;
        root.flow.submit(passwordField.text);
        passwordField.text = "";
    }

    function cancel() {
        if (root.flow)
            root.flow.cancelAuthenticationRequest();
    }

    onOpenChanged: if (open)
        Qt.callLater(function () {
            card.forceActiveFocus();
        })

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.72)
        opacity: root.open ? 1 : 0
        Behavior on opacity {
            OpacityAnimator {
                duration: 280
            }
        }
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: 420
        implicitHeight: col.implicitHeight + 60
        radius: Theme.radius
        color: Theme.bgnd
        border.color: Theme.acct
        border.width: 2

        opacity: root.open ? 1 : 0
        scale: root.open ? 1.0 : 0.94

        Behavior on opacity {
            OpacityAnimator {
                duration: 280
            }
        }
        Behavior on scale {
            ScaleAnimator {
                duration: 280
                easing.type: Easing.OutCubic
            }
        }

        Keys.onPressed: function (event) {
            if (event.key === Qt.Key_Escape) {
                root.cancel();
            }
        }

        Component.onCompleted: card.forceActiveFocus()

        Column {
            id: col

            anchors.centerIn: parent
            width: parent.width - 60
            spacing: 14

            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.flow && root.flow.iconName !== ""
                source: root.flow && root.flow.iconName ? Quickshell.iconPath(root.flow.iconName, true) : ""
                width: 48
                height: 48
                fillMode: Image.PreserveAspectFit
            }

            Text {
                width: parent.width
                text: root.flow ? root.flow.message : ""
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: 13
                font.family: Theme.font
                color: Theme.txt1
            }

            Rectangle {
                id: inputBox

                width: parent.width
                height: 40
                radius: 18
                visible: root.flow && root.flow.isResponseRequired
                color: "#99000000"
                border.width: 2
                border.color: root.flow && root.flow.failed ? "#cc241d" : Theme.acct

                onVisibleChanged: if (visible)
                    passwordField.forceActiveFocus()

                Behavior on border.color {
                    ColorAnimation {
                        duration: 300
                    }
                }

                TextInput {
                    id: passwordField
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: root.flow && root.flow.responseVisible ? TextInput.Normal : TextInput.Password
                    passwordCharacter: "*"
                    font.pointSize: 12
                    font.family: Theme.font
                    color: Theme.txt1

                    Keys.onReturnPressed: root.submit()
                    Keys.onEnterPressed: root.submit()
                    Keys.onEscapePressed: root.cancel()

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.flow ? root.flow.inputPrompt : ""
                        font: passwordField.font
                        color: Theme.txt2
                        visible: passwordField.text.length === 0
                    }
                }
            }

            Text {
                width: parent.width
                visible: root.flow && root.flow.supplementaryMessage !== ""
                text: root.flow ? root.flow.supplementaryMessage : ""
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: 10
                font.family: Theme.font
                color: root.flow && root.flow.supplementaryIsError ? "#cc241d" : Theme.txt2
            }
        }
    }
}
