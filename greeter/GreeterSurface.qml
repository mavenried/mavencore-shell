import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Greetd
import Quickshell.Io
import QtQuick
import qs

Item {
    id: root

    property string blurPath: ""
    property string avatarPath: ""
    property string lastUserPath: ""
    property string defaultUser: ""

    property string step: "connecting" // connecting | prompt | launching
    property string promptLabel: "Connecting…"
    property bool promptEcho: false
    property bool respFailed: false
    property string failText: ""
    property bool _authStarted: false

    property bool powerArmed: false
    property string powerAction: ""

    property string currentHour: Qt.formatTime(new Date(), "hh")
    property string currentMinute: Qt.formatTime(new Date(), "mm")
    property string currentDate: Qt.formatDate(new Date(), "dddd, d MMMM")
    readonly property string batteryText: BatteryStats.icon + " " + BatteryStats.level.toFixed(0) + "%"

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            const now = new Date();
            root.currentHour = Qt.formatTime(now, "hh");
            root.currentMinute = Qt.formatTime(now, "mm");
            root.currentDate = Qt.formatDate(now, "dddd, d MMMM");
        }
    }

    Loader {
        id: lastUserLoader
        active: root.lastUserPath.length > 0
        sourceComponent: PersistentFile {
            path: root.lastUserPath
        }
    }

    function _preferredUsername() {
        const saved = lastUserLoader.item ? lastUserLoader.item.read().trim() : "";
        return saved.length ? saved : root.defaultUser;
    }

    function _maybeStartAuth() {
        if (root._authStarted || !Users.users.length)
            return;
        const preferred = root._preferredUsername();
        if (preferred)
            Users.selectByName(preferred);
        root._authStarted = true;
        root._startAuth();
    }

    function _startAuth() {
        root.step = "connecting";
        root.promptLabel = "Connecting…";
        root.promptEcho = false;
        root.respFailed = false;
        root.failText = "";
        inputField.text = "";
        Greetd.createSession(Users.current);
    }

    function _changeUser(dir) {
        Greetd.cancelSession();
        if (dir > 0)
            Users.next();
        else
            Users.prev();
        root._startAuth();
    }

    Component.onCompleted: root._maybeStartAuth()

    Connections {
        target: Users
        function onUsersChanged() {
            root._maybeStartAuth();
        }
    }

    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            root.step = "prompt";
            root.promptLabel = message || "Response";
            root.promptEcho = echoResponse;
            inputField.text = "";
            inputField.forceActiveFocus();
            if (!responseRequired)
                autoRespond.restart();
        }

        function onAuthFailure(message) {
            root.respFailed = true;
            root.failText = message || "Authentication failed";
            shakeAnim.restart();
            resetTimer.restart();
        }

        function onReadyToLaunch() {
            root.step = "launching";
            const s = Sessions.current;
            if (lastUserLoader.item)
                lastUserLoader.item.save(Greetd.user);
            Greetd.launch(["sh", "-c", s ? s.exec : "$SHELL -l"], [`XDG_SESSION_TYPE=${s ? s.type : "wayland"}`], true);
        }

        function onError(err) {
            root.respFailed = true;
            root.failText = err;
            shakeAnim.restart();
            resetTimer.restart();
        }
    }

    Timer {
        id: autoRespond
        interval: 400
        onTriggered: Greetd.respond("")
    }

    Timer {
        id: resetTimer
        interval: 1500
        onTriggered: root._startAuth()
    }

    Timer {
        id: powerDisarm
        interval: 2500
        onTriggered: root.powerArmed = false
    }

    Process {
        id: poweroffProc
        command: ["systemctl", "poweroff"]
    }

    Process {
        id: rebootProc
        command: ["systemctl", "reboot"]
    }

    function _powerTap(action) {
        if (root.powerArmed && root.powerAction === action) {
            powerDisarm.stop();
            root.powerArmed = false;
            if (action === "poweroff")
                poweroffProc.running = true;
            else
                rebootProc.running = true;
        } else {
            root.powerAction = action;
            root.powerArmed = true;
            powerDisarm.restart();
        }
    }

    function _cancel() {
        inputField.text = "";
    }

    function _submit() {
        if (root.step !== "prompt")
            return;
        Greetd.respond(inputField.text);
        root.step = "connecting";
        root.promptLabel = "Verifying…";
        inputField.text = "";
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        source: root.blurPath ? "file://" + root.blurPath : ""
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
                family: Theme.font
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
                family: Theme.font
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
            x: 500 - 70
            y: -150 - 70
            width: 140
            height: 140
            radius: 70
            color: "transparent"
            border.color: Theme.bgnd
            border.width: 2
            Image {
                anchors.fill: parent
                source: root.avatarPath ? "file://" + root.avatarPath : ""
                visible: root.avatarPath.length > 0
            }
            Text {
                anchors.centerIn: parent
                visible: root.avatarPath.length === 0
                text: String.fromCodePoint(0xF007)
                font {
                    pointSize: 52
                    family: Theme.font
                }
                color: Theme.txt2
            }
        }

        Text {
            x: 500 - implicitWidth / 2
            y: -60 - implicitHeight / 2
            text: root.currentDate
            font {
                pointSize: 13
                family: Theme.font
            }
            color: Theme.txt2
        }

        // username switcher
        Row {
            x: 500 - implicitWidth / 2
            y: -25 - implicitHeight / 2
            spacing: 10

            Text {
                text: String.fromCodePoint(0xF053)
                font {
                    pointSize: 16
                    family: Theme.font
                }
                color: Theme.txt2
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    onClicked: root._changeUser(-1)
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 260
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                text: Users.current || "No user found"
                font {
                    pointSize: 14
                    family: Theme.font
                }
                color: Theme.txt1
            }
            Text {
                text: String.fromCodePoint(0xF054)
                font {
                    pointSize: 16
                    family: Theme.font
                }
                color: Theme.txt2
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    onClicked: root._changeUser(1)
                }
            }
        }

        // session switcher
        Row {
            x: 500 - implicitWidth / 2
            y: 10 - implicitHeight / 2
            spacing: 10

            Text {
                text: String.fromCodePoint(0xF053)
                font {
                    pointSize: 16
                    family: Theme.font
                }
                color: Theme.txt2
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    onClicked: Sessions.prev()
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 260
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                text: Sessions.current ? Sessions.current.name : "No session found"
                font {
                    pointSize: 14
                    family: Theme.font
                }
                color: Theme.txt1
            }
            Text {
                text: String.fromCodePoint(0xF054)
                font {
                    pointSize: 16
                    family: Theme.font
                }
                color: Theme.txt2
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    onClicked: Sessions.next()
                }
            }
        }

        Item {
            id: pwAnchor
            x: 500 - 100
            y: 55 - 25

            width: 200
            height: 50

            SequentialAnimation {
                id: shakeAnim
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
                border.color: root.respFailed ? Theme.err : Theme.acct
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
                            root._cancel();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Tab) {
                            Sessions.next();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Backtab) {
                            Sessions.prev();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            root._changeUser(-1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down) {
                            root._changeUser(1);
                            event.accepted = true;
                        }
                    }

                    TextInput {
                        id: inputField
                        enabled: root.step === "prompt"
                        cursorDelegate: Item {}
                        anchors {
                            fill: parent
                            leftMargin: 8
                            rightMargin: 8
                        }
                        echoMode: root.promptEcho ? TextInput.Normal : TextInput.Password
                        passwordCharacter: " "
                        font {
                            pointSize: 14
                            family: Theme.font
                        }
                        color: root.respFailed ? Theme.err : Theme.txt1
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
                            text: root.step !== "prompt" ? root.promptLabel : ""
                            font: inputField.font
                            color: Theme.txt2
                            visible: inputField.text.length === 0
                        }

                        Keys.onReturnPressed: root._submit()
                        Keys.onEnterPressed: root._submit()

                        Row {
                            anchors.centerIn: parent
                            spacing: 2
                            visible: root.step === "prompt" && !root.promptEcho

                            Repeater {
                                model: inputField.text.length

                                delegate: Item {
                                    width: 10
                                    height: 10

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 10
                                        height: 10
                                        radius: 5
                                        color: root.respFailed ? Theme.err : Theme.txt1
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
                    family: Theme.font
                }
                color: Theme.err
                opacity: root.respFailed ? 1.0 : 0.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                    }
                }
            }
        }

        Text {
            visible: CapsLock.active
            x: 500 - implicitWidth / 2
            y: 120 - implicitHeight / 2
            text: String.fromCodePoint(0xF071) + " caps lock is on"
            font {
                pointSize: 12
                family: Theme.font
            }
            color: Theme.err
        }

        Text {
            width: 360
            x: 500 - width / 2
            y: 155 - implicitHeight / 2
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: root.step === "launching" ? "Launching…" : "enter confirm · tab/↑↓ switch · esc clear"
            font {
                pointSize: 11
                family: Theme.font
            }
            color: Theme.txt2
        }

        Row {
            x: 500 - implicitWidth / 2
            y: 195 - implicitHeight / 2
            spacing: 50

            Text {
                text: String.fromCodePoint(0xF011)
                font {
                    pointSize: 20
                    family: Theme.font
                }
                color: root.powerArmed && root.powerAction === "poweroff" ? Theme.err : Theme.txt2
                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -12
                    onClicked: root._powerTap("poweroff")
                }
            }
            Text {
                text: String.fromCodePoint(0xF021)
                font {
                    pointSize: 20
                    family: Theme.font
                }
                color: root.powerArmed && root.powerAction === "reboot" ? Theme.err : Theme.txt2
                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -12
                    onClicked: root._powerTap("reboot")
                }
            }
        }

        Text {
            visible: root.powerArmed
            x: 500 - implicitWidth / 2
            y: 225 - implicitHeight / 2
            text: "tap again to confirm"
            font {
                pointSize: 10
                family: Theme.font
            }
            color: Theme.err
        }

        Text {
            visible: !Greetd.available
            width: 360
            x: 500 - width / 2
            y: 260 - implicitHeight / 2
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: "greetd socket not available"
            font {
                pointSize: 12
                family: Theme.font
            }
            color: Theme.err
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
                family: Theme.font
            }
            color: Theme.disk
        }
    }
}
