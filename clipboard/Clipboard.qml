pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs

Scope {
    id: root

    property string query: ""
    property var entries: []
    readonly property bool opened: ot.open

    function refresh() {
        historyProc.running = false;
        historyProc.running = true;
    }

    function parseHistory(data) {
        let result = [];

        for (const line of data.split(/\r?\n/)) {
            if (!line)
                continue;

            const separator = line.indexOf("\t");
            if (separator < 1)
                continue;

            result.push({
                id: line.slice(0, separator),
                preview: line.slice(separator + 1),
                raw: line
            });
        }

        root.entries = result;
    }

    property var filteredEntries: {
        const q = root.query.trim().toLowerCase();
        if (!q)
            return root.entries;

        return root.entries.filter(entry =>
            entry.preview.toLowerCase().includes(q)
        );
    }

    function restore(entry) {
        if (!entry)
            return;

        // Pass the selected entry as an argument, not interpolated
        // into shell source, so its contents cannot inject shell syntax.
        Quickshell.execDetached([
            "sh", "-c",
            "printf '%s\\n' \"$1\" | cliphist decode | wl-copy",
            "clipboard", entry.raw
        ]);

        ot.setOpen(false);
        root.query = "";
    }

    function removeEntry(entry) {
        if (!entry)
            return;

        Quickshell.execDetached([
            "sh", "-c",
            "printf '%s\\n' \"$1\" | cliphist delete",
            "clipboard", entry.raw
        ]);

        refreshTimer.restart();
    }

    IpcHandler {
        target: "clipboard"

        function open() {
            root.query = "";
            ot.setOpen(true);
            root.refresh();
        }

        function close() {
            ot.setOpen(false);
        }

        function toggle() {
            if (!ot.open) {
                root.query = "";
                root.refresh();
            }
            ot.toggle();
        }
    }

    OverlayToggle {
        id: ot
        loader: panelLoader
        closeDelay: 300
    }

    // Keep history collection running for the lifetime of the shell.
    Process {
        id: watcher
        command: ["wl-paste", "--watch", "cliphist", "store"]
        running: true
    }

    Process {
        id: historyProc
        command: ["cliphist", "list"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.parseHistory(this.text)
        }
    }

    Timer {
        id: refreshTimer
        interval: 300
        onTriggered: root.refresh()
    }

    LazyLoader {
        id: panelLoader
        active: false

        ClipboardPanel {
            entries: root.entries
            filteredEntries: root.filteredEntries
            query: root.query
            open: ot.open

            onSearchChanged: root.query = searchText
            onRestoreRequested: root.restore(entry)
            onDeleteRequested: root.removeEntry(entry)
            onCloseRequested: ot.setOpen(false)
            onClearRequested: {
                Quickshell.execDetached(["cliphist", "wipe"]);
                refreshTimer.restart();
            }
        }
    }
}
