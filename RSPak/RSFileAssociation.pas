unit RSFileAssociation;

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
  SysUtils, Windows, RSRegistry, RSQ, RSSysUtils;

type
  TRSFileAssociation = class(TObject)
  private
    FAssociationName: string;
    FBackupName: string;
    FExtension: string;
    FCommand: string;
    FDefaultIcon: string;
    function GetAssociated: Boolean;
    procedure SetAssociated(const Value: Boolean);
  public
    constructor Create(const Extension, AssociationName, BackupName,
      Command, DefaultIcon: string);

    property Associated: Boolean read GetAssociated write SetAssociated;
    property AssociationName: string read FAssociationName write FAssociationName;
    property BackupName: string read FBackupName write FBackupName;
    property Extension: string read FExtension write FExtension;
    property Command: string read FCommand write FCommand;
    property DefaultIcon: string read FDefaultIcon write FDefaultIcon;
  end;

implementation

uses Registry;

{ TRSFileAssociation }

constructor TRSFileAssociation.Create(const Extension, AssociationName,
   BackupName, Command, DefaultIcon: string);
begin
  FExtension:= Extension;
  FAssociationName:= AssociationName;
  FBackupName:= BackupName;
  FCommand:= Command;
  FDefaultIcon:= DefaultIcon;
end;

function TRSFileAssociation.GetAssociated: Boolean;
var s:string;
begin
  with TRSRegistry.Create do
  try
    RootKey:= HKEY_CLASSES_ROOT;
    Result:= OpenKeyReadOnly('\' + Extension) and Read('', s) and
             (s = AssociationName) and
             OpenKeyReadOnly('\' + AssociationName + '\shell\open\command') and
             Read('', s) and SameText(s, Command);
  finally
    Free;
  end;
end;

procedure TRSFileAssociation.SetAssociated(const Value: Boolean);
var
  s:string; Info:TRegKeyInfo;
begin
  with TRSRegistry.Create do
  try
    RootKey:=HKEY_CLASSES_ROOT;

    if Value then
    begin
      RSWin32Check(OpenKey('\' + AssociationName + '\DefaultIcon', true));
      WriteString('', DefaultIcon);
      RSWin32Check(OpenKey('\' + AssociationName + '\shell\open\command', true));
      WriteString('', Command);

      RSWin32Check(OpenKey('\' + Extension, true));
      if not Read('', s) then
        DeleteValue(BackupName)
      else
        if s<>AssociationName then
          WriteString(BackupName, s);

      WriteString('', AssociationName);
    end else
    begin
      if not OpenKey('\' + Extension, false) then  exit;
      s:= ReadString('');
      if s = AssociationName then
      begin
        if Read(BackupName, s) then
          WriteString('', s)
        else
          DeleteValue('');
          
        DeleteValue(BackupName);
        if GetKeyInfo(Info) and (Info.NumSubKeys or Info.NumValues = 0) then
        begin
          CloseKey;
          DeleteKey('\' + Extension);
        end;

        DeleteKey('\' + AssociationName);
      end;
    end;
  finally
    Free;
  end;
end;

end.
