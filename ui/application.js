/*
 * application.js - utility functions for main.qml window
 */

// Settings
var debugMode = false; // Enables debugging messages
var standaloneMode = false; // Loads UI widgets without ICE box connected
var buildNumber = 0;
var programVersion = python.version + '.' + buildNumber;
var apiURL = 'http://www.vescent.com/api/ice.xml'; // URL to check for program updates
var updateUrl = 'https://github.com/Vescent/ICE-GUI/releases/latest' // Default URL for program download

// Global Variables
var currentWidget;
var slotButtons = [];
var cmdHistory = []; // Holds history of user commands entered
var cmdHistoryIndex = 0;
var config = {
    master_ver: 0.0,
    num_devices: 0,
    devices: [],
	icegui: {
		latestVersion: '0.0.0',
		updateUrl: updateUrl,
		data: {}
	}
};

// Called when main QML file has loaded.
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
	
	// Get latest config data from web server
	config.icegui.data = python.getXML(apiURL);
	
	if (config.icegui.data.hasOwnProperty('icegui')) {
		if (config.icegui.data.icegui.hasOwnProperty('latest')) {
			if (config.icegui.data.icegui.latest.hasOwnProperty('version')) {
				config.icegui.latestVersion = config.icegui.data.icegui.latest.version;
			}
			
			if (config.icegui.data.icegui.latest.hasOwnProperty('url')) {
				config.icegui.updateUrl = config.icegui.data.icegui.latest.url;
			}
		}
	}
	
	if (checkForUpdate()) {
		appWindow.showUpdateText();
	}
}

function checkForUpdate() {
	var newVerInfo = config.icegui.latestVersion.split('.');
	var currVerInfo = programVersion.split('.');
	
	for (var i = 0; i < currVerInfo.length; i++) {
		var newVer = parseInt(newVerInfo[i]);
		var currVer = parseInt(currVerInfo[i]);
		if (newVer > currVer) {
			return true;
		}
	}
	
	return false;
}

function showProgramUpdateMsg() {
	var info = config.icegui;
	
	if (info.error == true) {
		return;
	}
	
	var message = 'A newer version of the program is available to download.<br/><br/>';
	message += 'Current Version: ' + programVersion + '<br/>';
	message += 'Latest Version: ' + info.latestVersion + '<br/><br/>';
	message += '<b>Download new version here:</b><br/>';
	message += '<a href="' + info.url + '">' + info.updateUrl + '</a>';
	appWindow.alert(message, 'Program Update');
}

function serialConnect() {
    if (appWindow.serialConnected == false) {
		if (ice.serialOpen(comboComPorts.currentText) === true) {
            python.log('Connected to serial port ' + comboComPorts.currentText);

            // Send version command to see if an ICE box is responding on serial port.
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

                // Check to see if ICE box system power is on to daughter boards
                ice.send('#status', 1, function(response){
                    python.log('Power: ' + response);

                    if (response === 'On') {
                        appWindow.systemPower = true;
                        loadSystemDevices();
                    }
                    else {
                        appWindow.systemPower = false;
						appWindow.alert('ICE box power not enabled. Send #poweron command and then try reconnecting.')
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
        case 3: sourceFile = 'OPL1.qml';
                break;
        case 4: sourceFile = 'SOA.qml';
                break;
        case 5: sourceFile = 'HC1.qml';
                break;
		case 6: sourceFile = 'PB1.qml';
                break;
        case 9: sourceFile = 'OPL1.qml';
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
        config.num_devices = 8;
        for (var i = 0; i < config.num_devices; i++) {
            config.devices[i] = {id: (i+1)};
            slotButtons[i].enabled = true;
        }
    } else {
        enumerateDevices();

        textSlot.color = "#fff";
        textSlot.font.bold = true;

        // Load first slot that has a device
        // for (var i = 0; i < config.num_devices; i++) {
        //     if (config.devices[i].id !== 0) {
        //         switchSlot(i + 1);
        //         break;
        //     }
        // }
    }
}

// Queries ID and version of all ICE daughterboards
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

            // Get version information for each daughterboard
            ice.send('#version ' + (i+1), 1, function(result){
                var version = result.split(' ');
                config.devices[i].version = {
                    pcb: version[0],
                    cpld: version[1],
                    mcu: version[2],
                    serial: version[3]
                };
            });
        }
    });
}

// Returns displayable string for an about box
function getAllDeviceInfo() {
    var newerAvail = checkForUpdate();
	if (newerAvail === true) {
		appWindow.showUpdateText();
	}
	
	var infoStr = '<b>ICE GUI Version:</b> ' + programVersion;
	if (newerAvail === true) {
		infoStr += ' <a href="https://github.com/Vescent/ICE-GUI/releases/latest">Update Available</a>';
	}
	infoStr += '<br/><br/>';
    infoStr += '<b>Vescent Photonics, Inc.</b><br/>';
    infoStr += 'Website: <a href="http://www.vescent.com">www.vescent.com</a><br/>';
    infoStr += 'Manual: <a href="http://www.vescent.com/manuals/doku.php?id=ice">http://www.vescent.com/manuals/doku.php?id=ice</a><br/>';
    infoStr += 'Source Code: <a href="https://github.com/Vescent/ICE-GUI">https://github.com/Vescent/ICE-GUI</a><br/>';
    infoStr += 'Latest Release: <a href="' + updateUrl + '">';
    infoStr += updateUrl + '</a>';

    if (appWindow.serialConnected == false) return infoStr;

    infoStr += '<br/><br/><b>Hardware Version Info:</b><br/>';
    infoStr += 'Master: FW=' + config.master_ver.mcu;
    infoStr += ', HW=' + config.master_ver.pcb;
    infoStr += ', SN=' + config.master_ver.serial;

    for (var i = 0; i < config.num_devices; i++) {
        if (config.devices[i].id !== 0) {
            infoStr += '<br/>Slot ' + (i+1) + ': FW=' + config.devices[i].version.mcu;
            infoStr += ', HW=' + config.devices[i].version.pcb;
            infoStr += ', SN=' + config.devices[i].version.serial;
        }
        else {
            infoStr += '<br/>Slot ' + (i+1) + ': n/a';
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