unit RSStringGrid;

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
  Windows, Messages, SysUtils, Classes, Controls, Grids, RSCommon, RSQ,
  RSSysUtils;

{$I RSWinControlImport.inc}

type
  TRSStringGrid = class;

  TRSStringGridCreateEditEvent =
     procedure (Sender: TStringGrid; var Editor: TInplaceEdit) of object;
  TRSGridRowResizeEvent =
     procedure (Sender: TStringGrid; Index, OldSize: Integer) of object;

  TRSStringGrid = class(TStringGrid)
  private
    FOnCreateParams: TRSCreateParamsEvent;
    FProps: TRSWinControlProps;
    FOnBeforeSetEditText: TGetEditEvent;
    FOnCreateEditor: TRSStringGridCreateEditEvent;
    FOnColumnResize: TRSGridRowResizeEvent;
    FOnRowResize: TRSGridRowResizeEvent;
  protected
    FSizingIndex: int;
    procedure CreateParams(var Params:TCreateParams); override;
    procedure TranslateWndProc(var Msg:TMessage);
    procedure WndProc(var Msg:TMessage); override;

    function CreateEditor: TInplaceEdit; override;
    procedure SetEditText(ACol, ARow: Longint; const Value: string); override;
    {$IFNDEF D2007} // D2006 has this bug, in newer versions it might be fixed
    procedure WMCommand(var Msg: TWMCommand); message WM_COMMAND;
    {$ENDIF}
    procedure CalcSizingState(X, Y: Integer; var State: TGridState;
      var Index: Longint; var SizingPos, SizingOfs: Integer;
      var FixedInfo: TGridDrawInfo); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner:TComponent); override;
  published
    property OnColumnResize: TRSGridRowResizeEvent read FOnColumnResize write FOnColumnResize;
    property OnRowResize: TRSGridRowResizeEvent read FOnRowResize write FOnRowResize;
    property OnBeforeSetEditText: TGetEditEvent read FOnBeforeSetEditText write FOnBeforeSetEditText;
    property OnCreateEditor: TRSStringGridCreateEditEvent read FOnCreateEditor write FOnCreateEditor;
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
  RegisterComponents('RSPak', [TRSStringGrid]);
end;

{
********************************** TRSStringGrid ***********************************
}
procedure TRSStringGrid.CalcSizingState(X, Y: Integer; var State: TGridState;
  var Index, SizingPos, SizingOfs: Integer; var FixedInfo: TGridDrawInfo);
begin
  inherited;
  FSizingIndex:= Index;
end;

constructor TRSStringGrid.Create(AOwner:TComponent);
begin
  inherited Create(AOwner);
  WindowProc:=TranslateWndProc;
end;

procedure TRSStringGrid.CreateParams(var Params:TCreateParams);
begin
  inherited CreateParams(Params);
  if Assigned(FOnCreateParams) then FOnCreateParams(self, Params);
end;

procedure TRSStringGrid.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  sizing: TRSGridRowResizeEvent;
  index, size: int;
begin
  sizing:= nil;
  index:= FSizingIndex;
  size:= 0;
  case FGridState of
    gsRowSizing:
    begin
      sizing:= OnRowResize;
      size:= RowHeights[FSizingIndex];
    end;
    gsColSizing:
    begin
      sizing:= OnColumnResize;
      size:= ColWidths[FSizingIndex];
    end;
  end;
  inherited;
  if Assigned(sizing) then
    sizing(self, index, size);
end;

procedure TRSStringGrid.TranslateWndProc(var Msg:TMessage);
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

procedure TRSStringGrid.WndProc(var Msg:TMessage);
begin
  RSProcessProps(self, Msg, FProps);
  inherited;
end;

function TRSStringGrid.CreateEditor: TInplaceEdit;
begin
  Result:=inherited CreateEditor;
  if Assigned(OnCreateEditor) then
    OnCreateEditor(self, Result);
end;

procedure TRSStringGrid.SetEditText(ACol, ARow: Longint; const Value: string);
var v:string;
begin
  v:=Value;
  if Assigned(OnBeforeSetEditText) then
    OnBeforeSetEditText(self, ACol, ARow, v);

  inherited SetEditText(ACol, ARow, v);
end;

 // A bug that prevented ComboBox dropped on grid from showing drop-down list 
procedure TRSStringGrid.WMCommand(var Msg: TWMCommand);
begin
  RSDispatchEx(self, TWinControl, Msg);
  inherited;
end;

end.
