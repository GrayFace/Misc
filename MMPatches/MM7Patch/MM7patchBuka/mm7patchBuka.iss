#define m() "mm7"
#define MM() "MM7"
#define AppDll() AddBackslash(SourcePath) + "Files\" + MM() + "patch.dll"
#define AppVersion() GetFileVersion(AppDll())
#define AppVer() \
  ParseVersion(AppDll(), Local[0], Local[1], Local[2], Local[3]), \
  Str(Local[0])+"."+Str(Local[1])+((Local[2] || Local[3]) ? "."+Str(Local[2]) : "")+(Local[3] ? "."+Str(Local[3]) : "")
#define DragonMD5() GetMD5OfFile(AddBackslash(SourcePath) + "OptData\01 dragon.games.lod")
#define TunnelsMD5() GetMD5OfFile(AddBackslash(SourcePath) + "OptData\01 tunnels.events.lod")

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
ru.LodGroup=Отключите эти задачи, если Вы устанавливаете патч поверх большого мода, такого как BDJ Rev4 mod:
ru.LodsTask=Установить LOD-архивы с исправлениями для конкретных карт и по ходу сюжета
ru.TunnelsTask=Исправить путаницу со входами в Гору Громовой Кулак, добавить видеозаставки при переходе в другие подземелья из неё
ru.DragonTask=Заменить ослабленного обычного дракона с именем "Мегадракон" в Пещерах драконов в Эофоле на настоящего магадракона

[Tasks]
Name: lods1; Description: {cm:LodsTask}; GroupDescription: {cm:LodGroup}; Check: LodsTaskCheck(true);
Name: lods2; Description: {cm:LodsTask}; GroupDescription: {cm:LodGroup}; Flags: unchecked; Check: LodsTaskCheck(false);
Name: tun1; Description: {cm:TunnelsTask}; GroupDescription: {cm:LodGroup}; Check: TunnelTaskCheck(true);
Name: tun2; Description: {cm:TunnelsTask}; GroupDescription: {cm:LodGroup}; Flags: unchecked; Check: TunnelTaskCheck(false);
Name: dragon1; Description: {cm:DragonTask}; GroupDescription: {cm:LodGroup}; Check: DragonTaskCheck(true);
Name: dragon2; Description: {cm:DragonTask}; GroupDescription: {cm:LodGroup}; Flags: unchecked; Check: DragonTaskCheck(false);

; Delete SafeDisk files
[InstallDelete]
Type: files; Name: "{app}\00000001.TMP";
Type: files; Name: "{app}\clcd16.dll";
Type: files; Name: "{app}\clcd32.dll";
Type: files; Name: "{app}\clokspl.exe";
Type: files; Name: "{app}\dplayerx.dll";
Type: files; Name: "{app}\drvmgt.dll";
Type: files; Name: "{app}\secdrv.sys";
Type: files; Name: "{app}\{#MM}.ICD";

[Files]
Source: "Files\*.*"; Excludes: "*.bak"; DestDir: "{app}"; Flags: ignoreversion; AfterInstall: AfterInst;
Source: "Data\*"; Excludes: "*.bak"; DestDir: "{app}\Data\"; Flags: promptifolder; Tasks: lods1 lods2;
Source: "OptData\01 dragon.games.lod"; DestDir: "{app}\Data\"; Flags: promptifolder; Tasks: dragon1 dragon2;
Source: "OptData\01 tunnels.events.lod"; DestDir: "{app}\Data\"; Flags: promptifolder; Tasks: tun1 tun2;
Source: "OptFiles\*"; Excludes: "*.bak"; DestDir: "{app}"; Flags: onlyifdoesntexist recursesubdirs;

[Run]
Filename: "{app}\{#MM}Patch ReadMe_rus.TXT"; Flags: shellexec skipifdoesntexist postinstall skipifsilent;

[Code]

function GetInstallDir(param: string): string;
begin
  if not RegQueryStringValue(HKLM, 'SOFTWARE\New World Computing\Might and Magic VII\1.0', 'AppPath', Result) then
    Result:= ExpandConstant('{pf}\Buka\MMCollection\MM_VII');
end;

function GetTaskDescription(param: string): string;
begin
  Result:= 'Установить LOD-архивы патча'
  +#13#10'Они содержат множество исправлений для конкретных карт и по ходу сюжета.'
  +#13#10'Отключите эту задачу, если Вы устанавливаете патч поверх большого мода, такого как BDJ Rev4 mod.';
end;


function CheckVer(ver: Cardinal): Boolean;
var
  ms, ls: Cardinal;
begin
  Result:= GetVersionNumbers(ExpandConstant('{app}\{#m}patch.dll'), ms, ls) and (ms >= ver);
end;

function CheckOptLod(var Task, TaskChecked: Boolean; path, md5: string; checked: Boolean): Boolean;
var
  exist: Boolean;
begin
  exist:= FileExists(path);
  if not exist or (GetMD5OfFile(path) <> md5) then
  begin
    if not TaskChecked then
      Task:= exist or not CheckVer($20001);
    TaskChecked:= true;
    Result:= (Task = checked);
  end else
    Result:= false;
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


var
  DragonTask, DragonTaskChecked: Boolean;

function DragonTaskCheck(checked: Boolean): Boolean;
begin
  Result:= CheckOptLod(DragonTask, DragonTaskChecked, ExpandConstant('{app}\Data\01 dragon.games.lod'), '{#DragonMD5}', checked);
end;


var
  TunnelTask, TunnelTaskChecked: Boolean;

function TunnelTaskCheck(checked: Boolean): Boolean;
begin
  Result:= CheckOptLod(TunnelTask, TunnelTaskChecked, ExpandConstant('{app}\Data\01 tunnels.events.lod'), '{#TunnelsMD5}', checked);
end;


procedure AfterInst;
begin
  if GetIniString('Install', 'PatchLods', #13#10, ExpandConstant('{app}\{#m}.ini')) <> #13#10 then 
    DeleteIniEntry('Install', 'PatchLods', ExpandConstant('{app}\{#m}.ini'))
end;
