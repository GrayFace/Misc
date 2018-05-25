unit RSC;

interface

uses
  SysUtils, Windows, Classes, Controls, Graphics, Variants, RSQ, RSSpeedButton,
  Menus, Messages, RSSysUtils;

procedure EnableArr(const Arr:array of TControl; v:boolean);
procedure ShowArr(const Arr:array of TControl; v:boolean);
function SqDifference(cl1,cl2:TColor):integer;
procedure msgz(Args:array of const); overload;
procedure msgz(a:Variant); overload;
procedure msgz(a,b:Variant); overload;
procedure msgz(const r:TRect); overload;
procedure msgz(const pt:TPoint); overload;
procedure msgH(Args:array of int); overload;
procedure MsgArr(b:array of integer);
//function IfThen(b:boolean; t,f:Variant):Variant;

procedure ShowTempPopup(Button:TRSSpeedButton; Menu:TPopupMenu);
procedure ShowRightPopup(Button:TRSSpeedButton; Menu:TPopupMenu);

procedure AppendDebugLog(const s:string);

type
  TRSThreadProc = procedure(Thread:TThread; Param:int) of object;

procedure RSThreadExec(const AMethod:TRSThreadProc; AParam:int=0); overload;

procedure RSThreadExec(AMethod:pointer; AParam1:int=0; AParam2:int=0); overload;
  // procedure(Thread:TThread; Param1, Param2:int);
var
  RSThreadProcsNum:integer;

implementation

procedure EnableArr(const Arr:array of TControl; v:boolean);
var i:integer;
begin
  for i:=Low(Arr) to High(Arr) do
    Arr[i].Enabled:=v;
end;

procedure ShowArr(const Arr:array of TControl; v:boolean);
var i:integer;
begin
  for i:=Low(Arr) to High(Arr) do
    Arr[i].Visible:=v;
end;

function SqDifference(cl1,cl2:TColor):integer;
begin
  cl1:=ColorToRGB(cl1);
  cl2:=ColorToRGB(cl2);
  Result:=sqr(cl1 and $ff - cl2 and $ff) +
          sqr(cl1 shr 8 and $ff - cl2 shr 8 and $ff) +
          sqr(cl1 shr 16 and $ff - cl2 shr 16 and $ff);
end;

function MyBoolToStr(b:Boolean):string;
begin
  if b then Result:='T'
  else Result:='F';
end;

procedure msg(s:string); overload;
begin
  MessageBox(0,pchar(s),'',0);
end;

function VarRecToStr(a:TVarRec):string;
begin
  with a do
    case VType of
      vtInteger:    Result:=IntToStr(VInteger);
      vtBoolean:    Result:=MyBoolToStr(VBoolean);
      vtChar:       Result:=VChar;
      vtExtended:   Result:=FloatToStr(VExtended^);
      vtString:     Result:=VString^;
      vtPointer:    Result:=IntToHex(DWord(VPointer),8);
      vtPChar:      Result:=VPChar;
      vtObject:     Result:=VObject.ClassName;
      vtClass:      Result:=VClass.ClassName;
      vtWideChar:   Result:=VWideChar;
      vtPWideChar:  Result:=VPWideChar;
      vtAnsiString: Result:=string(VAnsiString);
      vtCurrency:   Result:=CurrToStr(VCurrency^);
      vtVariant:    Result:=string(VVariant^);
      vtWideString: Result:=WideString(VWideString);
      vtInt64:      Result:=IntToStr(VInt64^);

    end;
end;

function VarToStr(a:Variant):string;
begin
  if VarType(a)=varBoolean then Result:=MyBoolToStr(a)
  else Result:=string(a);
end;

procedure msgz(Args:array of const); overload;
var i:integer; s:string;
begin
  s := '';
  for i := Low(Args) to High(Args) do
    s:=s + VarRecToStr(Args[i]) + ' ';
  msg(s);
end;

procedure msgz(a:Variant); overload;
begin
  msg(VarToStr(a)+' ');
end;

procedure msgz(a,b:Variant); overload;
begin
  msg(VarToStr(a)+' '+VarToStr(b)+' ');
end;

procedure msgz(const r:TRect); overload;
begin
  MessageBox(0,pchar(IntToStr(r.Left)+' '+IntToStr(r.Top)+'  -  '+IntToStr(r.Right)+' '+IntToStr(r.Bottom)),'',0);
end;

procedure msgz(const pt:TPoint); overload;
begin
  MessageBox(0,pchar(IntToStr(pt.X)+' '+IntToStr(pt.Y)),'',0);
end;

procedure msgH(Args:array of int); overload;
var i:integer; s:string;
begin
  s:='';
  for i:=0 to length(Args)-1 do
    s:=s+IntToHex(Args[i],8)+' ';
  msg(s);
end;

procedure MsgArr(b:array of integer);
var x:integer; s:string;
begin
  s:='';
  for x:=0 to length(b)-1 do
  begin
    if x<>0 then s:=s+' ';
    s:=s+IntToStr(b[x]);
  end;
  msg(s);
end;

function IfThen(b:boolean; t,f:Variant):Variant;
begin
  if b then Result:=t else Result:=f;
end;


{ShowTempPopup}

var Hook:HHOOK;

function HookProc(Code, wParam:int; lParam:PMsg):int; stdcall;
var b:boolean;
begin
  if Code<0 then
  begin
    Result:=CallNextHookEx(Hook, Code, wParam, int(lParam));
    exit;
  end;
  with lParam^ do
    if message=WM_LBUTTONUP then
    begin
      b:= TRSWnd(WindowFromPoint(pt)).Style and WS_POPUP = 0;
      if b then
        SendMessage(PopupList.Window, WM_CANCELMODE, 0, 0);
      UnhookWindowsHookEx(Hook);
      Hook:=0;
      if not b then
        mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
      mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
    end;
  CallNextHookEx(Hook, Code, wParam, int(lParam));
  Result:=0;
end;

procedure ShowTempPopup(Button:TRSSpeedButton; Menu:TPopupMenu);
var p:TPoint;
begin
  with Button.BoundsRect do
  begin
    p.X:=Left;
    p.Y:=Bottom;
  end;
  p:=Button.Parent.ClientToScreen(p);
  Hook:=SetWindowsHookEx(WH_MSGFILTER, @HookProc, 0, GetCurrentThreadId);
  Button.ForceDown:=true;
  try
    Menu.Popup(p.x, p.y);
  finally
    Button.ForceDown:=false;
    UnhookWindowsHookEx(Hook);
    Hook:=0;
  end;
end;

procedure ShowRightPopup(Button:TRSSpeedButton; Menu:TPopupMenu);
var p:TPoint; r:TRect;
begin
  if Menu.Items.Count = 0 then  exit;
  r:= Button.BoundsRect;
  MapWindowPoints(Button.Parent.Handle, 0, r, 2);
  with r do
  begin
    p.X:= Left;
    p.Y:= Bottom;
  end;
  Button.ForceDown:=true;
  try
{$IFNDEF D2006}
    Button.Perform(CM_MOUSELEAVE, 0, 0);
{$ENDIF}    
    Menu.Popup(p.x, p.y);
  finally
    Button.ForceDown:= false;
  end;
end;

type
  TMyProcedure = procedure(Thread:TThread; Param1, Param2:int);

type
  TRSThreadedProc = class(TThread)
  private
    { Private declarations }
  protected
    procedure Execute; override;
  public
    Method:TMyProcedure;
    Param0:int;
    Param1:int;
    Param2:int;
  end;

procedure TRSThreadedProc.Execute;
begin
  FreeOnTerminate:=true;
  try
    try
      Method(self, Param1, Param2);
    except
      ShowException(ExceptObject, ExceptAddr);
    end;
  finally
    InterlockedDecrement(RSThreadProcsNum);
  end;
end;

procedure RSThreadExec(const AMethod:TRSThreadProc; AParam:int=0);
var a:TRSThreadedProc;
begin
  a:=TRSThreadedProc.Create(true);
  with a do
  begin
    Method:=TMethod(AMethod).Code;
    Param0:=int(TMethod(AMethod).Data);
    Param1:=int(a);
    Param2:=AParam;
    Resume;
  end;
end;

procedure RSThreadExec(AMethod:pointer; AParam1:int=0; AParam2:int=0);
var a:TRSThreadedProc;
begin
  InterlockedIncrement(RSThreadProcsNum);
  a:=TRSThreadedProc.Create(true);
  with a do
  begin
    Method:=AMethod;
    Param0:=int(a);
    Param1:=AParam1;
    Param2:=AParam2;
    Resume;
  end;
end;

procedure AppendDebugLog(const s:string);
const
  Sep = '===================================================================' +
        '============='#13#10#13#10;
begin
  RSAppendTextFile(AppPath + 'ErrorLog.txt', s + Sep);
end;

end.
