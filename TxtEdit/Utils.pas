unit Utils;

interface

uses
  SysUtils, Windows, Messages, Classes, Controls, Forms, Dialogs, StdCtrls,
  RSSysUtils, RSQ, RSRegistry;

type
  TFindOptions = Dialogs.TFindOptions;
  
  TRSFindReplaceHelper = record
    FIsAlphanum: array[Char] of Boolean;
    FCharMap: array[Char] of Char;
    FDirection: int;
    FWholeWord: Boolean;
    SearchStr: string;
    constructor Create(const ASearchStr: string; Options: TFindOptions = [frDown]);
    function Find(Buf: PChar; BufLen: int; SelStart: int = -1; SelLen: int = 0; Replace: Boolean = false; OtherEnd: Boolean = false): int; overload;
    function Find(s: string; SelStart: int = -1; SelLen: int = 0; Replace: Boolean = false; OtherEnd: Boolean = false): int; overload;
  end;

  TRSFileAssociationCmd = class(TObject)
  private
    FExtension: string;
    FCommandName: string;
    FCommand: string;
    function GetAssociated: Boolean;
    procedure SetAssociated(const Value: Boolean);
  public
    CommandCaption: string;
    constructor Create(const Extension, CommandName, Command, CommandCaption: string);

    property Associated: Boolean read GetAssociated write SetAssociated;
    property Extension: string read FExtension write FExtension;
    property CommandName: string read FCommandName write FCommandName;
    property Command: string read FCommand write FCommand;
  end;

implementation

uses Registry;

{ TRSFindReplaceHelper }

constructor TRSFindReplaceHelper.Create(const ASearchStr: string; Options: TFindOptions);
var
  c: Char;
begin
  FWholeWord:= frWholeWord in Options;
  for c := low(FIsAlphanum) to high(FIsAlphanum) do
    FIsAlphanum[c]:= IsCharAlphaNumeric(c);

  SearchStr:= ASearchStr;
  for c := low(FCharMap) to high(FCharMap) do
    FCharMap[c] := c;

  if not (frMatchCase in Options) then
  begin
    UniqueString(SearchStr);
    AnsiUpperBuff(@SearchStr[1], length(SearchStr));
    AnsiUpperBuff(PChar(@FCharMap), sizeof(FCharMap));
  end;

  if frDown in Options then
    FDirection:= 1
  else
    FDirection:= -1;
end;

function TRSFindReplaceHelper.Find(Buf: PChar; BufLen, SelStart, SelLen: int; Replace, OtherEnd: Boolean): int;
var
  p, BufHigh, BufLow: PChar;
  str: string;
  dir: int;

  function CheckWord: Boolean;
  var
    i: int;
  begin
    Result:= false;
    if FWholeWord then
    begin
      if (p > Buf) and (FIsAlphanum[(p - 1)^]) then  exit;
      if (p < BufHigh) and (FIsAlphanum[(p + length(str))^]) then  exit;
    end;

    for i:= 1 to length(str) do
      if FCharMap[(p + i - 1)^] <> str[i] then
        exit;
    Result:= true;
  end;

begin
  Result:= -1;
  if Buf = nil then
    exit;
    
  dir:= FDirection;
  str:= SearchStr;
  BufLow:= Buf;
  BufHigh:= Buf + BufLen - length(str);
  p:= Buf + SelStart;
  if Replace and (SelStart >= 0) and (SelLen = length(str)) and CheckWord then
  begin
    Result:= p - Buf;
    exit;
  end;

  if SelStart < 0 then
    if dir > 0 then
      p:= Buf
    else
      p:= BufHigh
  else
    if dir > 0 then
      inc(p, SelLen)
    else
      dec(p, length(str));

  // search reached the end continues from the beginning (or vice versa)
  if OtherEnd then
  begin
    if SelStart < 0 then  exit;
    if dir > 0 then
    begin
      BufHigh:= p - 1;
      p:= Buf;
    end else
    begin
      BufLow:= p + 1;
      p:= BufHigh;
    end;
  end;

  while (p >= BufLow) and (p <= BufHigh) do
  begin
    if CheckWord then
    begin
      Result:= p - Buf;
      if (Result = SelStart) and (length(str) = SelLen) then
        Result:= -1;
      exit;
    end;
    inc(p, dir);
  end;
end;

function TRSFindReplaceHelper.Find(s: string; SelStart, SelLen: int; Replace,
  OtherEnd: Boolean): int;
begin
  Result:= Find(ptr(s), length(s), SelStart, SelLen, Replace, OtherEnd);
end;

{ TRSFileAssociationCmd }

constructor TRSFileAssociationCmd.Create(const Extension, CommandName,
   Command, CommandCaption: string);
begin
  FExtension:= Extension;
  FCommandName:= CommandName;
  FCommand:= Command;
  self.CommandCaption:= CommandCaption;
end;

function TRSFileAssociationCmd.GetAssociated: Boolean;
var s:string;
begin
  with TRSRegistry.Create do
  try
    RootKey:= HKEY_CLASSES_ROOT;
    Result:= OpenKeyReadOnly('\' + Extension) and Read('', s) and
             OpenKeyReadOnly('\' + s + '\shell\' + CommandName) and
             Read('', s) and SameText(s, CommandCaption) and
             OpenKeyReadOnly('command') and
             Read('', s) and SameText(s, Command);
  finally
    Free;
  end;
end;

procedure TRSFileAssociationCmd.SetAssociated(const Value: Boolean);
var
  s:string;
begin
  with TRSRegistry.Create do
  try
    RootKey:=HKEY_CLASSES_ROOT;
    if not OpenKeyReadOnly('\' + Extension) or not Read('', s) then  exit;
    if (s = '') or not KeyExists('\' + s) then  exit;
    Access:= KEY_ALL_ACCESS;

    if Value then
    begin
      RSWin32Check(OpenKey('\' + s + '\shell\' + CommandName, true));

      SetLastError(RegSetValueEx(CurrentKey, nil, 0, REG_SZ, PChar(CommandCaption),
        length(CommandCaption) + 1));
      RSWin32Check(GetLastError = 0);

      WriteString('', CommandCaption);
      RSWin32Check(OpenKey('command', true));
      WriteString('', Command);
    end else
    begin
      DeleteKey('\' + s + '\shell\' + CommandName);
    end;
  finally
    Free;
  end;
end;

end.
