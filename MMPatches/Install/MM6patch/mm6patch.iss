#ifdef for_convenience
#include "..\MM6PatchBuka\mm6patchBuka.iss"
#include "..\MM6PatchLoc\mm6patchLoc.iss"
#endif
#ifndef en
#define en 1
#define ru 0
#endif
#define loc (en && ru)
#define m() "mm6"
#define MM() "MM6"
#define AppDll() AddBackslash(SourcePath) + "Files\" + MM() + "patch.dll"
#define AppVersion() GetFileVersion(AppDll())
#define AppVer() \
  ParseVersion(AppDll(), Local[0], Local[1], Local[2], Local[3]), \
  Str(Local[0])+"."+Str(Local[1])+((Local[2] || Local[3]) ? "."+Str(Local[2]) : "")+(Local[3] ? "."+Str(Local[3]) : "")
#define BitmapsMD5() GetMD5OfFile(AddBackslash(SourcePath) + "OptData\00 patch.bitmaps.lod")
#define SpritesMD5() GetMD5OfFile(AddBackslash(SourcePath) + "OptData\00 patch.sprites.lod")

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
;WizardImageFile={#MM}Install.bmp
WizardImageFile=none.bmp
WizardSmallImageFile=none.bmp
WizardImageStretch=no
;WizardStyle=modern
WizardResizable=yes
WizardSizePercent=120

[LangOptions]
DialogFontName=Tahoma
DialogFontSize=9

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
LodGroup=Uncheck these tasks if you are installing the patch over an old big mod like The Chaos Conspiracy:
LodsTask=Install LOD archives with fixes for maps and game progression
SpritesTask=Install fixed graphics of skeletons and enforcer units
#endif
#if ru
ru.LodGroup=Отключите эти задачи, если Вы устанавливаете патч поверх старого большого мода, такого как "Заговор хаоса":
ru.LodsTask=LOD-архивы с исправлениями для карт и по ходу сюжета
ru.SpritesTask=Установить исправленную графику скелетов и "роботов - инфорсеров"
#endif

[Tasks]
#if loc
Name: RusFiles; Description: {cm:RussianGameVersion};
#endif
Name: lods; Description: {cm:LodsTask}; GroupDescription: {cm:LodGroup};
Name: sprites; Description: {cm:SpritesTask}; GroupDescription: {cm:LodGroup}; Check: SpritesTaskCheck(true);

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
Source: "OptData\00 patch.bitmaps.lod"; DestDir: "{app}\Data\"; Tasks: sprites;
Source: "OptData\00 patch.sprites.lod"; DestDir: "{app}\Data\"; Tasks: sprites;
Source: "OptFiles\*"; Excludes: "*.bak"; DestDir: "{app}"; Flags: onlyifdoesntexist recursesubdirs;
#if loc
Source: "Data\*"; Excludes: "*.bak"; DestDir: "{app}\Data\"; Tasks: lods;
Source: "tmp\*.*"; DestDir: "{tmp}"; Flags: deleteafterinstall; Tasks: lods;
Source: "tmpEN\*.*"; DestDir: "{tmp}"; Flags: deleteafterinstall; Tasks: lods; Languages: en;
Source: "tmpRU\*.*"; DestDir: "{tmp}"; Flags: deleteafterinstall; Tasks: lods; Languages: ru;

Source: "rus\*.*"; DestDir: "{app}"; Flags: promptifolder; Tasks: RusFiles;
Source: "rus\{#MM}Patch ReadMe_rus.TXT"; DestDir: "{app}"; Flags: promptifolder; Languages: ru;
Source: "rus\{#MM}Patch ReadMe_rus.TXT"; DestDir: "{app}"; Flags: promptifolder onlyifdestfileexists; Languages: en;
Source: "eng\{#MM}Patch ReadMe.TXT"; DestDir: "{app}"; Flags: promptifolder onlyifdestfileexists; Languages: ru;
Source: "eng\{#MM}Patch ReadMe.TXT"; DestDir: "{app}"; Flags: promptifolder; Languages: en;
#else
Source: "Data\*"; Excludes: "*.bak"; DestDir: "{app}\Data\"; Flags: promptifolder; Tasks: lods;
#endif

[Run]
#if loc
Filename: "{tmp}\PatchTxt.exe"; Parameters: """{app}\data\icons.lod"" ""{tmp}\GLOBAL.diff.txt"" ""{app}\data\00 patch.icons.lod"" /r"; Tasks: lods;
#endif
#if en
Filename: "{app}\{#MM}Patch ReadMe.TXT"; Flags: shellexec skipifdoesntexist postinstall skipifsilent; Languages: en;
#endif
#if ru
Filename: "{app}\{#MM}Patch ReadMe_rus.TXT"; Flags: shellexec skipifdoesntexist postinstall skipifsilent; Languages: ru;
#endif

[Code]

type int = Integer;

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
  if not RegQueryStringValue(HKLM, 'SOFTWARE\New World Computing\Might and Magic® VI\1.0', 'AppPath', Result) then
#if en
    Result:= ExpandConstant('{pf}\Might and Magic VI');
#else
    Result:= ExpandConstant('{pf}\Buka\MMCollection\MM_VI');
#endif
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

function CheckOptLod(vis: Boolean; path, md5: string; ver: Integer): Boolean;
begin
  if vis then
    Result:= (GetMD5(path) <> md5)
  else
    Result:= Exists(path) or not CheckVer(ver);
end;


#if loc
function RussianTaskCheck: Boolean;
begin
  Result:= (GetIniString('Install', 'GameLanguage', '', ExpandConstant('{app}\{#m}lang.ini')) = 'rus') or
   (ExpandConstant('{language}') = 'ru') and not Exists('{app}\{#MM}Patch ReadMe.TXT');
end;
#endif


function LodsTaskCheck: Boolean;
begin
  if CheckVer($20001) then
    Result:= Exists('{app}\Data\00 patch.games.lod')
  else
    Result:= GetIniBool('Install', 'PatchLods', true, MMIni);
end;


function SpritesTaskCheck(vis: Boolean): Boolean;
begin
  Result:= CheckOptLod(vis, '{app}\Data\00 patch.bitmaps.lod', '{#BitmapsMD5}', $20005);
  if Result <> vis then
    Result:= CheckOptLod(vis, '{app}\Data\00 patch.sprites.lod', '{#SpritesMD5}', $20005);
end;


procedure CheckTask(const msg: string; b: Boolean);
var
  i: int;
begin
  i:= WizardForm.TasksList.Items.IndexOf(CustomMessage(msg));
  if i >= 0 then
    WizardForm.TasksList.Checked[i]:= b;
end;

var
  LastPath: string;

procedure CurPageChanged(CurPageID: Integer);
begin
  if (CurPageID <> wpSelectTasks) or (ExpandConstant('{app}') = LastPath) then  exit;
  LastPath:= ExpandConstant('{app}');
#if loc
  CheckTask('RussianGameVersion', RussianTaskCheck());
#endif
  CheckTask('LodsTask', LodsTaskCheck());
  CheckTask('SpritesTask', SpritesTaskCheck(false));
end;

procedure AfterInst;
begin
  if GetIniString('Install', 'PatchLods', #13#10, ExpandConstant('{app}\{#m}.ini')) <> #13#10 then 
    DeleteIniEntry('Install', 'PatchLods', ExpandConstant('{app}\{#m}.ini'))
end;
