pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property string batteryPath: "/sys/class/power_supply/BAT1"
}
