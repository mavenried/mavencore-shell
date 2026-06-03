pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs

Rectangle {
    id: root
    color: "#1c1c1c"
    radius: Theme.radius
    border.color: Theme.sptr
    border.width: 1

    // All data is pushed in from Dashboard scope (lives outside LazyLoader)
    property string weatherLocation: "—"
    property string temperature: "—°C"
    property string feelsLike: "—°C"
    property string condition: "—"
    property string humidity: "—%"
    property string windSpeed: "— km/h"
    property string icon: "🌡"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 6

        Text {
            text: root.weatherLocation
            color: Theme.txt2
            font.pixelSize: 12
            font.family: Theme.font
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        RowLayout {
            spacing: 10
            Text {
                text: root.icon
                font.pixelSize: 36
                color: Theme.txt1
            }
            ColumnLayout {
                spacing: 1
                Text {
                    text: root.temperature
                    color: Theme.txt1
                    font.pixelSize: 36
                    font.bold: true
                    font.family: Theme.font
                }
                Text {
                    text: "Feels like " + root.feelsLike
                    color: Theme.txt2
                    font.pixelSize: 11
                    font.family: Theme.font
                }
            }
        }

        Text {
            text: root.condition
            color: Theme.txt1
            font.pixelSize: 13
            font.family: Theme.font
        }

        RowLayout {
            spacing: 16
            Text {
                text: "󰖌 " + root.humidity
                color: Theme.txt2
                font.pixelSize: 12
                font.family: Theme.font
            }
            Text {
                text: " " + root.windSpeed
                color: Theme.txt2
                font.pixelSize: 12
                font.family: Theme.font
            }
        }
    }
}
