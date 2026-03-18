import Quickshell
import Quickshell.Wayland
import Quickshell.Io

import QtQuick

Scope {
    LockContext {
        id: lockContext

        onUnlocked: {
            lock.locked = false;
        }
    }

    IpcHandler {
        target: "lockscreen"
        function lock() {
            lock.locked = true;
        }
    }

    WlSessionLock {
        id: lock
        locked: false

        WlSessionLockSurface {
            LockSurface {
                anchors.fill: parent
                context: lockContext
            }
        }
    }
}
