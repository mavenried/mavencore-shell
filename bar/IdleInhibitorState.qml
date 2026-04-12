pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    property bool active: false
    onActiveChanged: {
        if (active) {
            proc.running = true;
        } else {
            proc.running = false;
        }
    }

    Process {
        id: proc

        running: false
        command: ["systemd-inhibit", "--what=sleep:idle", "--why=MavenCore Sleep Inhibit", "--mode=block", "sleep", "infinity"]
    }

    Component.onDestruction: {
        proc.running = false;
    }
}
