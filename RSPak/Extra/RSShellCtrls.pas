unit RSShellCtrls;

{ *********************************************************************** }
{                                                                         }
{ RSPak                                    Copyright (c) Rozhenko Sergey  }
{ http://sites.google.com/site/sergroj/                                   }
{ sergroj@mail.ru                                                         }
{                                                                         }
{ See copyright notice at the end of RSSysUtils.pas file (MIT license).   }
{                                                                         }
{ *********************************************************************** }

interface

uses
  Forms, Windows, Messages, SysUtils, Classes, RSShellBrowse, RSQ, ComObj,
  ShlObj, ShellAPI;

type
   // A class with common functions for shell controls
  TRSShellBrowser = class
  public
    ShellFolderClass: TRSShellFolderClass;
    constructor Create;
    class procedure ShowException(e: Exception);
    function Browse(Root:TRSShellFolder; const Path:string):TRSShellFolder; overload;
    function Browse(Root:TRSShellFolder; SpecialFolderCSIDL:int):TRSShellFolder; overload;
    function Browse(Root:TRSShellFolder; ShellFile: TRSShellFile):TRSShellFolder; overload;
  end;

implementation

{ TRSShellBrowser }

constructor TRSShellBrowser.Create;
begin
  ShellFolderClass:= TRSShellFolder;
end;

function TRSShellBrowser.Browse(Root: TRSShellFolder;
  const Path: string): TRSShellFolder;
var s:string;
begin
  if Root<>nil then
  begin
    s:=Root.FullName([RSForParsing, RSForAddressBar]);
    if SameText(Path, s) or
       (Path<>'') and (Path[length(Path)] in ['\', '/']) and
       SameText(Path, s + Path[length(Path)]) then
    begin
      Result:= Root;
      exit;
    end;
  end;

  try
    Result:= ShellFolderClass.Create(Path, Application.Handle);
  except
    on e:EOleSysError do
    begin
      ShowException(e);
      Result:= nil;
    end;
  end;
end;

function TRSShellBrowser.Browse(Root: TRSShellFolder;
  SpecialFolderCSIDL: int): TRSShellFolder;
begin
  try
    Result:= ShellFolderClass.Create(SpecialFolderCSIDL, Application.Handle);
  except
    on e:EOleSysError do
    begin
      ShowException(e);
      Result:=nil;
    end;
  end;
end;

function TRSShellBrowser.Browse(Root: TRSShellFolder;
  ShellFile: TRSShellFile): TRSShellFolder;
begin
  if ShellFile<>Root then
    try
      Result:= ShellFolderClass.Create(ShellFile);
    except
      on e:EOleSysError do
      begin
        ShowException(e);
        Result:=nil;
      end;
    end
  else
    Result:= Root;
end;

class procedure TRSShellBrowser.ShowException(e: Exception);
var Msg:string;
begin
  Msg := e.Message;
  if (Msg <> '') and (AnsiLastChar(Msg) > '.') then  Msg := Msg + '.';
  Application.MessageBox(PChar(Msg), PChar(Application.Title),
     MB_ICONINFORMATION);
end;

end.
