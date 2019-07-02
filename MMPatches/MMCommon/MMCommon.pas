unit MMCommon;

interface

uses
  Windows, Messages, SysUtils, Classes, RSSysUtils, Math, Common, IniFiles,
  RSCodeHook, RSStrUtils, RSQ, Direct3D, Graphics, RSGraphics;

{$I MMPatchVer.inc}

const
  hqPostponeIntro = 2;
  hqFixObelisks = 26;
  hqWindowSize = 27;
  hqBorderless = 28;
  hqFixSmackDraw = 29;
  hqTrueColor = 30;
  hqMipmaps = 31;
  hqInactivePlayersFix = 32;
  hqFixTurnBasedWalking = 33;
  hqNoWaterShoreBumps = 34;
  hqFixUnimplementedSpells = 35;
  hqFixMonsterSummon = 36;
  hqNoPlayerSwap = 37;
  hqFixQuickSpell = 38;
  hqFixInterfaceBugs = 39;
  hqFixIndoorFOV = 40;
  hqLayout = 41;
  hqPaperDollInChests = 42;
  hqCloseRingsCloser = 43;
  hqPaperDollInChestsAndOldCloseRings = 44;
  hqPaperDollInChests2 = 45;
  hqPlaceChestItemsVertically = 46;
  hqFixInterfaceBugs2 = 47;
  hqFixChestsByCompacting = 48;
  hqSpriteAngleCompensation = 49;
  hqTex32Bit = 50;
  hqTex32Bit2 = 51;
  hqFixSFT = 52;
  hqPostponeIntro2 = 53;

{$IFDEF mm6}
  m6 = 1;
  m7 = 0;
  m8 = 0;
{$ELSEIF defined(mm7)}
  m6 = 0;
  m7 = 1;
  m8 = 0;
{$ELSEIF defined(mm8)}
  m6 = 0;
  m7 = 0;
  m8 = 1;
{$IFEND}

  HookEachTick = m6*$453AD3 + m7*$46334B + m8*$461320; // OnAction
  HookLoadLods = m6*$45761E + m7*$4655FE + m8*$463862; // set hook after
  HookWindowProc = m6*$454340 + m7*$463828 + m8*$4618FF; // use RShtFunctionStart or RShtBefore

type
  TOptions = packed record
    Size: int;
    MaxMLookAngle: int;                       //
    MouseLook: LongBool;                      //
    MouseLookUseAltMode: LongBool;            //
    CapsLockToggleMouseLook: LongBool;        //
    MouseFly: LongBool;                       //
    MouseWheelFly: LongBool;                  //
    MouseLookTempKey: int;                    //
    MouseLookChangeKey: int;                  //
    InventoryKey: int;                        //
    CharScreenKey: int;                       //
    DoubleSpeedKey: int;                      //
    QuickLoadKey: int;                        //
    AutorunKey: int;                          //
    HDWTRCount: uint;                         // (unused in MM6)
    HDWTRDelay: uint;                         // (unused in MM6)
    HorsemanSpeakTime: int;                   //
    BoatmanSpeakTime: int;                    //
    PaletteSMul: single;                      // (unused in MM6)
    PaletteVMul: single;                      // (unused in MM6)
    NoBitmapsHwl: LongBool;                   // (unused in MM6)
    PlayMP3: LongBool;                        //
    MusicLoopsCount: int;                     //
    HardenArtifacts: LongBool;                // (unused in MM6)
    ProgressiveDaggerTrippleDamage: LongBool; //
    FixChests: LongBool;                      //
    DataFiles: LongBool;                      //
    FixDualWeaponsRecovery: LongBool;         // (MM6 only)
    IncreaseRecoveryRateStrength: int;        // (MM6 only)
    BlasterRecovery: int;                     // (unused in MM8)
    FixSkyBitmap: LongBool;                   // (MM8 only)
    NoCD: LongBool;                           //
    FixChestsByReorder: LongBool;             //
    LastLoadedFileSize: int;                  //
    FixTimers: LongBool;                      //
    FixMovement: LongBool;                    //
    MonsterJumpDownLimit: int;                //
    FixHeroismPedestal: LongBool;             // (MM8 only)
    SkipUnsellableItemCheck: LongBool;        // (MM7 only)
    FixGMStaff: LongBool;                     // (MM7 only)
    FixObelisks: LongBool;                    // (MM8 only)
    BorderlessWindowed: LongBool;             // (set to false only when the game is in Borderless Fullscreen)
    CompatibleMovieRender: LongBool;          //
    SmoothMovieScaling: LongBool;             //
    SupportTrueColor: LongBool;               //
    RenderRect: TRect;                        //
    FixUnimplementedSpells: LongBool;         // (MM8 only)
    IndoorMinimapZoomMul: int;                //
    IndoorMinimapZoomPower: int;              //
    FixMonsterSummon: LongBool;               // (unused in MM6)
    FixInterfaceBugs: LongBool;               // (MM7 only)
    UILayout: PChar;                          // (unused in MM6)
    PaperDollInChests: int;                   //
    HigherCloseRingsButton: LongBool;         // (MM7 only)
    RenderBottomPixel: int;                   //
    TrueColorTextures: LongBool;              // (unused in MM6)
    ResetPalettes: LongBool;                  // (unused in MM6)
    FixSFT: LongBool;                         //
  end;

var
  Options: TOptions = (
    Size: SizeOf(TOptions);
    MaxMLookAngle: 200;
    BorderlessWindowed: true;
{$IFDEF mm8}
    RenderRect: (Left: 0; Top: 29; Right: 640; Bottom: 480 - 113);
{$ELSE}
    RenderRect: (Left: 8; Top: 8; Right: 468; Bottom: 352);
{$ENDIF}
    IndoorMinimapZoomMul: 1024;
    IndoorMinimapZoomPower: 10;
{$IFDEF mm8}
    RenderBottomPixel: 480-114;
{$ELSE}
    RenderBottomPixel: 351;
{$ENDIF}
  );

var
  QuickSavesCount, QuickSaveKey, TurnBasedSpeed, TurnBasedPartySpeed,
  WindowWidth, WindowHeight, RenderMaxWidth, RenderMaxHeight, MipmapsCount: int;

  MLookSpeed, MLookSpeed2: TPoint;
  MouseLookRememberTime: uint;
  MLookRightPressed: pbool = _RightButtonPressed;

  TurnSpeedNormal, TurnSpeedDouble: single;

  MouseDX, MouseDY: Double;

  FormatSettingsEN: TFormatSettings;

  StretchWidth, StretchWidthFull, StretchHeight, StretchHeightFull,
  ScalingParam1, ScalingParam2: ext;

  RecoveryTimeInfo, PlayerNotActive, SDoubleSpeed, SNormalSpeed,
  QuickSaveName, QuickSaveDigitSpace, SArmorHalved, SArmorHalvedMessage: string;

  CapsLockToggleRun, NoDeathMovie, FreeTabInInventory, ReputationNumber,
  AlwaysStrafe, StandardStrafe, MouseLookChanged, FixInfiniteScrolls,
  FixInactivePlayersActing, BorderlessFullscreen, BorderlessProportional,
  MouseLookCursorHD, SmoothScaleViewSW, WasIndoor, SpriteAngleCompensation,
  PlaceChestItemsVertically, FixChestsByCompacting: Boolean;
  {$IFNDEF mm6}
  NoVideoDelays, DisableAsyncMouse: Boolean;
  TurnBasedWalkDelay: int;
  MipmapsBase, MipmapsBasePat: TStringList;
  ViewMulFactor: ext = 1;
  {$ENDIF}

  TimersValidated: int64;

  DisabledHooks: TStringList;

{$IFDEF mm6}
  GameSavedText: string;

  UseMM6text, AlwaysRun, FixWalk, FixStarburst, PlaceItemsVertically,
  NoPlayerSwap: Boolean;

  MappedKeys, MappedKeysBack: array[0..255] of Byte;
{$ELSEIF defined(mm7)}
  UseMM7text, SupportMM7ResTool: Boolean;
{$ELSEIF defined(mm8)}
  NoWaterShoreBumpsSW, FixQuickSpell, FixIndoorFOV: Boolean;
  MouseBorder, StartupCopyrightDelay: int;
{$IFEND}

type
  PHwlBitmap = ^THwlBitmap;
  THwlBitmap = packed record
    HwlName: array[1..$14] of byte;
    HwlPalette: int;
    FullW: int;
    FullH: int;
    AreaW: int; // my added field
    AreaH: int; // my added field
    BufW: int;
    BufH: int;
    AreaX: int;
    AreaY: int;
    Buffer: ptr;
  end;
  PSpriteLine = ^TSpriteLine;
  TSpriteLine = packed record
    a1: int2;
    a2: int2;
    pos: PChar;
  end;
  PSpriteLines = ^TSpriteLines;
  TSpriteLines = packed array[0..(MaxInt div SizeOf(TSpriteLine) div 2)] of TSpriteLine;

  PSprite = ^TSprite;
  TSprite = packed record
    Name: array[1..12] of char;
    Size: int;
    w: int2;
    h: int2;
    Palette: int2;
    unk_1: int2;
    yskip: int2; // number of clear lines at bottom
    unk_2: int2; // used in runtime only, for bits
    UnpSize: int;
    Lines: PSpriteLines;
    buf: PChar;
  end;

  PSpriteD3D = ^TSpriteD3D;
  TSpriteD3D = packed record
    Name: PChar;
    Pal: int;
    Surface: ptr;
    Texture: ptr;
    AreaX: int;
    AreaY: int;
    BufW: int;
    BufH: int;
    AreaW: int;
    AreaH: int;
  end;
  PPSpriteD3DArray = ^PSpriteD3DArray;
  PSpriteD3DArray = ^TSpriteD3DArray;
  TSpriteD3DArray = array[0..MaxInt div SizeOf(TSpriteD3D) - 1] of TSpriteD3D;

  PLodBitmap = ^TLodBitmap;
  TLodBitmap = packed record
    FileName: array[1..16] of char;
    BmpSize: int;
    DataSize: int;
    w: int2;
    h: int2;
    BmpWidthLn2: int2;  // textures: log2(BmpWidth)
    BmpHeightLn2: int2;  // textures: log2(BmpHeight)
    BmpWidthMinus1: int2;  // textures: BmpWidth - 1
    BmpHeightMinus1: int2;  // textures: BmpHeight - 1
    Palette: int2;
    _unk: int2;
    UnpSize: int;
    Bits: int;  // Bits:  2 - multitexture,
    // Data...
    // Palette...
  end;

  TLoadedBitmap = packed record
    Rec: TLodBitmap;
    Image: PByteArray;
    ImageMip: array[1..3] of PByteArray;
    Palette16: PWordArray;
    Palette24: ptr;
  end;
  PLoadedBitmaps = ^TLoadedBitmaps;
  TLoadedBitmaps = packed record
    Items: array[0..999 - 500*m6] of TLoadedBitmap;
    Count: int;
  end;

  TLoadedPcx = packed record
    _1: array[1..20] of byte;
    w, h: int2;  // 20, 22
    _2: array[1..12] of byte;
    Buf: PWordArray;
  end;

  PMapExtra = ^TMapExtra;
  TMapExtra = packed record
    LastVisitTime: uint64;
    SkyBitmap: array[0..11] of char;
    DayBits, FogRange1, FogRange2, Bits, Ceiling: int;
    LastPeriodicTimer: array[0..3] of uint;
    function GetPeriodicTimer(i: int; first: Boolean = false): int64;
  end;

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

  PPDlgButton = ^PDlgButton;
  PDlgButton = ^TDlgButton;
  TDlgButton = packed record
    Left, Top, Width, Height, Right_, Bottom_: int;
    Shape: int;
    u1: int;
    Action, ActionInfo: int;
    u2: int;
    Pressed: Bool;
    UpperBtn, LowerBtn: PDlgButton;
    Parent: ptr;
    Sprites: array[1..5] of int;
    SpritesCount: int;
    ShortCut: Byte;
    Hint: array[1..103] of Char;
  end;

  PDrawSpriteD3D = ^TDrawSpriteD3D;
  TDrawSpriteD3D = record
    Texture: ptr;
    VertNum: int;
    Vert: array[0..3] of TD3DTLVertex;
    ZBuf: int;
    unk: array[0..1] of int;
    ObjRef: uint;
    SpriteToDrawIndex: int;
  end;

  PStatusTexts = ^TStatusTexts;
  TStatusTexts = record
    Text: array[Boolean] of array[0..199] of Char;
    TmpTime: int;
  end;

  PPoint3D = ^TPoint3D;
  TPoint3D = record
    x, y, z: int;
  end;

  PMoveToMap = ^TMoveToMap;
  TMoveToMap = record
    x, y, z: int;
    Direction, Angle: int;
    SpeedZ: int;
    Defined: Bool;
  end;

  PSpellBuff = ^TSpellBuff;
  TSpellBuff = record
    Expires: int8;
    Power, Skill, OverlayId: int2;
    Caster, Bits: Byte;
  end;
  PPartyBuffs = ^TPartyBuffs;
  TPartyBuffs = array[0..19 - m6*4] of TSpellBuff;

const
  _ActionQueue: PActionQueue = ptr(m6*$4D5F48 + m7*$50CA50 + m8*$51E330);
  PowerOf2: array[0..15] of int = (1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768);
  _IconsLodLoaded = PLoadedBitmaps(_IconsLod + $23C);
  //BitmapsLodLoaded = PLoadedBitmaps(_BitmapsLod + $23C);
  _ObjectByPixel = PPIntegerArray(m6*$9B1090 + m7*$E31A9C + m8*$F019B4);
{$IFNDEF MM8}
  _InventoryRingsShown = pbool(m6*$4D50F0 + m7*$511760);
  _InventoryShowRingsButton = PPDlgButton(m6*$4D4710 + m7*$507514);
  _InventoryPaperDollButton = PPDlgButton(m6*$4D46E0 + m7*$507510);
{$ENDIF}
  _StatusText = PStatusTexts(m6*$55BC04 + m7*$5C32A8 + m8*$5DB758);
  _NoMusicDialog = pbool(m6*$9DE394 + m7*$F8BA90 + m8*$FFDE88); // intro, win screen, High Council
  _PartyPos = PPoint3D(m6*$908C98 + m7*$ACD4EC + m8*$B21554);
  _CameraPos = PPoint3D(m6*$4D5150 + m7*$507B60 + m8*$519438);
  _ScreenMiddle = PPoint(m6*$9DE3C0 + m7*$F8BABC + m8*$FFDEB4);
  _DialogsHigh = pint(m6*$4D46BC + m7*$5074B0 + m8*$518CE8);
  _MoveToMap = PMoveToMap(m6*$551D20 + m7*$5B6428 + m8*$5CCCB8);
  _PartyBuffs = PPartyBuffs(m6*$908E34 + m7*$ACD6C4 + m8*$B21738);
  _ShowHits = pbool(m6*$6107EC + m7*$6BE1F8 + m8*$6F39B8);
  _NoIntro = pbool(m6*$6A5F64 + m7*$71FE8C + m8*$75CDF8);
  _ChestOff_Items = 4;
  _ChestOff_Inventory = 4 + _ItemOff_Size*140;
{$IFNDEF MM6}
  _SpritesD3D = PPSpriteD3DArray(_SpritesLod + $ECB0);
{$ENDIF}

{$IFNDEF mm6}
var
  Sprites: array[0..SpritesMax-1] of TSprite;
{$ENDIF}

procedure LoadIni;
procedure LoadExeMods;
{$IFNDEF mm6}
function GetMipmapsCountProc(var a: THwlBitmap; p: PChar): int;
procedure AddMipmapBase(p: PChar; v: int);
{$ENDIF}
function GetMapExtra: PMapExtra;

// make semi-transparent borders not black when scaling
procedure Wnd_CalcClientRect(var r: TRect);
procedure Wnd_PaintBorders(wnd: HWND; wp: int);
procedure Wnd_Sizing_GetWH(wnd: HWND; const r: TRect; var w, h: int);
procedure Wnd_Sizing(wnd: HWND; side: int; var r: TRect);
procedure Wnd_Sizing_SetWH(wnd: HWND; side: int; var r: TRect; dw, dh: int);
procedure CheckHooks(var Hooks);
procedure ClipCursorRel(r: TRect);
function DynamicFovFactor(const x, y: int): ext;
function GetViewMul: ext; inline;
procedure AddAction(action, info1, info2:int); stdcall;

var
  SW, SH: int;

procedure NeedScreenWH;
procedure __SetSpellBuff;

var
  SetSpellBuff: procedure(this: ptr; time: int64; skill, power, overlay, caster: int); stdcall;

implementation

procedure ReadDisabledHooks(const ss: string);
var
  ps: TRSParsedString;
  i: int;
begin
  DisabledHooks:= TStringList.Create;
  DisabledHooks.Sorted:= true;
  DisabledHooks.CaseSensitive:= true;
  DisabledHooks.Duplicates:= dupIgnore;
  ps:= RSParseString(ss, [',']);
  for i:= 0 to RSGetTokensCount(ps, true) do
    DisabledHooks.Add(Trim(RSGetToken(ps, i)));
end;

procedure LoadIni;
var
  ini, iniOverride: TIniFile;
  sect: string;

  function ReadString(const key, default: string): string;
  begin
    if iniOverride <> nil then
    begin
      Result:= iniOverride.ReadString(sect, key, #13#10);
      if Result <> #13#10 then
        exit;
    end;
    Result:= ini.ReadString(sect, key, #13#10);
    if Result = #13#10 then
    begin
      ini.WriteString(sect, key, default);
      Result:= default;
    end;
  end;

  function ReadInteger(const key: string; default: int): int;
  begin
    if iniOverride <> nil then
    begin
      Result:= iniOverride.ReadInteger(sect, key, 0);
      if (Result <> 0) or (iniOverride.ReadInteger(sect, key, 1) = 0) then
        exit;
    end;
    Result:= ini.ReadInteger(sect, key, 0);
    if (Result = 0) and (ini.ReadInteger(sect, key, 1) <> 0) then
    begin
      ini.WriteInteger(sect, key, default);
      Result:= default;
    end;
  end;

  function ReadBool(const key: string; default: Boolean): Boolean;
  begin
    Result := ReadInteger(key, Ord(Default)) <> 0;
  end;

  function ReadFloat(const key: string; default: Double): Double;
  var
    s: string;
  begin
    Assert(iniOverride = nil);
    s:= ini.ReadString(sect, key, '');
    if RSVal(s, Result) then  exit;
    ini.WriteString(sect, key, FloatToStr(default, FormatSettingsEN));
    Result:= default;
  end;

  function HasKey(const Key: string): Boolean;
  begin
    Result:= ini.ReadString(sect, key, #13#10) <> #13#10;
  end;

  procedure DeleteKey(const Key: string);
  begin
    if HasKey(Key) then
      ini.DeleteKey(sect, Key);
  end;

{$IFDEF mm6}
var
  i, j:int;
{$ELSE}
var
  i:int;
{$ENDIF}
begin
  GetLocaleFormatSettings($409, FormatSettingsEN);
  iniOverride:= nil;
  ini:= TIniFile.Create(AppPath + SIni);
  with Options do
    try
      sect:= 'Settings';
{$IFDEF mm6}
      _FlipOnExit^:= ReadInteger('FlipOnExit', 0);
      _LoudMusic^:= ReadInteger('LoudMusic', 0);
      AlwaysRun:= ReadBool('AlwaysRun', true);
      FixWalk:= ini.ReadBool(sect, 'FixWalkSound', true);
      FixDualWeaponsRecovery:= ini.ReadBool(sect, 'FixDualWeaponsRecovery', true);
      IncreaseRecoveryRateStrength:= ini.ReadInteger(sect, 'IncreaseRecoveryRateStrength', 10);
      FixStarburst:= ini.ReadBool(sect, 'FixStarburst', true);
      PlaceItemsVertically:= ini.ReadBool(sect, 'PlaceItemsVertically', true);
      NoPlayerSwap:= ini.ReadBool(sect, 'NoPlayerSwap', true);
      DeleteKey('FixCompatibility');
{$ELSE}
      NoVideoDelays:= ini.ReadBool(sect, 'NoVideoDelays', true);
      HardenArtifacts:= ini.ReadBool(sect, 'HardenArtifacts', true);
      DisableAsyncMouse:= ini.ReadBool(sect, 'DisableAsyncMouse', true);
{$ENDIF}
      CapsLockToggleRun:= ReadBool('CapsLockToggleRun', false);

      QuickSavesCount:= ReadInteger('QuickSavesCount', 3);
{$IFNDEF mm8}
      i:= ini.ReadInteger(sect, 'QuickSaveKey', 11) + VK_F1 - 1;
      if (i < VK_F1) or (i > VK_F24) then
        i:= VK_F11;
      QuickSaveKey:= ReadInteger('QuickSavesKey', i);
      DeleteKey('QuickSaveKey');
      DeleteKey('QuickSaveSlot1');
      DeleteKey('QuickSaveSlot2');
      DeleteKey('QuickSaveName');
{$ELSE}
      QuickSaveKey:= ReadInteger('QuickSavesKey', VK_F11);
      DeleteKey('JumpSpeed');
{$ENDIF}
      if (QuickSaveKey < 0) or (QuickSaveKey > 255) then
        QuickSaveKey:= VK_F11;
      QuickLoadKey:= ReadInteger('QuickLoadKey', 0);

      NoDeathMovie:= ReadBool('NoDeathMovie', false);
      if ReadBool('NoIntro', false) then
      begin
        i:= ini.ReadInteger(sect, 'PostponeIntro', 1);
        if (i <> 0) and (i <> m7*2) then
          i:= 1;
        pint(_NoIntro)^:= 1 + i;
      end;
      NoCD:= ini.ReadBool(sect, 'NoCD', true);
      InventoryKey:= ReadInteger('InventoryKey', ord('I'));
      CharScreenKey:= ReadInteger('ToggleCharacterScreenKey', 192);
      FreeTabInInventory:= ini.ReadBool(sect, 'FreeTabInInventory', true);
      PlayMP3:= ReadBool('PlayMP3', true);
      MusicLoopsCount:= ReadInteger('MusicLoopsCount', 1);

      ReputationNumber:= ini.ReadBool(sect, 'ReputationNumber', true);
      DoubleSpeedKey:= ReadInteger('DoubleSpeedKey', VK_F2);
      TurnSpeedNormal:= ReadInteger('TurnSpeedNormal', 100)/100;
      TurnSpeedDouble:= ReadInteger('TurnSpeedDouble', 120)/200;
      ProgressiveDaggerTrippleDamage:= ini.ReadBool(sect, 'ProgressiveDaggerTrippleDamage', true);
      {$IFDEF mm8}MouseBorder:= ReadInteger('MouseLookBorder', 100);{$ENDIF}
      FixChests:= ReadBool('FixChests', false);
      {$IFNDEF mm8}BlasterRecovery:= ReadInteger('BlasterRecovery', 4);{$ENDIF}
      DataFiles:= ini.ReadBool(sect, 'DataFiles', true);
      {$IFNDEF mm6}NoBitmapsHwl:= ini.ReadBool(sect, 'NoD3DBitmapHwl', true);{$ENDIF}
      MouseLook:= ReadBool('MouseLook', false);
      MLookSpeed.X:= ReadInteger('MouseSensitivityX', 35);
      MLookSpeed.Y:= ini.ReadInteger(sect, 'MouseSensitivityY', MLookSpeed.X);
      MLookSpeed2.X:= ReadInteger('MouseSensitivityAltModeX', 75);
      MLookSpeed2.Y:= ini.ReadInteger(sect, 'MouseSensitivityAltModeY', MLookSpeed2.X);
      MouseLookChangeKey:= ReadInteger('MouseLookChangeKey', VK_MBUTTON);
      MouseLookTempKey:= ReadInteger('MouseLookTempKey', 0);
      CapsLockToggleMouseLook:= ReadBool('CapsLockToggleMouseLook', true);
      MouseLookUseAltMode:= ReadBool('MouseLookUseAltMode', false);
      if ReadBool('MouseLookWhileRightClick', false) then
        MLookRightPressed:= @DummyFalse;
      MouseFly:= ini.ReadBool(sect, 'MouseLookFly', true);
      MouseWheelFly:= ReadBool('MouseWheelFly', true);
      MouseLookRememberTime:= max(1, ini.ReadInteger(sect, 'MouseLookRememberTime', 10*1000));
      AlwaysStrafe:= ReadBool('AlwaysStrafe', false);
      StandardStrafe:= ini.ReadBool(sect, 'StandardStrafe', false);
      {$IFNDEF mm6}PaletteSMul:= ReadFloat('PaletteSMul', m7*0.65 + m8*1);{$ENDIF}
      {$IFNDEF mm6}PaletteVMul:= ReadFloat('PaletteVMul', 1.1);{$ENDIF}
      {$IFDEF mm8}StartupCopyrightDelay:= ini.ReadInteger(sect, 'StartupCopyrightDelay', 0);{$ENDIF}
      AutorunKey:= ReadInteger('AutorunKey', VK_F3);
{$IFNDEF mm6}
      if NoBitmapsHwl then
      begin
        HDWTRCount:= max(1, min(15, ini.ReadInteger(sect, 'HDWTRCount', 7 + m8)));
        HDWTRDelay:= max(1, ini.ReadInteger(sect, 'HDWTRDelay', 20));
      end else
      begin
        HDWTRCount:= max(1, min(15, ini.ReadInteger(sect, 'HDWTRCountHWL', 7)));
        HDWTRDelay:= max(1, ini.ReadInteger(sect, 'HDWTRDelayHWL', 20));
      end;
{$ENDIF}
      FixInfiniteScrolls:= ini.ReadBool(sect, 'FixInfiniteScrolls', true);
      FixInactivePlayersActing:= ini.ReadBool(sect, 'FixInactivePlayersActing', true);
      {$IFDEF mm8}FixSkyBitmap:= ini.ReadBool(sect, 'FixSkyBitmap', true);{$ENDIF}
      FixChestsByReorder:= ini.ReadBool(sect, 'FixChestsByReorder', true);
      {$IFDEF mm7}FixGMStaff:= ini.ReadBool(sect, 'FixGMStaff', true);{$ENDIF}
      FixTimers:= ini.ReadBool(sect, 'FixTimers', true);
      TurnBasedSpeed:= ReadInteger('TurnBasedSpeed', 1);
      TurnBasedPartySpeed:= ReadInteger('TurnBasedPartySpeed', 1);
      FixMovement:= ini.ReadBool(sect, 'FixMovement', true);
      MonsterJumpDownLimit:= ini.ReadInteger(sect, 'MonsterJumpDownLimit', 500);
      {$IFDEF mm8}FixHeroismPedestal:= ini.ReadBool(sect, 'FixHeroismPedestal', true);{$ENDIF}
      {$IFDEF mm8}FixObelisks:= ini.ReadBool(sect, 'FixObelisks', true);{$ENDIF}
      WindowWidth:= ReadInteger('WindowWidth', -1);
      WindowHeight:= ReadInteger('WindowHeight', 480);
      StretchWidth:=  max(1, ReadFloat('StretchWidth', 1));
      StretchWidthFull:= max(StretchWidth, ReadFloat('StretchWidthFull', 1));
      StretchHeight:= max(1, ReadFloat('StretchHeight', 1));
      StretchHeightFull:= max(StretchHeight, ReadFloat('StretchHeightFull', 1.067)); // stretch to 5:4
      BorderlessFullscreen:= ReadBool('BorderlessFullscreen', true);
      BorderlessProportional:= ini.ReadBool(sect, 'BorderlessProportional', false);
      CompatibleMovieRender:= ini.ReadBool(sect, 'CompatibleMovieRender', true);
      SmoothMovieScaling:= ini.ReadBool(sect, 'SmoothMovieScaling', true);
      SupportTrueColor:= ini.ReadBool(sect, 'SupportTrueColor', true);
      RenderMaxWidth:= ReadInteger('RenderMaxWidth', 0);
      RenderMaxHeight:= ReadInteger('RenderMaxHeight', 0);
      ScalingParam1:= ini.ReadFloat(sect, 'ScalingParam1', 3);
      ScalingParam2:= ini.ReadFloat(sect, 'ScalingParam2', 0.2);
      {$IFNDEF mm6}MipmapsCount:= ReadInteger('MipmapsCount', 3);{$ENDIF}
      {$IFNDEF mm6}TurnBasedWalkDelay:= ReadInteger('TurnBasedWalkDelay', 0);{$ENDIF}
      MouseLookCursorHD:= ini.ReadBool(sect, 'MouseLookCursorHD', true);
      SmoothScaleViewSW:= ini.ReadBool(sect, 'SmoothScaleViewSW', true);
      {$IFDEF mm8}NoWaterShoreBumpsSW:= ini.ReadBool(sect, 'NoWaterShoreBumpsSW', true);{$ENDIF}
      {$IFDEF mm8}FixUnimplementedSpells:= ini.ReadBool(sect, 'FixUnimplementedSpells', true);{$ENDIF}
      {$IFNDEF mm6}FixMonsterSummon:= ini.ReadBool(sect, 'FixMonsterSummon', true);{$ENDIF}
      {$IFDEF mm8}FixQuickSpell:= ini.ReadBool(sect, 'FixQuickSpell', true);{$ENDIF}
      {$IFDEF mm7}FixInterfaceBugs:= ini.ReadBool(sect, 'FixInterfaceBugs', true);{$ENDIF}
      {$IFDEF mm8}FixIndoorFOV:= ini.ReadBool(sect, 'FixIndoorFOV', true);{$ENDIF}
      {$IFNDEF mm6}pstring(@UILayout)^:= ReadString('UILayout', '');
      if (UILayout <> nil) and not FileExists('Data\' + UILayout + '.txt') then
        pstring(@UILayout)^:= '';
      {$ENDIF}
      PaperDollInChests:= ReadInteger('PaperDollInChests', 1);
      {$IFDEF mm7}HigherCloseRingsButton:= ReadBool('HigherCloseRingsButton', true);{$ENDIF}
      PlaceChestItemsVertically:= ini.ReadBool(sect, 'PlaceChestItemsVertically', true);
      {$IFDEF mm7}SupportMM7ResTool:= ini.ReadBool(sect, 'SupportMM7ResTool', false);{$ENDIF}
      FixChestsByCompacting:= ini.ReadBool(sect, 'FixChestsByCompacting', true);
      SpriteAngleCompensation:= ini.ReadBool(sect, 'SpriteAngleCompensation', true);
      TrueColorTextures:= ini.ReadBool(sect, 'TrueColorTextures', true);
      FixSFT:= ini.ReadBool(sect, 'FixSFT', true);

{$IFDEF mm6}
      if FileExists(AppPath + 'mm6text.dll') then
        UseMM6text:= ReadBool('UseMM6textDll', true);

      for i:=1 to 255 do
        MappedKeysBack[i]:= i;

      for i:=1 to 255 do
      begin
        j:= ini.ReadInteger('Controls', 'Key'+IntToStr(i), i);
        MappedKeys[i]:= j;
        if j <> i then
          MappedKeysBack[j]:= i;
      end;
{$ELSE}
      MipmapsBase:= TStringList.Create;
      with MipmapsBase do
      begin
        CaseSensitive:= false;
        Duplicates:= dupIgnore;
        Sorted:= true;
        MipmapsBasePat:= TStringList.Create;
        MipmapsBasePat.CaseSensitive:= true;
        MipmapsBasePat.Duplicates:= dupIgnore;
        MipmapsBasePat.Sorted:= true;
        ini.ReadSection('MipmapsBase', MipmapsBase);

        Sorted:= false;
        for i:= 0 to Count - 1 do
        begin
          Strings[i]:= LowerCase(Strings[i]);
          Objects[i]:= ptr(max(1, ini.ReadInteger('MipmapsBase', Strings[i], 128)));
          if LastDelimiter('?*', Strings[i]) > 0 then
            MipmapsBasePat.AddObject(Strings[i], Objects[i]);
        end;
        CaseSensitive:= true;
        Sorted:= true;
      end;

{$ENDIF}{$IFDEF mm7}
      if FileExists(AppPath + 'mm7text.dll') then
        UseMM7text:= ReadBool('UseMM7textDll', true);
{$ENDIF}
      ReadDisabledHooks(ini.ReadString(sect, 'DisableHooks', ''));

      iniOverride:= ini;
      ini:= TIniFile.Create(AppPath + SIni2);

      QuickSaveName:= ReadString('QuickSavesName', {$IFNDEF mm8}'Quicksave'{$ELSE}''{$ENDIF});
      if ReadBool('SpaceBeforeQuicksaveDigit', false) then
        QuickSaveDigitSpace:= ' ';
      RecoveryTimeInfo:= #10#10 + ReadString('RecoveryTimeInfo', 'Recovery time: %d');
      {$IFDEF mm6}GameSavedText:= ReadString('GameSavedText', 'Game Saved!');{$ENDIF}
      PlayerNotActive:= ReadString('PlayerNotActive', 'That player is not active');
      SDoubleSpeed:= ReadString('DoubleSpeed', 'Double Speed');
      SNormalSpeed:= ReadString('NormalSpeed', 'Normal Speed');
      {$IFDEF mm7}SArmorHalved:= ReadString('ArmorHalved', 'Armor Halved');{$ENDIF}
      {$IFNDEF mm6}SArmorHalvedMessage:= ReadString('ArmorHalvedMessage', '%s halves armor of %s');{$ENDIF}
      HorsemanSpeakTime:= ReadInteger('HorsemanSpeakTime', 1500);
      BoatmanSpeakTime:= ReadInteger('BoatmanSpeakTime', 2500);

    finally
      ini.Free;
      iniOverride.Free;
    end;
end;

function GetOptions: ptr; stdcall;
begin
  Result:= @options;
end;

procedure LoadExeMods;
var
  sl: TStringList;
  i: int;
begin
  // Load from ExeMods folder
  with TRSFindFile.Create(AppPath + 'ExeMods\*.dll') do
    try
      while FindNextAttributes(0, FILE_ATTRIBUTE_DIRECTORY) do // Only files
        LoadLibrary(ptr(FileName));
    finally
      Free;
    end;
  // Load from ini
  sl:= TStringList.Create;
  sl.CaseSensitive:= false;
  sl.Duplicates:= dupIgnore;
  sl.Sorted:= true;
  with TIniFile.Create(AppPath + SIni) do
    try
      ReadSection('ExeMods', sl);
      for i := 0 to sl.Count - 1 do
        LoadLibrary(PChar(ReadString('ExeMods', sl[i], '')));
    finally
      Free;
      sl.Free;
    end;
end;

{$IFNDEF mm6}
function PatMatch(const pat, s: string): Boolean;  // only allows one '*' and any number of '?'
var
  i: int;
begin
  Result:= false;
  for i:= 1 to length(pat) + 1 do
    if (s[i] <> pat[i]) and (pat[i] <> '?') then
    begin
      if pat[i] = '*' then
        Result:= (i = length(pat)) or
           PatMatch(Copy(pat, i + 1, MaxInt), Copy(s, i + 1 + length(s) - length(pat), MaxInt));
      exit;
    end;
  Result:= true;
end;

function GetMipmapsCountProc(var a: THwlBitmap; p: PChar): int;
var
  s: string;
  i, w: int;
begin
  s:= LowerCase(p);
  Result:= MipmapsCount;
  if (Result < 0) or (s = '') then
    exit;
  if Options.NoBitmapsHwl then
    w:= a.AreaW
  else
    w:= a.BufW;
  if MipmapsBase.Find(s, i) then
    w:= int(MipmapsBase.Objects[i])
  else
    for i:= 0 to MipmapsBasePat.Count - 1 do
      if PatMatch(MipmapsBasePat[i], s) then
      begin
        w:= int(MipmapsBasePat.Objects[i]);
        break;
      end;
  while a.BufW < w do
  begin
    dec(Result);
    w:= w div 2;
  end;
  while a.BufW > w do
  begin
    inc(Result);
    w:= w*2;
  end;
  if Result <= 1 then
    Result:= 0;
end;

procedure AddMipmapBase(p: PChar; v: int);
var
  i: int;
begin
  if (p = nil) or (p^ = #0) or (v <= 0) then
    exit;
  i:= MipmapsBase.Add(LowerCase(p));
  MipmapsBase.Objects[i]:= ptr(v);
end;
{$ENDIF}

var
  BaseClientRect: TRect;

function Stretch(x: ext; Target: int; mul, full: ext): int;
begin
  if x >= Target then
    Result:= Round(x)
  else if x*full >= Target then
    Result:= Target
  else
    Result:= Round(x*mul);
end;

procedure Wnd_CalcClientRect(var r: TRect);
var
  w, h: int;
begin
  NeedScreenWH;
  BaseClientRect:= r;
  w:= r.Right - r.Left;
  h:= r.Bottom - r.Top;
  if BorderlessProportional then
  begin
    w:= w div SW;
    h:= min(w, h div SH);
    w:= h*SW;
    h:= h*SH;
  end else
    if w*SH >= h*SW then
      w:= Stretch(h*SW/SH, w, StretchWidth, StretchWidthFull)
    else
      h:= Stretch(w*SH/SW, h, StretchHeight, StretchHeightFull);
  dec(w, r.Right - r.Left);
  dec(r.Left, w div 2);
  dec(r.Right, w div 2 - w);
  dec(h, r.Bottom - r.Top);
  dec(r.Top, h div 2);
  dec(r.Bottom, h div 2 - h);
end;

procedure Wnd_PaintBorders(wnd: HWND; wp: int);
var
  dc: HDC;
  r, r0, rc, r1: TRect;
begin
  if BaseClientRect.Right = BaseClientRect.Left then  exit;
  GetWindowRect(wnd, r);
  GetClientRect(wnd, rc);
  if GetWindowLong(wnd, GWL_STYLE) and WS_BORDER = 0 then
    r0:= r
  else
    r0:= BaseClientRect;
  MapWindowPoints(wnd, 0, rc, 2);
  OffsetRect(rc, -r.Left, -r.Top);
  OffsetRect(r0, -r.Left, -r.Top);
  dc:= GetWindowDC(wnd);//GetDCEx(wnd, wp, DCX_WINDOW or DCX_INTERSECTRGN);

  r1:= Rect(r0.Left, r0.Top, r0.Right, rc.Top); // top
  FillRect(dc, r1, GetStockObject(BLACK_BRUSH));
  r1:= Rect(r0.Left, rc.Top, rc.Left, rc.Bottom); // left
  FillRect(dc, r1, GetStockObject(BLACK_BRUSH));
  r1:= Rect(rc.Right, rc.Top, r0.Right, rc.Bottom); // right
  FillRect(dc, r1, GetStockObject(BLACK_BRUSH));
  r1:= Rect(r0.Left, rc.Bottom, r0.Right, r0.Bottom); // bottom
  FillRect(dc, r1, GetStockObject(BLACK_BRUSH));

  ReleaseDC(wnd, dc);
end;

procedure Wnd_Sizing_GetWH(wnd: HWND; const r: TRect; var w, h: int);
var
  r0, r1: TRect;
begin
  GetClientRect(wnd, r0);
  GetWindowRect(wnd, r1);
  w:= r.Right - r.Left - r1.Right + r1.Left + r0.Right;
  h:= r.Bottom - r.Top - r1.Bottom + r1.Top + r0.Bottom;
end;

procedure Wnd_Sizing(wnd: HWND; side: int; var r: TRect);
var
  CW: int absolute WindowWidth;
  CH: int absolute WindowHeight;
  w, h, w0, h0: int;
begin
  Wnd_Sizing_GetWH(wnd, r, w0, h0);
  NeedScreenWH;
  w:= max(w0, SW);
  h:= max(h0, SH);
  if (CW = Round(CH*SW/SH)) or (CH = Round(CW*SH/SW)) then
  begin
    CW:= SW;
    CH:= SH;
  end;
  if side in [WMSZ_LEFT, WMSZ_RIGHT] then
    w:= max(w0, Round(h*min(SW/SH, CW/CH)))
  else if side in [WMSZ_TOP, WMSZ_BOTTOM] then
    h:= max(h0, Round(w*min(SH/SW, CH/CW)))
  else
    if w*CH >= h*CW then
      w:= (h*CW + CH div 2) div CH
    else
      h:= (w*CH + CW div 2) div CW;
  w:= max(w, SW);
  h:= max(h, SH);
  if side in [WMSZ_LEFT, WMSZ_RIGHT, WMSZ_TOP, WMSZ_BOTTOM] then
  begin
    CW:= w;
    CH:= h;
  end;
  Wnd_Sizing_SetWH(wnd, side, r, w - w0, h - h0);
end;

procedure Wnd_Sizing_SetWH(wnd: HWND; side: int; var r: TRect; dw, dh: int);
begin
  if side in [WMSZ_LEFT, WMSZ_TOPLEFT, WMSZ_BOTTOMLEFT] then
    dec(r.Left, dw)
  else
    inc(r.Right, dw);

  if side in [WMSZ_TOP, WMSZ_TOPLEFT, WMSZ_TOPRIGHT] then
    dec(r.Top, dh)
  else
    inc(r.Bottom, dh);
end;

procedure CheckHooks(var Hooks);
var
  hk: array[0..1] of TRSHookInfo absolute Hooks;
  i: int;
begin
  i:= RSCheckHooks(Hooks);
  if i >= 0 then
    raise Exception.CreateFmt(SWrong, [hk[i].p]);
  i:= 0;
  while hk[i].p <> 0 do
  begin
    if DisabledHooks.IndexOf(IntToHex(hk[i].p, 0)) >= 0 then
      hk[i].Querry:= -100;
    inc(i);
  end;
end;

procedure ClipCursorRel(r: TRect);
begin
  MapWindowPoints(_MainWindow^, 0, r, 2);
  BringWindowToTop(_MainWindow^);
  if (GetForegroundWindow = _MainWindow^) and ((GetFocus = _MainWindow^) or (GetFocus = 0)) then
    ClipCursor(@r);
end;

function DynamicFovCalc(const x, y: int): ext;
begin
  if x < y then
    Result:= x*Power(y/x, 0.34)
  else
  	Result:= y*Power(x/y, 0.34);
end;

function DynamicFovFactor(const x, y: int): ext;
begin
  Result:= DynamicFovCalc(x, y)/DynamicFovCalc(460, 344);
end;

function GetViewMul: ext;
begin
  if _IndoorOrOutdoor^ <> 1 then
    Result:= _ViewMulOutdoor^
{$IFNDEF MM6}
  else if _IsD3D^ then
    Result:= psingle(ppchar(_CGame^ + $E54)^ + $C4)^
{$ENDIF}
  else
    Result:= _ViewMulIndoorSW^;
end;

procedure AddAction(action, info1, info2:int); stdcall;
begin
  with _ActionQueue^ do
    if Count < 40 then
    begin
      Items[Count]:= PActionQueueItem(@action)^;
      inc(Count);
    end;
end;

procedure NeedScreenWH;
begin
  SW:= _ScreenW^;
  SH:= _ScreenH^;
  if SW = 0 then  SW:= 640;
  if SH = 0 then  SH:= 480;
end;

procedure __SetSpellBuff;
asm
  pop ecx
  xchg ecx, [esp]
  push m6*$44A970 + m7*$458519 + m8*$455D97
end;

{ TMapExtra }

function TMapExtra.GetPeriodicTimer(i: int; first: Boolean = false): int64;
var
  time: uint64;
begin
  Result:= LastPeriodicTimer[i];
  time:= LastVisitTime;
  if (time = 0) and (Result = 0) then
    exit;
  if not first then
    time:= _Time^;
  while Result + $100000000 < time do
    inc(Result, $100000000);
end;

function GetMapExtra: PMapExtra;
begin
  if _IndoorOrOutdoor^ = 1 then
    Result:= ptr(m6*$5F7D74 + m7*$6BE534 + m8*$6F3CF4)
  else
    Result:= ptr(m6*$689C78 + m7*$6A1160 + m8*$6CF0CC);
end;

procedure SaveBufferToBitmap(s: PChar; buf: ptr; w, h, bits: int); stdcall;
var
  b: TBitmap;
begin
  b:= TBitmap.Create;
  try
    case bits of
      32:   b.PixelFormat:= pf32bit;
      24:   b.PixelFormat:= pf24bit;
      16,0: b.PixelFormat:= pf16bit;
      15:   b.PixelFormat:= pf15bit;
      else  Assert(false);
    end;
    b.Width:= w;
    b.Height:= h;
    RSBufferToBitmap(buf, b);
    RSCreateDir(ExtractFilePath(s));
    b.SaveToFile(s);
  except
    RSShowException;
  end;
  b.Free;
end;

exports
{$IFNDEF mm6}
  AddMipmapBase,
{$ENDIF}
  GetOptions,
  SaveBufferToBitmap;
initialization
  @SetSpellBuff:= @__SetSpellBuff;
end.

