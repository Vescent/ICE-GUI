# ICE Control

This project is a GUI for controlling the [Integrated Control Electronics (ICE)][ICE] product. The program is based on 
Python 3.4 and PyQt5. For convenience, it is released as binaries as well.

The program entry point, main.py, creates a QtQuick application and sets up the QML environment with hooks for
serial communication. The application GUI and logic are contained in the QML files in the UI sub-directory. 
Serial communications are encapsulated in the iceComm.py module.

[ICE]: http://www.vescent.com/products/electronics/icetm-integrated-control-electronics/

## Current Release

The current release of ICE Control is [here](https://github.com/Vescent/ICE-GUI/releases/latest).

It includes a ZIP package with a Windows binary with additional instructions for dependencies for older OSes.

## Installation Instructions (Windows)
 
### DirectX Runtime Install (Optional)

> NOTE: This step is optional and only needs to be done if you have an older operating system and the program doesn't run.
 
 PyQt5 depends on DirectX and OpenGL for graphics and some older versions of Windows 7 or XP don't have the necessary files included.
 In this case, the user will need to run the Microsoft DirectX runtime installer before the ICE GUI will run.
 
 If the ICE GUI program fails to start, usually an update to DirectX 9.0c is needed. Download the DirectX update utility and install.
 After installation, the ICE GUI program should run.
 
 Download: [DirectX Runtime Web Installer](http://www.microsoft.com/en-US/download/details.aspx?id=35)
 
### ICE GUI

1. Download the binary zip for the ICE GUI from the [releases section](https://github.com/Vescent/ICE-GUI/releases).
2. Unzip the file to a lcoation of your choice.
3. Run ice_control.exe.

> You may edit and tweak the user interface without any development tools. The user interface files are located
in the 'ui' subfolder and can be edited with a text editor. Changes will be reflected the next time ice_control.exe
is run. The user interface is programmed using QtQuick QML and javascript.

## Setting Up the Development Environment

Setting up the environment should be needed only when you want to develop or change the ICE Control python
program. Most of the user interface is contained in the *.qml files distributed with the program and doesn't require 
a development environment setup to edit. 

The main dependencies are [Python 3.5](https://www.python.org/downloads/),
[QT5.5](http://doc.qt.io/qt-5/gettingstarted.html),
[SIP4.6](http://www.riverbankcomputing.com/software/sip/download)
and [PyQt5.6](http://www.riverbankcomputing.com/software/pyqt/download5).

### Installing on Windows
The following sections describe how to install the requirements for a development version of ICE Control on Windows.

#### Install Git

Download and install git from: https://git-scm.com/download/win

#### Install Python 3.5

Download and install Python 3.5.latest for windows from: https://www.python.org/downloads/

#### Install PyQt5.4

Download and install binary packages for Windows from: http://www.riverbankcomputing.com/software/pyqt/download5

It is possible to install PyQt5 via pip, as is suggested on the Riverbank website.  Our recommendation is to install 
PyQt5 via a distributed executable, as the pip install does not include some Qt dependencies.  These executables can be 
found at [the PyQt project on SourceForge](https://sourceforge.net/projects/pyqt/files/PyQt5/PyQt-5.6/).  Be sure to
download the executable that matches the bitness (32 vs. 64 bit) of your python install.


#### Install Python Libraries

The only required python library is PySerial version 2.5 or greater. Install using:

```pip install pyserial```


#### Clone ICE Control

Start git bash, and clone ICE Control:

```git clone https://github.com/Vescent/ICE-GUI.git```

The main program entry point is main.py. The application can be started by runnning:

```python main.py```

### Building Windows Binaries

#### Install PyInstaller

If you want to build binaries for ICE Control, install PyInstaller as detailed below:

Download and install pywin32 from http://sourceforge.net/projects/pywin32/files/pywin32/Build%20219/

> Make sure to download pywin32 for Python 3.5, 64bit or 32bit version depending on which version of Python you installed.

> In our experience, using a pip-installed PyQt5 causes problems with PyInstaller.  We recommend installing PyQt5 via
  a distributed executable as detailed above.

Clone the 'vescent' branch of PyInstaller from https://github.com/jtshugrue/pyinstaller.git. This fork of the development 
version of PyInstaller contains bug fixes to build QtQuick binaries on Windows.

```git clone https://github.com/jtshugrue/pyinstaller.git```

Extract the ZIP file.

In command prompt, navigate where pyinstaller is unzipped and run:

```python setup.py install```

#### Build

Navigate where ICE Control is cloned and run:

```pyinstaller --onefile --icon="ui\vescent.ico" --windowed --name="ice_control" main.py```

#### Copy GUI Support Files

Copy the folder "UI" to the same directory as the resulting binary from the previous step. This folder contains application resources 
such as the user interface QML files. We choose to not bundle these resources into the executable so that a user may easily tweak or 
modify the user interface without needing to recompile.

## License

Python ICE GUI is published under the [GPLv2 license](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html).
