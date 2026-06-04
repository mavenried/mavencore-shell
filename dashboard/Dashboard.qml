pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs

Scope {
    id: root

    property string weatherLocation: ""
    property string scratchpadPath: ""
    property string todoPath: ""
    property string networkIface: "wlan0"

    // ── Weather cache (outside LazyLoader — persists across open/close) ──────
    property string wxLocation: String.fromCodePoint(0x2014)
    property string wxTemp: String.fromCodePoint(0x2014) + String.fromCodePoint(0xB0) + "C"
    property string wxFeelsLike: String.fromCodePoint(0x2014) + String.fromCodePoint(0xB0) + "C"
    property string wxCondition: String.fromCodePoint(0x2014)
    property string wxHumidity: String.fromCodePoint(0x2014) + "%"
    property string wxWind: String.fromCodePoint(0x2014) + " km/h"
    property string wxIcon: String.fromCodePoint(0x1F321)

    function wxCodeToIcon(code) {
        if (code === 113)
            return String.fromCodePoint(0x2600);   // ☀  Clear
        if (code === 116)
            return String.fromCodePoint(0x26C5);   // ⛅ Partly cloudy
        if (code === 119 || code === 122)
            return String.fromCodePoint(0x2601);  // ☁  Cloudy/Overcast
        if (code === 143 || code === 248 || code === 260)
            return String.fromCodePoint(0x1F32B); // 🌫 Mist/Fog
        if (code === 200 || code >= 386)
            return String.fromCodePoint(0x26C8);   // ⛈ Thunder
        // Snow: patchy/blowing/blizzard, sleet, ice, snow showers
        if (code === 179 || code === 182 || code === 227 || code === 230 || code === 317 || code === 320 || (code >= 323 && code <= 350) || (code >= 362 && code <= 377))
            return String.fromCodePoint(0x2744);  // ❄  Snow/Sleet/Ice
        // Rain: heavy showers, moderate+
        if ((code >= 299 && code <= 314) || code === 356 || code === 359)
            return String.fromCodePoint(0x1F327); // 🌧 Rain
        // Light rain/drizzle: patchy, freezing drizzle, light drizzle, light showers
        if (code === 176 || code === 185 || (code >= 263 && code <= 296) || code === 353)
            return String.fromCodePoint(0x1F326); // 🌦 Light rain
        return String.fromCodePoint(0x1F321);     // 🌡 default
    }

    Timer {
        interval: 600000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            wxProc.running = false;
            wxProc.running = true;
        }
    }

    Process {
        id: wxProc
        command: ["sh", "-c", "curl -sf 'wttr.in/" + root.weatherLocation.replace(/ /g, "+") + "?format=j1'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var d = JSON.parse(this.text);
                    var c = d.current_condition[0];
                    var a = d.nearest_area[0];
                    root.wxLocation = root.weatherLocation;
                    root.wxTemp = c.temp_C + String.fromCodePoint(0xB0) + "C";
                    root.wxFeelsLike = c.FeelsLikeC + String.fromCodePoint(0xB0) + "C";
                    root.wxCondition = c.weatherDesc[0].value;
                    root.wxHumidity = c.humidity + "%";
                    root.wxWind = c.windspeedKmph + " km/h";
                    root.wxIcon = root.wxCodeToIcon(parseInt(c.weatherCode));
                } catch (_) {
                    root.wxCondition = "Unavailable";
                }
            }
        }
    }

    // ── Pomodoro (outside LazyLoader — timer keeps running while closed) ────
    property int pomWorkMins: 25
    property int pomBreakMins: 5
    property int pomLongBreakMins: 15
    property string pomPhase: "idle"
    property bool pomPaused: false
    property int pomSecondsLeft: 25 * 60
    property int pomSessions: 0

    readonly property int pomTotalSeconds: {
        if (pomPhase === "work")
            return pomWorkMins * 60;
        if (pomPhase === "longBreak")
            return pomLongBreakMins * 60;
        if (pomPhase !== "idle")
            return pomBreakMins * 60;
        return pomWorkMins * 60;
    }

    function pomAdvance() {
        if (pomPhase === "work") {
            pomSessions++;
            pomPhase = (pomSessions % 4 === 0) ? "longBreak" : "break";
            pomSecondsLeft = (pomPhase === "longBreak") ? pomLongBreakMins * 60 : pomBreakMins * 60;
        } else {
            pomPhase = "work";
            pomSecondsLeft = pomWorkMins * 60;
        }
        pomPaused = false;
    }

    function pomStartPause() {
        if (pomPhase === "idle") {
            pomPhase = "work";
            pomSecondsLeft = pomWorkMins * 60;
            pomPaused = false;
        } else {
            pomPaused = !pomPaused;
        }
    }

    function pomReset() {
        pomPhase = "idle";
        pomPaused = false;
        pomSecondsLeft = pomWorkMins * 60;
        pomSessions = 0;
    }

    Timer {
        interval: 1000
        running: root.pomPhase !== "idle" && !root.pomPaused
        repeat: true
        onTriggered: {
            if (root.pomSecondsLeft > 0)
                root.pomSecondsLeft--;
            else
                root.pomAdvance();
        }
    }

    // ── Media cache (outside LazyLoader — persists across open/close) ────────
    property string mediaArtist: ""
    property string mediaTitle: "Nothing playing"
    property string mediaStatus: "Stopped"
    property string mediaArtUrl: ""
    property real mediaPositionUs: 0
    property real mediaLengthUs: 0

    Timer {
        interval: 1000
        running: root.mediaStatus === "Playing" && root.mediaLengthUs > 0
        repeat: true
        onTriggered: root.mediaPositionUs = Math.min(root.mediaPositionUs + 1000000, root.mediaLengthUs)
    }

    PolledProcess {
        command: ["playerctl", "metadata", "--format", "{{artist}}|{{title}}|{{status}}|{{mpris:length}}|{{position}}|{{mpris:artUrl}}"]
        interval: 3000
        onReceived: function (data) {
            var parts = data.split("|");
            if (parts.length < 5 || !parts[1]) {
                root.mediaTitle = "Nothing playing";
                root.mediaArtist = "";
                root.mediaStatus = "Stopped";
                root.mediaLengthUs = 0;
                root.mediaArtUrl = "";
                return;
            }
            root.mediaArtist = parts[0];
            root.mediaTitle = parts[1];
            root.mediaStatus = parts[2];
            root.mediaLengthUs = parseFloat(parts[3]) || 0;
            root.mediaPositionUs = parseFloat(parts[4]) || 0;
            root.mediaArtUrl = parts[5] || "";
        }
    }

    // ── IPC / lifecycle ──────────────────────────────────────────────────────
    OverlayToggle {
        id: ot
        loader: loader
        closeDelay: 300
    }

    IpcHandler {
        id: handler
        target: "dashboard"
        function toggle() {
            ot.toggle();
        }
    }

    // ── UI ───────────────────────────────────────────────────────────────────
    LazyLoader {
        id: loader

        PanelWindow {
            id: dashWindow
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: ot.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusiveZone: -1
            color: "transparent"

            Component.onCompleted: Qt.callLater(function () {
                focusCatcher.forceActiveFocus();
            })

            Item {
                id: focusCatcher
                anchors.fill: parent
                focus: true

                Keys.onPressed: function (event) {
                    if (event.key === Qt.Key_Escape) {
                        handler.toggle();
                        event.accepted = true;
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.72)
                    opacity: ot.open ? 1 : 0
                    Behavior on opacity {
                        OpacityAnimator {
                            duration: 280
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: handler.toggle()
                    }
                }

                Item {
                    id: widgetArea
                    anchors.centerIn: parent
                    width: 16 * 100
                    height: 9 * 100

                    opacity: ot.open ? 1 : 0
                    scale: ot.open ? 1.0 : 0.94

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

                    MouseArea {
                        anchors.fill: parent
                    }

                    RowLayout {
                        anchors.fill: parent
                        spacing: 10

                        // ── Left: System ──────────────────────────────
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 10

                            ClockWidget {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 190
                            }

                            NetworkWidget {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 130
                                iface: root.networkIface
                            }

                            StatsWidget {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }
                            UptimeWidget {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 220
                            }
                        }

                        // ── Middle: Planning ──────────────────────────
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 10

                            TodoWidget {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                savePath: root.todoPath || "/tmp/qs-todo.txt"
                            }
                        }

                        // ── Middle: Planning ──────────────────────────
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 10
                            ScratchpadWidget {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                savePath: root.scratchpadPath || "/tmp/qs-scratch.txt"
                            }
                        }
                        // ── Right: Personal ───────────────────────────
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 10

                            CalendarWidget {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 220
                            }

                            WeatherWidget {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 190
                                weatherLocation: root.wxLocation
                                temperature: root.wxTemp
                                feelsLike: root.wxFeelsLike
                                condition: root.wxCondition
                                humidity: root.wxHumidity
                                windSpeed: root.wxWind
                                icon: root.wxIcon
                            }

                            MediaWidget {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 200
                                artist: root.mediaArtist
                                title: root.mediaTitle
                                status: root.mediaStatus
                                artUrl: root.mediaArtUrl
                                positionUs: root.mediaPositionUs
                                lengthUs: root.mediaLengthUs
                            }

                            PomodoroWidget {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                phase: root.pomPhase
                                paused: root.pomPaused
                                secondsLeft: root.pomSecondsLeft
                                totalSeconds: root.pomTotalSeconds
                                sessions: root.pomSessions
                                onStartPauseClicked: root.pomStartPause()
                                onResetClicked: root.pomReset()
                                onSkipClicked: root.pomAdvance()
                            }
                        }
                    }
                }
            }
        }
    }
}
