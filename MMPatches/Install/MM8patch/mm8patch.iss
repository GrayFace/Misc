#define m() "mm8"
#define MM() "MM8"
#define AppDll() AddBackslash(SourcePath) + "Files\" + MM() + "patch.dll"
#define AppVersion() GetFileVersion(AppDll())
#define AppVer() \
  ParseVersion(AppDll(), Local[0], Local[1], Local[2], Local[3]), \
  Str(Local[0])+"."+Str(Local[1])+((Local[2] || Local[3]) ? "."+Str(Local[2]) : "")+(Local[3] ? "."+Str(Local[3]) : "")
#define OldWaterMD5() GetMD5OfFile(AddBackslash(SourcePath) + "OptData\old\00 patch.bitmaps.lod")
#define HDWaterMD5() GetMD5OfFile(AddBackslash(SourcePath) + "OptData\01 water.bitmaps.lwd")
#define IconsMD5() GetMD5OfFile(AddBackslash(SourcePath) + "OptData\00 patch.icons.lod")

[Setup]
VersionInfoVersion={#AppVersion}
AppVerName=GrayFace {#MM} Patch v{#AppVer}
OutputBaseFilename={#MM} Patch v{#AppVer}

AppName=GrayFace {#MM} Patch
DefaultDirName={code:GetInstallDir}
Compression=lzma/ultra
InternalCompressLevel=ultra
SolidCompression=yes
SetupIconFile={#MM}_ICON.ico
Uninstallable=no
AppCopyright=Sergey Rozhenko
DisableProgramGroupPage=yes
DisableWelcomePage=yes
DirExistsWarning=no
EnableDirDoesntExistWarning=yes
InfoBeforeFile="eng\{#MM}Patch ReadMe.TXT"
AppendDefaultDirName=no
WizardImageFile={#MM}Install.bmp
WizardSmallImageFile=none.bmp
WizardImageStretch=no

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl";
Name: "ru"; MessagesFile: "compiler:Languages\Russian.isl"; InfoBeforeFile: "rus\{#MM}Patch ReadMe_rus.TXT";

[Messages]
InfoBeforeLabel=Below is the content of {#MM}Patch ReadMe.txt file detailing all changes of the patch.
ru.InfoBeforeLabel=Ниже приведён файл {#MM}Patch ReadMe_rus.txt, описывающий изменения патча.

[CustomMessages]
NoFakeMouseLook=Disable default MM8 pseudo mouse look triggered by right mouse button
ru.NoFakeMouseLook=Отключить встроенное в MM8 недо- управление мышью, активируемое нажатием правой кнопки мыши
RussianGameVersion=Russian version of the game
ru.RussianGameVersion=Русская версия игры
LodsTask=Install LOD archives with fixes for particular maps and game progression%nUncheck this task if you are installing the patch over a big mod like MM6+7+8 merge.
ru.LodsTask=LOD-архивы с исправлениями для конкретных карт и по ходу сюжета%nОтключите эту задачу, если Вы устанавливаете патч поверх большого мода, такого как объединение MM6+7+8.
WaterTask=Use improved water animation
ru.WaterTask=Использовать улучшенную анимацию воды
IconsTask=Install LOD archive with one interface fix%nUncheck this task if you are installing the patch over a mod that recolors interface.
ru.IconsTask=LOD-архив с одним исправлением для интерфейса%nОтключите эту задачу, если Вы устанавливаете патч поверх мода, перекрашивающего интерфейс.
UITask=Use widescreen-friendly flexible interface
ru.UITask=Включить гибкий интерфейс, адаптированный для широкоэкранников

[Tasks]
Name: RusFiles1; Description: {cm:RussianGameVersion}; Check: RussianTaskCheck(true);
Name: RusFiles2; Description: {cm:RussianGameVersion}; Flags: unchecked; Check: RussianTaskCheck(false);
Name: ui1; Description: {cm:UITask}; Check: UITaskCheck(true);
Name: ui2; Description: {cm:UITask}; Flags: unchecked; Check: UITaskCheck(false);
Name: NoFakeMouseLook1; Description: {cm:NoFakeMouseLook}; Check: LookTaskCheck(true);
Name: NoFakeMouseLook2; Description: {cm:NoFakeMouseLook}; Flags: unchecked; Check: LookTaskCheck(false);
Name: lods1; Description: {cm:LodsTask}; Check: LodsTaskCheck(true);
Name: lods2; Description: {cm:LodsTask}; Flags: unchecked; Check: LodsTaskCheck(false);
Name: water1; Description: {cm:WaterTask}; Check: WaterTaskCheck(true);
Name: water2; Description: {cm:WaterTask}; Flags: unchecked; Check: WaterTaskCheck(false);
Name: icons1; Description: {cm:IconsTask}; Check: IconsTaskCheck(true);
Name: icons2; Description: {cm:IconsTask}; Flags: unchecked; Check: IconsTaskCheck(false);

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
Source: "Files\*.*"; Excludes: "*.bak"; DestDir: "{app}"; Flags: promptifolder ignoreversion recursesubdirs; BeforeInstall: BeforeInst;
Source: "Data\*"; Excludes: "*.bak"; DestDir: "{app}\Data\"; Tasks: lods1 lods2;
Source: "BaseWater\00 patch.bitmaps.lod"; DestDir: "{app}\Data\"; Check: BaseWaterCheck;
Source: "OptData\01 water.bitmaps.lwd"; DestDir: "{app}\Data\"; Tasks: water1 water2;
Source: "OptData\00 patch.icons.lod"; DestDir: "{app}\Data\"; Tasks: icons1 icons2;
Source: "OptFiles\*"; Excludes: "*.bak"; DestDir: "{app}"; Flags: onlyifdoesntexist recursesubdirs; AfterInstall: AfterInst;

Source: "rus\*.*"; DestDir: "{app}"; Flags: promptifolder; Tasks: RusFiles1 RusFiles2;
Source: "rus\{#MM}Patch ReadMe_rus.TXT"; DestDir: "{app}"; Flags: promptifolder; Languages: ru;
Source: "rus\{#MM}Patch ReadMe_rus.TXT"; DestDir: "{app}"; Flags: promptifolder onlyifdestfileexists; Languages: en;
Source: "eng\{#MM}Patch ReadMe.TXT"; DestDir: "{app}"; Flags: promptifolder onlyifdestfileexists; Languages: ru;
Source: "eng\{#MM}Patch ReadMe.TXT"; DestDir: "{app}"; Flags: promptifolder; Languages: en;

[Run]
Filename: "{app}\{#MM}Patch ReadMe.TXT"; Flags: shellexec skipifdoesntexist postinstall skipifsilent; Languages: en;
Filename: "{app}\{#MM}Patch ReadMe_rus.TXT"; Flags: shellexec skipifdoesntexist postinstall skipifsilent; Languages: ru;

[Code]

function GetMD5(s: string): string;
begin
  s:= ExpandConstant(s);
  Result:= '';
  if FileExists(s) then
    Result:= GetMD5OfFile(s);
end;

function Exists(const s: string): Boolean;
begin
  Result:= FileExists(ExpandConstant(s));
end;

function GetInstallDir(param: string): string;
begin
  if not RegQueryStringValue(HKLM, 'SOFTWARE\New World Computing\Might and Magic Day of the Destroyer\1.0', 'AppPath', Result) then
    Result:= ExpandConstant('{pf}\3DO\Might and Magic VIII');
end;

function MMIni: string;
begin
  Result:= ExpandConstant('{app}\{#m}.ini');
end;

function CheckVer(ver: Cardinal): Boolean;
var
  ms, ls: Cardinal;
begin
  Result:= GetVersionNumbers(ExpandConstant('{app}\{#m}patch.dll'), ms, ls) and (ms >= ver);
end;

function CheckNoMerge: Boolean;
begin
  Result:= not (Exists('{app}\Data\mm6.games.lod') and Exists('{app}\Data\mm7.games.lod'));
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
var
  md: string;
begin
  md:= GetMD5(path);
  vis:= (md <> md5);
  Result:= vis and not t.Checked;
  if Result then
    t.On:= (md <> '') or not CheckVer(ver);
  t.Checked:= t.Checked or vis;
  vis:= vis and (t.On = checked);
end;


var
  Lods: TTask;

function LodsTaskCheck(checked: Boolean): Boolean;
begin
  if not Lods.Checked then
    Lods.On:= (not CheckVer($20001) or Exists('{app}\Data\00 patch.games.lod')) and CheckNoMerge;
  Result:= CheckTask(Lods, checked);
end;


var
  Icons: TTask;

function IconsTaskCheck(checked: Boolean): Boolean;
begin
  CheckOptLod(Icons, Result, '{app}\Data\00 patch.icons.lod', '{#IconsMD5}', checked, $20002);
end;


var
  RussianGame: TTask;

function RussianTaskCheck(checked: Boolean): Boolean;
begin
  if not RussianGame.Checked then
    RussianGame.On:= (GetIniString('Install', 'GameLanguage', '', ExpandConstant('{app}\{#m}lang.ini')) = 'rus') or
     (ExpandConstant('{language}') = 'ru') and not Exists('{app}\{#MM}Patch ReadMe.TXT');
  Result:= CheckTask(RussianGame, checked);
end;


var
  LookVisible, LookEnabled, LookChecked: Boolean;

function LookTaskCheck(checked: Boolean): Boolean;
begin
  LookVisible:= GetIniInt('Settings', 'MouseLookBorder', 200, 0, 0, MMIni) >= 0;
  if LookVisible and not LookChecked then
  begin
    LookEnabled:= not CheckVer($10006);  // 1.5.1 and lower didn't have this option in setup
    LookChecked:= true;
  end;
  Result:= LookVisible and (LookEnabled = checked);
end;


var
  Water: TTask;

function GetWaterKind: Integer;  // -2 = base, 2 = need wavy, 3 = wavy
var
  md: string;
begin
  Result:= 2;
  md:= GetMD5('{app}\Data\01 water.bitmaps.lwd');
  if md = '{#HDWaterMD5}' then
    Result:= 3;
  if md <> '' then
    exit;

  md:= GetMD5('{app}\Data\00 patch.bitmaps.lod');
  if (md <> '') and CheckVer($20002) then
    Result:= -2;
  if md = '{#OldWaterMD5}' then
    Result:= 3;
end;

function WaterTaskCheck(checked: Boolean): Boolean;
begin
  if not Water.Checked then
    Water.On:= (GetWaterKind > 0);
  Result:= CheckTask(Water, checked) and CheckNoMerge;
end;

function BaseWaterCheck: Boolean;
begin
  Result:= not IsTaskSelected('water1 water2') and CheckNoMerge;
end;


var
  UI: TTask;

function UITaskCheck(checked: Boolean): Boolean;
begin
  if not UI.Checked then
    UI.On:= not CheckVer($20003);
  Result:= ((UpperCase(GetIniString('Settings', 'UILayout', '', MMIni)) <> 'UI') or
    not GetIniBool('Settings', 'SupportTrueColor', true, MMIni)) and CheckTask(UI, checked);
end;


procedure BeforeInst;
var
  ini, path: string;
  b: Boolean;
  delay, wk: integer;
begin
  ini:= MMIni;
  if IsTaskSelected('NoFakeMouseLook1 NoFakeMouseLook2') then
    SetIniInt('Settings', 'MouseLookBorder', -1, ini);
  delay:= GetIniInt('Settings', 'StartupCopyrightDelay', 1, 0, 0, ini);
  if not CheckVer($20004) and ((delay = 5000) or (delay = 0)) then
    DeleteIniEntry('Settings', 'StartupCopyrightDelay', ini);

  b:= IsTaskSelected('water1 water2');
  wk:= GetWaterKind;
  if b and (wk < 3) and (GetIniInt('Settings', 'HDWTRCount', 8, 0, 0, ini) <> 14) then
  begin
    SetIniInt('Settings', 'HDWTRCount', 14, ini);
    SetIniInt('Settings', 'HDWTRDelay', 15, ini);
  end;
  if not b and CheckNoMerge and (wk > 1) and (GetIniInt('Settings', 'HDWTRCount', 8, 0, 0, ini) <> 8) then
  begin
    DeleteIniEntry('Settings', 'HDWTRCount', ini);
    DeleteIniEntry('Settings', 'HDWTRDelay', ini);
  end;

  if IsIniSectionEmpty('MipmapsBase', ini) then
  begin
    SetIniInt('MipmapsBase', 'hwtrdr*', 128, ini);
    SetIniInt('MipmapsBase', 'hdwtr???', 64, ini);
    SetIniInt('MipmapsBase', 'hdlav???', 64, ini);
    SetIniInt('MipmapsBase', 'hwoil???', 128, ini);
    SetIniInt('MipmapsBase', 'gdtyl', 256, ini);
    SetIniInt('MipmapsBase', 'DIRTtyl', 256, ini);
    SetIniInt('MipmapsBase', 'Grastyl', 256, ini);
    SetIniInt('MipmapsBase', 'Grastyl2', 256, ini);
  end;
  if IsTaskSelected('ui1 ui2') then
  begin
    SetIniString('Settings', 'UILayout', 'UI', ini);
    if GetIniInt('Settings', 'SupportTrueColor', 1, 0, 0, ini) <> 1 then
      SetIniInt('Settings', 'SupportTrueColor', 1, ini);
  end;
end;

procedure AfterInst;
begin
  if IsTaskSelected('water1 water2') then
    DeleteFile(ExpandConstant('{app}\Data\00 patch.bitmaps.lod'))
  else if BaseWaterCheck then
    DeleteFile(ExpandConstant('{app}\Data\01 water.bitmaps.lwd'));
end;
