#if false
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
#define OptMD5(s) GetMD5OfFile(AddBackslash(SourcePath) + "OptData\" + s)
#define CheckOptLod(s, v) "CheckOptLod(vis, '{app}\Data\" + s + "', '" + OptMD5(s) + "', " + Str(v) + ")";

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
;WizardImageFile=none.bmp
;WizardImageStretch=no
WizardSmallImageFile=none.bmp
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

// must be last in the list:
Name: Dummy; Description: -; Check: CheckUpdateTasks;

[InstallDelete]
Type: files; Name: "{app}\MSS32.DLL";
Type: files; Name: "{app}\MSS32.NEW";
Type: files; Name: "{app}\SmackW32.dll";
Type: files; Name: "{app}\SmackW32.NEW";
Type: files; Name: "{app}\MP3DEC.ASI";

[Files]
#if en
Source: "Files\*"; Excludes: "*.bak"; DestDir: "{app}"; Flags: promptifolder ignoreversion recursesubdirs;
#else
Source: "Files\*"; Excludes: "*.bak"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs;
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
Filename: "{app}\{#MM}Patch ReadMe.TXT"; Flags: shellexec skipifdoesntexist postinstall skipifsilent; Languages: en; Check: CheckFinishPage;
#endif
#if ru
Filename: "{app}\{#MM}Patch ReadMe_rus.TXT"; Flags: shellexec skipifdoesntexist postinstall skipifsilent; Languages: ru; Check: CheckFinishPage;
#endif

[Code]

#include "..\..\MMCommon\MMPatchCommonCode.iss"

function GetInstallDir(param: string): string;
begin
	if not RegQueryStringValue(HKLM, 'SOFTWARE\New World Computing\Might and Magic® VI\1.0', 'AppPath', Result) then
#if en
		Result:= _P('{pf}\Might and Magic VI');
#else
		Result:= _P('{pf}\Buka\MMCollection\MM_VI');
#endif
end;


#if loc
function RussianTaskCheck: Boolean;
begin
	Result:= (GetIniString('Install', 'GameLanguage', '', _P('{app}\{#m}lang.ini')) = 'rus') or
	 (_P('{language}') = 'ru') and not Exists('{app}\{#MM}Patch ReadMe.TXT');
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
	Result:= {#CheckOptLod('00 patch.bitmaps.lod', 0x20005)};
	if Result <> vis then
		Result:= {#CheckOptLod('00 patch.sprites.lod', 0x20005)};
end;


procedure UpdateTasks;
begin
#if loc
	CheckTask('RusFiles', RussianTaskCheck());
#endif
	CheckTask('lods', LodsTaskCheck());
	CheckTask('sprites', SpritesTaskCheck(false));
end;

procedure BeforeInstall;
begin
end;

procedure AfterInstall;
begin
	if GetIniString('Install', 'PatchLods', #13#10, MMIni) <> #13#10 then 
		DeleteIniEntry('Install', 'PatchLods', MMIni);
	if IsIniSectionEmpty('Install', MMIni) then
		DeleteIniSection('Install', MMIni);
end;
