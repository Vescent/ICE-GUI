// application.js - utility functions for main.qml window
var currentWidget;
var systemDevices = [0, 0, 0, 0, 0, 0, 0, 0];
var slotButtons = [];
var debugMode = false; // Enables debugging messages
var standaloneMode = false; // Loads UI widgets without ICE box connected

function onLoad() {
	var comPorts = ice.getSerialPorts();
    slotButtons = [
        slot1btn,
        slot2btn,
        slot3btn,
        slot4btn,
        slot5btn,
        slot6btn,
        slot7btn,
        slot8btn
    ];

    for (var i = 0; i < comPorts.length; i++) {
        comPortsListModel.append( { text: comPorts[i] } );
    }

    if (standaloneMode) {
        //toggleswitchSystemPower.enableSwitch(true);
        appWindow.systemPower = true;
        loadSystemDevices();
    }
}

function serialConnect() {
    if (appWindow.serialConnected == false) {
        if (ice.serialOpen(comboComPorts.currentText)) {
            console.log('Connected to serial port ' + comboComPorts.currentText);

            ice.send('#version', 1, function(response){
                var version = response;

                console.log('ICE Master Controller Version ' + version);
                appWindow.serialConnected = true;
                buttonConnect.text = 'Disconnect';

                ice.send('#status', 1, function(response){
                    console.log('Power: ' + response);

                    if (response === 'On') {
                        //toggleswitchSystemPower.enableSwitch(true);
                        appWindow.systemPower = true;
                        loadSystemDevices();
                    }
                    else {
                        //toggleswitchSystemPower.enableSwitch(false);
                        appWindow.systemPower = false;
						appWindow.alert('ICE box power is not enabled. Send #poweron command and then reconnecting.')
                    }
                });
            });
        }
        else {
            console.log('Error connecting to serial port.');
			appWindow.alert('Error connecting to serial port.')
        }
    }
    else {
        unloadSystemDevices();
		ice.serialClose();
        appWindow.serialConnected = false;
        buttonConnect.text = 'Connect';
        console.log('Serial port disconnected.');
    }
}

function loadSlotWidget(slotNumber, deviceType) {
    var sourceFile;

    switch(deviceType) {
        case 1: sourceFile = 'TemperatureController.qml';
                break;
        case 2: sourceFile = 'PeakLockServo.qml';
                break;
        case 3: sourceFile = 'OPLS.qml';
                break;
		case 6: sourceFile = 'PB1.qml';
                break;
        default: return;
    }

    var component = Qt.createComponent(sourceFile);
    var widget = component.createObject(widgetView, {
		'slot': slotNumber
	});
    widget.error.connect(function(msg) {
        console.log(msg);
        commandResult.text = msg;
    });

    currentWidget = widget;
}

function switchSlot(slot) {
	for (var i = 0; i < slotButtons.length; i++) {
		slotButtons[i].highlight = false;
		slotButtons[i].width = 40;
	}

	slotButtons[slot - 1].highlight = true;
	slotButtons[slot - 1].width = 50;
	setSlotActive(slot);
}

function loadSystemDevices() {
    if (standaloneMode) {
        systemDevices[0] = 1;
        slotButtons[0].enabled = true;
        systemDevices[2] = 2;
        slotButtons[2].enabled = true;
        systemDevices[3] = 3;
        slotButtons[3].enabled = true;
    } else {
        ice.send('#enumerate', 1, function(response) {
            var devices = response.split(' ');

            for (var i = 0; i < devices.length; i++) {
                var devID = parseInt(devices[i]);

                if (isNaN(devID)) {
                    continue;
                }

                systemDevices[i] = devID;

                if (devID === 0) {
                    slotButtons[i].enabled = false;
                }
                else {
                    slotButtons[i].enabled = true;
                }
            }

            textSlot.color = "#fff";
            textSlot.font.bold = true;
			
			// Load first slot that has a device
			for (var i = 0; i < systemDevices.length; i++) {
				if (systemDevices[i] !== 0) {
					switchSlot(i + 1);
					break;
				}
			}
        });
    }
}

function unloadSystemDevices() {
    if (typeof(currentWidget) != 'undefined') {
        currentWidget.destroy();
    }
    for (var i = 0; i < 8; i++) {
        slotButtons[i].enabled = false;
        slotButtons[i].width = 40;
        slotButtons[i].highlight = false;
    }
}

function setSlotActive(slotNumber) {
    if (typeof(currentWidget) != 'undefined') {
        if (typeof(currentWidget.destroy) != 'undefined') {
            currentWidget.destroy();
        }
    }

    loadSlotWidget(slotNumber, systemDevices[slotNumber - 1]);
    currentWidget.active = true;
    currentSlot = slotNumber;
}

function toggleSystemPower(enable) {
    if (enable) {  
        ice.send('#poweron', 1, function(response){
			return;
        });

        appWindow.setTimeout(function(){
			ice.send('#status', 1, function(response){
                ice.getResponses();
				loadSystemDevices();
            });
        }, 8000);

        appWindow.systemPower = true;
    }
    else {
        unloadSystemDevices();
        ice.send('#poweroff', 1, null);
        appWindow.systemPower = false;
    }
}
