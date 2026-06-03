import QtQuick
import Quickshell
import qs.bar
import qs.notifyd
import qs.launcher
import qs.network
import qs.osd
import qs.wallpaper
import qs.lockscreen
import qs.dashboard

ShellRoot {

    Wallpaper {
        wallpaperPath: "/mnt/DATA/Pictures/CURRENT"
        showTime: true
    }
    Dashboard {
        diskPaths: ["/", "/mnt/DATA"]
        scratchpadPath: "/mnt/DATA/Documents/scratches/.mavencore-scratchpad"
        todoPath: "/mnt/DATA/Documents/scratches/.mavencore-todo"
        networkIface: "wlan0"
        weatherLocation: "Kochi"
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
    LockScreen {
        blurPath: "/mnt/DATA/Pictures/CURRENT_BLUR"
    }
}
