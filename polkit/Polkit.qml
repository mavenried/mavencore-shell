import Quickshell
import Quickshell.Services.Polkit
import qs

Scope {
    id: root

    // Kept around through the closing fade so the dialog doesn't go blank
    // the instant the flow completes and agent.flow resets to null.
    property var lastFlow: null

    PolkitAgent {
        id: agent
        onFlowChanged: {
            if (agent.flow)
                root.lastFlow = agent.flow;
            ot.setOpen(agent.flow !== null);
        }
    }

    OverlayToggle {
        id: ot
        loader: loader
        closeDelay: 280
    }

    LazyLoader {
        id: loader

        PolkitDialog {
            flow: root.lastFlow
            open: ot.open
        }
    }
}
