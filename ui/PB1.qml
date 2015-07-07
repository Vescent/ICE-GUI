import QtQuick 2.0
import QtQuick.Controls 1.0

Rectangle {
    id: widget
    width: 750
    height: 525
    color: "#333333"
    radius: 15
    border.width: 2
    border.color: (active) ? '#3399ff' : "#666666";
    property string widgetTitle: 'ICE-PB1: Power Breakout'
    property int slot: 1
    property int updateRate: 1000
    property bool active: false
    signal error(string msg)

    onActiveChanged: {
        if (active) {
            getEnable();
			getAutoPower();
			intervalTimer.start();
        }
        else {
            intervalTimer.stop();
        }
    }

    function timerUpdate() {
        getEnable();
    }
	
	function save(value) {
		ice.send('Save', slot, function(result){
			if (result == "Success") {
				console.log('Successfully saved settings.');
			}
			else {
				console.log('Error saving settings.');
			}
		});
	}

    // Common Laser Controller Command Set
    function setEnable(value) {
        state = (value) ? 'On' : 'Off';
        ice.send('Enable ' + state, slot, function(result){
            if (result === 'On') {
                toggleswitchEnable.enableSwitch(true);
				faultText.visible = false;
            }
            else {
                toggleswitchEnable.enableSwitch(false);
				
				if (result === 'Fault') {
					faultText.visible = true;
				}
				else {
					faultText.visible = false;
				}
            }
        });
    }

    function getEnable() {
        ice.send('Enable?', slot, function(result){
            if (result === 'On') {
                toggleswitchEnable.enableSwitch(true);
				faultText.visible = false;
            }
            else {
                toggleswitchEnable.enableSwitch(false);
				
				if (result === 'Fault') {
					faultText.visible = true;
				}
				else {
					faultText.visible = false;
				}
            }
        });
    }
	
	function setAutoPower(value) {
        state = (value) ? 'On' : 'Off';
        ice.send('AutoPwr ' + state, slot, function(result){
            if (result === 'On') {
                toggleswitchAutoPwr.enableSwitch(true);
            }
            else {
                toggleswitchAutoPwr.enableSwitch(false);
            }
        });
    }

    function getAutoPower() {
        ice.send('AutoPwr?', slot, function(result){
            if (result === 'On') {
                toggleswitchAutoPwr.enableSwitch(true);
            }
            else {
                toggleswitchAutoPwr.enableSwitch(false);
            }
        });
    }

    Timer {
        id: intervalTimer
        interval: updateRate
        running: false
        repeat: true
        onTriggered: timerUpdate()
        triggeredOnStart: true
    }

    Text {
        id: textWidgetTitle
        height: 20
        color: "#cccccc"
        text: slot.toString() + ": " + widgetTitle
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.top: parent.top
        anchors.topMargin: 7
        styleColor: "#ffffff"
        font.bold: true
        font.pointSize: 12
        font.family: "MS Shell Dlg 2"
    }
	
	ThemeButton {
		id: saveBtn
		y: 7
		width: 40
		height: 20
		anchors.right: widget.right
		anchors.rightMargin: 10
		text: "Save"
		highlight: false
		onClicked: save()
		enabled: true
	}

	Rectangle {
        id: rect
        x: 9
        y: 32
        width: 200
        height: 130
        color: "#00000000"
        radius: 7
        border.color: "#cccccc"
	
		Text {
            id: textEnable
            x: 12
            y: 8
			anchors.top: rect.top
            anchors.topMargin: 10
            color: "#ffffff"
            text: qsTr("Power Output Enable:")
            font.pointSize: 12
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
		
        ToggleSwitch {
            id: toggleswitchEnable
            x: 8
            y: 33
            width: 47
            height: 26
			anchors.top: textEnable.bottom
            anchors.topMargin: 5
            onClicked: setEnable(enableState)
        }
		
		Text {
            id: faultText
            x: 12
            y: 8
            color: "#FF0000"
            text: qsTr("FAULT")
            font.pointSize: 14
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
			anchors.left: toggleswitchEnable.right
            anchors.leftMargin: 10
            anchors.verticalCenter: toggleswitchEnable.verticalCenter
			visible: false
        }
		
		Text {
            id: textAutopower
			x: 8
			y: 8
            anchors.top: toggleswitchEnable.bottom
            anchors.topMargin: 10
            color: "#ffffff"
            text: qsTr("Auto Power On Enable:")
            font.pointSize: 12
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
		
        ToggleSwitch {
            id: toggleswitchAutoPwr
            x: 8
			y: 8
            anchors.top: textAutopower.bottom
            anchors.topMargin: 5
            width: 47
            height: 26
            onClicked: setAutoPower(enableState)
        }
		
	}
}
