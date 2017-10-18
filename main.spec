# -*- mode: python -*-

block_cipher = None


#Need to include datas=[("C:\\Python35\\Lib\\site-packages\\PyQt5\\qml\\QtQuick\\Controls\\Styles",
                                     #"qml\QtQuick\Controls\Styles")
# because the ComboBox and TextField Styles are not properly copied/hooked
# in defualt pyinstaller behaviour

added_files = [("C:\\Python35\\Lib\\site-packages\\PyQt5\\qml\\QtQuick\\Controls\\Styles",
                "qml\QtQuick\Controls\Styles")]

a = Analysis(['main.py'],
             pathex=['C:\\Users\\Charlie\\Documents\\VPN00141'],
             binaries=None,
             datas=added_files,
             hiddenimports=['sip', "PyQt5.QtCore", "PyQt5.QtGui", 
             "PyQt5.QtWidgets", "PyQt5.QtQml"],
             hookspath=[],
             runtime_hooks=[],
             excludes=[],
             win_no_prefer_redirects=False,
             win_private_assemblies=False,
             cipher=block_cipher)
pyz = PYZ(a.pure, a.zipped_data,
             cipher=block_cipher)
exe = EXE(pyz,
          a.scripts,
          a.binaries,
          a.zipfiles,
          a.datas,
          name='ICE_Control',
          debug=False,
          strip=False,
          upx=True,
          console=True,
          icon='.\\ui\\vescent.ico')
