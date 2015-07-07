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
    property string widgetTitle: 'ICE-DC1: SOA Driver'
    property int slot: 1
    property int updateRate: 1000
    property real maxCurrent: 1000
    property bool active: false
    signal error(string msg)
    property var global: ({
                              evtLOff1Addr: 0,
                              evtLOff2Addr: 0
                          })

    onActiveChanged: {
        if (active) {
            getLaser(1);
            getCurrent(1);
            getCurrentLimit(1);

            getLaser(2);
            getCurrent(2);
            getCurrentLimit(2);

            getEvtLOff(1);
            getEvtLOff(2);
            getEvtLOffRow(1);
            getEvtLOffRow(2);

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
				python.log('Successfully saved settings.');
			}
			else {
				python.log('Error saving settings.');
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

    function getEvtLOff(channel) {
        var result = ice.send('EvtLOff? ' + channel, slot, null);
        var addr = parseInt(result);

        if (channel === 1) {
            laserAddr1TextField.value = addr;
            global.evtLOff1Addr = addr;
        }
        else if (channel === 2) {
            //laserAddr2TextField.value = addr;
            global.evtLOff2Addr = addr;
        }

        return addr;
    }

    function getEvtLOffRow(channel) {
        var result = ice.send('Laser? ' + channel, slot, null);
        var row = 0;

        if (result.toUpperCase() == 'ON') {
            result = ice.send('Current? ' + channel, slot, null);
            var current = parseFloat(result);

            if (current < 0.005) {
                row = 2;
            }
            else {
                row = 1;
            }
        }
        else {
            row = 2;
        }

        setCurrentLOffRow(row, channel);
        return row;
    }

    function setCurrentLOffRow(row, channel) {
        if (channel === 1) {
            if (row === 1) {
                var rect1 = rectEvtLoff1State2;
                var rect2 = rectEvtLoff1State1;
            }
            else {
                var rect1 = rectEvtLoff1State1;
                var rect2 = rectEvtLoff1State2;
            }
        }
        else {
            if (row === 1) {
                var rect1 = rectEvtLoff2State2;
                var rect2 = rectEvtLoff2State1;
            }
            else {
                var rect1 = rectEvtLoff2State1;
                var rect2 = rectEvtLoff2State2;
            }
        }


        var item1 = rect1.children[0];
        var item2 = rect2.children[0];
        rect1.border.color = '#CCCCCC'
        item1.color = '#FFFFFF';
        item1.font.bold = false;
        rect2.border.color = '#3399ff'
        item2.color = '#3399ff';
        item2.font.bold = true;
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
        width: 465
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
            width: 120
            height: 35
            text: "0.0"
            precision: 5
            useInt: false
            maxVal: maxCurrent
            minVal: 0
            decimal: 1
            pointSize: 19
            stepSize: 1
            onValueEntered: setCurrentLimit(newVal, 1)
        }

        Text {
            id: textCurrentLimit1
            x: 128
            y: 70
            color: "#ffffff"
            text: qsTr("Current Limit (mA)")
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
            text: qsTr("Laser Current (mA)")
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
            stepSize: 2
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

        Rectangle {
            id: rectLOffEvents1
            anchors.top: parent.top
            anchors.left: datainputCurrentLimit1.right
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 10
            anchors.leftMargin: 20
            color: "#505050"
            radius: 5

            Text {
                id: eventLOff1Title
                color: "#cccccc"
                text: "Laser Pulse Events"
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.top: parent.top
                anchors.topMargin: 7
                styleColor: "#ffffff"
                font.bold: true
                font.pointSize: 10
            }

            Column {
                id: controlsLOff1
                anchors.left: parent.left
                anchors.top: eventLOff1Title.bottom
                anchors.margins: 10
                spacing: 5
                width: 60

                Text {
                    text: 'Address:'
                    color: "#ffffff"
                    font.pointSize: 10
                }

                DataInput {
                    id: laserAddr1TextField
                    width: 40
                    useInt: true
                    pointSize: 12
                    maxVal: 7
                    minVal: 0
                    value: 0
                    decimal: 0
                    stepSize: 1
                    onValueEntered: {
                        global.evtLOff1Addr = newVal;
                        ice.send('EvtLOff 1 ' + global.evtLOff1Addr, slot, null);
                    }
                }

                ThemeButton {
                    id: trigLOff1Btn
                    y: 7
                    width: 50
                    height: 30
                    text: "Trig"
                    highlight: false
                    onClicked: {
                        ice.send('#DoEvent ' + global.evtLOff1Addr, slot, null);
                        getEvtLOffRow(1);
                    }
                    enabled: true
                }
            }

            Column {
                id: columnLOff1
                anchors.left: controlsLOff1.right
                anchors.right: parent.left
                anchors.top: eventLOff1Title.bottom
                anchors.bottom: parent.bottom
                anchors.margins: 10
                spacing: 5

                Rectangle {
                    width: parent.width
                    height: 10

                    Text {
                        x: 0
                        anchors.top: parent.top
                        text: "State"
                        color: "#cccccc"
                    }

                    Text {
                        x: 40
                        anchors.top: parent.top
                        text: "Laser"
                        color: "#cccccc"
                    }
                }

                Rectangle {
                    id: rectEvtLoff1State1
                    width: 70
                    height: 20
                    color: "#202020"
                    border.color: '#cccccc'
                    border.width: 1;
                    radius: 5

                    Text {
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: '1'
                        color: "#cccccc"
                    }

                    Text {
                        x: 40
                        anchors.verticalCenter: parent.verticalCenter
                        text: 'On'
                        color: "#FFFFFF"
                    }
                }

                Rectangle {
                    id: rectEvtLoff1State2
                    width: 70
                    height: 20
                    color: "#202020"
                    border.color: '#cccccc'
                    border.width: 1;
                    radius: 5

                    Text {
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: '2'
                        color: "#cccccc"
                    }

                    Text {
                        x: 40
                        anchors.verticalCenter: parent.verticalCenter
                        text: 'Off'
                        color: "#FFFFFF"
                    }
                }

                Text {
                    text: "Note: TTL Event\ninputs may\noverride GUI\ntrigger button."
                    color: "#cccccc"
                }
            }
        }

	}

	Rectangle {
        id: rect2
        x: 9
        y: 32
        anchors.top: rect1.bottom
        anchors.topMargin: 10
        width: 465
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
            width: 120
            height: 35
            text: "0.0"
            precision: 5
            useInt: false
            maxVal: maxCurrent
            minVal: 0
            decimal: 1
            pointSize: 19
            stepSize: 1
            onValueEntered: setCurrentLimit(newVal, 2)
        }

        Text {
            id: textCurrentLimit2
            x: 128
            y: 70
            color: "#ffffff"
            text: qsTr("Current Limit (mA)")
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
            text: qsTr("Laser Current (mA)")
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
            stepSize: 2
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

        Rectangle {
            id: rectLOffEvents2
            anchors.top: parent.top
            anchors.left: datainputCurrentLimit2.right
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 10
            anchors.leftMargin: 20
            color: "#505050"
            radius: 5

            Text {
                id: eventLOff2Title
                color: "#cccccc"
                text: "Laser Pulse Events"
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.top: parent.top
                anchors.topMargin: 7
                styleColor: "#ffffff"
                font.bold: true
                font.pointSize: 10
            }

            Column {
                id: controlsLOff2
                anchors.left: parent.left
                anchors.top: eventLOff2Title.bottom
                anchors.margins: 10
                spacing: 5
                width: 60

                Text {
                    text: 'Address:'
                    color: "#ffffff"
                    font.pointSize: 10
                }

                DataInput {
                    id: laserAddr2TextField
                    width: 40
                    useInt: true
                    pointSize: 12
                    maxVal: 7
                    minVal: 0
                    value: 0
                    decimal: 0
                    stepSize: 1
                    onValueEntered: {
                        global.evtLOff2Addr = newVal;
                        ice.send('EvtLOff 2 ' + global.evtLOff2Addr, slot, null);
                    }
                }

                ThemeButton {
                    id: trigLOff2Btn
                    y: 7
                    width: 50
                    height: 30
                    text: "Trig"
                    highlight: false
                    onClicked: {
                        ice.send('#DoEvent ' + global.evtLOff2Addr, slot, null);
                        getEvtLOffRow(2);
                    }
                    enabled: true
                }
            }

            Column {
                id: columnLOff2
                anchors.left: controlsLOff2.right
                anchors.right: parent.left
                anchors.top: eventLOff2Title.bottom
                anchors.bottom: parent.bottom
                anchors.margins: 10
                spacing: 5

                Rectangle {
                    width: parent.width
                    height: 10

                    Text {
                        x: 0
                        anchors.top: parent.top
                        text: "State"
                        color: "#cccccc"
                    }

                    Text {
                        x: 40
                        anchors.top: parent.top
                        text: "Laser"
                        color: "#cccccc"
                    }
                }

                Rectangle {
                    id: rectEvtLoff2State1
                    width: 70
                    height: 20
                    color: "#202020"
                    border.color: '#cccccc'
                    border.width: 1;
                    radius: 5

                    Text {
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: '1'
                        color: "#cccccc"
                    }

                    Text {
                        x: 40
                        anchors.verticalCenter: parent.verticalCenter
                        text: 'On'
                        color: "#FFFFFF"
                    }
                }

                Rectangle {
                    id: rectEvtLoff2State2
                    width: 70
                    height: 20
                    color: "#202020"
                    border.color: '#cccccc'
                    border.width: 1;
                    radius: 5

                    Text {
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: '2'
                        color: "#cccccc"
                    }

                    Text {
                        x: 40
                        anchors.verticalCenter: parent.verticalCenter
                        text: 'Off'
                        color: "#FFFFFF"
                    }
                }

                Text {
                    text: "Note: TTL Event\ninputs may\noverride GUI\ntrigger button."
                    color: "#cccccc"
                }

            }
        }

	}
}
