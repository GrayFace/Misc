unit RSComboBox;

{ *********************************************************************** }
{                                                                         }
{ RSPak                                    Copyright (c) Rozhenko Sergey  }
{ http://sites.google.com/site/sergroj/                                   }
{ sergroj@mail.ru                                                         }
{                                                                         }
{ See copyright notice at the end of RSSysUtils.pas file (MIT license).   }
{                                                                         }
{ *********************************************************************** )

 Height may be changed in OwnerDraw mode.
 Button is drawn normally, no metter what BevelKind is set.
 Display hint if a string is too long - AutoHint
 OwnerDraw for any style - StyleDropDown
 Fixed a bug of TComboBox.WMLButtonDown in conjunction with PageControl:
  If the ComboBox has focus, when user swiches to another TabSheet and back,
  and clickes the ComboBox its list wasn't shown

{ *********************************************************************** }
{$I RSPak.inc}

interface

uses
  Forms, Windows, Messages, SysUtils, Classes, Controls, StdCtrls, RSCommon,
  RSQ, Graphics, RSSysUtils, RSListBoxHint;

{$I RSWinControlImport.inc}

type
  TRSComboBox = class;

  TRSComboBoxPaintEvent = procedure(Sender:TRSComboBox) of object;

  TRSComboBoxOwnerDraw = (RScdsDefault, RScdsFixed, RScdsVariable);

  TRSComboBox = class(TComboBox)
  private
    FOnCreateParams: TRSCreateParamsEvent;
    FOnPaint: TRSComboBoxPaintEvent;
    FProps: TRSWinControlProps;

    FAutoHint: Boolean;
    FListBorderColor:TColor;
    FStyleOwnerDraw: TRSComboBoxOwnerDraw;
    FOnEditWndProc: TRSWndProcEvent;
    FOnListWndProc: TRSWndProcEvent;
    FListBoxInstance: ptr;
    FListBoxLastWndProc: ptr;
    FListHandle: HWnd;
    procedure FirstListBoxWndProc(var Msg: TMessage);
  protected
    FHintMan: TRSListBoxHints;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CNMeasureItem(var Msg: TWMMeasureItem); message CN_MEASUREITEM;
    procedure CreateWnd; override;
{$IFDEF D2006}
      // Delphi 2006 bug
    procedure WMNCCalcSize(var Message: TWMNCCalcSize); message WM_NCCALCSIZE;
{$ENDIF}
    procedure WMPaint(var Msg: TWMPaint); message WM_PAINT;
    procedure Paint; virtual;
    procedure WMLButtonDown(var Msg: TWMLButtonDown); message WM_LBUTTONDOWN;
    procedure KeyPress(var Key:Char); override;

    function GetItemHt: Integer; override;
    procedure SetStyle(Value: TComboBoxStyle); override;
    procedure SetStyleOwnerDraw(v: TRSComboBoxOwnerDraw);
      // !! Если делать SetStyleOwnerDraw virtual'ным, SetStyle надо изменить
    procedure TranslateWndProc(var Msg: TMessage);
    procedure TranslateEditWndProc(var Msg: TMessage);
    procedure TranslateListWndProc(var Msg: TMessage);
    procedure WndProc(var Msg: TMessage); override;
{$IFNDEF D2006}
    procedure EditWndProc(var Msg: TMessage); virtual;
{$ENDIF}
    procedure ListBoxWndProc(var Msg: TMessage); virtual;
  public
    constructor Create(AOwner:TComponent); override;
    destructor Destroy; override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;

    property EditHandle;
    property ListBoxHandle: HWnd read FListHandle write FListHandle;
  published
    property AutoHint: Boolean read FAutoHint write FAutoHint default false;
    property ListBorderColor:TColor read FListBorderColor write FListBorderColor default clDefault;
    property StyleOwnerDraw: TRSComboBoxOwnerDraw read FStyleOwnerDraw write SetStyleOwnerDraw default RScdsDefault;

    property Align;
    property OnCanResize;
    property OnPaint: TRSComboBoxPaintEvent read FOnPaint write FOnPaint;
    property OnResize;
    property OnEditWndProc: TRSWndProcEvent read FOnEditWndProc write FOnEditWndProc;
    property OnListBoxWndProc: TRSWndProcEvent read FOnListWndProc write FOnListWndProc;
    {$I RSWinControlProps.inc}
  end;
  
procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('RSPak', [TRSComboBox]);
end;

{
********************************* TRSComboBox **********************************
}
constructor TRSComboBox.Create(AOwner:TComponent);
begin
  inherited;
  WindowProc:=TranslateWndProc;
  FListBorderColor:=clDefault;

  FreeObjectInstance(FEditInstance);
  FEditInstance:=MakeObjectInstance(TranslateEditWndProc);
  FListBoxInstance:=MakeObjectInstance(TranslateListWndProc);

  FHintMan:=TRSListBoxHints.Create(Font);
  ItemHeight:=13;
end;

destructor TRSComboBox.Destroy;
begin
  if HandleAllocated then
    DestroyWindowHandle;
  FreeObjectInstance(FListBoxInstance);
  FHintMan.Free;
  inherited;
end;

procedure TRSComboBox.CreateParams(var Params: TCreateParams);
const
  DrawingStyles: array[TRSComboBoxOwnerDraw] of DWORD = (
    0, CBS_OWNERDRAWFIXED, CBS_OWNERDRAWVARIABLE);
begin
  inherited CreateParams(Params);
  Params.Style:= Params.Style or DrawingStyles[FStyleOwnerDraw];
  if Assigned(FOnCreateParams) then
    FOnCreateParams(self, Params);
end;

procedure TRSComboBox.TranslateWndProc(var Msg: TMessage);
var b: Boolean;
begin
  if Assigned(FProps.OnWndProc) then
  begin
    b:=false;
    FProps.OnWndProc(Self, Msg, b, WndProc);
    if b then exit;
  end;
  WndProc(Msg);
end;

procedure TRSComboBox.TranslateEditWndProc(var Msg: TMessage);
var b: Boolean;
begin
  if Assigned(OnEditWndProc) then
  begin
    b:=false;
    OnEditWndProc(Self, Msg, b, EditWndProc);
    if b then exit;
  end;
  EditWndProc(Msg);
end;

procedure TRSComboBox.TranslateListWndProc(var Msg: TMessage);
var b: Boolean;
begin
  if Assigned(OnListBoxWndProc) then
  begin
    b:=false;
    OnListBoxWndProc(Self, Msg, b, ListBoxWndProc);
    if b then exit;
  end;
  ListBoxWndProc(Msg);
end;

procedure TRSComboBox.WndProc(var Msg: TMessage);
begin
  RSProcessProps(self, Msg, FProps);
  with Msg do
    if (Msg = WM_CTLCOLORLISTBOX) and (FListHandle = 0{<> HWnd(LParam)}) and
       (Style<>csSimple) then
    begin
      SetWindowLong(FListHandle, GWL_WNDPROC, int(FListBoxLastWndProc));
      FListHandle:=LParam;
      FListBoxLastWndProc:=
         ptr(SetWindowLong(LParam, GWL_WNDPROC, int(FListBoxInstance)));
    end;
  inherited;
end;

{$IFNDEF D2006}
procedure TRSComboBox.EditWndProc(var Msg: TMessage);
begin
  inherited EditWndProc(Msg);
end;
{$ENDIF}

procedure TRSComboBox.FirstListBoxWndProc(var Msg: TMessage);
begin
  with Msg do
    Result:= CallWindowProc(FListBoxLastWndProc,FListHandle,Msg,WParam,LParam);
end;

procedure TRSComboBox.ListBoxWndProc(var Msg: TMessage);
var DC:HDC; r:TRect;
begin
  if AutoHint then
  begin
    FHintMan.Handle:=FListHandle;
    FHintMan.BeforeWndProc(Msg);
    FirstListBoxWndProc(Msg);
    FHintMan.AfterWndProc(Msg);
  end else
    FirstListBoxWndProc(Msg);

  if ((Msg.Msg = WM_PAINT) or (Msg.Msg = WM_NCPAINT)) and
     (FListBorderColor <> clDefault) then
  begin
    DC:=GetWindowDC(FListHandle);
    if DC=0 then exit;
    with TBrush.Create do
      try
        Color:=FListBorderColor;
        GetWindowRect(FListHandle, r);
        OffsetRect(r, -r.Left, -r.Top);
        FrameRect(DC, r, Handle);
      finally
        Free;
        ReleaseDC(FListHandle, DC);
      end;
  end;
end;

procedure TRSComboBox.CNMeasureItem(var Msg: TWMMeasureItem);
begin
  with Msg.MeasureItemStruct^ do
  begin
    if (itemID=dword(-1)) and (Style<>csSimple) then
      itemHeight:= Height - 6
    else
      itemHeight:= GetItemHt;
      
    if FStyleOwnerDraw = RScdsVariable then
      MeasureItem(itemID, Integer(itemHeight));
  end;
end;

procedure TRSComboBox.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  inherited;
  if (AHeight<>0) and (AHeight<>Height) then
    RecreateWnd;
end;

procedure TRSComboBox.CreateWnd;
begin
  inherited;
  if FListHandle<>0 then
    FListBoxLastWndProc:=
         ptr(SetWindowLong(FListHandle, GWL_WNDPROC, int(FListBoxInstance)));
end;

procedure TRSComboBox.WMPaint(var Msg: TWMPaint);
const
  InnerStyles: array[TBevelCut] of Integer = (0, BDR_SUNKENINNER, BDR_RAISEDINNER, 0);
  OuterStyles: array[TBevelCut] of Integer = (0, BDR_SUNKENOUTER, BDR_RAISEDOUTER, 0);
  EdgeStyles: array[TBevelKind] of Integer = (0, 0, BF_SOFT, BF_FLAT);
  Ctl3DStyles: array[Boolean] of Integer = (BF_MONO, 0);
var bk:TBevelKind; r:TRect;
begin
  bk:=TBevelKind((@BevelKind)^);
  TBevelKind((@BevelKind)^):=bkNone;
  inherited;
  TBevelKind((@BevelKind)^):=bk;
  if bk<>bkNone then
    with Canvas do
    begin
      r:=Rect(0, 0, Width, Height);
      Brush.Color:=Color;
      FrameRect(r);
      FrameRect(DecRect(r));
      DrawEdge(Handle, r, InnerStyles[BevelInner] or OuterStyles[BevelOuter],
        Byte(BevelEdges) or EdgeStyles[BevelKind] or Ctl3DStyles[Ctl3D] or
        BF_ADJUST);
    end;

  Paint;

  if Assigned(OnPaint) then
    OnPaint(self);
end;

procedure TRSComboBox.Paint;
begin
end;

function TRSComboBox.GetItemHt: Integer;
var OldStyle:TComboBoxStyle;
begin
  if StyleOwnerDraw<>RScdsDefault then
  begin
    OldStyle:=Style;
    if StyleOwnerDraw=RScdsFixed then
      TComboBoxStyle((@Style)^):=csOwnerDrawFixed
    else
      TComboBoxStyle((@Style)^):=csOwnerDrawVariable;
      
    try
      Result:= inherited GetItemHt;
    finally
      TComboBoxStyle((@Style)^):=OldStyle;
    end;
  end else
    Result:= inherited GetItemHt;
end;

procedure TRSComboBox.SetStyle(Value: TComboBoxStyle);
var a:TRSComboBoxOwnerDraw;
begin
  a:=FStyleOwnerDraw;
  case Value of
    csOwnerDrawFixed:
      FStyleOwnerDraw:=RScdsFixed;
    csOwnerDrawVariable:
      FStyleOwnerDraw:=RScdsVariable;
    else
    begin
      inherited;
      exit;
    end;
  end;
  if (Style = csDropDownList) and (a<>FStyleOwnerDraw) then
    RecreateWnd
  else
    inherited Style:= csDropDownList;
end;

procedure TRSComboBox.SetStyleOwnerDraw(v: TRSComboBoxOwnerDraw);
begin
  if FStyleOwnerDraw=v then exit;
  FStyleOwnerDraw:=v;
  RecreateWnd;
end;

procedure TRSComboBox.WMLButtonDown(var Msg: TWMLButtonDown);
var
  Form: TCustomForm;
begin
  if (DragMode = dmAutomatic) and (Style = csDropDownList) and
      (Msg.XPos < (Width - GetSystemMetrics(SM_CXHSCROLL))) then
  begin
    inherited;
    exit;
  end;
  RSDispatchEx(self, TCustomCombo, Msg); // Skip TCustomComboBox handler
  if MouseCapture then
  begin
    Form := GetParentForm(Self);
    if (Form <> nil) and (Form.ActiveControl <> Self) and
       (Perform(CB_GETDROPPEDSTATE, 0, 0) = 0) then
      MouseCapture := False;
  end;
end;

{$IFDEF D2006}
procedure TRSComboBox.WMNCCalcSize(var Message: TWMNCCalcSize);
var bk:TBevelKind;
begin
  bk:=TBevelKind((@BevelKind)^);
  TBevelKind((@BevelKind)^):=bkNone;
  inherited;
  TBevelKind((@BevelKind)^):=bk;
end;
{$ENDIF}

procedure TRSComboBox.KeyPress(var Key: Char);
begin
  inherited;
  if Key=#1 then // Ctrl+A
  begin
    SelectAll;
    Key:=#0;
  end;
end;

end.
