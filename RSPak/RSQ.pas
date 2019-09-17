unit RSQ;

{ *********************************************************************** }
{                                                                         }
{ RSPak                                    Copyright (c) Rozhenko Sergey  }
{ http://sites.google.com/site/sergroj/                                   }
{ sergroj@mail.ru                                                         }
{                                                                         }
{ See copyright notice at the end of RSSysUtils.pas file (MIT license).   }
{                                                                         }
{ *********************************************************************** )

 A set of small functions and types I made for my own use.

{ *********************************************************************** }
{$I RSPak.inc}

interface

uses
  SysUtils, Windows;

type
  int1=ShortInt;
  int2=SmallInt;
  int4=LongInt;
  int8=Int64;
  int=int4;
  pint1=^int1;
  pint2=^int2;
  pint4=^int4;
  pint8=^int8;
  pint=^int;

  uint1=byte;
  uint2=word;
  uint4=longWord;
  uint=uint4;
  puint1=^uint1;
  puint2=^uint2;
  puint4=^uint4;
  puint=^uint;
  puint64=^uint64;

  ptr=pointer;
  pptr=^pointer;
  ppptr=^pptr;
  ppint=^pint;

  IntPtr = int;
  UintPtr = uint;

  PStr=^string;

  ext = extended;
  pext = ^ext;

  PPIntegerArray = ^PIntegerArray;
  PByteArray = ^TByteArray;
  TByteArray = array[0..$7ffffffe] of Byte;

  PWordArray = ^TWordArray;
  TWordArray = array[0..$3ffffffe] of Word;

  PDWordArray = ^TDWordArray;
  TDWordArray = array[0..$1ffffffe] of DWord;

const
  VK_PGUP = VK_PRIOR;
  VK_PGDN = VK_NEXT;
  VK_BACKSPACE = VK_BACK;
  VK_ALT = VK_MENU;
  VK_CAPSLOCK = VK_CAPITAL;
  BoolToInt: array[boolean] of byte = (0, 1);
  BoolStr: array[boolean] of string = ('0', '1');
  PalStart: int = $1000300;
  ChrCtrl: array['A'..']'] of char = (#1,#2,#3,#4,#5,#6,#7,#8,#9,#10,#11,#12,
     #13,#14,#15,#16,#17,#18,#19,#20,#21,#22,#23,#24,#25,#26,#27,#28,#29);

var
  AppPath:string;
  AppTitle:string;

procedure msgz(const s:string); overload;
procedure msgz(const s1, s2:string); overload;
procedure msgz(i:integer); overload;
procedure msgz(i:int64); overload;
procedure msgz(a:ext); overload;
procedure msgz(b:Boolean); overload;
procedure msgz(i,j:int); overload;
procedure msgH(a:pointer); overload;
procedure msgH(a,b:pointer); overload;
procedure msgH(i:int); overload;
procedure msgH(i,j:int); overload;
function WinLong(wnd:hWnd; add:integer; sub:integer=0):integer;
function WinLongEx(wnd:hWnd; add:integer; sub:integer=0):integer;
function GetSysParamsInfo(Action:int; Param:int=0):int;
procedure zD; overload;
procedure zD(b: Boolean); overload;
procedure zM(const s:string); overload;
procedure zM(const s1, s2:string); overload;
procedure zM(i:integer); overload;
procedure zM(i,j:int); overload;
procedure zM(a:ext); overload;
procedure zM(a,b:ext); overload;
procedure zM(b:Boolean); overload;
procedure zMH(a:pointer); overload;
procedure zMH(a,b:pointer); overload;
procedure zMH(i:int); overload;
procedure zMH(i,j:int); overload;
function IfThen(b:boolean; const t: string; const f:string = ''):string; overload;
function DecRect(const r:TRect):TRect;
function SizeRect(const r:TRect):TRect;
procedure zCount;
procedure zStopCount(min:DWord = 0);
function zSwap(var a,b):int; {$IFDEF D2005}inline;{$ENDIF}

// 'inline' is buggy. zSet(v, v - 1) would give wrong value if zSet is inlined
function zSet(var a: int1; b: int1):int1; overload;
function zSet(var a: int2; b: int2):int2; overload;
function zSet(var a: int4; b: int4):int4; overload;
function zSet(var a: int8; b: int8):int4; overload;
function zSet(var a: uint1; b: uint1):uint1; overload;
function zSet(var a: uint2; b: uint2):uint2; overload;
function zSet(var a: uint4; b: uint4):uint4; overload;
function zSet(var a: Boolean; b: Boolean):Boolean; overload;
function zSet(var a: ptr; b: ptr):ptr; overload;
function zSet(var a: string; const b: string):string; overload;

function IntoRange(v, min, max:int):int; {$IFDEF D2005}inline;{$ENDIF}
procedure CopyMemory(Destination: Pointer; Source: Pointer; Length: DWORD); {$IFDEF D2005}inline;{$ENDIF}
// These two are only for elements' sizes less than 2048
// Call before SetLength. Moves item Index to the end of array.
procedure ArrayDelete(var Arr; Index:int; Size:int);
// Call after SetLength. Moves last item in the array to Index.
procedure ArrayInsert(var Arr; Index:int; Size:int);
function SqDifference(cl1,cl2:int):int; //deprecated;
function FileAge(const FileName: string): Integer;
function RectW(const r: TRect): int; inline;
function RectH(const r: TRect): int; inline;
function RDiv(i, j: int): int; inline;  // round(i/j)
{$IFDEF MSWINDOWS}
// Borland's original routines bug: they don't consider '/' a path delimiter.
function FileExists(const FileName: string): Boolean;
function ChangeFileExt(const FileName, Extension: string): string;
function ExtractFilePath(const FileName: string): string;
function ExtractFileDir(const FileName: string): string;
function ExtractFileDrive(const FileName: string): string;
function ExtractFileName(const FileName: string): string;
function ExtractFileExt(const FileName: string): string;
// ExtractRelativePath not changed, won't be so simple
function FileSearch(const Name, DirList: string): string;
function IsPathDelimiter(const S: string; Index: Integer): Boolean;
function IncludeTrailingBackslash(const S: string): string;
function IncludeTrailingPathDelimiter(const S: string): string;
function ExcludeTrailingBackslash(const S: string): string;
function ExcludeTrailingPathDelimiter(const S: string): string;
{$ENDIF}

implementation

//function WinLong(wnd:hWnd; nIndex:integer; add:integer; sub:integer=0):integer;
//begin
//  Result:=SetWindowLong(wnd,nIndex,(GetWindowLong(wnd,nIndex) or add) and not sub);
//end;

procedure msgz(const s:string); overload;
begin
  MessageBox(0,pchar(s),'',0);
end;

procedure msgz(const s1, s2:string); overload;
begin
  MessageBox(0,pchar(s1+' '+s2),'',0);
end;

procedure msgz(i:integer); overload;
begin
  MessageBox(0,pchar(IntToStr(i)),'',0);
end;

procedure msgz(i:int64); overload;
begin
  MessageBox(0,pchar(IntToStr(i)),'',0);
end;

procedure msgz(a:ext); overload;
begin
  MessageBox(0,pchar(FloatToStr(a)),'',0);
end;

procedure msgz(b:Boolean); overload;
const
  str: array[boolean] of PChar = ('false', 'true');
begin
  MessageBox(0, str[b],'',0);
end;

procedure msgz(i,j:int); overload;
begin
  MessageBox(0,pchar(IntToStr(i)+' '+IntToStr(j)),'',0);
end;

procedure msgH(a:pointer); overload;
begin
  msgh(DWord(a));
end;

procedure msgH(a,b:pointer); overload;
begin
  msgh(DWord(a), DWord(b));
end;

procedure msgH(i:int); overload;
begin
  MessageBox(0,pchar(IntToHex(i,8)),'',0);
end;

procedure msgH(i,j:int); overload;
begin
  MessageBox(0,pchar(IntToHex(i,8)+' '+IntToHex(j,8)),'',0);
end;

procedure zM(const s:string); overload;
begin
  OutputDebugString(pchar(s));
end;

procedure zM(const s1, s2:string); overload;
begin
  OutputDebugString(pchar(s1+' '+s2));
end;

procedure zM(i:integer); overload;
begin
  OutputDebugString(pchar(IntToStr(i)));
end;

procedure zM(a:ext); overload;
begin
  OutputDebugString(pchar(FloatToStr(a)));
end;

procedure zM(a,b:ext); overload;
begin
  OutputDebugString(pchar(FloatToStr(a)+' '+FloatToStr(b)));
end;

procedure zM(b:Boolean); overload;
const
  str: array[boolean] of PChar = ('false', 'true');
begin
  OutputDebugString( str[b]);
end;

procedure zM(i,j:int); overload;
begin
  OutputDebugString(pchar(IntToStr(i)+' '+IntToStr(j)));
end;

procedure zMH(a:pointer); overload;
begin
  zMH(DWord(a));
end;

procedure zMH(a,b:pointer); overload;
begin
  zMH(DWord(a), DWord(b));
end;

procedure zMH(i:int); overload;
begin
  OutputDebugString(pchar(IntToHex(i,8)));
end;

procedure zMH(i,j:int); overload;
begin
  OutputDebugString(pchar(IntToHex(i,8)+' '+IntToHex(j,8)));
end;

function WinLong(wnd:hWnd; add:integer; sub:integer=0):integer;
begin
  Result:=SetWindowLong(wnd,GWL_STYLE,(GetWindowLong(wnd,GWL_STYLE) or add) and not sub);
end;

function WinLongEx(wnd:hWnd; add:integer; sub:integer=0):integer;
begin
  Result:=SetWindowLong(wnd,GWL_EXSTYLE,(GetWindowLong(wnd,GWL_EXSTYLE) or add) and not sub);
end;

function GetSysParamsInfo(Action:int; Param:int=0):int;
begin
  SystemParametersInfo(Action, Param, @Result, 0);
end;

procedure zD; overload;
asm
  int 3
end;

procedure zD(b: Boolean); overload;
asm
  test al, al
  jnz @ok
  int 3
@ok:
end;

function IfThen(b:boolean; const t: string; const f:string = ''):string; overload;
begin
  if b then Result:=t else Result:=f;
end;

function DecRect(const r:TRect):TRect;
begin
  Result.Left:=r.Left+1;
  Result.Top:=r.Top+1;
  Result.Right:=r.Right-1;
  Result.Bottom:=r.Bottom-1;
end;

function SizeRect(const r:TRect):TRect;
begin
  Result.Right:=r.Right-r.Left;
  Result.Bottom:=r.Bottom-r.Top;
  Result.Left:=0;
  Result.Top:=0;
end;

var k:DWord;

procedure zCount;
begin
  k:=GetTickCount;
end;

procedure zStopCount(min:DWord = 0);
var i:DWord;
begin
  i:=GetTickCount-k;
  if i>min then
    MessageBox(0, ptr(IntToStr(i)), '', 0);
end;

function zSwap(var a,b):int; {$IFDEF D2005}inline;{$ENDIF}
begin
  Result:=int(b);
  int(b):=int(a);
  int(a):=Result;
end;

function zSet(var a: int1; b: int1):int1; overload;
begin
  a:= b;
  Result:= b;
end;

function zSet(var a: int2; b: int2):int2; overload;
begin
  a:= b;
  Result:= b;
end;

function zSet(var a: int4; b: int4):int4; overload;
begin
  a:= b;
  Result:= b;
end;

function zSet(var a: int8; b: int8):int4; overload;
begin
  a:= b;
  Result:= b;
end;

function zSet(var a: uint1; b: uint1):uint1; overload;
begin
  a:= b;
  Result:= b;
end;

function zSet(var a: uint2; b: uint2):uint2; overload;
begin
  a:= b;
  Result:= b;
end;

function zSet(var a: uint4; b: uint4):uint4; overload;
begin
  a:= b;
  Result:= b;
end;

function zSet(var a: Boolean; b: Boolean):Boolean; overload;
begin
  a:= b;
  Result:= b;
end;

function zSet(var a: ptr; b: ptr):ptr; overload;
begin
  a:= b;
  Result:= b;
end;

function zSet(var a: string; const b: string):string; overload;
begin
  a:= b;
  Result:= b;
end;

function IntoRange(v, min, max:int):int; {$IFDEF D2005}inline;{$ENDIF}
begin
  Result:=v;
  if Result<min then
    Result:=min
  else
    if Result>max then
      Result:=max;
end;

procedure CopyMemory(Destination: Pointer; Source: Pointer; Length: DWORD); {$IFDEF D2005}inline;{$ENDIF}
begin
  Move(Source^, Destination^, Length);
end;

// Call before SetLength. Moves item Index to the end of array.
procedure ArrayDelete(var Arr; Index:int; Size:int);
var
  Buf: array[0..2047] of byte;
  j:int; p:PChar;
begin
  j:=(length(string(Arr)) - 1)*Size; // High(Arr)*Size
  Index:=Index*Size;
  p:=PChar(Arr);
  CopyMemory(@Buf, p + Index, Size);
  CopyMemory(p + Index, p + Index + Size, j - Index);
  CopyMemory(p + j, @Buf, Size);
end;

// Call after SetLength. Moves last item in the array to Index.
procedure ArrayInsert(var Arr; Index:int; Size:int);
var
  Buf: array[0..2047] of byte;
  j:int; p:PChar;
begin
  j:=(length(string(Arr)) - 1)*Size; // High(Arr)*Size
  Index:=Index*Size;
  p:=PChar(Arr);
  CopyMemory(@Buf, p + j, Size);
  CopyMemory(p + Index + Size, p + Index, j - Index);
  CopyMemory(p + Index, @Buf, Size);
end;

(*
{$W-}
function ArrayDo(var Arr; Index:int; Size:int; Buf:ptr; Delete:boolean):int;
var
  j:int; p:PChar;
begin
  j:=(length(string(Arr)) - 1)*Size; // High(Arr)*Size
  Index:=Index*Size;
  p:=PChar(Arr);
  if Delete then
  begin
    CopyMemory(Buf, p + Index, Size);
    CopyMemory(p + Index, p + Index + Size, j - Index);
    CopyMemory(p + j, Buf, Size);
  end else
  begin
    CopyMemory(Buf, p + j, Size);
    CopyMemory(p + Index + Size, p + Index, j - Index);
    CopyMemory(p + Index, Buf, Size);
  end;
  Result:=Size;
end;

{$W-}

// !!!! 4-byte boundary needed for esp!!!
procedure ArrayDelete(var Arr; Index:int; Size:int); // Call before SetLength
asm
  sub esp, ecx
  push esp
  push true
  call ArrayDo
  add esp, eax
end;

procedure ArrayInsert(var Arr; Index:int; Size:int); // Call after SetLength
asm
  sub esp, ecx
  push esp
  push false
  call ArrayDo
  add esp, eax
end;
*)

function SqDifference(cl1,cl2:int):int;
begin
  Result:= sqr(cl1 and $ff - cl2 and $ff) +
           sqr((cl1 and $ff00 - cl2 and $ff00) div $100) +
           sqr((cl1 and $ff0000 - cl2 and $ff0000) div $10000);
end;

function FileAge(const FileName: string): Integer;
begin
{$WARNINGS OFF}
  Result:= SysUtils.FileAge(FileName);
{$WARNINGS ON}
end;

function RectW(const r: TRect): int; inline;
begin
  with r do
    Result:= Right - Left;
end;

function RectH(const r: TRect): int; inline;
begin
  with r do
    Result:= Bottom - Top;
end;

function RDiv(i, j: int): int; inline;
begin
  Result:= (i*2 div j + 1) div 2;
end;

// code mostly by DVM from delphimaster.ru forum
function FileExists(const FileName: string): Boolean;

  function ExistsLockedOrShared(const Filename: string): Boolean;
  var
    FindData: TWin32FindData;
    LHandle: THandle;
  begin
    LHandle := FindFirstFile(PChar(Filename), FindData);
    if LHandle <> INVALID_HANDLE_VALUE then
    begin
      Windows.FindClose(LHandle);
      Result := FindData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY = 0;
    end
    else
      Result := False;
  end;

var
  Code: Integer;
  LastError: Cardinal;
  OldMode: Cardinal;
begin
  // avoid a dialog when checking CD
  OldMode := SetErrorMode(SEM_FAILCRITICALERRORS);
  try
    Code := Integer(GetFileAttributes(PChar(FileName)));
    if Code <> -1 then
      Result := (FILE_ATTRIBUTE_DIRECTORY and Code = 0)
    else
    begin
      LastError := GetLastError;
      Result := (LastError <> ERROR_FILE_NOT_FOUND) and
        (LastError <> ERROR_PATH_NOT_FOUND) and
        (LastError <> ERROR_INVALID_NAME) and ExistsLockedOrShared(Filename);
    end;
  finally
    SetErrorMode(OldMode);
  end;
end;

// Path functions: support '/' on Windows

const
  PathDelimStr  = '\/';
  PathDelims = ['\', '/'];

function ChangeFileExt(const FileName, Extension: string): string;
var
  I: Integer;
begin
  I := LastDelimiter('.' + PathDelimStr + DriveDelim,Filename);
  if (I = 0) or (FileName[I] <> '.') then I := MaxInt;
  Result := Copy(FileName, 1, I - 1) + Extension;
end;

function ExtractFilePath(const FileName: string): string;
var
  I: Integer;
begin
  I := LastDelimiter(PathDelimStr + DriveDelim, FileName);
  Result := Copy(FileName, 1, I);
end;

function ExtractFileDir(const FileName: string): string;
var
  I: Integer;
begin
  I := LastDelimiter(PathDelimStr + DriveDelim, Filename);
  if (I > 1) and (FileName[I] in PathDelims) and
    (not IsDelimiter( PathDelimStr + DriveDelim, FileName, I-1)) then Dec(I);
  Result := Copy(FileName, 1, I);
end;

function ExtractFileDrive(const FileName: string): string;
var
  I, J: Integer;
begin
  if (Length(FileName) >= 2) and (FileName[2] = DriveDelim) then
    Result := Copy(FileName, 1, 2)
  else if (Length(FileName) >= 2) and (FileName[1] in PathDelims) and
    (FileName[2] in PathDelims) then
  begin
    J := 0;
    I := 3;
    While (I < Length(FileName)) and (J < 2) do
    begin
      if FileName[I] in PathDelims then Inc(J);
      if J < 2 then Inc(I);
    end;
    if FileName[I] in PathDelims then Dec(I);
    Result := Copy(FileName, 1, I);
  end else Result := '';
end;

function ExtractFileName(const FileName: string): string;
var
  I: Integer;
begin
  I := LastDelimiter(PathDelimStr + DriveDelim, FileName);
  Result := Copy(FileName, I + 1, MaxInt);
end;

function ExtractFileExt(const FileName: string): string;
var
  I: Integer;
begin
  I := LastDelimiter('.' + PathDelimStr + DriveDelim, FileName);
  if (I > 0) and (FileName[I] = '.') then
    Result := Copy(FileName, I, MaxInt) else
    Result := '';
end;

// ExtractRelativePath not changed, won't be so simple

function FileSearch(const Name, DirList: string): string;
var
  I, P, L: Integer;
  C: Char;
begin
  Result := Name;
  P := 1;
  L := Length(DirList);
  while True do
  begin
    if FileExists(Result) then Exit;
    while (P <= L) and (DirList[P] = PathSep) do Inc(P);
    if P > L then Break;
    I := P;
    while (P <= L) and (DirList[P] <> PathSep) do
    begin
      if DirList[P] in LeadBytes then
        P := NextCharIndex(DirList, P)
      else
        Inc(P);
    end;
    Result := Copy(DirList, I, P - I);
    C := AnsiLastChar(Result)^;
    if (C <> DriveDelim) and not (C in PathDelims) then
      Result := Result + '\';
    Result := Result + Name;
  end;
  Result := '';
end;

function IsPathDelimiter(const S: string; Index: Integer): Boolean;
begin
  Result := (Index > 0) and (Index <= Length(S)) and (S[Index] in PathDelims)
    and (ByteType(S, Index) = mbSingleByte);
end;

function IncludeTrailingBackslash(const S: string): string;
begin
  Result := IncludeTrailingPathDelimiter(S);
end;

function IncludeTrailingPathDelimiter(const S: string): string;
begin
  Result := S;
  if not IsPathDelimiter(Result, Length(Result)) then
    Result := Result + '\';
end;

function ExcludeTrailingBackslash(const S: string): string;
begin
  Result := ExcludeTrailingPathDelimiter(S);
end;

function ExcludeTrailingPathDelimiter(const S: string): string;
begin
  Result := S;
  if IsPathDelimiter(Result, Length(Result)) then
    SetLength(Result, Length(Result)-1);
end;


{------------------ Copy -----------------}
{

function SqDifference(cl1,cl2:TColor):integer;
begin
  cl1:=ColorToRGB(cl1);
  cl2:=ColorToRGB(cl2);
  Result:=sqr(Byte(cl1)-Byte(cl2))
          + sqr(Byte(cl1 shr 8)-Byte(cl2 shr 8))
          + sqr(Byte(cl1 shr 16)-Byte(cl2 shr 16));
end;

function IsThere(a:PChar; s2:string):integer;
begin
  if s2<>'' then
    Result := CompareString(LOCALE_USER_DEFAULT, NORM_IGNORECASE, a,
      length(s2), ptr(s2), length(s2)) - 2
  else
    Result:=false;
end;

function IsThere1(a:PChar; s:string):boolean;
begin
  if s='' then result:=false
  else Result:=CompareMem(a,PChar(s),length(s));
end;

function IncThere(var a:PChar; s:string):integer;
begin
  Result:=IsThere(a,s);
  if Result=0 then inc(a,length(s));
end;

function IncThere1(var a:PChar; s:string):boolean;
begin
  Result:=IsThere1(a,s);
  if Result then inc(a,length(s));
end;

}

initialization
  AppPath:=ExtractFilePath(ParamStr(0));
end.
