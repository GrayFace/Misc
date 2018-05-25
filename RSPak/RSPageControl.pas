unit RSPageControl;

{ *********************************************************************** }
{                                                                         }
{ RSPak                                    Copyright (c) Rozhenko Sergey  }
{ http://sites.google.com/site/sergroj/                                   }
{ sergroj@mail.ru                                                         }
{                                                                         }
{ See copyright notice at the end of RSSysUtils.pas file (MIT license).   }
{                                                                         }
{ *********************************************************************** )

 Now controls get WM_KILLFOCUS and WM_SETFOCUS messages when swiching
  between pages. This is another way to fix the bug described in
  RSComboBox unit.

{ *********************************************************************** }
{$I RSPak.inc}

interface

uses
  Forms, Windows, Messages, SysUtils, Classes, Controls, ComCtrls, RSCommon,
  RSQ;

{$I RSWinControlImport.inc}

type
  TRSPageControl = class(TPageControl)
  private
    FOnCreateParams: TRSCreateParamsEvent;
    FProps: TRSWinControlProps;
    FRuntimeTabIndex: Integer;
    function GetTab(Index: Integer): TTabSheet;
  protected
    procedure CreateParams(var Params:TCreateParams); override;
    procedure Loaded; override;
    procedure Change; override;

    procedure TranslateWndProc(var Msg:TMessage);
    procedure WndProc(var Msg:TMessage); override;
  public
    constructor Create(AOwner:TComponent); override;
     // Includes only visible sheets:
    property Tabs[Index: Integer]: TTabSheet read GetTab;
  published
    property RuntimeTabIndex: Integer read FRuntimeTabIndex write FRuntimeTabIndex default -1;
    property OnCanResize;
    property OnDblClick;
    property OnResize;
    {$I RSWinControlProps.inc}
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('RSPak', [TRSPageControl]);
end;

{
******************************** TRSPageControl ********************************
}

constructor TRSPageControl.Create(AOwner:TComponent);
begin
  inherited Create(AOwner);
  WindowProc:=TranslateWndProc;
  FRuntimeTabIndex:=-1;
end;

procedure TRSPageControl.CreateParams(var Params:TCreateParams);
begin
  inherited CreateParams(Params);
  if Assigned(FOnCreateParams) then FOnCreateParams(self, Params);
end;

function TRSPageControl.GetTab(Index: Integer): TTabSheet;
begin
  Result:= TTabSheet(inherited Tabs.Objects[Index]);
end;

procedure TRSPageControl.Loaded;
begin
  inherited Loaded;
  if not (csDesigning in ComponentState) and (FRuntimeTabIndex>=0) and
         (FRuntimeTabIndex<PageCount) then
    TabIndex:=FRuntimeTabIndex;
end;

procedure TRSPageControl.Change;
var
  Form: TCustomForm; h, h1:Hwnd;
begin
  inherited;

  Form:= GetParentForm(Self);
  h:= GetFocus;
  if Form.ActiveControl<>nil then
    h1:= Form.ActiveControl.Handle
  else
    h1:= 0;

   // This will update Form.ActiveControl and do other stuff
  if h1 <> h then
  begin
    SendMessage(h1, WM_KILLFOCUS, h, 0);
    SendMessage(h, WM_SETFOCUS, h1, 0);
  end;
end;

procedure TRSPageControl.TranslateWndProc(var Msg:TMessage);
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

procedure TRSPageControl.WndProc(var Msg:TMessage);
begin
  RSProcessProps(self, Msg, FProps);
  inherited;
end;

end.
