import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root
            exclusiveZone: -1
            WlrLayershell.layer: WlrLayer.Background

            required property var modelData

            screen: modelData
            color: "transparent"

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            Image {
                id: img
                anchors.fill: parent
                source: "/mnt/DATA/Pictures/CURRENT"
            }

            OpacityAnimator {
                id: fadeIn
                target: img
                duration: 1000
                from: 0
                to: 1
                easing.type: Easing.InOutQuad
            }
            IpcHandler {
                id: ipc
                target: "wallpaper"
                function reload() {
                    img.source = "";
                    img.opacity = 0;
                    img.source = "/mnt/DATA/Pictures/CURRENT";
                    fadeIn.start();
                }
            }
            Component.onCompleted: {
                ipc.reload();
            }
        }
    }
}
