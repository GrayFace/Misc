program IcnPack;

uses
  Windows, Classes, SysUtils, RSQ, RSSysUtils, Math, Graphics, RSGraphics,
  RSDefLod, IniFiles;

{
Version 1.2:
[+] RLE bitmaps support.

Version 1.3:
[-] Inability to load some bitmaps

Version 1.3.1:
[-] H1IcnPack didn't work

Version 1.3.2:
[-] Previous version was crashing on Windows XP
}

{ Builds:
1. -
2. Heroes2
3. Unpack + Heroes2
4. Unpack
}

{ $DEFINE Unpack}
{ $DEFINE Heroes2}

const
{$IFNDEF Unpack}
 {$IFNDEF Heroes2}
  AppName = 'H1IcnPack';
 {$ELSE}
  AppName = 'H2IcnPack';
 {$ENDIF}
{$ELSE}
 {$IFNDEF Heroes2}
  AppName = 'H1IcnUnpack';
 {$ELSE}
  AppName = 'H2IcnUnpack';
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
  TIcnCadre = packed record
    X: int2;
    Y: int2;
    Width: Word;
    Height: Word;
{$IFDEF Heroes2}
    Bits: Byte;
{$ENDIF}
    Offset: uint;
  end;
  
  PIcnFile = ^TIcnFile;
  TIcnFile = packed record
    Count: Word;
    Size: int;
    Cadres: array[0..1000000] of TIcnCadre;
  end;

const
  TransCode = 0;
  SpecialCode = 5;
  SpecialShdCode = 6;
  SpecialShdLCode = 7;
  ShadowCodes: array[0..15] of Byte = (4, 3, 2, 1, 8, 9, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255);
type
  TByteArray255 = array[0..255] of Byte;
var
  ColorToKindNorm: TByteArray255;
  ColorToKindMask: TByteArray255;


procedure UnpackCadre(p: PByte; buf: PByte; scan: int; mask: Boolean = false);
var
  p1: PByte;

  function GetByte: Byte;
  begin
    Result:= p^;
    inc(p);
  end;

  procedure FillBytes(n: int; v: Byte);
  begin
    FillMemory(p1, n, v);
    inc(p1, n);
  end;

var
  code: byte;
{$IFDEF Heroes2}
  c: byte;
{$ENDIF}
begin
  p1:= buf;
  while true do
  begin
    code:= GetByte;
    case code of
      $80:
        exit;
      0:
      begin
        inc(buf, scan);
        p1:= buf;
      end;
      1..$7F:
      if not mask then
      begin
        CopyMemory(p1, p, code);
        inc(p, code);
        inc(p1, code);
      end else
        FillBytes(code, SpecialCode);
{$IFNDEF Heroes2}
      $81..$FF:
        inc(p1, code and $7F);
{$ELSE}
      $81..$BF:
        inc(p1, code and $7F);

      $C1:
      begin
        code:= GetByte;
        FillBytes(code, GetByte);
      end;
      $C2..$FF:
        FillBytes(code and $3F, GetByte);

      $C0:
      begin
        Code:= GetByte;
        if code and $80 <> 0 then
          if code and $40 <> 0 then
            if code and not 3 = $C0 then
              c:= SpecialShdCode
            else
              c:= SpecialShdLCode
          else
            c:= SpecialCode
        else if code and $40 <> 0 then
          c:= ShadowCodes[(code shr 2) and $F]
        else
          c:= TransCode;

        if Code and 3 <> 0 then
          FillBytes(code and $3, c)
        else
          FillBytes(GetByte, c);
      end;
{$ENDIF}
    end;
  end;
end;

procedure PrepareColorToKindH2;
var
  i: int;
begin
  ColorToKindNorm[SpecialCode]:= 2;
  ColorToKindNorm[SpecialShdCode]:= 3;
  ColorToKindNorm[SpecialShdLCode]:= 4;
  for i := 0 to 13 do
    ColorToKindNorm[ShadowCodes[i]]:= i + 5;
end;

procedure PrepareColorToKind;
begin
  ColorToKindNorm[TransCode]:= 1;
  ColorToKindMask[TransCode]:= 1;
{$IFDEF Heroes2}
  PrepareColorToKindH2;
{$ENDIF}
end;

// doesn't do RLE of standard colors
procedure PackCadre(m: TStream; buf: PByteArray; scan: int; w, h: int; mask: Boolean = false);
var
  ColorToKind: ^TByteArray255;
  x: int;

  procedure PutByte(b: Byte);
  begin
    m.Write(b, 1);
  end;

  // counts up to n colors of the same kind
  function CountSameBytes(n: int): int;
  var
    k: Byte;
  begin
    k:= ColorToKind[buf[x]];
    Result:= 1;
    while (Result < n) and (x + Result < w) and (ColorToKind[buf[x + Result]] = k) do
      inc(Result);
  end;

var
  kind: byte;
  n: int;
begin
  if mask then
    ColorToKind:= @ColorToKindMask
  else
    ColorToKind:= @ColorToKindNorm;
    
  for h := h downto 1 do
  begin
    x:= 0;
    while x < w do
    begin
      kind:= ColorToKind[buf[x]];
      case kind of
        0: // normal color
        begin
          n:= CountSameBytes($7F);
          PutByte(n);
          if not mask then
            m.Write(buf[x], n)
          else
            FillMemory(@buf[x], n, TransCode);
          inc(x, n);
        end;
        1: // transparent
        begin
{$IFNDEF Heroes2}
          n:= CountSameBytes($7F);
{$ELSE}
          n:= CountSameBytes($3F);
{$ENDIF}
          inc(x, n);
          if x < w then
            PutByte($80 + n);
        end;
        // special color or shadow
{$IFDEF Heroes2}
        else begin
          PutByte($C0);
          if kind = 2 then // selection
            kind:= $80
          else if kind = 3 then // selection + shadow
            kind:= $C0
          else if kind = 4 then // selection + light shadow
            kind:= $C4
          else // shadow
            kind:= $40 + (kind - 5)*4;
          n:= CountSameBytes($FF);
          if n >= 4 then
          begin
            PutByte(kind);
            PutByte(n);
          end else
            PutByte(kind + n);
          inc(x, n);
        end;
{$ENDIF}
      end;
    end;
    PutByte(0);
    buf:= @buf[scan];
  end;
  PutByte($80);
end;


var
  Bmp: TBitmap;
{
function IsMask(s: string; cadre: int): Boolean;
begin
  s:= LowerCase(ExtractFileName(s));
  Result:= (s = 'font.icn') or (s = 'overlay.icn') or
           (cadre = 0) and (ExtractFileExt(s) = '.std');
end;
}

{$IFNDEF Heroes2}

// Heroes 1 doesn't indicate frames with masks in any way, so...
function IsMask(s: string; const arr: TRSByteArray; cadre: int): Boolean;
var
  icn: PIcnFile absolute arr;
  p, pmax: PChar;

  function GetByte: Byte;
  begin
    Result:= ord(p^);
    inc(p);
  end;

var
  code: byte;
  h: int;
begin
  s:= LowerCase(ExtractFileName(s));
  Result:= (s = 'font.icn') or (cadre = 0) and (ExtractFileExt(s) = '.std');
  if Result then  exit;
  h:= icn.Cadres[cadre].Height;
  Result:= (h <> 0);
  if not Result then  exit;

  p:= ptr(PChar(@icn.Cadres) + icn.Cadres[cadre].Offset);

  if cadre < icn.Count - 1 then
    pmax:= PChar(@icn.Cadres) + icn.Cadres[cadre + 1].Offset
  else
    pmax:= p;

  if pmax <= p then
    pmax:= PChar(arr) + length(arr);
  dec(pmax);

  while true do
  begin
    code:= GetByte;
    case code of
      $80:
        break;
      0:
        dec(h);
      1..$7F:
        for code := code downto 1 do
        begin
          if (p^ = #0) or (p = pmax) then
            exit;
          inc(p);
        end;
    end;
  end;
  Result:= (h <> 0) and (h <> 1);
end;

{$ELSE}

function IsMask(const s: string; const arr: TRSByteArray; cadre: int): Boolean;
var
  icn: PIcnFile absolute arr;
begin
  Result:= (icn.Cadres[cadre].Bits and $20 <> 0);
end;

{$ENDIF}

procedure UnpackPreview(const name, outName: string);
var
  arr: TRSByteArray;
  icn: PIcnFile absolute arr;
  p: PChar;
  i, j: int;
begin
  arr:= RSLoadFile(name);
{$IFNDEF Heroes2}
  i:= BoolToInt[SameText(ExtractFileExt(name), '.std') and (icn.Count > 1)];
{$ELSE}
  i:= 0;
{$ENDIF}
  if icn.Count <= i then  exit;
  if icn.Cadres[i].Height <= 1 then
    for j := i + 1 to icn.Count - 1 do
      if icn.Cadres[j].Height > 1 then
      begin
        i:= j;
        break;
      end;

  if Bmp = nil then
    Bmp:= RSLoadBitmap(AppPath + PaletteName);
  Bmp.Height:= 0;
  with icn.Cadres[i] do
  begin
    Bmp.Width:= Width;
    Bmp.Height:= Height;
    with Bmp.Canvas do
    begin
      Brush.Color:= $FFFF00;
      FillRect(ClipRect);
    end;

    if Height > 0 then
    begin
      p:= Bmp.ScanLine[0];
      if Height > 1 then
        j:= Bmp.ScanLine[1] - p
      else
        j:= 0;
      UnpackCadre(ptr(PChar(@icn.Cadres) + Offset), ptr(p), j, IsMask(name, arr, i));
    end;
  end;
  Bmp.SaveToFile(outName);
end;


procedure UnpackIcn(const name, outPath: string);
var
  arr: TRSByteArray;
  icn: PIcnFile absolute arr;
  ini: TIniFile;
  r: TRect;
  s: string;
  mask: Boolean;
  p: PChar;
  i, scan: int;
begin
  RSCreateDir(outPath);
  arr:= RSLoadFile(name);
  if icn.Count = 0 then  exit;
  r.Left:= MaxInt;
  r.Top:= MaxInt;
  r.Right:= not MaxInt;
  r.Bottom:= not MaxInt;
  for i := 0 to icn.Count - 1 do
    with r, icn.Cadres[i] do
    begin
      Left:= min(Left, X);
      Top:= min(Top, Y);
      Right:= max(Right, X + Width);
      Bottom:= max(Bottom, Y + Height);
    end;

  ini:= TIniFile.Create(outPath + 'setup.ini');
  try
    ini.WriteInteger('Position', 'X', r.Left);
    ini.WriteInteger('Position', 'Y', r.Top);
    if Bmp = nil then
      Bmp:= RSLoadBitmap(AppPath + PaletteName);
    Bmp.Height:= 0;
    Bmp.Width:= r.Right - r.Left;
    Bmp.Height:= r.Bottom - r.Top;
    p:= nil;
    if Bmp.Height > 0 then
      p:= Bmp.ScanLine[0];
    scan:= 0;
    if Bmp.Height > 1 then
      scan:= Bmp.ScanLine[1] - p;

    for i := 0 to icn.Count - 1 do
      with icn.Cadres[i] do
      begin
        mask:= IsMask(name, arr, i);
        with Bmp.Canvas do
        begin
          Brush.Color:= $FFFF00;
          FillRect(ClipRect);
        end;

        UnpackCadre(ptr(PChar(@icn.Cadres) + Offset),
                    ptr(p + scan*(Y - r.Top) + (X - r.Left)), scan, mask);
        s:= Format('%.4d.bmp', [i]);
        Bmp.SaveToFile(outPath + s);
{$IFNDEF Heroes2}
        ini.WriteInteger('Bits', s, IfThen(mask, $20, 0));
{$ELSE}
        ini.WriteInteger('Bits', s, Bits);
{$ENDIF}
      end;
  finally
    ini.Free;
  end;
end;


procedure UnpackByMask(const path: string; const PreviewPath: string = '');
  function IsIcn(s: string):Boolean;
  begin
    s:= LowerCase(ExtractFileExt(s));
{$IFNDEF Heroes2}
    Result:= (s = '.icn') or (s = '.obj') or (s = '.atk') or (s = '.std') or (s = '.wlk') or (s = '.wip')  or (s = '.xtl');
{$ELSE}
    Result:= (s = '.icn');
{$ENDIF}
  end;
begin
  if PreviewPath <> '' then
    RSCreateDir(PreviewPath);
  with TRSFindFile.Create(path) do
    try
      while FindNextAttributes(0, FILE_ATTRIBUTE_DIRECTORY) do // Only files
      begin
        while not IsIcn(Data.cFileName) do
          if not FindNextAttributes(0, FILE_ATTRIBUTE_DIRECTORY) then
            exit;
        ErrorFile:= FileName;
        if PreviewPath <> '' then
          UnpackPreview(FileName, PreviewPath + ExtractFileName(FileName) + '.bmp')
        else
          UnpackIcn(FileName, FileName + '.cadres\');
      end;
    finally
      Free;
    end;
end;



// Frame otside which there are only 0 pixels.
function GetFrame(b:TBitmap):TRect;
var p:PByte; i,j,dy,w,h:int;
begin
  w:=b.Width;
  h:=b.Height;
  if (w=0) or (h=0) then
  begin
    Result:=Rect(0,0,0,0);
    exit;
  end;
  p:=b.ScanLine[0];
  dy:= (w + 3) and not 3 + w; // scanline length
  dy:=-dy;
  with Result do
  begin
    Left:=w;
    Right:=-1;
    Top:=h;
    Bottom:=-1;
  end;
  for j:=0 to h-1 do
  begin
    for i:=0 to w-1 do
    begin
      if p^<>0 then
        with Result do
        begin
          if Left>i then Left:=i;
          if Top>j then Top:=j;
          if Right<i then Right:=i;
          if Bottom<j then Bottom:=j;
        end;
      inc(p);
    end;
    inc(p, dy);
  end;
  inc(Result.Right);
  inc(Result.Bottom);
  if Result.Right=0 then
  begin
    Result.Left:=0;
    Result.Top:=0;
  end;
end;


procedure PackIcn(const name, outPath: string);
var
  files: TStringList;
  m: TMemoryStream;
  icn: PIcnFile;
  b: TBitmap;
  r: TRect;
  ini: TIniFile;
  mask: Boolean;
  p: PChar;
  i, x0, y0, scan: int;
begin
  PrepareColorToKind;
  ini:= TIniFile.Create(outPath + 'setup.ini');
  b:= TBitmap.Create;
  m:= TMemoryStream.Create;
  files:= TStringList.Create;
  try
    with TRSFindFile.Create(outPath + '*.bmp') do
      try
        while FindNextAttributes(0, FILE_ATTRIBUTE_DIRECTORY) do // Only files
          files.Add(Data.cFileName);
      finally
        Free;
      end;

    x0:= ini.ReadInteger('Position', 'X', 0);
    y0:= ini.ReadInteger('Position', 'Y', 0);
    m.SetSize(int(@PIcnFile(nil).Cadres[files.Count]));
    m.Seek(0, soEnd);
    for i := 0 to files.Count - 1 do
    begin
      ErrorFile:= outPath + files[i];
      RSLoadBitmap(outPath + files[i], b);
      if RSGetPixelFormat(b) <> pf8bit then
        raise Exception.Create('Wrong bitmap format');
      r:= GetFrame(b);
      icn:= m.Memory;
      with icn.Cadres[i] do
      begin
        X:= x0 + r.Left;
        Y:= y0 + r.Top;
        Width:= r.Right - r.Left;
        Height:= r.Bottom - r.Top;
        Offset:= m.Size - int(@PIcnFile(nil).Cadres);
{$IFNDEF Heroes2}
        mask:= (ini.ReadInteger('Bits', files[i], 0) and $20 <> 0);
{$ELSE}
        Bits:= ini.ReadInteger('Bits', files[i], 0);
        mask:= (Bits and $20 <> 0);
{$ENDIF}
        p:= nil;
        if b.Height > 0 then
          p:= b.ScanLine[0];
        scan:= 0;
        if b.Height > 1 then
          scan:= b.ScanLine[1] - p;
        PackCadre(m, ptr(p + r.Top*scan + r.Left), scan, Width, Height, mask);
      end;
    end;
    ErrorFile:= '';
    icn:= m.Memory;
    icn.Count:= files.Count;
    icn.Size:= m.Size - int(@PIcnFile(nil).Cadres);
    m.SaveToFile(name);
  finally
    files.Free;
    m.Free;
    b.Free;
    ini.Free;
  end;
end;


{

var
  FileNames: TStringList;

procedure EnumFiles(const path: string);
begin
  FileNames:= TStringList.Create;
  with TRSFindFile.Create(path + '*.icn') do
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
label aaa;
var
  arr: TRSByteArray;
  icn: PIcnFile absolute arr;
  i, j: int;
begin
  EnumFiles(path);
  for i := FileNames.Count - 1 downto 0 do
  begin
    arr:= RSLoadFile(path + FileNames[i]);
    for j := 0 to icn.Count - 1 do
      if icn.Cadres[j].Unk <> 0 then
        goto aaa;
    FileNames.Delete(i);
aaa:
  end;
  FileNames.SaveToFile(path + 'IcnUnk.txt');
end;
}

procedure PreparePalette;
const
  Delete: array[0..19] of byte = (2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 34, 37, 40, 43, 46, 49, 52, 55, 58, 61);
var
  pal: TRSByteArray;
  i: int;
{$IFNDEF Heroes2}
  j: int;
{$ENDIF}
begin
  pal:= RSLoadFile(ChangeFileExt(PaletteName, '.pal'));
  for i := 0 to length(pal) - 1 do
    pal[i]:= pal[i]*4;
{$IFNDEF Heroes2}
  j:= 0;
  for i := 0 to 255 do
    if (j < 20) and (i = Delete[j]) then
      inc(j)
    else
      CopyMemory(@pal[(i - j)*3], @pal[i*3], 3);
  CopyMemory(@pal[30], @pal[0], (256 - 20)*3);
{$ENDIF}
  // Special colors
  FillMemory(@pal[0], 30, 0);
  FillMemory(@pal[246*3], 30, 0);
  pal[1]:= 255;
  pal[2]:= 255;
  pal[SpecialCode*3]:= 255;
  pal[SpecialCode*3 + 1]:= 255;
  pal[SpecialShdCode*3]:= 180;
  pal[SpecialShdCode*3 + 2]:= 255;
  pal[SpecialShdLCode*3 + 1]:= 255;
  for i := 0 to 3 do
  begin
    pal[ShadowCodes[i]*3]:= 255;
    pal[ShadowCodes[i]*3 + 1]:= 50*i;
    pal[ShadowCodes[i]*3 + 2]:= 255;
  end;
  for i := 4 to 15 do
  begin
    pal[ShadowCodes[i]*3]:= 201 - 16*(i - 4);
    pal[ShadowCodes[i]*3 + 1]:= 201 - 16*(i - 4);
    pal[ShadowCodes[i]*3 + 2]:= 255;
  end;

  with TBitmap.Create do
  begin
    PixelFormat:= pf8bit;
    Palette:= RSMakePalette(ptr(pal));
    Width:= 16;
    Height:= 16;
    for i := 0 to 255 do
      (PChar(Scanline[i div 16]) + i mod 16)^ := chr(i);
    SaveToFile(PaletteName);
    Free;
  end;
end;


const
  Info = AppName + ' v1.3.2'#13#10 +
         'Usage 1:  ' + AppName + '.exe Target.icn'#13#10 +
{$IFDEF Unpack}
         'Unpacks into "Target.icn.cadres" folder.'#13#10 +
         'File masks are supported. Use "*" to unpack all ICN files.'#13#10#13#10 +
         'Usage 2:  ' + AppName + '.exe InFolder [OutFolder]'#13#10 +
         'Extracts 1 frame of each ICN file into OutFolder.'#13#10 +
         'OutFolder defaults to "InFolder\Icn Preview".'#13#10#13#10 +
{$ELSE}
         'Usage 2:  ' + AppName + '.exe Target.icn.cadres'#13#10 +
         'Creates "Target.icn" using frames from "Target.icn.cadres" folder.'#13#10#13#10 +
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
    //PreparePalette; exit;
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
        s1:= s + 'Icn Preview\'
      else
        s1:= IncludeTrailingPathDelimiter(s1);
{$IFNDEF Heroes2}
      UnpackByMask(s + '*', s1);
{$ELSE}
      UnpackByMask(s + '*.icn', s1);
{$ENDIF}
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
    PackIcn(s, s1);
{$ENDIF}

    RSMessageBox(0, 'Operation succesful.', AppName, MB_ICONINFORMATION);
  except
    on e:Exception do
      Error(e.Message);
  end
end.
