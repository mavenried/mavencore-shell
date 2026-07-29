import Quickshell
import Quickshell.Wayland
import qs

// A dedicated, invisible surface for the Wayland idle inhibitor.
//
// The bar itself lives on the Top layer, which niri renders *below*
// fullscreen windows (and stops scanning out while covered) — so an
// inhibitor attached to the bar's own surface would go dead the moment
// anything goes fullscreen. The Overlay layer stays on top of fullscreen
// content, so keeping the inhibitor here instead makes it survive that.
PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    color: "transparent"
    implicitWidth: 1
    implicitHeight: 1
    mask: Region {}

    anchors {
        top: true
        left: true
    }

    IdleInhibitor {
        window: root
        enabled: IdleInhibitorState.active
    }
}
