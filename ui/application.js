// application.js - utility functions for main.qml window

// Settings
var debugMode = false; // Enables debugging messages
var standaloneMode = false; // Loads UI widgets without ICE box connected
var buildNumber = 1;
var programVersion = python.version + '.' + buildNumber;

// Global Variables
var currentWidget;
var slotButtons = [];
var cmdHistory = [];
var cmdHistoryIndex = 0;
var config = {
    master_ver: 0.0,
    num_devices: 0,
    devices: []
};

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
        appWindow.systemPower = true;
        loadSystemDevices();
    }
}

function serialConnect() {
    if (appWindow.serialConnected == false) {
		if (ice.serialOpen(comboComPorts.currentText) === true) {
            python.log('Connected to serial port ' + comboComPorts.currentText);

            ice.send('#version', 1, function(response){
                var version = response.split(' ');
                config.master_ver = {
                    pcb: version[0],
                    cpld: version[1],
                    mcu: version[2],
                    serial: version[3]
                };

                python.log('ICE Master Controller Version ' + response);

                appWindow.serialConnected = true;
                buttonConnect.text = 'Disconnect';
                buttonConnect.highlight = false;

                ice.send('#status', 1, function(response){
                    python.log('Power: ' + response);

                    if (response === 'On') {
                        //toggleswitchSystemPower.enableSwitch(true);
                        appWindow.systemPower = true;
                        loadSystemDevices();
                    }
                    else {
                        //toggleswitchSystemPower.enableSwitch(false);
                        appWindow.systemPower = false;
						appWindow.alert('ICE box power is not enabled. Send #poweron command and then try reconnecting.')
                    }
                });
            });
        }
        else {
			python.log('Error connecting to serial port.');
			appWindow.alert('Error connecting to serial port.');
        }
    }
    else {
        unloadSystemDevices();
		ice.serialClose();
        appWindow.serialConnected = false;
        buttonConnect.text = 'Connect';
        buttonConnect.highlight = true;
        python.log('Serial port disconnected.');
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
        case 4: sourceFile = 'SOA.qml';
                break;
        case 5: sourceFile = 'HC1.qml';
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
        python.log(msg);
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
        config.devices[0].id = 1; // ICE-QT1
        slotButtons[0].enabled = true;
        config.devices[1].id = 2; // ICE-CS1
        slotButtons[1].enabled = true;
        config.devices[2].id = 3; // ICE-CP1
        slotButtons[2].enabled = true;
        config.devices[3].id = 6; // ICE-PB1
        slotButtons[3].enabled = true;
        config.devices[4].id = 4; // ICE-DC1
        slotButtons[4].enabled = true;
    } else {
        enumerateDevices();

        textSlot.color = "#fff";
        textSlot.font.bold = true;

        // Load first slot that has a device
        for (var i = 0; i < config.num_devices; i++) {
            if (config.devices[i].id !== 0) {
                switchSlot(i + 1);
                break;
            }
        }
    }
}

function enumerateDevices() {
    ice.send('#enumerate', 1, function(response) {
        var devices = response.split(' ');
        config.num_devices = devices.length;

        for (var i = 0; i < config.num_devices; i++) {
            var devID = parseInt(devices[i]);

            if (isNaN(devID)) {
                continue;
            }

            config.devices[i] = {id: devID};

            if (devID === 0) {
                slotButtons[i].enabled = false;
            }
            else {
                slotButtons[i].enabled = true;
            }
        }
    });

    for (var i = 0; i < config.num_devices; i++) {
        if (config.devices[i].id !== 0) {
            ice.send('#version ' + (i+1).toString(), 1, function(result){
                var version = result.split(' ');
                config.devices[i].version = {
                    pcb: version[0],
                    cpld: version[1],
                    mcu: version[2],
                    serial: version[3]
                };
            });
        }
    }
}

function getAllDeviceInfo() {
    var infoStr = 'Vescent Photonics, Inc.\nWebsite: www.vescent.com\n\n';
    infoStr += 'ICE GUI Version: ' + programVersion + '\n\n';

    if (appWindow.serialConnected == false) return infoStr;

    infoStr += 'Version Info:\n';
    infoStr += 'Master: FW=' + config.master_ver.mcu;
    infoStr += ', HW=' + config.master_ver.pcb;
    infoStr += ', SN=' + config.master_ver.serial + '\n';

    for (var i = 0; i < config.num_devices; i++) {
        if (config.devices[i].id !== 0) {
            infoStr += 'Slot ' + (i+1) + ': FW=' + config.devices[i].version.mcu;
            infoStr += ', HW=' + config.devices[i].version.pcb;
            infoStr += ', SN=' + config.devices[i].version.serial + '\n';
        }
        else {
            infoStr += 'Slot ' + (i+1) + ': n/a\n';
        }
    }

    return infoStr;
}

function unloadSystemDevices() {
    if (typeof(currentWidget) != 'undefined') {
        currentWidget.active = false;
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
            currentWidget.active = false;
            currentWidget.destroy();
        }
    }

    loadSlotWidget(slotNumber, config.devices[slotNumber - 1].id);
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

function pushCmdToHistory(command) {
    if (cmdHistory[cmdHistory.length - 1] == command) {
        return;
    }

    // Restrict maximum length of array
    if (cmdHistory.length >= 20) {
        cmdHistory.shift();
    }

    cmdHistory.push(command);
    cmdHistoryIndex = cmdHistory.length - 1;
}

function getPrevCmdFromHistory() {
    if (cmdHistoryIndex > 0) {
        cmdHistoryIndex -= 1;
    }

    return cmdHistory[cmdHistoryIndex];
}

function getNextCmdFromHistory() {
    if (cmdHistoryIndex < (cmdHistory.length - 1)) {
        cmdHistoryIndex += 1;
    }

    return cmdHistory[cmdHistoryIndex];
}