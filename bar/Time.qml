pragma Singleton
import QtQuick
import Quickshell

Singleton {

    readonly property string time: {
        Qt.formatDateTime(clock.date, "<b> hh:mm:ss</b> dd|MM|yy ddd");
    }

    SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }
}
