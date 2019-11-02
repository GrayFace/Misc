unit RSSysUtilsOld;

{ *********************************************************************** }
{                                                                         }
{ RSPak                                    Copyright (c) Rozhenko Sergey  }
{ http://sites.google.com/site/sergroj/                                   }
{ sergroj@mail.ru                                                         }
{                                                                         }
{ This file is a subject to any one of these licenses at your choice:     }
{ BSD License, MIT License, Apache License, Mozilla Public License.       }
{                                                                         }
{ *********************************************************************** }
{$I RSPak.inc}

interface

uses
  SysUtils, Windows, Messages, SysConst, ShellAPI, Classes, RSQ, Types, Math,
  RTLConsts, RSSysUtils;

{--------}

type
  TRSObjectInstance = packed record
    Code: array[0..4] of byte;
    Proc: ptr;
    Obj: ptr;
  end;

procedure RSMakeObjectInstance(var ObjInst:TRSObjectInstance;
             Obj, ProcStdCall:ptr); deprecated;

procedure RSCustomObjectInstance(var ObjInst:TRSObjectInstance;
             Obj, Proc, CustomProc:ptr); deprecated;

function RSMakeLessParamsFunction(
            ProcStdCall, Param:ptr):Pointer; overload; deprecated;

function RSMakeLessParamsFunction(
            ProcStdCall:pointer; DWordParams:Pointer;
            Count:integer; ResultInParam:integer=-1):Pointer; overload; deprecated;

function RSMakeLessParamsFunction(
            ProcStdCall:pointer; const DWordParams:array of DWord;
            ResultInParam:integer=-1):Pointer; overload; deprecated;

procedure RSFreeLessParamsFunction(Ptr:Pointer); deprecated;

{--------}

function RSCreateRemoteCopy(CurPtr:Pointer; var RemPtr:Pointer;
                      Len, hProcess:DWord; var Mapping:DWord):boolean;

function RSCreateRemoteCopyID(CurPtr:Pointer; var RemPtr:Pointer;
                      Len, ProcessID:DWord; var Mapping:DWord):boolean;

function RSCreateRemoteCopyWnd(CurPtr:Pointer; var RemPtr:Pointer;
                     Len:DWord; wnd:hWnd; var Mapping:DWord):boolean;

function RSFreeRemoteCopy(CurPtr, RemPtr:pointer;
                           Len, hProcess, Mapping:DWord):boolean;

function RSFreeRemoteCopyID(CurPtr, RemPtr:pointer;
                             Len, ProcessID, Mapping:DWord):boolean;

function RSFreeRemoteCopyWnd(CurPtr, RemPtr:pointer;
                          Len:DWord; wnd:hWnd; Mapping:DWord):boolean;

{--------}

function RSSendDataMessage(hWnd:HWnd; Msg:DWord; wParam:WParam;
           lParam:LParam; var lpdwResult:DWord; wDataLength:DWord=0;
           lDataLength:DWord=0; wReadOnly:boolean=false;
           lReadOnly:boolean=false):boolean;

function RSSendDataMessageTimeout(hWnd:HWnd; Msg:DWord; wParam:WParam;
           lParam:LParam; fuFlags,uTimeout:DWord; var lpdwResult:DWord;
           wDataLength:DWord=0; lDataLength:DWord=0;
           wReadOnly:boolean=false; lReadOnly:boolean=false):boolean;

function RSSendDataMessageCallback(hWnd:HWnd; Msg:DWord; wParam:WParam;
           lParam:LParam; lpCallBack:Pointer; dwData:DWord;
           wDataLength:DWord=0; lDataLength:DWord=0;
           wReadOnly:boolean=true; lReadOnly:boolean=true):boolean;

function RSPostDataMessage(hWnd:HWnd; Msg:DWord; wParam:WParam;
           lParam:LParam; wDataLength:DWord=0;
           lDataLength:DWord=0; wReadOnly:boolean=true;
           lReadOnly:boolean=true):boolean;

{--------}

 // Use RSDebug instead
function RSHandleException(FuncSkip:integer=0; TraceLimit:integer=0; EAddr:pointer=nil; EObj:TObject=nil):string; deprecated;

{--------}

implementation

var
  OSVersion: OSVERSIONINFO absolute RSOSVersionInfo;

const
  PageSize = 4096;

{$W-} // Unused stack frames are not welcome here (RSDelayLoad)
{$H+} // Long strings

function CalcJmpOffset(Src, Dest: Pointer): Pointer;
begin
  Result := ptr(Longint(Dest) - (Longint(Src) + 5));
end;

function MakeCall(Caller, JumpTo:ptr):ptr;
begin
  PByte(Caller)^:=$E8;
  inc(PByte(Caller));
  Result:=PChar(Caller)+4;
  pptr(Caller)^:= ptr(int(JumpTo) - int(Result));
end;

{---------------------- RSMakeLessParamsFunction ---------------------}

procedure ObjectInstanceProc;
asm
  pop eax
  pop edx // Return address
  push [eax + 4] // Param
  push edx // Return address
  jmp [eax]
end;

procedure ObjectInstanceProcRegisterSmall;
asm
  mov ecx, edx
  mov edx, eax
  pop eax
  push [eax] // Return address
  mov eax, [eax+4] // Param
end;

{
procedure ObjectInstanceProcRegisterBig;
asm
  xchg ecx, [esp+4]
  xchg ecx, [esp]
  xchg edx, ecx
  xchg eax, edx
  push [eax] // Return address
  mov eax, [eax+4] // Param
end;
}

procedure RSMakeObjectInstance(var ObjInst:TRSObjectInstance;
   Obj, ProcStdCall:ptr);
begin
  MakeCall(@ObjInst.Code, @ObjectInstanceProc);
  ObjInst.Proc:=ProcStdCall;
  ObjInst.Obj:=Obj;
end;

procedure RSCustomObjectInstance(var ObjInst:TRSObjectInstance;
             Obj, Proc, CustomProc:ptr);
begin
  MakeCall(@ObjInst.Code, CustomProc);
  ObjInst.Proc:=Proc;
  ObjInst.Obj:=Obj;
end;

function RSMakeLessParamsFunction(
   ProcStdCall:pointer; Param:ptr):Pointer; overload;
begin
  GetMem(Result, SizeOf(TRSObjectInstance));
  RSMakeObjectInstance(TRSObjectInstance(Result^), ProcStdCall, Param);
end;

procedure LessParamsProc;
asm
  pop eax
  
// EAX structure:
//  Params Count
//  Proc address
//  Params...

  mov ecx, [eax] // Count
  add eax, 4 // Skip Count
   // Don't skip Proc address, ecx*4 will skip it
  pop edx // Return address

@loop:
  push [eax + ecx*4]
  dec ecx
  jz @loop

  push edx // Return address
  jmp [eax]
end;

function RSMakeLessParamsFunction(
            ProcStdCall:pointer; DWordParams:Pointer;
            Count:int; ResultInParam:int=-1):Pointer; overload;
var i:integer; n:int; p:pptr;
begin
  if (ResultInParam>=0) and (ResultInParam<=Count) then
    n:=Count+1
  else
    n:=Count;
  GetMem(Result, 5+8 + 4*n);
  p:=MakeCall(Result, @LessParamsProc);
  p^:=ptr(Count);
  inc(p);
  p^:=ProcStdCall;
  inc(p);

  for i:=0 to Count-1 do
  begin
    if ResultInParam=i then
    begin
      p^:=Result;
      inc(p);
    end;
    p^:=pptr(DWordParams)^;
    inc(p);
    inc(pptr(DWordParams));
  end;
  
  if ResultInParam=Count then p^:=Result;
end;

{
function RSMakeLessParamsFunction(
            ProcStdCall:pointer; DWordParams:Pointer;
            Count:integer; ResultInParam:integer=-1):Pointer; overload;
const First=$58;    // POP EAX
      Loop=$68;     // PUSH DWordParams[i]
      Middle=$B850; // PUSH EAX
                    // MOV EAX ProcPtr
      Last=$E0FF;   // JMP EAX
      EdgesSize = SizeOf(First) + SizeOf(Middle) + SizeOf(Last) + 4;
      LoopSize = SizeOf(Loop) + 4;

var p:Pointer;

  procedure AddParam(const i:DWord);
  begin
    PByte(p)^:=Loop;
    inc(PByte(p));
    PDWord(p)^:=i;
    inc(PDWord(p));
  end;

var i:integer; n:DWord;
begin
  if (ResultInParam>=0) and (ResultInParam<=Count) then n:=Count+1
  else n:=Count;
  i:= EdgesSize + LoopSize*n;
  GetMem(p,i);
  Result:=p;
  if Result=nil then exit;
  PByte(p)^:=First;
  inc(PByte(p));
  DWordParams:=pointer(DWord(DWordParams)+Dword(Count)*4);
  if ResultInParam=Count then AddParam(DWord(Result));
  for i:=Count-1 downto 0 do
  begin
    dec(PDWord(DWordParams));
    AddParam(PDWord(DWordParams)^);
    if ResultInParam=i then AddParam(DWord(Result));
  end;
  PWord(p)^:=Middle;
  inc(PWord(p));
  PPointer(p)^:=ProcStdCall;
  inc(PPointer(p));
  PWord(p)^:=Last;
//  inc(PWord(p));
end;
}

function RSMakeLessParamsFunction(
            ProcStdCall:pointer; const DWordParams:array of DWord;
            ResultInParam:integer=-1):Pointer; overload;
begin
  Result:=RSMakeLessParamsFunction(
                  ProcStdCall, @DWordParams[low(DWordParams)],
                  high(DWordParams)-low(DWordParams)+1, ResultInParam);
end;

procedure RSFreeLessParamsFunction(Ptr:Pointer);
begin
  FreeMem(Ptr);
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

{----------------------- RSCreateRemoteCopy --------------------------}

function RSCreateRemoteCopy(CurPtr:Pointer; var RemPtr:Pointer;
                      Len, hProcess:DWord; var Mapping:DWord):boolean;
begin
  Result:=false;
  if OSVersion.dwPlatformId = VER_PLATFORM_WIN32_WINDOWS then
  begin // Win 9x
    Mapping:=CreateFileMapping(INVALID_HANDLE_VALUE, nil,
                                     PAGE_READWRITE, 0, Len, nil);
    if Mapping=0 then exit;
    RemPtr:=MapViewOfFile(Mapping,FILE_MAP_ALL_ACCESS,0,0,0);
    if RemPtr=nil then
    begin
      CloseHandle(Mapping);
      exit;
    end;
    Move(CurPtr^,RemPtr^,Len);
    Result:=true;
  end else
  begin // Win NT
    if hProcess=0 then exit;
    Mapping:=0;
    RemPtr:=VirtualAllocEx(hProcess, nil, Len, MEM_COMMIT,
                                   PAGE_EXECUTE_READWRITE);
    if RemPtr=nil then exit;
    Result:=WriteProcessMemory(hProcess, RemPtr,
                                       CurPtr, Len, Cardinal(nil^));
  end;
end;

function RSCreateRemoteCopyID(CurPtr:Pointer; var RemPtr:Pointer;
                      Len, ProcessID:DWord; var Mapping:DWord):boolean;
var Pr:DWord;
begin
  if OSVersion.dwPlatformId <> VER_PLATFORM_WIN32_WINDOWS then
    if ProcessID=0 then Result:=false
    else begin
      Pr:=OpenProcess(PROCESS_VM_OPERATION or PROCESS_VM_WRITE, false,
         ProcessID);
      Result:=RSCreateRemoteCopy(CurPtr, RemPtr, Len, Pr, Mapping);
      if Pr<>0 then CloseHandle(Pr);
    end
  else Result:=RSCreateRemoteCopy(CurPtr, RemPtr, Len, 0, Mapping);
end;

function RSCreateRemoteCopyWnd(CurPtr:Pointer; var RemPtr:Pointer;
                     Len:DWord; wnd:hWnd; var Mapping:DWord):boolean;
var pID, Pr:DWord;
begin
  if OSVersion.dwPlatformId <> VER_PLATFORM_WIN32_WINDOWS then
  begin
    GetWindowThreadProcessId(wnd, pID);
    if pID=0 then Result:=false
    else begin
      Pr:=OpenProcess(PROCESS_VM_OPERATION or PROCESS_VM_WRITE,
                         false, pID);
      Result:=RSCreateRemoteCopy(CurPtr, RemPtr, Len, Pr, Mapping);
      if Pr<>0 then CloseHandle(Pr);
    end;
  end else Result:=RSCreateRemoteCopy(CurPtr, RemPtr, Len, 0, Mapping);
end;

{------------------------- RSFreeRemoteCopy --------------------------}

function RSFreeRemoteCopy(CurPtr, RemPtr:pointer;
                           Len, hProcess, Mapping:DWord):boolean;
begin
  if OSVersion.dwPlatformId = VER_PLATFORM_WIN32_WINDOWS then
  begin // Win 9x
    try
      if Len<>0 then Move(RemPtr^, CurPtr^, Len);
      Result:=true;
    except
      Result:=false;
    end;
    UnmapViewOfFile(RemPtr);
    CloseHandle(Mapping);
  end else
  begin // Win NT
    if hProcess=0 then
    begin
      Result:=false;
      exit;
    end;
    Result:=(Len=0) or ReadProcessMemory(hProcess, RemPtr,
                                        CurPtr, Len, Cardinal(nil^));
    VirtualFreeEx(hProcess, RemPtr, 0, MEM_RELEASE);
  end;
end;

function RSFreeRemoteCopyID(CurPtr, RemPtr:pointer;
                             Len, ProcessID, Mapping:DWord):boolean;
var Pr:DWord;
begin
  if OSVersion.dwPlatformId <> VER_PLATFORM_WIN32_WINDOWS then
    if ProcessID=0 then Result:=false
    else begin
      Pr:=OpenProcess(PROCESS_VM_OPERATION or PROCESS_VM_READ, false,
         ProcessID);
      Result:=RSFreeRemoteCopy(CurPtr, RemPtr, Len, Pr, Mapping);
      if Pr<>0 then CloseHandle(Pr);
    end
  else Result:=RSFreeRemoteCopy(CurPtr, RemPtr, Len, 0, Mapping);
end;

function RSFreeRemoteCopyWnd(CurPtr, RemPtr:pointer;
                          Len:DWord; wnd:hWnd; Mapping:DWord):boolean;
var pID, Pr:DWord;
begin
  if OSVersion.dwPlatformId <> VER_PLATFORM_WIN32_WINDOWS then
  begin
    GetWindowThreadProcessId(wnd, pID);
    if pID=0 then Result:=false
    else begin
      Pr:=OpenProcess(PROCESS_VM_OPERATION or PROCESS_VM_READ,
                       false, pID);
      Result:=RSFreeRemoteCopy(CurPtr, RemPtr, Len, Pr, Mapping);
      if Pr<>0 then CloseHandle(Pr);
    end
  end else Result:=RSFreeRemoteCopy(CurPtr, RemPtr, Len, 0, Mapping);
end;

{------------------------- SendDataMessage ---------------------------}

type
  TCallback=procedure(hwnd:HWND; uMsg, dwData:DWord; lResult:LRESULT);
  TSendDetails=record
    Process:DWord;
    wMap:DWord;
    wParam:pointer;
    wPtr:pointer;
    wLen:DWord;
    lMap:DWord;
    lParam:pointer;
    lPtr:pointer;
    lLen:DWord;
    Callback:Pointer;
    CallData:DWord;
  end;
  PSendDetails=^TSendDetails;

function PrepareDataMessage(var SD:TSendDetails; hWnd:HWnd; var wParam:WParam;
           var lParam:LParam; wDataLength:DWord;
           lDataLength:DWord; wReadOnly:boolean;
           lReadOnly:boolean):boolean;
begin
  Result:=false;
  if OSVersion.dwPlatformId<>VER_PLATFORM_WIN32_WINDOWS then
  begin
    SD.Process:=TRSWnd(hWnd).OpenProcess(PROCESS_VM_OPERATION or
                        PROCESS_VM_READ or PROCESS_VM_WRITE, false);
    if SD.Process=0 then exit;
  end else SD.Process:=0; // For compiler

  SD.wParam:=pointer(wParam);
  if wReadOnly then SD.wLen:=0
  else SD.wLen:=wDataLength;
  if wDataLength=0 then SD.wPtr:=nil
  else begin
    if not RSCreateRemoteCopy(pointer(wParam),SD.wPtr,
                              wDataLength, SD.Process, SD.wMap)
    then exit;
    wParam:=DWord(SD.wPtr);
  end;

  SD.lParam:=pointer(lParam);
  if lReadOnly then SD.lLen:=0
  else SD.lLen:=lDataLength;

  if lDataLength=0 then SD.lPtr:=nil
  else begin
    if not RSCreateRemoteCopy(pointer(lParam),SD.lPtr,
          lDataLength, SD.Process, SD.lMap) and (wDataLength<>0) then
    begin
      RSFreeRemoteCopy(SD.wParam, SD.wPtr, 0, SD.Process, SD.wMap);
      exit;
    end;
    lParam:=DWord(SD.lPtr);
  end;

  SD.Callback:=nil;
  Result:=true;
end;

function FreeDataMessage(var SD:TSendDetails):boolean;
begin
  with SD do
  begin
    if wPtr<>nil then
      Result:=RSFreeRemoteCopy(wParam, wPtr, wLen, Process, wMap)
    else Result:=true;
    if lPtr<>nil then
      Result:=RSFreeRemoteCopy(lParam, lPtr, lLen, Process, lMap)
                                                         and Result;
    if Process<>0 then CloseHandle(Process);
  end;
end;

procedure FreeDataCallback(hwnd:HWND; uMsg, dwData:DWord;
                                            lResult:LRESULT); stdcall;
var SD:PSendDetails;
begin
  SD:=Pointer(dwData);
  FreeDataMessage(SD^);
  if SD^.Callback<>nil then
    TCallback(SD^.Callback)(hwnd, uMsg, SD^.CallData, lResult);
  Dispose(SD);
end;

function RSSendDataMessage(hWnd:HWnd; Msg:DWord; wParam:WParam;
           lParam:LParam; var lpdwResult:DWord; wDataLength:DWord=0;
           lDataLength:DWord=0; wReadOnly:boolean=false;
           lReadOnly:boolean=false):boolean;
var SD:TSendDetails;
begin
  Result:=PrepareDataMessage(SD, hwnd, wParam, lParam, wDataLength,
                                 lDataLength, wReadOnly, lReadOnly);
  if not Result then exit;
  lpdwResult:=SendMessage(hWnd, Msg, wParam, lParam);
  Result:=FreeDataMessage(SD);
end;

function RSSendDataMessageTimeout(hWnd:HWnd; Msg:DWord; wParam:WParam;
           lParam:LParam; fuFlags,uTimeout:DWord; var lpdwResult:DWord;
           wDataLength:DWord=0; lDataLength:DWord=0;
           wReadOnly:boolean=false; lReadOnly:boolean=false):boolean;
var SD:PSendDetails;
begin
  New(SD);
  Result:=PrepareDataMessage(SD^,hwnd,wParam,lParam,wDataLength,
                                 lDataLength,wReadOnly,lReadOnly);
  if not Result then
  begin
    lpdwResult:=0;
    Dispose(SD);
    exit;
  end;
  Result:=SendMessageTimeout(hWnd, Msg, wParam, lParam, fuFlags,
                                             uTimeout, lpdwResult)<>0;
  if Result then
  begin
    Result:=FreeDataMessage(SD^);
    Dispose(SD);
  end else
  begin
    SD.wLen:=0;
    SD.lLen:=0;
    if not SendMessageCallback(hWnd, WM_NULL, 0, 0,
            @FreeDataCallback, DWord(SD)) then
    begin
      FreeDataMessage(SD^);
      Dispose(SD);
    end;
  end;
end;

function RSSendDataMessageCallback(hWnd:HWnd; Msg:DWord; wParam:WParam;
           lParam:LParam; lpCallBack:Pointer; dwData:DWord;
           wDataLength:DWord=0; lDataLength:DWord=0;
           wReadOnly:boolean=true; lReadOnly:boolean=true):boolean;
var SD:PSendDetails;
begin
  New(SD);
  Result:=PrepareDataMessage(SD^,hwnd,wParam,lParam,wDataLength,
                                 lDataLength,wReadOnly,lReadOnly);
  if not Result then
  begin
    Dispose(SD);
    exit;
  end;
  SD^.Callback:=lpCallBack;
  SD^.CallData:=dwData;
  Result:=SendMessageCallback(hWnd, Msg, wParam, lParam,
                                 @FreeDataCallback, DWord(SD));
  if not Result then
  begin
    SD.wLen:=0;
    SD.lLen:=0;
    FreeDataMessage(SD^);
    Dispose(SD);
  end;
end;

function RSPostDataMessage(hWnd:HWnd; Msg:DWord; wParam:WParam;
           lParam:LParam; wDataLength:DWord=0;
           lDataLength:DWord=0; wReadOnly:boolean=true;
           lReadOnly:boolean=true):boolean;
begin
  Result:=RSSendDataMessageCallback(hWnd, Msg, wParam, lParam, nil, 0,
            wDataLength, lDataLength, wReadOnly, lReadOnly);
end;

function MethodsList(EBP:pointer; FuncSkip:integer):string;
const
  CallInfo=
    'EBP = %p    Return address: %p'#13#10;
  Bug=
    '...'#13#10;
var p,p1:PPtr;
begin
  p:=EBP;
  p1:=p;
  inc(p1);
  try
    while (p<>nil) and (p^<>p) do
    begin
      if FuncSkip<=0 then
        Result:=Result+Format(CallInfo, [p, p1^])
      else
        dec(FuncSkip);
      p:=p^;
      p1:=p;
      inc(p1);
    end;
  except
    Result:=Result+Bug; // К сожалению, нередкая ситуация.
  end;
end;

function StackTrace(EBP:pointer; Lim:integer):string;
const
  CallInfo=
    'Call: EBP=%p  RetAddr=%p';
begin

end;

function Registers(Context:PContext):string;
begin
end;

function RSHandleException(FuncSkip:integer=0; TraceLimit:integer=0; EAddr:pointer=nil; EObj:TObject=nil):string;
const
  TextShort=
    'Exception %s in module %s at %p.'#13#10+
    '%s.';
  TextMain=
     TextShort+#13#10+
        #13#10+
    'Absolute address: %p  Allocation base: %p'#13#10+
    'Module: %s  Base address: %p'#13#10;
  TextProc=
        #13#10+
        #13#10+
    'Methods calls:'#13#10+
        #13#10;
  TextStack=
        #13#10+
        #13#10+
    'Stack trace:'#13#10+
        #13#10;

  function ConvertAddr(Address: Pointer): Pointer;
  asm
    test eax, eax // Always convert nil to nil
    je @exit
    sub eax, $1000 // offset from code start; code start set by linker to $1000
  @exit:
  end;

var
  ModuleName, ModulePath, EText, EName:string;
  Temp:array[0..MAX_PATH] of Char;
  Info:TMemoryBasicInformation;
  ConvertedAddress:Pointer; p, ModuleBase:pointer;
begin
  if EObj=nil then
  begin
    EObj:=ExceptObject;
    EAddr:=ExceptAddr;
  end;
  //if TraceLimit<=0 then TraceLimit:=MaxInt;
  if VirtualQuery(EAddr, Info, sizeof(Info))=0 then
  begin

  end else
  begin
    if (Info.State <> MEM_COMMIT) or
      (GetModuleFilename(THandle(Info.AllocationBase), Temp, SizeOf(Temp)) = 0)
      then
    begin
      ModuleBase:=ptr(HInstance);
      GetModuleFileName(HInstance, Temp, SizeOf(Temp));
      ConvertedAddress := ConvertAddr(EAddr);
    end else
    begin
      ModuleBase:=Info.AllocationBase;
      int(ConvertedAddress):=int(EAddr)-int(ModuleBase);
    end;
    ModulePath:=Temp;
    ModuleName:=ExtractFileName(ModulePath);
    if EObj<>nil then
    begin
      EName:=EObj.ClassName;
      if EObj is Exception then
        EText:=Exception(EObj).Message;
    end;
    Result:=Format(TextMain, [EName, ModuleName, ConvertedAddress, EText,
                    EAddr, Info.AllocationBase, ModulePath, ModuleBase]);

    asm
      mov p, ebp
    end;

    Result:= Result + TextProc + MethodsList(p, FuncSkip);
    //Result:=Result+TextStack+StackTrace(p,TraceLimit);
  end;
end;

{-------------------------------------------------------}

initialization
  OSVersion.dwOSVersionInfoSize:=SizeOf(OSVersion);
  GetVersionEx(OSVersion);

end.
