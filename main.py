#!python3.4
__author__ = 'Vescent Photonics'
__version__ = '1.0'

# NOTE: PyQt5 depends on DirectX for doing OpenGL graphics, so
# the deployment machine may require the Microsoft DirectX runtime
# to be installed for the application to start.

import sys
import os
import ctypes

# This is to add our local site-package directory before any
# other paths for importing PyQt5 modules
dirname = os.path.dirname(__file__)
sys.path.insert(0, os.path.join(dirname, 'pkgs'))

print('Starting ICE Control GUI...')

from PyQt5.QtCore import *
from PyQt5.QtGui import QIcon
from PyQt5.QtWidgets import QApplication
from PyQt5.QtQuick import QQuickView
from PyQt5.QtQml import QJSValue
import iceComm

# Since QtCore.dll is patched to look for PyQt libraries in the location
# specified during the installation on the development machine, we must
# programmatically add the local PyQt5 site-package paths to QApplication
# before instantiating it. The plugin_path will enable QApplication to load the
# windows platform plugin qwindows.dll. However, qwindows.dll still depends
# on libEGL.dll, but doesn't seem to look in the PyQt package directory we
# set with addLibraryPath(). For now, libEGL.dll must be copied to the same
# directory that this python script executes from.
os.chdir(dirname) #change working directory so other qml relative imports work.
pyqt_path = os.path.join(dirname, 'pkgs', 'PyQt5')
plugin_path = os.path.join(pyqt_path, 'plugins')
QCoreApplication.addLibraryPath(pyqt_path) 
QCoreApplication.addLibraryPath(plugin_path) 

# Alternate way of specifying plugin path:
#os.environ['QT_QPA_PLATFORM_PLUGIN_PATH'] = os.path.join(plugin_path, 'platforms')

app = QApplication(sys.argv) 

# This is a workaround for letting python interpreter display application's
# icon instead of python's on windows.
# http://stackoverflow.com/questions/1551605/how-to-set-applications-taskbar-icon-in-windows-7/1552105#1552105
ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID('Vescent.ICE_Control')

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

		
console = PyConsole()
context.setContextProperty('PyConsole', console)

ice = iceController()
context.setContextProperty('ice', ice)

view.setSource(QUrl("qml/main.qml"))
view.show()

app.exec_()
ice.iceRef.disconnect()
sys.exit(0)