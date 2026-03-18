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

    Wallpaper {}
    Scratchpad {
        path: "/mnt/DATA/Documents/scratches/.mavencore-scratchpad"
    }
    Bar {}
    Notifyd {}
    Launcher {}
    Osd {}
    LockScreen{}
}
