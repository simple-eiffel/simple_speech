; Simple Speech CLI Installer
; Created with Inno Setup

#define MyAppName "Simple Speech CLI"
#define MyAppVersion "1.1.0"
#define MyAppPublisher "Simple Eiffel"
#define MyAppURL "https://github.com/simple-eiffel"
#define MyAppExeName "speech_cli.exe"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
AppId={{B8C7D6E5-F4A3-4B2C-9D1E-0F8A7B6C5D4E}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\SimpleSpeech
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
; Output settings
OutputDir=..\installer_output
OutputBaseFilename=SimpleSpeech_Setup_{#MyAppVersion}
; Compression
Compression=lzma2/ultra64
SolidCompression=yes
; Appearance
WizardStyle=modern
WizardImageFile=..\..\reference_docs\artwork\logo-tall-164x314.png
WizardSmallImageFile=..\..\reference_docs\artwork\logo-small-55x58.png
; Windows version
MinVersion=10.0
; Architecture
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; Privileges
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "addtopath"; Description: "Add to PATH environment variable"; GroupDescription: "Additional options:"

[Files]
; Main executable
Source: "..\bin\speech_cli.exe"; DestDir: "{app}"; Flags: ignoreversion

; Required DLLs
Source: "..\bin\whisper.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\bin\ggml.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\bin\ggml-base.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\bin\ggml-cpu.dll"; DestDir: "{app}"; Flags: ignoreversion

; Models directory (user can add models here)
Source: "..\models\*"; DestDir: "{app}\models"; Flags: ignoreversion recursesubdirs createallsubdirs skipifsourcedoesntexist

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"

[Registry]
; Add to PATH if selected
Root: HKCU; Subkey: "Environment"; ValueType: expandsz; ValueName: "Path"; ValueData: "{olddata};{app}"; Tasks: addtopath; Check: NeedsAddPath('{app}')

[Code]
function NeedsAddPath(Param: string): boolean;
var
  OrigPath: string;
begin
  if not RegQueryStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', OrigPath) then
  begin
    Result := True;
    exit;
  end;
  Result := Pos(';' + Param + ';', ';' + OrigPath + ';') = 0;
end;

[Messages]
WelcomeLabel2=This will install [name/ver] on your computer.%n%nSimple Speech CLI is a command-line tool for speech-to-text transcription powered by Whisper.%n%nFeatures:%n- Transcribe audio/video files%n- Export to VTT, SRT, JSON, TXT%n- Detect chapter markers%n- Batch processing%n- Embed captions into video

[Run]
Filename: "{app}\{#MyAppExeName}"; Parameters: "--help"; Description: "Show CLI help"; Flags: postinstall shellexec skipifsilent nowait unchecked
