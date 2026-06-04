import QtQuick
import Quickshell
import qs

Scope {
    id: scope
    required property string diskPath
    property bool showBattery: true
    property bool showPower: true

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root

            required property var modelData

            function truncate(str, n) {
                if (str.length > n) {
                    return str.slice(0, n - 1) + String.fromCodePoint(0x2026);
                }
                return str;
            }

            screen: modelData
            color: "transparent"
            implicitHeight: row.implicitHeight

            anchors {
                top: true
                left: true
                right: true
            }

            Row {
                id: row

                anchors.verticalCenter: parent.verticalCenter
                padding: 5
                bottomPadding: 0
                spacing: 5

                CommandMonitor {
                    labelColor: Theme.dstr
                    command: ["zsh", "-c", "checkupdates | wc -l "]
                    onclick: ["ghostty", "-e", "yay", "-Syu", "--noconfirm"]
                    template: String.fromCodePoint(0xF303) + " %3s"
                    label: String.fromCodePoint(0xF303) + " ---"
                    interval: 5000
                }

                Module {
                    label: Time.time
                    labelColor: Theme.clck
                }

                Rectangle {
                    implicitHeight: inner.implicitHeight
                    implicitWidth: inner.implicitWidth
                    color: Theme.acct
                    border.width: 2
                    border.color: Theme.acct
                    radius: Theme.radius
                    Row {
                        id: inner
                        spacing: -5
                        Module {
                            label: "<b>" + (CompositorIpc.state.workspaces.indexOf(CompositorIpc.state.workspace_id) + 1) + "</b>"
                            labelColor: Theme.wksp
                            drawBox: false
                        }
                        Module {
                            label: root.truncate(CompositorIpc.state.window_name, 32)
                            labelColor: Theme.name
                            color: Theme.bgnd
                            drawBox: true
                        }
                    }
                }
            }

            Row {
                padding: 5
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 5
                bottomPadding: 0

                SysInfo {
                    diskPath: scope.diskPath
                    showBattery: scope.showBattery
                    showPower: scope.showPower
                }
            }

            Row {
                padding: 5
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                spacing: 5
                bottomPadding: 0

                CommandMonitor {
                    labelColor: Theme.wifi
                    command: ["mavencore", "online"]
                    label: String.fromCodePoint(0xF059F) + " offline"

                    onclick: ["qs", "ipc", "call", "network-manager", "toggle"]
                    interval: 1000
                    template: "%s<b> " + root.truncate(Network.active ? Network.active.ssid : "---", 15) + "</b>"
                }

                Module {
                    label: String.fromCodePoint(0xF102) + " " + Uptime.text
                    labelColor: Theme.uptm
                }

                PowerProfileSelector {}

                IdleInhibitor {
                    labelColor: Theme.idle
                }
            }
        }
    }
}
