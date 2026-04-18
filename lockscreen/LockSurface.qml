import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import qs

Item {
    id: root

    required property var context

    property string fpState: "idle"
    property bool pwFailed: false
    property string failText: ""

    property string currentHour: Qt.formatTime(new Date(), "hh")
    property string currentMinute: Qt.formatTime(new Date(), "mm")
    property string uptimeText: ""
    property string batteryText: ""

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.currentHour = Qt.formatTime(new Date(), "hh");
            root.currentMinute = Qt.formatTime(new Date(), "mm");
        }
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: uptimeProc.running = true
    }
    Process {
        id: uptimeProc
        command: ["zsh", "-c", "mavencore uptime"]
        stdout: SplitParser {
            onRead: data => root.uptimeText = " " + data.trim()
        }
    }
    // process {
    //     id: getUsername
    //     command:
    // }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: batteryProc.running = true
    }
    Process {
        id: batteryProc
        command: ["/mnt/DATA/scripts/battery"]
        stdout: SplitParser {
            onRead: data => root.batteryText = data.trim()
        }
    }

    Component.onCompleted: {
        context.unlocked.connect(_onUnlocked);
        context.authFailed.connect(_onFail);
        root._kickFp();
        passwordField.forceActiveFocus();
    }
    Component.onDestruction: {
        context.unlocked.disconnect(_onUnlocked);
        context.authFailed.disconnect(_onFail);
    }

    function _kickFp() {
        fpState = "scanning";
        context.startFingerprint();
    }
    function _onUnlocked() {
        fpState = "ok";
    }
    function _onFail(reason) {
        const fp = reason.toLowerCase().includes("finger") || reason.toLowerCase().includes("scan") || reason.toLowerCase().includes("recogni");
        if (fp) {
            fpState = "fail";
            fpRetryTimer.restart();
        } else {
            pwFailed = true;
            failText = "Auth Failure";
            shakeAnim.restart();
            clearTimer.restart();
        }
    }
    function _submitPassword() {
        const pw = passwordField.text;
        if (!pw.length)
            return;
        context.cancelFingerprint();
        context.submitPassword(pw);
        // passwordField.text = "";
    }

    Timer {
        id: fpRetryTimer
        interval: 1800
        onTriggered: root._kickFp()
    }

    Timer {
        id: clearTimer
        interval: 1000
        onTriggered: {
            root.pwFailed = false;
            root.failText = "";
            passwordField.text = "";
            passwordField.forceActiveFocus();
            root._kickFp();
        }
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        source: "file:///mnt/DATA/Pictures/CURRENT_BLUR"
        visible: true
    }
    Item {
        id: centreAnchor
        anchors.centerIn: parent
        width: 0
        height: 0

        Rectangle {
            x: -500 - 300
            y: -400
            width: 600
            height: 800
            radius: 90
            color: Theme.bgnd
            border.color: Theme.acct
            border.width: 2
        }
        Text {
            x: -500 - implicitWidth / 2
            y: -150 - implicitHeight / 2
            text: root.currentHour
            font {
                pointSize: 250
                family: "JetBrains Mono Nerd Font"
            }
            renderType: Text.CurveRendering
            color: Theme.mmry
        }

        Text {
            x: -500 - implicitWidth / 2
            y: 150 - implicitHeight / 2
            text: root.currentMinute
            font {
                pointSize: 250
                family: "JetBrains Mono Nerd Font"
            }
            renderType: Text.CurveRendering
            color: Theme.cpuc
        }

        Rectangle {
            x: 500 - 200
            y: -300
            width: 400
            height: 600
            radius: 90
            color: Theme.bgnd
            border.color: Theme.acct
            border.width: 2
        }

        ClippingRectangle {
            x: 500 - 80
            y: -50 - 80
            width: 160
            height: 160
            radius: 80
            color: "transparent"
            border.color: Theme.bgnd
            border.width: 2
            Image {
                anchors.fill: parent
                source: "file:///mnt/DATA/Pictures/AVATAR"
            }
        }

        Text {
            x: 500 - implicitWidth / 2
            y: -200 - implicitHeight / 2
            text: root.uptimeText
            font {
                pointSize: 25
                family: "JetBrains Mono Nerd Font"
            }
            color: Theme.uptm
        }

        Text {
            x: 500 - implicitWidth / 2
            y: 100 - implicitHeight / 2
            text: Quickshell.env("USER")
            font {
                pointSize: 30
                family: "JetBrains Mono Nerd Font"
            }
            color: Theme.txt1
        }

        Item {
            id: pwAnchor
            x: 500 - 100
            y: 180 - 25

            width: 200
            height: 50

            SequentialAnimation {
                id: shakeAnim
                property real base: 500 - 100
                NumberAnimation {
                    target: pwAnchor
                    property: "x"
                    to: pwAnchor.x + 10
                    duration: 50
                }
                NumberAnimation {
                    target: pwAnchor
                    property: "x"
                    to: pwAnchor.x - 20
                    duration: 50
                }
                NumberAnimation {
                    target: pwAnchor
                    property: "x"
                    to: pwAnchor.x + 14
                    duration: 50
                }
                NumberAnimation {
                    target: pwAnchor
                    property: "x"
                    to: pwAnchor.x - 14
                    duration: 50
                }
                NumberAnimation {
                    target: pwAnchor
                    property: "x"
                    to: 500 - 100
                    duration: 50
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: 25
                color: "transparent"
                border.width: 2
                border.color: root.pwFailed ? "#cc241d" : Theme.acct
                Behavior on border.color {
                    ColorAnimation {
                        duration: 300
                    }
                }

                Rectangle {
                    anchors {
                        fill: parent
                        margins: 2
                    }
                    color: "#99000000"
                    radius: 25

                    Keys.onPressed: function (event) {
                        if (event.key === Qt.Key_Escape) {
                            passwordField.clear();
                        }
                    }

                    TextInput {
                        id: passwordField
                        cursorDelegate: Item {}
                        anchors {
                            fill: parent
                            leftMargin: 8
                            rightMargin: 8
                        }
                        echoMode: TextInput.Password
                        passwordCharacter: " "
                        font {
                            pointSize: 14
                            family: "JetBrainsMonoNL Nerd Font"
                        }
                        color: root.pwFailed ? "#cc241d" : Theme.txt1
                        verticalAlignment: TextInput.AlignVCenter
                        horizontalAlignment: TextInput.AlignHCenter
                        focus: true

                        Behavior on color {
                            ColorAnimation {
                                duration: 300
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "Enter Passwd"
                            font: passwordField.font
                            color: Theme.txt2
                            visible: passwordField.text.length === 0
                        }

                        Keys.onReturnPressed: root._submitPassword()
                        Keys.onEnterPressed: root._submitPassword()
                        onTextChanged: {
                            if (root.fpState !== "scanning")
                                root._kickFp();
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 2

                            Repeater {
                                model: passwordField.text.length

                                delegate: Item {

                                    width: 10
                                    height: 10

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 10
                                        height: 10
                                        radius: 5
                                        color: root.pwFailed ? "#cc241d" : Theme.txt1
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 300
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Text {
                anchors {
                    top: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }
                anchors.topMargin: 6
                text: root.failText
                font {
                    pointSize: 12
                    family: "JetBrains Mono Nerd Font"
                }
                color: "#cc241d"
                opacity: root.pwFailed ? 1.0 : 0.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 5
        anchors.rightMargin: 5
        width: 85
        height: 35
        radius: 15
        color: Theme.bgnd
        border.color: Theme.acct
        border.width: 2

        Text {
            anchors.centerIn: parent
            text: root.batteryText
            font {
                pointSize: 12
                family: "JetBrains Mono Nerd Font"
            }
            color: Theme.disk
        }
    }
}
