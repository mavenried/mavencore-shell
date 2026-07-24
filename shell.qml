import QtQuick
import Quickshell
import qs
import qs.bar
import qs.notifyd
import qs.launcher
import qs.network
import qs.osd
import qs.wallpaper
import qs.lockscreen
import qs.dashboard
import qs.polkit

ShellRoot {
    // Change Conf Singleton options
    Binding {
        target: Conf
        property: "batteryPath"
        value: "/sys/class/power_supply/BAT1"
    }
    Wallpaper {
        wallpaperPath: "/mnt/DATA/Pictures/CURRENT"
        showTime: true
    }
    Binding {
        target: Conf
        property: "diskPaths"
        value: ["/", "/mnt/DATA"]
    }

    Dashboard {
        scratchpadPath: "/mnt/DATA/Documents/scratches/.mavencore-scratchpad"
        todoPath: "/mnt/DATA/Documents/scratches/.mavencore-todo"
        networkIface: "wlan0"
        weatherLocation: "Kochi"
    }
    NetworkManager {}
    Bar {
        showBattery: true
        showPower: true
        diskPath: "/mnt/DATA"
    }
    Notifyd {}
    Launcher {}
    Osd {}
    LockScreen {
        blurPath: "/mnt/DATA/Pictures/CURRENT_BLUR"
        avatarPath: "/mnt/DATA/Pictures/AVATAR"
    }
    Polkit {}
}
