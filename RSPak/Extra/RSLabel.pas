unit RSLabel;

{ *********************************************************************** }
{                                                                         }
{ RSPak                                    Copyright (c) Rozhenko Sergey  }
{ http://sites.google.com/site/sergroj/                                   }
{ sergroj@mail.ru                                                         }
{                                                                         }
{ See copyright notice at the end of RSSysUtils.pas file (MIT license).   }
{                                                                         }
{ *********************************************************************** )

 IndentVertical    Adds spece before or after the text according to Layout.
  Default value mekes it position on one line with edit's text.
  Also, you can place it right above an edit, set Layout to tlBottom and the
  spece between it and the edit would be the same as of TLabeledEdit.

 IndentHorizontal  Adds space on the right side if Alignment = taRightJustify.
  This behavior of IndentHorizontal may seem wierd, but that's when it's needed.
  The default space is also similar to one in TLabeledEdit.

{ *********************************************************************** }
{$I RSPak.inc}

// This Indent stuff was useful in Delphi 7, but is bad in Delphi 2006,
// because labels are aligned with edits automatically.

interface

uses
  Windows, Messages, SysUtils, Classes, Controls, StdCtrls, RSCommon, RSQ;

{$I RSControlImport.inc}

type
  TRSLabel = class(TLabel)
  private
    FProps: TRSControlProps;
    FVIndent: int;
    FHIndent: int;
    procedure SetHIndent(v:int);
    procedure SetVIndent(v:int);
  protected
    procedure ChangeRect(var r:TRect; Mul:int);
    procedure DoDrawText(var Rect: TRect; Flags: Longint); override;
    procedure TranslateWndProc(var Msg: TMessage);
    procedure WndProc(var Msg: TMessage); override;
  public
    constructor Create(AOwner:TComponent); override;
    property MouseInside: Boolean read FProps.MouseIn;
  published
    property OnCanResize;
{$IFNDEF D7} // They already exist in TLabel since some version
    property OnMouseEnter: TNotifyEvent read FProps.OnMouseEnter write FProps.OnMouseEnter;
    property OnMouseLeave: TNotifyEvent read FProps.OnMouseLeave write FProps.OnMouseLeave;
{$ENDIF}
    property IndentVertical: int read FVIndent write SetVIndent default 3;
    property IndentHorizontal: int read FHIndent write SetHIndent default 4;
    property OnResize;
    property OnWndProc: TRSWndProcEvent read FProps.OnWndProc write FProps.OnWndProc;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('RSPak', [TRSLabel]);
end;

{
********************************** TRSLabel ***********************************
}
constructor TRSLabel.Create(AOwner:TComponent);
begin
  inherited Create(AOwner);
  WindowProc:=TranslateWndProc;
  FVIndent:=3;
  FHIndent:=4;
end;

procedure TRSLabel.TranslateWndProc(var Msg: TMessage);
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

procedure TRSLabel.WndProc(var Msg: TMessage);
begin
  RSProcessProps(self, Msg, FProps);
  inherited;
end;

procedure TRSLabel.ChangeRect(var r:TRect; Mul:int);
begin
  if Alignment=taRightJustify then
    inc(r.Right, Mul*FHIndent);
  if Layout=tlTop then
    dec(r.Top, Mul*FVIndent)
  else
    if Layout=tlBottom then
      inc(r.Bottom, Mul*FHIndent);
end;

{$W-}
procedure TRSLabel.DoDrawText(var Rect: TRect; Flags: Longint);
begin
  ChangeRect(Rect, -1);
  inherited;
  ChangeRect(Rect, 1);
end;

procedure TRSLabel.SetHIndent(v:int);
begin
  if v=FHIndent then exit;
  FHIndent:=v;
  AdjustBounds;
end;

procedure TRSLabel.SetVIndent(v:int);
begin
  if v=FVIndent then exit;
  FVIndent:=v;
  AdjustBounds;
end;

end.
