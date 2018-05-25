unit RSRADPlay;

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
  SysUtils, Windows, Classes, Messages, Graphics, RSSysUtils, RSGraphics, RSQ,
  Math, RTLConsts;

type
  ERSRADException = class(Exception)
  end;

  TRSRADPlayer = class(TObject)
  protected
    FLib: HINST;
    FLibName: string;
//    FFileHandle: HFile;
    function GetCurrentFrame: int; virtual; abstract;
    function GetFramesCount: int; virtual; abstract;
    procedure SetCurrentFrame(v: int); virtual; abstract;
    procedure DoOpen(FileHandle: hFile; FilePath:Boolean); virtual; abstract;
    function NormalizeFrame(i:int):int;
    procedure SetPause(v:Boolean); virtual; abstract;

    procedure LoadProc(var Proc:Pointer; const ProcName:string);
  public
    Width:pint;
    Height:pint;
    constructor Create(const LibName:string);
    destructor Destroy; override;
    procedure Open(FileHandle:hFile); overload;
    procedure Open(FileName:string); overload;
//    procedure Open(FileData:TRSByteArray); overload;
    procedure SetVolume(i: int); virtual;
    procedure Close; virtual;
    procedure NextFrame; virtual; abstract;
    procedure PreparePic(b:TBitmap); virtual;
    procedure GotoFrame(Index:int; b:TBitmap); virtual;
    function ExtractFrame(b:TBitmap = nil):TBitmap; virtual; abstract;
    function Wait:Boolean; virtual; abstract;

    property Frame: int read GetCurrentFrame write SetCurrentFrame;
    property FramesCount: int read GetFramesCount;
    property LibInstance: HINST read FLib;
    property Pause: Boolean write SetPause;
  end;

  TRSBinkStruct = packed record
    Width: int;
    Height: int;
    FrameCount: int;
    CurrentFrame: int; // Starting with 1
    LastFrame: int;
    FPSMul: int; // frames/second multiplier
    FPSDiv: int; // frames/second divisor
    Unk1: int;
    Flags: int;
    Unk2: array[0..259] of byte;

     // The following members strongly depand on Bink version:
    FileHandleOld: hFile; // Bink beta version
    Unk3: array[0..5] of int;
    // Another Bink version has those members: 
    //
    //CurrentPlane: int;
    //Plane1: ptr;
    //Plane2: ptr;
    //Unk3: array[0..1] of int;
    //YPlaneWidth: int;
    //YPlaneHeight: int;
    //UVPlaneWidth: int;
    //UVPlaneHeight: int;
    FileHandleNew: hFile; // new Bink version
  end;
  PRSBinkStruct = ^TRSBinkStruct;

  TRSBinkPlayer = class(TRSRADPlayer)
  protected
    FNewMode: int;
    FData: PRSBinkStruct;
    FWaveOutOpen: ptr;
    FBuffer: TRSByteArray;

    BinkOpen: function(BinkFile:HFile; Flags:uint = $8a800000):PRSBinkStruct; stdcall;
     // New Bink:
     // $00400000 = BinkFile is memory address
     // $00800000 = BinkFile is file handle
     //
     // Old Bink:
     // $08000000 = BinkFile is file handle
    BinkGoto: procedure(Bink:PRSBinkStruct; FrameNumber:int; Unknown:int = 0); stdcall;
    BinkNextFrame: procedure(Bink:PRSBinkStruct); stdcall;
    BinkDoFrame: procedure(Bink:PRSBinkStruct); stdcall;
    BinkClose: procedure(Bink:PRSBinkStruct); stdcall;
    BinkCopyToBuffer: function(Bink:PRSBinkStruct; Buffer:ptr; Stride, Height:int;
       x:int=0; y:int=0; Mode:int=0):int; stdcall;

    BinkCopyToBufferRect: function(Bink:PRSBinkStruct; Buffer:ptr;
      Stride, Height:int; x:int; y:int; SrcRect:TRect; Mode:int=0):int; stdcall;
     // '_BinkCopyToBufferRect@44'

    BinkGetError: function:PChar; stdcall;
    BinkWait: function(Bink:PRSBinkStruct):Boolean; stdcall;
    BinkSetSoundSystem: function(SoundFunction:ptr; Param:ptr):LongBool; stdcall;
    BinkGetPalette: function(Bink:PRSBinkStruct):int; stdcall;
    BinkPause: procedure(Bink:PRSBinkStruct; Pause:Bool); stdcall;
    //BinkLogoAddress: function:ptr; stdcall;
    function GetCurrentFrame: int; override;
    function GetFramesCount: int; override;
    procedure SetCurrentFrame(v: int); override;
    procedure DoOpen(FileHandle: hFile; FilePath:Boolean); override;
    procedure CheckMode;
    procedure SetPause(v:Boolean); override;
  public
    UseInternalBuffer: Boolean;
    constructor Create(const LibName:string = 'BINKW32.DLL');
    procedure Close; override;
    procedure NextFrame; override;
    procedure PreparePic(b:TBitmap); override;
    function ExtractFrame(b:TBitmap = nil):TBitmap; override;
    function Wait:Boolean; override;
  end;

  TRSSmkStruct = packed record
    Version: int;
    Width: int;
    Height: int;
    FrameCount: int;
    mspf: int;
    Unk1: array[0..87] of byte;
    Palette: array[0..775] of byte;
    CurrentFrame: int; // Starting with 0

     // 72 - Øèï
     // 1060 - interesting
     // 1100 - Mute:Bool

    Unk: array[0..$37] of byte;
    FileHandle: hFile;
  end;
  PRSSmkStruct = ^TRSSmkStruct;

  TRSSmackPlayer = class(TRSRADPlayer)
  protected
    FData: PRSSmkStruct;
    SmackOpen: function(SmackFile:HFile; Flags:uint = $ff400; Unk:int = -1):PRSSmkStruct; stdcall;
     // 1000 = SmackFile is file handle. Otherwise it must be file path
    SmackDoFrame: function(Smk:PRSSmkStruct):int; stdcall;
    SmackGoto: procedure(Smk:PRSSmkStruct; FrameNumber:int); stdcall;
    SmackNextFrame: procedure(Smk:PRSSmkStruct); stdcall;
    SmackClose: procedure(Smk:PRSSmkStruct); stdcall;
    SmackToBuffer: procedure(Smk:PRSSmkStruct; x:int; y:int; Stride, Height:int;
                 Buffer:ptr; Flags:int); stdcall;
    SmackWait: function(Smk:PRSSmkStruct):Bool; stdcall;
    SmackSoundOnOff: procedure(Smk:PRSSmkStruct; Enable:Bool); stdcall;

    (*
    SmackVolumePan: procedure(Smk:PRSSmkStruct; Unk1:int {FE000}; Volume:int;
       Balance:int = $7FFF); stdcall;
     // Global in case of SmakUseWin!!!  Volume up to $10000

    SmackSoundInTrack: function(Smk:PRSSmkStruct; Unk1:int = $fe000):int; stdcall; // ??

    SmackSoundUseWin: procedure; stdcall;
    SmackSoundUseMSS: procedure(Unk1:int); stdcall;
    SmackSoundUseDirectSound: procedure(Unk1:int); stdcall;
    *)

    function GetCurrentFrame: int; override;
    function GetFramesCount: int; override;
    procedure SetCurrentFrame(v: int); override;
    procedure DoOpen(FileHandle: hFile; FilePath:Boolean); override;
    procedure SetPause(v:Boolean); override;
  public
    constructor Create(const LibName:string = 'SmackW32.DLL');
    procedure Close; override;
    procedure NextFrame; override;
    function ExtractFrame(b:TBitmap = nil):TBitmap; override;
    procedure PreparePic(b:TBitmap); override;
    function Wait:Boolean; override;
    procedure GotoFrame(Index:int; b:TBitmap); override;
  end;

 // Ignore Bink and Smack thread synchronization bug
 // (happens when swithing between files)
procedure RSSetSilentExceptionsFiter;

 // Useful in *.vid files of H3 and MM parsing
function RSGetBikSize(f:hFile):int;
function RSGetSmkSize(f:hFile):int;

//procedure InitMSS;

implementation

var
  Zero:int;
//  Miles:ptr;

{ TRSRADPlayer }

constructor TRSRADPlayer.Create(const LibName: string);
begin
  FLib:= LoadLibrary(ptr(LibName));
  FLibName:= LibName;
//  FFileHandle:=INVALID_HANDLE_VALUE;
  Width:= @Zero;
  Height:= @Zero;
end;

destructor TRSRADPlayer.Destroy;
begin
  Close;
  if FLib<>0 then
    FreeLibrary(FLib);
  inherited;
end;

procedure TRSRADPlayer.Open(FileName: string);
begin
  Close;
  DoOpen(int(FileName), true);
{
  FFileHandle:= CreateFile(ptr(FileName), GENERIC_READ, FILE_SHARE_READ, nil,
                 OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  RSWin32Check(FFileHandle<>INVALID_HANDLE_VALUE);
  try
    DoOpen(FFileHandle);
  except
    CloseHandle(FFileHandle);
    FFileHandle:=INVALID_HANDLE_VALUE;
    raise;
  end;
}
end;

{
procedure TRSRADPlayer.Open(FileData: TRSByteArray);
begin
  Close;
  // ...
end;
}

procedure TRSRADPlayer.Open(FileHandle: hFile);
begin
  Close;
  DoOpen(FileHandle, false);
end;

procedure TRSRADPlayer.Close;
begin
{
  if FFileHandle<>INVALID_HANDLE_VALUE then
  begin
    CloseHandle(FFileHandle);
    FFileHandle:=INVALID_HANDLE_VALUE;
  end;
}
  Width:=@Zero;
  Height:=@Zero;
end;

procedure TRSRADPlayer.PreparePic(b:TBitmap);
begin
  if (b.Height<>Height^) or (b.Width<>Width^) then
    b.Height:=0;
  b.HandleType:= bmDIB;
  b.Width:= Width^;
  b.Height:= Height^;
end;

procedure TRSRADPlayer.SetVolume(i: int);
begin
end;

function TRSRADPlayer.NormalizeFrame(i: int): int;
var j:int;
begin
  j:=FramesCount;
  if j>0 then
    if i>=0 then
      while i>=j do  dec(i, j)
    else
      while i<0 do  inc(i, j);
  Result:=i;
end;

procedure TRSRADPlayer.GotoFrame(Index: int; b: TBitmap);
begin
  Frame:= Index;
  ExtractFrame(b);
end;

procedure TRSRADPlayer.LoadProc(var Proc: Pointer; const ProcName: string);
begin
  if Proc<>nil then  exit;
  Proc:= GetProcAddress(FLib, ptr(ProcName));
  if Proc=nil then
    raise ERSRADException.CreateFmt(sRSCantLoadProc, [ProcName, FLibName]);
end;

{ TRSBinkPlayer }

constructor TRSBinkPlayer.Create(const LibName: string = 'BINKW32.DLL');
begin
  inherited Create(LibName);
  FNewMode:= -1;
  FWaveOutOpen:= GetProcAddress(FLib, '_BinkOpenWaveOut@4');
  UseInternalBuffer:= true;
end;

procedure TRSBinkPlayer.Close;
begin
  if FData<>nil then
  begin
    LoadProc(@BinkClose, '_BinkClose@4');
    BinkClose(FData);
    FData:=nil;
    FBuffer:=nil;
  end;
  inherited;
end;

procedure TRSBinkPlayer.DoOpen(FileHandle: hFile; FilePath:Boolean);
const
  Flags: array[Boolean] of uint = ($8a800000, $82000000);
begin
  LoadProc(@BinkGetError, '_BinkGetError@0');
  LoadProc(@BinkOpen, '_BinkOpen@8');

  if FWaveOutOpen<>nil then
  begin
    LoadProc(@BinkSetSoundSystem, '_BinkSetSoundSystem@8');
    BinkSetSoundSystem(FWaveOutOpen, nil);
  end;

  FData:= BinkOpen(FileHandle, Flags[FilePath]);
  if FData = nil then
    raise ERSRADException.Create(BinkGetError);
  Width:= @FData^.Width;
  Height:= @FData^.Height;
end;

procedure TRSBinkPlayer.CheckMode;
var Buf:array of byte; i:int;
begin
  LoadProc(@BinkDoFrame, '_BinkDoFrame@4');
  LoadProc(@BinkCopyToBuffer, '_BinkCopyToBuffer@28');
  if FNewMode<>-1 then  exit;
  SetLength(Buf, FData.Width*3);
  i:=high(Buf);
  Buf[i]:=1;
  BinkCopyToBuffer(FData, ptr(Buf), 0, FData.Height);
  if Buf[i]=1 then
  begin
    Buf[i]:=2;
    BinkCopyToBuffer(FData, ptr(Buf), 0, FData.Height);
    if Buf[i]=2 then
      FNewMode:=1;
  end else
    FNewMode:=0;
end;

function TRSBinkPlayer.ExtractFrame(b: TBitmap): TBitmap;
var i,j:int; pf:TPixelFormat;
begin
  CheckMode;

  if b=nil then
  begin
    b:=TBitmap.Create;
    Result:=b;
  end else
    Result:=nil;

  try
    pf:=RSGetPixelFormat(b);
    i:=0; j:=0; // For compiler
    case pf of
      pf24bit:  i:=3;
      pf15bit, pf16bit:  i:=2;
      pf32bit:  i:=4;
      pf8bit:  i:=1;
      //else Assert(false);
    end;
    if FNewMode=0 then
      case pf of
        pf24bit:  j:=0;
        pf32bit:  j:=1;
        pf15bit:  j:=2;
        pf16bit:  j:=3;
        else  Assert(false);

        // Bit $8000000 = VMirror
      end
    else
      case pf of
        pf8bit:   j:=0;
        pf24bit:  j:=1;
        pf32bit:  j:=3;
        pf15bit:  j:=8;
        pf16bit:  j:=10;
        else  Assert(false);

        // Bit $20000 = GrayScale
      end;
    if FBuffer = nil then
    begin
      SetLength(FBuffer, b.Width*b.Height*i);
      RSBitmapToBuffer(ptr(FBuffer), b, Rect(0, 0, b.Width, b.Height));
    end;
    BinkDoFrame(FData);
    BinkCopyToBuffer(FData, ptr(FBuffer), b.Width*i, b.Height, 0, 0, j);
    RSBufferToBitmap(ptr(FBuffer), b, Rect(0, 0, b.Width, b.Height));
    if not UseInternalBuffer then
      FBuffer:= nil;
  except
    if not UseInternalBuffer then
      FBuffer:= nil;
    Result.Free;
    raise;
  end;
  Result:=b;
  
// Old Bink version:  BinkCopyToBuffer(Bink, b.ScanLine[0],
//                        (-b.Width*i) and not 3, b.Height, 0, 0, j + NewMode);
// New Bink version:  BinkCopyToBuffer(Bink, b.ScanLine[b.Height-1],
//                        (-b.Width*i) and not 3, b.Height, 0, 0, j + NewMode);
end;

function TRSBinkPlayer.GetCurrentFrame: int;
begin
  if FData=nil then
    Result:=0
  else
    Result:=FData^.CurrentFrame-1;
end;

function TRSBinkPlayer.GetFramesCount: int;
begin
  if FData=nil then
    Result:=0
  else
    Result:=FData^.FrameCount;
end;

procedure TRSBinkPlayer.SetCurrentFrame(v: int);
begin
  v:= NormalizeFrame(v) + 1;
  if v = FData^.CurrentFrame then  exit;
  LoadProc(@BinkGoto, '_BinkGoto@12');
  if (v = 1) and (FData^.CurrentFrame = FData^.FrameCount) then
    NextFrame
  else
    BinkGoto(FData, v);
end;

procedure TRSBinkPlayer.NextFrame;
begin
  LoadProc(@BinkNextFrame, '_BinkNextFrame@4');
  BinkNextFrame(FData);
end;

function TRSBinkPlayer.Wait:Boolean;
begin
  LoadProc(@BinkWait, '_BinkWait@4');
  Result:=BinkWait(FData);
end;

procedure TRSBinkPlayer.PreparePic(b: TBitmap);
var j:int; Pal:array[0..256] of int;
begin
  inherited;
  case RSGetPixelFormat(b) of
    pf24bit, pf32bit, pf15bit, pf16bit:;

    pf8bit:
    begin
      if @BinkGetPalette=nil then
        @BinkGetPalette:=GetProcAddress(FLib, '_BinkGetPalette@4');
      if @BinkGetPalette<>nil then
      begin
        with PLogPalette(@Pal)^ do
        begin
          palVersion:=$300;
          palNumEntries:=BinkGetPalette(@palPalEntry);
          for j:=0 to palNumEntries-1 do
            int(palPalEntry[j]):=RSSwapColor(int(palPalEntry[j]));
        end;
        b.Palette:=CreatePalette(PLogPalette(@Pal)^);
      end else
        b.PixelFormat:=pf24bit;
    end;

    else
      b.PixelFormat:=pf24bit;
  end

end;

procedure TRSBinkPlayer.SetPause(v: Boolean);
begin
  if FData=nil then  exit;
  LoadProc(@BinkPause, '_BinkPause@8');
  BinkPause(FData, v);
end;

{ TRSSmackPlayer }

constructor TRSSmackPlayer.Create(const LibName: string = 'SmackW32.DLL');
begin
  inherited Create(LibName);
end;

procedure TRSSmackPlayer.Close;
begin
  if FData<>nil then
  begin
    LoadProc(@SmackClose, '_SmackClose@4');
    SmackClose(FData);
  end;
  FData:=nil;
  inherited;
end;

procedure TRSSmackPlayer.DoOpen(FileHandle: hFile; FilePath:Boolean);
const
  Flags: array[Boolean] of uint = ($ff400, $fe400);
  ErrorStr = 'Can''t open smack file. GetLastError = %d'#13#10'%s';
begin
  LoadProc(@SmackOpen, '_SmackOpen@12');
  FData:= SmackOpen(FileHandle, Flags[FilePath]);
  if FData = nil then
    raise ERSRADException.CreateFmt(ErrorStr,
      [GetLastError, SysErrorMessage(GetLastError)]);
  Width:=@FData^.Width;
  Height:=@FData^.Height;
end;

procedure TRSSmackPlayer.PreparePic(b: TBitmap);
begin
  inherited;
  case RSGetPixelFormat(b) of
    pf15bit, pf16bit:;
    else begin
      b.PixelFormat:=pf16bit;
      //b.PixelFormat:=pf8bit;
      //b.Palette:=RSMakePalette(@FData^.Palette);
    end;
  end;
end;

function TRSSmackPlayer.ExtractFrame(b: TBitmap): TBitmap;
var i,j:int; pf:TPixelFormat; //Buf:array of byte;
begin
  LoadProc(@SmackDoFrame, '_SmackDoFrame@4');
  LoadProc(@SmackToBuffer, '_SmackToBuffer@28');
  if b=nil then
  begin
    b:=TBitmap.Create;
    Result:=b;
  end else
    Result:=nil;
    
  try
    pf:=RSGetPixelFormat(b);
    i:=0; j:=0; // For compiler
    case pf of
      pf8bit:  i:=1;
      pf15bit, pf16bit:  i:=2;
      else Assert(false);
    end;
    case pf of
      pf8bit:  j:=$10000000;
      pf15bit:  j:=int($80000000);
      pf16bit:  j:=int($c0000000);
      //else  Assert(false);

      // Bit 1 = VMirror
    end;
//    SetLength(Buf, b.Width*b.Height*i);
//    RSBitmapToBuffer(ptr(Buf), b, Rect(0, 0, b.Width, b.Height));
//    SmackToBuffer(FData, 0, 0, b.Width*i, b.Height, ptr(Buf), j);
    SmackToBuffer(FData, 0, 0, (-b.Width*i) and not 3, b.Height, b.Scanline[0], j);
    SmackDoFrame(FData);

//    RSBufferToBitmap(ptr(Buf), b, Rect(0, 0, b.Width, b.Height));
  except
    //Buf:=nil;
    Result.Free;
    raise;
  end;
  Result:=b; 
end;

function TRSSmackPlayer.GetCurrentFrame: int;
begin
  Result:=FData^.CurrentFrame;
end;

function TRSSmackPlayer.GetFramesCount: int;
begin
  Result:=FData^.FrameCount;
end;

procedure TRSSmackPlayer.SetCurrentFrame(v: int);
begin
  v:=NormalizeFrame(v);
  if v = FData^.CurrentFrame then  exit;
  LoadProc(@SmackGoto, '_SmackGoto@8');
  LoadProc(@SmackNextFrame, '_SmackNextFrame@4');
  if v<FData^.CurrentFrame then
  begin
    SmackGoto(FData, v);
  end else
  begin
     // SmackGoto is buggy
    v:=v-FData^.CurrentFrame;
    for v:=v downto 1 do
      SmackNextFrame(FData);
  end;
end;

procedure TRSSmackPlayer.NextFrame;
begin
  LoadProc(@SmackNextFrame, '_SmackNextFrame@4');
  SmackNextFrame(FData);
end;

function TRSSmackPlayer.Wait: Boolean;
begin
  LoadProc(@SmackWait, '_SmackWait@4');
  Result:=SmackWait(FData);
end;

procedure TRSSmackPlayer.GotoFrame(Index:int; b:TBitmap);
var i:int;
begin
  Index:=NormalizeFrame(Index);

  if FData.CurrentFrame>Index then
  begin
    Frame:=0;
    ExtractFrame(b);
  end;
  i:=FData.CurrentFrame;

  while i<Index do
  begin
    NextFrame;
    ExtractFrame(b);
    inc(i);
  end;
end;

procedure TRSSmackPlayer.SetPause(v: Boolean);
begin
  if FData=nil then  exit;
  LoadProc(@SmackSoundOnOff, '_SmackSoundOnOff@8');
  SmackSoundOnOff(FData, not v);
end;




procedure UnhandledException(var e: TExceptionPointers); stdcall;
begin
  ExitThread(e.ExceptionRecord.ExceptionCode);
end;

procedure RSSetSilentExceptionsFiter;
begin
  SetUnhandledExceptionFilter(@UnhandledException);
end;


procedure DoFileRead(Handle:hFile; var Buffer; Count:int);
begin
  if (Count <> 0) and (FileRead(Handle, Buffer, Count) <> Count) then
    raise EReadError.CreateRes(@SReadError);
end;

function RSGetBikSize(f:hFile):int;
begin
  FileSeek(f, 4, 1);
  DoFileRead(f, Result, 4);
  FileSeek(f, -8, 1);
  inc(Result, 8);
end;

function RSGetSmkSize(f:hFile):int;
type
  TSmkHeader = packed record
    Sig: array[0..2] of char;
    Version: byte;
    Width: int;
    Height: int;
    Count: int;
    FrameRate: int;
    Flags: int;
    AudioBiggestSize: array[0..6] of int;
    TreesSize: int;
    TreesInfo: array[0..3] of int;
    AudioRate: array[0..6] of int;
    Dummy: int;
  end;
var
  smk:TSmkHeader;
  Sizes: array of int;
  i, count:int;
begin
  DoFileRead(f, smk, SizeOf(TSmkHeader));
  count:= smk.Count;
  if (smk.Flags and 1) <> 0 then
    inc(count);
  SetLength(Sizes, count);
  DoFileRead(f, Sizes[0], count*4);
  FileSeek(f, -SizeOf(TSmkHeader) - count*4, 1);
  Result:= smk.TreesSize + SizeOf(TSmkHeader) + count*5;
  for i:= 0 to count - 1 do
    inc(Result, Sizes[i] and not 3);
end;


{
var
  AIL_startup: procedure;
  AIL_shutdown: procedure;
  AIL_waveOutOpen: function(a1,a2,a3,a4:ptr):ptr; stdcall;
  AIL_set_preference: procedure(a1, a2:int); stdcall;
  Buf: array[0..4000] of byte;

procedure InitMSS;
var h:HMODULE; i:int;
begin
  h:=LoadLibrary('mss32.dll');
  @AIL_startup:=GetProcAddress(h, '_AIL_startup@0');
  @AIL_set_preference:=GetProcAddress(h, '_AIL_set_preference@8');
  @AIL_waveOutOpen:=GetProcAddress(h, '_AIL_waveOutOpen@16');
//  if (@AIL_startup=nil) or (@AIL_waveOutOpen=nil) then  exit;
  Assert(@AIL_startup<>nil);
  Assert(@AIL_waveOutOpen<>nil);
  Assert(@AIL_set_preference<>nil);
  AIL_startup;
  AIL_set_preference(15, 0);
  AIL_set_preference($21, 1);
  Buf[0]:=1;
  Buf[2]:=2;
  //20001
  pint(@Buf[4])^:=$5622;
  pint(@Buf[8])^:=$15888;
  pint(@Buf[12])^:=$10004;
  Miles:=AIL_waveOutOpen(@i, nil, ptr(-1), @Buf);
end;
}

end.
