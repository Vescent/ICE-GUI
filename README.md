# ICE Control

This project is a GUI for controlling the [Integrated Control Electronics (ICE)][ICE] product. The program is based on 
Python 3.4 and PyQt5. 

The program entry point, main.py, creates a QtQuick application and sets up the QML environment with hooks for
serial communication. The application GUI and logic are contained in the QML files in the UI sub-directory. 
Serial communications are encapsulated in the iceComm.py module.

[ICE]: http://www.vescent.com/products/electronics/icetm-integrated-control-electronics/

## Current Release

The current release of ICE Control is [1.0](https://github.com/Vescent/ICE-GUI/releases/tag/v1.0).

It includes a ZIP package with a Windows binary with additional instructions for dependencies for older OSes.

## Binary Installer Instructions (Windows)
 
### DirectX Runtime Install
 
 PyQt5 depends on DirectX for graphics and some older versions of Windows 7 or XP don't have the necessary files included.
 In this case, the user will need to run the Microsoft DirectX runtime installer before the ICE GUI will run.
 
 If the ICE GUI program fails to start, usually an update to DirectX 9.0c is needed. Download the DirectX update utility and install.
 After installation, the ICE GUI program should run.
 
 Download: [DirectX Runtime Web Installer](http://www.microsoft.com/en-US/download/details.aspx?id=35)
 
 There is also a copy of the full update utility located in the [releases section](https://github.com/Vescent/ICE-GUI/releases).
 When running the installer, it will ask for a temporary location to decompress the files to. Once this is done, go to that folder
 and run the setup.exe file to finish the install.
 
### ICE GUI Installer

1. Download the binary installer for the ICE GUI from the [releases section](https://github.com/Vescent/ICE-GUI/releases).
2. Run the installer and click Next.
3. You may uncheck "Python 3.4.2" if you already have Python 3.4 installed on your system.
4. Choose a location for the install. It doesn't necessarily have to be in Program Files, any folder will work.
5. The installer will place a shortcut to ICE Control in your Start Menu programs. Use this to run the program.

The ICE GUI program may be uninstalled by using the Windows Add-Remove programs tool in the Control Panel.

## Setting Up the Development Environment

> NOTE: Setting up the environment should be needed only when you want to develop or change ICE Control itself. 

The main dependencies are Python 3.4,
[QT5.4](http://doc.qt.io/qt-5/gettingstarted.html),
[SIP4.6](http://www.riverbankcomputing.com/software/sip/download)
and [PyQt5.4](http://www.riverbankcomputing.com/software/pyqt/download5).

### Installing on Windows
The following sections describe how to install the requirements for a development version of ICE Control on Windows.

#### Install Git

Download and install git from: https://git-scm.com/download/win

#### Install Python 3.4

Download and install Python 3.4.latest for windows from: https://www.python.org/downloads/

#### Install PyQt5.4

Download and install binary packages for Windows from: http://www.riverbankcomputing.com/software/pyqt/download5

#### Install Python Libraries

The only required python library is PySerial version 2.5 or greater. Install using:

```pip install pyserial```

#### Clone ICE Control

Start git bash, and clone ICE Control:

```git clone https://github.com/Vescent/ICE-GUI.git```

### Building Windows Binaries

If you want to build binaries for ICE Control, install PyInstaller as detailed below:

Download and install pywin32 from http://sourceforge.net/projects/pywin32/files/pywin32/Build%20219/

> Make sure to download pywin32 for Python 3.4, 64bit or 32bit version depending on which version of Python you installed.

Download the python3 branch of pyinstaller https://github.com/pyinstaller/pyinstaller/tree/python3

Extract the ZIP file.

In command prompt, navigate where pyinstaller is unzipped and run:

```python setup.py install```

Navigate where ICE Control is cloned and run:

```pyinstaller --clean main.spec```

## Contributors

TBD

## License

Python ICE GUI is published under the GPLv2 license.
