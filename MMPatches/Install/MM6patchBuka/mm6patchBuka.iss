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
OutputBaseFilename={#MM} Patch Buka v{#AppVer}

AppName=GrayFace {#MM} Patch
DefaultDirName={code:GetInstallDir}
Compression=lzma/ultra
InternalCompressLevel=ultra
SolidCompression=yes
SetupIconFile={#MM}_ICON.ico
Uninstallable=no
AppCopyright=Сергей Роженко
DisableProgramGroupPage=yes
DirExistsWarning=no
EnableDirDoesntExistWarning=yes
InfoBeforeFile="Files\{#MM}Patch ReadMe_rus.TXT"
AppendDefaultDirName=no
WizardImageFile={#MM}Install.bmp
WizardSmallImageFile=none.bmp
WizardImageStretch=no

[Languages]
Name: "ru"; MessagesFile: "compiler:Languages\Russian.isl"

[Messages]
ru.InfoBeforeLabel=Ниже приведён файл {#MM}Patch ReadMe_rus.txt, описывающий изменения патча.

[CustomMessages]
ru.LodsTask=LOD-архивы с исправлениями для конкретных карт и по ходу сюжета%nОтключите эту задачу, если Вы устанавливаете патч поверх большого мода, такого как "Заговор хаоса".

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
Source: "Files\*"; Excludes: "*.bak"; DestDir: "{app}"; Flags: ignoreversion; AfterInstall: AfterInst;
Source: "Data\*"; Excludes: "*.bak"; DestDir: "{app}\Data\"; Flags: promptifolder; Tasks: lods1 lods2;
Source: "OptFiles\*"; Excludes: "*.bak"; DestDir: "{app}"; Flags: onlyifdoesntexist recursesubdirs;

[Run]
Filename: "{app}\{#MM}Patch ReadMe_rus.TXT"; Flags: shellexec skipifdoesntexist postinstall skipifsilent;

[Code]

function GetInstallDir(param: string): string;
begin
  if not RegQueryStringValue(HKLM, 'SOFTWARE\New World Computing\Might and Magic® VI\1.0', 'AppPath', Result) then
    Result:= ExpandConstant('{pf}\Buka\MMCollection\MM_VI');
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
