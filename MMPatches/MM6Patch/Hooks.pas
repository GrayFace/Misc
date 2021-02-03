unit Hooks;

interface

uses
  Windows, Messages, SysUtils, Classes, RSSysUtils, RSQ, Common, RSCodeHook,
  Math, MP3, RSDebug, IniFiles, MMSystem, Graphics, DirectDraw, DXProxy,
  RSResample, MMCommon, MMHooks;

procedure HookAll;
procedure ApplyDeferredHooks;

implementation

var
  QuickSaveUndone, SkipMouseLook: Boolean;
  _sprintfex: ptr; // Buka localization

//----- Functions

procedure OpenCharScreen;
begin
  if _CurrentMember^ = 0 then
    _CurrentMember^:= 1;
  _OpenInventory_result^:= _OpenInventory_part;
  _NeedRedraw^:= 1;
  ZeroMemory(_ObjectByPixel^, _ScreenW^*_ScreenH^*4);  // avoid crash
end;

function IncreaseRecoveryRateProc(v, n1: int; member:ptr):int; forward;

procedure QuickLoad;
begin
  _Paused^:= 1;
  pint($610444)^:= 1;
  _StopSounds;
  _SaveSlotsFiles^[0]:= 'quiksave.mm6';
  _DoLoadGame(0, 0, 0);
  pint($6199C0)^:= 3;
end;

//----- Map Keys

function GetAsyncKeyStateHook(vKey: Integer): SHORT; stdcall;
begin
  Result:= MyGetAsyncKeyState(MappedKeys[vKey and $ff]);
end;

//----- Run/Walk check

function RunWalkProc(ShiftState:word):boolean;
begin
  Result:= (ShiftState = 0) xor AlwaysRun xor
           (CapsLockToggleRun and (GetKeyState(VK_CAPSLOCK) and 1 <> 0));
{$IFDEF NoMok}
  Result:= not Result;
{$ENDIF}
end;

procedure RunWalkHook;
asm
  call RunWalkProc
  cmp al, false
 // StdCode
  mov eax, [$908DEC]
end;

//----- Called every tick. Quick Save, Always Run, keys related things

var
  LastMusicStatus, MusicLoopsLeft: int;

procedure KeysProc;
var
  nopause: Boolean;
  status, loops: int;
begin
  // MusicLoopsCount
  if MusicLoopsLeft <> 0 then
  begin
    status:= RedbookStatus;
    if not (status in [1, 2]) and (LastMusicStatus in [1, 2]) then
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
     and FileExists('saves\quiksave.mm6') then
    QuickLoad;

  // InventoryKey
  if CheckKey(Options.InventoryKey) and nopause then
  begin
    _CurrentCharScreen^:= 103;
    OpenCharScreen;
  end;

  // Pause the game while in Enchant Item screen
  if (_CurrentScreen^ = 103) and (_Paused^=0) then
    _PauseTime;

  // Shared keys proc
  CommonKeysProc;
end;

procedure KeysHook;
asm
  call KeysProc
  call _ProcessActions
end;

function WindowProcKeyProc(k: byte):int;
const
  ProcessChar: procedure(n1, n2, c: int) = ptr($417F90);
begin
  if pint($4D46BC)^ = 0 then
  begin
    Result:= MappedKeysBack[k];
    if (Result = k) and (MappedKeys[k] <> k) then
      Result:= 0;

    if not (pint($5F6F74)^ in [1, 2]) and (pint($4D46BC)^ = 0) then
    begin
      if (chr(Result) in [#9, #13, ' ', '0'..'9', 'A'..'Z']) then
        ProcessChar(0, 0, Result);
      if Result in [107, 109] then // +, -
        ProcessChar(0, 0, Result - 64);
    end;
  end else
    Result:= k;
end;

procedure WindowProcKeyHook;
const
  CurScreen = int(_CurrentScreen);
asm
  // CharScreenKey
  cmp ecx, Options.CharScreenKey
  jnz @std
  cmp [CurScreen], 7
  jnz @test0
  pop edx
  push $4546BD
  ret
@test0:
  cmp [CurScreen], 0
  jnz @std
  call OpenCharScreen
  pop edx
  push $454873
  ret

  // MappedKeys
@std:
  mov al, cl
  call WindowProcKeyProc
  mov ecx, eax
  sub eax, $D
  cmp eax, $66
end;

procedure WindowProcCharHook;
asm
  cmp dword ptr [$4D46BC], 0
  jz @exit
  push $417F90
@exit:
end;

//----- Fix Save/Load Slots

var
  SaveName: string;
  SaveSpecial: string = 'quiksave.mm6';
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
  _SaveScroll^:= max(0, min(_SaveScroll^, count - 10));
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
  ShowStatusText(GameSavedText);
  QuickSaveUndone:= false;
  SaveSpecial:= 'quiksave.mm6';
  if QuickSavesCount <= 1 then
    exit;
  s1:= Format('saves\quiksave%d.mm6', [QuickSavesCount]);
  DeleteFile(s1);
  for i := QuickSavesCount - 1 downto 2 do
  begin
    s2:= s1;
    s1:= Format('saves\quiksave%d.mm6', [i]);
    MoveFile(ptr(s1), ptr(s2));
    DeleteFile(s1);
  end;
  MoveFile('saves\quiksave.mm6', ptr(s1));
end;

procedure QuicksaveHook;
const
  QuiksaveStr: PChar = 'saves\quiksave.mm6';
asm
  cmp [esp + $24], 2
  jnz @norm

  push eax
  call QuicksaveProc
  pop eax

  pop ecx
  push QuiksaveStr
  jmp ecx
  
@norm:
  pop ecx
  push $4C051C
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
    name:= Format('quiksave%s.mm6', [s]);
    MoveFile(ptr(Format('quick%s.mm6', [s])), ptr(name));
    if _access(ptr(name)) <> -1 then
    begin
      StrCopy(_SaveSlotsFiles^[_SaveSlotsCount^], ptr(name));
      inc(_SaveSlotsCount^);
    end;
  end;
end;

procedure QuickSaveSlotHook;
const
  SaveSlotsCount = int(_SaveSlotsCount);
asm
  mov [SaveSlotsCount], edx
  call QuickSaveSlotProc
end;

procedure QuickSaveSlotHook2;
asm
  cmp eax, -1
  jnz @exit
  call QuickSaveSlotProc
  pop eax
  push $44E244
@exit:
end;

procedure QuickSaveNamesProc(fileName, caption: PChar);
var
  name: string;
begin
  if CompareMem(fileName, PChar('quiksave'), 8) then
  begin
    name:= fileName;
    name:= Copy(name, 9, length(name) - 12);
    if name <> '' then
      name:= QuickSaveDigitSpace + name;
    caption^:= #2;
    StrCopy(caption + 1, PChar(name));
  end;
end;

procedure QuickSaveNamesHook;
asm
  mov eax, esi
  mov edx, ebx
  call QuickSaveNamesProc
  pop eax
  push $4C0420
  jmp eax
end;

var
  QuickSaveNamesTmp: string;

function QuickSaveDrawProc(name: PChar): PChar;
begin
  if name^ = #2 then
  begin
    QuickSaveNamesTmp:= QuickSaveName + (name + 1);
    Result:= ptr(QuickSaveNamesTmp);
  end else
    Result:= name;
end;

procedure QuickSaveDrawHook;
asm
  push eax
  mov eax, [esp + 8]
  call QuickSaveDrawProc
  mov [esp + 8], eax
  pop eax
  mov edx, [$55BDB8]
end;

procedure QuickSaveDrawHook2;
asm
  push ecx
  mov eax, edx
  call QuickSaveDrawProc
  mov edx, eax
  pop ecx
  mov eax, [$55BDB8]
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

//----- Show Train Level

procedure TrainLevelProc(member, lev: int; str:PChar);
const
  CalcExp: function(a1,a2, lev:int):uint = ptr($499D10);
  Sprintf1: procedure(buf, str:PChar; a1:int) cdecl = ptr($4AE273);
  Sprintf2: procedure(buf, str:PChar; a1, a2:int) cdecl = ptr($4AE273);
  Buf1 = _TextBuffer1;
  Buf2 = _TextBuffer2;
  StrNeedExp = PPChar($56C098);
var exp, nexp, i:uint;
begin
  exp:= puint(member + 5152)^;
  nexp:= CalcExp(0, 0, lev);
  while nexp <= exp do
  begin
    inc(lev);
    nexp:= CalcExp(0, 0, lev);
  end;
  Sprintf1(Buf1, str, lev);
  Sprintf2(Buf2, StrNeedExp^, nexp - exp, lev + 1);
  i:= StrLen(Buf1);
  (Buf1 + i)^:= #10;
  StrCopy(Buf1 + i + 1, Buf2);
end;

procedure TrainLevelHook;
asm
  mov eax, esi
  mov ecx, [esp + 8]
  call TrainLevelProc
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
  push offset @after
@normal:
  sub esp, 26Ch
  inc eax
  jmp eax
@after:
  xor eax, eax
  mov [CurMember], eax
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
  MinDelay = pint1($42A239);
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
    blaster:= (pint(i + $14)^ and 2 = 0) and (pbyte(_ItemsTxt^ + $28*pint(i)^ + $15)^ = 8);
  end;
  i:= _Character_GetWeaponDelay(0, 0, member, shoot and not blaster);
  if (i < MinDelay^) and not (shoot or blaster) then
    i:= MinDelay^;
  i:= IncreaseRecoveryRateProc(i, 0, member);
  StrLCopy(_TextBuffer2, str, 499);
  Result:= StrLCat(_TextBuffer2, ptr(Format(RecoveryTimeInfo, [i])), 499);
end;

procedure AttackDescriptionHook;
asm
  xor edx, edx
  mov eax, [esp + $34 - $24]
  call AttackDescriptionProc
  mov [esp + $34 - $24], eax
  push $413859
end;

procedure ShootDescriptionHook;
asm
  xor edx, edx
  inc edx
  mov eax, [esp + $34 - $24]
  call AttackDescriptionProc
  mov [esp + $34 - $24], eax
  push $413859
end;

//----- Important for PlayMP3, good in any case

procedure TravelHook;
asm
@loop:
  push 1
  call Sleep
  call edi
  cmp eax, esi
  jb @loop
end;

//----- Stop sounds on deactivate

procedure ActivateHook;
asm
  mov eax, [$9CF5A4]
  test eax, eax
  jz @std
  push [$9CF5C0]
  push eax
  call [$4B9280] // AIL_set_digital_master_volume
  xor edx, edx
  mov eax, [$9CF5A0]
  cmp eax, edx
  jz @std
  cmp [$9DE394], edx
  jnz @std
  cmp [$9DE364], edx
  jnz @std
  push eax
  call [$4B925C] // AIL_redbook_resume

@std:
  mov eax, [$6107D8]
end;

procedure DeactivateHook;
asm
  mov eax, [$9CF5A4]
  test eax, eax
  jz @std
  push 0
  push eax
  call [$4B9280] // AIL_set_digital_master_volume
  mov eax, [$9CF5A0]
  test eax, eax
  jz @std
  push eax
  call [$4B923C] // AIL_redbook_pause

@std:
  mov ecx, [$6107D8]
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
const
  lod = $4CB6D0; // icons.lod
  pushProc = $4B8B08;
asm
  cmp ecx, lod
  jnz @std
  push ecx
  mov eax, [esp + 12]
  mov edx, [esp + 16]
  call LodFilesProc
  pop ecx
  test eax, eax
  jz @std
  pop ecx
  ret 8

@std:
  pop eax
  push -1
  push pushProc
  jmp eax
end;

procedure LodFileStoreSize;
asm
  mov eax, [ecx + $14]
  mov Options.LastLoadedFileSize, eax
end;

procedure LodFileEvtOrStr;
asm
  mov ebp, Options.LastLoadedFileSize
  push $43972B
end;

//----- Scrolls reappearing in inventory bug

procedure ScrollReappearProc;
var
  dlg: int;
begin
  // Remove item from mouse
  FillMemory(ptr($90E81C), _ItemOff_Size, 0);
  // Make scrolls pause the game when used on paper doll
  dlg:= pint($4D50CC)^;
  if (dlg <> 0) and (pint(dlg + $18)^ <> 0) then
  begin
    AddAction(113, 0, 0);
    _ProcessActions;
  end;
end;

procedure ScrollReappearHook;
asm
  push ecx
  push edx
  call ScrollReappearProc
  pop edx
  pop ecx
  mov eax, dword ptr [$4D50CC]
  push $422000
end;

//----- Don't allow using scrolls by not recovered member

function FindActiveMember: int;
begin
  Result:= _FindActiveMember;
end;

procedure ScrollTestMember;
const
  TurnBased = int(_TurnBased);
asm
  // ebx = member index
  push ecx
  mov eax, $4876E0
  call eax
  pop ecx
  test eax, eax
  jz @exit
  cmp word ptr [ecx + _CharOff_Recover], 0 // recovering
  jnz @beep
  cmp dword ptr [TurnBased], 0
  jz @exit
  call FindActiveMember
  cmp eax, ebx
  jz @exit
@beep:
  pop eax
  mov ecx, PlayerNotActive
  mov edx, 2
  push $459EE0
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
end;

//----- DoubleSpeed

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
  mov eax, $10624DD3
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

//----- 'Increases rate of Recovery' enchantement didn't work

function IncreaseRecoveryRateProc(v, n1: int; member:ptr):int;
var
  rate: int;
begin
  rate:= 100 + _Character_CalcSpecialBonusByItems(0, 0, member, 17);
  Result:= RDiv(v*100, rate);
end;

procedure IncreaseRecoveryRateHook;
asm
  push ecx
  call IncreaseRecoveryRateProc
  pop ecx
  xor edx, edx
  mov dx, [ecx + _CharOff_Recover]
end;

procedure IncreaseRecoveryRateTBHook;
asm
  jge @a1
  mov eax, 30
@a1:
  mov ecx, edi
  shl ecx, 4
  mov ecx, [ecx+esi+1Ch]
  sar ecx, 3
  mov ecx, $944C68[ecx*4]
  call IncreaseRecoveryRateProc
end;

//----- ProgressiveDaggerTrippleDamage

procedure DaggerTrippleHook;
asm
  idiv ecx
  mov al, [esi + $62]
  and eax, $3F
  cmp edx, eax
end;

//----- Fix Smack volume

procedure SmackVolumePan(Smk:ptr; Unk1:int {FE000}; Volume:int; Balance:int = $7FFF); stdcall; external 'Smackw32.dll' name '_SmackVolumePan@16'; // Volume up to $10000

procedure SmackVolumeHook;
asm
  mov eax, dword ptr [$9CF5C0]
  mov ah, al
  push $7FFF
  push eax
  push $FE000
  mov eax, [ebx + $34]
  push eax
  call SmackVolumePan
  mov eax, dword ptr [$9B10E8]
end;

//----- New Smack

procedure SmackColorRemapWithTrans(a1, a2, a3, a4, a5: int); stdcall; external 'Smackw32.dll' name '_SmackColorRemapWithTrans@20';

procedure SmackColorRemapHook(a1, a2, a3, a4: int); stdcall;
begin
  SmackColorRemapWithTrans(a1, a2, a3, a4, 1000);
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


procedure ErrorProc(RetAddr: int; Reason: PChar; Ebx, Esi, Edi, Ebp, Esp, Ecx, Edx: int); stdcall;
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
  c.Eax:= 0;
  c.Ecx:= Ecx;
  c.Edx:= Edx;
  c.Eip:= RetAddr - 5;
  args.Context:= @c;
  if Reason = nil then
    args.ExceptObj:= EAssertionFailed.Create('(internal error)')
  else
    args.ExceptObj:= EAssertionFailed.Create(Reason);

  MyRaiseExceptionProc(cNonDelphiException, 0, 2, @args);
  AppendDebugLog(RSLogExceptions);
  args2.RetAddr:= ptr(RetAddr);
  MyRaiseExceptionProc(cDelphiTerminate, 0, 1, @args2);
  Exception(args.ExceptObj).Free;
end;

procedure ErrorHook1;
asm
  lea eax, [esp + $14]
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

  mov eax, dword ptr [$9B10B4]
end;

var
  ErrorHook2Std: ptr;

procedure ErrorHook2;
const
  TextBuffer = int(_TextBuffer1);
asm
  push ecx

  lea eax, [esp + $1C]
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

  pop ecx
  jmp ErrorHook2Std
end;

//----- MusicLoopsCount (main part is in KeysProc)

procedure ChangeTrackHook;
asm
  mov eax, Options.MusicLoopsCount
  dec eax
  mov MusicLoopsLeft, eax
  mov LastMusicStatus, 0

  // std
  mov al, byte ptr [$6107D8]
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
  lea eax, $5E2580[ebp*4]
  test byte ptr [eax + 2], 2
  jz @exit
  mov edx, edi
  call FixChest
  lea eax, [ecx + 1]
  cmp eax, ecx
@exit:
end;

//----- Limit blaster & bow speed with BlasterRecovery

procedure FixBlasterSpeed;
asm
  pop ebx
  cmp eax, Options.BlasterRecovery
  jnl @exit
  mov eax, Options.BlasterRecovery
@exit:
  add esp, $18
  ret 4
end;

//----- Support stereo MP3

procedure StereoHook;
asm
  mov [$9CF6F0], $20001
  mov [$9CF6F4], $5622
  mov [$9CF6F8], $15888
  mov [$9CF6FC], $100004
end;

//----- Fix Starburst, Meteor Shower
// ebx
var
  IsMonsterTargetHookStd: function(n1, n2, mon: int):LongBool;

function IsMonsterTargetHookProc(spell, n2, mon: int): LongBool;
begin
  Result:= IsMonsterTargetHookStd(spell, n2, mon);
  if not Result or not (spell in [9, 22]) then  exit;
  Result:= _ObjectByPixel^[_Mouse_X^ + _ScanlineOffset^[_Mouse_Y^]] <= 5120 shl 16;
end;

procedure IsMonsterTargetHook;
asm
  movzx eax, word ptr [ebx]
  jmp IsMonsterTargetHookProc
end;

//----- Fix party generation screen clouds, flame & arrows speed

var
  DrawPartyScreenStd: procedure;
  LastPartyScreenDraw: uint;

procedure DrawPartyScreenHook;
var
  k: uint;
  o1, o2, o3: int;
begin
  k:= timeGetTime;
  o1:= pint($6103F4)^; o2:= pint($610AB0)^; o3:= pint($61073C)^;
  DrawPartyScreenStd;
  if (k - LastPartyScreenDraw) < 15 then
  begin
    pint($6103F4)^:= o1; pint($610AB0)^:= o2; pint($61073C)^:= o3;
  end else
    LastPartyScreenDraw:= k;
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
  mov [esi + $13890], $10000000  // in Arena there's a check for available heap size
  xor edi, edi
end;

procedure MemoryFreeHook;
asm
  mov eax, ebp
  //mov edx, [esp + $10]
  call MemoryFreeProc
  push $421087
end;

procedure MemoryNewHook;
asm
  test ebx, ebx
  jge @ok
  xor eax, eax
  jmp @exit
@ok:
  mov eax, ebx
  call MemoryNewProc
@exit:
  push $4214DB
end;

//----- Fix global.txt parsing out-of-bounds

procedure GlobalTxtHook;
asm
  cmp edi, $56C180
  jge @exit
  push $4AF2CC
@exit:
end;

//----- Fix intro.str parsing out-of-bounds

procedure IntroStrHook;
asm
  mov eax, [esp + $F4 - $DC]
  dec eax
  xor ecx, ecx
end;

//----- Fix facet interception checking out-of-bounds

procedure FacetCheckHook;
asm
  cmp eax, 19
  jl @norm
  add dx, [ebx]
  ret
@norm:
  add dx, [ebx+eax*2+2]
end;

procedure FacetCheckHook2;
asm
  cmp eax, 19
  jl @norm
  add dx, [edi]
  ret
@norm:
  add dx, [edi+eax*2+2]
end;

procedure FacetCheckHook3;
asm
  xor edx, edx
  cmp ecx, 19
  jl @norm
  mov dx, [eax-78h-40]
  ret
@norm:
  mov dx, [eax-78h]
end;

//----- There may be facets without vertexes

procedure NoVertexFacetHook;
asm
  mov al, [ecx + $4d]
  test al, al
  jnz @norm
  pop eax
  push $48C6DF
  ret
@norm:
  mov al, [ecx + $4C]
  cmp al, 3
end;

//----- Correct door state switching: param = 3

procedure DoorStateSwitchHook;
asm
  shl ecx, 4
  add ecx, edx
  cmp edi, 3
  jnz @exit
  mov ax, [ecx + $4C]
  xor edi, edi
  dec ax
  jz @exit
  dec ax
  jz @exit
  inc edi
@exit:
end;

//----- Crash when moving between maps

var
  _ClearLevel: int = $454930;

procedure FreeSoundsHook;
asm
  call _ClearLevel
  mov ecx, $9CF700
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
  MaxH = pint($465243);
  PartyH = pint($908C70);
  PartyZ = pint($908CA0);
  DriftZ = pint($908CD4);
  PartyState = pint($90E838);
  z = -$6C;
  z2 = -$60;
  HasCeil = -$24;
  CeilH = -$3C;
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
    _Flying^:= 0;
    PartyState^:= PartyState^ or 1;
    v.X:= 0;
    v.Y:= 0;
  end;
end;

procedure MouseLookFlyHook1;
asm
  lea edx, [esp + $8C]
  push ebp
  push dword ptr [edx - $78]
  mov eax, esp
  call MouseLookFlyProc
  pop eax
  pop ebp
  mov [esp + $8C - $78], eax

  mov esi, [esp + $8C - $6C]
  mov eax, [esp + $8C - $54]
end;

procedure MouseLookFlyHook2;
asm
  mov ds:[$908CA8], eax
  lea edx, [esp + $60]
  push ebp
  push ebx
  mov eax, esp
  call MouseLookFlyProc
  pop ebx
  pop ebp
  mov ds:[esp + $60 - $44], ebx
  mov ds:[esp + $60 - $40], ebp
end;

//----- Fix condition removal spells (3 hours/days instead of 1, integer overflow)

procedure FixConditionSpells;
type
  TTarget = record
    p1, p2: int;
  end;
const
  Targets: array[1..8] of TTarget = (
    (p1: $424EC9; p2: $424EDE),
    (p1: $427282; p2: $427297),
    (p1: $427541; p2: $427556),
    (p1: $42774E; p2: $427763),
    (p1: $427A09; p2: $427A1E),
    (p1: $427D99; p2: $427DAE),
    (p1: $42801A; p2: $42802F),
    (p1: $428295; p2: $4282AA)
  );
var
  hook: TRSHookInfo;
  i: int;
begin
  FillChar(hook, SizeOf(hook), 0);
  hook.old:= $C0;
  hook.new:= $40;
  hook.t:= RSht1;
  for i := 1 to high(Targets) do
  begin
    hook.p:= Targets[i].p1 + 8;
    Assert(RSCheckHook(hook), SWrong);
    RSApplyHook(hook);
  end;
  hook.old:= 10800;
  hook.new:= 3600;
  hook.t:= RSht4;
  for i := 1 to high(Targets) do
  begin
    hook.p:= Targets[i].p2 + 2;
    Assert(RSCheckHook(hook), SWrong);
    RSApplyHook(hook);
  end;
end;

//----- negative/0 causes a crash in stats screen

procedure StatColorFixHook;
asm
  shl eax, 2
  cdq
  test ecx, ecx
  jnz @norm
  dec ecx
@norm:
  idiv ecx
end;

procedure FixStatColor;
const
  Targets: array[1..20] of int = ($413B10, $413C2A, $413D42, $413E5A, $413F72, $41408A, $4141A2, $4142CF, $4143F8, $41450C, $4147AE, $4148E1, $414BC1, $414CFA, $414E33, $414F6C, $41506A, $416B3D, $416CB6, $416E38);
var
  hook: TRSHookInfo;
  i: int;
begin
  FillChar(hook, SizeOf(hook), 0);
  hook.newp:= @StatColorFixHook;
  hook.t:= RShtCall;
  hook.size:= 6;
  for i := 1 to high(Targets) do
  begin
    hook.p:= Targets[i] - 4;
    RSApplyHook(hook);
  end;
end;


//----- Fix damage of weapon enchants (don't ignore resists)

function PicToDmg(pic: int): int;
begin
  case pic of
    5: Result:= 4; // Cold
    6: Result:= 3; // Elec
    7: Result:= 5; // Poison
    8: Result:= 2; // Fire
  else
    Assert(false, 'Unknown damage overlay');
    Result:= 0;
  end;
{
id  Overlay  Sprite
1   904      splat01a  Blood
2   905      splat01a  Blood
3   906      splat01a  Blood
4   907      splat01a  Blood
5   901      explo06b  Cold
6   902      explo13b  Elec
7   903      explo05a  Poison
8   900      effec10b  Fire
9   909      effec08a  Magic
10  908      EXPLO12A  Energy (Blaster)
}
end;

procedure FixBonusDamageProc;
asm
  // stoned?
  cmp [esi+118h], 0
  jl @norm
  jg @noeffect
  cmp [esi+114h], 0
  ja @noeffect

@norm:
  push eax
  push edx
  push ecx

  // get damage type
  cmp edi, 3
  ja @melee1
  mov eax, [esp + edi*4 + 16 + $34 - 8]
  jmp @after1
@melee1:
  mov eax, [edi - 4]
@after1:
  call PicToDmg

  // calculate new damage
  mov edx, [esp + 12]
  neg edx
  push edx  // Damage
  push eax  // DmgType
  push esi  // Monster
  mov ecx, $4D51D8
  mov eax, $421DC0
  call eax

  // decrease health
  sub word ptr [esi+28h], ax
  cmp eax, 0

  pop ecx
  pop edx
  pop eax
  jnz @exit  // has dmg - show effect, else remove it

@noeffect:
  cmp edi, 3
  ja @melee2
  dec edi
  jmp @exit
@melee2:  
  sub edi, 4
  dec ebp
@exit:
  add esp, 4
end;

procedure FixBonusDamageHook20;
asm
  push -20
  jmp FixBonusDamageProc
end;

procedure FixBonusDamageHook30;
asm
  push -30
  jmp FixBonusDamageProc
end;

procedure FixBonusDamageHook5;
asm
  push -5
  jmp FixBonusDamageProc
end;

procedure FixBonusDamageHook8;
asm
  push -8
  jmp FixBonusDamageProc
end;

procedure FixBonusDamageHook12;
asm
  push -12
  jmp FixBonusDamageProc
end;

procedure FixBonusDamageHookC;
asm
  sub ecx, eax
  push ecx
  jmp FixBonusDamageProc
end;

procedure FixBonusDamageHookD;
asm
  sub edx, eax
  push edx
  jmp FixBonusDamageProc
end;

procedure FixBonusDamageHookA;
asm
  sub eax, edx
  push eax
  jmp FixBonusDamageProc
end;

procedure FixBonusDamageHookBow20;
asm
  mov edi, 1
  push -20
  jmp FixBonusDamageProc
end;

procedure FixBonusDamageHookEDI;
asm
  inc ebp
  add edi, 4
  push ecx
  jmp FixBonusDamageProc
end;

procedure FixBonusDamageHookBowEDI;
asm
  inc edi
  push ecx
  jmp FixBonusDamageProc
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
  mov [$6107F0], al
end;

//----- Quick Save didn't work in Hive after destroying Reactor

procedure HiveSaveHook;
asm
  xor ebp, ebp
  cmp ebx, 1
  jz @exit
  mov [esp], $44F3D4
@exit:
end;

//----- Waiting didn't recover characters

procedure FixWaitHook;
asm
  push esi
  sal esi, 7
  test dword ptr ds:[$908DEC], 2
  jnz @doit
  sal esi, 1

@doit:
  mov ecx, ds:[$944C68]
  push esi
  call _Character_Recover
  mov ecx, ds:[$944C68 + 4]
  push esi
  call _Character_Recover
  mov ecx, ds:[$944C68 + 8]
  push esi
  call _Character_Recover
  mov ecx, ds:[$944C68 + 12]
  push esi
  call _Character_Recover

  pop esi
  push $4880A0
end;

//----- Subtract gold after autosave when trevelling

var
  TravelGold: int;

procedure TravelGoldFixHook1;
asm
  mov TravelGold, ecx
  xor ecx, ecx
  push $487680
end;

procedure TravelGoldFixHook2;
asm
  mov eax, TravelGold
  sub ds:[$908D50], eax
  mov eax, ds:[$4D50C4]
end;

//----- Don't show walk travel dialog when flying

procedure TravelWalkTriggerFixHook;
asm
  test cl, $8C
  jnz @bad
  mov edx, ds:[$908CE8]
  test edx, edx
  jz @ok
@bad:
  mov [esp], $45C60B
@ok:
end;

//----- Switch to 16 bit color when going windowed

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
  call AutoColor16Proc
  mov ecx, $1B
end;

//----- Autorun key like in WoW

function AutorunHook: int;
type
  PQueue = ^TQueue;
  TQueue = packed record
    n: int;
    key: array[0..29] of int;
  end;
const
  Queue = PQueue($6A72A0);
  Add: procedure(n1,n2, this, key: int) = ptr($467A50);
var
  i: int;
begin
  Result:= pint(_ActionQueue)^;
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

//----- Lloyd: take spell points and action after autosave

procedure LloydAutosaveFix;
asm
  // get back spell points and remove recovery delay
  mov ax, [esi + _CharOff_Recover]
  push eax
  mov word ptr [esi + _CharOff_Recover], 0
  mov eax, [esi + _CharOff_SpellPoints]
  push eax
  add eax, dword ptr [$4CAF10]
  mov [esi + _CharOff_SpellPoints], eax

  call _DoSaveGame

  // restore decreased spell points and recovery delay
  pop eax
  mov [esi + _CharOff_SpellPoints], eax
  pop eax
  mov [esi + _CharOff_Recover], ax
end;

//----- TP: take action after autosave

procedure TPAutosaveFix;
asm
  // remove recovery delay
  push edx
  xor eax, eax
  mov al, [$4D59B8]
  mov edi, _CharOff_Size
  mul eax, edi
  pop edx
  lea edi, [eax + $908F34 + _CharOff_Recover]
  mov ax, [edi]
  push eax
  mov word ptr [edi], 0

  call _DoSaveGame

  // restore recovery delay
  pop eax
  mov [edi], ax
end;

//----- Finger Of Death didn't give any experience

var
  FixFingerDeathBugStd: procedure(a1, a2, index: int);

procedure FixFingerDeathBug(a1, a2, index: int);
const
  MonsterExperience: procedure(a1, a2, exp: int) = ptr($421520);
begin
  MonsterExperience(0, 0, pint($56C1C0 + 72*pbyte($56F478 + $34 + $224*index)^)^);
  FixFingerDeathBugStd(0, 0, index);
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
  FindInLodPtr2 = $44CCA0 + 5;

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
  push ebx
  push ebp
  push esi
  mov esi, ecx
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
  push ebp
  push esi
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
    CanWrite: int; Name: PChar): LongBool = ptr($44CEE0);
  LodLoadChapter: function(_1, _2: int; This: ptr;
    Chapter: PChar): LongBool = ptr($44D020);
  LodClean: procedure(_1, _2: int; This: ptr) = ptr($44CE90);

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

procedure LoadCustomLods(Old: int; const Name: string; Chap: PChar);
begin
  with TRSFindFile.Create('Data\*.' + Name) do
    try
      while FindEachFile do
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
  LoadCustomLods(_IconsLod, 'icons.lod', 'icons');
  LoadCustomLods($610AB8, 'bitmaps.lod', 'bitmaps');
  LoadCustomLods($61AA10, 'sprites.lod',  'sprites08');
  LoadCustomLods($6104F8, 'games.lod', 'chapter');
  LoadLodsOld;
  ApplyMMHooksLodsLoaded;
end;

//----- Custom LODs - Vid

const
  _VidOff_N = $5C;
  _VidOff_Files = $4C;
  _VidOff_Handle = $54;
  VidArc1 = 'Anims1.vid';
  VidArc2 = 'Anims2.vid';

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
  mov eax, ebp
  call OpenVidsProc
  // std
  lea esi, [ebp + $5C]
  lea ebx, [ebp + $60]
  push $4A5C7E
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
  mov eax, [esi + $5C]
end;

//----- Custom LODs - Snd

const
  _Snd_N = pint($9CF5BC);
  _Snd_Files = pptr($9CF5B4);
  _Snd_Handle = pint($9CF5B8);

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
  mov eax, ebx
  call SelectSndFile
  inc eax
end;

procedure OpenSndHook2;
asm
  mov eax, [esp + 8]
  call SelectSndFile
end;

//----- Strafe in MouseLook

function StrafeOrWalkProc(key: int): bool;
begin
  Result:= MyGetAsyncKeyState(key) <> 0;
  if AlwaysStrafe or MouseLookOn then
    Result:= not Result;
end;

procedure StrafeOrWalkHook;
asm
  mov eax, [esp + 4]
  call StrafeOrWalkProc
  test ax, ax
  ret 4
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
  mov eax, ecx
  mov ecx, CurRemainder
  imul edx
  add eax, [ecx]
  adc edx, 0
  mov [ecx], ax
  add ecx, 4
  mov CurRemainder, ecx
  shrd eax, edx, $10
end;

procedure FixStrafe2;
asm
  mov eax, ecx
  imul edx
  add eax, $8000
  adc edx, 0
  shrd eax, edx, $10
end;

procedure FixStrafePlayer;
asm
  mov eax, ecx
  lea ecx, PlayerStrafe
  imul edx
  add eax, [ecx]
  adc edx, 0
  mov [ecx], ax
  add ecx, 4
  mov CurRemainder, ecx
  shrd eax, edx, $10
end;

procedure FixStrafeMonster1;
asm
  mov eax, ecx

  mov ecx, [esp + $94 - $80]
  lea ecx, [ecx*4 + ecx]
  lea ecx, MonsterStrafe[ecx*4]

  imul edx
  add eax, [ecx]
  adc edx, 0
  mov [ecx], ax
  add ecx, 4
  mov CurRemainder, ecx
  shrd eax, edx, $10
end;

procedure FixStrafeMonster2;
asm
  mov eax, ecx

  mov ecx, [esp + $54 - $40]
  lea ecx, [ecx*4 + ecx]
  lea ecx, MonsterStrafe[ecx*4]

  imul edx
  add eax, [ecx]
  adc edx, 0
  mov [ecx], ax
  add ecx, 4
  mov CurRemainder, ecx
  shrd eax, edx, $10
end;

procedure FixStrafeObject1;
asm
  mov eax, ecx

  mov ecx, [esp + $28 - 4]
  lea ecx, [ecx*4 + ecx]
  lea ecx, ObjectStrafe[ecx*4]

  imul edx
  add eax, [ecx]
  adc edx, 0
  mov [ecx], ax
  add ecx, 4
  mov CurRemainder, ecx
  shrd eax, edx, $10
end;

procedure FixStrafeObject2;
asm
  mov eax, ecx

  mov ecx, [esp + $44 - $28]
  lea ecx, [ecx*4 + ecx]
  lea ecx, ObjectStrafe[ecx*4]

  imul edx
  add eax, [ecx]
  adc edx, 0
  mov [ecx], ax
  add ecx, 4
  mov CurRemainder, ecx
  shrd eax, edx, $10
end;

//----- Fix Scholar not giving +5% exp

procedure FixScholarExp;
asm
  mov ecx, 4
  call _HasNPCProf
  test eax, eax
  jz @std
  add ebx, 5
@std:
  mov ecx, 14
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

//----- Don't waste black potion if it has no effect

procedure DontWasteBlackPotion;
asm
  lea eax, [ecx - $A3]
  cmp ecx, 181
  jl @exit
  cmp ecx, 187
  jg @exit
  lea ecx, [esi + $128 + ecx*4 - 181*4]
  cmp [ecx], ebp
  jz @exit
  mov [esp], $459EE5
@exit:
end;

//----- Fix crash with mm6hd.lua

procedure FixSmallScaleSprites;
asm
  cmp edx, 2
  jng @bad
  push $4453E0
  ret
@bad:
  mov [esp], $4918CF
end;

//----- Fix timers

type
  TTimerStruct = packed record
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
    TriggerTime: int64;
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

// 2 reasons: 1) game saved without patch 2) timer previously not present in EVT
procedure FixTimerValidate;
var
  i: int;
begin
  with GetMapExtra^ do
    for i:= 0 to 3 do
      if (LastVisitTime = 0) or (LastVisitTime - GetPeriodicTimer(i, true) > TimerPeriods[i]) then
        LastPeriodicTimer[i]:= LastVisitTime;
end;

procedure FixTimerRetriggerHook;
asm
  lea ecx, [esi-4]
  cmp [ecx].TTimerStruct.CmdType, $26
  jz @update
  cmp [esi+4], ebp  // check EachYear = 0, EachMonth = 0, EachWeek = 0
  jnz @start
  cmp [esi+8], bp
  jnz @start
// Handle timer that triggers at specific time each day
  mov eax, dword ptr [$908D08]  // Game.Time
  mov edx, dword ptr [$908D08+4]
  call TimerSetTriggerTime
  ret
@update:
  push edx
  call UpdatePeriodicTimer
  pop edx
@start:
  cmp edx, dword ptr [$908D08+4]  // NextTrigger < Game.Time?
  ja @std
  jb @fix
  cmp eax, dword ptr [$908D08]
  jnb @std
@fix:
  mov eax, dword ptr [$908D08]  // set to Game.Time
  mov edx, dword ptr [$908D08+4]
  mov [esp], $43E939  // Add Period again
@std:
  mov [esi+14h], eax
  mov [esi+18h], edx
end;

procedure FixTimerSetupHook1;
asm
  test ebp, ebp
  jnz @noRefill
  test edi, edi
  jnz @noRefill
  push $439BC0
  ret
@noRefill:
  mov eax, ebp
  mov edx, edi
  mov ecx, esi
  call TimerSetTriggerTime
  push $439DB3
end;

procedure FixTimerSetupHook2;
asm
  mov eax, dword ptr [$908D08]  // Game.Time
  mov edx, dword ptr [$908D08+4]
  mov ecx, esi
  call TimerSetTriggerTime
  push $439DB3
end;

//----- Place items vertically like in 7 and 8

procedure PlaceItemsVerticallyHook;
asm
  add esi, 14
  cmp esi, 126
  jl @ok
  sub esi, 125
  cmp esi, 14
@ok:
end;

//----- Town Portal wasting player's turn even if you cancel the dialog

var
  TPDelay: int;

procedure TPDelayHook1;
asm
  mov eax, [esp+$AAC-$A10]
  mov TPDelay, eax
  mov esi, [esp+$AAC-$A8C]
  push $429B58
end;

function TPDelayProc2(delay: int): ptr;
begin
  Result:= ptr(_PlayersArray + pbyte($4D59B8)^*_CharOff_Size);
  _Character_SetDelay(0,0, Result, delay);
  if _TurnBased^ then
    _TurnBased_CharacterActed;
end;

procedure TPDelayHook2;
const
  __ftol: int = $4AE24C;
  TurnBased = int(_TurnBased);
asm
  mov eax, TPDelay
  test eax, eax
  jng @skip

  // from 425D07
  mov ecx, dword ptr [TurnBased]
  test ecx, ecx
  jnz @TurnBased
  fld dword ptr [$61080C]
  fimul TPDelay
  fmul qword ptr ds:[$4B9318]
  call __ftol
  call TPDelayProc2
  jmp @skip

@TurnBased:
  movzx edx, byte ptr [$4D59B8]
  mov _TurnBasedDelays[edx*4], eax
  call TPDelayProc2

@skip:
  mov TPDelay, 0
  mov eax, dword ptr [$4D50CC]
end;

//----- Fix movement rounding problems - nerf jump

procedure FixMovementNerf;
asm
  shl eax, 3
  sub ecx, eax
  shl eax, 3
  add ecx, eax
end;

//----- Prevent monsters from jumping into lava etc.

var
  NoMonsterJumpDownLim: int;

procedure NoMonsterJumpDown1;
asm
  mov eax, ebx
  sub eax, Options.MonsterJumpDownLimit
  cmp byte ptr [esi+$3B], 0
  jz @NoFly
  mov eax, -30000
@NoFly:
  mov NoMonsterJumpDownLim, eax
  cmp word ptr [esi+$A2], 1
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

//----- Buy dialog out-of-bounds read when no active player

procedure FixBuyNoMember;
asm
  test dl, dl
  jnl @ok
  xor edx, edx
@ok:
  push 1
  mov esi, edx
  push edi
  push $489CFF
end;

//----- Blasters and some spells couldn't target rats
// They use Party_Height/2 instead of Party_Height/3,
// but targeting didn't account for it

procedure FixDragonTargeting;
const
  std: int = $4046F0;
asm
  movsx eax, word ptr [ebx]
  cmp eax, 102 // Blaster
  jz @dragon
  cmp eax, 30  // Acid Burst
  jz @dragon
  cmp eax, 39  // Blades
  jz @dragon
  cmp eax, 76  // Flying Fist
  jz @dragon
  cmp eax, 90  // Toxic Cloud
  jz @dragon
  cmp eax, 92  // Shrapmetal
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

//----- +2/+3 weapon skill NPCs didn't effect delay

function CheckWeaponNPCs: int;
begin
  Result:= 0;
  if _HasNPCProf(0,0, 15) then  inc(Result, 2);
  if _HasNPCProf(0,0, 16) then  inc(Result, 3);
  if _HasNPCProf(0,0, 46) then  inc(Result, 2);
end;

procedure FixWeaponDelayBonusByNPC;
asm
  and eax, $3F
  mov edi, eax
  call CheckWeaponNPCs
  add edi, eax
end;

//----- Make left click not only cancel right button menu, but also perform action

function RightThenLeftMouseHook: LongBool;
begin
  if _RightButtonPressed^ then
  begin
    _ReleaseMouse;
    SkipMouseLook:= true;
  end;
  Result:= false;
end;

//----- Shops buying blasters

procedure CanSellItemHook;
asm
  cmp [esp+$18 + $10], 3
  jnz @exit
  mov ecx, [__ItemsTxt]
  cmp dword ptr [ecx + eax + $10], 0  // Value = 0 in items.txt
  jnz @exit
  mov [esp], $4851F1
@exit:
  mov eax, [esp+$18 + $C]
  lea eax, [eax+eax*2]
end;

procedure CanSellItemHook2;
asm
  mov eax, [ecx]
  lea eax, [eax+eax*4]
  shl eax, 3
  add eax, [__ItemsTxt]
  cmp dword ptr [eax + $10], 0  // Value = 0 in items.txt
  jz @deny
  push $4A4C30
@deny:
  xor eax, eax
end;

//----- Crash on exit

procedure ExitCrashHook;
asm
  mov eax, [$9DE384]
  cmp eax, [$9DE388]
  jz @skip
  push eax
  call esi
@skip:
end;

//----- Configure window size (also see WindowProcHook)

function ScreenToClientHook(w: HWND; var p: TPoint): BOOL; stdcall;
begin
  Result:= ScreenToClient(w, p);
  if Result then
    p.y:= TransformMousePos(p.x, p.y, p.x);
end;

// Just disabling it if window size is irregular
procedure InstantMouseItemHook(_Std: ptr; _2, this: int);
var
  Std: procedure(_1, _2, this: int);
  r: TRect;
begin
  GetClientRect(_MainWindow^, r);
  NeedScreenWH;
  if (r.Right = SW) and (r.Bottom = SH) and not DXProxyActive then
  begin
    @Std:= _Std;
    Std(0, 0, this);
  end;
end;

//----- Borderless fullscreen (also see WindowProcHook)

procedure SwitchToWindowedHook;
begin
  Options.BorderlessWindowed:= true;
  ShowWindow(_MainWindow^, SW_SHOWNORMAL);
  SetWindowLong(_MainWindow^, GWL_STYLE, GetWindowLong(_MainWindow^, GWL_STYLE) or _WindowedGWLStyle^);
  ClipCursor(nil);
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
      Height:= 480;
      SmkScanline:= Scanline[479];
    end;
  end;
  ZeroMemory(SmkScanline, 640*480*2);
end;

procedure SmackDrawProc1(_1,_2: ptr; info: PDDSurfaceDesc2; _3,_4: ptr); stdcall;
begin
  info.lpSurface:= SmkScanline;
  info.lPitch:= 640*2;
end;

procedure SmackDrawHook1;
asm
  cmp dword ptr [__Windowed], 0
  jz @std
  mov [esp], $4A5EC0
  jmp SmackDrawProc1
@std:
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
  cmp dword ptr [__Windowed], 0
  jz @std
  mov edx, [esp + $88 + $C]
  cmp Options.SmoothMovieScaling, 0
  jnz @smooth
  xor edx, edx
@smooth:
  mov [esp], $4A605A
  jmp SmackDrawProc2
@std:
end;

procedure SmackLoadHook;
asm
  cmp dword ptr [__Windowed], 0
  jz @std
  mov eax, $C0000000
  cmp Options.SmoothMovieScaling, 0
  jnz @ok
  cmp [esp + $5C + $C], ebp
  jz @ok
  or al, 6
@ok:
  mov [esp], $4A6868
@std:
end;

//----- Allow window maximization

function GetRestoredRect(hWnd: HWND; var lpRect: TRect): BOOL; stdcall;
begin
  ShowWindow(hWnd, SW_SHOWNORMAL);
  Result:= GetWindowRect(hWnd, lpRect);
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
  _StopSounds; // sometimes the death kept talking
  if Result then
  begin
    if _IsMoviePlaying^ then
      _ExitMovie;
    QuickLoad;
  end;
end;

procedure DeathMovieHook;
asm
  call DeathMovieProc
  test al, al
  jz @std
  xor ebx, ebx
  mov [esp], $4541EF
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

//----- Postpone intro

procedure PostponeIntroHook;
const
  movs: array[0..2] of PChar = ('mm6Intro', 'jvc', '3dologo');
var
  i: int;
begin
  _AbortMovie^:= false;
  for i:= 2 downto 0 do
    if (i = 0) or not NoIntoLogos and not _AbortMovie^ then
      _ShowMovie(0, 0, movs[i], i = 0);
end;

//----- Fix Static Charge cost, sync spells cost

procedure FixSpellsCost;
var
  i, j: int;
begin
  for i:= 1 to 99 do
    for j:= 1 to 3 do
      pword($4BDD6E + i*$E + j*2)^:= pbyte($56ABD0 + i*$1C + j + $18)^;
end;

//----- Fix Paralyze

procedure FixParalyzeHook;
const
  Monster_ChooseTargetMember: int = $4219B0;
  Character_DoBadThing: int = $480010;
  Party_Players = $944C68;
asm
  cmp word ptr [esi], 8080
  jnz @std
  cmp edx, 4
  jnz @std
  mov eax, [esi+4Ch]  // Owner
  sar eax, 3
  imul eax, _MonOff_Size
  add eax, _MonstersPtr
  push eax            // mon
  mov ecx, $4D51D8
  call Monster_ChooseTargetMember
  mov ecx, [Party_Players + eax*4] // this
  push 12             // thing
  call Character_DoBadThing
  mov edx, 4
@std:
end;

//----- Make HookPopAction useable with straight Delphi funcitons

procedure PopActionAfter;
asm
  mov ecx, [$4D5F48]
end;

//----- HooksList

var
  HooksList: array[1..283] of TRSHookInfo = (
    (p: $42ADE7; newp: @RunWalkHook; t: RShtCall), // Run/Walk check
    (p: $453AD3; old: $42ADA0; newp: @KeysHook; t: RShtCall), // My keys handler
    (p: $45456E; old: $417F90; newp: @WindowProcCharHook; t: RShtCall), // Map Keys
    (p: $4B916C; newp: @GetAsyncKeyStateHook; t: RSht4), // Map Keys
    (p: $44E43A; old: $44E1C0; backup: @FillSaveSlotsStd; newp: @FillSaveSlotsHook; t: RShtCall), // Fix Save/Load Slots
    (p: $44E9EC; old: $44E1C0; newp: @FillSaveSlotsHook; t: RShtCall), // Fix Save/Load Slots
    (p: $42F5EC; old: $42B453; backup: @ChooseSaveSlotBackup; newp: @ChooseSaveSlotHook; t: RSht4), // Fix Save/Load Slots
    (p: $42F8CC; old: $42DE20; backup: @SaveBackup; newp: @SaveHook; t: RSht4), // Fix Save/Load Slots
    (p: $44FDF7; newp: @QuicksaveHook; t: RShtCall), // Quicksave trigger
    (p: $44E23E; newp: @QuickSaveSlotHook; t: RShtCall; size: 6), // Show multiple Quick Saves
    (p: $44E1FD; newp: @QuickSaveSlotHook2; t: RShtCall), // Show multiple Quick Saves
    (p: $44E4EF; newp: @QuickSaveNamesHook; t: RShtCall), // Quick Saves names
    (p: $45067C; newp: @QuickSaveDrawHook; t: RShtCall; size: 6), // Quick Saves names Draw
    (p: $450523; newp: @QuickSaveDrawHook2; t: RShtCall), // Quick Saves names Draw
    (p: $44F832; old: $44D3F0; backup: @@SaveSetPauseStd; newp: @SaveSetPauseHook; t: RShtCall), // Autosave didn't pause time
    (p: $454596; newp: @WindowProcKeyHook; t: RShtCall; size: 6), // CharScreenKey, Map Keys
    (p: $453D27; backup: @@oldDeathMovie; newp: @DeathMovieHook; t: RShtCall), // Allow loading quick save from death movie + NoDeathMovie
    (p: $4571F1; new: $45718E; t: RShtJmp; Querry: 1), // NoCD
    (p: $4136FD; old: $4AE273; newp: @TrainLevelHook; t: RShtCall), // Show level to train to
    (p: $490285; old: $4902A0; new: $490287; t: RShtJmp2), // Fix XP compatibility
    (p: $453499; old: $1C244C89; new: int($FFB0C031); t: RSht4; size: 7), // Fix XP compatibility
    (p: $464CCC; old: $9A; new: 0; t: RSht4; Querry: 3), // Fix Walk Sound
    (p: $46667C; old: $DE; new: 0; t: RSht4; Querry: 3), // Fix Walk Sound
    (p: $4B8DEA; new: $4B8E22; t: RShtJmp), // Fix Vista
    (p: $43C7C0; newp: @InactiveMemberEventsHook; t: RShtCall; size: 6), // Multiple fauntain drinks bug
    (p: $48795D; newp: @CheckNextMemberHook; t: RShtCall; size: 8; Querry: 8), // Switch between inactive members in inventory screen
    (p: $41376C; old: $413859; newp: @AttackDescriptionHook; t: RShtJmp), // Show recovery time for Attack
    (p: $413799; old: $413859; newp: @ShootDescriptionHook; t: RShtJmp), // Show recovery time for Shoot
    (p: $481C79; old: $481C92; new: $481C80; t: RShtJmp2; Querry: 5), // Fix dual weapons recovery time
    (p: $49D9E1; newp: @TravelHook; t: RShtCall; size: 6), // Important for PlayMP3, good in any case
    (p: $454477; newp: @ActivateHook; t: RShtCall), // Stop sounds on deactivate
    (p: $4544DA; newp: @DeactivateHook; t: RShtCall), // Stop sounds on deactivate
    (p: $40C1A0; newp: @LodFilesHook; t: RShtCall; size: 7; Querry: 12), // Load files from DataFiles folder
    (p: $40C2F6; newp: @LodFileStoreSize; t: RShtCall), // Need when loading files
    (p: $43969F; newp: @LodFileEvtOrStr; t: RShtJmp; size: 9), // Load *.evt and *.str from DataFiles folder
    (p: $439789; t: RShtNop; size: 5),
    (p: $45974A; old: $422000; newp: @ScrollReappearHook; t: RShtCall; Querry: 17), // Scrolls reappearing in inventory bug
    (p: $4596EA; old: $4876E0; newp: @ScrollTestMember; t: RShtCall; Querry: 17), // Don't allow using scrolls by anyone except active member
    (p: $459703; old: $74; new: $EB; t: RSht1), // Scrolls - choose target when right-clicking portrait
    (p: $4172FD; old: $489C60; backup: @ReputationHookStd; newp: @ReputationHook; t: RShtCall; Querry: 7), // Show numerical reputation value
    (p: $41730C; old: $4BD5C8; newp: PChar('%s: '#12'%05d%d %s'#12'00000'); t: RSht4; Querry: 7), // Show numerical reputation value
    (p: $417328; old: $14; new: $18; t: RSht1; Querry: 7), // Show numerical reputation value
    (p: $420EFF; newp: @DoubleSpeedHook; t: RShtCall), // DoubleSpeed
    (p: $465309; old: $4AE24C; backup: @TurnSpeedStd; newp: @TurnSpeedHook; t: RShtCall), // TurnSpeed
    (p: $465335; old: $4AE24C; newp: @TurnSpeedHook; t: RShtCall), // TurnSpeed
    (p: $465361; old: $4AE24C; newp: @TurnSpeedHook; t: RShtCall), // TurnSpeed
    (p: $46538F; old: $4AE24C; newp: @TurnSpeedHook; t: RShtCall), // TurnSpeed
    (p: $463E2A; old: $4AE24C; newp: @TurnSpeedHook; t: RShtCall), // TurnSpeed
    (p: $463E51; old: $4AE24C; newp: @TurnSpeedHook; t: RShtCall), // TurnSpeed
    (p: $463E78; old: $4AE24C; newp: @TurnSpeedHook; t: RShtCall), // TurnSpeed
    (p: $463EA1; old: $4AE24C; newp: @TurnSpeedHook; t: RShtCall), // TurnSpeed
    (p: $45710D; old: $4C083C; newp: PChar('Might and Magic'#174' VI\1.0'); t: RSht4), // bug with registry key closing: small buffer
    (p: $457118; newp: ptr($457133); t: RShtJmp; size: 8), // bug with registry key closing: small buffer
    (p: $457136; old: $14; new: $18; t: RSht1), // bug with registry key closing: small buffer
    (p: $45715F; t: RShtNop; size: 7), // bug with registry key closing: small buffer
    (p: $482C8A; newp: @IncreaseRecoveryRateHook; t: RShtCall; size: 9), // 'Increases rate of Recovery' enchantement didn't work
    (p: $406889; newp: @IncreaseRecoveryRateTBHook; t: RShtCall; size: 7), // 'Increases rate of Recovery' enchantement didn't work
    (p: $482BBA; newp: ptr($1424448B); t: RSht4), // remove NWC 'Increases rate of Recovery' implementation attempt
    (p: $482BBE; newp: ptr($482C17); t: RShtJmp; size: $482C17 - $482BBF), // remove NWC 'Increases rate of Recovery' implementation attempt
    (p: $4885F9; newp: ptr($1024448B); t: RSht4), // remove NWC 'Increases rate of Recovery' implementation attempt
    (p: $4885FD; newp: ptr($488656); t: RShtJmp; size: $488656 - $4885FE), // remove NWC 'Increases rate of Recovery' implementation attempt
    (p: $482E60; old: 50; newp: @Options.IncreaseRecoveryRateStrength; newref: true; t: RSht4; Querry: -1), // strength of 'Increases rate of Recovery'
    (p: $47E51C; newp: @DaggerTrippleHook; t: RShtCall; Querry: 10), // ProgressiveDaggerTrippleDamage
    (p: $47E640; newp: @DaggerTrippleHook; t: RShtCall; Querry: 10), // ProgressiveDaggerTrippleDamage
    (p: $49D93F; old: 1500; newp: @Options.HorsemanSpeakTime; newref: true; t: RSht4; Querry: -1), // Horseman delay
    (p: $49D959; old: 2500; newp: @Options.BoatmanSpeakTime; newref: true; t: RSht4; Querry: -1), // Boatman delay
    (p: $4B9370; old: $43D55555; new: $43550000; t: RSht4), // Fix turn-based turn time
    (p: $4A64DA; newp: @SmackVolumeHook; t: RShtCall), // Fix Smack volume
    (p: $4A63BF; old: $7100; new: $FF40; t: RSht4), // Fix Smack volume
    (p: $4A638B; old: $7100; new: $FF40; t: RSht4), // Fix Smack volume
    (p: $4B92C8; newp: @SmackColorRemapHook; t: RSht4), // New Smack
    (p: $458982; newp: @ErrorHook1; t: RShtCall), // Report errors
    (p: $458ACF; old: $45B850; backup: @ErrorHook2Std; newp: @ErrorHook2; t: RShtCall), // Report errors
    (p: $48EA30; newp: @ChangeTrackHook; t: RShtCall), // MusicLoopsCount
    (p: $4AE273; newp: @_sprintfex; newref: true; t: RShtJmp; size: 6; Querry: 6), // Buka localization
    (p: $41E52E; newp: @FixChestHook; t: RShtCall; size: 8; Querry: 11), // Fix chests: place items that were left over
    (p: $481E8F; newp: @FixBlasterSpeed; t: RShtJmp), // Limit blaster & bow speed with BlasterRecovery
    (p: $420178; new: $42021E; t: RShtJmp; size: 6; Querry: hqNoPlayerSwap), // Remove buggy character swapping (with Ctrl + click)
    (p: $48FD66; newp: @StereoHook; t: RShtCall; size: 9), // Support stereo MP3
    (p: $42273E; old: $409170; backup: @@IsMonsterTargetHookStd; newp: @IsMonsterTargetHook; t: RShtCall; Querry: 16), // Fix Starburst, Meteor Shower
    (p: $452777; old: $450DC0; backup: @@DrawPartyScreenStd; newp: @DrawPartyScreenHook; t: RShtCall), // Fix party generation screen clouds, flame & arrows speed
    (p: $42125B; newp: @MemoryInitHook; t: RShtCall; size: 8), // Use Delphi memory manager
    (p: $420FB4; newp: @MemoryFreeHook; t: RShtJmp; size: 6), // Use Delphi memory manager
    (p: $4213E1; newp: @MemoryNewHook; t: RShtJmp; size: 10), // Use Delphi memory manager
    (p: $4456B8; old: $4AF2CC; newp: @GlobalTxtHook; t: RShtCall), // Fix global.txt parsing out-of-bounds
    (p: $46887B; old: 399; new: 398; t: RSht4), // Fix npcdata.txt parsing out-of-bounds
    (p: $46845F; old: $4C13F0; new: $4C13EC; t: RSht4), // Fix trans.txt parsing out-of-bounds
    (p: $46810F; old: $6A8804; new: $6A8800; t: RSht4), // Fix scroll.txt parsing out-of-bounds
    (p: $46903B; old: 280; new: 279; t: RSht4), // Fix npcnews.txt parsing out-of-bounds
    (p: $452DF4; newp: @IntroStrHook; t: RShtCall; size: 6), // Fix intro.str parsing out-of-bounds
    (p: $46741E; newp: @FacetCheckHook2; t: RShtCall), // Fix facet ray interception checking out-of-bounds
    (p: $46742C; newp: @FacetCheckHook; t: RShtCall), // Fix facet ray interception checking out-of-bounds
    (p: $467441; newp: @FacetCheckHook2; t: RShtCall), // Fix facet ray interception checking out-of-bounds
    (p: $467450; newp: @FacetCheckHook; t: RShtCall), // Fix facet ray interception checking out-of-bounds
    (p: $4674F5; newp: @FacetCheckHook2; t: RShtCall), // Fix facet ray interception checking out-of-bounds
    (p: $467503; newp: @FacetCheckHook; t: RShtCall), // Fix facet ray interception checking out-of-bounds
    (p: $467518; newp: @FacetCheckHook2; t: RShtCall), // Fix facet ray interception checking out-of-bounds
    (p: $467527; newp: @FacetCheckHook; t: RShtCall), // Fix facet ray interception checking out-of-bounds
    (p: $4675C4; newp: @FacetCheckHook2; t: RShtCall), // Fix facet ray interception checking out-of-bounds
    (p: $4675D3; newp: @FacetCheckHook; t: RShtCall), // Fix facet ray interception checking out-of-bounds
    (p: $4675E8; newp: @FacetCheckHook2; t: RShtCall), // Fix facet ray interception checking out-of-bounds
    (p: $4675F7; newp: @FacetCheckHook; t: RShtCall), // Fix facet ray interception checking out-of-bounds
    (p: $45E444; newp: @FacetCheckHook3; t: RShtCall; size: 6), // Fix facet interception checking out-of-bounds
    (p: $45E460; newp: @FacetCheckHook3; t: RShtCall; size: 6), // Fix facet interception checking out-of-bounds
    (p: $48C4E8; newp: @NoVertexFacetHook; t: RShtCall), // There may be facets without vertexes
    (p: $43FCBA; newp: @DoorStateSwitchHook; t: RShtCall), // Correct door state switching: param = 3
    (p: $453F9A; size: 5), // no need to clear level twice
    (p: $453C4A; size: 5), // no need to clear level twice
    (p: $4566EF; newp: @FreeSoundsHook; t: RShtCall), // Crash when moving between maps
    (p: $48B5F1; size: 5), // memory leak - unreferenced malloc
    (p: $42AF22; newp: @StrafeOrWalkHook; t: RShtCall; Querry: 15), // Strafe in MouseLook
    (p: $42AF89; newp: @StrafeOrWalkHook; t: RShtCall; Querry: 15), // Strafe in MouseLook
    (p: $465B14; newp: @MouseLookFlyHook1; t: RShtCall; size: 8), // Fix strafes and walking rounding problems
    (p: $464404; newp: @MouseLookFlyHook2; t: RShtCall), // Fix strafes and walking rounding problems
    (p: $430FE4; newp: @FixBonusDamageHook20; t: RShtCall), // Fix damage of weapon enchants (don't ignore resists)
    (p: $430FD3; newp: @FixBonusDamageHook30; t: RShtCall), // Fix damage of weapon enchants (don't ignore resists)
    (p: $4311EC; newp: @FixBonusDamageHook5; t: RShtCall), // Fix damage of weapon enchants (don't ignore resists)
    (p: $4311FD; newp: @FixBonusDamageHook8; t: RShtCall), // Fix damage of weapon enchants (don't ignore resists)
    (p: $43120E; newp: @FixBonusDamageHook12; t: RShtCall), // Fix damage of weapon enchants (don't ignore resists)
    (p: $4310C1; newp: @FixBonusDamageHookEDI; t: RShtCall; size: 8), // Fix damage of weapon enchants (don't ignore resists)
    (p: $43110F; newp: @FixBonusDamageHookC; t: RShtCall; size: 6), // Fix damage of weapon enchants (don't ignore resists)
    (p: $43113A; newp: @FixBonusDamageHookD; t: RShtCall; size: 6), // Fix damage of weapon enchants (don't ignore resists)
    (p: $431231; newp: @FixBonusDamageHookA; t: RShtCall; size: 6), // Fix damage of weapon enchants (don't ignore resists)
    (p: $4316BF; newp: @FixBonusDamageHookBowEDI; t: RShtCall), // Fix damage of weapon enchants (don't ignore resists)
    (p: $431708; newp: @FixBonusDamageHookC; t: RShtCall; size: 6), // Fix damage of weapon enchants (don't ignore resists)
    (p: $431732; newp: @FixBonusDamageHookD; t: RShtCall; size: 6), // Fix damage of weapon enchants (don't ignore resists)
    (p: $4317DE; newp: @FixBonusDamageHook5; t: RShtCall), // Fix damage of weapon enchants (don't ignore resists)
    (p: $4317EE; newp: @FixBonusDamageHook8; t: RShtCall), // Fix damage of weapon enchants (don't ignore resists)
    (p: $4317FE; newp: @FixBonusDamageHook12; t: RShtCall), // Fix damage of weapon enchants (don't ignore resists)
    (p: $431820; newp: @FixBonusDamageHookA; t: RShtCall; size: 6), // Fix damage of weapon enchants (don't ignore resists)
    (p: $431628; newp: @FixBonusDamageHookBow20; t: RShtCall; size: 9), // Fix damage of weapon enchants (don't ignore resists)
    (p: $40D225; old: $40CFE0; backup: @@TPFixStd; newp: @TPFixHook; t: RShtCall), // Pause the game in Town Portal screen
    (p: $457B68; newp: @DefaultSmoothTurnHook; t: RShtCall), // Use Smooth turn rate by default
    (p: $44F39E; newp: @HiveSaveHook; t: RShtCall; size: 6), // Quick Save didn't work in Hive after destroying Reactor
    (p: $4879D1; old: $4880A0; newp: @FixWaitHook; t: RShtCall), // Waiting didn't recover characters
    (p: $49D6E5; old: $487680; newp: @TravelGoldFixHook1; t: RShtCall), // Subtract gold after autosave when trevelling
    (p: $49D8D8; newp: @TravelGoldFixHook2; t: RShtCall), // Subtract gold after autosave when trevelling
    (p: $45C5E0; newp: @TravelWalkTriggerFixHook; t: RShtCall), // Don't show walk travel dialog when flying
    (p: $4573C6; t: RShtNop; size: $18), // Switch to 16 bit color when going windowed
    (p: $48DB2B; newp: @AutoColor16Hook; t: RShtCall), // Switch to 16 bit color when going windowed
    (p: $42B237; newp: @AutorunHook; t: RShtCall), // Autorun key like in WoW
    (p: $42E2CF; newp: @LloydAutosaveFix; t: RShtCall), // Lloyd: take spell points and action after autosave
    (p: $42E6BA; newp: @TPAutosaveFix; t: RShtCall), // TP: take action after autosave
    (p: $42E642; t: RShtNop; size: 5), // Town Portal triggered autosave even within a location
    (p: $4AEBAB; backup: @@FixPrismaticBugStd; newp: @FixPrismaticBug; t: RShtCall), // A beam of Prismatic Light in the center of screen that doesn't disappear
    (p: $45D65B; old: $403050; backup: @@FixFingerDeathBugStd; newp: @FixFingerDeathBug; t: RShtCall), // Finger Of Death didn't give any experience
    (p: $48BF32; old: 0; new: 1; t: RSht1), // Fix DLV search in games.lod
    (p: $46DB57; old: 0; new: 1; t: RSht1), // Fix ODM search in games.lod
    (p: $493883; old: $FD; new: $ED; t: RSht1), // Fix integer overflow crash indoors
    (p: $44CBC0; newp: @FindInLodAndSeekHook; t: RShtCall), // Custom LODs
    (p: $44CCA0; newp: @FindInLodHook; t: RShtCall), // Custom LODs
    (p: $45761E; backup: @@LoadLodsOld; newp: @LoadLodsHook; t: RShtCall), // Custom LODs
    (p: $4A5C5B; newp: @OpenVidsHook; t: RShtJmp), // Custom LODs - Vid
    (p: $4A630A; newp: @OpenBikSmkHook; t: RShtCall), // Custom LODs - Vid(Smk)
    (p: $48FC6F; newp: @OpenSndsHook; t: RShtCall; size: 7), // Custom LODs - Snd
    (p: $48E0D0; newp: @OpenSndHook; t: RShtCall), // Custom LODs - Snd
    (p: $48E3E3; newp: @OpenSndHook2; t: RShtCall), // Custom LODs - Snd
    (p: $460D18; newp: @FixStrafeMonster1; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $460D38; newp: @FixStrafe1; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $460D5B; newp: @FixStrafe1; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $460D7E; newp: @FixStrafe1; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $460D9C; newp: @FixStrafe1; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $461B82; newp: @FixStrafeMonster2; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $461BA2; newp: @FixStrafe1; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $461BC5; newp: @FixStrafe1; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $461BE8; newp: @FixStrafe1; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $461C06; newp: @FixStrafe1; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $4626BD; newp: @FixStrafeObject1; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $4626DD; newp: @FixStrafe1; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $462700; newp: @FixStrafe1; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $462723; newp: @FixStrafe1; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $462741; newp: @FixStrafe1; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $46314E; newp: @FixStrafeObject2; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $46316E; newp: @FixStrafe1; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $463191; newp: @FixStrafe1; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $4631B4; newp: @FixStrafe1; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $4631D2; newp: @FixStrafe1; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $4645AC; newp: @FixStrafePlayer; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $4645CC; newp: @FixStrafe1; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $4645EF; newp: @FixStrafe1; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $464612; newp: @FixStrafe1; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $464630; newp: @FixStrafe1; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $465F12; newp: @FixStrafePlayer; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $465F32; newp: @FixStrafe1; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $465F55; newp: @FixStrafe1; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $465F78; newp: @FixStrafe1; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $465F96; newp: @FixStrafe1; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $464784; newp: @FixStrafe2; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $46479D; newp: @FixStrafe2; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $4647B6; newp: @FixStrafe2; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $466103; newp: @FixStrafe2; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $46611C; newp: @FixStrafe2; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $466135; newp: @FixStrafe2; t: RShtCall; Querry: 23), // Fix movement rounding problems
    (p: $4215C7; newp: @FixScholarExp; t: RShtCall), // Fix Scholar not giving +5% exp
    (p: $453484; backup: @OldStart; newp: @StartHook; t: RShtCall), // Call ApplyDeferredHooks after MMExt loads
    (p: $459103; newp: @DontWasteBlackPotion; t: RShtCall; size: 6), // Don't waste black potion if it has no effect
    (p: $416713; old: 1; new: 3; t: RSht1), // Show broken and unidentified items in red
    (p: $490BA2; old: $4453E0; newp: @FixSmallScaleSprites; t: RShtCall), // Fix small scale sprites crash with mm6hd.lua
    (p: $433A52; old: $1F400000; new: $7FFFFFFF; t: RSht4), // Infinite view distance in dungeons
    (p: $433ACE; old: $1F400000; new: $7FFFFFFF; t: RSht4), // Infinite view distance in dungeons
    (p: $43E9AC; newp: @FixTimerRetriggerHook; t: RShtCall; size: 6; Querry: 21), // Fix timers
    (p: $439B0D; newp: @FixTimerSetupHook1; t: RShtJmp; size: 8; Querry: 21), // Fix timers
    (p: $439CE0; newp: @FixTimerSetupHook2; t: RShtJmp; size: 8; Querry: 21), // Fix timers
    (p: $439940; newp: @FixTimerValidate; t: RShtBefore; Querry: 21), // Tix timers - validate last timers
    (p: $486FA1; newp: @PlaceItemsVerticallyHook; t: RShtCall; size: 7; Querry: 22), // Place items vertically like in 7 and 8
    (p: $47D75E; newp: @PlaceItemsVerticallyHook; t: RShtCall; size: 7; Querry: 22), // Place items vertically like in 7 and 8
    (p: $425E08; newp: @TPDelayHook1; t: RShtJmp), // Town Portal wasting player's turn even if you cancel the dialog
    (p: $42E756; newp: @TPDelayHook2; t: RShtCall), // Town Portal wasting player's turn even if you cancel the dialog
    (p: $465AD6; newp: @FixMovementNerf; t: RShtCall; Querry: 23), // Fix movement rounding problems - nerf jump
    (p: $4643E4; newp: @FixMovementNerf; t: RShtCall; Querry: 23), // Fix movement rounding problems - nerf jump
    (p: $4608EB; newp: @NoMonsterJumpDown1; t: RShtCall; size: 8), // Prevent monsters from jumping into lava etc.
    (p: $461019; newp: @NoMonsterJumpDown2; t: RShtCall), // Prevent monsters from jumping into lava etc.
    (p: $46104D; newp: @NoMonsterJumpDown2; t: RShtCall), // Prevent monsters from jumping into lava etc.
    (p: $489CFA; newp: @FixBuyNoMember; t: RShtJmp), // Buy dialog out-of-bounds read when no active player
    (p: $422790; old: $4046F0; newp: @FixDragonTargeting; t: RShtCall), // Blasters and some spells couldn't target rats
    (p: $481E1B; newp: @FixWeaponDelayBonusByNPC; t: RShtCall), // +2/+3 weapon skill NPCs didn't effect delay
    (p: $41140E; size: 5), // Don't resume time if mouse exits the window while right button is pressed
    (p: $440687; old: 72; new: 51; t: RSht1), // Evt commands couldn't operate on some skills
    (p: $441213; old: 52; new: 42; t: RSht1), // Evt commands couldn't operate on some skills
    (p: $442043; old: 52; new: 42; t: RSht1), // Evt commands couldn't operate on some skills
    (p: $442B35; old: 48; new: 38; t: RSht1), // Evt commands couldn't operate on some skills
    (p: $411CA0; newp: @RightThenLeftMouseHook; t: RShtCall), // Make left click not only cancel right button menu, but also perform action
    (p: $48519A; newp: @CanSellItemHook; t: RShtCall; size: 7), // Shops buying blasters
    (p: $4A53C9; old: $4A4C30; newp: @CanSellItemHook2; t: RShtCall), // Shops buying blasters
    (p: $48FFF0; newp: @ExitCrashHook; t: RShtCall; size: 9), // Crash on exit
    (p: $4B9224; newp: @ScreenToClientHook; t: RSht4), // Configure window size
    (p: $45B56D; old: $45ADF0; newp: @InstantMouseItemHook; t: RShtCallStore), // Configure window size
    (p: $457AEC; old: $48D840; new: $48DA70; t: RShtCall; Querry: hqBorderless), // Borderless fullscreen
    (p: $457AEC; newp: @SwitchToFullscreenHook; t: RShtAfter; Querry: hqBorderless), // Borderless fullscreen
    (p: $457AA8; newp: @SwitchToWindowedHook; t: RShtAfter; Querry: hqBorderless), // Borderless fullscreen
    (p: $45835A; size: 6; Querry: hqBorderless), // Borderless fullscreen
    (p: $4583E0; size: 1; Querry: hqBorderless), // Borderless fullscreen
    (p: $4583E6; old: $48D840; newp: @SwitchToFullscreenHook; t: RShtCall; Querry: hqBorderless), // Borderless fullscreen
    (p: $4583F8; size: 1; Querry: hqBorderless), // Borderless fullscreen
    (p: $4583F9; old: $48DA70; newp: @SwitchToWindowedHook; t: RShtCall; size: $458413 - $4583F9; Querry: hqBorderless), // Borderless fullscreen
    (p: $458426; old: $8B; new: $5E; t: RSht1; Querry: hqBorderless), // Borderless fullscreen - 'pop esi' from 45862B
    (p: $458427; new: $45863D; t: RShtJmp; Querry: hqBorderless), // Borderless fullscreen
    (p: $458353; old: int(_Windowed); newp: @Options.BorderlessWindowed; t: RSht4; Querry: hqBorderless), // Borderless fullscreen
    (p: $450CE4; old: int(_Windowed); newp: @Options.BorderlessWindowed; t: RSht4; Querry: hqBorderless), // Borderless fullscreen
    (p: $450D08; old: int(_Windowed); newp: @Options.BorderlessWindowed; t: RSht4; Querry: hqBorderless), // Borderless fullscreen
    (p: $45291C; old: int(_Windowed); newp: @Options.BorderlessWindowed; t: RSht4; Querry: hqBorderless), // Borderless fullscreen
    (p: $452942; old: int(_Windowed); newp: @Options.BorderlessWindowed; t: RSht4; Querry: hqBorderless), // Borderless fullscreen
    (p: $453255; old: int(_Windowed); newp: @Options.BorderlessWindowed; t: RSht4; Querry: hqBorderless), // Borderless fullscreen
    (p: $45327D; old: int(_Windowed); newp: @Options.BorderlessWindowed; t: RSht4; Querry: hqBorderless), // Borderless fullscreen
    (p: $4537AB; old: int(_Windowed); newp: @Options.BorderlessWindowed; t: RSht4; Querry: hqBorderless), // Borderless fullscreen
    (p: $4537D1; old: int(_Windowed); newp: @Options.BorderlessWindowed; t: RSht4; Querry: hqBorderless), // Borderless fullscreen
    (p: $45423C; old: int(_Windowed); newp: @Options.BorderlessWindowed; t: RSht4; Querry: hqBorderless), // Borderless fullscreen
    (p: $454261; old: int(_Windowed); newp: @Options.BorderlessWindowed; t: RSht4; Querry: hqBorderless), // Borderless fullscreen
    (p: $454B0C; old: int(_Windowed); newp: @Options.BorderlessWindowed; t: RSht4; Querry: hqBorderless), // Borderless fullscreen
    (p: $454B31; old: int(_Windowed); newp: @Options.BorderlessWindowed; t: RSht4; Querry: hqBorderless), // Borderless fullscreen
    (p: $4589D8; old: int(_Windowed); newp: @Options.BorderlessWindowed; t: RSht4; Querry: hqBorderless), // Borderless fullscreen
    (p: $4589FC; old: int(_Windowed); newp: @Options.BorderlessWindowed; t: RSht4; Querry: hqBorderless), // Borderless fullscreen
    (p: $458AFE; old: int(_Windowed); newp: @Options.BorderlessWindowed; t: RSht4; Querry: hqBorderless), // Borderless fullscreen
    (p: $458B22; old: int(_Windowed); newp: @Options.BorderlessWindowed; t: RSht4; Querry: hqBorderless), // Borderless fullscreen
    (p: $4A5A17; newp: @DrawMovieHook; t: RShtBefore; Querry: hqFixSmackDraw), // Configure window size
    (p: $4A5EC8; old: $840F; new: $E990; t: RSht2; Querry: hqFixSmackDraw), // Compatible movie render
    (p: $4A5EB5; newp: @SmackDrawHook1; t: RShtBefore; Querry: hqFixSmackDraw), // Compatible movie render
    (p: $4A604A; newp: @SmackDrawHook2; t: RShtBefore; Querry: hqFixSmackDraw), // Compatible movie render
    (p: $4A66A3; newp: @SmackLoadHook; t: RShtAfter; size: 6; Querry: hqFixSmackDraw), // Compatible movie render
    (p: $4573C6; size: 2; Querry: hqTrueColor), // 32 bit color support
    (p: $4B9018; newp: @MyDirectDrawCreate; t: RSht4; Querry: hqTrueColor), // 32 bit color support
    (p: $45748F; old: $CA0000; new: $CA0000 or WS_SIZEBOX or WS_MAXIMIZEBOX or WS_SYSMENU; t: RSht4), // Allow window resize
    (p: $458372; newp: @GetRestoredRect; t: RShtCall; size: 6), // Allow window maximization
    (p: $450CFD; newp: @GetRestoredRect; t: RShtCall; size: 6), // Allow window maximization
    (p: $452936; newp: @GetRestoredRect; t: RShtCall; size: 6), // Allow window maximization
    (p: $453271; newp: @GetRestoredRect; t: RShtCall; size: 6), // Allow window maximization
    (p: $4537C5; newp: @GetRestoredRect; t: RShtCall; size: 6), // Allow window maximization
    (p: $454255; newp: @GetRestoredRect; t: RShtCall; size: 6), // Allow window maximization
    (p: $454B26; newp: @GetRestoredRect; t: RShtCall; size: 6), // Allow window maximization
    (p: $4589F1; newp: @GetRestoredRect; t: RShtCall; size: 6), // Allow window maximization
    (p: $458B17; newp: @GetRestoredRect; t: RShtCall; size: 6), // Allow window maximization
    (p: $438A90; newp: @MinimapZoomHook; t: RShtFunctionStart; size: 6), // Remember minimap zoom indoors
    (p: $444CF5; old: $7F; new: $7D; t: RSht1), // TFT.bin was animated incorrectly (first frame was longer, last frame was shorter)
    (p: $4B9194; newp: @MyLoadCursor; t: RSht4), // Load cursors from Data
    (p: $453650; newp: @PostponeIntroHook; t: RShtAfter; Querry: hqPostponeIntro), // Postpone intro
    (p: $448F66; newp: @FixSpellsCost; t: RShtAfter), // Fix Static Charge cost, sync spells cost
    (p: $4A6D02; size: 6), // End game movies were unskippable
    (p: $457BA4; size: 2), // Intro movies were unskippable on 1st launch
    (p: $42AF6B; old: 10; new: 2; t: RSht1), // Snow X speed was effected by strafing too much
    (p: $42AFD3; old: -10; new: -2; t: RSht1), // Snow X speed was effected by strafing too much
    (p: $45C7A1; newp: @FixParalyzeHook; t: RShtBefore; size: 6; Querry: hqFixParalyze), // Fix Paralyze
    (p: HookPopAction; newp: @PopActionAfter; t: RShtBefore; size: 6), // Make HookPopAction useable with straight Delphi funcitons
    ()
  );

procedure ReadDisables;
var
  i: int;
begin
  with TIniFile.Create(AppPath+'mm6.ini') do
    try
      for i := low(HooksList) to high(HooksList) do
        if ReadBool('Disable', 'Hook'+IntToStr(i), false) then
          HooksList[i].Querry:= -100;
    finally
      Free;
    end;
end;

procedure HookAll;
var
  LastDebugHook: DWord;
begin
  CheckHooks(HooksList);
  ReadDisables;
  RSApplyHooks(HooksList);
  if FixWalk then
    RSApplyHooks(HooksList, 3);
  if UseMM6text and (RSLoadProc(_sprintfex, AppPath + 'mm6text.dll', '_sprintfex') <> 0) then
    RSApplyHooks(HooksList, 6);
  if ReputationNumber then
    RSApplyHooks(HooksList, 7);
  if FreeTabInInventory then
    RSApplyHooks(HooksList, 8);
  if not StandardStrafe then
    RSApplyHooks(HooksList, 15);
  if FixStarburst then
    RSApplyHooks(HooksList, 16);
  if FixInfiniteScrolls then
    RSApplyHooks(HooksList, 17);
  if PlaceItemsVertically then
    RSApplyHooks(HooksList, 22);
  if BorderlessFullscreen then
    RSApplyHooks(HooksList, hqBorderless);
  if NoPlayerSwap then
    RSApplyHooks(HooksList, hqNoPlayerSwap);
  FixConditionSpells;
  FixStatColor;
  ApplyMMHooks;
  NeedWindowSize;

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
  if Options.PlayMP3 then
    HookMP3;
  if Options.NoCD and FileExists('Anims\Anims2.vid') then
    RSApplyHooks(HooksList, 1);
  if pint(_NoIntro)^ = 2 then
    RSApplyHooks(HooksList, hqPostponeIntro);
  if Options.FixDualWeaponsRecovery then
    RSApplyHooks(HooksList, 5);
  if Options.ProgressiveDaggerTrippleDamage then
    RSApplyHooks(HooksList, 10);
  if Options.FixChests then
    RSApplyHooks(HooksList, 11);
  if Options.DataFiles then
    RSApplyHooks(HooksList, 12);
  if Options.FixTimers then
    RSApplyHooks(HooksList, 21);
  if Options.FixMovement then
    RSApplyHooks(HooksList, 23);
  if Options.CompatibleMovieRender then
    RSApplyHooks(HooksList, hqFixSmackDraw);
  if Options.SupportTrueColor then
    RSApplyHooks(HooksList, hqTrueColor);
  if Options.FixParalyze then
    RSApplyHooks(HooksList, hqFixParalyze);
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
