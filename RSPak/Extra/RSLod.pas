unit RSLod;

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
  Windows, Classes, Messages, SysUtils, RSSysUtils, RSQ, Consts, Graphics,
  {ZLib}dzlib, Math, RSDefLod, RSGraphics, RSStrUtils, Types;

type
(*
Lod format:
 <Header> { <DirItem> }   <Data...>
*)
  ERSLodException = class(Exception)
  end;
  ERSLodWrongFileName = class(ERSLodException)
  end; // too long file name
  ERSLodBitmapException = class(ERSLodException)
  end; // error in bitmap palette or dimensions

  TRSLodVersion = (RSLodHeroes, RSLodBitmaps, RSLodIcons, RSLodSprites,
    RSLodGames, RSLodGames7, RSLodChapter, RSLodChapter7, RSLodMM8);

  TRSLodHeroesHeader = packed record
    Signature: array[0..3] of char;
    Version: DWord;
    Count: DWord;
    Unknown: array[0..79] of char;
  end;
  PRSLodHeroesHeader = ^TRSLodHeroesHeader;

  TRSLodMMHeader = packed record
    Signature: array[0..3] of char;
    Version: array[0..79] of char;
    Description: array[0..79] of char;
    Unk1: int; // 100 (version)
    Unk2: int; // 0
    ArchivesCount: int; // 1 (archives count)
    Unknown: array[0..79] of char;
    LodType: array[0..15] of char;
    ArchiveStart: DWord;
    ArchiveSize: DWord;
    Unk5: int; // 0 (bits)
    Count: uint2;
    Unk6: uint2; // 0 (type of data)
  end;
  PRSLodMMHeader = ^TRSLodMMHeader;


  TRSMMFilesOptions = record
    // Lod Entry properties
    NameSize: int;
    AddrOffset: int;
    SizeOffset: int;
    UnpackedSizeOffset: int;
    PackedSizeOffset: int;
    ItemSize: int;

    // Lod properties
    DataStart: uint;
    AddrStart: uint;
    MinFileSize: uint;
  end;

type
  TRSMMFiles = class;

  TRSMMFilesReadHeaderEvent = procedure(Sender: TRSMMFiles; Stream: TStream;
     var Options: TRSMMFilesOptions; var FilesCount: Integer) of object;
  TRSMMFilesWriteHeaderEvent = procedure(Sender: TRSMMFiles; Stream: TStream) of object;
  TRSMMFilesProcessEvent = procedure(Sender: TRSMMFiles; FileName: string;
     var Stream: TStream; var Size: Integer) of object;
  TRSMMFilesGetFileSizeEvent = procedure(Sender: TRSMMFiles; Index: Integer;
     var Size: Integer) of object;
  TRSMMFilesSetFileSizeEvent = procedure(Sender: TRSMMFiles; Index: Integer;
     Size: Integer) of object;
  TRSMMFilesFileEvent = procedure(Sender: TRSMMFiles; Index: Integer) of object;

// !!! Add 'Processing' exceptions for all public members
  TRSMMFiles = class(TObject)
  private
    FOnReadHeader: TRSMMFilesReadHeaderEvent;
    FOnWriteHeader: TRSMMFilesWriteHeaderEvent;
    FOnGetFileSize: TRSMMFilesGetFileSizeEvent;
    FOnBeforeReplaceFile: TRSMMFilesFileEvent;
    FOnBeforeDeleteFile: TRSMMFilesFileEvent;
    FOnAfterRenameFile: TRSMMFilesFileEvent;
    FIgnoreUnzipErrors: Boolean;
    FOnSetFileSize: TRSMMFilesSetFileSizeEvent;
    procedure SetWriteOnDemand(v: Boolean);
    function GetUserData(i: int): ptr;
    procedure SetUserDataSize(v: int);
    function GetAddress(i: int): uint;
    function GetIsPacked(i: int): Boolean;
    function GetName(i: int): PChar;
    function GetSize(i: int): int;
    function GetUnpackedSize(i: int): int;
  protected
    FOptions: TRSMMFilesOptions;

    // Files
    FInFile: string;
    FOutFile: string;
    FWriteStream: TStream;
    FWritesCount: int;
    FBlockStream: TStream;
    FFileTime: int64;

    // Files properties
    FBlockInFile: Boolean;
    FWriteOnDemand: Boolean;

    // Fields
    FData: TRSByteArray;
    FCount: int;
    FFileSize: uint;
    FFileBuffers: array of TMemoryStream;
    FSorted: Boolean;
    FGamesLod: Boolean; // must preserve order of odm/blv files at archive
                        // beginning for Lloyd, but sort dlv/ddm alphabetically

    FUserData: TRSByteArray;
    FUserDataSize: int;

    procedure DoDelete(i: int; NoWrite: Boolean = false);
    //function GetFileSpace(Index: int): int;
    function CanExpand(Index, aSize: uint): Boolean;
    procedure ReadHeader;
    procedure WriteHeader;
    procedure DoWriteFile(Index:int; Data:TStream; Size, Addr:uint;
       ForceWrite: Boolean = false);
    procedure DoMoveFile(Index:int; Addr:int);
    function BeginRead: TStream;
    procedure EndRead(Stream: TStream);
    function BeginWrite: TStream;
    procedure EndWrite;
    procedure InsertData(var Data:TRSByteArray; Index, ItemSize:int);
    procedure RemoveData(var Data:TRSByteArray; Index, ItemSize:int);
    procedure CalculateFileSize;
    procedure SaveAsNoBlock(const FileName: string);
    function IsBlvOrOdm(const Name: string): Boolean;
    function FindFileBinSearch(const Name: PChar; var Index: int; L, H: int): Boolean; overload;
    function FindAddIndex(const Name: string; var Index: int): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure New(const FileName: string; const Options: TRSMMFilesOptions);
    procedure Load(const FileName: string);
    procedure AssignStream(fs: TStream);  // hackish way to load from foreign stream
    procedure DoSave;  // force save
    procedure Save;
    procedure SaveAs(const FileName: string);
    procedure Rebuild;
    procedure Close;
    function CloneForProcessing(const NewFile: string; FilesCount: int): TRSMMFiles;
    procedure MergeTo(Files: TRSMMFiles);

    function Add(const Name: string; Data: TStream; Size: int = -1;
       Compression: TCompressionLevel = clDefault; UnpackedSize: int = -1): int;
    procedure Delete(i:int); overload;
    procedure Delete(const Name: string); overload;
    procedure Delete(const Name: PChar); overload;
    function Rename(Index: int; const NewName: string): int;
    procedure CheckName(const Name: string);
    function FindFile(const Name: string; var Index: int): Boolean; overload;
    function FindFile(const Name: PChar; var Index: int): Boolean; overload;
    function GetAsIsFileStream(Index: int; IgnoreWrite: Boolean = false): TStream;
    procedure FreeAsIsFileStream(Index: int; Stream: TStream);
    procedure RawExtract(i: int; a: TStream);
    procedure ReserveFilesCount(n: int);

    function CheckFileChanged: Boolean;

    property Name[i: int]: PChar read GetName;
    property Address[i: int]: uint read GetAddress;
    property Size[i: int]: int read GetSize;
    property UnpackedSize[i: int]: int read GetUnpackedSize;
    property IsPacked[i: int]: Boolean read GetIsPacked;
    property UserData[i: int]: ptr read GetUserData;
    property Count: int read FCount;
    property ArchiveSize: uint read FFileSize;
    property Options: TRSMMFilesOptions read FOptions;
    property UserDataSize: int read FUserDataSize write SetUserDataSize;
    property WriteOnDemand: Boolean read FWriteOnDemand write SetWriteOnDemand;
    property FileName: string read FOutFile;
    property Sorted: Boolean read FSorted;
    property IgnoreUnzipErrors: Boolean read FIgnoreUnzipErrors write FIgnoreUnzipErrors;

    property OnReadHeader: TRSMMFilesReadHeaderEvent read FOnReadHeader write FOnReadHeader;
    property OnWriteHeader: TRSMMFilesWriteHeaderEvent read FOnWriteHeader write FOnWriteHeader;
    property OnGetFileSize: TRSMMFilesGetFileSizeEvent read FOnGetFileSize write FOnGetFileSize;
    property OnSetFileSize: TRSMMFilesSetFileSizeEvent read FOnSetFileSize write FOnSetFileSize;
    property OnBeforeReplaceFile: TRSMMFilesFileEvent read FOnBeforeReplaceFile write FOnBeforeReplaceFile;
    property OnBeforeDeleteFile: TRSMMFilesFileEvent read FOnBeforeDeleteFile write FOnBeforeDeleteFile;
    property OnAfterRenameFile: TRSMMFilesFileEvent read FOnAfterRenameFile write FOnAfterRenameFile;
  end;

  
  TRSArchive = class(TObject)
  protected
    function GetCount: int; virtual; abstract;
    function GetFileName(i: int): PChar; virtual; abstract;
  public
    constructor Create; overload; virtual; abstract;
    constructor Create(const FileName: string); overload;
    procedure Load(const FileName: string); virtual; abstract;
    procedure SaveAs(const FileName: string); virtual; abstract;

    property Count: int read GetCount;
    property Names[i: int]: PChar read GetFileName;
  end;


  TRSMMArchive = class(TRSArchive)
  private
    FBackupOnAdd: Boolean;
    FBackupOnAddOverwrite: Boolean;
    FBackupOnDelete: Boolean;
    FBackupOnDeleteOverwrite: Boolean;
  protected
    FFiles: TRSMMFiles;
    FTagSize: int;

    constructor CreateInternal(Files: TRSMMFiles); virtual;

    function GetCount: int; override;
    function GetFileName(i: int): PChar; override;
    procedure ReadHeader(Sender: TRSMMFiles; Stream: TStream;
       var Options: TRSMMFilesOptions; var FilesCount: int); virtual; abstract;
    procedure WriteHeader(Sender: TRSMMFiles; Stream: TStream); virtual; abstract;
    function DoExtract(Index: int; const FileName: string; Overwrite: Boolean = true): string;
    function MakeBackupDir: string;
    procedure DoBackupFile(Index: int; Overwrite:Boolean); virtual;
    procedure BeforeReplaceFile(Sender: TRSMMFiles; Index: int);
    procedure BeforeDeleteFile(Sender: TRSMMFiles; Index: int);
  public
    constructor Create; override;
    destructor Destroy; override;

    function Add(const Name: string; Data: TStream; Size: int = -1; pal: int = 0): int; overload; virtual;
    function Add(const Name: string; Data: TRSByteArray; pal: int = 0): int; overload; // virtual;
    function Add(const FileName: string; pal: int = 0): int; overload; // virtual;
    function Add(const FileName: string; Data: string): int; overload; // virtual;
    function Extract(Index: int; const Dir: string; Overwrite: Boolean = true): string; overload; virtual;
    function Extract(Index: int; Output: TStream): string; overload; virtual;
    function Extract(Index: int): TObject; overload; virtual;
    function ExtractArrayOrBmp(Index: int; var Arr: TRSByteArray): TBitmap; virtual;
    function ExtractArray(Index: int): TRSByteArray;
    function ExtractString(Index: int): string;
    function GetExtractName(Index: int): string; virtual;
    function BackupFile(Index: int; Overwrite:Boolean): Boolean;
    function CloneForProcessing(const NewFile: string; FilesCount: int = 0): TRSMMArchive; virtual;
    procedure Load(const FileName: string); override;
    procedure SaveAs(const FileName: string); override;

    property RawFiles: TRSMMFiles read FFiles;
    property BackupOnAdd: Boolean read FBackupOnAdd write FBackupOnAdd;
    property BackupOnAddOverwrite: Boolean read FBackupOnAddOverwrite write FBackupOnAddOverwrite;
    property BackupOnDelete: Boolean read FBackupOnDelete write FBackupOnDelete;
    property BackupOnDeleteOverwrite: Boolean read FBackupOnDeleteOverwrite write FBackupOnDeleteOverwrite;
  end;

  TRSMMArchivesArray = array of TRSMMArchive;


  TRSLodBase = class(TRSMMArchive)
  private
    FAnyHeader: array[0..SizeOf(TRSLodMMHeader)-1] of byte;
  protected
    FMMHeader: PRSLodMMHeader;
    FHeroesHeader: PRSLodHeroesHeader;
    FAdditionalData: TRSByteArray;
    FVersion: TRSLodVersion;

    constructor CreateInternal(Files: TRSMMFiles); override;
    procedure InitOptions(var Options: TRSMMFilesOptions);
    procedure ReadHeader(Sender: TRSMMFiles; Stream: TStream;
       var Options: TRSMMFilesOptions; var FilesCount: int); override;
    procedure WriteHeader(Sender: TRSMMFiles; Stream: TStream); override;
    procedure WriteGamesLod7Sig(Sender: TRSMMFiles; Stream: TStream);
    procedure AfterRenameFile(Sender: TRSMMFiles; Index: int);
  public
    function GetExtractName(Index: int): string; override;
    function CloneForProcessing(const NewFile: string; FilesCount: int): TRSMMArchive; override;
    procedure New(const FileName: string; AVersion: TRSLodVersion);
    procedure Load(const FileName: string); override;

    property Version: TRSLodVersion read FVersion write FVersion;  // !!! setting it may be dangerous
  end;


  TRSLod = class;

  TRSLodSpritePaletteEvent = procedure(Sender: TRSLod; Name: string; var pal: Smallint; var Data) of object;
  TRSLodNeedPaletteEvent = procedure(Sender: TRSLod; Bitmap: TBitmap; var Palette: Integer) of object;
  TRSLodConvertPaletteEvent = procedure(Sender: TRSLod; Bitmap, BmpResult: TBitmap) of object;
  //TRSLodExtractPaletteEvent = procedure(Sender: TRSLod; ) of object;

  TRSLod = class(TRSLodBase)
  private
    FOwnBitmapsLod: Boolean;
    FOnNeedBitmapsLod: TNotifyEvent;
    FOnNeedPalette: TRSLodNeedPaletteEvent;
    FOnConvertToPalette: TRSLodConvertPaletteEvent;
    FOnSpritePalette: TRSLodSpritePaletteEvent;
    FLastPalette: int;
    function GetBitmapsLod: TRSLod;
    procedure SetBitmapsLod(v: TRSLod);
  protected
    constructor CreateInternal(Files: TRSMMFiles); override;

    function GetIntAt(i: int; o: int): int;
    procedure PackSprite(b: TBitmap; m: TMemoryStream; pal: int);
    procedure FindBitmapPalette(const name: string; b: TBitmap; var pal, Bits: int); virtual;
    procedure DoPackBitmap(b: TBitmap; var b1, b2: TBitmap; var hdr; m, buf: TMemoryStream; Keep: Boolean); virtual;
    procedure PackBitmap(b: TBitmap; m: TMemoryStream; pal, ABits: int; Keep: Boolean);
    procedure PackStr(m: TMemoryStream; Data: TStream; Size: int); // STR converted by mm8leveleditor
    function PackPcx(b: TBitmap; m: TMemoryStream; KeepBmp: Boolean): int;
    procedure Zip(output:TMemoryStream; buf:TStream; size: int; pk, unp: int); overload;
    procedure Zip(output:TMemoryStream; buf:TStream; size: int;
       DataSize, UnpackedSize: ptr); overload;

    procedure Unzip(input, output: TStream; size, unp: int; noless: Boolean);
    procedure UnpackPcx(data: TMemoryStream; b: TBitmap);
    procedure UnpackBitmap(data: TStream; b: TBitmap; const FileHeader); virtual;
    procedure UnpackSprite(const name: string; data: TStream; b: TBitmap; size: int);
    procedure UnpackStr(a, Output:TStream; const FileHeader);

    function AddBitmap(const Name: string; b: TBitmap; pal: int; Keep: Boolean;
      Bits: int = -1): int;
    function DoExtract(i: int; Output: TStream = nil; Arr: PRSByteArray = nil;
      FileName: PStr = nil; CheckNameKind: int = 0):TObject; overload;
    procedure DoBackupFile(Index: int; Overwrite: Boolean); override;
    function IsSamePalette(const PalEntries; i: int): Boolean;
    procedure StdNeedBitmapsLod(Sender: TObject);
  public
    BitmapsLods: TRSMMArchivesArray;

    destructor Destroy; override;
    function Add(const Name: string; Data: TStream; Size: int = -1; pal: int = 0): int; override;
    function Add(const Name: string; b: TBitmap; pal: int = 0): int; overload;
    function Extract(Index: int; const Dir: string; Overwrite: Boolean = true): string; override;
    function Extract(Index: int; Output: TStream): string; override;
    function Extract(Index: int): TObject; override;
    function ExtractArrayOrBmp(Index: int; var Arr: TRSByteArray): TBitmap; override;
    function GetExtractName(Index: int): string; override;
    function CloneForProcessing(const NewFile: string; FilesCount: int): TRSMMArchive; override;
    function FindSamePalette(const PalEntries; var pal: int): Boolean;
    procedure LoadBitmapsLods(const dir: string);

    property BitmapsLod: TRSLod read GetBitmapsLod write SetBitmapsLod;
    property LastPalette: int read FLastPalette;
    property OwnBitmapsLod: Boolean read FOwnBitmapsLod write FOwnBitmapsLod;
    property OnNeedBitmapsLod: TNotifyEvent read FOnNeedBitmapsLod write FOnNeedBitmapsLod;
    property OnNeedPalette: TRSLodNeedPaletteEvent read FOnNeedPalette write FOnNeedPalette;
    property OnConvertToPalette: TRSLodConvertPaletteEvent read FOnConvertToPalette write FOnConvertToPalette;
    property OnSpritePalette: TRSLodSpritePaletteEvent read FOnSpritePalette write FOnSpritePalette;
  end;


  TRSLwd = class(TRSLod)
  protected
    constructor CreateInternal(Files: TRSMMFiles); override;
    procedure FindBitmapPalette(const name: string; b: TBitmap; var pal, Bits: int); override;
    function FindDimentions(p: PChar): TColor;
    function PackLwd(p: PChar; w, h: int; m: TMemoryStream): int;
    procedure DoPackBitmap(b: TBitmap; var b1, b2: TBitmap; var hdr; m, buf: TMemoryStream; Keep: Boolean); override;
    procedure UnpackLwd(data: TStream; b: TBitmap; const FileHeader);
    procedure UnpackBitmap(data: TStream; b: TBitmap; const FileHeader); override;
  public
    TransparentColor: TColor;
  end;


  TRSSnd = class(TRSMMArchive)
  protected
    FMM: Boolean;

    procedure InitOptions(var Options: TRSMMFilesOptions);
    procedure ReadHeader(Sender: TRSMMFiles; Stream: TStream;
       var Options: TRSMMFilesOptions; var FilesCount: int); override;
    procedure WriteHeader(Sender: TRSMMFiles; Stream: TStream); override;
  public
    procedure New(const FileName: string; MightAndMagic: Boolean);
    function Add(const Name: string; Data: TStream; Size: int = -1; pal: int = 0): int; override;
    function GetExtractName(Index: int): string; override;
    function CloneForProcessing(const NewFile: string; FilesCount: int): TRSMMArchive; override;
  end;


  TRSVid = class(TRSMMArchive)
  protected
    FNoExtension: Boolean;
    FInitSizeTable: array of uint;

    constructor CreateInternal(Files: TRSMMFiles); override;

    //function DoGetFileSize(Stream: TStream; sz: uint): uint;
    function NeedSizeTable(Stream: TStream): Boolean;
    function NeedNoExtSig: Boolean;

    procedure InitOptions(var Options: TRSMMFilesOptions);
    procedure ReadHeader(Sender: TRSMMFiles; Stream: TStream;
       var Options: TRSMMFilesOptions; var FilesCount: int); override;
    procedure WriteHeader(Sender: TRSMMFiles; Stream: TStream); override;
    procedure GetFileSize(Sender: TRSMMFiles; Index: int; var Size: int);
    procedure SetFileSize(Sender: TRSMMFiles; Index: int; Size: int);
  public
    procedure New(const FileName: string; NoExtension: Boolean);
    function Add(const Name: string; Data: TStream; Size: int = -1; pal: int = 0): int; override;
    function GetExtractName(Index: int): string; override;
    function CloneForProcessing(const NewFile: string; FilesCount: int): TRSMMArchive; override;
    procedure Load(const FileName: string); override;
  end;


procedure RSMMFilesOptionsInitialize(var Options: TRSMMFilesOptions);
function RSLoadMMArchive(const FileName: string): TRSMMArchive;
function RSMMArchivesFind(const a: TRSMMArchivesArray; const Name: string;
   var Archive: TRSMMArchive; var Index: int): Boolean;
function RSMMArchivesFindSamePalette(const a: TRSMMArchivesArray; const PalEntries): int;
function RSMMArchivesCheckFileChanged(const a: TRSMMArchivesArray; Ignore: TRSMMArchive = nil): Boolean;
procedure RSMMArchivesFree(var a: TRSMMArchivesArray);
function RSMMPaletteToBitmap(const a: TRSByteArray): TBitmap;

// _stricmp comparsion. AnsiCompareText returns a different result.
function RSLodCompareStr(s1, s2: PChar): int; overload;
function RSLodCompareStr(s1, s2: PChar; var SameCount: int): int; overload;

resourcestring
  SRSLodCorrupt = 'File invalid or corrupt';
  SRSLodLongName = 'File name (%s) length exceeds %d symbols';
  SRSLodUnknown = 'Unknown LOD version';
  SRSLodUnknownSnd = 'Unknown SND format';
  SRSLodSpriteMustPal = 'Palette index for sprite must be specified';
  SRSLodSpriteMust256 = 'Sprites must be in 256 colors format';
  SRSLodNoBitmaps = 'This LOD type doesn''t support bitmaps';
  SRSLodSpriteMustBmp = 'Cannot add files other than bitmaps into sprites.lod';
  SRSLodActPalMust768 = 'ACT palette size must be 768 bytes';
  SRSLodSpriteExtractNeedLods = 'BitmapsLod and TextsLod must be specified to extract images from sprites.lod';
  SRSLodPalNotFound = 'File "PAL%.3d" referred to by sprite "%s" not found in BitmapsLod';
  SRSLodMustPowerOf2 = 'Bitmap %s must be a power of 2 and can''t be less than 4';

implementation

const
  HeroesId=#$C8; MM6Id='MMVI'; MM8Id='MMVIII';

const
  SReadFailed = 'Failed to read %d bytes at offset %d';

// {3EB9C5C5-7947-48bd-913A-ACEB28EBE015}
const VidSizeSigOld = #$3E#$B9#$C5#$C5#$79#$47#$48#$bd#$91#$3A#$AC#$EB#$28#$EB#$E0#$15;
// {8703C24E-26CF-4cc6-97DD-E2ECAEBECDB4}
const VidSizeSigStart = #$87#$03#$C2#$4E#$26#$CF#$4c#$c6#$97#$DD#$E2#$EC#$AE#$BE#$CD#$B4;
// {0B745246-7609-4d9f-AFE5-3F7E9B23780E}
const VidSizeSigEnd = #$0B#$74#$52#$46#$76#$09#$4d#$9f#$AF#$E5#$3F#$7E#$9B#$23#$78#$0E;
// {3F78DE47-E92E-4065-9AF1-74BBAE9D77D7}
const VidSizeSigNoExt = #$3F#$78#$DE#$47#$E9#$2E#$40#$65#$9A#$F1#$74#$BB#$AE#$9D#$77#$D7;

const VidSizeSigSize = length(VidSizeSigOld);
const GamesLod7Sig = VidSizeSigOld;

const
  PowerOf2: array[0..15] of int = (1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768);

type
  TLodType = record
    Version: string;
    LodType: string;
  end;

const
  LodTypes: array[TRSLodVersion] of TLodType =
  (
    (Version: ''; LodType: ''),              // RSLodHeroes
    (Version: 'MMVI'; LodType: 'bitmaps'),   // RSLodBitmaps
    (Version: 'MMVI'; LodType: 'icons'),     // RSLodIcons
    (Version: 'MMVI'; LodType: 'sprites08'), // RSLodSprites
    (Version: 'GameMMVI'; LodType: 'maps'),  // RSLodGames
    (Version: 'GameMMVI'; LodType: 'maps'),  // RSLodGames7
    (Version: 'MMVI'; LodType: 'chapter'),   // RSLodChapter
    (Version: 'MMVII'; LodType: 'chapter'),  // RSLodChapter7
    (Version: 'MMVIII'; LodType: 'language') // RSLodMM8
  );

  LodDescriptions: array[TRSLodVersion] of string =
  (
    '',                                      // RSLodHeroes
    'Bitmaps for MMVI.',                     // RSLodBitmaps
    'Icons for MMVI.',                       // RSLodIcons
    'Sprites for MMVI.',                     // RSLodSprites
    'Maps for MMVI',                         // RSLodGames
    'Maps for MMVI',                         // RSLodGames7
    'newmaps for MMVI',                      // RSLodChapter
    'newmaps for MMVII',                     // RSLodChapter7
    'Language for MMVIII.'                   // RSLodMM8
  );

type
  PMMLodFile = ^TMMLodFile;
  TMMLodFile = packed record
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
    Bits: int;  // Bits:  2 - multitexture, $10 - something important too, $400 - don't free buffers 
    // Data...
    // Palette...
  end;

  TSpriteLine = packed record
    a1: int2;
    a2: int2;
    pos: int4;
  end;
  TSprite = packed record
    Size: int;
    w: int2;
    h: int2;
    Palette: int2;
    unk_1: int2;
    yskip: int2; // number of clear lines at the bottom
    unk_2: int2; // used in runtime only, for bits
    UnpSize: int;
  end;
  TSpriteEx = packed record
    Sprite: TSprite;
    Lines: array[0..(MaxInt div SizeOf(TSpriteLine) div 2)] of TSpriteLine;
    // Data...
  end;

  TPCXFileHeader = packed record
    ImageSize: longint;
    Width: longint;
    Height: longint;
    // Data...
    // Palette...
  end;
  PPCXFileHeader = ^TPCXFileHeader;
   // Pcx Format: <Header> <Picture> <Palette>
   // The format is far from real PCX
   // Palette exists only if biSizeImage/(biWidth*biHeight) = 1

  TMM6GamesFile = packed record
    DataSize: int;
    UnpackedSize: int;
  end;

  TMM7GamesFile = packed record
    Sig1: int; // $16741
    Sig2: int; // $6969766D (mvii)
    DataSize: int;
    UnpackedSize: int;
  end;

const
  cnkNone = 0;
  cnkExist = 1;
  cnkGetName = 2;

type
  TMyReadStream = class(TMemoryStream)
  protected
    FPtr: pptr;
    function Realloc(var NewCapacity: Longint): Pointer; override;
  public
    constructor Create(var p: ptr);
    destructor Destroy; override;
    function Write(const Buffer; Count: Longint): Longint; override;
  end;

{ TMyReadStream }

constructor TMyReadStream.Create(var p: ptr);
begin
  FPtr:= @p;
end;

destructor TMyReadStream.Destroy;
var
  p: pint;
begin
  p:= FPtr^;
  if (p <> nil) and (InterlockedDecrement(p^) = 0) then
  begin
    FPtr^:= nil;
    FreeMem(p, Capacity + sizeof(int));
  end;
  FPtr:= nil;
  SetPointer(nil, 0);
  inherited;
end;

function TMyReadStream.Realloc(var NewCapacity: Integer): Pointer;
var
  p: pint;
begin
  Assert(Memory = nil, 'Attempt to set size of read-only stream');
  Result:= nil;
  if FPtr <> nil then
  begin
    p:= AllocMem(NewCapacity + sizeof(int));
    FPtr^:= p;
    p^:= 1;
    inc(p);
    Result:= p;
  end;
end;

function TMyReadStream.Write(const Buffer; Count: Integer): Longint;
begin
  Assert(false, 'Attempt to write to read-only stream');
  Result:= 0;
end;

procedure ByteArrayDelete(var Arr: TRSByteArray; Index:int; Size:int);
var
  Buf: array[0..2047] of byte;
  j:int; p:PChar;
begin
  j:= length(Arr) - Size; // High(Arr)*Size
  Index:= Index*Size;
  p:= PChar(Arr);
  CopyMemory(@Buf, p + Index, Size);
  CopyMemory(p + Index, p + Index + Size, j - Index);
  CopyMemory(p + j, @Buf, Size);
end;

procedure ByteArrayInsert(var Arr: TRSByteArray; Index:int; Size:int);
var
  Buf: array[0..2047] of byte;
  j:int; p:PChar;
begin
  j:= length(Arr) - Size; // High(Arr)*Size
  Index:= Index*Size;
  p:= PChar(Arr);
  CopyMemory(@Buf, p + j, Size);
  CopyMemory(p + Index + Size, p + Index, j - Index);
  CopyMemory(p + Index, @Buf, Size);
end;


function RSLodCompareStr(s1, s2: PChar): int; overload;
var
  a,b:int;
begin
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

function RSLodCompareStr(s1, s2: PChar; var SameCount: int): int; overload;
var
  a,b:int; baseS1: PChar;
begin
  baseS1:= s1;
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
    begin
      SameCount:= s1 - baseS1;
      exit;
    end;
    inc(s1);
    inc(s2);
  end;
end;

procedure UnzipIgnoreErrors(output, input: TStream; unp: uint; noless: Boolean);
var
  c: TDecompressionStream;
  oldPos, oldPosI: int64;
  i, ReadOk, oldSize: uint;
begin
  oldPos:= output.Position;
  oldPosI:= input.Position;
  oldSize:= uint(-1);
  c:= TDecompressionStream.Create(input);
  try
    if output is TMemoryStream then
    begin
      oldSize:= uint(output.Size);
      i:= uint(oldPos) + unp;
      if oldSize < i then
        TMemoryStream(output).SetSize(i)
      else
        oldSize:= uint(-1);
    end;
    try
      output.CopyFrom(c, unp);
    except
      FreeAndNil(c);
      input.Position:= oldPosI;
      c:= TDecompressionStream.Create(input);
      try
        ReadOk:= uint(output.Position - oldPos);
        if ReadOk <> 0 then
          c.Seek(ReadOk, soFromBeginning);
        for i := 1 to unp - ReadOk do
          output.CopyFrom(c, 1);
      except
      end;
      if noless then
      begin
        ReadOk:= uint(output.Position - oldPos);
        oldPos:= 0;
        for i := 1 to unp - ReadOk do
          output.WriteBuffer(oldPos, 1);
      end else
        if oldSize <> uint(-1) then
          output.Size:= max(oldSize, output.Position);
    end;
  finally
    c.Free;
  end;
end;

function MyGetFileTime(const name: string): int64;
var
  d: TWin32FindData;
  h: THandle;
begin
  Result:= 0;
  if zSet(h, FindFirstFile(ptr(name), d)) <> INVALID_HANDLE_VALUE then
    try
      Result:= int64(d.ftLastWriteTime);
    finally
      Windows.FindClose(h);
    end;
end;

function GetLn2(v: int): int;
begin
  Result:= 0;
  while (v <> 0) and (v and 1 = 0) do
  begin
    v:= v shr 1;
    inc(Result);
  end;
  if v <> 1 then
    Result:= 0;
end;


{ TRSMMFiles }

procedure MyReadBuffer(a: TStream; var data; size: int);
begin
  if a is TMemoryStream then
    a.ReadBuffer(data, size) // don't mistake it for the lod file
  else
    Assert(a.Read(data, size) = size, Format(SReadFailed, [size, a.Position]));
end;

function TRSMMFiles.Add(const Name: string; Data: TStream; Size: int = -1;
   Compression: TCompressionLevel = clDefault; UnpackedSize: int = -1): int;
var
  NewData, fs, Compr: TStream;
  Found: Boolean;
  addr: uint;
  i, UnpSize, PkSize: int;
begin
  CheckName(Name);
  if Size < 0 then
    Size:= Data.Size - Data.Position;
  UnpSize:= Size;
  PkSize:= 0;
  NewData:= nil;
  fs:= nil;
  with FOptions do
    try
      // Pack file
      if UnpackedSize >= 0 then // Already packed
      begin
        UnpSize:= UnpackedSize;
        PkSize:= Size;
      end else
        if (Compression <> clNone) and (Data.Size > 64) and
           ((PackedSizeOffset >= 0) or (UnpackedSizeOffset >= 0)) then
        begin
          NewData:= TMemoryStream.Create;
          Compr:= TCompressionStream.Create(Compression, NewData);
          try
            RSCopyStream(Compr, Data, UnpSize);
          finally
            Compr.Free;
          end;
          if NewData.Size < Size then
          begin
            Data:= NewData;
            Data.Seek(0, 0);
            Size:= Data.Size;
            PkSize:= Size;
          end else
            Data.Seek(-UnpSize, soCurrent);
        end;

      // Find insert index
      Found:= FindAddIndex(Name, Result);
      if Found and Assigned(OnBeforeReplaceFile) then
        OnBeforeReplaceFile(self, Result);

      BeginWrite;
      try
        if Found then  // Replace existing
        begin
          if CanExpand(Result, Size) then
            DoWriteFile(Result, Data, Size, Address[Result])
          else
            DoWriteFile(Result, Data, Size, FFileSize);
          // !!! update data
          ZeroMemory(@FUserData[Result*FUserDataSize], FUserDataSize);
        end else       // Add new
        begin
          addr:= DataStart + uint((FCount + 1)*ItemSize);
          //if uint(addr) > uint(FOptions.MinFileSize) then
            for i := 0 to FCount - 1 do
              if Address[i] < addr then
                {if FCount = 1 then
                  DoMoveFile(i, addr)
                else}
                  DoMoveFile(i, FFileSize);

          inc(FCount);
          InsertData(FData, Result, ItemSize);
          InsertData(FUserData, Result, FUserDataSize);
          SetLength(FFileBuffers, FCount);
          ArrayInsert(FFileBuffers, Result, sizeof(ptr));
          FFileSize:= max(FFileSize, FOptions.DataStart + uint(length(FData)));
          DoWriteFile(Result, Data, Size, FFileSize);
        end;
        i:= Result;

        // Write file name
        ZeroMemory(@FData[i*ItemSize], NameSize);
        if Name <> '' then
          Move(Name[1], FData[i*ItemSize], length(Name));
        // Write file size
        if SizeOffset >= 0 then
          pint(@FData[i*ItemSize + SizeOffset])^:= Size;
        if UnpackedSizeOffset >= 0 then
          pint(@FData[i*ItemSize + UnpackedSizeOffset])^:= UnpSize;
        if PackedSizeOffset >= 0 then
          pint(@FData[i*ItemSize + PackedSizeOffset])^:= PkSize;
        if Assigned(OnSetFileSize) then
          OnSetFileSize(self, i, Size);

        if not FWriteOnDemand then
          WriteHeader;
      finally
        EndWrite;
      end;

    finally
      NewData.Free;
      fs.Free;
    end;
end;

procedure TRSMMFiles.AssignStream(fs: TStream);
begin
  FWriteStream:= fs;
  inc(FWritesCount);
end;

function TRSMMFiles.BeginRead: TStream;
var h: HFILE;
begin
  if (FWriteStream = nil) or not SameText(FInFile, FOutFile) then
  begin
    h:= RSCreateFile(FInFile, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING);
    if h = INVALID_HANDLE_VALUE then  RSRaiseLastOSError;
    Result:= TFileStream.Create(h);
  end else
    Result:= BeginWrite;
end;

function TRSMMFiles.BeginWrite: TStream;
var h: HFILE;
begin
  Result:= FWriteStream;
  if Result = nil then
  begin
    if (FBlockStream <> nil) and SameText(FInFile, FOutFile) then
      FreeAndNil(FBlockStream);

    h:= RSCreateFile(FOutFile, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ, nil, OPEN_ALWAYS); //OPEN_EXISTING);
    if h = INVALID_HANDLE_VALUE then  RSRaiseLastOSError;
    Result:= TFileStream.Create(h);
    FWriteStream:= Result;
  end;
  Result.Seek(0, 0);
  inc(FWritesCount);
end;

procedure TRSMMFiles.CalculateFileSize;
var
  sz: uint;
  i: int;
begin
  sz:= max(FOptions.DataStart, FOptions.MinFileSize);
  for i := 0 to Count - 1 do
    sz:= max(sz, Address[i] + uint(Size[i]));
  FFileSize:= sz;  
end;

function TRSMMFiles.CanExpand(Index, aSize: uint): Boolean;
var addr, sz, i, j: uint;
begin
  addr:= Address[Index];
  sz:= uint(Size[Index]);
  Result:= (aSize <= sz) or (addr + sz >= uint(FFileSize));
  if Result then  exit;

  j:= uint(Address[Index + 1]);
  Result:= (j >= addr) and (j - addr >= aSize);
  if not Result then  exit;

  for i := 0 to Count - 1 do
  begin
    j:= uint(Address[i]);
    Result:= (j >= addr) and (j - addr >= aSize);
    if not Result then  exit;
  end;
end;

function TRSMMFiles.CheckFileChanged: Boolean;
begin
  Result:= FFileTime <> MyGetFileTime(FInFile);
  {if Result then
  begin
    Close;
    ReadHeader;
  end;}
end;

procedure TRSMMFiles.CheckName(const Name: string);
begin
  if length(Name) >= FOptions.NameSize then
    raise ERSLodWrongFileName.CreateFmt(SRSLodLongName, [Name, FOptions.NameSize]);
end;

function TRSMMFiles.CloneForProcessing(const NewFile: string; FilesCount: int): TRSMMFiles;
begin
  Result:= TRSMMFiles.Create;
  with Result do
  begin
    FOptions:= self.FOptions;
    FInFile:= NewFile;
    FOutFile:= NewFile;
    FUserDataSize:= self.FUserDataSize;
    FFileSize:= max(FOptions.DataStart + uint(FilesCount*FOptions.ItemSize), FOptions.MinFileSize); // !!! wrong?
    FGamesLod:= self.FGamesLod;
    FSorted:= self.FSorted;
    FFileTime:= MyGetFileTime(FInFile);
  end;
end;

procedure TRSMMFiles.Close;
var i:int;
begin
  for i := 0 to length(FFileBuffers) - 1 do
    FFileBuffers[i].Free;
  FFileBuffers:= nil;
  FreeAndNil(FBlockStream);
  FCount:= 0;
  RSMMFilesOptionsInitialize(FOptions);
  FData:= nil;
  FInFile:= '';
  FOutFile:= '';
  FSorted:= true;
  // !!! Finalize UserData
  FUserData:= nil;
end;

constructor TRSMMFiles.Create;
begin
  RSMMFilesOptionsInitialize(FOptions);
end;

procedure TRSMMFiles.Delete(i: int);
begin
  DoDelete(i);
end;

procedure TRSMMFiles.Delete(const Name: string);
var i:int;
begin
  if FindFile(ptr(Name), i) then
    Delete(i);
end;

procedure TRSMMFiles.Delete(const Name: PChar);
var i:int;
begin
  if FindFile(Name, i) then
    Delete(i);
end;

destructor TRSMMFiles.Destroy;
begin
  Close;
  inherited;
end;

procedure TRSMMFiles.DoDelete(i: int; NoWrite: Boolean = false);
begin
  if Assigned(OnBeforeDeleteFile) then
    OnBeforeDeleteFile(self, i);
  dec(FCount);
  RemoveData(FData, i, FOptions.ItemSize);
  // !!! Finalize UserData
  RemoveData(FUserData, i, FUserDataSize);
  if length(FFileBuffers) > i then
  begin
    FFileBuffers[i].Free;
    ArrayDelete(FFileBuffers, i, sizeof(ptr));
    SetLength(FFileBuffers, length(FFileBuffers) - 1);
  end;
  if not NoWrite and not FWriteOnDemand then
    WriteHeader;
end;

procedure TRSMMFiles.DoMoveFile(Index, Addr: int);
var
  r:TStream;
begin
  if (length(FFileBuffers) > Index) and (FFileBuffers[Index] <> nil) then
  begin
    FFileBuffers[Index].Seek(0, 0);
    DoWriteFile(Index, FFileBuffers[Index], FFileBuffers[Index].Size, Addr);
    exit;
  end;

  r:= GetAsIsFileStream(Index);
  try
    DoWriteFile(Index, r, Size[Index], Addr);  // !!! bug if overlap
  finally
    FreeAsIsFileStream(Index, r);
  end;
end;

procedure TRSMMFiles.DoSave;
var i:int;
begin
  BeginWrite;
  try
    for i := 0 to length(FFileBuffers) - 1 do
      if FFileBuffers[i] <> nil then
      begin
        FFileBuffers[i].Seek(0, 0);
        DoWriteFile(i, FFileBuffers[i], FFileBuffers[i].Size, Address[i], true);
        FreeAndNil(FFileBuffers[i]);
      end;
    FFileBuffers:= nil;
    WriteHeader;
  finally
    EndWrite;
  end;
end;

procedure TRSMMFiles.DoWriteFile(Index: int; Data: TStream; Size, Addr: uint;
   ForceWrite: Boolean = false);
var
  w: TStream;
begin
  if FWriteOnDemand and not ForceWrite then
  begin
    if Index >= length(FFileBuffers) then
      SetLength(FFileBuffers, Index + 1);
    if Data <> FFileBuffers[Index] then
    begin
      FFileBuffers[Index].Free;
      FFileBuffers[Index]:= TMemoryStream.Create;
      FFileBuffers[Index].SetSize(Size);
      MyReadBuffer(Data, FFileBuffers[Index].Memory^, Size);
    end;
  end else
  begin
    w:= BeginWrite;
    try
      w.Seek(Addr, 0);
      Assert(Data.Size - Data.Position >= Size, Format(SReadFailed, [Size, Data.Position]));
      RSCopyStream(w, Data, Size);
    finally
      EndWrite;
    end;
  end;

  with FOptions do
    puint(@FData[Index*ItemSize + AddrOffset])^:= Addr - AddrStart;
  inc(Addr, Size);
  if Addr > FFileSize then
    FFileSize:= Addr;
end;

procedure TRSMMFiles.EndRead(Stream: TStream);
begin
  if Stream <> nil then
    if Stream = FWriteStream then
      EndWrite
    else
      if Stream <> FBlockStream then
        Stream.Free;
end;

procedure TRSMMFiles.EndWrite;
var i:int;
begin
  i:= FWritesCount - 1;
  Assert(i >= 0);
  FWritesCount:= i;
  if i = 0 then
  begin
    FreeAndNil(FWriteStream);
    if FBlockInFile and SameText(FInFile, FOutFile) and (FBlockStream = nil) then
      FBlockStream:= BeginRead;
  end;
  FFileTime:= MyGetFileTime(FInFile);
end;

function TRSMMFiles.FindAddIndex(const Name: string; var Index: int): Boolean;
var
  i: int;
begin
  Result:= FindFile(Name, Index);
  if not Result and FGamesLod then
  begin
    i:= FCount - 1;
    while (i >= 0) and not IsBlvOrOdm(self.Name[i]) do
      dec(i);
    // games.lod must allow binary search for dlv/ddm files
    // yet order of blv/odm files should be kept for compatibility
    // with Lloyd beacons in save games
    if not IsBlvOrOdm(Name) then
      FindFileBinSearch(PChar(Name), Index, i + 1, FCount - 1)
    else
      Index:= i + 1;
  end;
end;

function TRSMMFiles.FindFile(const Name: PChar; var Index: int): Boolean;
var
  best, bestC, i, C, same, bestSame: int;
begin
  if not FSorted then
  begin
    bestSame:= 0;
    best:= 0;
    bestC:= 1;
    for i := 0 to FCount - 1 do
    begin
      C:= RSLodCompareStr(Name, self.Name[i], same);
      if C = 0 then
      begin
        Index:= i;
        Result:= true;
        exit;
      end else
        if (same > bestSame) or (same = bestSame) and (bestC > 0) then
        begin
          best:= i;
          if C > 0 then
            inc(best);
          bestSame:= same;
          bestC:= C;
        end;
    end;
    Index:= best;
    Result:= false;
  end else
    Result:= FindFileBinSearch(Name, Index, 0, FCount - 1);
end;

function TRSMMFiles.FindFileBinSearch(const Name: PChar; var Index: int; L,
  H: int): Boolean;
var
  i, C: int;
begin
  while L <= H do
  begin
    i:= (L + H) div 2;

    C:= RSLodCompareStr(Name, self.Name[i]);
    if C <= 0 then
    begin
      if C = 0 then
      begin
        Index:= i;
        Result:= True;
        exit;
      end;
      H:= i - 1;
    end else
      L:= i + 1;
  end;
  Index:= L;
  Result:= false;
end;

function TRSMMFiles.FindFile(const Name: string; var Index: int): Boolean;
begin
  Result:= FindFile(PChar(Name), Index);
end;

procedure TRSMMFiles.FreeAsIsFileStream(Index: int; Stream: TStream);
begin
  if (Index >= length(FFileBuffers)) or (FFileBuffers[Index] <> Stream) then
    EndRead(Stream);
end;

function TRSMMFiles.GetAddress(i: int): uint;
begin
  with FOptions do
    if i < Count then
      Result:= puint(@FData[i*ItemSize + AddrOffset])^ + AddrStart
    else
      Result:= FFileSize;
end;

{function TRSMMFiles.GetFileSpace(Index: int): int;
var addr, i, j: int;
begin
  Result:= MaxInt;
  addr:= Address[Index];
  j:= Address[Index + 1] - addr;
  if j > 0 then  Result:= j;

  for i := 0 to Count - 1 do
  begin
    j:= Address[i] - addr;
    if (j > 0) and (j < Result) then  Result:= j;
  end;
end;}

function TRSMMFiles.GetAsIsFileStream(Index: int; IgnoreWrite: Boolean = false): TStream;
begin
  if (Index < length(FFileBuffers)) and (FFileBuffers[Index] <> nil) then
  begin
    Result:= FFileBuffers[Index];
    Result.Seek(0, 0);
    exit;
  end;

  Result:= BeginRead;
  Result.Position:= Address[Index];
  if (Result = FWriteStream) and not IgnoreWrite then
  begin
    Result:= TMemoryStream.Create;
    with TMemoryStream(Result) do
    begin
      SetSize(self.Size[Index]);
      MyReadBuffer(FWriteStream, Memory^, Size);
      Seek(0, 0);
    end;
    EndWrite;
  end;
end;

function TRSMMFiles.GetIsPacked(i: int): Boolean;
begin
  with FOptions do
    if PackedSizeOffset >= 0 then
      Result:= (pint(@FData[i*ItemSize + PackedSizeOffset])^ <> 0)
    else
      if (SizeOffset >= 0) and (UnpackedSizeOffset >= 0) then
        Result:= (pint(@FData[i*ItemSize + SizeOffset])^ <>
                    pint(@FData[i*ItemSize + UnpackedSizeOffset])^)
      else
        Result:= false;
end;

function TRSMMFiles.GetName(i: int): PChar;
begin
  Result:= @FData[i*FOptions.ItemSize];
end;

function TRSMMFiles.GetSize(i: int): int;
begin
  if (i < length(FFileBuffers)) and (FFileBuffers[i] <> nil) then
  begin
    Result:= FFileBuffers[i].Size;
    exit;
  end;

  Result:= 0;
  with FOptions do
    if SizeOffset < 0 then
    begin
      if (Result = 0) and (PackedSizeOffset >= 0) then
        Result:= pint(@FData[i*ItemSize + PackedSizeOffset])^;
      if (Result = 0) and (UnpackedSizeOffset >= 0) then
        Result:= pint(@FData[i*ItemSize + UnpackedSizeOffset])^;
    end else
      Result:= pint(@FData[i*ItemSize + SizeOffset])^;

  if Assigned(OnGetFileSize) then
    OnGetFileSize(self, i, Result);
end;

function TRSMMFiles.GetUnpackedSize(i: int): int;
begin
  if FOptions.UnpackedSizeOffset < 0 then
  begin
    Assert(FOptions.PackedSizeOffset < 0); // !!! ??
    Result:= GetSize(i);
  end else
    Result:= pint(@FData[i*FOptions.ItemSize + FOptions.UnpackedSizeOffset])^;
end;

function TRSMMFiles.GetUserData(i: int): ptr;
begin
  Result:= @FUserData[i*FUserDataSize];
end;

procedure TRSMMFiles.InsertData(var Data: TRSByteArray; Index, ItemSize: int);
var i,j: int;
begin
  SetLength(Data, length(Data) + ItemSize);
  i:= Index*ItemSize;
  j:= i + ItemSize;
  Move(Data[i], Data[j], length(Data) - j);
  ZeroMemory(@Data[i], ItemSize);
end;

function TRSMMFiles.IsBlvOrOdm(const Name: string): Boolean;
var
  s: string;
begin
  s:= ExtractFileExt(Name);
  if s <> '' then
    StrLower(ptr(s));
  Result:= (s = '.blv') or (s = '.odm');
end;

procedure TRSMMFiles.Load(const FileName: string);
begin
  Close;
  FInFile:= FileName;
  FOutFile:= FileName;
  ReadHeader;
end;

procedure TRSMMFiles.MergeTo(Files: TRSMMFiles);
var
  r: TStream;
  i: int;
begin
  Files.BeginWrite;
  try
    for i := 0 to Count - 1 do
    begin
      r:= GetAsIsFileStream(i);
      try
        if IsPacked[i] then
          Files.Add(Name[i], r, Size[i], clNone, UnpackedSize[i])
        else
          Files.Add(Name[i], r, Size[i], clNone);
      finally
        FreeAsIsFileStream(i, r);
      end;
    end;
  finally
    Files.EndWrite;
  end;
end;

procedure TRSMMFiles.New(const FileName: string;
  const Options: TRSMMFilesOptions);
begin
  Close;
  FOptions:= Options;
  FInFile:= FileName;
  FOutFile:= FileName;
  FFileSize:= max(FOptions.DataStart, FOptions.MinFileSize);
  FFileTime:= MyGetFileTime(FInFile);
  DoSave;
end;

(*
procedure TRSMMFiles.Process(OutputFile: string;
   ProcessProc: TRSMMFilesProcessEvent);
var
  i, sz: int;
  r, Stream: TStream;
begin
  FOutFile:= OutputFile;
  try
    BeginWrite;
  except
    FOutFile:= FInFile;
    raise;
  end;
  FProcessing:= true;
  try
    i:= 0;
    while i < FCount do
    begin
      r:= BeginRead;
      Stream:= r;
      sz:= Size[i];
      try
        ProcessProc(self, Name[i], Stream, sz);
        if Stream = nil then
        begin
          DoDelete(i);
        end else
        begin
          DoWriteFile(i, Stream, sz);
          inc(i);
        end;

      finally
        EndRead(r);
        if Stream<>r then
          Stream.Free;
      end;
    end;
    FInFile:= OutputFile;
  finally
    FProcessing:= false;
    EndWrite;
    FOutFile:= FInFile;
  end;
end;
*)

procedure TRSMMFiles.RawExtract(i: int; a: TStream);
var
  b, c: TStream;
begin
  b:= GetAsIsFileStream(i, true);
  c:= nil;
  try
    if IsPacked[i] then
      if not IgnoreUnzipErrors then
      begin
        c:= TDecompressionStream.Create(b);
        RSCopyStream(a, c, UnpackedSize[i]);
      end else
        UnzipIgnoreErrors(a, b, UnpackedSize[i], true)
    else
      RSCopyStream(a, b, Size[i]);
  finally
    c.Free;
    FreeAsIsFileStream(i, b);
  end;
end;

procedure TRSMMFiles.ReadHeader;
var
  r: TStream;
  i: int;
begin
  r:= BeginRead;
  if FBlockInFile then
    FBlockStream:= r;
  FFileTime:= MyGetFileTime(FInFile);

  with r do
    try
      OnReadHeader(self, r, FOptions, FCount);

      SetLength(FData, FCount*FOptions.ItemSize);
      SetLength(FUserData, FCount*FUserDataSize);
      if FCount = 0 then  exit;
      Seek(FOptions.DataStart, 0);
      MyReadBuffer(r, FData[0], length(FData));
    finally
      EndRead(r);
    end;

  CalculateFileSize;
  FSorted:= false;
  for i := 0 to Count - 2 do
    if RSLodCompareStr(Name[i], Name[i+1]) > 0 then
      exit;
  FSorted:= true;
end;

procedure TRSMMFiles.Rebuild;
var
  name, s: string;
begin
  name:= FOutFile;
  s:= name + '.tmp';
  while FileExists(s) do
    s:= name + '.' + IntToHex(Random($1000), 3);
  try
    SaveAsNoBlock(s);
    RSWin32Check(RSMoveFile(s, name, false));
  finally
    if FileExists(name) then
      DeleteFile(s)
    else
      name:= s;
    FOutFile:= name;
    FInFile:= name;
    FFileTime:= MyGetFileTime(FInFile);
  end;
  if FBlockInFile then
    FBlockStream:= BeginRead;
end;

procedure TRSMMFiles.RemoveData(var Data: TRSByteArray; Index, ItemSize: int);
var i,j: int;
begin
  i:= Index*ItemSize;
  j:= i + ItemSize;
  Move(Data[j], Data[i], length(Data) - j);
  SetLength(Data, length(Data) - ItemSize);
end;

function TRSMMFiles.Rename(Index: int; const NewName: string): int;
begin
  CheckName(NewName);
  with FOptions do
  begin
    if FindFile(NewName, Result) then
      if Result = Index then
        exit
      else
        DoDelete(Result, true);

    // remove (move to the end of lists)
    ByteArrayDelete(FData, Index, ItemSize);
    ByteArrayDelete(FUserData, Index, FUserDataSize);
    if length(FFileBuffers) > Index then
      ArrayDelete(FFileBuffers, Index, SizeOf(ptr));
    dec(FCount);

    // add (move from the end of lists to Result position)
    Assert(not FindAddIndex(NewName, Result));
    inc(FCount);
    ByteArrayInsert(FData, Result, ItemSize);
    ByteArrayInsert(FUserData, Result, FUserDataSize);
    if length(FFileBuffers) > Index then
    begin
      if length(FFileBuffers) <= Result then
      begin
        SetLength(FFileBuffers, FCount);
        ArrayDelete(FFileBuffers, Index, SizeOf(ptr));
      end;
      ArrayInsert(FFileBuffers, Result, SizeOf(ptr));
    end;

    // write new name
    ZeroMemory(@FData[Result*ItemSize], NameSize);
    if NewName <> '' then
      Move(NewName[1], FData[Result*ItemSize], length(NewName));
  end;

  if not FWriteOnDemand then
    WriteHeader;
  
  if Assigned(OnAfterRenameFile) then
    OnAfterRenameFile(self, Result);
end;

procedure TRSMMFiles.ReserveFilesCount(n: int);
begin
  FFileSize:= max(FFileSize, FOptions.DataStart + uint(n*FOptions.ItemSize));
end;

procedure TRSMMFiles.Save;
begin
  if length(FFileBuffers) <> 0 then
    DoSave;
end;

procedure TRSMMFiles.SaveAs(const FileName:string);
begin
  SaveAsNoBlock(FileName);
  if FBlockInFile then
    FBlockStream:= BeginRead;
end;

procedure TRSMMFiles.SaveAsNoBlock(const FileName: string);
var
  i, oldSize: int;
  f: TStream;
  ok: Boolean;
  oldData: TRSByteArray;
begin
  Assert(FWriteStream = nil);
  FOutFile:= FileName;
  oldSize:= FFileSize;
  FFileSize:= max(FOptions.MinFileSize, FOptions.DataStart + uint(length(FData)));
  SetLength(oldData, length(FData));
  Move(FData[0], oldData[0], length(FData));
  //DeleteFile(FileName);
  //BeginWrite;
  FWriteStream:= TFileStream.Create(FOutFile, fmCreate);
  inc(FWritesCount);
  ok:= false;
  try
    for i := 0 to FCount - 1 do
    begin
      f:= GetAsIsFileStream(i);
      Assert(f.Size - f.Position >= Size[i], Format('Failed to read %d bytes at offset %d (file %d address %d)', [Size[i], f.Position, i, Address[i]]));
      try
        DoWriteFile(i, f, Size[i], FFileSize, true);
      finally
        FreeAsIsFileStream(i, f);
      end;
    end;
    ok:= true;
    WriteHeader;
  finally
    EndWrite;
    if not ok then
    begin
      FData:= oldData;
      FFileSize:= oldSize;
    end;
  end;

  for i := 0 to length(FFileBuffers) - 1 do
    FreeAndNil(FFileBuffers[i]);
  FreeAndNil(FBlockStream);
  FInFile:= FOutFile;
  FFileTime:= MyGetFileTime(FInFile);
end;

procedure TRSMMFiles.SetUserDataSize(v: int);
begin
  if v = FUserDataSize then  exit;
  Assert(FUserDataSize <= 2048);
  FUserData:= nil;
  FUserDataSize:= v;
  SetLength(FUserData, FUserDataSize*FCount);
end;

procedure TRSMMFiles.SetWriteOnDemand(v: Boolean);
begin
  if FWriteOnDemand = v then  exit;

  if not v then
    Save;
  FWriteOnDemand:= v;
end;

procedure TRSMMFiles.WriteHeader;
var
  sz, Addr: uint;
  w: TStream;
  i: int;
begin
  w:= BeginWrite;
  with w do
    try
      sz:= FOptions.DataStart + uint(length(FData));
      for i:= 0 to FCount - 1 do
      begin
        Addr:= GetAddress(i) + uint(GetSize(i));
        if Addr > sz then
          sz:= Addr;
      end;
      FFileSize:= sz;
      if Size <> sz then
      begin
        Size:= sz;
        Position:= 0;
      end;
      OnWriteHeader(self, w);

      if FCount = 0 then  exit;
      Seek(FOptions.DataStart, 0);
      WriteBuffer(FData[0], length(FData));
    finally
      EndWrite;
    end;
end;

{ TRSArchive }

constructor TRSArchive.Create(const FileName: string);
begin
  Create;
  Load(FileName);
end;

{ TRSMMArchive }

function TRSMMArchive.Add(const Name: string; Data: TStream;
  Size: int = -1; pal: int = 0): int;
begin
  Result:= FFiles.Add(Name, Data, Size, clNone);
end;

function TRSMMArchive.Add(const Name: string; Data: TRSByteArray;
  pal: int = 0): int;
var
  a: TStream;
begin
  a:= TRSArrayStream.Create(Data);
  try
    Result:= Add(Name, a, -1, pal);
  finally
    a.Free;
  end;
end;

function TRSMMArchive.Add(const FileName: string; pal: int = 0): int;
var
  a: TStream;
begin
  a:= TFileStream.Create(FileName, fmOpenRead);
  try
    Result:= Add(ExtractFileName(FileName), a, -1, pal);
  finally
    a.Free;
  end;
end;

function TRSMMArchive.Add(const FileName: string; Data: string): int;
var
  a: TStream;
begin
  a:= TRSStringStream.Create(Data);
  try
    a.Position:= 0;
    Result:= Add(FileName, a);
  finally
    a.Free;
  end;
end;

function TRSMMArchive.BackupFile(Index: int; Overwrite: Boolean): Boolean;
var
  old: Boolean;
begin
  old:= FFiles.IgnoreUnzipErrors;
  FFiles.IgnoreUnzipErrors:= true;
  try
    DoBackupFile(Index, Overwrite);
    Result:= true;
  except
    Result:= false;
  end;
  FFiles.IgnoreUnzipErrors:= old;
end;

procedure TRSMMArchive.BeforeDeleteFile(Sender: TRSMMFiles; Index: int);
begin
  if FBackupOnDelete then
    BackupFile(Index, FBackupOnDeleteOverwrite);
end;

procedure TRSMMArchive.BeforeReplaceFile(Sender: TRSMMFiles; Index: int);
begin
  if FBackupOnAdd then
    BackupFile(Index, FBackupOnAddOverwrite);
end;

function TRSMMArchive.CloneForProcessing(const NewFile: string;
  FilesCount: int): TRSMMArchive;
begin
  Result:= TRSMMArchive(self.NewInstance);
  Result.CreateInternal(FFiles.CloneForProcessing(NewFile, FilesCount));
end;

constructor TRSMMArchive.Create;
begin
  CreateInternal(TRSMMFiles.Create);
end;

constructor TRSMMArchive.CreateInternal(Files: TRSMMFiles);
begin
  FFiles:= Files;
  Files.OnReadHeader:= ReadHeader;
  Files.OnWriteHeader:= WriteHeader;
  Files.UserDataSize:= FTagSize;
  Files.OnBeforeReplaceFile:= BeforeReplaceFile;
  Files.OnBeforeDeleteFile:= BeforeDeleteFile;
end;

destructor TRSMMArchive.Destroy;
begin
  FFiles.Free;
  inherited;
end;

procedure TRSMMArchive.DoBackupFile(Index: int; Overwrite: Boolean);
begin
  Extract(Index, MakeBackupDir, Overwrite);
end;

function TRSMMArchive.DoExtract(Index: int; const FileName: string; Overwrite: Boolean): string;
var
  a: TMemoryStream;
begin
  Result:= '';
  if not Overwrite and FileExists(FileName) then  exit;
  Result:= FileName;
  a:= TMemoryStream.Create;
  try
    Extract(Index, a);
    RSSaveFile(Result, a);
  finally
    a.Free;
  end;
end;

function TRSMMArchive.Extract(Index: int): TObject;
begin
  Result:= TMemoryStream.Create;
  try
    Extract(Index, TStream(Result));
  except
    Result.Free;
    raise;
  end;
end;

function TRSMMArchive.ExtractArray(Index: int): TRSByteArray;
var
  a: TStream;
begin
  Result:= nil;
  a:= TRSArrayStream.Create(Result);
  try
    Extract(Index, a);
  finally
    a.Free;
  end;
end;

function TRSMMArchive.ExtractArrayOrBmp(Index: int; var Arr: TRSByteArray): TBitmap;
begin
  Arr:= nil;
  Arr:= ExtractArray(Index);
  Result:= nil;
end;

function TRSMMArchive.ExtractString(Index: int): string;
var
  a: TStream;
begin
  Result:= '';
  a:= TRSStringStream.Create(Result);
  try
    Extract(Index, a);
  finally
    a.Free;
  end;
end;

function TRSMMArchive.Extract(Index: int; Output: TStream): string;
begin
  FFiles.RawExtract(Index, Output);
  Result:= GetExtractName(Index);
end;

function TRSMMArchive.Extract(Index: int; const Dir: string; Overwrite: Boolean = true): string;
begin
  Result:= DoExtract(Index, IncludeTrailingPathDelimiter(Dir) + GetExtractName(Index), Overwrite);
end;

function TRSMMArchive.GetCount: int;
begin
  Result:= FFiles.Count;
end;

function TRSMMArchive.GetExtractName(Index: int): string;
begin
  Result:= FFiles.Name[Index];
end;

function TRSMMArchive.GetFileName(i: int): PChar;
begin
  Result:= FFiles.Name[i];
end;

procedure TRSMMArchive.Load(const FileName: string);
begin
  FFiles.Load(FileName);
end;

function TRSMMArchive.MakeBackupDir: string;
begin
  Result:= FFiles.FileName + ' Backup';
  RSCreateDir(Result);
  Result:= Result + '\';
end;

procedure TRSMMArchive.SaveAs(const FileName: string);
begin
  FFiles.SaveAs(FileName);
end;

{ TRSLodBase }

procedure TRSLodBase.AfterRenameFile(Sender: TRSMMFiles; Index: int);
var
  a: TStream;
begin
  if not (FVersion in [RSLodBitmaps, RSLodIcons, RSLodMM8, RSLodSprites]) then
    exit;

  // change file name inside the linked file structure 
  with FFiles do
    if not WriteOnDemand then
    begin
      a:= BeginWrite;
      try
        a.Seek(Address[Index], 0);
        a.WriteBuffer(Name[Index]^, Options.NameSize);
      finally
        EndWrite;
      end;
    end else
    begin
      if Index >= length(FFileBuffers) then
        SetLength(FFileBuffers, Index + 1);
      a:= FFileBuffers[Index];
      try
        if a = nil then
        begin
          a:= TMemoryStream.Create;
          RawExtract(Index, a);
        end;
        a.Seek(0, 0);
        a.WriteBuffer(Name[Index]^, Options.NameSize);
        a.Seek(0, 0);
        zSwap(a, FFileBuffers[Index]);
      finally
        if a <> FFileBuffers[Index] then
          a.Free;
      end;
    end;
end;

function TRSLodBase.CloneForProcessing(const NewFile: string; FilesCount: int): TRSMMArchive;
begin
  Result:= inherited CloneForProcessing(NewFile, FilesCount);
  with TRSLodBase(Result) do
  begin
    FAnyHeader:= self.FAnyHeader;
    FVersion:= self.FVersion;
    SetLength(FAdditionalData, length(self.FAdditionalData));
    if FAdditionalData <> nil then
      Move(self.FAdditionalData[0], FAdditionalData[0], length(FAdditionalData));

    if FVersion = RSLodHeroes then
    begin
      FHeroesHeader^.Count:= 0;
    end else
      with FMMHeader^ do
      begin
        Count:= 0;
        ArchiveSize:= FFiles.ArchiveSize - FFiles.Options.DataStart;
      end;

    if FVersion in [RSLodGames, RSLodGames7, RSLodChapter, RSLodChapter7] then
      RawFiles.FSorted:= self.RawFiles.FSorted;
  end;
end;

constructor TRSLodBase.CreateInternal(Files: TRSMMFiles);
begin
  inherited;
  FHeroesHeader:= @FAnyHeader;
  FMMHeader:= @FAnyHeader;
  Files.OnAfterRenameFile:= AfterRenameFile;
end;

function TRSLodBase.GetExtractName(Index: int): string;
begin
  Result:= FFiles.Name[Index] + '.mmrawdata';
end;

procedure TRSLodBase.InitOptions(var Options: TRSMMFilesOptions);
begin
  with Options do
  begin
    if Version <> RSLodHeroes then
    begin
      if FVersion = RSLodMM8 then
      begin
        NameSize:= $40;
        AddrOffset:= $40;
        UnpackedSizeOffset:= $44;
        ItemSize:= $4C;
      end else
      begin
        NameSize:= $10;
        AddrOffset:= $10;
        UnpackedSizeOffset:= $14;
        ItemSize:= $20;
      end;
      PackedSizeOffset:= -1;

      AddrStart:= FMMHeader^.ArchiveStart;
      DataStart:= FMMHeader^.ArchiveStart;
      MinFileSize:= 0;
    end else
      with Options do
      begin
        NameSize:= $10;
        AddrOffset:= $10;
        UnpackedSizeOffset:= $14;
        PackedSizeOffset:= $1C;
        ItemSize:= $20;

        AddrStart:= 0;
        DataStart:= SizeOf(TRSLodHeroesHeader);
        MinFileSize:= 320092;
      end
  end;
end;

procedure TRSLodBase.Load(const FileName: string);
var
  sig: array[1..2] of int;
  a: TStream;
  ext: string;
  i: int;
begin
  inherited;
  if FVersion = RSLodGames then
    for i := 0 to FFiles.Count - 1 do
    begin
      ext:= LowerCase(ExtractFileExt(FFiles.Name[i]));
      if (ext = '.blv') or (ext = '.dlv') or (ext = '.odm') or (ext = '.ddm') then
      begin
        if FFiles.Size[i] < 16 then  exit;
        a:= FFiles.GetAsIsFileStream(i, true);
        try
          MyReadBuffer(a, sig, 8);
        finally
          FFiles.FreeAsIsFileStream(i, a);
        end;
        if (sig[1] = $16741) and (sig[2] = $6969766D) then
          FVersion:= RSLodGames7;
        exit;
      end;
    end;
end;

procedure TRSLodBase.New(const FileName: string; AVersion: TRSLodVersion);
var
  o: TRSMMFilesOptions;
begin
  FVersion:= AVersion;
  ZeroMemory(@FAnyHeader, SizeOf(FAnyHeader));
  FAdditionalData:= nil;
  FMMHeader^.Signature:= 'LOD';
  if AVersion <> RSLodHeroes then
    with FMMHeader^ do
    begin
      StrCopy(Version, ptr(LodTypes[AVersion].Version));
      StrCopy(LodType, ptr(LodTypes[AVersion].LodType));
      StrCopy(Description, ptr(LodDescriptions[AVersion]));
      Unk1:= 100;
      Unk2:= 0;
      ArchivesCount:= 1;
      ArchiveStart:= $120;
    end
  else
    FHeroesHeader^.Version:= 200;
  RSMMFilesOptionsInitialize(o);
  InitOptions(o);
  FFiles.New(FileName, o);
  FFiles.FGamesLod:= (AVersion in [RSLodGames, RSLodGames7]);
end;

procedure TRSLodBase.ReadHeader(Sender: TRSMMFiles; Stream: TStream;
   var Options: TRSMMFilesOptions; var FilesCount: int);
var
  s1: string;
  ver: TRSLodVersion;
begin
  with Stream do
  begin
    MyReadBuffer(Stream, FHeroesHeader^, SizeOf(TRSLodHeroesHeader));
    FVersion:= RSLodHeroes;
    if FHeroesHeader^.Version > $FFFF then
    begin
      MyReadBuffer(Stream, (PChar(FMMHeader) + SizeOf(TRSLodHeroesHeader))^,
        SizeOf(TRSLodMMHeader) - SizeOf(TRSLodHeroesHeader));

      Assert(FMMHeader^.ArchivesCount = 1, 'Combined archives aren''t supported');
      for ver := RSLodBitmaps to RSlodMM8 do
        if (FMMHeader^.Version = LodTypes[ver].Version) and
           (FMMHeader^.LodType = LodTypes[ver].LodType) then
        begin
          FVersion:= ver;
          break;
        end;

      if FVersion = RSLodHeroes then
        raise ERSLodException.Create(SRSLodUnknown);
      if FVersion = RSLodGames then  // RSLodGames7 isn't detected yet
        FFiles.FGamesLod:= true;

      FilesCount:= FMMHeader^.Count;
      InitOptions(Options);
      SetLength(FAdditionalData, FMMHeader^.ArchiveStart - SizeOf(TRSLodMMHeader));
      if FAdditionalData <> nil then
        MyReadBuffer(Stream, FAdditionalData[0], length(FAdditionalData));

      if FVersion = RSLodGames then
      begin
        SetLength(s1, VidSizeSigSize);
        Stream.Seek(-VidSizeSigSize, soFromEnd);
        if Stream.Read(s1[1], VidSizeSigSize) = VidSizeSigSize then
          if s1 = GamesLod7Sig then
            FVersion:= RSLodGames7;
      end;
    end else
    begin
      FVersion:= RSLodHeroes;
      FilesCount:= FHeroesHeader^.Count;
      InitOptions(Options);
    end;
  end;
end;

procedure TRSLodBase.WriteGamesLod7Sig(Sender: TRSMMFiles; Stream: TStream);
var
  ext: string;
  sz: uint;
  i: int;
begin
  if FVersion <> RSLodGames7 then
    exit;
    
  for i := 0 to FFiles.Count - 1 do
  begin
    ext:= LowerCase(ExtractFileExt(FFiles.Name[i]));
    if (ext = '.blv') or (ext = '.dlv') or (ext = '.odm') or (ext = '.ddm') then
      exit;
  end;

  // if there are no other means to find out it's games.lod of MM7
  sz:= max(Stream.Size - VidSizeSigSize, FFiles.FOptions.DataStart);
  for i := 0 to FFiles.Count - 1 do
    sz:= max(sz, FFiles.Address[i] + uint(FFiles.Size[i]));

  Stream.Position:= sz;
  Stream.WriteBuffer(GamesLod7Sig[1], VidSizeSigSize);
end;

procedure TRSLodBase.WriteHeader(Sender: TRSMMFiles; Stream: TStream);
begin
  with Stream do
  begin
    if FVersion = RSLodHeroes then
    begin
      FHeroesHeader^.Count:= FFiles.Count;

      WriteBuffer(FHeroesHeader^, SizeOf(TRSLodHeroesHeader));
    end else
    begin
      FMMHeader^.Count:= FFiles.Count;
      FMMHeader^.ArchiveSize:= FFiles.ArchiveSize - FFiles.Options.DataStart;

      WriteBuffer(FMMHeader^, SizeOf(TRSLodMMHeader));
      if FAdditionalData <> nil then
        WriteBuffer(FAdditionalData[0], length(FAdditionalData));
    end;
    WriteGamesLod7Sig(Sender, Stream);
  end;
end;

{ TRSLod }

function TRSLod.Add(const Name: string; b: TBitmap; pal: int = 0): int;
begin
  Result:= AddBitmap(Name, b, pal, true);
end;

function TRSLod.Add(const Name: string; Data: TStream; Size: int = -1; pal: int = 0): int;
var
  ext, s: string;
  sz: int;
  m: TMemoryStream;
  act: Boolean;
  b: TBitmap;
begin
  Result:= -1;
  ext:= LowerCase(ExtractFileExt(Name));
  if ext = '.mmrawdata' then
  begin
    Result:= inherited Add(ChangeFileExt(Name, ''), Data, Size, pal);
    exit;
  end;
  if ext = '.bmp' then
  begin
    Result:= AddBitmap(Name, RSLoadBitmap(Data), pal, false);
    exit;
  end;
  if Size < 0 then
    Size:= Data.Size - Data.Position;
  act:= false;
  if (ext = '') and (FVersion = RSLodBitmaps) and (LowerCase(Copy(Name, 1, 3)) = 'pal') then
    if Size <> 768 then
    begin
      b:= RSLoadBitmap(Data);
      b.Width:= 0;
      b.Height:= 0;
      Result:= AddBitmap(Name, b, 0, false, 0);
      exit;
    end else
      act:= true;

  m:= nil;
  try
    case FVersion of
      RSLodHeroes:
        Result:= FFiles.Add(Name, Data, Size);
      RSLodBitmaps, RSLodIcons, RSLodMM8:
      begin
        if ext = '.act' then
        begin
          act:= true;
          if Size <> 768 then
            raise ERSLodException.Create(SRSLodActPalMust768);
          s:= copy(Name, 1, length(Name) - 4);
        end else
          s:= Name;
        FFiles.CheckName(s);
        sz:= FFiles.Options.NameSize;
        m:= TMemoryStream.Create;
        m.SetSize(sz + SizeOf(TMMLodFile));
        ZeroMemory(m.Memory, sz + SizeOf(TMMLodFile));
        if s <> '' then
          Move(s[1], m.Memory^, length(s));

        if act then
          Zip(m, Data, Size, -1, int(@PMMLodFile(sz).UnpSize))
        else if ext = '.str' then
          PackStr(m, Data, Size)
        else
          Zip(m, Data, Size, int(@PMMLodFile(sz).DataSize), int(@PMMLodFile(sz).UnpSize));
        m.Seek(0, 0);
        Result:= FFiles.Add(s, m, -1, clNone);
      end;
      RSLodSprites:
        raise ERSLodException.Create(SRSLodSpriteMustBmp);
      RSLodGames, RSLodGames7, RSLodChapter, RSLodChapter7:
        if (ext = '.blv') or (ext = '.dlv') or (ext = '.odm') or (ext = '.ddm') then
        begin
          m:= TMemoryStream.Create;
          sz:= 8;
          if FVersion in [RSLodGames7, RSLodChapter7] then
            sz:= 16;
          m.SetSize(sz);
          if sz = 16 then
            with TMM7GamesFile(m.Memory^) do
            begin
              Sig1:= $16741;
              Sig2:= $6969766D;
            end;
          Zip(m, Data, Size, sz - 8, sz - 4);
          m.Seek(0, 0);
          Result:= FFiles.Add(Name, m, -1, clNone);
        end else
          Result:= FFiles.Add(Name, Data, Size, clNone);
    end;
  finally
    m.Free;
  end;
end;

destructor TRSLod.Destroy;
begin
  BitmapsLod:= nil;
  inherited;
end;

function TRSLod.DoExtract(i: int; Output: TStream = nil; Arr: PRSByteArray = nil;
   FileName: PStr = nil; CheckNameKind: int = 0): TObject;
// Output <> nil    =>  fills Output
// Arr <> nil       =>  fills Arr
// else creates a bitmap or memory stream and returns it as Result
var
  outnew: TStream;
  Dummy: string;

  function CheckName: Boolean;
  begin
    Result:= (CheckNameKind = 0) or (CheckNameKind = cnkExist) and not FileExists(FileName^);
    CheckNameKind:= 0;
  end;

  function SetName(const s: string): Boolean;
  begin
    FileName^:= s;
    Result:= CheckName;
  end;

  function NeedOutput: Boolean;
  begin
    if (Output = nil) and CheckName then
    begin
      if Arr <> nil then
        outnew:= TRSArrayStream.Create(Arr^)
      else
        outnew:= TMemoryStream.Create;
      Output:= outnew;
    end;
    Result:= Output<>nil;
  end;

var
  a: TStream;
  games: TMM7GamesFile;
  regular: TMMLodFile;
  sz: int;
  b: TBitmap;
  name, ext: string;
begin
  FLastPalette:= 0;
  Result:= nil;
  b:= nil;
  a:= nil;
  outnew:= nil;
  Dummy:= '';
  if FileName = nil then
    FileName:= @Dummy;
  name:= FFiles.Name[i];
  ext:= LowerCase(ExtractFileExt(name));
  try
    if FVersion <> RSLodHeroes then
      a:= FFiles.GetAsIsFileStream(i, true);

    case FVersion of
      RSLodHeroes:
        if ext = '.pcx' then
        begin
          if not SetName(ChangeFileExt(FileName^, '.bmp')) then  exit;
          a:= TMemoryStream.Create;
          FFiles.RawExtract(i, a);
          b:= TBitmap.Create;
          UnpackPcx(TMemoryStream(a), b);
        end else
        begin
          if not NeedOutput then  exit;
          FFiles.RawExtract(i, Output);
        end;

      RSLodSprites:
      begin
        if not SetName(FileName^ + '.bmp') then  exit;
        a.Seek(FFiles.Options.NameSize - 4, soCurrent);
        b:= TBitmap.Create;
        UnpackSprite(name, a, b, FFiles.Size[i] - FFiles.Options.NameSize + 4);
      end;

      RSLodBitmaps, RSLodIcons, RSLodMM8:
      begin
        a.Seek(FFiles.Options.NameSize, soCurrent);
        a.ReadBuffer(regular, SizeOf(regular));
        if regular.BmpSize <> 0 then
        begin
          if not SetName(FileName^ + '.bmp') then  exit;
          b:= TBitmap.Create;
          UnpackBitmap(a, b, regular);
        end else
          if (regular.DataSize = 0) and (FFiles.Size[i] >= 768 + SizeOf(regular) + FFiles.Options.NameSize) then
          begin
            if not SetName(FileName^ + '.act') or not NeedOutput then  exit;
            RSCopyStream(Output, a, 768);
          end else
          begin
            if not NeedOutput then  exit;
            if ext = '.str' then
              UnpackStr(a, Output, regular)
            else
              Unzip(a, Output, regular.DataSize, regular.UnpSize, ext <> '.txt');
          end;
      end;
      
      RSLodGames, RSLodGames7, RSLodChapter, RSLodChapter7:
      begin
        if not NeedOutput then  exit;
        if (ext = '.blv') or (ext = '.dlv') or (ext = '.odm') or (ext = '.ddm') then
        begin
          if FVersion in [RSLodGames7, RSLodChapter7] then
          begin
            sz:= 16;
            a.ReadBuffer(games, 16)
          end else
          begin
            sz:= 8;
            a.ReadBuffer(games.DataSize, 8);
          end;
          Unzip(a, Output, FFiles.Size[i] - sz, games.UnpackedSize, true);
        end else
          FFiles.RawExtract(i, Output);
      end;
    end;

    if Output <> nil then
    begin
      if b <> nil then
        b.SaveToStream(Output);

      if (outnew = Output) and (Arr = nil) then
      begin
        Result:= outnew;
        outnew:= nil;
      end;
    end else
      Result:= b;
  finally
    if a <> nil then
      FFiles.FreeAsIsFileStream(i, a);
    outnew.Free;
    if b <> Result then
      b.Free;
  end;
end;

function MixCl(c1, c2, c3, c4: int): int;
begin
  Result:= ((c1 and $FCFCFC + c2 and $FCFCFC + c3 and $FCFCFC + c4 and $FCFCFC) +
    (c1 and $030303 + c2 and $030303 + c3 and $030303 + c4 and $030303 + $020202) and $C0C0C) shr 2;
end;

procedure FillBitmapZooms(b2: TBitmap; buf: PChar; pal: HPALETTE);
const
  dx = 4;
var
  i, x, y, dy, c, w, h: int;
  p: PChar;
begin
  b2.HandleType:= bmDIB;
  b2.PixelFormat:= pf32bit;
  w:= b2.Width;
  h:= b2.Height;
  inc(buf, w*h);  // skip normal size picture
  p:= b2.ScanLine[0];
  dy:= int(b2.ScanLine[1]) - int(p);
  for i := 1 to 3 do
  begin
    w:= w div 2;
    h:= h div 2;
    for y := 0 to h - 1 do
      for x := 0 to w - 1 do
      begin
        c:= MixCl(pint(p + y*2*dy + x*2*dx)^,
                  pint(p + y*2*dy + (x*2 + 1)*dx)^,
                  pint(p + (y*2 + 1)*dy + x*2*dx)^,
                  pint(p + (y*2 + 1)*dy + (x*2 + 1)*dx)^);
        if i = 1 then
          c:= RSSwapColor(c);
        pint(p + y*dy + x*dx)^:= c;
        buf^:= chr(GetNearestPaletteIndex(pal, c));
        inc(buf);
      end;
  end;
end;

procedure TRSLod.DoPackBitmap(b: TBitmap; var b1, b2: TBitmap; var hdr; m,
  buf: TMemoryStream; Keep: Boolean);
var
  zoom: Boolean;
  i: int;
begin
  with TMMLodFile(hdr) do
  begin
    UnpSize:= BmpSize;
    zoom:= (Bits and 2 <> 0);
    if zoom then
      inc(UnpSize, ((BmpSize div 4 + BmpSize) div 4 + BmpSize) div 4);
    buf.SetSize(UnpSize);
  end;
  if b.Width <> 0 then
  begin
    if (Keep or zoom or Assigned(OnConvertToPalette)) and (b.PixelFormat <> pf8bit) or
        Keep and (b.HandleType <> bmDIB) then
    begin
      b1:= TBitmap.Create;
      b1.Assign(b);
    end;
    if (b1.PixelFormat <> pf8bit) and Assigned(OnConvertToPalette) then
      OnConvertToPalette(self, b, b1);
    b1.PixelFormat:= pf8bit;
    b1.HandleType:= bmDIB;
    RSBitmapToBuffer(buf.Memory, b1);
    if zoom then
    begin
      b2:= TBitmap.Create;
      b2.Assign(b);
      b1.IgnorePalette:= false;
      FillBitmapZooms(b2, buf.Memory, b1.Palette);
    end;
  end;

  with TMMLodFile(hdr) do
    Zip(m, buf, UnpSize, @DataSize, @UnpSize);

  i:= m.Seek(0, soEnd);
  m.SetSize(i + 256*3);
  b1.IgnorePalette:= false;
  RSWritePalette(PChar(m.Memory) + i, b1.Palette);
end;

function TRSLod.Extract(Index: int; const Dir: string; Overwrite: Boolean): string;
var
  a: TObject;
begin
  Result:= IncludeTrailingPathDelimiter(Dir) + FFiles.Name[Index];
  a:= nil;
  try
    a:= DoExtract(Index, nil, nil, @Result, IfThen(Overwrite, 0, cnkExist));
    if a = nil then
      Result:= ''
    else
      if a is TBitmap then
        TBitmap(a).SaveToFile(Result)
      else
        RSSaveFile(Result, a as TMemoryStream);
  finally
    a.Free;
  end
end;

function TRSLod.Extract(Index: int; Output: TStream): string;
begin
  Result:= FFiles.Name[Index];
  DoExtract(Index, Output, nil, @Result);
end;

function TRSLod.Extract(Index: int): TObject;
begin
  Result:= DoExtract(Index);
end;

function TRSLod.ExtractArrayOrBmp(Index: int; var Arr: TRSByteArray): TBitmap;
begin
  Result:= TBitmap(DoExtract(Index, nil, @Arr));
end;

function PalVal(p: PChar): uint;
label
  bad;
var
  i: uint;
begin
  // Don't know why I optimized it...
  // '0' - '9'  =  $30 - $39
  inc(p, 3);
  i:= pint(p + 1)^;
  if ((i and $C0F0F0) <> $3030) or ((ord(p^) and $F0) <> $30) then  goto bad;
  Result:= (ord(p^) and $F)*100 + (i and $F)*10 + (i shr 8) and $F;
  i:= i shr 16;
  if byte(i) = 0 then  exit;
  if (byte(i) < $30) or (Result < 100) then  goto bad;
  Result:= Result*10 + byte(i) - $30;
  i:= i shr 8;
  if i = 0 then  exit;
  if (byte(i) < $30) or (byte(i) > $39) then  goto bad;
  Result:= Result*10 + byte(i) - $30;
  if (p + 5)^ = #0 then  exit;
bad:
  Result:= 0;
end;

procedure TRSLod.FindBitmapPalette(const name: string; b: TBitmap; var pal, Bits: int);
var
  NoPal: Boolean;
  i: int;
begin
  NoPal:= pal <= 0;
  if (NoPal or (Bits = -1)) and FFiles.FindFile(name, i) then
  begin
    if pal <= 0 then
      pal:= GetIntAt(i, 20);
    if Bits = -1 then
      Bits:= GetIntAt(i, 28) or $12;
  end else
    if Bits = -1 then
      Bits:= $12;

  if NoPal and (Bits <> 0) and Assigned(OnNeedPalette) then
    OnNeedPalette(self, b, pal);
end;

function TRSLod.FindSamePalette(const PalEntries; var pal: int): Boolean;
var
  i, j, m1, m2, fr3, fr4, fr5: int;
begin
  Result:= false;
  if FVersion <> RSLodBitmaps then  exit;
  FFiles.FindFile('pal', m1);
  FFiles.FindFile('pam', m2);
  fr3:= 1;  // to find a free palette index
  fr4:= 1000;  // for numbers consisting of 3, 4 and 5 digits
  fr5:= 10000;  // in these categories lexicographical sorting works
  for i := m1 to m2 - 1 do
  begin
    j:= PalVal(FFiles.Name[i]);
    if (j = 0) or (j > $7FFF) then  continue;
    if j <= fr3 then
      inc(fr3)
    else if j <= fr4 then
      inc(fr4)
    else if j <= fr5 then
      inc(fr5);
    if IsSamePalette(PalEntries, i) then
    begin
      pal:= j;  // found identical palette
      Result:= true;
      exit;
    end;
  end;

  if fr3 < 1000 then
    pal:= fr3
  else if fr4 < 10000 then
    pal:= fr4
  else
    pal:= fr5;
end;

function TRSLod.GetBitmapsLod: TRSLod;
begin
  if BitmapsLods <> nil then
    Result:= BitmapsLods[0] as TRSLod
  else
    Result:= nil;
end;

function TRSLod.GetExtractName(Index: int): string;
begin
  Result:= FFiles.Name[Index];
  DoExtract(Index, nil, nil, @Result, cnkGetName);
end;

function TRSLod.GetIntAt(i, o: int): int;
var
  a: TStream;
begin
  a:= FFiles.GetAsIsFileStream(i);
  try
    a.Seek(o + FFiles.Options.NameSize, soCurrent);
    MyReadBuffer(a, Result, 4);
  finally
    FFiles.FreeAsIsFileStream(i, a);
  end;
end;

function TRSLod.IsSamePalette(const PalEntries; i: int): Boolean;
const
  ReadOff = 16;
  FileSize = SizeOf(TMMLodFile) + ReadOff + 768;
var
  PalFile: array[0..SizeOf(TMMLodFile) + 768 - 1] of byte;
  a: TStream;
begin
  Result:= false;
  if (FFiles.Size[i] <> FileSize) then  exit;
  a:= FFiles.GetAsIsFileStream(i);
  try
    a.Seek(ReadOff, soCurrent);
    a.ReadBuffer(PalFile, SizeOf(PalFile));
  finally
    FFiles.FreeAsIsFileStream(i, a);
  end;

  with PMMLodFile(@PalFile)^ do
    Result:= ((BmpSize or DataSize or pint(@BmpWidth)^) = 0) and
       CompareMem(@PalFile[SizeOf(TMMLodFile)], @PalEntries, 768);
end;

procedure TRSLod.LoadBitmapsLods(const dir: string);

  procedure AddLod(const s: string);
  var
    i: int;
  begin
    i:= length(BitmapsLods);
    SetLength(BitmapsLods, i + 1);
    if SameText(s, FFiles.FileName) then
      BitmapsLods[i]:= self
    else
      BitmapsLods[i]:= TRSLod.Create(s);
  end;

var
  s: string;
begin
  BitmapsLod:= nil;
  OwnBitmapsLod:= true;
  s:= dir + 'bitmaps.lod';
  if FileExists(s) then
    AddLod(s);

  with TRSFindFile.Create(dir + '*.bitmaps.lod') do
    try
      while FindNextAttributes(0, FILE_ATTRIBUTE_DIRECTORY) do // Only files
        AddLod(FileName);
    finally
      Free;
    end;
end;

function TRSLod.AddBitmap(const Name: string; b: TBitmap; pal: int;
  Keep: Boolean; Bits: int = -1): int;
var
  nam: string;
  m: TMemoryStream;
  i: int;
begin
  b.HandleType:= bmDIB;
  Result:= -1;
  if FVersion = RSLodHeroes then
    nam:= '.pcx'
  else
    nam:= '';
  nam:= ChangeFileExt(Name, nam);
  m:= nil;
  try
    if FVersion <> RSLodSprites then
      FFiles.CheckName(nam)
    else
      if length(nam) >= 12 then
        raise ERSLodWrongFileName.CreateFmt(SRSLodLongName, [nam, 12]);

    m:= TMemoryStream.Create;
    if FVersion <> RSLodHeroes then
    begin
      m.SetSize(FFiles.Options.NameSize);
      ZeroMemory(m.Memory, m.Size);
      if nam <> '' then
        Move(nam[1], m.Memory^, length(nam));
    end;
    case FVersion of
      RSLodHeroes:
        PackPcx(b, m, Keep);  // Result?
      RSLodSprites:
      begin
        if pal <= 0 then
        begin
          if FFiles.FindFile(nam, i) then
            pal:= GetIntAt(i, 4);
          if Assigned(OnNeedPalette) then
            OnNeedPalette(self, b, pal);
        end;
        PackSprite(b, m, pal);
      end;
      RSLodBitmaps, RSLodIcons, RSLodMM8:
      begin
        if FVersion = RSLodBitmaps then
          FindBitmapPalette(nam, b, pal, Bits)
        else if Bits = -1 then
          Bits:= 0;

        PackBitmap(b, m, pal, Bits, Keep);
      end;
      else
        raise ERSLodException.Create(SRSLodNoBitmaps);
    end;
    m.Seek(0, 0);
    if FVersion <> RSLodHeroes then
      Result:= FFiles.Add(nam, m, m.Size, clNone)
    else
      Result:= FFiles.Add(nam, m);
  finally
    m.Free;
    if not Keep then
      b.Free;
  end;
end;

procedure TRSLod.DoBackupFile(Index: int; Overwrite: Boolean);
var
  a: TFileStream;
  s: string;
begin
  if Version in [RSLodBitmaps, RSLodSprites] then
  begin
    s:= MakeBackupDir + FFiles.Name[Index] + '.mmrawdata';
    if not Overwrite and FileExists(s) then  exit;
    a:= TFileStream.Create(s, fmCreate);
    try
      FFiles.RawExtract(Index, a);
    finally
      a.Free;
    end;
  end else
    inherited;
end;

function TRSLod.CloneForProcessing(const NewFile: string;
  FilesCount: int): TRSMMArchive;
begin
  Result:= inherited CloneForProcessing(NewFile, FilesCount);
  with TRSLod(Result) do
  begin
    BitmapsLods:= self.BitmapsLods;
    FOnNeedBitmapsLod:= self.FOnNeedBitmapsLod;
    FOnNeedPalette:= self.FOnNeedPalette;
    FOnConvertToPalette:= self.FOnConvertToPalette; 
    FOnSpritePalette:= self.FOnSpritePalette;
  end;
end;

constructor TRSLod.CreateInternal(Files: TRSMMFiles);
begin
  inherited;
  OnNeedBitmapsLod:= StdNeedBitmapsLod;
end;

function TRSLod.PackPcx(b: TBitmap; m: TMemoryStream; KeepBmp: Boolean): int;
var
  i, j: int;
  HasPal: Boolean;
  b1: TBitmap;
begin
  b1:= nil;
  try
    if b.PixelFormat <> pf8bit then
    begin
      if (b.PixelFormat <> pf24bit) and KeepBmp then
      begin
        b1:= TBitmap.Create;
        b1.Assign(b);
        b:= b1;
      end;
      b.PixelFormat:=pf24bit;
      i:=3;
      Result:= $11;
    end else
    begin
      i:=1;
      Result:= $10;
    end;

    HasPal:= i = 1;
    i:= i * b.Width * b.Height;
    j:= i + SizeOf(TPCXFileHeader);
    if HasPal then
      m.SetSize(j + 256*3)
    else
      m.SetSize(j);

    with PPCXFileHeader(m.Memory)^ do
    begin
      ImageSize:= i;
      Width:= b.Width;
      Height:= b.Height;
    end;
    RSBitmapToBuffer(PChar(m.Memory) + SizeOf(TPCXFileHeader), b);

    if HasPal then
    begin
      b.IgnorePalette:= false;
      RSWritePalette(PChar(m.Memory) + j, b.Palette);
    end;
  finally
    b1.Free;
  end;
end;

procedure TRSLod.PackBitmap(b: TBitmap; m: TMemoryStream; pal, ABits: int; Keep: Boolean);
var
  buf: TMemoryStream;
  b1, b2: TBitmap;
  sz0: int;
begin
  sz0:= m.Size;
  m.SetSize(sz0 + SizeOf(TMMLodFile));
  ZeroMemory(PChar(m.Memory) + sz0, SizeOf(TMMLodFile));
  with TMMLodFile(ptr(PChar(m.Memory) + sz0)^) do
  begin
    BmpWidth:= b.Width;
    BmpHeight:= b.Height;
    BmpSize:= BmpWidth*BmpHeight;
    if (FVersion = RSLodBitmaps) and (BmpWidth <> 0) then
    begin
      Palette:= pal;
      Bits:= ABits;
      if ABits and 2 <> 0 then
      begin
        BmpWidthLn2:= GetLn2(BmpWidth);
        if BmpWidthLn2 < 2 then
          raise ERSLodBitmapException.CreateFmt(SRSLodMustPowerOf2, ['width']);
        BmpHeightLn2:= GetLn2(BmpHeight);
        if BmpHeightLn2 < 2 then
          raise ERSLodBitmapException.CreateFmt(SRSLodMustPowerOf2, ['height']);
        BmpWidthMinus1:= BmpWidth - 1;
        BmpHeightMinus1:= BmpHeight - 1;
      end;
    end;
  end;
  b1:= b;
  b2:= nil;
  buf:= TMemoryStream.Create;
  try
    DoPackBitmap(b, b1, b2, ptr(PChar(m.Memory) + sz0)^, m, buf, Keep);
  finally
    buf.Free;
    if b1 <> b then
      b1.Free;
    b2.Free;
  end;
end;

procedure TRSLod.PackSprite(b: TBitmap; m: TMemoryStream; pal: int);
var
  buf: TMemoryStream;
  i, j, k, bp: int;
  scan0, p: PChar; dscan, sz0: int;
  oldht: TBitmapHandleType;
begin
  if b.PixelFormat <> pf8bit then
    raise ERSLodBitmapException.Create(SRSLodSpriteMust256);
  if pal = 0 then
    raise ERSLodBitmapException.Create(SRSLodSpriteMustPal);
  oldht:= b.HandleType;
  buf:= TMemoryStream.Create;
  try
    sz0:= m.Size - 4;
    m.SetSize(sz0 + SizeOf(TSprite) + b.Height*SizeOf(TSpriteLine));
    with TSpriteEx(ptr(PChar(m.Memory) + sz0)^), Sprite do
    begin
      w:= b.Width;
      h:= b.Height;
      Palette:= pal;
      unk_1:= 0;
      yskip:= h;
      unk_2:= 0;

      b.HandleType:= bmDIB;
      scan0:= nil;
      dscan:= 0;
      if h > 0 then  scan0:= b.ScanLine[0];
      if h > 1 then  dscan:= IntPtr(b.ScanLine[1]) - IntPtr(scan0);

      bp:= 0;
      for i := 0 to h - 1 do
        with Lines[i] do
        begin
          p:= scan0 + dscan*i;
          k:= w - 1;
          while (k >= 0) and ((p + k)^ = #0) do  dec(k);

          if k >= 0 then
          begin
            yskip:= h - i - 1;
            j:= 0;
            while ((p + j)^ = #0) do  inc(j);
            a1:= j;
            a2:= k;
            pos:= bp;
            buf.WriteBuffer((p + j)^, k - j + 1);
            inc(bp, k - j + 1);
          end else
          begin
            a1:= -1;
            a2:= -1;
            pos:= 0;
          end;
        end;
      buf.Seek(0, 0);
      Zip(m, buf, buf.Size, @Size, @UnpSize);
    end;
  finally
    b.HandleType:= oldht;
    buf.Free;
  end;
end;

procedure TRSLod.PackStr(m: TMemoryStream; Data: TStream; Size: int);
var
  s: string;
  a: TStream;
  i: int;
begin
  SetLength(s, Size);
  Data.ReadBuffer(s[1], Size);
  i:= length(s);
  while (i > 0) and (s[i] <> #0) do
    dec(i);
  if i = 0 then  // no #0 found
    s:= RSStringReplace(s, #13#10, #0);
  a:= TRSStringStream.Create(s);
  try
    with PMMLodFile(FFiles.Options.NameSize)^ do
      Zip(m, a, length(s), int(@DataSize), int(@UnpSize));
  finally
    a.Free;
  end;
end;

procedure TRSLod.SetBitmapsLod(v: TRSLod);
var
  i: int;
begin
  if v <> nil then
  begin
    if BitmapsLods = nil then
      SetLength(BitmapsLods, 1);
    BitmapsLods[0]:= v;
  end else
    if BitmapsLods <> nil then
    begin
      if OwnBitmapsLod then
        for i := 0 to high(BitmapsLods) do
          if BitmapsLods[i] <> self then
            BitmapsLods[i].Free;
      BitmapsLods:= nil;
    end;
end;

procedure TRSLod.StdNeedBitmapsLod(Sender: TObject);
begin
  with Sender as TRSLod do
    LoadBitmapsLods(ExtractFilePath(RawFiles.FileName));
end;

procedure TRSLod.UnpackBitmap(data: TStream; b: TBitmap; const FileHeader);
var
  m: TMemoryStream;
  hdr: TMMLodFile absolute FileHeader;
begin
  Assert(hdr.BmpSize = hdr.BmpWidth*hdr.BmpHeight);
  m:= TMemoryStream.Create;
  with b do
    try
      m.Size:= 768;
      data.Seek(hdr.DataSize, soCurrent);
      data.ReadBuffer(m.Memory^, 768);
      PixelFormat:= pf8bit;
      Palette:= RSMakePalette(m.Memory);

      data.Seek(-hdr.DataSize - 768, soCurrent);
      Unzip(data, m, hdr.DataSize, hdr.UnpSize, true);

      Width:= hdr.BmpWidth;
      Height:= hdr.BmpHeight;
      RSBufferToBitmap(m.Memory, b);
      FLastPalette:= hdr.Palette;
    finally
      m.Free;
    end
end;

{
procedure TRSLod.UnpackBitmap(data: TStream; b: TBitmap; const FileHeader);
var
  j: int;
  m, a: TMemoryStream;
  hdr: TMMLodFile absolute FileHeader;
begin
  Assert(hdr.BmpSize = hdr.BmpWidth*hdr.BmpHeight);
  m:= TMemoryStream.Create;
  a:= TMemoryStream.Create;
  with b do
    try
      PixelFormat:= pf8bit;

      Unzip(data, m, hdr.DataSize, hdr.UnpSize, true);

      Width:= hdr.BmpWidth;
      Height:= hdr.BmpHeight;

      Assert(FFiles.FindFile(Format('pal%.3d', [int(hdr.Palette)]), j));
      a:= ptr(Extract(j));
      Palette:= RSMakePalette(a.Memory);

      RSBufferToBitmap(m.Memory, b);
    finally
      m.Free;
      a.Free;
    end
end;
}

procedure TRSLod.UnpackPcx(data: TMemoryStream; b: TBitmap);
var
  w, h, len, ByteCount:int;
  p: PChar;
begin
  p:= data.Memory;
  with PPCXFileHeader(p)^ do
  begin
    len:= ImageSize;
    w:= Width;
    h:= Height;
  end;
  inc(p, SizeOf(TPCXFileHeader));
  if w*h <> 0 then
    ByteCount:= len div (w*h)
  else
    if data.Size >= SizeOf(TPCXFileHeader) + 256*3 then
      ByteCount:= 1
    else
      ByteCount:= 3;
      
  Assert(ByteCount*w*h=len);
  Assert(ByteCount in [1,3] {, 'Unsupported bitmap type. Bits per pixel = '
                             + IntToStr(ByteCount*8)});
  with b do
  begin
    Width:=0;
    Height:=0;

    if ByteCount = 1 then
    begin
      PixelFormat:= pf8bit;
      Palette:= RSMakePalette(p + len)
    end else
      PixelFormat:= pf24bit;

    Width:=w;
    Height:=h;
    RSBufferToBitmap(p, b, Rect(0,0,w,h));
  end;
end;

procedure TRSLod.UnpackSprite(const name: string; data: TStream; b: TBitmap; size: int);
{
  function FindPals(a1, a2: int): int;
  begin
    if not BitmapsLod.RawFiles.FindFile(Format('pal%.3d', [a1]), Result) and
       ((a1 = a2) or not BitmapsLod.RawFiles.FindFile(Format('pal%.3d', [a2]), Result)) then
      raise ERSLodException.CreateFmt(SRSLodPalNotFound, [a1]);
  end;
}
var
  hdr: TSprite;
  Lines: array of TSpriteLine;
  lod: TRSMMArchive;
  a: TMemoryStream;
  i, j, w, dy: int;
  p, pbuf: PChar;
begin
  if (BitmapsLods = nil) and Assigned(OnNeedBitmapsLod) then
    OnNeedBitmapsLod(self);
  if BitmapsLods = nil then
    raise ERSLodException.Create(SRSLodSpriteExtractNeedLods);
  data.ReadBuffer(hdr, SizeOf(hdr));
  {
  if not FindSpritePal(name, pal) then
    pal:= hdr.Palette;
  if pal = hdr.Palette + 1 then
    j:= FindPals(hdr.Palette, pal)
  else
    j:= FindPals(pal, hdr.Palette);
  }
  if Assigned(OnSpritePalette) then
    OnSpritePalette(self, name, hdr.Palette, hdr);
  if not RSMMArchivesFind(BitmapsLods, Format('pal%.3d', [int(hdr.Palette)]), lod, j){ and
     (not FindSpritePal(name, pal) or
      not BitmapsLod.RawFiles.FindFile(Format('pal%.3d', [int(pal)]), j))} then
    raise ERSLodException.CreateFmt(SRSLodPalNotFound, [int(hdr.Palette), name]);

  FLastPalette:= hdr.Palette;
  SetLength(Lines, hdr.h);
  data.ReadBuffer(Lines[0], hdr.h*SizeOf(TSpriteLine));

  a:= TMemoryStream.Create;
  try
    lod.Extract(j, a);
    b.HandleType:= bmDIB;
    b.PixelFormat:= pf8bit;
    b.Palette:= RSMakePalette(a.Memory);
    b.Width:= hdr.w;
    b.Height:= hdr.h;

    if hdr.h = 0 then
      exit;
      
    a.Clear;
    Unzip(data, a, size - SizeOf(hdr) - hdr.h*SizeOf(TSpriteLine), hdr.UnpSize, true);
    pbuf:= a.Memory;

    p:= b.ScanLine[0];
    dy:= 0;
    if hdr.h > 1 then
      dy:= int(b.ScanLine[1]) - int(p);
    w:= hdr.w;
    for i := 0 to hdr.h - 1 do
    begin
      with Lines[i] do
        if a1 >= 0 then
        begin
          ZeroMemory(p, a1);
          CopyMemory(p + a1, pbuf + pos, a2 - a1 + 1);
          ZeroMemory(p + a2 + 1, w - a2 - 1);
        end else
          ZeroMemory(p, w);
      inc(p, dy);
    end;
      
  finally
    a.Free;
  end;
end;

procedure TRSLod.UnpackStr(a, Output: TStream; const FileHeader);
var
  m: TRSStringStream;
  hdr: TMMLodFile absolute FileHeader;
  s: string;
begin
  m:= TRSStringStream.Create(s);
  try
    Unzip(a, m, hdr.DataSize, hdr.UnpSize, true);
    s:= RSStringReplace(s, #0, #13#10);
  finally
    m.Free;
  end;
  Output.WriteBuffer(s[1], length(s));
end;

procedure TRSLod.Unzip(input, output: TStream; size, unp: int; noless: Boolean);
begin
  if unp <> 0 then
    if not FFiles.IgnoreUnzipErrors then
    begin
      input:= TDecompressionStream.Create(input);
      try
        RSCopyStream(output, input, unp);
      finally
        input.Free;
      end;
    end else
      UnzipIgnoreErrors(output, input, unp, noless)
  else
    RSCopyStream(output, input, size);
end;

procedure TRSLod.Zip(output: TMemoryStream; buf: TStream; size, pk, unp: int);
var
  a: TStream;
  i: int;
begin
  i:= output.Seek(int(0), soEnd);
  if (size > 256) and (pk >= 0) then
  begin
    a:= TCompressionStream.Create(clDefault, output);
    try
      RSCopyStream(a, buf, size);
    finally
      a.Free;
    end;
    i:= output.Seek(int(0), soEnd) - i;
    if i < size then
    begin
      pint(PChar(output.Memory) + pk)^:= i;
      pint(PChar(output.Memory) + unp)^:= size;
      exit;
    end else
    begin
      i:= output.Seek(-i, soEnd);
      buf.Seek(-size, soCurrent);
    end;
  end;
  output.SetSize(i + size);
  buf.ReadBuffer((PChar(output.Memory) + i)^, size);
  if pk >= 0 then
    pint(PChar(output.Memory) + pk)^:= size;
  pint(PChar(output.Memory) + unp)^:= 0;
  output.Seek(0, soEnd);
end;

procedure TRSLod.Zip(output:TMemoryStream; buf:TStream; size: int;
   DataSize, UnpackedSize: ptr);
var
  p: PChar;
begin
  p:= PChar(output.Memory);
  Zip(output, buf, size, int(PChar(DataSize) - p), int(PChar(UnpackedSize) - p));
end;

{ TRSLwd }

constructor TRSLwd.CreateInternal(Files: TRSMMFiles);
begin
  inherited;
  TransparentColor:= Graphics.clDefault;
end;

procedure TRSLwd.DoPackBitmap(b: TBitmap; var b1, b2: TBitmap; var hdr; m,
  buf: TMemoryStream; Keep: Boolean);
var
  trans: int;
begin
  with buf, TMMLodFile(hdr) do
  begin
    if (FVersion <> RSLodBitmaps) or (BmpSize = 0) then
    begin
      inherited;
      exit;
    end;
    if Keep and ((b.PixelFormat <> pf24bit) or (b.HandleType <> bmDIB)) then
    begin
      b1:= TBitmap.Create;
      b1.Assign(b);
    end;
    b1.HandleType:= bmDIB;
    b1.PixelFormat:= pf24bit;
    SetSize(BmpSize*3 + 1);
    RSBitmapToBuffer(Memory, b1);
    trans:= PackLwd(Memory, BmpWidth, BmpHeight, m);
    Zip(m, buf, BmpSize*3, @DataSize, @UnpSize);
  end;
  m.WriteBuffer(trans, 4);
end;

procedure TRSLwd.FindBitmapPalette(const name: string; b: TBitmap; var pal, Bits: int);
begin
  pal:= 0;
  Bits:= $12;
end;

function TRSLwd.FindDimentions(p: PChar): TColor;
var
  a: TStream;
  lod: TRSMMArchive;
  rec: TMMLodFile;
  c, j: int;
begin
  Result:= Graphics.clDefault;
  if BitmapsLods = nil then
    StdNeedBitmapsLod(self);
  if (BitmapsLods = nil) or not RSMMArchivesFind(BitmapsLods, PChar(p), lod, j) then
    exit;
  a:= lod.FFiles.GetAsIsFileStream(j, true);
  try
    a.Seek(16, soFromCurrent);
    if a.Read(rec, SizeOf(rec)) = SizeOf(rec) then
      with PMMLodFile(p + 16)^ do
      begin
        BmpWidth:= rec.BmpWidth;
        BmpHeight:= rec.BmpHeight;
        a.Seek(rec.DataSize, soFromCurrent);
        c:= 0;
        if a.Read(c, 3) = 3 then
          if (c = $FFFF00) or (c = $FF00FF) or (c = $FC00FC) or (c = $FCFC00) then
            Result:= c
          else
            Result:= Graphics.clNone;
      end;
  finally
    lod.FFiles.FreeAsIsFileStream(j, a);
  end;
end;

function TRSLwd.PackLwd(p: PChar; w, h: int; m: TMemoryStream): int;
var
  i, c: int;
begin
  Result:= FindDimentions(m.Memory);
  if TransparentColor <> Graphics.clDefault then
    Result:= TransparentColor;
  if Result <> Graphics.clDefault then
  begin
    if Result <> Graphics.clNone then
      Result:= RSSwapColor(ColorToRGB(Result));
    exit;
  end;
  for i:= w*h downto 1 do
  begin
    c:= pint(p)^ and $FFFFFF;
    if Result = Graphics.clDefault then
      if (c = $FFFF) or (c = $FF00FF) or (c = $FC00FC) or (c = $FCFC) then
      begin
        Result:= c;  // Margenta/light blue for transparency
        exit;
      end;
    inc(p, 3);
  end;
  Result:= Graphics.clNone;
end;

procedure TRSLwd.UnpackBitmap(data: TStream; b: TBitmap; const FileHeader);
begin
  with TMMLodFile(FileHeader) do
    if (Palette = 0) and ((UnpSize > BmpSize*2) or (UnpSize = 0) and (DataSize > BmpSize*2)) then
      UnpackLwd(data, b, FileHeader)
    else
      inherited;
end;

procedure TRSLwd.UnpackLwd(data: TStream; b: TBitmap; const FileHeader);
var
  hdr: TMMLodFile absolute FileHeader;
  m: TMemoryStream;
begin
  m:= TMemoryStream.Create;
  with b do
    try
      Unzip(data, m, hdr.DataSize, hdr.UnpSize, true);

      PixelFormat:= pf24bit;
      Width:= PowerOf2[hdr.BmpWidthLn2];
      Height:= PowerOf2[hdr.BmpHeightLn2];
      RSBufferToBitmap(m.Memory, b);
      FLastPalette:= hdr.Palette;
    finally
      m.Free;
    end
end;

{ TRSSnd }

function TRSSnd.Add(const Name: string; Data: TStream; Size, pal: int): int;
begin
  Result:= FFiles.Add(ChangeFileExt(Name, ''), Data, Size);
end;

function TRSSnd.CloneForProcessing(const NewFile: string; FilesCount: int): TRSMMArchive;
begin
  Result:= inherited CloneForProcessing(NewFile, FilesCount);
  TRSSnd(Result).FMM:= FMM;
end;

function TRSSnd.GetExtractName(Index: int): string;
begin
  Result:= FFiles.Name[Index] + '.wav';
end;

procedure TRSSnd.InitOptions(var Options: TRSMMFilesOptions);
begin
  with Options do
  begin
    NameSize:= $28;
    AddrOffset:= $28;
    SizeOffset:= $2C;
    if FMM then
    begin
      UnpackedSizeOffset:= $30;
      ItemSize:= $34;
    end else
      ItemSize:= $30;

    DataStart:= 4;
    AddrStart:= 0;
    MinFileSize:= 0;
  end;
end;

procedure TRSSnd.New(const FileName: string; MightAndMagic: Boolean);
var
  o: TRSMMFilesOptions;
begin
  FMM:= MightAndMagic;
  RSMMFilesOptionsInitialize(o);
  InitOptions(o);
  FFiles.New(FileName, o);
end;

type
  TSndOneFilePart = record
    Count: DWord;
    Name: array[1..$28] of char;
    Addr: DWord;
    Size: DWord;
    UnpSize: DWord;
  end;

procedure TRSSnd.ReadHeader(Sender: TRSMMFiles; Stream: TStream;
   var Options: TRSMMFilesOptions; var FilesCount: int);
const
  aWav = $4952;
  aZip = $9C78;
var
  OneFilePart: TSndOneFilePart;
  Sig: word;
  readCount: int;
begin
  readCount:= Stream.Read(OneFilePart, SizeOf(OneFilePart));
  if readCount < 4 then
    raise ERSLodException.Create(SRSLodUnknownSnd);

  FilesCount:= OneFilePart.Count;
  // heuristics to find the type of archive
  if (OneFilePart.Count > 0) and (readCount >= SizeOf(TSndOneFilePart)) then
  begin
    Stream.Seek(OneFilePart.Addr, 0);
    sig:= 0;
    Stream.Read(Sig, 2);
    FMM:= (sig = aZip) or (OneFilePart.UnpSize = OneFilePart.Size);
    {MyReadBuffer(Stream, Sig, 2);
    case sig of
      aWav:  FMM:= OneFilePart.UnpSize = OneFilePart.Size; // Not for sure
      aZip:  FMM:= true;
      else
        raise ERSLodException.Create(SRSLodUnknownSnd);
    end;
    }
  end else
    FMM:= (OneFilePart.Count = 0) and
          not FileExists(ExtractFilePath(FFiles.FileName) + 'H3sprite.lod');

  InitOptions(Options);
end;

procedure TRSSnd.WriteHeader(Sender: TRSMMFiles; Stream: TStream);
var i: int;
begin
  i:= Sender.Count;
  Stream.WriteBuffer(i, 4);
end;

{ TRSVid }

function TRSVid.Add(const Name: string; Data: TStream; Size, pal: int): int;
begin
  if FNoExtension and SameText(ExtractFileExt(Name), '.smk') then
    Result:= inherited Add(ChangeFileExt(Name, ''), Data, Size, pal)
  else
    Result:= inherited Add(Name, Data, Size, pal)
end;

function TRSVid.CloneForProcessing(const NewFile: string; FilesCount: int): TRSMMArchive;
begin
  Result:= inherited CloneForProcessing(NewFile, FilesCount);
  TRSVid(Result).FNoExtension:= FNoExtension;
end;

constructor TRSVid.CreateInternal(Files: TRSMMFiles);
begin
  inc(FTagSize, 4);
  inherited;
  FFiles.OnGetFileSize:= GetFileSize;
  FFiles.OnSetFileSize:= SetFileSize;
end;

{type
  TVideoHeaderPart = record
    Signature: array[0..2] of char;
    Version: byte;
    case Integer of
      0:
      (
        BinkSize:DWord;
      );
      1:
      (
        Width: int;
        Height: int;
        Count: int;
        FrameRate: int;
        Flags: int;
        AudioBiggestSize: array[0..6] of int;
        TreesSize: uint;
      );
  end;

function TRSVid.DoGetFileSize(Stream: TStream; sz: uint): uint;
var
  Header: TVideoHeaderPart;
  Sizes: array of uint;
  i, n: uint;
begin
  Result:= sz;
  //exit;  // tmp
  if Stream.Read(Header, SizeOf(Header)) <> SizeOf(Header) then  exit;
  with Stream, Header do
    if Signature[0] = 'S' then
    begin
      Seek($68 - SizeOf(Header), 1);
      n:= Count;
      if (Flags and 1) <> 0 then
        inc(n);
      Result:= TreesSize + $68 + n*5;
      if Result < sz then
      begin
        SetLength(Sizes, n);
        Read(Sizes[0], n*4);
        for i:= 0 to n - 1 do
        begin
          inc(Result, Sizes[i] and not 3);
          if Result > sz then  break;
        end;
      end;
    end else
      if Signature[0] = 'B' then
        Result:= Header.BinkSize + 8;

  if Result > sz then
    Result:= sz;
end;}

function TRSVid.GetExtractName(Index: int): string;
begin
  Result:= FFiles.Name[Index];
  if ExtractFileExt(Result) = '' then
    Result:= Result + '.smk';
end;

procedure TRSVid.GetFileSize(Sender: TRSMMFiles; Index: int; var Size: int);
var
  sz, start, j: uint;
  i: int;
  r: TStream;
begin
  Size:= pint(FFiles.UserData[Index])^;
  if Size = 0 then
  begin
    r:= FFiles.GetAsIsFileStream(Index, true);
    try
      start:= r.Position;
      if FInitSizeTable <> nil then
      begin
        sz:= start + FInitSizeTable[Index];
        if Index = FFiles.Count - 1 then
          FInitSizeTable:= nil;
      end else
        sz:= r.Size;

      if r is TFileStream then
        for i:= 0 to FFiles.Count - 1 do
          if (zSet(j, FFiles.Address[i]) >= start) and (j < sz) and (i <> Index) then
            sz:= j;
      Size:= sz - start; //DoGetFileSize(r, MaxInt {sz - start});
      {if Size <> sz - start then
        RSAppendTextFile('c:\sizes.txt', Format('%s'#9'%d'#9'%d'#13#10, [FFiles.Name[Index], Size, sz - start]));}
    finally
      FFiles.FreeAsIsFileStream(Index, r);
    end;
    pint(FFiles.UserData[Index])^:= Size + 1;
  end else
    dec(Size);
end;

procedure TRSVid.InitOptions(var Options: TRSMMFilesOptions);
begin
  with Options do
  begin
    NameSize:= $28;
    AddrOffset:= $28;
    ItemSize:= $2C;
    DataStart:= 4;
    AddrStart:= 0;
    MinFileSize:= 0;
  end;
end;

procedure TRSVid.Load(const FileName: string);
var
  s: string;
  i: int;
begin
  FNoExtension:= false;
  inherited;
  for i := 0 to FFiles.Count - 1 do
  begin
    s:= ExtractFileExt(FFiles.Name[i]);
    if s = '' then
    begin
      FNoExtension:= true;
      exit;
    end else
      if SameText(s, '.smk') then
        exit;
  end;
end;

function TRSVid.NeedNoExtSig: Boolean;
var
  i: int;
begin
  Result:= false;
  if not FNoExtension then
    exit;
  for i := 0 to FFiles.Count - 1 do
    if ExtractFileExt(FFiles.Name[i]) = '' then
      exit;
  Result:= true;
end;

function TRSVid.NeedSizeTable(Stream: TStream): Boolean;
var
  sz, f1: uint;
  i: int;
begin
  f1:= Stream.Size;
  for i := 0 to FFiles.Count - 1 do
    if FFiles.GetAddress(i) < f1 then
      f1:= FFiles.GetAddress(i);
  sz:= 0;
  for i := 0 to FFiles.Count - 1 do
    inc(sz, FFiles.Size[i]);
  Result:= (f1 + sz <> Stream.Size);
end;

procedure TRSVid.New(const FileName: string; NoExtension: Boolean);
var
  o: TRSMMFilesOptions;
begin
  FNoExtension:= NoExtension;
  RSMMFilesOptionsInitialize(o);
  InitOptions(o);
  FFiles.New(FileName, o);
end;

procedure TRSVid.ReadHeader(Sender: TRSMMFiles; Stream: TStream;
   var Options: TRSMMFilesOptions; var FilesCount: int);
var
  s1: string;
begin
  MyReadBuffer(Stream, FilesCount, 4);
  InitOptions(Options);
  SetLength(s1, VidSizeSigSize);
  Stream.Seek(-VidSizeSigSize, soFromEnd);
  if Stream.Read(s1[1], VidSizeSigSize) <> VidSizeSigSize then  exit;
  if s1 = VidSizeSigOld then  // old way of beta version of MMArchive
  begin
    Stream.Seek(-VidSizeSigSize - FilesCount*4, soFromEnd);
    if FilesCount = 0 then  exit;
    SetLength(FInitSizeTable, FilesCount);
    MyReadBuffer(Stream, FInitSizeTable[0], FilesCount*4);
    exit;
  end;
  if s1 = VidSizeSigEnd then
  begin
    Stream.Seek(-VidSizeSigSize*2 - FilesCount*4, soFromEnd);
    if (Stream.Read(s1[1], VidSizeSigSize) <> VidSizeSigSize) or (s1 <> VidSizeSigStart) then
      exit;

    if FilesCount <> 0 then
    begin
      SetLength(FInitSizeTable, FilesCount);
      MyReadBuffer(Stream, FInitSizeTable[0], FilesCount*4);
      Stream.Seek(-VidSizeSigSize*2 - FilesCount*4, soFromCurrent);
      if Stream.Read(s1[1], VidSizeSigSize) <> VidSizeSigSize then
        exit;
    end;
  end;
  if s1 = VidSizeSigNoExt then
    FNoExtension:= true;
    
  Stream.Seek(4, 0);
end;

procedure TRSVid.SetFileSize(Sender: TRSMMFiles; Index, Size: int);
begin
  pint(FFiles.UserData[Index])^:= Size + 1;
end;

procedure TRSVid.WriteHeader(Sender: TRSMMFiles; Stream: TStream);
var
  a: array of int;
  NeedSize, NeedNoExt: Boolean;
  sz: uint;
  i, n: int;
begin
  n:= FFiles.Count;
  Stream.WriteBuffer(n, 4);
  NeedSize:= NeedSizeTable(Stream);
  NeedNoExt:= NeedNoExtSig;
  i:= 0;
  if NeedSize then
    i:= VidSizeSigSize*2 + n*4;
  if NeedNoExt then
    inc(i, VidSizeSigSize);
  if i = 0 then
    exit;

  sz:= max(Stream.Size - i, FFiles.FOptions.DataStart);
  for i := 0 to n - 1 do
    sz:= max(sz, FFiles.Address[i] + uint(FFiles.Size[i]));

  Stream.Position:= sz;
  if NeedNoExt then
    Stream.WriteBuffer(VidSizeSigNoExt[1], VidSizeSigSize);

  if NeedSize then
  begin
    SetLength(a, n);
    for i := 0 to n - 1 do
      a[i]:= FFiles.Size[i];

    Stream.WriteBuffer(VidSizeSigStart[1], VidSizeSigSize);
    Stream.WriteBuffer(a[0], n*4);
    Stream.WriteBuffer(VidSizeSigEnd[1], VidSizeSigSize);
  end;
end;

{------------------------------------------------------------------------------}

procedure RSMMFilesOptionsInitialize(var Options: TRSMMFilesOptions);
begin
  with Options do
  begin
    NameSize:= 0;
    AddrOffset:= -1;
    SizeOffset:= -1;
    UnpackedSizeOffset:= -1;
    PackedSizeOffset:= -1;
    ItemSize:= 0;
    DataStart:= 0;
    AddrStart:= 0;
    MinFileSize:= 0;
  end;
end;

function RSLoadMMArchive(const FileName: string): TRSMMArchive;
var
  ext: string;
begin
  ext:= LowerCase(ExtractFileExt(FileName));
  if ext = '.snd' then
    Result:= TRSSnd.Create(FileName)
  else if ext = '.vid' then
    Result:= TRSVid.Create(FileName)
  else if ext = '.lwd' then
    Result:= TRSLwd.Create(FileName)
  else
    Result:= TRSLod.Create(FileName);
end;

function RSMMArchivesFind(const a: TRSMMArchivesArray; const Name: string;
   var Archive: TRSMMArchive; var Index: int): Boolean;
var
  i: int;
begin
  Result:= false;
  for i := high(a) downto 0 do
  begin
    Result:= a[i].RawFiles.FindFile(Name, Index);
    Archive:= a[i];
    if Result then
      break;
  end;
end;

function RSMMArchivesFindSamePalette(const a: TRSMMArchivesArray; const PalEntries): int;
var
  i: int;
begin
  for i := high(a) downto 0 do
    if (a[i] is TRSLod) and TRSLod(a[i]).FindSamePalette(PalEntries, Result) then
      exit;
  Result:= 0;
end;

function RSMMArchivesCheckFileChanged(const a: TRSMMArchivesArray; Ignore: TRSMMArchive = nil): Boolean;
var
  i: int;
begin
  Result:= false;
  for i := 0 to high(a) do
    if (a[i] <> Ignore) and a[i].RawFiles.CheckFileChanged then
      Result:= true;
end;

procedure RSMMArchivesFree(var a: TRSMMArchivesArray);
var
  i: int;
begin
  for i := 0 to high(a) do
    a[i].Free;
  a:= nil;
end;

function RSMMPaletteToBitmap(const a: TRSByteArray): TBitmap;
const
  Data = #0#1#2#3#4#5#6#7#8#9#10#11#12#13#14#15#16#17#18#19#20#21#22#23#24#25#26#27#28#29#30#31#32#33#34#35#36#37#38#39#40#41#42#43#44#45#46#47#48#49#50#51#52#53#54#55#56#57#58#59#60#61#62#63#64#65#66#67#68#69#70#71#72#73#74#75#76#77#78#79#80#81#82#83#84#85#86#87#88#89#90#91#92#93#94#95#96#97#98#99#100#101#102#103#104#105#106#107#108#109#110#111#112#113#114#115#116#117#118#119#120#121#122#123#124#125#126#127 + #128#129#130#131#132#133#134#135#136#137#138#139#140#141#142#143#144#145#146#147#148#149#150#151#152#153#154#155#156#157#158#159#160#161#162#163#164#165#166#167#168#169#170#171#172#173#174#175#176#177#178#179#180#181#182#183#184#185#186#187#188#189#190#191#192#193#194#195#196#197#198#199#200#201#202#203#204#205#206#207#208#209#210#211#212#213#214#215#216#217#218#219#220#221#222#223#224#225#226#227#228#229#230#231#232#233#234#235#236#237#238#239#240#241#242#243#244#245#246#247#248#249#250#251#252#253#254#255;
begin
  Assert(length(a) = 768);
  Result:= TBitmap.Create;
  with Result do
    try
      PixelFormat:= pf8bit;
      Palette:= RSMakePalette(ptr(a));
      Width:= 16;
      Height:= 16;
      RSBufferToBitmap(@Data[1], Result);
    except
      Free;
      raise;
    end
end;

end.

