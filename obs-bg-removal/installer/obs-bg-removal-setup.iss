; ============================================================
; OBS Background Removal Plugin - Inno Setup Installer
; ============================================================
; Requires Inno Setup 6.x: https://jrsoftware.org/isinfo.php
;
; Build: Open this .iss in Inno Setup Compiler and click Build,
;        or run from command line:
;        iscc "obs-bg-removal-setup.iss"
; ============================================================

#define MyAppName      "OBS Background Removal"
#define MyAppVersion   "1.0.0"
#define MyAppPublisher "Shad3ious"
#define MyAppURL       "https://github.com/Shad3ious/shads-obs-bg-removal"
#define PluginName     "shads-obs-bg-removal"

[Setup]
AppId={{A7E3F2B1-9C4D-4E5F-8A1B-2C3D4E5F6A7B}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
DefaultDirName={code:GetOBSPath}
DirExistsWarning=no
DisableProgramGroupPage=yes
OutputDir=output
OutputBaseFilename=OBS-BG-Removal-{#MyAppVersion}-Setup
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
UninstallDisplayIcon={app}\obs-plugins\64bit\{#PluginName}.dll
UninstallDisplayName={#MyAppName} for OBS Studio
MinVersion=10.0.17763
DisableDirPage=no
UsePreviousAppDir=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Messages]
SelectDirLabel3=Select the OBS Studio installation folder. The installer has attempted to auto-detect this for you.
SelectDirBrowseLabel=If the path below is incorrect, click Browse to select your OBS Studio folder.

[Files]
; Plugin DLL
Source: "files\{#PluginName}.dll"; DestDir: "{app}\obs-plugins\64bit"; Flags: ignoreversion

; ONNX Runtime DLLs (DirectML NuGet build)
Source: "files\onnxruntime.dll"; DestDir: "{app}\obs-plugins\64bit"; Flags: ignoreversion
Source: "files\onnxruntime_providers_shared.dll"; DestDir: "{app}\obs-plugins\64bit"; Flags: ignoreversion

; Shader
Source: "files\effects\mask.effect"; DestDir: "{app}\data\obs-plugins\{#PluginName}\effects"; Flags: ignoreversion

; AI Model
Source: "files\models\rvm_mobilenetv3_fp32.onnx"; DestDir: "{app}\data\obs-plugins\{#PluginName}\models"; Flags: ignoreversion

[InstallDelete]
; Clean up old plugin name (was plugintemplate-for-obs during development)
Type: files; Name: "{app}\obs-plugins\64bit\plugintemplate-for-obs.dll"
Type: filesandordirs; Name: "{app}\data\obs-plugins\plugintemplate-for-obs"
; Clean up any leftover CUDA DLLs from earlier development builds
Type: files; Name: "{app}\obs-plugins\64bit\onnxruntime_providers_cuda.dll"
Type: files; Name: "{app}\obs-plugins\64bit\cublas64_12.dll"
Type: files; Name: "{app}\obs-plugins\64bit\cublasLt64_12.dll"
Type: files; Name: "{app}\obs-plugins\64bit\cudart64_12.dll"
Type: files; Name: "{app}\obs-plugins\64bit\cudnn64_9.dll"
Type: files; Name: "{app}\obs-plugins\64bit\cufft64_11.dll"

[UninstallDelete]
Type: files; Name: "{app}\obs-plugins\64bit\{#PluginName}.dll"
Type: files; Name: "{app}\obs-plugins\64bit\onnxruntime.dll"
Type: files; Name: "{app}\obs-plugins\64bit\onnxruntime_providers_shared.dll"
Type: filesandordirs; Name: "{app}\data\obs-plugins\{#PluginName}"

[Code]
// -------------------------------------------------------
// Auto-detect OBS Studio installation path
// -------------------------------------------------------

function GetOBSFromRegistry: String;
var
  Path: String;
begin
  Result := '';

  // Try 64-bit registry first (most common)
  if RegQueryStringValue(HKLM, 'SOFTWARE\OBS Studio', '', Path) then
  begin
    if DirExists(Path) then
    begin
      Result := Path;
      Exit;
    end;
  end;

  // Try 32-bit registry view
  if RegQueryStringValue(HKLM32, 'SOFTWARE\OBS Studio', '', Path) then
  begin
    if DirExists(Path) then
    begin
      Result := Path;
      Exit;
    end;
  end;

  // Try current user
  if RegQueryStringValue(HKCU, 'SOFTWARE\OBS Studio', '', Path) then
  begin
    if DirExists(Path) then
    begin
      Result := Path;
      Exit;
    end;
  end;
end;

function GetOBSPath(Param: String): String;
var
  RegPath: String;
begin
  // Try registry first
  RegPath := GetOBSFromRegistry;
  if RegPath <> '' then
  begin
    Result := RegPath;
    Exit;
  end;

  // Fall back to common install paths
  if DirExists(ExpandConstant('{pf}\obs-studio')) then
  begin
    Result := ExpandConstant('{pf}\obs-studio');
    Exit;
  end;

  if DirExists('C:\Program Files\obs-studio') then
  begin
    Result := 'C:\Program Files\obs-studio';
    Exit;
  end;

  // Steam
  if DirExists('C:\Program Files (x86)\Steam\steamapps\common\OBS Studio') then
  begin
    Result := 'C:\Program Files (x86)\Steam\steamapps\common\OBS Studio';
    Exit;
  end;

  // Default
  Result := ExpandConstant('{pf}\obs-studio');
end;

// -------------------------------------------------------
// Validate OBS installation
// -------------------------------------------------------
function NextButtonClick(CurPageID: Integer): Boolean;
var
  OBSExe: String;
begin
  Result := True;
  if CurPageID = wpSelectDir then
  begin
    OBSExe := AddBackslash(WizardDirValue) + 'bin\64bit\obs64.exe';
    if not FileExists(OBSExe) then
    begin
      if MsgBox(
        'OBS Studio was not found at:' + #13#10 +
        WizardDirValue + #13#10#13#10 +
        'The plugin may not work if this is not a valid OBS installation.' + #13#10#13#10 +
        'Continue anyway?',
        mbConfirmation, MB_YESNO) = IDNO then
      begin
        Result := False;
      end;
    end;
  end;
end;

// -------------------------------------------------------
// Warn if OBS is running
// -------------------------------------------------------
function IsOBSRunning: Boolean;
var
  ResultCode: Integer;
begin
  Exec('tasklist', '/FI "IMAGENAME eq obs64.exe" /NH', '',
       SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Result := (ResultCode = 0);
end;

function InitializeSetup: Boolean;
begin
  Result := True;

  if FindWindowByClassName('OBSBasic') <> 0 then
  begin
    if MsgBox(
      'OBS Studio appears to be running.' + #13#10#13#10 +
      'Please close OBS before installing to avoid file conflicts.' + #13#10#13#10 +
      'Continue anyway?',
      mbConfirmation, MB_YESNO) = IDNO then
    begin
      Result := False;
    end;
  end;
end;

function InitializeUninstall: Boolean;
begin
  Result := True;

  if FindWindowByClassName('OBSBasic') <> 0 then
  begin
    MsgBox(
      'OBS Studio appears to be running.' + #13#10#13#10 +
      'Please close OBS before uninstalling.',
      mbError, MB_OK);
    Result := False;
  end;
end;
