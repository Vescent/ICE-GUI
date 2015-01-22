## Python GUI for ICE

This project is a GUI for communicating with [Integrated Control Electronics (ICE)][ICE]. Serial communications are encapsulated in the iceComm.py library.

[ICE]: http://www.vescent.com/products/electronics/icetm-integrated-control-electronics/

## Code Example

TBD

## Binary Installer Instructions (Windows)

The GUI relies on the PyQt5 GUI toolkit to run. To ease deployment, we've created a binary installer that will install Python 3.4.2
 (this can be skipped if the user already has a Python 3.4 install on their machine) and our Python files to a user specified
 directory. 
 
### DirectX Runtime Install
 
 PyQt5 depends on DirectX for graphics and some older versions of Windows 7 don't have the necessary files included.
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

## Contributors

TBD

## License

Python ICE GUI is published under the GPLv2 license.
