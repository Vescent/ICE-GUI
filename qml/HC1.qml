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
    property string widgetTitle: 'ICE-HC1: High Current Driver'
    property int slot: 1
    property int updateRate: 1000
    property real maxCurrent: 4000
    property bool active: false
    signal error(string msg)

    onActiveChanged: {
        if (active) {
            getLaser();
            getCurrent();
            getCurrentLimit();

			intervalTimer.start();
        }
        else {
            intervalTimer.stop();
        }
    }

    function timerUpdate() {
        getLaser();
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
    function setLaser(value) {
        state = (value) ? 'On' : 'Off';
        ice.send('Laser ' + state, slot, function(result){
            var enable = false
            if (result === 'On') {
                enable = true;
            }
            else {
                enable = false;
            }

            toggleswitchLaser1.enableSwitch(enable);
        });
    }

    function getLaser() {
        ice.send('Laser?', slot, function(result){
            var enable = false
            if (result === 'On') {
                enable = true;
            }
            else {
                enable = false;
            }

            toggleswitchLaser1.enableSwitch(enable);
        });
    }

    function setCurrent(value) {
        ice.send('CurrSet ' + value, slot, function(result){
            rotarycontrolCurrent1.setValue(result);
        });
    }

    function getCurrent() {
        ice.send('CurrSet?', slot, function(result){
            rotarycontrolCurrent1.setValue(result);
        });
    }

    function setCurrentLimit(value) {
        ice.send('CurrLim ' + value, slot, function(result){
            datainputCurrentLimit1.setValue(result);
            rotarycontrolCurrent1.maxValue = parseFloat(result);
        });
    }

    function getCurrentLimit() {
        ice.send('CurrLim?', slot, function(result){
            datainputCurrentLimit1.setValue(result);
            rotarycontrolCurrent1.maxValue = parseFloat(result);
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
            text: qsTr("Output:")
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
            text: "0"
            precision: 4
            useInt: true
            maxVal: maxCurrent
            minVal: 0
            decimal: 0
            pointSize: 19
            stepSize: 10
            onValueEntered: setCurrentLimit(newVal)
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
            decimalPlaces: 0
            useArc: true
            showRange: true
            value: 0
            stepSize: 1
            minValue: 0
            maxValue: maxCurrent
            onNewValue: {
                setCurrent(value);
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
            onClicked: setLaser(enableState)
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
}
