#if false
[Code]
#endif

procedure UpdateTasks; forward;
procedure BeforeInstall; forward;
procedure AfterInstall; forward;

type int = Integer;

function _P(const s:string): string;
begin
	Result:= ExpandConstant(s);
end;

function GetMD5(s: string): string;
begin
	s:= _P(s);
	Result:= '';
	if FileExists(s) then
		Result:= GetMD5OfFile(s);
end;

function GetSHA1(s: string): string;
begin
	s:= _P(s);
	Result:= '';
	if FileExists(s) then
		Result:= GetSHA1OfFile(s);
end;

function Exists(const s: string): Boolean;
begin
	Result:= FileExists(_P(s));
end;

// allows trailing delimiter that won't produce an empty string
function SplitStr(var s: string; const sep: string): string;
var
	i: int;
begin
	i:= Pos(sep, s);
	if i <= 0 then
		i:= length(s) + 1;
	Result:= Copy(s, 1, i - 1);
	s:= Copy(s, i + 1, MaxInt);
end;

function HasParam(const name: string): Boolean;
var
	i: int;
begin
	Result:= true;
	for i:= 1 to ParamCount do
		if LowerCase(ParamStr(i)) = name then
			exit;
	Result:= false;
end;

function CreateSortedStringList: TStringList;
begin
	Result:= TStringList.Create;
	Result.Duplicates:= dupIgnore;
	Result.Sorted:= true;
end;

function MMIni: string;
begin
	Result:= _P('{app}\{#m}.ini');
end;

function CheckVer(ver: Cardinal): Boolean;
var
	ms, ls: Cardinal;
begin
	Result:= GetVersionNumbers(_P('{app}\{#m}patch.dll'), ms, ls) and (ms >= ver);
end;

function CheckVer2(ver, ver2: Cardinal): Boolean;
var
	ms, ls: Cardinal;
begin
	Result:= GetVersionNumbers(_P('{app}\{#m}patch.dll'), ms, ls) and (ms >= ver) and (ms <= ver2);
end;

function CheckOptLod(vis: Boolean; path, md5: string; ver: Integer): Boolean;
begin
	if vis then
		Result:= (GetMD5(path) <> md5)
	else
		Result:= Exists(path) or not CheckVer(ver);
end;


function CheckFinishPage: Boolean;
begin
	Result:= not (HasParam('/skipfinished') or WizardSilent);
end;

var
	WasPage: Boolean;

function ShouldSkipPage(PageID: Integer): Boolean;
begin
	Result:= (PageID in [wpInfoBefore, wpSelectDir]) and not WasPage and HasParam('/skipdirselect')
		 or (PageID = wpFinished) and not CheckFinishPage;
	WasPage:= WasPage or not Result;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
	if CurStep = ssInstall then
		BeforeInstall
	else if CurStep = ssPostInstall then
		AfterInstall;
end;

#if false
{procedure CheckTask(const msg: string; b: Boolean);
var
	i: int;
begin
	i:= WizardForm.TasksList.Items.IndexOf(CustomMessage(msg));
	if i >= 0 then
		WizardForm.TasksList.Checked[i]:= b;
end;}
#endif

procedure CheckTask(task: string; b: Boolean);
begin
	if not b then
		task:= '!' + task;
	WizardSelectTasks(task);
end;

var
	LastPath: string;

function CheckUpdateTasks: Boolean;
begin
	Result:= false;
	if _P('{app}') <> LastPath then
		UpdateTasks;
	LastPath:= _P('{app}');
end;

#if false
(* // doesn't rely on a dummy task, but wrong checkbox states are displayed before right ones are calculated
procedure CurPageChanged(CurPageID: Integer);
begin
	if (CurPageID <> wpSelectTasks) or (_P('{app}') = LastPath) then  exit;
	LastPath:= _P('{app}');
	UpdateTasks;
end;
*)

(* // just a test of showing tasks in style of components selection
procedure InitializeWizard;
var
	a: TNewCheckListBox;
begin
	with WizardForm.TasksList do
	begin
		a:= WizardForm.ComponentsList;
		Flat:= a.Flat;
		MinItemHeight:= a.MinItemHeight;
		Offset:= a.Offset;
		BorderStyle:= a.BorderStyle;
		Font:= a.Font;
		Color:= a.Color;
		ShowLines:= a.ShowLines;
		WantTabs:= a.WantTabs;
		ParentBackground:= a.ParentBackground;
	end;
end;
*)
#endif