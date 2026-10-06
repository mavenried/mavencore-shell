pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Wayland
import qs

Scope {
    id: root

    function fuzzyScore(name, query) {
        name = name.toLowerCase();
        query = query.toLowerCase();

        let score = 0;
        let j = 0;

        for (let i = 0; i < name.length && j < query.length; i++) {
            if (name[i] === query[j]) {
                score += 2;   // match bonus
                j++;
            } else {
                score -= 0.5; // gap penalty
            }
        }

        if (j !== query.length)
            return -Infinity;

        // bonus for prefix match
        if (name.startsWith(query))
            score += 5;

        return score;
    }

    property bool cmdMode: false
    property bool clcMode: false
    property bool dictMode: false
    property string activePrefix: ""
    property bool consumingPrefix: false
    property bool openDictionaryOnResult: false
    property string closingModeIcon: ""
    property var spinnerFrames: ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
    property int spinnerFrame: 0
    property string clcResult: ""
    property string dictResult: ""

    property var apps: []
    property var searchText: ""
    // property var filtered: {
    //     if (searchText.trim() === "" || root.cmdMode)
    //         return [];
    //     if (root.clcMode)
    //         return [
    //             {
    //                 name: root.clcResult,
    //                 icon: ""
    //             }
    //         ];
    //     return root.apps.filter(a => a.name.toLowerCase().trim().includes(searchText.toLowerCase().trim()));
    // }
    property var filtered: {
        if (searchText.trim() === "" || root.cmdMode)
            return [];

        if (root.dictMode) {
            return [];
        }

        if (root.clcMode) {
            if (root.clcResult === "")
                return [];
            return [
                {
                    name: root.clcResult,
                    icon: ""
                }
            ];
        }

        let q = searchText.trim().toLowerCase();

        return root.apps.map(a => ({
                    app: a,
                    score: fuzzyScore(a.name, q)
                })).filter(x => x.score > -Infinity).sort((a, b) => b.score - a.score).slice(0, 20) // limit results
        .map(x => x.app);
    }

    Process {
        id: proc
        command: ["sh", "-c", "mavencore apps-list"]
        running: false
        stdout: SplitParser {
            onRead: function (data) {
                try {
                    root.apps = root.apps.concat([JSON.parse(data)]);
                } catch (e) {
                    console.error(e);
                }
            }
        }
    }

    Process {
        id: calc
        command: ["sh", "-c", "qalc '" + root.searchText.slice(1) + "'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: function () {
                console.log(this.text);
                if (this.text.trim().split(/\r?\n/).length != 1)
                    root.clcResult = "Error";
                else
                    root.clcResult = this.text.trim();
            }
        }
    }

    Process {
        id: dictionary
        command: ["mavencore", "dict", root.searchText.trim().slice(1).trim()]
        running: false
        stdout: StdioCollector {
            onStreamFinished: function () {
                root.dictResult = this.text.trim();
            }
        }
        stderr: StdioCollector {
            id: dictionaryErrors
        }
        onExited: code => {
            if (!root.openDictionaryOnResult)
                return;

            Qt.callLater(() => {
                if (!root.openDictionaryOnResult)
                    return;

                if (code === 0 && root.dictResult !== "") {
                    Quickshell.execDetached(["qs", "ipc", "call", "infowindow", "setContent", root.searchText.slice(1).trim().toUpperCase(), root.dictResult]);
                } else {
                    const details = dictionaryErrors.text.trim() || `Lookup failed (exit code ${code}).`;
                    const escaped = details.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
                    const wrappedError = escaped.replace(/\r?\n/g, "<br>");
                    const content = `<p style="color: #ab4642"><b>Dictionary lookup failed.</b></p><p style="color: #ab4642">${wrappedError}</p>`;
                    Quickshell.execDetached(["qs", "ipc", "call", "infowindow", "setContent", "dictionary::error", content]);
                }
                handler.close();
            });
        }
    }

    Timer {
        id: closingIconTimer
        interval: 350
        onTriggered: root.closingModeIcon = ""
    }

    Timer {
        interval: 100
        repeat: true
        running: root.dictMode && root.openDictionaryOnResult || root.closingModeIcon === "spinner"
        onTriggered: root.spinnerFrame = (root.spinnerFrame + 1) % root.spinnerFrames.length
    }

    OverlayToggle {
        id: ot
        loader: loader
        closeDelay: 300
    }

    IpcHandler {
        id: handler
        target: "launcher"
        function open() {
            closingIconTimer.stop();
            root.closingModeIcon = "";
            ot.setOpen(true);
            proc.running = true;
            root.apps = [];
        }

        function close() {
            root.closingModeIcon = root.cmdMode ? "" : root.clcMode ? "" : root.dictMode ? root.openDictionaryOnResult ? "spinner" : "" : "";
            closingIconTimer.restart();
            ot.setOpen(false);
            root.apps = [];
            root.searchText = "";
            root.cmdMode = false;
            root.clcMode = false;
            root.dictMode = false;
            root.activePrefix = "";
            root.openDictionaryOnResult = false;
            root.dictResult = "";
            dictionary.running = false;
        }
    }
    LazyLoader {
        id: loader
        PanelWindow {
            id: runnerWindow
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: ot.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            implicitHeight: 600

            anchors {
                bottom: true
                left: true
                right: true
            }
            exclusiveZone: -1
            color: "transparent"
            Rectangle {
                id: inner
                anchors.horizontalCenter: parent.horizontalCenter
                width: 700
                implicitHeight: col.height
                anchors.margins: 10
                anchors.bottom: parent.bottom
                radius: Theme.radius
                color: Theme.bgnd
                border.color: Theme.acct
                border.width: 2

                opacity: ot.open ? 1 : 0

                Behavior on opacity {
                    OpacityAnimator {
                        duration: 100
                    }
                }

                Keys.onPressed: function (event) {
                    console.log("Key pressed:", event.key);
                    if (event.key === Qt.Key_Escape) {
                        console.log("Escape pressed!");
                        handler.close();
                    } else if (event.key === Qt.Key_Return) {
                        if (!root.cmdMode && !root.clcMode && !root.dictMode) {
                            let path = root.filtered[list.currentIndex].path;
                            Quickshell.execDetached(["gio", "launch", path]);
                        } else if (root.cmdMode) {
                            Quickshell.execDetached(["sh", "-c", root.searchText.slice(1)]);
                        } else if (root.dictMode && root.searchText.slice(1).trim() !== "") {
                            root.dictResult = "";
                            root.openDictionaryOnResult = true;
                            if (!dictionary.running)
                                dictionary.running = true;
                            event.accepted = true;
                            return;
                        }
                        handler.close();
                    } else if (event.key === Qt.Key_Tab) {
                        list.currentIndex = (list.currentIndex + 1) % list.count;
                    } else if (event.key === Qt.Key_Backtab) {
                        list.currentIndex = (list.currentIndex - 1) % list.count;
                        if (list.currentIndex < 0)
                            list.currentIndex = list.count - 1;
                    }
                }
                ColumnLayout {
                    id: col
                    spacing: list.count > 0 ? 5 : 0
                    ListView {
                        id: list
                        implicitWidth: 700
                        implicitHeight: Math.min(500, contentHeight)
                        clip: true

                        Behavior on implicitHeight {
                            NumberAnimation {
                                duration: 100
                                easing.type: Easing.InOutQuad
                            }
                        }
                        model: root.filtered.reverse()
                        currentIndex: this.count - 1

                        delegate: Rectangle {
                            id: item
                            required property var modelData

                            width: ListView.view.width
                            height: modelData.richText ? Math.min(500, name.implicitHeight + 20) : 50
                            color: ListView.isCurrentItem ? Qt.rgba(0, 0, 0, 0.5) : "transparent"
                            radius: 15
                            border.width: 2
                            border.color: ListView.isCurrentItem ? Theme.acct : "transparent"
                            Row {
                                anchors.fill: parent
                                anchors.margins: 10

                                Image {
                                    property string iconName: item.modelData.icon
                                    fillMode: Image.PreserveAspectFit
                                    visible: !item.modelData.richText && iconName != ""
                                    source: "image://icon/" + iconName
                                    height: 30
                                    width: 30
                                }
                                // Text {
                                //     id: name
                                //     leftPadding: 10
                                //     text: item.modelData.name
                                //     font.pixelSize: 20
                                //     // font.family: "JetbrainsMono Nerd Font"
                                //     font.family: Theme.font
                                //     color: item.ListView.isCurrentItem ? Theme.txt1 : Theme.txt1
                                // }
                                Text {
                                    id: name
                                    width: item.modelData.richText ? item.width - 20 : implicitWidth
                                    font.pixelSize: 20
                                    font.family: Theme.font
                                    color: Theme.txt1
                                    wrapMode: Text.WordWrap
                                    textFormat: Text.RichText

                                    text: {
                                        if (item.modelData.richText)
                                            return item.modelData.name;

                                        let q = root.searchText.toLowerCase();
                                        let n = item.modelData.name;

                                        if (!q)
                                            return n;

                                        let res = "";
                                        let qi = 0;

                                        for (let i = 0; i < n.length; i++) {
                                            if (qi < q.length && n[i].toLowerCase() === q[qi]) {
                                                res += "<b><u>" + n[i] + "</u></b>";
                                                qi++;
                                            } else {
                                                res += n[i];
                                            }
                                        }
                                        return res;
                                    }

                                }
                            }
                        }
                    }

                    Rectangle {
                        id: search
                        implicitHeight: text.implicitHeight
                        color: "transparent"
                            TextField {
                                id: text
                                padding: 10
                                leftPadding: 46
                                focus: true
                            placeholderText: root.cmdMode ? "Enter a command." : root.clcMode ? "Enter an equation." : root.dictMode ? "Type a word, then press Enter." : "Search apps or enter a prefix."
                            placeholderTextColor: Theme.txt2
                            font.pixelSize: 20
                            font.family: Theme.font
                            color: Theme.txt1
                                background: Rectangle {
                                    color: Qt.rgba(0, 0, 0, 0.5)
                                    radius: 15
                                    border.color: root.cmdMode ? Theme.wifi : root.clcMode ? Theme.mmry : root.dictMode ? Theme.dstr : Theme.acct
                                    border.width: 2
                                    width: 700

                                    Text {
                                        id: modeIcon
                                        anchors.left: parent.left
                                        anchors.leftMargin: 14
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.closingModeIcon === "spinner" ? root.spinnerFrames[root.spinnerFrame] : root.closingModeIcon !== "" ? root.closingModeIcon : root.cmdMode ? "" : root.clcMode ? "" : root.dictMode ? root.openDictionaryOnResult ? root.spinnerFrames[root.spinnerFrame] : "" : ""
                                        color: root.cmdMode ? Theme.wifi : root.clcMode ? Theme.mmry : root.dictMode ? Theme.dstr : Theme.txt2
                                        font.family: Theme.font
                                        font.pixelSize: 21

                                    }
                                }
                            onTextChanged: function () {
                                if (root.consumingPrefix)
                                    return;

                                root.openDictionaryOnResult = false;

                                let visibleText = this.text;
                                if (root.activePrefix && visibleText === "")
                                    root.activePrefix = "";

                                if ([":", "=", "?"].includes(visibleText[0])) {
                                    root.activePrefix = visibleText[0];
                                    root.consumingPrefix = true;
                                    this.text = visibleText.slice(1);
                                    root.consumingPrefix = false;
                                    visibleText = this.text;
                                }

                                root.searchText = root.activePrefix ? root.activePrefix + visibleText : visibleText;
                                if (root.searchText.startsWith(":")) {
                                    root.cmdMode = true;
                                    root.clcMode = false;
                                    root.dictMode = false;
                                    dictionary.running = false;
                                    root.dictResult = "";
                                } else if (root.searchText.startsWith("=")) {
                                    root.cmdMode = false;
                                    root.clcMode = true;
                                    root.dictMode = false;
                                    dictionary.running = false;
                                    root.dictResult = "";
                                    if (root.searchText.slice(1).trim() !== "") {
                                        calc.running = false;
                                        calc.running = true;
                                    } else {
                                        root.clcResult = "";
                                    }
                                } else if (root.searchText.startsWith("?")) {
                                    root.cmdMode = false;
                                    root.clcMode = false;
                                    root.dictMode = true;
                                    root.dictResult = "";
                                    dictionary.running = false;
                                } else {
                                    root.cmdMode = false;
                                    root.clcMode = false;
                                    root.dictMode = false;
                                    dictionary.running = false;
                                    root.dictResult = "";
                                }
                            }
                            Keys.onPressed: function (event) {
                                if (event.key === Qt.Key_Backspace && this.text === "" && root.activePrefix !== "") {
                                    root.activePrefix = "";
                                    root.searchText = "";
                                    root.cmdMode = false;
                                    root.clcMode = false;
                                    root.dictMode = false;
                                    root.clcResult = "";
                                    root.dictResult = "";
                                    dictionary.running = false;
                                    calc.running = false;
                                    event.accepted = true;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
