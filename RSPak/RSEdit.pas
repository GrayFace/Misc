unit RSEdit;

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
  Windows, Messages, SysUtils, Classes, Controls, StdCtrls, RSCommon, RSQ;

{$I RSWinControlImport.inc}

type
  TRSEdit = class(TEdit)
  private
    FOnCreateParams: TRSCreateParamsEvent;
    FProps: TRSWinControlProps;
    FSelAnchor: int;
    function GetCaret:int;
    procedure SetCaret(v:int);
  protected
    procedure CreateParams(var Params:TCreateParams); override;
    procedure TranslateWndProc(var Msg:TMessage);
    procedure WndProc(var Msg:TMessage); override;

    procedure KeyPress(var Key:Char); override;
  public
    constructor Create(AOwner:TComponent); override;
    procedure GetSelection(var Start, Caret: Integer);
    procedure SetSelection(Start, Caret:int);
    property Caret: int read GetCaret write SetCaret;
  published
    property Align;
    property OnCanResize;
    property OnResize;
    {$I RSWinControlProps.inc}
  end;
  
procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('RSPak', [TRSEdit]);
end;

{
********************************** TRSEdit ***********************************
}
constructor TRSEdit.Create(AOwner:TComponent);
begin
  inherited Create(AOwner);
  WindowProc:=TranslateWndProc;
end;

procedure TRSEdit.CreateParams(var Params:TCreateParams);
begin
  inherited CreateParams(Params);
  if Assigned(FOnCreateParams) then FOnCreateParams(self, Params);
end;

function TRSEdit.GetCaret: int;
begin
  Result:= RSEditGetCaret(self, FSelAnchor);
end;

procedure TRSEdit.SetCaret(v:int);
begin
  Perform(EM_SETSEL, v, v);
end;

procedure TRSEdit.GetSelection(var Start, Caret: Integer);
begin
  RSEditGetSelection(self, Start, Caret, FSelAnchor);
end;

procedure TRSEdit.SetSelection(Start, Caret: int);
begin
  RSEditSetSelection(self, Start, Caret);
end;

procedure TRSEdit.TranslateWndProc(var Msg:TMessage);
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

procedure TRSEdit.WndProc(var Msg:TMessage);
begin
  RSProcessProps(self, Msg, FProps);
  inherited;
  RSEditWndProcAfter(self, Msg, FSelAnchor);
end;

procedure TRSEdit.KeyPress(var Key: Char);
begin
  inherited;
  if Key=#1 then // Ctrl+A
  begin
    SelectAll;
    Key:=#0;
  end;
end;

end.
