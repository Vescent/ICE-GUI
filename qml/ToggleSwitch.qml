import QtQuick 2.0

Item {
    id: toggleSwitch
    width: 38
    height: 20
    property alias text: label.text
    property alias textColor: label.color
    property alias pointSize: label.font.pointSize
    signal clicked(bool enableState)
    property bool enableState: false
    property bool active: true
    property string textOnState: 'ON'
    property string textOffState: 'OFF'
    property color onColor: "#37ff00"
    property color offColor: "#c8c8c8"

    Component.onCompleted: {
        enableSwitch(enableState);
    }

    function enableSwitch(enabled) {
        if (enabled) {
            toggleSwitch.state = 'On';
            enableState = true;
        }
        else {
            toggleSwitch.state = '';
            enableState = false;
        }
    }

    states: [
        State {
            name: "overOn"
            changes: [
                PropertyChanges {
                    target: rect1
                    border.color: '#3399ff'
                }
            ]
            extend: "On"
        },
        State {
            name: "overOff"
            changes: [
                PropertyChanges {
                    target: rect1
                    border.color: '#3399ff'
                }
            ]
        },
        State {
            name: "On"

            PropertyChanges {
                target: label
                color: onColor
                text: textOnState
            }
        }
    ]

    transitions: [
        Transition {
            from: ""
            to: "overOff"
            reversible: true

            ColorAnimation {
                duration: 100
            }
        },
        Transition {
            from: "On"
            to: "overOn"
            reversible: true

            ColorAnimation {
                duration: 100
            }
        }
    ]

    Rectangle {
        id: rect1
        color: '#666666'
        border.color: '#cccccc'
        border.width: 1
        radius: 5
        anchors.rightMargin: 1
        anchors.leftMargin: 1
        anchors.bottomMargin: 1
        anchors.topMargin: 1
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.fill: parent

        Text {
            id: label
            text: textOffState
            font.family: 'Helvetica'
            font.pointSize: 10
            anchors {
                centerIn: parent
                margins: 2
            }
            color: offColor
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true

            onClicked: {
                if (!active) {
                    return;
                }

                if (enableState) {
                    toggleSwitch.state = '';
                    enableState = false;
                }
                else {
                    toggleSwitch.state = 'On';
                    enableState = true;
                }

                toggleSwitch.clicked(enableState);
            }

            onEntered: {
                if (enableState) {
                    toggleSwitch.state = 'overOn';
                }
                else {
                    toggleSwitch.state = 'overOff';
                }
            }

            onExited: {
                if (enableState) {
                    toggleSwitch.state = 'On';
                }
                else {
                    toggleSwitch.state = '';
                }
            }
        }

    }
}

