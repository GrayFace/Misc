unit Common;

interface

uses
  Windows, Messages, SysUtils, Classes, IniFiles, RSSysUtils, RSQ, Math;

type
  TSaveSlotFile = array[0..279] of char;
  TSaveSlotFiles = array[0..19] of TSaveSlotFile;
  PSaveSlotFiles = ^TSaveSlotFiles;

const
  _Paused = pint($4D5184);
  _UsingBook = pint($4D45CC);
  _CurrentScreen = pint($4BCDD8);
  _MainMenuCode = pint($5F811C);
  _FlipOnExit = pint($4C0E1C);
  _LoudMusic = pint($4C0E20);
  _Lucida_fnt = pptr($55BDB4);
  _CurrentMember = pint($4D50E8);
  _CurrentCharScreen = pint($4D4714);
  _NeedRedraw = pint($52D29C);
  _TextBuffer1 = pchar($55CDE0);
  _TextBuffer2 = pchar($55D5B0);
  _PartyMembers = $944C64;
  _TurnBased = pbool($908E30);
  _TurnBasedPhase = pint($4C7DF4);
  _TurnBasedObjectsInAir = $4C7E08;
  _TurnBasedDelays = $4C6CA8;
  _SaveSlot = pint($6A5F6C);
  _SaveScroll = pint($6A5F68);
  _SaveSlotsFiles = PSaveSlotFiles($5F883C);
  _SaveSlotsCount = pint($5FB9B4);
  __ItemsTxt = $41C4F5;
  _ItemsTxt = pint(__ItemsTxt);
  _ItemsTxtOff_Size = $30;
  _MainWindow = puint($61076C);
  _Party_X = pint($908C98);
  _Party_Y = pint($908C9C);
  _Party_Z = pint($908CA0);
  _Party_Direction = pint($908CA4);
  _Party_Angle = pint($908CA8);
  _Party_Height = $908C70;
  _ScreenW = pint($971074);
  _ScreenH = pint($971070);
  _ScreenBuffer = pptr($9B108C);
  _TimeDelta = pint($4D519C);
  _Flying = pint($908CE8);
  _MapMonsters = $56F478;
  _NoIntro = pbool($6A5F64);
  _Mouse_X = pint($6A6120);
  _Mouse_Y = pint($6A6124);
  _ObjectByPixel = PPIntegerArray($9B1090);
  _ScanlineOffset = PPIntegerArray($41F431);
  _PlayersArray = $908F34;
  __Windowed = $9B10B4;
  _Windowed = pbool(__Windowed);
  _GreenColorBits = pint($9B1118);
  _RightButtonPressed = pbool($4D50EC);
  _WindowedGWLStyle = pint($6107B0);
  _RedMask = pint($9B1120);
  _GreenMask = pint($9B1124);
  _BlueMask = pint($9B1128);
  _IndoorOrOutdoor = pint($6107D4);
  _Time = puint64($908D08);
  _IsMoviePlaying = pbool($9DE364);
  _AbortMovie = pbool($9DE338);
  _ViewMulOutdoor = pint($6296F4);
  _ViewMulIndoor = psingle($4D516C);
  _RenderRect = PRect($9DE3A8);

  _PauseTime: procedure(a1: int = 0; a2: int = 0; this: int = $4D5180) = ptr($420DB0);
  _ReleaseMouse: TProcedure = ptr($42FAC0);
  _SaveGameToSlot: procedure(n1,n2, slot:int) = ptr($44FEF0);
  _DoSaveGame: procedure(n1,unk, autosave: int) = ptr($44F320);
  _DoLoadGame: procedure(n1,n2, slot: int) = ptr($44EE50);
  _LoadGameStats: procedure(n1,n2, slot:int) = ptr($44EE50);
  _FindActiveMember: function(n1: int = 0; n2: int = 0; this: int = $908C70):int = ptr($487780);
  _ShowStatusText: function(n1, seconds: int; Text: PChar): int = ptr($442BD0);
  //_StrWidth: function(n1:int; str:PChar; fnt:ptr):int = ptr($442DD0);
  _OpenInventory_part: function(a1: int = 0; a2: int = 0; screen: int = 7):int = ptr($41FA50);
  _OpenInventory_result = pint($4D50CC);
  _access: function(fileName: PChar; unk: int = 0): int cdecl = ptr($4B885E);
  _malloc: function(size:int):ptr cdecl = ptr($4AE753);
  _PermAlloc: function(n1,n2: int; allocator: ptr; name: PChar; size, unk: int):ptr = ptr($421390);
  _PermAllocator = ptr($5FCB50);
  _ProcessActions: procedure = ptr($42ADA0);
  _LoadMapTrack: procedure = ptr($454F90);
  _PlaySound = $48EB40;
  _PlaySoundStruct = $9CF598;
  _HasNPCProf: function(n1,n2, prof: int): LongBool = ptr($467F30);
  _DrawInventory: procedure(n1,n2, member: int) = ptr($4165E0);
  _ExitMovie: procedure(_1: int = 0; _2: int = 0; _3: int = $9DE330) = ptr($4A5D10);
  _StopAllSounds: procedure(_: int = 0; __: int = 0; _3: int = $9CF598; _4: int = -1; _5: int = -1) = ptr($48FB40);

  _Chest_CanPlaceItem: function(n1, itemType, pos, chest: int): BOOL = ptr($41DE90);
  _Chest_PlaceItem: procedure(n1, itemIndex, pos, chest: int) = ptr($41E210);
  _ChestWidth = $4BD18C;
  _ChestHeight = $4BD1AC;

  _Character_GetWeaponDelay: function(n1, n2: int; this:ptr; ranged: LongBool):int = ptr($481A80);
  _Character_IsAlive: function(a1,a2, member:ptr):Bool = ptr($4876E0);
  _Character_CalcSpecialBonusByItems: function(n1,n2:int; member:ptr; SpecialEnchantment:int):int = ptr($482E00);
  _Character_Recover: function(n1, n2: int; this: ptr; time: int): Bool = ptr($482BB0);
  _Character_SetDelay: procedure(n1, n2: int; this: ptr; delay: int) = ptr($482C80);
  _TurnBased_CharacterActed: procedure(n1: int = 0; n2: int = 0; this: int = $4C7DF0) = ptr($404EB0);

  _CharOff_ItemMainHand = $142C;
  _CharOff_Items = $128;
  _CharOff_Recover = $137C;
  _CharOff_SpellPoints = $1418;
  _CharOff_Size = $161C;

  _ItemOff_Size = $1C;

  _MonOff_X = $7E;
  _MonOff_Y = $80;
  _MonOff_Z = $82;
  _MonOff_vx = $84;
  _MonOff_vy = $86;
  _MonOff_BodyRadius = $78;
  _MonOff_Size = $224;

const
  SWrong: string = 'This is not a valid mm6.exe file. Check failed at address %X';
  SIni = 'mm6.ini';
  SIni2 = 'mm6lang.ini';
  DummyFalse: Bool = false;
  _IsD3D: pbool = @DummyFalse;

implementation

end.
