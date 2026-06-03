pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs

WidgetCard {
    id: root

    // All data is pushed in from Dashboard scope (lives outside LazyLoader)
    property string weatherLocation: String.fromCodePoint(0x2014)
    property string temperature: String.fromCodePoint(0x2014) + String.fromCodePoint(0xB0) + "C"
    property string feelsLike: String.fromCodePoint(0x2014) + String.fromCodePoint(0xB0) + "C"
    property string condition: String.fromCodePoint(0x2014)
    property string humidity: String.fromCodePoint(0x2014) + "%"
    property string windSpeed: String.fromCodePoint(0x2014) + " km/h"
    property string icon: String.fromCodePoint(0x1F321)

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
                text: String.fromCodePoint(0xF058C) + " " + root.humidity
                color: Theme.txt2
                font.pixelSize: 12
                font.family: Theme.font
            }
            Text {
                text: String.fromCodePoint(0xEF16) + " " + root.windSpeed
                color: Theme.txt2
                font.pixelSize: 12
                font.family: Theme.font
            }
        }
    }
}
