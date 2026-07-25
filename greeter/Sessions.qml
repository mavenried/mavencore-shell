pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var sessions: []
    property int currentIndex: 0
    readonly property var current: sessions.length ? sessions[currentIndex] : null

    function next() {
        if (sessions.length)
            currentIndex = (currentIndex + 1) % sessions.length;
    }
    function prev() {
        if (sessions.length)
            currentIndex = (currentIndex - 1 + sessions.length) % sessions.length;
    }
    function selectByName(name) {
        for (let i = 0; i < sessions.length; i++) {
            if (sessions[i].name === name) {
                currentIndex = i;
                return;
            }
        }
    }

    Process {
        id: scan
        command: ["sh", "-c", "for f in /usr/share/wayland-sessions/*.desktop /usr/share/xsessions/*.desktop; do [ -f \"$f\" ] || continue; name=$(grep -m1 '^Name=' \"$f\" | cut -d= -f2-); exec=$(grep -m1 '^Exec=' \"$f\" | cut -d= -f2-); case \"$f\" in */wayland-sessions/*) type=wayland ;; *) type=x11 ;; esac; printf '%s\\t%s\\t%s\\n' \"$type\" \"$name\" \"$exec\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n").map(l => l.trim()).filter(l => l.length);
                root.sessions = lines.map(l => {
                    const parts = l.split("\t");
                    return {
                        type: parts[0] || "wayland",
                        name: parts[1] || "Session",
                        exec: parts[2] || ""
                    };
                });
            }
        }
    }

    Component.onCompleted: scan.running = true
}
