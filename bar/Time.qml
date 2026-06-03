pragma Singleton
import QtQuick
import Quickshell

Singleton {

    readonly property string time: {
        Qt.formatDateTime(clock.date, "<b>" + String.fromCodePoint(0xF017) + " hh:mm:ss</b> dd|MM|yy ddd");
    }

    SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }
}
