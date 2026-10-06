pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

Scope {
    id: root

    property string title: "Information"
    property string content: ""

    OverlayToggle {
        id: ot
        loader: loader
        closeDelay: 280
    }

    IpcHandler {
        target: "infowindow"

        function setContent(title: string, text: string): void {
            root.title = title;
            root.content = text;
            ot.setOpen(true);
        }

        function close() {
            ot.setOpen(false);
        }
    }

    LazyLoader {
        id: loader

        PanelWindow {
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: ot.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusiveZone: -1
            color: "transparent"

            Item {
                id: focusCatcher
                anchors.fill: parent
                focus: true

                Component.onCompleted: Qt.callLater(function () {
                    focusCatcher.forceActiveFocus();
                })

                Keys.onPressed: function (event) {
                    if (event.key === Qt.Key_Escape) {
                        ot.setOpen(false);
                        event.accepted = true;
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.72)
                    opacity: ot.open ? 1 : 0
                    Behavior on opacity {
                        OpacityAnimator { duration: 280 }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: ot.setOpen(false)
                    }
                }

                Rectangle {
                    id: card
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 48, 1040)
                    height: Math.min(parent.height - 48, 860)
                    radius: Theme.radius
                    color: Theme.bgnd
                    border.color: Theme.acct
                    border.width: 2
                    opacity: ot.open ? 1 : 0
                    scale: ot.open ? 1 : 0.96
                    Behavior on opacity {
                        OpacityAnimator { duration: 220 }
                    }
                    Behavior on scale {
                        ScaleAnimator {
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: function (event) { event.accepted = true; }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 16

                        Text {
                            text: root.title
                            color: Theme.txt1
                            font.family: Theme.font
                            font.pixelSize: 24
                            font.bold: true
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.acct
                            opacity: 0.5
                        }

                        Flickable {
                            id: bodyFlickable
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            contentWidth: width
                            contentHeight: body.implicitHeight
                            boundsBehavior: Flickable.StopAtBounds
                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                            }

                            Text {
                                id: body
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 20
                                anchors.rightMargin: 20

                                text: root.content
                                textFormat: Text.RichText
                                color: Theme.txt1
                                font.family: Theme.font
                                font.pixelSize: 18
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            }
                        }
                    }
                }
            }
        }
    }
}

