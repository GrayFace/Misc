#define m() "mm8"
#define MM() "MM8"
#define AppDll() AddBackslash(SourcePath) + "Files\" + MM() + "patch.dll"
#define AppVersion() GetFileVersion(AppDll())
#define AppVer() \
  ParseVersion(AppDll(), Local[0], Local[1], Local[2], Local[3]), \
  Str(Local[0])+"."+Str(Local[1])+((Local[2] || Local[3]) ? "."+Str(Local[2]) : "")+(Local[3] ? "."+Str(Local[3]) : "")

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

[Tasks]
Name: RusFiles1; Description: {cm:RussianGameVersion}; Check: RussianTaskCheck(true);
Name: RusFiles2; Description: {cm:RussianGameVersion}; Flags: unchecked; Check: RussianTaskCheck(false);
Name: NoFakeMouseLook1; Description: {cm:NoFakeMouseLook}; Check: LookTaskCheck(true);
Name: NoFakeMouseLook2; Description: {cm:NoFakeMouseLook}; Flags: unchecked; Check: LookTaskCheck(false);
Name: lods1; Description: {cm:LodsTask}; Check: LodsTaskCheck(true);
Name: lods2; Description: {cm:LodsTask}; Flags: unchecked; Check: LodsTaskCheck(false);

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
Source: "Files\*.*"; Excludes: "*.bak"; DestDir: "{app}"; Flags: promptifolder ignoreversion recursesubdirs; AfterInstall: AfterInst;
Source: "Data\*"; Excludes: "*.bak"; DestDir: "{app}\Data\"; Tasks: lods1 lods2;
Source: "OptFiles\*"; Excludes: "*.bak"; DestDir: "{app}"; Flags: onlyifdoesntexist recursesubdirs;

Source: "rus\*.*"; DestDir: "{app}"; Flags: promptifolder; Tasks: RusFiles1 RusFiles2;
Source: "rus\{#MM}Patch ReadMe_rus.TXT"; DestDir: "{app}"; Flags: promptifolder; Languages: ru;
Source: "rus\{#MM}Patch ReadMe_rus.TXT"; DestDir: "{app}"; Flags: promptifolder onlyifdestfileexists; Languages: en;
Source: "eng\{#MM}Patch ReadMe.TXT"; DestDir: "{app}"; Flags: promptifolder onlyifdestfileexists; Languages: ru;
Source: "eng\{#MM}Patch ReadMe.TXT"; DestDir: "{app}"; Flags: promptifolder; Languages: en;

[Run]
Filename: "{app}\{#MM}Patch ReadMe.TXT"; Flags: shellexec skipifdoesntexist postinstall skipifsilent; Languages: en;
Filename: "{app}\{#MM}Patch ReadMe_rus.TXT"; Flags: shellexec skipifdoesntexist postinstall skipifsilent; Languages: ru;

[Code]

function GetInstallDir(param: string): string;
begin
  if not RegQueryStringValue(HKLM, 'SOFTWARE\New World Computing\Might and Magic Day of the Destroyer\1.0', 'AppPath', Result) then
    Result:= ExpandConstant('{pf}\3DO\Might and Magic VIII');
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
    PatchLods:= not CheckVer($20001) or FileExists(ExpandConstant('{app}\Data\00 patch.games.lod'));
  PatchLodsChecked:= true;
  Result:= (PatchLods = checked);
end;


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


var
  LookVisible, LookEnabled, LookChecked: Boolean;

function LookTaskCheck(checked: Boolean): Boolean;
begin
  LookVisible:= GetIniInt('Settings', 'MouseLookBorder', 200, 0, 0, ExpandConstant('{app}\mm8.ini')) >= 0;
  if LookVisible and not LookChecked then
  begin
    LookEnabled:= not CheckVer($10006);  // 1.5.1 and lower didn't have this option in setup
    LookChecked:= true;
  end;
  Result:= LookVisible and (LookEnabled = checked);
end;


procedure AfterInst;
begin
  if IsTaskSelected('NoFakeMouseLook1 NoFakeMouseLook2') then
    SetIniInt('Settings', 'MouseLookBorder', -1, ExpandConstant('{app}\mm8.ini'));
end;
