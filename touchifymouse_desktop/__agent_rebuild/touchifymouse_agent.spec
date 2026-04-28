# -*- mode: python ; coding: utf-8 -*-


a = Analysis(
    ['touchifymouse_agent.py'],
    pathex=[],
    binaries=[],
    datas=[('drivers/*', 'drivers')],
    hiddenimports=[
        'qrcode', 'qrcode.image.pil', 'PIL.Image',
        'sounddevice', 'numpy', '_cffi_backend',
        'AppKit', 'Quartz', 'objc',
        'zeroconf', 'pyautogui',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='touchifymouse_agent',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
