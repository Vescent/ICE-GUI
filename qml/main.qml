import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Dialogs 1.1
import "application.js" as App

Rectangle {
    id: appWindow
    width: 825
    height: 600
    color: '#000000'
    property bool systemPower: false
    property bool serialConnected: false
    Component.onCompleted: App.onLoad()
    property int currentSlot: 1
    property bool logMode: false

    // Function that when paired with a QML Timer replicates functionality of window.setTimeout().
    function setTimeout(callback, interval) {
        oneshotTimer.interval = interval;

        // Disconnect the prior binding to the old callback function reference.
        oneshotTimer.onTriggeredState.disconnect(oneshotTimer.refFunc);

        // Store a reference to new callback function so we can unbind it later.
        oneshotTimer.refFunc = callback;

        oneshotTimer.onTriggeredState.connect(callback);
        oneshotTimer.start();
    }

    // One shot timer for implementing a window.setTimeout() function.
    Timer {
        id: oneshotTimer
        interval: 0
        running: false
        repeat: false
        triggeredOnStart: false
        signal onTriggeredState;
        onTriggered: onTriggeredState();
        property var refFunc: function() {}
    }
	
	Timer {
        id: callbackTimer
        interval: 250
        running: true
        repeat: true
        triggeredOnStart: false
        onTriggered: {
			ice.processResponses();
			ice.getResponses();
		}
    }
	
	MessageDialog {
		id: messageDialog
		title: ""
		icon: StandardIcon.Warning
		text: "Error"
		onAccepted: {
			return;
		}
	}
	
	function alert(message) {
		messageDialog.text = message;
		messageDialog.open();
	}

    Item {
        id: slotSwitcher
        width: 50
        height: 216
        anchors.top: parent.top
        anchors.topMargin: 60
        anchors.left: parent.left
        anchors.leftMargin: 0

        Column {
            id: column1
            spacing: 1
            anchors.fill: parent

            ThemeButton {
                id: slot1btn
                width: 40
                height: 26
                radius: 0
                text: "1"
                pointSize: 12
                textColor: "#ffffff"
                borderWidth: 0
                highlight: false
                onClicked: App.switchSlot(1)
                enabled: false
            }

            ThemeButton {
                id: slot2btn
                width: 40
                height: 26
                radius: 0
                text: "2"
                pointSize: 12
                textColor: "#ffffff"
                highlight: false
                borderWidth: 0
                onClicked: App.switchSlot(2)
                enabled: false
            }

            ThemeButton {
                id: slot3btn
                width: 40
                height: 26
                radius: 0
                text: "3"
                pointSize: 12
                textColor: "#ffffff"
                highlight: false
                borderWidth: 0
                onClicked: App.switchSlot(3)
                enabled: false
            }

            ThemeButton {
                id: slot4btn
                width: 40
                height: 26
                radius: 0
                text: "4"
                pointSize: 12
                textColor: "#ffffff"
                highlight: false
                borderWidth: 0
                onClicked: App.switchSlot(4)
                enabled: false
            }

            ThemeButton {
                id: slot5btn
                width: 40
                height: 26
                radius: 0
                text: "5"
                pointSize: 12
                textColor: "#ffffff"
                highlight: false
                borderWidth: 0
                onClicked: App.switchSlot(5)
                enabled: false
            }

            ThemeButton {
                id: slot6btn
                width: 40
                height: 26
                radius: 0
                text: "6"
                pointSize: 12
                textColor: "#ffffff"
                highlight: false
                borderWidth: 0
                onClicked: App.switchSlot(6)
                enabled: false
            }

            ThemeButton {
                id: slot7btn
                width: 40
                height: 26
                radius: 0
                text: "7"
                pointSize: 12
                textColor: "#ffffff"
                highlight: false
                borderWidth: 0
                onClicked: App.switchSlot(7)
                enabled: false
            }

            ThemeButton {
                id: slot8btn
                width: 40
                height: 26
                radius: 0
                text: "8"
                pointSize: 12
                textColor: "#ffffff"
                highlight: false
                borderWidth: 0
                onClicked: App.switchSlot(8)
                enabled: false
            }

        }
    }

    Rectangle {
        id: topToolbar
        width: parent.width
        height: 30
        color: "#333333"
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.top: parent.top
        anchors.topMargin: 0

        Text {
            id: vescentLogo
            y: 8
            color: "#ffffff"
            text: "Vescent"
            anchors.left: parent.left
            anchors.leftMargin: 5
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
            font.pointSize: 16
            font.family: "Calibri"
        }

        Text {
            id: iceLogo
            y: 2
            color: "#3399ff"
            text: "ICE"
            anchors.verticalCenterOffset: 0
            font.family: "Calibri"
            font.bold: false
            anchors.left: vescentLogo.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 5
            font.pointSize: 16
        }

        ComboBox {
            id: comboComPorts
            x: 216
            y: 5
            width: 72
            height: 20
            anchors.verticalCenter: parent.verticalCenter
            model: ListModel {
                id: comPortsListModel
            }
        }

        Text {
            id: textComPort
            x: 158
            y: 8
            color: "#ffffff"
            text: qsTr("COM Port:")
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 12
        }

        ThemeButton {
            id: buttonConnect
            y: 4
            width: 81
            height: 20
            text: qsTr("Connect")
            anchors.left: comboComPorts.right
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            onClicked: App.serialConnect()
        }

		/*
        ToggleSwitch {
            id: toggleswitchSystemPower
            y: 5
            anchors.left: textSystemPower.right
            anchors.leftMargin: 6
            onClicked: App.toggleSystemPower(enableState)
            opacity: serialConnected ? 1.0 : 0;
        }

        Text {
            id: textSystemPower
            y: 8
            width: 77
            color: "#ffffff"
            text: qsTr("System Power:")
            anchors.left: buttonConnect.right
            anchors.leftMargin: 12
            anchors.verticalCenterOffset: 0
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
            verticalAlignment: Text.AlignVCenter
            opacity: serialConnected ? 1.0 : 0;
        }
		*/
		
        ToggleSwitch {
            id: logMode
            x: 864
            y: 5
            text: "LOG"
            textOffState: "LOG"
            textOnState: "LOG"
            anchors.right: parent.right
            anchors.rightMargin: 10
            onClicked: {
                appWindow.logMode = enableState;
                ice.setLogging(enableState);
            }
        }
    }

    Row {
        id: widgetView
        x: 55
        y: 38
        width: 835
        height: 530
        anchors.rightMargin: 10
        anchors.leftMargin: 55
        anchors.bottomMargin: 32
        anchors.topMargin: 38
        anchors.fill: parent
        spacing: 10
    }

    function commandSend(command) {
		ice.send(command, currentSlot, function(response){
            commandResult.text = response;
        });
    }

    TextField {
        id: commandEntry
        x: 55
        y: 574
        width: 172
        height: 20
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        placeholderText: "Enter Command"
        onAccepted: commandSend(commandEntry.text)
    }

    TextField {
        id: commandResult
        y: 574
        height: 20
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.left: commandEntry.right
        anchors.leftMargin: 6
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        placeholderText: "Command Result"
    }

    Text {
        id: textSlot
        x: 8
        y: 38
        color: "#aaaaaa"
        text: qsTr("Slot:")
        anchors.horizontalCenter: rectangle2.horizontalCenter
        z: 1
        horizontalAlignment: Text.AlignRight
        anchors.verticalCenterOffset: 0
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: 14
        anchors.verticalCenter: rectangle2.verticalCenter
    }

    Rectangle {
        id: rectangle1
        x: 0
        width: 40
        color: "#666666"
        anchors.top: slotSwitcher.bottom
        anchors.topMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
    }

    Rectangle {
        id: rectangle2
        x: 0
        y: 30
        width: 40
        height: 24
        color: "#666666"
        anchors.bottom: slotSwitcher.top
        anchors.top: topToolbar.bottom
        anchors.topMargin: 0
        anchors.bottomMargin: 1
    }
}
