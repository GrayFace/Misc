#define loc (en && ru)
#define m() "mm7"
#define MM() "MM7"
#define AppDll() AddBackslash(SourcePath) + "Files\" + MM() + "patch.dll"
#define AppVersion() GetFileVersion(AppDll())
#define AppVer() \
  ParseVersion(AppDll(), Local[0], Local[1], Local[2], Local[3]), \
  Str(Local[0])+"."+Str(Local[1])+((Local[2] || Local[3]) ? "."+Str(Local[2]) : "")+(Local[3] ? "."+Str(Local[3]) : "")
#define DragonMD5() GetMD5OfFile(AddBackslash(SourcePath) + "OptData\01 dragon.games.lod")
#define TunnelsMD5() GetMD5OfFile(AddBackslash(SourcePath) + "OptData\01 tunnels.events.lod")
#define WaterMD5() GetMD5OfFile(AddBackslash(SourcePath) + "OptData\00 patch.bitmaps.lod")
#define IconsMD5() GetMD5OfFile(AddBackslash(SourcePath) + "OptData\00 patch.icons.lod")

[Setup]
VersionInfoVersion={#AppVersion}
AppVerName=GrayFace {#MM} Patch v{#AppVer}
#if loc
OutputBaseFilename={#MM} Patch Loc v{#AppVer}
#elif en
OutputBaseFilename={#MM} Patch v{#AppVer}
#else
OutputBaseFilename={#MM} Patch Buka v{#AppVer}
#endif

AppName=GrayFace {#MM} Patch
DefaultDirName={code:GetInstallDir}
Compression=lzma/ultra
InternalCompressLevel=ultra
SolidCompression=yes
SetupIconFile={#MM}_ICON.ico
Uninstallable=no
#if en
AppCopyright=Sergey Rozhenko
#else
AppCopyright=Сергей Роженко
#endif
DisableProgramGroupPage=yes
DirExistsWarning=no
EnableDirDoesntExistWarning=yes
#if loc
InfoBeforeFile="eng\{#MM}Patch ReadMe.TXT"
#elif en
InfoBeforeFile="Files\{#MM}Patch ReadMe.TXT"
#else
InfoBeforeFile="Files\{#MM}Patch ReadMe_rus.TXT"
#endif
AppendDefaultDirName=no
WizardImageFile={#MM}Install.bmp
WizardSmallImageFile=none.bmp
WizardImageStretch=no

[Languages]
#if en
Name: "en"; MessagesFile: "compiler:Default.isl";
#endif
#if loc
Name: "ru"; MessagesFile: "compiler:Languages\Russian.isl"; InfoBeforeFile: "rus\{#MM}Patch ReadMe_rus.TXT";
#elif ru
Name: "ru"; MessagesFile: "compiler:Languages\Russian.isl";
#endif

[Messages]
#if en
InfoBeforeLabel=Below is the content of {#MM}Patch ReadMe.txt file detailing all changes of the patch.
#endif
#if ru
ru.InfoBeforeLabel=Ниже приведён файл {#MM}Patch ReadMe_rus.txt, описывающий изменения патча.
#endif

[CustomMessages]
#if loc
RussianGameVersion=Russian version of the game
ru.RussianGameVersion=Русская версия игры
#endif
#if en
LodGroup=Uncheck these tasks if you are installing the patch over a big mod like BDJ''s Rev4 mod:
LodsTask=Install LOD archives with fixes for particular maps and game progression
TunnelsTask=Fix Thunderfist Mountain entrances mismatch, add videos to exits from it into different dungeons
DragonTask=Make "Mega-Dragon" in The Dragon Caves in Eeofol a real mega-dragon instead of a weakened regular dragon
WaterTask=Use improved water animation
IconsTask=Install LOD archive with interface fixes%nUncheck this task if you are installing the patch over a mod that recolors interface.
UITask=Use widescreen-friendly flexible interface
#endif
#if ru
ru.LodGroup=Отключите эти задачи, если Вы устанавливаете патч поверх большого мода, такого как BDJ Rev4 mod:
ru.LodsTask=LOD-архивы с исправлениями для конкретных карт и по ходу сюжета
ru.TunnelsTask=Исправить путаницу со входами в Гору Громовой Кулак, добавить видеозаставки при переходе в другие подземелья из неё
ru.DragonTask=Заменить ослабленного обычного дракона с именем "Мегадракон" в Пещерах драконов в Эофоле на настоящего магадракона
ru.WaterTask=Использовать улучшенную анимацию воды
ru.IconsTask=Установить LOD-архив с исправлениями для интерфейса%nОтключите эту задачу, если Вы устанавливаете патч поверх мода, перекрашивающего интерфейс.
ru.UITask=Включить гибкий интерфейс, адаптированный для широкоэкранников
#endif

[Tasks]
#if loc
Name: RusFiles1; Description: {cm:RussianGameVersion}; Check: RussianTaskCheck(true);
Name: RusFiles2; Description: {cm:RussianGameVersion}; Flags: unchecked; Check: RussianTaskCheck(false);
#endif
Name: ui1; Description: {cm:UITask}; Check: UITaskCheck(true);
Name: ui2; Description: {cm:UITask}; Flags: unchecked; Check: UITaskCheck(false);
Name: icons1; Description: {cm:IconsTask}; Check: IconsTaskCheck(true);
Name: icons2; Description: {cm:IconsTask}; Flags: unchecked; Check: IconsTaskCheck(false);
Name: water1; Description: {cm:WaterTask}; Check: WaterTaskCheck(true);
Name: water2; Description: {cm:WaterTask}; Flags: unchecked; Check: WaterTaskCheck(false);
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
#define FlagsOlder (loc ? "Flags: promptifolder;" : "")
#define FlagOlder (loc ? "promptifolder" : "")
Source: "Files\*.*"; Excludes: "*.bak"; DestDir: "{app}"; Flags: {#FlagOlder} ignoreversion; AfterInstall: AfterInst;
Source: "Data\*"; Excludes: "*.bak"; DestDir: "{app}\Data\"; {#FlagsOlder} Tasks: lods1 lods2;
Source: "OldWater\00 patch.bitmaps.lod"; DestDir: "{app}\Data\"; Check: OldWaterCheck;
Source: "OptData\01 dragon.games.lod"; DestDir: "{app}\Data\"; Flags: promptifolder; Tasks: dragon1 dragon2;
Source: "OptData\01 tunnels.events.lod"; DestDir: "{app}\Data\"; {#FlagsOlder} Tasks: tun1 tun2;
Source: "OptData\00 patch.bitmaps.lod"; DestDir: "{app}\Data\"; Tasks: water1 water2;
Source: "OptData\00 patch.icons.lod"; DestDir: "{app}\Data\"; Tasks: icons1 icons2;
Source: "OptFiles\*"; Excludes: "*.bak"; DestDir: "{app}"; Flags: onlyifdoesntexist recursesubdirs;
#if loc
Source: "tmp\*.*"; DestDir: "{tmp}"; Flags: deleteafterinstall; Tasks: lods1 lods2 tun1 tun2;
Source: "tmpRU\*.*"; DestDir: "{tmp}"; Flags: deleteafterinstall; Tasks: RusFiles1 RusFiles2;
Source: "rus\*.*"; DestDir: "{app}"; Flags: promptifolder; Tasks: RusFiles1 RusFiles2;
Source: "rus\{#MM}Patch ReadMe_rus.TXT"; DestDir: "{app}"; Flags: promptifolder; Languages: ru;
Source: "rus\{#MM}Patch ReadMe_rus.TXT"; DestDir: "{app}"; Flags: promptifolder onlyifdestfileexists; Languages: en;
Source: "eng\{#MM}Patch ReadMe.TXT"; DestDir: "{app}"; Flags: promptifolder onlyifdestfileexists; Languages: ru;
Source: "eng\{#MM}Patch ReadMe.TXT"; DestDir: "{app}"; Flags: promptifolder; Languages: en;
#endif

[Run]
#if loc
Filename: "{tmp}\PatchTxt.exe"; Parameters: """{app}\data\events.lod"" ""{tmp}\MAPSTATS.diff.txt"" ""{app}\data\00 patch.events.lod"" /r"; Tasks: lods1 lods2;
Filename: "{tmp}\PatchTxt.exe"; Parameters: """{app}\data\events.lod"" ""{tmp}\2DEvents.diff.txt"" ""{app}\data\01 tunnels.events.lod"""; Tasks: tun1 tun2;
Filename: "{tmp}\PatchTxt.exe"; Parameters: """{app}\data\events.lod"" ""{tmp}\TRANS.diff.txt"" ""{app}\data\01 tunnels.events.lod"" /r"; Tasks: tun1 tun2;
#endif
#if en
Filename: "{app}\{#MM}Patch ReadMe.TXT"; Flags: shellexec skipifdoesntexist postinstall skipifsilent; Languages: en;
#endif
#if ru
Filename: "{app}\{#MM}Patch ReadMe_rus.TXT"; Flags: shellexec skipifdoesntexist postinstall skipifsilent; Languages: ru;
#endif

[Code]

function GetInstallDir(param: string): string;
begin
  if not RegQueryStringValue(HKLM, 'SOFTWARE\New World Computing\Might and Magic VII\1.0', 'AppPath', Result) then
#if en
    Result:= ExpandConstant('{pf}\Might and Magic VII');
#else
    Result:= ExpandConstant('{pf}\Buka\MMCollection\MM_VII');
#endif
end;

function MMIni: string;
begin
  Result:= ExpandConstant('{app}\{#m}.ini');
end;

#if loc
var
  RussianGame, RussianGameChecked: Boolean;

function RussianTaskCheck(checked: Boolean): Boolean;
begin
  if not RussianGameChecked then
    RussianGame:= (GetIniString('Install', 'GameLanguage', '', ExpandConstant('{app}\{#m}lang.ini')) = 'rus') or
     (ExpandConstant('{language}') = 'ru') and not FileExists(ExpandConstant('{app}\{#MM}Patch ReadMe.TXT'));
  RussianGameChecked:= true;
  Result:= (RussianGame = checked);
end;
#endif

function CheckVer(ver: Cardinal): Boolean;
var
  ms, ls: Cardinal;
begin
  Result:= GetVersionNumbers(ExpandConstant('{app}\{#m}patch.dll'), ms, ls) and (ms >= ver);
end;

type
  TTask = record
    On, Checked: Boolean;
  end;

function CheckTask(var t: TTask; checked: Boolean): Boolean;
begin
  t.Checked:= true;
  Result:= (t.On = checked);
end;

function CheckOptLod(var t: TTask; var vis: Boolean; path, md5: string; checked: Boolean; ver: Integer): Boolean;
begin
  vis:= not FileExists(path) or (GetMD5OfFile(path) <> md5);
  Result:= vis and not t.Checked;
  if Result then
    t.On:= FileExists(path) or not CheckVer(ver);
  t.Checked:= t.Checked or vis;
  vis:= vis and (t.On = checked);
end;


var
  PatchLods, PatchLodsChecked: Boolean;

function LodsTaskCheck(checked: Boolean): Boolean;
begin
  if not PatchLodsChecked then
    if CheckVer($20001) then
      PatchLods:= FileExists(ExpandConstant('{app}\Data\00 patch.games.lod'))
    else
      PatchLods:= GetIniBool('Install', 'PatchLods', true, MMIni);
  PatchLodsChecked:= true;
  Result:= (PatchLods = checked);
end;


var
  Dragon: TTask;

function DragonTaskCheck(checked: Boolean): Boolean;
begin
  CheckOptLod(Dragon, Result, ExpandConstant('{app}\Data\01 dragon.games.lod'), '{#DragonMD5}', checked, $20001);
end;


var
  Tunnel: TTask;

function TunnelTaskCheck(checked: Boolean): Boolean;
begin
  CheckOptLod(Tunnel, Result, ExpandConstant('{app}\Data\01 tunnels.events.lod'), '{#TunnelsMD5}', checked, $20001);
end;


var
  Icons: TTask;

function IconsTaskCheck(checked: Boolean): Boolean;
begin
  CheckOptLod(Icons, Result, ExpandConstant('{app}\Data\00 patch.icons.lod'), '{#IconsMD5}', checked, $20002);
end;


var
  Water: TTask;

function WaterTaskCheck(checked: Boolean): Boolean;
var
  path: string;
begin
  if not Water.Checked then
  begin
    path:= ExpandConstant('{app}\Data\00 patch.bitmaps.lod');
    if FileExists(path) then
      Water.On:= (GetMD5OfFile(path) = '{#WaterMD5}') or not CheckVer($20002)
    else
      Water.On:= not CheckVer($20000);
    Water.Checked:= true;
  end;
  Result:= (Water.On = checked);
end;

function OldWaterCheck: Boolean;
var
  path: string;
begin
  Result:= not IsTaskSelected('water1 water2');
  path:= ExpandConstant('{app}\Data\00 patch.bitmaps.lod');
  if FileExists(path) then
    Result:= Result and (GetMD5OfFile(path) = '{#WaterMD5}')
  else
    Result:= Result and not CheckVer($20000);
end;


var
  UI: TTask;

function UITaskCheck(checked: Boolean): Boolean;
begin
  if not UI.Checked then
    UI.On:= not CheckVer($20003);
  Result:= (UpperCase(GetIniString('Settings', 'UILayout', '', MMIni)) <> 'UI') and CheckTask(UI, checked);
end;


procedure AfterInst;
var
 ini: string;
begin
  ini:= MMIni;
  if GetIniString('Install', 'PatchLods', #13#10, ini) <> #13#10 then 
    DeleteIniEntry('Install', 'PatchLods', ini);
  if IsTaskSelected('water1 water2') and (GetIniInt('Settings', 'HDWTRCount', 7, 0, 0, ini) <> 14) then
  begin
    SetIniInt('Settings', 'HDWTRCount', 14, ini);
    SetIniInt('Settings', 'HDWTRDelay', 15, ini);
  end
  else if FileExists(ExpandConstant('{app}\Data\00 patch.bitmaps.lod')) and (GetIniInt('Settings', 'HDWTRCount', 7, 0, 0, ini) = 14) then
  begin
    DeleteIniEntry('Settings', 'HDWTRCount', ini);
    DeleteIniEntry('Settings', 'HDWTRDelay', ini);
  end;
  if IsIniSectionEmpty('MipmapsBase', ini) then
  begin
    SetIniInt('MipmapsBase', 'hwtrdr*', 128, ini);
    SetIniInt('MipmapsBase', 'hdwtr???', 32, ini);
  end;
  if IsTaskSelected('ui1 ui2') then
    SetIniString('Settings', 'UILayout', 'UI', ini);
end;
