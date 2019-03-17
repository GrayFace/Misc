unit RSShape;

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
  Windows, Messages, SysUtils, Classes, Controls, ExtCtrls, RSCommon, RSQ;

{$I RSControlImport.inc}

type
  TRSShape = class(TShape)
  private
    FProps: TRSControlProps;
  protected
    procedure TranslateWndProc(var Msg: TMessage);
    procedure WndProc(var Msg:TMessage); override;
  public
    property Canvas;
  published
    property OnCanResize;
    property OnClick;
    property OnDblClick;
    property OnResize;
    {$I RSControlProps.inc}
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('RSPak', [TRSShape]);
end;

{
******************************** TRSShape ********************************
}

procedure TRSShape.TranslateWndProc(var Msg: TMessage);
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

procedure TRSShape.WndProc(var Msg:TMessage);
begin
  RSProcessProps(self, Msg, FProps);
  inherited;
end;

end.
