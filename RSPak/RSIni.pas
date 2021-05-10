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
  SysUtils, IniFiles, RSQ, TypInfo, RSStrUtils, RSSysUtils, Classes;

type
   // Logic: Get key or section name from each added string, convert to unique
   //  number via list of all names (FNameIndex). Quickly walk the array
   //  whenever in need of key or section line.
   // Full seamless control over ini is provided, through TStrings interface.
  TRSMemIniStrings = class(TStringList)
  protected
    FNameIndex: TStringList;  // <= -5 = section, 0 = comment, >= 5 = key
    procedure Changed; override;
    function DoGetKey(Line: int; var key: string): Boolean; 
    procedure LineChanged(Index: int);
    procedure Put(Index: Integer; const S: string); override;
    function GetObject(Index: Integer): TObject; override;
    procedure PutObject(Index: Integer; AObject: TObject); override;
    procedure InsertItem(Index: Integer; const S: string; AObject: TObject); override;
    function DoFind(Line, Val: int; StopAtSection: Boolean): int;
    procedure WalkBackComments(StartLine: int; var Index: Integer);
    function GetNameIndex(Line: int): int;
    function NeedName(const s: string): int;
  public
    Modified: Boolean;
    constructor Create;
    destructor Destroy; override;
    function FindSection(const Section: string): int;
    function FindNextSection(StartLine: int; DefaultToFileEnd: Boolean = false): int;
    // doesn't include trailing comments:
    function FindSectionEnd(StartLine: int): int;
    // follows the Find() logic, but Index is set to -1 if section doesn't exist:
    function FindKey(const Section, Name: string; var Index: Integer): Boolean; overload;
    function FindKey(StartLine: int; const Name: string; var Index: Integer): Boolean; overload;
    function IsComment(Line: int): Boolean;
    function IsSectionHeader(Line: int): Boolean;
    function GetKey(Line: int): string;
    function GetValue(Line: int): string;
    procedure ReadSections(List: TStrings);
    procedure ReadSection(const Section: string; List: TStrings; Values: Boolean);
    class function EscapeValue(const s: string): string;
  end;

  TRSMemIni = class(TCustomIniFile)
  protected
    FLines: TRSMemIniStrings;
  public
    constructor Create(const FileName: string);
    destructor Destroy; override;
    function ReadString(const Section, Ident, Default: string): string; override;
    procedure WriteString(const Section, Ident, Value: string); override;
    // Handles strings with spaces and quotation marks:
    procedure WriteStringSafe(const Section, Ident, Value: string);
    procedure DeleteKey(const Section, Ident: string); override;
    function HasKey(const Section, Ident: string): Boolean;
    procedure EraseSection(const Section: string); override;
    procedure ReadSection(const Section: string; Strings: TStrings); override;
    procedure ReadSectionValues(const Section: string; Strings: TStrings); override;
    procedure ReadSections(Strings: TStrings); override;
    procedure UpdateFile; override;
    procedure Flush;
    procedure Reload;
    property Lines: TRSMemIniStrings read FLines;
  end;

{$IFNDEF MSWINDOWS}
  // Instead of horrible TMemIniFile
  TIniFile = class(TRSMemIni)
  end;
{$ENDIF}

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

const
  MinIdx = 10;

{ TRSMemIniStrings }

function TRSMemIniStrings.FindKey(const Section, Name: string;
  var Index: Integer): Boolean;
begin
  Index:= FindSection(Section);
  Result:= false;
  if Index >= 0 then
    Result:= FindKey(Index + 1, Name, Index);
end;

procedure TRSMemIniStrings.Changed;
begin
  Modified:= true;
  inherited;
end;

constructor TRSMemIniStrings.Create;
begin
  CaseSensitive:= true;
  FNameIndex:= TStringList.Create;
  FNameIndex.CaseSensitive:= false;
  FNameIndex.Duplicates:= dupIgnore;
  FNameIndex.Sorted:= true;
end;

destructor TRSMemIniStrings.Destroy;
begin
  FNameIndex.Free;
  inherited;
end;

function TRSMemIniStrings.DoFind(Line, Val: int; StopAtSection: Boolean): int;
var
  v: int;
begin
  for Result:= Line to Count - 1 do
  begin
    v:= int(inherited GetObject(Result));
    if (v = Val) or StopAtSection and (v <= -MinIdx) then
      exit;
  end;
  Result:= -1;
end;

function TRSMemIniStrings.DoGetKey(Line: int; var key: string): Boolean;
var
  s: string;
  i, j, L: int;
begin
  Result:= false;
  s:= Strings[Line];
  L:= length(s);
  i:= 1;
  while (i <= L) and (s[i] <= ' ') do  // trim start
    inc(i);
  if (i > L) or (s[i] = ';') then  // comment
    exit;
  if s[i] = '[' then  // section
  begin
    j:= RSPos(']', s, i);
    if j > 0 then  // closing bracket isn't required
      L:= j - 1;
  end else
    L:= RSPos('=', s, i) - 1;  // key
  Result:= (L >= 0);
  while (L > 0) and (s[L] <= ' ') do  // trim end
    dec(L);
  key:= Copy(s, i, L - i + 1);
end;

class function TRSMemIniStrings.EscapeValue(const s: string): string;
var
  c, c1: char;
begin
  Result:= s;
  if s = '' then  exit;
  c:= s[1];
  c1:= s[length(s)];
  if (c <= ' ') or (c1 <= ' ') or (c in ['"', '''']) and (c1 = c) then
    Result:= '"' + s + '"';
end;

function TRSMemIniStrings.FindKey(StartLine: int; const Name: string;
  var Index: Integer): Boolean;
var
  v: int;
begin
  if FNameIndex.Find(Name, v) then
    v:= int(FNameIndex.Objects[v])
  else
    v:= -1;
  Index:= DoFind(StartLine, v, true);
  Result:= (Index >= 0) and (GetNameIndex(Index) = v);
  if not Result then  // insertion point before last comment of the section
    WalkBackComments(StartLine, Index);
end;

function TRSMemIniStrings.FindNextSection(StartLine: int; DefaultToFileEnd: Boolean): int;
begin
  Result:= DoFind(StartLine, -1, true);
  if (Result < 0) and DefaultToFileEnd then
    Result:= Count;
end;

function TRSMemIniStrings.FindSectionEnd(StartLine: int): int;
begin
  Result:= DoFind(StartLine, -1, true);
  WalkBackComments(StartLine, Result);
end;

function TRSMemIniStrings.FindSection(const Section: string): int;
begin
  if FNameIndex.Find('[' + Section, Result) then
    Result:= DoFind(0, int(FNameIndex.Objects[Result]), false)
  else
    Result:= -1;
end;

function TRSMemIniStrings.GetKey(Line: int): string;
begin
  if not DoGetKey(Line, Result) then
    Result:= ''
  else if Result[1] = '[' then
    Result:= Copy(Result, 2, MaxInt);
end;

function TRSMemIniStrings.GetNameIndex(Line: int): int;
begin
  Result:= int(inherited GetObject(Line));
end;

function TRSMemIniStrings.GetObject(Index: Integer): TObject;
begin
  Result:= nil;
end;

function TRSMemIniStrings.GetValue(Line: int): string;
var
  c: char;
begin
  Result:= Strings[Line];
  Result:= Trim(Copy(Result, Pos('=', Result) + 1, MaxInt));
  if Result = '' then  exit;
  c:= Result[1];
  if (c in ['"', '''']) and (Result[length(Result)] = c) then
    Result:= Copy(Result, 2, length(Result) - 2);
end;

procedure TRSMemIniStrings.InsertItem(Index: Integer; const S: string;
  AObject: TObject);
begin
  if AObject <> nil then
    Error(@sRSObjectsNotSupported, 0);
  Changing;
  BeginUpdate;
  inherited;
  LineChanged(Index);
  EndUpdate;
  Changed;
end;

function TRSMemIniStrings.IsComment(Line: int): Boolean;
begin
  Result:= inherited GetObject(Line) = nil;
end;

function TRSMemIniStrings.IsSectionHeader(Line: int): Boolean;
begin
  Result:= GetNameIndex(Line) <= -MinIdx;
end;

function TRSMemIniStrings.NeedName(const s: string): int;
begin
  Result:= FNameIndex.Count + MinIdx;
  if (s <> '') and (s[1] = '[') then
    Result:= -Result;
  Result:= FNameIndex.AddObject(s, ptr(Result));
  Result:= int(FNameIndex.Objects[Result]);
end;

procedure TRSMemIniStrings.LineChanged(Index: int);
var
  s: string;
  v: int;
begin
  v:= 0;
  if DoGetKey(Index, s) then
    v:= NeedName(s);
  inherited PutObject(Index, ptr(v));
end;

procedure TRSMemIniStrings.Put(Index: Integer; const S: string);
begin
  Changing;
  BeginUpdate;
  inherited;
  LineChanged(Index);
  EndUpdate;
  Changed;
end;

procedure TRSMemIniStrings.PutObject(Index: Integer; AObject: TObject);
begin
  if AObject <> nil then
    Error(@sRSObjectsNotSupported, 0);
end;

procedure TRSMemIniStrings.ReadSection(const Section: string; List: TStrings;
  Values: Boolean);
var
  have: array of Boolean;
  i, v: int;
begin
  List.BeginUpdate;
  try
    List.Clear;
    i:= FindSection(Section) + 1;
    if i <= 0 then  exit;
    SetLength(have, FNameIndex.Count);
    for i := i to FindNextSection(i, true) - 1 do
      if not IsComment(i) then
      begin
        v:= GetNameIndex(i) - MinIdx;
        if have[v] then  continue;
        have[v]:= true;
        if Values then
          List.Add(GetKey(i) + '=' + GetValue(i))
        else
          List.Add(GetKey(i));
      end;
  finally
    List.EndUpdate;
  end;
end;

procedure TRSMemIniStrings.ReadSections(List: TStrings);
var
  have: array of Boolean;
  i, v: int;
begin
  SetLength(have, FNameIndex.Count);
  List.BeginUpdate;
  try
    List.Clear;
    i:= FindNextSection(0);
    while i <> -1 do
    begin
      v:= -MinIdx - GetNameIndex(i);
      if not have[v] then
        List.Add(GetKey(i));
      have[v]:= true;
      i:= FindNextSection(i + 1);
    end;
  finally
    List.EndUpdate;
  end;
end;

procedure TRSMemIniStrings.WalkBackComments(StartLine: int; var Index: Integer);
begin
  if Index < 0 then
    Index:= Count;
  while (Index > StartLine) and IsComment(Index - 1) do
    dec(Index);
end;

{ TRSMemIni }

constructor TRSMemIni.Create(const FileName: string);
begin
  inherited Create(FileName);
  FLines:= TRSMemIniStrings.Create;
  Reload;
end;

procedure TRSMemIni.DeleteKey(const Section, Ident: string);
var
  i: int;
begin
  if FLines.FindKey(Section, Ident, i) then
    FLines.Delete(i);
end;

destructor TRSMemIni.Destroy;
begin
  Flush;
  FLines.Free;
  inherited;
end;

procedure TRSMemIni.EraseSection(const Section: string);
var
  i, j: int;
begin
  i:= FLines.FindSection(Section);
  if i >= 0 then
    for j:= FLines.FindSectionEnd(i + 1) - 1 downto i do
      FLines.Delete(j);
end;

procedure TRSMemIni.Flush;
begin
  if FLines.Modified then
    UpdateFile;
end;

function TRSMemIni.HasKey(const Section, Ident: string): Boolean;
var
  i: int;
begin
  Result:= FLines.FindKey(Section, Ident, i);
end;

procedure TRSMemIni.ReadSection(const Section: string; Strings: TStrings);
begin
  FLines.ReadSection(Section, Strings, false);
end;

procedure TRSMemIni.ReadSections(Strings: TStrings);
begin
  FLines.ReadSections(Strings);
end;

procedure TRSMemIni.ReadSectionValues(const Section: string; Strings: TStrings);
begin
  FLines.ReadSection(Section, Strings, true);
end;

function TRSMemIni.ReadString(const Section, Ident, Default: string): string;
var
  i: int;
begin
  if FLines.FindKey(Section, Ident, i) then
    Result:= FLines.GetValue(i)
  else
    Result:= Default;
end;

procedure TRSMemIni.Reload;
begin
  if FileExists(FileName) then
    FLines.LoadFromFile(FileName)
  else
    FLines.Clear;
  FLines.Modified:= false;
end;

procedure TRSMemIni.UpdateFile;
begin
  FLines.SaveToFile(FileName);
  FLines.Modified:= false;
end;

procedure TRSMemIni.WriteString(const Section, Ident, Value: string);
var
  s: string;
  i: int;
begin
  if FLines.FindKey(Section, Ident, i) then
  begin
    s:= FLines[i];
    SetLength(s, Pos('=', s));
    FLines[i]:= s + Value;
    exit;
  end;
  if i < 0 then
  begin
    if (FLines.Count > 0) and (FLines[FLines.Count - 1] <> '') then
      FLines.Add('');
    i:= FLines.Add('[' + Section + ']') + 1;
  end;
  FLines.Insert(i, Ident + '=' + Value);
end;

procedure TRSMemIni.WriteStringSafe(const Section, Ident, Value: string);
begin
  WriteString(Section, Ident, FLines.EscapeValue(Value));
end;

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
        ini.WriteString(Section, Ident, TRSMemIniStrings.EscapeValue(Default));
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
    ini.WriteString(Section, Ident, TRSMemIniStrings.EscapeValue(Value));
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
                  WriteString(Section, OptionName, TRSMemIniStrings.EscapeValue(GetStrProp(obj, pname)));
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
            WriteString(Section, OptionName, TRSMemIniStrings.EscapeValue(PStr(OptionPtr)^));
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
