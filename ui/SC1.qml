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
    property string widgetTitle: "ICE-SC1: Servo"
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
							  rampSwp: 10,
                              this_slot_loaded: false
                          })

    signal error(string msg)

    onActiveChanged: {
        if (active) {
            ice.send('#pauselcd f', slot, null);

            getRampSweep();
            setRampNum(widget.dataWidth);

            get_pid_poles();
            getServo();
            getDCOffset();
            getServoOffset();
            getAuxOffset();
            getInvert();
            getGain();
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
                //python.log('Ramp: ' + global.rampOn);
            }

            if (typeof(appWindow.widgetState[slot].servoOn) === 'boolean') {
                global.servoOn = appWindow.widgetState[slot].servoOn;
                if (global.servoOn) {
                    runRamp(false);
                }
                setServo(global.servoOn);
                //python.log('Servo: ' + global.rampOn);
            }
			*/

			if (global.servoOn) {
                runRamp(false);
            }

            graphcomponent.refresh();
            graphcomponent2.refresh();

            global.this_slot_loaded = true
        }
        else{
            intervalTimer.stop();
            runRamp(false);

            appWindow.widgetState[slot].vDivSetting1 = graphcomponent.vDivSetting;
            appWindow.widgetState[slot].vDivSetting2 = graphcomponent2.vDivSetting;
            appWindow.widgetState[slot].yOffset = graphcomponent.yOffset;
            appWindow.widgetState[slot].numDataPoints = global.numDataPoints;
            appWindow.widgetState[slot].rampOn = global.rampOn;
            appWindow.widgetState[slot].servoOn = global.servoOn;

            global.this_slot_loaded = false
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

        yDiv = (graphcomponent2.yMaximum - graphcomponent2.yMinimum)/graphcomponent2.gridYDiv;
        graphcomponent2.axisXLabel = "Ramp Voltage [" + xDiv + " V/Div]";
        //graphcomponent2.axisYLabel = "DC Error [" + yDiv + " V/Div]";
        graphcomponent2.refresh();
	}

    function setInvert(value) {
        state = (value) ? 'On' : 'Off';
        ice.send('Invert ' + state, slot, function(result){
            if (result === 'On') {
                toggleswitchInvert.enableSwitch(true);
            }
            else if(result === 'Off'){
                toggleswitchInvert.enableSwitch(false);
            }
            else{
                //Error, don't change the state.
            }
            return;
        });
    }

    function getInvert() {
        ice.send('Invert?', slot, function(result){
            if (result === 'On') {
                toggleswitchInvert.enableSwitch(true);
            }
            else if(result === 'Off'){
                    toggleswitchInvert.enableSwitch(false);
                }
            else{
                //Error, don't change the state.
            }

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

    function setAuxOffset(value) {
        ice.send('AxOffst ' + value, slot, function(result){
            rotarycontrolAuxOffset.setValue(result);
            return;
        });
    }

    function getAuxOffset() {
        ice.send('AxOffst?', slot, function(result){
            rotarycontrolAuxOffset.setValue(result);
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
            rotarycontrolGainPIDPane.setValue(result);
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
            graphcomponent.addPoint(value, 0);
            return;
        });
        
        // Read DC Error and plot
        ice.send('ReadVolt 3', slot, function(result){
            var value = parseFloat(result);
            graphcomponent2.addPoint(value, 0);
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
			graphcomponent2.clearData();
			graphcomponent2.rollMode = false;
            
            ice.send('#pauselcd t', slot, function(result){});
            
            doRamp();
        }
        else {
            global.rampRun = false;
            toggleswitchRamp.enableSwitch(false);
            graphcomponent.rollMode = true;
            graphcomponent.clearData();
            graphcomponent2.rollMode = true;
            graphcomponent2.clearData();
			
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
			python.log('Total Time (s): ' + totalTime/1000);
			var bulkTime = global.bulkStop - global.bulk;
			python.log('- Bulk (s):  ' + bulkTime/1000);
			var setupTime = totalTime - bulkTime;
			python.log('- Setup (s): ' + setupTime/1000);
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
				python.log('Data Points: ' + data.length + '/' + global.numDataPoints*2);
			}
        }
        else {
            // Trim excess data
            data.splice(global.numDataPoints, (data.length - global.numDataPoints));

            graphcomponent.plotData(data, 0);
            graphcomponent2.clearData();

            if (ice.logging == true) {
				python.log('Data Points: ' + data.length + '/' + global.numDataPoints);
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
        anchors.top: textWidgetTitle.bottom
        anchors.left: parent.left
        anchors.margins: 10
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
            stepSize: 1
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
            stepSize: 1
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
        anchors.top: rampRect.bottom
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 10
        width: 275
        color: "#00000000"
        radius: 7
        border.color: "#cccccc"


        Text {
            id: textServoBtn
            x: 13
            y: 8
            color: "#ffffff"
            text: qsTr("Servo")
            anchors.top: parent.top
            anchors.topMargin: 5
            anchors.bottomMargin: 5
            anchors.horizontalCenter: toggleswitchServo.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 12
            verticalAlignment: Text.AlignVCenter
        }

        ToggleSwitch {
            id: toggleswitchServo
            anchors.top: textServoBtn.bottom
            anchors.horizontalCenter: parent.horizontalCenter
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
                
                //setServo(enableState);
            }
        }

        Text {
            id: textInvert
            color: "#ffffff"
            text: qsTr("Invert")
            anchors.top: parent.top
            anchors.topMargin: 5
            anchors.bottomMargin: 5
            anchors.horizontalCenter: toggleswitchInvert.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 12
            verticalAlignment: Text.AlignVCenter
        }

        ToggleSwitch {
            id: toggleswitchInvert
            x: 20
            width: 58
            height: 32
            anchors.margins: 5
            anchors.top: textInvert.bottom
            pointSize: 12
            onClicked: setInvert(enableState)
        }        

        Text {
            id: textAuxOffset
            x: 258
            y: 1
            color: "#ffffff"
            text: qsTr("Aux Offset")
            anchors.bottom: rotarycontrolAuxOffset.top
            anchors.bottomMargin: 2
            anchors.horizontalCenterOffset: 0
            anchors.horizontalCenter: rotarycontrolAuxOffset.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 10
            verticalAlignment: Text.AlignVCenter
        }

        RotaryControl {
            id: rotarycontrolAuxOffset
            x: 101
            y: 183
            width: 70
            height: 70
            anchors.verticalCenterOffset: 117
            anchors.horizontalCenterOffset: -1
            displayTextRatio: 0.25
            decimalPlaces: 2
            useArc: true
            useCursor: true
            showRange: false
            value: 0
            stepSize: 0.01
            minValue: -10.0
            maxValue: 10.0
            onNewValue: setAuxOffset(value)
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
            y: 89
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
            stepSize: 0.01
            minValue: -5.00
            maxValue: 5.00
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
            y: 89
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
            y: 89
            width: 70
            height: 70
            anchors.verticalCenterOffset: 23
            anchors.horizontalCenterOffset: -86
            displayTextRatio: 0.3
            decimalPlaces: 1
            useArc: true
            showRange: false
            value: 0
            stepSize: 1
            minValue: -28
            maxValue: 38
            onNewValue: setGain(value)
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
            if(enableState){

                rectGraph.visible = true;
                rectAllEvents.visible = false;
                rectPIDControls.visible = false;

                evtPanelBtn.enableSwitch(false);
                pidControlTabBtn.enableSwitch(false);

                runRamp(global.rampState); // restore old state of ramp    
            }
		    
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
            if(enableState){
    		    global.rampState = global.rampRun;
    		    runRamp(false);

    		    rectAllEvents.visible = true;
    		    rectGraph.visible = false;
                rectPIDControls.visible = false

    		    graphPanelBtn.enableSwitch(false);
                pidControlTabBtn.enableSwitch(false)
            }
		}
	}

    ToggleSwitch {
        id: pidControlTabBtn
        width: 70
        radius: 0
        anchors {
            top: textWidgetTitle.bottom
            margins: 0
            topMargin: 10
            bottomMargin: 0
            left: evtPanelBtn.right
        }
        text: "PID Poles"
        textOnState: "PID Poles"
        enableState: false
        onClicked: {
            if(enableState){
                global.rampState = global.rampRun
                runRamp(false)
                get_pid_poles()

                rectPIDControls.visible = true
                rectGraph.visible = false
                rectAllEvents.visible = false

                graphPanelBtn.enableSwitch(false)
                evtPanelBtn.enableSwitch(false)
            }
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

        GraphComponent {
            id: graphcomponent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 5
            height: 212
            yOffset: 0
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

        Text {
            id: textGraphNote
            color: "#ffff26"
            text: qsTr("Note: Servo locks to <i>positive</i> slope.")
            anchors.left: graphcomponent.left
            anchors.top: graphcomponent.bottom
            anchors.topMargin: 2
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 9
            verticalAlignment: Text.AlignVCenter
        }

        GraphComponent {
            id: graphcomponent2
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: textGraphNote.bottom
            anchors.margins: 5
            height: 212
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
                getEvtLOffRow();
            }
        }

        Text {
            id: eventLOffTitle
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
        }

        Column {
            id: columnLOff
            anchors.left: controlsLOff.right
            anchors.right: parent.left
            anchors.top: eventLOffTitle.bottom
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
                text: "Note: TTL Event\ninputs may override\nGUI trigger button."
                color: "#cccccc"
            }
        }
    }

    function get_i1_pole(){
        ice.send('I1POLE?', slot, function(result){
            var i1_pole = parseInt(result)
            pidPoleIntegralOneComboBox.currentIndex = i1_pole
            })
    }

    function set_i1_pole(){
        var i1_pole = pidPoleIntegralOneComboBox.currentIndex
        var cmd_str = "I1POLE " + i1_pole
        ice.send(cmd_str, slot, null)
    }

    function get_i2_pole(){
        ice.send('I2POLE?', slot, function(result){
            var i2_pole = parseInt(result)
            pidPoleIntegralTwoComboBox.currentIndex = i2_pole
            })
    }

    function set_i2_pole(){
        var i2_pole = pidPoleIntegralTwoComboBox.currentIndex
        var cmd_str = "I2POLE " + i2_pole
        ice.send(cmd_str, slot, null)
    }

    function get_d_pole(){
        ice.send('DPOLE?', slot, function(result){
            var d_pole = parseInt(result)
            pidPoleDerivativeComboBox.currentIndex = d_pole
            })
    }

    function set_d_pole(){
        var d_pole = pidPoleDerivativeComboBox.currentIndex
        var cmd_str = "DPOLE " + d_pole
        ice.send(cmd_str, slot, null)
    }

    function get_pid_poles(){
        get_i1_pole();
        get_i2_pole();
        get_d_pole();
    }

    function set_pid_poles(){
        set_i1_pole();
        set_i2_pole();
        set_d_pole();
        get_pid_poles();
    }

    Rectangle {
        id: rectPIDControls
        anchors.top: graphPanelBtn.bottom
        anchors.left: rampRect.right
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 0
        anchors.margins: 10
        visible: false
        color: 'transparent'
        border.color: '#CCCCCC'
        radius: 5

        Image {
            id: pidTransferFunctionImage
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: 10
            }
            source: ".\\resources\\pid_transfer_function_SC1.png"
        }

        Row {
            spacing: 5

            anchors {
                top: pidTransferFunctionImage.bottom
                left: parent.left
                right: parent.right
                margins: 10
            }
            Column {
                y: 5                
                spacing: 10

                Text {
                    text: "f_I1"
                    color: "#cccccc"
                    font.pointSize: 10
                }

                Text {
                    text: "f_I2"
                    color: "#cccccc"
                    font.pointSize: 10
                }

                Text {
                    text: "f_D"
                    color: "#cccccc"
                    font.pointSize: 10

                }
                

            }

            Column {                
                spacing: 5

                ComboBox {
                    id: pidPoleIntegralOneComboBox
                    model: ListModel {
                        ListElement { text: "Off" }  //passed_int_pole = 0
                        ListElement { text: "10 Hz" }
                        ListElement { text: "20 Hz" }
                        ListElement { text: "50 Hz" }
                        ListElement { text: "100 Hz" }
                        ListElement { text: "200 Hz" }  
                        ListElement { text: "500 Hz" }  
                        ListElement { text: "1 kHz" }
                        ListElement { text: "2 kHz" }
                        ListElement { text: "5 kHz" }
                        ListElement { text: "10 kHz" }
                        ListElement { text: "20 kHz" }
                        ListElement { text: "50 kHz" }
                        ListElement { text: "100 kHz" }
                        ListElement { text: "200 kHz" }
                    }
                    onCurrentIndexChanged: {
                        if(global.this_slot_loaded === true){
                            set_pid_poles()
                        }
                    }
                }

                ComboBox {
                    id: pidPoleIntegralTwoComboBox
                    model: ListModel {
                        ListElement { text: "Off" }  //passed_int_pole = 0
                        ListElement { text: "100 Hz" }
                        ListElement { text: "200 Hz" }  
                        ListElement { text: "500 Hz" }  
                        ListElement { text: "1 kHz" }
                        ListElement { text: "2 kHz" }
                        ListElement { text: "5 kHz" }
                        ListElement { text: "10 kHz" }
                        ListElement { text: "20 kHz" }
                        ListElement { text: "50 kHz" }
                        ListElement { text: "100 kHz" }
                        ListElement { text: "200 kHz" }
                        ListElement { text: "500 kHz" }
                        ListElement { text: "1 MHz" }
                        ListElement { text: "2 MHz" }
                    }
                    onCurrentIndexChanged: {
                        if(global.this_slot_loaded === true){
                            set_pid_poles()
                        }
                    }
                }

                ComboBox {
                    id: pidPoleDerivativeComboBox
                    model: ListModel {
                        ListElement { text: "Off" }  //passed_diff_pole = 0
                        ListElement { text: "500 Hz" }  
                        ListElement { text: "1 kHz" }
                        ListElement { text: "2 kHz" }
                        ListElement { text: "5 kHz" }
                        ListElement { text: "10 kHz" }
                        ListElement { text: "20 kHz" }
                        ListElement { text: "50 kHz" }
                        ListElement { text: "100 kHz" }
                        ListElement { text: "200 kHz" }
                        ListElement { text: "500 kHz" }
                        ListElement { text: "1 MHz" }
                        ListElement { text: "2 MHz" }
                        ListElement { text: "5 MHz" }
                        ListElement { text: "10 MHz" }
                    }
                    onCurrentIndexChanged: {
                        if(global.this_slot_loaded === true){
                            set_pid_poles()
                        }
                    }
                }

            }

            Column {
                spacing: 5

                Text {
                    text: "Proportional Gain"
                    color: "#cccccc"
                    font.pointSize: 10

                }

                RotaryControl {
                    id: rotarycontrolGainPIDPane
                    x: 16
                    width: 70
                    height: 70
                    displayTextRatio: 0.3
                    decimalPlaces: 1
                    useArc: true
                    showRange: false
                    value: 1
                    stepSize: 1
                    minValue: -28
                    maxValue: 38
                    onNewValue: setGain(value)
                }
            }
        }
    }
}
