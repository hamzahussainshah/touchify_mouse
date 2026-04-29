; ─────────────────────────────────────────────────────────────
;  TouchifyMouse — Inno Setup Script
;  Used by build_windows.ps1 automatically if Inno Setup is installed
; ─────────────────────────────────────────────────────────────

; AppVersion can be overridden from the command line via Inno's /D flag,
; e.g.  iscc /DAppVersion=1.0.1  scripts\windows_installer.iss
; The CI workflow does this so version stays in sync with pubspec.yaml.
#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif

#define MyAppName      "TouchifyMouse"
#define MyAppPublisher "TouchifyMouse"
#define MyAppURL       "https://github.com/hamzahussainshah/touchify_mouse"
#define MyAppExeName   "touchifymouse_desktop.exe"
#define BuildDir       "..\build\windows\x64\runner\Release"
#define DistDir        "..\dist"

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#MyAppName}
AppVersion={#AppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir={#DistDir}
OutputBaseFilename=TouchifyMouse-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon";   Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "startupentry";  Description: "Start TouchifyMouse when Windows starts"; GroupDescription: "Startup"

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\{#MyAppName}";          Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall {#MyAppName}";Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}";    Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; \
  ValueType: string; ValueName: "{#MyAppName}"; \
  ValueData: """{app}\{#MyAppExeName}"""; \
  Flags: uninsdeletevalue; Tasks: startupentry

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; \
  Flags: nowait postinstall skipifsilent
