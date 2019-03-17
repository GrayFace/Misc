unit RSListBoxHint;

{ *********************************************************************** }
{                                                                         }
{ RSPak                                    Copyright (c) Rozhenko Sergey  }
{ http://sites.google.com/site/sergroj/                                   }
{ sergroj@mail.ru                                                         }
{                                                                         }
{ See copyright notice at the end of RSSysUtils.pas file (MIT license).   }
{                                                                         }
{ *********************************************************************** )

Used internally by RSComboBox and RSListBox

Special thanks to Igor Shevchenko for HSHintComboBox

{ *********************************************************************** }
{$I RSPak.inc}

interface

uses
  Windows, Messages, SysUtils, Classes, Controls, RSQ, Graphics, RSSysUtils,
  CommCtrl, Forms, Math;

type
  PHWnd = ^HWnd;

  TRSListBoxHints = class(TObject)
  protected
    LastIndex:int;
    Font: TFont;
    HintWindow: THintWindow;
    function GetTextRight(const Text:string; r:TRect):int;
    procedure UpdateHint(const p:TPoint); overload;
  public
    Handle: HWnd;
    Columns: int;
    constructor Create(AFont:TFont);
    destructor Destroy; override;
    procedure BeforeWndProc(var Msg:TMessage);
    procedure AfterWndProc(var Msg:TMessage);
    procedure UpdateHint; overload;
    procedure HideHint;
  end;

implementation

type
  TListBoxTip = class(THintWindow)
  protected
    procedure CreateParams(var Params:TCreateParams); override;
    procedure NCPaint(DC:HDC); override;
    procedure Paint; override;
  public
    Compact: Boolean;
    procedure ActivateHint(Rect:TRect; const AHint:string); override;
    function CalcHintRect(MaxWidth: Integer; const AHint: string;
      AData: Pointer): TRect; override;
  end;

procedure TListBoxTip.CreateParams(var Params:TCreateParams);
begin
  inherited CreateParams(Params);
  with Params.WindowClass do
    Style:= Style and not CS_DROPSHADOW;
  with Params do
    ExStyle:= ExStyle or WS_EX_TOPMOST;
end;

procedure TListBoxTip.NCPaint(DC:HDC);
begin
  with TBrush.Create do
  try
    Color:=clBlack;
    FrameRect(DC, Rect(0, 0, Width, Height), Handle);
  finally
    Free;
  end;
end;

procedure TListBoxTip.Paint;
var
  R: TRect;
begin
  R := ClientRect;
  if Compact then
   inc(R.Left, 1)
  else
   inc(R.Left, 2);
  DrawText(Canvas.Handle, PChar(Caption), -1, R, DT_LEFT or DT_NOPREFIX or
    DT_WORDBREAK or DrawTextBiDiModeFlagsReadingOnly);
end;

procedure TListBoxTip.ActivateHint(Rect:TRect; const AHint:string);
var a:TAnimateWindowProc;
begin
  Canvas.Font.Color:=Screen.HintFont.Color;
  dec(Rect.Bottom, 4); // Потом inherited ActivateHint делает inc на 4

  if not Compact then
  begin
    dec(Rect.Left);
    inc(Rect.Right, 2);
  end else
    dec(Rect.Left, 2);

  dec(Rect.Top);
  inc(Rect.Bottom);

  a:=@AnimateWindowProc;
  @AnimateWindowProc:=nil;
  inherited ActivateHint(Rect, AHint);
  @AnimateWindowProc:=@a;
end;

function TListBoxTip.CalcHintRect(MaxWidth: Integer; const AHint: string; AData: Pointer): TRect;
begin
  Result:= inherited CalcHintRect(MaxWidth, AHint, AData);
  dec(Result.Right, 4);
  dec(Result.Bottom, 2);
end;

{
******************************* TRSListBoxHints ********************************
}
constructor TRSListBoxHints.Create(AFont:TFont);
begin
  LastIndex:=-1;
  Font:=AFont;
  HintWindow:=TListBoxTip.Create(nil);
  HintWindow.Color:=clInfoBk;
end;

destructor TRSListBoxHints.Destroy;
begin
  HintWindow.Free;
  inherited;
end;

procedure TRSListBoxHints.BeforeWndProc(var Msg:TMessage);
begin
  case Msg.Msg of
    WM_MOUSEMOVE:
      with TWMMouseMove(Msg) do
        UpdateHint(Point(XPos, YPos));
    WM_SHOWWINDOW:
      if Msg.WParam = 0 then
        HideHint;
    CM_MOUSELEAVE:
      HideHint;
    CM_MOUSEENTER, WM_NCMOUSEMOVE:
      UpdateHint;
  end;
end;

procedure TRSListBoxHints.AfterWndProc(var Msg:TMessage);
begin
  case Msg.Msg of
    WM_VSCROLL, WM_MOUSEWHEEL:
      UpdateHint;
  end;
end;

procedure TRSListBoxHints.UpdateHint;
var p:TPoint;
begin
  if GetCursorPos(p) and Windows.ScreenToClient(Handle, p) then
    UpdateHint(p);
end;

procedure TRSListBoxHints.HideHint;
begin
  HintWindow.ReleaseHandle;
  LastIndex:=-1;
end;

function GetItemText(h:hwnd; i:int):string;
begin
  SetLength(Result, SendMessage(h, LB_GETTEXTLEN, i, 0));
  SendMessage(h, LB_GETTEXT, i, int(Result));
end;

function TRSListBoxHints.GetTextRight(const Text:string; r:TRect):int;
var DC:HDC; old:HFONT;
begin
  DC:= GetDC(Handle);
  try
    old:=SelectObject(DC, Font.Handle);
    if Columns<>0 then
      inc(r.Left)
    else
      inc(r.Left, 2);
    DrawText(DC, ptr(Text), length(Text), r, DT_CALCRECT or DT_NOPREFIX);
    SelectObject(DC, old);
    Result:=r.Right;
  finally
    ReleaseDC(Handle, DC);
  end;
end;

procedure TRSListBoxHints.UpdateHint(const p:TPoint);
var i:int; r, r1:TRect; Text:string;
begin
  GetClientRect(Handle, r);
  if PtInRect(r, p) then
  begin
    i:=SendMessage(Handle, LB_ITEMFROMPOINT, 0, MakeLParam(p.x, p.y));
    RSWin32Check(i<>LB_ERR);
    if i shr 16 <> 0 then
      i:=-1;
  end else
    i:=-1;
  if i=LastIndex then exit;
  LastIndex:=i;
  if i>=0 then
  begin
    Text:=GetItemText(Handle, i);
    RSWin32Check(SendMessage(Handle, LB_GETITEMRECT, i, int(@r))<>LB_ERR);
    if GetTextRight(Text, r)>r.Right then
      with HintWindow do
      begin
        MapWindowPoints(self.Handle, 0, r, 2); // Client To Screen
        Canvas.Font:=self.Font;

         // Calculate Hint Window rect
        TListBoxTip(HintWindow).Compact:=Columns<>0;
        r1:=CalcHintRect(Screen.Width, Text, nil);
        if r.Right < r.Left + r1.Right then
          r.Right:= r.Left + r1.Right;
        r.Bottom:=max(r.Top + r1.Bottom, r.Bottom);

        ActivateHint(r, Text);
        exit; // Don't hide hint window
      end;
  end;
  HintWindow.ReleaseHandle;
end;

end.
