unit Hooks;

interface

uses
  Windows, Messages, SysUtils, Classes, RSSysUtils, RSQ, Common, RSCodeHook,
  Math, MP3, RSDebug, IniFiles, Direct3D, MMSystem, Graphics, RSStrUtils,
  DirectDraw, DXProxy, RSResample, MMCommon, D3DHooks, MMHooks,
  LayoutSupport;

procedure HookAll;
procedure ApplyDeferredHooks;

implementation

const
  SecToTime: single = 128/30;
var
  QuickSaveUndone: Boolean;
  _sprintfex: ptr; // Buka localization

//----- Functions

procedure QuickLoad;
begin
  _Paused^:= 1;
  pint($69CDA8)^:= 1;
  _StopSounds;
  _SaveSlotsFiles^[0]:= 'quiksave.mm7';
  _DoLoadGame(0, 0, 0);
  pint($6A0BC8)^:= 3;
end;

//----- Fix keys configuration loading

const
  DefaultKeys: array[0..29] of int = (38, 40, 37, 39, 89, 88, 13, 83, 65, 32, 67, 66, 9, 81, 90, 82, 84, 78, 77, 85, 34, 46, 35, 107, 109, 33, 45, 36, 219, 221);
  _KeysPtr = ptr($69AC8C);
var
  KeyConfigDone: Boolean;
  StoredKeys: array[0..29] of int;

procedure FixKeyConfigProc;
begin
  CopyMemory(@StoredKeys, _KeysPtr, SizeOf(StoredKeys));
  CopyMemory(_KeysPtr, @DefaultKeys, SizeOf(DefaultKeys));
end;

procedure FixKeyConfigHook;
asm
  call FixKeyConfigProc
  pop edi
  pop esi
  pop ebx
  leave
end;

procedure DoKeyConfig;
const
  UpdateShortCut: procedure(a1, new, old: int; first: BOOL) = ptr($41B48A);
var
  first: BOOL;
  i: int;
begin
  CopyMemory(_KeysPtr, @StoredKeys, SizeOf(StoredKeys));
  first:= true;
  for i := 0 to high(DefaultKeys) do
    if (StoredKeys[i] <> DefaultKeys[i]) then
    begin
      UpdateShortCut(0, StoredKeys[i], DefaultKeys[i], first);
      first:= false;
    end;
end;

//----- Called every tick. Quick Save, keys related things

var
  LastMusicStatus, MusicLoopsLeft: int;

procedure KeysProc;
var
  nopause: Boolean;
  status, loops: int;
begin
  // Fix keys configuration loading
  if not KeyConfigDone then
    DoKeyConfig;
  KeyConfigDone:= true;

  // Fix TurnBasedPhase staying at 3 while TurnBased is off
  if not _TurnBased^ then
    _TurnBasedPhase^:= 0;

  // MusicLoopsCount
  if MusicLoopsLeft <> 0 then
  begin
    status:= RedbookStatus;
    if (status = 3) and (LastMusicStatus in [1, 2]) then
    begin
      loops:= MusicLoopsLeft;
      _LoadMapTrack;
      if loops > 0 then
        MusicLoopsLeft:= loops - 1;
    end;
    LastMusicStatus:= status;
  end;

  nopause:= (_Paused^=0) and (_CurrentScreen^ = 0);

  // QuickSave
  if (QuickSavesCount >= 0) and CheckKey(QuickSaveKey) and nopause then
  begin
    QuickSaveUndone:= true;
    _DoSaveGame(0, 0, 2);
    if QuickSaveUndone then
      PlaySound(27);
  end;

  // QuickLoad
  if (QuickSavesCount >= 0) and CheckKey(Options.QuickLoadKey) and nopause
     and FileExists('saves\quiksave.mm7') then
    QuickLoad;

  // InventoryKey
  if CheckKey(Options.InventoryKey) and nopause then
  begin
    if _CurrentMember^ = 0 then
      _CurrentMember^:= 1;
    _CurrentCharScreen^:= 103;
    _OpenInventory_result^:= _OpenInventory_part;
    _NeedRedraw^:= 1;
  end;

  // CharScreenKey
  if CheckKey(Options.CharScreenKey) then
    case _CurrentScreen^ of
      0:
        if _Paused^=0 then
        begin
          if _CurrentMember^ = 0 then
            _CurrentMember^:= 1;
          _OpenInventory_result^:= _OpenInventory_part;
          _NeedRedraw^:= 1;
        end;
      7:
        ExitScreen;
    end;

  // Shared keys proc
  CommonKeysProc;
end;

procedure KeysHook;
asm
  call KeysProc
  jmp GetAsyncKeyState
end;

//----- Buggy autosave file name localization

var
  SaveNamesStd: procedure;

procedure SaveNamesHook;
begin
  SaveNamesStd;
  _AutosaveFile^:= 'autosave.mm7';
end;

//----- Fix Save/Load Slots

var
  SaveName: string;
  SaveSpecial: string = 'quiksave.mm7';
  FillSaveSlotsStd: ptr;

procedure FillSaveSlotsBefore;
var
  name: PChar;
begin
  name:= @_SaveSlotsFiles^[_SaveSlot^];
  if (name^ = #0) or (_SaveSlotsCount^ = 0) then  exit;

  if CompareMem(name, PChar('save'), 4) then
    SaveName:= name
  else
    if SaveSpecial = '' then
      SaveSpecial:= name;
end;

procedure FillSaveSlotsAfter(save: bool);
var
  slot, count: int;
  name: string;
begin
  name:= SaveName;
  if not save and (SaveSpecial <> '') then
    name:= SaveSpecial;

  if save then
    count:= (_SaveSlotsFilesLim^ - ptr(_SaveSlotsFiles^)) div SizeOf(TSaveSlotFile)
  else
    count:= _SaveSlotsCount^;

  if name <> '' then
  begin
    slot:= max(count - 1, 0);
    while (slot > 0) and (AnsiStrComp(_SaveSlotsFiles^[slot], ptr(name)) <> 0) do
      dec(slot);
  end else
    slot:= 0;

  _SaveSlot^:= slot;
  if (slot < _SaveScroll^) or (slot >= _SaveScroll^ + 7) then
    _SaveScroll^:= slot - 3;
  _SaveScroll^:= max(0, min(_SaveScroll^, count - 7));
  if not save then
    SaveSpecial:= '';
end;

procedure FillSaveSlotsHook;
asm
  push ecx
  call FillSaveSlotsBefore
  mov ecx, [esp]
  call FillSaveSlotsStd
  pop eax
  call FillSaveSlotsAfter
end;

procedure ChooseSaveSlotProc;
begin
  SaveSpecial:= '';
end;

var
  ChooseSaveSlotBackup: ptr;

procedure ChooseSaveSlotHook;
asm
  call ChooseSaveSlotProc
  jmp ChooseSaveSlotBackup
end;

var
  SaveBackup: ptr;

procedure SaveHook;
asm
  call ChooseSaveSlotProc
  jmp SaveBackup
end;

//----- Quicksave trigger

procedure QuicksaveProc;
var
  i: int;
  s1, s2: string;
begin
  ShowStatusText(_TextGameSaved^);
  QuickSaveUndone:= false;
  SaveSpecial:= 'quiksave.mm7';
  if QuickSavesCount <= 1 then
    exit;
  s1:= Format('saves\quiksave%d.mm7', [QuickSavesCount]);
  DeleteFile(s1);
  for i := QuickSavesCount - 1 downto 2 do
  begin
    s2:= s1;
    s1:= Format('saves\quiksave%d.mm7', [i]);
    MoveFile(ptr(s1), ptr(s2));
    DeleteFile(s1);
  end;
  MoveFile('saves\quiksave.mm7', ptr(s1));
end;

procedure QuicksaveHook;
const
  QuiksaveStr: PChar = 'saves\quiksave.mm7';
asm
  cmp [ebp - $24], 2
  jnz @norm

  push eax
  call QuicksaveProc
  pop eax

  pop ecx
  push QuiksaveStr
  jmp ecx
  
@norm:
  pop ecx
  push $4E95B4
  jmp ecx
end;

//----- Show multiple Quick Saves

procedure QuickSaveSlotProc;
var
  i: int;
  name, s: string;
begin
  s:= '';
  for i := 1 to QuickSavesCount do
  begin
    if i <> 1 then
      s:= IntToStr(i);
    name:= Format('quiksave%s.mm7', [s]);
    MoveFile(ptr(Format('quick%s.mm7', [s])), ptr(name));
    if _access(ptr(name)) <> -1 then
    begin
      StrCopy(_SaveSlotsFiles^[_SaveSlotsCount^], ptr(name));
      inc(_SaveSlotsCount^);
    end;
  end;
end;

procedure QuickSaveSlotHook;
asm
  mov esi, $5C5C30
  cmp [esp + $14], 0
  jnz @exit
  call QuickSaveSlotProc
@exit:
end;

var
  QuickSaveNamesTmp: string;

function QuickSaveNamesProc(fileName: PChar): bool;
var
  name: string;
begin
  Result:= CompareMem(fileName, PChar('quiksave'), 8);
  if Result then
  begin
    name:= fileName;
    name:= Copy(name, 9, length(name) - 12);
    if name <> '' then
      name:= QuickSaveDigitSpace + name;
    QuickSaveNamesTmp:= #2 + name;
  end else
    if CompareMem(fileName, PChar('autosave'), 8) then
    begin
      Result:= true;
      QuickSaveNamesTmp:= #1;
    end;
end;

procedure QuickSaveNamesHook;
const
  AutosaveFile = int(_AutosaveFile);
asm
  mov eax, [esp + $1C]
  call QuickSaveNamesProc
  test eax, eax
  pop eax
  jnz @quik

  push dword ptr [AutosaveFile]
  jmp eax

@quik:
  push QuickSaveNamesTmp
  push $45E676
end;

function QuickSaveDrawProc(name: PChar): PChar;
begin
  case name^ of
    #1:
      Result:= _AutosaveName^;
    #2:
    begin
      QuickSaveNamesTmp:= QuickSaveName + (name + 1);
      Result:= ptr(QuickSaveNamesTmp);
    end;
    else
      Result:= name;
  end;
end;

procedure QuickSaveDrawHook;
asm
  push ecx
  push eax
  mov eax, edi
  call QuickSaveDrawProc
  mov [esp + 12], eax
  pop eax
  pop ecx
  mov edx, [$5C3488]
end;

procedure QuickSaveDrawHook2;
asm
  push ecx
  add eax, [__PSaveSlotsHeaders]
  call QuickSaveDrawProc
  mov edx, eax
  pop ecx
end;

//----- Autosave didn't pause time

var
  SaveSetPauseStd: function(a1, a2, a3, b4, b5, b6: int): int;

function SaveSetPauseHook(a1, a2, a3, b4, b5, b6: int): int;
var
  old: int;
begin
  old:= _Paused^;
  _Paused^:= 1;
  Result:= SaveSetPauseStd(a1, a2, a3, b4, b5, b6);
  _Paused^:= old;
end;

//----- CapsLockToggleRun

procedure CapsLockHook;
asm
  xor eax, eax
  ret 4
end;

//----- Multiple fauntain drinks bug

function InactiveMemberEventsProc: int;
type
  TMembersArray = array[0..4] of ptr;
  PMembersArray = ^TMembersArray;
const
  Members = PMembersArray(_PartyMembers);
var
  a: array[0..3] of byte;
  i, n: int;
begin
  n:= 0;
  for i := 1 to 4 do
    if _Character_IsAlive(nil, nil, Members^[i]) then
    begin
      a[n]:= i;
      inc(n);
    end;
  if n > 0 then
    Result:= a[Random(n)]
  else
    Result:= 1;
end;

procedure InactiveMemberEventsHook;
const
  CurMember = int(_CurrentMember);
asm
  mov eax, [CurMember]
  test eax, eax
  pop eax
  jnz @normal
// temporary set CurrentMember to random value, but fixed during the whole event
  pushad
  call InactiveMemberEventsProc
  mov [CurMember], eax
  popad
  push [esp + 4]
  push offset @after
@normal:
  sub esp, 498h
  inc eax
  jmp eax
@after:
  xor eax, eax
  mov [CurMember], eax
  ret 4
end;

//----- Switch between inactive members in inventory screen

procedure CheckNextMemberHook;
const
  CurScreen = int(_CurrentScreen);
asm
  cmp [CurScreen], 7
  jz @ok
  cmp word ptr [esi + _CharOff_Recover], 0
@ok:
end;

//----- Show recovery time in Attack/Shoot description

function AttackDescriptionProc(str: PChar; shoot: LongBool):PChar;
const
  MinDelay = pint1($42EFC9);
var
  member: PChar;
  i: int;
  blaster: Boolean;
begin
  blaster:= false;
  Result:= str;
  member:= GetCurrentPlayer;
  if member = nil then
    exit;
  i:= pint(member + _CharOff_ItemMainHand)^;
  if (i > 0) then
  begin
    i:= int(member + _CharOff_Items + i*_ItemOff_Size);
    blaster:= (pint(i + $14)^ and 2 = 0) and (pbyte(_ItemsTxt^ + $30*pint(i)^ + $1D)^ = 7);
  end;
  i:= _Character_GetWeaponDelay(0, 0, member, shoot and not blaster);
  if (i < MinDelay^) and not (shoot or blaster) then
    i:= MinDelay^;
  StrLCopy(_TextBuffer2, str, 499);
  Result:= StrLCat(_TextBuffer2, ptr(Format(RecoveryTimeInfo, [i])), 499);
end;

procedure AttackDescriptionHook;
asm
  xor edx, edx
  mov eax, ebx
  call AttackDescriptionProc
  mov ebx, eax
  push $418437
end;

procedure ShootDescriptionHook;
asm
  xor edx, edx
  inc edx
  mov eax, ebx
  call AttackDescriptionProc
  mov ebx, eax
  push $418437
end;

//----- Load files from DataFiles folder

function LodFilesProc(name: PChar; UseMalloc: Boolean): ptr;
var
  f: HFILE;
  n: DWORD;
begin
  Result:= nil;
  f:= FileOpen('DataFiles\' + name, fmOpenRead);
  if f = INVALID_HANDLE_VALUE then  exit;

  try
    n:= GetFileSize(f, nil);
    if UseMalloc then
      Result:= _malloc(n)
    else
      Result:= _Alloc(0, 0, _Allocator, name, n, 0);
    FileRead(f, Result^, n);
    Options.LastLoadedFileSize:= n;
  finally
    FileClose(f);
  end
end;

procedure LodFilesHook;
const
  lod = $6BE8D8; // events.lod
asm
  cmp ecx, lod
  jnz @std
  mov eax, [esp + 8]
  mov edx, [esp + 12]
  push ecx
  call LodFilesProc
  pop ecx
  test eax, eax
  jz @std
  pop ecx
  ret 8

@std:
  pop eax
  push ebp
  mov ebp, esp
  sub esp, $4C
  jmp eax
end;

procedure LodFileStoreSize;
asm
  mov eax, [ebp - $38]
  mov Options.LastLoadedFileSize, eax
  pop ecx
  // std
  pop edi
  mov eax, ebx
  pop esi
  pop ebx
  jmp ecx
end;

procedure LodFileEvtOrStr;
asm
  mov esi, Options.LastLoadedFileSize
  push $443D76
end;

//----- Dagger tripple damage from 2nd hand check

procedure SecondHandDaggerHook;
asm
  xor eax, eax
  cmp word ptr [edi + $10C], 128
  jb @exit
  inc eax
@exit:
end;

//----- Include items bonus to skill in recovery time

procedure WeaponRecoveryBonusHook;
asm
  cmp ecx, 64
end;

//----- Don't allow using scrolls by not active member

var
  ScrollTestMemberStd: ptr;

function FindActiveMember: int;
begin
  Result:= _FindActiveMember;
end;

procedure ScrollTestMember;
const
  TurnBased = int(_TurnBased);
asm
  push ecx
  mov eax, ScrollTestMemberStd
  call eax
  pop ecx
  test eax, eax
  jz @exit
  cmp word ptr [ecx + _CharOff_Recover], 0 // recovering
  jnz @beep
  cmp dword ptr [TurnBased], 0
  jz @exit
  push ecx
  call FindActiveMember
  pop ecx
  imul eax, $1B3C
  add eax, $ACBCC8
  cmp ecx, eax
  jz @exit
@beep:
  pop eax
  mov ecx, PlayerNotActive
  mov edx, 2
  push $46861D
@exit:
end;

//----- Show numerical reputation value

var
  ReputationHookStd: ptr;

procedure ReputationHook;
asm
  push ecx
  call ReputationHookStd
  pop ecx
  xchg eax, [esp]
  push eax
  mov eax, ecx
  neg eax
end;

//----- DoubleSpeed

var
  DoubleSpeedStd: ptr;

procedure DoubleSpeedHook;
const
  TurnBased = int(_TurnBased);
  TurnBasedPhase = int(_TurnBasedPhase);
  CurrentMember = int(_CurrentMember);
asm
  mov eax, [esi + $1C]
  cmp TurnBasedSpeed, 1
  jng @rt
  cmp dword ptr [TurnBased], 1
  jnz @rt
  cmp dword ptr [TurnBasedPhase], 2
  jl @monsters
  jg @rt
  cmp dword ptr [_TurnBasedObjectsInAir], 0
  jnz @party
  cmp dword ptr [CurrentMember], 0
  jnz @rt
@party:
  imul eax, TurnBasedPartySpeed
  jmp @norm
@monsters:
  imul eax, TurnBasedSpeed
  jmp @norm
@rt:
  cmp DoubleSpeed, 0
  jz @norm
  shl eax, 1
@norm:
  mov [esi + $1C], eax
  call DoubleSpeedStd
end;

//----- TurnSpeed

var
  TurnSpeedStd: ptr;

procedure TurnSpeedHook;
asm
  cmp DoubleSpeed, 0
  jz @norm
  fmul TurnSpeedDouble
  jmp TurnSpeedStd
@norm:
  fmul TurnSpeedNormal
  jmp TurnSpeedStd
end;

//----- fix 'of Feather Falling' items

var
  FeatherFallStd: ptr;

procedure FeatherFallHook;
asm
  push 72
  call _Character_WearsItemWithEnchantSpec
  test eax, eax
  jnz @feather

  push 8
  push 529
  mov ecx, [esi]
  call _Character_WearsItem
  test eax, eax
  jnz @feather

  mov ecx, [esi]
  jmp FeatherFallStd

@feather:
  push $474FF3
  ret 8
end;

//----- ProgressiveDaggerTrippleDamage

procedure DaggerTrippleHook;
asm
  idiv ecx
  push edx
  mov ecx, edi
  push 2
  call _Character_GetSkillWithBonuses
  and eax, $3F
  pop edx
  cmp edx, eax
end;

//----- Haste on party with dead weak members

function HasteWeakCheck(p: int):LongBool;
begin
  Result:= (pint8(p + 8)^ <> 0) and (pint8(p + 8*14)^ = 0) and (pint8(p + 8*16)^ = 0);
end;

procedure HasteWeakHook1;
asm
  push eax
  push edx
  sub eax, 8
  call HasteWeakCheck
  test eax, eax
  pop edx
  pop eax
end;

procedure HasteWeakHook2;
asm
  lea eax, [edi - 8]
  call HasteWeakCheck
  test eax, eax
end;

//----- Report errors
// Delphi exception handling with DebugHook doesn't work here for some reason,
//  so I have to emulate exceptions.

procedure AppendDebugLog(const s:string);
const
  Sep = '================================================================================'#13#10#13#10;
begin
  RSAppendTextFile(AppPath + 'ErrorLog.txt', s + Sep);
end;

type
  TDelphiExceptionArgs = packed record
    RetAddr: ptr;
    ExceptObj: ptr;
    Ebx: int;
    Esi: int;
    Edi: int;
    Ebp: int;
    Esp: int;
  end;
  
  TNonDelphiExceptionArgs = packed record
    Context: PContext;
    ExceptObj: ptr;
  end;

  TNotifyTerminateArgs = packed record
    RetAddr: ptr;
  end;

const
  cDelphiException    = $0EEDFADE;
  cNonDelphiException = $0EEDFAE4;
  cDelphiTerminate    = $0EEDFAE2;

var
  MyRaiseExceptionProc: procedure(Code, Flags, ArgCount: int; Args: ptr); stdcall;
  LastUnhandledExceptionFilter: function(var p: TExceptionPointers): int; stdcall;

const
  EXCEPTION_EXECUTE_HANDLER = 1;
  EXCEPTION_CONTINUE_SEARCH = 0;
  EXCEPTION_CONTINUE_EXECUTION = -1;


function UnhandledException(var p: TExceptionPointers): int; stdcall;
type
  TExceptObjProc = function(p: Windows.PExceptionRecord): Exception;
var
  args: TNonDelphiExceptionArgs;
  args2: TNotifyTerminateArgs absolute args;
begin
  args.Context:= p.ContextRecord;
  args.ExceptObj:= TExceptObjProc(ExceptObjProc)(p.ExceptionRecord);
  MyRaiseExceptionProc(cNonDelphiException, 0, 2, @args);
  AppendDebugLog(RSLogExceptions);
  args2.RetAddr:= nil;
  MyRaiseExceptionProc(cDelphiTerminate, 0, 1, @args2);
  Exception(args.ExceptObj).Free;
  if @LastUnhandledExceptionFilter <> nil then
    Result:= LastUnhandledExceptionFilter(p)
  else
    Result:= EXCEPTION_CONTINUE_SEARCH;
end;


procedure ErrorProc(RetAddr: int; Reason: PChar; Ebx, Esi, Edi, Ebp, Esp, Ecx, Edx, Eax: int); stdcall;
var
  c: TContext;
  args: TNonDelphiExceptionArgs;
  args2: TNotifyTerminateArgs absolute args;
begin
  c.Ebx:= Ebx;
  c.Esi:= Esi;
  c.Edi:= Edi;
  c.Ebp:= Ebp;
  c.Esp:= Esp;
  c.Eax:= Eax;
  c.Ecx:= Ecx;
  c.Edx:= Edx;
  c.Eip:= RetAddr - 5;
  args.Context:= @c;
  if Reason = nil then
    args.ExceptObj:= Exception.Create('(internal error)')
  else
    args.ExceptObj:= Exception.Create(Reason);

  MyRaiseExceptionProc(cNonDelphiException, 0, 2, @args);
  AppendDebugLog(RSLogExceptions);
  args2.RetAddr:= ptr(RetAddr);
  MyRaiseExceptionProc(cDelphiTerminate, 0, 1, @args2);
  Exception(args.ExceptObj).Free;
end;

procedure ErrorHook1;
asm
  push eax
  lea eax, [esp + $C]
  push edx
  push ecx
  lea ecx, [eax + 4]
  push ecx             // esp
  push ebp
  push edi
  push esi
  push ebx
  push 0               // Reason
  push dword ptr [eax] // RetAddr
  call ErrorProc
  
  jmp [$4D8280]
end;

procedure ErrorHook2;
const
  TextBuffer = int(_TextBuffer1);
asm
  push eax
  lea eax, [esp + $18]
  push edx
  push ecx
  lea ecx, [eax + 4]
  push ecx             // esp
  push ebp
  push edi
  push esi
  push ebx
  push TextBuffer      // Reason
  push dword ptr [eax] // RetAddr
  call ErrorProc

  mov ecx, [$720808]
end;

procedure ErrorHook3;
asm
  push eax
  mov eax, ebp
  push edx
  mov edx, [esp + $10]
  push ecx
  lea ecx, [eax + 8]
  push ecx                   // esp
  push dword ptr [eax]       // ebp
  push dword ptr [eax - $2C] // edi
  push dword ptr [eax - $28] // esi
  push dword ptr [eax - $24] // ebx
  push edx                   // Reason
  push dword ptr [eax + 4]   // RetAddr
  call ErrorProc

  jmp [$4D826C]
end;

//----- MusicLoopsCount (main part is in KeysProc)

procedure ChangeTrackHook;
asm
  mov eax, Options.MusicLoopsCount
  dec eax
  mov MusicLoopsLeft, eax
  mov LastMusicStatus, 0

  // std
  test byte ptr [$6BE1E4], $10
end;

//----- Fix chests: place items that were left over

procedure FixChest(p, chest: int);
var
  ItemsToPlace: array[0..139] of int;
  i, j, h: int;
begin
  h:= pint(_ChestWidth + 4*pword(p)^)^*pint(_ChestHeight + 4*pword(p)^)^ - 1;
  inc(p, 4);
  for i := 0 to 139 do
    ItemsToPlace[i]:= pint(p + _ItemOff_Size*i)^;
  inc(p, _ItemOff_Size*140);
  for i := 0 to h do
    if pint2(p + i*2)^ > 0 then
      ItemsToPlace[pint2(p + i*2)^ - 1]:= 0;
  for i := 0 to 139 do
    if ItemsToPlace[i] <> 0 then
      for j := 0 to h do
        if (pint2(p + j*2)^ = 0) and _Chest_CanPlaceItem(0, ItemsToPlace[i], j, chest) then
        begin
          _Chest_PlaceItem(0, i, j, chest);
          break;
        end;
end;

procedure FixChestHook;
asm
  test byte ptr [edi], 2
  jz @exit
  lea eax, [edi - 2]
  mov edx, ecx
  call FixChest
  mov [esp], $42041C
@exit:
end;

//----- Limit blaster & bow speed with BlasterRecovery

procedure FixBlasterSpeed;
asm
  mov eax, ecx
  cmp eax, Options.BlasterRecovery
  jnl @exit
  mov eax, Options.BlasterRecovery
@exit:
end;

//----- Ignore DDraw errors

procedure DDrawErrorHook;
asm
  mov eax, esi
  pop esi
  pop ebp
  ret $10
end;

//----- Credits move too fast

procedure FixCreditsPause;
asm
  push 12
  call dword ptr [$4D80B8] // Sleep
end;

//----- Fix party generation screen clouds & arrows speed

var
  DrawPartyScreenStd: procedure;
  LastPartyScreenDraw: uint;

procedure DrawPartyScreenHook;
var
  k: uint;
  o1, o2: int;
begin
  k:= timeGetTime;
  o1:= pint($A74B4C)^; o2:= pint($A74B54)^;
  DrawPartyScreenStd;
  if (k - LastPartyScreenDraw) < 15 then
  begin
    pint($A74B4C)^:= o1; pint($A74B54)^:= o2;
  end else
    LastPartyScreenDraw:= k;
end;

//----- No HWL for sprites

procedure LoadSpriteD3DHook2;
asm
  inc dword ptr [esi+0EC9Ch]
  push $4ACA1E
  push $4A4FD8
  ret
end;

var
  HaveIt: Boolean; // found sprite by name, but palette doesn't match

procedure LoadSpriteD3DHook3;
asm
  mov eax, [esi+0EC9Ch]
  cmp HaveIt, 0
  jz @load
  mov HaveIt, 0
  pop ecx
  push $4AC996
@load:
end;

procedure LoadSpriteD3DHook4;
asm
  mov eax, [esi + 0ECB0h]
  mov ecx, [ebp - $10]  // sprite offset
  mov eax, dword ptr [eax + ecx + 4]  // sprite pal
  cmp eax, [ebp + $C]  // check pal
  jz @found
  cmp [esi + $EC9C], SpritesMax  // check for sprites overflow
  jz @found
  mov HaveIt, 1
  push $4AC76E
  ret
@found:
  mov HaveIt, 0
  push $4AC851
end;

//----- Extend Sprites Limits

procedure ExtendSpriteLimits;
const
  PatchPtr: array[0..25] of int = ($41E4BE, $41E9B9, $4403EB, $440DFB, $441BB9, $441BD1, $47AE29, $47B044, $47BC4B, $4A8FAC, $450CFB, $450D30, $46244A, $46250A, $462541, $462569, $4AC827, $4AC8DD, $4AC90F, $4AC94A, $4D7B50, $4AC8AC, $4AC8C1, $4AC8F7, $4AC96F, $4AC986);
  PatchCount: array[0..4] of int = ($462563, $462444, $4D7B46, $4AC7AD, $4AC782);
var
  Hook: TRSHookInfo;
  i: int;
begin
  ZeroMemory(@Hook, SizeOf(Hook));
  Hook.t:= RSht4;
  Hook.add:= int(@Sprites) - _SpritesOld;
  for i := 0 to high(PatchPtr) do
  begin
    Hook.p:= PatchPtr[i];
    RSApplyHook(Hook);
  end;
  Hook.add:= 0;
  for i := 0 to high(PatchCount) do
  begin
    Hook.p:= PatchCount[i];
    Hook.new:= (pint(Hook.p)^ div 1500) * SpritesMax;
    RSApplyHook(Hook);
  end;
end;

//----- Use Delphi memory manager

function MemoryNewProc(n: uint): ptr;
begin
  Result:= AllocMem(n + 256); // +256 is to have some protection from out-of-bounds
  //ZeroMemory(PChar(Result) + n, 256);
  ZeroMemory(PChar(Result), n + 256);
end;

procedure MemoryFreeProc(p: ptr);
begin
  FreeMem(p);
end;
{
 // shows out-of-bounds problems
function MemoryNewProc(n: uint): ptr;
var
  i: uint;
begin
  inc(n);  // trailing zero for text files
  i:= (n + $FFF) and not $FFF;
  Result:= VirtualAlloc(nil, i + $1000, MEM_RESERVE, PAGE_NOACCESS);
  VirtualAlloc(Result, i, MEM_COMMIT, PAGE_EXECUTE_READWRITE);
  inc(PChar(Result), i - n);
  ZeroMemory(PChar(Result), n);
end;

procedure MemoryFreeProc(p: ptr; ret: int);
begin
  //RSAppendTextFile('c:\palog.txt', IntToHex(int(p), 6) + #9 + IntToHex(ret, 6) + #13#10);
  //VirtualProtect(p, $1000, PAGE_NOACCESS, @p);
  VirtualFree(ptr(uint(p) and not $FFF), 0, MEM_RELEASE);
end;
{}

procedure MemoryInitHook;
asm
  mov [esi + $1D4D0], $10000000  // in Arena there's a check for available heap size
end;

procedure MemoryFreeHook;
asm
  mov eax, ebp
  call MemoryFreeProc
  push $4264EC
end;

procedure MemoryNewHook;
asm
  cmp eax, edi
  jge @ok
  xor eax, eax
  jmp @exit
@ok:
  call MemoryNewProc
@exit:
  push $426835
end;

//----- Fix global.txt parsing out-of-bounds

procedure GlobalTxtHook;
asm
  mov eax, [esp + $1C]
  cmp eax, [$452D45]
  jnl @exit
  push $4CC17B
@exit:
end;

//----- Fix spells.txt parsing out-of-bounds

procedure SpellsTxtHook;
asm
  mov eax, [esp + $1C]
  add eax, $14
  cmp eax, [$453B28]
  jg @exit
  push $4CC17B
@exit:
end;

//----- Fix facet interception checking out-of-bounds

procedure FacetCheckHook;
asm
  cmp eax, 38
  jl @norm
  sub eax, 40
@norm:
  movzx esi, word ptr [eax+esi+2]
end;

procedure FacetCheckHook2;
asm
  cmp ecx, 38
  jl @norm
  sub ecx, 40
@norm:
  movzx esi, word ptr [ecx+esi+2]
end;

procedure FacetCheckHook3;
asm
  cmp edx, 19*4
  jl @norm
  movzx edi, word ptr [eax-76h-40]
  jmp @std
@norm:
  movzx edi, word ptr [eax-76h]
@std:
  lea edi, [edi+edi*2]
end;

//----- There may be facets without vertexes

procedure NoVertexFacetHook;
asm
  mov al, [edi + $5d]
  test al, al
  jnz @norm
  pop eax
  push $49AE52
  ret
@norm:
  mov al, [edi + $5C]
  cmp al, 3
end;

procedure NoVertexFacetHook2;
asm
  mov al, [esi + $5d]
  test al, al
  jnz @norm
  mov eax, 1
  mov [esp], $436478
@norm:
end;

//----- Get rid of palettes limit in D3D

procedure PalettesHook;
asm
  cmp esi, $32
  jl @next
  cmp dword ptr [$DF1A68], 0  // _IsD3D (stupid compiler)
  jz @sw
  dec esi
  mov [esp], $48A5C5
@sw:
  ret
@next:
  mov [esp], $48A5B0
end;

//----- D3D better space reaction

const
  CVis_get_object_zbuf_val: function(n1, n2, this, obj: int): Word = ptr($4C1B1C);
var
  PressSpaceStd: function(n1, index, ref: int): Byte;

function PressSpaceHook: Byte;
var
  i, j, p: int;
begin
  p:= pint(pint($71FE94)^ + 3660)^;
  Result:= 1;
  for i := 0 to pint(p + 8200)^ - 1 do
  begin
    j:= CVis_get_object_zbuf_val(0, 0, p, pint(p + 6152 + i*4)^);
    Result:= PressSpaceStd(0, j shr 3, j);
    if Result = 0 then
      exit;
  end;
end;

//----- Correct door state switching: param = 3

procedure DoorStateSwitchHook;
asm
  shl ecx, 4
  add ecx, eax
  cmp ebx, 3
  jnz @exit
  mov ax, [ecx + $4C]
  xor ebx, ebx
  dec ax
  jz @exit
  dec ax
  jz @exit
  inc ebx
@exit:
end;

//----- A beam of Prismatic Light in the center of screen that doesn't disappear

var
  FixPrismaticBugStd: function(size, unk: uint):ptr cdecl;

function FixPrismaticBug(size, unk: uint):ptr; cdecl;
begin
  Result:= FixPrismaticBugStd(size, unk);
  ZeroMemory(Result, size);
end;

//----- Fly in Z axis with mouse

procedure MouseLookFlyProc(var v: TPoint; ebp: PChar);
const
  MaxH = pint($473C64);
  PartyH = pint($ACCE3C);
  PartyZ = pint($ACD4F4);
  DriftZ = pint($ACD528);
  PartyState = pint($AD45B0);
  z = -$20;
  z2 = -$48;
  HasCeil = -$74;
  CeilH = -$58;
var
  x, y, a, b: ext;
  dz: int;
begin
  if (v.X = 0) and (v.Y = 0) then  exit;
  with Options do
    if (_Flying^ = 0) or not MouseLook or not MouseFly then
      exit;

  a:= _Party_Direction^*pi/1024;
  x:= cos(a);
  y:= sin(a);
  a:= x*v.X + y*v.Y;
  b:= _Party_Angle^*pi/1024;
  dz:= Round(a*sin(b)*_TimeDelta^/128);
  if (dz > 0) and (pint(ebp + z)^ + dz > MaxH^) then
    dz:= 0;
  a:= a*(cos(b) - 1);
  v.X:= v.X + Round(x*a);
  v.Y:= v.Y + Round(y*a);
  inc(pint(ebp + z)^, dz);
  inc(pint(ebp + z2)^, dz);
  if (pint(ebp + HasCeil)^ <> 0) and (pint(ebp + z)^ < pint(ebp + CeilH)^) and
     (pint(ebp + z)^ + PartyH^ >= pint(ebp + CeilH)^) then
  begin
    PartyZ^:= pint(ebp + CeilH)^ - PartyH^ - 1;
    pint(ebp + z)^:= PartyZ^;
    pint(ebp + z2)^:= PartyZ^;
    DriftZ^:= PartyZ^;
    pint($721458)^:= 0;
    _Flying^:= 0;
    PartyState^:= PartyState^ or 1;
    v.X:= 0;
    v.Y:= 0;
  end;
end;

procedure MouseLookFlyHook1;
asm
  mov ds:[$ACD4F8], eax
  push edi
  push ebx
  mov eax, esp
  mov edx, ebp
  call MouseLookFlyProc
  pop ebx
  pop edi
  mov ds:[ebp - $C], edi
end;

procedure MouseLookFlyHook2;
asm
  push ebx
  push edi
  mov eax, esp
  mov edx, ebp
  call MouseLookFlyProc
  pop edi
  pop ebx
  mov eax, [ebp - 4]
  xor ecx, ecx
end;

//----- Show resistances of monster

var
  IDMonStr: string;

function IDMonProc(n: int): PChar;
begin
  IDMonStr:= IntToStr(n);
  Result:= PChar(IDMonStr);
end;

procedure IDMonHook;
asm
  call IDMonProc
  xchg eax, [esp]
  jmp eax
end;

//----- negative/0 causes a crash in stats screen

procedure StatColorFixHook;
asm
  test esi, esi
  jnz @norm
  dec esi
@norm:
  idiv esi
  mov ecx, $FF
end;

//----- Pause the game in Town Portal screen

var
  TPFixStd: procedure;

procedure TPFixHook;
begin
  _PauseTime;
  TPFixStd;
end;

//----- Use Smooth turn rate by default

procedure DefaultSmoothTurnHook;
asm
  mov edx, 3
  mov ecx, $4E46C8
end;

//----- Waiting used to recover characters twice as fast

procedure FixWaitHook;
asm
  test dword ptr ds:[$ACD6BC], 2
  jz @skip
  sar dword ptr ds:[esp + 4], 1

@skip:
  push $48E8ED
end;

//----- Was no LeaveMap event on death

procedure FixLeaveMapDieHook;
const
  OnMapLeave: int = $443FB8;
asm
  call OnMapLeave
  push $4CAC80
end;

//----- Was no LeaveMap event with walk travel

procedure FixLeaveMapWalkHook;
const
  OnMapLeave: int = $443FB8;
asm
  call OnMapLeave
  mov ecx, $576CB0
end;

//----- Subtract gold after autosave when trevelling

var
  TravelGold: int;

procedure TravelGoldFixHook1;
asm
  mov TravelGold, ecx
  xor ecx, ecx
  push $492BAE
end;

procedure TravelGoldFixHook2;
asm
  mov eax, TravelGold
  sub ds:[$ACD56C], eax
  push $4B1DF5
end;

//----- Switch to 16 bit color when going windowed

var
  AutoColor16Std, AutoColor16Std2: ptr;

procedure AutoColor16Proc;
const
  bpp: array[boolean] of byte = (16, 32);
var
  mode: TDevMode;
begin
  if not (GetDeviceCaps(GetDC(0), BITSPIXEL) in [16, bpp[Options.SupportTrueColor]]) or
     (GetDeviceCaps(GetDC(0), PLANES) <> 1) then
    with mode do
    begin
      dmSize:= SizeOf(mode);
      dmBitsPerPel:= bpp[Options.SupportTrueColor];
      dmFields:= DM_BITSPERPEL;
      ChangeDisplaySettings(mode, CDS_FULLSCREEN);
    end;
end;

procedure AutoColor16Hook;
asm
  push AutoColor16Std
  jmp AutoColor16Proc
end;

procedure AutoColor16Hook2;
asm
  push ecx
  call AutoColor16Proc
  mov ecx, AutoColor16Std2
  xchg ecx, [esp]
end;

//----- Autorun key like in WoW

procedure AutorunProc;
type
  PQueue = ^TQueue;
  TQueue = packed record
    n: int;
    key: array[0..29] of int;
  end;
const
  Queue = PQueue($721458);
  Add: procedure(n1,n2, this, key: int) = ptr($4760C5);
var
  i: int;
begin
  Autorun:= Autorun and (_CurrentScreen^ = 0) and not _TurnBased^;
  if not Autorun or (_Paused^ <> 0) then  exit;
  for i:= 0 to Queue.n - 1 do
    if Queue.key[i] in [3..6, 16, 17] then
    begin
      Autorun:= false;
      exit;
    end;
  Add(0, 0, int(Queue), 16);
end;

procedure AutorunHook;
asm
  push $4304D6
  jmp AutorunProc
end;

//----- Lloyd: take spell points and action after autosave

procedure LloydAutosaveFix;
asm
  // get back spell points and remove recovery delay
  push esi
  mov esi, [esp + $600 - $5E8]
  mov ax, [esi + _CharOff_Recover]
  push eax
  mov word ptr [esi + _CharOff_Recover], 0
  mov eax, [esi + _CharOff_SpellPoints]
  push eax
  add eax, dword ptr [$5061C4]
  mov [esi + _CharOff_SpellPoints], eax

  call _DoSaveGame

  // restore decreased spell points and recovery delay
  pop eax
  mov [esi + _CharOff_SpellPoints], eax
  pop eax
  mov [esi + _CharOff_Recover], ax
  pop esi
end;

//----- TP: take action after autosave

procedure TPAutosaveFix;
asm
  // remove recovery delay
  push edx
  xor eax, eax
  mov al, [$50BF40]
  mov edi, _CharOff_Size
  mul eax, edi
  pop edx
  lea edi, [eax + $ACD804 + _CharOff_Recover]
  mov ax, [edi]
  push eax
  mov word ptr [edi], 0

  call _DoSaveGame

  // restore recovery delay
  pop eax
  mov [edi], ax
  mov edi, 1
end;

//----- Fix crash when looking too low (lower than game allows)

procedure FixSkyCrash;
asm
  sar edx, $10
  cmp [ebp-$C], 0
  jg @ok  // unexpected case
  mov ecx, edx
  sal ecx, 1
  cmp ecx, [ebp-$C]
  jg @ok
  mov eax, $40000000 // -1
  ret
@ok:
  idiv [ebp-$C]
end;

//----- Fix int overflow crash in editor

procedure FixDivCrash1;
const
  down = -$10;
  up = -$C;
asm
  // std code
  sar edx, 15  // 15 instead of 16, cause it's idiv, EDX must be 2 times smaller
  // (edx < C) <> (-edx < C) means overflow, equality means overflow
  cmp edx, [ebp + down]
  jg @g
  jz @bad
  // edx < C
  neg edx
  cmp edx, [ebp + down]
  jl @good
  jmp @bad
@g: // edx > C
  neg edx
  cmp edx, [ebp + down]
  jle @bad

@good:
  neg edx
  sar edx, 1
  // std code
  idiv [ebp + down]
  ret

@bad:
  // return $7FFFFFFF or -$7FFFFFFF
  mov eax, [ebp + up]
  xor eax, [ebp + down]
  shr eax, 31
  add eax, $7FFFFFFF
  or eax, 1
end;

procedure FixDivCrash2; // copy of FixDivCrash1 with different constants
const
  down = -$2C;
  up = -$C;
asm
  // std code
  sar edx, 15  // 15 instead of 16, cause it's idiv, EDX must be 2 times smaller
  // (edx < C) <> (-edx < C) means overflow, equality means overflow
  cmp edx, [ebp + down]
  jg @g
  jz @bad
  // edx < C
  neg edx
  cmp edx, [ebp + down]
  jl @good
  jmp @bad
@g: // edx > C
  neg edx
  cmp edx, [ebp + down]
  jle @bad

@good:
  neg edx
  sar edx, 1
  // std code
  idiv [ebp + down]
  ret

@bad:
  // return $7FFFFFFF or -$7FFFFFFF
  mov eax, [ebp + up]
  xor eax, [ebp + down]
  shr eax, 31
  add eax, $7FFFFFFF
  or eax, 1
end;

//----- Custom LODs - find file

type
  TCustomLod = record
    Std: ptr;
    Mine: ptr;
  end;
  TLodRecord = record
    Lod: ptr;
    PtrPassedAsName: ptr;
    Name: array[0..$3F] of char;
  end;
  TLodRecords = record
    Index: int;
    Records: array[0..255] of TLodRecord;
  end;

var
  CustomLods: array of TCustomLod;
  LodRecords: TLodRecords;

const
  FindInLodPtr2 = $461659 + 5;

procedure AddLodRecord(ALod: ptr; AName: PChar);
begin
  LodRecords.Index:= uint(LodRecords.Index - 1) and 255;
  with LodRecords, Records[Index] do
  begin
    Lod:= ALod;
    PtrPassedAsName:= AName;
    StrLCopy(@Name, AName, $39);
  end;
end;

procedure FindInLodAndSeek;
asm
  push ebp
  mov ebp, esp
  push ebx
  push esi
  jmp eax
end;

procedure FindInLod;
asm
  // remove Unsorted param from stack
  pop eax
  pop edx
  mov [esp], edx
  push eax
  // std code
  push ebx
  push esi
  push edi
  mov esi, ecx
  push FindInLodPtr2
end;

function FindInLodProc(StdPtr, _2: int; This: ptr; Unsorted: LongBool; Name: PChar): int;
var
  find: function(StdPtr, _2: int; This: ptr; Unsorted: LongBool; Name: PChar): int;
  i: int;
begin
  if StdPtr = FindInLodPtr2 then
    @find:= @FindInLod
  else
    @find:= @FindInLodAndSeek;

  for i := high(CustomLods) downto 0 do
    if CustomLods[i].Std = This then
    begin
      Result:= find(StdPtr, 0, CustomLods[i].Mine, Unsorted, Name);
      if Result <> 0 then
      begin
        AddLodRecord(CustomLods[i].Mine, Name);
        exit;
      end;
    end;
  Result:= find(StdPtr, 0, This, Unsorted, Name);
  if Result <> 0 then
    AddLodRecord(This, Name);
end;

procedure FindInLodAndSeekHook;
asm
  pop eax
  jmp FindInLodProc
end;

procedure FindInLodHook;
asm
  pop eax
  mov edx, [esp]
  push edx  // return address
  mov edx, [esp+8]
  mov [esp+4], edx  // Name
  jmp FindInLodProc
end;

//----- Custom LODs - load

const
  LodSize = $23C;
  LodChapOff = $214;
  LodLoad: function(_1, _2: int; This: ptr;
    CanWrite: int; Name: PChar): LongBool = ptr($461812);
  LodLoadChapter: function(_1, _2: int; This: ptr;
    Chapter: PChar): LongBool = ptr($4618C7);
  LodClean: procedure(_1, _2: int; This: ptr) = ptr($46146E);

function DoLoadCustomLod(Old: PChar; Name, Chap: PChar): ptr;
var
  i: int;
begin
  GetMem(Result, LodSize);
  ZeroMemory(Result, LodSize);
  if SameText(Chap, 'chapter') then
    Chap:= 'maps';
  if LodLoad(0,0, Result, 0, Name) or LodLoadChapter(0,0, Result, Chap) then
  begin
    LodClean(0,0, Result);
    FreeMem(Result, LodSize);
    Result:= nil;
  end else
  begin
    if SameText(Chap, 'maps') then
      StrCopy(Old + LodChapOff, 'chapter');

    i:= length(CustomLods);
    SetLength(CustomLods, i + 1);
    CustomLods[i].Std:= Old;
    CustomLods[i].Mine:= Result;
  end;
end;

function LoadCustomLod(Old: PChar; Name: PChar): ptr; stdcall;
begin
  if int(Old) = _BitmapsLod then
    Options.ResetPalettes:= true;
  Result:= DoLoadCustomLod(Old, Name, Old + LodChapOff);
end;

function FreeCustomLod(Lod: ptr): Boolean; stdcall;
var
  i: int;
begin
  for i := high(CustomLods) downto 0 do
    if CustomLods[i].Mine = Lod then
    begin
      if int(CustomLods[i].Std) = _BitmapsLod then
        Options.ResetPalettes:= true;
      ArrayDelete(CustomLods, i, SizeOf(CustomLods[0]));
      SetLength(CustomLods, length(CustomLods) - 1);
      LodClean(0,0, Lod);
      FreeMem(Lod, LodSize);
      Result:= true;
      exit;
    end;
  Result:= false;
end;

function GetCustomLodsList: ptr; stdcall;
begin
  Result:= ptr(CustomLods);
end;

function GetLodRecords: ptr; stdcall;
begin
  Result:= @LodRecords;
end;

procedure DoLoadCustomLods(Old: int; const Name: string; Chap: PChar);
begin
  with TRSFindFile.Create('Data\' + Name) do
    try
      while FindEachFile do
        DoLoadCustomLod(ptr(Old), PChar('Data\' + Data.cFileName), Chap);
    finally
      Free;
    end;
end;

procedure LoadCustomLods(Old: int; Name: string; Chap: PChar);
begin
  DoLoadCustomLods(Old, '*.' + Name, Chap);
  if Options.UILayout = nil then
    exit;
  Name:= ChangeFileExt(Name, '.' + Options.UILayout + '.lod');
  DoLoadCustomLods(Old, Name, Chap);
  DoLoadCustomLods(Old, '*.' + Name, Chap);
end;

procedure LoadCustomLodsD3D(Old: int; const Name: string; Chap: PChar);
var
  s: string;
begin
  s:= 'Data\' + Name + '.lwd';
  if FileExists(s) then
    DoLoadCustomLod(ptr(Old), PChar(s), Chap);
  with TRSFindFile.Create('Data\*.' + Name + '.l?d') do
    try
      while FindEachFile do
      begin
        s:= LowerCase(ExtractFileExt(Data.cFileName));
        if (s = '.lod') or (s = '.lwd') then
          DoLoadCustomLod(ptr(Old), PChar('Data\' + Data.cFileName), Chap);
      end;
    finally
      Free;
    end;
end;

var
  LoadLodsOld: TProcedure;

// OnStart, just before loading any data
procedure LoadLodsHook;
begin
  if not _IsD3D^ or not Options.SupportTrueColor then
    Options.UILayout:= '';
  LoadCustomLods(_IconsLod, 'icons.lod', 'icons');
  LoadCustomLods($6BE8D8, 'events.lod', 'icons');
  if _IsD3D^ then
    LoadCustomLodsD3D(_BitmapsLod, 'bitmaps', 'bitmaps')
  else
    LoadCustomLods(_BitmapsLod, 'bitmaps.lod', 'bitmaps');
  LoadCustomLods(_SpritesLod, 'sprites.lod', 'sprites08');
  LoadCustomLods($6A08E0, 'games.lod', 'chapter');
  LoadLodsOld;
  if _IsD3D^ then
    ApplyHooksD3D;
  ApplyMMHooksLodsLoaded;
end;

//----- Custom LODs - Vid

const
  _VidOff_N = $48;
  _VidOff_Files = $38;
  _VidOff_Handle = $78;
  VidArc1 = 'might7.vid';
  VidArc2 = 'magic7.vid';

type
  TVidRec = packed record
    Name: array[0..39] of Char;
    Offset: uint;
  end;

var
  VidList: TStringList;
  VidFiles: array of TVidRec;
  VidHandles: array of HFILE;

procedure OpenVid(h: HFILE);
var
  i, n: int;
begin
  if FileRead(h, n, 4) <> 4 then  exit;
  i:= length(VidFiles);
  SetLength(VidFiles, i + n);
  SetLength(VidHandles, i + n);
  FileRead(h, VidFiles[i], n*SizeOf(VidFiles[0]));
  RSFillDWord(@VidHandles[i], n, h);
end;

procedure OpenCustomVids(const Name: string);
begin
  with TRSFindFile.Create('Anims\*.' + Name) do
    try
      while FindNextAttributes(0, FILE_ATTRIBUTE_DIRECTORY) do // Only files
        OpenVid(CreateFile(ptr(FileName), $80000000, 1, nil, 3, $8000080, 0));
    finally
      Free;
    end;
end;

procedure OpenVidsProc(p: PChar);
var
  i: int;
begin
  pint(p + _VidOff_N)^:= 1;  // Only 1 file that I'll change to appropriate record
  pint(p + _VidOff_N + 4)^:= 0;
  OpenVid(pint(p + _VidOff_Handle + 4)^);
  OpenVid(pint(p + _VidOff_Handle)^);
  OpenCustomVids(VidArc2);
  OpenCustomVids(VidArc1);

  VidList:= TStringList.Create;
  VidList.CaseSensitive:= false;
  VidList.Duplicates:= dupIgnore;
  VidList.Sorted:= true;
  for i:= high(VidFiles) downto 0 do
    VidList.AddObject(VidFiles[i].Name, ptr(i));
end;

procedure OpenVidsHook;
asm
  mov eax, esi
  call OpenVidsProc
  // std
  lea ebp, [esi+48h]
  push $4BEA3C
end;

procedure SelectVidFile(Name, _, p: PChar);
var
  b: Boolean;
  i: int;
begin
  b:= VidList.Find(Name, i);
  pint(p + _VidOff_N)^:= BoolToInt[b];
  if b then
  begin
    i:= int(VidList.Objects[i]);
    CopyMemory(pptr(p + _VidOff_Files)^, @VidFiles[i], SizeOf(VidFiles[0]));
    pint(p + _VidOff_Handle)^:= VidHandles[i];
  end;
end;

procedure OpenBikSmkHook;
asm
  mov eax, [esp + 4*4 + 8]
  call SelectVidFile
  // std
  xor edi, edi
  cmp [esi+$48], ebp
end;

//----- Custom LODs - Snd

const
  _Snd_N = pint($F79218);
  _Snd_Files = pptr($F79210);
  _Snd_Handle = pint($F79214);

type
  TSndRec = packed record
    Name: array[0..39] of Char;
    Offset, Size, UnpSize: uint;
  end;

var
  SndList: TStringList;
  SndFiles: array of TSndRec;
  SndHandles: array of HFILE;

procedure OpenSnd(h: HFILE);
var
  i, n: int;
begin
  if FileRead(h, n, 4) <> 4 then  exit;
  i:= length(SndFiles);
  SetLength(SndFiles, i + n);
  SetLength(SndHandles, i + n);
  FileRead(h, SndFiles[i], n*SizeOf(SndFiles[0]));
  RSFillDWord(@SndHandles[i], n, h);
end;

procedure OpenSndsHook(dummy: int); stdcall;
var
  i: int;
begin
  _Snd_N^:= 1;  // Only 1 file that I'll change to appropriate record
  OpenSnd(_Snd_Handle^);
  with TRSFindFile.Create('Sounds\*.Audio.snd') do
    try
      while FindNextAttributes(0, FILE_ATTRIBUTE_DIRECTORY) do // Only files
        OpenSnd(CreateFile(ptr(FileName), $80000000, 1, nil, 3, $8000080, 0));
    finally
      Free;
    end;

  SndList:= TStringList.Create;
  SndList.CaseSensitive:= false;
  SndList.Duplicates:= dupIgnore;
  SndList.Sorted:= true;
  for i:= high(SndFiles) downto 0 do
    SndList.AddObject(SndFiles[i].Name, ptr(i));
end;

function SelectSndFile(Name: PChar): int;
var
  i: int;
begin
  if SndList.Find(Name, i) then
  begin
    i:= int(SndList.Objects[i]);
    CopyMemory(_Snd_Files^, @SndFiles[i], SizeOf(SndFiles[0]));
    _Snd_Handle^:= SndHandles[i];
    Result:= 0;
  end else
    Result:= -1;
end;

procedure OpenSndHook;
asm
  mov eax, [ebp - 4]
  call SelectSndFile
  mov [$F1B348], eax
end;

procedure OpenSndHook2;
asm
  mov eax, [esp + 8]
  call SelectSndFile
end;

//----- Strafe in MouseLook

function StrafeOrWalkHook(key: int): bool; stdcall;
begin
  Result:= MyGetAsyncKeyState(key) <> 0;
  if AlwaysStrafe or MouseLookOn then
    Result:= not Result;
end;

//----- Fix movement rounding problems

type
  TStrafeRemainder = array[0..4] of int;
var
  CurRemainder: pint;
  PlayerStrafe: TStrafeRemainder;
  MonsterStrafe: array[0..499] of TStrafeRemainder;
  ObjectStrafe: array[0..999] of TStrafeRemainder;
  OldMoveStructInit: ptr;

procedure FixStrafe1;
asm
  imul [ebp - 4]
  mov ecx, CurRemainder
  add eax, [ecx]
  adc edx, 0
  mov [ecx], ax
  add ecx, 4
  mov CurRemainder, ecx
  shrd eax, edx, $10
end;

procedure FixStrafe2;
asm
  imul dword ptr [$72142C]
  add eax, $8000
  adc edx, 0
end;

procedure FixStrafePlayer;
asm
  lea eax, PlayerStrafe
  mov CurRemainder, eax
  jmp OldMoveStructInit
end;

procedure FixStrafeMonster1;
asm
  mov eax, [ebp - 4]
  lea eax, [eax*4 + eax]
  lea eax, MonsterStrafe[eax*4]
  mov CurRemainder, eax
  jmp OldMoveStructInit
end;

procedure FixStrafeMonster2;
asm
  mov eax, [ebp - 8]
  lea eax, [eax*4 + eax]
  lea eax, MonsterStrafe[eax*4]
  mov CurRemainder, eax
  jmp OldMoveStructInit
end;

procedure FixStrafeObject1;
asm
  mov eax, [ebp - $1C]
  lea eax, [eax*4 + eax]
  lea eax, ObjectStrafe[eax*4]
  mov CurRemainder, eax
  jmp OldMoveStructInit
end;

procedure FixStrafeObject2;
asm
  mov eax, [ebp - $20]
  lea eax, [eax*4 + eax]
  lea eax, ObjectStrafe[eax*4]
  mov CurRemainder, eax
  jmp OldMoveStructInit
end;

//----- Control D3D water

function HDWTRCountHook(time: uint): int;
begin
  Result:= (time div Options.HDWTRDelay) mod Options.HDWTRCount;
end;

//----- Call ApplyDeferredHooks after MMExt loads

var
  OldStart: ptr;

procedure StartHook;
asm
  pushad
  call ApplyDeferredHooks
  popad
  jmp OldStart
end;

//----- Spear skill wasn't added to damage on expert level (only on master)

procedure FixSpear;
asm
  je @spear
  cmp eax, 3
  jmp @exit
@spear:
  cmp eax, 2
@exit:
  push $48FDFF
end;

//----- Taledon's helm does not add anything to light magic

procedure FixTaledonsHelm;
asm
  cmp esi, 2  // std code
  jz @eq2
  cmp esi, 41  // light magic
  jnz @exit
  mov al, [ebx + $12E]
  shr eax, 1
  and eax, $1F
  mov [esp + $1C + 4 - 8], eax
@exit:
  mov [esp], $48F0D3
@eq2:
end;

//----- Fix small scale sprites crash

procedure FixSmallScaleSprites;
asm
  cmp esi, 2
  jng @bad
  cmp eax, 2
  jng @bad
  mov ebx, $10000
  ret
@bad:
  mov [esp], $4AD22D
end;

//----- Telepathy preventing you from finding random items in corpses

procedure FixTelepathy;
asm
  and byte ptr [ebx+$26], $7F
  cmp word ptr [ebx+$B4], 0
end;

//----- Fix GM Staff ignoring Armsmaster bonus to Damage

procedure FixGMStaffHook;
asm
  and eax, $3F
  imul eax, esi
  push $48FE11
end;

//----- Fix items.txt: make special items accept standard "of ..." strings

function FixItemsTxtProc(text: PChar): int;
const
  str = '|of Might|of Thought|of Charm|of Vigor|of Precision|of Speed|of Luck|of Health|of Magic|of Defense|of Fire Resistance|of Air Resistance|of Water Resistance|of Earth Resistance|of Mind Resistance|of Body Resistance|of Alchemy|of Stealing|of Disarming|'+
  'of Items|of Monsters|of Arms|of Dodging|of the Fist|of Protection|of The Gods|of Carnage|of Cold|of Frost|of Ice|of Sparks|of Lightning|of Thunderbolts|of Fire|of Flame|of Infernos|of Poison|of Venom|of Acid|Vampiric|of Recovery|of Immunity|of Sanity|'+'of Freedom|of Antidotes|of Alarms|of The Medusa|of Force|of Power|of Air Magic|of Body Magic|of Dark Magic|of Earth Magic|of Fire Magic|of Light Magic|of Mind Magic|of Spirit Magic|of Water Magic|of Thievery|of Shielding|of Regeneration|of Mana|'+'Demon Slaying|Dragon Slaying|of Darkness|of Doom|of Earth|of Life|Rogues''|of The Dragon|of The Eclipse|of The Golem|of The Moon|of The Phoenix|of The Sky|of The Stars|of The Sun|of The Troll|of The Unicorn|Warriors''|Wizards''|Antique|Swift|Monks''|'+'Thieves''|of Identifying|Elf Slaying|Undead Slaying|Of David|of Plenty|Assassins''|Barbarians''|of the Storm|of the Ocean|of Water Walking|of Feather Falling|';
var
  ps: TRSParsedString;
begin
  ps:= RSParseString(str, ['|' + text + '|']);
  if RSGetTokensCount(ps) > 1 then
    Result:= RSGetTokensCount(RSParseToken(ps, 0, ['|'])) - 1
  else
    Result:= -1;
end;

procedure FixItemsTxtHook;
asm
  mov eax, ebx
  call FixItemsTxtProc
  test eax, eax
  jnl @ok
  push $457972
  ret
@ok:
  cmp eax, 24
  jge @spc
  push $4578A7
  ret
@spc:
  sub eax, 24
  push $4578EF
end;

//----- Fix timers

type
  TTimerStruct = packed record
    TriggerTime: int64;
    EventNum,
    EventLine,
    IntervalLeft,
    Interval,
    EachYear,
    EachMonth,
    EachWeek,
    Hour,
    Minute,
    Second,
    CmdType,
    _: int2;
  end;

const
  TimerPeriods: array[0..3] of uint = (123863040, 10321920, 2580480, 368640);

function GetTimerKind(var t: TTimerStruct): int;
var
  i: int;
begin
  for i:= 0 to 3 do
  begin
    Result:= i;
    if PWordArray(@t.EachYear)[i] <> 0 then
      exit;
  end;
end;

procedure TimerSetTriggerTime(time1, time2: int; var t: TTimerStruct);
var
  time: int64;
  period: uint64;
  i: int;
begin
  time:= uint64(time2) shl 32 + time1;
  i:= GetTimerKind(t);
  period:= TimerPeriods[i];
  if t.CmdType = $26 then
    t.TriggerTime:= GetMapExtra^.GetPeriodicTimer(i) + period
  else if i = 3 then  // daily timer at fixed time
  begin
    t.TriggerTime:= (t.Hour*60 + t.Minute)*256 + t.Second*256 div 60 +
       time - time mod period;
    if t.TriggerTime <= time then
      inc(t.TriggerTime, period);
  end else
    t.TriggerTime:= time + period;
end;

function UpdatePeriodicTimer(eax, _: int; var t: TTimerStruct): int;
begin
  Result:= eax;
  GetMapExtra^.LastPeriodicTimer[GetTimerKind(t)]:= _Time^;
end;

procedure FixTimerValidate;
var
  i: int;
begin
  with GetMapExtra^ do
    for i:= 0 to 3 do
      if (LastVisitTime = 0) or (LastVisitTime - GetPeriodicTimer(i, true) > TimerPeriods[i]) then
        LastPeriodicTimer[i]:= LastVisitTime;
end;

procedure FixTimerRetriggerHook1;
asm
  mov [esi-$C], ebx
  mov [esi-8], edi
  push $448C43  // add Period
end;

procedure FixTimerRetriggerHook2;
asm
  cmp [esi-$C].TTimerStruct.CmdType, $26
  jz @update
  cmp eax, $15180  // daily?
  jnz @std
// Handle timer that triggers at specific time each day
  lea ecx, [esi-$C]
  mov eax, ebx  // Game.Time
  mov edx, edi
  call TimerSetTriggerTime
  mov [esp], $448CCF
  ret
@update:
  push ecx
  push edx
  lea ecx, [esi-$C]
  call UpdatePeriodicTimer
  pop edx
  pop ecx
@std:
end;

procedure FixTimerSetupHook1;
asm
  mov eax, dword ptr [ebp-$34]
  mov edx, dword ptr [ebp-$34+4]
  mov ecx, esi
  call TimerSetTriggerTime
  push $444323
end;

procedure FixTimerSetupHook2;
asm
  mov eax, dword ptr [$ACCE64]  // Game.Time
  mov edx, dword ptr [$ACCE64+4]
  mov ecx, esi
  call TimerSetTriggerTime
  mov ebx, [ebp - $28]
  push $444323
end;

//----- Town Portal wasting player's turn even if you cancel the dialog

var
  TPDelay: int;

procedure TPDelayHook1;
asm
  mov eax, [ebp-$B4]
  mov TPDelay, eax
  push $42E874
end;

function TPDelayProc2(delay: int): ptr;
begin
  Result:= ptr(_PlayersArray + pbyte($50BF40)^*_CharOff_Size);
  _Character_SetDelay(0,0, Result, delay);
  if _TurnBased^ and not pbool($50BF44)^ then
    _TurnBased_CharacterActed;
end;

procedure TPDelayHook2;
const
  __ftol: int = $4CA74C;
  TurnBased = int(_TurnBased);
asm
  mov eax, TPDelay
  test eax, eax
  jng @skip

  // from 4282AF
  cmp dword ptr [TurnBased], ebx
  jnz @TurnBased
  fld dword ptr [$6BE224]
  fimul TPDelay
  fmul qword ptr ds:[$4D8438]
  call __ftol
  call TPDelayProc2
  jmp @skip

@TurnBased:
  movzx edx, byte ptr [$50BF40]
  mov _TurnBasedDelays[edx*4], eax
  call TPDelayProc2

@skip:
  mov TPDelay, 0
  mov eax, dword ptr [$507A4C]
end;

//----- Fix movement rounding problems - nerf jump

procedure FixMovementNerf;
asm
  mov eax, [$ACCE5C]
  shl eax, 3
  mov edx, eax
  shl eax, 3
  sub eax, edx
end;

//----- Prevent monsters from jumping into lava etc.

var
  NoMonsterJumpDownLim: int;

procedure NoMonsterJumpDown1;
asm
  mov eax, [ebp-$20]
  sub eax, Options.MonsterJumpDownLimit
  cmp byte ptr [esi+$3A], 0
  jz @NoFly
  mov eax, -30000
@NoFly:
  mov NoMonsterJumpDownLim, eax
  cmp word ptr [esi+$B2], 1
end;

procedure NoMonsterJumpDown2;
asm
  cmp eax, $FFFF8AD0
  jz @exit
  cmp eax, NoMonsterJumpDownLim
  jg @exit
  cmp eax, eax
@exit:
end;

//----- Light gray blinking in full screen

procedure FixFullScreenBlink;
asm
  jz @paint
  sub eax, 5  // ignore WM_ERASEBKGND
  jnz @DefProc
  mov [esp], $4639FE
  ret
@DefProc:
  mov [esp], $46402E
@paint:
end;

//----- Draw buffer overflow in Arcomage

function FixBlitCopyProc(var r: TRect; sy, sx: int): int;
var
  r2: TRect;
begin
  r2:= Rect(0, 0, _ScreenW^, _ScreenH^);
  dec(sx, r.Left);
  dec(sy, r.Top);
  OffsetRect(r, sx, sy);
  IntersectRect(r, r, r2);
  Result:= MakeLong(r.Left, r.Top);
  OffsetRect(r, -sx, -sy);
end;

procedure FixBlitCopy;
const
  ScreenW = int(_ScreenW);
asm
  mov ebx, [ScreenW]
  push eax
  mov eax, esi
  call FixBlitCopyProc
  movzx ecx, ax
  shr eax, 16
  mov edx, eax
  pop eax
end;

//----- Buy dialog out-of-bounds read when no active player

procedure FixBuyNoMember;
asm
  test dl, dl
  jnl @ok
  xor edx, edx
@ok:
  mov bl, dl
  mov [ebp-$10], ecx
end;

//----- Monsters summoned by other monsters had wrong monster as their ally

procedure FixMonsterSummon;
asm
  add eax, 2
  mov ecx, 3
  idiv ecx
  push $44FF52
end;

//----- Blasters and some spells couldn't target rats
// They use Party_Height/2 instead of Party_Height/3,
// but targeting didn't account for it

procedure FixDragonTargeting;
const
  std: int = $4040E9;
asm
  movsx eax, word ptr [ebx]
  cmp eax, 102 // Blaster
  jz @dragon
  cmp eax, 29  // Acid Burst
  jz @dragon
  cmp eax, 39  // Blades
  jz @dragon
  cmp eax, 76  // Flying Fist
  jz @dragon
  cmp eax, 90  // Toxic Cloud
  jz @dragon
  cmp eax, 93  // Shrapmetal
  jz @dragon
  push std
  ret
@dragon:
  mov eax, [__Party_Height]
  // push Party_Height
  push eax
  // Party_Height = Party_Height*3/2
  sar eax, 1
  lea eax, [eax + eax*2]
  mov [__Party_Height], eax
  // call <std>
  push [esp + 3*4]
  push [esp + 3*4]
  call std
  // restore Party_Height
  pop ecx
  mov [__Party_Height], ecx
  // return
  ret 8
end;

//----- Show "Leave ***" instead of "No transition text found!"

procedure NoTransitionTextHook;
asm
  push _MapName
  mov ecx, _MapStats
  call _MapStats_Find
  mov [ebp-8], eax
  imul eax, $44
  lea esi, [_MapStats + eax]
  push $444C1C
end;

//----- Make left click not only cancel right button menu, but also perform action

function RightThenLeftMouseHook: LongBool;
begin
  if _RightButtonPressed^ then
  begin
    _ReleaseMouse;
    SkipMouseLook:= not _IsD3D^;
  end;
  Result:= false;
end;

//----- Shops buying blasters

procedure CanSellItemHook;
asm
  cmp [ebp + $14], 3
  jnz @exit
  mov eax, [__ItemsTxt]
  cmp dword ptr [eax + ecx + $10], 0  // Value = 0 in items.txt
  jz @deny
  cmp Options.SkipUnsellableItemCheck, 0
  jnz @exit
  cmp dword ptr [ebx], 530  // Cloak of the Sheep
  jz @deny
  cmp dword ptr [ebx], 540  // Lady Carmine's Dagger
  jz @deny
  cmp dword ptr [ebx], 542  // The Perfect Bow (uncalibrated)
  jnz @exit
@deny:
  mov [esp], $490F2D
  ret
@exit:
  test byte ptr [ebx+$15], 1
  jnz @exit2
  mov [esp], $490FA4
@exit2:
end;

procedure CanSellItemHook2;
asm
  mov eax, [ecx]
  cmp Options.SkipUnsellableItemCheck, 0
  jnz @skip
  cmp eax, 530  // Cloak of the Sheep
  jz @deny
  cmp eax, 540  // Lady Carmine's Dagger
  jz @deny
  cmp eax, 542  // The Perfect Bow (uncalibrated)
  jz @deny
@skip:
  lea eax, [eax+eax*2]
  shl eax, 4
  add eax, [__ItemsTxt]
  cmp dword ptr [eax + $10], 0  // Value = 0 in items.txt
  jz @deny
  push $4BDA12
@deny:
  xor eax, eax
end;

//----- Crash on exit

procedure ExitCrashHook;
asm
  mov eax, [$F8BA00]
  cmp eax, [$F8BA04]
  jz @skip
  push eax
  call ebp
@skip:
end;

//----- Lava hurting players in air

var
  Party_FloorDist: int;

procedure FixLava1;
asm
  mov Party_FloorDist, eax
  cmp eax, $80
end;

procedure FixLava2;
asm
  cmp Party_FloorDist, -1
  jl @skip
  or dword ptr [_Party_State], $200
@skip:
end;

//----- Bug if the game is deactivated during end movie

procedure FixEndMovieStop;
const
  FreeMovie: int = $4BEB3A;
asm
  cmp dword ptr [$F8B9F4], 0
  jz @std
  mov ecx, $F8B988
  call FreeMovie
@std:
end;

//----- Configure window size (also see WindowProcHook)

function ScreenToClientHook(w: HWND; var p: TPoint): BOOL; stdcall;
begin
  Result:= ScreenToClient(w, p);
  if Result then
    p.y:= TransformMousePos(p.x, p.y, p.x);
end;

//----- Compatible movie render

var
  Scale640, Scale320: TRSResampleInfo;
  SmkBmp: TBitmap; SmkScanline: ptr; SmkPixelFormat: TPixelFormat;

procedure DrawMovieHook;
begin
  if not _Windowed^ then  exit;
  if SmkBmp = nil then
  begin
    SmkBmp:= TBitmap.Create;
    with SmkBmp do
    begin
      PixelFormat:= pf16bit;
      HandleType:= bmDIB;
      Width:= 640;
      Height:= -480;
      SmkScanline:= ptr(min(uint(Scanline[479]), uint(Scanline[0])));
    end;
  end;
  ZeroMemory(SmkScanline, 640*480*2);
end;

procedure SmackDrawProc1(surf: ptr; info: PDDSurfaceDesc2; param: ptr); stdcall;
begin
  info.lpSurface:= SmkScanline;
  info.lPitch:= 640*2;
end;

procedure SmackDrawHook1;
asm
  cmp dword ptr [__Windowed], 0
  jnz SmackDrawProc1
  jmp eax
end;

procedure SmackDrawProc2(_1, DoubleSize: LongBool);
begin
  if DoubleSize then
    DrawScaled(Scale320, 320, 240, SmkScanline, 640*2)
  else
    DrawScaled(Scale640, 640, 480, SmkScanline, 640*2);
end;

procedure SmackDrawHook2;
asm
  mov edx, [ebp + $10]
  cmp Options.SmoothMovieScaling, 0
  jnz @smooth
  xor edx, edx
@smooth:
  cmp dword ptr [__Windowed], 0
  jnz SmackDrawProc2
  jmp eax
end;

procedure SmackLoadHook;
asm
  cmp dword ptr [__Windowed], 0
  jz @std
  mov eax, $C0000000
  cmp Options.SmoothMovieScaling, 0
  jnz @ok
  cmp [ebp + $10], edi
  jz @ok
  or al, 6
@ok:
  mov [esp], $4BF4DB
@std:
end;

function BinkDrawProc1(_1, bink, this: PChar): LongBool;
begin
  pptr(this + 20)^:= SmkScanline;
  pint(this + 24)^:= 640*2;
  pint(this + 16)^:= 10;
  Result:= true;
end;

procedure BinkDrawHook1;
asm
  mov edx, [esi + $80]
  cmp dword ptr [__Windowed], 0
  jnz BinkDrawProc1
  jmp eax
end;

procedure BinkDrawHook2;
asm
  cmp dword ptr [__Windowed], 0
  mov edx, [ebp + $10]
  jnz @mine
  jmp eax
@mine:
  call SmackDrawProc2
  ret $10
end;

//----- Mipmaps generation code not calling surface->Release

procedure FixMipmapsMemLeak;
asm
  mov ecx, [ebp + $10]
  cmp edi, [ecx]
  jz @keep
  push eax
  mov eax, [edi]
  push edi
  call dword ptr [eax + 8]
  pop eax
@keep:
end;

//----- Fix sprites with non-zero transparent colors in monster info dialog

procedure FixSpritesInMonInfo;
asm
  test ax, ax
  jl @ok
  xor ax, ax
@ok:
end;

//----- Allow window maximization

function GetRestoredRect(hWnd: HWND; var lpRect: TRect): BOOL; stdcall;
begin
  ShowWindow(hWnd, SW_SHOWNORMAL);
  Result:= GetWindowRect(hWnd, lpRect);
end;

//----- Fix multiple steps at once in turn-based mode

var
  LastTurnBasedWalk: uint;

procedure FixTurnBasedWalking;
asm
  jle @std
  call timeGetTime
  mov edx, eax
  sub eax, LastTurnBasedWalk
  and eax, $7FFFFFFF
  cmp eax, TurnBasedWalkDelay
  jle @std
  mov LastTurnBasedWalk, edx
@std:
end;

//----- Allow loading quick save from death movie + NoDeathMovie

var
  oldDeathMovie: TProcedure;

function DeathMovieProc: Boolean;
begin
  AllowMovieQuickLoad:= true;
  if not NoDeathMovie then
    oldDeathMovie;
  Result:= not AllowMovieQuickLoad;
  AllowMovieQuickLoad:= false;
  if Result then
  begin
    if _IsMoviePlaying then
      _ExitMovie;
    QuickLoad;
  end;
end;

procedure DeathMovieHook;
asm
  call DeathMovieProc
  test al, al
  jz @std
  mov edi, $DF1A68
  mov [esp], $4637AD
@std:
end;

//----- Remember minimap zoom indoors

type
  TSelfProc = procedure(__,_: int; this: ptr);

procedure MinimapZoomHook(f: TSelfProc; _, p: PChar);
begin
  if WasIndoor then
    pint64(@Options.IndoorMinimapZoomMul)^:= pint64(p + 36)^;
  f(0, 0, p);
  WasIndoor:= (_IndoorOrOutdoor^ = 1);
  if WasIndoor then
    pint64(p + 36)^:= pint64(@Options.IndoorMinimapZoomMul)^;
end;

//----- IsWater and AnimateTFT bits didn't work together in D3D

procedure TFTWaterHook;
asm
  test ah, $40
  jz @std
  and al, $EF
@std:
end;

//----- IsWater bit was causing water texture to be used outdoors in D3D

procedure WaterBitHook;
asm
  mov edx, [ebp - $30]
  cmp edx, [$EF5114]
  jz @std
  mov [esp], $478988
@std:
end;

//----- Load cursors from Data

var
  CursorTarget: HCURSOR;

function MyLoadCursor(hInstance: HINST; name: PChar): HCURSOR; stdcall;
begin
  Result:= 0;
  if int(name) > $7FFFF then
    if name = 'Arrow' then
      Result:= ArrowCur
    else if name = 'Target' then
      Result:= CursorTarget;
  if Result = 0 then
    Result:= LoadCursor(hInstance, name);
end;

//----- Auto Transparency for icons

procedure DrawIconAuto;
const
  Green = int(_GreenMask);
  Blue = int(_BlueMask);
asm
  mov eax, [esp+$C]
  mov eax, [eax+$40]
  mov ax, [eax]
  // assume #00FFFF is transparent
  sub ax, [Green]
  sub ax, [Blue]
  mov eax, $4A5E42
  jnz @std
  mov eax, $4A6204
@std:
  push eax
end;

//----- Fly and Water Walk icon not drawn in simple message screen (+ support FlyNPCScreen)

procedure FixSimpleMessageSpells;
asm
  jz @std
  cmp eax, 19
  jz @std
  cmp eax, FlyNPCScreen
@std:
end;

//----- 'Of Spirit Magic' effect of Glory Shield wasn't working

procedure FixGloryShield;
asm
  cmp esi, 38
  jnz @std
  mov eax, $48F1EC
@std:
  jmp eax
end;

//----- Postpone intro

procedure PostponeIntroHook;
const
  movs: array[0..3] of int = (5, 3, 2, 1);
var
  i: int;
begin
  _AbortMovie^:= false;
  for i:= 3 downto 0 do
    if (i = 0) or not NoIntoLogos and not _AbortMovie^ then
      _ShowStdMovie(movs[i], i = 0);
end;

//----- No hints for non-interactive sprites

procedure NoTreeHintsHook;
asm
  cmp ShowTreeHints, 0
  jnz @std
  mov [esp+4], $F93CEC
@std:
end;

//----- Fix Lady's Escort water walking

function LadysEscortFix(_,__, pl, slot, item: int): LongBool;
begin
  Result:= _Character_WearsItem(0,0, pl, slot, item) or _Character_WearsItem(0,0, pl, 16, 536);
end;

//----- Fix space in evt.Question

procedure QuestionFixSpace;
asm
  cmp eax, $13
  jnz @skip
  mov eax, [$507A64]
  test eax, eax
  jz @ok
  cmp [eax + $1C], 26
  jz @skip
@ok:
  ret
@skip:
  mov [esp], $43043F
end;

//----- Fix Master Healer

procedure FixMasterHealer;
asm
  mov [esi-7Ch], eax
  mov [esi-80h], ebx
end;

//----- Lich becoming immune to all magic with sufficient Day of Protection

procedure FixLichImmuneHook;
asm
  mov eax, [ebp + 8]
  cmp eax, 7
  jz @ok
  cmp eax, 8
  jz @ok
  or al, $80  // not immune
@ok:
end;

//----- Make HookPopAction useable with straight Delphi funcitons

procedure PopActionAfter;
asm
end;

//----- Remember clock area to extend it with UI layout

procedure RememberClockArea;
asm
  mov ClockArea, eax
end;

//----- Fix 'Of David' not working on bows

procedure FixTitanSlaying;
asm
  cmp ebx, 65
  jnz @std
  mov [esp], 7
  push $48D296
@std:
end;

//----- Fix 'Gibbet' only doing double damage to Undead

function DoFixGibbet(_,__, mon: ptr): int;
begin
  Result:= 3;
  while (Result > 1) and not _IsMonsterOfKind(0, Result, mon) do
    dec(Result);
end;

procedure FixGibbet;
asm
  jnz @std
  push ecx
  call DoFixGibbet
  pop ecx
  mov edx, eax
  mov [esp], $48CECF
@std:
end;

//----- Wand stolen from a monster having 0 max charges

procedure FixStealWand;
asm
  mov [ebp - $24 - $10 + $19], al
end;

//----- Resting in dark taverns was taking too long

procedure FixDarkTaverns;
asm
  cmp eax, 25*60
  jle @ok
  sub eax, 24*60
@ok:
end;

//----- Training in dark training halls was taking too long

procedure FixDarkTrainers;
asm
  cmp eax, 28*60
  jle @ok
  sub eax, 24*60
@ok:
end;

//----- Kelebrim wasn't doing -30 Earth Res

procedure FixKelebrim;
asm
  jz @std
  cmp esi, 13
  jnz @std
  sub edi, 30
  mov [esp], $48F556
@std:
end;

//----- Fix Wetsuits having recovery penalty

procedure FixWetsuits;
asm
  cmp ebx, _Skill_Misc
  jnz @std
  xor ebx, ebx
  mov [esp], $48E380
@std:
end;

//----- Fix simple message staying on screen

procedure FixSimpleMessagePersist;
asm
  cmp Options.DontSkipSimpleMessage, 0
  jnz @redraw
  cmp dword [eax + $1C], $1A
  jnz @keep
@redraw:
  mov dword ptr [$576EAC], 1
@keep:
end;

//----- HooksList

var
  HooksList: array[1..325] of TRSHookInfo = (
    (p: $45B0D1; newp: @KeysHook; t: RShtCall; size: 6), // My keys handler
    (p: $4655FE; old: $452C75; backup: @@SaveNamesStd; newp: @SaveNamesHook; t: RShtCall), // Buggy autosave file name localization
    (p: $45E5A4; old: $45E2D0; backup: @FillSaveSlotsStd; newp: @FillSaveSlotsHook; t: RShtCall), // Fix Save/Load Slots
    (p: $45EB36; old: $45E2D0; newp: @FillSaveSlotsHook; t: RShtCall), // Fix Save/Load Slots
    (p: $4352CD; old: $4309C7; backup: @ChooseSaveSlotBackup; newp: @ChooseSaveSlotHook; t: RSht4), // Fix Save/Load Slots
    (p: $43520D; old: $430B16; backup: @SaveBackup; newp: @SaveHook; t: RSht4), // Fix Save/Load Slots
    (p: $460002; newp: @QuicksaveHook; t: RShtCall), // Quicksave trigger
    (p: $45E33F; newp: @QuickSaveSlotHook; t: RShtCall), // Show multiple Quick Saves
    (p: $45E65B; newp: @QuickSaveNamesHook; t: RShtCall; size: 6), // Quick Saves names
    (p: $4606FD; newp: @QuickSaveDrawHook; t: RShtCall; size: 6), // Quick Saves names Draw
    (p: $4605F2; newp: @QuickSaveDrawHook2; t: RShtCall; size: 6), // Quick Saves names Draw
    (p: $45F84E; old: $461B85; backup: @@SaveSetPauseStd; newp: @SaveSetPauseHook; t: RShtCall), // Autosave didn't pause time
    (p: $42FC46; newp: @CapsLockHook; t: RShtCall; size: 6; Querry: 4), // CapsLockToggleRun
    (p: $463541; backup: @@oldDeathMovie; newp: @DeathMovieHook; t: RShtCall), // Allow loading quick save from death movie + NoDeathMovie
    (p: $4651F0; new: $465241; t: RShtJmp; size: 6; Querry: 1), // NoCD
    (p: $4AC2D7; old: $840F; new: $E990; t: RSht2), // Fix XP compatibility
    (p: $462D9D; old: $2024448B; new: int($FFB0C031); t: RSht4), // Fix XP compatibility
    (p: $474CEF; old: $F5; new: 0; t: RSht4), // Fix Walk Sound
    (p: $47371E; old: $9A; new: 0; t: RSht4), // Fix Walk Sound
    (p: $4BF572; old: $72; new: $EB; t: RSht1), // Mok's patch smack bug
    (p: $44686D; newp: @InactiveMemberEventsHook; t: RShtCall; size: 6), // Multiple fauntain drinks bug
    (p: $493891; newp: @CheckNextMemberHook; t: RShtCall; size: 8; Querry: 8), // Switch between inactive members in inventory screen
    (p: $4938B5; newp: @CheckNextMemberHook; t: RShtCall; size: 8; Querry: 8), // Switch between inactive members in inventory screen
    (p: $418361; old: $418437; newp: @AttackDescriptionHook; t: RShtJmp), // Show recovery time for Attack
    (p: $418387; old: $418437; newp: @ShootDescriptionHook; t: RShtJmp), // Show recovery time for Shoot
    (p: $41697B; old: 500; new: 600; t: RSht4; Querry: 9), // Allow using Harden Item on artifacts
    (p: $4167FC; old: $416773; new: $41677E; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $416814; old: $416773; new: $41677E; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $416837; old: $416773; new: $41677E; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $416845; old: $416773; new: $41677E; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $41684E; old: $416773; new: $41677E; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $416857; old: $416773; new: $41677E; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $41686C; old: $416773; new: $41677E; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $416878; old: $416773; new: $41677E; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $4168F7; old: $416773; new: $41677E; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $416905; old: $416773; new: $41677E; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $41690E; old: $416773; new: $41677E; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $416917; old: $416773; new: $41677E; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $41692C; old: $416773; new: $41677E; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $416938; old: $416773; new: $41677E; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $416961; old: $416773; new: $41677E; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $41696A; old: $416773; new: $41677E; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $416974; old: $416773; new: $41677E; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $41697F; old: $416773; new: $41677E; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $4CAD70; newp: @_sprintfex; newref: true; t: RShtJmp; size: 6; Querry: 6), // Buka localization
    (p: $4BE7C1; old: 1000; new: 1; t: RSht4; Querry: 5), // Delay after cancelling video
    (p: $4BEB54; old: 300; new: 1; t: RSht4; Querry: 5), // Delay after showing video
    (p: $410897; newp: @LodFilesHook; t: RShtCall; size: 6; Querry: 12), // Load files from DataFiles folder
    (p: $410980; newp: @LodFileStoreSize; t: RShtCall), // Need when loading files
    (p: $443D29; newp: @LodFileEvtOrStr; t: RShtJmp), // Load *.evt and *.str from DataFiles folder
    (p: $48D021; old: $45827D; newp: @SecondHandDaggerHook; t: RShtCall), // Dagger tripple damage from 2nd hand check
    (p: $48E431; old: $45827D; newp: @WeaponRecoveryBonusHook; t: RShtCall; size: 8), // Include items bonus to skill in recovery time
    (p: $48E43B; t: RShtNop; size: 2), // Include items bonus to skill in recovery time
    (p: $4685ED; old: $492C03; backup: @ScrollTestMemberStd; newp: @ScrollTestMember; t: RShtCall; Querry: 17), // Don't allow using scrolls by not active member
    (p: $41AB2E; old: $495446; backup: @ReputationHookStd; newp: @ReputationHook; t: RShtCall; Querry: 7), // Show numerical reputation value
    (p: $41AB3C; old: $4E3010; newp: PChar('%s: '#12'%05d%d %s'#12'00000'); t: RSht4; Querry: 7), // Show numerical reputation value
    (p: $41AB48; old: $14; new: $18; t: RSht1; Querry: 7), // Show numerical reputation value
    (p: $492EA0; newp: ptr($492DD3); t: RShtJmp; size: $492EBA - $492EA0), // Poison condition ignored Protection from Magic
    (p: $426376; old: $4262C0; backup: @DoubleSpeedStd; newp: @DoubleSpeedHook; t: RShtCall), // DoubleSpeed
    (p: $472C6F; old: $4CA74C; backup: @TurnSpeedStd; newp: @TurnSpeedHook; t: RShtCall), // TurnSpeed
    (p: $472C97; old: $4CA74C; newp: @TurnSpeedHook; t: RShtCall), // TurnSpeed
    (p: $473DA9; old: $4CA74C; newp: @TurnSpeedHook; t: RShtCall), // TurnSpeed
    (p: $473DD1; old: $4CA74C; newp: @TurnSpeedHook; t: RShtCall), // TurnSpeed
    (p: $474F92; old: $48E4F0; backup: @FeatherFallStd; newp: @FeatherFallHook; t: RShtCall), // fix 'of Feather Falling' items
    (p: $48CF05; newp: @DaggerTrippleHook; t: RShtCall; Querry: 10), // ProgressiveDaggerTrippleDamage
    (p: $48D033; newp: @DaggerTrippleHook; t: RShtCall; Querry: 10), // ProgressiveDaggerTrippleDamage
    (p: $4B6B10; old: 1500; newp: @Options.HorsemanSpeakTime; newref: true; t: RSht4; Querry: -1), // Horseman delay
    (p: $4B6B23; old: 2500; newp: @Options.BoatmanSpeakTime; newref: true; t: RSht4; Querry: -1), // Boatman delay
    (p: $42934D; newp: @HasteWeakHook1; t: RShtCall), // Haste on party with dead weak members
    (p: $42D9AD; newp: @HasteWeakHook2; t: RShtCall), // Haste on party with dead weak members
    (p: $466B9B; newp: @ErrorHook1; t: RShtCall; size: 6), // Report errors
    (p: $466C0C; newp: @ErrorHook2; t: RShtCall; size: 6), // Report errors
    (p: $466E5D; newp: @ErrorHook3; t: RShtCall; size: 6), // Report errors
    (p: $4AA0CF; newp: @ChangeTrackHook; t: RShtCall; size: 7), // MusicLoopsCount
    (p: $432AC8; old: $7B; new: $71; t: RSht1), // Fix menu return
    (p: $420412; newp: @FixChestHook; t: RShtCall; Querry: 11), // Fix chests: place items that were left over
    (p: $48E4E3; newp: @FixBlasterSpeed; t: RShtCall; size: 6), // Limit blaster & bow speed with BlasterRecovery
    (p: $466CD8; newp: @DDrawErrorHook; t: RShtJmp), // Ignore DDraw errors
    (p: $42262C; old: $D75; new: $22EB; t: RSht2), // Remove code left from MM6 (pretty harmless, but still a bug)
    (p: $4C0B31; old: $20; new: 8; t: RSht1), // Attacking big monsters D3D
    (p: $4A4FF1; old: $452504; newp: @LoadSpriteD3DHook; t: RShtCall), // No HWL for sprites
    (p: $4ACA13; old: $4A4FD8; newp: @LoadSpriteD3DHook2; t: RShtJmp), // No HWL for sprites
    (p: $4AC8CD; old: $4AC98A; newp: @LoadSpriteD3DHook3; t: RShtCall), // No HWL for sprites
    (p: $4AC768; old: $4AC851; newp: @LoadSpriteD3DHook4; t: RShtJmp6), // No HWL for sprites
    (p: $49EAE8; size: 16), // No HWL for sprites
    (p: $49EB49; size: 5), // No HWL for sprites
    (p: $4C115A; old: $4C1235; new: $4C1386; t: RShtCall), // Never can be sure a sprite obscures a facet
    (p: $4C115F; size: 8), // Never can be sure a sprite obscures a facet
    (p: $4C151E; old: $4C088F; new: $4C0C96; t: RShtCall), // Don't check sprite visibility when clicking
    (p: $4C1523; size: 4), // Don't check sprite visibility when clicking
    (p: $497E2B; newp: @FixCreditsPause; t: RShtCall; size: 6), // Credits move too fast
    (p: $4975E9; old: $495B4F; backup: @@DrawPartyScreenStd; newp: @DrawPartyScreenHook; t: RShtCall), // Fix party generation screen clouds & arrows speed
    (p: $426689; newp: @MemoryInitHook; t: RShtCall; size: 8), // Use Delphi memory manager
    (p: $426446; newp: @MemoryFreeHook; t: RShtJmp; size: 6), // Use Delphi memory manager
    (p: $42674E; newp: @MemoryNewHook; t: RShtJmp; size: 7), // Use Delphi memory manager
    (p: $452D3A; old: $4CC17B; newp: @GlobalTxtHook; t: RShtCall), // Fix global.txt parsing out-of-bounds
    (p: $453B11; old: $4CC17B; newp: @SpellsTxtHook; t: RShtCall), // Fix spells.txt parsing out-of-bounds
    (p: $453EEC; old: 29; new: 28; t: RSht4), // Fix history.txt parsing out-of-bounds
    (p: $475A67; newp: @FacetCheckHook; t: RShtCall), // Fix facet ray interception checking out-of-bounds
    (p: $475B42; newp: @FacetCheckHook; t: RShtCall), // Fix facet ray interception checking out-of-bounds
    (p: $475C15; newp: @FacetCheckHook; t: RShtCall), // Fix facet ray interception checking out-of-bounds
    (p: $4C21AB; newp: @FacetCheckHook2; t: RShtCall), // Fix facet interception checking out-of-bounds
    (p: $4C22A9; newp: @FacetCheckHook2; t: RShtCall), // Fix facet interception checking out-of-bounds
    (p: $4C239D; newp: @FacetCheckHook2; t: RShtCall), // Fix facet interception checking out-of-bounds
    (p: $46D5F6; newp: @FacetCheckHook3; t: RShtCall; size: 7), // Fix facet interception checking out-of-bounds
    (p: $46D60E; newp: @FacetCheckHook3; t: RShtCall; size: 7), // Fix facet interception checking out-of-bounds
    (p: $49AC92; newp: @NoVertexFacetHook; t: RShtCall), // There may be facets without vertexes
    (p: $43644F; newp: @NoVertexFacetHook2; t: RShtBefore), // There may be facets without vertexes
    (p: $48A5B9; newp: @PalettesHook; t: RShtCall), // Get rid of palettes limit in D3D
    (p: $46A364; newp: ptr($46A38C); t: RShtJmp), // Ignore 'Invalid ID reached!'
    (p: $44EC22; newp: ptr($44EC4A); t: RShtJmp), // Ignore 'Sprite outline currently Unsupported'
    (p: $46A1A9; old: $46A338; backup: @@PressSpaceStd; newp: @PressSpaceHook; t: RShtCall), // D3D better space reaction
    (p: $449AC3; newp: @DoorStateSwitchHook; t: RShtCall), // Correct door state switching: param = 3
    (p: $42FE25; newp: @StrafeOrWalkHook; t: RShtCall; size: 6; Querry: 15), // Strafe in MouseLook
    (p: $42FEA5; newp: @StrafeOrWalkHook; t: RShtCall; size: 6; Querry: 15), // Strafe in MouseLook
    (p: $4CB071; backup: @@FixPrismaticBugStd; newp: @FixPrismaticBug; t: RShtCall), // A beam of Prismatic Light in the center of screen that doesn't disappear
    (p: $474300; newp: @MouseLookFlyHook1; t: RShtCall), // Fix strafes and walking rounding problems
    (p: $47303C; newp: @MouseLookFlyHook2; t: RShtCall), // Fix strafes and walking rounding problems
    (p: $41F312; newp: @IDMonHook; t: RShtCall; size: 6), // Show resistances of monster
    (p: $4178C5; newp: @StatColorFixHook; t: RShtCall; size: 7), // negative/0 causes a crash in stats screen
    (p: $45A994; newp: @FixKeyConfigHook; t: RShtCall), // Fix keys configuration loading
    (p: $48A4C8; old: $4D8868; newp: @Options.PaletteSMul; t: RSht4), // Control palette gamma
    (p: $48A48F; old: $4D886C; newp: @Options.PaletteVMul; t: RSht4), // Control palette gamma
    (p: $4D8868; newp: @Options.PaletteSMul; newref: true; t: RSht4; Querry: -1), // Control palette gamma
    (p: $4D886C; newp: @Options.PaletteVMul; newref: true; t: RSht4; Querry: -1), // Control palette gamma
    (p: $411C1E; old: $411AB6; backup: @@TPFixStd; newp: @TPFixHook; t: RShtCall), // Pause the game in Town Portal screen
    (p: $465B9E; newp: @DefaultSmoothTurnHook; t: RShtCall), // Use Smooth turn rate by default
    (p: $493917; old: $48E8ED; newp: @FixWaitHook; t: RShtCall), // Waiting used to recover characters twice as fast
    (p: $4636E4; old: $4CAC80; newp: @FixLeaveMapDieHook; t: RShtCall), // Was no LeaveMap event on death
    (p: $432E63; newp: @FixLeaveMapWalkHook; t: RShtCall), // Was no LeaveMap event with walk travel
    //(p: $4D8260; newp: @MyGetAsyncKeyState; t: RSht4), // Don't rely on bit 1 of GetAsyncKeyState
    (p: $4B6997; old: $492BAE; newp: @TravelGoldFixHook1; t: RShtCall), // Subtract gold after autosave when trevelling
    (p: $4B6AF4; old: $4B1DF5; newp: @TravelGoldFixHook2; t: RShtCall), // Subtract gold after autosave when trevelling
    (p: $46532F; t: RShtNop; size: $11), // Switch to 16 bit color when going windowed
    (p: $49DE88; old: $4CB9C0; backup: @AutoColor16Std; newp: @AutoColor16Hook; t: RShtCall), // Switch to 16 bit color when going windowed
    (p: $4A0987; old: $4A11AC; backup: @AutoColor16Std2; newp: @AutoColor16Hook2; t: RShtCall), // Switch to 16 bit color when going windowed
    (p: $46334B; old: $4304D6; newp: @AutorunHook; t: RShtCall), // Autorun key like in WoW
    (p: $43367E; newp: @LloydAutosaveFix; t: RShtCall), // Lloyd: take spell points and action after autosave
    (p: $43393B; newp: @TPAutosaveFix; t: RShtCall), // TP: take action after autosave
    (p: $4338CB; t: RShtNop; size: 5), // Town Portal triggered autosave even within a location
    (p: $44F0A8; new: $44F100; t: RShtJmp), // My bug: quicksave set to F11 not working
    (p: $466CC6; newp: ptr($10C2); t: RSht4), // Ignore DD errors
    (p: $49A5D9; old: 0; new: 1; t: RSht1), // Fix DLV search in games.lod
    (p: $47E60A; old: 0; new: 1; t: RSht1), // Fix DDM search in games.lod
    (p: $4798BA; newp: @FixSkyCrash; t: RShtCall; size: 6), // Fix crash when looking too low (lower than game allows)
    (p: $485220; newp: @FixDivCrash1; t: RShtCall; size: 6), // Fix int overflow crash in editor
    (p: $479DEA; newp: @FixDivCrash2; t: RShtCall; size: 6), // Fix int overflow crash in editor
    (p: $47A12E; newp: @FixDivCrash2; t: RShtCall; size: 6), // Fix int overflow crash in editor
    (p: $4615BD; newp: @FindInLodAndSeekHook; t: RShtCall), // Custom LODs
    (p: $461659; newp: @FindInLodHook; t: RShtCall), // Custom LODs
    (p: $4655FE; backup: @@LoadLodsOld; newp: @LoadLodsHook; t: RShtCall), // Custom LODs
    (p: $4BEA1A; newp: @OpenVidsHook; t: RShtJmp), // Custom LODs - Vid
    (p: $4BF154; newp: @OpenBikSmkHook; t: RShtCall), // Custom LODs - Vid(Smk)
    (p: $4BF0AF; newp: @OpenBikSmkHook; t: RShtCall), // Custom LODs - Vid(Bik)
    (p: $4AB80B; newp: @OpenSndsHook; t: RShtCall; size: 7), // Custom LODs - Snd
    (p: $4A9783; newp: @OpenSndHook; t: RShtCall; size: 16), // Custom LODs - Snd
    (p: $4A9BA6; newp: @OpenSndHook2; t: RShtCall), // Custom LODs - Snd
    (p: $470578; newp: @FixStrafe1; t: RShtCall; size: 7; Querry: 23), // Fix movement rounding problems
    (p: $4705A4; newp: @FixStrafe1; t: RShtCall; size: 7; Querry: 23), // Fix movement rounding problems
    (p: $4705CB; newp: @FixStrafe1; t: RShtCall; size: 7; Querry: 23), // Fix movement rounding problems
    (p: $4705F2; newp: @FixStrafe1; t: RShtCall; size: 7; Querry: 23), // Fix movement rounding problems
    (p: $470614; newp: @FixStrafe1; t: RShtCall; size: 7; Querry: 23), // Fix movement rounding problems
    (p: $46FDAF; backup: @OldMoveStructInit; newp: @FixStrafeMonster1; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $470C44; newp: @FixStrafeMonster2; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $471690; newp: @FixStrafeObject1; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $471E5A; newp: @FixStrafeObject2; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $473161; newp: @FixStrafePlayer; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $4745B9; newp: @FixStrafePlayer; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $4731D1; newp: @FixStrafe2; t: RShtCall; size: 6; Querry: 23), // Fix movement rounding problems
    (p: $4731F1; newp: @FixStrafe2; t: RShtCall; size: 6; Querry: 23), // Fix movement rounding problems
    (p: $473214; newp: @FixStrafe2; t: RShtCall; size: 6; Querry: 23), // Fix movement rounding problems
    (p: $474633; newp: @FixStrafe2; t: RShtCall; size: 6; Querry: 23), // Fix movement rounding problems
    (p: $474656; newp: @FixStrafe2; t: RShtCall; size: 6; Querry: 23), // Fix movement rounding problems
    (p: $474679; newp: @FixStrafe2; t: RShtCall; size: 6; Querry: 23), // Fix movement rounding problems
    (p: $441252; newp: @HDWTRCountHook; t: RShtCall; size: $441282 - $441252), // Control D3D water
    (p: $465EBB; old: 7; newp: @Options.HDWTRCount; newref: true; t: RSht1; Querry: -1), // Control D3D water
    (p: $462D8E; backup: @OldStart; newp: @StartHook; t: RShtCall), // Call ApplyDeferredHooks after MMExt loads
    (p: $48FDF0; newp: @FixSpear; t: RShtJmp; Querry: -1), // Spear skill wasn't added to damage on expert level (only on master)
    (p: $48F0CB; newp: @FixTaledonsHelm; t: RShtCall), // Taledon's helm does not add anything to light magic
    (p: $468C75; old: $4687A8; new: $468624; t: RShtJmp6), // Don't waste black potion if it has no effect
    (p: $468C92; old: $4687A8; new: $468624; t: RShtJmp6), // Don't waste black potion if it has no effect
    (p: $468CAF; old: $4687A8; new: $468624; t: RShtJmp6), // Don't waste black potion if it has no effect
    (p: $468CCC; old: $4687A8; new: $468624; t: RShtJmp6), // Don't waste black potion if it has no effect
    (p: $468CE9; old: $4687A8; new: $468624; t: RShtJmp6), // Don't waste black potion if it has no effect
    (p: $468D06; old: $4687A8; new: $468624; t: RShtJmp6), // Don't waste black potion if it has no effect
    (p: $468D23; old: $4687A8; new: $468624; t: RShtJmp6), // Don't waste black potion if it has no effect
    (p: $41A49B; old: 1; new: 3; t: RSht1), // Show broken and unidentified items in red
    (p: $40872C; new: $408760; t: RShtJmp), // Fix Telepathy
    (p: $426A96; newp: @FixTelepathy; t: RShtCall; size: 8), // Fix Telepathy
    (p: $4ACBBB; newp: @FixSmallScaleSprites; t: RShtCall), // Fix small scale sprites crash
    (p: $43681F; old: $1F400000; new: $7FFFFFFF; t: RSht4), // Infinite view distance in dungeons
    (p: $48FE51; newp: @FixGMStaffHook; t: RShtJmp; Querry: 20), // Fix GM Staff ignoring Armsmaster bonus to Damage
    (p: $4578E7; newp: @FixItemsTxtHook; t: RShtJmp), // Fix items.txt: make special items accept standard "of ..." strings
    (p: $448CC9; newp: @FixTimerRetriggerHook1; t: RShtJmp; size: 6; Querry: 21), // Fix timers
    (p: $448C8A; newp: @FixTimerRetriggerHook2; t: RShtBefore; size: 7; Querry: 21), // Fix timers
    (p: $444133; newp: @FixTimerSetupHook1; t: RShtJmp; Querry: 21), // Fix timers
    (p: $44427C; newp: @FixTimerSetupHook2; t: RShtJmp; size: 7; Querry: 21), // Fix timers
    (p: $444008; newp: @FixTimerValidate; t: RShtBefore; size: 6; Querry: 21), // Tix timers - validate last timers
    (p: $42B535; newp: @TPDelayHook1; t: RShtJmp), // Town Portal wasting player's turn even if you cancel the dialog
    (p: $4339CB; newp: @TPDelayHook2; t: RShtCall), // Town Portal wasting player's turn even if you cancel the dialog
    (p: $473005; newp: @FixMovementNerf; t: RShtCall; Querry: 23), // Fix movement rounding problems - nerf jump
    (p: $47300E; t: RShtNop; size: 3; Querry: 23), // Fix movement rounding problems - nerf jump
    (p: $474294; newp: @FixMovementNerf; t: RShtCall; Querry: 23), // Fix movement rounding problems - nerf jump
    (p: $4742AD; t: RShtNop; size: 3; Querry: 23), // Fix movement rounding problems - nerf jump
    (p: $46FA3B; newp: @NoMonsterJumpDown1; t: RShtCall; size: 8), // Prevent monsters from jumping into lava etc.
    (p: $46FFE0; newp: @NoMonsterJumpDown2; t: RShtCall), // Prevent monsters from jumping into lava etc.
    (p: $46387C; newp: @FixFullScreenBlink; t: RShtCall; size: 6), // Light gray blinking in full screen
    (p: $40D9EA; newp: @FixBlitCopy; t: RShtCall; size: 6), // Draw buffer overflow in Arcomage
    (p: $40A5DB; t: RShtNop; size: 2), // Hang in Arcomage
    (p: $495484; newp: @FixBuyNoMember; t: RShtCall), // Buy dialog out-of-bounds read when no active player
    (p: $44FD6F; old: $44FD8A; new: $44FD99; t: RShtJmp2; Querry: hqFixMonsterSummon), // Monsters summoning wrong monsters (e.g. Archmages summoning Sylphs)
    (p: $44FF40; newp: @FixMonsterSummon; t: RShtJmp; size: 7), // Monsters summoned by other monsters had wrong monster as their ally
    (p: $427F12; old: $4040E9; newp: @FixDragonTargeting; t: RShtCall), // Blasters and some spells couldn't target rats
    (p: $462DD5; t: RShtNop; size: 7; Querry: 24), // DisableAsyncMouse
    (p: $463979; t: RShtNop; size: 7; Querry: 24), // DisableAsyncMouse
    (p: $463BFA; t: RShtNop; size: 7; Querry: 24), // DisableAsyncMouse
    (p: $465F83; t: RShtNop; size: 7; Querry: 24), // DisableAsyncMouse
    (p: $466DDD; t: RShtNop; size: 6; Querry: 24), // DisableAsyncMouse
    (p: $444C41; newp: @NoTransitionTextHook; t: RShtJmp), // Show "Leave ***" instead of "No transition text found!"
    (p: $416D85; size: 5), // Don't resume time if mouse exits the window while right button is pressed
    (p: $449FA5; old: 97; new: 104; t: RSht1), // Evt commands couldn't operate on some skills
    (p: $44A030; size: 9), // Evt commands couldn't operate on some skills
    (p: $44AB44; old: 97; new: 104; t: RSht1), // Evt commands couldn't operate on some skills
    (p: $44ABE2; size: 9), // Evt commands couldn't operate on some skills
    (p: $44B4FB; old: 97; new: 104; t: RSht1), // Evt commands couldn't operate on some skills
    (p: $44B56B; size: 9), // Evt commands couldn't operate on some skills
    (p: $44C187; oldstr: #50#48#50#50#50#50#50#50; newstr: #48#48#48#48#48#48#48#48; t: RShtBStr), // Evt commands couldn't operate on some skills
    (p: $417580; old: $46381D; newp: @RightThenLeftMouseHook; t: RShtCall), // Make left click not only cancel right button menu, but also perform action
    (p: $490F31; size: 16), // Shops unable to operate on some artifacts
    (p: $4BDA4E; size: 16), // Shops unable to operate on some artifacts
    (p: $490F67; newp: @CanSellItemHook; t: RShtCall; size: 6), // Shops buying blasters
    (p: $4BDE0A; old: $4BDA12; newp: @CanSellItemHook2; t: RShtCall), // Shops buying blasters
    (p: $4ABCF5; newp: @ExitCrashHook; t: RShtCall; size: 8), // Crash on exit
    (p: $4732E1; newp: @FixLava1; t: RShtCall), // Lava hurting players in air
    (p: $47382F; newp: @FixLava2; t: RShtCall; size: 7), // Lava hurting players in air
    (p: $4BE889; newp: @FixEndMovieStop; t: RShtBefore), // Bug if the game is deactivated during end movie
    (p: $4D8258; newp: @ScreenToClientHook; t: RSht4), // Configure window size
    (p: $4BE6EB; newp: @DrawMovieHook; t: RShtBefore; Querry: hqFixSmackDraw), // Compatible movie render
    (p: $4BEE41; old: $74; new: $EB; t: RSht1; Querry: hqFixSmackDraw), // Compatible movie render
    (p: $4BEE97; old: $840F; new: $E990; t: RSht2; Querry: hqFixSmackDraw), // Compatible movie render
    (p: $4A173B; old: $4A0ED0; newp: @SmackDrawHook1; t: RShtCallStore; Querry: hqFixSmackDraw), // Compatible movie render
    (p: $4A1701; old: $4A0FC2; newp: @SmackDrawHook1; t: RShtCallStore; Querry: hqFixSmackDraw), // Compatible movie render
    (p: $4BEFBE; old: $4A1757; newp: @SmackDrawHook2; t: RShtCallStore; Querry: hqFixSmackDraw), // Compatible movie render
    (p: $4BF4B1; newp: @SmackLoadHook; t: RShtBefore; Querry: hqFixSmackDraw), // Compatible movie render
    (p: $4BECFA; old: $4C00A5; newp: @BinkDrawHook1; t: RShtCallStore; Querry: hqFixSmackDraw), // Compatible movie render
    (p: $4BED3A; old: $74; new: $EB; t: RSht1; Querry: hqFixSmackDraw), // Compatible movie render
    (p: $4BED9F; old: $4A1885; newp: @BinkDrawHook2; t: RShtCallStore; Querry: hqFixSmackDraw), // Compatible movie render
    (p: $49F1EE; new: $49F20D; t: RShtJmp; size: 6; Querry: hqTrueColor), // 32 bit color support
    (p: $463AA8; size: 6; Querry: hqTrueColor), // 32 bit color support
    (p: $465333; size: 2; Querry: hqTrueColor), // 32 bit color support
    (p: $4D801C; newp: @MyDirectDrawCreate; t: RSht4; Querry: hqTrueColor), // 32 bit color support + HD
    (p: $4A4ED7; newp: @FixMipmapsMemLeak; t: RShtAfter), // Mipmaps generation code not calling surface->Release
    (p: $41E84B; newp: @FixSpritesInMonInfo; t: RShtBefore; size: 6), // Fix sprites with non-zero transparent colors in monster info dialog
    (p: $41E948; newp: @FixSpritesInMonInfo; t: RShtBefore; size: 5), // Fix sprites with non-zero transparent colors in monster info dialog
    (p: $465438; old: $CA0000; new: $CA0000 or WS_SIZEBOX or WS_MAXIMIZEBOX or WS_SYSMENU; t: RSht4), // Allow window resize
    (p: $4668A2; newp: @GetRestoredRect; t: RShtCall; size: 6), // Allow window maximization
    (p: $464686; newp: @GetRestoredRect; t: RShtCall; size: 6), // Allow window maximization
    (p: $43FCC7; old: $D4; new: $C4; t: RSht4), // Decorations were shrinked vertically in D3D mode
    (p: $43FCBC; old: $D0; new: $C4; t: RSht4), // Support changing FOV indoor in D3D mode
    (p: $440090; old: $D0; new: $C4; t: RSht4), // Support changing FOV indoor in D3D mode
    (p: $440516; old: $D0; new: $C4; t: RSht4), // Support changing FOV indoor in D3D mode
    (p: $48AF26; old: $D0; new: $C4; t: RSht4), // Support changing FOV indoor in D3D mode
    (p: $42FD15; newp: @FixTurnBasedWalking; t: RShtAfter; size: 6; Querry: hqFixTurnBasedWalking), // Fix multiple steps at once in turn-based mode
    (p: $42FD65; newp: @FixTurnBasedWalking; t: RShtAfter; size: 6; Querry: hqFixTurnBasedWalking), // Fix multiple steps at once in turn-based mode
    (p: $42FDBD; newp: @FixTurnBasedWalking; t: RShtAfter; size: 6; Querry: hqFixTurnBasedWalking), // Fix multiple steps at once in turn-based mode
    (p: $42FE00; newp: @FixTurnBasedWalking; t: RShtAfter; size: 6; Querry: hqFixTurnBasedWalking), // Fix multiple steps at once in turn-based mode
    (p: $42FE4E; newp: @FixTurnBasedWalking; t: RShtAfter; size: 6; Querry: hqFixTurnBasedWalking), // Fix multiple steps at once in turn-based mode
    (p: $42FECE; newp: @FixTurnBasedWalking; t: RShtAfter; size: 6; Querry: hqFixTurnBasedWalking), // Fix multiple steps at once in turn-based mode
    (p: $443388; newp: @MinimapZoomHook; t: RShtFunctionStart; size: 6), // Remember minimap zoom indoors
    (p: $44E203; old: $7F; new: $7D; t: RSht1), // TFT.bin was animated incorrectly (first frame was longer, last frame was shorter)
    (p: $4B0C7E; newp: @TFTWaterHook; t: RShtBefore), // IsWater and AnimateTFT bits didn't work together in D3D
    (p: $478965; newp: @WaterBitHook; t: RShtBefore; size: 6), // IsWater bit was causing water texture to be used outdoors in D3D
    (p: $4D821C; newp: @MyLoadCursor; t: RSht4), // Load cursors from Data
    (p: $4417FB; old: $4A5E42; newp: @DrawIconAuto; t: RShtCall), // Transparent spell icons (Bless etc.)
    (p: $441839; old: $4A5E42; newp: @DrawIconAuto; t: RShtCall), // Transparent spell icons (Bless etc.)
    (p: $441877; old: $4A5E42; newp: @DrawIconAuto; t: RShtCall), // Transparent spell icons (Bless etc.)
    (p: $4418B5; old: $4A5E42; newp: @DrawIconAuto; t: RShtCall), // Transparent spell icons (Bless etc.)
    (p: $4416EA; newp: @FixSimpleMessageSpells; t: RShtCall), // Fly and Water Walk icon not drawn in simple message screen (+ support FlyNPCScreen)
    (p: $4E2A98; old: $16; new: $17; t: RSht2; Querry: hqFixInterfaceBugs), // Fix health bars position
    (p: $4E2A9C; old: $89; new: $8A; t: RSht2; Querry: hqFixInterfaceBugs), // Fix health bars position
    (p: $4924FA; add: -1; t: RSht4; Querry: hqFixInterfaceBugs), // Fix danger indicators position
    (p: $4924AF; add: -1; t: RSht4; Querry: hqFixInterfaceBugs), // Fix danger indicators position
    (p: $434AA2; add: 1; t: RSht4; Querry: hqFixInterfaceBugs2), // Fix position of 'close rings view' in inventory
    (p: $434AA2; add: 518 - 470; t: RSht4; Querry: hqCloseRingsCloser), // Move 'close rings' button closer
    (p: $434A9D; old: 445; new: 313; t: RSht4; Querry: hqCloseRingsCloser), // Move 'close rings' button closer
    (p: $43E8CA; old: $511748; new: $507558; t: RSht4; Querry: hqCloseRingsCloser), // Move 'close rings' button closer
    (p: $48F694; old: $48F0AC; newp: @FixGloryShield; t: RShtCodePtrStore), // 'Of Spirit Magic' effect of Glory Shield wasn't working
    (p: $463007; newp: @PostponeIntroHook; t: RShtBefore; Querry: hqPostponeIntro), // Postpone intro
    (p: $462FEB; newp: @PostponeIntroHook; t: RShtAfter; Querry: hqPostponeIntro2), // Postpone intro
    (p: $44EB0B; newp: @NoTreeHintsHook; t: RShtAfter; size: 6), // No hints for non-interactive sprites
    (p: $4942CA; old: $48D6EF; newp: @LadysEscortFix; t: RShtCall), // Fix Lady's Escort water walking
    (p: $4303E2; newp: @QuestionFixSpace; t: RShtCall), // Fix space in evt.Question
    (p: $40D677; size: 2), // If current fines are due, arcomage win/lose count wasn't added to awards
    (p: $40D6BF; size: 2), // If current fines are due, arcomage win/lose count wasn't added to awards
    (p: $42FE94; old: 10; new: 2; t: RSht1), // Snow X speed was effected by strafing too much
    (p: $42FF15; old: -10; new: -2; t: RSht1), // Snow X speed was effected by strafing too much
    (p: $4BB762; newp: @FixMasterHealer; t: RShtCall), // Fix Master Healer messing up some skills
    (p: $4501E8; size: 5), // Fix artifacts not being generated as objects on the ground
    (p: $41E0CC; old: $4E32A4; newp: @SDuration; newref: true; t: RSht4), // Duration text
    (p: $41E0F2; old: $4E329C; newp: @SDurationYr; newref: true; t: RSht4), // Duration text
    (p: $41E126; old: $4E3294; newp: @SDurationMo; newref: true; t: RSht4), // Duration text
    (p: $41E162; old: $4E328C; newp: @SDurationDy; newref: true; t: RSht4), // Duration text
    (p: $41E1A6; old: $4E3284; newp: @SDurationHr; newref: true; t: RSht4), // Duration text
    (p: $41E1F2; old: $4E327C; newp: @SDurationMn; newref: true; t: RSht4), // Duration text
    (p: $48D4F3; newp: @FixLichImmuneHook; t: RShtCall; size: 6; Querry: hqFixLichImmune), // Lich becoming immune to all magic with sufficient Day of Protection
    (p: HookPopAction; newp: @PopActionAfter; t: RShtBefore; size: 9), // Make HookPopAction useable with straight Delphi funcitons
    (p: $41BD94; newp: @RememberClockArea; t: RShtAfter), // Remember clock area to extend it with UI layout
    (p: $445F76; old: 4; new: 3; t: RSht1), // Fix NPCs with action having 1 non-interactive dialog item
    (p: $48D284; newp: @FixTitanSlaying; t: RShtBefore; size: 6), // Fix 'Of David' not working on bows
    (p: $48CE8F; newp: @FixGibbet; t: RShtAfter; size: 6), // Fix 'Gibbet' only doing double damage to Undead
    (p: $428EC9; size: 3), // Fix 'Charm' duration overflow on GM(Master)
    (p: $428ED9; old: $4D8470; newp: @SecToTime; t: RSht4), // Fix 'Charm' duration overflow on GM(Master)
    (p: $42E0F8; size: 3), // Fix 'Control Undead' duration overflow on GM
    (p: $42E108; old: $4D8470; newp: @SecToTime; t: RSht4), // Fix 'Control Undead' duration overflow on GM
    (p: $428E8F; old: 2; new: 3; t: RSht1), // Fix 'Charm' wrong durations
    (p: $428E9F; old: 3; new: 4; t: RSht1), // Fix 'Charm' wrong durations
    (p: $48DA1A; newp: @FixStealWand; t: RShtAfter; size: 7), // Wand stolen from a monster having 0 max charges
    (p: $48DA92; old: $5E44C0; newp: @SStoleItem; t: RSht4), // Wrong message was displayed when stealing an item from a monster
    (p: $433FC7; newp: @FixDarkTaverns; t: RShtAfter; Querry: hqFixDarkTrainers), // Resting in dark taverns was taking too long
    (p: $4B4BCF; newp: @FixDarkTrainers; t: RShtAfter; Querry: hqFixDarkTrainers), // Training in dark training halls was taking too long
    (p: $439F6C; old: 2; new: 8; t: RSht4), // 'of Acid' was dealing Water damage instead of Body
    (p: $48F0C6; newp: @FixKelebrim; t: RShtBefore; Querry: hqFixKelebrim), // Kelebrim wasn't doing -30 Earth Res
    (p: $450A15; old: 6; new: 7; t: RSht1; Querry: hqFixBarrels), // Kelebrim wasn't doing -30 Earth Res
    (p: $48E30F; newp: @FixWetsuits; t: RShtCall), // Fix Wetsuits having recovery penalty
    (p: $4451C1; newp: @FixSimpleMessagePersist; t: RShtCallBefore), // Fix simple message staying on screen
    ()
  );

procedure ReadDisables;
var
  i: int;
begin
  with TIniFile.Create(AppPath+'mm7.ini') do
    try
      for i := low(HooksList) to high(HooksList) do
        if ReadBool('Disable', 'Hook'+IntToStr(i), false) then
          HooksList[i].Querry:= -100;
    finally
      Free;
    end
end;

const
  MMResToolError = 'It appears that you are using an executable modified by MM7ResTool. '
   + 'GrayFace patch does a far greater job at supporting HD mode now, so it''s recommended that '
   + 'you restore and run the original mm7.exe for new UI to properly function. '
   + 'If you still want to continue using MM7ResTool, add the line SupportMM7ResTool=1 to mm7.ini to disable this message.'#13#10#13#10
   + 'Do you want to run MM7 with MM7ResTool support?';

procedure HookAll;
var
  LastDebugHook: DWord;
begin
  CheckHooks(HooksList);
  CheckMMHooks;
  CheckHooksD3D;
  if not SupportMM7ResTool and (pint($434AA2)^ <> 470) then
    if RSMessageBox(0, MMResToolError, SCaption, MB_ICONEXCLAMATION or MB_OKCANCEL) <> ID_OK then
      ExitProcess(0);
  ExtendSpriteLimits;
  ReadDisables;
  RSApplyHooks(HooksList);
  if NoDeathMovie then
    RSApplyHooks(HooksList, 3);
  if not CapsLockToggleRun then
    RSApplyHooks(HooksList, 4);
  if NoVideoDelays then
    RSApplyHooks(HooksList, 5);
  if UseMM7text and (RSLoadProc(_sprintfex, AppPath + 'mm7text.dll', '_sprintfex') <> 0) then
    RSApplyHooks(HooksList, 6);
  if ReputationNumber then
    RSApplyHooks(HooksList, 7);
  if FreeTabInInventory then
    RSApplyHooks(HooksList, 8);
  if not StandardStrafe then
    RSApplyHooks(HooksList, 15);
  if FixInfiniteScrolls then
    RSApplyHooks(HooksList, 17);
  if DisableAsyncMouse then
    RSApplyHooks(HooksList, 24);
  if (MipmapsCount > 1) or (MipmapsCount < 0) then
    RSApplyHooks(HooksList, hqMipmaps);
  if TurnBasedWalkDelay > 0 then
    RSApplyHooks(HooksList, hqFixTurnBasedWalking);
  if FixLichImmune then
    RSApplyHooks(HooksList, hqFixLichImmune);
  ApplyMMHooks;

  RSDebugUseDefaults;
  LastDebugHook:= DebugHook;
  DebugHook:= 0;
  RSDebugHook(true);
  @MyRaiseExceptionProc:= RaiseExceptionProc;
  RSDebugHook(false);
  DebugHook:= LastDebugHook;
  @LastUnhandledExceptionFilter:= SetUnhandledExceptionFilter(@UnhandledException);
end;

procedure ApplyDeferredHooks;
begin
  RSApplyHooks(HooksList, -1);
  if Options.PlayMP3 and DirectoryExists('Music') then
    HookMP3;
  if Options.NoCD and FileExists('Anims\Magic7.vid') then
    RSApplyHooks(HooksList, 1);
  case pint(_NoIntro)^ of
    2: RSApplyHooks(HooksList, hqPostponeIntro);
    3: RSApplyHooks(HooksList, hqPostponeIntro2);
  end;
  if Options.HardenArtifacts then
    RSApplyHooks(HooksList, 9);
  if Options.ProgressiveDaggerTrippleDamage then
    RSApplyHooks(HooksList, 10);
  if Options.FixChests then
    RSApplyHooks(HooksList, 11);
  if Options.DataFiles then
    RSApplyHooks(HooksList, 12);
  if Options.FixGMStaff then
    RSApplyHooks(HooksList, 20);
  if Options.FixTimers then
    RSApplyHooks(HooksList, 21);
  if Options.FixMovement then
    RSApplyHooks(HooksList, 23);
  if Options.CompatibleMovieRender then
    RSApplyHooks(HooksList, hqFixSmackDraw);
  if Options.SupportTrueColor then
    RSApplyHooks(HooksList, hqTrueColor);
  if Options.FixMonsterSummon then
    RSApplyHooks(HooksList, hqFixMonsterSummon);
  if Options.FixInterfaceBugs then
    RSApplyHooks(HooksList, hqFixInterfaceBugs);
  if Options.FixInterfaceBugs and not Options.HigherCloseRingsButton then
    RSApplyHooks(HooksList, hqFixInterfaceBugs2);
  if Options.HigherCloseRingsButton then
    RSApplyHooks(HooksList, hqCloseRingsCloser);
  if Options.FixDarkTrainers then
    RSApplyHooks(HooksList, hqFixDarkTrainers);
  if Options.FixKelebrim then
    RSApplyHooks(HooksList, hqFixKelebrim);
  if Options.FixBarrels then
    RSApplyHooks(HooksList, hqFixBarrels);
  ApplyMMDeferredHooks;
end;

exports
  LoadCustomLod,
  FreeCustomLod,
  GetCustomLodsList,
  GetLodRecords;
initialization
  ArrowCur:= LoadCursorFromFile('Data\MouseCursorArrow.cur');
  if ArrowCur = 0 then
    ArrowCur:= LoadCursor(GetModuleHandle(nil), 'Arrow');
  CursorTarget:= LoadCursorFromFile('Data\MouseCursorTarget.cur');
finalization
  // avoid hanging in case of exception on shutdown
  SetUnhandledExceptionFilter(@LastUnhandledExceptionFilter);
end.
