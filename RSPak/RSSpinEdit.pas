unit RSSpinEdit;

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

uses Windows, Classes, StdCtrls, Controls, Messages, SysUtils,
  Graphics, Buttons, Themes, RSCommon, UxTheme, RSSpeedButton, RSGraphics,
  RSStrUtils, RSTimer, RSQ, Math;

{$I RSWinControlImport.inc}

type
  TNumGlyphs = Buttons.TNumGlyphs;
  TRSSpinButton = class;
  TRSSpinEvent = procedure (Sender:TRSSpinButton; SpinnedBy:integer) of object;

{ TRSSpinButton }

  TRSSpinButton = class (TCustomControl)
  private
    FButton: TObject;
    FDownButton: TRSSpeedButton;
    FDownKey: Boolean;
    FFirstPause: Integer;
    FFocusControl: TWinControl;
    FFocusedButton: TRSSpeedButton;
    FOnCreateParams: TRSCreateParamsEvent;
    FOnDownClick: TRSSpinEvent;
    FOnUpClick: TRSSpinEvent;
    FPause: Integer;
    FProps: TRSWinControlProps;
    FSpin: Boolean;
    FSpinFactor: Integer;
    FTimer: TRSTimer;
    FUpButton: TRSSpeedButton;
    FUpKey: Boolean;
    function GetDownGlyph: TBitmap;
    function GetDownNumGlyphs: TNumGlyphs;
    function GetFlat: Boolean;
    function GetFlatHighlighted: Boolean;
    function GetStyled: Boolean;
    function GetStyledOnXP: Boolean;
    function GetUpGlyph: TBitmap;
    function GetUpNumGlyphs: TNumGlyphs;
    procedure SetDownButton(v: TRSSpeedButton);
    procedure SetDownGlyph(Value: TBitmap);
    procedure SetDownNumGlyphs(Value: TNumGlyphs);
    procedure SetFlat(Value: Boolean);
    procedure SetFlatHighlighted(Value: Boolean);
    procedure SetFocusBtn(Btn: TRSSpeedButton);
    procedure SetStyled(v: Boolean);
    procedure SetStyledOnXP(v: Boolean);
    procedure SetUpButton(v: TRSSpeedButton);
    procedure SetUpGlyph(Value: TBitmap);
    procedure SetUpNumGlyphs(Value: TNumGlyphs);
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
  protected
    procedure BtnMouseDown(Sender: TObject; Button: TMouseButton; Shift:
            TShiftState; X, Y: Integer);
    procedure BtnMouseUp(Sender: TObject; Button: TMouseButton; Shift:
            TShiftState; X, Y: Integer);
    procedure ButtonPaint(Sender: TRSSpeedButton; DefaultPaint:TRSProcedure;
            var AState: TButtonState; var MouseInControl:boolean;
            MouseReallyInControl:boolean); dynamic;
    function CreateButton: TRSSpeedButton;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure ForceButtons;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation);
            override;
    procedure PressDownKey(v:boolean);
    procedure PressUpKey(v:boolean);
    procedure SetEnabled(v:boolean); override;

    procedure SizeChanged; virtual;
    procedure DoUpClick(SpinnedBy:int); virtual;
    procedure DoDownClick(SpinnedBy:int); virtual;

    procedure Timer(Sender: TObject);
    procedure TranslateWndProc(var Msg: TMessage);
    procedure WndProc(var Msg: TMessage); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    property Spinning: Boolean read FSpin;
  published
    property DownButton: TRSSpeedButton read FDownButton write SetDownButton;
    property DownGlyph: TBitmap read GetDownGlyph write SetDownGlyph stored false;
    property DownNumGlyphs: TNumGlyphs read GetDownNumGlyphs write SetDownNumGlyphs stored false;
    property Flat: Boolean read GetFlat write SetFlat stored false;
    property FlatHighlighted: Boolean read GetFlatHighlighted write SetFlatHighlighted stored false;
    property FocusControl: TWinControl read FFocusControl write FFocusControl;
    property InitRepeatPause: Integer read FFirstPause write FFirstPause
            default 400;
    property RepeatPause: Integer read FPause write FPause default 100;
    property SpinFactor: Integer read FSpinFactor write FSpinFactor;
    property Styled: Boolean read GetStyled write SetStyled stored false;
    property StyledOnXP: Boolean read GetStyledOnXP write SetStyledOnXP stored false;
    property UpButton: TRSSpeedButton read FUpButton write SetUpButton;
    property UpGlyph: TBitmap read GetUpGlyph write SetUpGlyph stored false;
    property UpNumGlyphs: TNumGlyphs read GetUpNumGlyphs write SetUpNumGlyphs stored false;
    property OnDownClick: TRSSpinEvent read FOnDownClick write FOnDownClick;
    property OnUpClick: TRSSpinEvent read FOnUpClick write FOnUpClick;

    property Align;
    property Anchors;
    property BevelEdges;
    property BevelInner;
    property BevelKind default bkNone;
    property BevelOuter;
    property BevelWidth;
    property Canvas;
    property Constraints;
    property Ctl3D;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property ParentCtl3D;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnCanResize;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
    {$I RSWinControlProps.inc}
  end;

{ TRSCustomSpinEdit }

  TRSCustomSpinEdit = class (TCustomEdit)
  private
    FButton: TRSSpinButton;
    FEditorEnabled: Boolean;
    FOnChanged: TNotifyEvent;
    FOnCreateParams: TRSCreateParamsEvent;
    FOnDownClick: TNotifyEvent;
    FOnUpClick: TNotifyEvent;
    FProps: TRSWinControlProps;
    FSelAnchor: int;
    FIgnoreTextChange: Boolean;
    procedure CMEnter(var Message: TCMGotFocus); message CM_ENTER;
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
    function GetCaret: int;
    function GetMinHeight: Integer;
    function GetStyled: Boolean;
    function GetStyledOnXP: Boolean;
    procedure SetButton(v: TRSSpinButton);
    procedure SetCaret(v: int);
    procedure SetStyled(v: Boolean);
    procedure SetStyledOnXP(v: Boolean);
    procedure WMCut(var Message: TWMCut); message WM_CUT;
    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;
    procedure WMPaste(var Message: TWMPaste); message WM_PASTE;
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
  protected
    procedure Change; override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure DoChanged; virtual; abstract;
    procedure DoDown(SpinnedBy:integer; Clicked:boolean=false); virtual;
    procedure DoUp(SpinnedBy:integer; Clicked:boolean=false); virtual;
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
    function IsValidChar(c: Char): Boolean; virtual;
    function IsValidInputChar(c: Char): Boolean; virtual; abstract;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    procedure MakeVisibleH;
    procedure SetEditRect;
    procedure SetEnabled(v:boolean); override;
    procedure TranslateWndProc(var Msg: TMessage);
    procedure Validate; virtual; abstract;
    procedure WndProc(var Msg: TMessage); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure IncrementValue(mul: int); virtual; abstract;
    procedure GetSelection(var Start, Caret: Integer);
    procedure PlaceButton;
    procedure SetSelection(Start, Caret:int);
    property Caret: int read GetCaret write SetCaret;
  published
    property Button: TRSSpinButton read FButton write SetButton;
    property EditorEnabled: Boolean read FEditorEnabled write FEditorEnabled default True;
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
    property OnDownClick: TNotifyEvent read FOnDownClick write FOnDownClick;
    property OnUpClick: TNotifyEvent read FOnUpClick write FOnUpClick;
    property Styled: Boolean read GetStyled write SetStyled stored false;
    property StyledOnXP: Boolean read GetStyledOnXP write SetStyledOnXP stored false;
    property Align;
    property Anchors;
    property AutoSelect;
    property AutoSize;
    property BevelEdges;
    property BevelInner;
    property BevelKind default bkNone;
    property BevelOuter;
    property BevelWidth;
    property BorderStyle;
    property CharCase;
    property Color;
    property Constraints;
    property Ctl3D;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property HideSelection;
    property MaxLength;
    property OnCanResize;
    property OnChange;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
    property ParentColor;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ReadOnly;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;

{$IFDEF D2005}
    property OnMouseActivate;
{$ENDIF}
    {$I RSWinControlProps.inc}
  end;

  TRSSpinEdit = class (TRSCustomSpinEdit)
  private
    FBase: Integer;
    FIncrement: LongInt;
    FLastValue: Integer;
    FMaxValue: LongInt;
    FMinValue: LongInt;
    FValue: Integer;
    FDigits: int;
    FThous: Boolean;
    FThousSep: Char;
    function GetValue: LongInt;
    procedure SetBase(v: Integer);
    procedure SetMaxValue(v: LongInt);
    procedure SetMinValue(v: LongInt);
    procedure SetValue(NewValue: LongInt);
    procedure SetDigits(v:int);
    procedure SetThous(b: Boolean);
    procedure SetThousSep(c: Char);
  protected
    function CheckValue(NewValue: LongInt): LongInt;
    procedure Validate; override;
    procedure DoChanged; override;
    function IsValidInputChar(c: Char): Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure IncrementValue(mul: int); override;
  published
    property Base: Integer read FBase write SetBase default 0;
    property Thousands: Boolean read FThous write SetThous default false;
    property ThousandsSeparator: Char read FThousSep write SetThousSep default #0;
    property Digits: int read FDigits write SetDigits default 0;
    property Increment: LongInt read FIncrement write FIncrement default 1;
    property MaxValue: LongInt read FMaxValue write SetMaxValue default high(int);
    property MinValue: LongInt read FMinValue write SetMinValue default low(int);
    property Value: LongInt read GetValue write SetValue default 0;
  end;

  TRSFloatSpinEdit = class (TRSCustomSpinEdit)
  private
    FIncrement: ext;
    FLastValue: ext;
    FMaxValue: ext;
    FMinValue: ext;
    FValue: ext;
    FThous: Boolean;
    FDotAsSeparator: Boolean;
    FPrecision: Byte;
    procedure SetPrecision(v: Byte);
    function IsMaxValueStored: Boolean;
    function IsMinValueStored: Boolean;
    function GetValue: ext;
    procedure SetMaxValue(v: ext);
    procedure SetMinValue(v: ext);
    procedure SetValue(NewValue: ext);
    procedure SetThous(b: Boolean);
    procedure SetDotAsSeparator(v: Boolean);
  protected
    function CheckValue(NewValue: ext): ext;
    procedure Validate; override;
    procedure DoChanged; override;
    function IsValidInputChar(c: Char): Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure IncrementValue(mul: int); override;
  published
    property Thousands: Boolean read FThous write SetThous default false;
    property DotAsSeparator: Boolean read FDotAsSeparator write SetDotAsSeparator default false;
    property Precision: Byte read FPrecision write SetPrecision default 15;
    property Increment: ext read FIncrement write FIncrement;
    property MaxValue: ext read FMaxValue write SetMaxValue stored IsMaxValueStored;
    property MinValue: ext read FMinValue write SetMinValue stored IsMinValueStored;
    property Value: ext read GetValue write SetValue;
  end;

{$R RSSpinEdit.res}

implementation

{
******************************** TRSSpinButton *********************************
}

type
  TRSSpinSpeedButton = class (TRSSpeedButton)
  protected
    procedure DoPaint; override;
    procedure DoInheritedPaint;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
  public
    constructor Create(AOwner:TComponent); override;
  published
    property DrawFrame default true;
  end;

{ TRSSpinSpeedButton }

constructor TRSSpinSpeedButton.Create(AOwner: TComponent);
begin
  inherited;
  DrawFrame:=true;
end;

procedure TRSSpinSpeedButton.DoInheritedPaint;
begin
  Canvas.Brush:= FNoBrush;
  Canvas.Pen:= FNoPen;
  inherited DoPaint;
end;

procedure TRSSpinSpeedButton.DoPaint;
begin
  (Owner as TRSSpinButton).ButtonPaint(self, DoInheritedPaint, fState,
    Pboolean(@MouseInControl)^, MouseInside);
end;

procedure TRSSpinSpeedButton.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  (Owner as TRSSpinButton).BtnMouseDown(self, Button, Shift, X, Y);
end;

procedure TRSSpinSpeedButton.MouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  (Owner as TRSSpinButton).BtnMouseUp(self, Button, Shift, X, Y);
end;

{ TRSSpinButton }

constructor TRSSpinButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque] -
    [csAcceptsControls, csSetCaption, csReplicatable];
  fTimer:=TRSTimer.Create(Self);
  fTimer.Interval:=0;
  fTimer.Enabled:=true;
  fTimer.OnTimer:=Timer;
  fFirstPause:= 400;
  fPause:= 100;
  FUpButton := CreateButton;
  FDownButton := CreateButton;
  UpGlyph := nil;
  DownGlyph := nil;
  FSpin:=false;
  fButton:=nil;
  Width := 20;
  Height := 25;
  FFocusedButton := FUpButton;
  fDownKey:= false;
  fUpKey:= false;
  fSpinFactor:= 15;
  //Framed:=true;
end;

procedure TRSSpinButton.BtnMouseDown(Sender: TObject; Button: TMouseButton; 
        Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    fButton:=Sender;
    SetFocusBtn (TRSSpeedButton (Sender));
    if (FFocusControl <> nil) and FFocusControl.TabStop and
        FFocusControl.CanFocus and (GetFocus <> FFocusControl.Handle)
    then
      FFocusControl.SetFocus
    else
      if TabStop and (GetFocus <> Handle) and CanFocus then
        SetFocus;
  
    FSpin:=true;
    fTimer.Tag:=0;
    fTimer.Interval:=fFirstPause;
  
    if Sender=FUpButton then
      DoUpClick(1)
    else
      DoDownClick(1);
  end;
end;

procedure TRSSpinButton.BtnMouseUp(Sender: TObject; Button: TMouseButton; 
        Shift: TShiftState; X, Y: Integer);
var
  ButtonBefore: TControl;
begin
  if (Button <> mbLeft) or (fButton=nil) then exit;
  FSpin:=false;
  fTimer.Interval:=0;
  ButtonBefore:=(fButton as TControl);
  fButton:=nil;
  ButtonBefore.Invalidate;
end;

procedure TRSSpinButton.ButtonPaint(Sender: TRSSpeedButton; 
        DefaultPaint:TRSProcedure; var AState: TButtonState; var 
        MouseInControl:boolean; MouseReallyInControl:boolean);
var
  a: TThemedElementDetails;
  lastNG: Integer;
begin
  with Sender do
  begin
    if Glyph.Empty then
    begin
      BlockRepaint;
      lastNG:=NumGlyphs;
      if Sender=fUpButton then
        Glyph.Handle := LoadBitmap(HInstance, 'RSUPGLYPH')
      else
        Glyph.Handle := LoadBitmap(HInstance, 'RSDOWNGLYPH');
      Glyph.Transparent:=true;
      Glyph.TransparentColor:=clWhite;
      NumGlyphs := 1;
    end else
      lastNG:=-1;
  
    if (fButton<>nil) and (GetKeyState(VK_LBUTTON)>=0) then
      BtnMouseUp(fButton,mbLeft,[],0,0);
    if (Sender=fButton) and (AState=bsUp) and (fSpinFactor>0) then
      AState:=bsDown;

    if IsStyled then
    begin
      Canvas.Brush.Color:=clBtnFace;
      Canvas.Fillrect(Bounds(0,0,Sender.Width,Sender.Height));
      {
      if AState=bsDisabled then
      begin
        DefaultPaint;
      end
        with Canvas do
        begin
          if AState<>bsDisabled then


          Pen.Color:=RSMixColorsNorm(clBtnShadow, GetColorTheme.Button, 180);
          if AState=bsDisabled then
            Brush.Color:=GetColorTheme.Button
          else
            Brush.Style:=bsClear;
          Rectangle(Rect(0, 0, Width, Height));
          Pixels[0, 0]:=GetColorTheme.Button;
          Pixels[Width-1, 0]:=GetColorTheme.Button;
          Pixels[0, Height-1]:=GetColorTheme.Button;
          Pixels[Width-1, Height-1]:=GetColorTheme.Button;
          if AState=bsDisabled then
            RSDrawDisabled(Canvas, Glyph, clBtnShadow,
              (Width-Glyph.Width) div 2,
              (Height-Glyph.Height) div 2);
        end
      else
      }
        DefaultPaint;
    end else
      if ThemeServices.ThemesEnabled then
      begin
        a.Element:=teSpin;
        if Sender=FUpButton then a.Part:=1
        else a.Part:=2;
        case AState of
          bsUp:
            if MouseReallyInControl then a.State:=UPS_HOT
            else a.State:=UPS_NORMAL;
          bsDisabled:
            a.State:=UPS_DISABLED;
          bsDown, bsExclusive:
            a.State:=UPS_PRESSED;
        end;
        ThemeServices.DrawElement(Sender.Canvas.Handle,a,
                                Bounds(0,0,Sender.Width,Sender.Height));
      end else
      begin
        Canvas.Brush.Color:=clBtnFace;
        Canvas.FillRect(Bounds(0,0,Sender.Width,Sender.Height));
        DefaultPaint;
      end;
  
    if lastNG<>-1 then
    begin
      Glyph:=nil;
      NumGlyphs := lastNG;
    end;
  end;
end;

function TRSSpinButton.CreateButton: TRSSpeedButton;
begin
  Result:= TRSSpinSpeedButton.Create(Self);
  Result.Parent:= self;
  Result.SetSubComponent(true);
end;

procedure TRSSpinButton.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  if Assigned(FOnCreateParams) then FOnCreateParams(self, Params);
end;

procedure TRSSpinButton.ForceButtons;
begin
  FUpButton.ForceDown:= fUpKey;
  FDownButton.ForceDown:= fDownKey;
end;

function TRSSpinButton.GetDownGlyph: TBitmap;
begin
  Result := FDownButton.Glyph;
end;

function TRSSpinButton.GetDownNumGlyphs: TNumGlyphs;
begin
  Result := FDownButton.NumGlyphs;
end;

function TRSSpinButton.GetFlat: Boolean;
begin
  Result:=FUpButton.Flat;
end;

function TRSSpinButton.GetFlatHighlighted: Boolean;
begin
  Result:=FUpButton.Highlighted and FDownButton.Highlighted;
end;

function TRSSpinButton.GetStyled: Boolean;
begin
  Result:=FUpButton.Styled;
end;

function TRSSpinButton.GetStyledOnXP: Boolean;
begin
  Result:=FUpButton.StyledOnXP;
end;

function TRSSpinButton.GetUpGlyph: TBitmap;
begin
  Result := FUpButton.Glyph;
end;

function TRSSpinButton.GetUpNumGlyphs: TNumGlyphs;
begin
  Result := FUpButton.NumGlyphs;
end;

procedure TRSSpinButton.KeyDown(var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_UP:
    begin
      SetFocusBtn(FUpButton);
      PressUpKey(true);
    end;
    VK_DOWN:
    begin
      SetFocusBtn(FDownButton);
      PressDownKey(true);
    end;
    VK_SPACE:
    begin
      if FFocusedButton=FUpButton then PressUpKey(true)
      else if FFocusedButton=FDownButton then PressDownKey(true);
    end;
  end;
end;

procedure TRSSpinButton.KeyUp(var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_UP:
    begin
      SetFocusBtn(FUpButton);
      PressUpKey(false);
    end;
    VK_DOWN:
    begin
      SetFocusBtn(FDownButton);
      PressDownKey(false);
    end;
    VK_SPACE:
    begin
      if FFocusedButton=FUpButton then PressUpKey(false)
      else if FFocusedButton=FDownButton then PressDownKey(false);
    end;
  end;
end;

procedure TRSSpinButton.Notification(AComponent: TComponent; Operation: 
        TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FFocusControl) then
    FFocusControl := nil;
end;

procedure TRSSpinButton.PressDownKey(v:boolean);
begin
  if fDownKey=v then exit;
  fDownKey:=v;
  if v and fUpKey then fUpKey:=false;
  ForceButtons;
end;

procedure TRSSpinButton.PressUpKey(v:boolean);
begin
  if fUpKey=v then exit;
  fUpKey:=v;
  if v and fDownKey then fDownKey:=false;
  ForceButtons;
end;

procedure TRSSpinButton.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
  SizeChanged;
end;

procedure TRSSpinButton.SetDownButton(v: TRSSpeedButton);
begin
  FDownButton.Assign(v);
end;

procedure TRSSpinButton.SetDownGlyph(Value: TBitmap);
begin
  FDownButton.Glyph := Value;
end;

procedure TRSSpinButton.SetDownNumGlyphs(Value: TNumGlyphs);
begin
  FDownButton.NumGlyphs := Value;
end;

procedure TRSSpinButton.SetEnabled(v:boolean);
begin
  FUpButton.Enabled:=v;
  FDownButton.Enabled:=v;
  inherited SetEnabled(v);
end;

procedure TRSSpinButton.SetFlat(Value: Boolean);
begin
  fUpButton.Flat:=Value;
  fDownButton.Flat:=Value;
  SizeChanged;
end;

procedure TRSSpinButton.SetFlatHighlighted(Value: Boolean);
begin
  fUpButton.Highlighted:=Value;
  fDownButton.Highlighted:=Value;
  SizeChanged;
end;

procedure TRSSpinButton.SetFocusBtn(Btn: TRSSpeedButton);
begin
  if TabStop and CanFocus and  (Btn <> FFocusedButton) then
  begin
    FFocusedButton := Btn;
    if (GetFocus = Handle) then
    begin
      Invalidate;
    end;
  end;
end;

procedure TRSSpinButton.SetStyled(v: Boolean);
begin
  fUpButton.Styled:=v;
  fDownButton.Styled:=v;
end;

procedure TRSSpinButton.SetStyledOnXP(v: Boolean);
begin
  fUpButton.StyledOnXP:=v;
  fDownButton.StyledOnXP:=v;
end;

procedure TRSSpinButton.SetUpButton(v: TRSSpeedButton);
begin
  FUpButton.Assign(v);
end;

procedure TRSSpinButton.SetUpGlyph(Value: TBitmap);
begin
  FUpButton.Glyph := Value;
end;

procedure TRSSpinButton.SetUpNumGlyphs(Value: TNumGlyphs);
begin
  FUpButton.NumGlyphs := Value;
end;

procedure TRSSpinButton.SizeChanged;
var
  W, H: Integer;
begin
  if not HandleAllocated or (FUpButton = nil) or
     (csLoading in ComponentState) then exit;
  W:=ClientWidth;
  H:=ClientHeight;

  if FUpButton.IsStyled or Flat or ThemeServices.ThemesEnabled then
  begin
    FUpButton.SetBounds(0, 0, W, (H+1) div 2);
    FDownButton.SetBounds(0, FUpButton.Height, W, H - FUpButton.Height);
  end else
  begin
    FUpButton.SetBounds(0, 0, W, H div 2 + 1);
    FDownButton.SetBounds(0, FUpButton.Height -1, W, H - FUpButton.Height +1);
  end;
end;

procedure TRSSpinButton.DoUpClick(SpinnedBy: int);
begin
  if Assigned(FOnUpClick) then  FOnUpClick(Self, SpinnedBy);
end;

procedure TRSSpinButton.DoDownClick(SpinnedBy: int);
begin
  if Assigned(FOnDownClick) then  FOnDownClick(Self, SpinnedBy);
end;

procedure TRSSpinButton.Timer(Sender: TObject);
var
  i, j: Integer;
  r: TRect;
begin
  if GetKeyState(VK_LBUTTON) and 128=0 then
  begin
    BtnMouseUp(fButton,mbLeft,[],0,0);
    exit;
  end;
  GetWindowRect(Handle,r);
  i:=mouse.CursorPos.Y-r.Top;
  if fButton = FUpButton then
  begin
    dec(i,FUpButton.Top);
    if fSpinFactor<>0 then
    begin
      if i>=FUpButton.Height then
        i:=0
      else
        if i<0 then
          i:=2+ (-i) div fSpinFactor
        else
          i:=1;
          
      i:=sqr(i);
    end else
      if (i>=FUpButton.Height) or (i<0) or not FProps.MouseIn then
        i:=0
      else
        i:=1;
        
    if i<=0 then
      i:=1
    else
      DoUpClick(FTimer.Tag + 1);
  end else
  begin
    dec(i,FDownButton.Top);
    if fSpinFactor<>0 then
    begin
      if i<0 then
        i:=0
      else
        if i>=FDownButton.Height then
          i:=2+ (i-FDownButton.Height) div fSpinFactor
        else
          i:=1;
          
      i:=sqr(i);
    end else
      if (i>=FDownButton.Height) or (i<0) or not FProps.MouseIn then
        i:=0
      else
        i:=1;
        
    if i<=0 then
      i:=1
    else
      DoDownClick(FTimer.Tag + 1);
  end;
  j:=fPause div i;
  if j<10 then
  begin
    fTimer.Interval:=15;
    fTimer.Tag:=(15*i+fPause div 2) div fPause;
  end else
  begin
    fTimer.Interval:=j;
    fTimer.Tag:=0;
  end;
end;

procedure TRSSpinButton.TranslateWndProc(var Msg: TMessage);
var
  b: Boolean;
begin
  if assigned(FProps.OnWndProc) then
  begin
    b:=false;
    FProps.OnWndProc(Self, Msg, b, WndProc);
    if b then exit;
  end;
  WndProc(Msg);
end;

procedure TRSSpinButton.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  Message.Result := DLGC_WANTARROWS;
end;

procedure TRSSpinButton.WMSize(var Message: TWMSize);
begin
  inherited;
  SizeChanged;
  Message.Result := 0;
end;

procedure TRSSpinButton.WndProc(var Msg: TMessage);
begin
  RSProcessProps(self, Msg, FProps);
  inherited;
end;

(*
procedure TRSSpinButton.ButtonPaint(Sender: TRSSpeedButton;
        DefaultPaint:TRSProcedure; var State: TButtonState; var
        MouseInControl:boolean; MouseReallyInControl:boolean);
var
  a: TThemedElementDetails;
  lastNG: Integer;
  wasFlat: Boolean;
  wasTransp: Boolean;
begin
  if Sender.Glyph.Empty then
  begin
    lastNG:=Sender.NumGlyphs;
    if Sender=fUpButton then
      Sender.Glyph.Handle := LoadBitmap(HInstance, 'RSUPGLYPH')
    else
      Sender.Glyph.Handle := LoadBitmap(HInstance, 'RSDOWNGLYPH');
    if ((Sender.Style<>RSsbStandard) or Sender.Flat) and
       (Sender.Glyph.Height>2) then
      Sender.Glyph.Height:=Sender.Glyph.Height-2;
    Sender.Glyph.Transparent:=true;
    Sender.Glyph.TransparentColor:=clWhite;
    Sender.NumGlyphs := 1;
  end else lastNG:=-1;
  if (fButton<>nil) and (GetKeyState(VK_LBUTTON)>=0) then
    BtnMouseUp(fButton,mbLeft,[],0,0);
  if (Sender=fButton) and (State=bsUp) and (fSpinFactor>0) then
    State:=bsDown;

  if not ThemeServices.ThemesEnabled then
  begin
    if Sender.Style=RSsbBright then
    begin
      if MouseReallyInControl then MouseInControl:=true;
      wasFlat:=Sender.Flat;
      wasTransp:=Sender.Transparent;
      Sender.Flat:=true;
      Sender.Transparent:=true;

      if MouseInControl or (State in [bsDown, bsExclusive]) then
        Sender.Canvas.Brush.Color:=clBtnHighlight
      else Sender.Canvas.Brush.Color:=clBtnFace;
      Sender.Canvas.Fillrect(Bounds(0,0,Sender.Width,Sender.Height));

      DefaultPaint;

      if MouseInControl or (State in [bsDown, bsExclusive]) then
      begin
        Sender.Canvas.Pen.Color:=clBtnFace;
        Sender.Canvas.Brush.Style:=bsClear;
        Sender.Canvas.Rectangle(Bounds(0,0,Sender.Width,Sender.Height));
      end;

      Sender.Flat:=wasFlat;
      Sender.Transparent:=wasTransp;
    end else
    begin
      Sender.Canvas.Brush.Color:=clBtnFace;
      Sender.Canvas.Fillrect(Bounds(0,0,Sender.Width,Sender.Height));
      if (Style=RSsbOffice) and not MouseInControl and (State<>bsDown) then
        with Sender, Canvas do
        begin
          if State<>bsDisabled then
            DefaultPaint;

          Pen.Color:=GetColorTheme.Dark;
          if State=bsDisabled then
            Brush.Color:=GetColorTheme.Button
          else
            Brush.Style:=bsClear;
          Rectangle(Rect(0, 0, Width, Height));
          Pixels[0, 0]:=GetColorTheme.Button;
          Pixels[Width-1, 0]:=GetColorTheme.Button;
          Pixels[0, Height-1]:=GetColorTheme.Button;
          Pixels[Width-1, Height-1]:=GetColorTheme.Button;
          if State=bsDisabled then
            RSDrawDisabled(Canvas, Glyph, clBtnShadow,
              (Width-Glyph.Width) div 2,
              (Height-Glyph.Height) div 2);
        end
      else
        DefaultPaint;
    end;
  end else
  begin
    a.Element:=teSpin;
    if Sender=FUpButton then a.Part:=1
    else a.Part:=2;
    case State of
      bsUp:
        if MouseReallyInControl then a.State:=UPS_HOT
        else a.State:=UPS_NORMAL;
      bsDisabled:
        a.State:=UPS_DISABLED;
      bsDown, bsExclusive:
        a.State:=UPS_PRESSED;
    end;
    ThemeServices.DrawElement(Sender.Canvas.Handle,a,
                            Bounds(0,0,Sender.Width,Sender.Height));
  end;
  if lastNG<>-1 then
  begin
    Sender.Glyph:=nil;
    Sender.NumGlyphs := lastNG;
  end;
end;
*)

{
********************************* TRSCustomSpinEdit **********************************
}

type
  TRSSpinEditButton = class (TRSSpinButton)
  protected
    FNoPlace: Boolean;
    procedure SizeChanged; override;
    procedure DoUpClick(SpinnedBy:int); override;
    procedure DoDownClick(SpinnedBy:int); override;
  end;

{ TRSSpinEditButton }

procedure TRSSpinEditButton.SizeChanged;
begin
  inherited;
  if not fNoPlace and (Parent = Owner) then
    (Owner as TRSCustomSpinEdit).PlaceButton;
end;

procedure TRSSpinEditButton.DoUpClick(SpinnedBy: int);
begin
  inherited;
  (Owner as TRSCustomSpinEdit).DoUp(SpinnedBy, true);
end;

procedure TRSSpinEditButton.DoDownClick(SpinnedBy: int);
begin
  inherited;
  (Owner as TRSCustomSpinEdit).DoDown(SpinnedBy, true);
end;

{ TRSCustomSpinEdit }

constructor TRSCustomSpinEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FButton := TRSSpinEditButton.Create(self);
  FButton.Width := 15;
  FButton.Parent := Self;
  FButton.FocusControl := Self;
  //  FButton.Framed:=false;
  FButton.SetSubComponent(true);

  ControlStyle := ControlStyle - [csSetCaption];
  FEditorEnabled := True;
  ParentBackground := false;
    //FFirstCreateWnd:=true;
end;

procedure TRSCustomSpinEdit.Change;
begin
  if not FIgnoreTextChange and not (csReadingState in ControlState) then
    inherited;
end;

procedure TRSCustomSpinEdit.CMEnter(var Message: TCMGotFocus);
begin
  if AutoSelect and not (csLButtonDown in ControlState) then
    SelectAll;
  inherited;
end;

procedure TRSCustomSpinEdit.CMExit(var Message: TCMExit);
begin
  inherited;
  Validate;
end;

procedure TRSCustomSpinEdit.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  // Params.Style := Params.Style and not WS_BORDER;
  Params.Style := Params.Style or ES_MULTILINE or WS_CLIPCHILDREN;
  if Assigned(FOnCreateParams) then FOnCreateParams(self, Params);
end;

procedure TRSCustomSpinEdit.CreateWnd;
begin
  inherited CreateWnd;
  MakeVisibleH;
  SetEditRect;
  //if FFirstCreateWnd then
  //begin
  //  FFirstCreateWnd:=false;
  //  AutoSize:=false;
  //end;
end;

procedure TRSCustomSpinEdit.DoDown(SpinnedBy:integer; Clicked:boolean=false);
begin
  if ReadOnly then MessageBeep(0);
  if not ReadOnly then
    IncrementValue(-SpinnedBy);
  if Clicked and Assigned(FOnDownClick) then
    FOnDownClick(self);

  if ReadOnly then exit;

  //SelectAll;
  DoChanged;
end;

procedure TRSCustomSpinEdit.DoUp(SpinnedBy:integer; Clicked:boolean=false);
begin
  if ReadOnly then MessageBeep(0);
  if not ReadOnly then
    IncrementValue(SpinnedBy);
  if Clicked and Assigned(FOnUpClick) then
    FOnUpClick(self);

  if ReadOnly then exit;

  //SelectAll;
  DoChanged;
end;

function TRSCustomSpinEdit.GetCaret: int;
begin
  Result:=RSEditGetCaret(self, FSelAnchor);
end;

procedure TRSCustomSpinEdit.GetChildren(Proc: TGetChildProc; Root: TComponent);
begin
  
end;

function TRSCustomSpinEdit.GetMinHeight: Integer;
var
  DC: HDC;
  SaveFont: HFont;
  I: Integer;
  SysMetrics, Metrics: TTextMetric;
begin
   // text edit bug: if size too less than minheight, then edit ctrl does
   // not display the text
  DC := GetDC(0);
  GetTextMetrics(DC, SysMetrics);
  SaveFont := SelectObject(DC, Font.Handle);
  GetTextMetrics(DC, Metrics);
  SelectObject(DC, SaveFont);
  ReleaseDC(0, DC);
  I := SysMetrics.tmHeight;
  if I > Metrics.tmHeight then I := Metrics.tmHeight;
  Result := Metrics.tmHeight + I div 4 + GetSystemMetrics(SM_CYBORDER) * 4 + 2;
end;

procedure TRSCustomSpinEdit.GetSelection(var Start, Caret: Integer);
begin
  RSEditGetSelection(self, Start, Caret, FSelAnchor);
end;

function TRSCustomSpinEdit.GetStyled: Boolean;
begin
  Result:=FButton.Styled;
end;

function TRSCustomSpinEdit.GetStyledOnXP: Boolean;
begin
  Result:=FButton.StyledOnXP;
end;

function TRSCustomSpinEdit.IsValidChar(c: Char): Boolean;
begin
  Result:= FEditorEnabled;
  if not Result and (c in [Char(VK_BACK), Char(VK_DELETE), #32..#255]) then
    exit;
  Result:= ((c < #32) and (c <> Chr(VK_RETURN))) or IsValidInputChar(c);
end;

procedure TRSCustomSpinEdit.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if Key = VK_UP then
  begin
    if not ReadOnly then FButton.PressUpKey(true);
    DoUp(1);
  end else
  if Key = VK_DOWN then
  begin
    if not ReadOnly then FButton.PressDownKey(true);
    DoDown(1);
  end;
  inherited KeyDown(Key, Shift);
end;

procedure TRSCustomSpinEdit.KeyPress(var Key: Char);
var c:char;
begin
  c:=Key;
  if Key = #13 then
  begin
    Validate;
    SelectAll;
    Key:=#0;
  end;

  if Key<>#0 then
    inherited KeyPress(Key)
  else
    inherited KeyPress(c);

  case Key of
    #1: // Ctrl+A
    begin
      SelectAll;
      Key:=#0;
    end;
    else
      if not IsValidChar(Key) then
      begin
        Key := #0;
        MessageBeep(0);
      end;
  end;
end;

procedure TRSCustomSpinEdit.KeyUp(var Key: Word; Shift: TShiftState);
begin
  if Key = VK_UP then FButton.PressUpKey(false)
  else if Key = VK_DOWN then FButton.PressDownKey(false);
  inherited KeyUp(Key, Shift);
end;

procedure TRSCustomSpinEdit.MakeVisibleH;
var
  h: Integer;
begin
  // text edit bug: if size too less than minheight, then edit ctrl does
  // not display the text
  h:=height;
  height:=GetMinHeight;
  height:=h;
end;

procedure TRSCustomSpinEdit.PlaceButton;
begin
  if FButton <> nil then
  begin
    TRSSpinEditButton(fButton).fNoPlace:=true;
    FButton.SetBounds(ClientWidth-FButton.Width, 0, FButton.Width,
      ClientHeight);
    TRSSpinEditButton(fButton).fNoPlace:=false;
    if HandleAllocated then SetEditRect;
  end;
end;

procedure TRSCustomSpinEdit.SetButton(v: TRSSpinButton);
begin
  FButton.Assign(v);
end;

procedure TRSCustomSpinEdit.SetCaret(v: int);
begin
  Perform(EM_SETSEL, v, v);
end;

procedure TRSCustomSpinEdit.SetEditRect;
var
  Loc: TRect;
  w: Integer;
begin
    //SendMessage(Handle, EM_GETRECT, 0, LongInt(@Loc));
  if FButton.Visible then w:=FButton.Width else w:=0;
  Loc.Bottom := ClientHeight + 1;
       //+1 is workaround for windows paint bug
    //if NewStyleControls and Ctl3D then Loc.Right := ClientWidth - w +1
  Loc.Right := ClientWidth - w + 1;
  if NewStyleControls and Ctl3D then
  begin
    Loc.Top := 0;
    Loc.Left := 0;
  end else
  begin
    Loc.Top:=1;
    Loc.Left:=1;
  end;
  SendMessage(Handle, EM_SETRECTNP, 0, LongInt(@Loc));
  //  SendMessage(Handle, EM_GETRECT, 0, LongInt(@Loc));  //debug
end;

procedure TRSCustomSpinEdit.SetEnabled(v:boolean);
begin
  FButton.Enabled:=v;
  inherited SetEnabled(v);
end;

procedure TRSCustomSpinEdit.SetSelection(Start, Caret:int);
begin
  RSEditSetSelection(self, Start, Caret);
end;

procedure TRSCustomSpinEdit.SetStyled(v: Boolean);
begin
  fButton.Styled:=v;
end;

procedure TRSCustomSpinEdit.SetStyledOnXP(v: Boolean);
begin
  fButton.StyledOnXP:=v;
end;

procedure TRSCustomSpinEdit.TranslateWndProc(var Msg: TMessage);
var
  b: Boolean;
begin
  if assigned(FProps.OnWndProc) then
  begin
    b:=false;
    FProps.OnWndProc(Self, Msg, b, WndProc);
    if b then exit;
  end;
  WndProc(Msg);
end;

procedure TRSCustomSpinEdit.WMCut(var Message: TWMCut);
begin
  if not FEditorEnabled or ReadOnly then Perform(WM_COPY,0,0);
  inherited;
end;

procedure TRSCustomSpinEdit.WMKillFocus(var Message: TWMKillFocus);
begin
  inherited;
  FButton.PressUpKey(false);
  FButton.PressDownKey(false);
end;

procedure TRSCustomSpinEdit.WMPaste(var Message: TWMPaste);
begin
  if not FEditorEnabled or ReadOnly then Exit;
  inherited;
end;

procedure TRSCustomSpinEdit.WMSize(var Message: TWMSize);
begin
  inherited;
  PlaceButton;
end;

procedure TRSCustomSpinEdit.WndProc(var Msg: TMessage);
begin
  RSProcessProps(self, Msg, FProps);
  inherited;
  RSEditWndProcAfter(self, Msg, FSelAnchor);
end;

{ TRSSpinEdit }

function TRSSpinEdit.CheckValue(NewValue: LongInt): LongInt;
begin
  Result := NewValue;
  if (FMaxValue >= FMinValue) then
  begin
    if NewValue < FMinValue then
      Result := FMinValue
    else
      if NewValue > FMaxValue then
        Result := FMaxValue;
  end;
end;

constructor TRSSpinEdit.Create(AOwner: TComponent);
begin
  inherited;
  FMaxValue:= MaxInt;
  FMinValue:= low(int);
  FIncrement:= 1;
  FIgnoreTextChange:= true;
  Value:= 0;
  FIgnoreTextChange:= false;
  FLastValue:= FValue;
end;

procedure TRSSpinEdit.DoChanged;
begin
  if (fValue<>FLastValue) and (Assigned(fOnChanged)) then FOnChanged(self);
  FLastValue:=FValue;
end;

function TRSSpinEdit.GetValue: LongInt;
var
  i: Integer;
begin
  i:=FBase;
  if i<2 then i:=10;
  if FThous then
    if FThousSep=#0 then Result := RSStrToIntEx(Text,i,i,ThousandSeparator)
    else Result := RSStrToIntEx(Text,i,i,FThousSep)
  else Result := RSStrToIntEx(Text,i,i);
  if i>=3 then
    Result:=FValue
  else
    Result:=CheckValue(Result);
end;

procedure TRSSpinEdit.IncrementValue(mul: int);
var
  v: Integer;
begin
  v:= Value;
  mul:= mul*FIncrement;
  if mul < 0 then
    if v > low(int) - mul then
      Value:= v + mul
    else
      Value:= low(int)
  else
    if v < MaxInt - mul then
      Value:= v + mul
    else
      Value:= MaxInt;
end;

function TRSSpinEdit.IsValidInputChar(c: Char): Boolean;
var
  i: int;
begin
  i:= FBase;
  if i<2 then i:=16;
  Result:= (c = '+') or (c = '-') or
    ((RSCharToInt(c, i)>=0) or (c = '$') and (FBase <= 1)) or
    (FThous and ((FThousSep = #0) and (c = ThousandSeparator) or (c = FThousSep)));
end;

procedure TRSSpinEdit.SetBase(v: Integer);
var
  c: Char;
begin
  if (v<0) or (v>36) then exit;
  FValue:=Value;
  FBase:=v;
  c:=fThousSep;
  FThousSep:=#0;
  SetThousSep(c);
  FIgnoreTextChange:= true;
  Value:=FValue;
  FIgnoreTextChange:= false;
end;

procedure TRSSpinEdit.SetDigits(v: int);
begin
  v:=IntoRange(v, 0, 41);
  if FDigits=v then  exit;
  FDigits:=v;
  Value:=Value;
end;

procedure TRSSpinEdit.SetMaxValue(v: LongInt);
begin
  FMaxValue:=v;
  Value:=Value;
end;

procedure TRSSpinEdit.SetMinValue(v: LongInt);
begin
  FMinValue:=v;
  Value:=Value;
end;

procedure TRSSpinEdit.SetThous(b: Boolean);
begin
  if b=FThous then exit;
  FValue:= Value;
  fThous:=b;
  Value:= FValue;
end;

procedure TRSSpinEdit.SetThousSep(c: Char);
var
  i: int;
begin
  i:=FBase;
  if i=0 then i:=16;
  if (c=FThousSep) or (c='-') or (c='+') or (RSCharToInt(c,i) >= 0) then exit;
  FValue:= Value;
  fThousSep:=c;
  FIgnoreTextChange:= true;
  Value:= FValue;
  FIgnoreTextChange:= false;
end;

procedure TRSSpinEdit.SetValue(NewValue: Integer);
var
  i:int; s:string; c:char;
begin
  FLastValue:=FValue;
  FValue:=CheckValue(NewValue);
  i:=FBase;
  case i of
    0: i:=10;
    1: i:=16;
  end;
  if FThous then
    if FThousSep=#0 then
      c:=ThousandSeparator
    else
      c:=FThousSep
  else
    c:=#0;

  s:= RSIntToStr(FValue, i, c, true, FDigits);
  if FBase=1 then
    if s[1]='-' then
    begin
      s:='-'+s;
      s[2]:='$';
    end else
      s:='$'+s;

  Text:=s;
end;

procedure TRSSpinEdit.Validate;
var
  old: int;
begin
  old:= FValue;
  FIgnoreTextChange:= true;
  Value:= Value;
  FIgnoreTextChange:= false;
  if FValue<>old then
  begin
    inherited Change;
    DoChanged;
  end;
end;

{ TRSFloatSpinEdit }

function TRSFloatSpinEdit.CheckValue(NewValue: ext): ext;
begin
  Result := NewValue;
  if (FMaxValue >= FMinValue) then
  begin
    if NewValue < FMinValue then
      Result := FMinValue
    else
      if NewValue > FMaxValue then
        Result := FMaxValue;
  end;
end;

constructor TRSFloatSpinEdit.Create(AOwner: TComponent);
begin
  inherited;
  FMaxValue:= Infinity;
  FMinValue:= NegInfinity;
  FPrecision:= 15;
  FIncrement:= 1;
  FIgnoreTextChange:= true;
  Value:=0;
  FIgnoreTextChange:= false;
  FLastValue:=FValue;
end;

procedure TRSFloatSpinEdit.DoChanged;
begin
  if (fValue<>FLastValue) and (Assigned(fOnChanged)) then FOnChanged(self);
  FLastValue:=FValue;
end;

function TRSFloatSpinEdit.GetValue: ext;
var
  s: string;
begin
  s:= Text;
  if FThous then
    s:= RSStringReplace(s, ThousandSeparator, '', [rfReplaceAll]);
  s:= RSStringReplace(s, '.', DecimalSeparator, []);
  Result:= CheckValue(StrToFloatDef(s, FValue));
end;

procedure TRSFloatSpinEdit.IncrementValue(mul: int);
const
  prec = 1E-16;
var
  v: ext;
begin
  v:= Value + mul*FIncrement;
  if abs(v) < FIncrement*prec then
    v:= 0;
  Value:= v;
end;

function TRSFloatSpinEdit.IsMaxValueStored: Boolean;
begin
  Result:= (FMaxValue <> Infinity);
end;

function TRSFloatSpinEdit.IsMinValueStored: Boolean;
begin
  Result:= (FMinValue <> NegInfinity);
end;

function TRSFloatSpinEdit.IsValidInputChar(c: Char): Boolean;
begin
  Result:= (c = '+') or (c = '-') or (c = 'e') or (c = 'E') or
    (RSCharToInt(c, 10)>=0) or (c = '.') or (c = DecimalSeparator);
end;

procedure TRSFloatSpinEdit.SetDotAsSeparator(v: Boolean);
begin
  if v = FDotAsSeparator then exit;
  FValue:= Value;
  FDotAsSeparator:= v;
  FIgnoreTextChange:= true;
  Value:= FValue;
  FIgnoreTextChange:= false;
end;

procedure TRSFloatSpinEdit.SetMaxValue(v: ext);
begin
  FMaxValue:=v;
  Value:=Value;
end;

procedure TRSFloatSpinEdit.SetMinValue(v: ext);
begin
  FMinValue:=v;
  Value:=Value;
end;

procedure TRSFloatSpinEdit.SetPrecision(v: Byte);
begin
  v:= IntoRange(v, 2, 20);
  if v = FPrecision then  exit;
  FPrecision:= v;
  Value:= Value;
end;

procedure TRSFloatSpinEdit.SetThous(b: Boolean);
begin
  if b=FThous then exit;
  FValue:= Value;
  fThous:=b;
  FIgnoreTextChange:= true;
  Value:= FValue;
  FIgnoreTextChange:= false;
end;

procedure TRSFloatSpinEdit.SetValue(NewValue: ext);
var
  fs: TFormatSettings;
begin
  FLastValue:= FValue;
  FValue:= CheckValue(NewValue);
  fs.CurrencyFormat:= CurrencyFormat;
  fs.NegCurrFormat:= NegCurrFormat;
  fs.ThousandSeparator:= ThousandSeparator;
  fs.DecimalSeparator:= DecimalSeparator;
  if DotAsSeparator then
    fs.DecimalSeparator:= '.';
  fs.CurrencyDecimals:= CurrencyDecimals;
  fs.CurrencyString:= CurrencyString;
  if FThous then
    Text:= FloatToStrF(FValue, ffNumber, FPrecision, 0, fs)
  else
    Text:= FloatToStrF(FValue, ffGeneral, FPrecision, 0, fs);
end;

procedure TRSFloatSpinEdit.Validate;
var
  old: ext;
begin
  old:= FValue;
  FIgnoreTextChange:= true;
  Value:= Value;
  FIgnoreTextChange:= false;
  if FValue<>old then
  begin
    inherited Change;
    DoChanged;
  end;
end;

end.
