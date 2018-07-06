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
OutputBaseFilename={#MM} Patch Loc v{#AppVer}

AppName=GrayFace {#MM} Patch
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
LodsTask=Install LOD archives with fixes for particular maps and game progression%nUncheck this task if you are installing the patch over a big mod like The Chaos Conspiracy.
ru.LodsTask=LOD-архивы с исправлениями для конкретных карт и по ходу сюжета%nОтключите эту задачу, если Вы устанавливаете патч поверх большого мода, такого как "Заговор хаоса".
RussianGameVersion=Russian version of the game
ru.RussianGameVersion=Русская версия игры

[Tasks]
Name: RusFiles1; Description: {cm:RussianGameVersion}; Check: RussianTaskCheck(true);
Name: RusFiles2; Description: {cm:RussianGameVersion}; Flags: unchecked; Check: RussianTaskCheck(false);
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
Source: "Data\*"; Excludes: "*.bak"; DestDir: "{app}\Data\"; Tasks: lods1 lods2;
Source: "OptFiles\*"; Excludes: "*.bak"; DestDir: "{app}"; Flags: onlyifdoesntexist recursesubdirs;
Source: "tmp\*.*"; DestDir: "{tmp}"; Flags: deleteafterinstall; Tasks: lods1 lods2;
Source: "tmpEN\*.*"; DestDir: "{tmp}"; Flags: deleteafterinstall; Tasks: lods1 lods2; Languages: en;
Source: "tmpRU\*.*"; DestDir: "{tmp}"; Flags: deleteafterinstall; Tasks: lods1 lods2; Languages: ru;

Source: "rus\*.*"; DestDir: "{app}"; Flags: promptifolder; Tasks: RusFiles1 RusFiles2;
Source: "rus\{#MM}Patch ReadMe_rus.TXT"; DestDir: "{app}"; Flags: promptifolder; Languages: ru;
Source: "rus\{#MM}Patch ReadMe_rus.TXT"; DestDir: "{app}"; Flags: promptifolder onlyifdestfileexists; Languages: en;
Source: "eng\{#MM}Patch ReadMe.TXT"; DestDir: "{app}"; Flags: promptifolder onlyifdestfileexists; Languages: ru;
Source: "eng\{#MM}Patch ReadMe.TXT"; DestDir: "{app}"; Flags: promptifolder; Languages: en;

[Run]
Filename: "{tmp}\PatchTxt.exe"; Parameters: """{app}\data\icons.lod"" ""{tmp}\GLOBAL.diff.txt"" ""{app}\data\00 patch.icons.lod"" /r"; Tasks: lods1 lods2;

Filename: "{app}\{#MM}Patch ReadMe.TXT"; Flags: shellexec skipifdoesntexist postinstall skipifsilent; Languages: en;
Filename: "{app}\{#MM}Patch ReadMe_rus.TXT"; Flags: shellexec skipifdoesntexist postinstall skipifsilent; Languages: ru;

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


procedure AfterInst;
begin
  if GetIniString('Install', 'PatchLods', #13#10, ExpandConstant('{app}\{#m}.ini')) <> #13#10 then 
    DeleteIniEntry('Install', 'PatchLods', ExpandConstant('{app}\{#m}.ini'))
end;
