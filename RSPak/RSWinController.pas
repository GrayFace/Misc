unit RSWinController;

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

uses Windows, Messages, RSCommon, RSWindowProc, Classes, Controls, RSQ;

type
  TRSWndProcEvent = RSCommon.TRSWndProcEvent;

  TRSCustomWinController = class(TComponent)
  private
    FControl: TControl;
    FActive: boolean;
    FOnWndProc: TRSWndProcEvent;
    FPriority: integer;
    FHookObj: ptr;
    FNextWndProc:TWndMethod;
    procedure SetControl(v:TControl);
    procedure SetActive(v:boolean);
    procedure SetPriority(v:integer);
    procedure WndProcHook(Sender:TObject; var Msg:TMessage;
      const NextWndProc:TWndMethod);
  protected
    IsActive: boolean;
    procedure BoolActive(v:boolean);
    function CanActivate:boolean; virtual;
    procedure Activate;
    procedure Deactivate;
    procedure OnDeactivate; virtual;
    procedure WndProc(var Msg:TMessage); virtual;

    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;

    property OnWndProc: TRSWndProcEvent read FOnWndProc write FOnWndProc;
    property Control: TControl read FControl write SetControl;
    property Active: boolean read FActive write SetActive;
    property Priority: integer read FPriority write SetPriority;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published

  end;

  TRSWinController = class(TRSCustomWinController)
  published
    property OnWndProc;
    property Control;
    property Active default true;
    property Priority;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('RSPak', [TRSWinController]);
end;

constructor TRSCustomWinController.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FControl:=nil;
  FActive:=true;
  IsActive:=false;
  FPriority:=200;
end;

destructor TRSCustomWinController.Destroy;
begin
  Deactivate;
  inherited Destroy;
end;

procedure TRSCustomWinController.WndProc(var Msg:TMessage);
begin
  FNextWndProc(Msg);
end;

procedure TRSCustomWinController.WndProcHook(Sender:TObject; var Msg:TMessage;
  const NextWndProc:TWndMethod);
var b:boolean;
begin
  FNextWndProc:=NextWndProc;
  if assigned(FOnWndProc) then
  begin
    b:=false;
    FOnWndProc(Self, Msg, b, WndProc);
    if b then exit;
  end;
  WndProc(Msg);
end;

function TRSCustomWinController.CanActivate:boolean;
begin
  Result:=FActive and (FControl<>nil) and
                              not (csDesigning in ComponentState);
end;

procedure TRSCustomWinController.BoolActive(v:boolean);
begin
  if v then Activate
  else Deactivate;
end;

procedure TRSCustomWinController.Activate;
begin
  if IsActive or not CanActivate then exit;
  IsActive:=true;
  FHookObj:=RSHookWindowProc(FControl, WndProcHook, FPriority);
end;

procedure TRSCustomWinController.Deactivate;
begin
  if not IsActive or (FControl=nil) then exit;
  IsActive:=false;
  RSUnhookWindowProc(FHookObj);
  //FHookObj:=nil;
  OnDeactivate;
end;

procedure TRSCustomWinController.OnDeactivate;
begin
end;

procedure TRSCustomWinController.SetControl(v:TControl);
begin
  if FControl=v then exit;
  if FControl<>nil then
  begin
    FControl.RemoveFreeNotification(self);
    Deactivate;
  end;
  
  FControl:=v;
  if v<>nil then
  begin
    v.FreeNotification(self);
    Activate;
  end;  
end;

procedure TRSCustomWinController.SetActive(v:boolean);
begin
  if v=FActive then exit;
  FActive:=v;
  BoolActive(v);
end;

procedure TRSCustomWinController.SetPriority(v:integer);
begin
  if FPriority=v then exit;
  FPriority:=v;
  if IsActive then
  begin
    Deactivate;
    Activate;
  end;
end;

procedure TRSCustomWinController.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if (AComponent=Control) and (Operation=opRemove) then
  begin
    Deactivate;
    FControl:=nil;
  end;
end;

end.
