program AggPack;

uses
  Windows, Classes, SysUtils, RSQ, RSSysUtils, Math, Graphics, RSGraphics,
  DemoFiles in 'DemoFiles.pas';

{
Version 1.2:
[+] RLE bitmaps support.

Version 1.3:
[-] Inability to load some bitmaps

Version 1.3.2:
[-] Previous version was crashing on Windows XP
}
  
{ Builds:
1. -
2. Buka
3. Heroes2
4. Unpack + Heroes2
5. Unpack
6. Unpack + Buka
7. Unpack + H1Demo
}

{ $DEFINE Unpack}
{ $DEFINE H1Demo}
{ $DEFINE Buka}
{ $DEFINE Heroes2}

const
{$IFNDEF Unpack}
 {$IFNDEF Heroes2}
  {$IFNDEF Buka}
  AppName = 'H1AggPack';
  {$ELSE}
  AppName = 'H1XAggPack';
  {$ENDIF}
 {$ELSE}
  AppName = 'H2AggPack';
 {$ENDIF}
{$ELSE}
 {$IFNDEF Heroes2}
  {$IFNDEF Buka}
   {$IFNDEF H1Demo}
  AppName = 'H1AggUnpack';
   {$ELSE}
  AppName = 'H1DAggUnpack';
   {$ENDIF}
  {$ELSE}
  AppName = 'H1XAggUnpack';
  {$ENDIF}
 {$ELSE}
  AppName = 'H2AggUnpack';
 {$ENDIF}
{$ENDIF}

{$IFNDEF Heroes2}
  PaletteName = 'H1Palette.bmp';
{$ELSE}
  PaletteName = 'H2Palette.bmp';
{$ENDIF}

{$IFNDEF H1Demo}
  ExeCopyPath = AppName + '.exe';
{$ELSE}
  ExeCopyPath = 'AggPackH1Demo\' + AppName + '.exe';
{$ENDIF}

var
  ErrorFile: string;

procedure Error(const s:string);
begin
  if ErrorFile <> '' then
    RSMessageBox(0, s + '.'#13#10 + ErrorFile, AppName, MB_ICONERROR)
  else
    RSMessageBox(0, s + '.', AppName, MB_ICONERROR);
end;

{$IFNDEF Heroes2}

function GetHashId(a: PChar): Word;
asm
  push    ebx
  mov     ecx, eax
  sub     ebx, ebx
  sub     eax, eax
@loc_47CA23:
  mov     bl, [ecx]
  or      bl, bl
  jz      @exit
  and     bl, 7Fh
  cmp     bl, 60h
  jb      @loc_47CA34
  sub     bl, 20h
@loc_47CA34:
  xchg    al, ah
  rol     ax, 1
  sub     ax, bx
  inc     ecx
  jmp     @loc_47CA23
@exit:
  pop    ebx
end;

{$ELSE}

function GetHashId(const a: string): uint;
var
  i, j, k: uint;
begin
  Result:= 0;
  j:= 0;
  for k:= length(a) downto 1 do
  begin
    i:= ord(a[k]);
    if (i >= 97) and (i <= 122) then
      i:= i and $DF;
    j:= j + i;
    Result:= (Result shr 25) + (Result shl 5) + j + i;
  end;
end;

{$ENDIF}

type
{$IFNDEF Heroes2}
  TFileRec = packed record
    Hash: word;
    Offset: uint;
    Size: uint;
{$IFNDEF Buka}
{$IFNDEF H1Demo}
    Size1: uint;
{$ENDIF}
{$ENDIF}
  end;
{$ELSE}
  TFileRec = packed record
    Hash: uint;
    Offset: uint;
    Size: uint;
  end;
{$ENDIF}
  TFileNameRec = packed record
    Name: array[0..14] of char;
  end;


type
  PTilFile = ^TTilFile;
  TTilFile = packed record
    Count: Word;
    Width: Word;
    Height: Word;
    Buffer: array[0..MaxInt div 2] of Byte;
  end;

var
  Bmp: TBitmap;

procedure UnpackBmp(const arr: TRSByteArray; const name: string);
var
  til: PTilFile absolute arr;
begin
  if Bmp = nil then
    Bmp:= RSLoadBitmap(AppPath + PaletteName);
  Bmp.Height:= 0;
  with til^ do
  begin
    Bmp.Width:= Width;
    Bmp.Height:= Height;
    RSBufferToBitmap(@Buffer, Bmp);
  end;
  Bmp.SaveToFile(name);
end;

function PackBmp(const name: string): TRSByteArray;
var
  til: PTilFile absolute Result;
  m: TRSArrayStream;
  b: TBitmap;
begin
  Result:= RSLoadFile(name);
  if (length(Result) >= 6) and (Result[0] = 33) then  exit;
  m:= TRSArrayStream.Create(Result);
  b:= nil;
  try
    b:= RSLoadBitmap(m);
    FreeAndNil(m);
    SetLength(Result, b.Width*b.Height + 6);
    with til^ do
    begin
      Count:= 33;
      Width:= b.Width;
      Height:= b.Height;
      if RSGetPixelFormat(b) <> pf8bit then
        raise Exception.Create('Wrong bitmap format');
      RSBitmapToBuffer(@Buffer, b);
    end;
  finally
    m.Free;
    b.Free;
  end;
end;


var
  FileNames: TStringList;

procedure EnumFiles(const path: string);
begin
  FileNames:= TStringList.Create;
  with TRSFindFile.Create(path + '*') do
    try
      while FindAttributes(0, FILE_ATTRIBUTE_DIRECTORY) do // Only files
      begin
        FileNames.Add(Data.cFileName);
        FindNext;
      end;
    finally
      Free;
    end;
end;

procedure PackFiles(const agg: string; const path: string);
var
{$IFNDEF Heroes2}
  HashCounts: array[Word] of Word;
{$ENDIF}
  files: array of TFileRec;
  names: array of TFileNameRec;
  buf: TRSByteArray;
  f: TFileStream;
  i, j, off: uint;
  count, k: Word;
  s: string;
begin
{$IFNDEF Heroes2}
  FillChar(HashCounts, SizeOf(HashCounts), 0);
{$ENDIF}
  count:= FileNames.Count;
  SetLength(names, count);
  SetLength(files, count);
  f:= TFileStream.Create(agg, fmCreate);
  try
    f.WriteBuffer(count, 2);
    off:= 2 + count*SizeOf(TFileRec);
    f.Seek(off, 0);
    for i := 0 to count - 1 do
    begin
      s:= FileNames[i];
      ErrorFile:= path + s;
      if SameText(ExtractFileExt(s), '.bmp') then
      begin
        buf:= PackBmp(path + s);
        if SameText(ExtractFileExt(ChangeFileExt(s, '')), '.bkg') then
          s:= ChangeFileExt(s, '');
      end else
        buf:= RSLoadFile(path + s);

      CopyMemory(@names[i], ptr(s), min(length(s), 14));
      files[i].Hash:= GetHashId(PChar(@names[i]));
{$IFNDEF Heroes2}
      inc(HashCounts[files[i].Hash]);
{$ENDIF}
      files[i].Offset:= off;
      files[i].Size:= length(buf);
{$IFNDEF Heroes2}{$IFNDEF Buka}{$IFNDEF H1Demo}
      files[i].Size1:= length(buf);
{$ENDIF}{$ENDIF}{$ENDIF}
      f.WriteBuffer(buf[0], length(buf));
      off:= off + uint(length(buf));
    end;
    f.WriteBuffer(names[0], count*SizeOf(TFileNameRec));
    f.Seek(2, 0);
    f.WriteBuffer(files[0], count*SizeOf(TFileRec));

    // Check for duplicate hash ids
    ErrorFile:= '';
{$IFNDEF Heroes2}
    s:= '';
    for i := 0 to count - 1 do
      if HashCounts[files[i].Hash] > 1 then
      begin
        k:= files[i].Hash;
        HashCounts[k]:= 0;
        if s = '' then
          s:= 'The following files have the same hash ID:'
        else
          s:= s + #13#10;

        for j := i to count - 1 do
          if files[j].Hash = k then
            s:= s + #13#10 + FileNames[j];
      end;

    if s <> '' then
      Error(s + #13#10'Rename them to make their IDs different.');
{$ENDIF}
  finally
    f.Free;
  end;
end;

procedure UnpackFiles(const agg: string; const path: string);
var
  files: array of TFileRec;
{$IFNDEF H1Demo}
  names: array of TFileNameRec;
{$ENDIF}
  buf: TRSByteArray;
  f: TFileStream;
  s: string;
  count: Word;
  i: uint;
begin
  f:= TFileStream.Create(agg, fmOpenRead);
  try
    f.ReadBuffer(count, 2);
    SetLength(files, count);
    f.ReadBuffer(files[0], count*SizeOf(TFileRec));
{$IFNDEF H1Demo}
    SetLength(names, count);
    f.Seek(-int(count*SizeOf(TFileNameRec)), soEnd);
    f.ReadBuffer(names[0], count*SizeOf(TFileNameRec));
{$ENDIF}
    RSCreateDir(path);
    for i := 0 to count - 1 do
    begin
{$IFDEF H1Demo}
      ErrorFile:= FileByHash[files[i].Hash];
      if ErrorFile = '' then
        ErrorFile:= Format('file_%d', [i]);
{$ELSE}
      ErrorFile:= names[i].Name;
{$ENDIF}
      buf:= nil;
      if files[i].Size <> 0 then
      begin
        f.Seek(files[i].Offset, 0);
        SetLength(buf, files[i].Size);
        f.ReadBuffer(buf[0], files[i].Size);
      end;
      s:= ExtractFileExt(ErrorFile);
      if SameText(s, '.bmp') then
        UnpackBmp(buf, path + ErrorFile)
      else if SameText(s, '.bkg') then
        UnpackBmp(buf, path + ErrorFile + '.bmp')
      else
        RSSaveFile(path + ErrorFile, buf);
    end;
    ErrorFile:= '';
  finally
    f.Free;
  end;
end;


const
  Info = AppName + ' v1.3.2'#13#10 +
         'Usage: ' + AppName + '.exe Archive.agg [Folder]'#13#10 +
         'Folder defaults to the archive name without extension.'#13#10#13#10 +
         'By Sergey Rozhenko'#13#10 +
         'http://grayface.github.io/'#13#10 +
         'sergroj@mail.ru';
var
  s, s1: string;
begin
  try
    s:= ParamStr(1);
    if s = '' then
    begin
      RSMessageBox(0, Info, AppName, MB_ICONINFORMATION);
      exit;
    end;
    if s = ':copyexe' then
    begin
      CopyFile(ptr(ParamStr(0)), PChar(ExeCopyPath), false);
      exit;
    end;

    s1:= ParamStr(2);
    if s1 = '' then
      s1:= ChangeFileExt(s, '');
    s1:= IncludeTrailingPathDelimiter(s1);

{$IFDEF H1Demo}
    InitFileByHash;
{$ENDIF}
{$IFNDEF Unpack}
    if not DirectoryExists(s1) then
    begin
      Error('Folder doesn''t exist: ' + s1);
      exit;
    end;
{$ENDIF}
{$IFNDEF Unpack}
    EnumFiles(s1);
    PackFiles(s, s1);
{$ELSE}
    UnpackFiles(s, s1);
{$ENDIF}
    RSMessageBox(0, 'Operation succesful.', AppName, MB_ICONINFORMATION);
  except
    on e:Exception do
      Error(e.Message);
  end
end.
