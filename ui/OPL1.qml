import QtQuick 2.0
import QtQuick.Controls 1.4
import QtQml.Models 2.2
import QtQuick.Dialogs 1.2


Rectangle {
    id: widget
    width: 750
    height: 525
    color: "#333333"
    radius: 15
    border.width: 2
    border.color: (active) ? '#3399ff' : "#666666";
    property string widgetTitle: 'ICE-OPL1'
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
                              ddsqPlaylist: [],
                              ddsqProfiles: [],
                              pid_poles: {},
                              ddsq_event_addr: 1,
                              ddsq_active: false,
                              laser_slave_slot: 1
                          })
	property double intfreq: 100

    signal error(string msg)

    onActiveChanged: {
        if (active) {
            ice.send('#pauselcd f', slot, null);

            if (typeof(appWindow.widgetState[slot].laser_slave_slot) === 'number') {
                global.laser_slave_slot = appWindow.widgetState[slot].laser_slave_slot;
            }
            else{
                global.laser_slave_slot = 1
            }
            slaveSlotComboBox.currentIndex = global.laser_slave_slot - 1 //comboboxes are 0 indexed, but slaves are 1 indexed, so subtract one
                                                                         //to translate from slave index to cbox index.
            
            getLaserFromSlave();
            getCurrentFromSlave();
            getCurrentLimitFromSlave();

            getRampSweep();
            setRampNum(widget.dataWidth);

            getNDiv();
            getInvert();
            getIntRef();
            getIntFreq();
            getServo();
            getServoOffset();
            getGain();

            get_pid_poles();
            set_ddsq_event_addr(global.ddsq_event_addr)

            intervalTimer.start();
            setGraphLabels();
            getFeatureID();

            ddspllStatusCheckTimer.start();

            if (typeof(appWindow.widgetState[slot].vDivSetting) === 'number') {
                graphcomponent.vDivSetting = appWindow.widgetState[slot].vDivSetting;
            }

            if (typeof(appWindow.widgetState[slot].numDataPoints) === 'number') {
                global.numDataPoints = appWindow.widgetState[slot].numDataPoints;
            }

            //NOTE: MUST set profiles first!  The playlist depends on the profile already being defined
            //      before it can update the gui playlist.  Updating playlist before profile will break the system.
            if(typeof(appWindow.widgetState[slot].ddsqProfiles) === 'object'){
                global.ddsqProfiles = appWindow.widgetState[slot].ddsqProfiles
                setAvailableProfilesFromGlobalProfileList()
            }          

            if(typeof(appWindow.widgetState[slot].ddsqPlaylist) === 'object'){
                global.ddsqPlaylist = appWindow.widgetState[slot].ddsqPlaylist
                setGUIPlaylistFromGlobalPlaylist()
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

            ddsqUpdateGlobalPlaylistFromGUI()
            // No need to call function to update available profiles... global list is always up to date since add/delete definition
            // functions modify the global profile list.

            appWindow.widgetState[slot].ddsqProfiles = global.ddsqProfiles
            appWindow.widgetState[slot].ddsqPlaylist = global.ddsqPlaylist
            appWindow.widgetState[slot].laser_slave_slot = global.laser_slave_slot

            ddspllStatusCheckTimer.stop();
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

	function setGraphLabels() {
        var yDiv = (graphcomponent.yMaximum - graphcomponent.yMinimum)/graphcomponent.gridYDiv;
        var xDiv = global.rampSwp/graphcomponent.gridXDiv;
        xDiv = xDiv.toFixed(2);
        graphcomponent.axisXLabel = "Ramp Voltage [" + xDiv + " V/Div]";
        //graphcomponent.axisYLabel = "Error Input [" + yDiv + " V/Div]";
        graphcomponent.refresh();
	}

    function getCurrentSlaveInfo(){
        validateLaserSlave();
        getCurrentFromSlave();
        getCurrentLimitFromSlave();
        getLaserFromSlave();
    }

    function validateLaserSlave(){
        var valid_color = "#BBBBFF"
        var invalid_color = "#FF0000"
        ice.send("Laser?", global.laser_slave_slot, function(result){
            if(result === "Invalid Command"){
                slaveSlotLabel.color = invalid_color
                textLaserBtn.color = invalid_color
                textLaserBtn.text = "Invalid Slave"
            }
            else {
                slaveSlotLabel.color = valid_color
                textLaserBtn.color = valid_color 
                textLaserBtn.text = "Laser"
            }
        })

        ice.send("CurrSet?", global.laser_slave_slot, function(result){
            if(result === "Invalid Command"){
                slaveSlotLabel.color = invalid_color
                textCurrentSet.color = invalid_color
                textCurrentSet.text = "Invalid Slave"
            }
            else {
                slaveSlotLabel.color = valid_color
                textCurrentSet.color = valid_color 
                textCurrentSet.text = "Laser Current (mA)"
            }
        })

        ice.send("CurrLim?", global.laser_slave_slot, function(result){
            if(result === "Invalid Command"){
                slaveSlotLabel.color = invalid_color
                textCurrentLimit.color = invalid_color
                textCurrentLimit.text = "Invalid Slave"
            }
            else {
                slaveSlotLabel.color = valid_color
                textCurrentLimit.color = valid_color 
                textCurrentLimit.text = "Current Limit (mA)"
            }
        })
    }

    // Common Laser Controller Command Set
    function setLaserOnSlave(value) {
        state = (value) ? 'On' : 'Off';
        ice.send('Laser ' + state, global.laser_slave_slot, function(result){
            if (result === 'On') {
                toggleswitchLaser.enableSwitch(true);
            }
            else {
                toggleswitchLaser.enableSwitch(false);
            }
            return;
        });
    }

    function getLaserFromSlave() {
        ice.send('Laser?', global.laser_slave_slot, function(result){
            if (result === 'On') {
                toggleswitchLaser.enableSwitch(true);
            }
            else {
                toggleswitchLaser.enableSwitch(false);
            }
            return;
        });
    }

    function setCurrentOnSlave(value) {
        ice.send('CurrSet ' + value, global.laser_slave_slot, function(result){
            rotarycontrolCurrent.setValue(result);
            return;
        });
    }

    function getCurrentFromSlave() {
        ice.send('CurrSet?', global.laser_slave_slot, function(result){
            rotarycontrolCurrent.setValue(result);
            return;
        });
    }

    function setCurrentLimitOnSlave(value) {
        ice.send('CurrLim ' + value, global.laser_slave_slot, function(result){
            datainputCurrentLimit.setValue(result);
            rotarycontrolCurrent.maxValue = parseFloat(result);
            return;
        });
    }

    function getCurrentLimitFromSlave() {
        ice.send('CurrLim?', global.laser_slave_slot, function(result){
            datainputCurrentLimit.setValue(result);
            rotarycontrolCurrent.maxValue = parseFloat(result);
            return;
        });
    }

    // OPLS Commands
    function setNDiv(value) {
        if(global.ddsq_active == false){
            ice.send('N ' + value, slot, function(result){
                rotarycontrolNDiv.setValue(result);
                return;
            });
        }
    }

    function getNDiv() {
        ice.send('N?', slot, function(result){
            rotarycontrolNDiv.setValue(result);
            return;
        });
    }

    function setInvert(value) {
        if(global.ddsq_active == false){
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
        if(global.ddsq_active == false){
            ice.send('PFLFREQ 0 ' + value * 1000000, slot, function(result){ //multiply by 1000000 to convert from MHz to Hz
                datainputIntFreq.setValue(result / 1000000); //Convert from Hz to MHz
                readoutOffsetFreq.setValue(datainputIntFreq.value*rotarycontrolNDiv.getValue()/1000);
                return;
            });
        }
    }

    function getIntFreq() {
        ice.send('PFLF? 0', slot, function(result){
            var val = parseInt(result)
            datainputIntFreq.setValue(val / 1000000); //Convert from Hz to MHz
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
        if(global.ddsq_active == false){
            ice.send('SvOffst ' + value, slot, function(result){
                rotarycontrolServoOffset.setValue(result);
                rotarycontrolCenter.setValue(result);
                global.rampCenter = parseFloat(result);
                return;
            });
        }
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

    function update_DDS_PLL_LockIndicator(){
        ice.send('DDSPLL?', slot, function(result){
            var state = result
            if (state == "On"){
                ddspllLockIndicator.setState(true)
            }
            else if (state == "Off"){
                ddspllLockIndicator.setState(false)
            }
        });
    }

    function get_pid_poles(){
        ice.send('POLES?', slot, function(result){
            var poles = result.split(" ")
            var int_pole = parseInt(poles[0])
            var diff_pole = parseInt(poles[1])

            global.pid_poles["int"] = int_pole
            global.pid_poles["diff"] = diff_pole

            pidPoleIntegralComboBox.currentIndex = int_pole
            pidPoleDerivativeComboBox.currentIndex = diff_pole
        });
    }

    function set_pid_poles(){
        var int_pole = pidPoleIntegralComboBox.currentIndex
        var diff_pole = pidPoleDerivativeComboBox.currentIndex

        var cmd_str = "POLES " + int_pole + " " + diff_pole

        ice.send(cmd_str, slot, null)
        get_pid_poles()
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

    Timer {
        id: ddspllStatusCheckTimer
        interval: updateRate
        running: false
        repeat: true
        onTriggered: update_DDS_PLL_LockIndicator()
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
            maxValue: 10.0
            minValue: -10.0
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
            id: slaveSlotLabel
            color: "#BBBBFF"
            text: qsTr("Laser Slot: ")
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 5
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 10
            verticalAlignment: Text.AlignVCenter
        }

        ComboBox {
            id: slaveSlotComboBox
            anchors.top: parent.top
            anchors.left: slaveSlotLabel.right
            anchors.margins: 5
            width: 30
            model: ListModel {
                ListElement { text: "1" }
                ListElement { text: "2" }
                ListElement { text: "3" }
                ListElement { text: "4" }
                ListElement { text: "5" }
                ListElement { text: "6" }
                ListElement { text: "7" }
                ListElement { text: "8" }
            }
            onCurrentIndexChanged: {
                global.laser_slave_slot = currentIndex + 1
                getCurrentSlaveInfo()
            }
        }

        Text {
            id: textCurrentSet
            color: "#BBBBFF"
            text: qsTr("Laser Current (mA)")
            y:30
            // anchors.top: parent.top
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
            width: 70
            height: 70
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
                setCurrentOnSlave(value);
            }
        }

        Text {
            id: textLaserBtn
            color: "#BBBBFF"
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
            onClicked: setLaserOnSlave(enableState)
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
            color: "#BBBBFF"
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
            onValueEntered: setCurrentLimitOnSlave(newVal)
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
            minValue: -10.0
            maxValue: 10.0
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
            text: "100.000000"
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
		anchors.top: textWidgetTitle.top
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
                runRamp(global.rampState); // restore old state of ramp

    		    rectGraph.visible = true;
                rectDDSQueue.visible = false;
                rectPIDControls.visible = false

                ddsqPanelBtn.enableSwitch(false);
                pidControlTabBtn.enableSwitch(false)
            }
		}
	}

    ToggleSwitch {
        id: pidControlTabBtn
        width: 70
        radius: 0
        anchors {
            top: textWidgetTitle.top
            margins: 0
            topMargin: 10
            bottomMargin: 0
            left: graphPanelBtn.right
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
                rectDDSQueue.visible = false
                rectGraph.visible = false

                graphPanelBtn.enableSwitch(false)
                ddsqPanelBtn.enableSwitch(false)
            }
        }
    }

    ToggleSwitch {  
        id: ddsqPanelBtn
        width: 80
        anchors.top: textWidgetTitle.top
        anchors.margins: 0
        anchors.topMargin: 10
        anchors.bottomMargin: 0
        anchors.left: pidControlTabBtn.right
        text: "DDS Queue"
        textOnState: "DDS Queue"
        enableState: false
        radius: 0
        onClicked: {
            if(enableState){
                global.rampState = global.rampRun
                runRamp(false)

                rectDDSQueue.visible = true
                rectGraph.visible = false
                rectPIDControls.visible = false

                graphPanelBtn.enableSwitch(false)
                pidControlTabBtn.enableSwitch(false)
            }
        }
    }

    LEDIndicator {
        id: ddspllLockIndicator
        anchors {
            top: ddsqPanelBtn.top
            left: ddsqPanelBtn.right
        }
        labelText: "DDS PLL Locked?"
        currentState: false
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
            source: ".\\resources\\pid_transfer_function.png"
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
                    text: "f_D [kHz]"
                    color: "#cccccc"
                    font.pointSize: 8
                }

                Text {
                    text: "f_I [kHz]"
                    color: "#cccccc"
                    font.pointSize: 8

                }
            }

            Column {                
                spacing: 5

                ComboBox {
                    id: pidPoleDerivativeComboBox
                    model: ListModel {
                        ListElement { text: "Off" }  //passed_diff_pole = 0
                        ListElement { text: "10 kHz" }
                        ListElement { text: "30 kHz" }
                        ListElement { text: "100 kHz" }
                        ListElement { text: "300 kHz" } //passed_diff_pole = 4
                    }
                }

                ComboBox {
                    id: pidPoleIntegralComboBox
                    model: ListModel {
                        ListElement { text: "Off" }  //passed_int_pole = 0
                        ListElement { text: "3 kHz" }
                        ListElement { text: "10 kHz" }
                        ListElement { text: "32 kHz" }
                        ListElement { text: "100 kHz" }
                        ListElement { text: "300 kHz" }  //passed_int_pole = 5
                    }
                }
            }
        }

        ThemeButton {
            height: 30
            width: 80
            text: "Update Poles"
            anchors {
                bottom: parent.bottom
                right: parent.right
                margins: 10
            }
            onClicked: {
                set_pid_poles()
            }
        }
    }

    ListModel {
        id: availableProfiles
    }

    ListModel {
        id: playlistProfiles
    }

    function showDDSQComponents(state){
        rectDDSQueuePlaylist.visible = state
        rectDDSQueueCommands.visible = state
    }

    function setGUIPlaylistFromGlobalPlaylist(){
        playlistProfiles.clear()
        for(var i=0; i<global.ddsqPlaylist.length; i++){
            playlistProfiles.append({"name": global.ddsqProfiles[0]["name"]})
        }

        for(var i=0; i<global.ddsqPlaylist.length; i++){
            var row = playlistRepeater.itemAt(i)
            var profile_cbox = row.children[1]
            profile_cbox.currentIndex = global.ddsqPlaylist[i]["profile_idx"]

            var interrupt_cbox = row.children[3]
            interrupt_cbox.currentIndex = global.ddsqPlaylist[i]["interrupt_idx"]
        }

        if(global.ddsqPlaylist.length == 0){
            ddsqPlaylistStartupHelp.visible = true
            ddsqPlaylistLabels.visible = false
        }
        else {
            ddsqPlaylistStartupHelp.visible = false
            ddsqPlaylistLabels.visible = true
        }
    }

    function ddsqUpdateGlobalPlaylistFromGUI(){
        //TODO: Refactor functions that operate on playlsit to use this function.
        global.ddsqPlaylist = []
        for(var i=0; i<playlistProfiles.count; i++){
            var playlist_entry = playlistRepeater.itemAt(i)
            var prof_idx = playlist_entry.children[1].currentIndex //index of combobox that has the profile
            var interrupt_type = playlist_entry.children[3].currentIndex //Will use this later, grab it now
            global.ddsqPlaylist[i] = {"profile_idx": prof_idx, "interrupt_idx": interrupt_type}
        }
    }

    function setAvailableProfilesFromGlobalProfileList(){
        availableProfiles.clear()
        for(var i=0; i<global.ddsqProfiles.length; i++){
            availableProfiles.append({"name": global.ddsqProfiles[i]["name"]})
        }
    }

    function deleteProfileFromPlaylist(del_index){
        ddsqUpdateGlobalPlaylistFromGUI()
        global.ddsqPlaylist.splice(del_index, 1)
        setGUIPlaylistFromGlobalPlaylist()
    }

    function insertProfileIntoPlaylist(insert_index){
        ddsqUpdateGlobalPlaylistFromGUI()
        global.ddsqPlaylist.splice(insert_index, 0, {"profile_idx": 0, "interrupt_idx": 0})
        setGUIPlaylistFromGlobalPlaylist()   
    }

    function sendPlaylistToDevice(){

        ddsqUpdateGlobalPlaylistFromGUI()

        //Go ahead and abort any running queue
        abort_ddsq()

        //Because of the way the DDSQ works on OPL1 board, we need 
        // to count the number of STP and DRG profiles we send.
        var cnt_drg = 0
        var cnt_stp = 0
        var profile_mapping = {} //will contain the mapping of each profile to where it's stored
                                 //in the microcontroller memory.  format is:
                                 // { str::profileName : {"type": <number indicating type>, "index": <index of that profile>} }

        //Clear the ddsq.  We start with a clean slate every time we send the program.
        ice.send("ddsqclr", slot, null) //no callback

        //Program each profile, step by step
        for(var i=0; i<availableProfiles.count; i++){
            //Get the profile corresponding to this playlist entry
            var profile = global.ddsqProfiles[i]

            //Things diverge here, depending on the profile type
            if(profile["type"] == 0){ //Single frequency
                var idx = cnt_stp //The index where we'll store our info in the device
                cnt_stp += 1
                var base_int_str = "ddsqmpi 2 " + idx + " " //2 is the type -- STP
                var base_float_str = "ddsqmpf 2 " + idx + " "

                //Send all the STP things 
                ice.send(base_int_str + "0 " + profile["stpNValue"], slot, null) 
                ice.send(base_int_str + "1 " + profile["invertPFDPolarity"], slot, null)
                ice.send(base_float_str + "2 " + profile["stpOffsetDac"], slot, null)
                //ice.send(base_float_str + "3 " + profile["stpAuxDac"], slot, null) //Unused AUX DAC option
                ice.send(base_int_str + "4 " + profile["duration"], slot, null) 
                ice.send(base_int_str + "5 " + profile["stpFrequency"], slot, null)

                //Now save the mapping of this profile to the 
                var new_mapping = {"type": 2, "index": idx}
                profile_mapping[profile["name"]] = new_mapping
            }
            else if(profile["type"] == 1){ //Ramp profile type
                var idx = cnt_drg 
                cnt_drg += 1
                var base_int_str = "ddsqmpi 1 " + idx + " " //1 is the type -- DRG
                var base_float_str = "ddsqmpf 1 " + idx + " "

                //Send all the DRG things --many of the argument indexes are the same as STP
                ice.send(base_int_str + "0 " + profile["drgNValue"], slot, null) 
                ice.send(base_int_str + "1 " + profile["invertPFDPolarity"], slot, null)
                ice.send(base_float_str + "2 " + profile["drgOffsetDAC"], slot, null)
                //ice.send(base_float_str + "3 " + profile["drgAuxDac"], slot, null) //Unused AUX DAC option
                ice.send(base_int_str + "4 " + profile["duration"], slot, null)
                ice.send(base_int_str + "5 " + profile["drgRampDuration"], slot, null)
                ice.send(base_int_str + "6 " + profile["drgDirection"], slot, null)
                ice.send(base_int_str + "7 0", slot, null) //Ramp destination is frequency.  Hard coded for now (also default setting on board)
                ice.send(base_int_str + "8 " + profile["drgLowerLimit"], slot, null)
                ice.send(base_int_str + "9 " + profile["drgUpperLimit"], slot, null)

                //Now save the mapping of this profile to the 
                var new_mapping = {"type": 1, "index": idx}
                profile_mapping[profile["name"]] = new_mapping
            }
        } //end profile programming


        //Now program the device's playlist.  For each playlist element, send the  
        for(var i=0; i<global.ddsqPlaylist.length; i++){
            //First, get the profile attached to this playlist entry
            var prof_idx = global.ddsqPlaylist[i]["profile_idx"] //index of combobox that has the profile
            var interrupt_type = global.ddsqPlaylist[i]["interrupt_idx"] //Will use this later, grab it now

            var profile_key = global.ddsqProfiles[prof_idx]["name"]

            ice.send("ddsqadde " + profile_mapping[profile_key]["type"] + " " + profile_mapping[profile_key]["index"] + " " + interrupt_type, slot, null)
            //i.e. ddsqadde 2 0 1
        }
            
    }

    function set_ddsq_event_addr(addr){
        var cmd_str = "evtaddr 0 " + addr //0 is the identifier for ddsq events.  other ints are something else
        ice.send(cmd_str, slot, null)
        get_ddsq_event_addr()
    }

    function get_ddsq_event_addr(){
        ice.send("evtaddr? 0", slot, function(result){
            var addr = result
            ddsqEventAddr.value = parseInt(addr)
            ddsqEventAddr.text = addr
            global.ddsq_event_addr = parseInt(addr)
        })
    }

    function send_manual_mode_params(){
        setIntFreq(datainputIntFreq.value) //convert from MHz to Hz
        setInvert(toggleswitchInvert.enableState)
        setNDiv(rotarycontrolNDiv.getValue())
        setServoOffset(rotarycontrolServoOffset.getValue())
    }

    function abort_ddsq(){
        if(global.ddsq_active == true){
            //Set all the current manual control values.  This ensures when teh ddsq is aborted or ends, we
            // Return to the same manual control values.
            send_manual_mode_params()
            //Send a #doevent command to address corresponding to the address that triggers the next ddsq step
            var cmd_str = "DDSQABRT 0"  //Execute profile 0 after stopping the queue
            ice.send(cmd_str, slot, null)
        }
        get_ddsq_step()
    }

    function get_ddsq_step(){
        ice.send("ddsqppt? 3", slot, function(result){  //3 is the parameter id for ddsqproperty.next_index_to_exe
            var index = parseInt(result)
            if(index == 255){
                //We haven't even set up the next profile.  Queue is inactive
                ddsqCurrentStep.text = "Queue\nInactive"
                textServoOffset.color = "#FFFFFF"
                textNDiv.color = "#FFFFFF"
                textInvert.color = "#FFFFFF"
                textIntFreq.color = "#FFFFFF"
                if(global.ddsq_active == true){
                    global.ddsq_active = false
                    send_manual_mode_params()
                }
            }
            else if(result == "Invalid Command"){
                ddsqCurrentStep.text = "Error.\nRestart."
                textServoOffset.color = "#FFFFFF"
                textNDiv.color = "#FFFFFF"
                textInvert.color = "#FFFFFF"
                textIntFreq.color = "#FFFFFF"
                global.ddsq_active = false
            }
            else if(index == 1){
                ddsqCurrentStep.text = "1st Profile\nProgrammed"
                textServoOffset.color = "#DD0000"
                textNDiv.color = "#DD0000"
                textInvert.color = "#DD0000"
                textIntFreq.color = "#DD0000"
                global.ddsq_active = true
            }
            else{
                ddsqCurrentStep.text = index - 2 //the actual reported index is of the NEXT index to PROGRAM.
                // That means the index that's actually executing is 2 behind.
                textServoOffset.color = "#DD0000"
                textNDiv.color = "#DD0000"
                textInvert.color = "#DD0000"
                textIntFreq.color = "#DD0000"
                global.ddsq_active = true
            }
        })  
    }

    Rectangle {
        id: rectDDSQueue
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

        Rectangle {
            id: rectDDSQueuePlaylist
            anchors.top: parent.top
            anchors.left: rectDDSQueueCommands.right
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 5
            color: "#505050"
            radius: 5

            Text {
                id: ddsqProfilesTitle
                color: "#cccccc"
                text: "Playlist - DDS Queue Profiles To Execute"
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.top: parent.top
                anchors.topMargin: 7
                styleColor: "#ffffff"
                font.bold: true
                font.pointSize: 10
            }

            Column {
                id: ddsqPlaylistColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: ddsqProfilesTitle.bottom
                anchors.bottom: parent.bottom
                anchors.margins: 10
                spacing: 5

                Rectangle {
                    id: ddsqPlaylistLabels
                    visible: false
                    width: parent.width
                    height: 10
                    color: "#505050"

                    Text {
                        x: 29
                        anchors.top: parent.top
                        text: "Profile"
                        color: "#cccccc"
                    }

                    Text {
                        x: 183
                        anchors.top: parent.top
                        text: "Interrupt Trigger"
                        color: "#cccccc"
                    }

                }

                Rectangle{
                    id: ddsqPlaylistStartupHelp
                    width: parent.width
                    height: 50
                    color: "#333333"
                    Text {
                        anchors.centerIn: parent
                        color: "#cccccc"
                        text: "Create at least one profile and hit, 'Add Element'\nto start building the series of events you want the\nDDS to perform."
                    }
                }

                Repeater {
                    id: playlistRepeater
                    // model: global.ddsqPlaylist.length
                    model: playlistProfiles.count

                    Row {

                        // Button to delete a profile from the playlist
                        Rectangle {
                            y: 0
                            height: 15
                            width: 30
                            color: 'transparent'
                            Text {
                                id: profileIndexText
                                // anchor.left: parent.left
                                y: 3
                                text: index
                                font.bold: true
                                color: "#cccccc"
                            }
                            Text {
                                id: delProfileXBox
                                // anchor.left: parent
                                x: 15
                                y: 3
                                text: "[X]"
                                color: "#cccccc"
                            
                                MouseArea {
                                    anchors.fill: delProfileXBox
                                    onClicked: {
                                        deleteProfileFromPlaylist(index)
                                    }
                                }
                            }
                        }

                        
                        // Selection box for picking which profile should be executed
                        ComboBox {
                            textRole: 'name'
                            model: availableProfiles
                        }

                        Rectangle {
                            y: 3
                            height: 15
                            width: 30
                            color: 'transparent'
                            Text {
                                color: "#cccccc"
                                text: "[edit]"
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    var test = playlistRepeater.itemAt(index)
                                    var cbox = test.children[1]
                                    ddsqSetProfileBoxParamsToProfileVals(cbox.currentIndex);
                                    ddsqEditProfileSelectionBox.visible = false;
                                    ddsqDefineProfileBox.visible = true;
                                    showDDSQComponents(false)
                                }
                            }
                        }

                        ComboBox {
                            model: ListModel {
                                ListElement {text: "Go To Next Profile"}
                                ListElement {text: "Event System"}
                            }
                        }
                    }
                }
            }

            ThemeButton {
                id: addProfileToPlaylist
                height: 30
                width: 105
                anchors {
                    bottom: parent.bottom
                    left: parent.left
                    margins: 10
                }
                text: "Add Element at:"

                onClicked: {
                    //turn off help and turn on labels!
                    if(0 < global.ddsqProfiles.length){
                        insertProfileIntoPlaylist(addProfileToPlaylistIndexBox.value)
                    } else { //no profiles to add!
                        showAlert("You must create at least one profile\nbefore adding a profile to\nthe DDS Playlist")
                    }

                }
            }

            DataInput {
                id: addProfileToPlaylistIndexBox
                height: 30
                width: 30
                pointSize: 10
                anchors {
                    bottom: parent.bottom
                    left: addProfileToPlaylist.right
                    margins: 10
                }
                value: 0
                precision: 2
                decimal: 0
            }

            ThemeButton {
                id: ddsqPreviewButton
                y: 7
                width: 90
                height: 30
                text: "Preview"
                highlight: false
                anchors {
                    bottom: parent.bottom
                    right: parent.right
                    margins: 10
                }
                onClicked: {
                    if(0 < global.ddsqPlaylist.length){
                        ddsqPreviewRect.visible = true
                        showDDSQComponents(false)
                        ddsqUpdatePlaylistPreview()                 
                    }
                    else {
                        showAlert("You must have at least 1 element\nadded to the playlist before the\npreview will be meaningful.")
                    }
                }
            }
        }

        FileDialog {
            id: ddsqSavePlaylistDialog
            title: "Select a location to save your settings"
            visible: false
            selectMultiple: false
            selectExisting: false
            nameFilters: ["DDS Queue Settings (*.ddsq-settings)"]
            onAccepted: {
                ddsqUpdateGlobalPlaylistFromGUI()
                ice.saveData(ddsqSavePlaylistDialog.fileUrl, {"profiles": global.ddsqProfiles, "playlist": global.ddsqPlaylist})
            }
            onRejected: {
                console.log("Canceled save operation")
            }
        }

        FileDialog {
            id: ddsqLoadPlaylistDialog
            title: "Select a DDS Queue Settings file to load"
            visible: false
            selectMultiple: false
            selectExisting: true
            nameFilters: ["DDS Queue Settings (*.ddsq-settings)"]
            onAccepted: {
                var loaded_data = ice.loadData(ddsqLoadPlaylistDialog.fileUrl)
                global.ddsqProfiles = loaded_data["profiles"]
                global.ddsqPlaylist = loaded_data["playlist"]
                setAvailableProfilesFromGlobalProfileList()
                setGUIPlaylistFromGlobalPlaylist()
            }
            onRejected: {
                console.log("Canceled load operation")
            }
        }

        Rectangle {
            id: rectDDSQueueCommands
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 5
            width: 100
            color: "#505050"
            radius: 5

            Column {
                id: ddsqCommandsColumn
                anchors.top: parent.top
                anchors.margins: 10
                spacing: 5
                width: 90
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    color: "#ffffff"
                    text: "Profiles"
                    styleColor: "#ffffff"
                    font.bold: true
                    font.pointSize: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                ThemeButton {
                    id: ddsqNewProfileBtn
                    y: 7
                    width: 90
                    height: 25
                    text: "New Profile"
                    highlight: false
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: {
                        ddsqSetProfileBoxParamsToDefaults();
                        ddsqDefineProfileBox.visible = true
                        showDDSQComponents(false)
                    }
                }

                ThemeButton {
                    id: ddsqEditProfileBtn
                    y: 7
                    width: 90
                    height: 25
                    text: "Edit Profile"
                    highlight: false
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: {
                        editProfileSelectionComboBox.currentIndex = -1
                        if(0 == global.ddsqProfiles.length){
                            showAlert("You must create a profile\nbefore you can edit a profile.")
                        }
                        else{
                            ddsqEditProfileSelectionBox.visible = true
                            showDDSQComponents(false)
                        }
                    }
                }

                ThemeButton {
                    id: ddsqDeleteProfileBtn
                    y: 7
                    width: 90
                    height: 25
                    text: "Delete Profile"
                    highlight: false
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: {
                        editProfileSelectionComboBox.currentIndex = -1
                        if(0 == global.ddsqProfiles.length){
                            showAlert("You must create a profile\nbefore you can delete a profile.")
                        }
                        else{
                            ddsqDeleteProfileSelectionBox.visible = true
                            showDDSQComponents(false)
                        }
                    }
                }

                // Text {
                //     color: "#cccccc"
                //     text: "---------"
                //     font.pointSize: 10
                //     anchors.horizontalCenter: parent.horizontalCenter
                // }

                Text {
                    color: "#ffffff"
                    text: "Options"
                    styleColor: "#ffffff"
                    font.bold: true
                    font.pointSize: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                ThemeButton {
                    id: ddsqSaveSettingsBtn
                    y: 7
                    width: 90
                    height: 25
                    text: "Save Settings"
                    highlight: false
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: {
                        ddsqSavePlaylistDialog.open()
                    }
                    enabled: true
                }

                ThemeButton {
                    id: ddsqLoadSettingsBtn
                    y: 7
                    width: 90
                    height: 25
                    text: "Load Settings"
                    highlight: false
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: {
                        ddsqLoadPlaylistDialog.open()
                    }
                }

                // Text {
                //     color: "#cccccc"
                //     text: "---------"
                //     font.pointSize: 10
                //     anchors.horizontalCenter: parent.horizontalCenter
                // }

                Text {
                    color: "#ffffff"
                    text: "Commands"
                    styleColor: "#ffffff"
                    font.bold: true
                    font.pointSize: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                ThemeButton {
                    id: ddsqStartDDSQBtn
                    y: 7
                    width: 90
                    height: 25
                    text: "Execute Seq."
                    highlight: false
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: {
                        if (playlistProfiles.count == 0){
                            showAlert("Please add profiles to the playlist\n before attempting to program\nthe device.")
                        }
                        else{
                            sendPlaylistToDevice()
                            ice.send('ddsqppt 7 0', slot, null) //Tell device to execute profile 0 after execution ends
                            ice.send('ddsqppt 8 1', slot, null) //Tell device to execute selected profile after execution ends.
                            ice.send('ddsqexe 1', slot, null) //Tell the device to begin ddsq mode.
                            get_ddsq_step()
                            ddsqCurrentStep.text = "Programmed\n& Idling"
                            global.ddsq_active = true
                        }
                    }
                }

                ThemeButton {
                    id: ddsqAbortDDSQBtn
                    y: 7
                    width: 90
                    height: 25
                    text: "Abort Seq."
                    highlight: false
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: {
                        abort_ddsq()
                    }
                }

                ThemeButton {
                    id: ddsqTriggerDDSQBtn
                    y: 7
                    width: 90
                    height: 25
                    text: "Trigger Event"
                    highlight: false
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: {
                        //Send a #doevent command to address corresponding to the address that triggers the next ddsq step
                        var cmd_str = "#doevent " + ddsqEventAddr.value
                        ice.send(cmd_str, slot, null)
                        get_ddsq_step()
                    }
                }

                Text {
                    color: "#cccccc"
                    text: "Event Addr:"
                    styleColor: "#ffffff"
                    font.bold: true
                    font.pointSize: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                DataInput {
                    id: ddsqEventAddr
                    value: 1
                    text: "1"
                    pointSize: 12
                    radius: 0
                    minVal: 0
                    maxVal: 7
                    precision: 1
                    decimal: 0
                    width: 40
                    anchors.horizontalCenter: parent.horizontalCenter
                    onValueEntered: {
                        set_ddsq_event_addr(ddsqEventAddr.value)
                    }
                }

                Text {
                    color: "#cccccc"
                    text: "Current Step:"
                    styleColor: "#ffffff"
                    font.bold: true
                    font.pointSize: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    id: ddsqCurrentStep
                    color: "#cccccc"
                    text: "N/A"
                    styleColor: "#ffffff"
                    font.bold: true
                    font.pointSize: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
        
    }

    function ddsqSetProfileBoxParamsToDefaults(){
        //Profile class box, common to all profile types
        profileName.text = "My New Profile"
        ddsqProfileTypeComboBox.currentIndex = 0
        profileDuration.value = 1000.0

        //Single Tone Profile parameters
        stpFrequency.value = 100.000000
        stpNValue.value = 8
        stpOffsetDac.value = 0.0

        //Ramp Profile Parameters
        drgStopFreq.value = 150.000000
        drgStartFreq.value = 100.000000
        drgRampDuration.value = 1000
        drgNValue.value = 8
        drgOffsetDAC.value = 0.0
    }

    function ddsqSetProfileBoxParamsToProfileVals(profile_index){
        if(profile_index < global.ddsqProfiles.length){
            var profile = global.ddsqProfiles[profile_index]

            //Profile class box, common to all profile types
            profileName.text = profile["name"]
            ddsqProfileTypeComboBox.currentIndex = profile["type"]
            profileDuration.value = profile["duration"]
            ddsqProfileInvertPFDPolarityComboBox.currentIndex = profile["invertPFDPolarity"]

            //Single Tone Profile parameters
            stpFrequency.value = profile["stpFrequency"] / 1000000.0 //convert back to MHz
            stpNValue.value = profile["stpNValue"]
            stpOffsetDac.value = profile["stpOffsetDac"]

            //Ramp Profile Parameters
            if(profile["drgDirection"] == 0){ //lower -> upper
                drgStopFreq.value = profile["drgUpperLimit"] / 1000000.0 //convert back to MHz
                drgStartFreq.value = profile["drgLowerLimit"] / 1000000.0 //convert back to MHz
            }
            else{
                drgStopFreq.value = profile["drgLowerLimit"] / 1000000.0 //convert back to MHz
                drgStartFreq.value = profile["drgUpperLimit"]    / 1000000.0 //convert back to MHz
            }
            

            drgRampDuration.value = profile["drgRampDuration"]
            drgNValue.value = profile["drgNValue"]
            drgOffsetDAC.value = profile["drgOffsetDAC"]

        }
    }

    function ddsqPrintProfileVals(profile_index){
        if(profile_index < global.ddsqProfiles.length){
            var profile = global.ddsqProfiles[profile_index]

            //Profile class box, common to all profile types
            print("name  " + profile["name"])
            print( "type  " + profile["type"])
            print( "duration  " + profile["duration"])
            print( "invertPFD " + profile["invertPFDPolarity"])

            //Single Tone Profile parameters
            print( "stpFrequency  " + profile["stpFrequency"])
            print( "stpNValue  " + profile["stpNValue"])
            print( "stpOffsetDac  " + profile["stpOffsetDac"])

            //Ramp Profile Parameters
            print( "drgUpperLimit  " + profile["drgUpperLimit"])
            print( "drgLowerLimit  " + profile["drgLowerLimit"])
            print( "drgDirection  " + profile["drgDirection"])
            print( "drgRampDuration  " + profile["drgRampDuration"])
            print( "drgNValue  " + profile["drgNValue"])
            print( "drgOffsetDAC  " + profile["drgOffsetDAC"])
        }
    }

    function ddsqAddProfileDefinition(force_write){
        //Check if we already have a profile by this neame
        var already_defined = false;
        var existing_index = -1;
        for(var i=0; i < global.ddsqProfiles.length; i++){
            var profile = global.ddsqProfiles[i]
            if(profileName.text == profile["name"]){
                already_defined = true;
                existing_index = i;
            }
        }        
        var new_entry = {
            "name": profileName.text,
            "type": ddsqProfileTypeComboBox.currentIndex,
            "duration": profileDuration.value,
            "invertPFDPolarity": ddsqProfileInvertPFDPolarityComboBox.currentIndex,
            
            "stpFrequency": stpFrequency.value * 1000000, //convert to Hz
            "stpNValue": stpNValue.value,
            "stpOffsetDac": stpOffsetDac.value,

            "drgRampDuration": drgRampDuration.value,
            "drgNValue": drgNValue.value,
            "drgOffsetDAC": drgOffsetDAC.value,            
        }

        if(drgStartFreq.value < drgStopFreq.value){
                new_entry["drgUpperLimit"] = drgStopFreq.value * 1000000, //convert to Hz
                new_entry["drgLowerLimit"] = drgStartFreq.value * 1000000, //convert to Hz
                new_entry["drgDirection"] = 0
        }else{
                new_entry["drgUpperLimit"] = drgStartFreq.value * 1000000, //convert to Hz
                new_entry["drgLowerLimit"] = drgStopFreq.value * 1000000, //convert to Hz
                new_entry["drgDirection"] = 1
        }

        if(already_defined == false){
            global.ddsqProfiles[global.ddsqProfiles.length] = new_entry
            availableProfiles.append({"name": new_entry["name"]})
        }
        else{
            global.ddsqProfiles[existing_index] = new_entry   
        }

    }

    function ddsqDeleteProfileDefinition(profile_index){
        ddsqUpdateGlobalPlaylistFromGUI()
        if(0 <= profile_index && profile_index < global.ddsqProfiles.length){
            //first, remove this profile from any lpaylist elements
            //Iterate backwards so we don't have to worry about our dleetions
            //affecting our indexes
            for(var i=global.ddsqPlaylist.length - 1; 0 <= i; i--){
                if(global.ddsqPlaylist[i]["profile_idx"] == profile_index){
                    deleteProfileFromPlaylist(i)
                }
            }

            //Now we need to lower the indexes of each profile that had a value grater than the one we just deleted
            for(var i=0; i<global.ddsqPlaylist.length; i++){
                if(profile_index < global.ddsqPlaylist[i]["profile_idx"]){
                    global.ddsqPlaylist[i]["profile_idx"] = global.ddsqPlaylist[i]["profile_idx"] - 1
                }
            }
        }

        //Now delete the profile itself
        global.ddsqProfiles.splice(profile_index, 1)

        //NOw update the GUI with the new profiles and playlist arrays
        setAvailableProfilesFromGlobalProfileList()
        setGUIPlaylistFromGlobalPlaylist()

    }

    Rectangle {
        id: ddsqEditProfileSelectionBox
        anchors.centerIn: rectDDSQueue
        color: '#333333'
        width: 250
        height: 100
        border.color: '#39F'
        border.width: 2
        visible: false
        z: 100

        Text {
            id: ddsqEditProfileSelectionTitle
            text: "Select Profile To Modify"
            font.family: 'Helvetica'
            font.pointSize: 12
            font.bold: true
            anchors {
                top: parent.top
                left: parent.left
                margins: 10
            }
            color: '#FFF'
        }

        ComboBox {
            id: editProfileSelectionComboBox
            textRole: 'name'
            anchors {
                top: ddsqEditProfileSelectionTitle.bottom
                left: parent.left
                right: parent.right
                margins: 10
            }
            model: availableProfiles
        }

        ThemeButton {
            id: editProfileOKButton
            width: 40
            height: 26
            text: "Ok"
            pointSize: 12
            textColor: "#ffffff"
            borderWidth: 1
            highlight: true
            onClicked: {
                //if a profile is selected, set the values to that profile and open the edit box
                if(editProfileSelectionComboBox.currentIndex != -1){
                    ddsqSetProfileBoxParamsToProfileVals(editProfileSelectionComboBox.currentIndex);
                    ddsqEditProfileSelectionBox.visible = false;
                    ddsqDefineProfileBox.visible = true;
                    showDDSQComponents(false)
                }
                else{
                    ddsqEditProfileSelectionBox.visible = false;
                    showDDSQComponents(true)
                }
            }
            anchors {
                bottom: parent.bottom
                right: editProfileCancelButton.left
                margins: 10
            }
        }

        ThemeButton {
            id: editProfileCancelButton
            width: 60
            height: 26
            text: "Cancel"
            pointSize: 12
            textColor: "#ffffff"
            borderWidth: 1
            highlight: true
            onClicked: {
                ddsqEditProfileSelectionBox.visible = false;
                showDDSQComponents(true)
            }
            anchors {
                bottom: parent.bottom
                right: parent.right
                margins: 10
            }
        }
    }

    Rectangle {
        id: ddsqDeleteProfileSelectionBox
        anchors.centerIn: rectDDSQueue
        color: '#333333'
        width: 250
        height: 150
        border.color: '#39F'
        border.width: 2
        visible: false
        z: 100

        Text {
            id: ddsqDeleteProfileSelectionTitle
            text: "Select Profile To Delete\nWARNING: IRREVERSIBLE!"
            font.family: 'Helvetica'
            font.pointSize: 12
            font.bold: true
            anchors {
                top: parent.top
                left: parent.left
                margins: 10
            }
            color: '#FFF'
        }

        ComboBox {
            id: deleteProfileSelectionComboBox
            textRole: 'name'
            anchors {
                top: ddsqDeleteProfileSelectionTitle.bottom
                left: parent.left
                right: parent.right
                margins: 10
            }
            model: availableProfiles
        }

        ThemeButton {
            id: deleteProfileOKButton
            width: 40
            height: 26
            text: "Ok"
            pointSize: 12
            textColor: "#ffffff"
            borderWidth: 1
            highlight: true
            onClicked: {
                ddsqDeleteProfileSelectionBox.visible = false
                if(deleteProfileSelectionComboBox.currentIndex != -1){
                    ddsqDeleteProfileDefinition(deleteProfileSelectionComboBox.currentIndex)
                }
                showDDSQComponents(true)
            }
            anchors {
                bottom: parent.bottom
                right: deleteProfileCancelButton.left
                margins: 10
            }
        }

        ThemeButton {
            id: deleteProfileCancelButton
            width: 60
            height: 26
            text: "Cancel"
            pointSize: 12
            textColor: "#ffffff"
            borderWidth: 1
            highlight: true
            onClicked: {
                ddsqDeleteProfileSelectionBox.visible = false;
                showDDSQComponents(true)
            }
            anchors {
                bottom: parent.bottom
                right: parent.right
                margins: 10
            }
        }
    }

    Rectangle {
        id: ddsqDefineProfileBox
        anchors.centerIn: rectDDSQueue
        color: '#333333'
        width: 400
        height: 450
        border.color: '#39F'
        border.width: 2
        visible: false
        z: 100
        
        Text {
            id: titleText
            text: "Modify DDS Queue Profile"
            font.family: 'Helvetica'
            font.pointSize: 12
            font.bold: true
            anchors {
                top: parent.top
                left: parent.left
                margins: 10
            }
            color: '#FFF'
        }
        
        Rectangle {
            id: ddsqDefineProfileClassBox
            anchors {
                top: titleText.bottom
                left: parent.left
                margins: 10
            }
            width: 380
            height: 110
            color: '#555'
            border.color: '#39F'
            border.width: 2
            

            Column{
                id: ddsqProfileClassLCol
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 10
                spacing: 10

                Text{
                    text: "Profile Name: "
                    color: '#FFF'
                }

                Text {
                    text: "Profile Type: "
                    color: '#FFF'
                }

                Text {
                    text: "Invert PFD Polarity: "
                    color: '#FFF'
                }

                Text {
                    text: "Total Duration* [\u03BCs]: "
                    color: '#FFF'
                }
            }
        
            Column {
                id: commonProfileData
                anchors.left: ddsqProfileClassLCol.right
                anchors.top: parent.top
                anchors.margins: 10
                spacing: 6

                TextInput {
                    id: profileName
                    text: "My New DDS Profile"
                    cursorVisible: true
                    height: 12
                    color: '#FFF'
                    selectByMouse: true
                    onFocusChanged: {
                        if (profileName.focus === true) {
                        profileName.selectAll()
                        }
                    }
                }
                

                ComboBox {
                    editable: false
                    id: ddsqProfileTypeComboBox
                    model: ListModel {
                        id: model
                        ListElement { text: "Single Frequency" }
                        ListElement { text: "Frequency Ramp" }
                    }
                    onCurrentIndexChanged: {
                        if(currentIndex == 0){
                            ddsqDefineSTPProfileParamsBox.visible = true
                            ddsqDefineDRGProfileParamsBox.visible = false
                        }
                        else if(currentIndex == 1){
                            ddsqDefineSTPProfileParamsBox.visible = false
                            ddsqDefineDRGProfileParamsBox.visible = true
                        }
                    }
                }

                ComboBox {
                    editable: false
                    id: ddsqProfileInvertPFDPolarityComboBox
                    model: ListModel {
                        id: model2
                        ListElement { text: "Disabled" }
                        ListElement { text: "Enabled" }
                    }
                }

                DataInput {
                    id: profileDuration
                    value: 10000
                    text: "10000"
                    pointSize: 8
                    radius: 0
                    minVal: 100
                    maxVal: 65535
                    precision: 5
                    decimal: 0
                }
            }

            Column{
                id: ddsqProfileClassLimitations
                anchors.left: commonProfileData.right
                anchors.top: parent.top
                anchors.margins: 10
                spacing: 10

                Text{
                    text: "{Any String}"
                    color: '#FFF'
                }

                Text {
                    text: "Pick one"
                    color: '#FFF'
                }

                Text {
                    text: "Pick one"
                    color: '#FFF'
                }

                Text {
                    text: "[200, 65535]"
                    color: '#FFF'
                }
            }
        }

        Text {
            id: durationWarning
            color: "#FFFFFF"
            text: "* Duration only applies if \"Go to next step\" is used as the\ninterrupt trigger for this profile."
            anchors {
                top: ddsqDefineProfileClassBox.bottom
                left: parent.left
                margins: 10
            }
        }

        Rectangle {
            id: ddsqDefineSTPProfileParamsBox
            anchors {
                top: durationWarning.bottom
                left: parent.left
                margins: 10
            }
            width: 380
            height: 90
            color: '#555'
            border.color: '#39F'
            border.width: 2
            visible: false

            Column {
                id: ddsqProfileSTPParamsLCol
                anchors {
                    left: parent.left
                    top: parent.top
                    margins: 10
                }
                spacing: 14

                Text{
                    text: "Int. Ref. Frequency [MHz]: "
                    color: '#FFF'
                }

                Text {
                    text: "N Div [integer]"
                    color: '#FFF'
                }

                Text {
                    text: "Servo Offset [V]: "
                    color: '#FFF'
                }

            }
        
            Column {
                id: stpData
                anchors {
                    left: ddsqProfileSTPParamsLCol.right
                    // right: stpLimits.left
                    top: parent.top    
                    margins: 10
                }
                spacing: 2

                DataInput {
                    id: stpFrequency
                    value: 125.000000
                    text: "125.000000"
                    pointSize: 8
                    radius: 0
                    minVal: 0
                    maxVal: 250.000000
                    decimal: 6
                    precision: 10
                }

                DataInput {
                    id: stpNValue
                    value: 8
                    text: "8"
                    pointSize: 8
                    radius: 0
                    minVal: 0
                    maxVal: 64
                    decimal: 0
                    precision: 2
                }

                DataInput {
                    id: stpOffsetDac
                    value: 0.0
                    text: "0.0"
                    pointSize: 8
                    radius: 0
                    minVal: -10.0
                    maxVal: 10.0
                    precision: 6
                    decimal: 2
                }
            }

            Column {
                id: stpLimits
                spacing: 14
                anchors {
                    left: stpData.right
                    right: parent.right
                    top: parent.top
                    margins: 10
                }

                Text{                   
                    text: "(0, 250.000000]"
                    color: '#FFF'
                }

                Text {
                    text: "{8, 16, 32, 64}"
                    color: '#FFF'
                }

                Text {
                    text: "[-10.00, 10.00]"
                    color: '#FFF'
                }
            }
        }

        Rectangle {
            id: ddsqDefineDRGProfileParamsBox
            anchors {
                top: durationWarning.bottom
                left: parent.left
                margins: 10
            }
            width: 380
            height: 170
            color: '#555'
            border.color: '#39F'
            border.width: 2
            visible: true
            

            Column {
                id: ddsqProfileDRGParamsLCol
                anchors {
                    left: parent.left
                    top: parent.top
                    margins: 10
                }
                spacing: 12

                Text{
                    text: "Start Int. Ref. Frequency [MHz]: "
                    color: '#FFF'
                }

                Text{
                    text: "End Int. Ref. Frequency [MHz]: "
                    color: '#FFF'
                }

                Text{
                    text: "Ramp Duration [\u03BCs]: "
                    color: '#FFF'
                }

                Text {
                    text: "N Div [integer]"
                    color: '#FFF'
                }

                Text {
                    text: "Servo Offset [V]: "
                    color: '#FFF'
                }

            }
        
            Column {
                id: drgData
                anchors {
                    left: ddsqProfileDRGParamsLCol.right
                    // right: drgLimits.right
                    top: parent.top    
                    margins: 10
                }
                spacing: 3

                DataInput {
                    id: drgStartFreq
                    value: 100.000000
                    text: "100.000000"
                    pointSize: 8
                    radius: 0
                    minVal: 0
                    maxVal: 250.000000
                    precision: 10
                    decimal: 6
                }

                DataInput {
                    id: drgStopFreq
                    value: 150.000000
                    text: "150.000000"
                    pointSize: 8
                    radius: 0
                    minVal: 0
                    maxVal: 250.000000
                    precision: 10
                    decimal: 6
                }

                DataInput {
                    id: drgRampDuration
                    value: 0.0
                    text: "0.0"
                    pointSize: 8
                    radius: 0
                    minVal: 100
                    maxVal: 65535
                    precision: 5
                    decimal: 0
                }

                DataInput {
                    id: drgNValue
                    value: 0.0
                    text: "0.0"
                    pointSize: 8
                    radius: 0
                    minVal: 0
                    maxVal: 64
                    precision: 2
                    decimal: 0
                }

                DataInput {
                    id: drgOffsetDAC
                    value: 0.0
                    text: "0.0"
                    pointSize: 8
                    radius: 0
                    minVal: -10.0
                    maxVal: 10.0
                    precision: 6
                    decimal: 2
                }
            }

            Column {
                id: drgLimits
                spacing: 14
                anchors {
                    left: drgData.right
                    right: parent.right
                    top: parent.top
                    margins: 10
                }

                Text{
                    text: "(0, 250.000000]"
                    color: '#FFF'
                }

                Text{
                    text: "(0, 250.000000]"
                    color: '#FFF'
                }

                Text{
                    text: "[100, 65535]"
                    color: '#FFF'
                }

                Text {
                    text: "{8, 16, 32, 64}"
                    color: '#FFF'
                }

                Text {
                    text: "[-10.00, 10.00]"
                    color: '#FFF'
                }

            }
        }
        
        ThemeButton {
            id: okButton
            width: 40
            height: 26
            text: "Ok"
            pointSize: 12
            textColor: "#ffffff"
            borderWidth: 1
            highlight: true
            onClicked: {
                ddsqAddProfileDefinition(true);
                ddsqDefineProfileBox.visible = false;
                showDDSQComponents(true)
            }
            anchors {
                bottom: parent.bottom
                right: cancelButton.left
                margins: 10
            }
        }

        ThemeButton {
            id: cancelButton
            width: 60
            height: 26
            text: "Cancel"
            pointSize: 12
            textColor: "#ffffff"
            borderWidth: 1
            highlight: true
            onClicked: {
                ddsqSetProfileBoxParamsToDefaults();
                ddsqDefineProfileBox.visible = false;
                showDDSQComponents(true)
            }
            anchors {
                bottom: parent.bottom
                right: parent.right
                margins: 10
            }
        }
    }

    function ddsqUpdatePlaylistPreview(){
        ddsqPreviewGraph.clearData()
        ddsqUpdateGlobalPlaylistFromGUI()
        var time_offset = 0
        var max_value = 0

        for(var i=0; i<global.ddsqPlaylist.length; i++){
            //First, get the profile attached to this playlist entry
            var prof_idx = global.ddsqPlaylist[i]["profile_idx"] //index of combobox that has the profile
            var interrupt_type = global.ddsqPlaylist[i]["interrupt_idx"] //Will use this later, grab it now

            var profile = global.ddsqProfiles[prof_idx]

            if(profile["type"] == 0){ //STP profile
                var n_value = profile["stpNValue"]
                ddsqPreviewGraph.addPoint([time_offset, n_value * profile["stpFrequency"] / 1000000.0], 0)
                time_offset = time_offset + profile["duration"]
                ddsqPreviewGraph.addPoint([time_offset, n_value * profile["stpFrequency"] / 1000000.0], 0)
                if(max_value < n_value * profile["stpFrequency"]){
                    max_value = n_value * profile["stpFrequency"]
                }
            }
            else if(profile["type"] == 1){ //DRG profile
                var n_value = profile["drgNValue"]
                if(profile["drgDirection"] == 0){ // positive direction, start w/ lower limit
                    ddsqPreviewGraph.addPoint([time_offset, n_value * profile["drgLowerLimit"] / 1000000.0], 0)
                    time_offset = time_offset + profile["drgRampDuration"]
                    ddsqPreviewGraph.addPoint([time_offset, n_value * profile["drgUpperLimit"] / 1000000.0], 0)
                    time_offset = time_offset + profile["duration"] - profile["drgRampDuration"]
                    ddsqPreviewGraph.addPoint([time_offset, n_value * profile["drgUpperLimit"] / 1000000.0], 0)
                }
                else if(profile["drgDirection"] == 1){ //negative direction
                    ddsqPreviewGraph.addPoint([time_offset, n_value * profile["drgUpperLimit"] / 1000000.0], 0)
                    time_offset = time_offset + profile["drgRampDuration"]
                    ddsqPreviewGraph.addPoint([time_offset, n_value * profile["drgLowerLimit"] / 1000000.0], 0)
                    time_offset = time_offset + profile["duration"] - profile["drgRampDuration"]
                    ddsqPreviewGraph.addPoint([time_offset, n_value * profile["drgLowerLimit"] / 1000000.0], 0)
                }
                if(max_value < n_value * profile["drgUpperLimit"]){
                    max_value = n_value * profile["drgUpperLimit"]
                }
            }

        }

        //Now set the x_scale to the appropriate value
        ddsqPreviewGraph.xMinimum = 0
        ddsqPreviewGraph.xMaximum = time_offset
        ddsqPreviewGraph.gridXDiv = 10 
        ddsqPreviewGraph.axisXLabel = "Total Time = " + time_offset + "[\u03BCs] [" + time_offset / 10 + " \u03BCs/div]"

        ddsqPreviewGraph.yMinimum = 0
        ddsqPreviewGraph.yMaximum = max_value / 1000000.0 //convert to MHz
        ddsqPreviewGraph.gridYDiv = 10 //1000 Mhz / div
        ddsqPreviewGraph.axisYLabel = "Output Frequency [0 - " + max_value / 1000000.0 + " MHz] [" + max_value / 1000000 / 10 +" MHz/div]"

        ddsqPreviewGraph.refresh()

    }

    Rectangle{
        id: ddsqPreviewRect
        color: "#333333"
        radius: 15
        border.width: 2
        border.color: (active) ? '#3399ff' : "#666666";
        visible: false
        anchors {
            fill: parent
            margins: 20
        }
        
        Text {
            id: ddsqPreviewTitle
            color: "#cccccc"
            text: "DDS Queue Playlist Preview"
            height: 20
            anchors {
                top: parent.top
                left: parent.left
                margins: 10
            }
            font {
                pointSize: 12
                bold: true
            }
        }

        ThemeButton {
            id: ddsqPreviewExit
            text: "Close"
            textColor: "#ffffff"
            width: 40
            height: 20
            borderWidth: 1
            anchors {
                top: parent.top
                right: parent.right
                margins: 10
            }
            onClicked: {
                ddsqPreviewRect.visible = false
                showDDSQComponents(true)
            }
        }

        PlotComponent{
            id: ddsqPreviewGraph
            anchors {
                top: ddsqPreviewTitle.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: 10
            }            
            gridYDiv: 10
            yMinimum: 0
            yMaximum: 250
            axisYLabel: "Frequency [MHz] [0-16.0 MHz]"
            axisYUnits: "MHz"
            gridXDiv: 100
            xMinimum: 0
            xMaximum: 1000
            axisXLabel: "Time"
            axisXUnits: "us"
            xAxisPosition: 0.0
            yAxisPosition: 1.0

            datasetFill: false
            autoScale: false
            vDivSetting: 6
            rollMode: false 
            adjustableVdiv: false
            adjustableYOffset: false
        }
    }

    function showAlert(text){
        rectAlert.visible = true
        alertText.text = text
        showDDSQComponents(false)
    }

    Rectangle {
        id: rectAlert
        anchors.centerIn: rectDDSQueue
        color: '#333333'
        width: 250
        height: 250
        border.color: '#39F'
        border.width: 2
        visible: false
        z: 100
        radius: 5

        Text {
            id: alertText
            anchors.centerIn: parent
            text: "No message."
            color: "#cccccc"
            font.bold: true
            font.pointSize: 10
            font.family: "MS Shell Dlg 2"
        }

        ThemeButton {
            id: alertOkButton
            text: "Ok"
            anchors {
                bottom: parent.bottom
                right: parent.right
                margins: 10
            }
            onClicked: {
                rectAlert.visible = false
                showDDSQComponents(true)
            }
        }
    }
}

