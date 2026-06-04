<h1 align="center">mavencore-shell</h1>
<p align="center">
A Wayland shell built with <a href="https://quickshell.outfoxxed.me">Quickshell</a>, featuring a status bar, dashboard overlay, app launcher, network manager, lock screen, OSD, and wallpaper layer.
</p>
## Dependencies

| Package                                                  | Purpose                                               |
| -------------------------------------------------------- | ----------------------------------------------------- |
| `quickshell`                                             | Shell framework                                       |
| [`mavencore`](https://github.com/mavenried/mavencore-rs) | System info backend (cpu, ram, disk, battery, uptime) |
| `playerctl`                                              | Media controls in the dashboard                       |
| `bluetoothctl`                                           | Bluetooth management                                  |
| `NetworkManager`                                         | Wi-Fi management (via `nmcli`)                        |
| `checkupdates`                                           | Pending update count in bar (pacman/paru/yay)         |
| `qalc`                                                   | Calculator mode in launcher                           |
| `ghostty`                                                | Terminal opened for system upgrades                   |
| `brightnessctl`                                          | Brightness OSD                                        |
| `wpctl`                                                  | Volume OSD (PipeWire)                                 |
| A [Nerd Font](https://www.nerdfonts.com/)                | All icons — configured in `Theme.qml`                 |

## Installation

```sh
git clone <repo> ~/.config/quickshell
quickshell
```

## Configuration

All per-machine settings live in **`shell.qml`**. Nothing else needs editing for a basic setup.

```qml
ShellRoot {

    Wallpaper {
        wallpaperPath: "/path/to/wallpaper"   // image shown on all monitors
        showTime: true                         // clock overlay on wallpaper
    }

    Dashboard {
        diskPaths: ["/", "/mnt/DATA"]          // drives shown in stats widget
        scratchpadPath: "/path/to/scratch.txt" // persistent scratchpad file
        todoPath:       "/path/to/todo.txt"    // persistent todo file
        networkIface:   "wlan0"                // interface for network speed
        weatherLocation: "London"              // city name passed to wttr.in
    }

    Bar {
        diskPath:    "/mnt/DATA"                          // disk shown in bar
        batteryPath: "/sys/class/power_supply/BAT1"       // sysfs battery node
        showBattery: true                                  // hide on desktops
        showPower:   true                                  // hide watt display
    }

    LockScreen {
        blurPath: "/path/to/wallpaper_blur"   // blurred image for lock screen
    }

    NetworkManager {}
    Launcher {}
    Notifyd {}
    Osd {}
}
```

### Theme

Edit **`Theme.qml`** to change colours or font:

```qml
readonly property string font: "JetBrainsMonoNL Nerd Font"
readonly property color  bgnd: "#141414"   // base background
// ...
```

## IPC

All modules are toggled via `qs ipc call`:

| Command                              | Action                           |
| ------------------------------------ | -------------------------------- |
| `qs ipc call dashboard toggle`       | Open / close dashboard           |
| `qs ipc call launcher open`          | Open launcher                    |
| `qs ipc call launcher close`         | Close launcher                   |
| `qs ipc call network-manager toggle` | Open / close network manager     |
| `qs ipc call lockscreen lock`        | Lock the screen                  |
| `qs ipc call wallpaper reload`       | Reload wallpaper image from disk |
| `qs ipc call osd volume_up`          | Volume +5% with OSD              |
| `qs ipc call osd volume_down`        | Volume -5% with OSD              |
| `qs ipc call osd volume_mute`        | Toggle mute with OSD             |
| `qs ipc call osd brightness_up`      | Brightness +5% with OSD          |
| `qs ipc call osd brightness_down`    | Brightness -5% with OSD          |

## Modules

### Bar

Three-section top bar, one instance per monitor.

- **Left** — pending updates (click to run `yay -Syu`), clock, active workspace + window title
- **Centre** — CPU %, RAM %, disk %, battery %, power draw (W)
- **Right** — network status / SSID (click to open network manager), uptime, power profile selector, idle inhibitor toggle

### Dashboard

Opened with `toggle`. Press `Escape` or click the backdrop to close.

| Widget   | Description                                        |
| -------- | -------------------------------------------------- |
| Clock    | Current time, date, and uptime                     |
| Network  | Per-interface RX/TX speeds                         |
| Stats    | CPU, RAM, disk, battery, and power bars            |
| Todo     | Markdown-like task list, saved automatically       |
| Notes    | Free-text scratchpad, saved automatically          |
| Calendar | Month view with today highlighted                  |
| Weather  | Current conditions from [wttr.in](https://wttr.in) |
| Media    | playerctl playback controls with album art         |
| Pomodoro | 25/5 timer with session tracking                   |

#### Todo syntax

```
task text           → ungrouped task (added to the top)
#group              → create or navigate to a group
#group task text    → add a task under a group
```

#### Weather

Set `weatherLocation` in `shell.qml` to any city name or coordinates accepted by wttr.in (e.g. `"London"`, `"48.85,2.35"`). Leave empty to disable polling.

### Launcher

Opened with `open`, closed with `Escape` or `close`.

| Prefix   | Mode                                                               |
| -------- | ------------------------------------------------------------------ |
| _(none)_ | Fuzzy app search — `Tab` / `Shift+Tab` to cycle, `Enter` to launch |
| `:`      | Shell command — `Enter` to run detached                            |
| `=`      | Calculator via `qalc` — result shown inline                        |

### Network Manager

Wi-Fi scan and connect, Bluetooth device list. Password dialog appears automatically for secured networks.

### Lock Screen

Triggered by `qs ipc call lockscreen lock` or your compositor's idle/suspend hooks. Supports password entry and fingerprint (fprintd). Dismissed automatically on successful auth.

### OSD

Vertical bar overlay on the left edge of the screen, shown on volume or brightness change. Auto-dismisses after 2 seconds.

## Singleton poll rates

| Singleton      | Interval | Data                       |
| -------------- | -------- | -------------------------- |
| `Time`         | 1 s      | Clock string for bar       |
| `Uptime`       | 60 s     | `mavencore uptime`         |
| `SysStats`     | 2 s      | CPU %, RAM %               |
| `BatteryStats` | 5 s      | Battery level, watts, icon |
