unit RSCodeHook;

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
  Windows, RSSysUtils, RSQ, Math, SysUtils;

type
  TRSHookType = (RShtNop, RSht1, RSht2, RSht4, RShtCall, RShtJmp, RShtJmp6,
    RShtJmp2, RShtBStr, RShtStr, RShtCallStore, RShtBefore, RShtAfter,
    RShtFunctionStart, RShtCodePtrStore);
{
  RShtCallStore - store original function ptr in eax
  RShtBefore, RShtAfter - seemlessly "insert" new code before/after
  RShtFunctionStart - like RShtCallStore, but placed at the start of a function
}

  PRSHookInfo = ^TRSHookInfo;
  TRSHookInfo = record
    p: int;
    pref: Boolean;
    old: int;
    oldstr: string;
    backup: ptr;
    add: int;
    new: int;
    newp: ptr;
    newref: Boolean;
    newstr: string;
    t: TRSHookType;
    size: int;
    Querry: int;
  end;

function AllocCode(n: int): int;
procedure RSApplyHook(const Hook: TRSHookInfo);
procedure RSApplyHooks(const Hooks; Querry: int = 0);
function RSCheckHook(const hk:TRSHookInfo): Boolean;
function RSCheckHooks(const Hooks): int; overload;
function RSCheckHooks(const Hooks; Querry: int): int; overload;
function RSGetHookValue(const hk: TRSHookInfo): int;

implementation

var
  AllocPtr: PChar;
  AllocSize: int;

function AllocCode(n: int): int;
begin
  if AllocSize < n then
  begin
    AllocSize:= max(n, RSGetPageSize);
    AllocPtr:= VirtualAlloc(nil, AllocSize, MEM_COMMIT, PAGE_EXECUTE_READWRITE);
  end;
  Result:= int(AllocPtr);
  inc(AllocPtr, n);
  dec(AllocSize, n);
end;

procedure CopyCode(dest, p, n: int);
begin
  CopyMemory(ptr(dest), ptr(p), n);
  if (pbyte(p)^ in [$E8, $E9]) and (puint(p+1)^ + 5 > uint(n)) then
    inc(pint(dest+1)^, p - dest);
end;

function RSGetHookValue(const hk: TRSHookInfo):int;
var p: int;
begin
  p:= hk.p;
  case hk.t of
    RSht1:  Result:= pbyte(p)^;
    RSht2:  Result:= pword(p)^;
    RSht4, RShtCodePtrStore:  Result:= pint(p)^;
    RShtCall, RShtJmp, RShtCallStore:
      Result:= pint(p+1)^ + p + 5;
    RShtJmp6:
      Result:= pint(p+2)^ + p + 6;
    RShtJmp2:
      Result:= pint1(p+1)^ + p + 2;
    else
      Result:= 0;
  end;
end;

function Jmp(p, dest: int; call: Boolean = false): int;
begin
  if call then
    pbyte(p)^:= $E8
  else
    pbyte(p)^:= $E9;
  Result:= p + 5;
  pint(p+1)^:= dest - Result;
end;

procedure RSApplyHook(const Hook: TRSHookInfo);
var
  OldProtect: DWord;
  sz, sz0, new, i, p, p1: int;
begin
  case Hook.t of
    RShtNop:   sz0:= 0;
    RSht1:     sz0:= 1;
    RSht2:     sz0:= 2;
    RSht4, RShtCodePtrStore:  sz0:= 4;
    RShtJmp2:  sz0:= 2;
    RShtJmp6:  sz0:= 6;
    RShtBStr:  sz0:= length(Hook.oldstr);
    RShtStr:   sz0:= length(Hook.oldstr) + 1;
    else       sz0:= 5;
  end;
  sz:= max(Hook.size, sz0);
  p:= Hook.p;
  if Hook.pref then  p:= pint(p)^;
  new:= int(Hook.newp);
  if new = 0 then  new:= Hook.new;
  if Hook.newref then  new:= pint(new)^;
  if Hook.add <> 0 then  new:= RSGetHookValue(Hook) + Hook.add;
  if Hook.backup <> nil then  pint(Hook.backup)^:= RSGetHookValue(Hook);

  VirtualProtect(ptr(p), sz, PAGE_EXECUTE_READWRITE, @OldProtect);
  case Hook.t of
    RSht1:    pbyte(p)^:= new;
    RSht2:    pword(p)^:= new;
    RSht4:    pint(p)^:= new;
    RShtJmp6: pint(p+2)^:= new - p - 6;
    RShtJmp2: pint1(p+1)^:= new - p - 2;
    RShtCall: Jmp(p, new, true);
    RShtJmp:  Jmp(p, new);
    RShtBStr, RShtStr:
      CopyMemory(ptr(p), PChar(Hook.newstr), sz0);
    RShtCallStore:
    begin
      p1:= AllocCode(10);
      pbyte(p1)^:= $B8;          // mov eax, @orig
      pint(p1+1)^:= RSGetHookValue(Hook);
      Jmp(p, p1, true);
      Jmp(p1 + 5, new);          // jmp @hook
    end;
    RShtBefore:
    begin
      p1:= AllocCode(sz + 10);
      CopyCode(p1 + 5, p, sz);
      Jmp(p, p1);
      Jmp(p1, new, true);        // call @hook
      Jmp(p1 + 5 + sz, p + sz);  // std...jmp @after
      if Hook.backup <> nil then  pint(Hook.backup)^:= p1 + 5;
    end;
    RShtAfter:
    begin
      p1:= AllocCode(sz + 10);
      CopyCode(p1, p, sz);       // std
      Jmp(p, p1);
      pbyte(p1 + sz)^:= $68;     // push @after
      pint(p1 + sz + 1)^:= p + sz;
      Jmp(p1 + sz + 5, new);     // jmp @hook
    end;
    RShtFunctionStart:
    begin
      p1:= AllocCode(sz + 15);
      CopyCode(p1 + 10, p, sz);
      Jmp(p, p1);
      pbyte(p1)^:= $B8;          // mov eax, @std
      pint(p1+1)^:= p1 + 10;
      Jmp(p1 + 5, new);          // jmp @hook
      Jmp(p1 + 10 + sz, p + sz); // std...jmp @after
      if Hook.backup <> nil then  pint(Hook.backup)^:= p1 + 10;
    end;
    RShtCodePtrStore:
    begin
      p1:= AllocCode(10);
      pbyte(p1)^:= $B8;          // mov eax, @std
      pint(p1+1)^:= pint(p)^;
      Jmp(p1 + 5, new);          // jmp @hook
      pint(p)^:= p1;
    end;
  end;
  for i := sz0 to sz - 1 do
    pbyte(p+i)^:= $90;
  VirtualProtect(ptr(p), sz, OldProtect, @OldProtect);
end;

procedure RSApplyHooks(const Hooks; Querry: int = 0);
var
  hk: PRSHookInfo;
begin
  hk:= @Hooks;
  while hk.p <> 0 do
  begin
    if hk.Querry = Querry then
      RSApplyHook(hk^);
    inc(hk);
  end;
end;

function RSCheckHook(const hk:TRSHookInfo): Boolean;
begin
  Result:= true;
  if hk.old = 0 then
    if (hk.newp <> nil) or (hk.add <> 0) or not (hk.t in [RSht1, RSht2, RSht4, RShtBStr, RShtStr]) then
      exit;

  if hk.t in [RShtBStr, RShtStr] then
    Result:= CompareMem(ptr(hk.p), PChar(hk.oldstr), length(hk.oldstr) + IfThen(hk.t = RShtStr, 1, 0))
  else
    Result:= RSGetHookValue(hk) = hk.old;
end;

function RSCheckHooks(const Hooks): int;
var
  hk: PRSHookInfo;
begin
  hk:= @Hooks;
  Result:= 0;
  while hk.p <> 0 do
  begin
    if not RSCheckHook(hk^) then  exit;
    inc(hk);
    inc(Result);
  end;
  Result:= -1;
end;

function RSCheckHooks(const Hooks; Querry: int): int;
var
  hk: PRSHookInfo;
begin
  hk:= @Hooks;
  Result:= 0;
  while hk.p <> 0 do
  begin
    if (hk.Querry = Querry) and not RSCheckHook(hk^) then  exit;
    inc(hk);
    inc(Result);
  end;
  Result:= -1;
end;

end.
