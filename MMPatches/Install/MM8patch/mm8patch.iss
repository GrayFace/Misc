#if false
	#include "..\..\MM6Patch\MM6Patch\mm6patch.iss"
	#include "..\..\MM7Patch\MM7Patch\mm7patch.iss"
#endif
#define m() "mm8"
#define MM() "MM8"
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
Name: "en"; MessagesFile: "compiler:Default.isl";
Name: "ru"; MessagesFile: "compiler:Languages\Russian.isl"; InfoBeforeFile: "rus\{#MM}Patch ReadMe_rus.TXT";

[Messages]
InfoBeforeLabel=Below is the content of {#MM}Patch ReadMe.txt file detailing all changes of the patch.
ru.InfoBeforeLabel=Ниже приведён файл {#MM}Patch ReadMe_rus.txt, описывающий изменения патча.

[CustomMessages]
NoFakeMouseLook=Disable default MM8 pseudo mouse look triggered by right mouse button
ru.NoFakeMouseLook=Отключить встроенное в MM8 недо- управление мышью, активируемое нажатием правой кнопки мыши
ObelisksTask=Fix Unicorn King appearing before all obelisks are visited
ru.ObelisksTask=Исправить появление Короля единорогов до посещения всех обелисков
RussianGameVersion=Russian version of the game
ru.RussianGameVersion=Русская версия игры
LodsTask=Install LOD archives with fixes for maps, game progression and some textures
ru.LodsTask=LOD-архивы с исправлениями для карт, скриптов сюжета и некоторых текстур
WaterTask=Use improved water animation
ru.WaterTask=Использовать улучшенную анимацию воды
IconsTask=Install LOD archive with one interface fix
ru.IconsTask=LOD-архив с одним исправлением для интерфейса
UITask=Use widescreen-friendly flexible interface
ru.UITask=Включить гибкий интерфейс, адаптированный для широкоэкранников
PalTask=Improved Monsters - Fix monsters that look the same in all 3 variations, as well as thunderbirds and plane guardians
ru.PalTask=Улучшенные монстры - Исправить монстров, которые во всех 3 вариациях выглядят одинаково, а также громовых птиц и защитников измерения
CleanMerge=Remove files from previous patch installation with which The World of Enroth is incompatible
ru.CleanMerge=Удалить файлы, оставшиеся от предыдущей установки патча, с которыми Мир Энрота несовместим

[Tasks]
Name: RusFiles; Description: {cm:RussianGameVersion};
Name: ui; Description: {cm:UITask}; Check: UITaskShow;
Name: NoFakeMouseLook; Description: {cm:NoFakeMouseLook}; Check: LookTaskShow;
Name: Obelisks; Description: {cm:ObelisksTask}; Check: ObelisksShow;
Name: water; Description: {cm:WaterTask}; Check: NotMerge;
Name: lods; Description: {cm:LodsTask}; Check: NotMerge;
Name: icons; Description: {cm:IconsTask}; Check: IconsTaskCheck(true);
Name: pal; Description: {cm:PalTask}; Check: PalTaskCheck(true);
Name: CleanMerge; Description: {cm:CleanMerge}; Check: CleanMerge(true);

// must be last in the list:
Name: Dummy; Description: -; Check: CheckUpdateTasks;

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
Source: "Files\*.*"; Excludes: "*.bak"; DestDir: "{app}"; Flags: promptifolder ignoreversion recursesubdirs;
Source: "Data\*"; Excludes: "*.bak"; DestDir: "{app}\Data\"; Tasks: lods;
Source: "OptData\01 water.bitmaps.lwd"; DestDir: "{app}\Data\"; Tasks: water;
Source: "OptData\00 patch.icons.lod"; DestDir: "{app}\Data\"; Tasks: icons;
Source: "OptData\01 mon pal.bitmaps.lod"; DestDir: "{app}\Data\"; Tasks: pal;
Source: "OptData\01 roc.sprites.lod"; DestDir: "{app}\Data\"; Tasks: pal;
Source: "OptFiles\*"; Excludes: "*.bak"; DestDir: "{app}"; Flags: onlyifdoesntexist recursesubdirs;

Source: "rus\*.*"; DestDir: "{app}"; Flags: promptifolder; Tasks: RusFiles;
Source: "rus\{#MM}Patch ReadMe_rus.TXT"; DestDir: "{app}"; Flags: promptifolder; Languages: ru;
Source: "rus\{#MM}Patch ReadMe_rus.TXT"; DestDir: "{app}"; Flags: promptifolder onlyifdestfileexists; Languages: en;
Source: "eng\{#MM}Patch ReadMe.TXT"; DestDir: "{app}"; Flags: promptifolder onlyifdestfileexists; Languages: ru;
Source: "eng\{#MM}Patch ReadMe.TXT"; DestDir: "{app}"; Flags: promptifolder; Languages: en;

[Run]
Filename: "{app}\{#MM}Patch ReadMe.TXT"; Flags: shellexec skipifdoesntexist postinstall skipifsilent; Languages: en; Check: CheckFinishPage;
Filename: "{app}\{#MM}Patch ReadMe_rus.TXT"; Flags: shellexec skipifdoesntexist postinstall skipifsilent; Languages: ru; Check: CheckFinishPage;

[Code]

#include "..\..\MMCommon\MMPatchCommonCode.iss"

function GetInstallDir(param: string): string;
begin
	if not RegQueryStringValue(HKLM, 'SOFTWARE\New World Computing\Might and Magic Day of the Destroyer\1.0', 'AppPath', Result) then
		Result:= _P('{pf}\3DO\Might and Magic VIII');
end;

function NotMerge: Boolean;
begin
	Result:= not (Exists('{app}\Data\mm6.games.lod') and Exists('{app}\Data\mm7.games.lod'));
end;



function LodsTaskCheck: Boolean;
begin
	Result:= not CheckVer($20001) or Exists('{app}\Data\00 patch.games.lod');
end;


function IconsTaskCheck(vis: Boolean): Boolean;
begin
	Result:= {#CheckOptLod('00 patch.icons.lod', 0x20002)};
end;


function PalTaskCheck(vis: Boolean): Boolean;
begin
	Result:= {#CheckOptLod('01 mon pal.bitmaps.lod', 0x20005)};
	if Result <> vis then
		Result:= {#CheckOptLod('01 roc.sprites.lod', 0x20005)};
	Result:= Result and NotMerge;
end;




function RussianTaskCheck: Boolean;
begin
	Result:= (GetIniString('Install', 'GameLanguage', '', _P('{app}\{#m}lang.ini')) = 'rus') or
	 (_P('{language}') = 'ru') and not Exists('{app}\{#MM}Patch ReadMe.TXT');
end;


function LookTaskShow: Boolean;
begin
	Result:= GetIniInt('Settings', 'MouseLookBorder', 200, 0, 0, MMIni) >= 0;
end;


function ObelisksShow: Boolean;
begin
	Result:= not CheckVer($20005);
end;


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

function BaseWaterCheck: Boolean;
begin
	Result:= not IsTaskSelected('water') and NotMerge;
end;


function UITaskShow: Boolean;
begin
	Result:= (UpperCase(GetIniString('Settings', 'UILayout', '', MMIni)) <> 'UI') or
		not GetIniBool('Settings', 'SupportTrueColor', true, MMIni);
end;


function CleanMerge(vis: Boolean): Boolean;
var
	s, ss: string;
begin
	Result:= not NotMerge;
	if not Result then  exit;
	ss:= '00 patch.games.lod;00 patch.T.lod;01 mon pal.bitmaps.lod;01 roc.sprites.lod';
	repeat
		s:= _P('{app}\Data\' + SplitStr(ss, ';'));
		if FileExists(s) then
		begin
			if vis then  exit;
			DeleteFile(s);
		end;
	until ss = '';
	Result:= false;
end;


procedure UpdateTasks;
begin
	CheckTask('RusFiles', RussianTaskCheck());
	CheckTask('lods', LodsTaskCheck());
	CheckTask('NoFakeMouseLook', not CheckVer($10006));
	CheckTask('ui', not CheckVer($20003));
	CheckTask('water', GetWaterKind > 0);
	CheckTask('icons', IconsTaskCheck(false));
	CheckTask('pal', PalTaskCheck(false));
	CheckTask('Obelisks', GetIniBool('Settings', 'FixObelisks', true, MMIni));
	CheckTask('CleanMerge', true);
end;

procedure BeforeInstall;
var
	ini, path: string;
	b: Boolean;
	delay, wk: integer;
begin
	ini:= MMIni;
	if IsTaskSelected('NoFakeMouseLook') then
		SetIniInt('Settings', 'MouseLookBorder', -1, ini);
	delay:= GetIniInt('Settings', 'StartupCopyrightDelay', 1, 0, 0, ini);
	if not CheckVer($20004) and ((delay = 5000) or (delay = 0)) then
		DeleteIniEntry('Settings', 'StartupCopyrightDelay', ini);

	b:= IsTaskSelected('water');
	wk:= GetWaterKind;
	if b and (wk < 3) and (GetIniInt('Settings', 'HDWTRCount', 8, 0, 0, ini) <> 14) then
	begin
		SetIniInt('Settings', 'HDWTRCount', 14, ini);
		SetIniInt('Settings', 'HDWTRDelay', 15, ini);
	end;
	if not b and NotMerge and (wk > 1) and (GetIniInt('Settings', 'HDWTRCount', 8, 0, 0, ini) <> 8) then
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
	if IsTaskSelected('ui') then
	begin
		SetIniString('Settings', 'UILayout', 'UI', ini);
		if GetIniInt('Settings', 'SupportTrueColor', 1, 0, 0, ini) <> 1 then
			SetIniInt('Settings', 'SupportTrueColor', 1, ini);
	end;
	if IsTaskSelected('obelisks') then
		SetIniInt('Settings', 'FixObelisks', 1, MMIni)
	else if ObelisksShow then
		SetIniInt('Settings', 'FixObelisks', 0, MMIni);
end;

procedure AfterInstall;
begin
	if BaseWaterCheck then
		DeleteFile(_P('{app}\Data\01 water.bitmaps.lwd'));
	if IsTaskSelected('CleanMerge') then
		CleanMerge(false);
end;
