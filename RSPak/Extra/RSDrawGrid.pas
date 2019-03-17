unit RSDrawGrid;

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
  Windows, Messages, SysUtils, Classes, Controls, Grids, RSCommon, RSSysUtils,
  RSQ;

{$I RSWinControlImport.inc}

type
  TRSDrawGrid = class(TStringGrid)
  private
    FOnCreateParams: TRSCreateParamsEvent;
    FProps: TRSWinControlProps;
    //FAllowedInvisibleCellsPart: int;
    //FNeedClientRectChange: Boolean;
  protected
    procedure CreateParams(var Params:TCreateParams); override;
    //function GetClientRect: TRect; override;
    procedure TranslateWndProc(var Msg:TMessage);
    procedure WndProc(var Msg:TMessage); override;

    procedure WMCommand(var Msg: TWMCommand); message WM_COMMAND;
  public
    constructor Create(AOwner:TComponent); override;

    //property AllowedInvisibleCellsPart: int read FAllowedInvisibleCellsPart write FAllowedInvisibleCellsPart;
  published
    property BevelEdges;
    property BevelInner;
    property BevelKind default bkNone;
    property BevelOuter;
    property BevelWidth;
    property InplaceEditor;
    property OnCanResize;
    property OnResize;
    {$I RSWinControlProps.inc}
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('RSPak', [TRSDrawGrid]);
end;

{
********************************** TRSDrawGrid ***********************************
}
constructor TRSDrawGrid.Create(AOwner:TComponent);
begin
  inherited Create(AOwner);
  WindowProc:=TranslateWndProc;
end;

procedure TRSDrawGrid.CreateParams(var Params:TCreateParams);
begin
  inherited CreateParams(Params);
  if Assigned(FOnCreateParams) then FOnCreateParams(self, Params);
end;

{
function TRSDrawGrid.GetClientRect: TRect;
begin
  Result:= inherited GetClientRect;
  if FNeedClientRectChange then
  begin
    inc(Result.Right, FAllowedInvisibleCellsPart);
    inc(Result.Bottom, FAllowedInvisibleCellsPart);
  end;
end;
}

procedure TRSDrawGrid.TranslateWndProc(var Msg:TMessage);
var b:Boolean;
begin
  if assigned(FProps.OnWndProc) then
  begin
    b:=false;
    FProps.OnWndProc(Self, Msg, b, WndProc);
    if b then exit;
  end;
  WndProc(Msg);
end;

procedure TRSDrawGrid.WndProc(var Msg:TMessage);
begin
  RSProcessProps(self, Msg, FProps);
  inherited;
{
  if FNeedClientRectChange then
  begin
    inherited;
    exit;
  end;

  with Msg do
    FNeedClientRectChange:= (FAllowedInvisibleCellsPart <> 0) and
       ((Msg = WM_MOUSEMOVE) or (Msg = WM_LBUTTONDOWN) or (Msg = WM_LBUTTONUP) or
        (Msg = WM_KEYDOWN) or (WParam in [VK_LEFT, VK_RIGHT, VK_DOWN, VK_UP]));

  if FNeedClientRectChange then zD;

  try
    inherited;
  finally
    FNeedClientRectChange:= false;
  end
}
end;

 // A bug that prevented ComboBox dropped on grid from showing drop-down list
procedure TRSDrawGrid.WMCommand(var Msg: TWMCommand);
begin
  RSDispatchEx(self, TWinControl, Msg);
  inherited;
end;

end.
