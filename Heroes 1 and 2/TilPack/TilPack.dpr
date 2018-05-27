program TilPack;

uses
  Windows, Classes, SysUtils, RSQ, RSSysUtils, Math, Graphics, RSGraphics;

{
Version 1.2:
[+] RLE bitmaps support.

Version 1.3:
[-] Inability to load some bitmaps

Version 1.3.2:
[-] Previous version was crashing on Windows XP
}

{ Builds:
1. Unpack
2. Unpack + Heroes2
3. no defines
}

{ $DEFINE Unpack}
{ $DEFINE Heroes2}

const
{$IFNDEF Unpack}
  AppName = 'TilPack';
{$ELSE}
 {$IFNDEF Heroes2}
  AppName = 'H1TilUnpack';
 {$ELSE}
  AppName = 'H2TilUnpack';
 {$ENDIF}
{$ENDIF}
 {$IFNDEF Heroes2}
  PaletteName = 'H1Palette.bmp';
 {$ELSE}
  PaletteName = 'H2Palette.bmp';
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

procedure UnpackTil(const arr: TRSByteArray; const path: string);
var
  til: PTilFile absolute arr;
  p: PByte;
  i: int;
begin
  if Bmp = nil then
    Bmp:= RSLoadBitmap(AppPath + PaletteName);
  Bmp.Height:= 0;
  RSCreateDir(path);
  with til^ do
  begin
    Bmp.Width:= Width;
    Bmp.Height:= Height;
    p:= @Buffer;
    for i:= 0 to Count - 1 do
    begin
      RSBufferToBitmap(p, Bmp);
      Bmp.SaveToFile(path + Format('%.4d.bmp', [i]));
      inc(p, Width*Height);
    end;
  end;
end;

function PackTil(const path: string): TRSByteArray;
var
  files: TStringList;
  til: PTilFile absolute Result;
  b: TBitmap;
  p: PByte;
  i: int;
begin
  b:= TBitmap.Create;
  files:= TStringList.Create;
  try
    with TRSFindFile.Create(path + '*.bmp') do
      try
        while FindNextAttributes(0, FILE_ATTRIBUTE_DIRECTORY) do // Only files
          files.Add(FileName);
      finally
        Free;
      end;

    if files.Count = 0 then
    begin
      SetLength(Result, 6);
      exit;
    end;

    ErrorFile:= files[0];
    RSLoadBitmap(files[0], b);
    SetLength(Result, 6 + files.Count*b.Width*b.Height);
    with til^ do
    begin
      Count:= files.Count;
      Width:= b.Width;
      Height:= b.Height;
      p:= @Buffer;
    end;
    for i := 0 to files.Count - 1 do
    begin
      ErrorFile:= files[i];
      if i <> 0 then
        RSLoadBitmap(files[i], b);

      if (b.Width <> til.Width) or (b.Height <> til.Height) or
         (RSGetPixelFormat(b) <> pf8bit) then
        raise Exception.Create('Wrong bitmap format');
      RSBitmapToBuffer(p, b);
      inc(p, til.Width*til.Height);
    end;
    ErrorFile:= '';
  finally
    files.Free;
    b.Free;
  end;
end;

procedure UnpackByMask(const path: string; const PreviewPath: string = '');
begin
  if PreviewPath <> '' then
    RSCreateDir(PreviewPath);
  with TRSFindFile.Create(path) do
    try
      while FindNextAttributes(0, FILE_ATTRIBUTE_DIRECTORY) do // Only files
      begin
        ErrorFile:= FileName;
        if PreviewPath <> '' then
          UnpackBmp(RSLoadFile(FileName), PreviewPath + ExtractFileName(FileName) + '.bmp')
        else
          UnpackTil(RSLoadFile(FileName), FileName + '.cadres\');
      end;
    finally
      Free;
    end;
end;

{
var
  FileNames: TStringList;

procedure EnumFiles(const path: string);
begin
  FileNames:= TStringList.Create;
  with TRSFindFile.Create(path + '*.bmp') do
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


procedure TestH2(const path: string);
var
  arr: TRSByteArray;
  bmp: PTilFile absolute arr;
  i: int;
begin
  EnumFiles(path);
  for i := FileNames.Count - 1 downto 0 do
  begin
    arr:= RSLoadFile(path + FileNames[i]);
    if bmp.Count = 33 then
      FileNames.Delete(i);
  end;
  FileNames.SaveToFile(path + 'BmpUnk.txt');
end;
}


const
  Info = AppName + ' v1.3.2'#13#10 +
         'Usage 1:  ' + AppName + '.exe Target.til'#13#10 +
{$IFDEF Unpack}
         'Unpacks into "Target.til.cadres" folder.'#13#10 +
         'File masks are supported. Use "*.til" to unpack all TIL files.'#13#10#13#10 +
         'Usage 2:  ' + AppName + '.exe InFolder [OutFolder]'#13#10 +
         'Extracts 1 cadre of each TIL file into OutFolder.'#13#10 +
         'OutFolder defaults to "InFolder\Til Preview".'#13#10#13#10 +
{$ELSE}
         'Usage 2:  ' + AppName + '.exe Target.til.cadres'#13#10 +
         'Creates "Target.til" using cadres from "Target.til.cadres" folder.'#13#10#13#10 +
{$ENDIF}
         'You can simply create a desktop shortcut for ' + AppName +
         ' and drag files or folders you want to ' +
{$IFDEF Unpack}
         'un' +
{$ENDIF}
         'pack onto it.'#13#10#13#10 +
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
      CopyFile(ptr(ParamStr(0)), PChar(AppName + '.exe'), false);
      exit;
    end;

{$IFDEF Unpack}
    if DirectoryExists(s) then
    begin
      s:= IncludeTrailingPathDelimiter(s);
      s1:= ParamStr(2);
      if s1 = '' then
        s1:= s + 'Til Preview\'
      else
        s1:= IncludeTrailingPathDelimiter(s1);
      UnpackByMask(s + '*.til', s1);
    end else
      UnpackByMask(s);

{$ELSE}
    if DirectoryExists(s) then
    begin
      s1:= IncludeTrailingPathDelimiter(s);
      s:= ChangeFileExt(ExcludeTrailingPathDelimiter(s), '');
    end else
    begin
      s1:= s + '.cadres\';
      if not DirectoryExists(s1) then
        raise Exception.Create('Folder doesn''t exist: ' + s1);
    end;
    RSSaveFile(s, PackTil(s1));
{$ENDIF}

    RSMessageBox(0, 'Operation succesful.', AppName, MB_ICONINFORMATION);
  except
    on e:Exception do
      Error(e.Message);
  end
end.
