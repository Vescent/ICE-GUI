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
    property string widgetTitle: "Peak Lock Servo and Current Controller"
    property int slot: 1
    property bool active: false
    property int updateRate: 500
    property bool alternate: false
    property int dataWidth: 256
    property real maxCurrent: 200
    property var global: ({
                              numDataPoints: 128,
                              dataChn: 3,
                              rampOn: false,
                              servoOn: false,
							  blockChunkSize: 8,
							  rampCenter: 0,
							  rampSwp: 10
                          })

    signal error(string msg)

    onActiveChanged: {
        if (active) {
            ice.send('#pauselcd f', slot, null);

            getLaser();
            getCurrent();
            getCurrentLimit();

            getRampSweep();
            setRampNum(widget.dataWidth);

            getServo();
            getPhase();
            getDitherAmplitude();
            getDCOffset();
            getServoOffset();
            getGain();
            getOpAmpOffset();
            getDataChannel();
            intervalTimer.start();
            setGraphLabels();
            getFeatureID();

            if (typeof(appWindow.widgetState[slot].vDivSetting1) === 'number') {
                graphcomponent.vDivSetting = appWindow.widgetState[slot].vDivSetting1;
            }

            if (typeof(appWindow.widgetState[slot].vDivSetting2) === 'number') {
                graphcomponent2.vDivSetting = appWindow.widgetState[slot].vDivSetting2;
            }

            if (typeof(appWindow.widgetState[slot].yOffset) === 'number') {
                graphcomponent.yOffset = appWindow.widgetState[slot].yOffset;
            }

            if (typeof(appWindow.widgetState[slot].numDataPoints) === 'number') {
                global.numDataPoints = appWindow.widgetState[slot].numDataPoints;
                datainputRampNum.text = global.numDataPoints.toString();
                setRampNum(global.numDataPoints);

            }

			/*
            if (typeof(appWindow.widgetState[slot].rampOn) === 'boolean') {
                global.rampOn = appWindow.widgetState[slot].rampOn;

                if (global.rampOn) {
                    setServo(false);
                }

                runRamp(global.rampOn)
                //console.log('Ramp: ' + global.rampOn);
            }

            if (typeof(appWindow.widgetState[slot].servoOn) === 'boolean') {
                global.servoOn = appWindow.widgetState[slot].servoOn;
                if (global.servoOn) {
                    runRamp(false);
                }
                setServo(global.servoOn);
                //console.log('Servo: ' + global.rampOn);
            }
			*/

            graphcomponent.refresh();
            graphcomponent2.refresh();
        }
        else {
            intervalTimer.stop();
            runRamp(false);

            appWindow.widgetState[slot].vDivSetting1 = graphcomponent.vDivSetting;
            appWindow.widgetState[slot].vDivSetting2 = graphcomponent2.vDivSetting;
            appWindow.widgetState[slot].yOffset = graphcomponent.yOffset;
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
                console.log("Error getting feature ID");
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
				console.log('Successfully saved settings.');
			}
			else {
				console.log('Error saving settings.');
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

        yDiv = (graphcomponent2.yMaximum - graphcomponent2.yMinimum)/graphcomponent2.gridYDiv;
        graphcomponent2.axisXLabel = "Ramp Voltage [" + xDiv + " V/Div]";
        //graphcomponent2.axisYLabel = "DC Error [" + yDiv + " V/Div]";
        graphcomponent2.refresh();
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

    // Peak Lock Servo Commands
    function setPhase(value) {
        ice.send('Phase ' + value, slot, function(result){
            rotarycontrolPhase.setValue(result);
            return;
        });
    }

    function getPhase() {
        ice.send('Phase?', slot, function(result){
            rotarycontrolPhase.setValue(result);
            return;
        });
    }

    function setDitherAmplitude(value) {
        ice.send('DitherA ' + value, slot, function(result){
            rotarycontrolDitherAmp.setValue(result);
            return;
        });
    }

    function getDitherAmplitude() {
        ice.send('DitherA?', slot, function(result){
            rotarycontrolDitherAmp.setValue(result);
            return;
        });
    }

    function setDither(value) {
        ice.send('Dither ' + value, slot, function(result){
            return;
        });
    }

    function getDither() {
        ice.send('Dither?', slot, function(result){
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

    function setDCOffset(value) {
        ice.send('DCOffst ' + value, slot, function(result){
            rotarycontrolDCOffset.setValue(result);
            return;
        });
    }

    function getDCOffset() {
        ice.send('DCOffst?', slot, function(result){
            rotarycontrolDCOffset.setValue(result);
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

    function setOpAmpOffset(value) {
        ice.send('OpOffst ' + value, slot, function(result){
            rotarycontrolOpOffset.setValue(result);
            return;
        });
    }

    function getOpAmpOffset() {
        ice.send('OpOffst?', slot, function(result){
            rotarycontrolOpOffset.setValue(result);
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

    function setDataChannel(value) {
        ice.send('DataChn ' + value, slot, function(result){
            datainputDataChn.setValue(result);
            global.dataChn = parseInt(result);
            getRampNum();
            return;
        });
    }

    function getDataChannel() {
        ice.send('DataChn?', slot, function(result){
            datainputDataChn.setValue(result);
            global.dataChn = parseInt(result);
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
        if (global.rampRun === true) {
            return;
        }
        
        // Read Error Input and plot
        ice.send('ReadVolt 4', slot, function(result){
            var value = parseFloat(result);
            var data = [];

            for (var i = 0; i < 20; i++) {
                data[i] = value;
            }

            graphcomponent.plotData(data, 0);
            return;
        });
        
        // Read DC Error and plot
        ice.send('ReadVolt 3', slot, function(result){
            var value = parseFloat(result);
            var data = [];

            for (var i = 0; i < 20; i++) {
                data[i] = value;
            }

            graphcomponent2.plotData(data, 0);
            return;
        });
    }

    function runRamp(enableState) {
        if (enableState) {
            global.rampRun = true;
            toggleswitchRamp.enableSwitch(true);
			setServo(false);
            
            ice.send('#pauselcd t', slot, function(result){});
            
            doRamp();
        }
        else {
            global.rampRun = false;
            toggleswitchRamp.enableSwitch(false);
			
            ice.send('#pauselcd f', slot, function(result){});
        }
    }

    function doRamp() {
        global.start = new Date();
		
		if (ice.logging == true) {
			console.log('Started: ' + global.start);
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

            setTimeout(getRampBlockData, 75);
        });
    }

    function getRampBlockData() {
        var steps = global.numDataPoints;

        // Double the data points to collect if we're recording two data variables
        if (global.dataChn === 3) {
            steps *= 2;
        }

        var blocks = Math.ceil(steps/4);
        global.bulk = new Date();

        readBlock(blocks, processBlockData);
    }

    function processBlockData(data) {
        if (ice.logging == true) {
			global.stop = new Date();
			var totalTime = global.stop - global.start;
			console.log('Total Time (s): ' + totalTime/1000);
			var bulkTime = global.bulkStop - global.bulk;
			console.log('- Bulk (s):  ' + bulkTime/1000);
			var setupTime = totalTime - bulkTime;
			console.log('- Setup (s): ' + setupTime/1000);
		}

        // De-interlace the data if we're recording two data variables.
        if (global.dataChn === 3) {
            var dataDCErr = [];
            var dataErrInput = [];

            // Trim excess data
            data.splice(global.numDataPoints, (data.length - global.numDataPoints*2));

            for (var i = 0; i < data.length; i++) {
                if ((i % 2) > 0) {
                    // Odd
                    dataErrInput.push(data[i]);
                }
                else {
                    // Even
                    dataDCErr.push(data[i]);
                }
            }

            graphcomponent.plotData(dataErrInput, 0);
            graphcomponent2.plotData(dataDCErr, 0);

            if (ice.logging == true) {
				console.log('Data Points: ' + data.length + '/' + global.numDataPoints*2);
			}
        }
        else {
            // Trim excess data
            data.splice(global.numDataPoints, (data.length - global.numDataPoints));

            graphcomponent.plotData(data, 0);
            graphcomponent2.clearData();

            if (ice.logging == true) {
				console.log('Data Points: ' + data.length + '/' + global.numDataPoints);
			}
        }

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

    // Auto sets ramp increment value to get specified number of data points
    function rampAutoSet() {
        var increment = (global.rampEnd - global.rampBeg)/dataWidth;

        setRampInc(increment);
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
        x: 9
        y: 32
        width: 275
        height: 153
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
            onClicked: {
                if (enableState) {
                    setServo(false);
                }
                
                runRamp(enableState)
            }
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
            x: 64
            y: 98
            width: 32
            height: 16
            color: "#ffffff"
            text: qsTr("Datapoints")
            anchors.horizontalCenterOffset: -52
            anchors.horizontalCenter: datainputRampNum.horizontalCenter
            horizontalAlignment: Text.AlignRight
            font.pointSize: 10
            verticalAlignment: Text.AlignVCenter
        }

        DataInput {
            id: datainputRampNum
            x: 208
            y: 96
            width: 59
            height: 20
            radius: 5
            text: "256"
            precision: 5
            useInt: true
            maxVal: 1536
            minVal: 1
            decimal: 0
            pointSize: 12
            onValueEntered: setRampNum(newVal)
        }

        Text {
            id: textDataChn
            x: 164
            y: 127
            width: 38
            height: 16
            color: "#ffffff"
            text: qsTr("Channel")
            horizontalAlignment: Text.AlignRight
            font.pointSize: 10
            verticalAlignment: Text.AlignVCenter
        }

        DataInput {
            id: datainputDataChn
            x: 208
            y: 125
            width: 59
            height: 20
            radius: 5
            text: "1"
            precision: 5
            useInt: true
            maxVal: 3
            minVal: 1
            decimal: 0
            pointSize: 12
            onValueEntered: setDataChannel(newVal)
        }

        RotaryControl {
            id: rotarycontrolCenter
            x: 178
            y: 21
            width: 76
            height: 70
            useCursor: true
            maxValue: 9.9
            minValue: -9.9
            value: 0
            stepSize: 0.01
            decimalPlaces: 2
            anchors.verticalCenterOffset: -21
            anchors.horizontalCenterOffset: 78
            onNewValue: {
                setServoOffset(value);
                getRampSweep();
            }
        }

        RotaryControl {
            id: rotarycontrolRange
            x: 85
            y: 21
            width: 76
            height: 70
            value: 10
            stepSize: 0.1
            maxValue: 20.0
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
        x: 10
        y: 191
        width: 273
        height: 321
        color: "#00000000"
        radius: 7
        border.color: "#cccccc"

        Text {
            id: textCurrentLimit
            x: 128
            y: 70
            color: "#ffffff"
            text: qsTr("Current Limit")
            anchors.horizontalCenter: datainputCurrentLimit.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 10
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            id: textCurrentSet
            x: 27
            y: 5
            color: "#ffffff"
            text: qsTr("Laser Current")
            anchors.bottom: rotarycontrolCurrent.top
            anchors.bottomMargin: 3
            anchors.horizontalCenterOffset: 0
            anchors.horizontalCenter: rotarycontrolCurrent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 10
            verticalAlignment: Text.AlignVCenter
        }

        DataInput {
            id: datainputCurrentLimit
            x: 143
            y: 88
            width: 106
            height: 35
            text: "0.0"
            precision: 5
            useInt: false
            maxVal: maxCurrent
            minVal: 0
            decimal: 1
            pointSize: 19
            onValueEntered: setCurrentLimit(newVal)
        }

        RotaryControl {
            id: rotarycontrolCurrent
            x: 11
            y: 23
            width: 100
            height: 100
            colorInner: "#ff7300"
            anchors.verticalCenterOffset: -88
            anchors.horizontalCenterOffset: -76
            anchors.horizontalCenter: parent.horizontalCenter
            displayTextRatio: 0.2
            decimalPlaces: 2
            useArc: true
            showRange: true
            value: 0
            stepSize: .2
            minValue: 0
            maxValue: maxCurrent
            onNewValue: {
                setCurrent(value);
            }
        }

        Text {
            id: textLaserBtn
            x: 147
            y: 11
            color: "#ffffff"
            text: qsTr("Laser")
            anchors.horizontalCenter: toggleswitchLaser.horizontalCenter
            font.pointSize: 12
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        ToggleSwitch {
            id: toggleswitchLaser
            x: 128
            y: 32
            width: 56
            height: 32
            pointSize: 12
            onClicked: setLaser(enableState)
        }

        Text {
            id: textServoBtn
            x: 13
            y: 8
            color: "#ffffff"
            text: qsTr("Servo")
            anchors.bottom: toggleswitchServo.top
            anchors.bottomMargin: 3
            anchors.horizontalCenter: toggleswitchServo.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 12
            verticalAlignment: Text.AlignVCenter
        }

        ToggleSwitch {
            id: toggleswitchServo
            x: 200
            y: 32
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
                
                //setServo(enableState);
            }
        }

        Text {
            id: textPhase
            x: 258
            y: 1
            color: "#ffffff"
            text: qsTr("Phase")
            anchors.bottom: rotarycontrolPhase.top
            anchors.bottomMargin: 2
            anchors.horizontalCenterOffset: 0
            anchors.horizontalCenter: rotarycontrolPhase.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 10
            verticalAlignment: Text.AlignVCenter
        }

        RotaryControl {
            id: rotarycontrolPhase
            x: 16
            y: 243
            width: 70
            height: 70
            anchors.verticalCenterOffset: 117
            anchors.horizontalCenterOffset: -86
            anchors.horizontalCenter: parent.horizontalCenter
            displayTextRatio: 0.2
            decimalPlaces: 2
            useArc: true
            useCursor: true
            showRange: false
            value: 0
            stepSize: 11.25
            minValue: -12.0
            maxValue: 360.1
            onNewValue: setPhase(value)
        }

        Text {
            id: textDitherAmp
            x: 258
            y: 1
            color: "#ffffff"
            text: qsTr("Dither Amp")
            anchors.bottom: rotarycontrolDitherAmp.top
            anchors.bottomMargin: 2
            anchors.horizontalCenterOffset: 0
            anchors.horizontalCenter: rotarycontrolDitherAmp.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 10
            verticalAlignment: Text.AlignVCenter
        }

        RotaryControl {
            id: rotarycontrolDitherAmp
            x: 101
            y: 243
            width: 70
            height: 70
            anchors.verticalCenterOffset: 117
            anchors.horizontalCenterOffset: -1
            displayTextRatio: 0.25
            decimalPlaces: 0
            useArc: true
            useCursor: false
            showRange: false
            value: 0
            stepSize: 1
            minValue: 0
            maxValue: 63
            onNewValue: setDitherAmplitude(value)
        }

        Text {
            id: textDCOffset
            x: 258
            y: 1
            color: "#ffffff"
            text: qsTr("DC Offset")
            anchors.bottom: rotarycontrolDCOffset.top
            anchors.bottomMargin: 2
            anchors.horizontalCenterOffset: 0
            anchors.horizontalCenter: rotarycontrolDCOffset.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 10
            verticalAlignment: Text.AlignVCenter
        }

        RotaryControl {
            id: rotarycontrolDCOffset
            x: 184
            y: 149
            width: 70
            height: 70
            anchors.verticalCenterOffset: 23
            anchors.horizontalCenterOffset: 82
            displayTextRatio: 0.25
            decimalPlaces: 3
            useArc: true
            useCursor: true
            showRange: false
            value: 0
            stepSize: 0.001
            minValue: -0.22
            maxValue: 0.22
            onNewValue: setDCOffset(value)
        }

        Text {
            id: textServoOffset
            x: 258
            y: 1
            color: "#ffffff"
            text: qsTr("Servo Offset")
            anchors.bottom: rotarycontrolServoOffset.top
            anchors.bottomMargin: 2
            anchors.horizontalCenterOffset: 0
            anchors.horizontalCenter: rotarycontrolServoOffset.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 10
            verticalAlignment: Text.AlignVCenter
        }

        RotaryControl {
            id: rotarycontrolServoOffset
            x: 101
            y: 149
            width: 70
            height: 70
            anchors.verticalCenterOffset: 23
            anchors.horizontalCenterOffset: -1
            displayTextRatio: 0.25
            decimalPlaces: 2
            useArc: true
            useCursor: true
            showRange: false
            value: 0
            stepSize: 0.05
            minValue: -10
            maxValue: 10
            onNewValue: setServoOffset(value)
        }

        Text {
            id: textOpOffset
            x: 89
            y: 122
            color: "#ffffff"
            text: qsTr("Op Offset")
            anchors.bottom: rotarycontrolOpOffset.top
            anchors.bottomMargin: 2
            anchors.horizontalCenterOffset: 0
            anchors.horizontalCenter: rotarycontrolOpOffset.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 10
            verticalAlignment: Text.AlignVCenter
        }

        RotaryControl {
            id: rotarycontrolOpOffset
            x: 184
            y: 243
            width: 70
            height: 70
            anchors.verticalCenterOffset: 117
            anchors.horizontalCenterOffset: 82
            displayTextRatio: 0.3
            decimalPlaces: 0
            useArc: true
            useCursor: true
            showRange: false
            value: 128
            stepSize: 1
            minValue: 0
            maxValue: 255
            onNewValue: setOpAmpOffset(value)
        }

        Text {
            id: textGain
            x: 274
            y: 87
            color: "#ffffff"
            text: qsTr("Gain")
            anchors.bottom: rotarycontrolGain.top
            anchors.bottomMargin: 2
            anchors.horizontalCenterOffset: 0
            anchors.horizontalCenter: rotarycontrolGain.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 10
            verticalAlignment: Text.AlignVCenter
        }

        RotaryControl {
            id: rotarycontrolGain
            x: 16
            y: 149
            width: 70
            height: 70
            anchors.verticalCenterOffset: 23
            anchors.horizontalCenterOffset: -86
            displayTextRatio: 0.3
            decimalPlaces: 0
            useArc: true
            showRange: false
            value: 0
            stepSize: 1
            minValue: 0
            maxValue: 28
            onNewValue: setGain(value)
        }

    }

    GraphComponent {
        id: graphcomponent
        x: 289
        y: 32
        width: 443
        height: 235
        yOffset: -0.6
        yMinimum: -0.8
        yMaximum: 0.8
        xMinimum: -128
        xMaximum: 128
        datasetFill: false
        axisYLabel: "Error Input"
        axisXLabel: "Ramp Voltage"
        autoScale: false
        vDivSetting: 5
        adjustableYOffset: true
    }

    GraphComponent {
        id: graphcomponent2
        x: 289
        y: 273
        width: 443
        height: 239
        yMinimum: -0.2
        yMaximum: 0.2
        xMinimum: -128
        xMaximum: 128
        datasetFill: false
        axisYLabel: "DC Error"
        axisXLabel: "Ramp Voltage"
        autoScale: false
        vDivSetting: 4
    }

}
