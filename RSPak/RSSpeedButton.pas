unit RSSpeedButton;

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

{ TODO :
NumGlyphs in Styled mode
DropDown in non-Styled mode
published DropDownGlyph
}

interface

uses
  SysUtils, Classes, Controls, Buttons, Themes, Messages, RSPainters,
  Windows, Graphics, RSCommon, RSQ, RSGraphics, Menus, ExtCtrls, ImgList,
  RSImgList, RSUtils, Math, RSPopupMenu, Types, Forms;

{$I RSControlImport.inc}

type
  TRSSpeedButton = class;
  TRSSpeedButtonPaintEvent = procedure (Sender: TRSSpeedButton;
          DefaultPaint:TRSProcedure; var State: TButtonState; var
          MouseInControl:boolean; MouseReallyInControl:boolean) of object;

  TRSControlArray = RSCommon.TRSControlArray;

  TRSSpeedButton = class(TSpeedButton)
  private
    FProps: TRSControlProps;
    FForceDown: Boolean;
    FHighlightedMild: Boolean;
    FHighlighted: Boolean;
    FHighlightedXP: Boolean;
    FOnPaint: TRSSpeedButtonPaintEvent;
    FStyled: Boolean;
    FStyledOnXP: Boolean;
    FDrawFrame: Boolean;
    FOnDropDown: TNotifyEvent;
    FDropDownDisabled: Boolean;
    procedure SetDropDownDisabled(v: Boolean);
    procedure SetDropDownMenu(v: TPopupMenu);
    procedure SetDropDown(v: Boolean);
    procedure SetDropDownWidth(v: int);
    procedure SetForceDown(v: Boolean);
    procedure SetHighlightedMild(v: Boolean);
    procedure SetHighlighted(v: Boolean);
    procedure SetHighlightedXP(v: Boolean);
    procedure SetStyled(v: Boolean);
    procedure SetStyledOnXP(v: Boolean);
    function GetColors:TRSColorTheme;
    procedure SetColors(v: TRSColorTheme);
    procedure SetDrawFrame(v: Boolean);

    procedure CountPos(var x, tx:int; w, gw, tw:int; Right:boolean);
  protected
    FColors: TRSColorTheme;
    FBlockRepaint: Boolean;
    FPaintCount: ShortInt;
    FNoBrush: TBrush;
    FNoPen: TPen;
    FBlockClick: Boolean;
    FClicked: Boolean;
    FDropDown: Boolean;
    FDropDownWidth: int;
    FDropDownGlyph: TBitmap;
    FDragging: Boolean;
    FDropped: Boolean;
    FDropDownMenu: TPopupMenu;
    procedure DefPaint;
    procedure GlyphTextPos(var gx, gy:int; var TextRect:TRect);
    procedure DrawBorder;
    procedure DrawDropDownGlyph;
    procedure DoPaint; virtual;
    procedure Paint; override;
    // down and up state changes must occur before corresponding event calls
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure TranslateWndProc(var Msg: TMessage);
    procedure WndProc(var Msg: TMessage); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure CMButtonPressed(var Message: TMessage); message CM_BUTTONPRESSED;
  public
    constructor Create(AOwner:TComponent); override;
    destructor Destroy; override;
    procedure Invalidate; override;
    procedure Repaint; override;
    procedure BlockRepaint(Block:Boolean=true);
    procedure Click; override;

    function IsStyled:Boolean;
    function IsHighlighted: Boolean;
    property Canvas;
    property ForceDown: Boolean read FForceDown write SetForceDown;
    // State is made public through this import, because otherwise
    // Ctrl+Shift+C creates a new FState field
    {$I RSSpeedButton.inc}
    property GetColorTheme: TRSColorTheme read FColors;
    property PaintCount:ShortInt read FPaintCount;
    property DropDownGlyph: TBitmap read FDropDownGlyph;
  published
    property ColorTheme: TRSColorTheme read GetColors write SetColors;
    property DrawFrame: Boolean read FDrawFrame write SetDrawFrame default false;
    property HighlightedMild: Boolean read FHighlightedMild write SetHighlightedMild default false;
    property Highlighted: Boolean read FHighlighted write SetHighlighted default false;
    property HighlightedXP: Boolean read FHighlightedXP write SetHighlightedXP default false;
    property OnPaint: TRSSpeedButtonPaintEvent read FOnPaint write FOnPaint;
    property Styled: boolean read FStyled write SetStyled default false;
    property StyledOnXP: boolean read FStyledOnXP write SetStyledOnXP default false;
    property DropDown: Boolean read FDropDown write SetDropDown default false;
    property DropDownDisabled: Boolean read FDropDownDisabled write SetDropDownDisabled default false;
    property DropDownWidth: int read FDropDownWidth write SetDropDownWidth default 13;
    property DropDownMenu: TPopupMenu read FDropDownMenu write SetDropDownMenu;
    property OnDropDown: TNotifyEvent read FOnDropDown write FOnDropDown;

    property OnCanResize;
    property OnContextPopup;
    property OnResize;
    {$I RSControlProps.inc}
  end;

var RSBindToolBar:boolean;

function RSMakeToolBar(Control:TWinControl; const Items:array of TMenuItem;
                       var Controls:TRSControlArray;
                       Indent:int=0; SepWidth:int=8; SepHeight:int=18;
                       ItemWidth:int=23; ItemHeight:int=22;
                       Space:int=0):int; overload;

function RSMakeToolBar(Control:TWinControl; const Items:array of TMenuItem;
                       Indent:int=0; SepWidth:int=8; SepHeight:int=18;
                       ItemWidth:int=23; ItemHeight:int=22;
                       Space:int=0):int; overload;

function RSToolBarSender(Sender:TObject):TMenuItem;
procedure RSToolBarCheck(MenuItem:TMenuItem; Check:boolean);
procedure RSToolBarEnable(MenuItem:TMenuItem; Enable:boolean);

procedure RSToolBarReactCheck(Sender:TObject; MenuItem:TMenuItem); overload;
procedure RSToolBarReactCheck(Sender:TObject); overload;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('RSPak', [TRSSpeedButton]);
end;

{
******************************** TRSSpeedButton ********************************
}
constructor TRSSpeedButton.Create(AOwner:TComponent);
begin
  inherited Create(AOwner);
  FNoBrush:= TBrush.Create;
  FNoPen:= TPen.Create;
  FColors:= RSColorTheme;
  WindowProc:= TranslateWndProc;
  FDropDownWidth:= 13;
  FDropDownGlyph:= TBitmap.Create;
  with FDropDownGlyph, Canvas do
  begin
    Width:= 5;
    Height:= 4;
    Brush.Color:= clWhite;
    FillRect(Rect(0, 0, 5, 4));
    Pen.Color:= clBlack;
    MoveTo(0, 1);
    LineTo(4, 1);
    LineTo(2, 3);
    LineTo(1, 2);
    LineTo(3, 2);
    Transparent:= true;
  end;
end;

destructor TRSSpeedButton.Destroy;
begin
  FNoBrush.Free;
  FNoPen.Free;
  FDropDownGlyph.Free;
  inherited Destroy;
end;

procedure TRSSpeedButton.DefPaint;
var
  oldBrush: TBrush;
  oldPen: TPen;
begin
  oldBrush:=TBrush.Create;
  oldPen:=TPen.Create;
  oldBrush.Assign(Canvas.Brush);
  oldPen.Assign(Canvas.Pen);
  Canvas.Brush:=fNoBrush;
  Canvas.Pen:=fNoPen;
  Canvas.Font:=self.Font;
  DoPaint;
  Canvas.Brush:=oldBrush;
  Canvas.Pen:=oldPen;
  oldBrush.Free;
  oldPen.Free;
end;

function TRSSpeedButton.IsStyled:Boolean;
begin
  if ThemeServices.ThemesEnabled then
    Result:=FStyledOnXP
  else
    Result:=FStyled;
end;

procedure TRSSpeedButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  old: TMouseEvent;
  drop: Boolean;
begin
  old:= OnMouseDown;
  OnMouseDown:= nil;
  try
    inherited;
  finally
    OnMouseDown:= old;
  end;
  if (Button = mbLeft) and Enabled then
    FDragging:= true;
  drop:= not FDropped and (Button = mbLeft) and Enabled and FDropDown
                                     and (X >= Width - FDropDownWidth - 1);
  FDropped:= drop or FDropped;
  if Assigned(old) then
    old(self, Button, Shift, X, Y);
  if drop then
  begin
    if not FDropDownDisabled then
    begin
      if Assigned(OnDropDown) then
        OnDropDown(self);
      if FDropDownMenu <> nil then
        with Parent.ClientToScreen(Point(Left, Top + Height)) do
          FDropDownMenu.Popup(X, Y);
    end;
    Application.ProcessMessages;
    if FDragging then //and (GetKeyState(VK_LBUTTON) >= 0) then
    begin
      Shift:= [];
      if GetKeyState(VK_SHIFT) < 0 then  Include(Shift, ssShift);
      if GetKeyState(VK_CONTROL) < 0 then  Include(Shift, ssCtrl);
      if GetKeyState(VK_MENU) < 0 then  Include(Shift, ssAlt);
      if GetKeyState(VK_LBUTTON) < 0 then  Include(Shift, ssLeft);
      if GetKeyState(VK_RBUTTON) < 0 then  Include(Shift, ssRight);
      if GetKeyState(VK_MBUTTON) < 0 then  Include(Shift, ssMiddle);
      with Parent.ScreenToClient(Mouse.CursorPos) do
        MouseUp(mbLeft, Shift, X, Y);
    end;
  end;
end;

procedure TRSSpeedButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  old: TMouseEvent;
  b: Boolean;
begin
  b:= false;
  if Button = mbLeft then
  begin
    if FDragging then
      Invalidate;
    FDragging:= false;
    old:= OnMouseUp;
    OnMouseUp:= nil;
    FBlockClick:= true;
    FClicked:= false;
    try
      inherited;
    finally
      OnMouseUp:= old;
      FBlockClick:= false;
      b:= FClicked and not FDropped;
      FClicked:= false;
      FDropped:= false;
    end;
  end;
  if Assigned(OnMouseUp) then
    OnMouseUp(self, Button, Shift, X, Y);
  if b then
    Click;
end;

function TRSSpeedButton.IsHighlighted: Boolean;
begin
  if not ThemeServices.ThemesEnabled then
    Result:= FHighlighted
  else
    Result:= FHighlightedXP;
end;

procedure TRSSpeedButton.CountPos(var x, tx:int; w, gw, tw:int; Right:boolean);
var aw, sp:int;
begin
  if (gw=0) or (tw=0) then
    sp:= 0
  else
    sp:= Spacing;
  aw:=gw + tw + sp;

  if not Right then
  begin
    if Margin<0 then
      x:= (w - aw + 1) div 2
    else
      x:= Margin + 1;

    tx:= x + gw + sp;
  end else
  begin
    if Margin<0 then
      tx:= (w - aw + 1) div 2
    else
      tx:= w - aw - Margin - 1;

    x:= tx + tw + sp;
  end;
end;

procedure TRSSpeedButton.GlyphTextPos(var gx, gy:int; var TextRect:TRect);
var
  w, h, ty, tx:int;
begin
  FillChar(TextRect, SizeOf(TextRect), 0);
  if Caption<>'' then
    DrawText(Canvas.Handle, ptr(Caption), length(Caption), TextRect,
       DT_CALCRECT or DT_NOCLIP);

  w:= Width;
  h:= Height;
  if FDropDown then
    dec(w, FDropDownWidth);
  if Layout in [blGlyphLeft, blGlyphRight] then
  begin
    gy:= (h - Glyph.Height + 1) div 2;
    ty:= (h - TextRect.Bottom + 1) div 2;
    CountPos(gx, tx, w, Glyph.Width, TextRect.Right, Layout=blGlyphRight);
  end else
  begin
    gx:= (w - Glyph.Width + 1) div 2;
    tx:= (w - TextRect.Right + 1) div 2;
    CountPos(gy, ty, h, Glyph.Height, TextRect.Bottom, Layout=blGlyphBottom);
  end;
  OffsetRect(TextRect, tx, ty);
end;

procedure TRSSpeedButton.DrawBorder;
begin
  with Canvas do
  begin
    MoveTo(1, 0);
    LineTo(Width-1, 0);
    MoveTo(0, 1);
    LineTo(0, Height-1);
    MoveTo(1, Height-1);
    LineTo(Width-1, Height-1);
    MoveTo(Width-1, 1);
    LineTo(Width-1, Height-1);
    if FDropDown then
    begin
      MoveTo(Width - FDropDownWidth, 1);
      LineTo(Width - FDropDownWidth, Height-1);
    end;
  end;
end;

procedure TRSSpeedButton.DrawDropDownGlyph;
var
  x, y: int;
begin
  if not FDropDown then  exit;
  x:= Width - (FDropDownWidth + FDropDownGlyph.Width + 1) div 2;
  y:= (Height - FDropDownGlyph.Height + 1) div 2;
  if not Enabled or FDropDownDisabled then
    FColors.DrawGlyph(Canvas, x, y, FDropDownGlyph, [odDisabled], FColors.Button)
  else
    Canvas.Draw(x, y, FDropDownGlyph);  
end;

procedure TRSSpeedButton.DoPaint;
var
  x, y: int; moused, NoBorder:Boolean; r:TRect;
begin
  moused:= MouseInControl;
  NoBorder:= false;

  with Canvas do
    if IsStyled then
    begin
      FColors.CheckColors;

      GlyphTextPos(x, y, r);

      if not Enabled then
      begin
        if IsHighlighted then
          RSGradientV(Canvas, Rect(1,1,Width-1,Height-1),
             RSMixColors(FColors.SelButton1, FColors.Button, 128),
             RSMixColors(FColors.SelButton2, FColors.Button, 128))
        else if FHighlightedMild then
          RSGradientV(Canvas, Rect(1,1,Width-1,Height-1),
             RSMixColors(FColors.SelButton1, FColors.Button, 64),
             RSMixColors(FColors.SelButton2, FColors.Button, 64))
        else if not Transparent then
        begin
          Brush.Color:=FColors.Button;
          FillRect(ClipRect);
        end;

        FColors.DrawGlyph(Canvas, x, y, Glyph, [odDisabled], FColors.Button);
        DrawDropDownGlyph;

        if Down or IsHighlighted or FHighlightedMild then
        begin
          Pen.Color:= RSMixColors(FColors.Disabled, FColors.Button, 160);
          DrawBorder;
        end else
          NoBorder:= true;
      end else
        if (FState = bsDown) or (FState = bsExclusive) then
        begin
          Brush.Color:=FColors.CheckedButton;
          Pen.Color:=FColors.SelBorder;
          FillRect(Rect(1, 1, Width-1, Height-1));
          //Rectangle(Rect(0,0,Width,Height));

          if Height<10 then
          begin
            RSGradientV(Canvas, Rect(1, 1, Width-1, Height div 2),
              FColors.Light, FColors.CheckedButton);
            RSGradientV(Canvas, Rect(1, Height div 2, Width-1, Height-1),
              FColors.CheckedButton, FColors.Dark);
          end else
          begin
            RSGradientV(Canvas, Rect(1,1,Width-1,5),
              FColors.Light, FColors.CheckedButton);
            RSGradientV(Canvas, Rect(1,Height-5,Width-1,Height-1),
              FColors.CheckedButton, FColors.Dark);
          end;
{          RSGradientV(Canvas, Rect(1,1,Width-1,Height-1),
          RSMixColorsNorm(FColors.SelColor,clWhite,100), FColors.SoftLightColor);
}

{          // this will make sub-buttons behave as separate:
          if FDropped then
          begin
            RSGradientV(Canvas, Rect(1,1,Width-FDropDownWidth-1,Height-1),
               FColors.SelButton1, FColors.SelButton2);

            FColors.DrawGlyph(Canvas, x, y, Glyph, [odHotLight], FColors.Button);
          end else
          begin
            RSGradientV(Canvas, Rect(Width-FDropDownWidth,1,Width-1,Height-1),
               FColors.SelButton1, FColors.SelButton2);

            Draw(x, y, Glyph);
          end;
}
          Draw(x, y, Glyph);
          DrawDropDownGlyph;
          DrawBorder;
        end else
          if moused then
          begin
            RSGradientV(Canvas, Rect(1,1,Width-1,Height-1),
               FColors.SelButton1, FColors.SelButton2);

            FColors.DrawGlyph(Canvas, x, y, Glyph, [odHotLight], FColors.Button);
            DrawDropDownGlyph;

             // Frame
            Pen.Color:=FColors.SelBorder;
            DrawBorder;
          end else
          if FHighlightedMild then
          begin
            RSGradientV(Canvas, Rect(1,1,Width-1,Height-1),
               RSMixColors(FColors.SelButton1, FColors.Button, 128),
               RSMixColors(FColors.SelButton2, FColors.Button, 128));

            FColors.DrawGlyph(Canvas, x, y, Glyph, [odHotLight], FColors.Button);
            DrawDropDownGlyph;

             // Frame
            Pen.Color:= RSMixColors(FColors.SelBorder, FColors.Button, 128);
            DrawBorder;
          end else
          begin
            Brush.Color:=FColors.Button;
            if Transparent then
              Brush.Style:=bsClear
            else
              FillRect(ClipRect);
            Draw(x, y, Glyph);
            DrawDropDownGlyph;
            NoBorder:= true;
          end;

       // Text
      if not Enabled then Font.Color:=FColors.Disabled;
      Brush.Style:=bsClear;
      DrawText(Handle, ptr(Caption), length(Caption), r, DT_NOCLIP or DT_CENTER);

      if NoBorder and (DrawFrame or (csDesigning in ComponentState)) then
      begin
        Pen.Color:= RSMixColors(clBtnShadow, FColors.Button, 180);
        DrawBorder;
      end;
      
    end else
      inherited Paint;
end;

procedure TRSSpeedButton.BlockRepaint(Block:Boolean=true);
begin
  FBlockRepaint:=Block;
end;

procedure TRSSpeedButton.Invalidate;
begin
  if not FBlockRepaint then
    inherited;
end;

procedure TRSSpeedButton.Repaint;
begin
  if not FBlockRepaint then
    inherited;
end;

procedure TRSSpeedButton.Paint;
var
  StateBefore: TButtonState;
  MousedBefore: Boolean;
  p: TPoint;
begin
  if FPaintCount>0 then
  begin
    FPaintCount:=2;
    exit;
  end;

  repeat
    FPaintCount:=1;
    
    //FBlockRepaint:=true;

    Glyph.Handle; // There's a bug in TBitmap

    Glyph.Transparent:=true;
     // Will also cause an additonal invalidate on start which is
     // a workaround for a strange transparency bug

    //FBlockRepaint:=false;

    Canvas.Brush:=fNoBrush;
    Canvas.Pen:=fNoPen;


    if not Enabled then
      FState := bsDisabled
    else
      if FState = bsDisabled then
        if (GroupIndex <> 0) and Down then
          FState := bsExclusive
        else
          FState := bsUp;

     // Getting rid of TSpeedButton bugs
    if FProps.MouseIn and Parent.HandleAllocated then
    begin
      GetCursorPos(p);
      windows.ScreenToClient(Parent.Handle, p);
      FProps.MouseIn:=PtInRect(BoundsRect, p);
    end;

     // Getting rid of TSpeedButton bugs
    if (FState=bsDown) and (GetKeyState(VK_LBUTTON)>=0) and (GroupIndex=0) then
      FState:=bsUp;

    FDragging:= FDragging and Enabled;
    Pboolean(@MouseInControl)^:= FProps.MouseIn;

    Canvas.Font := Self.Font;

    StateBefore:=FState;
    if fForceDown and (FState=bsUp) then FState:=bsDown;

    MousedBefore:=MouseInControl;

    if IsHighlighted or FDragging then
      Pboolean(@MouseInControl)^:=true; // Cracking a readonly property

    try
      if Assigned(FOnPaint) then
        fOnPaint(self, DefPaint, fState, Pboolean(@MouseInControl)^,
                 FProps.MouseIn)
      else
        DefPaint;

    finally
      Pboolean(@MouseInControl)^:=MousedBefore;
      FState:=StateBefore;
      FBlockRepaint:=false;
      if FPaintCount=1 then
        FPaintCount:=0
      else
        FPaintCount:=-1; // Safe in case of exception
    end;
  until FPaintCount=0;
end;

procedure TRSSpeedButton.SetForceDown(v: Boolean);
begin
  if fForceDown=v then exit;
  fForceDown:=v;
  if fState=bsUp then Invalidate;
end;

procedure TRSSpeedButton.SetHighlighted(v: Boolean);
begin
  if fHighlighted=v then exit;
  fHighlighted:=v;
  if not MouseInControl and not ThemeServices.ThemesEnabled then
    Invalidate;
end;

procedure TRSSpeedButton.SetHighlightedMild(v: Boolean);
begin
  if FHighlightedMild = v then  exit;
  FHighlightedMild:=v;
  if not FHighlighted and not MouseInControl and not ThemeServices.ThemesEnabled then
    Invalidate;
end;

procedure TRSSpeedButton.SetHighlightedXP(v: Boolean);
begin
  if fHighlightedXP=v then exit;
  fHighlightedXP:=v;
  if not MouseInControl and ThemeServices.ThemesEnabled then
    Invalidate;
end;

procedure TRSSpeedButton.SetStyled(v: Boolean);
begin
  if FStyled=v then exit;
  FStyled:=v;
  if not ThemeServices.ThemesEnabled then Invalidate;
end;

procedure TRSSpeedButton.SetStyledOnXP(v: Boolean);
begin
  if FStyledOnXP=v then exit;
  FStyledOnXP:=v;
  if ThemeServices.ThemesEnabled then Invalidate;
end;

procedure TRSSpeedButton.SetDrawFrame(v: Boolean);
begin
  if FDrawFrame=v then  exit;
  FDrawFrame:=v;
  if not FProps.MouseIn then  Invalidate;
end;

procedure TRSSpeedButton.SetDropDown(v: Boolean);
begin
  if FDropDown = v then  exit;
  FDropDown:= v;
  Invalidate;
end;

procedure TRSSpeedButton.SetDropDownDisabled(v: Boolean);
begin
  if FDropDownDisabled = v then  exit;
  FDropDownDisabled:= v;
  Invalidate;
end;

procedure TRSSpeedButton.SetDropDownMenu(v: TPopupMenu);
begin
  if FDropDownMenu = v then  exit;
  if FDropDownMenu <> nil then
    FDropDownMenu.RemoveFreeNotification(self);
  FDropDownMenu:= v;
  if v <> nil then
    v.FreeNotification(self);
end;

procedure TRSSpeedButton.SetDropDownWidth(v: int);
begin
  if FDropDownWidth = v then  exit;
  FDropDownWidth:= v;
  Invalidate;
end;

function TRSSpeedButton.GetColors:TRSColorTheme;
begin
  Result:=FColors;
  if Result=RSColorTheme then
    Result:=nil;
end;

procedure TRSSpeedButton.SetColors(v: TRSColorTheme);
begin
  if v=nil then
    v:=RSColorTheme;

  if FColors=v then exit;
  if FColors<>RSColorTheme then
    FColors.RemoveFreeNotification(self);
  FColors:=v;
  if v<>RSColorTheme then
    v.FreeNotification(self);
  if IsStyled then
    Invalidate;
end;

procedure TRSSpeedButton.TranslateWndProc(var Msg: TMessage);
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

procedure TRSSpeedButton.WndProc(var Msg: TMessage);
var b:boolean;
begin
  case Msg.Msg of
    CM_MouseEnter:
      b:= not FProps.MouseIn;
    CM_MouseLeave:
      b:= FProps.MouseIn;
    else
      b:= false;
  end;
  RSProcessProps(self, Msg, FProps);
  if b then
    if IsHighlighted then
      Pboolean(@MouseInControl)^:= FProps.MouseIn
    else
      if IsStyled then
        Invalidate;

  inherited;
end;

procedure TRSSpeedButton.Notification(AComponent: TComponent;
   Operation: TOperation);
begin
  inherited;
  if Operation=opRemove then
    if AComponent = FColors then
      FColors:= RSColorTheme
    else if AComponent = FDropDownMenu then
      FDropDownMenu:= nil;
end;

procedure TRSSpeedButton.Click;
begin
  if FBlockClick then
    FClicked:= true
  else
    inherited;
end;

procedure TRSSpeedButton.CMButtonPressed(var Message: TMessage);
begin
  inherited;
   // TSpeedButton bug: when AllowAllUp = false, Down = true and you set
   //  GroupIndex to 0, the button stays pressed.
  if (ptr(Message.LParam) = self) and (GroupIndex = 0) and Down then
  begin
    PBoolean(@Down)^:= false;
    FState:= bsUp;
    Repaint;
  end;
end;

{
--------------------------------------------------------------------------------
}

function RSMakeToolBar(Control:TWinControl; const Items:array of TMenuItem;
                       var Controls:TRSControlArray;
                       Indent, SepWidth, SepHeight, ItemWidth, ItemHeight:int;
                       Space:int):int;
var
  il: TCustomImageList;
  m, m1: TMenuItem;
  popup: TRSPopupMenu;
  i, y, SepY: int;
begin
  y:=(Control.ClientHeight-ItemHeight) div 2;
  SepY:=(Control.ClientHeight-SepHeight) div 2;
//  inc(Indent, y);
  SetLength(Controls, high(Items)-low(Items)+1);
    for i:=Low(Items) to High(Items) do
    begin
      m:= Items[i];
      if (m<>nil) and not m.IsLine then
        if (m.Count = 0) or (i = 0) or not (Controls[i - 1] is TRSSpeedButton) then
        begin
          Controls[i]:= TRSSpeedButton.Create(Control);

          with TRSSpeedButton(Controls[i]) do
          begin
            Width:= ItemWidth;
            Height:= ItemHeight;
            Top:= y;
            Left:= Indent;
            if RSBindToolBar then
            begin
              Tag:=int(m);
              m.Tag:=int(Controls[i]);
            end else
              Tag:=m.Tag;
            Enabled:=RSIsEnabled(m);
            Styled:=true;
            StyledOnXP:=true;

            il:=m.GetImageList;
            if (il<>nil) and (m.ImageIndex<>-1) then
              RSImgListToBmp(il, m.ImageIndex, Glyph)
            else
              Glyph:=m.Bitmap;

            Hint:= StripHotkey(m.Caption);
            if m.Hint <> '' then
              Hint:= Hint + '|' + m.Hint;

            m1:=m.Parent;
            if m.RadioItem or m.AutoCheck or
               (m.GroupIndex<>0) and ((m1.IndexOf(m) = 0) or
               (m1[m1.IndexOf(m) - 1].GroupIndex<>m.GroupIndex)) then
            begin
              GroupIndex:=m.GroupIndex;
              Down:=m.Checked;
            end;

            if not m.RadioItem then
              AllowAllUp:= true;

            OnClick:= m.OnClick;
            Parent:= Control;
            inc(Indent, ItemWidth + Space);
          end
        end else
          with TRSSpeedButton(Controls[i - 1]) do
          begin
            Controls[i]:= Controls[i - 1];
            inc(Indent, DropDownWidth);
            Width:= Width + DropDownWidth;
            DropDown:= true;
            popup:= TRSPopupMenu.Create(Controls[i]);
            popup.SetItems(m);
            DropDownMenu:= popup;
            OnDropDown:= m.OnClick;
            if RSBindToolBar then
              m.Tag:=int(Controls[i]);
          end
      else
        if SepHeight>0 then
        begin
          Controls[i]:=TBevel.Create(Control);
          with TBevel(Controls[i]) do
          begin
            Width:=1;
            Height:=SepHeight;
            Top:=SepY;
            Left:=Indent + (SepWidth-1) div 2;
            Shape:=bsLeftLine;
            Parent:=Control;
          end;
          inc(Indent, SepWidth);
        end else
        begin
          Controls[i]:=nil;
          inc(Indent, SepWidth);
        end;
    end;
  Result:=Indent;
end;

function RSMakeToolBar(Control:TWinControl; const Items:array of TMenuItem;
                       Indent, SepWidth, SepHeight, ItemWidth, ItemHeight:int;
                       Space:int):int;//TRSControlArray;
var a:TRSControlArray;
begin
  Result:=RSMakeToolBar(Control, Items, a, Indent, SepWidth, SepHeight,
            ItemWidth, ItemHeight, Space);
end;

function RSToolBarSender(Sender:TObject):TMenuItem;
begin
  if Sender is TMenuItem then
    Result:=ptr(Sender)
  else
    Result:=ptr((Sender as TRSSpeedButton).Tag);
end;

procedure RSToolBarCheck(MenuItem:TMenuItem; Check:boolean);
begin
  MenuItem.Checked:=Check;
  TRSSpeedButton(MenuItem.Tag).Down:=Check;
end;

procedure EnableItem(it:TMenuItem; Enable:boolean);
var i:int;
begin
  if it.Tag<>0 then TRSSpeedButton(it.Tag).Enabled:=Enable;
  for i:=0 to it.Count-1 do
    if it[i].Enabled then
      EnableItem(it[i], Enable);
end;

procedure RSToolBarEnable(MenuItem:TMenuItem; Enable:boolean);
begin
  MenuItem.Enabled:=Enable;
  EnableItem(MenuItem, Enable);
end;

procedure RSToolBarReactCheck(Sender:TObject; MenuItem:TMenuItem); overload;
var b:boolean;
begin
  if Sender=MenuItem then
  begin
    b:=not TRSSpeedButton(MenuItem.Tag).Down;
    TRSSpeedButton(MenuItem.Tag).Down:=b;
  end else
    b:=(Sender as TRSSpeedButton).Down;

  MenuItem.Checked:=b;
end;

procedure RSToolBarReactCheck(Sender:TObject); overload;
begin
  if Sender is TRSSpeedButton then
    RSToolBarReactCheck(Sender, TMenuItem(TRSSpeedButton(Sender).Tag))
  else
    RSToolBarReactCheck(Sender, Sender as TMenuItem);
end;

end.
