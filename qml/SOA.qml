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
    property string widgetTitle: 'SOA Driver'
    property int slot: 1
    property int updateRate: 1000
    property real maxCurrent: 1000
    property bool active: false
    signal error(string msg)

    onActiveChanged: {
        if (active) {
            getLaser(1);
            getCurrent(1);
            getCurrentLimit(1);

            getLaser(2);
            getCurrent(2);
            getCurrentLimit(2);

			intervalTimer.start();
        }
        else {
            intervalTimer.stop();
        }
    }

    function timerUpdate() {
        getLaser(1);
        getLaser(2);
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
    function setLaser(value, channel) {
        state = (value) ? 'On' : 'Off';
        ice.send('Laser ' + channel + ' ' + state, slot, function(result){
            var enable = false
            if (result === 'On') {
                enable = true;
            }
            else {
                enable = false;
            }

            if (channel === 1) {
                toggleswitchLaser1.enableSwitch(enable);
            }
            else {
                toggleswitchLaser2.enableSwitch(enable);
            }
        });
    }

    function getLaser(channel) {
        ice.send('Laser? ' + channel, slot, function(result){
            var enable = false
            if (result === 'On') {
                enable = true;
            }
            else {
                enable = false;
            }

            if (channel === 1) {
                toggleswitchLaser1.enableSwitch(enable);
            }
            else {
                toggleswitchLaser2.enableSwitch(enable);
            }
        });
    }

    function setCurrent(value, channel) {
        ice.send('CurrSet ' + channel + ' ' + value, slot, function(result){
            if (channel === 1) {
                rotarycontrolCurrent1.setValue(result);
            }
            else {
                rotarycontrolCurrent2.setValue(result);
            }
        });
    }

    function getCurrent(channel) {
        ice.send('CurrSet? ' + channel, slot, function(result){
            if (channel === 1) {
                rotarycontrolCurrent1.setValue(result);
            }
            else {
                rotarycontrolCurrent2.setValue(result);
            }
        });
    }

    function setCurrentLimit(value, channel) {
        ice.send('CurrLim ' + channel + ' ' + value, slot, function(result){
            if (channel === 1) {
                datainputCurrentLimit1.setValue(result);
                rotarycontrolCurrent1.maxValue = parseFloat(result);
            }
            else {
                datainputCurrentLimit2.setValue(result);
                rotarycontrolCurrent2.maxValue = parseFloat(result);
            }
        });
    }

    function getCurrentLimit(channel) {
        ice.send('CurrLim? ' + channel, slot, function(result){
            if (channel === 1) {
                datainputCurrentLimit1.setValue(result);
                rotarycontrolCurrent1.maxValue = parseFloat(result);
            }
            else {
                datainputCurrentLimit2.setValue(result);
                rotarycontrolCurrent2.maxValue = parseFloat(result);
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
        id: rect1
        x: 9
        y: 32
        width: 260
        height: 180
        color: "#00000000"
        radius: 7
        border.color: "#cccccc"

        Text {
            id: textEnable1
            x: 12
            y: 8
			anchors.top: parent.top
            anchors.topMargin: 10
            color: "#ffffff"
            text: qsTr("Output 1:")
            font.pointSize: 12
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        DataInput {
            id: datainputCurrentLimit1
            anchors.top: parent.top
            anchors.topMargin: 120
            anchors.left: parent.left
            anchors.leftMargin: 140
            width: 106
            height: 35
            text: "0.0"
            precision: 5
            useInt: false
            maxVal: maxCurrent
            minVal: 0
            decimal: 1
            pointSize: 19
            onValueEntered: setCurrentLimit(newVal, 1)
        }

        Text {
            id: textCurrentLimit1
            x: 128
            y: 70
            color: "#ffffff"
            text: qsTr("Current Limit")
            anchors.bottom: datainputCurrentLimit1.top
            anchors.bottomMargin: 5
            anchors.left: datainputCurrentLimit1.left
            font.pointSize: 12
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            id: textCurrentSet1
            x: 27
            y: 5
            color: "#ffffff"
            text: qsTr("Laser Current")
            anchors.bottom: rotarycontrolCurrent1.top
            anchors.bottomMargin: 3
            anchors.horizontalCenterOffset: 0
            anchors.horizontalCenter: rotarycontrolCurrent1.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 10
            verticalAlignment: Text.AlignVCenter
        }

        RotaryControl {
            id: rotarycontrolCurrent1
            width: 100
            height: 100
            colorInner: "#ff7300"
            anchors.top: parent.top
            anchors.topMargin: 60
            anchors.left: parent.left
            anchors.leftMargin: 10
            displayTextRatio: 0.2
            decimalPlaces: 1
            useArc: true
            showRange: true
            value: 0
            stepSize: 1
            minValue: 0
            maxValue: maxCurrent
            onNewValue: {
                setCurrent(value, 1);
            }
        }

        ToggleSwitch {
            id: toggleswitchLaser1
            anchors.top: parent.top
            anchors.topMargin: 60
            anchors.left: parent.left
            anchors.leftMargin: 140
            width: 56
            height: 32
            pointSize: 12
            onClicked: setLaser(enableState, 1)
        }

        Text {
            id: textLaserBtn1
            color: "#ffffff"
            text: qsTr("Laser State")
            anchors.left: toggleswitchLaser1.left
            anchors.bottom: toggleswitchLaser1.top
            anchors.bottomMargin: 5
            font.pointSize: 12
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
		
	}

	Rectangle {
        id: rect2
        x: 9
        y: 32
        anchors.top: rect1.bottom
        anchors.topMargin: 10
        width: 260
        height: 180
        color: "#00000000"
        radius: 7
        border.color: "#cccccc"

        Text {
            id: textEnable2
            x: 12
            y: 8
			anchors.top: parent.top
            anchors.topMargin: 10
            color: "#ffffff"
            text: qsTr("Output 2:")
            font.pointSize: 12
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        DataInput {
            id: datainputCurrentLimit2
            anchors.top: parent.top
            anchors.topMargin: 120
            anchors.left: parent.left
            anchors.leftMargin: 140
            width: 106
            height: 35
            text: "0.0"
            precision: 5
            useInt: false
            maxVal: maxCurrent
            minVal: 0
            decimal: 1
            pointSize: 19
            onValueEntered: setCurrentLimit(newVal, 2)
        }

        Text {
            id: textCurrentLimit2
            x: 128
            y: 70
            color: "#ffffff"
            text: qsTr("Current Limit")
            anchors.bottom: datainputCurrentLimit2.top
            anchors.bottomMargin: 5
            anchors.left: datainputCurrentLimit2.left
            font.pointSize: 12
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            id: textCurrentSet2
            x: 27
            y: 5
            color: "#ffffff"
            text: qsTr("Laser Current")
            anchors.bottom: rotarycontrolCurrent2.top
            anchors.bottomMargin: 3
            anchors.horizontalCenterOffset: 0
            anchors.horizontalCenter: rotarycontrolCurrent2.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 10
            verticalAlignment: Text.AlignVCenter
        }

        RotaryControl {
            id: rotarycontrolCurrent2
            width: 100
            height: 100
            colorInner: "#ff7300"
            anchors.top: parent.top
            anchors.topMargin: 60
            anchors.left: parent.left
            anchors.leftMargin: 10
            displayTextRatio: 0.2
            decimalPlaces: 1
            useArc: true
            showRange: true
            value: 0
            stepSize: 1
            minValue: 0
            maxValue: maxCurrent
            onNewValue: {
                setCurrent(value, 2);
            }
        }

        ToggleSwitch {
            id: toggleswitchLaser2
            anchors.top: parent.top
            anchors.topMargin: 60
            anchors.left: parent.left
            anchors.leftMargin: 140
            width: 56
            height: 32
            pointSize: 12
            onClicked: setLaser(enableState, 2)
        }

        Text {
            id: textLaserBtn2
            color: "#ffffff"
            text: qsTr("Laser State")
            anchors.left: toggleswitchLaser2.left
            anchors.bottom: toggleswitchLaser2.top
            anchors.bottomMargin: 5
            font.pointSize: 12
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

	}
}
