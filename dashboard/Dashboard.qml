pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs

Scope {
    id: root

    property bool open: false
    property list<string> diskPaths: ["/"]
    property string weatherLocation: ""
    property string scratchpadPath: ""
    property string todoPath: ""
    property string networkIface: "wlan0"

    // ── Weather cache (outside LazyLoader — persists across open/close) ──────
    property string wxLocation: "—"
    property string wxTemp: "—°C"
    property string wxFeelsLike: "—°C"
    property string wxCondition: "—"
    property string wxHumidity: "—%"
    property string wxWind: "— km/h"
    property string wxIcon: "🌡"

    function wxCodeToIcon(code) {
        console.log(code);
        if (code === 113)
            return "☀";
        if (code === 116)
            return "⛅";
        if (code >= 119 && code <= 122)
            return "☁";
        if (code >= 248 && code <= 260)
            return "🌫";
        if (code >= 263 && code <= 296)
            return "🌦";
        if (code >= 299 && code <= 321)
            return "🌧";
        if (code >= 323 && code <= 377)
            return "❄";
        if (code === 200 || code >= 386)
            return "⛈";
        return "🌡";
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
                    root.wxLocation = a.areaName[0].value + ", " + a.country[0].value;
                    root.wxTemp = c.temp_C + "°C";
                    root.wxFeelsLike = c.FeelsLikeC + "°C";
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
    property int    pomWorkMins:      25
    property int    pomBreakMins:     5
    property int    pomLongBreakMins: 15
    property string pomPhase:         "idle"
    property bool   pomPaused:        false
    property int    pomSecondsLeft:   25 * 60
    property int    pomSessions:      0

    readonly property int pomTotalSeconds: {
        if (pomPhase === "work")      return pomWorkMins * 60
        if (pomPhase === "longBreak") return pomLongBreakMins * 60
        if (pomPhase !== "idle")      return pomBreakMins * 60
        return pomWorkMins * 60
    }

    function pomAdvance() {
        if (pomPhase === "work") {
            pomSessions++
            pomPhase       = (pomSessions % 4 === 0) ? "longBreak" : "break"
            pomSecondsLeft = (pomPhase === "longBreak") ? pomLongBreakMins * 60 : pomBreakMins * 60
        } else {
            pomPhase       = "work"
            pomSecondsLeft = pomWorkMins * 60
        }
        pomPaused = false
    }

    function pomStartPause() {
        if (pomPhase === "idle") {
            pomPhase       = "work"
            pomSecondsLeft = pomWorkMins * 60
            pomPaused      = false
        } else {
            pomPaused = !pomPaused
        }
    }

    function pomReset() {
        pomPhase       = "idle"
        pomPaused      = false
        pomSecondsLeft = pomWorkMins * 60
        pomSessions    = 0
    }

    Timer {
        interval: 1000
        running: root.pomPhase !== "idle" && !root.pomPaused
        repeat: true
        onTriggered: {
            if (root.pomSecondsLeft > 0) root.pomSecondsLeft--
            else root.pomAdvance()
        }
    }

    // ── IPC / lifecycle ──────────────────────────────────────────────────────
    IpcHandler {
        id: handler
        target: "dashboard"
        function toggle() {
            root.open = !root.open;
            loader.active = true;
            if (!root.open)
                closeTimer.start();
        }
    }

    Timer {
        id: closeTimer
        interval: 300
        onTriggered: loader.active = root.open
    }

    // ── UI ───────────────────────────────────────────────────────────────────
    LazyLoader {
        id: loader

        PanelWindow {
            id: dashWindow
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

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
                    opacity: root.open ? 1 : 0
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

                    MouseArea {
                        anchors.fill: parent
                    }

                    RowLayout {
                        anchors.fill: parent
                        spacing: 14

                        // ── Left: System ──────────────────────────────
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 14

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
                                diskPaths: root.diskPaths
                            }
                        }

                        // ── Middle: Planning ──────────────────────────
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 14

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
                            spacing: 14
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
                            spacing: 14

                            CalendarWidget {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 260
                            }

                            WeatherWidget {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 190
                                weatherLocation: root.wxLocation
                                temperature:     root.wxTemp
                                feelsLike:       root.wxFeelsLike
                                condition:       root.wxCondition
                                humidity:        root.wxHumidity
                                windSpeed:       root.wxWind
                                icon:            root.wxIcon
                            }

                            MediaWidget {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 170
                            }

                            PomodoroWidget {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                phase:        root.pomPhase
                                paused:       root.pomPaused
                                secondsLeft:  root.pomSecondsLeft
                                totalSeconds: root.pomTotalSeconds
                                sessions:     root.pomSessions
                                onStartPauseClicked: root.pomStartPause()
                                onResetClicked:      root.pomReset()
                                onSkipClicked:       root.pomAdvance()
                            }
                        }
                    }
                }
            }
        }
    }
}
