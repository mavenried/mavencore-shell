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

        FloatingWindow {
            id: win
            required property var modelData
            screen: modelData

            visible: true
            fullscreen: true
            color: "black"

            GreeterSurface {
                anchors.fill: parent
                blurPath: "/mnt/DATA/Pictures/CURRENT_BLUR"
                avatarPath: "/mnt/DATA/Pictures/AVATAR"
                lastUserPath: "/var/lib/greetd/.quickshell-last-user"
                defaultUser: "mavenried"
            }
        }
    }
}
