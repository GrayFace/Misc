unit RSListBox;

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
  Windows, Messages, SysUtils, Classes, Controls, StdCtrls, RSCommon, RSQ,
  RSListBoxHint;

{$I RSWinControlImport.inc}

type
  TRSListBox = class(TListBox)
  private
    FOnCreateParams: TRSCreateParamsEvent;
    FProps: TRSWinControlProps;

    FAutoHint: Boolean;
    procedure SetAutoHint(v:Boolean);
  protected
    FHintMan: TRSListBoxHints;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure TranslateWndProc(var Msg: TMessage);
    procedure WndProc(var Msg: TMessage); override;
  public
    constructor Create(AOwner:TComponent); override;
    destructor Destroy; override;
  published
    property AutoHint: Boolean read FAutoHint write SetAutoHint default false;
    property BevelWidth;
    property OnCanResize;
    property OnDblClick;
    property OnResize;
    {$I RSWinControlProps.inc}
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('RSPak', [TRSListBox]);
end;

{
********************************** TRSListBox ***********************************
}
constructor TRSListBox.Create(AOwner:TComponent);
begin
  inherited Create(AOwner);
  WindowProc:=TranslateWndProc;
  FHintMan:=TRSListBoxHints.Create(Font);
  ItemHeight:=13;
end;

destructor TRSListBox.Destroy;
begin
  FHintMan.Free;
  inherited;
end;

procedure TRSListBox.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  if Assigned(FOnCreateParams) then FOnCreateParams(self, Params);
end;

procedure TRSListBox.TranslateWndProc(var Msg: TMessage);
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

procedure TRSListBox.WndProc(var Msg: TMessage);
begin
  RSProcessProps(self, Msg, FProps);

  if AutoHint and HandleAllocated then
  begin
    FHintMan.Handle:=Handle;
    FHintMan.Columns:=Columns;
    FHintMan.BeforeWndProc(Msg);
    inherited;
    FHintMan.AfterWndProc(Msg);
  end else
    inherited;
end;

procedure TRSListBox.SetAutoHint(v:Boolean);
begin
  if FAutoHint=v then exit;
  FAutoHint:=v;
  if v then
    FHintMan.UpdateHint
  else
    FHintMan.HideHint;
end;

end.
