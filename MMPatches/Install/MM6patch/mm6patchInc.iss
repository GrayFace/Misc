#define loc (en && ru)
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
LodsTask=Install LOD archives with fixes for particular maps and game progression%nUncheck this task if you are installing the patch over a big mod like The Chaos Conspiracy.
#endif
#if ru
ru.LodsTask=LOD-архивы с исправлениями для конкретных карт и по ходу сюжета%nОтключите эту задачу, если Вы устанавливаете патч поверх большого мода, такого как "Заговор хаоса".
#endif

[Tasks]
#if loc
Name: RusFiles1; Description: {cm:RussianGameVersion}; Check: RussianTaskCheck(true);
Name: RusFiles2; Description: {cm:RussianGameVersion}; Flags: unchecked; Check: RussianTaskCheck(false);
#endif
Name: lods1; Description: {cm:LodsTask}; Check: LodsTaskCheck(true);
Name: lods2; Description: {cm:LodsTask}; Flags: unchecked; Check: LodsTaskCheck(false);

[InstallDelete]
Type: files; Name: "{app}\MSS32.DLL";
Type: files; Name: "{app}\MSS32.NEW";
Type: files; Name: "{app}\SmackW32.dll";
Type: files; Name: "{app}\SmackW32.NEW";
Type: files; Name: "{app}\MP3DEC.ASI";

[Files]
#if en
Source: "Files\*"; Excludes: "*.bak"; DestDir: "{app}"; Flags: promptifolder ignoreversion recursesubdirs; AfterInstall: AfterInst;
#else
Source: "Files\*"; Excludes: "*.bak"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs; AfterInstall: AfterInst;
#endif
Source: "OptFiles\*"; Excludes: "*.bak"; DestDir: "{app}"; Flags: onlyifdoesntexist recursesubdirs;
#if loc
Source: "Data\*"; Excludes: "*.bak"; DestDir: "{app}\Data\"; Tasks: lods1 lods2;
Source: "tmp\*.*"; DestDir: "{tmp}"; Flags: deleteafterinstall; Tasks: lods1 lods2;
Source: "tmpEN\*.*"; DestDir: "{tmp}"; Flags: deleteafterinstall; Tasks: lods1 lods2; Languages: en;
Source: "tmpRU\*.*"; DestDir: "{tmp}"; Flags: deleteafterinstall; Tasks: lods1 lods2; Languages: ru;

Source: "rus\*.*"; DestDir: "{app}"; Flags: promptifolder; Tasks: RusFiles1 RusFiles2;
Source: "rus\{#MM}Patch ReadMe_rus.TXT"; DestDir: "{app}"; Flags: promptifolder; Languages: ru;
Source: "rus\{#MM}Patch ReadMe_rus.TXT"; DestDir: "{app}"; Flags: promptifolder onlyifdestfileexists; Languages: en;
Source: "eng\{#MM}Patch ReadMe.TXT"; DestDir: "{app}"; Flags: promptifolder onlyifdestfileexists; Languages: ru;
Source: "eng\{#MM}Patch ReadMe.TXT"; DestDir: "{app}"; Flags: promptifolder; Languages: en;
#else
Source: "Data\*"; Excludes: "*.bak"; DestDir: "{app}\Data\"; Flags: promptifolder; Tasks: lods1 lods2;
#endif

[Run]
#if loc
Filename: "{tmp}\PatchTxt.exe"; Parameters: """{app}\data\icons.lod"" ""{tmp}\GLOBAL.diff.txt"" ""{app}\data\00 patch.icons.lod"" /r"; Tasks: lods1 lods2;
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
  if not RegQueryStringValue(HKLM, 'SOFTWARE\New World Computing\Might and Magic® VI\1.0', 'AppPath', Result) then
#if en
    Result:= ExpandConstant('{pf}\Might and Magic VI');
#else
    Result:= ExpandConstant('{pf}\Buka\MMCollection\MM_VI');
#endif
end;


function CheckVer(ver: Cardinal): Boolean;
var
  ms, ls: Cardinal;
begin
  Result:= GetVersionNumbers(ExpandConstant('{app}\{#m}patch.dll'), ms, ls) and (ms >= ver);
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
