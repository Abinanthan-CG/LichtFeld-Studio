; Inno Setup Script for LichtFeld Studio
; Builds a complete Windows Release Installer (.exe)

#ifndef MyAppVersion
  #define MyAppVersion "0.5.5"
#endif

#ifndef SourceRootDir
  #define SourceRootDir "."
#endif

#define MyAppName "LichtFeld Studio"
#define MyAppPublisher "LichtFeld Studio Authors"
#define MyAppURL "https://lichtfeld.io"
#define MyAppExeName "LichtFeld-Studio.exe"

[Setup]
AppId={{C6B5E863-7DA9-4F5B-B73B-15D39D11462E}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL="https://discord.gg/TbxJST2BbC"
AppUpdatesURL="https://portal.lichtfeld.io/"
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
LicenseFile={#SourceRootDir}\LICENSE
OutputDir={#SourceRootDir}\installer_output
OutputBaseFilename=LichtFeld-Studio-v{#MyAppVersion}-Setup-x64
SetupIconFile={#SourceRootDir}\resources\icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequiredOverridesAllowed=dialog
PrivilegesRequired=lowest

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#SourceRootDir}\dist\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\bin\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\bin\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\bin\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
