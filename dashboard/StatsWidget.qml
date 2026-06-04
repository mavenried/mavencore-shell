pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs

WidgetCard {
    id: root

    readonly property string iconCpu: String.fromCodePoint(0xF4BC)
    readonly property string iconRam: String.fromCodePoint(0xEFC5)
    readonly property string iconDisk: String.fromCodePoint(0xF02CA)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        Text {
            text: "System"
            color: Theme.txt1
            font.pixelSize: 20
            font.bold: true
            font.family: Theme.font
        }

        StatBar {
            label: root.iconCpu + " CPU"
            pct: SysStats.cpu / 100
            barColor: Theme.cpuc
        }
        StatBar {
            label: root.iconRam + " RAM"
            pct: SysStats.ram / 100
            barColor: Theme.mmry
        }

        Repeater {
            model: Conf.diskPaths
            delegate: StatBar {
                required property string modelData
                label: root.iconDisk + " " + (modelData === "/" ? "ROOT" : modelData.split("/").filter(Boolean).pop().toUpperCase())
                pct: SysStats.diskValues[modelData] ?? 0
                barColor: Theme.disk
            }
        }

        StatBar {
            visible: BatteryStats.level > 0
            label: BatteryStats.icon + " BAT"
            pct: BatteryStats.level / 100
            barColor: BatteryStats.levelColor
        }

        StatBar {
            visible: BatteryStats.level > 0
            label: String.fromCodePoint(0xF140B) + " PWR"
            pct: Math.min(BatteryStats.watts / 35, 1)
            valueText: BatteryStats.watts.toFixed(1) + "W"
            barColor: Theme.powr
        }

        Item {
            Layout.fillHeight: true
        }
    }

    component StatBar: ColumnLayout {
        id: sb
        required property string label
        required property real pct
        required property color barColor
        property string valueText: Math.round(sb.pct * 100) + "%"
        spacing: 5
        Layout.fillWidth: true

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: sb.label
                color: sb.barColor
                font.pixelSize: 13
                font.family: Theme.font
            }
            Item {
                Layout.fillWidth: true
            }
            Text {
                text: sb.valueText
                color: sb.barColor
                font.pixelSize: 13
                font.family: Theme.font
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 6
            radius: 3
            color: Qt.rgba(0, 0, 0, 0.2)
            Rectangle {
                id: fillBar
                width: parent.width * sb.pct
                height: parent.height
                radius: parent.radius
                color: sb.barColor
                property bool _ready: false
                Component.onCompleted: Qt.callLater(function () {
                    _ready = true;
                })
                Behavior on width {
                    enabled: fillBar._ready
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
}
