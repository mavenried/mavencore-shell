pragma Singleton
import Quickshell
import Quickshell.Io

Singleton {
    property bool active: false

    IpcHandler {
        target: "idle-inhibitor"
        function toggle() {
            active = !active;
        }
    }
}
