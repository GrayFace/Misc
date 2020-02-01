unit LOD;

interface

uses
  Windows, Messages, SysUtils, Classes, zUnCompr, Zlib, Graphics, RSSysUtils,
  RSDefLod, RSQ, RSGraphics, RTLConsts;

type
  archinfo = record
    Len: Integer;
    RealLen: integer;
  end;
  Lodhead = packed record // заголовок LoD'а
    Header: longint; // Шапка "LOD"
    Unk: longint; // версия лода. Игнорируется
    HowMachFiles: longint; // сколько файлов в Lod'e
  end;
  PLodhead = ^Lodhead;
  TLodStruct = packed record // тип для чтения информации о файле
    NameFile: array[1..16] of char; // Имя файла. 0 в конце обязателен.
    StartSingleFile: Longint; // начало файла в лоде.
    LenSingleFile: Longint; // длина файла вне архива 
    Unk1: Longint; // Тип файла
    RealSize: Longint; // размер запакованного файла, 0 если файл не запакован.
  end;

(* Unk1:

Data 1  (H3C, XMI, IFR)
TXT  2
PCX  10-15

  bitmap8     10
  bitmap24    11
  bitmap16    12 (?)
  bitmap565   13 (?)
  bitmap555   14 (?)
  bitmap1555  15 (?)
    Bitmaps with 15 and 16 bits per pixel are not supported.

midi	30

DEF  def type (1st byte)
MSK  4f
FNT  50
PAL  60

Not very important. Used by Resource Manager for error reports.

*)

  TLOD = class(TObject)
  private
    function GetUserData(i:integer):pointer;
    procedure SetUserSize(v:integer);
  protected
    FLodFileName: string;
    FUserData: array of byte;
    FUserSize: integer;
    function PcxToBitmap(Pcx:TRSByteArray; Bitmap:TBitmap=nil):TBitmap;
    function PackBitmap(b:TBitmap; var ResType:int):TRSByteArray;
    function DoAdd(const Data:TRSByteArray; const Name:string; DataType:int):int;
    function CompareStr(s1, s2: PChar): int;
  public
    FFilesStruct: array of TLodStruct;
    FHead: Lodhead;
    FBuffer: TRSByteArray;
    procedure New;
    procedure Open; // Same as OpenLodFile, but with exceptions
    function Add(const Data:TRSByteArray; const Name:string):int; overload;
    function Add(Bitmap:TBitmap; const Name:string):int; overload;
    procedure Delete(Index:int);

    procedure ExtractFile(Number:Word; const SaveAsName:string=''); overload;
    procedure ExtractFile(const Name:string; const SaveAsName:string=''); overload;
    function ExtractSomeFile(Number:Word; const SaveAsName:string=''):boolean;
      // if SaveAsName='' then  Stay in Memory buffer without saving to disk
    function ExtractString(Number:Word):string;

    procedure BackupFile(const Name:string; OverwriteExisting:Boolean = false);

    function ConvPCXDump2Bitmap(Bitmap:TBitmap=nil):TBitmap;
    function GetFileName(i:integer):PChar;
    function FindNumberOfFile(const Filename: string): longint;
      // if file not found, -1-i is returned (which is equal to NOT i),
      // where i is the place where Filename should be inserted

    function OpenLodFile: boolean;
    function CreateEmptyLodFile(const Filename: string): boolean;
    function Arch(const FileNameForArchive, DestNameForArchive: string): archinfo;
    procedure ConvPCXFile2BMP(const PCXFile, BMPFile: string);
    procedure ConvPCXDump2BMP(const BMPFile: string);
    procedure ConvBMPFile2PCX(BMPFilename, TempPath: string);

    property LodFileName: string read FLodFileName write FLodFileName;
    property Count:integer read FHead.HowMachFiles write FHead.HowMachFiles;
    property UserData[i:integer]:pointer read GetUserData;
    property UserDataSize:integer read FUserSize write SetUserSize;
  end;

  ELodException = class(Exception)
  end;

type
  TFntHeader = packed record
    Unk1: array[0..4] of byte; // 1F FF 08 00 00 or 1E FF 08 00 00
    Height: int;
    Unk2: array[0..22] of byte; // Zeroes
    ABC: array[0..255] of TABC;
    Offsets: array[0..255] of int; // Relative to the end of header
  end;

procedure LoadModHommObj(const Data:TRSByteArray; var InternalName:string;
  var Def, Msk:TRSByteArray; var Txt:string);

//procedure FntGetBitmap:

implementation

type
  TPCXFileHeader = record
    ImageSize: longint;
    Width: longint;
    Height: longint;
  end;
  PPCXFileHeader = ^TPCXFileHeader;
   // Pcx Format: <Header> <Picture> <Palette>
   // The format is far form PCX in fact
   // Palette exists only if biSizeImage/(biWidth*biHeight) = 1

function TLOD.PackBitmap(b:TBitmap; var ResType:int):TRSByteArray;
var i,j:int; HasPal:boolean;
begin
  if b.PixelFormat <> pf8bit then
  begin
    b.PixelFormat:=pf24bit;
    i:=3;
    ResType:=$11;
  end else
  begin
    i:=1;
    ResType:=$10;
  end;

  HasPal:= i=1;
  i:= i * b.Width * b.Height;
  j:= i + SizeOf(TPCXFileHeader);
  if HasPal then
    SetLength(Result, j + 256*3)
  else
    SetLength(Result, j);

  with PPCXFileHeader(Result)^ do
  begin
    ImageSize:=i;
    Width:=b.Width;
    Height:=b.Height;
  end;
  RSBitmapToBuffer(@Result[SizeOf(TPCXFileHeader)], b, b.Canvas.ClipRect);

  if HasPal then
    RSWritePalette(@Result[j], b.Palette);
end;

function TLOD.PcxToBitmap(Pcx:TRSByteArray; Bitmap:TBitmap=nil):TBitmap;
var
  w, h, len, ByteCount:int;
begin
  with PPCXFileHeader(Pcx)^ do
  begin
    len:= ImageSize;
    w:= Width;
    h:= Height;
  end;
  if w*h <> 0 then
    ByteCount:= len div (w*h)
  else
    if length(Pcx) >= SizeOf(TPCXFileHeader) + 256*3 then
      ByteCount:= 1
    else
      ByteCount:= 3;
      
  Assert(ByteCount*w*h=len);
  Assert(ByteCount in [1,3] {, 'Unsupported bitmap type. Bits per pixel = '
                             + IntToStr(ByteCount*8)});
  if Bitmap=nil then
    Result:=TBitmap.Create
  else
    Result:=Bitmap;

  with Result do
    try
      Width:=0;
      Height:=0;

      case ByteCount of
        1: PixelFormat:=pf8bit;
        else PixelFormat:=pf24bit;
      end;

      if ByteCount=1 then
        Palette:=RSMakePalette(@Pcx[SizeOf(TPCXFileHeader) + len]);

      Width:=w;
      Height:=h;
      RSBufferToBitmap(@Pcx[SizeOf(TPCXFileHeader)], Result, Rect(0,0,w,h));

    except
      if Bitmap=nil then Free;
      raise;
    end;
end;

(*
function TLOD.ConvPcxStream2Bitmap(Pcx:TStream; Bitmap:TBitmap=nil):TBitmap;
var
  PcxHeader: TPCXFileHeader;
  PcxPal: array[0..767] of byte;
  HPal:HPalette; HasPal:boolean;
  i, w, h, len, dy, ByteCount:int;
  p:PByte;
begin
  Pcx.ReadBuffer(PcxHeader, SizeOf(PcxHeader));
  len:=PcxHeader.biSizeImage;
  w:=PcxHeader.biWidth;
  h:=PcxHeader.biHeight;
  ByteCount:=len div (w*h);
  Assert(ByteCount*w*h=len);
  Assert(ByteCount in [1,3], 'Unsupported bitmap type. Bits per pixel = '
                             + IntToStr(ByteCount*8));
  HasPal:= ByteCount=1;

  if Bitmap=nil then
    Result:=TBitmap.Create
  else
    Result:=Bitmap;

  with Result do
    try
      Width:=0;
      Height:=0;

      case ByteCount of
        1: PixelFormat:=pf8bit;
        else PixelFormat:=pf24bit;
      end;
      {
      if HasPal then
        PixelFormat:=pf8bit
      else
        PixelFormat:=pf24bit;
      }

      if HasPal then
      begin
        Pcx.Seek(len, soFromCurrent);
        Pcx.ReadBuffer(PcxPal, 768);
        HPal:=RSMakePalette(@PcxPal[0]);
        if HPal=0 then RaiseLastOSError;
        Palette:=HPal;
        Pcx.Seek(-768-len, soFromCurrent);
      end;


      Width:=w;
      Height:=h;
      if (w=0) or (h=0) then exit;
      p:=ScanLine[0];
      w:=w*ByteCount;
      dy:= (-w) and not 3;

      for i:=h-1 downto 0 do
      begin
        Pcx.ReadBuffer(p^, w);
        inc(p, dy);
      end;

    except
      if Bitmap=nil then Free;
      raise;
    end;
end;
*)

procedure TLOD.ConvPCXFile2BMP(const PCXFile, BMPFile: string);
begin
  with PcxToBitmap(RSLoadFile(PCXFile)) do
    try
      RSCreateDir(ExtractFilePath(BMPFile));
      FileSetReadOnly(BMPFile, false);
      SaveToFile(BMPFile);
    finally
      Free;
    end;
end;

procedure TLOD.ConvPCXDump2BMP(const BMPFile: string);
begin
  with PcxToBitmap(FBuffer) do
    try
      RSCreateDir(ExtractFilePath(BMPFile));
      FileSetReadOnly(BMPFile, false);
      SaveToFile(BMPFile);
    finally
      Free;
    end;
end;

function TLOD.ConvPCXDump2Bitmap(Bitmap:TBitmap=nil):TBitmap;
begin
  Result:=PcxToBitmap(FBuffer, Bitmap);
end;


function TLOD.CompareStr(s1, s2: PChar): int;
var
  a,b:int;
begin
  if s1 = nil then
    Result:= ord(s2 <> nil)
  else if s2 = nil then
    Result:= -1
  else
    while true do
    begin
      a:= ord(s1^);
      if a in [ord('A')..ord('Z')] then
        inc(a, ord('a') - ord('A'));
      b:= ord(s2^);
      if b in [ord('A')..ord('Z')] then
        inc(b, ord('a') - ord('A'));
      Result:= a - b;
      if (Result <> 0) or (a = 0) or (b = 0) then
        exit;

      inc(s1);
      inc(s2);
    end;
end;

procedure TLOD.ConvBMPFile2PCX(BMPFilename, TempPath: string);
var b:TBitmap; i:int;
begin
  b:=TBitmap.Create;
  try
    RSLoadBitmap(BMPFilename, b);
    RSSaveFile(TempPath, PackBitmap(b, i));
  finally
    b.Free;
  end;
end;

procedure TLOD.Open;
var b:boolean;
begin
  b:=false;
  with TFileStream.Create(FLodFileName, fmOpenRead or fmShareDenyNone) do
  try
    ReadBuffer(FHead, sizeof(FHead));
    Seek(92, 0);
    SetLength(FFilesStruct, Count);
    ReadBuffer(FFilesStruct[0], count*sizeof(TLodStruct));
    FUserData:=nil;
    SetLength(FUserData, FUserSize*Count);
    b:=true;
  finally
    if not b then Count:=0;
    Free;
  end;
end;

function TLOD.OpenLodFile: boolean;
begin
  try
    Open;
    Result:=true;
  except
    Result:=false;
  end;
{
  if fileexists(FLodFileName) then
  begin
    try
      InFile:=TFileStream.Create(FLodFileName, fmOpenRead or fmShareDenyNone);
      try
        InFile.ReadBuffer(FHead, sizeof(FHead));
        InFile.Seek(92, 0);
        SetLength(FFilesStruct, Count);
        InFile.ReadBuffer(FFilesStruct[0], count*sizeof(TLodStruct));
        FUserData:=nil;
        SetLength(FUserData, FUserSize*Count);
      finally
        InFile.Free;
      end;
      OpenLodFile:=True;
    except
      OpenLodFile:=False;
    end;
  end
  else
    OpenLodFile:=False;
}
end;

procedure MakeEmptyLod(const FileName: string);
var a:TRSByteArray;
begin
  SetLength(a, 92 + 320000);
  PLodHead(a)^.Header:=$444F4C;
  PLodHead(a)^.Unk:=$C8;
  RSSaveFile(FileName, a);
end;

function TLOD.CreateEmptyLodFile(const Filename: string): boolean;
begin
  try
    MakeEmptyLod(Filename);
    CreateEmptyLodFile:=True;
  except
    CreateEmptyLodFile:=False;
  end;
end;

procedure TLOD.New;
begin
  MakeEmptyLod(LodFileName);
  FHead.HowMachFiles:=0;
  FFilesStruct:=nil;
  FUserData:=nil;
end;


function TLoD.Arch(const FileNameForArchive, DestNameForArchive: string): Archinfo;
var
  temperrname: string;
  InFile, OutFile: Tstream;
  ZStream: TCustomZLibStream;
  buffer: array[1..50] of byte;
begin
  if ((uppercase(copy(extractfilename(FileNameForArchive),
    length(extractfilename(FileNameForArchive)) - 3, 4)) = '.MSK') or
    (uppercase(copy(extractfilename(FileNameForArchive),
    length(extractfilename(FileNameForArchive)) - 3, 4)) = '.MSG')) then
  begin
    InFile:=TFileStream.Create(FileNameForArchive, fmOpenRead);
    OutFile:=TFileStream.Create(DestNameForArchive, fmCreate);
    Arch.RealLen:=0;
    Arch.Len:=Infile.Size;
    InFile.Read(buffer, Infile.Size);
    OutFile.Write(buffer, Infile.Size);
    OutFile.Free;
    InFile.Free;
  end
  else
  begin
    temperrname:=FileNameForArchive;
    InFile:=TFileStream.Create(FileNameForArchive, fmOpenRead);
    OutFile:=TFileStream.Create(DestNameForArchive, fmCreate);
    ZStream:=TCompressionStream.Create(clFastest, OutFile);
    ZStream.CopyFrom(InFile, 0);
    ZStream.Free;
    Arch.RealLen:=Outfile.Size;
    OutFile.Free;
    Arch.Len:=Infile.Size;
    InFile.Free;
  end;
end;

function TLOD.DoAdd(const Data:TRSByteArray; const Name:string; DataType:int):int;
var fs:TFileStream; DataS, CompS:TStream; p,i,j:int; a:TRSByteArray;
begin
  Assert(length(Name)<16, 'File name length must not exceed 15 symbols');
  if length(Data)>16 then // Don't compress MSK, MSG
  begin
    DataS:=TRSArrayStream.Create(a);
    CompS:=nil;
    try
      CompS:=TCompressionStream.Create(zlib.clDefault, DataS);
      CompS.WriteBuffer(Data[0], length(Data));
    finally
      CompS.Free;
      DataS.Free;
    end;
    if length(a) >= length(Data) then
      a:= Data;
  end else
    a:=Data;

  Result:= FindNumberOfFile(Name);
  fs:= TFileStream.Create(LodFileName, fmOpenWrite);
  try
  
      // Insert

    if Result>=0 then // Already exists
    begin
      p:=FFilesStruct[Result].StartSingleFile;
      j:=FFilesStruct[Result].RealSize;
      if j=0 then
        j:=FFilesStruct[Result].LenSingleFile;

      if length(a)>j then
        if j<>0 then
        begin
          j:=p + length(a);
          for i:=0 to length(FFilesStruct)-1 do
            if (FFilesStruct[i].StartSingleFile > p) and
               (FFilesStruct[i].StartSingleFile < j) then
            begin
              p:=GetFileSize(fs.Handle, nil);
              break;
            end;
        end else
          p:=GetFileSize(fs.Handle, nil);

      j:=Result;
    end else
    begin
      j:= not Result;
      SetLength(FFilesStruct, length(FFilesStruct)+1);
      Move(FFilesStruct[j], FFilesStruct[j+1],
            (high(FFilesStruct)-j)*SizeOf(TLodStruct));
      if FUserSize<>0 then
      begin
        SetLength(FUserData, length(FUserData) + FUserSize);
        i:=j*FUserSize;
        Move(FUserData[i], FUserData[i + FUserSize],
              length(FUserData) - i - FUserSize);
        FillChar(FUserData[i], FUserSize, 0);
      end;
      inc(FHead.HowMachFiles);
      p:=GetFileSize(fs.Handle, nil);
    end;

     // Prepare Header

    with FFilesStruct[j] do
    begin
      CopyMemory(@NameFile, ptr(Name), length(Name)+1);
      StartSingleFile:=p;
      LenSingleFile:=length(Data);
      if ptr(a)<>ptr(Data) then
        RealSize:=length(a)
      else
        RealSize:=0;
      Unk1:=DataType;
    end;

     // Write

    with fs do
    begin
      Seek(p, 0);
      WriteBuffer(ptr(a)^, length(a));
      Seek(0, 0);
      WriteBuffer(FHead, SizeOf(FHead));
      Seek(92, 0);
      WriteBuffer(FFilesStruct[0], length(FFilesStruct)*SizeOf(TLodStruct));
    end;

  finally
    fs.Free;
  end;
end;

function TLOD.Add(const Data:TRSByteArray; const Name:string):int;
const
  aTXT = 1415074862;  aDEF = 1178944558;  aMSK = 1263750446;
  aFNT = 1414415918;  aPAL = 1279348782;  aMSG = 1196641582;
var s:string; i:int;
begin
  s:=UpperCase(ExtractFileExt(Name));
  if length(s)=4 then
    case pint(s)^ of
      aTXT:  i:=2;
      aFNT:  i:=$50;
      aPAL:  i:=$60;
      aMSK, aMSG:  i:=$4f;
      aDEF:
        if length(Data)>=4 then
          i:=pint(Data)^
        else
          i:=1;
          
      else  i:=1;
    end
  else
    i:=1;
    
  Result:=DoAdd(Data, Name, i);
end;

function TLOD.Add(Bitmap:TBitmap; const Name:string):int;
var a:TRSByteArray; i:int;
begin
  a:=PackBitmap(Bitmap, i);
  Result:=DoAdd(a, Name, i);
end;

procedure TLOD.Delete(Index:int);
var fs:TFileStream; j:int;
begin
  j:=Index;
  CopyMemory(@FFilesStruct[j], @FFilesStruct[j+1],
        (high(FFilesStruct)-j)*SizeOf(TLodStruct));
  FillChar(FFilesStruct[high(FFilesStruct)], SizeOf(TLodStruct), 0);
  dec(FHead.HowMachFiles);
  j:=j*FUserSize;
  CopyMemory(@FUserData[j], @FUserData[j+FUserSize], length(FUserData) - j - FUserSize);
  SetLength(FUserData, length(FUserData) - FUserSize);

  fs:=TFileStream.Create(LodFileName, fmOpenWrite);
  with fs do
    try
      WriteBuffer(FHead, SizeOf(FHead));
      Seek(92, 0);
      WriteBuffer(FFilesStruct[0], length(FFilesStruct)*SizeOf(TLodStruct));
    finally
      Free;
      SetLength(FFilesStruct, high(FFilesStruct));
    end;
end;

procedure TLoD.ExtractFile(Number:Word; const SaveAsName:string='');
var
  InFile: TStream;
  ZStream: TCustomZLibStream;
  sizebuffer: longint;
begin
  if (Number>=Count) {or (Number<0)} then
    raise ELodException.CreateFmt(SListIndexError, [Number]);
  ZStream:=nil;
  InFile:=TFileStream.Create(FLodFileName, fmOpenRead or fmShareDenyNone);
  try
    Infile.Seek(FFilesStruct[Number].StartSingleFile, 0);
    FBuffer:=nil;
    sizebuffer:=FFilesStruct[Number].LenSingleFile;
    SetLength(FBuffer, sizebuffer);
    if FFilesStruct[Number].realsize <> 0 then
    begin
      ZStream:=TDecompressionStream.Create(InFile);
      ZStream.Read(FBuffer[0], sizebuffer);
    end else
      Infile.Read(FBuffer[0], sizebuffer)
  finally
    infile.Free;
    ZStream.Free;
  end;

  if SaveAsName <> '' then
    RSSaveFile(SaveAsName, FBuffer);
end;

procedure TLOD.ExtractFile(const Name, SaveAsName: string);
begin
  ExtractFile(FindNumberOfFile(Name), SaveAsName);
end;

function TLoD.ExtractSomeFile(Number:Word; const SaveAsName:string=''):boolean;
begin
  try
    ExtractFile(Number, SaveAsName);
    Result:=true;
  except
    Result:=false;
  end;
end;

function TLoD.ExtractString(Number:Word):string;
begin
  ExtractFile(Number);
  Result:= '';
  SetLength(Result, length(FBuffer));
  CopyMemory(ptr(Result), ptr(FBuffer), length(FBuffer));
end;

function TLoD.GetFileName(i:integer):PChar;
begin
  Result:=@FFilesStruct[i].NameFile;
end;

function TLoD.FindNumberOfFile(const Filename: string): longint;
var
  L, H, I, C: Integer; Present:boolean;
begin
  Present := False;
  L := 0;
  H := Count - 1;
  while L <= H do
  begin
    I := (L + H) shr 1;
    C := CompareStr(GetFileName(I), ptr(Filename));
    if C < 0 then
      L := I + 1
    else
    begin
      H := I - 1;
      if C = 0 then
      begin
        Present := True;
        L := I;
      end;
    end;
  end;
  if Present then
    Result := L
  else
    Result := not L; // = -L-1
end;

function TLoD.GetUserData(i:integer):pointer;
begin
  if FUserSize=0 then
    Result:=nil
  else
    Result:=@FUserData[FUserSize*i];
end;

procedure TLoD.SetUserSize(v:integer);
begin
  if v=FUserSize then exit;
  FUserSize:=v;
  FUserData:=nil;
  SetLength(FUserData, v*Count);
end;

procedure ReadZip(Stream:TStream; Buf:ptr; Size:int);
var ZStream: TCustomZLibStream;
begin
  ZStream:= TDecompressionStream.Create(Stream);
  try
    ZStream.Read(Buf^, Size);
  finally
    ZStream.Free;
  end;
end;

procedure LoadModHommObj(const Data:TRSByteArray; var InternalName:string;
   var Def, Msk:TRSByteArray; var Txt:string);
var
  InStream: TStream;
  i:int; p, PSize:PChar;

  procedure Next(const Ext:string);
  begin
    while not CompareMem(p, ptr(InternalName), i) or
      (CompareString(LOCALE_USER_DEFAULT, 1, p + i, 4, ptr(Ext), 4) <> 2) do
    begin
      while p^<>#0 do  inc(p);
      inc(p);
    end;
    inc(p, i + 4);
    inc(PSize, i + 8);
    InStream.Seek(p - PChar(Data), 0);
  end;

begin
  p:= ptr(Data);
  while p^<>'.' do  inc(p);
  i:= p - PChar(Data);
  SetString(InternalName, PChar(Data), i);

  p:= @Data[i + 4];
  PSize:= PChar(Data) + length(Data) - 4;
  dec(PSize, (i + 8)*2);

  InStream:= TRSArrayStream.Create(PRSByteArray(@Data)^);
  try
    InStream.Seek(p - PChar(Data), 0);
    SetLength(Def, pint(PSize)^);
    ReadZip(InStream, Def, pint(PSize)^);

    Next('.msk');
    SetLength(Msk, pint(PSize)^);
    ReadZip(InStream, Msk, pint(PSize)^);

    Next('.txt');
    SetLength(Txt, pint(PSize)^);
    ReadZip(InStream, ptr(Txt), pint(PSize)^);

  finally
    InStream.Free;
  end;
end;

procedure TLOD.BackupFile(const Name: string; OverwriteExisting: Boolean);
var i:int; s:string;
begin
  i:= FindNumberOfFile(Name);
  if i>=0 then
    try
      if SameText(ExtractFileExt(Name), '.pcx') then
      begin
        s:= LodFileName + ' Backup\' + ChangeFileExt(Name, '.bmp');
        if OverwriteExisting or not FileExists(s) then
        begin
          ExtractFile(i);
          ConvPCXDump2BMP(s);
        end;
      end else
      begin
        s:= LodFileName + ' Backup\' + Name;
        if OverwriteExisting or not FileExists(s) then
          ExtractFile(i, s);
      end;
    except
    end;
end;

end.
