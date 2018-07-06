unit RSSysUtils;

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
  SysUtils, Windows, Messages, SysConst, ShellAPI, Classes, RSQ, Types, Math,
  RTLConsts;

type
  TRSApproveEvent = procedure(Sender:TObject; var Handled: Boolean) of object;

  TRSByteArray = Types.TByteDynArray; //packed array of byte;
  PRSByteArray = ^TRSByteArray;

  PWMMoving = ^TWMMoving;

  TRSArrayStream = class(TMemoryStream)
  protected
    FArr: PRSByteArray;
    function Realloc(var NewCapacity: Longint): Pointer; override;
  public
    constructor Create(var a: TRSByteArray);
    destructor Destroy; override;
  end;

  TRSStringStream = class(TMemoryStream)
  protected
    FStr: ^string;
    function Realloc(var NewCapacity: Longint): Pointer; override;
  public
    constructor Create(var a: string);
    destructor Destroy; override;
  end;

  TRSReplaceStream = class(TStream)
  protected
    FMain: TStream;
    FReplace: TStream;
    FRepPos: Int64;
    FRepLim: Int64;
    FPos: Int64;
    FOwnMain: Boolean;
    FOwnRep: Boolean;
    function GetSize: Int64; override;
    procedure SetSize(NewSize: Longint); overload; override;
    procedure SetSize(const NewSize: Int64); overload; override;
  public
    constructor Create(Main, Replace: TStream; OwnMain, OwnReplace: Boolean; Pos: Int64);
    destructor Destroy; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
  end;
  
  TRSCompositeStream = class(TStream) // never tested, just an unused draft
  protected
    FPosition: int;
    FStreams: TList;
    FOwnStreams: Boolean;
    FCurrentStream: int;
    function GetSize: Int64; override;
    procedure SetSize(NewSize: Longint); overload; override;
    procedure SetSize(const NewSize: Int64); overload; override;
  public
    constructor Create;
    //constructor Create(const Streams: array of TStream; OwnStreams: Boolean);
    destructor Destroy; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    procedure AddStream(a: TStream);
  end;

  TRSFileStreamProxy = class(TFileStream)
  protected
    FMode: Word;
    FRights: Cardinal;
{$IFNDEF D2006}
    FFileName: string;
{$ENDIF}
    procedure Check;
    procedure SetSize(NewSize: Longint); override;
    procedure SetSize(const NewSize: Int64); override;
  public
    CreateDir: Boolean;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    constructor Create(const AFileName: string; Mode: Word); overload;
    constructor Create(const AFileName: string; Mode: Word; Rights: Cardinal); overload;
{$IFNDEF D2006}
    property FileName: string read FFileName;
{$ENDIF}
  end;

var
  RSWndExceptions: Boolean = true;

type
   // Usage: TRSWnd(hWnd)
  TRSWnd = class
  private
    function GetAbsoluteRect: TRect;
    function GetBoundsRect: TRect;
    function GetExtendedBoundsRect: TRect; deprecated; // turned out to be buggy (on multimonitor Win 10)
    function GetClientRect: TRect;
    function GetClass: string;
    function GetExStyle: LongInt;
    function GetHeight: LongInt;
    function GetId: LongInt;
    function GetProcessId: DWord;
    function GetStayOnTop: Boolean;
    function GetStyle: LongInt;
    function GetText: string;
    function GetThreadId: DWord;
    function GetVisible:boolean;
    function GetWidth: LongInt;
    procedure SetAbsoluteRect(v: TRect);
    procedure SetBoundsRect(const v: TRect);
    procedure SetExStyle(v: LongInt);
    procedure SetHeight(v: LongInt);
    procedure SetId(v: LongInt);
    procedure SetStayOnTop(v: Boolean);
    procedure SetStyle(v: LongInt);
    procedure SetText(const v: string);
    procedure SetVisible(v: boolean);
    procedure SetWidth(v: LongInt);
    function GetLeft: LongInt;
    function GetTop: LongInt;
    procedure SetLeft(v: LongInt);
    procedure SetTop(v: LongInt);
  public
    class function Create(ClassName:PChar; WindowName:PChar; Style:DWORD;
      X, Y, Width, Height:Integer; hWndParent: HWND; hMenu:HMENU;
      hInstance:HINST; lpParam:Pointer=nil; ExStyle:DWORD=0):TRSWnd;
    destructor Destroy; override;
    procedure BorderChanged;
    function OpenProcess(dwDesiredAccess:DWORD=PROCESS_ALL_ACCESS;
            bInheritHandle:boolean=false): DWord;
    procedure SetBounds(x, y, w, h:int);
    procedure SetPosition(x, y:int);

    property AbsoluteRect: TRect read GetAbsoluteRect write SetAbsoluteRect;
    property BoundsRect: TRect read GetBoundsRect write SetBoundsRect;
    property ExtendedBoundsRect: TRect read GetExtendedBoundsRect;
    property ClientRect: TRect read GetClientRect;
{$WARNINGS OFF}
    property ClassName: string read GetClass;
{$WARNINGS ON}
    property ExStyle: LongInt read GetExStyle write SetExStyle;
    property Id: LongInt read GetId write SetId;
    property ProcessId: DWord read GetProcessId;
    property StayOnTop: Boolean read GetStayOnTop write SetStayOnTop;
    property Style: LongInt read GetStyle write SetStyle;
    property Text: string read GetText write SetText;
    property ThreadId: DWord read GetThreadId;
    property Visible: boolean read GetVisible write SetVisible;
    property Width: LongInt read GetWidth write SetWidth;
    property Height: LongInt read GetHeight write SetHeight;
    property Top: LongInt read GetTop write SetTop;
    property Left: LongInt read GetLeft write SetLeft;
  end;

   // Usage: TRSBits(PByte, PWord or pointer to data of any size)
   // For example, TRSBits(@i).';
  TRSBits = class
  private
    function GetBit(i:DWord): Boolean;
    procedure SetBit(i:DWord; v: Boolean);
  public
    constructor Create;
    procedure FromBooleans(Buffer:pointer; Count:DWord; StartIndex:DWord = 0);
    procedure ToBooleans(Buffer:pointer; Count:DWord; StartIndex:DWord = 0);
    property Bit[i:DWord]: Boolean read GetBit write SetBit; default;
  end;

   // No adding overhead at the cost of 4 bytes per block
  TRSCustomStack = class(TObject)
  private
    function GetSize:int;
  protected
    FBlockSize: int;
    FBlock: ptr; // First DWord = PLastBlock, then there goes data
    FNextBlock: ptr; // In case of pop
    FBlockCount: int;
    FLastSize: int; // Including PLastBlock
    FVirtualAlloc: Boolean;
    function AllocBlock:ptr; virtual;
    procedure FreeBlock(ABlock:ptr); virtual;
    function NewBlock:ptr;
    function WholePush(Size:int):ptr;
    function WholePop(Size:int):ptr;
    function DoPeakAt(Offset:int):ptr;
    procedure DoPeak(var v; Size:int);

    function BlockNextTo(p:ptr):ptr; // For Queue
  public
    constructor Create(BlockSize:int);
    destructor Destroy; override;
    procedure Clear; virtual;
    property Size: int read GetSize;
  end;

  TRSFixedStack = class(TRSCustomStack)
  protected
    FItemSize: int;
    ExecutableMem: Boolean;
    function GetCount:int; virtual;
     // Unsafe routines
    function AllocBlock:ptr; override;
    procedure FreeBlock(ABlock:ptr); override;
    function DoPush:ptr;
    function DoPop:ptr;
    function DoPeak:ptr; overload;
    function DoPeakAtIndex(Index:int):ptr;
  public
    constructor Create(ItemSize:int; BlockSize:int=4096);

    procedure Peak(var v; Count:int);
    procedure PeakAll(var v);
    property Count: int read GetCount;
  end;

  TRSObjStack = class(TRSFixedStack)
  public
    constructor Create(BlockSize:int = 4096);
    procedure Push(Obj:TObject);
    function Pop:TObject;
    function Peak:TObject; overload;
    function PeakAt(Index:int):TObject;
  end;

(*
   // Thread-safe in case of single writer and single reader (which may be different threads)
  TRSCustomQueue = class(TRSFixedStack)
  protected
    FCount: int;
    FPopBlock: ptr;
    FPopCount: int;
    FPopIndex: int; // Inside block
    FFillEvent: THandle;
    function GetCount:int; override;
    function DoPop:ptr;
    function AfterPush:ptr;
  public
    constructor Create(ItemSize:int; BlockSize:int=4096);
    destructor Destroy; override;
    procedure WaitFor(var Queue:TRSCustomQueue); // Queue var for safe Destroy 
  end;

  TRSObjQueue = class(TRSCustomQueue)
  public
    procedure Push(Obj:TObject);
    function Pop:TObject;
    function Peak:TObject; overload;
    function PeakAt(Index:int):TObject;
  public
    constructor Create(BlockSize:int=4096);
  end;
*)

{
   // Общий случай стека байтов
  TRSStack = class(TRSCustomStack)
    procedure GetSize:int;
  public
    constructor Create(BlockSize:int=PageSize);
    destructor Destroy; override;
    procedure Push(const v; Count:int); overload;
    procedure Pop(var v; Count:int); overload;
    procedure Peak(var v; Count:int); overload;
    procedure PeakAll(var v);
    property Size: int read GetSize;
  end;
}

  TRSSharedData = class(TObject)
  protected
    FAlreadyExists: Boolean;
    FData: ptr;
    FMMF: THandle;
    FSize: int;
  public
    constructor Create(Name:string; Size:int); overload;
    constructor Create(MMF:THandle; Size:int); overload;
    destructor Destroy; override;

    property AlreadyExists: Boolean read FAlreadyExists;
    property Data: ptr read FData write FData;
    property MMF: THandle read FMMF write FMMF;
    property Size: int read FSize;
  end;


  TRSMemoryMappedStream = class(TMemoryStream)
  protected
    FHandle: Integer;
    FFileName: string;
    FWritable: Boolean;
    FMMF: THandle;
    FStartOffset: int64;
    FFileSize: int64;
    procedure CreateMapping(write: Boolean; start: int64; size: DWord);
    function Realloc(var NewCapacity: Longint): Pointer; override;
  public
    constructor Create(const FileName: string; Mode: Word; Start: int64 = 0; Size: DWord = $FFFFFFFF);
    destructor Destroy; override;
    procedure Remap(Start: int64; Size: DWord = $FFFFFFFF);
    property FileName: string read FFileName;
    property FileSize: int64 read FFileSize;
    property StartOffset: int64 read FStartOffset;
    property Handle: Integer read FHandle;
  end;


{ Example:

  with TRSFindFile.Create(FilesMask) do
    try
      while FindEachFile do // Only files
        DoSomething(FileName);
    finally
      Free;
    end;
}
  TRSFindFile = class(TObject)
  protected
    FHandle: THandle;
    FFileName: string;
    FFound: Boolean;
    FNotFirst: Boolean;
    FPath: string;
    FIgnoreDotFolders: Boolean;
    procedure CheckError;
    function GetFileName: string;
  public
    Data: TWin32FindData;
    constructor Create(FileMask:string; IgnoreDotFolders: Boolean = true);
    destructor Destroy; override;
    function FindNext: Boolean;
    function FindAttributes(Require, Exclude:DWord): Boolean;
    function FindNextAttributes(Require, Exclude:DWord): Boolean;
    function FindEachFile: Boolean;
    function FindEachFolder: Boolean;
    property FileName: string read GetFileName;
    property Found: Boolean read FFound;
    property Path: string read FPath;
    property IgnoreDotFolders: Boolean read FIgnoreDotFolders write FIgnoreDotFolders;
  end;

  PRSCmd = ^TRSCmd;
  TRSCmd = record
    InitDone: string;
    SI: TStartupInfo;
    AttributeList: ptr;  // _STARTUPINFOEX member
    PI: TProcessInformation;
    NeedProcessHandle, NeedThreadHandle, InheritHandles: Boolean;
    ApplicationName: string;
    ProcessAttributes, ThreadAttributes: PSecurityAttributes;
    CreationFlags: DWord;
    Environment: ptr;
    function App(const AppName: string): PRSCmd;
    function ShowCmd(showCmd:Word): PRSCmd;
    function Flags(Flags: DWord): PRSCmd;
    function NeedHandles(process: Boolean = true; thread: Boolean = true): PRSCmd;
    function Run(Command: string; Dir: string = ''; Timeout:DWord = INFINITE): Boolean;
  end;

   // Used in RSWindowProc.pas
  TRSEventHook = class(TObject)
  protected
    FEventProc:ptr;
    FPriority:int;
    FLastProc: TMethod;
    FNext: TRSEventHook;
    FLockCount: int;
    FDeleting: boolean;
    function GetEvent:TMethod; virtual; abstract;
    procedure SetEvent(const v:TMethod); virtual; abstract;
    function GetLast:TRSEventHook;
    property ObjEvent:TMethod read GetEvent write SetEvent;
  public
    constructor Create(Priority:int);
    procedure Delete;
    procedure Lock(aLock:boolean);
  end;

  TRSShellChangeNotifier = class(TThread)
  private
    FOnChange: TNotifyEvent;
    function GetNeedRefresh: Boolean;
  protected
    FWakeEvent: THandle;
    FCS: TRTLCriticalSection;
    FReset: Boolean;
    FNeedRefresh: Boolean;

    FDirectory: string;
    FWatchSubTree: Boolean;
    FFlags: DWord;

    procedure Execute; override;
    procedure CallOnChange;
  public
    constructor Create(OnChange: TNotifyEvent = nil); virtual;
    destructor Destroy; override;
    procedure Free;
    procedure Terminate;
    procedure SetOptions(Directory: string; WatchSubTree: Boolean = false;
     Flags:DWord = FILE_NOTIFY_CHANGE_FILE_NAME or FILE_NOTIFY_CHANGE_DIR_NAME);
    procedure Cancel;
    procedure Reset;
    property NeedRefresh: Boolean read GetNeedRefresh write FNeedRefresh;
    property Directory: string read FDirectory;
    property WatchSubTree: Boolean read FWatchSubTree;
    property Flags: DWord read FFlags;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

{--------}

procedure RSCopyStream(Dest, Source: TStream; Count: int64);
function RSMemStreamPtr(m: TCustomMemoryStream): ptr;

procedure RSRaiseLastOSError;
function RSWin32Check(RetVal: BOOL): BOOL; register; overload;
function RSWin32Check(CheckForZero:int):int; register; overload;
function RSWin32Check(CheckForZero:ptr):ptr; register; overload;

procedure RSDispatchEx(Obj:TObject; AClass:TClass; var Message);

 // From Grids.pas
procedure RSFillDWord(Dest:ptr; Count, Value: Integer); register;

function RSQueryPerformanceCounter: int64;
function RSQueryPerformanceFrequency: int64;

{
procedure RSSetLayeredAttribs(Handle:HWnd;
             AlphaBlend:boolean; AlphaBlendValue:byte;
             TransparentColor:boolean; TransparentColorValue:int);
{}

{--------}

function RSGetModuleFileName(hModule: HINST = 0):string;
function RSGetFileVersion(out Major, Minor, Release, Build: int; Path: string): Boolean; overload;
function RSGetFileVersion(Path: string; MinPlaces: int = 2): string; overload;
function RSGetModuleVersion(out Major, Minor, Release, Build: int; Instance: LongWord = 0): Boolean; overload;
function RSGetModuleVersion(Instance: LongWord = 0; MinPlaces: int = 2): string; overload;
function PathFileExists(pszPath: PChar):Bool; stdcall; external 'shlwapi.dll' name 'PathFileExistsA';
function PathFileExistsW(pszPath: PWideChar):Bool; stdcall; external 'shlwapi.dll' name 'PathFileExistsW';
function PathIsRoot(pPath: PChar):Bool; stdcall; external 'shlwapi.dll' name 'PathIsRootA';
function RSFileExists(const FileName: string): Boolean; {$IFDEF D2005}inline;{$ENDIF}

function RSMoveFile(const OldName, NewName: string; FailIfExists: Boolean): Bool;

function RSCreateFile(const FileName:string;
           dwDesiredAccess:DWord = GENERIC_READ or GENERIC_WRITE;
           dwShareMode:DWord = FILE_SHARE_DELETE or FILE_SHARE_READ;
           lpSecurityAttributes:PSecurityAttributes = nil;
           dwCreationDistribution:DWord = CREATE_ALWAYS;
           dwFlagsAndAttributes:DWord = FILE_ATTRIBUTE_NORMAL;
           hTemplateFile:HFile=0):HFile;

const
  REPLACEFILE_IGNORE_MERGE_ERRORS = 2;
  REPLACEFILE_IGNORE_ACL_ERRORS = 4;
  ERROR_UNABLE_TO_MOVE_REPLACEMENT = 1176;
  ERROR_UNABLE_TO_MOVE_REPLACEMENT_2 = 1177;
  ERROR_UNABLE_TO_REMOVE_REPLACED = 1175;

function RSReplaceFile(const Replaced, Replacement: string; const Backup: string = ''; Flags: int = REPLACEFILE_IGNORE_MERGE_ERRORS): Boolean;

function RSLoadFile(FileName:string):TRSByteArray;
procedure RSSaveFile(FileName:string; Data: ptr; L: int); overload;
procedure RSSaveFile(FileName:string; Data:TRSByteArray); overload;
procedure RSSaveFile(FileName:string; Data:TMemoryStream; RespectPosition: Boolean = false); overload;
procedure RSAppendFile(FileName:string; Data: ptr; L: int); overload;
procedure RSAppendFile(FileName:string; Data:TRSByteArray); overload;
procedure RSAppendFile(FileName:string; Data:TMemoryStream; RespectPosition: Boolean = false); overload;

function RSLoadTextFile(FileName:string):string;
procedure RSSaveTextFile(FileName:string; Data:string);
procedure RSAppendTextFile(FileName:string; Data:string);

function RSCreateDir(const PathName:string):boolean;

function RSCreateDirectory(const PathName:string;
           lpSecurityAttributes:PSecurityAttributes = nil):boolean;

function RSCreateDirectoryEx(const lpTemplateDirectory, NewDirectory:string;
           lpSecurityAttributes:PSecurityAttributes = nil):boolean;

function RSRemoveDir(const Dir: string):boolean; deprecated;
function RSDeleteAll(const Mask: string; Folders: boolean): boolean;

const
  FO_MOVE = ShellAPI.FO_MOVE;
  FO_COPY = ShellAPI.FO_COPY;
  FO_DELETE = ShellAPI.FO_DELETE;
  FO_RENAME = ShellAPI.FO_RENAME;

function RSFileOperation(const aFrom, aTo:string; FileOperation: uint;
   Flags: FILEOP_FLAGS = FOF_NOCONFIRMATION or FOF_NOCONFIRMMKDIR or
          FOF_NOERRORUI or FOF_SILENT) : boolean;

function RSFileOperation2(const aFrom, aTo:array of string; FileOperation: uint;
   Flags: FILEOP_FLAGS = FOF_NOCONFIRMATION or FOF_NOCONFIRMMKDIR or
          FOF_NOERRORUI or FOF_SILENT) : boolean;

function RSSearchPath(Path, FileName, Extension:string):string;

{--------}

function RSLoadProc(var Proc:Pointer; const LibName, ProcName:string; LoadLib:Boolean = true):hInst; overload;
function RSLoadProc(var Proc:Pointer; const LibName:string; ProcIndex:word; LoadLib:Boolean = true):hInst; overload;

function RSLoadProc(var Proc:Pointer; const LibName, ProcName:string;
   LoadLib:Boolean; RaiseException:boolean):hInst; overload;
function RSLoadProc(var Proc:Pointer; const LibName:string; ProcIndex:word;
   LoadLib:Boolean; RaiseException:boolean):hInst; overload;

procedure RSDelayLoad(var ProcAddress:Pointer; const LibName, ProcName:string;
   LoadLib:Boolean = true); overload;
procedure RSDelayLoad(var ProcAddress:Pointer; const LibName:string;
   ProcIndex:word; LoadLib:Boolean = true); overload;

function RSGetPageSize: int;

{--------}

function RSEnableTokenPrivilege(TokenHandle:THandle; const Privilege:string;
  Enable:Boolean):boolean;

function RSEnableProcessPrivilege(hProcess:THandle; const Privilege:string;
  Enable:boolean):boolean;

function RSEnableDebugPrivilege(Enable:boolean):boolean;

{--------}

function RSRunWait(Command:string; Dir:string;
           Timeout:DWord=INFINITE; showCmd:Word=SW_NORMAL):boolean;

// up to 3 parameters are accepted           
function RSRunThread(Func: ptr; Param: array of ptr;
   hThread: pint = nil; ThreadId: pint = nil;
   CreationFlags: LongWord = 0; StackSize: LongWord = 0;
   SecurityAttributes: ptr = nil): Boolean;

{--------}

procedure RSShowException;

 // Usage: AssertErrorProc:=RSAssertDisable
procedure RSAssertDisable(const Message, FileName: string;
    LineNumber: Integer; ErrorAddr: Pointer);

 // Usage: AssertErrorProc:=RSAssertErrorHandler
procedure RSAssertErrorHandler(const Message, FileName: string;
    LineNumber: Integer; ErrorAddr: Pointer);

{--------}

function RSMessageBox(hWnd:hwnd; Text, Caption:string; uType:DWord=0):int;

{--------}

var
  RSOSVersionInfo: OSVERSIONINFO;

resourcestring
  sRSCantLoadProc = 'Can''t load the "%s" procedure from "%s"';
  sRSCantLoadIndexProc = 'Can''t load the procedure number %d from "%s"';

implementation

var
  OSVersion: OSVERSIONINFO absolute RSOSVersionInfo;
  PageSize: int;

{$W-} // Unused stack frames are not welcome here (RSDelayLoad)
{$H+} // Long strings

function CalcJmpOffset(Src, Dest: Pointer): Pointer;
begin
  Result := ptr(Longint(Dest) - (Longint(Src) + 5));
end;

function MakeCall(Caller, JumpTo:ptr; Jump: Boolean = false):ptr;
begin
  if Jump then
    PByte(Caller)^:=$E9
  else
    PByte(Caller)^:=$E8;
  inc(PByte(Caller));
  Result:=PChar(Caller)+4;
  pptr(Caller)^:= ptr(int(JumpTo) - int(Result));
end;

{
******************************** TRSArrayStream ********************************
}
constructor TRSArrayStream.Create(var a: TRSByteArray);
begin
  inherited Create;
  FArr:=@a;
  SetPointer(ptr(a), length(a));
end;

destructor TRSArrayStream.Destroy;
begin
  FArr:=nil;
end;

function TRSArrayStream.Realloc(var NewCapacity: Longint): Pointer;
begin
  if FArr<>nil then
  begin
    SetLength(FArr^, NewCapacity);
    Result:=ptr(FArr^);
  end else
    Result:=nil;
end;

{
******************************* TRSStringStream ********************************
}

constructor TRSStringStream.Create(var a: string);
begin
  inherited Create;
  FStr:=@a;
  SetPointer(ptr(a), length(a));
end;

destructor TRSStringStream.Destroy;
begin
  FStr:=nil;
end;

function TRSStringStream.Realloc(var NewCapacity: Integer): Pointer;
begin
  if FStr<>nil then
  begin
    SetLength(FStr^, NewCapacity);
    Result:=ptr(FStr^);
  end else
    Result:=nil;
end;

{
****************************** TRSReplcaeStream ******************************
}

constructor TRSReplaceStream.Create(Main, Replace: TStream; OwnMain,
  OwnReplace: Boolean; Pos: Int64);
begin
  FMain:= Main;
  FReplace:= Replace;
  FOwnMain:= OwnMain;
  FOwnRep:= OwnReplace;
  FRepPos:= Pos;
  FRepLim:= Pos + FReplace.Size;
  FPos:= FMain.Position;
end;

destructor TRSReplaceStream.Destroy;
begin
  if FOwnMain then
    FreeAndNil(FMain);
  if FOwnRep then
    FreeAndNil(FReplace);
  inherited;
end;

function TRSReplaceStream.GetSize: Int64;
begin
  Result:= FMain.Size;
end;

function TRSReplaceStream.Read(var Buffer; Count: Integer): Longint;
var
  i: int;
  p: PChar;
begin
  Result:= Count;
  p:= @Buffer;
  if (Count > 0) and (FPos < FRepPos) then
  begin
    i:= FMain.Read(p^, min(Count, FRepPos - FPos));
    inc(FPos, i);
    dec(Count, i);
    inc(p, i);
    if FPos >= FRepPos then
      FReplace.Seek(0, 0);
  end;
  if (Count > 0) and (FPos >= FRepPos) and (FPos < FRepLim) then
  begin
    i:= FReplace.Read(p^, min(Count, FRepLim - FPos));
    inc(FPos, i);
    dec(Count, i);
    inc(p, i);
    if FPos = FRepLim then
      FMain.Seek(FPos, 0);
  end;
  if FPos >= FRepLim then
  begin
    i:= FMain.Read(p^, Count);
    inc(FPos, i);
    dec(Count, i);
  end;
  dec(Result, Count);
end;

function TRSReplaceStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  case Origin of
    soBeginning:  Result:= Offset;
    soCurrent:    Result:= FPos + Offset;
    else          Result:= FMain.Seek(Offset, Origin);
  end;
  FPos:= Result;
  if (Result >= FRepPos) and (Result < FRepLim) then
    FReplace.Seek(Result - FRepPos, 0);
end;

procedure TRSReplaceStream.SetSize(NewSize: Integer);
begin
  FMain.Size:= NewSize;
end;

procedure TRSReplaceStream.SetSize(const NewSize: Int64);
begin
  FMain.Size:= NewSize;
end;

function TRSReplaceStream.Write(const Buffer; Count: Integer): Longint;
begin
  Assert(false); // copy from Read
  Result:= 0;
end;

{
****************************** TRSCompositeStream ******************************
}

constructor TRSCompositeStream.Create;
begin
  inherited;
  FStreams:= TList.Create;
  FOwnStreams:= true;
end;

destructor TRSCompositeStream.Destroy;
var
  i: int;
begin
  if FOwnStreams then
    for i := 0 to FStreams.Count - 1 do
      TObject(FStreams.Items[i]).Destroy;
  inherited;
end;

function TRSCompositeStream.GetSize: Int64;
var
  i: int;
begin
  Result:= 0;
  for i := 0 to FStreams.Count - 1 do
    inc(Result, TStream(FStreams[i]).Size);
end;

function TRSCompositeStream.Read(var Buffer; Count: Integer): Longint;
var
  i, j: int;
  p: PChar;
begin
  Result:= Count;
  if Count = 0 then  exit;
  p:= @Buffer;
  for i := FCurrentStream to FStreams.Count - 2 do
  begin
    j:= TStream(FStreams[i]).Read(p^, Count);
    inc(p, j);
    dec(Count, j);
    if Count = 0 then  exit;
    TStream(FStreams[i]).Seek(0, 0);
    inc(FCurrentStream);
  end;
  if FStreams.Count > 0 then
    dec(Count, TStream(FStreams[FCurrentStream]).Read(p^, Count));
  dec(Result, Count);
end;

function TRSCompositeStream.Seek(const Offset: Int64;
  Origin: TSeekOrigin): Int64;
var
  i, j, sz, off, n: int;
  a: TStream;
//  orig: TSeekOrigin;
begin
  Result:= 0;
  n:= FStreams.Count;
  if n = 0 then  exit;

  case Origin of
    soBeginning:
      i:= 0;
    soCurrent:
      i:= FCurrentStream;
    else //soEnd:
      i:= n - 1;
  end;
  if FCurrentStream <> i then
    TStream(FStreams[FCurrentStream]).Seek(0, 0);
  a:= TStream(FStreams[i]);
  off:= a.Seek(0, Origin) + Offset;
  if Origin <> soBeginning then
    a.Seek(0, 0);
  if off <= 0 then
  begin
    while (off < 0) and (i > 0) do
    begin
      dec(i);
      a:= TStream(FStreams[i]);
      inc(off, a.Size);
    end;
    Result:= a.Seek(off, 0);
    FCurrentStream:= i;
    for j := i - 1 downto 0 do
      inc(Result, TStream(FStreams[j]).Size);
  end else
  begin
    for j := i - 1 downto 0 do
      inc(Result, TStream(FStreams[j]).Size);
    sz:= a.Size;
    while (sz <= off) and (i < n - 1) do
    begin
      inc(Result, sz);
      dec(off, sz);
      inc(i);
      a:= TStream(FStreams[i]);
      sz:= a.Size;
    end;
    inc(Result, a.Seek(off, 0));
    FCurrentStream:= i;
  end;
end;

procedure TRSCompositeStream.SetSize(NewSize: Integer);
begin
  SetSize(Int64(NewSize));
end;

procedure TRSCompositeStream.SetSize(const NewSize: Int64);
var
  sz: Int64;
//  a: TStream;
  i: int;
begin
  sz:= NewSize;
  for i := 0 to FStreams.Count - 2 do
    dec(sz, TStream(FStreams[i]).Size);
  i:= FStreams.Count;
  Assert((i > 0) and (sz >= 0));
  TStream(FStreams[i - 1]).Size:= sz;
end;

function TRSCompositeStream.Write(const Buffer; Count: Integer): Longint;
var
  i, j: int;
  p: PChar;
  a: TStream;
begin
  Result:= Count;
  if Count = 0 then  exit;
  p:= @Buffer;
  for i := FCurrentStream to FStreams.Count - 2 do
  begin
    a:= TStream(FStreams[i]);
    j:= a.Size - a.Position;
    if Count < j then
      j:= Count;
    j:= a.Write(p^, j);
    inc(p, j);
    dec(Count, j);
    if Count = 0 then  exit;
    TStream(FStreams[i]).Seek(0, 0);
    inc(FCurrentStream);
  end;
  if FStreams.Count > 0 then
    dec(Count, TStream(FStreams[FCurrentStream]).Write(p^, Count));
  dec(Result, Count);
end;

procedure TRSCompositeStream.AddStream(a: TStream);
begin
  a.Seek(0, 0);
  FStreams.Add(a);
end;

{
****************************** TRSFileStreamProxy ******************************
}

constructor TRSFileStreamProxy.Create(const AFileName: string; Mode: Word);
begin
{$IFDEF MSWINDOWS}
  Create(AFileName, Mode, 0);
{$ELSE}
  Create(AFileName, Mode, FileAccessRights);
{$ENDIF}
end;

constructor TRSFileStreamProxy.Create(const AFileName: string; Mode: Word;
  Rights: Cardinal);
begin
  inherited Create(-1);
{$IFDEF D2006}
  string((@FileName)^):= AFileName;
{$ELSE}
  FFileName:= AFileName;
{$ENDIF}
  FMode:= Mode;
  FRights:= Rights;
end;

procedure TRSFileStreamProxy.Check;
begin
  if (Handle < 0) and CreateDir then
    RSCreateDir(ExtractFilePath(FileName));
  if Handle < 0 then
{$IFDEF MSWINDOWS}
    if FMode = fmCreate then
    begin
      inherited Create(RSCreateFile(FileName));
      if FHandle < 0 then
        raise EFCreateError.CreateResFmt(@SFCreateErrorEx, [ExpandFileName(FileName), SysErrorMessage(GetLastError)]);
    end else
{$ENDIF}
    inherited Create(FileName, FMode, FRights);
end;

function TRSFileStreamProxy.Read(var Buffer; Count: Integer): Longint;
begin
  Check;
  Result:= inherited Read(Buffer, Count);
end;

function TRSFileStreamProxy.Seek(const Offset: Int64;
  Origin: TSeekOrigin): Int64;
begin
  Check;
  Result:= inherited Seek(Offset, Origin);
end;

procedure TRSFileStreamProxy.SetSize(NewSize: Integer);
begin
  Check;
  inherited;
end;

procedure TRSFileStreamProxy.SetSize(const NewSize: Int64);
begin
  Check;
  inherited;
end;

function TRSFileStreamProxy.Write(const Buffer; Count: Integer): Longint;
begin
  Check;
  Result:= inherited Write(Buffer, Count);
end;

{
************************************ TRSWnd ************************************
}

procedure RSWndCheck(b:Boolean);
asm
  test eax, eax
  jnz @Exit
  cmp RSWndExceptions, false
  jnz RSRaiseLastOSError
@Exit:
end;

class function TRSWnd.Create(ClassName:PChar; WindowName:PChar; Style:DWORD;
  X, Y, Width, Height:Integer; hWndParent: HWND; hMenu:HMENU;
  hInstance:HINST; lpParam:Pointer=nil; ExStyle:DWORD=0):TRSWnd;
begin
  Result:=TRSWnd(CreateWindowEx(ExStyle, ClassName, WindowName, Style, X, Y,
    Width, Height, hWndParent, hMenu, hInstance, lpParam));
end;

destructor TRSWnd.Destroy;
begin
  Assert(false);
  // TRSWnd isn't a normal class. Don't destroy it!
end;

procedure TRSWnd.BorderChanged;
begin
  SetWindowPos(HWnd(self),0,0,0,0,0,SWP_DRAWFRAME or SWP_FRAMECHANGED or
               SWP_NOZORDER or SWP_NOACTIVATE or SWP_NOMOVE or
               SWP_NOOWNERZORDER or SWP_NOSIZE or SWP_NOSENDCHANGING);
end;

function TRSWnd.GetAbsoluteRect: TRect;
begin
  RSWndCheck(GetWindowRect(HWnd(self), Result));
end;

function TRSWnd.GetBoundsRect: TRect;
var
  h: HWnd;
begin
  RSWndCheck(GetWindowRect(HWnd(self), Result));
  h:=GetParent(HWnd(self));
  if h=0 then exit;
  MapWindowPoints(0, h, Result, 2);
end;

function TRSWnd.GetClientRect: TRect;
begin
  RSWndCheck(windows.GetClientRect(HWnd(self), Result));
end;

function TRSWnd.GetClass: string;
var
  i: Integer;
begin
  SetLength(Result,255);
  i:=GetClassName(HWnd(self),pointer(Result),256);
  SetLength(Result, i);
  RSWndCheck(i<>0);
end;

function TRSWnd.GetExStyle: LongInt;
begin
  Result:=GetWindowLong(HWnd(self),GWL_EXSTYLE);
end;

const
  DWMWA_EXTENDED_FRAME_BOUNDS = 9;
var
  DwmGetWindowAttribute: function(wnd: HWND; attr1: DWORD; var res; attr3: DWORD): HRESULT stdcall;
  DwmGetWindowAttributeLoaded: Boolean;

function TRSWnd.GetExtendedBoundsRect: TRect;
begin
  if not DwmGetWindowAttributeLoaded then
    RSLoadProc(@DwmGetWindowAttribute, 'Dwmapi.dll', 'DwmGetWindowAttribute');
    
  if @DwmGetWindowAttribute <> nil then
    RSWndCheck(DwmGetWindowAttribute(HWnd(self), DWMWA_EXTENDED_FRAME_BOUNDS, Result, SizeOf(Result)) = S_OK)
  else
    RSWndCheck(GetWindowRect(HWnd(self), Result));
end;

function TRSWnd.GetHeight: LongInt;
begin
  with GetAbsoluteRect do
    Result:=Bottom-Top;
end;

function TRSWnd.GetId: LongInt;
begin
  Result:=GetWindowLong(HWnd(self),GWL_ID);
end;

function TRSWnd.GetProcessId: DWord;
begin
  RSWndCheck(GetWindowThreadProcessId(HWnd(self), Result) <> 0);
end;

function TRSWnd.GetStayOnTop: Boolean;
begin
  Result:=(GetWindowLong(HWnd(self),GWL_EXSTYLE) and WS_EX_Topmost)<>0;
end;

function TRSWnd.GetStyle: LongInt;
begin
  Result:=GetWindowLong(HWnd(self),GWL_STYLE);
end;

function TRSWnd.GetText: string;
var
  i: Integer;
begin
  i:=GetWindowTextLength(HWnd(self));
  if i<=0 then exit;
  SetLength(Result,i);
  GetWindowText(HWnd(self),pointer(Result),i+1);
end;

function TRSWnd.GetThreadId: DWord;
begin
  Result:= GetWindowThreadProcessId(HWnd(self), DWord(nil^));
  RSWndCheck(Result<>0);
end;

function TRSWnd.GetVisible:boolean;
begin
  Result:= GetWindowLong(HWnd(self),GWL_STYLE) and WS_VISIBLE <> 0;
end;

function TRSWnd.GetWidth: LongInt;
begin
  with GetAbsoluteRect do
    Result:=Right-Left;
end;

function TRSWnd.OpenProcess(dwDesiredAccess:DWORD=PROCESS_ALL_ACCESS; 
        bInheritHandle:boolean=false): DWord;
var
  pID: Dword;
begin
  GetWindowThreadProcessId(HWnd(self), pID);
  if pID=0 then
    Result:=0
  else
    Result:=Windows.OpenProcess(dwDesiredAccess, bInheritHandle, pID);
end;

procedure TRSWnd.SetAbsoluteRect(v: TRect);
var
  h: HWnd;
begin
  h:=GetParent(HWnd(self));
  if h<>0 then
    MapWindowPoints(0, h, v, 2);

  RSWndCheck(SetWindowPos(HWnd(self), 0,
                        v.Left, v.Top, v.Right-v.Left, v.Bottom-v.Top,
                        SWP_NOACTIVATE or SWP_NOOWNERZORDER or SWP_NOZORDER));
end;

procedure TRSWnd.SetBoundsRect(const v: TRect);
begin
  SetBounds(v.Left, v.Top, v.Right-v.Left, v.Bottom-v.Top);
end;

procedure TRSWnd.SetExStyle(v: LongInt);
begin
  SetWindowLong(HWnd(self), GWL_EXSTYLE, v);
end;

procedure TRSWnd.SetHeight(v: LongInt);
begin
  RSWndCheck(SetWindowPos(HWnd(self), 0, 0, 0, Width, v,
           SWP_NOMOVE or SWP_NOACTIVATE or SWP_NOOWNERZORDER or SWP_NOZORDER));
end;

procedure TRSWnd.SetId(v: LongInt);
begin
  SetWindowLong(HWnd(self), GWL_ID, v);
end;

procedure TRSWnd.SetStayOnTop(v: Boolean);
var h:hwnd;
begin
  if v then
    h:=HWND_TOPMOST
  else
    h:=HWND_NOTOPMOST;
  RSWndCheck(SetWindowPos(HWnd(self), h, 0, 0, 0, 0,
     SWP_NOACTIVATE or SWP_NOSIZE or SWP_NOMOVE or SWP_NOOWNERZORDER or SWP_NOSENDCHANGING))
end;

procedure TRSWnd.SetStyle(v: LongInt);
begin
  SetWindowLong(HWnd(self),GWL_STYLE,v);
end;

procedure TRSWnd.SetText(const v: string);
begin
  RSWndCheck(SetWindowText(HWnd(self),PChar(v)));
end;

procedure TRSWnd.SetVisible(v: boolean);
begin
  if v then
    ShowWindow(HWnd(self), SW_SHOWNOACTIVATE)
  else
    ShowWindow(HWnd(self), SW_HIDE);
end;

procedure TRSWnd.SetWidth(v: LongInt);
begin
  RSWndCheck(SetWindowPos(HWnd(self),0,0,0,v,Height,
             SWP_NOMOVE or SWP_NOACTIVATE or SWP_NOOWNERZORDER or SWP_NOZORDER));
end;

function TRSWnd.GetLeft: LongInt;
begin
  Result:=AbsoluteRect.Left;
end;

function TRSWnd.GetTop: LongInt;
begin
  Result:=AbsoluteRect.Top;
end;

procedure TRSWnd.SetBounds(x, y, w, h:int);
begin
  RSWndCheck(SetWindowPos(HWnd(self), 0, x, y, w, h,
     SWP_NOACTIVATE or SWP_NOOWNERZORDER or SWP_NOZORDER));
end;

procedure TRSWnd.SetPosition(x, y:int);
begin
  RSWndCheck(SetWindowPos(HWnd(self), 0, x, y, 0, 0,
     SWP_NOACTIVATE or SWP_NOOWNERZORDER or SWP_NOZORDER or SWP_NOMOVE));
end;

procedure TRSWnd.SetLeft(v: LongInt);
begin
  SetPosition(v, BoundsRect.Top);
end;

procedure TRSWnd.SetTop(v: LongInt);
begin
  SetPosition(BoundsRect.Left, v);
end;

{
*********************************** TRSBits ************************************
}
constructor TRSBits.Create;
begin
  Assert(false);
  // Don't try to create TRSBits objects.
  // Use TRSBits(PByte, PWord or pointer to data of any size) instead.
  // For example, TRSBits(@i).
end;

function TRSBits.GetBit(i:DWord): Boolean;
begin
  Result := PByte(DWord(self) + i div 8)^ and (1 shl (i mod 8)) <> 0;
end;

procedure TRSBits.SetBit(i:DWord; v: Boolean);
var
  j: PByte;
begin
  j:=PByte(DWord(self) + i div 8);
  if v then
    j^ := j^ or (1 shl (i mod 8))
  else
    j^ := j^ and not (1 shl (i mod 8));
end;

procedure TRSBits.FromBooleans(Buffer:pointer; Count:DWord; StartIndex:DWord=0);
var
  p:PByte; i,j:DWord; k:Byte;
begin
   // Optimized to death

  if Count=0 then exit;
  
  p:=PByte(PChar(self) + StartIndex div 8);
  i:=StartIndex mod 8;
  if i<>0 then
  begin
    k:=p^;
    j:=1 shl i;
    i:=8-i;
    if Count<i then i:=Count;
    dec(Count,i);
    while i<>0 do
    begin
      if PBoolean(Buffer)^ then
        k := k or j
      else
        k := k and not j;
      j:=j shl 1;
      inc(PBoolean(Buffer));
      dec(i);
    end;
    p^:=k;
    inc(p);
  end;

  for i:=(Count div 8) downto 1 do
  begin
    k:=0;
    j:=pint(Buffer)^;
    inc(pint(Buffer));
    if j and $ff <> 0 then  k := k or 1;
    if j and $ff00 <> 0 then  k := k or 2;
    if j and $ff0000 <> 0 then  k := k or 4;
    if j and $ff000000 <> 0 then  k := k or 8;
    j:=pint(Buffer)^;
    inc(pint(Buffer));
    if j and $ff <> 0 then  k := k or 16;
    if j and $ff00 <> 0 then  k := k or 32;
    if j and $ff0000 <> 0 then  k := k or 64;
    if j and $ff000000 <> 0 then  k := k or 128;
    p^:=k;
    inc(p);
  end;

  i:=Count mod 8;
  if i<>0 then
  begin
    k:=p^;
    j:=1;
    for i:=i downto 1 do
    begin
      if PBoolean(Buffer)^ then
        k := k or j
      else
        k := k and not j;
      j:=j shl 1;
      inc(PBoolean(Buffer));
    end;
    p^:=k;
  end;
end;

procedure TRSBits.ToBooleans(Buffer:pointer; Count:DWord; StartIndex:DWord = 0);
var
  j, k: Byte;
  p: PByte;
  i: DWord;
begin
   // Optimized to death
  
  if Count=0 then exit;

  p:=PByte(DWord(self) + StartIndex div 8);
  i:=StartIndex mod 8;
  if i<>0 then
  begin
    k:=p^;
    j:=1 shl i;
    i:=8-i;
    if Count<i then i:=Count;
    dec(Count,i);
    while i<>0 do
    begin
      PBoolean(Buffer)^:=k and j <> 0;
      j:=j shl 1;
      inc(PBoolean(Buffer));
      dec(i);
    end;
    inc(p);
  end;
  
  for i:=(Count div 8) downto 1 do
  begin
    k:=p^;
    PBoolean(Buffer)^:=k and 1 <> 0;
    inc(PBoolean(Buffer));
    PBoolean(Buffer)^:=k and 2 <> 0;
    inc(PBoolean(Buffer));
    PBoolean(Buffer)^:=k and 4 <> 0;
    inc(PBoolean(Buffer));
    PBoolean(Buffer)^:=k and 8 <> 0;
    inc(PBoolean(Buffer));
    PBoolean(Buffer)^:=k and 16 <> 0;
    inc(PBoolean(Buffer));
    PBoolean(Buffer)^:=k and 32 <> 0;
    inc(PBoolean(Buffer));
    PBoolean(Buffer)^:=k and 64 <> 0;
    inc(PBoolean(Buffer));
    PBoolean(Buffer)^:=k and 128 <> 0;
    inc(PBoolean(Buffer));
    inc(p);
  end;

  i:=Count mod 8;
  if i<>0 then
  begin
    k:=p^;
    j:=1;
    for i:=i downto 1 do
    begin
      PBoolean(Buffer)^:=k and j <> 0;
      j:=j shl 1;
      inc(PBoolean(Buffer));
    end;
  end;
end;

{
******************************** TRSCustomStack *********************************
}

constructor TRSCustomStack.Create(BlockSize:int);
begin
  FBlockSize:=BlockSize;
  FLastSize:=BlockSize;
end;

destructor TRSCustomStack.Destroy;
begin
  Clear;
  if FNextBlock<>nil then
    FreeBlock(FNextBlock);
  inherited Destroy;
end;

function TRSCustomStack.AllocBlock: ptr;
begin
  GetMem(Result, FBlockSize);
end;

procedure TRSCustomStack.FreeBlock(ABlock: ptr);
begin
  FreeMem(ABlock, FBlockSize);
end;

procedure TRSCustomStack.Clear;
var p:pptr; p1:ptr;
begin
//  FreeMem(FNextBlock);
//  FNextBlock:=nil;
  p:=FBlock;
  while p<>nil do
  begin
    p1:=p;
    p:=p^;
    FreeBlock(p1);
  end;
  FBlock:=nil;
  FBlockCount:=0;
end;

function TRSCustomStack.NewBlock:ptr;
begin
  Result:=FNextBlock;
  if Result=nil then
    Result:=AllocBlock
  else
    FNextBlock:=nil;
  pptr(Result)^:=FBlock;
  FBlock:=Result;
  inc(FBlockCount);
end;

function TRSCustomStack.WholePush(Size:int):ptr;
var i:int;
begin
  i:= FLastSize;
  if i = FBlockSize then
  begin
    Result:= NewBlock;
    i:= SizeOf(ptr);
  end else
    Result:= FBlock;

  inc(pbyte(Result), i);
  FLastSize:= i + Size;
end;

function TRSCustomStack.WholePop(Size:int):ptr;
var i:int;
begin
  Result:= FBlock;
  if Result = nil then exit;
  i:= FLastSize - Size;
  if i = SizeOf(ptr) then
  begin
    FreeBlock(FNextBlock);
    FNextBlock:= Result;
    FBlock:= pptr(Result)^;
    FLastSize:= FBlockSize;
    dec(FBlockCount);
  end else
    FLastSize:= i;
  inc(pbyte(Result), i);
end;

function TRSCustomStack.DoPeakAt(Offset:int):ptr;
var l:int;
begin
  if Offset > FLastSize - SizeOf(ptr) then
  begin
    dec(Offset, FLastSize - SizeOf(ptr));
    Result:= pptr(FBlock)^;
    l:= FBlockSize - SizeOf(ptr);
    while Offset>l do
    begin
      Result:= pptr(Result)^;
      dec(Offset, l);
    end;
    Result:=PChar(Result)+FBlockSize-Offset;
  end else
    Result:=PChar(FBlock)+FLastSize-Offset;
end;

procedure TRSCustomStack.DoPeak(var v; Size:int);
var l,Offset:int; p,Result:PChar;
begin
  Offset:=Size;
  p:=PChar(@v);
  if Offset > FLastSize - SizeOf(ptr) then
  begin
    dec(Offset, FLastSize - SizeOf(ptr));
    CopyMemory(p+Offset, PChar(FBlock) + SizeOf(ptr), FLastSize - SizeOf(ptr));
    Result:=pptr(FBlock)^;
    l:= FBlockSize - SizeOf(ptr);
    while Offset>l do
    begin
      dec(Offset, l);
      CopyMemory(p+Offset, PChar(Result) + SizeOf(ptr), l);
      Result:=pptr(Result)^;
    end;
    CopyMemory(p, Result+FBlockSize-Offset, Offset);
  end else
    CopyMemory(p, PChar(FBlock)+FLastSize-Offset, Offset);
end;

function TRSCustomStack.GetSize:int;
begin
  Result:= (FBlockSize - SizeOf(ptr))*FBlockCount + FLastSize - FBlockSize;
end;

function TRSCustomStack.BlockNextTo(p:ptr):ptr;
begin
  Result:= FBlock;
  if Result <> p then
    while Result<>nil do
    begin
      if pptr(Result)^ = p then  exit;
      Result:= pptr(Result)^;
    end;
  Result:=nil;
end;

{
******************************** TRSFixedStack *********************************
}

constructor TRSFixedStack.Create(ItemSize:int; BlockSize:int=4096);
begin
  RSGetPageSize;
  if BlockSize > PageSize then
    BlockSize:= (BlockSize + PageSize - 1) and not (PageSize - 1);
  BlockSize:= BlockSize - (BlockSize - SizeOf(ptr)) mod ItemSize;
  if BlockSize < ItemSize + SizeOf(ptr) then
  begin
    //Assert(BlockSize>4);
    BlockSize:= max(PageSize - (PageSize - SizeOf(ptr)) mod ItemSize, ItemSize + SizeOf(ptr));
  end;
  inherited Create(BlockSize);
  FItemSize:= ItemSize;
end;

function TRSFixedStack.AllocBlock: ptr;
begin
  if ExecutableMem then
    Result:=VirtualAlloc(nil, FBlockSize, MEM_COMMIT or MEM_RESERVE, PAGE_EXECUTE_READWRITE)
  else if FBlockSize + FItemSize >= PageSize then
    Result:=VirtualAlloc(nil, FBlockSize, MEM_COMMIT or MEM_RESERVE, PAGE_READWRITE)
  else
    GetMem(Result, FBlockSize);
end;

procedure TRSFixedStack.FreeBlock(ABlock: ptr);
begin
  if FBlockSize + FItemSize > PageSize then
    VirtualFree(ABlock, 0, MEM_DECOMMIT	or MEM_RELEASE)
  else
    FreeMem(ABlock, FBlockSize);
end;

function TRSFixedStack.DoPush:ptr;
begin
  Result:=WholePush(FItemSize);
end;

function TRSFixedStack.DoPop:ptr;
begin
  Result:=WholePop(FItemSize);
end;

function TRSFixedStack.DoPeak:ptr;
begin
  Result:=PChar(FBlock)+FLastSize-FItemSize;
end;

function TRSFixedStack.DoPeakAtIndex(Index:int):ptr;
begin
  inc(Index);
  Result:=DoPeakAt(Index*FItemSize);
end;

procedure TRSFixedStack.Peak(var v; Count:int);
begin
  DoPeak(v, Count*FItemSize);
end;

procedure TRSFixedStack.PeakAll(var v);
begin
  DoPeak(v, Size);
end;

function TRSFixedStack.GetCount:int;
begin
  Result:= Size div FItemSize;
end;

{
********************************* TRSObjStack **********************************
}

constructor TRSObjStack.Create(BlockSize:int=4096);
begin
  inherited Create(SizeOf(TObject), BlockSize);
end;

procedure TRSObjStack.Push(Obj:TObject);
begin
  pptr(WholePush(FItemSize))^:=Obj;
end;

function TRSObjStack.Pop:TObject;
begin
  Result:=pptr(WholePop(FItemSize))^;
end;

function TRSObjStack.Peak:TObject;
begin
  Result:=pptr(DoPeak)^;
end;

function TRSObjStack.PeakAt(Index:int):TObject;
begin
  inc(Index);
  Result:=pptr(DoPeakAt(Index*SizeOf(TObject)))^;
end;

(*
{
******************************** TRSCustomQueue ********************************
}

constructor TRSCustomQueue.Create(ItemSize:int; BlockSize:int=4096);
begin
  inherited;
  FFillEvent:= CreateEvent(nil, true, false, nil);
  FCount:= 0;
end;

destructor TRSCustomQueue.Destroy;
begin
  CloseHandle(FFillEvent);
  inherited;
end;

function TRSCustomQueue.DoPop: ptr;
begin
  if FCount<>FPopCount then
  begin
    inc(FPopCount);

  end else
    Result:= nil;
end;

function TRSCustomQueue.AfterPush: ptr;
begin
  inc(FCount);
  SetEvent(FFillEvent);
end;

function TRSCustomQueue.GetCount: int;
begin
  Result:= FCount - FPopCount;
end;

procedure TRSCustomQueue.WaitFor(var Queue:TRSCustomQueue);
begin
  while (self = Queue) and (FCount = FPopCount) do
    WaitForSingleObject(FFillEvent, INFINITE);
end;

{
********************************* TRSObjQueue **********************************
}

constructor TRSObjQueue.Create(BlockSize: int);
begin

end;

function TRSObjQueue.Peak: TObject;
begin

end;

function TRSObjQueue.PeakAt(Index: int): TObject;
begin

end;

function TRSObjQueue.Pop: TObject;
begin

end;

procedure TRSObjQueue.Push(Obj: TObject);
begin

end;

*)

{
******************************** TRSSharedData *********************************
}

constructor TRSSharedData.Create(Name:string; Size:int);
begin
  FSize:=Size;
  FMMF:= RSWin32Check(CreateFileMapping(INVALID_HANDLE_VALUE, nil,
                        PAGE_READWRITE, 0, Size, ptr(Name)));
  FAlreadyExists:= GetLastError = ERROR_ALREADY_EXISTS;
  FData:= RSWin32Check(MapViewOfFile(FMMF, FILE_MAP_ALL_ACCESS, 0, 0, 0));
end;

constructor TRSSharedData.Create(MMF:THandle; Size:int);
begin
  FSize:=Size;
  FMMF:=MMF;
  FAlreadyExists:= true;
  FData:= RSWin32Check(MapViewOfFile(MMF, FILE_MAP_ALL_ACCESS, 0, 0, 0));
end;

destructor TRSSharedData.Destroy;
begin
  UnmapViewOfFile(FData);
  CloseHandle(FMMF);
  inherited;
end;

{
**************************** TRSMemoryMappedStream *****************************
}

constructor TRSMemoryMappedStream.Create(const FileName: string; Mode: Word; Start: int64; Size: DWord);
const
  AccessMode: array[0..3] of LongWord = (GENERIC_READ, GENERIC_WRITE, GENERIC_READ or GENERIC_WRITE, 0);
begin
  inherited Create;
  FFileName:= FileName;
  FHandle:= FileOpen(FileName, Mode);
  if FHandle < 0 then
    raise EFOpenError.CreateResFmt(@SFOpenErrorEx, [ExpandFileName(FileName), SysErrorMessage(GetLastError)]);
  CreateMapping(Mode and 3 <> 0, Start, Size);
end;

destructor TRSMemoryMappedStream.Destroy;
begin
  UnmapViewOfFile(Memory);
  if FMMF > 0 then  CloseHandle(FMMF);
  if FHandle >= 0 then  FileClose(FHandle);
  inherited;
end;

procedure TRSMemoryMappedStream.CreateMapping(write: Boolean; start: int64; size: DWord);
const
  PageModes: array[Boolean] of DWORD = (PAGE_READONLY, PAGE_READWRITE);
begin
  PDWord(@FFileSize)^:= GetFileSize(FHandle, ptr(int(@FFileSize) + 4));
  FWritable:= write;
  FMMF:= CreateFileMapping(FHandle, nil, PageModes[write], 0, 0, nil);
  if FMMF = 0 then
    raise EFOpenError.CreateResFmt(@SFOpenErrorEx, [ExpandFileName(FileName), SysErrorMessage(GetLastError)]);
  Remap(start, size);
end;

function TRSMemoryMappedStream.Realloc(var NewCapacity: Integer): Pointer;
begin
  NewCapacity:= Capacity;
  Result:= Memory;
end;

procedure TRSMemoryMappedStream.Remap(Start: int64; Size: DWord);
const
  MapModes: array[Boolean] of DWORD = (FILE_MAP_READ, FILE_MAP_ALL_ACCESS);
var
  p: ptr;
begin
  FStartOffset:= Start;
  UnmapViewOfFile(Memory);
  SetPointer(nil, 0);
  Size:= min(Size, FFileSize - Start);
  if Size = 0 then
    exit;
  p:= RSWin32Check(MapViewOfFile(FMMF, MapModes[FWritable], Start shr 32, DWord(Start), Size));
  {if p = nil then
    raise EFOpenError.CreateResFmt(@SFOpenErrorEx, [ExpandFileName(FileName), SysErrorMessage(GetLastError)]);}
  SetPointer(p, Size);
end;

{
********************************* TRSFindFile **********************************
}

constructor TRSFindFile.Create(FileMask:string; IgnoreDotFolders: Boolean);
begin
  FIgnoreDotFolders:= IgnoreDotFolders;
  FPath:= ExtractFilePath(FileMask);
  FHandle:= FindFirstFile(ptr(FileMask), Data);
  FFound:= FHandle<>INVALID_HANDLE_VALUE;
  if not Found then
    CheckError;
end;

destructor TRSFindFile.Destroy;
begin
  FindClose(FHandle);
  inherited;
end;

procedure TRSFindFile.CheckError;
begin
  case GetLastError of
    ERROR_FILE_NOT_FOUND, ERROR_PATH_NOT_FOUND, ERROR_NO_MORE_FILES: ;
    else  RSRaiseLastOSError;
  end;
end;

function TRSFindFile.FindNext: Boolean;
begin
  FNotFirst:= true;
  FFileName:='';
  Result:= FindNextFile(FHandle, Data);
  FFound:= Result;
  if not Result then
    CheckError;
end;

function TRSFindFile.FindNextAttributes(Require, Exclude: DWord): Boolean;
begin
  if FNotFirst then
    FindNext;
  FNotFirst:= true;
  Result:= FindAttributes(Require, Exclude);
end;

function TRSFindFile.FindEachFile: Boolean;
begin
  Result:= FindNextAttributes(0, FILE_ATTRIBUTE_DIRECTORY);
end;

function TRSFindFile.FindEachFolder: Boolean;
begin
  Result:= FindNextAttributes(FILE_ATTRIBUTE_DIRECTORY, 0);
end;

function TRSFindFile.FindAttributes(Require, Exclude: DWord): Boolean;
var bits:DWord;
begin
  bits:= Require or Exclude;
  while Found and (((Data.dwFileAttributes and bits) <> Require) or
    (Data.cFileName[0] = '.') and ((Data.cFileName[1] = #0) or
      (Data.cFileName[1] = '.') and (Data.cFileName[2] = #0))) do
    FindNext;
  Result:=Found;
end;

function TRSFindFile.GetFileName: string;
begin
  if Found and (FFileName = '') then
    FFileName:= Path + Data.cFileName;
  Result:= FFileName;
end;

{
********************************* TRSCmd *********************************
}

function Check(var a: TRSCmd): PRSCmd;
begin
  if a.InitDone = '' then
  begin
    FillChar(a, SizeOf(a), 0);
    a.SI.cb := SizeOf(a.SI);
    a.InitDone:= 'ok';
  end;
  Result:= @a;
end;

function TRSCmd.NeedHandles(process, thread: Boolean): PRSCmd;
begin
  Result:= Check(self);
  NeedProcessHandle:= process;
  NeedThreadHandle:= thread;
end;

function TRSCmd.Run(Command, Dir: string; Timeout: DWord): Boolean;
var
  i: uint;
begin
  Check(self);
  RSWin32Check(CreateProcess(ptr(ApplicationName), ptr(Command),
     ProcessAttributes, ThreadAttributes, InheritHandles, CreationFlags,
     Environment, ptr(Dir), SI, PI));
  if not NeedThreadHandle then
    CloseHandle(PI.hThread);
  i:= WAIT_TIMEOUT;
  if Timeout > 0 then
    i:= WaitForSingleObject(pi.hProcess, Timeout);
  Result:= (i = WAIT_OBJECT_0);
  if not Result and (i <> WAIT_TIMEOUT) then
  begin
    if not NeedProcessHandle then
    begin
      i:= GetLastError;
      CloseHandle(PI.hProcess);
      SetLastError(i);
    end;
    RSRaiseLastOSError;
  end;
  if not NeedProcessHandle then
    CloseHandle(PI.hProcess);
end;

function TRSCmd.ShowCmd(showCmd: Word): PRSCmd;
begin
  Result:= Check(self);
  SI.dwFlags:= SI.dwFlags or STARTF_USESHOWWINDOW;
  SI.wShowWindow:= showCmd;
end;

function TRSCmd.App(const AppName: string): PRSCmd;
begin
  Result:= Check(self);
  ApplicationName:= AppName;
end;

function TRSCmd.Flags(Flags: DWord): PRSCmd;
begin
  Result:= Check(self);
  SI.dwFlags:= SI.dwFlags or Flags;
end;

{
********************************* TRSEventHook *********************************
}

constructor TRSEventHook.Create(Priority:int);
var Obj:TRSEventHook; NewMethod:TMethod;
begin
  inherited Create;
  FPriority:=Priority;

  NewMethod.Data:=self;
  NewMethod.Code:=FEventProc;
  FLastProc:=ObjEvent;
  Obj:=nil;
  while FLastProc.Code = NewMethod.Code do
  begin
    Obj:=FLastProc.Data;
    FLastProc:=Obj.FLastProc;
    if Obj.FPriority<=Priority then
      break;
  end;
  if Obj<>nil then
  begin
    FNext:=Obj;
    Obj.FLastProc:=NewMethod;
    if FLastProc.Code = NewMethod.Code then
      TRSEventHook(FLastProc.Data).FNext:=self;
  end else
    SetEvent(NewMethod);
end;

procedure TRSEventHook.Delete;
begin
  if FDeleting then exit;
  FDeleting:=true;

  if FNext<>nil then
    FNext.FLastProc:=FLastProc
  else
    if ObjEvent.Data<>self then
      exit
    else
      ObjEvent:=FLastProc;

  if FLastProc.Code = FEventProc then
    TRSEventHook(FLastProc.Data).FNext:=FNext;
  Lock(false);
end;

procedure TRSEventHook.Lock(aLock:boolean);
begin
  if self=nil then exit;
  if not aLock then
  begin
    dec(FLockCount);
    if FLockCount<0 then
      Free;
  end else
    inc(FLockCount);
end;

function TRSEventHook.GetLast:TRSEventHook;
begin
  Result:=FLastProc.Data;
  if FLastProc.Code<>FEventProc then
    Result:=nil;
end;


{
***************************** TRSShellChangeNotifier *****************************
}

constructor TRSShellChangeNotifier.Create(OnChange: TNotifyEvent = nil);
begin
  FOnChange:= OnChange;
  InitializeCriticalSection(FCS);
  inherited Create(false);
end;

destructor TRSShellChangeNotifier.Destroy;
begin
  FreeOnTerminate:= false;
  Terminate;
  DeleteCriticalSection(FCS);
  inherited Destroy;
end;

procedure TRSShellChangeNotifier.Free;
begin
  if self=nil then  exit;
  if FWakeEvent <> 0 then
  begin
    EnterCriticalSection(FCS);
    try
      if FWakeEvent <> 0 then
      begin
        FreeOnTerminate:=true;
        Terminate;
        exit;
      end;
    finally
      LeaveCriticalSection(FCS);
    end;
  end;
  Destroy;
end;

procedure TRSShellChangeNotifier.Terminate;
begin
  if not Terminated then
  begin
    inherited Terminate;
    if FWakeEvent <> 0 then
      SetEvent(FWakeEvent);
  end;
end;

procedure TRSShellChangeNotifier.Execute;
var
  WaitHandle: Integer; Handles: array[0..1] of Integer;
begin
  try
    FWakeEvent:= CreateEvent(nil, false, false, nil);
    Handles[0]:= FWakeEvent;
    while true do
    begin
      WaitHandle:= ERROR_INVALID_HANDLE;
      while true do
      begin
        if Terminated then  exit;
        EnterCriticalSection(FCS);
        try
          FReset:= false;
          if FDirectory<>'' then
            WaitHandle:= FindFirstChangeNotification(PChar(FDirectory),
               LongBool(FWatchSubTree), FFlags);
        finally
          LeaveCriticalSection(FCS);
        end;
        
        if WaitHandle <> ERROR_INVALID_HANDLE then  break;
        if WaitForSingleObject(FWakeEvent, INFINITE) = WAIT_FAILED then
          exit;
      end;
      Handles[1] := WaitHandle;
      case WaitForMultipleObjects(2, @Handles, false, INFINITE) of
        WAIT_OBJECT_0:
          FindCloseChangeNotification(WaitHandle);

        WAIT_OBJECT_0 + 1:
          if not Terminated and not FReset and TryEnterCriticalSection(FCS) then
          begin
            FNeedRefresh:=true;
            LeaveCriticalSection(FCS);
            Synchronize(CallOnChange);
            FindNextChangeNotification(WaitHandle);
          end else
            FindCloseChangeNotification(WaitHandle);

        WAIT_FAILED:
        begin
          FindCloseChangeNotification(WaitHandle);
          if WaitForSingleObject(FWakeEvent, INFINITE) = WAIT_FAILED then
            exit;
        end;
      end;
    end;
  finally
    EnterCriticalSection(FCS);
    CloseHandle(FWakeEvent);
    FWakeEvent:= 0;
    LeaveCriticalSection(FCS);
  end;
end;

procedure TRSShellChangeNotifier.CallOnChange;
var b:Boolean;
begin
  b:=FNeedRefresh;
  FNeedRefresh:=false;
  if b and not FReset and Assigned(FOnChange) then
    FOnChange(self);
end;

procedure TRSShellChangeNotifier.SetOptions(Directory: string;
  WatchSubTree: Boolean; Flags: DWord);
begin
  EnterCriticalSection(FCS);
  try
    FReset:= true;
    if FWakeEvent<>0 then  SetEvent(FWakeEvent);
    FDirectory:= Directory;
    FWatchSubTree:= WatchSubTree;
    FFlags:= Flags;
  except
    ptr(FDirectory):=nil;
    LeaveCriticalSection(FCS);
    raise;
  end;
  LeaveCriticalSection(FCS);
end;

procedure TRSShellChangeNotifier.Cancel;
begin
  SetOptions('', false, 0);
end;

procedure TRSShellChangeNotifier.Reset;
begin
  EnterCriticalSection(FCS);
  FReset:= true;
  if FWakeEvent<>0 then  SetEvent(FWakeEvent);
  LeaveCriticalSection(FCS);
end;

function TRSShellChangeNotifier.GetNeedRefresh: Boolean;
begin
  Result:= FNeedRefresh and not FReset;
end;

{---------------------------------------------------------------------}

procedure RaiseLastOSErrorAt(Offset: ptr);
var
  LastError: Integer;
  Error: EOSError;
begin
  LastError := GetLastError;
  if LastError <> 0 then
    Error := EOSError.CreateResFmt(@SOSError, [LastError,
      SysErrorMessage(LastError)])
  else
    Error := EOSError.CreateRes(@SUnkOSError);
  Error.ErrorCode := LastError;
  raise Error at Offset;
end;

procedure RSRaiseLastOSError;
asm
  mov eax, [esp]
  sub eax, 5
  jmp RaiseLastOSErrorAt
end;

function RSWin32Check(RetVal: LongBool): LongBool;
asm
  test eax, eax
  jz RSRaiseLastOSError
end;

function RSWin32Check(CheckForZero:int):int;
asm
  test eax, eax
  jz RSRaiseLastOSError
end;

function RSWin32Check(CheckForZero:ptr):ptr;
asm
  test eax, eax
  jz RSRaiseLastOSError
end;

function FindDynaClass(AClass:TClass; DMIndex:int):ptr; register;
asm
  jmp System.@FindDynaClass
end;

procedure RSDispatchEx(Obj:TObject; AClass:TClass; var Message);
var a:TMethod;
begin
  a.Data:=Obj;
  try
    a.Code:= FindDynaClass(AClass, word(Message));
  except
    Obj.DefaultHandler(Message);
    exit;
  end;
  TWndMethod(a)(TMessage(Message));
end;

 // From Grids.pas
procedure RSFillDWord(Dest:ptr; Count, Value: Integer); register;
asm
  XCHG  EDX, ECX
  PUSH  EDI
  MOV   EDI, EAX
  MOV   EAX, EDX
  REP   STOSD
  POP   EDI
end;


function RSQueryPerformanceCounter: int64;
begin
  RSWin32Check(QueryPerformanceCounter(Result));
end;

function RSQueryPerformanceFrequency: int64;
begin
  RSWin32Check(QueryPerformanceFrequency(Result));
end;


{
procedure RSSetLayeredAttribs(Handle:HWnd;
             AlphaBlend:boolean; AlphaBlendValue:byte;
             TransparentColor:boolean; TransparentColorValue:int);
const
  cUseAlpha: array [Boolean] of Integer = (0, LWA_ALPHA);
  cUseColorKey: array [Boolean] of Integer = (0, LWA_COLORKEY);
var
  Style: Integer;
begin
  if OSVersion.dwMajorVersion<5 then exit;
  Style := GetWindowLong(Handle, GWL_EXSTYLE);
  if AlphaBlend or TransparentColor then
  begin
    if (Style and WS_EX_LAYERED) = 0 then
      SetWindowLong(Handle, GWL_EXSTYLE, Style or WS_EX_LAYERED);
    SetLayeredWindowAttributes(Handle, TransparentColorValue, AlphaBlendValue,
      cUseAlpha[AlphaBlend] or cUseColorKey[TransparentColor]);
  end else
  if (Style and WS_EX_LAYERED) <> 0 then
  begin
    SetWindowLong(Handle, GWL_EXSTYLE, Style and not WS_EX_LAYERED);
    RedrawWindow(Handle, nil, 0, RDW_ERASE or RDW_INVALIDATE or RDW_FRAME or RDW_ALLCHILDREN);
  end;
end;
{}

function RSGetModuleFileName(hModule: HINST = 0):string;
var
  ss: array[0..MAX_PATH] of char;
  i: int;
begin
  i:= RSWin32Check(GetModuleFileName(hModule, ss, MAX_PATH+1));
  SetString(Result, PChar(@ss[0]), i);
end;

function DoGetVersionInfo(out info: PVSFixedFileInfo; path: PChar; var a: TRSByteArray): Boolean;
var
  verlen: DWORD;
begin
  SetLength(a, GetFileVersionInfoSize(path, verlen));
  Result:= (a <> nil) and GetFileVersionInfo(path, 0, length(a), ptr(a)) and
     VerQueryValue(ptr(a), '\', ptr(info), verlen);
end;

procedure CopyFileVersion(out Major, Minor, Release, Build: int; info: PVSFixedFileInfo; ok: Boolean);
begin
  if ok then
  begin
    Major:= info.dwFileVersionMS shr 16;
    Minor:= info.dwFileVersionMS and $FFFF;
    Release:= info.dwFileVersionLS shr 16;
    Build:= info.dwFileVersionLS and $FFFF;
  end else
  begin
    Major:= 0;
    Minor:= 0;
    Release:= 0;
    Build:= 0;
  end;
end;

function GetVersionString(const ver: array of int; MinPlaces: int): string;
var
  i: int;
begin
  i:= high(ver);
  while (i >= MinPlaces) and (ver[i] = 0) do
    dec(i);
  Result:= IntToStr(ver[0]);
  for i:= 1 to i do
    Result:= Result + '.' + IntToStr(ver[i]);
end;

function RSGetFileVersion(out Major, Minor, Release, Build: int; Path: string): Boolean; overload;
var
  info: PVSFixedFileInfo;
  a: TRSByteArray;
begin
  Result:= DoGetVersionInfo(info, PChar(Path), a);
  CopyFileVersion(Major, Minor, Release, Build, info, Result);
end;

function RSGetFileVersion(Path: string; MinPlaces: int = 2): string; overload;
var
  ver: array[0..3] of int;
begin
  if RSGetFileVersion(ver[0], ver[1], ver[2], ver[3], Path) then
    Result:= GetVersionString(ver, MinPlaces)
  else
    Result:= '';
end;

type
  VS_VERSIONINFO = packed record
    wLength: Word;
    wValueLength: Word;
    wType: Word;
    szKey: array[0..15] of WideChar;
    Padding1: Word;
    Value: VS_FIXEDFILEINFO;
    Padding2: Word;
    Children: Word;
  end;
  
function RSGetModuleVersion(out Major, Minor, Release, Build: int; Instance: LongWord = 0): Boolean; overload;
var
  h: THandle;
  p: ^VS_VERSIONINFO;
begin
  if Instance = 0 then
    Instance := HInstance;

  p:= nil;
  h:= FindResource(Instance, ptr(1), RT_VERSION);
  if (h <> 0) and (SizeofResource(Instance, h) >= SizeOf(VS_VERSIONINFO)) then
  begin
    h:= LoadResource(Instance, h);
    if h <> 0 then
      p:= LockResource(h);
  end;
  Result:= (p <> nil) and (p.wLength >= SizeOf(VS_VERSIONINFO)) and
    (p.wValueLength >= SizeOf(VS_FIXEDFILEINFO)) and
    (p.szKey = 'VS_VERSION_INFO') and (p.Value.dwSignature = $FEEF04BD);
  CopyFileVersion(Major, Minor, Release, Build, @p.Value, Result);
end;

{var
  VersionCache0, VersionCache1: TVSFixedFileInfo;

// At first this was meant to load version info from memory, but that turned out to be a dirty hack
function RSGetModuleVersion(out Major, Minor, Release, Build: int; Instance: LongWord = 0): Boolean; overload;
var
  info, cache: PVSFixedFileInfo;
  a: TRSByteArray;
  s: array[0..MAX_PATH] of char;
begin
  if Instance = 0 then
    cache:= @VersionCache0
  else if Instance = HInstance then
    cache:= @VersionCache1
  else
    cache:= nil;

  Result:= (cache <> nil) and (cache.dwSignature <> 0);
  if not Result then
  begin
    Result:= (GetModuleFileName(Instance, s, MAX_PATH+1) <> 0) and DoGetVersionInfo(info, @s[0], a);
    if Result and (cache <> nil) then
      cache^:= info^;
  end else
    info:= cache;

  CopyFileVersion(Major, Minor, Release, Build, info, Result);
end;
}

function RSGetModuleVersion(Instance: LongWord = 0; MinPlaces: int = 2): string; overload;
var
  ver: array[0..3] of int;
begin
  if RSGetModuleVersion(ver[0], ver[1], ver[2], ver[3], Instance) then
    Result:= GetVersionString(ver, MinPlaces)
  else
    Result:= '';
end;

function RSFileExists(const FileName: string): Boolean; {$IFDEF D2005}inline;{$ENDIF}
begin
  Result:= RSQ.FileExists(FileName);
end;

function TmpName(const s: string): string;
begin
  repeat
    Result:= s + IntToHex(Random($FFFF), 4);
  until not FileExists(Result);
end;

function RSMoveFile(const OldName, NewName: string; FailIfExists: Boolean): Bool;
var
  er: DWORD;
  tmp: string;
begin
  if not FailIfExists and FileExists(OldName) then
  begin
    //FileSetReadOnly(NewName, false);
    DeleteFile(ptr(NewName));
  end;
  Result:= MoveFile(ptr(OldName), ptr(NewName));
{  if FailIfExists then
    Result:= MoveFile(PChar(OldName), PChar(NewName))
  else
    Result:=
  if not FailIfExists and FileExists(OldName) then
  begin
    tmp:= TmpName(NewName);
    Result:= MoveFile(PChar(NewName), ptr(tmp));
    if not Result then  exit;
    //FileSetReadOnly(NewName, false);
    //DeleteFile(ptr(NewName));
  end;
  if tmp <> '' then
    if Result then
      if not DeleteFile(ptr(tmp)) then
      begin
        // roll back
        MoveFile(ptr(tmp), ptr(NewName))
        MoveFile(ptr(tmp), ptr(NewName))
      end else
    begin

    end else
    begin

    end;}
end;

function RSCreateFile(const FileName:string; dwDesiredAccess:DWord;
           dwShareMode:DWord;
           lpSecurityAttributes:PSecurityAttributes;
           dwCreationDistribution, dwFlagsAndAttributes:DWord;
           hTemplateFile:HFile):HFile;
begin
  if ((dwCreationDistribution = CREATE_ALWAYS)
     or (dwCreationDistribution = CREATE_NEW)
     or (dwCreationDistribution = OPEN_ALWAYS))
     and not RSCreateDir(ExtractFilePath(FileName)) then
  begin
    Result:=INVALID_HANDLE_VALUE;
  end else
    Result:=CreateFile(PChar(FileName), dwDesiredAccess, dwShareMode,
     lpSecurityAttributes, dwCreationDistribution, dwFlagsAndAttributes,
     hTemplateFile);
end;

var
  ReplaceFileLoaded: Boolean;
  ReplaceFile: function(Replaced, Replacement, Backup: PChar; Flags: int; u1: ptr = nil; u2: ptr = nil): Bool; stdcall;

function RSReplaceFile(const Replaced, Replacement: string; const Backup: string = ''; Flags: int = REPLACEFILE_IGNORE_MERGE_ERRORS): Boolean;
var
  tmp, tmp2: string;
  er: DWORD;
begin
  if not ReplaceFileLoaded then
    RSLoadProc(@ReplaceFile, kernel32, 'ReplaceFileA', false, false);
  ReplaceFileLoaded:= true;
  {if @ReplaceFile = nil then
  begin
    tmp:= TmpName(Replaced);
    Result:= RSMoveFile MoveFile(Replacement)
  end;
    if Backup <> '' then
    begin

      Result:= MoveFile()
      SetLastError(ERROR_UNABLE_TO_MOVE_REPLACEMENT)
    end else
    begin

    end;
  begin
    if
    repeat
      tmp:= Replaced + IntToHex(Random($FFFF), 4);
    until not FileExists(tmp);
    Result:= MoveFile(PChar(Replaced), ptr(tmp));
    if not Result then  exit;
    Result:= MoveFile()
  end else}
    Result:= ReplaceFile(PChar(Replaced), PChar(Replacement), ptr(Backup), Flags);
end;

function RSLoadFile(FileName:string):TRSByteArray;
var f:hfile; i:DWord;
begin
  f:=RSCreateFile(FileName, GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING,
                   FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN);
  if f=INVALID_HANDLE_VALUE then RSRaiseLastOSError;
  try
    i:=GetFileSize(f,nil);
    if i=DWord(-1) then RSRaiseLastOSError;
    SetLength(Result,i);
    if (i<>0) and (DWord(FileRead(f,Result[0],i))<>i) then RSRaiseLastOSError;
  finally
    FileClose(f);
  end;
end;

function RSLoadTextFile(FileName:string):string;
var f:hfile; i:DWord;
begin
  f:=RSCreateFile(FileName, GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING,
                   FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN);
  if f=INVALID_HANDLE_VALUE then RSRaiseLastOSError;
  try
    i:=GetFileSize(f,nil);
    if i=DWord(-1) then RSRaiseLastOSError;
    SetLength(Result,i);
    if (i<>0) and (DWord(FileRead(f,Result[1],i))<>i) then RSRaiseLastOSError;
  finally
    FileClose(f);
  end;
end;

procedure RSSaveFile(FileName:string; Data: ptr; L: int);
var f:HFile;
begin
  //FileSetReadOnly(FileName, false);
  f:=RSCreateFile(FileName, GENERIC_WRITE);
  if f=INVALID_HANDLE_VALUE then RSRaiseLastOSError;
  try
    if (L<>0) and (FileWrite(f, Data^, L) <> L) then  RSRaiseLastOSError;
  finally
    FileClose(f);
  end;
end;

procedure RSSaveFile(FileName:string; Data:TRSByteArray);
begin
  RSSaveFile(FileName, @Data[0], length(Data));
end;

procedure RSSaveFile(FileName:string; Data:TMemoryStream; RespectPosition: Boolean = false);
var
  pos: Int64;
begin
  if RespectPosition then
  begin
    pos:= Data.Position;
    RSSaveFile(FileName, PChar(Data.Memory) + pos, Data.Size - pos);
  end else
    RSSaveFile(FileName, Data.Memory, Data.Size);
end;

procedure RSSaveTextFile(FileName:string; Data:string);
begin
  RSSaveFile(FileName, @Data[1], length(Data));
end;

procedure RSAppendFile(FileName:string; Data: ptr; L:int);
var f:hfile;
begin
  FileSetReadOnly(FileName, false);
  f:=RSCreateFile(FileName, GENERIC_WRITE, 0, nil, OPEN_ALWAYS);
  if f=INVALID_HANDLE_VALUE then RSRaiseLastOSError;
  try
    if (L<>0) and ((FileSeek(f, 0, 2) = -1) or (FileWrite(f, Data^, L) <> L)) then
      RSRaiseLastOSError;
  finally
    FileClose(f);
  end;
end;

procedure RSAppendFile(FileName:string; Data:TRSByteArray);
begin
  RSAppendFile(FileName, @Data[0], length(Data));
end;

procedure RSAppendFile(FileName:string; Data:TMemoryStream; RespectPosition: Boolean = false);
var
  pos: Int64;
begin
  if RespectPosition then
  begin
    pos:= Data.Position;
    RSAppendFile(FileName, PChar(Data.Memory) + pos, Data.Size - pos);
  end else
    RSAppendFile(FileName, Data.Memory, Data.Size);
end;

procedure RSAppendTextFile(FileName:string; Data:string);
begin
  RSAppendFile(FileName, @Data[1], length(Data));
end;

function RSCreateDir(const PathName:string):boolean;
var s:string;
begin
  Result:=(PathName='') or DirectoryExists(PathName);
  if Result then exit;
  s:= ExtractFilePath(ExcludeTrailingPathDelimiter(ExpandFileName(PathName)));
  Result:= (s = PathName) or RSCreateDir(s) and CreateDir(PathName);
end;

function RSCreateDirectory(const PathName:string;
           lpSecurityAttributes:PSecurityAttributes):boolean;
begin
  Result:=RSCreateDir(
            ExtractFilePath(ExcludeTrailingPathDelimiter(PathName)));
  if Result then
    Result:=CreateDirectory(PChar(PathName), lpSecurityAttributes);
end;

function RSCreateDirectoryEx(const lpTemplateDirectory, NewDirectory:string;
   lpSecurityAttributes:PSecurityAttributes = nil):boolean;
begin
  Result:=RSCreateDir(
         ExtractFilePath(ExcludeTrailingPathDelimiter(NewDirectory)));
  if Result then
    Result:=CreateDirectoryEx(ptr(lpTemplateDirectory),
              ptr(NewDirectory), lpSecurityAttributes);
end;

function RSRemoveDir(const Dir:string):boolean; deprecated;
begin
  Result:=RSFileOperation(Dir, '', FO_DELETE);
end;

function RSDeleteAll(const Mask: string; Folders: boolean): boolean;
begin
  Result:= true;
  with TRSFindFile.Create(Mask) do
    try
      while FindNextAttributes(0, 0) do // Only files
        if Data.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY = 0 then
          Result:= DeleteFile(ptr(FileName)) and Result
        else if Folders then
        begin
          Result:= RSDeleteAll(FileName + '\*', true) and Result;
          Result:= RemoveDirectory(ptr(FileName)) and Result;
        end;
    finally
      Free;
    end;
end;

function DoubleNull(const s:string):string;
begin
  if s <> '' then
    SetString(Result, PChar(ptr(s)), length(s))
  else
    Result:= '';
end;

function NullArray(const a:array of string):string;
var i,j,k:int;
begin
  j:=0;
  for i:=high(a) downto low(a) do
    if a[i]<>'' then
      inc(j, length(a[i])+1);
  SetLength(Result, j);
  if j=0 then exit;
  j:=1;
  for i:=high(a) downto low(a) do
    if a[i]<>'' then
    begin
      k:=length(a[i])+1;
      CopyMemory(@Result[j], @a[i][1], k);
      inc(j, k);
    end;
end;

function RSFileOperation(const aFrom, aTo:string; FileOperation: uint;
 Flags: FILEOP_FLAGS = FOF_NOCONFIRMATION or FOF_NOCONFIRMMKDIR or FOF_NOERRORUI or FOF_SILENT):boolean;
var
  a:TSHFileOpStruct; s, s1:string;
begin
  s:= DoubleNull(aFrom);
  s1:= '';
  if FileOperation <> FO_DELETE then
    s1:= DoubleNull(aTo);

  with a do
  begin
    Wnd:=0;
    wFunc:=FileOperation;
    pFrom:=ptr(s);
    pTo:=ptr(s1);
    fFlags:=Flags and not (FOF_MULTIDESTFILES or FOF_WANTMAPPINGHANDLE);
    fAnyOperationsAborted:= false;
    hNameMappings:=nil;
    lpszProgressTitle:=nil;
  end;
  Result:= SHFileOperation(a)=0;
end;

function RSFileOperation2(const aFrom, aTo: array of string; FileOperation: uint;
   Flags: FILEOP_FLAGS = FOF_NOCONFIRMATION or FOF_NOCONFIRMMKDIR or
          FOF_NOERRORUI or FOF_SILENT) : boolean;
var a:TSHFileOpStruct; s, s1:string;
begin
  s:= NullArray(aFrom);
  if FileOperation <> FO_DELETE then
    s1:= NullArray(aTo);

  with a do
  begin
    Wnd:=0;
    wFunc:=FileOperation;
    pFrom:=ptr(s);
    pTo:=ptr(s1);
    fFlags:=Flags and not FOF_WANTMAPPINGHANDLE;
    fAnyOperationsAborted:=false;
    hNameMappings:=nil;
    lpszProgressTitle:=nil;
  end;
  Result:= SHFileOperation(a)=0;
end;

function RSSearchPath(Path, FileName, Extension:string):string;
var
  Buffer: array[0..MAX_PATH] of char;
  i:int; p:PChar;
begin
  i:= SearchPath(ptr(Path), ptr(FileName), ptr(Extension), MAX_PATH + 1, @Buffer, p);
  RSWin32Check(i);
  if i <= MAX_PATH + 1 then
  begin
    SetLength(Result, i - 1);
    if Result<>'' then
      Move(Buffer, Result[1], i - 1);
  end else
  begin
    SetLength(Result, i - 1);
    i:= SearchPath(ptr(Path), ptr(FileName), ptr(Extension), 0, ptr(Result), p);
    RSWin32Check(i);
  end;
end;

procedure RSCopyStream(Dest, Source: TStream; Count: int64);
var
  i: int64;
begin
  if (Source is TCustomMemoryStream) and (zSet(i, Source.Position) + Count < Source.Size) then
  begin
    Dest.WriteBuffer((PChar(TCustomMemoryStream(Source).Memory) + i)^, Count);
    Source.Seek(Count, soCurrent);
  end else
    if Dest is TMemoryStream then
      with TMemoryStream(Dest) do
      begin
        i:= Position;
        if i + Count > Size then
          Size:= i + Count;
        Source.ReadBuffer((PChar(Memory) + UintPtr(i))^, Count);
        Seek(Count, soCurrent);
      end
    else
      Dest.CopyFrom(Source, Count);
end;

function RSMemStreamPtr(m: TCustomMemoryStream): ptr;
begin
  Result:= PChar(m.Memory) + m.Position;
end;

{----------------------- RSLoadProc --------------------------}

function DoLoadProc(var Proc:Pointer; const LibName:string; ProcName:pointer;
   LoadLib:Boolean):hInst; overload;
var p:ptr;
begin
  if LoadLib then
    Result:= LoadLibrary(PChar(LibName))
  else
    Result:= GetModuleHandle(PChar(LibName));

  if Result <> 0 then
  begin
    p:= GetProcAddress(Result, ProcName);
    if p = nil then
    begin
      if LoadLib then  FreeLibrary(Result);
      Result:= 0;
    end else
      Proc:= p;
  end;
end;

function RSLoadProc(var Proc:Pointer; const LibName, ProcName:string;
   LoadLib:Boolean = true):hInst; overload;
begin
  Result:=DoLoadProc(Proc, LibName, ptr(ProcName), LoadLib);
end;

function RSLoadProc(var Proc:Pointer; const LibName:string; ProcIndex:word;
   LoadLib:Boolean = true):hInst; overload;
begin
  Result:=DoLoadProc(Proc, LibName, ptr(ProcIndex), LoadLib);
end;

function RSLoadProc(var Proc:Pointer; const LibName, ProcName:string;
   LoadLib:Boolean; RaiseException:boolean):hInst; overload;
begin
  Result:=DoLoadProc(Proc, LibName, ptr(ProcName), LoadLib);
  if (Result=0) and RaiseException then
    raise Exception.Create(Format(sRSCantLoadProc, [ProcName, LibName]));
end;

function RSLoadProc(var Proc:Pointer; const LibName:string; ProcIndex:word;
   LoadLib:Boolean; RaiseException:boolean):hInst; overload;
begin
  Result:=DoLoadProc(Proc, LibName, ptr(ProcIndex), LoadLib);
  if (Result=0) and RaiseException then
    raise Exception.Create(Format(sRSCantLoadIndexProc, [ProcIndex, LibName]));
end;

{---------------------- RSDelayLoad ---------------------}

type
  PDelayedImport = ^TDelayedImport;
  TDelayedImport = packed record
    Jmp: Byte;
    Address: Pointer;
    Call: Byte;
    CallAddress: Pointer;
    State: Byte;
    _: Byte;
//    Proc: PPointer;
    LibN: string;
    ProcN: pointer;
    Module: hInst;
  end;

const
  DINamed = 1;
  DILoadLib = 2;

var
  Delays: TRSFixedStack;
  DelaysOnClose: procedure;

 // Returns the address to call
function DelayProc(var Import:TDelayedImport):pointer;
var h:hInst; p: ptr;
begin
  with Import do
//    if Proc^=@Import then
    begin
      if State and DINamed <> 0 then
        h:=RSLoadProc(p, LibN, string(ProcN), State and DILoadLib <> 0, true)
      else
        h:=RSLoadProc(p, LibN, word(ProcN), State and DILoadLib <> 0, true);

      if State and DILoadLib <> 0 then
      begin
        h:= InterlockedExchange(int(Module), h);
        if h <> 0 then  FreeLibrary(h);
      end;
      // a simple assignment should also be atomic, but I'm not sure ATM
      InterlockedExchange(int(Address), int(p) - int(@Call));
    end;
  Result:= p;
//  Result:= Import.Proc^;
end;

procedure DelayAsmProc;
asm
   // Stack: <TDelayData adress + 5> <return adress> <proc params>
  xchg [esp], eax
  push ecx
  push edx

  sub eax, 10
  call DelayProc

  pop edx
  pop ecx
  xchg [esp], eax
   // Stack: <loaded proc adress> <return adress> <proc params>
end;

procedure FreeDelayImports;
var p:PDelayedImport;
begin
  p:=Delays.DoPop;
  repeat
    with p^ do
    begin
      LibN:='';
      if State and DINamed <> 0 then
        string(ProcN):='';
      if Module <> 0 then
        FreeLibrary(Module);
    end;
    p:=Delays.DoPop;
  until p=nil;

  FreeAndNil(Delays);
end;

procedure DoDelayLoad(var ProcAddress:Pointer; const LibName:string;
                      ProcName:pointer; LoadLib:Boolean; ANamed:boolean);
begin
  if Delays=nil then
  begin
    Delays:=TRSFixedStack.Create(SizeOf(TDelayedImport), RSGetPageSize);
    Delays.ExecutableMem:= true;
    if IsLibrary then  DelaysOnClose:=@FreeDelayImports;
  end;

  ProcAddress:=Delays.DoPush;
  with PDelayedImport(ProcAddress)^ do
  begin
    MakeCall(@Jmp, @Call);
    MakeCall(@Call, @DelayAsmProc);
//    Proc:= @ProcAddress;
    ptr(LibN):=nil;
    LibN:= LibName;
    ProcN:= ProcName;
    Module:= 0;
    State:= BoolToInt[ANamed]*DINamed + BoolToInt[LoadLib]*DILoadLib;
  end;
end;

procedure RSDelayLoad(var ProcAddress:Pointer; const LibName, ProcName:string;
   LoadLib:Boolean = true);
var s:string;
begin
  s:=ProcName;
  DoDelayLoad(ProcAddress, LibName, ptr(s), LoadLib, true);
  pointer(s):=nil;
end;

procedure RSDelayLoad(var ProcAddress:Pointer; const LibName:string;
  ProcIndex:word; LoadLib:Boolean = true);
begin
  DoDelayLoad(ProcAddress, LibName, ptr(ProcIndex), LoadLib, false);
end;

function RSGetPageSize: int;
var
  GetNativeSystemInfo: procedure(var info: TSystemInfo) stdcall;
  info: TSystemInfo;
begin
  if PageSize = 0 then
  begin
    if RSLoadProc(@GetNativeSystemInfo, kernel32, 'GetNativeSystemInfo', false) <> 0 then
      GetNativeSystemInfo(info)
    else
      GetSystemInfo(info);
    PageSize:= info.dwPageSize;
  end;
  Result:= PageSize;
end;

{
procedure ReplaceIATEntryInOneMod(PCSTR pszCalleeModName,
   PROC pfnCurrent, PROC pfnNew, HMODULE hmodCaller)
var Size:uint; pImportDesc:PIMAGE_IMPORT_DESCRIPTOR;
begin
     = (PIMAGE_IMPORT_DESCRIPTOR)
      ImageDirectoryEntryToData(hmodCaller, TRUE,
      IMAGE_DIRECTORY_ENTRY_IMPORT, &ulSize);

   if (pImportDesc == NULL)
      return;  // This module has no import section.

   for (; pImportDesc->Name; pImportDesc++) begin
      PSTR pszModName = (PSTR)
         ((PBYTE) hmodCaller + pImportDesc->Name);
      if (lstrcmpiA(pszModName, pszCalleeModName) == 0)
         break;
   end;

   if (pImportDesc->Name == 0)
      return;

   PIMAGE_THUNK_DATA pThunk = (PIMAGE_THUNK_DATA)
      ((PBYTE) hmodCaller + pImportDesc->FirstThunk);

   for (; pThunk->u1.Function; pThunk++) begin

      PROC* ppfn = (PROC*) &pThunk->u1.Function;

      BOOL fFound = ( *ppfn == pfnCurrent);

      if (fFound) begin
         // The addresses match; change the import section address.
         WriteProcessMemory(GetCurrentProcess(), ppfn, &pfnNew,
            sizeof(pfnNew), NULL);
         return;  // We did it; get out.
      end;
   end;
end;
}

{----------------------- TokenPrivileges --------------------------}

function RSEnableTokenPrivilege(TokenHandle:THandle; const Privilege:string;
  Enable:Boolean):boolean;
var
  Priv: TTokenPrivileges;
begin
  Priv.PrivilegeCount:= 1;
  if Enable then
    Priv.Privileges[0].Attributes:= SE_PRIVILEGE_ENABLED
  else
    Priv.Privileges[0].Attributes:= 0;

  Result:=
    LookupPrivilegeValue(nil, PChar(Privilege), Priv.Privileges[0].Luid) and
    AdjustTokenPrivileges(TokenHandle, false, Priv, 0, nil, DWord(nil^)) and
    (GetLastError = ERROR_SUCCESS);
end;

function RSEnableProcessPrivilege(hProcess:THandle; const Privilege:string;
  Enable:boolean):boolean;
var
  TokenHandle:THandle; i:DWord;
begin
  Result:= OpenProcessToken(hProcess, TOKEN_ADJUST_PRIVILEGES, TokenHandle);
  if Result then
    try
      Result:= RSEnableTokenPrivilege(TokenHandle, Privilege, Enable);
    finally
      i:=GetLastError;
      CloseHandle(TokenHandle);
      SetLastError(i);
    end;
end;

{function RtlAdjustPrivilege(priv: uint; enable, unk: Bool; unk2: pbool): int stdcall; external 'ntdll.dll';

function RSEnableDebugPrivilege(Enable:boolean):boolean;
var
  b: Bool;
begin
  RtlAdjustPrivilege(20, true, false, @b);
  Result:= true;
end;}

function RSEnableDebugPrivilege(Enable:boolean):boolean;
const
  Priv = 'SeDebugPrivilege';
begin
  Result:= RSEnableProcessPrivilege(GetCurrentProcess, Priv, Enable);
end;

{-----------------------  --------------------------}

function RSRunWait(Command:string; Dir:string; Timeout:DWord;
           showCmd:Word):boolean;
var
  SI: TStartupInfo; PI: TProcessInformation;
  i:integer;
begin
  FillChar(SI, SizeOf(SI), 0);
  FillChar(PI, SizeOf(PI), 0);
  SI.cb := SizeOf(SI);
  SI.dwFlags:=STARTF_USESHOWWINDOW;
  SI.wShowWindow:=showCmd;
  RSWin32Check(CreateProcess(nil, ptr(Command), nil, nil, false, 0, nil, ptr(Dir), SI, PI));
  CloseHandle(PI.hThread);
  try
    i:= WaitForSingleObject(pi.hProcess, Timeout);
    Result:= i=WAIT_OBJECT_0;
    if not Result and (i<>WAIT_TIMEOUT) then  RSRaiseLastOSError;
  finally
    CloseHandle(PI.hProcess);
  end;
end;

type
  TMyThreadFunc = function(Param1, Param2, Param3: Pointer): Integer; register;

  PThreadRec = ^TThreadRec;
  TThreadRec = record
    Func: TMyThreadFunc;
    Param1, Param2, Param3: Pointer;
  end;

function MyThreadFunc(P: PThreadRec): Integer;
var
  rec: TThreadRec;
begin
  rec:= P^;
  Dispose(P);
  try
    rec.Func(rec.Param1, rec.Param2, rec.Param3); // would work for 1 or 2 param functions as well
    Result:= 0;
  except
    RSShowException;
    Result:= int(STATUS_NONCONTINUABLE_EXCEPTION);
  end;
end;

function RSRunThread(Func: ptr; Param: array of ptr;
   hThread: pint = nil; ThreadId: pint = nil;
   CreationFlags: LongWord = 0; StackSize: LongWord = 0;
   SecurityAttributes: ptr = nil): Boolean;
var
  P: PThreadRec;
  handle: int;
  id: LongWord;
begin
  New(P);
  P.Func:= Func;
  if high(Param) >= 0 then  P.Param1:= Param[0];
  if high(Param) >= 1 then  P.Param2:= Param[1];
  if high(Param) >= 2 then  P.Param2:= Param[2];
  Assert(high(Param) <= 2);
  id:= 0;
  handle:= BeginThread(SecurityAttributes, StackSize, @MyThreadFunc, P, CreationFlags, id);
  Result:= (handle <> 0);
  if hThread <> nil then
    hThread^:= handle
  else if Result then
    CloseHandle(handle);
  if ThreadId <> nil then
    ThreadId^:= id;
end;

procedure RSShowException;
begin
  ShowException(ExceptObject, ExceptAddr);
end;

 // Usage: AssertErrorProc:=RSAssertDisable
procedure RSAssertDisable(const Message, FileName: string;
    LineNumber: Integer; ErrorAddr: Pointer);
begin
end;

 // Copied from SysUtils
procedure RaiseAssertException(const E: Exception; const ErrorAddr, ErrorStack: Pointer);
asm
        MOV     ESP,ECX
        MOV     [ESP],EDX
        MOV     EBP,[EBP]
        JMP     System.@RaiseExcept
end;

function CreateAssertException(const Message, Filename: string;
  LineNumber: Integer): Exception;
var
  S: string;
begin
  if Message <> '' then S := Message else S := SAssertionFailed;
  Result := EAssertionFailed.CreateFmt(SAssertError,
    [S, ExtractFileName(FileName), LineNumber]);
end;

 // Usage: AssertErrorProc:=RSAssertErrorHandler
 // Based on SysUtils.AssertErrorHandler
procedure RSAssertErrorHandler(const Message, FileName: string;
    LineNumber: Integer; ErrorAddr: Pointer);
var
  E: Exception;
begin
  E := CreateAssertException(Message, Filename, LineNumber);
  RaiseAssertException(E, ErrorAddr, PChar(@ErrorAddr)+4);
end;

function RSMessageBox(hWnd:hwnd; Text, Caption:string; uType:DWord=0):int;
begin
  Result:=MessageBox(hWnd, ptr(Text), ptr(Caption), uType);
end;

{-------------------------------------------------------}

initialization
  OSVersion.dwOSVersionInfoSize:=SizeOf(OSVersion);
  GetVersionEx(OSVersion);

finalization
  if @DelaysOnClose<>nil then
    DelaysOnClose;
{
Copyright (c) 2015 Sergey Rozhenko

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
}
end.
