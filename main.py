#!python3.4
__author__ = 'Vescent Photonics'
__version__ = '1.0'

# NOTE: PyQt5 depends on DirectX for doing OpenGL graphics, so
# the deployment machine may require the Microsoft DirectX runtime
# to be installed for the application to start.

import sys
import os
from PyQt5.QtCore import *
from PyQt5.QtGui import QIcon
from PyQt5.QtWidgets import QApplication
from PyQt5.QtQuick import QQuickView
from PyQt5.QtQml import QJSValue
import iceComm

class PyConsole(QObject):
    @pyqtSlot(str)
    def log(self, s):
        print(s)

class iceController(QObject):
    def __init__(self):
        super().__init__()
        self.slot = 0
        self._logging = False
        self.iceRef = iceComm.Connection(logging=False)

    @pyqtSlot(int)
    def setSlot(self, slot):
        if slot != self.slot:
            self.iceRef.send('#slave ' + str(slot))
            self.slot = slot

    @pyqtSlot(str, int, 'QJSValue', result=str)
    def send(self, command, slot, callback):        
        if slot != self.slot:
            self.iceRef.send('#slave ' + str(slot))
            self.slot = slot
        
        data = self.iceRef.send(command)
        #print(data[:9])
        if data[:9] == 'I2C Error':
            print('Error I2c!!!')
            return
        if callback.isCallable():
            callback.call({data})
            
        return data
        
    @pyqtSlot(str, 'QJSValue')
    def enqueue(self, command, callback):
        self.iceRef.send(command, blocking=False, callback=QJSValue(callback))
        return

    @pyqtSlot()
    def processResponses(self):        
        responses = self.iceRef.get_all_responses()
        
        for response in responses:
            cbFunc = response.get('callback', None)
            
            if cbFunc is not None:
                self.callback = cbFunc
                
                if cbFunc.isCallable():
                    cbFunc.call({response['result'].rstrip()})
    
        return
        
    @pyqtSlot()
    def getResponses(self):
        responses = self.iceRef.get_all_responses()
        if len(responses) > 0:
            return responses[0]['callback']
        
    @pyqtSlot(str, result=bool)
    def serialOpen(self, portname):
        result = self.iceRef.connect(portname, timeout=0.5)
        if result is None:
            return True
        else:
            return False
            
    @pyqtSlot(bool)
    def setLogging(self, enabled):
        self.iceRef.logging = enabled
        self._logging = enabled
        
    @pyqtProperty(bool)
    def logging(self):
        return self._logging
            
    @pyqtSlot()
    def serialClose(self):
        self.iceRef.disconnect()

    @pyqtSlot(result='QVariant')
    def getSerialPorts(self):
        ports = self.iceRef.list_serial_ports()
        portnames = []
        for port in ports:
            portnames.append(port[0])
            
        return portnames

def main():		
    app = QApplication(sys.argv) 

    app_name = 'ICE Control'
    app.setOrganizationName("Vescent Photonics, Inc.")
    app.setOrganizationDomain("www.vescent.com")
    app.setApplicationName(app_name)
    app.setWindowIcon(QIcon("vescent.ico"))

    view = QQuickView()

    # The QML import paths also need to be changed to our local site-package paths,
    # otherwise our qml files won't be able to import QtQuick by the qml interpreter.
    qml_path = os.path.join(pyqt_path, 'qml')
    view.engine().addImportPath(qml_path)
    view.setTitle(app_name)

    context = view.rootContext()
    
    console = PyConsole()
    context.setContextProperty('PyConsole', console)

    ice = iceController()
    context.setContextProperty('ice', ice)

    view.setSource(QUrl("qml/main.qml"))
    view.show()

    app.exec_()
    ice.iceRef.disconnect()
    sys.exit(0)
    
if __name__ == "__main__":
    main()
