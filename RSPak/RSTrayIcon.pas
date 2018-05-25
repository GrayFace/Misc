unit RSTrayIcon;

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
  Windows, Messages, SysUtils, Classes, ShellAPI, ExtCtrls, RSQ;

type
  TRSTrayIcon = class(TTrayIcon)
  private
    FOnBalloonClick: TNotifyEvent;
  protected
    procedure WindowProc(var Message: TMessage); override;
  published
    property OnBalloonClick: TNotifyEvent read FOnBalloonClick write FOnBalloonClick;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('RSPak', [TRSTrayIcon]);
end;

{ TRSTrayIcon }

procedure TRSTrayIcon.WindowProc(var Message: TMessage);
begin
  inherited;
  if (Message.Msg = WM_SYSTEM_TRAY_MESSAGE) and (Message.lParam = NIN_BALLOONUSERCLICK) then
    if Assigned(OnBalloonClick) then
      OnBalloonClick(self);
end;

end.
