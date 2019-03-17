unit RSPopupMenu;

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
  Windows, Messages, Classes, Menus;

type
  TRSAllowShortCutEvent = procedure(Sender: TMenu; var Message: TWMKey; var Allow: Boolean) of object;

  TRSPopupMenu = class(TPopupMenu)
  private
    FOnAfterPopup: TNotifyEvent;
    FOnIgnoreShortCut: TRSAllowShortCutEvent;
  protected
    FOwnItems: TMenuItem;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetItems(v: TMenuItem); virtual;
    procedure Popup(X, Y: Integer); override;
    function IsShortCut(var Message: TWMKey): Boolean; override;
  published
    property OnAfterPopup: TNotifyEvent read FOnAfterPopup write FOnAfterPopup;
    property OnAllowShortCut: TRSAllowShortCutEvent read FOnIgnoreShortCut write FOnIgnoreShortCut;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('RSPak', [TRSPopupMenu]);
end;

{
********************************** TRSPopupMenu ***********************************
}

constructor TRSPopupMenu.Create(AOwner: TComponent);
begin
  inherited;
  FOwnItems:=Items;
end;

destructor TRSPopupMenu.Destroy;
begin
  SetItems(nil);
  inherited;
end;

function TRSPopupMenu.IsShortCut(var Message: TWMKey): Boolean;
begin
  if Assigned(OnAllowShortCut) then
  begin
    Result:= true;
    OnAllowShortCut(self, Message, Result);
    if not Result then
      exit
  end;
  Result:= inherited IsShortCut(Message);
end;

procedure TRSPopupMenu.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if (Operation=opRemove) and (AComponent=Items) then
    TMenuItem((@Items)^):=FOwnItems;
end;

procedure TRSPopupMenu.Popup(X, Y: Integer);
begin
  inherited;
  if Assigned(FOnAfterPopup) then  FOnAfterPopup(self);
end;

procedure TRSPopupMenu.SetItems(v: TMenuItem);
begin
  if v=Items then exit;

  if Items<>FOwnItems then
    Items.RemoveFreeNotification(self);

  if (v<>nil) and (v<>FOwnItems) then
  begin
    TMenuItem((@Items)^):=v;
    v.FreeNotification(self);

    // Можно еще менять свойства менюшки на те, что в Items...

  end else
    TMenuItem((@Items)^):=FOwnItems;
end;

end.
