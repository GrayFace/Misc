unit RSCommon;

{ *********************************************************************** }
{                                                                         }
{ RSPak                                    Copyright (c) Rozhenko Sergey  }
{ http://sites.google.com/site/sergroj/                                   }
{ sergroj@mail.ru                                                         }
{                                                                         }
{ See copyright notice at the end of RSSysUtils.pas file (MIT license).   }
{                                                                         }
{ *********************************************************************** }
{$I RSPak.inc}

interface

uses
  Windows, Classes, Controls, Messages, {SysUtils,} Graphics, StdCtrls, RSQ;

type
  TRSProcedure = procedure of object;

  TRSWndProcEvent = procedure (Sender: TObject; var m: TMessage;
          var Handled: Boolean; const NextWndProc: TWndMethod) of object;

  TRSCreateParamsEvent = procedure(Sender: TWinControl; var Params: TCreateParams) of object;

  TRSCreateDragWindowEvent = procedure(Sender: TWinControl; Window: HWnd) of object;

  TRSControlState = set of (RScsDisabled, RScsMouseIn, RScsFocused,
                            RScsMouseDown, RScsSpaceDown);

  TRSCustomControl = class(TCustomControl)
  public
    property Canvas;
  end;

{
  TRSGraphicPaintEvent = procedure (Sender:TGraphicControl;
    DefaultPaint:TRSProcedure) of object;
}

  TRSWndPaintEvent = procedure (Sender:TRSCustomControl; State:TRSControlState;
    DefaultPaint:TRSProcedure) of object;

  TRSControlArray = array of TControl;

  TRSControlProps = record
    MouseIn: Boolean;
{$IFNDEF D2006}
    OnMouseEnter: TNotifyEvent;
    OnMouseLeave: TNotifyEvent;
{$ENDIF}
    OnWndProc: TRSWndProcEvent;
  end;
  PRSControlProps = ^TRSControlProps;

  TRSWinControlProps = record
    MouseIn: Boolean;
{$IFNDEF D2006}
    OnMouseEnter: TNotifyEvent;
    OnMouseLeave: TNotifyEvent;
{$ENDIF}
    OnWndProc: TRSWndProcEvent;
    State: TRSControlState;
  end;
  PRSWinControlProps = ^TRSWinControlProps;

procedure RSProcessProps(self:TControl; var Msg:TMessage;
            var Props:TRSControlProps); overload;

procedure RSProcessProps(self:TWinControl; var Msg:TMessage;
            var Props:TRSWinControlProps); overload;

function RSProcessState(var Msg:TMessage; var FState:TRSControlState):TRSControlState;

procedure RSEditWndProcAfter(c:TCustomEdit; const Msg:TMessage; var FSelAnchor:int);
procedure RSEditEmulateMouse(c:TCustomEdit; Point:int; Flags:int = -1);
function RSEditGetCaret(c:TCustomEdit; FSelAnchor:int):int;
procedure RSEditGetSelection(c:TCustomEdit; var Anchor, Caret:Integer; FSelAnchor:int);
procedure RSEditSetSelection(c:TCustomEdit; Anchor, Caret: int);

procedure RSDoubleBufferedPaint(Self:TWinControl; var m:TWMPaint);

implementation

procedure RSProcessProps(self:TControl; var Msg:TMessage;
            var Props:TRSControlProps);
begin
  with Props do
    case Msg.Msg of
      CM_MouseEnter:
        if not MouseIn then
        begin
          MouseIn:=true;
{$IFNDEF D2006}
          if assigned(OnMouseEnter) then OnMouseEnter(self);
{$ENDIF}
        end;
      CM_MouseLeave:
        if MouseIn then
        begin
          MouseIn:=false;
{$IFNDEF D2006}
          if assigned(OnMouseLeave) then OnMouseLeave(self);
{$ENDIF}
        end;
    end;
end;


procedure RSProcessProps(self:TWinControl; var Msg:TMessage;
            var Props:TRSWinControlProps);
begin
  RSProcessState(Msg, Props.State);
  RSProcessProps(self, Msg, PRSControlProps(@Props)^);
end;

function RSProcessState(var Msg:TMessage; var FState:TRSControlState):TRSControlState;
var last:TRSControlState;
begin
  last:=FState;
  case Msg.Msg of
    WM_ENABLE:
      if TWMEnable(Msg).Enabled then
        FState:=FState+[RScsDisabled]
      else
        FState:=FState-[RScsDisabled];
    WM_KEYDOWN:
      if TWMKeyDown(Msg).CharCode=vk_space then
        FState:=FState+[RScsSpaceDown];
    WM_KEYUP:
      if TWMKeyUp(Msg).CharCode=vk_space then
        FState:=FState-[RScsSpaceDown];
    WM_KILLFOCUS:
      FState:=FState-[RScsFocused];
    WM_LBUTTONDOWN:
      FState:=FState+[RScsMouseDown];
    WM_LBUTTONUP:
      FState:=FState-[RScsMouseDown];
    WM_SETFOCUS:
      FState:=FState+[RScsFocused];
    CM_MOUSEENTER:
      FState:=FState+[RScsMouseIn];
    CM_MOUSELEAVE:
      FState:=FState-[RScsMouseIn];
  end;
  Result:=TRSControlState( byte(FState) xor byte(last) );
end;

procedure RSEditWndProcAfter(c:TCustomEdit; const Msg:TMessage;
   var FSelAnchor:int);
var i,j:int;
begin
  case Msg.Msg of
    WM_LBUTTONDOWN, WM_LBUTTONDBLCLK:
      if Msg.WParam and MK_SHIFT = 0 then
        FSelAnchor:=c.SelStart;

    EM_SETSEL:
      FSelAnchor:=c.SelStart;

    CN_COMMAND:
      if TWMCommand(Msg).NotifyCode = EN_CHANGE then
        FSelAnchor:=c.SelStart;

    WM_KEYDOWN:
    begin
      c.Perform(EM_GETSEL, int(@i), int(@j));
      if i=j then
        FSelAnchor:=i;
    end;
  end;
end;

procedure RSEditEmulateMouse(c:TCustomEdit; Point:int; Flags:int = -1);
var m:TMessage;
begin
  if Point shr 16 in [0,1] then
    Point:=word(Point)+$20000;

  with m do
  begin
    if Flags=-1 then
    begin
      WParam:=0;
      if GetKeyState(VK_SHIFT)<0 then
        WParam:=MK_SHIFT;
    end else
      WParam:=Flags;
    WParam:=WParam or MK_LBUTTON;
    LParam:=Point;
    Msg:=WM_LBUTTONDOWN;
    c.DefaultHandler(m);
    WParam:=WParam and not MK_LBUTTON;
    Msg:=WM_LBUTTONUP;
    c.DefaultHandler(m);
  end;
end;

function RSEditGetCaret(c:TCustomEdit; FSelAnchor:int):int;
var i:int;
begin
  c.Perform(EM_GETSEL, int(@i), int(@Result));
  if Result=FSelAnchor then
    Result:=i;
end;

procedure RSEditGetSelection(c:TCustomEdit; var Anchor, Caret:Integer; FSelAnchor:int);
begin
  c.Perform(EM_GETSEL, int(@Anchor), int(@Caret));
  if Caret=FSelAnchor then
    zSwap(Anchor, Caret);
end;

procedure RSEditSetSelection(c:TCustomEdit; Anchor, Caret: int);
begin
  with c do
    if Caret<Anchor then
    begin
      windows.SetFocus(Handle);
      Perform(EM_SETSEL, Caret, Caret);
      Perform(EM_SCROLLCARET, 0, 0);
      Perform(EM_SETSEL, Anchor, Anchor);
      Caret:=Perform(EM_POSFROMCHAR, Caret, 0);
      if Caret=-1 then
        Caret:=$7fff7fff;
      RSEditEmulateMouse(c, Caret, MK_SHIFT);
    end else
      Perform(EM_SETSEL, Anchor, Caret)
end;

procedure RSDoubleBufferedPaint(Self:TWinControl; var m:TWMPaint);
var
  DC, MemDC: HDC;
  MemBitmap, OldBitmap: HBITMAP;
  PS: TPaintStruct;
//  WasDB: Boolean;
begin
  //zCount;
  with Self do
  begin
    BeginPaint(Handle, PS);
    with PS.rcPaint do
    try
      if Left = Right then  exit;
      DC:= GetDC(0);
      MemBitmap:= CreateCompatibleBitmap(DC, Right, Bottom);
      ReleaseDC(0, DC);
      DC:= PS.hdc;
      MemDC:= CreateCompatibleDC(0);
      OldBitmap:= SelectObject(MemDC, MemBitmap);
      {
      WasDB:= DoubleBuffered;
      DoubleBuffered:= true;
      }
      try
        IntersectClipRect(MemDC, Left, Top, Right, Bottom);
        {
        with PS.rcPaint do
          BitBlt(MemDC, Left, Top, Right, Bottom, DC, Left, Top, SRCCOPY);
        }
        Perform(WM_ERASEBKGND, MemDC, MemDC);
        m.DC := MemDC;
        Self.WindowProc(TMessage(m));
        m.DC := 0;
        BitBlt(DC, Left, Top, Right, Bottom, MemDC, Left, Top, SRCCOPY);
      finally
        {
        DoubleBuffered := WasDB;
        }
        SelectObject(MemDC, OldBitmap);
        DeleteDC(MemDC);
        DeleteObject(MemBitmap);
      end;
    finally
      EndPaint(Handle, PS);
    end;
  end;
  //zStopCount(50);
end;

end.

