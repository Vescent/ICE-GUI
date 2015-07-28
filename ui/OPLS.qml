import QtQuick 2.0

Rectangle {
    id: widget
    width: 750
    height: 525
    color: "#333333"
    radius: 15
    border.width: 2
    border.color: (active) ? '#3399ff' : "#666666";
    property string widgetTitle: 'ICE-CP1: OPLS and Current Controller'
    property int slot: 1
    property bool active: false
    property int updateRate: 500
    property bool alternate: false
    property int dataWidth: 256
    property real maxRampVal: 2.4
    property real maxCurrent: 200
    property var global: ({
                              numDataPoints: 256,
                              rampOn: false,
                              servoOn: false,
                              rampCenter: 0,
							  rampSwp: 10,
							  evtLOffAddr: 0,
                              evtJumpAddr: 0,
                              evtNum: 0
                          })
	property double intfreq: 100

    signal error(string msg)

    onActiveChanged: {
        if (active) {
            ice.send('#pauselcd f', slot, null);

            getLaser();
            getCurrent();
            getCurrentLimit();

            getRampSweep();
            setRampNum(widget.dataWidth);

            getNDiv();
            getInvert();
            getIntRef();
            getIntFreq();
            getServo();
            getServoOffset();
            getGain();

            intervalTimer.start();
            setGraphLabels();
            getFeatureID();

            if (typeof(appWindow.widgetState[slot].vDivSetting) === 'number') {
                graphcomponent.vDivSetting = appWindow.widgetState[slot].vDivSetting;
            }

            if (typeof(appWindow.widgetState[slot].numDataPoints) === 'number') {
                global.numDataPoints = appWindow.widgetState[slot].numDataPoints;
            }
			
			/*
            if (typeof(appWindow.widgetState[slot].rampOn) === 'boolean') {
                global.rampOn = appWindow.widgetState[slot].rampOn;

                if (global.rampOn) {
                    setServo(false);
                }

                runRamp(global.rampOn)
                //python.log('Ramp: ' + global.rampOn);
            }

            if (typeof(appWindow.widgetState[slot].servoOn) === 'boolean') {
                global.servoOn = appWindow.widgetState[slot].servoOn;
                runRamp(false);
                setServo(global.servoOn);
                //python.log('Servo: ' + global.rampOn);
            }
			*/

			if (global.servoOn) {
                runRamp(false);
            }

            graphcomponent.refresh();
        }
        else {
            intervalTimer.stop();
            runRamp(false);

            appWindow.widgetState[slot].vDivSetting = graphcomponent.vDivSetting;
            appWindow.widgetState[slot].numDataPoints = global.numDataPoints;
            appWindow.widgetState[slot].rampOn = global.rampOn;
            appWindow.widgetState[slot].servoOn = global.servoOn;
        }
    }

    function getFeatureID() {
        ice.send('Enumdev', slot, function(result){
            var deviceID = result.split(" ");
            var feature = parseInt(deviceID[2], 10);

            if (feature === 0) {
                maxCurrent = 200;
            }
            else if (feature === 1) {
                maxCurrent = 500;
            }
            else {
                python.log("Error getting feature ID");
            }
        });
    }

    function timerUpdate() {
        if (global.servoOn === true) {
            updateServoLock();
        }
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

	function setGraphLabels() {
        var yDiv = (graphcomponent.yMaximum - graphcomponent.yMinimum)/graphcomponent.gridYDiv;
        var xDiv = global.rampSwp/graphcomponent.gridXDiv;
        xDiv = xDiv.toFixed(2);
        graphcomponent.axisXLabel = "Ramp Voltage [" + xDiv + " V/Div]";
        //graphcomponent.axisYLabel = "Error Input [" + yDiv + " V/Div]";
        graphcomponent.refresh();
	}

    // Common Laser Controller Command Set
    function setLaser(value) {
        state = (value) ? 'On' : 'Off';
        ice.send('Laser ' + state, slot, function(result){
            if (result === 'On') {
                toggleswitchLaser.enableSwitch(true);
            }
            else {
                toggleswitchLaser.enableSwitch(false);
            }
            return;
        });
    }

    function getLaser() {
        ice.send('Laser?', slot, function(result){
            if (result === 'On') {
                toggleswitchLaser.enableSwitch(true);
            }
            else {
                toggleswitchLaser.enableSwitch(false);
            }
            return;
        });
    }

    function setCurrent(value) {
        ice.send('CurrSet ' + value, slot, function(result){
            rotarycontrolCurrent.setValue(result);
            return;
        });
    }

    function getCurrent() {
        ice.send('CurrSet?', slot, function(result){
            rotarycontrolCurrent.setValue(result);
            return;
        });
    }

    function setCurrentLimit(value) {
        ice.send('CurrLim ' + value, slot, function(result){
            datainputCurrentLimit.setValue(result);
            rotarycontrolCurrent.maxValue = parseFloat(result);
            return;
        });
    }

    function getCurrentLimit() {
        ice.send('CurrLim?', slot, function(result){
            datainputCurrentLimit.setValue(result);
            rotarycontrolCurrent.maxValue = parseFloat(result);
            return;
        });
    }

    // OPLS Commands
    function setNDiv(value) {
        ice.send('N ' + value, slot, function(result){
            rotarycontrolNDiv.setValue(result);
            return;
        });
    }

    function getNDiv() {
        ice.send('N?', slot, function(result){
            rotarycontrolNDiv.setValue(result);
            return;
        });
    }

    function setInvert(value) {
        state = (value) ? 'On' : 'Off';
        ice.send('Invert ' + state, slot, function(result){
            if (result === 'On') {
                toggleswitchInvert.enableSwitch(true);
            }
            else {
                toggleswitchInvert.enableSwitch(false);
            }

            return;
        });
    }

    function getInvert() {
        ice.send('Invert?', slot, function(result){
            if (result === 'On') {
                toggleswitchInvert.enableSwitch(true);
            }
            else {
                toggleswitchInvert.enableSwitch(false);
            }

            return;
        });
    }

    function setIntRef(value) {
        state = (value) ? 'On' : 'Off';
        ice.send('IntRef ' + state, slot, function(result){
            if (result === 'On') {
                toggleswitchIntRef.enableSwitch(true);
            }
            else {
                toggleswitchIntRef.enableSwitch(false);
            }

            return;
        });
    }

    function getIntRef() {
        ice.send('IntRef?', slot, function(result){
            if (result === 'On') {
                toggleswitchIntRef.enableSwitch(true);
            }
            else {
                toggleswitchIntRef.enableSwitch(false);
            }

            return;
        });
    }

    function setIntFreq(value) {
        ice.send('IntFreq ' + value, slot, function(result){
            datainputIntFreq.setValue(result);
            return;
        });
    }

    function getIntFreq() {
        ice.send('IntFreq?', slot, function(result){
            datainputIntFreq.setValue(result);
			/*
			//var val = '100.0000000000';
			//datainputIntFreq.setValue(val);
			var num = parseFloat(val);
			intfreq = num;
			python.log(val);
			python.log(num);
			python.log(num.toFixed(6));
			python.log(intfreq);
			//datainputIntFreq.text = intfreq.toFixed(6);
			*/
            return;
        });
    }

    function getVoltage(value) {
        ice.send('ReadVolt? ' + value, slot, function(result){
            return;
        });
    }

    function setServo(value) {
        state = (value) ? 'On' : 'Off';
        
        if (value === true) {
            global.servoOn = true;
        }
        else {
            global.servoOn = false;
        }
        
        ice.send('Servo ' + state, slot, function(result){
            if (result === 'On') {
                toggleswitchServo.enableSwitch(true);
            }
            else {
                toggleswitchServo.enableSwitch(false);
            }

            return;
        });
    }

    function getServo() {
        ice.send('Servo?', slot, function(result){
            if (result === 'On') {
                toggleswitchServo.enableSwitch(true);
				global.servoOn = true;
            }
            else {
                toggleswitchServo.enableSwitch(false);
				global.servoOn = false;
            }

            return;
        });
    }

    function setGain(value) {
        ice.send('Gain ' + value, slot, function(result){
            rotarycontrolGain.setValue(result);
            return;
        });
    }

    function getGain() {
        ice.send('Gain?', slot, function(result){
            rotarycontrolGain.setValue(result);
            return;
        });
    }

    function setServoOffset(value) {
        ice.send('SvOffst ' + value, slot, function(result){
            rotarycontrolServoOffset.setValue(result);
            rotarycontrolCenter.setValue(result);
            global.rampCenter = parseFloat(result);
            return;
        });
    }

    function getServoOffset() {
        ice.send('SvOffst?', slot, function(result){
            rotarycontrolServoOffset.setValue(result);
            rotarycontrolCenter.setValue(result);
            global.rampCenter = parseFloat(result);
            return;
        });
    }

    // Ramp Commands
    function setRampSweep(value) {
        ice.send('RampSwp ' + value, slot, function(result){
            rotarycontrolRange.setValue(result);
            global.rampSwp = parseFloat(result);
            setGraphLabels();
            return;
        });
    }

    function getRampSweep() {
        ice.send('RampSwp?', slot, function(result){
            rotarycontrolRange.setValue(result);
            global.rampSwp = parseFloat(result);
            return;
        });
    }

    function getRampNum() {
        ice.send('RampNum?', slot, function(result){
            datainputRampNum.setValue(result);
            global.numDataPoints = parseInt(result);
            return;
        });
    }

    function setRampNum(value) {
        ice.send('RampNum ' + value, slot, function(result){
            datainputRampNum.setValue(result);
            global.numDataPoints = parseInt(result);
            return;
        });
    }

    function updateServoLock() {
        ice.send('ReadVolt 2', slot, function(result){
            var value = parseFloat(result);
            graphcomponent.addPoint(value, 0);
            return;
        });
    }

    function runRamp(enableState) {
        if (enableState) {
            global.rampRun = true;
            toggleswitchRamp.enableSwitch(true);
			setServo(false);
			graphcomponent.clearData();
			graphcomponent.rollMode = false;
            
            ice.send('#pauselcd t', slot, function(result){});
            
            doRamp();
        }
        else {
            global.rampRun = false;
            toggleswitchRamp.enableSwitch(false);
            graphcomponent.rollMode = true;
            graphcomponent.clearData();
            
            ice.send('#pauselcd f', slot, function(result){});
        }
    }

    function doRamp() {
        global.start = new Date();
        
		if (ice.logging == true) {
			python.log('Started: ' + global.start);
		}
		
		if (global.rampRun == false) {
			return;
		}

        ice.send('RampRun', slot, function(result){
            if (result === 'Failure') {
                runRamp(false);
                error('Error: could not run ramp. Laser must be on.');
                return;
            }

            setTimeout(getRampBlockData, 150);
        });
    }

    function getRampBlockData() {
        var steps = global.numDataPoints;
        var blocks = Math.ceil(steps/4);
		
        if (global.rampRun === false) {
			return;
		}
		
        global.bulk = new Date();

        readBlock(blocks, processBlockData);
    }

    function processBlockData(data) {
        global.stop = new Date();
		
		if (ice.logging == true) {
			var totalTime = global.stop - global.start;
			python.log('Total Time (s): ' + totalTime/1000);
			var bulkTime = global.bulkStop - global.bulk;
			python.log('- Bulk (s):  ' + bulkTime/1000);
			var setupTime = totalTime - bulkTime;
			python.log('- Setup (s): ' + setupTime/1000);
		}

        // Trim excess data
        data.splice(global.numDataPoints, (data.length - global.numDataPoints));

        if (data.length === global.numDataPoints) {
            graphcomponent.plotData(data, 0);
        }
		
		if (ice.logging == true) {
			python.log('Data Points: ' + data.length + '/' + global.numDataPoints);
		}
		
        //python.log('Data: ' + dataErrInput);

        if (global.rampRun === true) {
            setTimeout(doRamp, 50);
        }
    }

    function readBlock(numBlocks, callbackFn) {
        ice.send('#BulkRead ' + numBlocks, slot, function(result){
            global.bulkStop = new Date();
            var data = decodeBlockData(result);

            callbackFn(data);
        });
    }

    // Takes string output from ICE "ReadBlk" command and converts into float array data.
    function decodeBlockData(rawData) {
        var strData = rawData.split(' ');
        var floatData = [];
        var numValues = strData.length;

        // Make sure we have an even number of data points
        if ((numValues % 2) > 0) {
            numValues -= 1;
        }

        numValues /= 2;

        for (var i = 0; i < numValues; i++) {
            var index = i*2;
            var hexStr = '0x';
            var intValue;
            var floatValue;

            // Start with index+1 because endianness needs to be reversed.
            // Pad zeros in front of single digit data.
            if (strData[index + 1].length === 1) {
                hexStr += '0';
            }

            hexStr += strData[index + 1];

            if (strData[index].length === 1) {
                hexStr += '0';
            }

            hexStr += strData[index];
            intValue = Number(hexStr);
            floatValue = convertBinToFloat(intValue, 0.25);
            floatData.push(floatValue);
        }

        return floatData;
    }

    // Takes a 12-bit ADC code and converts to floating point voltage.
    function convertBinToFloat(data, gain) {
        var count = data & 0x0FFF;
        var output = 0.0;
        var AD7327_REFERENCE_VOLTAGE = 10.0;

        // Check if data is negative (This should be shifted by 12, mask by 0x1FFF)
        if ((data & (1 << 12)) > 0) {
            output = count;
            output = -(AD7327_REFERENCE_VOLTAGE)*(1 - (output/4096))*gain;
        } else{
            output = count;
            output = output/4096*AD7327_REFERENCE_VOLTAGE*gain;
        }

        return output;
    }

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
        id: rampRect
        anchors.top: textWidgetTitle.bottom
        anchors.left: parent.left
        anchors.margins: 10
        y: 32
        width: 275
        height: 135
        color: "#00000000"
        radius: 7
        border.color: "#cccccc"

        ThemeButton {
            id: buttonRampTrig
            x: 8
            y: 65
            width: 47
            height: 26
            text: "Trig"
            onClicked: doRamp()
        }

        ToggleSwitch {
            id: toggleswitchRamp
            x: 8
            y: 33
            width: 47
            height: 26
            onClicked: runRamp(enableState)
        }

        ThemeButton {
            id: buttonRampAutoSet
            x: 8
            y: 97
            width: 47
            height: 26
            text: "Auto"
            onClicked: rampAutoSet()
        }

        Text {
            id: textRampBtn
            x: 12
            y: 8
            color: "#ffffff"
            text: qsTr("Ramp")
            font.pointSize: 12
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            id: textRampNumber
            x: 85
            y: 103
            width: 70
            height: 16
            color: "#ffffff"
            text: qsTr("Datapoints:")
            anchors.verticalCenterOffset: -2
            anchors.left: datainputRampNum.right
            anchors.leftMargin: -135
            anchors.verticalCenter: datainputRampNum.verticalCenter
            horizontalAlignment: Text.AlignLeft
            font.pointSize: 10
            verticalAlignment: Text.AlignVCenter
        }

        DataInput {
            id: datainputRampNum
            x: 161
            y: 103
            width: 59
            height: 20
            radius: 5
            text: "256"
            precision: 5
            useInt: true
            maxVal: 1024
            minVal: 1
            decimal: 0
            pointSize: 12
            onValueEntered: setRampNum(newVal)
        }

        RotaryControl {
            id: rotarycontrolCenter
            x: 178
            y: 21
            width: 76
            height: 70
            useCursor: true
            maxValue: 2.4
            minValue: -2.4
            value: 0
            stepSize: 0.05
            decimalPlaces: 2
            anchors.verticalCenterOffset: -21
            anchors.horizontalCenterOffset: 78
            onNewValue: {
                setServoOffset(value);
            }
        }

        RotaryControl {
            id: rotarycontrolRange
            x: 85
            y: 21
            width: 76
            height: 70
            value: 1
            stepSize: 0.2
            maxValue: 4.8
            minValue: 0
            decimalPlaces: 1
            anchors.verticalCenterOffset: -21
            anchors.horizontalCenterOffset: -15
            onNewValue: {
                setRampSweep(value);
            }
        }

        Text {
            id: textRampBegin1
            x: 115
            y: 0
            color: "#ffffff"
            text: qsTr("Range")
            anchors.bottom: rotarycontrolRange.top
            anchors.bottomMargin: 3
            anchors.horizontalCenter: rotarycontrolRange.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 10
            anchors.horizontalCenterOffset: 0
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            id: textRampBegin2
            x: 198
            y: 0
            color: "#ffffff"
            text: qsTr("Center")
            anchors.bottom: rotarycontrolCenter.top
            anchors.bottomMargin: 3
            anchors.horizontalCenter: rotarycontrolCenter.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 10
            anchors.horizontalCenterOffset: 0
            verticalAlignment: Text.AlignVCenter
        }
    }

    Rectangle {
        id: servoRect
        anchors.top: rampRect.bottom
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 10
        width: 275
        color: "#00000000"
        radius: 7
        border.color: "#cccccc"

        Text {
            id: textCurrentSet
            color: "#ffffff"
            text: qsTr("Laser Current (mA)")
            anchors.top: parent.top
            anchors.margins: 5
            anchors.horizontalCenterOffset: 0
            anchors.horizontalCenter: rotarycontrolCurrent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 10
            verticalAlignment: Text.AlignVCenter
        }

        RotaryControl {
            id: rotarycontrolCurrent
            x: 11
            width: 100
            height: 100
            colorInner: "#ff7300"
            anchors.top: textCurrentSet.bottom
            anchors.margins: 5
            anchors.verticalCenterOffset: -88
            anchors.horizontalCenterOffset: -76
            anchors.horizontalCenter: parent.horizontalCenter
            displayTextRatio: 0.2
            decimalPlaces: 2
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

        Text {
            id: textLaserBtn
            color: "#ffffff"
            text: qsTr("Laser")
            anchors.top: parent.top
            anchors.margins: 5
            anchors.horizontalCenter: toggleswitchLaser.horizontalCenter
            font.pointSize: 10
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        ToggleSwitch {
            id: toggleswitchLaser
            x: 132
            anchors.top: textLaserBtn.bottom
            anchors.margins: 5
            width: 56
            height: 32
            pointSize: 12
            onClicked: setLaser(enableState)
        }

        Text {
            id: textServoBtn
            color: "#ffffff"
            text: qsTr("Servo")
            anchors.top: parent.top
            anchors.margins: 5
            anchors.horizontalCenter: toggleswitchServo.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 10
            verticalAlignment: Text.AlignVCenter
        }

        ToggleSwitch {
            id: toggleswitchServo
            x: 200
            anchors.top: textServoBtn.bottom
            anchors.margins: 5
            width: 58
            height: 32
            pointSize: 12
            onClicked: {
                if (enableState) {
                    global.rampState = global.rampRun;
                    runRamp(false);
					setServo(true);
                }
                else {
                    setServo(false);
					runRamp(global.rampState); // restore old state of ramp
                }
            }
        }

        Text {
            id: textCurrentLimit
            anchors.top: toggleswitchServo.bottom
            anchors.margins: 5
            color: "#ffffff"
            text: qsTr("Current Limit (mA)")
            anchors.horizontalCenter: datainputCurrentLimit.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 10
            verticalAlignment: Text.AlignVCenter
        }

        DataInput {
            id: datainputCurrentLimit
            x: 143
            anchors.top: textCurrentLimit.bottom
            anchors.margins: 5
            width: 106
            height: 35
            text: "0.0"
            precision: 5
            useInt: false
            maxVal: maxCurrent
            minVal: 0
            decimal: 1
            pointSize: 19
            stepSize: 1
            onValueEntered: setCurrentLimit(newVal)
        }

        Text {
            id: textNDiv
            color: "#ffffff"
            text: qsTr("N Div")
            anchors.top: rotarycontrolCurrent.bottom
            anchors.margins: 5
            //anchors.horizontalCenterOffset: 1
            anchors.horizontalCenter: rotarycontrolNDiv.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 10
            verticalAlignment: Text.AlignVCenter
        }

        StepControl {
            id: rotarycontrolNDiv
            x: 250
            width: 70
            height: 70
            anchors.top: textNDiv.bottom
            anchors.margins: 5
            anchors.verticalCenterOffset: 20
            anchors.horizontalCenterOffset: 84
            displayTextRatio: 0.2
            decimalPlaces: 0
            maxValue: 3
            stepValues: [8,16,32,64]
            onNewValue: setNDiv(value)
        }

        Text {
            id: textServoOffset
            color: "#ffffff"
            text: qsTr("Servo Offset")
            anchors.top: rotarycontrolCurrent.bottom
            anchors.margins: 5
            anchors.horizontalCenter: rotarycontrolServoOffset.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 10
            verticalAlignment: Text.AlignVCenter
        }

        RotaryControl {
            id: rotarycontrolServoOffset
            x: 101
            width: 70
            height: 70
            anchors.top: textServoOffset.bottom
            anchors.margins: 5
            //anchors.verticalCenterOffset: 23
            displayTextRatio: 0.25
            decimalPlaces: 2
            useArc: true
            useCursor: true
            showRange: false
            value: 0
            stepSize: 0.05
            minValue: -2.4
            maxValue: 2.4
            onNewValue: setServoOffset(value)
        }

        Text {
            id: textGain
            color: "#ffffff"
            text: qsTr("Gain")
            anchors.top: rotarycontrolCurrent.bottom
            anchors.margins: 5
            anchors.horizontalCenter: rotarycontrolGain.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 10
            verticalAlignment: Text.AlignVCenter
        }

        RotaryControl {
            id: rotarycontrolGain
            x: 16
            width: 70
            height: 70
            anchors.top: textGain.bottom
            anchors.margins: 5
            //anchors.verticalCenterOffset: 23
            //anchors.horizontalCenterOffset: -86
            displayTextRatio: 0.3
            decimalPlaces: 0
            useArc: true
            showRange: false
            value: 1
            stepSize: 1
            minValue: 1
            maxValue: 64
            onNewValue: setGain(value)
        }

        ToggleSwitch {
            id: toggleswitchInvert
            x: 19
            width: 45
            height: 27
            anchors.top: textInvert.bottom
            onClicked: setInvert(enableState)
        }

        Text {
            id: textInvert
            color: "#ffffff"
            text: qsTr("Invert")
            anchors.top: rotarycontrolGain.bottom
            anchors.margins: 5
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignTop
            font.pointSize: 10
            anchors.horizontalCenter: toggleswitchInvert.horizontalCenter
        }

        ToggleSwitch {
            id: toggleswitchIntRef
            x: 19
            width: 45
            height: 27
            anchors.top: textIntRef.bottom
            onClicked: setIntRef(enableState)
        }

        Text {
            id: textIntRef
            color: "#ffffff"
            text: qsTr("Int Ref")
            horizontalAlignment: Text.AlignHCenter
            anchors.margins: 5
            verticalAlignment: Text.AlignTop
            anchors.top: toggleswitchInvert.bottom
            font.pointSize: 10
            anchors.horizontalCenter: toggleswitchIntRef.horizontalCenter
        }

        Text {
            id: textIntFreq
            x: 100
            color: "#ffffff"
            text: qsTr("Int Ref Freq (MHz)")
            anchors.top: rotarycontrolGain.bottom
            anchors.margins: 5
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pointSize: 10
            anchors.horizontalCenter: datainputIntFreq.horizontalCenter
        }

        DataInput {
            id: datainputIntFreq
            x: 87
            anchors.top: textIntFreq.bottom
            width: 170
            height: 35
            text: "0.000000"
            useInt: false
            pointSize: 19
            precision: 10
            maxVal: 250
            minVal: 50
            value: 100
            decimal: 6
            stepSize: 1.0
            onValueEntered: setIntFreq(newVal)
        }

        Text {
            id: textOffsetFreq
            x: 100
            color: "#ffffff"
            text: qsTr("Offset Freq (GHz)")
            anchors.top: datainputIntFreq.bottom
            anchors.margins: 5
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pointSize: 10
            anchors.horizontalCenter: readoutOffsetFreq.horizontalCenter
        }

        Readout {
            id: readoutOffsetFreq
            x: 87
            anchors.top: textOffsetFreq.bottom
            width: 170
            height: 25
            text: datainputIntFreq.value*rotarycontrolNDiv.getValue()/1000
            pointSize: 16
            decimal: 6
            textColor: "#ffffff"
        }

    }

    ToggleSwitch {
		id: graphPanelBtn
		width: 60
		anchors.top: textWidgetTitle.bottom
		anchors.margins: 0
		anchors.topMargin: 10
		anchors.leftMargin: 15
		anchors.left: rampRect.right
		text: "Graph"
		textOnState: "Graph"
		enableState: true
		radius: 0
		onClicked: {
		    rectAllEvents.visible = !enableState;
		    rectGraph.visible = enableState;
		    evtPanelBtn.enableSwitch(!enableState);
		    runRamp(global.rampState); // restore old state of ramp
		}
	}

	ToggleSwitch {
		id: evtPanelBtn
		width: 60
		anchors.top: textWidgetTitle.bottom
		anchors.margins: 0
		anchors.topMargin: 10
		anchors.bottomMargin: 0
		anchors.left: graphPanelBtn.right
		text: "Events"
		textOnState: "Events"
		enableState: false
		radius: 0
		onClicked: {
		    global.rampState = global.rampRun;
		    runRamp(false);
		    rectAllEvents.visible = enableState;
		    rectGraph.visible = !enableState;
		    graphPanelBtn.enableSwitch(!enableState);
		}
	}

    Rectangle {
        id: rectGraph
        anchors.top: graphPanelBtn.bottom
        anchors.left: rampRect.right
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 0
        anchors.margins: 10
        color: 'transparent'
        border.color: '#CCCCCC'
        radius: 5

        Text {
            id: textGraphNote
            color: "#ffff26"
            text: qsTr("Note: Servo locks to <i>negative</i> slope.")
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 5
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 9
            verticalAlignment: Text.AlignVCenter
        }

        GraphComponent {
            id: graphcomponent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.top: textGraphNote.bottom
            anchors.margins: 5
            gridYDiv: 10
            yMinimum: -5
            yMaximum: 5
            xMinimum: -128
            xMaximum: 128
            datasetFill: false
            axisYLabel: "Error Input"
            axisXLabel: "Ramp Voltage"
            autoScale: false
            vDivSetting: 6
        }
    }

    function getEvtLOff() {
        var result = ice.send('EvtLOff?', slot, null);
        return parseInt(result);
    }

    function getEvtJump() {
        var result = ice.send('EvtJump?', slot, null);
        return parseInt(result);
    }

    function getEvtNum() {
        var result = ice.send('EvtNum?', slot, null);
        return parseInt(result);
    }

    function getEvtJumpRow() {
        var result = ice.send('EvtJRow?', slot, null);
        var row = parseInt(result);

        setCurrentJumpRow(row);

        return row;
    }

    function setCurrentJumpRow(row) {
        for (var i = 0; i < global.evtNum; i++) {
            var rect = repeater.itemAt(i);
            var item = rect.children[0];
            rect.border.color = '#CCCCCC'
            item.color = '#FFFFFF';
            item.font.bold = false;
        }

        rect = repeater.itemAt(row - 1);
        item = repeater.itemAt(row - 1).children[0];
        rect.border.color = '#3399ff'
        item.color = '#3399ff';
        item.font.bold = true;
    }

    function getEvtLOffRow() {
        var result = ice.send('Laser?', slot, null);
        var row = 0;

        // Check if laser is on, else the next state we can go to is only ON
        if (result.toUpperCase() == 'ON') {
            result = ice.send('Readvolt 5', slot, null);
            var current = parseFloat(result);

            // If current is low, we're already in the fast off state
            if (current < 0.005) {
                row = 1;
            }
            else {
                row = 2;
            }
        }
        else {
            row = 1;
        }

        setCurrentLOffRow(row);
        return row;
    }

    function setCurrentLOffRow(row) {
        if (row === 1) {
            var rect1 = rectEvtLoffState2;
            var rect2 = rectEvtLoffState1;
        }
        else {
            var rect1 = rectEvtLoffState1;
            var rect2 = rectEvtLoffState2;
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

    function getEvtDataRow(row) {
        var result = ice.send('EvtData? ' + row + ' 0', slot, null);
        var mode = parseInt(result);
        result = ice.send('EvtData? ' + row + ' 1', slot, null);
        var freq = parseFloat(result);
        result = ice.send('EvtData? ' + row + ' 2', slot, null);
        var gain = parseFloat(result);

        return {mode: mode, intfreq: freq, fforward: gain};
    }

    function readEvtData() {
        var evtNum = 0;

        global.evtLOffAddr = getEvtLOff();
        laserAddrTextField.setValue(global.evtLOffAddr);
        global.evtJumpAddr = getEvtJump();
        jumpAddrTextField.setValue(global.evtJumpAddr);
        global.evtNum = getEvtNum();
        numEventsTextField.setValue(global.evtNum);

        repeater.model = global.evtNum;
        getEvtJumpRow();

        for (var i = 0; i < global.evtNum; i++) {
            var rowData = getEvtDataRow(i+1);
            repeater.itemAt(i).children[1].text = rowData.mode;
            repeater.itemAt(i).children[2].text = rowData.intfreq.toFixed(6);
            repeater.itemAt(i).children[3].text = rowData.fforward.toFixed(3);
            repeater.itemAt(i).children[3].color = (rowData.fforward < (2.4 - global.rampCenter) && rowData.fforward > (-2.4 - global.rampCenter)) ? '#FFFFFF' : '#ff0000';
        }
    }

    function pushEvtData() {
        var step, mode, intfreq, fforward;

        for (var i = 0; i < global.evtNum; i++) {
            step = repeater.itemAt(i).children[0].text;
            mode = repeater.itemAt(i).children[1].text;
            intfreq = repeater.itemAt(i).children[2].text;
            fforward = repeater.itemAt(i).children[3].text;
            var command = 'EvtData ' + step + ' ';
            ice.send(command + '0 ' + mode, slot, null);
            ice.send(command + '1 ' + intfreq, slot, null);
            ice.send(command + '2 ' + fforward, slot, null);
        }
    }

    Rectangle {
        id: rectAllEvents
        anchors.top: graphPanelBtn.bottom
        anchors.left: rampRect.right
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 0
        anchors.margins: 10
        color: 'transparent'
        border.color: '#CCCCCC'
        radius: 5
        visible: false
        onVisibleChanged: {
            if (visible) {
                readEvtData();
                getEvtLOffRow();
            }
        }

        Rectangle {
            id: rectJumpEvents
            anchors.top: parent.top
            anchors.left: rectLOffEvents.right
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 5
            color: "#505050"
            radius: 5

            Text {
                id: eventJumpTitle
                color: "#cccccc"
                text: "Offset Freq Events"
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.top: parent.top
                anchors.topMargin: 7
                styleColor: "#ffffff"
                font.bold: true
                font.pointSize: 10
            }

            Column {
                id: controls
                anchors.left: parent.left
                anchors.top: eventJumpTitle.bottom
                anchors.margins: 10
                spacing: 5
                width: 60

                Text {
                    text: '# States:'
                    color: "#ffffff"
                    font.pointSize: 10
                }

                DataInput {
                    id: numEventsTextField
                    width: 40
                    useInt: true
                    pointSize: 12
                    maxVal: 16
                    minVal: 1
                    value: 1
                    decimal: 0
                    stepSize: 1
                    onValueEntered: {
                        global.evtNum = newVal;
                        repeater.model = global.evtNum;
                        ice.send('EvtNum ' + global.evtNum, slot, null);
                        readEvtData();
                    }
                }

                Text {
                    text: 'Address:'
                    color: "#ffffff"
                    font.pointSize: 10
                }

                DataInput {
                    id: jumpAddrTextField
                    width: 40
                    useInt: true
                    pointSize: 12
                    maxVal: 7
                    minVal: 0
                    value: 0
                    decimal: 0
                    stepSize: 1
                    onValueEntered: {
                        global.evtJumpAddr = newVal;
                        ice.send('EvtJump ' + global.evtJumpAddr, slot, null);
                    }
                }

                ThemeButton {
                    id: trigBtn
                    y: 7
                    width: 50
                    height: 30
                    text: "Trig"
                    highlight: false
                    onClicked: {
                        ice.send('#DoEvent ' + global.evtJumpAddr, slot, null);
                        getEvtJumpRow();
                        getNDiv();
                        getIntFreq();
                        getIntRef();
                    }
                    enabled: true
                }

                ThemeButton {
                    id: saveJmpBtn
                    y: 7
                    width: 50
                    height: 30
                    text: "Save"
                    highlight: false
                    onClicked: {
                        pushEvtData();
                    }
                    enabled: true
                }

                ThemeButton {
                    id: resetBtn
                    y: 7
                    width: 50
                    height: 30
                    text: "Reset"
                    highlight: false
                    onClicked: {
                        ice.send('EvtNum ' + global.evtNum, slot, null);
                        getEvtJumpRow();
                    }
                    enabled: true
                }

            }

            Column {
                id: column1
                anchors.left: controls.right
                anchors.right: parent.left
                anchors.top: eventJumpTitle.bottom
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
                        text: "Mode"
                        color: "#cccccc"
                    }

                    Text {
                        x: 80
                        anchors.top: parent.top
                        text: "Int. Freq. (MHz)"
                        color: "#cccccc"
                    }

                    Text {
                        x: 180
                        anchors.top: parent.top
                        text: "F. Fwd (V)"
                        color: "#cccccc"
                    }
                }

                Repeater {
                    id: repeater
                    model: 16

                    Rectangle {
                        width: 240
                        height: 20
                        color: "#202020"
                        border.color: '#cccccc'
                        border.width: 1;
                        radius: 5

                        Text {
                            x: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: (index + 1).toString()
                            color: "#cccccc"
                        }

                        TextInput {
                            x: 40
                            text: '0'
                            anchors.verticalCenter: parent.verticalCenter
                            width: 30
                            color: (acceptableInput) ? '#FFFFFF' : '#ff0000'
                            validator: IntValidator{bottom: 0; top: 15}
                            selectByMouse: true
                            selectionColor: '#3399ff'
                            onFocusChanged: {
                                if (this.focus === true) {
                                    this.selectAll();
                                }
                            }
                        }

                        TextInput {
                            x: 80
                            text: '100.000000'
                            anchors.verticalCenter: parent.verticalCenter
                            width: 50
                            color: (acceptableInput) ? '#FFFFFF' : '#ff0000'
                            validator: DoubleValidator{decimals: 6; bottom: 50.0; top: 250.0}
                            maximumLength: 10
                            selectByMouse: true
                            selectionColor: '#3399ff'
                            onFocusChanged: {
                                if (this.focus === true) {
                                    this.selectAll();
                                }
                            }
                        }

                        TextInput {
                            x: 180
                            text: '0'
                            anchors.verticalCenter: parent.verticalCenter
                            width: 50
                            color: (acceptableInput &&  parseFloat(this.text) < (2.4 - global.rampCenter) &&  parseFloat(this.text) > (-2.4 - global.rampCenter)) ? '#FFFFFF' : '#ff0000'
                            validator: DoubleValidator{decimals: 3; bottom: -2.4; top: 2.4}
                            maximumLength: 7
                            selectByMouse: true
                            selectionColor: '#3399ff'
                            onFocusChanged: {
                                if (this.focus === true) {
                                    this.selectAll();
                                }
                            }
                        }
                    }
                }

            }
	    }

	    Rectangle {
            id: rectLOffEvents
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 5
            width: 100
            color: "#505050"
            radius: 5

            Text {
                id: eventLOffTitle
                color: "#cccccc"
                text: "Laser Pulse\nEvents"
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.top: parent.top
                anchors.topMargin: 7
                styleColor: "#ffffff"
                font.bold: true
                font.pointSize: 10
            }

            Column {
                id: controlsLOff
                anchors.left: parent.left
                anchors.top: eventLOffTitle.bottom
                anchors.margins: 10
                spacing: 5
                width: 60

                Text {
                    text: 'Address:'
                    color: "#ffffff"
                    font.pointSize: 10
                }

                DataInput {
                    id: laserAddrTextField
                    width: 40
                    useInt: true
                    pointSize: 12
                    maxVal: 7
                    minVal: 0
                    value: 0
                    decimal: 0
                    stepSize: 1
                    onValueEntered: {
                        global.evtLOffAddr = newVal;
                        ice.send('EvtLOff ' + global.evtLOffAddr, slot, null);
                    }
                }

                ThemeButton {
                    id: trigLOffBtn
                    y: 7
                    width: 50
                    height: 30
                    text: "Trig"
                    highlight: false
                    onClicked: {
                        ice.send('#DoEvent ' + global.evtLOffAddr, slot, null);
                        getEvtLOffRow();
                    }
                    enabled: true
                }

                Column {
                    id: columnLOff
                    anchors.left: parent.left
                    spacing: 5

                    Rectangle {
                        width: parent.width
                        height: 10
                        color: 'transparent'

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
                        id: rectEvtLoffState1
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
                        id: rectEvtLoffState2
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
}
