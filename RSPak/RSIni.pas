unit RSIni;

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
  SysUtils, IniFiles, RSQ, TypInfo, RSStrUtils, Classes;

type
  PRSIniOptionsOption = ^TRSIniOptionsOption;
  TRSIniOptionsOption = record
    Section: string;
    OptionName: string;
    DefStr: string;
    Def: int;
    Form: TObject;
    OptionPtr: ptr;
    Kind: TTypeKind;
  end;

  TRSIniOptions = class
  protected
    FOptions: array of TRSIniOptionsOption;
    function AddOption(const Name: string): int;
    function ParseOption(const Option: TRSIniOptionsOption; out obj: TObject; out name: string): PTypeInfo;
  public
    FileName: string;
    CurrentSection: string;
    CurrentForm: TObject;
    constructor Create(const fname: string; section: string = 'Options'; form: TObject = nil);
    procedure Add(const Name, FormOption: string); overload;
    procedure Add(const Name: string; var Option: string; Default: string); overload;
    procedure Add(const Name: string; var Option: int; Default: int); overload;
    procedure Add(const Name: string; var Option: Boolean; Default: Boolean); overload;
    procedure Read(EnsureExist: Boolean = false);
    procedure Write(WhenDifferent: Boolean = true);
    procedure Clear;
  end;

implementation

{ TRSIniOptions }

procedure TRSIniOptions.Add(const Name, FormOption: string);
begin
  FOptions[AddOption(Name)].DefStr:= FormOption;
end;

procedure TRSIniOptions.Add(const Name: string; var Option: string;
  Default: string);
begin
  with FOptions[AddOption(Name)] do
  begin
    OptionPtr:= @Option;
    Kind:= tkLString;
    DefStr:= Default;
  end;
end;

procedure TRSIniOptions.Add(const Name: string; var Option: int; Default: int);
begin
  with FOptions[AddOption(Name)] do
  begin
    OptionPtr:= @Option;
    Kind:= tkInteger;
    Def:= Default;
  end;
end;

procedure TRSIniOptions.Add(const Name: string; var Option: Boolean;
  Default: Boolean);
begin
  with FOptions[AddOption(Name)] do
  begin
    OptionPtr:= @Option;
    Kind:= tkEnumeration;
    Def:= ord(Default);
  end;
end;

function TRSIniOptions.AddOption(const Name: string): int;
begin
  Result:= length(FOptions);
  SetLength(FOptions, Result + 1);
  with FOptions[Result] do
  begin
    Section:= CurrentSection;
    OptionName:= Name;
    Form:= CurrentForm;
  end;
end;

procedure TRSIniOptions.Clear;
begin
  FOptions:= nil;
end;

constructor TRSIniOptions.Create(const fname: string; section: string; form: TObject);
begin
  FileName:= fname;
  CurrentSection:= section;
  CurrentForm:= form;
end;

function TRSIniOptions.ParseOption(const Option: TRSIniOptionsOption; out obj: TObject;
  out name: string): PTypeInfo;
var
  info: PPropInfo;
  ps: TRSParsedString;
  i: int;
begin
  ps:= RSParseString(Option.DefStr, ['.']);
  obj:= Option.Form;
  name:= '';
  Result:= nil;
  for i := 0 to RSGetTokensCount(ps) - 1 do
  begin
    if Result <> nil then
    begin
      Assert(Result.Kind = tkClass);
      obj:= GetObjectProp(obj, name);
    end;
    Assert(obj <> nil);
    name:= RSGetToken(ps, i);
    info:= GetPropInfo(obj, name);
    if info <> nil then
      Result:= info.PropType^
    else
      Result:= nil;
    if Result = nil then
      obj:= (obj as TComponent).FindComponent(name);
  end;
end;

procedure TRSIniOptions.Read(EnsureExist: Boolean);
var
  ini: TIniFile;

  function ReadString(const Section, Ident, Default: string): string;
  begin
    if EnsureExist then
    begin
      Result:= ini.ReadString(Section, Ident, #13#10);
      if Result = #13#10 then
      begin
        ini.WriteString(Section, Ident, Default);
        Result:= Default;
      end;
    end else
      Result:= ini.ReadString(Section, Ident, Default);
  end;

  function ReadInteger(const Section, Ident: string; Default: Longint): Longint;
  begin
    if EnsureExist then
      ReadString(Section, Ident, IntToStr(Default));
    Result:= ini.ReadInteger(Section, Ident, Default);
  end;

var
  obj: TObject;
  pname: string;
  i: int;
begin
  ini:= TIniFile.Create(FileName);
  try
    for i := 0 to high(FOptions) do
      with FOptions[i] do
        case Kind of
          tkUnknown:
            with ParseOption(FOptions[i], obj, pname)^ do
              case Kind of
                tkString, tkLString:
                  SetStrProp(obj, pname,
                    ReadString(Section, OptionName, GetStrProp(obj, pname)));
                tkInteger:
                  SetOrdProp(obj, pname,
                    ReadInteger(Section, OptionName, GetOrdProp(obj, pname)));
                tkEnumeration:
                  if Name = 'Boolean' then
                    SetOrdProp(obj, pname,
                      ord(ReadInteger(Section, OptionName, GetOrdProp(obj, pname)) <> 0))
                  else
                    Assert(false);
                else
                  Assert(false);
              end;
          tkLString:
            PStr(OptionPtr)^:= ReadString(Section, OptionName, DefStr);
          tkInteger:
            pint(OptionPtr)^:= ReadInteger(Section, OptionName, Def);
          tkEnumeration:
            PBoolean(OptionPtr)^:= ReadInteger(Section, OptionName, Def) <> 0;
          else
            Assert(false);
        end;
  finally
    ini.Free;
  end;
end;

procedure TRSIniOptions.Write(WhenDifferent: Boolean = true);
var
  ini: TIniFile;

  procedure WriteString(const Section, Ident, Value: string);
  begin
    if WhenDifferent and (ini.ReadString(Section, Ident, '_' + Value) = Value) then
      exit;
    ini.WriteString(Section, Ident, Value);
  end;

  procedure WriteInteger(const Section, Ident: string; Value: Longint);
  begin
    WriteString(Section, Ident, IntToStr(Value));
  end;

  procedure WriteBool(const Section, Ident: string; Value: Boolean);
  begin
    WriteString(Section, Ident, BoolStr[Value]);
  end;

var
  obj: TObject;
  pname: string;
  i: int;
begin
  ini:= TIniFile.Create(FileName);
  try
    for i := 0 to high(FOptions) do
      with FOptions[i] do
        case Kind of
          tkUnknown:
            with ParseOption(FOptions[i], obj, pname)^ do
              case Kind of
                tkString, tkLString:
                  WriteString(Section, OptionName, GetStrProp(obj, pname));
                tkInteger:
                  WriteInteger(Section, OptionName, GetOrdProp(obj, pname));
                tkEnumeration:
                  if Name = 'Boolean' then
                    WriteInteger(Section, OptionName, GetOrdProp(obj, pname))
                  else
                    Assert(false);
                else
                  Assert(false);
              end;
          tkLString:
            WriteString(Section, OptionName, PStr(OptionPtr)^);
          tkInteger:
            WriteInteger(Section, OptionName, pint(OptionPtr)^);
          tkEnumeration:
            WriteBool(Section, OptionName, PBoolean(OptionPtr)^);
          else
            Assert(false);
        end;
  finally
    ini.Free;
  end;
end;

end.
