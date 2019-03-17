unit RSDef;

{ *********************************************************************** }
{                                                                         }
{ Copyright (c) Rozhenko Sergey                                           }
{ http://sites.google.com/site/sergroj/                                   }
{ sergroj@mail.ru                                                         }
{                                                                         }
{ See copyright notice at the end of RSSysUtils.pas file (MIT license).   }
{                                                                         }
{ *********************************************************************** }
{$I RSPak.inc}

interface

uses
  Windows, Classes, Messages, SysUtils, RSSysUtils, RSQ, Graphics, RSDefLod,
  Math, RSGraphics, RTLConsts, IniFiles;

(*

Def format:
 <Header> { <Group> {Name} {Ptr} }   <Data>

Compressoins:
0   No special colors
1   255 special colors (only 8 are used)
2   7 special colors
3   7 special colors. Squares
Player's (blue) colors (found in some interface defs) aren't special in compression.

Code & Value meaning:
<255(7)   Special color number Code is repeated Value+1 times
255(7)    Then goes array of standard colors of Value+1 length

*)

type
  TLogPal = packed record
    palVersion: Word;
    palNumEntries: Word;
    palPalEntry: packed array[0..255] of TPaletteEntry;
  end;
  PLogPal = ^TLogPal;

  TRSDefWrapper = class;

  TRSPreparePaletteEvent = procedure(Sender: TRSDefWrapper; Pal:PLogPal)
                                                                    of object;

  TRSDefHeader = packed record
    TypeOfDef: int;
    Width: int;
    Height: int;
    GroupsCount: int;
    Palette: packed array [0..767] of Byte;
  end;
  PRSDefHeader = ^TRSDefHeader;

  TRSDefGroup = packed record
    GroupNum: int;
    ItemsCount: int;
    Unk2: int; // Big number (Runtime names array pointer)
    Unk3: int; // Another big number (Runtime offsets array pointer)
  end;
  PRSDefGroup = ^TRSDefGroup;

  TRSDefItemName = packed array[0..12] of char;
  PRSDefItemName = ^TRSDefItemName;
  TRSDefItemNames = packed array[0..MaxInt div SizeOf(TRSDefItemName) -1] of TRSDefItemName;
  PRSDefItemNames = ^TRSDefItemNames;
  TRSDefPointers = packed array[0..MaxInt div 4 -1] of DWord;
  PRSDefPointers = ^TRSDefPointers;

  TRSDefPic = packed record
    FileSize: int;
    Compression: int;
    Width: int;
    Height: int;
    FrameWidth: int;
    FrameHeight: int;
    FrameLeft: int;
    FrameTop: int;
  end;
  PRSDefPic = ^TRSDefPic;

  TRSDefWrapper = class(TObject)
  protected
    FUseCustomPalette: Boolean;
    FPicLinks: array of int;
    FPicNameLinks: array of PRSDefItemName;
    FPicturesCount: integer;
    FPal: PLogPalette;
    FPurePal: PLogPalette;
    FOnPreparePal: TRSPreparePaletteEvent;
    procedure PicLinksNeeded;
    procedure PicNameLinksNeeded;
    procedure DoExtractBuffer(Block:ptr; var PcxHdr:TRSDefPic;
                var Pic, Buffer, ShadowBuffer:ptr; BothBuffers:boolean);
    procedure DoExtractBmp(Block:ptr; Bmp, BmpSpec:TBitmap);
    function CreateExtractBmp(Block:ptr; Bmp, BmpSpec:TBitmap):TBitmap;
    procedure MakeFullBmp(Bmp, b1, b2:TBitmap);
    procedure DoExtractDefToolList(f:string; Pal:PLogPalette; Specials:string = '');
  public
    Header: PRSDefHeader;
    Groups: array of PRSDefGroup;
    ItemNames: array of PRSDefItemNames;
    ItemPointers: array of PRSDefPointers;
    Data: TRSByteArray;
    constructor Create(AData:TRSByteArray);
    destructor Destroy; override;
    function ExtractBmp(PicNum:integer; Bitmap:TBitmap=nil;
               BmpSpec:TBitmap=nil):TBitmap; overload;
    function ExtractBmp(Group, PicNum:integer; Bitmap:TBitmap=nil;
               BmpSpec:TBitmap=nil):TBitmap; overload;
      // If Bitmap is specified, changes it and returns as the result
      // Creates a bitmap otherwise
    function GetPicHeader(PicNum:integer):PRSDefPic; overload;
    function GetPicHeader(Group, PicNum:integer):PRSDefPic; overload;
    function GetPicName(PicNum:integer):string; overload;
    function GetPicName(Group, PicNum:integer):string; overload;
    procedure RebuildPal;
    function ExtractDefToolList(FileName: string; ExternalShadow: Boolean = false; In24Bits: Boolean = false): string;

    property PicturesCount: integer read FPicturesCount;
    property UseCustomPalette: Boolean read FUseCustomPalette write FUseCustomPalette;
    property OnPreparePalette:TRSPreparePaletteEvent read FOnPreparePal write FOnPreparePal;
    property DefPalette:PLogPalette read FPurePal;
  end;

  TRSPicBuffer = class(TObject)
  protected
    FPics: array of TBitmap;
    FFiles: TStrings;
  public
    Links: array of int;
    procedure Initialize(Files:TStrings);
    function LoadPic(i:int):TBitmap;
  end;

  TRSDefMaker = class(TObject)
  protected
    Groups: array of array of int;
    function PackBitmap(Bmp, Spec:TBitmap; Compr:int):TRSByteArray;
  public
    PicNames: array of string;
    Pics: array of TBitmap;
    PicsSpec: array of TBitmap;

    Compression: int;
    DefType: int;
    function AddPic(Name:string; Pic:TBitmap; PicSpec:TBitmap=nil):int;
    procedure AddItem(Group, PicNum:int);
    procedure Make(Stream:TStream);
  end;

  TMsk = packed record
    Width: byte;
    Height: byte;
    MaskObject: array[0..5] of byte; // Без учета тени [Not counting shadow]
    MaskShadow: array[0..5] of byte; // Без учета объекта [Not counting object]
  end;
  PMsk = ^TMsk;

const
  RSFullBmp = TBitmap(1);

resourcestring
  SRSInvalidDef = 'Def file is invalid';

procedure RSMakeMsk(Def:TRSDefWrapper; var Msk:TMsk); overload;
function RSMakeMsk(Def:TRSDefWrapper):TMsk; overload;
procedure RSMakeMsk(const DefFile:TRSByteArray; var Msk:TMsk); overload;
function RSMakeMsk(const DefFile:TRSByteArray):TMsk; overload;

implementation

uses Types;

constructor TRSDefWrapper.Create(AData:TRSByteArray);
var p, p1:PChar; i:int;
begin
  inherited Create;
  FUseCustomPalette:= true;
  Data:= AData;
  Header:= ptr(Data);
  p1:= PChar(Data) + length(Data);
  p:= @AData[SizeOf(TRSDefHeader)];
  if p > p1 then  raise EReadError.CreateRes(@SRSInvalidDef);

  SetLength(Groups, Header.GroupsCount);
  SetLength(ItemNames, Header.GroupsCount);
  SetLength(ItemPointers, Header.GroupsCount);
  for i:=0 to Header.GroupsCount-1 do
  begin
    Groups[i]:= ptr(p);
    inc(p, SizeOf(TRSDefGroup));
    if p > p1 then  raise EReadError.CreateRes(@SRSInvalidDef);

    ItemNames[i]:= ptr(p);
    inc(p, Groups[i].ItemsCount*SizeOf(TRSDefItemName));
    ItemPointers[i]:= ptr(p);
    inc(p, Groups[i].ItemsCount*4);
    inc(FPicturesCount, Groups[i].ItemsCount);
  end;
  if p > p1 then  raise EReadError.CreateRes(@SRSInvalidDef);
end;

destructor TRSDefWrapper.Destroy;
//var i:int;
begin
  if FPal<>nil then
    FreeMem(FPal);
  if FPurePal<>nil then
    FreeMem(FPurePal);
//  for i:=0 to length(ItemNames)-1 do ItemNames[i]:=nil;
//  for i:=0 to length(ItemPointers)-1 do ItemPointers[i]:=nil;
  inherited Destroy;
end;

procedure TRSDefWrapper.PicLinksNeeded;
var i,j,k:int;
begin
  if FPicLinks = nil then
  begin
    SetLength(FPicLinks, PicturesCount);
    k:=0;
    for i:=0 to length(Groups)-1 do
      for j:=0 to Groups[i].ItemsCount-1 do
      begin
        FPicLinks[k]:=ItemPointers[i][j];
        inc(k);
      end;
  end;
end;

procedure TRSDefWrapper.PicNameLinksNeeded;
var i,j,k:int;
begin
  if FPicNameLinks = nil then
  begin
    SetLength(FPicNameLinks, PicturesCount);
    k:=0;
    for i:=0 to length(Groups)-1 do
      for j:=0 to Groups[i].ItemsCount-1 do
      begin
        FPicNameLinks[k]:= @ItemNames[i][j];
        inc(k);
      end;
  end;
end;

function TRSDefWrapper.ExtractBmp(PicNum:integer; Bitmap:TBitmap=nil;
           BmpSpec:TBitmap=nil):TBitmap;
begin
  PicLinksNeeded;
  Result:= CreateExtractBmp(@Data[FPicLinks[PicNum]], Bitmap, BmpSpec);
end;

function TRSDefWrapper.ExtractBmp(Group, PicNum:integer;
           Bitmap:TBitmap=nil; BmpSpec:TBitmap=nil):TBitmap;
begin
  Result:= CreateExtractBmp(@Data[ItemPointers[Group][PicNum]], Bitmap,BmpSpec);
end;

function TRSDefWrapper.ExtractDefToolList(FileName: string; ExternalShadow,
  In24Bits: Boolean): string;
var
  Dir, ShadowDir: string;
  Bmp, BmpSpec: TBitmap;
  i: int;
begin
  ExternalShadow:= ExternalShadow and not (Header.TypeOfDef in [$40, $45, $46, $47]);
  Dir:= ExtractFilePath(FileName);

  ShadowDir:= '';
  if ExternalShadow then
  begin
    ShadowDir:= 'Shadow\';
    i:= 0;
    while FileExists(Dir + ShadowDir) do
    begin
      ShadowDir:= 'Shadow_' + IntToStr(i) + '\';
      inc(i);
    end;
  end;

  RSCreateDir(Dir + ShadowDir);

  DoExtractDefToolList(FileName, DefPalette, ShadowDir);

  Bmp:= nil;
  BmpSpec:= nil;
  Result:= '';
  ShadowDir:= Dir + ShadowDir;

  try
    Bmp:= TBitmap.Create;
    if ExternalShadow then
      BmpSpec:= TBitmap.Create;

    for i := 0 to PicturesCount - 1 do
      try
        ExtractBmp(i, Bmp, BmpSpec);
        if In24Bits then
          Bmp.PixelFormat:= pf24bit;
        Bmp.SaveToFile(Dir + ChangeFileExt(GetPicName(i), '.bmp'));
        if BmpSpec <> nil then
        begin
          if In24Bits then
            BmpSpec.PixelFormat:= pf24bit;
          BmpSpec.SaveToFile(ShadowDir + ChangeFileExt(GetPicName(i), '.bmp'));
        end;
      except
        on e:Exception do
          Result:= Result + e.Message + #13#10;
      end;

  finally
    Bmp.Free;
    BmpSpec.Free;
  end;
end;

function TRSDefWrapper.GetPicHeader(PicNum:integer):PRSDefPic;
begin
  PicLinksNeeded;
  Result:=PRSDefPic(@Data[FPicLinks[PicNum]]);
end;

function TRSDefWrapper.GetPicHeader(Group, PicNum:integer):PRSDefPic;
begin
  Result:=PRSDefPic(@Data[ItemPointers[Group][PicNum]]);
end;

function TRSDefWrapper.GetPicName(PicNum: integer): string;
begin
  PicNameLinksNeeded;
  Result:= FPicNameLinks[PicNum]^;
end;

function TRSDefWrapper.GetPicName(Group, PicNum: integer): string;
begin
  Result:= ItemNames[Group][PicNum];
end;

procedure TRSDefWrapper.RebuildPal;
begin
  if FPal<>nil then
    FreeMem(FPal);
  FPal:=RSMakeLogPalette(@Header.Palette[0]);
  if Assigned(FOnPreparePal) then FOnPreparePal(self, ptr(FPal));
end;



procedure FillBitmap(Bitmap:TBitmap; Value:Byte);
var p:PByte; i,dy,w,h:int;
begin
  w:=Bitmap.Width;
  h:=Bitmap.Height;
  if (w=0) or (h=0) then exit;
  p:=Bitmap.ScanLine[0];
  dy:= (w + 3) and not 3; // scanline length
  dy:=-dy;
  for i:=h-1 downto 0 do
  begin
    FillChar(p^, w, Value);
    inc(p, dy);
  end;
end;

  // Based on ConvertDefFileToBmpFile by Alexander Karpeko
procedure TRSDefWrapper.DoExtractBuffer(Block:ptr; var PcxHdr:TRSDefPic;
             var Pic, Buffer, ShadowBuffer:ptr; BothBuffers:boolean);
var
  Offsets:PIntegerArray;
  Offsets23:PWordArray;
  i, j, x, y: Integer;
  Buf, ShBuf: ptr;
  Code: Byte;    //Operation code.
  Value: Byte;   //Operand
  p, p1, p2:PByte;
begin
  Move(Block^, PcxHdr, SizeOf(PcxHdr));
  inc(PRSDefPic(Block));
  x := PcxHdr.Width;
  y := PcxHdr.Height;
  p:=Block;

   // For old format Defs: SGTWMTA.DEF and SGTWMTB.DEF
  with PcxHdr do
    if (FrameWidth>x) and (FrameHeight>y) and (Compression=1) then
    begin
      FrameLeft:=0;
      FrameTop:=0;
      FrameWidth:=x;
      FrameHeight:=y;
      dec(PByte(Block), 16);
    end else
    begin
      x:=FrameWidth;
      y:=FrameHeight;
    end;

  if PcxHdr.Compression<>0 then
  begin
    GetMem(Buf, x*y);
    if BothBuffers then
    begin
      GetMem(ShBuf, x*y);
      FillChar(Buf^, x*y, 0);
      FillChar(ShBuf^, x*y, 255);
    end else
      ShBuf:=Buf;
  end else
  begin
    Buf:=nil;
    ShBuf:=nil;
  end;

  try
    case PcxHdr.Compression of
      0:;

      1:
      begin
        Offsets:=Block;
        p1:=Buf;
        p2:=ShBuf;
        for j:=0 to y-1 do
        begin
          p:=Block;
          inc(p, Offsets[j]);
          i:=x;
          repeat
            Code:=p^;
            inc(p);
            Value:=p^;
            inc(p);
            if Code=255 then
            begin
              Move(p^, p1^, Value+1);
              inc(p, Value+1);
            end else
              FillChar(p2^, Value+1, Code);
            inc(p1, Value+1);
            inc(p2, Value+1);
            dec(i, Value+1);
          until i<=0;
          if i<0 then
          begin
            inc(p1, i);
            inc(p2, i);
          end;
        end;
      end;

      2, 3:
      begin
        if PcxHdr.Compression=3 then
        begin
          y:=y*(x div 32);
          x:=32;
        end;
        Offsets23:=Block;
        p1:=Buf;
        p2:=ShBuf;
        for j:=0 to y-1 do
        begin
          p:=Block;
          inc(p, Offsets23[j]);
          i:=x;
          repeat
            Value:=p^;
            inc(p);
            Code:= Value div 32;
            Value:= Value and 31 + 1;
            if Code=7 then
            begin
              Move(p^, p1^, Value);
              inc(p, Value);
            end else
            begin
              FillChar(p2^, Value, Code);
              if (Code = 5) and BothBuffers then // Flag color
                FillChar(p1^, Value, Code);
            end;
            inc(p1, Value);
            inc(p2, Value);
            dec(i, Value);
          until i<=0;
          if i<0 then
          begin
            inc(p1, i);
            inc(p2, i);
          end;
        end;
      end;

      else
        Assert(false);
    end;

    if Buf<>nil then
      p:=Buf;

    Pic:= p;
    Buffer:= Buf;
    ShadowBuffer:= ShBuf;

  except
    if ShBuf<>Buf then
      FreeMem(ShBuf, x*y);
    if Buf<>nil then
      FreeMem(Buf, x*y);
    raise;
  end;
end;


procedure TRSDefWrapper.DoExtractDefToolList(f: string; Pal: PLogPalette;
  Specials: string);

  function MakeGroup(g: int; Dir: string = ''):string;
  var i:int;
  begin
    Result:='';
    for i:=0 to Groups[g].ItemsCount-1 do
      Result:= Result + Dir + ChangeFileExt(GetPicName(g, i), '.bmp') + '|';
  end;

  function GetColorsString(low, high: int): string;
  var i:int;
  begin
    Result:= '';
    if FPurePal=nil then
      FPurePal:=RSMakeLogPalette(@Header.Palette[0]);
    for i := low to high do
      Result:= Result + '$' + IntToHex(int(FPurePal.palPalEntry[i]), 6) + '|';
  end;

const
  Sect = 'Data';
var
  ColorChecks: array[0..8] of Boolean;

  function GetChecksString(high: int): string;
  const BoolToStr: array[Boolean] of string = ('0', '1');
  var i:int;
  begin
    Result:= '';
    for i := 0 to high do
      Result:= Result + BoolToStr[ColorChecks[i]] + '|';
  end;

var
  s:string; i, n:int;
begin
  RSCreateDir(ExtractFilePath(f));
  DeleteFile(f);
  with TIniFile.Create(f) do
    try
      WriteInteger(Sect, 'Type', Header.TypeOfDef - $40);
      if Specials<>'' then
        i:=2
      else
        i:=0;

      WriteInteger(Sect, 'Shadow Type', i);
      n:= 0;
      for i:=0 to length(Groups)-1 do
      begin
        n:= max(n, Groups[i].GroupNum);
        WriteString(Sect, 'Group'+IntToStr(Groups[i].GroupNum), MakeGroup(i));
      end;
      if Specials<>'' then
        for i:=0 to length(Groups)-1 do
          WriteString(Sect, 'Shadow'+IntToStr(Groups[i].GroupNum), MakeGroup(i, Specials));
      WriteInteger(Sect, 'Groups Number', n+1);
      WriteBool(Sect, 'Generate Selection', false);

      // Color Boxes
      s:= GetColorsString(0, 7);
      WriteString(Sect, 'ColorsBox.Colors', s);
      WriteString(Sect, 'ShadowColorsBox.Colors', s);
      if Header.TypeOfDef = $47 then
        WriteString(Sect, 'ColorsBox.PlayerColors', GetColorsString(224, 255));

      ColorChecks[0]:= true;
      for i := 1 to 8 do
        ColorChecks[i]:= false;
      ColorChecks[5]:= (Header.TypeOfDef in [$43, $44]);
      if (Specials = '') and (Header.TypeOfDef = $42) then
        for i := 1 to 7 do
          ColorChecks[i]:= true;

      WriteString(Sect, 'ColorsBox.ColorChecks', GetChecksString(8));

      for i := 0 to 7 do
        ColorChecks[i]:= true;

      WriteString(Sect, 'ShadowColorsBox.ColorChecks', GetChecksString(7));

    finally
      Free;
    end;
end;

procedure TRSDefWrapper.DoExtractBmp(Block:ptr; Bmp, BmpSpec:TBitmap);
var
  PcxHdr: TRSDefPic;

  procedure InitBmp(Bmp:TBitmap);
  begin
    with Bmp do
    begin
      Width:=0;
      Height:=0;
      HandleType:=bmDIB;
      PixelFormat:=pf8bit;
    end;
  end;

  procedure BufToBmp(Bmp:TBitmap; Buf:ptr);
  begin
    with Bmp do
    begin
      Width:=PcxHdr.Width;
      Height:=PcxHdr.Height;
      FillBitmap(Bmp, 0);
      if Buf<>nil then
        with PcxHdr do
          RSBufferToBitmap(Buf, Bmp,
             Bounds(FrameLeft, FrameTop, FrameWidth, FrameHeight));
    end;
  end;

var
  Buf, ShBuf: ptr;
  Pal: HPalette;
begin
  DoExtractBuffer(Block, PcxHdr, Block, Buf, ShBuf, BmpSpec<>nil);
  try
    if Bmp<>nil then
    begin
      InitBmp(Bmp);

      if BmpSpec=nil then
      begin
        if FPal=nil then
          RebuildPal;
        Pal:=CreatePalette(FPal^);
      end else
      begin
        if FPurePal=nil then
          FPurePal:=RSMakeLogPalette(@Header.Palette[0]);
        Pal:=CreatePalette(FPurePal^);
      end;
      if Pal=0 then  RSRaiseLastOSError;
      Bmp.Palette:=Pal;

      BufToBmp(Bmp, Block);
    end;

    if BmpSpec<>nil then
    begin
      InitBmp(BmpSpec);
      if FPurePal=nil then
        FPurePal:=RSMakeLogPalette(@Header.Palette[0]);
      Pal:=CreatePalette(FPurePal^); // !!! use classical palette
      RSWin32Check(Pal);
      BmpSpec.Palette:= Pal;

      if ShBuf=nil then
      begin
        GetMem(ShBuf, PcxHdr.FrameWidth*PcxHdr.FrameHeight);
        FillMemory(ShBuf, PcxHdr.FrameWidth*PcxHdr.FrameHeight, 255);
      end;
      BufToBmp(BmpSpec, ShBuf);
    end;

  finally
    if ShBuf<>Buf then
      FreeMem(ShBuf);
    FreeMem(Buf);
  end;
end;

function TRSDefWrapper.CreateExtractBmp(Block:ptr; Bmp, BmpSpec:TBitmap):TBitmap;
var b1, b2:TBitmap;
begin
  if Bmp = RSFullBmp then
  begin
    Bmp:=BmpSpec;
    BmpSpec:=RSFullBmp;
    if Bmp = RSFullBmp then
      Bmp:=nil;
  end;

  if Bmp = nil then
    Result:=TBitmap.Create
  else
    Result:=Bmp;

  b1:=nil;
  b2:=nil;
  try
    if BmpSpec = RSFullBmp then
      try
        b1:=TBitmap.Create;
        b2:=TBitmap.Create;
        DoExtractBmp(Block, b1, b2);
        MakeFullBmp(Result, b1, b2);
      finally
        b1.Free;
        b2.Free;
      end
    else
      DoExtractBmp(Block, Result, BmpSpec);
  except
    if Bmp=nil then
      Result.Free;
    raise;
  end;
end;

function SwapColor(c:TColor):TColor;
asm
  bswap eax
  shr eax, 8
end;

procedure TRSDefWrapper.MakeFullBmp(Bmp, b1, b2:TBitmap);
var
  Pal1, Pal2: array[0..255] of int;
  i,j,w,h,dy:int; p:pint; p1, p2:pbyte;
begin
  w:=b1.Width;
  h:=b1.Height;
  with Bmp do
  begin
    PixelFormat:=pf32bit;
    HandleType:=bmDIB;
    Width:=w;
    Height:=h;
  end;
  if h = 0 then
    exit;
  if FPurePal=nil then
    FPurePal:=RSMakeLogPalette(@Header.Palette[0]);
  if FPal=nil then
    RebuildPal;
  for i:=0 to 255 do
  begin
    Pal1[i]:=SwapColor(int(FPurePal^.palPalEntry[i]));
    Pal2[i]:=SwapColor(int(FPal^.palPalEntry[i]));
  end;

  dy:= (-w) and 3;
  p:=Bmp.ScanLine[h-1];
  p1:=b1.ScanLine[h-1];
  p2:=b2.ScanLine[h-1];
  for j:=h downto 1 do
  begin
    for i:=w downto 1 do
    begin
      if p2^=255 then
        p^:=Pal1[p1^]
      else
        p^:=Pal2[p2^];
      inc(p);
      inc(p1);
      inc(p2);
    end;
    inc(p1, dy);
    inc(p2, dy);
  end;
  if Assigned(Bmp.OnChange) then
    Bmp.OnChange(Bmp);
end;


(*
  // Based on ConvertDefFileToBmpFile by Alexander Karpeko
function TRSDefWrapper.DoExtractBmp(Block:ptr; Bmp, BmpSpec:TBitmap):TBitmap;
var
  Offsets:PIntegerArray;
  Offsets23:PWordArray;
  i, j, x, y: Integer;
  Buf, ShBuf: ptr;
  Code: Byte;    //Operation code.
  Value: Byte;   //Operand
  Pal: HPalette;
  p, p1, p2:PByte;
  PcxHdr: TRSDefPic;
begin
  Move(Block^, PcxHdr, SizeOf(PcxHdr));
  inc(PRSDefPic(Block));
  x := PcxHdr.Width;
  y := PcxHdr.Height;
  p:=Block;

   // For old format Defs: SGTWMTA.DEF and SGTWMTB.DEF
  with PcxHdr do
    if (FrameWidth>x) and (FrameHeight>y) and (Compression=1) then
    begin
      FrameLeft:=0;
      FrameTop:=0;
      FrameWidth:=x;
      FrameHeight:=y;
      dec(PByte(Block), 16);
    end else
    begin
      x:=FrameWidth;
      y:=FrameHeight;
    end;

  if PcxHdr.Compression<>0 then
  begin
    GetMem(Buf, x*y);
    if BmpSpec<>nil then
    begin
      GetMem(ShBuf, x*y);
      FillChar(ShBuf^, x*y, 255);
    end else
      ShBuf:=Buf;
  end else
  begin
    Buf:=nil;
    ShBuf:=nil;
  end;

   // Fill Buffer

  try
    case PcxHdr.Compression of
      0:;

      1:
      begin
        Offsets:=Block;
        p1:=Buf;
        p2:=ShBuf;
        for j:=0 to y-1 do
        begin
          p:=Block;
          inc(p, Offsets[j]);
          i:=x;
          repeat
            Code:=p^;
            inc(p);
            Value:=p^;
            inc(p);
            if Code=255 then
            begin
              Move(p^, p1^, Value+1);
              inc(p, Value+1);
            end else
              FillChar(p2^, Value+1, Code);
            inc(p1, Value+1);
            inc(p2, Value+1);
            dec(i, Value+1);
          until i<=0;
          if i<0 then
          begin
            inc(p1, i);
            inc(p2, i);
          end;
        end;
      end;

      2, 3:
      begin
        if PcxHdr.Compression=3 then
        begin
          y:=y*(x div 32);
          x:=32;
        end;
        Offsets23:=Block;
        p1:=Buf;
        p2:=ShBuf;
        for j:=0 to y-1 do
        begin
          p:=Block;
          inc(p, Offsets23[j]);
          i:=x;
          repeat
            Value:=p^;
            inc(p);
            Code:= Value div 32;
            Value:= Value and 31 + 1;
            if Code=7 then
            begin
              Move(p^, p1^, Value);
              inc(p, Value);
            end else
              FillChar(p2^, Value, Code);
            inc(p1, Value);
            inc(p2, Value);
            dec(i, Value);
          until i<=0;
          if i<0 then
          begin
            inc(p1, i);
            inc(p2, i);
          end;
        end;
      end;

      else
        Assert(false);
    end;

     // Make Bitmaps

    if FPal=nil then
      RebuildPal;

    if Bmp=nil then
      Result:=TBitmap.Create
    else
      Result:=Bmp;

    if Buf<>nil then
      p:=Buf;
      
    with Result do
      try
        Width:=0;
        Height:=0;
        HandleType:=bmDIB;

        PixelFormat:=pf8bit;
        Pal:=CreatePalette(FPal^);
        if Pal=0 then RSRaiseLastOSError;
        Palette:=Pal;

        Width:=PcxHdr.Width;
        Height:=PcxHdr.Height;
        FillBitmap(Result, 0);
        with PcxHdr do
          BufferToBitmap(p, Result,
             Bounds(FrameLeft, FrameTop, FrameWidth, FrameHeight));
      except
        if Bmp=nil then Free;
        raise;
      end;

    if BmpSpec<>nil then
      with BmpSpec do
      begin
        Width:=0;
        Height:=0;
        HandleType:=bmDIB;
        PixelFormat:=pf8bit;

        Width:=PcxHdr.Width;
        Height:=PcxHdr.Height;
        FillBitmap(Result, 0);
        if ShBuf<>nil then
          with PcxHdr do
            BufferToBitmap(ShBuf, Result,
               Bounds(FrameLeft, FrameTop, FrameWidth, FrameHeight));
      end;

  finally
    if ShBuf<>Buf then
      FreeMem(ShBuf, x*y);
    FreeMem(Buf, x*y);
  end;
end;
*)

{------------------------------- TRSPicBuffer ---------------------------------}

procedure TRSPicBuffer.Initialize(Files:TStrings);
var i,j,k:int;
begin
  k:=Files.Count;
  FFiles:=Files;
  for i:=0 to length(FPics)-1 do
    FPics[i].Free;
  FPics:=nil;
  SetLength(FPics, k);
  SetLength(Links, k);
  for i:=0 to k-1 do
  begin
    Links[i]:=i;
    for j:=0 to i-1 do
      if SameText(ExpandFileName(Files[i]), ExpandFileName(Files[j])) then
      begin
        Links[i]:=j;
        break;
      end;
  end;
end;

function TRSPicBuffer.LoadPic(i:int):TBitmap;
begin
  i:=Links[i];
  if FPics[i]=nil then
  begin
    FPics[i]:=TBitmap.Create;
    FPics[i].LoadFromFile(FFiles[i]);
  end;
  Result:=FPics[i];
end;

{------------------------------- TRSDefMaker ----------------------------------}

procedure BufToShBuf(Buf:ptr; len:int; StdNum:int);
var p, p1:PByte;
begin
  p:=Buf;
  p1:=p;
  inc(p1, len);
  while DWord(p)<DWord(p1) do
  begin
    if p^>=StdNum then p^:=255;
    inc(p);
  end
end;

 // Length of sequence of normal or special pixels.
function SeqLength(Seq:ptr; MaxLen:int):int;
var p,p1:pbyte; b:byte;
begin
  p:=Seq;
  p1:=p;
  inc(p1, MaxLen);
  b:=p^;
  repeat
    inc(p);
  until (int(p)>=int(p1)) or (p^<>b);
  Result:= int(p) - int(Seq);
end;

function Add(var a:TRSByteArray; i:int):PByte;
var j:int;
begin
  j:=length(a);
  SetLength(a, j+i);
  Result:=@a[j];
end;

function TRSDefMaker.PackBitmap(Bmp, Spec:TBitmap; Compr:int):TRSByteArray;
var
  w,h,i,j,k:int; r:TRect; p,p1:PByte; Buf, ShBuf:PChar; b:byte;
begin
  Result:=nil;
  with Bmp do
  begin
    Assert(PixelFormat=pf8bit, 'Paletted bitmaps needed');
    HandleType:=bmDIB;
    w:=Width;
    h:=Height;
    if Compr=3 then
      Assert((w or h) and 31 = 0, 'Dimensions must devide by 32');
  end;
  if Spec<>nil then
    with Spec do
    begin
      Assert(PixelFormat=pf8bit, 'Paletted bitmaps needed');
      Assert((w=Width) and (h=Height));
      HandleType:=bmDIB;
    end;

   // Get Frame Rect 
  if Compr<>0 then
  begin
    if Spec<>nil then
      r:= RSGetNonZeroColorRect(Spec)
    else
      r:= RSGetNonZeroColorRect(Bmp);
        
    if Compr=3 then
    begin
      r.Left:=r.Left and not 31;
      r.Top:=r.Top and not 31;
      r.Right:=(r.Right+31) and not 31;
      r.Bottom:=(r.Bottom+31) and not 31;
    end;
  end else
    r:=Rect(0,0,w,h);

  with PRSDefPic(Add(Result, SizeOf(TRSDefPic)))^ do
  begin
    Compression:=Compr;
    Width:=w;
    Height:=h;
    w:=r.Right-r.Left;
    h:=r.Bottom-r.Top;
    FrameWidth:=w;
    FrameHeight:=h;
    FrameLeft:=r.Left;
    FrameTop:=r.Top;
    // FileSize is set in the end
  end;

  if w=0 then
  begin
    PRSDefPic(Result)^.FileSize:= length(Result)-SizeOf(TRSDefPic);
    exit;
  end;

   // Fill Buffers
  if Compr<>0 then
  begin
    GetMem(Buf, w*h);
    GetMem(ShBuf, w*h);
    RSBitmapToBuffer(Buf, Bmp, r);
    if Spec=nil then
    begin
      CopyMemory(ShBuf, Buf, w*h);
      if Compr=1 then
        BufToShBuf(ShBuf, w*h, 8)
      else
        BufToShBuf(ShBuf, w*h, 7);
    end else
      RSBitmapToBuffer(ShBuf, Spec, r);
  end else
  begin
    Buf:=nil;
    ShBuf:=nil;
  end;

   // Write buffers
  try
    case Compr of
      0:
        RSBitmapToBuffer(Add(Result, w*h), Bmp, r);

      1:
      begin
        Add(result, h*4);
        p:=ptr(Buf);
        p1:=ptr(ShBuf);
        for j:=0 to h-1 do
        begin
          pint(@Result[SizeOf(TRSDefPic)+j*4])^:=
             length(Result) - SizeOf(TRSDefPic);
          i:=w;
          repeat
            b:=p1^;
            Add(Result, 1)^:=b;
            k:=SeqLength(p1, min(256, i));
            Add(Result, 1)^:=k-1;
            if b = 255 then
              CopyMemory(Add(Result, k), p, k);
            dec(i, k);
            inc(p, k);
            inc(p1, k);
          until i=0;
        end;
      end;

      2,3:
      begin
        if Compr=3 then
        begin
          h:=h*(w div 32);
          w:=32;
        end;
        Add(result, h*2);
        p:=ptr(Buf);
        p1:=ptr(ShBuf);
        for j:=0 to h-1 do
        begin
          pword(@Result[SizeOf(TRSDefPic)+j*2])^:=
             length(Result) - SizeOf(TRSDefPic);
          i:=w;
          repeat
            b:=p1^;
            k:=SeqLength(p1, min(32, i));
            Add(Result, 1)^:=(k-1) or (b*32);
            if b>=7 then
              CopyMemory(Add(Result, k), p, k);
            dec(i,k);
            inc(p,k);
            inc(p1,k);
          until i=0;
        end;
      end;

    end;
  finally
    FreeMem(Buf);
    FreeMem(ShBuf);
  end;
  PRSDefPic(Result)^.FileSize:= length(Result)-SizeOf(TRSDefPic);
end;

procedure TRSDefMaker.Make(Stream:TStream);
var
  Header: TRSByteArray;
  PicData: array of TRSByteArray;
  Offsets: array of int;
  i, j:int; GrCount:int; p:pbyte;
begin
  Assert(length(Pics)>0, 'There must be at least one picture');

   // Calculate nonzero groups count & header size
  GrCount:=0;
  j:=SizeOf(TRSDefHeader);
  for i:=length(Groups)-1 downto 0 do
    if Groups[i]<>nil then
    begin
      inc(GrCount);
      inc(j, SizeOf(TRSDefGroup) + 17*length(Groups[i]));
    end;
  SetLength(Header, j);

   // Prepare pics
  SetLength(Offsets, length(Pics));
  SetLength(PicData, length(Pics));
  for i:=0 to length(Pics)-1 do
  begin
    PicData[i]:= PackBitmap(Pics[i], PicsSpec[i], Compression);
    Offsets[i]:= j;
    inc(j, length(PicData[i]));
  end;

   // Prepare Header
  with PRSDefHeader(Header)^ do
  begin
    TypeOfDef:=DefType;
    Width:=Pics[0].Width;
    Height:=Pics[0].Height;
    GroupsCount:=GrCount;
    RSWritePalette(@Palette, Pics[0].Palette);
  end;
  p:=@Header[SizeOf(TRSDefHeader)];
  for i:=0 to length(Groups)-1 do
    if Groups[i]<>nil then
    begin
      with PRSDefGroup(p)^ do
      begin
        GroupNum:=i;
        ItemsCount:=length(Groups[i]);
      end;
      inc(p, SizeOf(TRSDefGroup));
      for j:=0 to length(Groups[i])-1 do
      begin
        CopyMemory(p, ptr(PicNames[Groups[i][j]]),
                   min(13, length(PicNames[Groups[i][j]])+1));
        inc(p, SizeOf(TRSDefItemName));
      end;
      for j:=0 to length(Groups[i])-1 do
      begin
        pint(p)^:=Offsets[Groups[i][j]];
        inc(p, 4);
      end;
    end;

   // Write all
  Stream.WriteBuffer(Header[0], length(Header));
  for i:=0 to length(PicData)-1 do
    Stream.WriteBuffer(PicData[i][0], length(PicData[i]));
end;

function TRSDefMaker.AddPic(Name:string; Pic:TBitmap; PicSpec:TBitmap=nil):int;
var i:int;
begin
  i:=length(Pics);
  SetLength(Pics, i+1);
  SetLength(PicsSpec, i+1);
  SetLength(PicNames, i+1);
  Pics[i]:= Pic;
  PicsSpec[i]:= PicSpec;
  PicNames[i]:= Name;
  Result:=i;
end;

procedure TRSDefMaker.AddItem(Group, PicNum:int);
var i:int;
begin
  if length(Groups)<=Group then
    SetLength(Groups, Group+1);
  i:=length(Groups[Group]);
  SetLength(Groups[Group], i+1);
  Groups[Group][i]:= PicNum;
end;

{-------------------------------- RSMakeMSK -----------------------------------}

type
  TMyArray = array[0..255] of boolean;

function ProcessSquare(p:PByte; dy:int; var Colors:TMyArray):boolean;
var x,y:int;
begin
  Result:=true;
  for y:=32 downto 1 do
  begin
    for x:=32 downto 1 do
    begin
      dec(p);
      if Colors[p^] then exit;
    end;
    dec(p, dy - 32);
  end;
  Result:=false;
end;

procedure ProcessPic(b:TBitmap; Mask:PByteArray; var Colors:TMyArray);
var x,y,w,h,dy:int; p:PChar;
begin
  w:=b.Width;
  h:=b.Height;
  Assert((w mod 32 = 0) and (h mod 32 = 0));
  dy:=-w;
  p:= b.ScanLine[h-1];
  inc(p, w);
  for y:=0 to (h div 32) - 1 do
    for x:=0 to (w div 32) - 1 do
    begin
      if (Mask[5-y] and (1 shl (7-x)) = 0) and
          ProcessSquare(ptr( p - (x + y*dy)*32 ), dy, Colors) then
        Mask[5-y]:= Mask[5-y] or (1 shl (7-x));
    end;
end;

var
  ObjArray, ShArray:TMyArray; MskInitDone:boolean;

procedure RSMakeMsk(Def:TRSDefWrapper; var Msk:TMsk); overload;
var i:int; b:TBitmap;
begin
  if not MskInitDone then
  begin
    ShArray[1]:=true;
    ShArray[4]:=true;
    FillChar(ObjArray[5], 256 - 5, true);
    ObjArray[6]:=false;
    MskInitDone:=true;
  end;

  with Def.Header^ do
  begin
    Msk.Width:= Width div 32;
    Msk.Height:= Height div 32;
  end;
  Def.PicLinksNeeded;

  b:=TBitmap.Create;
  try
    for i:=0 to Def.PicturesCount-1 do
    begin
      with Def do
        DoExtractBmp(@Data[FPicLinks[i]], nil, b);

      ProcessPic(b, @Msk.MaskObject, ObjArray);
      ProcessPic(b, @Msk.MaskShadow, ShArray);
    end;
  finally
    b.Free;
  end;
end;

function RSMakeMsk(Def:TRSDefWrapper):TMsk; overload;
begin
  RSMakeMsk(Def, Result);
end;

procedure RSMakeMsk(const DefFile:TRSByteArray; var Msk:TMsk); overload;
var a:TRSDefWrapper;
begin
  a:=TRSDefWrapper.Create(DefFile);
  try
    RSMakeMsk(a, Msk);
  finally
    a.Free;
  end;
end;

function RSMakeMsk(const DefFile:TRSByteArray):TMsk; overload;
begin
  RSMakeMsk(DefFile, Result);
end;

end.
