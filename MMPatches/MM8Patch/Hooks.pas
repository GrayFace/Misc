unit Hooks;

interface

uses
  Windows, Messages, SysUtils, Classes, RSSysUtils, RSQ, Common, RSCodeHook,
  Math, MP3, RSDebug, IniFiles, Direct3D, Graphics, MMSystem, RSStrUtils,
  DirectDraw, DXProxy, RSResample, RSGraphics, MMCommon, D3DHooks, MMHooks,
  LayoutSupport;

procedure HookAll;
procedure ApplyDeferredHooks;

implementation

//----- Functions

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

procedure QuickLoad;
begin
  _Paused^:= 1;
  pint($6CAD00)^:= 1;
  _StopSounds;
  _SaveSlotsFiles[0]:= 'quiksave.dod';
  _DoLoadGame(0, 0, 0);
  pint($6CEB28)^:= 3;
end;

//----- Called every tick. Quick Save, keys related things

var
  LastMusicStatus, MusicLoopsLeft: int;

procedure KeysProc;
var
  nopause: Boolean;
  status, loops: int;
begin
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

  // QuickLoad
  if (QuickSavesCount >= 0) and CheckKey(Options.QuickLoadKey) and nopause
     and FileExists('saves\quiksave.dod') then
    QuickLoad;

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

  // Shared keys proc
  CommonKeysProc;
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
  push ecx
  push 8
  push 518
  mov ecx, esi
  call _Character_WearsItem
  test eax, eax
  pop ecx
  pop eax
  jz @1
  mov ecx, 20
@1:
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

//----- No HWL for sprites

procedure LoadSpriteD3DHook2;
asm
  inc dword ptr [esi+0EC9Ch]
  push $4AAEA9
  push $4A2E8B
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

procedure FacetCheckHook3;
asm
  cmp edx, 19*4
  jl @norm
  movzx edi, word ptr [eax-76h-40]
  jmp @std
@norm:
  movzx edi, word ptr [eax-76h]
@std:
  mov ebx, [esi+48h]
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

procedure NoVertexFacetHook2;
asm
  mov al, [esi + $5d]
  test al, al
  jnz @norm
  mov eax, 1
  mov [esp], $433DBC
@norm:
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
    if j <> -1 then
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
var
  Lang: array[0..103] of Char;
begin
  if not _IsD3D^ or not Options.SupportTrueColor then
    Options.UILayout:= '';
  LoadCustomLods(_IconsLod, 'icons.lod', 'icons');
  if _IsD3D^ then
    LoadCustomLodsD3D(_BitmapsLod, 'bitmaps', 'bitmaps')
  else
    LoadCustomLods(_BitmapsLod, 'bitmaps.lod', 'bitmaps');
  LoadCustomLods(_SpritesLod, 'sprites.lod', 'sprites08');
  LoadCustomLods($6CE838, 'games.lod', 'chapter');
  LoadCustomLods($6F30D0, 'T.lod', 'language');
  LoadCustomLods($6F330C, 'D.lod', 'language');
  _ReadRegStr(0, Lang[0], 'language_file', 'english', SizeOf(Lang));
  LoadCustomLods($6F30D0, PChar(Lang + 'T.lod'), 'language');
  LoadCustomLods($6F330C, PChar(Lang + 'D.lod'), 'language');
  LoadLodsOld;
  if _IsD3D^ then
    ApplyHooksD3D
  else
    ApplyMMHooksSW;
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
  mov [esi-$C], ecx
  mov [esi-8], eax
  push $445FE0  // add Period
end;

procedure FixTimerRetriggerHook2;
asm
  lea ecx, [esi-$C]
  cmp [ecx].TTimerStruct.CmdType, $26
  jz @update
  cmp eax, $15180  // daily?
  jnz @std
// Handle timer that triggers at specific time each day
  mov eax, dword ptr [$B20EBC]  // Game.Time
  mov edx, dword ptr [$B20EBC+4]
  call TimerSetTriggerTime
  mov [esp], $446080
  ret
@update:
  push edx
  call UpdatePeriodicTimer
  pop edx
@std:
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
  cmp [__Windowed], eax
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

//----- Monsters can't cast some spells, but waste turn

procedure FixUnimplementedSpells;
asm
  mov eax, [esp + $C]
  cmp eax, 20  // Implosion
  jz @bad
  cmp eax, 44  // Mass Distortion
  jz @bad
  cmp eax, 81  // Paralyze
  jz @bad

  jmp @std
@bad:
  xor eax, eax
  mov [esp], $425509
@std:
end;

//----- Configure window size (also see WindowProcHook)

function ScreenToClientHook(w: HWND; var p: TPoint): BOOL; stdcall;
begin
  Result:= ScreenToClient(w, p);
  if Result then
    p.y:= TransformMousePos(p.x, p.y, p.x);
end;

//----- Borderless fullscreen (also see WindowProcHook)

procedure SwitchToWindowedHook;
begin
  Options.BorderlessWindowed:= true;
  ShowWindow(_MainWindow^, SW_SHOWNORMAL);
  SetWindowLong(_MainWindow^, GWL_STYLE, GetWindowLong(_MainWindow^, GWL_STYLE) or _WindowedGWLStyle^);
end;

procedure SwitchToFullscreenHook;
begin
  Options.BorderlessWindowed:= false;
  ShowWindow(_MainWindow^, SW_SHOWMAXIMIZED);
  PostMessage(_MainWindow^, WM_SYSCOMMAND, SC_MAXIMIZE, 0);
  MyClipCursor;
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

//----- Allow window maximization

function GetRestoredRect(hWnd: HWND; var lpRect: TRect): BOOL; stdcall;
begin
  ShowWindow(hWnd, SW_SHOWNORMAL);
  Result:= GetWindowRect(hWnd, lpRect);
end;

//----- Inactive players could attack

procedure InactivePlayerActFix;
begin
  if (_CurrentMember^ <> 0) and
     (pword(int(GetCurrentMember) + _CharOff_Recover)^ > 0) then
  begin
    _CurrentMember^:= _FindActiveMember;
    _NeedRedraw^:= 1;
  end;
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
    QuickLoad;
end;

procedure DeathMovieHook;
asm
  call DeathMovieProc
  test al, al
  jz @std
  mov [esp], $461877
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

//----- A crash I once experienced in Adventurers Inn

procedure AdvInnCrashFix;
asm
  cmp esi, 0
  jnz @ok
  mov [esp], $421265
@ok:
end;

//----- IsWater and AnimateTFT bits didn't work together in D3D

procedure TFTWaterHook;
asm
  test ah, $40
  jz @std
  and al, $EF
@std:
end;

//----- Alt+Tab interpreted as Tab

function TabHook(n: int): int;
begin
  Result:= n;
  if GetAsyncKeyState(VK_ALT) < 0 then
    Result:= 40;
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

//----- Indoor FOV wasn't extended like outdoor

function FixIndoorFOVProcSW: int;
const
  base = 369;
begin
  with Options.RenderRect do
    Result:= Round(base*DynamicFovFactor(Right - Left, Bottom - Top));
  _ViewMulIndoorSW^:= Result;
end;

//----- Fix quick R+R+Esc press with encounter

procedure FixRestEncounter;
begin
  _ActionQueue.Count:= 0;
end;

//----- Postpone intro

procedure PostponeIntroHook;
asm
  push 0
  push 5
  mov eax, $4A7B7D
  call eax
end;

//----- Hints for non-interactive sprites

procedure TreeHintsHook;
asm
  cmp ShowTreeHints, 0
  jz @std
  mov eax, [ebp + $18]
  mov [esp+4], eax
@std:
end;

//----- Fix hiring in turn-based mode

procedure FixTurnBasedHire;
const
  EndTurnBased: int = $4063A9;
asm
  jnz @ok
  push 1
  mov ecx, $509C98
  call EndTurnBased
  mov dword ptr [$B21728], 0
  test esi, esi
@ok:
end;

//----- HooksList

var
  HooksList: array[1..318] of TRSHookInfo = (
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
    (p: $4614FF; backup: @@oldDeathMovie; newp: @DeathMovieHook; t: RShtCall), // Allow loading quick save from death movie + NoDeathMovie
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
    (p: $48D992; newp: @HeraldsBootsHook; t: RShtBefore), // Herald's Boots Swiftness didn't work
    (p: $464F5F; newp: @ErrorHook1; t: RShtCall; size: 6), // Report errors
    (p: $464FDA; newp: @ErrorHook2; t: RShtCall; size: 6), // Report errors
    (p: $4652F4; newp: @ErrorHook3; t: RShtCall; size: 6), // Report errors
    (p: $4A862D; newp: @ChangeTrackHook; t: RShtCall; size: 7), // MusicLoopsCount
    (p: $41F90A; newp: @FixChestHook; t: RShtCall; Querry: 11), // Fix chests: place items that were left over
    (p: $46516F; newp: @DDrawErrorHook; t: RShtJmp), // Ignore DDraw errors
    (p: $421847; old: $D75; new: $22EB; t: RSht2), // Remove code left from MM6
    (p: $4BE69E; old: $20; new: 8; t: RSht1), // Attacking big monsters D3D
    (p: $4A2EA4; old: $44FD37; newp: @LoadSpriteD3DHook; t: RShtCall), // No HWL for sprites
    (p: $4AAE9E; old: $4A2E8B; newp: @LoadSpriteD3DHook2; t: RShtJmp), // No HWL for sprites
    (p: $4AAD58; old: $4AAE15; newp: @LoadSpriteD3DHook3; t: RShtCall), // No HWL for sprites
    (p: $4AABF3; old: $4AACDC; newp: @LoadSpriteD3DHook4; t: RShtJmp6), // No HWL for sprites
    (p: $49C17A; size: 16), // No HWL for sprites
    (p: $49C1DA; size: 5), // No HWL for sprites
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
    (p: $46C09E; newp: @FacetCheckHook3; t: RShtCall; size: 7), // Fix facet interception checking out-of-bounds
    (p: $46C0B6; newp: @FacetCheckHook3; t: RShtCall; size: 7), // Fix facet interception checking out-of-bounds
    (p: $4981AC; newp: @NoVertexFacetHook; t: RShtCall), // There is a facet without a single vertex in Necromancers' Guild!
    (p: $433D91; newp: @NoVertexFacetHook2; t: RShtBefore; size: 6), // There is a facet without a single vertex in Necromancers' Guild!
    (p: $489EB1; newp: @PalettesHook; t: RShtCall), // Get rid of palettes limit in D3D
    (p: $4686D5; newp: ptr($4686FD); t: RShtJmp), // Ignore 'Invalid ID reached!'
    (p: $4AB73D; newp: ptr($4AB762); t: RShtJmp; size: 7), // Ignore 'Too many stationary lights!'
    (p: $44C37A; newp: ptr($44C3A2); t: RShtJmp), // Ignore 'Sprite outline currently Unsupported'
    (p: $4555E4; newp: ptr($4555FF); t: RShtJmp; size: 6), // rnditems.txt was freed before the processing is finished
    (p: $468519; old: $4686A8; backup: @@PressSpaceStd; newp: @PressSpaceHook; t: RShtCall), // D3D better space reaction
    (p: $4471C7; newp: @DoorStateSwitchHook; t: RShtCall; size: 6), // Correct door state switching: param = 3
    (p: $42E6F9; newp: @StrafeOrWalkHook; t: RShtCall; size: 6; Querry: 15), // Strafe in MouseLook
    (p: $42E72E; newp: @StrafeOrWalkHook; t: RShtCall; size: 6; Querry: 15), // Strafe in MouseLook
    (p: $4D9E11; backup: @@FixPrismaticBugStd; newp: @FixPrismaticBug; t: RShtCall), // A beam of Prismatic Light in the center of screen that doesn't disappear
    (p: $473184; newp: @MouseLookFlyHook1; t: RShtCall; size: 6), // Fix strafes and walking rounding problems
    (p: $471D57; newp: @MouseLookFlyHook2; t: RShtCall), // Fix strafes and walking rounding problems
    (p: $41E884; newp: @IDMonHook; t: RShtCall; size: 6), // Show resistances of monster
    (p: $416901; size: 14; Querry: 16), // Stop time by right click
    (p: $416F95; newp: @StatColorFixHook; t: RShtCall; size: 7), // negative/0 causes a crash in stats screen
    (p: $489DC1; newp: @PaletteSMulHook; t: RShtCall), // Control palette gamma
    (p: $489D8D; old: $4E8878; newp: @Options.PaletteVMul; t: RSht4), // Control palette gamma
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
    (p: $455173; newp: @FixItemsTxtHook; t: RShtJmp), // Fix items.txt: make special items accept standard "of ..." strings
    (p: $44607A; newp: @FixTimerRetriggerHook1; t: RShtJmp; size: 6; Querry: 21), // Fix immediate timer re-trigger
    (p: $44602D; newp: @FixTimerRetriggerHook2; t: RShtBefore; size: 7; Querry: 21), // Fix timers
    (p: $441036; newp: @FixTimerSetupHook1; t: RShtJmp; Querry: 21), // Fix timers
    (p: $441156; newp: @FixTimerSetupHook2; t: RShtJmp; size: 7; Querry: 21), // Fix timers
    (p: $440E0C; newp: @FixTimerValidate; t: RShtBefore; size: 6; Querry: 21), // Tix timers - validate last timers
    (p: $4296C8; newp: @TPDelayHook1; t: RShtJmp), // Town Portal wasting player's turn even if you cancel the dialog
    (p: $43129A; newp: @TPDelayHook2; t: RShtCall), // Town Portal wasting player's turn even if you cancel the dialog
    (p: $471D1A; newp: @FixMovementNerf; t: RShtCall; Querry: 23), // Fix movement rounding problems - nerf jump
    (p: $471D23; t: RShtNop; size: 3; Querry: 23), // Fix movement rounding problems - nerf jump
    (p: $473132; newp: @FixMovementNerf; t: RShtCall; Querry: 23), // Fix movement rounding problems - nerf jump
    (p: $47314B; t: RShtNop; size: 3; Querry: 23), // Fix movement rounding problems - nerf jump
    (p: $46E51B; newp: @NoMonsterJumpDown1; t: RShtCall; size: 8), // Prevent monsters from jumping into lava etc.
    (p: $46EACA; newp: @NoMonsterJumpDown2; t: RShtCall), // Prevent monsters from jumping into lava etc.
    (p: $461953; newp: @FixFullScreenBlink; t: RShtCall; size: 6; Querry: -100), // Light gray blinking in full screen
    (p: $40ECAD; newp: @FixBlitCopy; t: RShtCall; size: 6), // Draw buffer overflow in Arcomage
    (p: $40B15B; t: RShtNop; size: 2;), // Hang in Arcomage
    (p: $44D675; newp: @FixMonsterSummon; t: RShtJmp; size: 7; Querry: hqFixMonsterSummon), // Monsters summoned by other monsters had wrong monster as their ally
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
    (p: $431F0E; oldstr: #131#13#28#123#81#0#255; newstr: #137#29#28#123#81#0#144; t: RShtBStr; Querry: hqFixQuickSpell), // -1 being set as quick spell
    (p: $43217D; oldstr: #131#13#28#123#81#0#255; newstr: #137#29#28#123#81#0#144; t: RShtBStr; Querry: hqFixQuickSpell), // -1 being set as quick spell
    (p: $490058; size: 16), // Shops unable to operate on some artifacts
    (p: $4BB64A; size: 16), // Shops unable to operate on some artifacts
    (p: $49008E; newp: @CanSellItemHook; t: RShtCall; size: 6), // Shops unable to operate on some artifacts
    (p: $4BBA13; old: $4BB612; newp: @CanSellItemHook2; t: RShtCall), // Shops unable to operate on some artifacts
    (p: $4AA19B; newp: @ExitCrashHook; t: RShtCall; size: 8), // Crash on exit
    (p: $47204A; newp: @FixLava1; t: RShtCall), // Lava hurting players in air
    (p: $47256E; newp: @FixLava2; t: RShtCall; size: 7), // Lava hurting players in air
    (p: $479B04; newp: @FixObelisk; t: RShtBefore; size: 6; Querry: hqFixObelisks), // Unicorn King appearing before obelisks are taken and respawning
    (p: $424E55; newp: @FixObelisk2; t: RShtAfter; Querry: hqFixObelisks), // Unicorn King appearing before obelisks are taken and respawning
    (p: $4254BA; newp: @FixUnimplementedSpells; t: RShtBefore; size: 6; Querry: hqFixUnimplementedSpells), // Monsters can't cast some spells, but waste turn
    (p: $4E821C; newp: @ScreenToClientHook; t: RSht4), // Configure window size
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
    (p: $49C862; new: $49C881; t: RShtJmp; size: 6; Querry: hqTrueColor), // 32 bit color support
    (p: $461B7F; size: 6; Querry: hqTrueColor), // 32 bit color support
    (p: $4635BA; size: 2; Querry: hqTrueColor), // 32 bit color support
    (p: $4E801C; newp: @MyDirectDrawCreate; t: RSht4; Querry: hqTrueColor), // 32 bit color support + HD
    (p: $4A2D8A; newp: @FixMipmapsMemLeak; t: RShtAfter), // Mipmaps generation code not calling surface->Release
    (p: $41DE32; newp: @FixSpritesInMonInfo; t: RShtBefore; size: 6), // Fix sprites with non-zero transparent colors in monster info dialog
    (p: $41DF2F; newp: @FixSpritesInMonInfo; t: RShtBefore; size: 8), // Fix sprites with non-zero transparent colors in monster info dialog
    (p: $484B8A; newp: @FixDivCrash1; t: RShtCall; size: 6), // Fix int overflow crash in editor
    (p: $478FFD; newp: @FixDivCrash2; t: RShtCall; size: 6), // Fix int overflow crash in editor
    (p: $479341; newp: @FixDivCrash2; t: RShtCall; size: 6), // Fix int overflow crash in editor
    (p: $4636C3; old: $CA0000; new: $CA0000 or WS_SIZEBOX or WS_MAXIMIZEBOX or WS_SYSMENU; t: RSht4), // Allow window resize
    (p: $464C65; newp: @GetRestoredRect; t: RShtCall; size: 6), // Allow window maximization
    (p: $462986; newp: @GetRestoredRect; t: RShtCall; size: 6), // Allow window maximization
    (p: $43CC40; old: $D0; new: $C4; t: RSht4), // Support changing FOV indoor in D3D mode
    (p: $43CFEC; old: $D0; new: $C4; t: RSht4), // Support changing FOV indoor in D3D mode
    (p: $43D47A; old: $D0; new: $C4; t: RSht4), // Support changing FOV indoor in D3D mode
    (p: $48A804; old: $D0; new: $C4; t: RSht4), // Support changing FOV indoor in D3D mode
    (p: $420F1F; size: 2), // Inactive characters couldn't interact with chests
    (p: $420E14; size: 6; Querry: hqInactivePlayersFix), // Select inactive characters
    (p: $4316B2; newp: @InactivePlayerActFix; t: RShtBefore; size: 6; Querry: hqInactivePlayersFix), // Inactive players could attack
    (p: $42EBFF; newp: @FixTurnBasedWalking; t: RShtAfter; size: 6; Querry: hqFixTurnBasedWalking), // Fix multiple steps at once in turn-based mode
    (p: $42EBCE; newp: @FixTurnBasedWalking; t: RShtAfter; size: 6; Querry: hqFixTurnBasedWalking), // Fix multiple steps at once in turn-based mode
    (p: $42E669; newp: @FixTurnBasedWalking; t: RShtAfter; size: 6; Querry: hqFixTurnBasedWalking), // Fix multiple steps at once in turn-based mode
    (p: $42E6BF; newp: @FixTurnBasedWalking; t: RShtAfter; size: 6; Querry: hqFixTurnBasedWalking), // Fix multiple steps at once in turn-based mode
    (p: $48203C; newp: ptr($481F4F); t: RShtJmp; size: 6; Querry: hqNoWaterShoreBumps), // Fix bumpy water shore in software mode
    (p: $440169; newp: @MinimapZoomHook; t: RShtFunctionStart; size: 6), // Remember minimap zoom indoors
    (p: $4C9A9F; old: 476; new: 468; t: RSht4), // Left 8 pixels of paper doll area didn't react to clicks
    (p: $4C9B06; old: 476; new: 468; t: RSht4), // Left 8 pixels of paper doll area didn't react to clicks
    (p: $4C9B14; old: 164; new: 172; t: RSht4), // Left 8 pixels of paper doll area didn't react to clicks
    (p: $420FC8; newp: @AdvInnCrashFix; t: RShtBefore; size: 7), // A crash I once experienced in Adventurers Inn
    (p: $44B8EF; old: $7F; new: $7D; t: RSht1), // TFT.bin was animated incorrectly (first frame was longer, last frame was shorter)
    (p: $4AF05E; newp: @TFTWaterHook; t: RShtBefore), // IsWater and AnimateTFT bits didn't work together in D3D
    (p: $42ECAB; newp: @TabHook; t: RShtAfter), // Alt+Tab interpreted as Tab
    (p: $42EB31; newp: @TabHook; t: RShtAfter), // Alt+Tab interpreted as Tab
    (p: $4E8218; newp: @MyLoadCursor; t: RSht4), // Load cursors from Data
    (p: $4C6E37; old: 498; new: 498-6; t: RSht4), // Wrong minimap placement
    (p: $4C6E32; old: 635; new: 635-6; t: RSht4), // Wrong minimap placement
    (p: $4CDFAC; old: 498; new: 498-6; t: RSht4), // Wrong minimap placement
    (p: $4CDFA7; old: 635; new: 635-6; t: RSht4), // Wrong minimap placement
    (p: $43DA21; newp: @FixIndoorFOVProcSW; t: RShtAfter; Querry: hqFixIndoorFOV), // Indoor FOV wasn't extended like outdoor
    (p: $431A7A; newp: @FixRestEncounter; t: RShtBefore), // Fix quick R+R+Esc press with encounter
    (p: $460FA2; newp: @PostponeIntroHook; t: RShtAfter; size: 7; Querry: hqPostponeIntro), // Postpone intro
    (p: $44C264; newp: @TreeHintsHook; t: RShtAfter), // Hints for non-interactive sprites
    (p: $48C0A4; newp: @FixTurnBasedHire; t: RShtAfter; size: 7), // Fix hiring in turn-based mode
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
begin
  CheckHooks(HooksList);
  CheckHooksD3D;
  ExtendSpriteLimits;
  ReadDisables;
  RSApplyHooks(HooksList);
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
  if BorderlessFullscreen then
    RSApplyHooks(HooksList, hqBorderless);
  if FixInactivePlayersActing then
    RSApplyHooks(HooksList, hqInactivePlayersFix);
  if TurnBasedWalkDelay > 0 then
    RSApplyHooks(HooksList, hqFixTurnBasedWalking);
  if NoWaterShoreBumpsSW then
    RSApplyHooks(HooksList, hqNoWaterShoreBumps);
  if FixQuickSpell then
    RSApplyHooks(HooksList, hqFixQuickSpell);
  if FixIndoorFOV then
    RSApplyHooks(HooksList, hqFixIndoorFOV);
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
  if Options.NoCD and FileExists('Anims\Magicdod.vid') then
    RSApplyHooks(HooksList, 1);
  if pint(_NoIntro)^ = 2 then
    RSApplyHooks(HooksList, hqPostponeIntro);
  if Options.HardenArtifacts then
    RSApplyHooks(HooksList, 9);
  if Options.ProgressiveDaggerTrippleDamage then
    RSApplyHooks(HooksList, 10);
  if Options.FixChests then
    RSApplyHooks(HooksList, 11);
  if Options.DataFiles then
    RSApplyHooks(HooksList, 12);
  if Options.FixSkyBitmap then
    RSApplyHooks(HooksList, 18);
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
  if Options.FixUnimplementedSpells then
    RSApplyHooks(HooksList, hqFixUnimplementedSpells);
  if Options.FixMonsterSummon then
    RSApplyHooks(HooksList, hqFixMonsterSummon);
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
