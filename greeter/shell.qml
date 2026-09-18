import QtQuick
import Quickshell
import qs

ShellRoot {
    Binding {
        target: Conf
        property: "batteryPath"
        value: "/sys/class/power_supply/BAT1"
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusiveZone: 0
            aboveWindows: true
            focusable: true
            color: "black"

            GreeterSurface {
                anchors.fill: parent

                blurPath: "/mnt/DATA/Pictures/CURRENT_BLUR"
                avatarPath: "/mnt/DATA/Pictures/AVATAR"
                lastUserPath: "/var/lib/greetd/.quickshell-last-user"
                lastSessionPath: "/var/lib/greetd/.quickshell-last-session"
                defaultUser: "mavenried"
            }
        }
    }
}
