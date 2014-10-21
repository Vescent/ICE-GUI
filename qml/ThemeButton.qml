import QtQuick 2.0

Item {
    id: themeButton
    width: label.paintedWidth + 15
    height: label.paintedHeight + 5
    property alias text: label.text
    property color textColor: '#FFF'
    property alias backgroundColor: rect1.color
    property alias pointSize: label.font.pointSize
    property alias radius: rect1.radius
    property bool highlight: false
    property color highlightColor: '#39F'
    property int borderWidth: 1
    property bool enabled: true
    signal clicked()

    states: [
        State {
            name: "down"
            when: mouseArea.pressed === true

            PropertyChanges {
                target: rect1
                color: '#222222'
            }
        },
        State {
            name: "over"
            when: mouseArea.containsMouse === true

            PropertyChanges {
                target: rect1
                border.color: '#3399ff'
            }
        }
    ]

    transitions: [
        Transition {
            from: ""
            to: "down"
            reversible: true

            ColorAnimation {
                duration: 500
            }
        },
        Transition {
            from: ""
            to: "over"
            reversible: true

            ColorAnimation {
                duration: 100
            }
        }
    ]

    Rectangle {
        id: rect1
        color: (highlight) ? highlightColor : '#666666'
        border.color: '#cccccc'
        border.width: borderWidth
        radius: 5
        anchors.horizontalCenterOffset: 0
        anchors.rightMargin: 0
        anchors.leftMargin: 0
        anchors.bottomMargin: 0
        anchors.topMargin: 0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.fill: parent

        Text {
            id: label
            text: "Button"
            font.family: 'Helvetica'
            font.pointSize: 10
            anchors {
                centerIn: parent
                margins: 2
            }
            color: (themeButton.enabled) ? textColor : '#333'
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            enabled: themeButton.enabled

            onClicked: {
                themeButton.clicked()
            }
        }

    }
}

