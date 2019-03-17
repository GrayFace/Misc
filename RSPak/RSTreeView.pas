unit RSTreeView;

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
  Windows, Messages, SysUtils, Classes, Controls, ComCtrls, RSCommon;

{$I RSWinControlImport.inc}

type
  TRSTreeView = class(TTreeView)
  private
    FOnCreateParams: TRSCreateParamsEvent;
    FProps: TRSWinControlProps;
  protected
    {$IFDEF D2006}
      // Delphi 2006 bug: TreeView doesn't save state in case DestroyHandle is called
    procedure DestroyWnd; override;
    {$ENDIF}

    procedure CreateParams(var Params:TCreateParams); override;
    procedure TranslateWndProc(var Msg:TMessage);
    procedure WndProc(var Msg:TMessage); override;
  public
    constructor Create(AOwner:TComponent); override;
  published
    property OnCancelEdit;
    property OnCanResize;
    property OnResize;
    {$I RSWinControlProps.inc}
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('RSPak', [TRSTreeView]);
end;

{
********************************** TRSTreeView ***********************************
}
constructor TRSTreeView.Create(AOwner:TComponent);
begin
  inherited Create(AOwner);
  WindowProc:=TranslateWndProc;
end;

procedure TRSTreeView.CreateParams(var Params:TCreateParams);
begin
  inherited CreateParams(Params);
  if Assigned(FOnCreateParams) then FOnCreateParams(self, Params);
end;

{$IFDEF D2006}
procedure TRSTreeView.DestroyWnd;
var state: TControlState;
begin
  state:= ControlState;
  ControlState:= state + [csRecreating];
  inherited;
  ControlState:= state;
end;
{$ENDIF}

procedure TRSTreeView.TranslateWndProc(var Msg:TMessage);
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

procedure TRSTreeView.WndProc(var Msg:TMessage);
begin
  RSProcessProps(self, Msg, FProps);
  inherited;
end;

end.
