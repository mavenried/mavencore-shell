import QtQuick
import Quickshell
import qs.bar
import qs.notifyd
import qs.launcher
import qs.osd
import qs.wallpaper
import qs.scratchpad
import qs.lockscreen

ShellRoot {

    Wallpaper {
        wallpaperPath: "/mnt/DATA/Pictures/CURRENT"
        showTime: true
    }
    Scratchpad {
        savePath: "/mnt/DATA/Documents/scratches/.mavencore-scratchpad"
    }
    NetworkManager {}
    Bar {
        batteryPath: "/sys/class/power_supply/BAT1"
        showBattery: true
        showPower: true
        diskPath: "/mnt/DATA"
    }
    Notifyd {}
    Launcher {}
    Osd {}
    LockScreen {}
}
