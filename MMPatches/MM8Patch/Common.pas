unit Common;

interface

uses
  Windows, Messages, SysUtils, Classes, IniFiles, RSSysUtils, RSQ, Math;

type
  TSaveSlotFile = array[0..279] of char;
  TSaveSlotFiles = array[0..19] of TSaveSlotFile;
  PSaveSlotFiles = ^TSaveSlotFiles;

const
  _Paused = pint($51D33C);
  _CurrentMember = pint($519350);
  _CurrentScreen = pint($4F37D8);
  _MainMenuCode = pint($6CEB24);
  _CurrentCharScreen = pint($5185A8);
  _NeedRedraw = pint($587ADC);
  _TextGameSaved = ppchar($601E88);
  _ItemInMouse = pint($B7CA64);
  _PartyMembers = $B7CA48;
  _Party_MemberCount = pint($B7CA60);
  _Party_State = $B7CA88;
  _Party_Direction = pint($B21560);
  _Party_Angle = pint($B21564);
  _Party_Height = $B20E94;
  _EscKeyUnkCheck = pint($519328);
  _TurnBased = pbool($B21728);
  _TurnBasedPhase = pint($509C9C);
  _TurnBasedObjectsInAir = $509CB4;
  _TurnBasedDelays = $BB2E0C;
  _CharactersTable = $B2187C;
  _BinkVideo = pptr($FFDE00);
  _SmackVideo = pptr($FFDDA8);
  _AutosaveFile = PPChar($601DDC);
  _AutosaveName = PPChar($601488);
  _QuicksaveFile = PPChar($601FF4);
  _QuicksaveName = PPChar($601FF8);
  _SaveScroll = pint($6CEA74);
  _SaveSlot = pint($6CEA78);
  _SaveSlot2 = pint($6F30C0);
  _SaveSlotsFiles = PSaveSlotFiles($6CADCC);
  _SaveSlotsCount = pint($6CACFC);
  _TextBuffer1 = pchar($5DF0E0);
  __ItemsTxt = $41CE60;
  _ItemsTxt = pint(__ItemsTxt);
  _MainWindow = puint($6F3934);
  _ScreenW = pint($F01A80);
  _ScreenH = pint($F01A7C);
  _ScreenBuffer = pptr($F01A6C);
  _TimeDelta = pint($51D354);
  _Flying = pint($B215A4);
  _MapMonsters = $61C540;
  _IsD3D = pbool($EC1980);
  _startinwindow = pbool($EC1984);
  __Windowed = $F019D8;
  _Windowed = pbool(__Windowed);
  _GreenColorBits = pint($F01A50);
  _RightButtonPressed = pbool($519354);
  _WindowedGWLStyle = pint($6F3978);
  _RedMask = pint($F01A58);
  _GreenMask = pint($F01A5C);
  _BlueMask = pint($F01A60);
  _IndoorOrOutdoor = pint($6F39A0);
  _Time = puint64($B20EBC);
  _AbortMovie = pbool($FFDDEC);
  _ViewMulOutdoor = pint($6F300C);
  _RenderRect = PRect($FFDE9C);
  __SpritesToDrawCount = $529F40;

  _ReleaseMouse: TProcedure = ptr($433136);
  _DoSaveGame: procedure(n1,unk, autoquick: int) = ptr($45CF27);
  _DoLoadGame: procedure(n1,n2, slot: int) = ptr($45C906);
  _FindActiveMember: function(n1: int = 0; n2: int = 0; this: int = $B20E90):int = ptr($491A55);
  _ShowStatusText: procedure(a0, seconds: int; text: PChar) = ptr($4496C5);
  _access: function(fileName: PChar; unk: int = 0): int cdecl = ptr($4DC7E5);
  _malloc: function(size:int):ptr cdecl = ptr($4D9F62);
  _new: function(size:int):ptr cdecl = ptr($4D9E0B);
  _PermAlloc: function(n1,n2: int; allocator: ptr; name: PChar; size, unk: int):ptr = ptr($424B4D);
  _PermAllocator = ptr($73F910);
  _LoadMapTrack: procedure = ptr($4AA3E7);
  _ExitScreen: procedure(n1: int = 0; n2: int = 0; a1: int = $1006148; a6: int = 0; a5: int = 0; a4: int = 0; a3: int = 1; a2: int = 27) = ptr($4D1D6A);
  _strcmpi: function(const s1, s2: PChar): int cdecl = ptr($4DA920);

  _LodFind: function(n1, n2, Lod, NoSort: int; Name: PChar): ptr = ptr($45EFFF); 
  _fread: function(var Buf; Size, Count: int; f: ptr): int cdecl = ptr($4DA641);
  _Deflate: procedure(n1: int; UnpSize: pint; var UnpBuf; PkSize: int; var Pk) = ptr($4D1EC0);
  _BitmapsLod = $72DC60;

  _LoadPalette: function(n1, n2, Palettes, PalId: int): int = ptr($489C9F);
  _LockSurface: function(surf: IUnknown; var desc; flags: int = 1): bool stdcall = ptr($49E9C0);
  
  _Chest_CanPlaceItem: function(n1, itemType, pos, chest: int): BOOL = ptr($41F293);
  _Chest_PlaceItem: procedure(n1, itemIndex, pos, chest: int) = ptr($41F55E);
  _ChestWidth = $4F3B04;
  _ChestHeight = $4F3B24;

  _Character_GetWeaponDelay: function(n1, n2: int; this:ptr; ranged: LongBool):int = ptr($48D62A);
  _Character_IsAlive: function(a1,a2, member:ptr):Bool = ptr($491514);
  _Character_WearsItem: function(n1,n2:int; this:ptr; id:int):BOOL = ptr($48CFC3);
  _Character_WearsItemWithEnchantSpec: function(n1,n2:int; this:ptr; slot, id:int):BOOL = ptr($48CF8A);
  _Character_GetSkillWithBonuses: function(n1,n2:int; this: ptr; skill: int):int = ptr($48EF4F);
  _Character_SetDelay: procedure(n1, n2: int; this: ptr; delay: int) = ptr($48DFF8);
  _TurnBased_CharacterActed: procedure(n1: int = 0; n2: int = 0; this: int = $509C98) = ptr($4049BA);

  _ReadRegStr: procedure(_: int; out Buf; Name, Default: PChar; BufSize: int) = ptr($462F28);

  _CharOff_Items = $484;
  _CharOff_ItemMainHand = $1C08;
  _CharOff_ItemBoots = $1C24;
  _CharOff_Recover = $1BF2;
  _CharOff_SpellPoints = $1BFC;
  _CharOff_Size = $1D28;
  
  _ItemOff_Size = $24;

  _MonOff_vx = $9C;
  _MonOff_vy = $9E;
  _MonOff_Size = $3CC;
  
const
  _SpritesLod = $71EFA8;
  _SpritesOld = _SpritesLod + $23C;
  SpritesMax = 10000;

const
  SWrong: string = 'This is not a valid mm8.exe file. Check failed at address %X';
  SIni = 'mm8.ini';
  SIni2 = 'mm8lang.ini';
  DummyFalse: Bool = false;

implementation

end.
