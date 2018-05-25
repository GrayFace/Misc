unit RSPanel;

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
  Windows, Messages, Classes, Controls, ExtCtrls, Graphics, RSQ, RSCommon;

{$I RSWinControlImport.inc}

type
  TRSCustomControl = RSCommon.TRSCustomControl;
  TRSWndPaintEvent = RSCommon.TRSWndPaintEvent;

  TRSPanel = class (TPanel)
  private
    FProps: TRSWinControlProps;
    FNoBrush: TBrush;
    FNoPen: TPen;
    FOnCreateParams: TRSCreateParamsEvent;
    FOnPaint: TRSWndPaintEvent;
    FBlockRepaint: Boolean;
    function GetBevelExEdges: TBevelEdges;
    function GetBevelExInner: TBevelCut;
    function GetBevelExKind: TBevelKind;
    function GetBevelExOuter: TBevelCut;
    function GetBevelExWidth: TBevelWidth;
    procedure SetBevelExEdges(v: TBevelEdges);
    procedure SetBevelExInner(v: TBevelCut);
    procedure SetBevelExKind(v: TBevelKind);
    procedure SetBevelExOuter(v: TBevelCut);
    procedure SetBevelExWidth(v: TBevelWidth);
  protected
    FPaintCount: ShortInt;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure DefPaint;
    procedure DoPaint; virtual;
    procedure Paint; override;
    procedure WndProc(var Msg: TMessage); override;
    procedure TranslateWndProc(var Msg: TMessage);
  public
    constructor Create(AOwner:TComponent); override;
    destructor Destroy; override;
    procedure Invalidate; override;
    procedure Repaint; override;
    property Canvas;
  published
    procedure BlockRepaint(Block:Boolean=true);
    property BevelExEdges: TBevelEdges read GetBevelExEdges
               write SetBevelExEdges default [beLeft,beTop,beRight,beBottom];
    property BevelExInner: TBevelCut
               read GetBevelExInner write SetBevelExInner default bvRaised;
    property BevelExKind: TBevelKind
               read GetBevelExKind write SetBevelExKind default bkNone;
    property BevelExOuter: TBevelCut
               read GetBevelExOuter write SetBevelExOuter default bvLowered;
    property BevelExWidth: TBevelWidth
               read GetBevelExWidth write SetBevelExWidth default 1;
    property OnPaint: TRSWndPaintEvent read FOnPaint write FOnPaint;
    {$I RSWinControlProps.inc}
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('RSPak', [TRSPanel]);
end;

type
  TStripWinControl = class(TWinControl)
  end;

{
*********************************** TRSPanel ***********************************
}
constructor TRSPanel.Create(AOwner:TComponent);
begin
  inherited Create(AOwner);
  fNoBrush:=TBrush.Create;
  fNoPen:=TPen.Create;
  ControlStyle:= ControlStyle - [csSetCaption]; // Annoying thing 
  WindowProc:=TranslateWndProc;
end;

destructor TRSPanel.Destroy;
begin
  fNoBrush.Free;
  fNoPen.Free;
  inherited Destroy;
end;

procedure TRSPanel.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  if Assigned(FOnCreateParams) then FOnCreateParams(self, Params);
end;

procedure TRSPanel.DefPaint;
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
  DoPaint;
  Canvas.Brush:=oldBrush;
  Canvas.Pen:=oldPen;
  oldBrush.Free;
  oldPen.Free;
end;

procedure TRSPanel.DoPaint;
begin
  inherited Paint;
end;

function TRSPanel.GetBevelExEdges: TBevelEdges;
begin
  Result:=TStripWinControl(self).BevelEdges;
end;

function TRSPanel.GetBevelExInner: TBevelCut;
begin
  Result:=TStripWinControl(self).BevelInner;
end;

function TRSPanel.GetBevelExKind: TBevelKind;
begin
  Result:=TStripWinControl(self).BevelKind;
end;

function TRSPanel.GetBevelExOuter: TBevelCut;
begin
  Result:=TStripWinControl(self).BevelOuter;
end;

function TRSPanel.GetBevelExWidth: TBevelWidth;
begin
  Result:=TStripWinControl(self).BevelWidth;
end;

procedure TRSPanel.Invalidate;
begin
  if not FBlockRepaint then
    inherited;
end;

procedure TRSPanel.Repaint;
begin
  if not FBlockRepaint then
    inherited;
end;

procedure TRSPanel.BlockRepaint(Block:Boolean=true);
begin
  FBlockRepaint:=Block;
end;

procedure TRSPanel.Paint;
begin
  if FPaintCount>0 then
  begin
    FPaintCount:=2;
    exit;
  end;

  repeat
    FPaintCount:=1;
    try
      Canvas.Brush:=fNoBrush;
      Canvas.Pen:=fNoPen;
      if Assigned(FOnPaint) then
        FOnPaint(TRSCustomControl(self), FProps.State, DefPaint)
      else
        DefPaint;
    finally
      FBlockRepaint:=false;
      if FPaintCount=1 then
        FPaintCount:=0
      else
        FPaintCount:=-1; // Safe in case of exception
    end;
  until FPaintCount=0;
end;

procedure TRSPanel.SetBevelExEdges(v: TBevelEdges);
begin
  TStripWinControl(self).BevelEdges:=v;
end;

procedure TRSPanel.SetBevelExInner(v: TBevelCut);
begin
  TStripWinControl(self).BevelInner:=v;
end;

procedure TRSPanel.SetBevelExKind(v: TBevelKind);
begin
  TStripWinControl(self).BevelKind:=v;
end;

procedure TRSPanel.SetBevelExOuter(v: TBevelCut);
begin
  TStripWinControl(self).BevelOuter:=v;
end;

procedure TRSPanel.SetBevelExWidth(v: TBevelWidth);
begin
  TStripWinControl(self).BevelWidth:=v;
end;

procedure TRSPanel.WndProc(var Msg: TMessage);
begin
  RSProcessProps(self, Msg, FProps);
  inherited;
end;

procedure TRSPanel.TranslateWndProc(var Msg: TMessage);
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

end.
