unit RSGlue;

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
  SysUtils, Classes, Controls, Windows, Messages, RSCommon, RSWinController,
  Forms, RSQ;

type
  TRSWndProcEvent = RSCommon.TRSWndProcEvent;

  TRSGlueArea=(RSgaDefault, RSgaCustom, RSgaScreen);

  TRSGlue = class(TRSCustomWinController)
  private
    fGlueInside: integer;
    fGlueOutside: integer;
    fGlueEdge: integer;
    fGlueArea: TRSGlueArea;
    fResizeGlue: Boolean;
    fResizeMagnets: Boolean;
    fCarryMagnets: Boolean;
  protected
    fRealR: TRect;
    fLastR: TRect;
    fArea: TRect;
    fCarried: array of Boolean;
    function CanActivate:boolean; override;
    procedure GetArea;
    procedure Glue(var r:TRect; Glue:TRect; gIn, gOut:int; Inside:boolean);
    procedure MovingGlue(var r:TRect);
    procedure SizeGlue(Edge:int; var r:TRect; Glue:TRect; gIn, gOut:int);
    procedure ScreenSizeGlue(Edge:int; var r:TRect; Glue:TRect; gIn, gOut:int);
    procedure PrepareRect(var r:TRect);
    procedure CheckCarry(c:TControl);
    procedure WndProc(var Msg:TMessage); override;
  public
    MagnetRects: array of TRect;
    MagnetControls:array of TControl;
    constructor Create(AOwner: TComponent); override;
    function AddMagnet(const r:TRect):integer; overload;
    function AddMagnet(c:TControl):integer; overload;
    property GlueRect: TRect read fArea write fArea;
  published
    property OnWndProc;
    property Control;
    property Active default true;
    property Priority;

    property CarryMagnets: Boolean read fCarryMagnets write fCarryMagnets default false;
    property GlueArea: TRSGlueArea read fGlueArea write fGlueArea default RSgaDefault;
    property GlueInside: integer read fGlueInside write fGlueInside;
    property GlueOutside: integer read fGlueOutside write fGlueOutside;
    property GlueToEdge: integer read fGlueEdge write fGlueEdge;
    property ResizeGlueToScreen: boolean read fResizeGlue write fResizeGlue default false;
    property ResizeGlueToMagnets: boolean read fResizeMagnets write fResizeMagnets default true;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('RSPak', [TRSGlue]);
end;

constructor TRSGlue.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Active:=true;
  Priority:=100;
  fGlueInside:=8;
  fGlueOutside:=30;
  fGlueEdge:=12;
  fGlueArea:=RSgaDefault;
  fResizeMagnets:=true;
  if (csDesigning in ComponentState) and (AOwner<>nil) and
     (AOwner is TControl) then
    Control:=TControl(AOwner);
end;

function TRSGlue.CanActivate:boolean;
begin
  Result:=inherited CanActivate;
  if Result then
    GetArea;
end;

function LinesGlue(var x1, x2:int; l1, l2:int; gIn, gOut:int; Inside:boolean):boolean;
begin
  if not Inside then
  begin
    zSwap(gIn, gOut);
    zSwap(l1, l2);
  end;

// out |L1| in |L2| out.   X1 stick to L1, X2 stick to L2.

  Result:=true;
  if (x2>=l2-gIn) and (x2<=l2+gOut) then
  begin
    x1:=x1+l2-x2;
    x2:=l2;
    exit;
  end;

  if (x1>=l1-gOut) and (x1<=l1+gIn) then
  begin
    x2:=x2+l1-x1;
    x1:=l1;
    exit;
  end;
  Result:=false;
end;

procedure TRSGlue.Glue(var r:TRect; Glue:TRect; gIn, gOut:int; Inside:boolean);
var b:boolean;
begin
  if (r.Right<=Glue.Left) or (r.Left>=Glue.Right) or
     (r.Bottom<=Glue.Top) or (r.Top>=Glue.Bottom) then
    begin
      if Inside or (r.Right<=Glue.Left-gOut) or (r.Left>=Glue.Right+gOut) or
         (r.Bottom<=Glue.Top-gOut) or (r.Top>=Glue.Bottom+gOut) then exit;
      gIn:=0;
    end;

  b:=LinesGlue(r.Left, r.Right, Glue.Left, Glue.Right, gIn, gOut, Inside);
  if b and not Inside then
    LinesGlue(r.Top, r.Bottom, Glue.Top, Glue.Bottom, fGlueEdge, fGlueEdge, true);

  b:=LinesGlue(r.Top, r.Bottom, Glue.Top, Glue.Bottom, gIn, gOut, Inside);
  if b and not Inside then
    LinesGlue(r.Left, r.Right, Glue.Left, Glue.Right, fGlueEdge, fGlueEdge, true);
end;

procedure SizeGlueSide(Edge:int; var x1, x2:int; g1, g2:int; gIn, gOut:int);
begin
  if Edge=2 then
  begin
    if {(x1=g1) and} (x2>=g2-gIn) and (x2<=g2+gOut) then
      x2:=g2;
  end else
  begin
    if {(x2=g2) and} (x1>=g1-gOut) and (x1<=g1+gIn) then
      x1:=g1;
  end;
end;

function CheckGlue(x1, x2, g1, g2, gIn, gOut:int):boolean;
begin
  Result:= (x2=g1) or (x1=g2);
end;

procedure TRSGlue.SizeGlue(Edge:int; var r:TRect; Glue:TRect; gIn, gOut:int);
begin
  if (r.Right<=Glue.Left-gOut) or (r.Left>=Glue.Right+gOut) or
     (r.Bottom<=Glue.Top-gOut) or (r.Top>=Glue.Bottom+gOut) then exit;

// У Edge троичная система счисления

  if (Edge mod 3 <> 0) and
     CheckGlue(r.Top, r.Bottom, Glue.Top, Glue.Bottom, gIn, gOut) then
  begin
    SizeGlueSide(Edge mod 3, r.Left, r.Right, Glue.Left, Glue.Right,
                 fGlueEdge, fGlueEdge);
  end;

  if (Edge div 3 <> 0) and
     CheckGlue(r.Left, r.Right, Glue.Left, Glue.Right, gIn, gOut) then
  begin
    SizeGlueSide(Edge div 3, r.Top, r.Bottom, Glue.Top, Glue.Bottom,
                 fGlueEdge, fGlueEdge);
  end;
end;

procedure TRSGlue.ScreenSizeGlue(Edge:int; var r:TRect; Glue:TRect; gIn, gOut:int);
begin
  if Edge mod 3 <> 0 then
    SizeGlueSide(Edge mod 3, r.Left, r.Right, Glue.Left, Glue.Right, gIn, gOut);
  if Edge div 3 <> 0 then
    SizeGlueSide(Edge div 3, r.Top, r.Bottom, Glue.Top, Glue.Bottom, gIn, gOut);
end;

procedure TRSGlue.MovingGlue(var r:TRect);
var i:int;
begin
  for i:=length(MagnetRects)-1 downto 0 do
    Glue(r, MagnetRects[i], GlueOutside, GlueInside, false);

  for i:=length(MagnetControls)-1 downto 0 do
    with MagnetControls[i] do
      if not fCarried[i] and Visible then
        Glue(r, BoundsRect, GlueOutside, GlueInside, false);

  Glue(r, GlueRect, GlueInside, GlueOutside, true);
end;

procedure TRSGlue.PrepareRect(var r:TRect);
begin
  if fRealR.Left<>MaxInt then
  begin
    OffsetRect(fRealR, r.Left - fLastR.Left, r.Top - fLastR.Top);
    r:= fRealR;
  end else
    fRealR:= r;
end;

procedure TRSGlue.CheckCarry(c:TControl);
var i:int; r,r1:TRect;
begin
  r:=c.BoundsRect;
  for i:=0 to length(fCarried)-1 do
    if not fCarried[i] then
    begin
      r1:=MagnetControls[i].BoundsRect;
      fCarried[i]:= CheckGlue(r.Top, r.Bottom, r1.Top, r1.Bottom, 0, 0)
          or CheckGlue(r.Left, r.Right, r1.Left, r1.Right, 0, 0);
      if fCarried[i] then
        CheckCarry(MagnetControls[i]);
    end;
end;

procedure TRSGlue.WndProc(var Msg:TMessage);
type PWMMoving=^TWMMoving;
var i:int; r:TRect; pr:PRect; p:TPoint;
begin
  if Msg.Msg=WM_Moving then
    with PWMMoving(@msg)^ do
    begin
      pr:=PRect(DragRect);
      PrepareRect(pr^);

       // Process the control and all carried controls as a whole
      for i:=length(MagnetControls)-1 downto 0 do
        if fCarried[i] then
        begin
          r:= MagnetControls[i].BoundsRect;
          OffsetRect(r, pr^.Left - fLastR.Left, pr^.Top - fLastR.Top);
          p:= r.TopLeft;
          MovingGlue(r);
          OffsetRect(pr^, r.Left - p.X, r.Top - p.Y);
        end;

      MovingGlue(pr^);

       // Move carried Magnets
      r.Left:= pr^.Left - fLastR.Left;
      r.Top:= pr^.Top - fLastR.Top;
      if (r.Left <> 0) or (r.Top <> 0) then
        for i:=length(MagnetControls)-1 downto 0 do
          if fCarried[i] then
            with MagnetControls[i] do
              SetBounds(Left + r.Left, Top + r.Top, Width, Height);

      fLastR:=pr^;
    end
  else
    if Msg.Msg=WM_SIZING then
    begin
      if fResizeGlue then
        ScreenSizeGlue(Msg.wParam, PRect(Msg.LParam)^, fArea, GlueInside,
                       GlueOutside);

      if fResizeMagnets then
      begin
        for i:=length(MagnetRects)-1 downto 0 do
          SizeGlue(Msg.wParam, PRect(Msg.LParam)^, MagnetRects[i], GlueOutside,
                   GlueInside);
        for i:=length(MagnetControls)-1 downto 0 do
          with MagnetControls[i] do
            SizeGlue(Msg.wParam, PRect(Msg.LParam)^, BoundsRect, GlueOutside,
                     GlueInside);
      end;
    end;

  inherited;

  if msg.Msg=WM_EnterSizeMove then
  begin
    fRealR.Left:=MaxInt;
    GetArea;
    i:=length(MagnetControls);
    SetLength(fCarried, i);
    FillChar(ptr(fCarried)^, i, 0);
    if CarryMagnets then
      CheckCarry(Control);
  end;
end;

procedure TRSGlue.GetArea;
var w:hwnd;
begin
  case fGlueArea of
    RSgaScreen: // !!! problems on multiple monitors?
      fArea:=Rect(0, 0, GetSystemMetrics(SM_CXSCREEN),
                        GetSystemMetrics(SM_CYSCREEN));
    RSgaDefault:
    begin
      if Control is TWinControl then
        w:=GetParent(TWinControl(Control).handle)
      else
        w:=Control.Parent.Handle;
        
      if (w<>0) and (w<>Application.Handle) then
      begin
        GetClientRect(w,fArea);
        MapWindowPoints(w, 0, fArea, 2);
      end else
        SystemParametersInfo(SPI_GETWORKAREA, 0, @fArea, 0);
    end;
  end;
end;

function TRSGlue.AddMagnet(const r:TRect):integer;
begin
  Result:=length(MagnetRects);
  SetLength(MagnetRects, Result+1);
  MagnetRects[Result]:=r;
end;

function TRSGlue.AddMagnet(c:TControl):integer;
begin
  Result:=length(MagnetControls);
  SetLength(MagnetControls, Result+1);
  MagnetControls[Result]:=c;
end;

end.
