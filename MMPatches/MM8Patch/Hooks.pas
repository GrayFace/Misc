unit Hooks;

interface

uses
  Windows, Messages, SysUtils, Classes, RSSysUtils, RSQ, Common, RSCodeHook,
  Math, MP3, RSDebug, IniFiles, Direct3D, Graphics, MMSystem, RSStrUtils,
  DirectDraw, RSGraphics, DXProxy, RSResample;

procedure HookAll;
procedure ApplyDeferredHooks;

implementation

var
  Autorun: Boolean;
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
  Result:= ptr(_CharactersTable + pint(_PartyMembers + 4*_CurrentMember^)^*_CharOff_Size);
end;

procedure OpenInventory;
const // from 420D69
  NeedRedraw = int(_NeedRedraw);
  CurrentScreen = int(_CurrentScreen);
  CurrentMember = int(_CurrentMember);
  CurrentCharScreen = int(_CurrentCharScreen);
  opNew: int = $4D9E0B;
  c1: int = $4C9679;
  c2: int = $4D1BC7;
  c3: int = $4C9DA8;
  c4: int = $4C9FA2;
var
  v1: ptr;
asm
  mov [NeedRedraw], 1

  push $2E0
  call opNew
  pop ecx

  push -1
  mov ecx, eax
  call c1
  mov v1, eax

  push 0
  push eax
  mov ecx, $1006148
  mov dword ptr [CurrentScreen], 7
  call c2

  mov eax, [CurrentMember]
  push _PartyMembers[eax*4]
  mov ecx, v1
  call c3

  mov eax, [CurrentCharScreen]
  mov ecx, v1
  cmp eax, 100
  jz @s1
  cmp eax, 101
  jz @s0
  sub eax, 100
  push eax
  jmp @call
@s1:
  push 1
  jmp @call
@s0:
  push 0
@call:
  call c4
end;

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

//----- Time isn't resumed when mouse exits, need to check if it's still pressed

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

  // QuickLoad
  if (QuickSavesCount >= 0) and CheckKey(Options.QuickLoadKey) and nopause
     and FileExists('saves\quiksave.dod') then
  begin
    _Paused^:= 1;
    pint($6CAD00)^:= 1;
    _SaveSlotsFiles[0]:= 'quiksave.dod';
    _DoLoadGame(0, 0, 0);
    pint($6CEB28)^:= 3;
  end;

  // InventoryKey
  if CheckKey(Options.InventoryKey) and nopause then
  begin
    if _CurrentMember^ = 0 then
      _CurrentMember^:= 1;
    _CurrentCharScreen^:= 103;
    OpenInventory;
  end;

  // CharScreenKey
  if CheckKey(Options.CharScreenKey) then
    case _CurrentScreen^ of
      0:
        if _Paused^=0 then
        begin
          if _CurrentMember^ = 0 then
            _CurrentMember^:= 1;
          OpenInventory;
        end;
      7:
        _ExitScreen;
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

  // Time isn't resumed when mouse exits, need to check if it's still pressed
  if _Windowed^ and _RightButtonPressed^ then
    CheckRightPressed;
end;

procedure KeysHook;
asm
  call KeysProc
  jmp GetAsyncKeyState
end;

//----- Buggy autosave/quicksave filenames localization

var
  SaveNamesStd: procedure;

procedure SaveNamesHook;
begin
  SaveNamesStd;
  _AutosaveFile^:= 'autosave.dod';
  _QuicksaveFile^:= 'quiksave.dod';
end;

//----- Fix Save/Load Slots

var
  SaveName: string;
  SaveSpecial: string = 'quiksave.dod';
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
  i, slot, count: int;
  name: string;
begin
  name:= SaveName;
  if not save and (SaveSpecial <> '') then
    name:= SaveSpecial;

  if save then
    count:= 20
  else
    count:= _SaveSlotsCount^;

  if name <> '' then
  begin
    slot:= max(count - 1, 0);
    while (slot > 0) and (AnsiStrComp(_SaveSlotsFiles^[slot], ptr(name)) <> 0) do
      dec(slot);
  end else
    slot:= 0;

  if (slot < _SaveScroll^) or (slot >= _SaveScroll^ + 10) then
    _SaveScroll^:= slot - 5;
  _SaveScroll^:= max(0, min(_SaveScroll^, count - 10));
  for i := 1 to _SaveScroll^ do
    AddAction(163, _SaveSlotsCount^, 0);
  AddAction(165, slot - _SaveScroll^, 0);
  _SaveSlot2^:= -1;
  _SaveScroll^:= 0;
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
const
  SaveSlot2 = int(_SaveSlot2);
asm
  cmp dword ptr [SaveSlot2], -1
  jz @exit
  call ChooseSaveSlotProc
  xor edx, edx
@exit:
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
  SaveSpecial:= 'quiksave.dod';
  if QuickSavesCount <= 1 then
    exit;
  s1:= Format('saves\quiksave%d.dod', [QuickSavesCount]);
  DeleteFile(s1);
  for i := QuickSavesCount - 1 downto 2 do
  begin
    s2:= s1;
    s1:= Format('saves\quiksave%d.dod', [i]);
    MoveFile(ptr(s1), ptr(s2));
    DeleteFile(s1);
  end;
  MoveFile('saves\quiksave.dod', ptr(s1));
end;

procedure QuicksaveHook;
asm
  push eax
  call QuicksaveProc
  pop eax
  pop ecx
  push $4F9190
  jmp ecx
end;

//----- Show multiple Quick Saves

procedure QuickSaveSlotProc;
var
  i: int;
  name: string;
begin
  for i := 2 to QuickSavesCount do
  begin
    name:= Format('quiksave%d.dod', [i]);
    MoveFile(ptr(Format('quik%d.dod', [i])), ptr(name));
    if _access(ptr(name)) <> -1 then
    begin
      StrCopy(_SaveSlotsFiles^[_SaveSlotsCount^], ptr(name));
      inc(_SaveSlotsCount^);
    end;
  end;
end;

procedure QuickSaveSlotHook;
asm
  mov esi, $5DF0E0
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
asm
  mov eax, [ebp - $14]
  call QuickSaveNamesProc
  test eax, eax
  jnz @quik

  push $45C217
  ret

@quik:
  push QuickSaveNamesTmp
  push $45C20D
end;

function QuickSaveDrawProc(name: PChar): PChar;
begin
  case name^ of
    #1:
      Result:= _AutosaveName^;
    #2:
    begin
      if QuickSaveName = '' then
        QuickSaveName:= _QuicksaveName^;
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
  push edx
  add eax, $6C9B40
  call QuickSaveDrawProc
  pop edx
  pop ecx
end;

procedure QuickSaveDrawHook2;
asm
  add eax, $6C9B40
  call QuickSaveDrawProc
  mov edx, eax
end;

procedure QuickSaveDrawHook3;
asm
  push eax
  push ecx
  add edx, $6C9B40
  mov eax, edx
  call QuickSaveDrawProc
  mov edx, eax
  pop ecx
  pop eax
end;

procedure QuickSaveDrawHook4;
asm
  push eax
  push ecx
  push edx
  mov eax, [ebp - $1C]
  call QuickSaveDrawProc
  mov [esp + 16], eax
  pop edx
  pop ecx
  pop eax
  jmp dword ptr [eax+0A8h]
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
  TMembersArray = array[0..5] of int;
  PMembersArray = ^TMembersArray;
const
  Members = PMembersArray(_PartyMembers);
var
  a: array[0..4] of byte;
  i, n: int;
begin
  n:= 0;
  for i := 1 to _Party_MemberCount^ do
    if _Character_IsAlive(nil, nil, ptr(_CharactersTable + Members^[i]*_CharOff_Size)) then
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
  jnz @normal
  pop eax
// temporary set CurrentMember to random value, but fixed during the whole event
  pushad
  call InactiveMemberEventsProc
  mov [CurMember], eax
  popad
  push [esp + 4]
  push offset @after
  push eax
@normal:
  mov eax, $4E6CD1
  ret
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
  cmp word ptr [eax + _CharOff_Recover], 0
@ok:
end;

//----- Show recovery time in Attack/Shoot description

var
  TextBuffer: array[0..499] of char;

function AttackDescriptionProc(str: PChar; shoot: LongBool; memberId:int):PChar;
var
  member: PChar;
  i: int;
  blaster: Boolean;
begin
  blaster:= false;
  member:= ptr(_CharactersTable + _CharOff_Size*memberId);
  i:= pint(member + _CharOff_ItemMainHand)^;
  if (i > 0) then
  begin
    i:= int(member + _CharOff_Items + i*_ItemOff_Size);
    blaster:= (pint(i + $14)^ and 2 = 0) and (pbyte(_ItemsTxt^ + $30*pint(i)^ + $1D)^ = 7);
  end;
  i:= _Character_GetWeaponDelay(0, 0, member, shoot and not blaster);
  if (i < 30) and not (shoot or blaster) then
    i:= 30;
  StrLCopy(TextBuffer, str, 499);
  Result:= StrLCat(TextBuffer, ptr(Format(RecoveryTimeInfo, [i])), 499);
end;

var
  AttackDescriptionStd: ptr;

procedure AttackDescriptionHook;
asm
  xor edx, edx
  mov eax, ebx
  mov ecx, [esi + $128]
  call AttackDescriptionProc
  mov ebx, eax
  jmp AttackDescriptionStd
end;

procedure ShootDescriptionHook;
asm
  xor edx, edx
  inc edx
  mov eax, ebx
  mov ecx, [esi + $128]
  call AttackDescriptionProc
  mov ebx, eax
  jmp AttackDescriptionStd
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
      Result:= _PermAlloc(0, 0, _PermAllocator, name, n, 0);
    FileRead(f, Result^, n);
    Options.LastLoadedFileSize:= n;
  finally
    FileClose(f);
  end
end;

procedure LodFilesHook;
asm
  mov eax, [esp + 8]
  mov edx, [esp + 12]
  call LodFilesProc
  test eax, eax
  jz @std
  pop ecx
  ret 8

@std:
  pop eax
  push ebp
  mov ebp, esp
  sub esp, $7C
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
  pop ebx
  leave
  jmp ecx
end;

procedure LodFileEvtOrStr;
asm
  mov esi, Options.LastLoadedFileSize
  push $440B7A
end;

//----- Dagger tripple damage from 2nd hand check

procedure SecondHandDaggerHook;
asm
  xor eax, eax
  cmp word ptr [edi + $37C], 128
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
  mov eax, _PartyMembers[eax*4]
  imul eax, _CharOff_Size
  add eax, _CharactersTable
  cmp ecx, eax
  jz @exit
@beep:
  pop eax
  mov ecx, PlayerNotActive
  mov edx, 2
  push $4671C5
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

  push 16
  push 522
  mov ecx, edi
  call _Character_WearsItem
  test eax, eax
  jnz @feather

  mov ecx, edi
  jmp FeatherFallStd

@feather:
  push $473F8C
  ret 8
end;

//----- Temporary resistance bonuses didn't work

var
  ResistancesStd: ptr;

procedure ResistancesHook;
asm
  push [esp + 4]
  call ResistancesStd
  movzx ecx, word ptr [esi + edi*2 + $1A1E]
  add eax, ecx
  ret 4
end;

//----- change MouseLookBorder

procedure MouseBorderHook(a1, a2: int; var rect: TRect; b, r, t, l:int);
var mb:int;
begin
  mb:= max(MouseBorder, 0);
  with rect do
  begin
    Left:= l - 100 + mb;
    if MouseBorder < 0 then
      Top:= 0
    else
      Top:= t - 100 + mb;
    Right:= r + 100 - mb;
    Bottom:= b + 100 - mb;
    if MouseBorder < 0 then
      inc(Bottom, 480 - 366);
  end;
end;

//----- strange crash in Temple Of The sun: in damageMonsterFromParty member is out of bounds

procedure Crash1Hook;
begin
  raise Exception.Create('Invalid player in damageMonsterFromParty!');
end;

var
  Crash1Std: procedure;

procedure Crash1Hook2;
begin
  try
    Crash1Std;
  except
  end;
end;

//----- fix for 'Mok's delay' reason

procedure MovieHook;
asm
  mov byte ptr [esi + $A8], 1  // trigger on mouse down
  mov byte ptr [edi + $F0], 1  // is LButton pressed
  mov eax, [esp + 4]
end;

//----- Elderaxe wrong damage type: Fire instead of Ice

var
  ElderaxeStd: ptr;

procedure ElderaxeHook;
asm
  mov dword ptr [edi], 2
  jmp ElderaxeStd
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

procedure HasteWeakHook;
asm
  call HasteWeakCheck
  test eax, eax
end;

//----- Herald's Boots Swiftness didn't work

procedure HeraldsBootsHook;
asm
  push eax
  mov eax, [esi + _CharOff_ItemBoots]
  xor edx, edx
  imul eax, _ItemOff_Size
  cmp [esi + _CharOff_Items + eax], 518
  jnz @1
  mov ecx, 20
@1:
  pop eax
  sub eax, [ebp - 12]
  sub eax, ecx
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
  lea eax, [esp + $10]
  push edx
  push ecx
  lea ecx, [eax + 4]
  push ecx                 // esp
  push ebp
  push dword ptr [eax - 4] // edi
  push esi
  push ebx
  push 0                   // Reason
  push dword ptr [eax]     // RetAddr
  call ErrorProc
  
  jmp [$4E826C]
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

  mov ecx, [$75D770]
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

  jmp [$4E828C]
end;

//----- MusicLoopsCount (main part is in KeysProc)

procedure ChangeTrackHook;
asm
  mov eax, Options.MusicLoopsCount
  dec eax
  mov MusicLoopsLeft, eax
  mov LastMusicStatus, 0

  // std
  test byte ptr [$6F39A4], $10
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
  mov [ebp - $30], ebx
  jz @exit
  lea eax, [ebx - 2]
  mov edx, ecx
  call FixChest
  mov [esp], $41F914
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
  vx1 = pint($FFDE8C);
  vy1 = pint($FFDE90);
  vx2 = pint($FFDE94);
  vy2 = pint($FFDE98);
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
  lea eax, dword ptr $FC50DC[ebx]
  lea edx, [ebp - $18]  // number of points
  call VisibleSpriteD3DProc
  mov ebx, eax
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
  PalIndex:= _LoadPalette(0, 0, $84AFE0, PalIndex);
  p:= @pal;
  p1:= ptr($91C5E0 + PalIndex*32*256*2);
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
    ZeroMemory(Result, SizeOf(THwlBitmap));
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
    end;
  end;
end;

procedure LoadSpriteD3DHook2;
asm
  inc dword ptr [esi+0EC9Ch]
  push $4AAEA9
  push $4A2E8B
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
  push $4AAE21
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
  push $4AABF9
  ret
@found:
  mov HaveIt, 0
  push $4AACDC
end;

//----- Extend Sprites Limits

procedure ExtendSpriteLimits;
const
  PatchPtr: array[0..23] of int = ($41DA95, $41DFA0, $43D34A, $43DD47, $47A0B1, $47A307, $47AF3A, $4A7617, $44E558, $44E58D, $4603AD, $460477, $4604AE, $4604D8, $4AACB2, $4AAD66, $4AAD9A, $4AADD3, $4AAD34, $4AAD49, $4AAD82, $4AADF5, $4E6E8C, $4AAE11);
  PatchCount: array[0..4] of int = ($4603A5, $4604D0, $4AAC0D, $4AAC3D, $4E6E82);
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

//----- Credits move too fast

procedure FixCreditsPause;
asm
  push 12
  call dword ptr [$4E8158] // Sleep
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
  mov eax, [esp + $10]
  push $42492D
  jmp MemoryFreeProc
end;

procedure MemoryNewHook;
asm
  mov eax, [ebp+$C]
  cmp eax, edi
  jge @ok
  xor eax, eax
  jmp @exit
@ok:
  call MemoryNewProc
@exit:
  push $424C6E
end;

//----- Fix spells.txt parsing out-of-bounds

var
  SpellsTxtStd: ptr;

procedure SpellsTxtHook;
asm
  mov eax, [esp + $1C]
  cmp eax, ($4F52D2 - $24)
  jg @exit
  push SpellsTxtStd
@exit:
end;

//----- Fix sound loading

procedure LoadSoundHook;
asm
  mov eax, [$FEB338]
  cmp eax, edi
  jnz @exit
  mov eax, [$FEB324]
@exit:
end;

//----- Fix texture checking out-of-bounds

procedure TextureCheckHook;
asm
  and eax, $1FF
  mov [ebp + 8], eax
end;

procedure TextureCheckHook2;
asm
  and eax, $1FF
  mov [ebp + $C], eax
end;

//----- Fix facet ray interception checking out-of-bounds

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

//----- There is a facet without a single vertex in Necromancers' Guild!

procedure NoVertexFacetHook;
asm
  mov al, [edi + $5d]
  test al, al
  jnz @norm
  pop eax
  push $49836C
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
  end;
end;

//----- Get rid of palettes limit in D3D

procedure PalettesHook;
asm
  cmp esi, $32
  jl @next
  cmp dword ptr [$EC1980], 0  // _IsD3D (stupid compiler)
  jz @sw
  dec esi
  mov [esp], $489EBD
@sw:
  ret
@next:
  mov [esp], $489EA8
end;

//----- D3D better space reaction

const
  CVis_get_object_zbuf_val: function(n1, n2, this, obj: int): Word = ptr($4BF6C6);
var
  PressSpaceStd: function(n1, index, ref: int): Byte;

function PressSpaceHook: Byte;
var
  i, j, p: int;
begin
  p:= pint(pint($75CE00)^ + 3660)^;
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
  mov esi, 3
  cmp edx, 3
  jnz @exit
  mov ax, [ecx + $4C]
  xor edx, edx
  dec ax
  jz @exit
  dec ax
  jz @exit
  inc edx
@exit:
  cmp edx, 2
end;

//----- Mouse look

const
  MLSideX = 0;
  MLSideY = 480 - (29*2 + 338);
var
  MiddleX, MiddleY, MLookPartX, MLookPartY: int;
  MWndPos, MLastPos, MLookTempPos: TPoint;
  MLookStartTime: DWORD;
  EmptyCur, ArrowCur: HCURSOR;
  MouseLookOn, MLookIsTemp: Boolean;

function CursorPos:PPoint;
begin
  Result:= PPoint(PPChar($75D770)^ + $108);
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
  p2:= PPChar($F01A6C)^ + 2*(_ScreenW^*(MiddleY - h div 2) + MiddleX - w div 2);
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

procedure WindowProcStdImpl;
asm
  push ebp
  mov ebp, esp
  sub esp, $48
  push $461905
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
  CommandsArray = $75E3C0;
  AddCommand: procedure(a1, a2, this, cmd: int) = ptr($47519C);
var
  xy: TSmallPoint absolute lp;
  r: TRect;
begin
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
  PartyH = pint($B20E94);
  PartyZ = pint($B2155C);
  DriftZ = pint($B21590);
  PartyState = pint($B7CA88);
  z = -$64;
  z2 = -$20;
  MaxZ = -$2C;
  HasCeil = -$88;
  CeilH = -$6C;
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
  if (dz > 0) and (pint(ebp + z)^ + dz > pint(ebp + MaxZ)^) then
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
    pint($B21580)^:= 0;
    pint($B21584)^:= 0;
    _Flying^:= 0;
    PartyState^:= PartyState^ or 1;
    v.X:= 0;
    v.Y:= 0;
  end;
end;

procedure MouseLookFlyHook1;
asm
  push dword ptr [ebp - $28]
  push edi
  mov eax, esp
  mov edx, ebp
  call MouseLookFlyProc
  pop edi
  pop eax
  mov ds:[ebp - $14], edi
  mov ds:[ebp - $28], eax
  mov eax, [ebp - $20]
  cmp eax, [ebp - $58]
end;

procedure MouseLookFlyHook2;
asm
  mov ds:[$B21560], eax
  push ebx
  push edi
  mov eax, esp
  mov edx, ebp
  call MouseLookFlyProc
  pop edi
  pop ebx
  mov ds:[ebp - $C], ebx
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

//----- Control palette gamma

procedure PaletteSMulHook;
asm
  fld [ebp-14h]
  fmul Options.PaletteSMul
  fldz
end;

//----- Town Portal dlg reacts spell book click

var
  TPTime: uint;

procedure SetTPTime;
begin
  TPTime:= GetTickCount;
end;

procedure TPProc2(dlg: int);
var
  i, it: int;
begin
  if GetTickCount - TPTime > 20 then  exit;

  it:= pint(dlg + 172 + 4)^;
  for i := 1 to pint(dlg + 172 + 12)^ do
  begin
    pbyte(pint(it)^ + $11)^:= 0;  // pressed by mouse
    it:= pint(it + 4)^;
  end;
end;

procedure TPHook;
asm
  call SetTPTime
  pop eax
  mov ecx, [ebp-$C]
  pop edi
  pop esi
  jmp eax
end;

var
  TPOld2: procedure(a1, a2, this: int);

procedure TPHook2(a1, a2, this: int);
begin
  TPProc2(this);
  TPOld2(a1, a2, this);
end;

//----- Lloyd Beacon dlg reacts spell book click

procedure LBHook;
asm
  mov large fs:0, ecx
  push eax
  call SetTPTime
  pop eax
end;

var
  LBOld2: function(a1, a2, this: int): int;

function LBHook2(a1, a2, this: int): int;
begin
  TPProc2(this);
  Result:= LBOld2(a1, a2, this);
end;

//----- Use Smooth turn rate by default

procedure DefaultSmoothTurnHook;
asm
  mov edx, 3
  mov ecx, $4F98A0
end;

//----- Was no LeaveMap event on death

procedure FixLeaveMapDieHook;
const
  OnMapLeave: int = $440DBC;
asm
  call OnMapLeave
  push $4D9E20
end;

//----- Subtract gold after autosave when trevelling

var
  TravelGold: int;

procedure TravelGoldFixHook1;
const
  TrySubtract: int = $4BBDCD;
asm
  mov TravelGold, ecx
  call TrySubtract
  test eax, eax
  jz @exit
  mov ecx, TravelGold
  add ds:[$B215D4], ecx
@exit:
end;

procedure TravelGoldFixHook2;
asm
  mov eax, TravelGold
  sub ds:[$B215D4], eax
  push $4B0341
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
  Queue = PQueue($75E3C0);
  Add: procedure(n1,n2, this, key: int) = ptr($47519C);
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
  push $42EDD8
  jmp AutorunProc
end;

//----- Lloyd: take spell points and action after autosave

procedure LloydAutosaveFix;
asm
  // get back spell points and remove recovery delay
  push esi

  push edx
  xor eax, eax
  mov al, [$517918]
  mov esi, _CharOff_Size
  mul eax, esi
  pop edx
  lea esi, [eax + $B2187C]

  mov ax, [esi + _CharOff_Recover]
  push eax
  mov word ptr [esi + _CharOff_Recover], 0
  mov eax, [esi + _CharOff_SpellPoints]
  push eax
  add eax, dword ptr [$517914]
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
  mov al, [$51D818]
  mov edi, _CharOff_Size
  mul eax, edi
  pop edx
  lea edi, [eax + $B2187C + _CharOff_Recover]
  mov ax, [edi]
  push eax
  mov word ptr [edi], 0

  call _DoSaveGame

  // restore recovery delay
  pop eax
  mov [edi], ax
  mov edi, 1
end;

//----- Limit FPS for right physics

{function GetTimeHook:DWORD;
begin
  Result:= timeGetTime;
  if not DoubleSpeed then
    Result:= Result and not 15;
end;}

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
  FindInLodPtr2 = $45F09B + 5;

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
  LodLoad: array[Boolean] of function(_1, _2: int; This: ptr;
    CanWrite: int; Name: PChar): LongBool = (ptr($45F22E), ptr($45FEBC));
  LodLoadChapter: array[Boolean] of function(_1, _2: int; This: ptr;
    Chapter: PChar): LongBool = (ptr($45F2E3), ptr($45FF71));
  LodClean: procedure(_1, _2: int; This: ptr) = ptr($45EEF1);

function DoLoadCustomLod(Old: PChar; Name, Chap: PChar): ptr;
var
  IsMM8: Boolean;
  i: int;
begin
  IsMM8:= SameText(Chap, 'language');
  GetMem(Result, LodSize);
  ZeroMemory(Result, LodSize);
  if SameText(Chap, 'chapter') then
    Chap:= 'maps';
  if LodLoad[IsMM8](0,0, Result, 0, Name) or LodLoadChapter[IsMM8](0,0, Result, Chap) then
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

procedure LoadCustomLods(Old: int; const Name: string; Chap: PChar);
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
var
  Lang: array[0..103] of Char;
begin
  LoadCustomLods($70D3E8, 'icons.lod', 'icons');
  LoadCustomLods($72DC60, 'bitmaps.lod', 'bitmaps');
  LoadCustomLods($71EFA8, 'sprites.lod', 'sprites08');
  LoadCustomLods($6CE838, 'games.lod', 'chapter');
  LoadCustomLods($6F30D0, 'T.lod', 'language');
  LoadCustomLods($6F330C, 'D.lod', 'language');
  _ReadRegStr(0, Lang[0], 'language_file', 'english', SizeOf(Lang));
  LoadCustomLods($6F30D0, PChar(Lang + 'T.lod'), 'language');
  LoadCustomLods($6F330C, PChar(Lang + 'D.lod'), 'language');
  LoadLodsOld;
end;

//----- Custom LODs - Vid

const
  _VidOff_N = $48;
  _VidOff_Files = $38;
  _VidOff_Handle = $78;
  VidArc1 = 'mightdod.vid';
  VidArc2 = 'magicdod.vid';

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
  FileRead(h, n, 4);
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
  push $4BC657
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
  imul dword ptr [$75E394]
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
  mov eax, [ebp - $10]
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

//----- Sky getting reset when game is loaded

procedure FixSkyBitmap;
asm
  jnz @std
  mov eax, $6CF0D4
  mov dword ptr [esp], $47E2C1
  ret
@std:
  cmp [ebp - 1], 0
end;

//----- Sky bitmap name can be 12 bytes long

var
  FixSkyLenOld: int;

procedure FixSkyLen;
asm
  xchg [esi + $510], ebx
  call FixSkyLenOld
  xchg [esi + $510], ebx
  push $47E0D9
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

//----- Telepathy preventing you from finding random items in corpses

procedure FixTelepathy;
asm
  and byte ptr [ebx+$26], $7F
  cmp word ptr [ebx+$BC], 0
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
  mov [esp], $4AB69C
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
          AddObject(IntToStr(min(0, pint(p + i*size)^) and $8) + IntToHex(i, 2), ptr(i));

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
          pint(p + i*size)^:= RSCharToInt(Strings[i][1]) - 8;
        end;
      end;
    finally
      Free;
    end;
end;

procedure FixChestSmartHook;
asm
  mov [esp + $28], $8C
  mov eax, edi
  call FixChestSmartProc
end;

//----- Fix items.txt: make special items accept standard "of ..." strings

function FixItemsTxtProc(text: PChar): int;
const
  str = '|of Might|of Thought|of Charm|of Vigor|of Precision|of Speed|of Luck|of Health|of Magic|of Defense|of Fire Resistance|of Air Resistance|of Water Resistance|of Earth Resistance|of Mind Resistance|of Body Resistance|of Alchemy|of Stealing|of Disarming|' +
  'of Items|of Monsters|of Arms|of Dodging|of the Fist|of Protection|of The Gods|of Carnage|of Cold|of Frost|of Ice|of Sparks|of Lightning|of Thunderbolts|of Fire|of Flame|of Infernos|of Poison|of Venom|of Acid|Vampiric|of Recovery|of Immunity|of Sanity|'+'of Freedom|of Antidotes|of Alarms|of The Medusa|of Force|of Power|of Air Magic|of Body Magic|of Dark Magic|of Earth Magic|of Fire Magic|of Light Magic|of Mind Magic|of Spirit Magic|of Water Magic|of Thievery|of Shielding|of Regeneration|of Mana|'+'Ogre Slaying|Dragon Slaying|of Darkness|of Doom|of Earth|of Life|Rogues''|of The Dragon|of The Eclipse|of The Golem|of The Moon|of The Phoenix|of The Sky|of The Stars|of The Sun|of The Troll|of The Unicorn|Warriors''|Wizards''|Antique|Swift|Monks''|'+'Thieves''|of Identifying|Elemental Slaying|Undead Slaying|Of David|of Plenty|Assassins''|Barbarians''|of the Storm|of the Ocean|of Water Walking|of Feather Falling|';
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
  push $4551FE
  ret
@ok:
  cmp eax, 24
  jge @spc
  push $455133
  ret
@spc:
  sub eax, 24
  push $45517B
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

procedure TimerSetTriggerTime(time1, time2: int; var t: TTimerStruct);
var
  time: int64;
  period, start: int;
begin
  time:= uint64(time2) shl 32 + time1;
  start:= 0;
  if t.EachYear <> 0 then
    period:= 123863040
  else if t.EachMonth <> 0 then
    period:= 10321920
  else if t.EachWeek <> 0 then
    period:= 2580480
  else begin
    period:= 368640;
    start:= ((t.Hour*60 + t.Minute)*60 + t.Second)*256 div 60;
  end;
  t.TriggerTime:= time - time mod period + start;
  if t.TriggerTime <= time then
    inc(t.TriggerTime, period);
end;

procedure FixTimerRetriggerHook1;
asm
  cmp word ptr [esi+16], $26  // RefillTimer?
  jz @fixExactTime
  mov [esi-$C], ecx
  mov [esi-8], eax
@fixExactTime:
  push $445FE0  // add Period
end;

procedure FixTimerRetriggerHook2;
asm
  mov ax, [esi+8]
  test ax, ax  // daily?
  jnz @std
// Handle timer that triggers at specific time each day
  mov eax, dword ptr [$B20EBC]  // Game.Time
  mov edx, dword ptr [$B20EBC+4]
  lea ecx, [esi-$C]
  call TimerSetTriggerTime
  mov [esp], $446080
@std:
  neg ax
end;

procedure FixTimerSetupHook1;
asm
  mov eax, dword ptr [ebp-$30]
  mov edx, dword ptr [ebp-$30+4]
  mov ecx, esi
  call TimerSetTriggerTime
  push $4411FD
end;

procedure FixTimerSetupHook2;
asm
  mov eax, dword ptr [$B20EBC]  // Game.Time
  mov edx, dword ptr [$B20EBC+4]
  mov ecx, esi
  call TimerSetTriggerTime
  mov ebx, [ebp - $14]
  push $4411FD
end;

//----- Town Portal wasting player's turn even if you cancel the dialog

var
  TPDelay, TPMember: int;

procedure TPDelayHook1;
asm
  mov eax, [ebp-$B8]
  mov TPDelay, eax
  movsx eax, word ptr [ebx+2]
  mov TPMember, eax
  push $42D427
end;

function TPDelayProc2(delay, _: int; this: ptr): ptr;
begin
  Result:= this;
  _Character_SetDelay(0,0, Result, delay);
  if _TurnBased^ and not pbool($51D81C)^ then
    _TurnBased_CharacterActed;
end;

procedure TPDelayHook2;
const
  __ftol: int = $4D967C;
  TurnBased = int(_TurnBased);
asm
  push ecx
  mov eax, TPDelay
  test eax, eax
  jng @skip

  // from 42D3C1
  cmp dword ptr [TurnBased], ebx
  jnz @TurnBased
  fld dword ptr [$6F39E4]
  fimul TPDelay
  fmul qword ptr ds:[$4E8448]
  call __ftol
  mov ecx, [esp]
  call TPDelayProc2
  jmp @skip

@TurnBased:
  mov edx, TPMember
  mov _TurnBasedDelays[edx*4], eax
  call TPDelayProc2

@skip:
  mov TPDelay, 0
  pop ecx
  push $425B1A
end;

//----- Fix movement rounding problems - nerf jump

procedure FixMovementNerf;
asm
  mov eax, [$B20EB4]
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
  cmp word ptr [esi+$BA], 1
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
  mov [esp], $461AEC
  ret
@DefProc:
  mov [esp], $46219B
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

//----- Monsters summoned by other monsters had wrong monster as their ally

procedure FixMonsterSummon;
asm
  add eax, 2
  mov ecx, 3
  idiv ecx
  push $44D687
end;

//----- Dragons and some spells couldn't target rats
// They use Party_Height/2 instead of Party_Height/3,
// but targeting didn't account for it

procedure FixDragonTargeting;
const
  std: int = $404340;
asm
  movsx eax, word ptr [ebx]
  cmp eax, 135 // Blaster
  jz @dragon
  cmp eax, 137 // dragon
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

//----- Shops unable to operate on some artifacts

procedure CanSellItemHook;
asm
  cmp [ebp + $14], 3
  jnz @exit
  mov eax, [__ItemsTxt]
  cmp dword ptr [eax + ecx + $10], 0  // Value = 0 in items.txt
  jnz @exit
  mov [esp], $490054
  ret
@exit:
  test byte ptr [ebx+$15], 1
  jnz @exit2
  mov [esp], $4900CB
@exit2:
end;

procedure CanSellItemHook2;
asm
  mov eax, [ecx]
  lea eax, [eax+eax*2]
  shl eax, 4
  add eax, [__ItemsTxt]
  cmp dword ptr [eax + $10], 0  // Value = 0 in items.txt
  jz @deny
  push $4BB612
@deny:
  xor eax, eax
end;

//----- Crash on exit

procedure ExitCrashHook;
asm
  mov eax, [$FFDDF8]
  cmp eax, [$FFDDFC]
  jz @skip
  push eax
  call edi
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

//----- Unicorn King appearing before obelisks are taken and respawning

procedure FixObelisk;
const
  CheckBit: int = $447279;
asm
  test ax, ax
  jz @hide
  mov dx, 195  // killed the unicorn king?
  mov ecx, edi
  call CheckBit
  test ax, ax
  jnz @hide
  ret
@hide:
  pop edi
  pop edi
  push $479B29
end;

procedure FixObelisk2;
const
  SetBit: int = $4472A0;
  QBits = $B2160F;
asm
  test byte ptr [ebx + 39], 2
  jz @std
  mov dx, 195  // killed the unicorn king
  mov ecx, QBits
  push 1
  call SetBit
@std:
end;

//----- Monsters can't cast Paralyze spell, but waste turn

procedure FixParalyze;
asm
  jnz @1
  mov [esp], $42562C
@1:
  sub eax, 1
  jnz @2
  mov [esp], $425505
  ret
@2:
  sub eax, 4
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
  mov [esp], $4BD128
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

procedure BinkLoadHook;
asm
  cmp dword ptr [__Windowed], 0
  jz @std
  mov [esp], $4BDBEB
@std:
end;

//----- 32 bits support (Direct3D)

function GetPixel16(c: uint): uint;
begin
  Result:= (c and $F81F)*33 shr 2;  // r,b components - 5 bit: *(2^5 + 1) shr 2
  Result:= byte(Result) + Result shr 11 shl 16;
  inc(Result, (c and $7E0)*65 shr 9 shl 8);  // g component - 6 bit: *(2^6 + 1) shr 4
end;

var
  ToTrueColor: array[0..$FFFF] of int;

procedure Prepare16to32;
var
  i: int;
begin
  for i:= 0 to $FFFF do
    ToTrueColor[i]:= GetPixel16(i);
end;

procedure ScaleHQ(SrcBuf: ptr; info: PDDSurfaceDesc2);
var
  ps: PWord; pd: pint;
  trans: Word;
  x, y, dpitch, i: int;
begin
  ps:= SrcBuf;
  pd:= info.lpSurface;
  dpitch:= info.lPitch - SW*8;
  trans:= _GreenMask^ + _BlueMask^;
  for y:= 1 to SH do
  begin
    i:= ToTrueColor[ps^];
    for x:= 1 to SW do
    begin
      if ps^ <> trans then
        if i <> $00FFFF then
          pd^:= RSMixColorsRGB(ToTrueColor[ps^], i, 196)
        else
          pd^:= ToTrueColor[ps^];
      inc(pd);
      i:= ToTrueColor[ps^];
      if ps^ <> trans then
        pd^:= i;
      inc(ps);
      inc(pd);
    end;
    inc(PChar(pd), dpitch);
    dec(ps, SW);
    i:= ToTrueColor[ps^];
    for x:= 1 to SW do
    begin
      if ps^ <> trans then
        if i <> $00FFFF then
          pd^:= RSMixColorsRGB(ToTrueColor[ps^], i, 196)
        else
          pd^:= ToTrueColor[ps^];
      inc(pd);
      i:= ToTrueColor[ps^];
      if ps^ <> trans then
        pd^:= i;
      inc(ps);
      inc(pd);
    end;
    inc(PChar(pd), dpitch);
  end;
end;

procedure TrueColorProc(SrcBuf: ptr; info: PDDSurfaceDesc2);
var
  ps: PWord; pd: pint;
  trans: Word;
  x, y, dpitch: int;
begin
  DXProxyScale(SrcBuf, info);
  //ScaleHQ(SrcBuf, info);
  exit;

  if ToTrueColor[1] = 0 then
    Prepare16to32;
  NeedScreenWH;
  ps:= SrcBuf;
  pd:= info.lpSurface;
  dpitch:= info.lPitch - SW*4;
  trans:= _GreenMask^ + _BlueMask^;
  for y:= 1 to SH do
  begin
    for x:= 1 to SW do
    begin
      if ps^ <> trans then
        pd^:= ToTrueColor[ps^];
      inc(ps);
      inc(pd);
    end;
    inc(PChar(pd), dpitch);
  end;
end;

procedure TrueColorHook;
asm
  lea edx, [ebp - $98]
  cmp dword ptr [edx + $54], 32
  jnz @std
  mov dword ptr [esp], $4A3978
  jmp TrueColorProc
@std:
end;

procedure TrueColorHookNew;
asm
  call DXProxyDraw
  sub [esp], 5+6
  mov eax, 1
  xor ecx, ecx
  test ecx, ecx
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
const
  RenderLeft = pint($FFDE9C);
  RenderTop = pint($FFDEA0);
  RenderRight = pint($FFDEA4);
  RenderBottom = pint($FFDEA8);
var
  r: TRect;
begin
  r:= DXProxyScaleRect(Rect(RenderLeft^, RenderTop^, RenderRight^, RenderBottom^));
  DoTrueColorShot(info, ps, w, h, r);
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
  push $45BE12
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

//----- 32 bit color support (Software)

type
  VMTDirectDrawSurface4 = array[0..$B4-1] of byte;
  TMySurface = record
    PVMT: ^VMTDirectDrawSurface4;
    Original: ptr;
    VMT: VMTDirectDrawSurface4;
  end;

var
  BaseVMT: VMTDirectDrawSurface4;
  FrontBuffer, BackBuffer: TMySurface;
  ScreenBmp: TBitmap; ScreenScanline: ptr;

procedure PassThrough;
asm
  mov ecx, [esp + 4]
  mov ecx, [ecx + 4]
  mov [esp + 4], ecx
  jmp eax
end;

procedure InitBaseVMT(surf: pptr);
const
  HookBase: TRSHookInfo = (newp: @PassThrough; t: RShtCodePtrStore);
var
  hook: TRSHookInfo;
  i: int;
begin
  CopyMemory(@BaseVMT, surf^, SizeOf(VMTDirectDrawSurface4));
  hook:= HookBase;
  hook.p:= int(@BaseVMT);
  for i:= 1 to SizeOf(VMTDirectDrawSurface4) div 4 do
  begin
    RSApplyHook(hook);
    inc(hook.p, 4);
  end;
end;

function AnyBuffer_IsLost(this: ptr): HRESULT; stdcall;
begin
  Result:= DD_OK;
end;

procedure HookSurface(var my: TMySurface; psurf: pptr);
begin
  if pint(@BaseVMT)^ = 0 then
    InitBaseVMT(psurf^);
  my.PVMT:= @my.VMT;
  my.VMT:= BaseVMT;
  my.Original:= psurf^;
  psurf^:= @my;
  pptr(@my.VMT[$60])^:= @AnyBuffer_IsLost;
end;

procedure DrawSW;
var
  r: TRect;
  dc: HDC;
begin
  GetClientRect(_MainWindow^, r);
  dc:= GetDC(_MainWindow^);
  SetStretchBltMode(dc, BLACKONWHITE);
  StretchBlt(dc, 0, 0, r.Right, r.Bottom, ScreenBmp.Canvas.Handle, 0, 0, SW, SH, cmSrcCopy);
  ReleaseDC(_MainWindow^, dc);
end;

function FrontBuffer_Blt(this: ptr; dest: PRect; surf: ptr; r: PRect; flags: uint; fx: ptr): HRESULT; stdcall;
begin
//  Assert(ptr(surf) = @BackBuffer);
  DrawSW;
  Result:= DD_OK;
end;

function FrontBuffer_BltFast(this: ptr; X, Y: int; surf: ptr; r: PRect; flags: uint; fx: ptr): HRESULT; stdcall;
begin
//  Assert(ptr(surf) = @BackBuffer);
  DrawSW;
  Result:= DD_OK;
end;

function FrontBuffer_Lock(this: ptr; dest: PRect; out info: TDDSurfaceDesc2; flags: uint; hEvent: THandle): HRESULT; stdcall;
begin
//  Assert(false);
  Result:= DD_OK;
end;

function FrontBuffer_Unlock(this: ptr; dest: PRect): HRESULT; stdcall;
begin
//  Assert(false);
  Result:= DD_OK;
end;

function BackBuffer_Blt(this: ptr; dest: PRect; surf: ptr; r: PRect; flags: uint; fx: ptr): HRESULT; stdcall;
begin
//  Assert(surf = nil);
  Result:= DD_OK;
end;

function BackBuffer_BltFast(this: ptr; X, Y: int; surf: ptr; r: PRect; flags: uint; fx: ptr): HRESULT; stdcall;
begin
//  Assert(surf = nil);
  Result:= DD_OK;
end;

function BackBuffer_Lock(this: ptr; dest: PRect; out info: TDDSurfaceDesc2; flags: uint; hEvent: THandle): HRESULT; stdcall;
begin
  with info do
  begin
    dwWidth:= SW;
    dwHeight:= SH;
    lPitch:= SW*2;
    lpSurface:= ScreenScanline;
    with ddpfPixelFormat do
    begin
      dwRGBBitCount:= 16;
      dwRBitMask:= $F800;
      dwGBitMask:= $7E0;
      dwBBitMask:= $1F;
      dwRGBAlphaBitMask:= 0;
    end;
  end;
  Result:= DD_OK;
end;

function BackBuffer_Unlock(this: ptr; dest: PRect): HRESULT; stdcall;
begin
  Result:= DD_OK;
end;

procedure TrueColorSW;
const
  PFrontBuffer = pptr($F01A10);
  PBackBuffer = pptr($F01A14);
  Blt = $14;
  BltFast = $1C;
  Lock = $64;
  Unlock = $80;
begin
  if _IsD3D^ or ((GetDeviceCaps(GetDC(0), BITSPIXEL) = 16) and (GetDeviceCaps(GetDC(0), PLANES) = 1)) then
    exit;

  if ScreenBmp = nil then
  begin
    NeedScreenWH;
    ScreenBmp:= TBitmap.Create;
    with ScreenBmp do
    begin
      PixelFormat:= pf16bit;
      HandleType:= bmDIB;
      Width:= SW;
      Height:= -SH;
      ScreenScanline:= ptr(min(uint(Scanline[SH - 1]), uint(Scanline[0])));
    end;
    ZeroMemory(ScreenScanline, SW*SH*2);
  end;
  HookSurface(FrontBuffer, PFrontBuffer);
  HookSurface(BackBuffer, PBackBuffer);
  pptr(@FrontBuffer.VMT[Blt])^:= @FrontBuffer_Blt;
  pptr(@FrontBuffer.VMT[BltFast])^:= @FrontBuffer_BltFast;
  pptr(@FrontBuffer.VMT[Lock])^:= @FrontBuffer_Lock;
  pptr(@FrontBuffer.VMT[Unlock])^:= @FrontBuffer_Unlock;
  pptr(@BackBuffer.VMT[Blt])^:= @BackBuffer_Blt;
  pptr(@BackBuffer.VMT[BltFast])^:= @BackBuffer_BltFast;
  pptr(@BackBuffer.VMT[Lock])^:= @BackBuffer_Lock;
  pptr(@BackBuffer.VMT[Unlock])^:= @BackBuffer_Unlock;
end;

//----- 32 bit color support (General)

var
  TrueColorPixelFormatStd: procedure(var fmt: DDPIXELFORMAT); stdcall;

procedure TrueColorPixelFormat(var fmt: DDPIXELFORMAT); stdcall;
const
  str = #32#0#0#0#64#0#0#0#0#0#0#0#16#0#0#0#0#248#0#0#224#7#0#0#31#0#0#0#0#0#0#0;
begin
  TrueColorPixelFormatStd(fmt);
  if fmt.dwRGBBitCount <> 16 then
    CopyMemory(@fmt, PChar(str), length(str));
end;

{procedure Test;
asm
  mov eax, 1
  mov [esp], $49E08F
end;

function TrueColorDrawBuffer(eax, _2: ptr; var desc: DDSURFACEDESC2): ptr;
const
  str = #32#0#0#0#64#0#0#0#0#0#0#0#16#0#0#0#0#248#0#0#224#7#0#0#31#0#0#0#0#0#0#0;
begin
  Result:= eax;
  desc.dwFlags:= desc.dwFlags or DDSD_PIXELFORMAT;
  CopyMemory(@desc.ddpfPixelFormat, PChar(str), length(str));
end;}

//----- HooksList

var
  HooksList: array[1..312] of TRSHookInfo = (
    (p: $458E18; newp: @KeysHook; t: RShtCall; size: 6), // My keys handler
    (p: $463862; old: $450493; backup: @@SaveNamesStd; newp: @SaveNamesHook; t: RShtCall), // Buggy autosave/quicksave filenames localization
    (p: $4CD509; t: RShtNop; size: 12), // Fix Save/Load Slots: it resets SaveSlot, SaveScroll
    (p: $45C132; old: $45BF5B; backup: @FillSaveSlotsStd; newp: @FillSaveSlotsHook; t: RShtCall), // Fix Save/Load Slots
    (p: $45C5B4; old: $45BF5B; newp: @FillSaveSlotsHook; t: RShtCall), // Fix Save/Load Slots
    (p: $432D1B; old: $42F212; backup: @ChooseSaveSlotBackup; newp: @ChooseSaveSlotHook; t: RSht4), // Fix Save/Load Slots
    (p: $432C5B; old: $42F2F4; backup: @SaveBackup; newp: @SaveHook; t: RSht4), // Fix Save/Load Slots
    (p: $45DAA2; newp: @QuicksaveHook; t: RShtCall), // Quicksave trigger
    (p: $45BFFE; newp: @QuickSaveSlotHook; t: RShtCall), // Show multiple Quick Saves
    (p: $45C1D7; newp: @QuickSaveNamesHook; t: RShtJmp; size: 6), // Quick Saves names
    (p: $4CD875; newp: @QuickSaveDrawHook; t: RShtCall), // Quick Saves names Draw
    (p: $45DFCC; newp: @QuickSaveDrawHook2; t: RShtCall; size: 6), // Quick Saves names Draw
    (p: $4CDB0E; newp: @QuickSaveDrawHook3; t: RShtCall; size: 6), // Quick Saves names Draw
    (p: $45C3FC; newp: @QuickSaveDrawHook4; t: RShtCall; size: 6), // Quick Saves names Draw
    (p: $461EDD; old: VK_F11; newp: @QuickSaveKey; newref: true; t: RSht1), // QuickSaveKey
    (p: $44C83D; old: VK_F11; newp: @QuickSaveKey; newref: true; t: RSht1), // QuickSaveKey
    (p: $44C84E; old: VK_F11; newp: @QuickSaveKey; newref: true; t: RSht1), // QuickSaveKey
    (p: $42E54A; newp: @CapsLockHook; t: RShtCall; size: 6; Querry: 4), // CapsLockToggleRun
    (p: $4A7C76; old: $4A7C00; new: $4A7C45; t: RSht4; Querry: 3), // No death movie
    (p: $4A7C62; old: $4A7BCC; new: $4A7C45; t: RSht4; Querry: 2), // No intro: 3dologo
    (p: $4A7C66; old: $4A7BD9; new: $4A7C45; t: RSht4; Querry: 2), // No intro: new world logo
    (p: $4A7C6A; old: $4A7BE6; new: $4A7C45; t: RSht4; Querry: 2), // No intro: jvc
    (p: $4A7C72; old: $4A7BF3; new: $4A7C45; t: RSht4; Querry: 2), // No intro: Intro
    (p: $463477; new: $4634C8; t: RShtJmp; size: 6; Querry: 1), // NoCD
    (p: $4AA751; old: $840F; new: $E990; t: RSht2), // Fix XP compatibility
    (p: $46092C; old: int($FC458BA5); new: int($FFB0C031); t: RSht4), // Fix XP compatibility
    (p: $4BD1BB; old: $0975; new: $1D74; t: RSht2), // Smack in houses bug
    (p: $44378C; newp: @InactiveMemberEventsHook; t: RShtCall), // Multiple fauntain drinks bug
    (p: $491C20; newp: @CheckNextMemberHook; t: RShtCall; size: 8; Querry: 8), // Switch between inactive members in inventory screen
    (p: $491C50; newp: @CheckNextMemberHook; t: RShtCall; size: 8; Querry: 8), // Switch between inactive members in inventory screen
    (p: $417AAD; old: $417B98; backup: @AttackDescriptionStd; newp: @AttackDescriptionHook; t: RShtJmp), // Show recovery time for Attack
    (p: $417AD3; old: $417B98; newp: @ShootDescriptionHook; t: RShtJmp), // Show recovery time for Shoot
    (p: $416225; old: 500; new: 600; t: RSht4; Querry: 9), // Allow using Harden Item on artifacts
    (p: $41620B; old: $41603C; new: $416047; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $416214; old: $41603C; new: $416047; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $41621E; old: $41603C; new: $416047; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $416229; old: $41603C; new: $416047; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $4161AF; old: $41603C; new: $416047; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $4161B8; old: $41603C; new: $416047; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $4161C1; old: $41603C; new: $416047; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $4161D6; old: $41603C; new: $416047; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $4161E2; old: $41603C; new: $416047; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $4160FE; old: $41603C; new: $416047; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $416107; old: $41603C; new: $416047; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $416110; old: $41603C; new: $416047; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $416125; old: $41603C; new: $416047; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $416131; old: $41603C; new: $416047; t: RShtJmp6), // Don't waste potion bottle if it has no effect
    (p: $4BC3A6; old: 1000; new: 1; t: RSht4; Querry: 5), // Delay after cancelling video
    (p: $4BC76F; old: 300; new: 1; t: RSht4; Querry: 5), // Delay after showing video
    (p: $411C9B; newp: @LodFilesHook; t: RShtCall; size: 6; Querry: 12), // Load files from DataFiles folder
    (p: $411D9D; newp: @LodFileStoreSize; t: RShtCall), // Need when loading files
    (p: $440B2A; newp: @LodFileEvtOrStr; t: RShtJmp), // Load *.evt and *.str from DataFiles folder
    (p: $4AFA3C; newp: PChar('DataFiles\'); t: RSht4; Querry: 12), // Load files from DataFiles folder
    (p: $48C98F; old: $455B09; newp: @SecondHandDaggerHook; t: RShtCall), // Dagger tripple damage from 2nd hand check
    (p: $48D8C0; old: $455B09; newp: @WeaponRecoveryBonusHook; t: RShtCall; size: 8), // Include items bonus to skill in recovery time
    (p: $48D8CA; t: RShtNop; size: 4), // Include items bonus to skill in recovery time
    (p: $466AD8; old: $491514; backup: @ScrollTestMemberStd; newp: @ScrollTestMember; t: RShtCall; Querry: 17), // Don't allow using scrolls by not active member
    (p: $41AB91; old: $493753; backup: @ReputationHookStd; newp: @ReputationHook; t: RShtCall; Querry: 7), // Show numerical reputation value
    (p: $41AB9F; old: $4F3E18; newp: PChar('%s: '#12'%05d%d %s'#12'00000'); t: RSht4; Querry: 7), // Show numerical reputation value
    (p: $41ABB7; old: $14; new: $18; t: RSht1; Querry: 7), // Show numerical reputation value
    (p: $4917C0; newp: ptr($49193A); t: RShtJmp; size: $4917CC - $4917C0), // Poison condition ignored Protection from Magic
    (p: $4247D8; old: $424722; backup: @DoubleSpeedStd; newp: @DoubleSpeedHook; t: RShtCall), // DoubleSpeed
    (p: $47197B; old: $4D967C; backup: @TurnSpeedStd; newp: @TurnSpeedHook; t: RShtCall), // TurnSpeed
    (p: $471997; old: $4D967C; newp: @TurnSpeedHook; t: RShtCall), // TurnSpeed
    (p: $472C3A; old: $4D967C; newp: @TurnSpeedHook; t: RShtCall), // TurnSpeed
    (p: $472C6D; old: $4D967C; newp: @TurnSpeedHook; t: RShtCall), // TurnSpeed
    (p: $472C95; old: $4D967C; newp: @TurnSpeedHook; t: RShtCall), // TurnSpeed
    (p: $472CBD; old: $4D967C; newp: @TurnSpeedHook; t: RShtCall), // TurnSpeed
    (p: $473F27; old: $48D9B4; backup: @FeatherFallStd; newp: @FeatherFallHook; t: RShtCall), // fix 'of Feather Falling' items
    (p: $4B51C2; old: 1500; newp: @Options.HorsemanSpeakTime; newref: true; t: RSht4; Querry: -1), // Horseman delay
    (p: $4B51CB; old: 2500; newp: @Options.BoatmanSpeakTime; newref: true; t: RSht4; Querry: -1), // Boatman delay
    (p: $48DF65; old: $48EE09; backup: @ResistancesStd; newp: @ResistancesHook; t: RShtCall), // Temporary resistance bonuses didn't work
    (p: $42E5C3; old: $458CD6; newp: @MouseBorderHook; t: RShtCall), // change MouseLookBorder
    (p: $436E8B; old: $7D; new: $7F; t: RSht1), // check in damageMonsterFromParty: > 50 instead of >= 50
    (p: $436EA5; old: $2D7D; new: $57C; t: RSht2), // check in damageMonsterFromParty: || instead of &&
    (p: $436EAC; newp: @Crash1Hook; t: RShtJmp), // strange crash in Temple Of The sun: in damageMonsterFromParty member is out of bounds
    (p: $492806; old: $491CCE; backup: @@Crash1Std; newp: @Crash1Hook2; t: RShtCall), // strange crash in Temple Of The sun
    (p: $431865; old: $74; new: $EB; t: RSht1), // Rest on water (on shipyards)
    (p: $4BC2C1; t: RShtNop; size: 11), // Mok's delay before showing video
    (p: $4D04C1; old: $4DAD0A; newp: @MovieHook; t: RShtCall), // fix for 'Mok's delay' reason
    (p: $437AF8; add: 1; t: RSht1), // Wrong artifacts bonus damage ranges (4-9 instead of 4-10 and so on)
    (p: $43794E; add: 1; t: RSht1), // Wrong artifacts bonus damage ranges
    (p: $437932; add: 1; t: RSht1), // Wrong artifacts bonus damage ranges
    (p: $437948; old: $4D99F2; backup: @ElderaxeStd; newp: @ElderaxeHook; t: RShtCall), // Elderaxe wrong damage type: Fire instead of Ice
    (p: $48C895; newp: @DaggerTrippleHook; t: RShtCall; Querry: 10), // ProgressiveDaggerTrippleDamage
    (p: $48C9A1; newp: @DaggerTrippleHook; t: RShtCall; Querry: 10), // ProgressiveDaggerTrippleDamage
    (p: $42759A; newp: @HasteWeakHook; t: RShtCall; size: 6), // Haste on party with dead weak members
    (p: $42BD06; newp: @HasteWeakHook; t: RShtCall; size: 6), // Haste on party with dead weak members
    (p: $48D992; newp: @HeraldsBootsHook; t: RShtCall), // Herald's Boots Swiftness didn't work
    (p: $464F5F; newp: @ErrorHook1; t: RShtCall; size: 6), // Report errors
    (p: $464FDA; newp: @ErrorHook2; t: RShtCall; size: 6), // Report errors
    (p: $4652F4; newp: @ErrorHook3; t: RShtCall; size: 6), // Report errors
    (p: $4A862D; newp: @ChangeTrackHook; t: RShtCall; size: 7), // MusicLoopsCount
    (p: $41F90A; newp: @FixChestHook; t: RShtCall; Querry: 11), // Fix chests: place items that were left over
    (p: $46516F; newp: @DDrawErrorHook; t: RShtJmp), // Ignore DDraw errors
    (p: $421847; old: $D75; new: $22EB; t: RSht2), // Remove code left from MM6
    (p: $4BE5D9; newp: @VisibleSpriteD3DHook; t: RShtCall; size: 6), // Attacking big monsters D3D
    (p: $4BE69E; old: $20; new: 8; t: RSht1), // Attacking big monsters D3D
    (p: $4A2EA4; old: $44FD37; newp: @LoadSpriteD3DHook; t: RShtCall), // No HWL for sprites
    (p: $4AAE9E; old: $4A2E8B; newp: @LoadSpriteD3DHook2; t: RShtJmp), // No HWL for sprites
    (p: $4AAD58; old: $4AAE15; newp: @LoadSpriteD3DHook3; t: RShtCall), // No HWL for sprites
    (p: $4AABF3; old: $4AACDC; newp: @LoadSpriteD3DHook4; t: RShtJmp6), // No HWL for sprites
    (p: $49C17A; size: 16), // No HWL for sprites
    (p: $49C1DA; size: 5), // No HWL for sprites
    (p: $4BF072; old: $4BF0E3; backup: @@SpriteD3DHitStd; newp: @SpriteD3DHitHook; t: RShtCall), // Take sprite contour into account when clicking it
    (p: $4BECE5; old: $4BED9F; new: $4BEEF0; t: RShtCall), // Never can be sure a sprite obscures a facet
    (p: $4BECEA; size: 8), // Never can be sure a sprite obscures a facet
    (p: $4BF088; old: $4BE47D; new: $4BE7A9; t: RShtCall), // Don't check sprite visibility when clicking
    (p: $4BF08D; size: 4), // Don't check sprite visibility when clicking
    (p: $494832; newp: @FixCreditsPause; t: RShtCall; size: 6), // Credits move too fast
    (p: $424AC9; newp: @MemoryInitHook; t: RShtCall; size: 8), // Use Delphi memory manager
    (p: $424874; newp: @MemoryFreeHook; t: RShtJmp; size: 6), // Use Delphi memory manager
    (p: $424B8F; newp: @MemoryNewHook; t: RShtJmp; size: 7), // Use Delphi memory manager
    (p: $45127B; old: $4DB20E; backup: @SpellsTxtStd; newp: @SpellsTxtHook; t: RShtCall), // Fix spells.txt parsing out-of-bounds
    (p: $451656; old: 29; new: 28; t: RSht4), // Fix history.txt parsing out-of-bounds
    (p: $4A7D5B; newp: @LoadSoundHook; t: RShtCall), // Fix sound loading
    (p: $4A7DD9; old: 16; new: 4; t: RSht1), // Fix sound loading
    (p: $481FBC; newp: @TextureCheckHook; t: RShtCall), // Fix texture checking out-of-bounds
    (p: $481FE2; newp: @TextureCheckHook; t: RShtCall), // Fix texture checking out-of-bounds
    (p: $47E5D4; newp: @TextureCheckHook2; t: RShtCall), // Fix texture checking out-of-bounds
    (p: $47E5FA; newp: @TextureCheckHook2; t: RShtCall), // Fix texture checking out-of-bounds
    (p: $474B39; newp: @FacetCheckHook; t: RShtCall), // Fix facet ray interception checking out-of-bounds
    (p: $474C14; newp: @FacetCheckHook; t: RShtCall), // Fix facet ray interception checking out-of-bounds
    (p: $474CE7; newp: @FacetCheckHook; t: RShtCall), // Fix facet ray interception checking out-of-bounds
    (p: $4BFD4C; newp: @FacetCheckHook2; t: RShtCall), // Fix facet ray interception checking out-of-bounds
    (p: $4BFE4A; newp: @FacetCheckHook2; t: RShtCall), // Fix facet ray interception checking out-of-bounds
    (p: $4BFF3E; newp: @FacetCheckHook2; t: RShtCall), // Fix facet ray interception checking out-of-bounds
    (p: $4981AC; newp: @NoVertexFacetHook; t: RShtCall), // There is a facet without a single vertexes in Necromancers' Guild!
    (p: $4A2C46; old: $44FD37; newp: @LoadBitmapD3DHook; t: RShtCall; Querry: 13), // No HWL for bitmaps
    (p: $49C175; old: $44FBD0; new: $44FC90; t: RShtCall; Querry: 13), // No HWL for bitmaps
    (p: $49C1CD; size: 5; Querry: 13), // No HWL for bitmaps
    (p: $489EB1; newp: @PalettesHook; t: RShtCall), // Get rid of palettes limit in D3D
    (p: $4686D5; newp: ptr($4686FD); t: RShtJmp), // Ignore 'Invalid ID reached!'
    (p: $4AB73D; newp: ptr($4AB762); t: RShtJmp; size: 7), // Ignore 'Too many stationary lights!'
    (p: $44C37A; newp: ptr($44C3A2); t: RShtJmp), // Ignore 'Sprite outline currently Unsupported'
    (p: $4555E4; newp: ptr($4555FF); t: RShtJmp; size: 6), // rnditems.txt was freed before the processing is finished
    (p: $468519; old: $4686A8; backup: @@PressSpaceStd; newp: @PressSpaceHook; t: RShtCall), // D3D better space reaction
    (p: $4471C7; newp: @DoorStateSwitchHook; t: RShtCall; size: 6), // Correct door state switching: param = 3
    (p: $4683FE; newp: @MouseLookHook; t: RShtJmp; size: 10), // Mouse look
    (p: $4E8210; newp: @MouseLookHook2; t: RSht4), // Mouse look
    (p: $415584; backup: @@MouseLookHook3Std; newp: @MouseLookHook3; t: RShtCall), // Mouse look
    (p: $42E6F9; newp: @StrafeOrWalkHook; t: RShtCall; size: 6; Querry: 15), // Strafe in MouseLook
    (p: $42E72E; newp: @StrafeOrWalkHook; t: RShtCall; size: 6; Querry: 15), // Strafe in MouseLook
    (p: $4D9E11; backup: @@FixPrismaticBugStd; newp: @FixPrismaticBug; t: RShtCall), // A beam of Prismatic Light in the center of screen that doesn't disappear
    (p: $4618FF; newp: @WindowProcHook; t: RShtJmp; size: 6), // Window procedure hook
    (p: $473184; newp: @MouseLookFlyHook1; t: RShtCall; size: 6), // Fix strafes and walking rounding problems
    (p: $471D57; newp: @MouseLookFlyHook2; t: RShtCall), // Fix strafes and walking rounding problems
    (p: $41E884; newp: @IDMonHook; t: RShtCall; size: 6), // Show resistances of monster
    (p: $416901; size: 14; Querry: 16), // Stop time by right click
    (p: $416F95; newp: @StatColorFixHook; t: RShtCall; size: 7), // negative/0 causes a crash in stats screen
    (p: $489DC1; newp: @PaletteSMulHook; t: RShtCall), // Control palette gamma
    (p: $4E8878; newp: @Options.PaletteVMul; newref: true; t: RSht4; Querry: -1), // Control palette gamma
    (p: $4BD327; old: 5000; newp: @StartupCopyrightDelay; newref: true; t: RSht4), // Startup copyright delay
    (p: $4D1214; newp: @TPHook; t: RShtCall),  // Town Portal dlg reacts spell book click
    (p: $4D0FB7; old: $4D1227; backup: @@TPOld2; newp: @TPHook2; t: RShtCall),  // Town Portal dlg reacts spell book click
    (p: $4D1656; newp: @LBHook; t: RShtCall; size: 7),  // Lloyd Beacon dlg reacts spell book click
    (p: $4D132A; old: $4C4AF7; backup: @@LBOld2; newp: @LBHook2; t: RShtCall),  // Lloyd Beacon dlg reacts spell book click
    (p: $463E9E; newp: @DefaultSmoothTurnHook; t: RShtCall), // Use Smooth turn rate by default
    (p: $461758; old: $4D9E20; newp: @FixLeaveMapDieHook; t: RShtCall), // Was no LeaveMap event on death
    (p: $4E8280; newp: @MyGetAsyncKeyState; t: RSht4), // Don't rely on bit 1 of GetAsyncKeyState
    (p: $4B5172; old: $4BBDCD; newp: @TravelGoldFixHook1; t: RShtCall), // Subtract gold after autosave when trevelling
    (p: $4B5354; old: $4B0341; newp: @TravelGoldFixHook2; t: RShtCall), // Subtract gold after autosave when trevelling
    (p: $4635B6; t: RShtNop; size: $11), // Switch to 16 bit color when going windowed
    (p: $49B350; old: $4DA9F0; backup: @AutoColor16Std; newp: @AutoColor16Hook; t: RShtCall), // Switch to 16 bit color when going windowed
    (p: $49E033; old: $49EC9E; backup: @AutoColor16Std2; newp: @AutoColor16Hook2; t: RShtCall), // Switch to 16 bit color when going windowed
    (p: $49DD01; newp: @BetterD3DInitErrorsHook; t: RShtCall), // Show accurate errors of D3DInit
    (p: $461320; old: $42EDD8; newp: @AutorunHook; t: RShtCall), // Autorun key like in WoW
    (p: $430F62; newp: @LloydAutosaveFix; t: RShtCall), // Lloyd: take spell points and action after autosave
    (p: $4311EB; newp: @TPAutosaveFix; t: RShtCall), // TP: take action after autosave
    (p: $45CF9C; old: $45DB64; new: $45DB5C; t: RShtJmp6), // Fix arena death crash
    //(p: $424726; newp: @GetTimeHook; t: RShtCall; size: 6), // Limit FPS for right physics
    (p: $497ACC; old: 0; new: 1; t: RSht1), // Fix DLV search in games.lod
    (p: $47DB39; old: 0; new: 1; t: RSht1), // Fix DDM search in games.lod
    (p: $45EFFF; newp: @FindInLodAndSeekHook; t: RShtCall), // Custom LODs
    (p: $45F09B; newp: @FindInLodHook; t: RShtCall), // Custom LODs
    (p: $45FCA6; newp: @FindInLodAndSeekHook; t: RShtCall), // Custom LODs
    (p: $463862; backup: @@LoadLodsOld; newp: @LoadLodsHook; t: RShtCall), // Custom LODs
    (p: $4BC635; newp: @OpenVidsHook; t: RShtJmp), // Custom LODs - Vid
    (p: $4BCD87; newp: @OpenBikSmkHook; t: RShtCall), // Custom LODs - Vid(Smk)
    (p: $4BCCE2; newp: @OpenBikSmkHook; t: RShtCall), // Custom LODs - Vid(Bik)
    //(p: $45E2A0; old: $45F1C2; newp: @CopyMapsToNewLodHook; t: RShtCall),
    (p: $45773F; newp: @ClearKeyStatesHook; t: RShtJmp; size: 6), // Clear my keys as well
    (p: $45F91B; newp: @SaveGameBugHook; t: RShtCall), // Save game bug in Windows Vista and higher (bug of OS or other software)
    (p: $46F03E; newp: @FixStrafe1; t: RShtCall; size: 7; Querry: 23), // Fix movement rounding problems
    (p: $46F06A; newp: @FixStrafe1; t: RShtCall; size: 7; Querry: 23), // Fix movement rounding problems
    (p: $46F091; newp: @FixStrafe1; t: RShtCall; size: 7; Querry: 23), // Fix movement rounding problems
    (p: $46F0B8; newp: @FixStrafe1; t: RShtCall; size: 7; Querry: 23), // Fix movement rounding problems
    (p: $46F0DA; newp: @FixStrafe1; t: RShtCall; size: 7; Querry: 23), // Fix movement rounding problems
    (p: $46E896; backup: @OldMoveStructInit; newp: @FixStrafeMonster1; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $46F743; newp: @FixStrafeMonster2; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $4701EB; newp: @FixStrafeObject1; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $470923; newp: @FixStrafeObject2; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $471E81; newp: @FixStrafePlayer; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $4734F6; newp: @FixStrafePlayer; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $472071; newp: @FixStrafe2; t: RShtCall; size: 6; Querry: 23), // Fix movement rounding problems
    (p: $47208F; newp: @FixStrafe2; t: RShtCall; size: 6; Querry: 23), // Fix movement rounding problems
    (p: $4720AD; newp: @FixStrafe2; t: RShtCall; size: 6; Querry: 23), // Fix movement rounding problems
    (p: $47359D; newp: @FixStrafe2; t: RShtCall; size: 6; Querry: 23), // Fix movement rounding problems
    (p: $4735C1; newp: @FixStrafe2; t: RShtCall; size: 6; Querry: 23), // Fix movement rounding problems
    (p: $4735E4; newp: @FixStrafe2; t: RShtCall; size: 6; Querry: 23), // Fix movement rounding problems
    (p: $43E15B; newp: @HDWTRCountHook; t: RShtCall; size: $43E185 - $43E15B), // Control D3D water
    (p: $464203; old: 7; newp: @Options.HDWTRCount; newref: true; t: RSht1; Querry: -1), // Control D3D water
    (p: $464235; old: 7; newp: @Options.HDWTRCount; newref: true; t: RSht1; Querry: -1), // Control D3D water
    (p: $464267; old: 7; newp: @Options.HDWTRCount; newref: true; t: RSht1; Querry: -1), // Control D3D water
    (p: $47E27A; newp: @FixSkyBitmap; t: RShtCall; size: 6; Querry: 18), // Sky getting reset when game is loaded
    (p: $47E0D4; old: $410D70; backup: @FixSkyLenOld; newp: @FixSkyLen; t: RShtJmp),  // Sky bitmap name can be 12 bytes long
    (p: $4DC906; backup: @OldStart; newp: @StartHook; t: RShtCall), // Call ApplyDeferredHooks after MMExt loads
    (p: $46709F; old: $46720F; new: $4671CA; t: RShtJmp6), // Don't waste black potion if it has no effect
    (p: $4670C0; old: $46720F; new: $4671CA; t: RShtJmp6), // Don't waste black potion if it has no effect
    (p: $4670E1; old: $46720F; new: $4671CA; t: RShtJmp6), // Don't waste black potion if it has no effect
    (p: $467102; old: $46720F; new: $4671CA; t: RShtJmp6), // Don't waste black potion if it has no effect
    (p: $467123; old: $46720F; new: $4671CA; t: RShtJmp6), // Don't waste black potion if it has no effect
    (p: $467144; old: $46720F; new: $4671CA; t: RShtJmp6), // Don't waste black potion if it has no effect
    (p: $467165; old: $46720F; new: $4671CA; t: RShtJmp6), // Don't waste black potion if it has no effect
    (p: $41A49D; old: 1; new: 3; t: RSht1), // Show broken and unidentified items in red
    (p: $408ECC; new: $408F02; t: RShtJmp), // Fix Telepathy
    (p: $424ED0; newp: @FixTelepathy; t: RShtCall; size: 8), // Fix Telepathy
    (p: $4AB02A; newp: @FixSmallScaleSprites; t: RShtCall), // Fix small scale sprites crash
    (p: $434199; old: $1F400000; new: $7FFFFFFF; t: RSht4), // Infinite view distance in dungeons
    (p: $44D9AC; newp: @FixChestSmartHook; t: RShtCall; size: 8; Querry: 19), // Fix chests: reorder to preserve important items
    (p: $455173; newp: @FixItemsTxtHook; t: RShtJmp), // Fix items.txt: make special items accept standard "of ..." strings
    (p: $44607A; newp: @FixTimerRetriggerHook1; t: RShtJmp; size: 6; Querry: 21), // Fix immediate timer re-trigger
    (p: $44601A; newp: @FixTimerRetriggerHook2; t: RShtCall; size: 7; Querry: 21), // Fix timers
    (p: $441036; newp: @FixTimerSetupHook1; t: RShtJmp; Querry: 21), // Fix timers
    (p: $441156; newp: @FixTimerSetupHook2; t: RShtJmp; size: 7; Querry: 21), // Fix timers
    (p: $4296C8; newp: @TPDelayHook1; t: RShtJmp), // Town Portal wasting player's turn even if you cancel the dialog
    (p: $43129A; newp: @TPDelayHook2; t: RShtCall), // Town Portal wasting player's turn even if you cancel the dialog
    (p: $471D1A; newp: @FixMovementNerf; t: RShtCall; Querry: 23), // Fix movement rounding problems - nerf jump
    (p: $471D23; t: RShtNop; size: 3; Querry: 23), // Fix movement rounding problems - nerf jump
    (p: $473132; newp: @FixMovementNerf; t: RShtCall; Querry: 23), // Fix movement rounding problems - nerf jump
    (p: $47314B; t: RShtNop; size: 3; Querry: 23), // Fix movement rounding problems - nerf jump
    (p: $46E51B; newp: @NoMonsterJumpDown1; t: RShtCall; size: 8), // Prevent monsters from jumping into lava etc.
    (p: $46EACA; newp: @NoMonsterJumpDown2; t: RShtCall), // Prevent monsters from jumping into lava etc.
    (p: $461953; newp: @FixFullScreenBlink; t: RShtCall; size: 6), // Light gray blinking in full screen
    (p: $40ECAD; newp: @FixBlitCopy; t: RShtCall; size: 6), // Draw buffer overflow in Arcomage
    (p: $40B15B; t: RShtNop; size: 2;), // Hang in Arcomage
    (p: $44D675; newp: @FixMonsterSummon; t: RShtJmp; size: 7), // Monsters summoned by other monsters had wrong monster as their ally
    (p: $426145; old: $404340; newp: @FixDragonTargeting; t: RShtCall), // Dragons and some spells couldn't target rats
    (p: $460D46; t: RShtNop; size: 6; Querry: 24), // DisableAsyncMouse
    (p: $461A50; t: RShtNop; size: 7; Querry: 24), // DisableAsyncMouse
    (p: $461CDF; t: RShtNop; size: 7; Querry: 24), // DisableAsyncMouse
    (p: $464330; t: RShtNop; size: 7; Querry: 24), // DisableAsyncMouse
    (p: $465274; t: RShtNop; size: 6; Querry: 24), // DisableAsyncMouse
    (p: $4C1284; old: 500; new: 0; t: RSht4), // Key presses ignored
    (p: $447C32; oldstr: #62#62#62#62#62#62; newstr: #61#61#61#61#61#61; t: RShtBStr), // Evt commands couldn't operate on some skills
    (p: $4485C2; oldstr: #52#52#52#52#52#52; newstr: #51#51#51#51#51#51; t: RShtBStr), // Evt commands couldn't operate on some skills
    (p: $448F63; oldstr: #52#52#52#52#52#52; newstr: #51#51#51#51#51#51; t: RShtBStr), // Evt commands couldn't operate on some skills
    (p: $4496BB; oldstr: #49#49#49#49#49#49; newstr: #48#48#48#48#48#48; t: RShtBStr), // Evt commands couldn't operate on some skills
    (p: $446BBA; old: 8; new: 9; t: RSht4; Querry: 25), // Heroism pedestal casting Haste instead
    (p: $466990; old: 135; new: 149; t: RSht4), // Flute making Heal sound
    (p: $431F0E; oldstr: #131#13#28#123#81#0#255; newstr: #137#29#28#123#81#0#144; t: RShtBStr), // -1 being set as quick spell
    (p: $43217D; oldstr: #131#13#28#123#81#0#255; newstr: #137#29#28#123#81#0#144; t: RShtBStr), // -1 being set as quick spell
    (p: $490058; size: 16), // Shops unable to operate on some artifacts
    (p: $4BB64A; size: 16), // Shops unable to operate on some artifacts
    (p: $49008E; newp: @CanSellItemHook; t: RShtCall; size: 6), // Shops unable to operate on some artifacts
    (p: $4BBA13; old: $4BB612; newp: @CanSellItemHook2; t: RShtCall), // Shops unable to operate on some artifacts
    (p: $4AA19B; newp: @ExitCrashHook; t: RShtCall; size: 8), // Crash on exit
    (p: $47204A; newp: @FixLava1; t: RShtCall), // Lava hurting players in air
    (p: $47256E; newp: @FixLava2; t: RShtCall; size: 7), // Lava hurting players in air
    (p: $479B04; newp: @FixObelisk; t: RShtBefore; size: 6; Querry: hqFixObelisks), // Unicorn King appearing before obelisks are taken and respawning
    (p: $424E55; newp: @FixObelisk2; t: RShtAfter; Querry: hqFixObelisks), // Unicorn King appearing before obelisks are taken and respawning
    (p: $4255B3; newp: @FixParalyze; t: RShtCall), // Monsters can't cast Paralyze spell, but waste turn
    (p: $4637B7; newp: @WindowWidth; newref: true; t: RSht4; Querry: hqWindowSize), // Configure window size
    (p: $4637CD; newp: @WindowHeight; newref: true; t: RSht4; Querry: hqWindowSize), // Configure window size
    (p: $4E821C; newp: @ScreenToClientHook; t: RSht4; Querry: hqWindowSize), // Configure window size
    (p: $463D5F; old: $49D5EE; new: $49DC06; t: RShtCall; Querry: hqBorderless), // Borderless fullscreen
    (p: $463D5F; newp: @SwitchToFullscreenHook; t: RShtAfter; Querry: hqBorderless), // Borderless fullscreen
    (p: $463D0F; newp: @SwitchToWindowedHook; t: RShtAfter; Querry: hqBorderless), // Borderless fullscreen
    (p: $464C2A; size: 3; Querry: hqBorderless), // Borderless fullscreen
    (p: $464C34; new: $464C4E; t: RShtJmp; Querry: hqBorderless), // Borderless fullscreen
    (p: $464CCA; newp: @SwitchToFullscreenHook; t: RShtCall; size: 6; Querry: hqBorderless), // Borderless fullscreen
    (p: $464CD0; new: $464EFA; t: RShtJmp; Querry: hqBorderless), // Borderless fullscreen
    (p: $464D09; size: 6; Querry: hqBorderless), // Borderless fullscreen
    (p: $464D14; old: $49DC06; newp: @SwitchToWindowedHook; t: RShtCall; size: $464D2D - $464D14; Querry: hqBorderless), // Borderless fullscreen
    (p: $464D3F; new: $464EFA; t: RShtJmp; size: 6; Querry: hqBorderless), // Borderless fullscreen
    (p: $464C50; old: int(_Windowed); newp: @Options.BorderlessWindowed; t: RSht4; Querry: hqBorderless), // Borderless fullscreen
    (p: $46296E; old: int(_Windowed); newp: @Options.BorderlessWindowed; t: RSht4; Querry: hqBorderless), // Borderless fullscreen
    (p: $462992; old: int(_Windowed); newp: @Options.BorderlessWindowed; t: RSht4; Querry: hqBorderless), // Borderless fullscreen
    (p: $4BC2B3; newp: @DrawMovieHook; t: RShtBefore; Querry: hqFixSmackDraw), // Compatible movie render
    (p: $4BCA69; old: $74; new: $EB; t: RSht1; Querry: hqFixSmackDraw), // Compatible movie render
    (p: $4BCABF; old: $840F; new: $E990; t: RSht2; Querry: hqFixSmackDraw), // Compatible movie render
    (p: $49F22D; old: $49E9C0; newp: @SmackDrawHook1; t: RShtCallStore; Querry: hqFixSmackDraw), // Compatible movie render
    (p: $49F1F3; old: $49EAB2; newp: @SmackDrawHook1; t: RShtCallStore; Querry: hqFixSmackDraw), // Compatible movie render
    (p: $4BCBE6; old: $49F249; newp: @SmackDrawHook2; t: RShtCallStore; Querry: hqFixSmackDraw), // Compatible movie render
    (p: $4BD0FD; newp: @SmackLoadHook; t: RShtBefore; Querry: hqFixSmackDraw), // Compatible movie render
    (p: $4BC922; old: $4BDCEB; newp: @BinkDrawHook1; t: RShtCallStore; Querry: hqFixSmackDraw), // Compatible movie render
    (p: $4BC962; old: $74; new: $EB; t: RSht1; Querry: hqFixSmackDraw), // Compatible movie render
    (p: $4BC9C7; old: $49F377; newp: @BinkDrawHook2; t: RShtCallStore; Querry: hqFixSmackDraw), // Compatible movie render
    (p: $4BDB07; newp: @BinkLoadHook; t: RShtBefore; size: 6; Querry: hqFixSmackDraw), // Compatible movie render
    (p: $4A383A; newp: @TrueColorHook; t: RShtAfter; size: 6; Querry: hqTrueColor), // 32 bit color support
    //(p: $4A37CA; newp: @TrueColorHookNew; t: RShtCall; Querry: hqTrueColor), // 32 bit color support
    (p: $49C862; new: $49C881; t: RShtJmp; size: 6; Querry: hqTrueColor), // 32 bit color support
    (p: $45BDA1; newp: @TrueColorShotHook; t: RShtBefore; size: 6; Querry: hqTrueColor), // 32 bit color support
    (p: $49C46B; old: $49E9C0; backup: @@LockSurface; newp: @TrueColorLloydHook; t: RShtCall; Querry: hqTrueColor), // 32 bit color support
//    (p: $49E052; newp: @TrueColorSW; t: RShtBefore; size: 6; Querry: hqTrueColor), // 32 bit color support
//    (p: $49B3AF; old: $74; new: $EB; t: RSht1; Querry: hqTrueColor), // 32 bit color support
    (p: $461B7F; size: 6; Querry: hqTrueColor), // 32 bit color support
    (p: $4635BA; size: 2; Querry: hqTrueColor), // 32 bit color support
//    (p: $49F05A; backup: @@TrueColorPixelFormatStd; newp: @TrueColorPixelFormat; t: RShtFunctionStart; size: 7; Querry: hqTrueColor), // 32 bit color support
//    (p: $49E0F5; newp: @TrueColorDrawBuffer; t: RShtAfter; size: 10; Querry: hqTrueColor), // 32 bit color support
//    (p: $49E095; size: 2; Querry: hqTrueColor), // 32 bit color support
  // trying to do hi-res
  {
    // bigger back buffer
    (p: $49B406; old: 640; new: 640*2; t: RSht4),
    (p: $49B410; old: 480; new: 480*2; t: RSht4),
    (p: $49B4A6; old: 640; new: 640*2; t: RSht4),
    (p: $49B4B0; old: 480; new: 480*2; t: RSht4),
    (p: $49B7D3; old: 640; new: 640*2; t: RSht4), // also effects full screen
    (p: $49B7DA; old: 480; new: 480*2; t: RSht4), // also effects full screen
    (p: $49E109; old: 640; new: 640*2; t: RSht4),
    (p: $49E113; old: 480; new: 480*2; t: RSht4),
    // render whole back buffer
    (p: $49B9C6; old: 640; new: 640*2; t: RSht4),
    (p: $49B9BF; old: 480; new: 480*2; t: RSht4),
    // IDirect3DViewport3->Clear2
    (p: $49B984; old: 640; new: 640*2; t: RSht4),
    (p: $49B98B; old: 480; new: 480*2; t: RSht4),
    // ViewPort
//    (p: $464B89; old: 640; new: 640*2; t: RSht4),
//    (p: $464B84; old: 366; new: 366*2; t: RSht4),
    (),
}
    //(),
    (p: $4E801C; newp: @MyDirectDrawCreate; t: RSht4; Querry: hqTrueColor), // 32 bit color support + HD
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    ()
  );

procedure ReadDisables;
var
  i: int;
begin
  with TIniFile.Create(AppPath+'mm8.ini') do
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
  if ReputationNumber then
    RSApplyHooks(HooksList, 7);
  if FreeTabInInventory then
    RSApplyHooks(HooksList, 8);
  if not StandardStrafe then
    RSApplyHooks(HooksList, 15);
  if MouseBorder < 0 then
    RSApplyHooks(HooksList, 16);
  if FixInfiniteScrolls then
    RSApplyHooks(HooksList, 17);
  if DisableAsyncMouse then
    RSApplyHooks(HooksList, 24);
  if (WindowWidth <> 640) or (WindowHeight <> 480) or BorderlessFullscreen then
    RSApplyHooks(HooksList, hqWindowSize);
  if BorderlessFullscreen then
    RSApplyHooks(HooksList, hqBorderless);

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
  if Options.NoCD and FileExists('Anims\Magicdod.vid') then
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
  if Options.FixSkyBitmap then
    RSApplyHooks(HooksList, 18);
  if Options.FixChestsByReorder then
    RSApplyHooks(HooksList, 19);
  if Options.FixTimers then
    RSApplyHooks(HooksList, 21);
  if Options.FixMovement then
    RSApplyHooks(HooksList, 23);
  if Options.FixHeroismPedestal then
    RSApplyHooks(HooksList, 25);
  if Options.FixObelisks then
    RSApplyHooks(HooksList, hqFixObelisks);
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
  @WindowProcStd:= @WindowProcStdImpl;
finalization
  if EmptyCur <> 0 then
    DestroyCursor(EmptyCur);
  // avoid hanging in case of exception on shutdown
  SetUnhandledExceptionFilter(@LastUnhandledExceptionFilter);
end.
