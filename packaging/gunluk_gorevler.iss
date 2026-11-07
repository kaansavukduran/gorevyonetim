; Inno Setup script for the Günlük Görevler Windows installer.
; Built on a Windows host by .github/workflows/windows.yml;
; never built here. The app keeps its data under %APPDATA%\GunlukGorevler,
; outside the install folder, so uninstalling does not delete any task.
#define AppName "Günlük Görevler"
#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif

[Setup]
AppId={{3C1D5B2E-7A44-4F0B-9E61-5D2B8C9A0F17}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher=Günlük Görevler
DefaultDirName={autopf}\Gunluk Gorevler
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=..\dist
OutputBaseFilename=Gunluk-Gorevler-Kurulum
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\gunluk_gorevler.exe

[Languages]
Name: "turkish"; MessagesFile: "compiler:Languages\Turkish.isl"

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\gunluk_gorevler.exe"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\gunluk_gorevler.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Masaüstüne kısayol oluştur"; GroupDescription: "Kısayollar:"

[Run]
Filename: "{app}\gunluk_gorevler.exe"; Description: "Günlük Görevler'i aç"; Flags: nowait postinstall skipifsilent
