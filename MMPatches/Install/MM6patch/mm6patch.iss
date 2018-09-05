#define m() "mm6"
#define MM() "MM6"
#define AppDll() AddBackslash(SourcePath) + "Files\" + MM() + "patch.dll"
#define AppVersion() GetFileVersion(AppDll())
#define AppVer() \
  ParseVersion(AppDll(), Local[0], Local[1], Local[2], Local[3]), \
  Str(Local[0])+"."+Str(Local[1])+((Local[2] || Local[3]) ? "."+Str(Local[2]) : "")+(Local[3] ? "."+Str(Local[3]) : "")

[Setup]
VersionInfoVersion={#AppVersion}
AppVerName=GrayFace {#MM} Patch v{#AppVer}
OutputBaseFilename={#MM} Patch v{#AppVer}

AppName=GrayFace {#MM} Patch {#AppVer}  
DefaultDirName={code:GetInstallDir}
Compression=lzma/ultra
InternalCompressLevel=ultra
SolidCompression=yes
SetupIconFile={#MM}_ICON.ico
Uninstallable=no
AppCopyright=Sergey Rozhenko
DisableProgramGroupPage=yes
DirExistsWarning=no
EnableDirDoesntExistWarning=yes
InfoBeforeFile="Files\{#MM}Patch ReadMe.TXT"
AppendDefaultDirName=no
WizardImageFile={#MM}Install.bmp
WizardSmallImageFile=none.bmp
WizardImageStretch=no

[Messages]
InfoBeforeLabel=Below is the content of {#MM}Patch ReadMe.txt file detailing all changes of the patch.

[CustomMessages]
LodsTask=Install LOD archives with fixes for particular maps and game progression%nUncheck this task if you are installing the patch over a big mod like The Chaos Conspiracy.

[Tasks]
Name: lods1; Description: {cm:LodsTask}; Check: LodsTaskCheck(true);
Name: lods2; Description: {cm:LodsTask}; Flags: unchecked; Check: LodsTaskCheck(false);

[InstallDelete]
Type: files; Name: "{app}\MSS32.DLL";
Type: files; Name: "{app}\MSS32.NEW";
Type: files; Name: "{app}\SmackW32.dll";
Type: files; Name: "{app}\SmackW32.NEW";
Type: files; Name: "{app}\MP3DEC.ASI";

[Files]
Source: "Files\*"; Excludes: "*.bak"; DestDir: "{app}"; Flags: promptifolder ignoreversion; AfterInstall: AfterInst;
Source: "Data\*"; Excludes: "*.bak"; DestDir: "{app}\Data\"; Flags: promptifolder; Tasks: lods1 lods2;
Source: "OptFiles\*"; Excludes: "*.bak"; DestDir: "{app}"; Flags: onlyifdoesntexist recursesubdirs;

[Run]
Filename: "{app}\{#MM}Patch ReadMe.TXT"; Flags: shellexec skipifdoesntexist postinstall skipifsilent;

[Code]

function GetInstallDir(param: string): string;
begin
  if not RegQueryStringValue(HKLM, 'SOFTWARE\New World Computing\Might and Magic® VI\1.0', 'AppPath', Result) then
    Result:= ExpandConstant('{pf}\Might and Magic VI');
end;


function CheckVer(ver: Cardinal): Boolean;
var
  ms, ls: Cardinal;
begin
  Result:= GetVersionNumbers(ExpandConstant('{app}\{#m}patch.dll'), ms, ls) and (ms >= ver);
end;


var
  PatchLods, PatchLodsChecked: Boolean;

function LodsTaskCheck(checked: Boolean): Boolean;
begin
  if not PatchLodsChecked then
    if CheckVer($20001) then
      PatchLods:= FileExists(ExpandConstant('{app}\Data\00 patch.games.lod'))
    else
      PatchLods:= GetIniBool('Install', 'PatchLods', true, ExpandConstant('{app}\{#m}.ini'));
  PatchLodsChecked:= true;
  Result:= (PatchLods = checked);
end;


procedure AfterInst;
begin
  if GetIniString('Install', 'PatchLods', #13#10, ExpandConstant('{app}\{#m}.ini')) <> #13#10 then 
    DeleteIniEntry('Install', 'PatchLods', ExpandConstant('{app}\{#m}.ini'))
end;
