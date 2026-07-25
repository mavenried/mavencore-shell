pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var users: []
    property int currentIndex: 0
    readonly property string current: users.length ? users[currentIndex] : ""

    function next() {
        if (users.length)
            currentIndex = (currentIndex + 1) % users.length;
    }
    function prev() {
        if (users.length)
            currentIndex = (currentIndex - 1 + users.length) % users.length;
    }
    function selectByName(name) {
        const i = users.indexOf(name);
        if (i >= 0)
            currentIndex = i;
    }

    Process {
        id: scan
        command: ["sh", "-c", "getent passwd | awk -F: '$3>=1000 && $3<60000 {print $1}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.users = this.text.split("\n").map(l => l.trim()).filter(l => l.length);
            }
        }
    }

    Component.onCompleted: scan.running = true
}
