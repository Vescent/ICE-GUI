import QtQuick 2.0
import QtQuick.Controls 1.0

Rectangle {
    id: widget
    width: 445
    height: 525
    color: "#333333"
    radius: 15
    border.width: 2
    border.color: (active) ? '#3399ff' : "#666666";
    property string widgetTitle: "ICE-QT1: Temp Controller"
    property int slot: 1
    property bool active: false
    property int updateRate: 125
    property bool alternate: false
    signal error(string msg)

    onActiveChanged: {
        if (active) {
            toggleswitchActive.enableSwitch(true);
            ice.send('#pauselcd f', slot, null);

            if (stage1.status == Loader.Ready && stage2.status == Loader.Ready) {
                timer1.start();
            }
        }
        else {
            timer1.stop();
        }
    }

    function timerUpdate() {
        if (stage1.status == Loader.Ready && alternate) {
            stage1.item.update();
            alternate = !alternate;
        }
        else if (stage2.status == Loader.Ready && !alternate) {
            stage2.item.update();
            alternate = !alternate;
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

    Timer {
        id: timer1
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

    Text {
        id: textChannelA
        x: -22
        y: 132
        color: "#cccccc"
        text: "Stage 1"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        rotation: -90
        anchors.top: parent.top
        font.bold: true
        font.pointSize: 12
        font.family: "MS Shell Dlg 2"
        styleColor: "#ffffff"
        anchors.left: parent.left
        anchors.topMargin: 132
        anchors.leftMargin: -16
    }

    Rectangle {
        id: divider
        x: 5
        y: 275
        width: parent.width - 10
        height: 1
        color: "#cccccc"
        anchors.horizontalCenterOffset: 0
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Text {
        id: textChannelB
        x: -22
        y: 381
        color: "#cccccc"
        text: "Stage 2"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        anchors.top: parent.top
        rotation: -90
        font.bold: true
        font.pointSize: 12
        font.family: "MS Shell Dlg 2"
        styleColor: "#ffffff"
        anchors.left: parent.left
        anchors.leftMargin: -16
        anchors.topMargin: 381
    }

    Component {
        id: channelDisplay

        Item {
            id: channel1
            property int tempChannel: 1
            property int updateCycle: 0
            property real tempSetVal: 0.0

            onTempSetValChanged: {
                tempSet.setValue(tempSetVal);
            }

            function update() {
                getTError(tempChannel);

                updateCycle++;

                if (updateCycle == 2) {
                    getTemp(tempChannel);
                }
                else if (updateCycle == 4) {
                    getTecCurrent(tempChannel);
                    updateCycle = 0;
                }
            }

            function activate() {
                tErrorGraph.clearData();
                getTempSet(tempChannel);
                getTemp(tempChannel);
                getServo(tempChannel);
                getGain(tempChannel);
                getTecMaxCurrent(tempChannel);
                getBipolar(tempChannel);
                getTempMin(tempChannel);
                getTempMax(tempChannel);
            }

            function setTemp(channel, value) {
                ice.send('TempSet ' + channel + ' ' + value, slot, function(result){
                    //tempSet.setValue(result);
                    tempSetVal = parseFloat(result);
                });
            }

            function getTempSet(channel) {
                ice.send('TempSet? ' + channel, slot, function(result){
                    //tempSet.setValue(result);
                    tempSetVal = parseFloat(result);
                });
            }

            function getTemp(channel) {
                ice.send('Temp? ' + channel, slot, function(result){
                    tempCurrent.setValue(result);
                });
            }

            function setServo(channel, value) {
                if (value) {
                    ice.send('Servo ' + channel + ' on', slot, function(result){
                        if (result === 'On') {
                            servo.enableSwitch(true);
                        }
                        else {
                            servo.enableSwitch(false);
                        }
                    });
                }
                else {
                    ice.send('Servo ' + channel + ' off', slot, function(result){
                        if (result === 'On') {
                            servo.enableSwitch(true);
                        }
                        else {
                            servo.enableSwitch(false);
                        }
                    });
                }
            }

            function getServo(channel) {
                ice.send('Servo? ' + channel, slot, function(result){
                    if (result === 'On') {
                        servo.enableSwitch(true);
                    }
                    else {
                        servo.enableSwitch(false);
                    }
                });
            }

            function getTError(channel) {
                var success = ice.send('TError? ' + channel, slot, updateTError);
                if (!success) {
                    timer1.stop();
                    console.log('command failure');
                }
            }

            function updateTError(result){
                var error = parseFloat(result);
                if (isNaN(error)) {
                    console.log('System unresponsive.');
                    error('System Communications Error');
                    timer1.stop();
                    return;
                }
                else {
                    error = error*1000.0;
                    tempError.setValue(error);
                    tErrorGraph.addPoint(error, 0);
                }
            }

            function getTecCurrent(channel) {
                ice.send('Current? ' + channel, slot, function(result){
                    tecCurrent.setValue(result);
                });
            }

            function setTecMaxCurrent(channel, value) {
                ice.send('MaxCurr ' + channel + ' ' + value, slot, function(result){
                    tecMaxCurrentSet.setValue(result);
                });
            }

            function getTecMaxCurrent(channel) {
                ice.send('MaxCurr? ' + channel, slot, function(result){
                    tecMaxCurrentSet.setValue(result);
                });
            }

            function setGain(channel, value) {
                ice.send('Gain ' + channel + ' ' + value, slot, function(result){
                    gainSet.setValue(result);
                });
            }

            function getGain(channel) {
                ice.send('Gain? ' + channel, slot, function(result){
                    gainSet.setValue(result);
                });
            }

            function setTempMax(channel, value) {
                ice.send('TempMax ' + channel + ' ' + value, slot, function(result){
                    tempMaxSet.setValue(result);
					tempSet.maxVal = tempMaxSet.value;
                });
            }

            function getTempMax(channel) {
                ice.send('TempMax? ' + channel, slot, function(result){
                    tempMaxSet.setValue(result);
                    tempSet.maxVal = tempMaxSet.value;
                });
            }

            function setTempMin(channel, value) {
                ice.send('TempMin ' + channel + ' ' + value, slot, function(result){
                    tempMinSet.setValue(result);
					tempSet.minVal = tempMinSet.value;
                });
            }

            function getTempMin(channel) {
                ice.send('TempMin? ' + channel, slot, function(result){
                    tempMinSet.setValue(result);
                    tempSet.minVal = tempMinSet.value;
                });
            }

            function setBipolar(channel, value) {
                if (value) {
                    ice.send('BiPolar ' + channel + ' on', slot, null);
                }
                else {
                    ice.send('BiPolar ' + channel + ' off', slot, null);
                }
            }

            function getBipolar(channel) {
                ice.send('BiPolar? ' + channel, slot, function(result){
                    if (result === 'On') {
                        bipolarSwitch.enableSwitch(true);
                    }
                    else {
                        bipolarSwitch.enableSwitch(false);
                    }
                });
            }

            Column {
                id: column1
                width: 325
                height: 225

                Row {
                    id: row2
                    x: 0
                    y: 0
                    width: parent.width
                    height: 20
                    layoutDirection: Qt.LeftToRight
                    spacing: 10

                    Text {
                        id: textWidgetTitle1
                        width: 100
                        height: 20
                        color: "#ffffff"
                        text: qsTr("TSet (C)")
                        horizontalAlignment: Text.AlignHCenter
                        styleColor: "#ffffff"
                        font.bold: true
                        font.pointSize: 12
                        font.family: "MS Shell Dlg 2"
                    }

                    Text {
                        id: textWidgetTitle2
                        y: 0
                        width: 100
                        height: 20
                        color: "#ffffff"
                        text: qsTr("Temp (C)")
                        styleColor: "#ffffff"
                        font.bold: true
                        font.pointSize: 12
                        font.family: "MS Shell Dlg 2"
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        id: textWidgetTitle3
                        width: 100
                        height: 20
                        color: "#ffffff"
                        text: qsTr("TError (mK)")
                        styleColor: "#ffffff"
                        font.bold: true
                        font.pointSize: 12
                        font.family: "MS Shell Dlg 2"
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                Row {
                    id: row1
                    x: 0
                    y: 0
                    width: parent.width
                    height: 50
                    spacing: 10

                    DataInput {
                        id: tempSet
                        x: 61
                        y: 18
                        width: 100
                        height: 42
                        text: '0.0'
                        pointSize: 20
                        decimal: 1
                        precision: 5
                        minVal: 0.0
                        maxVal: 100.0
                        stepSize: 0.1
                        anchors.verticalCenter: parent.verticalCenter
                        onValueEntered: setTemp(channel1.tempChannel, newVal)
                        active: widget.active
                    }

                    Readout {
                        id: tempCurrent
                        x: 52
                        y: 16
                        width: 100
                        text: '0.000'
                        decimal: 1
                        pointSize: 20
                        background: '#000000'
                        anchors.verticalCenter: parent.verticalCenter
                        active: widget.active
                    }

                    Readout {
                        id: tempError
                        x: 57
                        y: 11
                        width: 100
                        text: "0.00"
                        precision: 2
                        background: "#000000"
                        fixedPrecision: false
                        decimal: 1
                        pointSize: 20
                        useBorder: true
                        anchors.verticalCenter: parent.verticalCenter
                        active: widget.active
                    }
                }


                Row {
                    id: row3
                    x: 0
                    y: 0
                    width: parent.width
                    height: 30
                    layoutDirection: Qt.LeftToRight
                    spacing: 10

                    Text {
                        id: textWidgetTitle4
                        width: 56
                        height: 20
                        color: "#ffffff"
                        text: qsTr("Servo:")
                        anchors.verticalCenter: parent.verticalCenter
                        styleColor: "#ffffff"
                        font.bold: true
                        font.pointSize: 12
                        font.family: "MS Shell Dlg 2"
                        horizontalAlignment: Text.AlignRight
                    }

                    ToggleSwitch {
                        id: servo
                        width: 40
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: setServo(channel1.tempChannel, enableState)
                    }

                    Text {
                        id: textWidgetTitle5
                        width: 105
                        height: 20
                        color: "#ffffff"
                        text: qsTr("TEC Current:")
                        anchors.verticalCenter: parent.verticalCenter
                        styleColor: "#ffffff"
                        font.bold: true
                        font.pointSize: 12
                        font.family: "MS Shell Dlg 2"
                        horizontalAlignment: Text.AlignRight
                    }

                    Readout {
                        id: tecCurrent
                        width: 80
                        height: 20
                        text: '0.000'
                        units: "A"
                        showUnits: true
                        decimal: 3
                        pointSize: 14
                        useBorder: false
                        anchors.verticalCenter: parent.verticalCenter
                        active: widget.active
                    }
                }

                Row {
                    id: row4
                    x: 0
                    y: 0
                    width: parent.width
                    height: 125

                    GraphComponent {
                        id: tErrorGraph
                        width: parent.width
                        height: parent.height
                        adjustableVdiv: false
                        adjustableYOffset: false
                        yMaximum: 200
                        yMinimum: -200
                        rollMode: true
                        axisXLabel: 'Time [1 s/div]'
                        axisYLabel: 'TError [50 mK/div]'
                        showYAxes: false
                    }
                }
            }

            Rectangle {
                x: 336
                width: 65
                height: 225
                color: "#202020"
                radius: 10
                border.width: 0
                border.color: "#000000"
                opacity: 1

                Column {
                    id: column2
                    anchors.fill: parent
                    spacing: 2

                    Text {
                        id: textWidgetOptions
                        width: 50
                        height: 16
                        color: "#cccccc"
                        text: qsTr("Options")
                        anchors.horizontalCenter: parent.horizontalCenter
                        styleColor: "#ffffff"
                        font.bold: true
                        font.pointSize: 10
                        font.family: "MS Shell Dlg 2"
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        id: textWidgetGain
                        width: 50
                        height: 16
                        color: "#ffffff"
                        text: qsTr("Gain:")
                        anchors.horizontalCenter: parent.horizontalCenter
                        styleColor: "#ffffff"
                        font.bold: false
                        font.pointSize: 10
                        font.family: "MS Shell Dlg 2"
                        horizontalAlignment: Text.AlignHCenter
                    }

                    DataInput {
                        id: gainSet
                        x: 0
                        y: 18
                        width: 50
                        height: 20
                        text: "50"
                        minVal: 1
                        maxVal: 255
                        background: "#333"
                        active: widget.active
                        anchors.horizontalCenter: parent.horizontalCenter
                        pointSize: 12
                        decimal: 0
                        precision: 5
                        stepSize: 1
                        onValueEntered: setGain(channel1.tempChannel, newVal)
                    }

                    Text {
                        id: textWidgetTecMaxCurrent
                        width: 50
                        height: 16
                        color: "#ffffff"
                        text: qsTr("TEC Max:")
                        anchors.horizontalCenter: parent.horizontalCenter
                        styleColor: "#ffffff"
                        font.bold: false
                        font.pointSize: 10
                        font.family: "MS Shell Dlg 2"
                        horizontalAlignment: Text.AlignHCenter
                    }

                    DataInput {
                        id: tecMaxCurrentSet
                        x: 0
                        y: 18
                        width: 50
                        height: 20
                        text: "50"
                        minVal: 0.00
                        maxVal: 1.51
                        background: "#333"
                        active: widget.active
                        anchors.horizontalCenter: parent.horizontalCenter
                        pointSize: 12
                        decimal: 2
                        precision: 5
                        stepSize: 0.1
                        onValueEntered: setTecMaxCurrent(channel1.tempChannel, newVal)
                    }

                    Text {
                        id: textWidgetBipolar
                        width: 50
                        height: 16
                        color: "#ffffff"
                        text: qsTr("Bipolar:")
                        anchors.horizontalCenter: parent.horizontalCenter
                        styleColor: "#ffffff"
                        font.bold: false
                        font.pointSize: 10
                        font.family: "MS Shell Dlg 2"
                        horizontalAlignment: Text.AlignHCenter
                    }

                    ToggleSwitch {
                        id: bipolarSwitch
                        width: 40
                        height: 20
                        anchors.horizontalCenter: parent.horizontalCenter
                        onClicked: setBipolar(channel1.tempChannel, enableState)
                    }

                    Text {
                        id: textWidgetTempMin
                        width: 50
                        height: 16
                        color: "#ffffff"
                        text: qsTr("T Min:")
                        anchors.horizontalCenter: parent.horizontalCenter
                        styleColor: "#ffffff"
                        font.bold: false
                        font.pointSize: 10
                        font.family: "MS Shell Dlg 2"
                        horizontalAlignment: Text.AlignHCenter
                    }

                    DataInput {
                        id: tempMinSet
                        x: 0
                        y: 18
                        width: 50
                        height: 20
                        text: "50"
                        minVal: 0.0
                        maxVal: 100.0
                        background: "#333"
                        active: widget.active
                        anchors.horizontalCenter: parent.horizontalCenter
                        pointSize: 12
                        decimal: 1
                        precision: 5
                        stepSize: 1
                        onValueEntered: setTempMin(channel1.tempChannel, newVal)
                    }

                    Text {
                        id: textWidgetTempMax
                        width: 50
                        height: 16
                        color: "#ffffff"
                        text: qsTr("T Max:")
                        anchors.horizontalCenter: parent.horizontalCenter
                        styleColor: "#ffffff"
                        font.bold: false
                        font.pointSize: 10
                        font.family: "MS Shell Dlg 2"
                        horizontalAlignment: Text.AlignHCenter
                    }

                    DataInput {
                        id: tempMaxSet
                        x: 0
                        y: 18
                        width: 50
                        height: 20
                        text: "50"
                        minVal: 0.0
                        maxVal: 100.0
                        background: "#333"
                        active: widget.active
                        anchors.horizontalCenter: parent.horizontalCenter
                        pointSize: 12
                        decimal: 1
                        precision: 5
                        stepSize: 1
                        onValueEntered: setTempMax(channel1.tempChannel, newVal)
                    }
                }
            }
        }
    }

    Loader {
        id: stage1
        sourceComponent: channelDisplay
        x: 33
        y: 37
        onStatusChanged: {
            if (stage1.status == Loader.Ready) {
                stage1.item.tempChannel = 1;
                stage1.item.activate();
                if (widget.active) {
                    timer1.start();
                }
            }
        }
    }

    Loader {
        id: stage2
        sourceComponent: channelDisplay
        x: 33
        y: 284
        onStatusChanged: {
            if (stage2.status == Loader.Ready) {
                stage2.item.tempChannel = 2;
                stage2.item.activate();
                if (widget.active) {                    
                    timer1.start();
                }
            }
        }
    }

    Rectangle {
        id: tempControllerOptions
        x: 240
        y: 5
        width: 140
        height: 24
        color: "#202020"
        radius: 5

        ToggleSwitch {
            id: toggleswitchActive
            x: 112
            y: 0
            width: 45
            visible: false
            anchors.verticalCenterOffset: 0
            anchors.verticalCenter: parent.verticalCenter
            textOnState: "RUN"
            offColor: "#c00000"
            textOffState: 'STOP'
            active: widget.active
            onClicked: {
                if (enableState) {
                    timer1.start();
                }
                else {
                    timer1.stop();
                }
            }
        }

        ToggleSwitch {
            id: toggleswitchChA
            y: 5
            width: 50
            anchors.verticalCenterOffset: 0
            anchors.left: textWidgetChannel.right
            anchors.leftMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            enableState: true
            active: widget.active
            textOnState: "1 & 2"
            textOffState: "1 & 2"
            onClicked: {
                if (enableState) {
                    timer1.stop();
                    stage1.item.tempChannel = 1;
                    stage1.item.activate();
                    stage2.item.tempChannel = 2;
                    stage2.item.activate();
                    toggleswitchChB.enableSwitch(false);
                    textChannelA.text = "Stage 1";
                    textChannelB.text = "Stage 2";
                    timer1.start();
                }
                else {
                    timer1.stop();
                }
            }
        }

        ToggleSwitch {
            id: toggleswitchChB
            y: 5
            width: 50
            anchors.left: toggleswitchChA.right
            anchors.leftMargin: 0
            anchors.verticalCenter: parent.verticalCenter
            textOnState: "3 & 4"
            textOffState: "3 & 4"
            active: widget.active
            onClicked: {
                if (enableState) {
                    timer1.stop();
                    stage1.item.tempChannel = 3;
                    stage1.item.activate();
                    stage2.item.tempChannel = 4;
                    stage2.item.activate();
                    toggleswitchChA.enableSwitch(false);
                    textChannelA.text = "Stage 3";
                    textChannelB.text = "Stage 4";
                    timer1.start();
                }
                else {
                    timer1.stop();
                }
            }
        }

        Text {
            id: textWidgetChannel
            x: 5
            y: 5
            height: 21.3
            color: "#ffffff"
            text: qsTr("CH:")
            anchors.verticalCenter: parent.verticalCenter
            font.bold: true
            font.family: "MS Shell Dlg 2"
            styleColor: "#ffffff"
            font.pointSize: 12
        }
		
		
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
}
