unit Hooks;

interface

uses
  Windows, Messages, SysUtils, Classes, RSSysUtils, RSQ, Common, RSCodeHook,
  Math, MP3, RSDebug, IniFiles, Direct3D, MMSystem, Graphics, RSStrUtils,
  DirectDraw, DXProxy, RSResample;

procedure HookAll;
procedure ApplyDeferredHooks;

implementation

var
  QuickSaveUndone, Autorun, SkipMouseLook: Boolean;
  DoubleSpeed: BOOL;

procedure ProcessMouseLook; forward;

//----- Functions

procedure AddAction(action, info1, info2:int); stdcall;
type
  PActionQueueItem = ^TActionQueueItem;
  TActionQueueItem = packed record
    Action: int;
    Info1: int;
    Info2: int;
  end;
  PActionQueue = ^TActionQueue;
  TActionQueue = packed record
    Count: int;
    Items: array[0..39] of TActionQueueItem;
  end;

const
  Queue = PActionQueue(_ActionQueue);
begin
  with Queue^ do
    if Count < 40 then
    begin
      Items[Count]:= PActionQueueItem(@action)^;
      inc(Count);
    end;
end;

function GetCurrentMember:ptr;
begin
  Result:= pptr(_PartyMembers + 4*_CurrentMember^)^;
end;

procedure DoPlaySound;
asm
  mov ecx, _PlaySoundStruct
  push _PlaySound
end;

var
  PlaySound: procedure(id: int; a3: int = 0; a4: int = 0; a5: int = -1; a6: int = 0; a7: int = 0; a8: int = 0; a9: int = 0); stdcall;

procedure ShowStatusText(text: string; time: int = 2);
begin
  _ShowStatusText(0, time, ptr(text));
  _NeedRedraw^:= 1;
end;

var
  SW, SH: int;

procedure NeedScreenWH;
begin
  SW:= _ScreenW^;
  SH:= _ScreenH^;
  if SW = 0 then  SW:= 640;
  if SH = 0 then  SH:= 480;
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

//----- Keys

var
  KeysChecked: array[0..255] of Boolean;

function MyGetAsyncKeyState(vKey: Integer): SHORT; stdcall;
begin
  vKey:= vKey and $ff;
  Result:= GetAsyncKeyState(vKey);
  if (Result < 0) and not KeysChecked[vKey] then
    Result:= Result or 1;
  KeysChecked[vKey]:= Result < 0;
end;

function CheckKey(key: int):Boolean;
begin
  Result:= (MyGetAsyncKeyState(key) and 1) <> 0;
end;

//----- Now time isn't resumed when mouse exits, need to check if it's still pressed

procedure CheckRightPressed;
const
  Btn: array[Boolean] of int = (VK_RBUTTON, VK_LBUTTON);
begin
  if GetAsyncKeyState(Btn[GetSystemMetrics(SM_SWAPBUTTON) <> 0]) >= 0 then
    _ReleaseMouse;
end;

//----- Called every tick. Quick Save, keys related things

var
  LastMusicStatus, MusicLoopsLeft: int;

procedure KeysProc;
var
  nopause: Boolean;
  status, loops: int;
begin
  // Don't allow using inactive members
  if (_Paused^=0) and (_CurrentScreen^ = 0) and (_CurrentMember^ <> 0) and
     (pword(int(GetCurrentMember) + _CharOff_Recover)^ > 0) and
     FixInactivePlayersActing then
  begin
    _CurrentMember^:= _FindActiveMember;
    _NeedRedraw^:= 1;
  end;

  // Fix keys configuration loading
  if not KeyConfigDone then
    DoKeyConfig;
  KeyConfigDone:= true;

  // Fix TurnBasedPhase staying at 3 whle TurnBased is off
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
  begin
    _Paused^:= 1;
    pint($69CDA8)^:= 1;
    _SaveSlotsFiles[0]:= 'quiksave.mm7';
    _DoLoadGame(0, 0, 0);
    pint($6A0BC8)^:= 3;
  end;

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
        AddAction(113, BoolToInt[_EscKeyUnkCheck^ <> 0], 0);
    end;

  // DoubleSpeedKey
  if CheckKey(Options.DoubleSpeedKey) then
  begin
    DoubleSpeed:= not DoubleSpeed;
    if DoubleSpeed then
      ShowStatusText(SDoubleSpeed)
    else
      ShowStatusText(SNormalSpeed);
  end;

  // Autorun like in WoW
  if CheckKey(Options.AutorunKey) then
    Autorun:= not Autorun;

  // MouseLookChangeKey
  if _CurrentScreen^ <> 0 then
    MouseLookChanged:= false
  else if CheckKey(Options.MouseLookChangeKey) then
    MouseLookChanged:= not MouseLookChanged;

  // MouseLook
  if Options.MouseLook then
    ProcessMouseLook;

  // Now time isn't resumed when mouse exits, need to check if it's still pressed
  if _Windowed^ and _RightButtonPressed^ then
    CheckRightPressed;
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
    count:= 40
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
  lea eax, $69BBE8[eax]
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

//----- NoIntro

procedure IntroHook;
asm
  mov ecx, $4EFE74 // "Intro"
  push $4BE671 // ShowMovie
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
var
  member: PChar;
  i: int;
  blaster: Boolean;
begin
  blaster:= false;
  member:= GetCurrentMember;
  i:= pint(member + _CharOff_ItemMainHand)^;
  if (i > 0) then
  begin
    i:= int(member + _CharOff_Items + i*_ItemOff_Size);
    blaster:= (pint(i + $14)^ and 2 = 0) and (pbyte(_ItemsTxt^ + $30*pint(i)^ + $1D)^ = 7);
  end;
  i:= _Character_GetWeaponDelay(0, 0, member, shoot and not blaster);
  if (i < 30) and not (shoot or blaster) then
    i:= 30;
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

//----- Attacking big monsters D3D

var
  SpriteD3DPoints: array[0..9] of single;

function VisibleSpriteD3DProc(p: psingle; var count: int):psingle;
const
  vx1 = pint($F8BA94);
  vy1 = pint($F8BA98);
  vx2 = pint($F8BA9C);
  vy2 = pint($F8BAA0);
var
  i: int;
  x1, x2, y1, y2: single;
begin
  Result:= p;
  y1:= p^;
  y2:= p^;
  dec(p);
  x1:= p^;
  x2:= p^;
  inc(p, 8);
  for i:= 1 to 3 do
  begin
    if p^ < x1 then  x1:= p^;
    if p^ > x2 then  x2:= p^;
    inc(p);
    if p^ < y1 then  y1:= p^;
    if p^ > y2 then  y2:= p^;
    inc(p, 7);
  end;
  x1:= max(x1, vx1^ + 0.1);
  x2:= min(x2, vx2^ - 0.1);
  y1:= max(y1, vy1^ + 0.1);
  y2:= min(y2, vy2^ - 0.1);
  if (x1 > x2) or (y1 > y2) then
  begin
    count:= 3;  // just check 1 point
    exit;
  end;
  dec(count);  // 5 points instead of 4
  SpriteD3DPoints[0]:= (x1 + x2)/2;
  SpriteD3DPoints[1]:= (y1 + y2)/2;
  SpriteD3DPoints[2]:= x1;
  SpriteD3DPoints[3]:= y1;
  SpriteD3DPoints[4]:= x1;
  SpriteD3DPoints[5]:= y2;
  SpriteD3DPoints[6]:= x2;
  SpriteD3DPoints[7]:= y1;
  SpriteD3DPoints[8]:= x2;
  SpriteD3DPoints[9]:= y2;
  Result:= @SpriteD3DPoints[1];
end;

procedure VisibleSpriteD3DHook;
asm
  lea eax, dword ptr $EF5144[esi]
  lea edx, [ebp + $C]  // number of points
  jmp VisibleSpriteD3DProc
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

function Power2(n: int):int;
begin
  Result:= 1;
  while Result < n do
    Result:= Result*2;
end;

function FindSprite(Name: PChar): PSprite;
var
  i: int;
begin
  i:= pint(_SpritesLod + $EC9C)^;
  Result:= @Sprites;
  while (i > 0) and (_strcmpi(@Result.Name, Name) <> 0) do
  begin
    inc(Result);
    dec(i);
  end;
  if i = 0 then
    Result:= nil;
end;

procedure LoadPaletteD3D(var pal; PalIndex: int);
var
  i: int;
  p, p1: PWordArray;
begin
  PalIndex:= _LoadPalette(0, 0, $80D018, PalIndex);
  p:= @pal;
  p1:= ptr($8DE618 + PalIndex*32*256*2);
  if _GreenColorBits^ = 6 then
    for i := 0 to 255 do
      p[i]:= p1[i] and $1F + (p1[i] and $FFC0) shr 1 + $8000
  else
    for i := 0 to 255 do
      p[i]:= p1[i] or $8000;
end;

function LoadSpriteD3DHook(Name: PChar; PalIndex: int): PHwlBitmap; stdcall;
var
  sprite: PSprite;
  i, j, x1, x2, y1, y2: int;
  pal: array[0..255] of word;
  p: pword;
begin
  Result:= nil;
  sprite:= FindSprite(Name);
  if sprite = nil then
    exit;

  with sprite^ do
  begin
    Result:= _new(SizeOf(THwlBitmap));
    //ZeroMemory(Result, SizeOf(THwlBitmap)); // now done always
    // Find area bounds
    x1:= w;
    x2:= -1;
    y1:= -1;
    y2:= -1;
    for i := 0 to h - 1 do
      with Lines[i] do
        if a1 >= 0 then
        begin
          if y1 < 0 then  y1:= i;
          y2:= i;
          if a1 < x1 then  x1:= a1;
          if a2 > x2 then  x2:= a2;
        end;
    with Result^ do
    begin
      FullW:= w;
      FullH:= h;
      if y1 < 0 then  exit;
      // Area dimensions must be powers of 2
      inc(x2);
      inc(y2);
      BufW:= Power2(x2 - x1);
      BufH:= Power2(y2 - y1);
      AreaW:= BufW;
      AreaH:= BufH;
      x1:= (x1 + x2 - BufW) div 2;
      //x1:= IntoRange(x1, 0, w - BufW);
      x2:= x1 + BufW - 1;
      y1:= (y1 + y2 - BufH) div 2;
      //y1:= IntoRange(y1, 0, h - BufH);
      y2:= y1 + BufH - 1;
      AreaX:= x1;
      AreaY:= y1;

      // Get Palette
      LoadPaletteD3D(pal, PalIndex);
      pal[0]:= 0;

      // Render
      Buffer:= _new(BufW*BufH*2);
      //ZeroMemory(Buffer, BufW*BufH*2); // now done always
      p:= Buffer;
      for i := y1 to y2 do
        with Lines[i] do
          if (i >= 0) and (i < h) and (a1 >= 0) then
          begin
            inc(p, a1 - x1);
            for j := 0 to a2 - a1 do
            begin
              p^:= pal[ord((pos + j)^)];
              inc(p);
            end;
            inc(p, x2 - a2);
          end else
            inc(p, BufW);
      PropagateIntoTransparent(Buffer, BufW, BufH);
    end;
  end;
end;

procedure LoadSpriteD3DHook2;
asm
  inc dword ptr [esi+0EC9Ch]
  push $4ACA1E
  push $4A4FD8
  ret
end;

var
  HaveIt: Boolean; // found sprite by name, but palette don't match

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

//----- Take sprite contour into account when clicking it

type
  TDrawSprite = packed record
    Texture: ptr;
    VertNum: int;
    Vert: array[0..3] of TD3DTLVertex;
    // ...
  end;

var
  SpriteD3DHitStd: function(var draw: TDrawSprite; x, y: single): LongBool; stdcall;

function FindSpriteD3D(texture: ptr): PSpriteD3D;
var
  i: int;
begin
  i:= pint(_SpritesLod + $EC9C)^ - 1;
  Result:= pptr(_SpritesLod + $ECB0)^;
  while (i > 0) and (Result.Texture <> texture) do
  begin
    inc(Result);
    dec(i);
  end;
  if i = 0 then
    Result:= nil;
end;

function SpriteD3DHitHook(var draw: TDrawSprite; x, y: single): LongBool; stdcall;
var
  sp3d: PSpriteD3D;
  sp: PSprite;
  drX, drW, drY, drH: Single;
  i, j: int;
begin
  Result:= SpriteD3DHitStd(draw, x, y);
  if not Result then
    exit;

  sp3d:= FindSpriteD3D(draw.Texture);
  if sp3d = nil then
    exit;
  with draw do
  begin
    drX:= Vert[0].sx;
    drW:= Vert[3].sx - drX;
    drY:= Vert[0].sy;
    drH:= Vert[1].sy - drY;
  end;
  i:= sp3d.AreaX + Round(sp3d.AreaW * (x - drX) / drW);
  j:= sp3d.AreaY + Round(sp3d.AreaH * (y - drY) / drH);
  sp:= FindSprite(sp3d.Name);
  if (sp = nil) or (sp.Lines = nil) then
    exit;

  Result:= false;
  if (j < 0) or (j >= sp.h) then  exit;
  with sp.Lines[j] do
  begin
    if (a1 < 0) or (i > a2) or (i < a1) then  exit;
    Result:= ((pos + i - a1)^ <> #0);
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
  i:= (n + $FFF) and not $FFF;
  Result:= VirtualAlloc(nil, i + $1000, MEM_RESERVE, PAGE_NOACCESS);
  VirtualAlloc(Result, i, MEM_COMMIT, PAGE_EXECUTE_READWRITE);
  inc(PChar(Result), i - n);
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

//----- Fix general.txt parsing out-of-bounds

procedure GlobalTxtHook;
asm
  cmp [esp + $1C], $5E4A94
  jnl @exit
  push $4CC17B
@exit:
end;

//----- Fix spells.txt parsing out-of-bounds

procedure SpellsTxtHook;
asm
  cmp [esp + $1C], ($4E4416 - $14)
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

//----- No HWL for bitmaps

function LoadBitmapD3DHook(n1, n2, this, PalIndex: int; Name: PChar): PHwlBitmap;
var
  bmp: TLodBitmap;
  f: ptr;
  pack: array of Byte;
  p: PWordArray;
  p1: PByteArray;
  pal: array[0..255] of Word;
  i, c: int;
begin
  Result:= nil;
  f:= _LodFind(0, 0, _BitmapsLod, 0, Name);
  if f = nil then
    exit;

  _fread(bmp, 1, $30, f); // read bitmap header
  Result:= _new(SizeOf(THwlBitmap));
  ZeroMemory(Result, SizeOf(THwlBitmap));
  with bmp, Result^ do
  begin
    FullW:= w;
    FullH:= h;
    AreaW:= w;
    AreaH:= h;
    BufW:= w;
    BufH:= h;
    Buffer:= _new(BmpSize*2);
    p:= Buffer;
    p1:= Buffer;
    // Read bitmap data
    if UnpSize <> 0 then
    begin
      SetLength(pack, DataSize);
      _fread(pack[0], 1, DataSize, f);
      _Deflate(0, @UnpSize, p1^, DataSize, pack[0]);
      pack:= nil;
    end else
      _fread(p1^, 1, DataSize, f);

    // Get Palette
    c:= 0;
    _fread(c, 1, 3, f);  // check first color
    LoadPaletteD3D(pal, Palette);
    if (c = $FFFF00) or (c = $FF00FF) or (c = $FC00FC) or (c = $FCFC00) then
      pal[0]:= 0;  // Margenta/light blue for transparency

    // Render
    for i := BmpSize - 1 downto 0 do
      p[i]:= pal[p1[i]];
    if pal[0] = 0 then
      PropagateIntoTransparent(p, w, h);
  end;
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

//----- Mouse look

const
  MLSideX = 640 - (8*2 + 460);
  MLSideY = 480 - (8*2 + 344);
var
  MiddleX, MiddleY, MLookPartX, MLookPartY: int;
  MWndPos, MLastPos, MLookTempPos: TPoint;
  MLookStartTime: DWORD;
  EmptyCur, ArrowCur: HCURSOR;
  MouseLookOn, MLookIsTemp: Boolean;

function CursorPos:PPoint;
begin
  Result:= PPoint(PPChar($720808)^ + $108);
end;

function GetMLookPoint(var p: TPoint): BOOL;
begin
  if MouseLookOn then
  begin
    CursorPos^:= Point(MiddleX, MiddleY);
    p:= MWndPos;
    ClientToScreen(_MainWindow^, p);
    Result:= true;
  end else
    Result:= GetCursorPos(p);
end;

procedure CheckMouseLook;
const
  myAnd: int = -1;
  myXor: int = 0;
var
  cur: HCURSOR;
  r: TRect;
begin
  if SkipMouseLook then  // a hack for right-then-left click combo
  begin
    SkipMouseLook:= false;
    exit;
  end;
  GetClientRect(_MainWindow^, r);
  NeedScreenWH;
  // compatibility with resolution patches like mmtool's one
  MiddleX:= (SW - MLSideX) div 2;
  MiddleY:= (SH - MLSideY) div 2;
  // compatibility with Angel's resolution mod
  MWndPos.X:= (MiddleX*r.Right + SW - 1) div SW;
  MWndPos.Y:= (MiddleY*r.Bottom + SH - 1) div SH;

  if ArrowCur = 0 then
    ArrowCur:= LoadCursor(GetModuleHandle(nil), 'Arrow');
  if EmptyCur = 0 then
    EmptyCur:= CreateCursor(GetModuleHandle(nil), 0, 0, 1, 1, @myAnd, @myXor);
  cur:= GetClassLong(_MainWindow^, -12);
  with Options do
    MouseLookOn:= MouseLook and (_CurrentScreen^ = 0) and (_MainMenuCode^ = -1) and
       ((cur = EmptyCur) or (cur = ArrowCur)) and not MLookRightPressed^ and
       ( (GetAsyncKeyState(MouseLookTempKey) and $8000 = 0) xor
          MouseLookChanged xor MouseLookUseAltMode xor
          (CapsLockToggleMouseLook and (GetKeyState(VK_CAPSLOCK) and 1 <> 0)));

  if MouseLookOn <> (cur = EmptyCur) then
  begin
    if not MouseLookOn then
    begin
      SetClassLong(_MainWindow^, -12, ArrowCur);
      _NeedRedraw^:= 1;
    end else
      SetClassLong(_MainWindow^, -12, EmptyCur);

    if MLookIsTemp or not MouseLookOn and not MLookRightPressed^ and
       (GetTickCount - MLookStartTime < MouseLookRememberTime) then
    begin
      MLastPos:= MLookTempPos;
      MLookIsTemp:= false;
    end else
    begin
      GetMLookPoint(MLastPos);
      if MouseLookOn then
      begin
        MLookIsTemp:= GetAsyncKeyState(Options.MouseLookTempKey) and $8000 <> 0;
        GetCursorPos(MLookTempPos);
        MLookStartTime:= GetTickCount;
      end;
    end;

    SetCursorPos(MLastPos.X, MLastPos.Y);
  end;
end;

procedure ProcessMouseLook;

  function Partial(move: int; var part: int; factor: int): int;
  var
    x: int;
  begin
    x:= part + move*factor;
    Result:= (x + 32) and not 63;
    part:= x - Result;
    Result:= Result div 64;
  end;

const
  dir = _Party_Direction;
  angle = _Party_Angle;
  AngleLim = 180;
var
  p: TPoint;
  speed: PPoint;
begin
  CheckMouseLook;
  GetCursorPos(p);
  if MouseLookOn and (GetForegroundWindow = _MainWindow^) then
  begin
    if MLookIsTemp then
      speed:= @MLookSpeed2
    else
      speed:= @MLookSpeed;
    dir^:= (dir^ - Partial((p.X - MLastPos.X), MLookPartX, speed.X)) and 2047;
    angle^:= IntoRange(angle^ - Partial((p.Y - MLastPos.Y), MLookPartY, speed.Y),
      -Options.MaxMLookAngle, Options.MaxMLookAngle);
    if (p.X <> MLastPos.X) or (p.Y <> MLastPos.Y) then
    begin
      p:= MWndPos;
      ClientToScreen(_MainWindow^, p);
      SetCursorPos(p.X, p.Y);
    end;
  end;
  MLastPos:= p;
end;

procedure MouseLookHook(p: TPoint); stdcall;
begin
  CheckMouseLook;
  if MouseLookOn then
    CursorPos^:= Point(MiddleX, MiddleY)
  else
    CursorPos^:= p;
end;

function MouseLookHook2(var p: TPoint): BOOL; stdcall;
begin
  CheckMouseLook;
  Result:= GetMLookPoint(p);
end;

var
  MouseLookHook3Std: procedure(a1, a2, this: ptr);
  MLookBmp: TBitmap;

procedure MLookLoad;
const
  CurFile = 'Data\MouseLookCursor.bmp';
var
  b: TBitmap;
  exist: Boolean;
begin
  MLookBmp:= TBitmap.Create;
  with MLookBmp, Canvas do
  begin
    if _GreenColorBits^ = 5 then
      PixelFormat:= pf15bit
    else
      PixelFormat:= pf16bit;
    HandleType:= bmDIB;
    b:= nil;
    exist:= FileExists(CurFile);
    if exist then
      try
        b:= TBitmap.Create;
        b.LoadFromFile(CurFile);
        Width:= b.Width;
        Height:= b.Height;
        CopyRect(ClipRect, b.Canvas, ClipRect);
        b.Free;
        exit;
      except
        RSShowException;
        b.Free;
      end;

    Width:= 64;
    Height:= 64;
    Brush.Color:= $F0A0B0;
    FillRect(ClipRect);
    DrawIconEx(Handle, 32, 32, ArrowCur, 0, 0, 0, 0, DI_DEFAULTSIZE or DI_NORMAL);
    if not exist then
      try
        SaveToFile(CurFile);
      except
      end;
  end;
end;

procedure MLookDraw;
var
  p1, p2: PChar;
  x, y, w, h, d1, d2: int;
  k, trans: Word;
begin
  if MLookBmp = nil then
    MLookLoad;
  w:= MLookBmp.Width;
  h:= MLookBmp.Height;
  p1:= MLookBmp.ScanLine[0];
  d1:= PChar(MLookBmp.ScanLine[1]) - p1 - 2*w;
  p2:= PPChar($E31B54)^ + 2*(_ScreenW^*(MiddleY - h div 2) + MiddleX - w div 2);
  d2:= 2*(_ScreenW^ - w);
  trans:= pword(p1)^;
  for y := 1 to h do
  begin
    for x := 1 to w do
    begin
      k:= pword(p1)^;
      if k <> trans then
        pword(p2)^:= k;
      inc(p1, 2);
      inc(p2, 2);
    end;
    inc(p1, d1);
    inc(p2, d2);
  end;
end;

procedure MouseLookHook3(a1, a2, this: ptr);
begin
  CheckMouseLook;
  if MouseLookOn and not MLookIsTemp then
    MLookDraw;

  MouseLookHook3Std(nil, nil, this);
end;

//----- A beam of Prismatic Light in the center of screen that doesn't disappear

var
  FixPrismaticBugStd: function(size, unk: uint):ptr cdecl;

function FixPrismaticBug(size, unk: uint):ptr; cdecl;
begin
  Result:= FixPrismaticBugStd(size, unk);
  ZeroMemory(Result, size);
end;

//----- Window procedure hook

//function MulDiv

procedure WindowProcStdImpl;
asm
  push ebp
  mov ebp, esp
  sub esp, $48
  push $46382E
end;

var
  WindowProcStd: function(w: HWND; msg: uint; wp: WPARAM; lp: LPARAM):HRESULT; stdcall;

procedure CalcClientRect(var r: TRect);
var
  w, h: int;
begin
  w:= r.Right - r.Left;
  h:= r.Bottom - r.Top;
  NeedScreenWH;
  if BorderlessProportional then
  begin
    w:= w div SW;
    h:= min(w, h div SH);
    w:= h*SW;
    h:= h*SH;
  end else
    if w*SH >= h*SW then
      w:= (h*SW + SH div 2) div SH
    else
      h:= (w*SH + SW div 2) div SW;
  dec(w, r.Right - r.Left);
  dec(r.Left, w div 2);
  dec(r.Right, w div 2 - w);
  dec(h, r.Bottom - r.Top);
  dec(r.Top, h div 2);
  dec(r.Bottom, h div 2 - h);
end;

procedure PaintBorders(wnd: HWND; wp: int);
var
  dc: HDC;
  r, rc, r1: TRect;
begin
  GetWindowRect(wnd, r);
  GetClientRect(wnd, rc);
  MapWindowPoints(wnd, 0, rc, 2);
  OffsetRect(rc, -r.Left, -r.Top);
  OffsetRect(r, -r.Left, -r.Top);
  dc:= GetWindowDC(wnd);//GetDCEx(wnd, wp, DCX_WINDOW or DCX_INTERSECTRGN);

  r1:= Rect(0, 0, r.Right, rc.Top); // top
  FillRect(dc, r1, GetStockObject(BLACK_BRUSH));
  r1:= Rect(0, rc.Top, rc.Left, rc.Bottom); // left
  FillRect(dc, r1, GetStockObject(BLACK_BRUSH));
  r1:= Rect(rc.Right, rc.Top, r.Right, rc.Bottom); // right
  FillRect(dc, r1, GetStockObject(BLACK_BRUSH));
  r1:= Rect(0, rc.Bottom, r.Right, r.Bottom); // bottom
  FillRect(dc, r1, GetStockObject(BLACK_BRUSH));

  ReleaseDC(wnd, dc);
end;

procedure MyClipCursor;
var
  r: TRect;
begin
  GetClientRect(_MainWindow^, r);
  MapWindowPoints(_MainWindow^, 0, r, 2);
  ClipCursor(@r);
end;

function WindowProcHook(w: HWND; msg: uint; wp: WPARAM; lp: LPARAM):HRESULT; stdcall;
const
  CommandsArray = $721458;
  AddCommand: procedure(a1, a2, this, cmd: int) = ptr($4760C5);
var
  xy: TSmallPoint absolute lp;
  r: TRect;
begin
  if _Windowed^ and (msg = WM_ERASEBKGND) then
  begin
    GetClientRect(w, r);
    Result:= FillRect(wp, r, GetStockObject(BLACK_BRUSH));
    exit;
  end;
  if _Windowed^ and (msg >= WM_MOUSEFIRST) and (msg <= WM_MOUSELAST) then
    with xy do
    begin
      NeedScreenWH;
      GetClientRect(_MainWindow^, r);
      x:= MulDiv(x, SW, r.Right);
      y:= MulDiv(y, SH, r.Bottom);
    end;

  Result:= WindowProcStd(w, msg, wp, lp);

  if (msg = WM_MOUSEWHEEL) and Options.MouseWheelFly then
    if wp < 0 then
      AddCommand(0, 0, CommandsArray, 14)
    else
      AddCommand(0, 0, CommandsArray, 13);

  if not Options.BorderlessWindowed and IsZoomed(w) then
    case msg of
      WM_ACTIVATEAPP:
        if wp = 0 then
        begin
          ClipCursor(nil);
//          ShowWindow(_MainWindow^, SW_MINIMIZE);
        end else
          MyClipCursor;
      WM_SYSCOMMAND:
        if wp and $FFF0 = SC_RESTORE then
          MyClipCursor;
      WM_NCCALCSIZE:
        if wp <> 0 then
          with PNCCalcSizeParams(lp)^ do
          begin
            CalcClientRect(rgrc[0]);
            Result:= WVR_REDRAW;
          end
        else
          CalcClientRect(PRect(lp)^);
      WM_NCPAINT:
        PaintBorders(w, wp);
    end;

  if Options.SupportTrueColor and (msg = WM_SIZE) then
    DXProxyOnResize;
end;

//----- Fly in Z axis with mouse

procedure MouseLookFlyProc(var v: TPoint; ebp: PChar);
const
  MaxH = 4000;
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
  if (dz > 0) and (pint(ebp + z)^ + dz > MaxH) then
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
var
  mode: TDevMode;
begin
  if Options.SupportTrueColor then
  begin
    if not _IsD3D^ then  exit;
    if (GetDeviceCaps(GetDC(0), BITSPIXEL) = 32) and (GetDeviceCaps(GetDC(0), PLANES) = 1) then  exit;
  end;
  if (GetDeviceCaps(GetDC(0), BITSPIXEL) <> 16) or (GetDeviceCaps(GetDC(0), PLANES) <> 1) then
    with mode do
    begin
      dmSize:= SizeOf(mode);
      dmBitsPerPel:= 16;
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

//----- Show accurate errors of D3DInit

procedure BetterD3DInitErrorsHook;
asm
  mov eax, [esi + 40088h]
  lea eax, [eax + 48h]
  xchg eax, [esp]
  jmp eax
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
  Result:= DoLoadCustomLod(Old, Name, Old + LodChapOff);
end;

function FreeCustomLod(Lod: ptr): Boolean; stdcall;
var
  i: int;
begin
  for i := high(CustomLods) downto 0 do
    if CustomLods[i].Mine = Lod then
    begin
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

procedure LoadCustomLods(Old: int; Name: string; Chap: PChar);
begin
  with TRSFindFile.Create('Data\*.' + Name) do
    try
      while FindNextAttributes(0, FILE_ATTRIBUTE_DIRECTORY) do // Only files
        DoLoadCustomLod(ptr(Old), PChar('Data\' + Data.cFileName), Chap);
    finally
      Free;
    end;
end;

var
  LoadLodsOld: TProcedure;

// OnStart, just before loading any data
procedure LoadLodsHook;
begin
  LoadCustomLods($6D0490, 'icons.lod', 'icons');
  LoadCustomLods($6BE8D8, 'events.lod', 'icons');
  LoadCustomLods($6F0D00, 'bitmaps.lod', 'bitmaps');
  LoadCustomLods($6E2048, 'sprites.lod', 'sprites08');
  LoadCustomLods($6A08E0, 'games.lod', 'chapter');
  LoadLodsOld;
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

//----- Called whenever time is resumed

procedure ClearKeyStatesHook;
var
  i: int;
begin
  for i := 1 to 255 do
    MyGetAsyncKeyState(i);
  GetCursorPos(MLastPos);
end;

//----- Save game bug in Windows Vista and higher (bug of OS or other software)

procedure SaveGameBugHook(old, new: PChar); cdecl;
begin
  while not MoveFile(old, new) do
  begin
    Sleep(1);
    DeleteFileA(new);
  end;
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

//----- Fix chests: reorder to preserve important items

procedure FixChestSmartProc(p: PChar);
const
  size = _ItemOff_Size;
var
  i, j: int;
begin
  with TStringList.Create do
    try
      CaseSensitive:= true;
      Sorted:= true;
      for i:= 0 to 139 do
        if pint(p + i*size)^ <> 0 then
          AddObject(IntToHex(byte(min(1, pint(p + i*size)^)), 2) + IntToHex(i, 2), ptr(i));

      if (Count = 0) or (Strings[Count - 1][1] = '0') then  // no random items
        exit;

      // sorted: fixed items, artifacts, i6, i5, ..., i1
      for i:= 0 to Count - 1 do
      begin
        j:= int(Objects[i]);
        if j > i then  // source item isn't erased yet
        begin
          CopyMemory(p + i*size, p + j*size, size);
          ZeroMemory(p + j*size, size);
        end
        else if j < i then  // random item
        begin
          ZeroMemory(p + i*size, size);
          pint(p + i*size)^:= StrToInt('$' + copy(Strings[i], 1, 2)) - 256;
        end;
      end;
    finally
      Free;
    end;
end;

procedure FixChestSmartHook;
asm
  mov [esp + $28], $8C
  mov eax, ebx
  call FixChestSmartProc
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
  mov eax, [_Party_Height]
  // push Party_Height
  push eax
  // Party_Height = Party_Height*3/2
  sar eax, 1
  lea eax, [eax + eax*2]
  mov [_Party_Height], eax
  // call <std>
  push [esp + 3*4]
  push [esp + 3*4]
  call std
  // restore Party_Height
  pop ecx
  mov [_Party_Height], ecx
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
var
  r: TRect;
begin
  Result:= ScreenToClient(w, p);
  if Result then
    with p do
    begin
      NeedScreenWH;
      GetClientRect(_MainWindow^, r);
      x:= MulDiv(x, SW, r.Right);
      y:= MulDiv(y, SH, r.Bottom);
    end;
end;

//----- Borderless fullscreen (also see WindowProcHook)

procedure SwitchToWindowedHook;
begin
  Options.BorderlessWindowed:= true;
//  SetWindowPos(_MainWindow^, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE + SWP_NOSIZE);
  ShowWindow(_MainWindow^, SW_SHOWNORMAL);
  SetWindowLong(_MainWindow^, GWL_STYLE, GetWindowLong(_MainWindow^, GWL_STYLE) or _WindowedGWLStyle^);
end;

procedure SwitchToFullscreenHook;
begin
  Options.BorderlessWindowed:= false;
//  SetWindowPos(_MainWindow^, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE + SWP_NOSIZE);
  ShowWindow(_MainWindow^, SW_SHOWMAXIMIZED);
  BringWindowToTop(_MainWindow^);
  MyClipCursor;
end;

//----- Compatible movie render

var
  ScreenDraw: TBitmap; ScreenDrawScanline: ptr;
  Scale640, Scale320: TRSResampleInfo;
  SmkBmp: TBitmap; SmkScanline: ptr; SmkPixelFormat: TPixelFormat;

procedure NeedScreenDraw(var scale: TRSResampleInfo; sw, sh, w, h: int);
begin
  w:= max(w, sw);
  h:= max(h, sh);
  if (scale.DestW <> w) or (scale.DestH <> h) then
  begin
    RSSetResampleParams(1.3);
    scale.Init(SW, SH, w, h);
    if ScreenDraw = nil then
      ScreenDraw:= TBitmap.Create
    else
      ScreenDraw.Height:= 0;
    with ScreenDraw do
    begin
      PixelFormat:= pf32bit;
      HandleType:= bmDIB;
      Width:= w;
      Height:= -h;
      ScreenDrawScanline:= Scanline[h-1];
      if PChar(Scanline[0]) - ScreenDrawScanline < 0 then
        ScreenDrawScanline:= Scanline[0];
    end;
  end;
end;

procedure DrawScaled(var scale: TRSResampleInfo; sw, sh: int; scan: ptr; pitch: int);
var
  r: TRect;
  dc: HDC;
begin
  GetClientRect(_MainWindow^, r);
  NeedScreenDraw(scale, sw, sh, r.Right, r.Bottom);
  RSResample16(scale, scan, pitch, ScreenDrawScanline, scale.DestW*4);
  dc:= GetDC(_MainWindow^);
  if (scale.DestW = r.Right) and (scale.DestH = r.Bottom) then
    BitBlt(dc, 0, 0, scale.DestW, scale.DestH, ScreenDraw.Canvas.Handle, 0, 0, cmSrcCopy)
  else
    StretchBlt(dc, 0, 0, r.Right, r.Bottom, ScreenDraw.Canvas.Handle, 0, 0, scale.DestW, scale.DestH, cmSrcCopy);
  ReleaseDC(_MainWindow^, dc);
end;

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

//----- 32 bit color support (Direct3D)

procedure TrueColorHook;
asm
  lea edx, [ebp - $98]
  cmp dword ptr [edx + $54], 32
  jnz @std
  mov dword ptr [esp], $4A5AE7
  jmp DXProxyDraw
@std:
end;

function MakePixel16(c32: int): Word;
asm
  ror eax, 8
  shr ah, 3
  shr ax, 2
  rol eax, 5
end;

var
  LockSurface: function(surf: ptr; info: PDDSurfaceDesc2; param: int): LongBool; stdcall;
  ShotBuf: array of Word;

procedure DoTrueColorShot(info: PDDSurfaceDesc2; ps: PWord; w, h: int; const r: TRect);
var
  pd: PChar;
  x, y, pitch, wd, hd: int;
begin
  wd:= r.Right - r.Left;
  hd:= r.Bottom - r.Top;
  pd:= info.lpSurface;
  pitch:= info.lPitch;
  inc(pd, (r.Top + hd div (2*h))*pitch + (r.Left + wd div (2*w))*4);
  for y:= 0 to h - 1 do
    for x:= 0 to w - 1 do
    begin
      ps^:= MakePixel16(pint(pd + (x*wd div w)*4 + (y*hd div h)*pitch)^);
      inc(ps);
    end;
end;

procedure TrueColorShotProc(info: PDDSurfaceDesc2; ps: PWord; w, h: int);
begin
  DoTrueColorShot(info, ps, w, h, DXProxyScaleRect(Options.RenderRect));
end;

procedure TrueColorShotHook;
asm
  lea eax, [ebp - $A0]  // info
  cmp dword ptr [eax + $54], 32
  jnz @std
  mov ecx, [ebp - $10]  // h
  mov [esp], ecx
  mov ecx, [ebp - $4]  // w
  mov edx, ebx  // ps
  push $45E1B6
  jmp TrueColorShotProc
@std:
end;

function TrueColorLloydHook(surf: ptr; info: PDDSurfaceDesc2; param: int): LongBool; stdcall;
begin
  Result:= LockSurface(surf, info, param);
  if not Result or (info.ddpfPixelFormat.dwRGBBitCount <> 32) then  exit;
  NeedScreenWH;
  SetLength(ShotBuf, SW*SH);
  DoTrueColorShot(info, ptr(ShotBuf), SW, SH, Rect(0, 0, SW, SH));
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

//----- Buka localization

var
  _sprintfex: ptr;

//----- HooksList

var
  HooksList: array[1..287] of TRSHookInfo = (
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
    (p: $4A95C6; old: $4A9550; new: $4A9595; t: RSht4; Querry: 3), // No death movie
    (p: $4A95B2; old: $4A950F; new: $4A9595; t: RSht4; Querry: 2), // No intro: 3dologo
    (p: $4A95B6; old: $4A951C; new: $4A9595; t: RSht4; Querry: 2), // No intro: new world logo
    (p: $4A95BA; old: $4A9529; new: $4A9595; t: RSht4; Querry: 2), // No intro: jvc
    (p: $4A95C2; old: $4A9536; new: $4A9595; t: RSht4; Querry: 2), // No intro: Intro
    (p: $4A953C; newp: @IntroHook; t: RShtCall; size: 7; Querry: 2), // No intro: Intro Post
    (p: $4A95BE; old: $4A9543; new: $4A9536; t: RSht4; Querry: 2), // No intro: Intro Post - include Intro too
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
    (p: $4C0A23; newp: @VisibleSpriteD3DHook; t: RShtCall; size: 6), // Attacking big monsters D3D
    (p: $4C0B31; old: $20; new: 8; t: RSht1), // Attacking big monsters D3D
    (p: $4A4FF1; old: $452504; newp: @LoadSpriteD3DHook; t: RShtCall), // No HWL for sprites
    (p: $4ACA13; old: $4A4FD8; newp: @LoadSpriteD3DHook2; t: RShtJmp), // No HWL for sprites
    (p: $4AC8CD; old: $4AC98A; newp: @LoadSpriteD3DHook3; t: RShtCall), // No HWL for sprites
    (p: $4AC768; old: $4AC851; newp: @LoadSpriteD3DHook4; t: RShtJmp6), // No HWL for sprites
    (p: $49EAE8; size: 16), // No HWL for sprites
    (p: $49EB49; size: 5), // No HWL for sprites
    (p: $4C1508; old: $4C1579; backup: @@SpriteD3DHitStd; newp: @SpriteD3DHitHook; t: RShtCall), // Take sprite contour into account when clicking it
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
    (p: $49AC92; newp: @NoVertexFacetHook; t: RShtCall), // There may be facets without vertexes
    (p: $4A4D93; old: $452504; newp: @LoadBitmapD3DHook; t: RShtCall; Querry: 13), // No HWL for bitmaps
    (p: $49EAE3; old: $4523AB; new: $45246B; t: RShtCall; Querry: 13), // No HWL for bitmaps
    (p: $49EB3B; size: 5; Querry: 13), // No HWL for bitmaps
    (p: $48A5B9; newp: @PalettesHook; t: RShtCall), // Get rid of palettes limit in D3D
    (p: $46A364; newp: ptr($46A38C); t: RShtJmp), // Ignore 'Invalid ID reached!'
    (p: $44EC22; newp: ptr($44EC4A); t: RShtJmp), // Ignore 'Sprite outline currently Unsupported'
    (p: $46A1A9; old: $46A338; backup: @@PressSpaceStd; newp: @PressSpaceHook; t: RShtCall), // D3D better space reaction
    (p: $449AC3; newp: @DoorStateSwitchHook; t: RShtCall), // Correct door state switching: param = 3
    (p: $46A08E; newp: @MouseLookHook; t: RShtJmp; size: 10), // Mouse look
    (p: $4D825C; newp: @MouseLookHook2; t: RSht4), // Mouse look
    (p: $4160C5; backup: @@MouseLookHook3Std; newp: @MouseLookHook3; t: RShtCall), // Mouse look
    (p: $42FE25; newp: @StrafeOrWalkHook; t: RShtCall; size: 6; Querry: 15), // Strafe in MouseLook
    (p: $42FEA5; newp: @StrafeOrWalkHook; t: RShtCall; size: 6; Querry: 15), // Strafe in MouseLook
    (p: $4CB071; backup: @@FixPrismaticBugStd; newp: @FixPrismaticBug; t: RShtCall), // A beam of Prismatic Light in the center of screen that doesn't disappear
    (p: $463828; newp: @WindowProcHook; t: RShtJmp; size: 6), // Window procedure hook
    (p: $474300; newp: @MouseLookFlyHook1; t: RShtCall), // Fix strafes and walking rounding problems
    (p: $47303C; newp: @MouseLookFlyHook2; t: RShtCall), // Fix strafes and walking rounding problems
    (p: $41F312; newp: @IDMonHook; t: RShtCall; size: 6), // Show resistances of monster
    (p: $4178C5; newp: @StatColorFixHook; t: RShtCall; size: 7), // negative/0 causes a crash in stats screen
    (p: $45A994; newp: @FixKeyConfigHook; t: RShtCall), // Fix keys configuration loading
    (p: $4D8868; newp: @Options.PaletteSMul; newref: true; t: RSht4; Querry: -1), // Control palette gamma
    (p: $4D886C; newp: @Options.PaletteVMul; newref: true; t: RSht4; Querry: -1), // Control palette gamma
    (p: $411C1E; old: $411AB6; backup: @@TPFixStd; newp: @TPFixHook; t: RShtCall), // Pause the game in Town Portal screen
    (p: $465B9E; newp: @DefaultSmoothTurnHook; t: RShtCall), // Use Smooth turn rate by default
    (p: $493917; old: $48E8ED; newp: @FixWaitHook; t: RShtCall), // Waiting used to recover characters twice as fast
    (p: $4636E4; old: $4CAC80; newp: @FixLeaveMapDieHook; t: RShtCall), // Was no LeaveMap event on death
    (p: $432E63; newp: @FixLeaveMapWalkHook; t: RShtCall), // Was no LeaveMap event with walk travel
    (p: $4D8260; newp: @MyGetAsyncKeyState; t: RSht4), // Don't rely on bit 1 of GetAsyncKeyState
    (p: $4B6997; old: $492BAE; newp: @TravelGoldFixHook1; t: RShtCall), // Subtract gold after autosave when trevelling
    (p: $4B6AF4; old: $4B1DF5; newp: @TravelGoldFixHook2; t: RShtCall), // Subtract gold after autosave when trevelling
    (p: $46532F; t: RShtNop; size: $11), // Switch to 16 bit color when going windowed
    (p: $49DE88; old: $4CB9C0; backup: @AutoColor16Std; newp: @AutoColor16Hook; t: RShtCall), // Switch to 16 bit color when going windowed
    (p: $4A0987; old: $4A11AC; backup: @AutoColor16Std2; newp: @AutoColor16Hook2; t: RShtCall), // Switch to 16 bit color when going windowed
    (p: $4A0662; newp: @BetterD3DInitErrorsHook; t: RShtCall), // Show accurate errors of D3DInit
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
    (p: $459E78; newp: @ClearKeyStatesHook; t: RShtJmp; size: 6), // Clear my keys as well
    (p: $461EFF; newp: @SaveGameBugHook; t: RShtCall), // Save game bug in Windows Vista and higher (bug of OS or other software)
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
    (p: $450284; newp: @FixChestSmartHook; t: RShtCall; size: 8; Querry: 19), // Fix chests: reorder to preserve important items
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
    (p: $44FD6F; old: $44FD8A; new: $44FD99; t: RShtJmp2), // Monsters summoning wrong monsters (e.g. Archmages summoning Sylphs)
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
    (p: $465531; newp: @WindowWidth; newref: true; t: RSht4; Querry: hqWindowSize), // Configure window size
    (p: $465546; newp: @WindowHeight; newref: true; t: RSht4; Querry: hqWindowSize), // Configure window size
    (p: $4D8258; newp: @ScreenToClientHook; t: RSht4; Querry: hqWindowSize), // Configure window size
    (p: $465A5F; old: $49FF8B; new: $4A0583; t: RShtCall; Querry: hqBorderless), // Borderless fullscreen
    (p: $465A5F; newp: @SwitchToFullscreenHook; t: RShtAfter; Querry: hqBorderless), // Borderless fullscreen
    (p: $465A0F; newp: @SwitchToWindowedHook; t: RShtAfter; Querry: hqBorderless), // Borderless fullscreen
    (p: $466868; new: $46688B; t: RShtJmp; size: 7; Querry: hqBorderless), // Borderless fullscreen
    (p: $466907; newp: @SwitchToFullscreenHook; t: RShtCall; Querry: hqBorderless), // Borderless fullscreen
    (p: $46690C; new: $466B37; t: RShtJmp; size: 6; Querry: hqBorderless), // Borderless fullscreen
    (p: $46694B; size: 6; Querry: hqBorderless), // Borderless fullscreen
    (p: $466951; old: $4A0583; newp: @SwitchToWindowedHook; t: RShtCall; size: $46696A - $466951; Querry: hqBorderless), // Borderless fullscreen
    (p: $46697C; new: $466B37; t: RShtJmp; size: 6; Querry: hqBorderless), // Borderless fullscreen
    (p: $46688D; old: int(_Windowed); newp: @Options.BorderlessWindowed; t: RSht4; Querry: hqBorderless), // Borderless fullscreen
    (p: $46466E; old: int(_Windowed); newp: @Options.BorderlessWindowed; t: RSht4; Querry: hqBorderless), // Borderless fullscreen
    (p: $464692; old: int(_Windowed); newp: @Options.BorderlessWindowed; t: RSht4; Querry: hqBorderless), // Borderless fullscreen
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
    (p: $4A59A3; newp: @TrueColorHook; t: RShtAfter; size: 6; Querry: hqTrueColor), // 32 bit color support
    (p: $49F1EE; new: $49F20D; t: RShtJmp; size: 6; Querry: hqTrueColor), // 32 bit color support
    (p: $45E14D; newp: @TrueColorShotHook; t: RShtBefore; size: 6; Querry: hqTrueColor), // 32 bit color support
    (p: $49EDF7; old: $4A0ED0; backup: @@LockSurface; newp: @TrueColorLloydHook; t: RShtCall; Querry: hqTrueColor), // 32 bit color support
    (p: $463AA8; size: 6; Querry: hqTrueColor), // 32 bit color support
    (p: $465333; size: 2; Querry: hqTrueColor), // 32 bit color support
    (p: $4D801C; newp: @MyDirectDrawCreate; t: RSht4; Querry: hqTrueColor), // 32 bit color support + HD
    (p: $4A4DA5; size: $4A4DC2 - $4A4DA5; Querry: hqMipmaps), // generate mipmaps
    (p: $4A4ED7; newp: @FixMipmapsMemLeak; t: RShtAfter), // Mipmaps generation code not calling surface->Release
    (p: $41E84B; newp: @FixSpritesInMonInfo; t: RShtBefore; size: 6), // Fix sprites with non-zero transparent colors in monster info dialog
    (p: $41E948; newp: @FixSpritesInMonInfo; t: RShtBefore; size: 5), // Fix sprites with non-zero transparent colors in monster info dialog
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

procedure HookAll;
var
  LastDebugHook: DWord;
  i: int;
begin
  i:= RSCheckHooks(HooksList);
  if i >= 0 then
    raise Exception.CreateFmt(SWrong, [HooksList[i + 1].p]);

  ExtendSpriteLimits;

  ReadDisables;
  RSApplyHooks(HooksList);
  if NoIntro then
    RSApplyHooks(HooksList, 2);
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
  if (WindowWidth <> 640) or (WindowHeight <> 480) or BorderlessFullscreen then
    RSApplyHooks(HooksList, hqWindowSize);
  if BorderlessFullscreen then
    RSApplyHooks(HooksList, hqBorderless);
  if (MipmapsCount > 1) or (MipmapsCount < 0) then
    RSApplyHooks(HooksList, hqMipmaps);

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
  if Options.HardenArtifacts then
    RSApplyHooks(HooksList, 9);
  if Options.ProgressiveDaggerTrippleDamage then
    RSApplyHooks(HooksList, 10);
  if Options.FixChests then
    RSApplyHooks(HooksList, 11);
  if Options.DataFiles then
    RSApplyHooks(HooksList, 12);
  if Options.NoBitmapsHwl then
    RSApplyHooks(HooksList, 13);
  if Options.FixChestsByReorder then
    RSApplyHooks(HooksList, 19);
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
end;

exports
  LoadCustomLod,
  FreeCustomLod,
  GetCustomLodsList,
  GetLodRecords;
initialization
  @PlaySound:= @DoPlaySound;
  @WindowProcStd:= @WindowProcStdImpl;
finalization
  if EmptyCur <> 0 then
    DestroyCursor(EmptyCur);
  // avoid hanging in case of exception on shutdown
  SetUnhandledExceptionFilter(@LastUnhandledExceptionFilter);
end.
