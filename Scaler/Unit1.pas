unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, RSQ, RSSysUtils, RSSysUtilsOld, StdCtrls, ComCtrls, IniFiles,
  RSWinController, Unit2, XPMan, ExtCtrls;

type
  TIniCheck = record
    Control: TCheckBox;
    Name: string;
  end;

  TForm1 = class(TForm)
    CheckBlackBack: TCheckBox;
    CheckScaling: TCheckBox;
    Label1: TLabel;
    Label2: TLabel;
    HotKey1: THotKey;
    RSWinController1: TRSWinController;
    ButtonControls: TButton;
    CheckOnlyControls: TCheckBox;
    CheckWindowed: TCheckBox;
    TrayIcon1: TTrayIcon;
    CheckMax: TCheckBox;
    procedure TrayIcon1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ButtonControlsClick(Sender: TObject);
    procedure RSWinController1WndProc(Sender: TObject; var m: TMessage;
      var Handled: Boolean; const NextWndProc: TWndMethod);
    procedure HotKey1Change(Sender: TObject);
    procedure CheckBlackBackClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WMSysCommand(var msg: TWMSysCommand); message WM_SYSCOMMAND;
    procedure WndProc(var m: TMessage); override;
  public
    IniChecks: array of TIniCheck;
    IniRead: Boolean;
    procedure AddIniCheck(const name: string; control: TCheckBox);
    procedure LoadIni;
    procedure SaveIni;
    procedure UpdateHotKey(del: Boolean = true);
    procedure UpdateEnabled;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

const
  HotKeyId = 1;
  DllName = 'Scaler';

procedure ForceSetForegroundWindow(w: HWND);
var
  last: DWORD;
begin
  SystemParametersInfo(SPI_GETFOREGROUNDLOCKTIMEOUT, 0, @last, 0);
  SystemParametersInfo(SPI_SETFOREGROUNDLOCKTIMEOUT, 0, nil, 0);
  BringWindowToTop(w); // IE 5.5 related hack
  SetForegroundWindow(w);
  SystemParametersInfo(SPI_SETFOREGROUNDLOCKTIMEOUT, 0, ptr(last), 0);
end;
  
function Inject(hProcess:DWord; LibName:string):boolean; overload;
var i, j:DWord; InjAddr:pointer;
begin
  Result:=RSCreateRemoteCopy(PChar(LibName), InjAddr,
                                 length(LibName)+1, hProcess, i);
  if not Result then exit;
  i := CreateRemoteThread(hProcess, nil, 0,
         GetProcAddress(GetModuleHandle('kernel32.dll'), 'LoadLibraryA'),
         InjAddr, 0, j);
  Result := i<>0;
  if Result then CloseHandle(i)
  else RaiseLastOSError;
end;

function InjectPID(pid: DWORD; LibName:string):boolean; overload;
var pr:DWord;
begin
  RSEnableDebugPrivilege(true);
  pr:= OpenProcess(PROCESS_ALL_ACCESS, false, pID);
  Result:= Inject(pr, LibName);
  if pr <> 0 then
    CloseHandle(Pr);
end;

procedure TForm1.AddIniCheck(const name: string; control: TCheckBox);
var
  i: int;
begin
  i:= length(IniChecks);
  SetLength(IniChecks, i + 1);
  IniChecks[i].Control:= control;
  IniChecks[i].Name:= name;
end;

procedure TForm1.ButtonControlsClick(Sender: TObject);
begin
  Application.CreateForm(TForm2, Form2);
  UnregisterHotKey(Handle, HotKeyId);
  try
    Form2.ShowModal;
  finally
    FreeAndNil(Form2);
    UpdateHotKey(false);
  end;
end;

procedure TForm1.CheckBlackBackClick(Sender: TObject);
begin
  SaveIni;
  UpdateEnabled;
end;

procedure TForm1.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.WinClassName:='Scaler Main Form';
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  AddIniCheck('BlackBackground', CheckBlackBack);
  AddIniCheck('NonIntegerScaling', CheckScaling);
  AddIniCheck('Windowed', CheckWindowed);
  AddIniCheck('Maximized', CheckMax);
  AddIniCheck('OnlyControls', CheckOnlyControls);
  LoadIni;
  Application.Title:= Caption;
  UpdateHotKey(false);
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  ShowWindow(Application.Handle, SW_HIDE);
end;

procedure TForm1.HotKey1Change(Sender: TObject);
begin
  SaveIni;
  UpdateHotKey;
end;

procedure TForm1.LoadIni;
var
  i: int;
begin
  with TIniFile.Create(AppPath + DllName + '.ini') do
    try
      for i:= 0 to high(IniChecks) do
        with IniChecks[i] do
          Control.Checked:= ReadBool('Options', Name, Control.Checked);
      HotKey1.HotKey:= ReadInteger('Options', 'HotKey', HotKey1.HotKey);
    finally
      Free;
    end;
  IniRead:= true;
  UpdateEnabled;
end;

procedure TForm1.RSWinController1WndProc(Sender: TObject; var m: TMessage;
  var Handled: Boolean; const NextWndProc: TWndMethod);
var
  i: int;
begin
  NextWndProc(m);
  Handled:= true;
  if (m.Msg = WM_KEYDOWN) and (m.WParam = VK_RETURN) then
  begin
    i:= VK_RETURN;
    if GetKeyState(VK_SHIFT) < 0 then
      i:= i or scShift;
    if GetKeyState(VK_CONTROL) < 0 then
      i:= i or scCtrl;
    if GetKeyState(VK_MENU) < 0 then
      i:= i or scAlt;
    HotKey1.HotKey:= i;
    HotKey1Change(HotKey1);
  end;
end;

procedure TForm1.SaveIni;
var
  i: int;
begin
  if not IniRead then  exit;
  with TIniFile.Create(AppPath + DllName + '.ini') do
    try
      for i:= 0 to high(IniChecks) do
        with IniChecks[i] do
          WriteBool('Options', Name, Control.Checked);
      WriteInteger('Options', 'HotKey', HotKey1.HotKey);
    finally
      Free;
    end;
end;

procedure TForm1.TrayIcon1Click(Sender: TObject);
begin
  Show;
  ForceSetForegroundWindow(Handle);
end;

procedure TForm1.UpdateEnabled;
begin
  CheckBlackBack.Enabled:= not CheckOnlyControls.Checked;
  CheckScaling.Enabled:= not CheckOnlyControls.Checked;
  CheckWindowed.Enabled:= not CheckOnlyControls.Checked;
  CheckMax.Enabled:= not CheckOnlyControls.Checked and CheckWindowed.Checked;
end;

procedure TForm1.UpdateHotKey(del: Boolean);
var
  i, j: int;
begin
  if del then
    UnregisterHotKey(Handle, HotKeyId);
  i:= HotKey1.HotKey;
  j:= 0;
  if i and scShift <> 0 then
    inc(j, MOD_SHIFT);
  if i and scCtrl <> 0 then
    inc(j, MOD_CONTROL);
  if i and scAlt <> 0 then
    inc(j, MOD_ALT);
  RegisterHotKey(Handle, HotKeyId, j, byte(i));
end;

procedure TForm1.WMSysCommand(var msg: TWMSysCommand);
var
  cmd: int;
begin
  cmd:= msg.CmdType and not 15;
  if (cmd = SC_MINIMIZE) or (cmd = SC_RESTORE) and not Visible then
    Visible:= (cmd = SC_RESTORE)
  else
    inherited;
end;

procedure TForm1.WndProc(var m: TMessage);
var
  w: HWND;
begin
  inherited;
  if (m.Msg = WM_HOTKEY) and (m.WParam = HotKeyId) then
  begin
    w:= GetForegroundWindow;
    if (w = 0) or (w = Handle) or IsZoomed(w) or (Copy(TRSWnd(w).ClassName, 4, MaxInt) <> 'MainClassTh') then
      exit;
    InjectPID(TRSWnd(w).ProcessId, AppPath + DllName + '.dll');
  end;
  if (m.Msg = WM_ACTIVATE) and (m.WParam <> WA_INACTIVE) then
    if HotKey1.Focused then
      CheckBlackBack.SetFocus;
end;

end.
