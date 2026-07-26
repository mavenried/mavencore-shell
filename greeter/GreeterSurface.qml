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
    property string lastSessionPath: ""
    property string defaultUser: ""
    property bool _sessionSelected: false

    property string step: "connecting"
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

    Loader {
        id: lastSessionLoader
        active: root.lastSessionPath.length > 0
        sourceComponent: PersistentFile {
            path: root.lastSessionPath
        }
    }

    function _preferredUsername() {
        const saved = lastUserLoader.item ? lastUserLoader.item.read().trim() : "";
        return saved.length ? saved : root.defaultUser;
    }

    function _maybeSelectSession() {
        if (root._sessionSelected || !Sessions.sessions.length)
            return;
        root._sessionSelected = true;
        const preferred = lastSessionLoader.item ? lastSessionLoader.item.read().trim() : "";
        if (preferred)
            Sessions.selectByName(preferred);
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

    Component.onCompleted: {
        root._maybeSelectSession();
        root._maybeStartAuth();
    }

    Connections {
        target: Users
        function onUsersChanged() {
            root._maybeStartAuth();
        }
    }

    Connections {
        target: Sessions
        function onSessionsChanged() {
            root._maybeSelectSession();
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
            if (lastSessionLoader.item && s)
                lastSessionLoader.item.save(s.name);
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

    Process {
        id: hibernateProc
        command: ["systemctl", "hibernate"]
    }

    function _powerTap(action) {
        if (root.powerArmed && root.powerAction === action) {
            powerDisarm.stop();
            root.powerArmed = false;
            if (action === "poweroff")
                poweroffProc.running = true;
            else if (action === "reboot")
                rebootProc.running = true;
            else if (action === "hibernate")
                hibernateProc.running = true;
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

    Rectangle {
        anchors.fill: parent
        color: "#66000000"
    }

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 - 460
        width: clockText.implicitWidth
        height: clockText.implicitHeight + dateText.implicitHeight + 4

        Text {
            id: clockText
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.currentHour + ":" + root.currentMinute
            font {
                pointSize: 72
                family: Theme.font
            }
            renderType: Text.CurveRendering
            color: Theme.txt1
        }
        Text {
            id: dateText
            anchors {
                top: clockText.bottom
                topMargin: 4
                horizontalCenter: parent.horizontalCenter
            }
            text: root.currentDate
            font {
                pointSize: 14
                family: Theme.font
            }
            color: Theme.txt2
        }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 360
        height: cardCol.implicitHeight + 100
        radius: Theme.radius * 2
        color: Theme.bgnd
        border.color: Theme.acct
        border.width: 2

        Column {
            id: cardCol
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
                topMargin: 50
            }
            width: parent.width - 60
            spacing: 22

            Item {
                width: parent.width
                height: 140

                ClippingRectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 140
                    height: 140
                    radius: 70
                    color: "transparent"
                    border.color: Theme.acct
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
            }

            Item {
                width: parent.width
                height: usernameRow.implicitHeight

                Row {
                    id: usernameRow
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: String.fromCodePoint(0xF053)
                        font {
                            pointSize: 14
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
                        width: 200
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        text: Users.current || "No user found"
                        font {
                            pointSize: 16
                            family: Theme.font
                        }
                        color: Theme.txt1
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: String.fromCodePoint(0xF054)
                        font {
                            pointSize: 14
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
            }

            Item {
                id: pwAnchor
                width: parent.width
                height: 46

                SequentialAnimation {
                    id: shakeAnim
                    NumberAnimation {
                        target: pwAnchor
                        property: "x"
                        to: 10
                        duration: 50
                    }
                    NumberAnimation {
                        target: pwAnchor
                        property: "x"
                        to: -10
                        duration: 50
                    }
                    NumberAnimation {
                        target: pwAnchor
                        property: "x"
                        to: 7
                        duration: 50
                    }
                    NumberAnimation {
                        target: pwAnchor
                        property: "x"
                        to: -7
                        duration: 50
                    }
                    NumberAnimation {
                        target: pwAnchor
                        property: "x"
                        to: 0
                        duration: 50
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius
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
                        color: "#33ffffff"
                        radius: Theme.radius - 2

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
            }

            Item {
                width: parent.width
                height: sessionRow.implicitHeight

                Row {
                    id: sessionRow
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: String.fromCodePoint(0xF053)
                        font {
                            pointSize: 11
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
                        text: String.fromCodePoint(0xF108) + "  "
                        font {
                            pointSize: 11
                            family: Theme.font
                        }
                        color: Theme.txt2
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 170
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        text: Sessions.current ? Sessions.current.name : "No session found"
                        font {
                            pointSize: 11
                            family: Theme.font
                        }
                        color: Theme.txt2
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: String.fromCodePoint(0xF054)
                        font {
                            pointSize: 11
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
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                visible: CapsLock.active
                text: String.fromCodePoint(0xF071) + " caps lock is on"
                font {
                    pointSize: 11
                    family: Theme.font
                }
                color: Theme.err
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.failText
                font {
                    pointSize: 11
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

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: root.step === "launching" ? "Launching…" : "enter confirm · tab/↑↓ switch · esc clear"
                font {
                    pointSize: 10
                    family: Theme.font
                }
                color: Theme.txt2
            }
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 + card.height / 2 + 30
        spacing: 40

        Text {
            text: String.fromCodePoint(0xF011)
            font {
                pointSize: 18
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
                pointSize: 18
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
        Text {
            text: String.fromCodePoint(0xF2DC)
            font {
                pointSize: 18
                family: Theme.font
            }
            color: root.powerArmed && root.powerAction === "hibernate" ? Theme.err : Theme.txt2
            Behavior on color {
                ColorAnimation {
                    duration: 200
                }
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -12
                onClicked: root._powerTap("hibernate")
            }
        }
    }

    Text {
        visible: root.powerArmed
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 + card.height / 2 + 60
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
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 20
        }
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: "greetd socket not available"
        font {
            pointSize: 12
            family: Theme.font
        }
        color: Theme.err
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
