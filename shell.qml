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
import qs.infowindow
import qs.clipboard

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
        timeYOffset: 0.75
        timeXOffset: 0.5
    }
    Binding {
        target: Conf
        property: "diskPaths"
        value: ["/", "/mnt/DATA"]
    }

    Dashboard {
        scratchpadPath: "/mnt/DATA/Documents/scratches/.mavencore-scratchpad"
        todoPath: "/mnt/DATA/Documents/scratches/.mavencore-todo"
        networkIface: "all"
        weatherLocation: "Kochi"
        countdownTarget: "13 Nov 2026"
        countdownName: "ESE"
    }
    NetworkManager {}
    Bar {
        showBattery: true
        showPower: true
        diskPath: "/mnt/DATA"
    }
    IdleInhibitorSurface {}
    Notifyd {}
    Launcher {}
    Clipboard {}
    // Larger rich-text views opened from the launcher.
    InfoWindow {}
    Osd {}
    LockScreen {
        blurPath: "/mnt/DATA/Pictures/CURRENT_BLUR"
        avatarPath: "/mnt/DATA/Pictures/AVATAR"
    }
    Polkit {}
}
