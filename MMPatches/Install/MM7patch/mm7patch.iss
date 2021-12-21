#if false
	#include "..\MM7PatchBuka\mm7patchBuka.iss"
	#include "..\MM7PatchLoc\mm7patchLoc.iss"
#endif
#ifndef en
#define en 1
#define ru 0
#endif
#define loc (en && ru)
#define m() "mm7"
#define MM() "MM7"
#define AppDll() AddBackslash(SourcePath) + "Files\" + MM() + "patch.dll"
#define AppVersion() GetFileVersion(AppDll())
#define AppVer() \
	ParseVersion(AppDll(), Local[0], Local[1], Local[2], Local[3]), \
	Str(Local[0])+"."+Str(Local[1])+((Local[2] || Local[3]) ? "."+Str(Local[2]) : "")+(Local[3] ? "."+Str(Local[3]) : "")
#define OptMD5(s) GetMD5OfFile(AddBackslash(SourcePath) + "OptData\" + s)
#define CheckOptLod(s, v) "CheckOptLod(vis, '{app}\Data\" + s + "', '" + OptMD5(s) + "', " + Str(v) + ")";
#define OldWaterMD5() OptMD5("old\00 patch.bitmaps.lod")
#define HDWaterMD5() OptMD5("01 water.bitmaps.lwd")

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
LodGroup=Uncheck these tasks if you are installing the patch over an old big mod like BDJ''s Rev4 mod:
LodsTask=Install LOD archives with fixes for maps and game progression
TunnelsTask=Fix Thunderfist Mountain entrances mismatch, add videos to exits from it into different dungeons
DragonTask=Make "Mega-Dragon" in The Dragon Caves in Eeofol a real mega-dragon instead of a weakened regular dragon
WaterTask=Use improved water animation
IconsTask=Install LOD archive with interface fixes.%nUncheck this task if you are installing the patch over an old mod that recolors interface
UITask=Use widescreen-friendly flexible interface
PalTask=Improved Monsters - Fix monsters that look the same in all 3 variations.%nUncheck this task if you are installing the patch over a mod that changes monsters
#endif
#if ru
ru.LodGroup=Отключите эти задачи, если Вы устанавливаете патч поверх старого большого мода, такого как BDJ Rev4 mod:
ru.LodsTask=LOD-архивы с исправлениями для карт и по ходу сюжета
ru.TunnelsTask=Исправить путаницу со входами в Гору Громовой Кулак, добавить видеозаставки при переходе в другие подземелья из неё
ru.DragonTask=Заменить ослабленного обычного дракона с именем "Мегадракон" в Пещерах драконов в Эофоле на настоящего магадракона
ru.WaterTask=Использовать улучшенную анимацию воды
ru.IconsTask=Установить LOD-архив с исправлениями для интерфейса.%nОтключите эту задачу, если Вы устанавливаете патч поверх старого мода, перекрашивающего интерфейс
ru.UITask=Включить гибкий интерфейс, адаптированный для широкоэкранников
ru.PalTask=Исправить монстров, которые во всех 3 вариациях выглядят одинаково.%nОтключите эту задачу, если Вы устанавливаете патч поверх мода, меняющего монстров
#endif

[Tasks]
#if loc
Name: RusFiles; Description: {cm:RussianGameVersion};
#endif
Name: ui; Description: {cm:UITask}; Check: UITaskShow;
Name: water; Description: {cm:WaterTask}; Check: IsMM7;
Name: icons; Description: {cm:IconsTask}; Check: IconsTaskCheck(true);
Name: pal; Description: {cm:PalTask}; Check: PalTaskCheck(true);
Name: lods; Description: {cm:LodsTask}; GroupDescription: {cm:LodGroup}; Check: IsMM7;
Name: tun; Description: {cm:TunnelsTask}; GroupDescription: {cm:LodGroup}; Check: TunnelTaskCheck(true);
Name: dragon; Description: {cm:DragonTask}; GroupDescription: {cm:LodGroup}; Check: DragonTaskCheck(true);

// must be last in the list:
Name: Dummy; Description: -; Check: CheckUpdateTasks;

; Delete SafeDisk files and Gamma.pcx
[InstallDelete]
Type: files; Name: "{app}\00000001.TMP";
Type: files; Name: "{app}\clcd16.dll";
Type: files; Name: "{app}\clcd32.dll";
Type: files; Name: "{app}\clokspl.exe";
Type: files; Name: "{app}\dplayerx.dll";
Type: files; Name: "{app}\drvmgt.dll";
Type: files; Name: "{app}\secdrv.sys";
Type: files; Name: "{app}\{#MM}.ICD";
Type: files; Name: "{app}\Gamma.pcx";

[Files]
#define FlagsOlder (loc ? "Flags: promptifolder;" : "")
#define FlagOlder (loc ? "promptifolder" : "")
#define Fil "AfterInstall: FileInstalled;"
Source: "Files\*.*"; Excludes: "*.bak"; DestDir: "{app}"; {#Fil} Flags: {#FlagOlder} ignoreversion recursesubdirs;
Source: "Files7\*.*"; Excludes: "*.bak"; DestDir: "{app}"; {#Fil} Flags: {#FlagOlder} ignoreversion; Check: IsMM7;
Source: "Data\*"; Excludes: "*.bak"; DestDir: "{app}\Data\"; {#Fil} {#FlagsOlder} Tasks: lods;
Source: "BaseWater\00 base water.bitmaps.lod"; DestDir: "{app}\Data\"; {#Fil} Check: BaseWaterCheck;
Source: "OptData\01 dragon.games.lod"; DestDir: "{app}\Data\"; {#Fil} Flags: promptifolder; Tasks: dragon;
Source: "OptData\01 tunnels.events.lod"; DestDir: "{app}\Data\"; {#Fil} {#FlagsOlder} Tasks: tun;
Source: "OptData\01 water.bitmaps.lwd"; DestDir: "{app}\Data\"; {#Fil} Tasks: water;
Source: "OptData\00 patch.icons.lod"; DestDir: "{app}\Data\"; {#Fil} Check: IsIconsTaskChecked;
Source: "OptData\01 mon pal.bitmaps.lod"; DestDir: "{app}\Data\"; {#Fil} Tasks: pal;
Source: "OptFiles\*"; Excludes: "*.bak"; DestDir: "{app}"; {#Fil} Flags: onlyifdoesntexist recursesubdirs;
#if loc
Source: "tmp\*.*"; DestDir: "{tmp}"; Flags: deleteafterinstall; Tasks: lods tun;
Source: "tmpRU\*.*"; DestDir: "{tmp}"; Flags: deleteafterinstall; Tasks: RusFiles;
Source: "rus\*.*"; DestDir: "{app}"; Flags: promptifolder; {#Fil} Tasks: RusFiles;
Source: "rus\{#MM}Patch ReadMe_rus.TXT"; DestDir: "{app}"; {#Fil} Flags: promptifolder; Languages: ru;
Source: "rus\{#MM}Patch ReadMe_rus.TXT"; DestDir: "{app}"; {#Fil} Flags: promptifolder onlyifdestfileexists; Languages: en;
Source: "eng\{#MM}Patch ReadMe.TXT"; DestDir: "{app}"; {#Fil} Flags: promptifolder onlyifdestfileexists; Languages: ru;
Source: "eng\{#MM}Patch ReadMe.TXT"; DestDir: "{app}"; {#Fil} Flags: promptifolder; Languages: en;
#endif

[Run]
#if loc
Filename: "{tmp}\PatchTxt.exe"; Parameters: """{app}\data\events.lod"" ""{tmp}\MAPSTATS.diff.txt"" ""{app}\data\00 patch.events.lod"" /r"; Tasks: lods;
Filename: "{tmp}\PatchTxt.exe"; Parameters: """{app}\data\events.lod"" ""{tmp}\2DEvents.diff.txt"" ""{app}\data\01 tunnels.events.lod"""; Tasks: tun;
Filename: "{tmp}\PatchTxt.exe"; Parameters: """{app}\data\events.lod"" ""{tmp}\TRANS.diff.txt"" ""{app}\data\01 tunnels.events.lod"" /r"; Tasks: tun;
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
	if not RegQueryStringValue(HKLM, 'SOFTWARE\New World Computing\Might and Magic VII\1.0', 'AppPath', Result) then
#if en
		Result:= _P('{pf}\Might and Magic VII');
#else
		Result:= _P('{pf}\Buka\MMCollection\MM_VII');
#endif
end;

#if loc
function RussianTaskCheck: Boolean;
begin
	Result:= (GetIniString('Install', 'GameLanguage', '', _P('{app}\{#m}lang.ini')) = 'rus') or
	 (_P('{language}') = 'ru') and not Exists('{app}\{#MM}Patch ReadMe.TXT');
end;
#endif


function IsMM7: Boolean;
begin
	Result:= not Exists('{app}\mm6.5.exe');
end;


function LodsTaskCheck: Boolean;
begin
	if CheckVer($20001) then
		Result:= Exists('{app}\Data\00 patch.games.lod')
	else
		Result:= GetIniBool('Install', 'PatchLods', true, MMIni);
end;


function DragonTaskCheck(vis: Boolean): Boolean;
begin
	Result:= IsMM7 and {#CheckOptLod('01 dragon.games.lod', 0x20001)};
end;


function TunnelTaskCheck(vis: Boolean): Boolean;
begin
	Result:= IsMM7 and {#CheckOptLod('01 tunnels.events.lod', 0x20001)};
end;


function IconsTaskCheck(vis: Boolean): Boolean;
begin
	Result:= IsMM7 and {#CheckOptLod('00 patch.icons.lod', 0x20002)};
end;

function IsIconsTaskChecked: Boolean;
begin
	Result:= not IsMM7 or IsTaskSelected('icons');
end;


function PalTaskCheck(vis: Boolean): Boolean;
begin
	Result:= IsMM7 and {#CheckOptLod('01 mon pal.bitmaps.lod', 0x20005)};
end;


var
	SavedWaterKind: Integer;

function GetWaterKind: Integer;  // -2 = base, 0 = none, 1 = base yet need wavy, 2 = need wavy, 3 = wavy
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
	if CheckVer($20000) then
		Result:= 0;
	if md <> '' then
		Result:= 1;
	if Exists('{app}\Data\00 base water.bitmaps.lod') or (md <> '') and CheckVer2($20002, $20004) then
		Result:= -2;
	if md = '{#OldWaterMD5}' then
		Result:= 3;
end;

function BaseWaterCheck: Boolean;
begin
	Result:= IsMM7 and not IsTaskSelected('water') and (SavedWaterKind <> 0);
end;


function UITaskShow: Boolean;
begin
	Result:= (UpperCase(GetIniString('Settings', 'UILayout', '', MMIni)) <> 'UI') or
		not GetIniBool('Settings', 'SupportTrueColor', true, MMIni);
end;


// WriteIni65
// (lists patch files in Data\mm65_archives.ini for MM6.5 uninstaller to delete them)

#define FileEntry(dir, path, name) "'" + dir + name + ":" + \
	GetSHA1OfFile(path + "\" + name) + "'#13#10"

#define DoProcessFile(dir, path, depth, name, FindHandle) \
	(name != "." && name != ".." \
		? (DirExists(path + "\" + name) \
			? (depth != 1 ? ProcessFind(dir + name + "\", path + "\" + name, "\*", depth - 1) : "") \
			: FileEntry(dir, path, name)) \
		: "")

#define ProcessFile(dir, path, depth, FindResult, FindHandle) \
	FindResult ? DoProcessFile(dir, path, depth, FindGetFileName(FindHandle), FindHandle) \
		+ ProcessFile(dir, path, depth, FindNext(FindHandle), FindHandle) \
	: (FindClose(FindHandle), "")

#define ProcessFind(dir, path, mask, depth) \
	Local[0] = FindFirst(path + mask, faAnyFile), \
	(Local[0] ? ProcessFile(dir, path, depth, Local[0], Local[0]): "")

#define ProcessPath(dir, path, depth)	\
	dir = (dir == '' ? dir : AddBackslash(dir)), path = AddBackslash(SourcePath) + path, \
	(DirExists(path) ? ProcessFind(dir, path, '\*', depth) : ProcessFind(dir, ExtractFilePath(path), '\' + ExtractFileName(path), depth))

#define ProcessAll() ProcessPath("", "OptFiles", 0)

procedure DoWriteIni65(ss: string; const ini, sect: string; var i: int);
var
	s, sha, sha0: string;
begin
	while ss <> '' do
	begin
		s:= SplitStr(ss, ':');
		sha0:= SplitStr(ss, ':');
		sha:= GetSHA1('{app}\' + s);
		if (sha0 <> '') and (sha = sha0) or (sha0 = '') and (sha <> '') then
		begin
			SetIniString(sect, IntToStr(i), s + ':' + sha, ini);
			i:= i + 1;
		end;
	end;
end;

procedure WriteIni65_(const ini: string);
var
	sect: string;
	i: int;
begin
	sect:= 'MM7Patch';
	DeleteIniSection(sect, ini);
	i:= 1;
	//DoWriteIni65('{#ProcessAll}', ini, sect, i);
end;


procedure UpdateTasks;
begin
#if loc
	CheckTask('RusFiles', RussianTaskCheck());
#endif
	CheckTask('lods', LodsTaskCheck());
	CheckTask('water', GetWaterKind > 0);
	CheckTask('ui', not CheckVer($20003));
	CheckTask('icons', IconsTaskCheck(false));
	CheckTask('pal', PalTaskCheck(false));
	CheckTask('tun', TunnelTaskCheck(false));
	CheckTask('dragon', DragonTaskCheck(false));
end;


var
	FilesList, FilesOptList: TStringList;

procedure WriteIni65(const ini: string);
var
	sect, s, line: string;
	i, k: int;
begin
	sect:= 'MM7Patch';
	DeleteIniSection(sect, ini);
	for i:= 0 to FilesList.Count - 1 do
	begin
		s:= Copy(FilesList[i], 7, MaxInt) + ':';  // it starts with '{app}\'
		FilesOptList.Find(s, k);
		if k < FilesOptList.Count then
			line:= FilesOptList[k];
		if (k = FilesOptList.Count) or not SameText(Copy(line, 1, length(s)), s) then
			line:= s + GetSHA1(FilesList[i]);
		SetIniString(sect, IntToStr(i + 1), line, ini);
	end;
end;
	
procedure BeforeInstall;
var
	ini, path: string;
	b: Boolean;
	wk: integer;
begin
	ini:= MMIni;
	if GetIniString('Install', 'PatchLods', #13#10, ini) <> #13#10 then 
		DeleteIniEntry('Install', 'PatchLods', ini);
	if IsIniSectionEmpty('Install', ini) then
		DeleteIniSection('Install', ini);

	if IsIniSectionEmpty('MipmapsBase', ini) then
	begin
		SetIniInt('MipmapsBase', 'hwtrdr*', 128, ini);
		SetIniInt('MipmapsBase', 'hdwtr???', 32, ini);
	end;
	if IsTaskSelected('ui') then
	begin
		SetIniString('Settings', 'UILayout', 'UI', ini);
		if GetIniInt('Settings', 'SupportTrueColor', 1, 0, 0, ini) <> 1 then
			SetIniInt('Settings', 'SupportTrueColor', 1, ini);
	end;

	if not IsMM7 then
	begin
		FilesList:= CreateSortedStringList;
		FilesOptList:= CreateSortedStringList;
		FilesOptList.Text:= {#ProcessAll};
		exit;
	end;

	b:= IsTaskSelected('water');
	wk:= GetWaterKind;
	SavedWaterKind:= wk;
	if b and (wk < 3) and (GetIniInt('Settings', 'HDWTRCount', 7, 0, 0, ini) <> 14) then
	begin
		SetIniInt('Settings', 'HDWTRCount', 14, ini);
		SetIniInt('Settings', 'HDWTRDelay', 15, ini);
	end;
	if not b and (wk > 1) and (GetIniInt('Settings', 'HDWTRCount', 7, 0, 0, ini) <> 7) then
	begin
		DeleteIniEntry('Settings', 'HDWTRCount', ini);
		DeleteIniEntry('Settings', 'HDWTRDelay', ini);
	end;
end;

procedure FileInstalled;
begin
	if (FilesList <> nil) and (Copy(CurrentFileName, 1, 6) = '{app}\') then
		FilesList.Add(CurrentFileName);
end;

procedure AfterInstall;
begin
	if IsTaskSelected('water') then
		DeleteFile(_P('{app}\Data\00 base water.bitmaps.lod'))
	else if BaseWaterCheck then
		DeleteFile(_P('{app}\Data\01 water.bitmaps.lwd'));
	if FilesList <> nil then
		WriteIni65(_P('{app}\Data\mm65_archives.ini'));
end;
