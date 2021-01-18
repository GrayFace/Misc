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
  hqTreeHints = 54;
  hqSpriteInteractIgnoreId = 55;
  hqClickThruEffects = 56;
  hqSprite32Bit = 57;
  hqFixStayingHints = 58;
  hqFixMonsterBlockShots = 59;
  hqMinimapBkg = 60;
  hqFixLichImmune = 61;
  hqFixParalyze = 62;
  hqAttackSpell = 63;
  hqShooterMode = 64;
  hqFixHitDistantMonstersIndoor = 65;
  hqGreenItemsWhileRightClick = 66;
  hqClickThruEffectsD3D = 67;
  hqFixDeadIdentifyItem = 68;
  hqDeadShowItemInfo = 69;
  hqDelayedInterface = 70;
  hqFixIceBoltBlast = 71;
  hqViewDistance = 72;
  hqViewDistanceLimits = 73;
  hqFixHouseAnimationRestart = 74;
  hqFixMonsterAttackTypes = 75;
  hqFixMonsterSpells = 76;
  hqCheckFreeSpace = 77;

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
  HookPopAction = m6*$42B2C9 + m7*$43056D + m8*$42EE83; // use RShtBefore
  HookLoadLods = m6*$45761E + m7*$4655FE + m8*$463862; // use RShtAfter
  HookWindowProc = m6*$454340 + m7*$463828 + m8*$4618FF; // use RShtFunctionStart or RShtBefore
  HookLoadInterface = m6*$4534D0 + m7*$462E36 + m8*$460DA0; // on game start. Use RShtBefore
  fpsNone = 0;
  fpsOff = 1;
  fpsOn = 2;

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
    AxeGMFullProbabilityAt: int;              // (unused in MM6)
    MouseDX: Double;                          //
    MouseDY: Double;                          //
    TrueColorSprites: LongBool;               // (unused in MM6)
    FixMonstersBlockingShots: LongBool;       // (unused in MM6)
    FixParalyze: LongBool;                    // (MM6 only for now)
    EnableAttackSpell: LongBool;              //
    ShooterMode: int;                         //
    MaxMLookUpAngle: int;                     //
    FixIceBoltBlast: LongBool;                // (unused in MM6)
    MonSpritesSizeMul: int;                   //
    FixMonsterAttackTypes: LongBool;          // (unused in MM6)
    FixMonsterSpells: LongBool;               //
  end;

var
  Options: TOptions = (
    Size: SizeOf(TOptions);
    MaxMLookAngle: 240;
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
    MaxMLookUpAngle: 300;
  );

var
  QuickSavesCount, QuickSaveKey, TurnBasedSpeed, TurnBasedPartySpeed,
  WindowWidth, WindowHeight, RenderMaxWidth, RenderMaxHeight, MipmapsCount,
  WinScreenDelay, HintStayTime, dist_mist, ViewDistanceD3D, IndoorAntiFov: int;

  MLookSpeed, MLookSpeed2: TPoint;
  MouseLookRememberTime, ShooterDelay: uint;
  MLookRightPressed: pbool = _RightButtonPressed;

  TurnSpeedNormal, TurnSpeedDouble: single;

  FormatSettingsEN: TFormatSettings;

  StretchWidth, StretchWidthFull, StretchHeight, StretchHeightFull,
  ScalingParam1, ScalingParam2, MLookRawMul: ext;

  RecoveryTimeInfo, PlayerNotActive, SDoubleSpeed, SNormalSpeed,
  QuickSaveName, QuickSaveDigitSpace, SArmorHalved, SArmorHalvedMessage,
  SDuration, SDurationYr, SDurationMo, SDurationDy, SDurationHr,
  SDurationMn, SRemoveASpell, SChooseASpell, SSetASpell, SSetASpell2: string;

  CapsLockToggleRun, NoDeathMovie, FreeTabInInventory, ReputationNumber,
  AlwaysStrafe, StandardStrafe, MouseLookChanged, MLookRaw, FixInfiniteScrolls,
  FixInactivePlayersActing, BorderlessFullscreen, BorderlessProportional,
  MouseLookCursorHD, SmoothScaleViewSW, WasIndoor, SpriteAngleCompensation,
  PlaceChestItemsVertically, FixChestsByCompacting, FixConditionPriorities,
  SpriteInteractIgnoreId, ClickThroughEffects, Autorun, FixLichImmune,
  ShowHintWithRMB, WasInDialog, FixHitDistantMonstersIndoor,
  GreenItemsWhileRightClick, FixDeadPlayerIdentifyItem,
  DeadPlayerShowItemInfo, SystemDDraw, UseVoodoo, NeedFreeSpaceCheck,
  FixHouseAnimationRestart, ExitTalkingWithRightButton: Boolean;
  DoubleSpeed: BOOL;
  {$IFNDEF mm6}
  NoVideoDelays, DisableAsyncMouse, ShowTreeHints: Boolean;
  TurnBasedWalkDelay, TreeHintsVal: int;
  MipmapsBase, MipmapsBasePat: TStringList;
  ViewMulFactor: ext = 1;
  {$ENDIF}

  TimersValidated: int64;
  ShooterButtons: array[Boolean] of Boolean;

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
    _1: array[1..16] of byte;
    WHProduct: int;
    w, h: int2;  // 20, 22
    WidthLn2, HeightLn2, WidthMinus1, HeightMinus1: int2;
    Bits: int;
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

  PDlg = ^TDlg;
  TDlg = packed record
    Left, Top, Width, Height, Right_, Bottom_: int;
    ID, DlgParam: int;  // DlgParam of house dialog is the index in 2DEvents
    ItemsCount: int;
    u1: int;
    KeyboardItemsCount: int;
    KeyboardItem: int;
    KeyboardNavigationTrackMouse: Bool;
    KeyboardLeftRightStep: int;
    KeyboardItemsStart: int;
    Index: int;
    u2: int;
    UseKeyboadNavigation: Bool;
    u3: int;
    TopItem: ptr;
    BottomItem: ptr;
  end;

  TDlgArray = array[1..20] of TDlg;
  TVisibleDlgArray = array[0..19] of int;

  PSpriteToDraw = ^TSpriteToDraw;
  TSpriteToDraw = packed record
    ScaleX: int;
{$IFNDEF mm6}
    ScaleY: int;
    ScaleXfl, ScaleYfl: Single;
{$ENDIF}
    ObjKind: uint2;
    ZBuf: int2;
{$IFNDEF mm6}
    Id: int;
{$ENDIF}
    SpriteIndex: int2;
    PalIndex: int2;
    Room: int2;
    Bits: int2;
    X, Y, Z: int2;
    ScreenX, ScreenY: int2;
    DarkenValue: int2;
{$IFNDEF mm6}
    TintColor: int;
{$ENDIF}
    SFTItem: int;
  end;
  PSpriteToDrawArray = ^TSpriteToDrawArray;
  PPSpriteToDrawArray = ^PSpriteToDrawArray;
  TSpriteToDrawArray = array[0..499] of TSpriteToDraw;

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
    Text: array[Boolean] of array[0..199] of Char; // BelowMouse, TimedHint
    TmpTime: uint;
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

  PGlobalTxt = ^TGlobalTxt;
  TGlobalTxt = array[0..(m6*596 + m7*677 + m8*750) - 1] of PChar;

  TSpellInfo = packed record
    Bits: Word;
    SpellPoints: array[1..4 - m6] of int2;
    Delay: array[1..4 - m6] of int2;
{$IFNDEF mm6}
    DamageAdd, DamageDiceSides: Byte;
{$ENDIF}
  end;
  PSpellInfoArray = ^TSpellInfoArray;
  TSpellInfoArray = array[0..99 + m8*33] of TSpellInfo;

{$IFDEF mm6}
  PSkills = PByteArray;
{$ELSE}
  PSkills = PWordArray;
{$ENDIF}

const
  _ActionQueue: PActionQueue = ptr(m6*$4D5F48 + m7*$50CA50 + m8*$51E330);
  PowerOf2: array[0..15] of int = (1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768);
  _IconsLodLoaded = PLoadedBitmaps(_IconsLod + $23C);
  //BitmapsLodLoaded = PLoadedBitmaps(_BitmapsLod + $23C);
  _ObjectByPixel = PPIntegerArray(m6*$9B1090 + m7*$E31A9C + m8*$F019B4);
  __CurrentMember = int(_CurrentMember);
{$IFNDEF MM8}
  _InventoryRingsShown = pbool(m6*$4D50F0 + m7*$511760);
  _InventoryShowRingsButton = PPDlgButton(m6*$4D4710 + m7*$507514);
  _InventoryPaperDollButton = PPDlgButton(m6*$4D46E0 + m7*$507510);
{$ENDIF}
  __MouseItem = m6*$90E81C + m7*$AD458C + m8*$B7CA64;
  _MouseItemNum = pint(__MouseItem);
  _StatusText = PStatusTexts(m6*$55BC04 + m7*$5C32A8 + m8*$5DB758);
  _NeedUpdateStatus = pbool(m6*$4CB6B4 + m7*$5C343C + m8*$517B48);
  _NoMusicDialog = pbool(m6*$9DE394 + m7*$F8BA90 + m8*$FFDE88); // intro, win screen, High Council
  _PartyPos = PPoint3D(m6*$908C98 + m7*$ACD4EC + m8*$B21554);
  _CameraPos = PPoint3D(m6*$4D5150 + m7*$507B60 + m8*$519438);
  _ScreenMiddle = PPoint(m6*$9DE3C0 + m7*$F8BABC + m8*$FFDEB4);
  _MoveToMap = PMoveToMap(m6*$551D20 + m7*$5B6428 + m8*$5CCCB8);
  _PartyBuffs = PPartyBuffs(m6*$908E34 + m7*$ACD6C4 + m8*$B21738);
  _ShowHits = pbool(m6*$6107EC + m7*$6BE1F8 + m8*$6F39B8);
  _SetHint: procedure(_,__: int; s: PChar) = ptr(m6*$418F40 + m7*$41C061 + m8*$041B711);
  _NoIntro = pbool(m6*$6A5F64 + m7*$71FE8C + m8*$75CDF8);
  _SpritesToDraw: PPSpriteToDrawArray = ptr(m6*$4338A6 + m7*$43FC6D + m8*$43CBF1);
  _SpritesToDrawCount: pint = ptr(m6*$4DA9B8 + m7*$518660 + m8*$529F40);
{$IFNDEF MM6}
  _SpritesD3D = PPSpriteD3DArray(_SpritesLod + $ECB0);
{$ENDIF}
  _SoundVolume = pint(m6*$6107E3 + m7*$6BE1EF + m8*$6F39AF);
  _GlobalTxt = PGlobalTxt(m6*$56B830 + m7*$5E4000 + m8*$601448);
  _DialogsHigh = pint(m6*$4D46BC + m7*$5074B0 + m8*$518CE8);
  _Dialogs: ^TVisibleDlgArray = ptr(m6*$4CB5F8 + m7*$507460 + m8*$5185B4);
  _DlgArray: ^TDlgArray = ptr(m6*$4D48F8 + m7*$506DE8 + m8*$518608);
  _HouseScreen = pint(m6*$9DDD8C + m7*$F8B01C + m8*$FFD408);
  _HouseExitMap = pint(m6*$55BDA4 + m7*$5C3450 + m8*$5DB8FC);
  _HouseNPCCount = pint(m6*$53CB60 + m7*$5912A4 + m8*$5A5714);
  _HouseCurrentNPC = pint(m6*$551F94 + m7*$591270 + m8*$5A56E0);
  _SpellBookSelectedSpell = pint(m6*$4CB214 + m7*$5063CC + m8*$517B1C);
  _SpellSounds = PWordArray(m6*$4C28E0 + m7*$4EDF30 + m8*$4FE128);
  _SpellInfo = PSpellInfoArray(m6*$4BDD6E + m7*$4E3C46 + m8*$4F486E);
  _DDraw = pptr(m6*$9B10E4 + m7*$E31AF4 + m8*$F01A0C);
  _dist_mist = pint(m6*$6296EC + m7*$6BDEFC + m8*$6F3004);

  _ItemOff_Number = 0;
  _ItemOff_Bonus = 4;
  _ItemOff_BonusStrength = 8;
  _ItemOff_Bonus2 = 12;
  _ItemOff_Charges = 16;
  _ItemOff_Condition = 20;
  _ItemOff_Size = $24 - 8*m6;

  _ItemCond_Identified = 1;
  _ItemCond_Broken = 2;
  _ItemCond_TemporaryBonus = 8;
  _ItemCond_Stolen = $100*(1 - m6);
  _ItemCond_Hardened = $200*(1 - m6);

  _ChestOff_Items = 4;
  _ChestOff_Inventory = 4 + _ItemOff_Size*140;

  _CharOff_ItemMainHand = m6*$142C + m7*$194C + m8*$1C08;
  _CharOff_Items = m6*$128 + m7*$1F0 + m8*$484; // The actual offset is bigger, because they're indexed from 1 instead of 0
  _CharOff_Inventory = m6*$105C + m7*$157C + m8*$1810;
  _CharOff_Recover = m6*$137C + m7*$1934 + m8*$1BF2;
  _CharOff_SpellPoints = m6*$1418 + m7*$1940 + m8*$1BFC;
  _CharOff_SpellBookPage = m6*$152E + m7*$1A4E + m8*$1C44;
  _CharOff_QuickSpell = m6*$152F + m7*$1A4F + m8*$1C45;
  _CharOff_AttackQuickSpell = m6*$137E + m7*$1936 + m8*$1C8E; // my addition (alt: m6*$13 + m7*$BB + m8*$1C8E)
  _CharOff_Skills = m6*$60 + m7*$108 + m8*$378;
  _CharOff_Size = m6*$161C + m7*$1B3C + m8*$1D28;

  _MonOff_HP = $28;
  _MonOff_FullHP = $5c + m7*$10 + m8*$18;
  _MonOff_AIState = $a0 + m7*$10 + m8*$18;
  _MonOff_Item = $a4 + m7*$10 + m8*$18;
  _MonOff_Item1 = m7*$234 + m8*$2BC;
  _MonOff_Item2 = _MonOff_Item1 + _ItemOff_Size;
  _MonOff_Buff_Stoned = $114 + m7*$10 + m8*$18;

  _FacetOff_VertexCount = $5D - m6*$10;

  _ObjOff_X = 4;
  _ObjOff_Y = 8;
  _ObjOff_Z = $C;

const
  _malloc: function(size:int):ptr cdecl = ptr(m6*$4AE753 + m7*$4CADC2 + m8*$4D9F62);
  _new: function(size:int):ptr cdecl = ptr(m6*$4AEBA5 + m7*$4CB06B + m8*$4D9E0B);
  _free: procedure(p:ptr) cdecl = ptr(m6*$4AE724 + m7*$4CAEFC + m8*$4DA09C);
  _ProcessActions: TProcedure = ptr(m6*$42ADA0 + m7*$4304D6 + m8*$42EDD8);
  _LoadBitmap: function(_, __, this: int; pal: {$IFNDEF mm8}int{$ELSE}int64{$ENDIF}; name: PChar): int = ptr(m6*$40B430 + m7*$40FB2C + m8*$410D70);
  _DrawBmpTrans: procedure(_, __, screen: int; bmp:{$IFNDEF mm8}uint{$ELSE}uint64{$ENDIF}; y, x: int) = ptr(m7*$4A6204 + m8*$4A419B);
  _DrawBmpOpaque: procedure(_, __, screen: int; var bmp: TLoadedBitmap; y, x: int) = ptr(m7*$4A5E42 + m8*$4A3CD5);
  _LoadPcx: function(_,_1: int; var pcx: TLoadedPcx; _2: {$IFNDEF mm8}int{$ELSE}int64{$ENDIF}; name: PChar): int = ptr(m6*$409E50 + m7*$40F420 + m8*$4106F3);
  _FreePcx: procedure(_,_1: int; var pcx: TLoadedPcx) = ptr(m6*$4091F0 + m7*$40E52B + m8*$40F7F6);
  _DrawPcx: procedure(_,__, screen: int; var pcx: TLoadedPcx; y, x: int) = ptr(m7*$4A5B73 + m8*$4A3A04);
  _FaceAnim: procedure(_,__: int; pl: ptr; _3, action: int) = ptr(m6*$488CA0 + m7*$4948A9 + m8*$492BCD);
  _Mon_IsAgainstMon: function(_: int; against, who: ptr): int = ptr(m7*$40104C + m8*$401051);
  _DrawItemInfoBox: procedure(n1, n2: int; it: ptr) = ptr(m6*$41C440 + m7*$41D83E + m8*$41CDC2);

{$IFNDEF mm6}
var
  Sprites: array[0..SpritesMax-1] of TSprite;
  ClockArea: PDlgButton;
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
function PtInView(x, y: int): Boolean;
function GetMouseTarget: int;
function CastRay(var x, y, z: ext; x0, y0: ext): ext;  // returns length of unnormalized vector
function DynamicFovFactor(const x, y: int): ext;
function GetViewMul: ext; inline;
procedure AddAction(action, info1, info2:int); stdcall;
procedure ShowStatusText(text: string; time: int = 2);

var
  SW, SH: int;

procedure NeedScreenWH;
procedure Draw8(ps: PByte; pd: PWord; ds, dd, w, h: int; pal: PWordArray);
procedure Draw8t(ps: PByte; pd: PWord; ds, dd, w, h: int; pal: PWordArray);
function LoadIcon(const name: string): int;
function FindDlg(id: int): PDlg;
function NewButtonMM8(id, action: int; actionInfo: int = 0; hintAction: int = 0): ptr;
procedure SetupButtonMM8(btn: ptr; x, y: int; transp: Bool; normalPic: PChar = nil; pressedPic: PChar = nil; hoverPic: PChar = nil; disabledPic: PChar = nil; englishD: Bool = false);
procedure AddToDlgMM8(dlg, btn: ptr);
function GetCurrentPlayer: ptr;
function IsMonAlive(m: PChar; CheckStoned: Boolean): Boolean;

var
  SetSpellBuff: procedure(this: ptr; time: int64; skill, power, overlay, caster: int); stdcall;
  PlaySound: procedure(id: int; a3: int = 0; a4: int = 0; a5: int = -1; a6: int = 0; a7: int = 0; a8: int = 0; a9: int = 0); stdcall;
  LoadSound: function(id: int; a3: bool = false; a4: bool = false): Bool; stdcall;

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
  sect, info, curInfo, fullIni: string;
  NoInfo: Boolean;

  procedure CheckInfo(const key: string);
  var
    s: string;
    c, c1: char;
  begin
    if NoInfo or (curInfo = '') or (pos('; ' + curInfo + ':', fullIni) > 0) then
      exit;
    s:= ini.ReadString(sect, key, #13#10);
    if (s = '#13#10') or (length(s) >= 2047) then
      exit;
    if s <> '' then
    begin
      c:= s[1];
      c1:= s[length(s)];
      if (c in ['"', '''']) and (c1 = c) or (ord(c) <= 32) or (ord(c1) <= 32) then
        s:= '"' + s + '"';
    end;
    ini.WriteString(sect, key, '-'#13#10'; ' + curInfo + ':'#13#10 + key + '=' + s);
    ini.DeleteKey(sect, key);
  end;

  function ReadString(const key, default: string; write: Boolean = true): string;
  begin
    curInfo:= info;
    info:= '';
    if iniOverride <> nil then
    begin
      Result:= iniOverride.ReadString(sect, key, #13#10);
      if Result <> #13#10 then
        exit;
    end;
    Result:= ini.ReadString(sect, key, #13#10);
    if Result = #13#10 then
    begin
      if write then
        ini.WriteString(sect, key, default);
      Result:= default;
    end;
    CheckInfo(key);
  end;

  function ReadInteger(const key: string; default: int; write: Boolean = true): int;
  begin
    curInfo:= info;
    info:= '';
    if iniOverride <> nil then
    begin
      Result:= iniOverride.ReadInteger(sect, key, 0);
      if (Result <> 0) or (iniOverride.ReadInteger(sect, key, 1) = 0) then
        exit;
    end;
    Result:= ini.ReadInteger(sect, key, 0);
    if (Result = 0) and (ini.ReadInteger(sect, key, 1) <> 0) then
    begin
      if write then
        ini.WriteInteger(sect, key, default);
      Result:= default;
    end;
    CheckInfo(key);
  end;

  function ReadBool(const key: string; default: Boolean; write: Boolean = true): Boolean;
  begin
    Result := ReadInteger(key, Ord(Default), write) <> 0;
  end;

  function ReadFloat(const key: string; default: Double; write: Boolean = true): Double;
  var
    s: string;
  begin
    Assert(iniOverride = nil);
    curInfo:= info;
    info:= '';
    s:= ini.ReadString(sect, key, #13#10);
    if RSVal(s, Result) then
    begin
      CheckInfo(key);
      exit;
    end;
    if write then
      ini.WriteString(sect, key, FloatToStr(default, FormatSettingsEN));
    Result:= default;
    if write or (s <> #13#10) then
      CheckInfo(key);
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

const
  SVoodooMsg = 'A replacement ddraw.dll found in game folder. '
   + 'It''s probably from dgVoodoo2. My patch handles higher resolutions on its '
   + 'own and dgVoodoo will reduce FPS. However, using dgVoodoo can let you '
   + 'overcome resolution limit of old DirectX and get other benefits. '#13#10
   + 'Would you like to use the replacement ddraw.dll?';

var
  i: int; {$IFDEF mm6}j: int;{$ENDIF}
begin
  GetLocaleFormatSettings($409, FormatSettingsEN);
  iniOverride:= nil;
  ini:= TIniFile.Create(AppPath + SIni);
  with Options do
    try
      sect:= 'Settings';
      if not ini.ReadBool(sect, 'KeepCurrentDirectory', false) then
        SetCurrentDir(AppPath);
      NoInfo:= not ini.ReadBool(sect, 'AddDescriptions', false);
      if not NoInfo and FileExists(AppPath + SIni) then
        fullIni:= RSLoadTextFile(AppPath + SIni);
{$IFDEF mm6}
      _FlipOnExit^:= ReadInteger('FlipOnExit', 0, false);
      info:= 'Makes the maximum volume of in-game CD Music the same as maximum of the normal Windows CD Audio Volume slider (set to 1 to enable)';
      _LoudMusic^:= ReadInteger('LoudMusic', 0);
      AlwaysRun:= ReadBool('AlwaysRun', true, false);
      FixWalk:= ReadBool('FixWalkSound', true, false);
      FixDualWeaponsRecovery:= ReadBool('FixDualWeaponsRecovery', true, false);
      IncreaseRecoveryRateStrength:= ReadInteger('IncreaseRecoveryRateStrength', 10, false);
      FixStarburst:= ReadBool('FixStarburst', true, false);
      PlaceItemsVertically:= ReadBool('PlaceItemsVertically', true, false);
      NoPlayerSwap:= ReadBool('NoPlayerSwap', true, false);
      DeleteKey('FixCompatibility');
{$ELSE}
      NoVideoDelays:= ReadBool('NoVideoDelays', true, false);
      HardenArtifacts:= ReadBool('HardenArtifacts', true, false);
      DisableAsyncMouse:= ReadBool('DisableAsyncMouse', true, false);
{$ENDIF}
      info:= 'Caps Lock key will toggle running/walking if this is set to 1';
      CapsLockToggleRun:= ReadBool('CapsLockToggleRun', false);

      info:= 'A history of this many quick saves would be kept';
      QuickSavesCount:= ReadInteger('QuickSavesCount', 3);
      info:= 'Quick Save key code (F11 by default. Use MM6 Controls program to find out the code of a key)';
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
      info:= 'Quick Load key code (use MM6 Controls program to find out the code of a key)';
      QuickLoadKey:= ReadInteger('QuickLoadKey', 0);

      info:= 'Set to 1 disable the death movie';
      NoDeathMovie:= ReadBool('NoDeathMovie', false, false);
      info:= 'Skips intro and makes it appear when you press the New Game button instead (unless "PostponeIntro" is set to 0)';
      if ReadBool('NoIntro', false) then
      begin
        i:= ReadInteger('PostponeIntro', 1, false);
        if (i <> 0) and (i <> m7*2) then
          i:= 1;
        pint(_NoIntro)^:= 1 + i;
      end;
      NoCD:= ReadBool('NoCD', true, false);
      info:= 'Key used to immediately open inventory screen ("I" by default. Use MM6 Controls program to find out the code of a key)';
      InventoryKey:= ReadInteger('InventoryKey', ord('I'));
      info:= 'Key used to toggle character screen ("~" by default. Use MM6 Controls program to find out the code of a key)';
      CharScreenKey:= ReadInteger('ToggleCharacterScreenKey', 192);
      FreeTabInInventory:= ReadBool('FreeTabInInventory', true, false);
      info:= 'Set to 1 to play MP3 files from Music folder instead of CD audio';
      PlayMP3:= ReadBool('PlayMP3', true, false);
      info:= 'Set to 0 to play location music in an infinite loop';
      MusicLoopsCount:= ReadInteger('MusicLoopsCount', 1);

      ReputationNumber:= ReadBool('ReputationNumber', true, false);
      info:= 'Key that double game speed (F2 by default. Use MM6 Controls program to find out the code of a key)';
      DoubleSpeedKey:= ReadInteger('DoubleSpeedKey', VK_F2);
      info:= 'Smooth turn speed when not in double speed mode';
      TurnSpeedNormal:= ReadInteger('TurnSpeedNormal', 100)/100;
      info:= 'Smooth turn speed in double speed mode';
      TurnSpeedDouble:= ReadInteger('TurnSpeedDouble', 120)/200;
      ProgressiveDaggerTrippleDamage:= ReadBool('ProgressiveDaggerTrippleDamage', true, false);
      info:= 'Set to -1 to disable MM8 original implementation of mouse look. Set to a value above 0 to perform rotation when mouse is this close to view border';
      {$IFDEF mm8}MouseBorder:= ReadInteger('MouseLookBorder', 100);{$ENDIF}
      info:= '';
      FixChests:= ReadBool('FixChests', false, false);
      info:= 'Minimal recovery value of blasters and bows (use to be 0 in original game)';
      {$IFNDEF mm8}BlasterRecovery:= ReadInteger('BlasterRecovery', 4);{$ENDIF}
      info:= '';
      DataFiles:= ReadBool('DataFiles', true, false);
      info:= 'Enable mouse look mode, which lets you look around by moving mouse';
      MouseLook:= ReadBool('MouseLook', false);
      info:= 'Mouse sensitivity';
      MLookSpeed.X:= ReadInteger('MouseSensitivityX', 35);
      MLookSpeed.Y:= ReadInteger('MouseSensitivityY', MLookSpeed.X, false);
      info:= 'Mouse sensitivity when "MouseLookUseAltMode" setting is enabled';
      MLookSpeed2.X:= ReadInteger('MouseSensitivityAltModeX', 75);
      MLookSpeed2.Y:= ReadInteger('MouseSensitivityAltModeY', MLookSpeed2.X, false);
      MLookSpeed.X:= MLookSpeed.X*32;
      MLookSpeed.Y:= MLookSpeed.Y*32;
      MLookSpeed2.X:= MLookSpeed2.X*32;
      MLookSpeed2.Y:= MLookSpeed2.Y*32;
      info:= 'Set to a positive value to use raw mouse input (a value can be non-integer). Mouse sensitivity is multiplied by this number';
      MLookRawMul:= ReadFloat('MouseSensitivityDirectMul', 0);
      MLookRaw:= (MLookRawMul > 0);
      info:= 'Key used to toggle mouse look (middle mouse button by default)';
      MouseLookChangeKey:= ReadInteger('MouseLookChangeKey', VK_MBUTTON);
      info:= 'Key used to disable/enable mouse look while it''s being held';
      MouseLookTempKey:= ReadInteger('MouseLookTempKey', 0);
      info:= 'Pressing Caps Lock would toggle mouse look if this is set to 1';
      CapsLockToggleMouseLook:= ReadBool('CapsLockToggleMouseLook', true);
      info:= 'Set to 1 to enable alternative mouse look mode where mouse look is off by default, but is turned on by the keys that toggle it';
      MouseLookUseAltMode:= ReadBool('MouseLookUseAltMode', false);
      info:= 'Set to 1 to enable looking around while the game is paused by right mouse button press';
      if ReadBool('MouseLookWhileRightClick', false) then
        MLookRightPressed:= @DummyFalse;
      MouseFly:= ReadBool('MouseLookFly', true, false);
      info:= 'Enables flying up/down by turning mouse wheel';
      MouseWheelFly:= ReadBool('MouseWheelFly', true);
      MouseLookRememberTime:= max(1, ReadInteger('MouseLookRememberTime', 10*1000, false));
      AlwaysStrafe:= ReadBool('AlwaysStrafe', false, false);
      StandardStrafe:= ReadBool('StandardStrafe', false, false);
      {$IFDEF mm8}StartupCopyrightDelay:= ReadInteger('StartupCopyrightDelay', 0, false);{$ENDIF}
      info:= 'Pressing this key will make you move forward until you do something other than turning (F3 by default. Use MM6 Controls program to find out the code of a key)';
      AutorunKey:= ReadInteger('AutorunKey', VK_F3);
      {$IFDEF mm7}info:= 'Saturation multiplier for all graphics (0.65 by default)';{$ENDIF}
      {$IFDEF mm8}info:= 'Saturation multiplier for all graphics (1.0 by default)';{$ENDIF}
{$IFNDEF mm6}
      PaletteSMul:= ReadFloat('PaletteSMul', m7*0.65 + m8*1);
      info:= 'Lightness aka Value multiplier for all graphics (1.1 by default, 1.04 for no change)';
      PaletteVMul:= ReadFloat('PaletteVMul', 1.1);
      NoBitmapsHwl:= not FileExists('data\d3dbitmap.hwl') or ReadBool('NoD3DBitmapHwl', true, false);
      if NoBitmapsHwl then
      begin
        HDWTRCount:= max(1, min(15, ReadInteger('HDWTRCount', 7 + m8, false)));
        HDWTRDelay:= max(1, ReadInteger('HDWTRDelay', 20, false));
      end else
      begin
        HDWTRCount:= max(1, min(15, ReadInteger('HDWTRCountHWL', 7, false)));
        HDWTRDelay:= max(1, ReadInteger('HDWTRDelayHWL', 20, false));
      end;
{$ENDIF}
      FixInfiniteScrolls:= ReadBool('FixInfiniteScrolls', true, false);
      FixInactivePlayersActing:= ReadBool('FixInactivePlayersActing', true, false);
      {$IFDEF mm8}FixSkyBitmap:= ReadBool('FixSkyBitmap', true, false);{$ENDIF}
      FixChestsByReorder:= ReadBool('FixChestsByReorder', true, false);
      {$IFDEF mm7}FixGMStaff:= ReadBool('FixGMStaff', true, false);{$ENDIF}
      FixTimers:= ReadBool('FixTimers', true, false);
      info:= 'Multiplier used to speed up monsters'' turn in turn-based mode';
      TurnBasedSpeed:= ReadInteger('TurnBasedSpeed', 1);
      info:= 'Multiplier used to speed up party turn in turn-based mode';
      TurnBasedPartySpeed:= ReadInteger('TurnBasedPartySpeed', 1);
      FixMovement:= ReadBool('FixMovement', true, false);
      MonsterJumpDownLimit:= ReadInteger('MonsterJumpDownLimit', 500, false);
      {$IFDEF mm8}FixHeroismPedestal:= ReadBool('FixHeroismPedestal', true, false);{$ENDIF}
      info:= 'Makes Unicorn King appear only after you''ve visited all obelisks (set to 0 to return to original behavior)';
      {$IFDEF mm8}FixObelisks:= ReadBool('FixObelisks', true);{$ENDIF}
      info:= 'Window width in Windowed mode (set to -1 to deduce from WindowHeight option)';
      WindowWidth:= ReadInteger('WindowWidth', -1);
      info:= 'Window height in Windowed mode (set to -1 to deduce from WindowWidth option)';
      WindowHeight:= ReadInteger('WindowHeight', 480);
      info:= 'Allow stretching game view horizontally this much to reduce black bars size';
      StretchWidth:=  max(1, ReadFloat('StretchWidth', 1));
      info:= 'Like StretchWidth, but only applied if it makes black bars go away';
      StretchWidthFull:= max(StretchWidth, ReadFloat('StretchWidthFull', 1));
      info:= 'Allow stretching game view vertically this much to reduce black bars size';
      StretchHeight:= max(1, ReadFloat('StretchHeight', 1));
      info:= 'Like StretchHeight, but only applied if it makes black bars go away';
      StretchHeightFull:= max(StretchHeight, ReadFloat('StretchHeightFull', 1.067)); // stretch to 5:4
      info:= 'Makes the game occupy full screen without changing resolution (note: use F4 to go to/from full screen mode)';
      BorderlessFullscreen:= ReadBool('BorderlessFullscreen', true);
      BorderlessProportional:= ReadBool('BorderlessProportional', false, false);
      CompatibleMovieRender:= ReadBool('CompatibleMovieRender', true, false);
      SmoothMovieScaling:= ReadBool('SmoothMovieScaling', true, false);
      SupportTrueColor:= ReadBool('SupportTrueColor', true, false);
      RenderMaxWidth:= ReadInteger('RenderMaxWidth', 0, false);
      RenderMaxHeight:= ReadInteger('RenderMaxHeight', 0, false);
      ScalingParam1:= ReadFloat('ScalingParam1', 3, false);
      ScalingParam2:= ReadFloat('ScalingParam2', 0.2, false);
      info:= 'For Hardware 3D mode. Bigger values lead to less flickering at a distance, but more washed-out look';
      {$IFNDEF mm6}MipmapsCount:= ReadInteger('MipmapsCount', 3);{$ENDIF}
      info:= 'Set this to a value of your choice (e.g. 100) to be able to do individual steps in the walking phase of turn-based combat';
      {$IFNDEF mm6}TurnBasedWalkDelay:= ReadInteger('TurnBasedWalkDelay', 0);{$ENDIF}
      info:= '';
      MouseLookCursorHD:= ReadBool('MouseLookCursorHD', true, false);
      SmoothScaleViewSW:= ReadBool('SmoothScaleViewSW', true, false);
      {$IFDEF mm8}NoWaterShoreBumpsSW:= ReadBool('NoWaterShoreBumpsSW', true, false);{$ENDIF}
      {$IFDEF mm8}FixUnimplementedSpells:= ReadBool('FixUnimplementedSpells', true, false);{$ENDIF}
      {$IFNDEF mm6}FixMonsterSummon:= ReadBool('FixMonsterSummon', true, false);{$ENDIF}
      {$IFDEF mm8}FixQuickSpell:= ReadBool('FixQuickSpell', true, false);{$ENDIF}
      {$IFDEF mm7}FixInterfaceBugs:= ReadBool('FixInterfaceBugs', true, false);{$ENDIF}
      {$IFDEF mm8}FixIndoorFOV:= ReadBool('FixIndoorFOV', true, false);{$ENDIF}
      {$IFNDEF mm6}
      info:= 'Set this to "UI" to enable flexible UI with wide screen support, set to an empty or invalid string to disable (see the patch readme for more info)';
      pstring(@UILayout)^:= ReadString('UILayout', '');
      if (UILayout <> nil) and not FileExists('Data\' + UILayout + '.txt') then
        pstring(@UILayout)^:= '';
      {$ENDIF}
      info:= 'Set this to 1 to see paper dolls when opening inventory from chest dialog, set to 2 to see paper doll right next to chest contents, set to 0 to disable';
      PaperDollInChests:= ReadInteger('PaperDollInChests', 1);
      info:= 'Places the "Close" button that closes rings view next to the magnifying glass, like in MM6. Set to 0 to disable';
      {$IFDEF mm7}HigherCloseRingsButton:= ReadBool('HigherCloseRingsButton', true);{$ENDIF}
      info:= '';
      PlaceChestItemsVertically:= ReadBool('PlaceChestItemsVertically', true, false);
      {$IFDEF mm7}SupportMM7ResTool:= ReadBool('SupportMM7ResTool', false, false);{$ENDIF}
      info:= '';
      FixChestsByCompacting:= ReadBool('FixChestsByCompacting', true, false);
      SpriteAngleCompensation:= ReadBool('SpriteAngleCompensation', true, false);
      {$IFNDEF mm6}TrueColorTextures:= SupportTrueColor and ReadBool('TrueColorTextures', BorderlessFullscreen, false);{$ENDIF}
      {$IFNDEF mm6}TrueColorSprites:= SupportTrueColor and ReadBool('TrueColorSprites', false, false);{$ENDIF}
      FixSFT:= ReadBool('FixSFT', true, false);
      info:= 'Set this to 1 to show hints for non-interactive decorations in Hardware 3D mode. Set to 0 to hide them. Set to 2 to force them on even in UI Layout mode with status bar auto-hiding enabled';
      {$IFNDEF mm6}TreeHintsVal:= ReadInteger('TreeHints', m7);{$ENDIF}
      {$IFNDEF mm6}ShowTreeHints:= (TreeHintsVal <> 0);{$ENDIF}
      info:= '';
      {$IFNDEF mm6}SpriteInteractIgnoreId:= ReadBool('SpriteInteractIgnoreId', true, false);{$ENDIF}
      {$IFNDEF mm6}AxeGMFullProbabilityAt:= ReadInteger('AxeGMFullProbabilityAt', 60, false);{$ENDIF}
      ClickThroughEffects:= ReadBool('ClickThroughEffects', true, false);
      WinScreenDelay:= ReadInteger('WinScreenDelay', 500, false);
      FixConditionPriorities:= ReadBool('FixConditionPriorities', true, false);
      HintStayTime:= ReadInteger('HintStayTime', 2, false);
      info:= 'Set this to 1 to stop monster shots being suspended in the air in dungeons when blocked by other monsters. This makes the game harder';
      {$IFNDEF mm6}FixMonstersBlockingShots:= ReadBool('FixMonstersBlockingShots', false);{$ENDIF}
      info:= '';
      {$IFDEF mm7}FixLichImmune:= ReadBool('FixLichImmune', true, false);{$ENDIF}
      {$IFDEF mm6}FixParalyze:= ReadBool('FixParalyze', true, false);{$ENDIF}
      info:= 'When enabled, lets you choose a spell that would be used by a player instead of regular attack';
      EnableAttackSpell:= ReadBool('EnableAttackSpell', true);
      info:= 'Set this to 1 to enable shooter mode (see patch readme for more info)';
      ShooterMode:= BoolToInt[ReadBool('ShooterMode', false)];
      ShowHintWithRMB:= ReadBool('ShowHintWithRMB', true, false);
      {$IFNDEF mm6}FixHitDistantMonstersIndoor:= ReadBool('FixHitDistantMonstersIndoor', true, false);{$ENDIF}
      GreenItemsWhileRightClick:= ReadBool('GreenItemsWhileRightClick', true, false);
      FixDeadPlayerIdentifyItem:= ReadBool('FixDeadPlayerIdentifyItem', true, false);
      info:= 'Set this to 1 to allow seeing item info inside inventory screen of an unconscious player';
      DeadPlayerShowItemInfo:= ReadBool('DeadPlayerShowItemInfo', false);
      info:= 'Bypass ddraw.dll found in game folder';
      i:= ReadInteger('SystemDDraw', MaxInt, false);
      UseVoodoo:= FileExists(AppPath + 'ddraw.dll');
      if (m6 = 0) and (i = MaxInt) and UseVoodoo then
      begin
        SystemDDraw:= RSMessageBox(0, SVoodooMsg, SCaption, MB_ICONEXCLAMATION or MB_OKCANCEL) <> ID_OK;
        ini.WriteBool(sect, 'SystemDDraw', SystemDDraw);
      end else
        SystemDDraw:= (i <> MaxInt) and (i <> 0);
      UseVoodoo:= UseVoodoo and not SystemDDraw;
      if UseVoodoo then
        TrueColorTextures:= TrueColorSprites;
      dist_mist:= ReadInteger('dist_mist', m6*$2000, false);
      MonSpritesSizeMul:= Round($10000*ReadFloat('MonSpritesSizeMul', 0, false));
      {$IFNDEF mm6}
      //info:= 'View distance in Direct 3D mode. Causes minor graphical glitches. Set to 0 to disable.';
      ViewDistanceD3D:= ReadInteger('ViewDistanceD3D', 12000);
      FixIceBoltBlast:= ReadBool('FixIceBoltBlast', true, false);
      FixMonsterAttackTypes:= ReadBool('FixMonsterAttackTypes', true, false);
      IndoorAntiFov:= Round(300/ReadFloat('IndoorFovMul', 300/369, false));
      {$ENDIF}
      FixHouseAnimationRestart:= ReadBool('FixHouseAnimationRestart', true, false);
      info:= 'Makes right mouse button act as Esc in houses, NPC, map entrance and message dialogs.';
      ExitTalkingWithRightButton:= ReadBool('ExitDialogsWithRightButton', false, false);
      FixMonsterSpells:= ReadBool('FixMonsterSpells', true, false);
      NeedFreeSpaceCheck:= ReadBool('CheckFreeSpace', true, false);

{$IFDEF mm6}
      info:= 'Set this to 0 to disable loading of mm6text.dll';
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
        if SupportTrueColor then
          ini.ReadSection('MipmapsBase', MipmapsBase)
        else
          MipmapsCount:= 0;

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
      info:= 'Set this to 0 to disable loading of mm7text.dll';
      if FileExists(AppPath + 'mm7text.dll') then
        UseMM7text:= ReadBool('UseMM7textDll', true);
{$ENDIF}
      info:= '';
      ReadDisabledHooks(ReadString('DisableHooks', '', false));

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
{$IFNDEF mm8}
      SChooseASpell:= ReadString('ChooseAttackSpell', 'Select a spell then click here to set an Attack Spell');
      SSetASpell:= ReadString('SetAttackSpell', 'Set %s as the Attack Spell');
      SSetASpell2:= ReadString('SwitchAttackSpell', 'Set as Attack Spell (instead of %s)');
      SRemoveASpell:= ReadString('RemoveAttackSpell', 'Remove Attack Spell (%s)');
{$ELSE}
      SChooseASpell:= ReadString('ChooseAttackSpell', 'No Attack Spell');
      SSetASpell:= ReadString('SetAttackSpell', 'Set as Attack Spell');
      SSetASpell2:= ReadString('SwitchAttackSpell', 'Change Attack Spell (%s)');
      SRemoveASpell:= ReadString('RemoveAttackSpell', 'Remove Attack Spell (%s)');
{$ENDIF}
      HorsemanSpeakTime:= ReadInteger('HorsemanSpeakTime', 1500);
      BoatmanSpeakTime:= ReadInteger('BoatmanSpeakTime', 2500);
{$IFNDEF mm6}
      SDuration:= ReadString('Duration', 'Duration:', false);
      SDurationYr:= ReadString('DurationYr', ' %d:yr', false);
      SDurationMo:= ReadString('DurationMo', ' %d:mo', false);
      SDurationDy:= ReadString('DurationDy', ' %d:dy', false);
      SDurationHr:= ReadString('DurationHr', ' %d:hr', false);
      SDurationMn:= ReadString('DurationMn', ' %d:mn', false);
{$ENDIF}

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
  if (GetForegroundWindow = _MainWindow^) and IsWindowEnabled(_MainWindow^) and ((GetFocus = _MainWindow^) or (GetFocus = 0)) then
  begin
    BringWindowToTop(_MainWindow^);
    ClipCursor(@r);
  end;
end;

function PtInView(x, y: int): Boolean;
begin
  with _RenderRect^ do
    Result:= (x >= Left) and (x < Right) and (y >= Top) and (y <= Bottom);
  if (m8 = 1) then
  begin
    NeedScreenWH;
    Result:= Result and ((y >= 64) or (x >= 64) and (x < SW - 64));
  end;
end;

function GetMouseTarget: int;
const
  GetD3D: function(_,__, this: int): int = ptr(m7*$4C1B63 + m8*$4BF70D);
begin
  NeedScreenWH;
{$IFNDEF MM6}
  if _IsD3D^ then
    Result:= GetD3D(0,0, pint(_CGame^ + 3660)^)
  else
{$ENDIF}
  with GameCursorPos^ do
    Result:= _ObjectByPixel^[X + Y*SW];
  Result:= word(Result);
end;

function CastRay(var x, y, z: ext; x0, y0: ext): ext;
var
  m, s, c: ext;
begin
  // get X, Y, Z in screen space based coordinate system (but with vertical Z)
  y:= GetViewMul;
  x:= x0 - _ScreenMiddle.X;
  z:= _ScreenMiddle.Y - y0 + 0.5; // don't know why +0.5 is needed
  // transform to world coordinate system
  // theta:
  SinCos(_Party_Angle^*Pi/1024, s, c);
  m:= y*c - z*s;
  z:= z*c + y*s;
  // phi:
  SinCos(_Party_Direction^*Pi/1024, s, c);
  y:= m*s - x*c;
  x:= m*c + x*s;
  // length
  Result:= sqrt(x*x + y*y + z*z);
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

procedure ShowStatusText(text: string; time: int = 2);
begin
  _ShowStatusText(0, time, ptr(text));
  _NeedRedraw^:= 1;
end;

procedure NeedScreenWH;
begin
  SW:= _ScreenW^;
  SH:= _ScreenH^;
  if SW = 0 then  SW:= 640;
  if SH = 0 then  SH:= 480;
end;

procedure DoDraw8(ps: PByte; pd: PWord; ds, dd, w, h: int; pal: PWordArray; solid: Boolean); inline;
var
  x: int;
begin
  dec(ds, w);
  dec(dd, w*2);
  for h:= h downto 1 do
  begin
    for x:= w downto 1 do
    begin
      if solid or (ps^ <> 0) then
        pd^:= pal[ps^];
      inc(ps);
      inc(pd);
    end;
    inc(PChar(ps), ds);
    inc(PChar(pd), dd);
  end;
end;

procedure Draw8(ps: PByte; pd: PWord; ds, dd, w, h: int; pal: PWordArray);
begin
  DoDraw8(ps, pd, ds, dd, w, h, pal, true);
end;

procedure Draw8t(ps: PByte; pd: PWord; ds, dd, w, h: int; pal: PWordArray);
begin
  DoDraw8(ps, pd, ds, dd, w, h, pal, false);
end;

function LoadIcon(const name: string): int;
begin
  Result:= _LoadLodBitmap(0,0, _IconsLod, {$IFDEF mm8}0,0,{$ENDIF} 2, PChar(name));
end;

function FindDlg(id: int): PDlg;
var
  i: int;
begin
  for i := _DialogsHigh^ downto 0 do
  begin
    Result:= @_DlgArray[_Dialogs[i]];
    if Result.ID = id then
      exit;
  end;
  Result:= nil;
end;

procedure CallPtr; // ecx, pfunc, params...
asm
  pop edx
  pop ecx
  xchg edx, [esp]
  jmp edx
end;

procedure CallVMT; // ecx, VMTOffset, params...
asm
  pop edx
  pop ecx
  xchg edx, [esp]
  mov eax, [ecx]
  jmp [eax + edx]
end;

function NewButtonMM8(id, action: int; actionInfo: int = 0; hintAction: int = 0): ptr;
type
  TF = function(btn: ptr; f, id, action, actionInfo, hintAction: int): ptr; stdcall;
begin
  Result:= TF(@CallPtr)(_new($E0), $4C2439, id, action, actionInfo, hintAction);
end;

procedure SetupButtonMM8(btn: ptr; x, y: int; transp: Bool; normalPic: PChar = nil; pressedPic: PChar = nil; hoverPic: PChar = nil; disabledPic: PChar = nil; englishD: Bool = false);
type
  TF = procedure(btn: ptr; VMTOff: int; var xy: TPoint; transp: Bool; normalPic, pressedPic, hoverPic, disabledPic: PChar; englishD: Bool); stdcall;
var
  p: TPoint;
begin
  p.X:= x;
  p.Y:= y;
  TF(@CallVMT)(btn, 168, p, transp, normalPic, pressedPic, hoverPic, disabledPic, englishD);
end;

procedure AddToDlgMM8(dlg, btn: ptr);
type
  TF = procedure (dlg: ptr; VMTOff: int; btn: ptr); stdcall;
begin
  TF(@CallVMT)(dlg, 164, btn);
end;

function GetCurrentPlayer: ptr;
const
  PartyMembers = PPtrArray(m6*$944C68 + m7*$A74F48 + m8*$B7CA4C);
begin
  Result:= nil;
  if _CurrentMember^ <= 0 then  exit;
  Result:= PartyMembers[_CurrentMember^ - 1];
  if m8 = 1 then
    Result:= ptr(_PlayersArray + _CharOff_Size*int(Result));
end;

function IsMonAlive(m: PChar; CheckStoned: Boolean): Boolean;
begin
  Result:= not (pword(m + _MonOff_AIState)^ in [4,5,11,17,19]);
  if CheckStoned then
    Result:= Result and (pint64(m + _MonOff_Buff_Stoned)^ = 0);
end;

procedure DoPlaySound;
asm
  mov ecx, _PlaySoundStruct
  push _PlaySound
end;

procedure DoLoadSound;
asm
  mov ecx, _PlaySoundStruct
  push m6*$48E2D0 + m7*$4A99F7 + m8*$4A7F22
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
  @PlaySound:= @DoPlaySound;
  @LoadSound:= @DoLoadSound;
end.

