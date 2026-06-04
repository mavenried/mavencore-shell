import QtQuick
import qs

Rectangle {
    id: root
    property bool showBattery: true
    property bool showPower: true
    property string diskPath: "/"

    color: Theme.bgnd
    border.color: Theme.acct
    border.width: 2
    radius: Theme.radius
    width: content.implicitWidth
    height: content.implicitHeight

    Row {
        id: content
        spacing: 0

        Module {
            label: String.fromCodePoint(0xF4BC) + " " + SysStats.cpu.toFixed(0).padStart(3, " ") + "%"
            labelColor: Theme.cpuc
            drawBox: false
        }

        Module {
            label: String.fromCodePoint(0xEFC5) + " " + SysStats.ram.toFixed(0).padStart(3, " ") + "%"
            labelColor: Theme.mmry
            drawBox: false
        }

        Module {
            label: String.fromCodePoint(0xF02CA) + " " + ((SysStats.diskValues[root.diskPath] ?? 0) * 100).toFixed(0).padStart(3, " ") + "%"
            labelColor: Theme.disk
            drawBox: false
        }

        Module {
            visible: root.showBattery
            label: BatteryStats.icon + " " + BatteryStats.level.toFixed(0).padStart(3, " ") + "%"
            labelColor: BatteryStats.levelColor
            drawBox: false
        }

        Module {
            visible: root.showBattery && root.showPower
            label: String.fromCodePoint(0xF140B) + " " + BatteryStats.watts.toFixed(0).padStart(2, " ") + "W"
            labelColor: Theme.powr
            drawBox: false
        }
    }
}
