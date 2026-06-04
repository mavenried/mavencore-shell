import Quickshell
import Quickshell.Wayland
import Quickshell.Io

import QtQuick

Scope {
    id: lockScreen
    property string blurPath: ""
    property string avatarPath: ""

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
                blurPath: lockScreen.blurPath
                avatarPath: lockScreen.avatarPath
            }
        }
    }
}
