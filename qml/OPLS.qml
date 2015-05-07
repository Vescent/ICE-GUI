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
    property string widgetTitle: 'OPLS and Current Controller'
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
        }
        else {
            intervalTimer.stop();
            runRamp(false);
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
            }
            else {
                toggleswitchServo.enableSwitch(false);
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
            var data = [];

            for (var i = 0; i < 20; i++) {
                data[i] = value;
            }

            graphcomponent.plotData(data, 0);
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
        console.log('Started: ' + global.start);
		
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
        var totalTime = global.stop - global.start;
        console.log('Total Time (s): ' + totalTime/1000);
        var bulkTime = global.bulkStop - global.bulk;
        console.log('- Bulk (s):  ' + bulkTime/1000);
        var setupTime = totalTime - bulkTime;
        console.log('- Setup (s): ' + setupTime/1000);

        // Trim excess data
        data.splice(global.numDataPoints, (data.length - global.numDataPoints));

        if (data.length === global.numDataPoints) {
            graphcomponent.plotData(data, 0);
        }

        console.log('Data Points: ' + data.length + '/' + global.numDataPoints);

        //console.log('Data: ' + dataErrInput);

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
            text: qsTr("Current Limit (mA)")
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
            text: qsTr("Laser Current (mA)")
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
            stepSize: 1
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
            anchors.bottom: toggleswitchLaser.top
            anchors.bottomMargin: 2
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
                }
                else {
                    runRamp(global.rampState); // restore old state of ramp
                }

                setServo(enableState);
            }
        }

        Text {
            id: textNDiv
            x: 196
            y: 131
            color: "#ffffff"
            text: qsTr("N Div")
            anchors.bottom: rotarycontrolNDiv.top
            anchors.bottomMargin: 2
            anchors.horizontalCenterOffset: 1
            anchors.horizontalCenter: rotarycontrolNDiv.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 10
            verticalAlignment: Text.AlignVCenter
        }

        StepControl {
            id: rotarycontrolNDiv
            x: 188
            y: 149
            width: 70
            height: 70
            anchors.verticalCenterOffset: 23
            anchors.horizontalCenterOffset: 84
            anchors.horizontalCenter: parent.horizontalCenter
            displayTextRatio: 0.2
            decimalPlaces: 0
            maxValue: 3
            stepValues: [8,16,32,64]
            onNewValue: setNDiv(value)
            //onNewValue: console.log(value)
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
            minValue: -2.4
            maxValue: 2.4
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
            y: 149
            width: 70
            height: 70
            anchors.verticalCenterOffset: 23
            anchors.horizontalCenterOffset: -86
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
            y: 239
            width: 45
            height: 27
            onClicked: setInvert(enableState)
        }

        Text {
            id: textInvert
            x: 29
            y: 225
            color: "#ffffff"
            text: qsTr("Invert")
            anchors.bottom: toggleswitchInvert.top
            anchors.bottomMargin: 0
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignTop
            font.pointSize: 10
            anchors.horizontalCenterOffset: 1
            anchors.horizontalCenter: toggleswitchInvert.horizontalCenter
        }

        ToggleSwitch {
            id: toggleswitchIntRef
            x: 19
            y: 286
            width: 45
            height: 27
            onClicked: setIntRef(enableState)
        }

        Text {
            id: textIntRef
            x: 29
            y: 272
            color: "#ffffff"
            text: qsTr("Int Ref")
            horizontalAlignment: Text.AlignHCenter
            anchors.bottomMargin: 0
            verticalAlignment: Text.AlignTop
            anchors.bottom: toggleswitchIntRef.top
            font.pointSize: 10
            anchors.horizontalCenterOffset: 0
            anchors.horizontalCenter: toggleswitchIntRef.horizontalCenter
        }

        Text {
            id: textIntFreq
            x: 100
            y: 260
            color: "#ffffff"
            text: qsTr("Int Ref Freq (MHz)")
            anchors.bottom: datainputIntFreq.top
            anchors.bottomMargin: 2
            anchors.horizontalCenterOffset: 0
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pointSize: 10
            anchors.horizontalCenter: datainputIntFreq.horizontalCenter
        }

        DataInput {
            id: datainputIntFreq
            x: 87
            y: 251
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
            onValueEntered: setIntFreq(newVal)
        }

    }

    GraphComponent {
        id: graphcomponent
        x: 289
        y: 32
        width: 443
        height: 480
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
