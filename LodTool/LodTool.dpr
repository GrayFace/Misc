program LodTool;

uses
  Windows, Messages, SysUtils, RSLod, Graphics, Classes, RSSysUtils, RSQ,
  RSStrUtils, dzlib, RSGraphics, RSSimpleExpr, SysConst;

// note: not using try..finally, because any error leads to program closing
//{$R *.res}
{$R LodTool1.res} // don't include icon

var
  Lod: TRSMMArchive;
  List: TStringList;
  Data: TRSByteArray;
  StoredLods, StoredLists: TStringList;
  BaseDir: string;
  ErrorFile: string;
  ErrorLine: int;

procedure DoExecCommands(const str, fname: string); forward;

function SortedList(CaseSens: Boolean): TStringList;
begin
  Result:= TStringList.Create;
  Result.CaseSensitive:= CaseSens;
  Result.Duplicates:= dupIgnore;
  Result.Sorted:= true;
end;

procedure MyParseExpr(const s: string; var a: TRSOperatorArray; Custom: TRSCustomOpEvent = nil; AcceptEmpty: Boolean = false);
begin
  if RSParseExpr(s, a, Custom, AcceptEmpty) <> 0 then
    raise Exception.Create('Expression syntax error');
end;

function ExprToInt(const expr: string): int;
var
  a: TRSOperatorArray;
begin
  MyParseExpr(expr, a);
  Result:= Round(RSCalcExpr(a));
end;

//-- TCallbacks

var
  ResX, ResY: ext;

type
  TCallbacks = class
    class function ChangePalIndex(const Name: string; data: ptr): ext;
    class procedure FindDimentions(Sender: TRSLwd; Name: PChar;
       var Width, Height: int2; RealWidth, RealHeight: int);
  end;

class function TCallbacks.ChangePalIndex(const name: string; data: ptr): ext;
begin
  if Name = 'pal' then
    Result:= int(data)
  else
    Result:= 0;
end;

class procedure TCallbacks.FindDimentions(Sender: TRSLwd; Name: PChar;
  var Width, Height: int2; RealWidth, RealHeight: int);
begin
  if ResX <> 0 then
    Width:= Round(RealWidth/ResX);
  if ResY <> 0 then
    Height:= Round(RealHeight/ResY);
end;

//-- Params

var
  ParamsShift: int;
  ParamsList: TStringList;
  IncludeFmt: TRSKeyValueStringList;
  CmdList: TStringList;

function Param(i: int): string;
begin
  inc(i, ParamsShift);
  if i < ParamsList.Count then
    Result:= ParamsList[i]
  else
    Result:= ParamStr(i + 1);
end;

procedure LoadParams(const name: string);
begin
  ParamsList.LoadFromFile(name);
end;

procedure ShiftParams(i: int);
begin
  inc(ParamsShift, i);
end;

procedure IncludeParam(const name, val: string);
begin
  IncludeFmt.Add(name, val);
end;

procedure ReplaceParam(const name, val: string);
begin
  CmdList.Text:= RSStringReplace(CmdList.Text, '<' + name + '>', val, [rfReplaceAll, rfIgnoreCase]);
end;

procedure ReplaceCopy(const name, val: string; i, j: int);
begin
  if i < 0 then
    i:= length(val) + i + 1;
  if j < 0 then
    j:= length(val) + j + 1;
  ReplaceParam(name, Copy(val, i, j - i + 1));
end;

procedure Calc(const name: string; expr: int; fmt: string);
begin
  if fmt = '' then
    fmt:= '%d';
  ReplaceParam(name, Format(fmt, [expr]));
end;

//-- List

procedure AddPattern(const pat: string);
var
  i: int;
begin
  for i := 0 to Lod.Count - 1 do
    if RSWildcardMatch(pat, Lod.Names[i]) then
      List.Add(Lod.Names[i]);
end;

procedure RemovePattern(const pat: string);
var
  i: int;
begin
  for i := List.Count - 1 downto 0 do
    if RSWildcardMatch(pat, List[i]) then
      List.Delete(i);
end;

procedure SetPattern(const pat: string);
begin
  List.Clear;
  AddPattern(pat);
end;

procedure SaveList(const name: string);
begin
  List.SaveToFile(name);
end;

procedure LoadList(const name: string);
begin
  List.LoadFromFile(name);
end;

procedure StoreList(const s: string);
var
  i: int;
begin
  i:= StoredLists.Add(s);
  StoredLists.Objects[i].Free;
  StoredLists.Objects[i]:= List;
  List:= SortedList(false);
end;

procedure RestoreList(const s: string);
var
  i: int;
begin
  if StoredLists.Find(s, i) then
  begin
    FreeAndNil(List);
    List:= ptr(StoredLists.Objects[i]);
    StoredLists.Delete(i);
  end else
    List.Clear;
end;

procedure ListAdd(const s: string);
var
  i: int;
begin
  if not StoredLists.Find(s, i) then
    exit;
  with TStringList(StoredLists.Objects[i]) do
    for i:= 0 to Count - 1 do
      List.Add(Strings[i]);
end;

procedure DoListRemove(const s: string; b: Boolean);
var
  i, j: int;
begin
  if not StoredLists.Find(s, i) then
    exit;
  with TStringList(StoredLists.Objects[i]) do
    for i:= List.Count - 1 downto 0 do
      if Find(List.Strings[i], j) = b then
        List.Delete(i);
end;

procedure ListRemove(const s: string);
begin
  DoListRemove(s, true);
end;

procedure ListAnd(const s: string);
begin
  DoListRemove(s, false);
end;

procedure ListInvert(const s: string);
begin
  StoreList(s);
  SetPattern('*');
  ListRemove(s);
end;

//-- Lod

procedure Load(const name: string);
begin
  FreeAndNil(Lod);
  Lod:= RSLoadMMArchive(name);
  Lod.RawFiles.WriteOnDemand:= true;
  if Lod is TRSLwd then
    TRSLwd(Lod).OnFindDimentions:= TCallbacks.FindDimentions;
end;

procedure Save(const name: string);
begin
  if SameText(name, Lod.RawFiles.FileName) then
    Lod.RawFiles.Rebuild
  else
    Lod.SaveAs(name);
end;

procedure StoreLod(const s: string);
var
  i: int;
begin
  i:= StoredLods.Add(s);
  StoredLods.Objects[i].Free;
  StoredLods.Objects[i]:= Lod;
  Lod:= nil;
end;

procedure RestoreLod(const s: string);
var
  i: int;
begin
  FreeAndNil(Lod);
  if StoredLods.Find(s, i) then
  begin
    Lod:= ptr(StoredLods.Objects[i]);
    StoredLods.Delete(i);
  end;
end;

procedure SetWriteOnDemand(i: int);
begin
  Lod.RawFiles.WriteOnDemand:= i <> 0;
end;

//-- Operations

procedure DeleteList;
var
  i: int;
begin
  for i:= 0 to List.Count - 1 do
    Lod.RawFiles.Delete(List[i]);
  //List.Clear;
end;

procedure RenameLodFile(const old, new: string);
var
  i: int;
begin
  if Lod.RawFiles.FindFile(old, i) then
    Lod.RawFiles.Rename(i, new);
end;

procedure MergeLod(const s: string);
var
  i: int;
begin
  if not StoredLods.Find(s, i) then
    exit;
  TRSMMArchive(StoredLods.Objects[i]).RawFiles.MergeTo(Lod.RawFiles);
end;

procedure CompareLod(const name: string);
var
  lod2: TRSMMArchive;
  b: Boolean;
  i, j: int;
begin
  if not StoredLods.Find(name, i) then
    exit;
  List.Clear;
  lod2:= TRSMMArchive(StoredLods.Objects[i]);
  with Lod do
    for i := 0 to Count - 1 do
    begin
      j:= i;
      b:= (j < lod2.Count) and SameText(Names[i], lod2.Names[j]) or
          lod2.RawFiles.FindFile(Names[i], j);
      if not b or not CompareFiles(lod2, i, j) then
        List.Add(Lod.Names[i]);
    end;
end;

procedure ExportFiles(const s: string);
var
  i, j: int;
begin
  for i:= 0 to List.Count - 1 do
    if Lod.RawFiles.FindFile(List[i], j) then
      Lod.Extract(j, s);
end;

procedure ImportFiles(const s: string);
begin
  with TRSFindFile.Create(s) do
  try
    while FindEachFile do
      Lod.Add(FileName);
  finally
    Free;
  end;
end;

procedure ImportResolution(x: int; const sy: string);
begin
  if sy = '' then
    ResY:= x
  else
    ResY:= ExprToInt(sy);
  ResX:= x;
end;

type
  TMMLodFile = packed record
    Name: array[1..16] of char;
    BmpSize: int;
    DataSize: int;
    BmpWidth: int2;
    BmpHeight: int2;
    BmpWidthLn2: int2;  // textures: log2(BmpWidth)
    BmpHeightLn2: int2;  // textures: log2(BmpHeight)
    BmpWidthMinus1: int2;  // textures: BmpWidth - 1
    BmpHeightMinus1: int2;  // textures: BmpHeight - 1
    Palette: int2;
    _unk: int2;  // runtime palette index
    UnpSize: int;
    Bits: int;  // Bits:  2 - mipmaps, $10 - something important too,
    //                    $400 - don't free buffers, $200 - transparent icon  
    // Data...
    // Palette...
  end;

  TMMSprite = packed record
    Name: array[1..12] of char;
    Size: int;
    w: int2;
    h: int2;
    Palette: int2;
    unk_1: int2;
    yskip: int2; // number of clear lines at the bottom
    unk_2: int2; // used in runtime only, for bits
    UnpSize: int;
  end;

{procedure AddPalIndex(dn: int);
var
  m: TMemoryStream;
  r: TStream;
  i, j: int;
begin
  m:= TMemoryStream.Create;
  with Lod.RawFiles do
    for j := 0 to List.Count - 1 do
      if FindFile(List[j], i) and not IsPacked[i] then
      begin
        m.Size:= Size[i];
        m.Seek(0, 0);
        r:= GetAsIsFileStream(i);
        r.ReadBuffer(m.Memory^, Size[i]);
        FreeAsIsFileStream(i, r);
        if (Lod as TRSLodBase).Version = RSLodSprites then
          with TMMSprite(m.Memory^) do
            inc(Palette, dn)
        else if TRSLodBase(Lod).Version = RSLodBitmaps then
          with TMMLodFile(m.Memory^) do
            inc(Palette, dn);
        Add(Name[i], m, Size[i], clNone);
      end;

  m.Free;
end;}

procedure ChangePalIndex(const expr: string);
var
  a: TRSOperatorArray;
  m: TMemoryStream;
  r: TStream;
  i, j: int;
begin
  MyParseExpr(expr, a);
  RSCalcExpr(a);
  m:= TMemoryStream.Create;
  with Lod.RawFiles do
    for j := 0 to List.Count - 1 do
      if FindFile(List[j], i) and not IsPacked[i] then
      begin
        m.Size:= Size[i];
        m.Seek(0, 0);
        r:= GetAsIsFileStream(i);
        r.ReadBuffer(m.Memory^, Size[i]);
        FreeAsIsFileStream(i, r);
        if (Lod as TRSLodBase).Version = RSLodSprites then
          with TMMSprite(m.Memory^) do
            Palette:= Round(RSCalcExpr(a, TCallbacks.ChangePalIndex, ptr(Palette)))
        else if TRSLodBase(Lod).Version = RSLodBitmaps then
          with TMMLodFile(m.Memory^) do
            Palette:= Round(RSCalcExpr(a, TCallbacks.ChangePalIndex, ptr(Palette)));
        Add(Name[i], m, Size[i], clNone);
      end;

  m.Free;
end;

procedure CopyBits(const s: string);
var
  hdr: TMMLodFile;
  r: TStream;
  m: TMemoryStream;
  i, idx, k1, k2: int;
begin
  if not StoredLods.Find(s, idx) then
    exit;
  Assert((Lod as TRSLodBase).Version in [RSLodBitmaps, RSLodIcons]);
  m:= TMemoryStream.Create;
  with TRSMMArchive(StoredLods.Objects[idx]) do
    for i := 0 to List.Count - 1 do
      if Lod.RawFiles.FindFile(List[i], k1) and RawFiles.FindFile(List[i], k2) then
      begin
        r:= RawFiles.GetAsIsFileStream(k2);
        r.ReadBuffer(hdr, SizeOf(hdr));
        RawFiles.FreeAsIsFileStream(k2, r);
        m.Size:= 0;
        Lod.RawFiles.RawExtract(k1, m);
        TMMLodFile(m.Memory^).Bits:= hdr.Bits;
        m.Position:= 0;
        Lod.RawFiles.Add(Lod.Names[k1], m, m.Size, clNone);
      end;
  m.Free;
end;

procedure CheckBit(v: int);
var
  hdr: TMMLodFile;
  r: TStream;
  i: int;
begin
  with Lod, RawFiles do
    for i := 0 to Count - 1 do
    begin
      r:= GetAsIsFileStream(i);
      r.ReadBuffer(hdr, SizeOf(hdr));
      FreeAsIsFileStream(i, r);
      if (hdr.Bits and v) <> 0 then
        List.Add(Name[i]);
    end;
end;

procedure ListBits;
var
  hdr: TMMLodFile;
  r: TStream;
  i, j: int; k: uint;
begin
  with Lod, RawFiles do
    for i := 0 to Count - 1 do
    begin
      r:= GetAsIsFileStream(i);
      r.ReadBuffer(hdr, SizeOf(hdr));
      FreeAsIsFileStream(i, r);
      k:= 1;
      for j := 0 to 31 do
      begin
        if hdr.Bits and k <> 0 then
          List.Add(IntToStr(k));
        k:= k*2;
      end;
    end;
end;

procedure JoinPixelData;
var
  a: TRSByteArray;
  b: TBitmap;
  i, j, k: int;
begin
  with Lod.RawFiles do
    for j := 0 to List.Count - 1 do
      if FindFile(List[j], i) then
      begin
        b:= Lod.ExtractArrayOrBmp(i, a);
        Assert((b <> nil) and (b.PixelFormat = pf8bit));
        k:= length(Data);
        SetLength(Data, k + b.Width*b.Height);
        RSBitmapToBuffer(@Data[k], b);
        b.Free;
      end;
end;

procedure SaveData(const name: string);
begin
  RSSaveFile(name, Data);
end;

procedure ClearData;
begin
  Data:= nil;
end;

//-- File operations

procedure DeleteF(const name: string);
begin
  DeleteFile(name);
end;

procedure RenameF(const old, new: string);
begin
  RenameFile(old, new);
end;

procedure RenameOverF(const old, new: string);
begin
  DeleteFile(new);
  RenameFile(old, new);
end;

procedure CopyF(const old, new: string);
begin
  CopyFile(PChar(old), PChar(new), true);
end;

procedure CopyOverF(const old, new: string);
begin
  CopyFile(PChar(old), PChar(new), false);
end;

procedure ChangeDir(const s: string);
begin
  if s <> '' then
    SetCurrentDir(s)
  else
    SetCurrentDir(BaseDir);
end;

procedure mkdir(const s: string);
begin
  RSCreateDir(s);
end;

//-- Command Files

procedure ReplaceAndExec(s: string; sl: TRSKeyValueStringList; const fname: string);
var
  i: int;
begin
  for i:= 0 to sl.Count - 1 do
    s:= RSStringReplace(s, '<' + sl[i] + '>', sl.Values[i], [rfReplaceAll, rfIgnoreCase]);
  IncludeFmt.Clear;
  DoExecCommands(s, fname);
end;

procedure ExecCommands(const name: string);
begin
  ReplaceAndExec(RSLoadTextFile(name), IncludeFmt, name);
end;

procedure EnumList(const name: string);
var
  lst: TStringList;
  sl: TRSKeyValueStringList;
  s: string;
  i: int;
begin
  s:= RSLoadTextFile(name);
  lst:= TStringList.Create;
  lst.Assign(List);
  sl:= TRSKeyValueStringList.Create(true);
  sl.Assign(IncludeFmt);
  for i:= 0 to lst.Count - 1 do
  begin
    sl.KeyValue['item']:= lst[i];
    ReplaceAndExec(s, sl, name);
  end;
  sl.Free;
end;

//-- Commands

type
  TMyCmd1 = procedure(const p1: string);
  TMyCmd2 = procedure(const p1, p2: string);
  TMyCmdNum = procedure(p1: int);
  TMyCmdNum1s1 = procedure(i: int; const p2: string);
  TMyCmd2n2 = procedure(const p1, p2: string; i, j: int);
  TMyCmd1n1s1 = procedure(const p1: string; p2: int; p3: string);

procedure ExecCmd(const ps: TRSParsedString);
var
  cmd, p1, p2, p3, p4: string;

  procedure c(const name: string; f: TMyCmd1); overload;
  begin
    if cmd = name then
      f(p1)
    else if cmd = name + '%' then
      f(Param(ExprToInt(p1)));
  end;

  procedure c(const name: string; f: TMyCmd2); overload;
  begin
    if cmd = name then
      f(p1, p2)
    else if cmd = name + '%' then
      f(Param(ExprToInt(p1)), Param(ExprToInt(p2)));
  end;

  procedure c2(const name: string; f: TMyCmd2); overload;
  begin
    if cmd = name then
      f(p1, p2)
    else if cmd = name + '%' then
      f(p1, Param(ExprToInt(p2)));
  end;

  procedure c2(const name: string; f: TMyCmd2n2); overload;
  begin
    if cmd = name then
      f(p1, p2, ExprToInt(p3), ExprToInt(p4))
    else if cmd = name + '%' then
      f(p1, Param(ExprToInt(p2)), ExprToInt(p3), ExprToInt(p4));
  end;

  procedure c(const name: string; f: TMyCmdNum); overload;
  begin
    if cmd = name then
      f(ExprToInt(p1));
  end;

  procedure c(const name: string; f: TProcedure); overload;
  begin
    if cmd = name then
      f;
  end;

  procedure c(const name: string; f: TMyCmdNum1s1); overload;
  begin
    if cmd = name then
      f(ExprToInt(p1), p2);
  end;

  procedure c(const name: string; f: TMyCmd1n1s1); overload;
  begin
    if cmd = name then
      f(p1, ExprToInt(p2), p3);
  end;

begin
  cmd:= LowerCase(Trim(RSGetToken(ps, 0)));
  p1:= RSGetToken(ps, 1);
  p2:= RSGetToken(ps, 2);
  p3:= RSGetToken(ps, 3);
  p4:= RSGetToken(ps, 4);
  c('+', &AddPattern);
  c('-', &RemovePattern);
  c('=', &SetPattern);
  c('save list', &SaveList);
  c('load list', &LoadList);
  c('list->', &StoreList);
  c('list<-', &RestoreList);
  c('list+', &ListAdd);
  c('list-', &ListRemove);
  c('list and', &ListAnd);
  c('list invert', &ListInvert);

  c('load', &Load);
  c('save', &Save);
  c('lod->', &StoreLod);
  c('lod<-', &RestoreLod);
  c('write on demand', &SetWriteOnDemand);

  c('del', &DeleteList);
  c('rename', &RenameLodFile);
//  c('pal add', &AddPalIndex);
  c('pal=', &ChangePalIndex);
  c('lod+', &MergeLod);
  c('compare', &CompareLod);
  c('export', &ExportFiles);
  c('import', &ImportFiles);
  c('import resolution', &ImportResolution);

  c('join pixel data', &JoinPixelData);
  c('save data', &SaveData);
  c('clear data', &ClearData);

  c('copy bits', &CopyBits);
  c('check bit', &CheckBit);
  c('list bits', &ListBits);

  c('include', &ExecCommands);
  c2('include replace', &IncludeParam);
  c2('replace', &ReplaceParam);
  c('enum', &EnumList);
  c2('substr', &ReplaceCopy);
  c('calc', &Calc);

  c('delete file', &DeleteF);
  c('rename file', &RenameF);
  c('copy file', &CopyF);
  c('force rename file', &RenameOverF);
  c('force copy file', &CopyOverF);
  c('cd', &ChangeDir);
  c('mkdir', &mkdir);

  c('load params', &LoadParams);
  c('shift params', &ShiftParams);
end;

procedure InfoBox;
const
  info = 'Usage: LodTool.exe Commands.txt Param1 Param2 ...'
   + #10'(Press Ctrl+C to copy this text to clipboard)'
   + #10'All commands that take strings as arguments have a version with "%"'
   + ' at the end of their name that takes parameter indexes instead.'
   + #10'For example, "load%|1" would load Param1 file, "replace%|dir|1" would replace "<dir>" with Param1.'
   + #10'Omitted parameters are treated as empty strings (e.g. "list->" is perfectly fine).'
   + #10'In place of any integer parameter you can use an expression (with +,-,*,^,/,div,mod,and,or,<,<=,>,>=,<> operators).'
   + #10#10'Commands (case-insensitive):';
  cmd: array[1..38] of string = (
    '+|mask`Add all files matching the mask (e.g. "pal*") to the list',
    '-|mask`Remove all items matching the mask from the list',
    '=|mask`Clear the list and add all files matching the mask',
    'save list|fname`Save the list as text to "fname"',
    'load list|fname`Load the list from "fname"',
    'list->|name`Store list in "name" variable, switch to empty list',
    'list<-|name`Restore list from "name"',
    'list+|name`Add items from list "name" to current list',
    'list-|name`Remove items of list "name" from current list',
    'list and|name`Only keep items that are also present in list "name" in current list',
    'list invert|name`Combination of commands:  list->|name,  =|*,  list-|name',

    '~load|fname`Load archive from "fname"',
    'save|fname`Save archive to "fname"',
    'lod->|name`Move current archive to variable "name" (independant of "name" list variable)',
    'lod<-|name`Restore archive from variable "name"',

    'del`Delete all files found in the list from current archive',
    'rename|old|new`Rename "old" file into "new" in the archive, overwrite if needed',
//    'pal add|N`Add N to palette indexes of all files from the list',
    'pal=|expr`Set palette index to the result of expression "expr" in which "pal" stands for current palette index',
    'lod+|name`Add(merge) all contents of archive in the "name" variable to current archive',
    'compare|name`Set list to all files that have changed in current archive compared to the one in "name" variable',
    'export|fname`Export files in the list to folder "fname"',
    'import|fmask`Import files matching mask (and path) "fmask"',
    'import resolution|x_res|y_res`set resolution for subsequent LWD imports, e.g. "import resolution|2" for 2x original resolution',
    'write on demand|on`If set to 1 (default), keeps all changes in memory until Save is called. If set to 0, performs all operations immediately, like MMArchive',

{    'join pixel data',
    'save data',
    'clear data',

    'copy bits',
    'check bit',
    'list bits',}

    '~replace|name|value`Replace "<name>" with "value" in current file',
    'include|fname`Include commands file',
    'include replace|name|value`Replace "<name>" with "value" in the next included file',
    'enum|fname`Run commands file for every item in the list, with "<item>" replaced by item name',
    'substr|name|str|i|j`Replace "<name>" with substring of "str" from "i" to "j", where 1 is the first character, -1 is the last, -2 is the one before it etc',
    'calc|name|expr|fmt`Replace "<name>" with the result of expression "expr" rounded to an integer, optionally formatted according to "fmt"',

    '~delete file|fname`Delete file from file system',
    'rename file|old|new`Rename file in file system if destination doesn''t exits',
    'copy file|old|new`Copy file if destination doesn''t exits',
    'force rename file|old|new`Rename file in file system, overwrite if present',
    'force copy file|old|new`Copy file in file system, overwrite if present',
    'cd|fname`Change current folder to "fname" or to initial folder if there''s no parameter',
    'mkdir|fname`Create folder "fname" (and all missing parent folders)',

//    '~load params|fname`Load text file as the list of Param1, Param2, ...',
//    'shift params|N`Add N to param indexes used (calling it multiple times would accumulate shifts)',

    ''
  );
var
  s: string;
  i: int;
begin
  s:= info;
  for i := 1 to high(cmd) - 1 do
    s:= s + RSStringReplace(RSStringReplace('~' + cmd[i], '`', '  '#9'-  '), '~', #10'  ') + '.';
//    s:= s + #13#10 + RSStringReplace(cmd[i], '`', #13#10'    ') + '.';
  RSMessageBox(0, s, 'LodTool Help', MB_ICONINFORMATION);
end;

procedure DoExecCommands(const str, fname: string);
var
  sl: TStringList;
  i: int;
begin
  sl:= TStringList.Create;
  sl.Text:= str;
  for i := 0 to sl.Count - 1 do
  begin
    CmdList:= sl;
    ErrorFile:= fname;
    ErrorLine:= i;
    ExecCmd(RSParseString(sl[i], ['|']));
  end;
  sl.Free;
end;

procedure ShowError;
var
  Title: array[0..63] of Char;
  msg: string;
begin
  if ExceptObject is Exception then
    msg:= Exception(ExceptObject).Message;
  LoadString(FindResourceHInstance(HInstance), PResStringRec(@SExceptTitle).Identifier, Title, SizeOf(Title));
  RSMessageBox(0, Format('%s:%d: %s.', [ErrorFile, ErrorLine + 1, msg]), Title, MB_OK or MB_ICONSTOP or MB_TASKMODAL);
end;

begin
  if ParamStr(1) = '' then
  begin
    InfoBox;
    exit;
  end;
  ParamsList:= TStringList.Create;
  List:= SortedList(false);
  IncludeFmt:= TRSKeyValueStringList.Create;
  StoredLods:= SortedList(true);
  StoredLists:= SortedList(true);
  BaseDir:= GetCurrentDir;
  ErrorFile:= Param(0);
  ErrorLine:= -2;
  try
    ExecCommands(Param(0));
  except
    ShowError;
    Halt(1);
  end;
end.
