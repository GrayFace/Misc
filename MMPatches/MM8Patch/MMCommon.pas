unit MMCommon;

interface

uses
  Windows, Messages, SysUtils, Classes, RSSysUtils, RSQ, Math, Common, IniFiles;

{$I MMPatchVer.inc}

const
{$IFDEF mm6}
  IsMM6 = 1;
  IsMM7 = 0;
  IsMM8 = 0;
{$ELSEIF defined(mm7)}
  IsMM6 = 0;
  IsMM7 = 1;
  IsMM8 = 0;
{$ELSEIF defined(mm8)}
  IsMM6 = 0;
  IsMM7 = 0;
  IsMM8 = 1;
{$IFEND}

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

type
  TOptions = packed record
    Size: int;
    MaxMLookAngle: int;                       // 4
    MouseLook: LongBool;                      // 8
    MouseLookUseAltMode: LongBool;            // 12
    CapsLockToggleMouseLook: LongBool;        // 16
    MouseFly: LongBool;                       // 20
    MouseWheelFly: LongBool;                  // 24
    MouseLookTempKey: int;                    // 28
    MouseLookChangeKey: int;                  // 32
    InventoryKey: int;                        // 36
    CharScreenKey: int;                       // 40
    DoubleSpeedKey: int;                      // 44
    QuickLoadKey: int;                        // 48
    AutorunKey: int;                          // 52
    HDWTRCount: uint;                         // 56 (unused in MM6)
    HDWTRDelay: uint;                         // 60 (unused in MM6)
    HorsemanSpeakTime: int;                   // 64
    BoatmanSpeakTime: int;                    // 68
    PaletteSMul: single;                      // 72 (unused in MM6)
    PaletteVMul: single;                      // 76 (unused in MM6)
    NoBitmapsHwl: LongBool;                   // 80 (unused in MM6)
    PlayMP3: LongBool;                        // 84
    MusicLoopsCount: int;                     // 88
    HardenArtifacts: LongBool;                // 92 (unused in MM6)
    ProgressiveDaggerTrippleDamage: LongBool; // 96
    FixChests: LongBool;                      // 100
    DataFiles: LongBool;                      // 104
    FixDualWeaponsRecovery: LongBool;         // 108 (MM6 only)
    IncreaseRecoveryRateStrength: int;        // 112 (MM6 only)
    BlasterRecovery: int;                     // 116 (unused in MM8)
    FixSkyBitmap: LongBool;                   // 120 (MM8 only)
    NoCD: LongBool;                           // 124
    FixChestsByReorder: LongBool;             // 128
    LastLoadedFileSize: int;                  // 132
    FixTimers: LongBool;                      // 136
    FixMovement: LongBool;                    // 140
    MonsterJumpDownLimit: int;                // 144
    FixHeroismPedestal: LongBool;             // 148 (MM8 only)
    SkipUnsellableItemCheck: LongBool;        // 152 (MM7 only)
    FixGMStaff: LongBool;                     // 156 (MM7 only)
    FixObelisks: LongBool;                    // 160 (MM8 only)
    BorderlessWindowed: LongBool;             // 164
    CompatibleMovieRender: LongBool;          // 168
    SmoothMovieScaling: LongBool;             // 172
    SupportTrueColor: LongBool;               // 176
    RenderRect: TRect;                        // 180
    FixUnimplementedSpells: LongBool;         // 184 (MM8 only)
    IndoorMinimapZoomMul: int;                // 188
    IndoorMinimapZoomPower: int;              // 192
    FixMonsterSummon: LongBool;               // 196 (unused in MM6)
    FixInterfaceBugs: LongBool;                  // 200 (MM7 only)
  end;

var
  Options: TOptions = (
    Size: SizeOf(TOptions);
    MaxMLookAngle: 200;
{$IFDEF mm8}
    RenderRect: (Left: 0; Top: 29; Right: 640; Bottom: 480 - 113);
{$ELSE}
    RenderRect: (Left: 8; Top: 8; Right: 468; Bottom: 352);
{$ENDIF}
    IndoorMinimapZoomMul: 1024;
    IndoorMinimapZoomPower: 10;
  );

var
  QuickSavesCount, QuickSaveKey, TurnBasedSpeed, TurnBasedPartySpeed,
  WindowWidth, WindowHeight, RenderMaxWidth, RenderMaxHeight, MipmapsCount: int;

  MLookSpeed, MLookSpeed2: TPoint;
  MouseLookRememberTime: uint;
  MLookRightPressed: pbool = _RightButtonPressed;

  TurnSpeedNormal, TurnSpeedDouble: single;
  
  StretchWidth, StretchWidthFull, StretchHeight, StretchHeightFull,
  ScalingParam1, ScalingParam2: ext;

  RecoveryTimeInfo, PlayerNotActive, SDoubleSpeed, SNormalSpeed,
  QuickSaveName, QuickSaveDigitSpace: string;

  CapsLockToggleRun, NoDeathMovie, FreeTabInInventory, ReputationNumber,
  AlwaysStrafe, StandardStrafe, MouseLookChanged, FixInfiniteScrolls,
  FixInactivePlayersActing, BorderlessFullscreen, BorderlessProportional,
  MouseLookCursorHD, SmoothScaleViewSW, WasIndoor: Boolean;
  {$IFNDEF mm6}
  NoIntro, NoVideoDelays, DisableAsyncMouse: Boolean;
  TurnBasedWalkDelay: int;
  MipmapsBase, MipmapsBasePat: TStringList;
  {$ENDIF}

  TimersValidated: int64;

{$IFDEF mm6}
  GameSavedText: string;

  UseMM6text, AlwaysRun, FixWalk, FixStarburst, PlaceItemsVertically,
  NoPlayerSwap: Boolean;

  MappedKeys, MappedKeysBack: array[0..255] of Byte;
{$ELSEIF defined(mm7)}
  UseMM7text: Boolean;
{$ELSEIF defined(mm8)}
  NoWaterShoreBumpsSW, FixQuickSpell: Boolean;
  MouseBorder, StartupCopyrightDelay: int;
{$IFEND}

type
  PHwlBitmap = ^THwlBitmap;
  THwlBitmap = packed record
    HwlName: array[1..$14] of byte;
    HwlPalette: int;
    FullW: int;
    FullH: int;
    AreaW: int;
    AreaH: int;
    BufW: int;
    BufH: int;
    AreaX: int;
    AreaY: int;
    Buffer: ptr;
  end;
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
    
const
  _ActionQueue: PActionQueue = ptr(IsMM6*$4D5F48 + IsMM7*$50CA50 + IsMM8*$51E330);
  PowerOf2: array[0..15] of int = (1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768);

{$IFNDEF mm6}
var
  Sprites: array[0..SpritesMax-1] of TSprite;
{$ENDIF}

procedure LoadIni;
function GetOptions: ptr; stdcall;
procedure LoadExeMods;
{$IFNDEF mm6}
function GetMipmapsCountProc(var a: THwlBitmap; p: PChar): int;
procedure AddMipmapBase(p: PChar; v: int);
{$ENDIF}
function GetMapExtra: PMapExtra;

// make semi-transparent borders not black when scaling
procedure PropagateIntoTransparent(p: PWordArray; w, h: int);
procedure Wnd_CalcClientRect(var r: TRect);
procedure Wnd_PaintBorders(wnd: HWND; wp: int);
procedure Wnd_Sizing(wnd: HWND; side: int; var r: TRect);

implementation

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
    old: char;
  begin
    Assert(iniOverride = nil);
    old:= DecimalSeparator;
    DecimalSeparator:= '.';
    Result:= ini.ReadFloat(sect, key, NaN);
    if IsNan(Result) then
    begin
      ini.WriteFloat(sect, key, default);
      Result:= default;
    end;
    DecimalSeparator:= old;
  end;

{$IFDEF mm6}
var
  i, j:int;
{$ELSE}
var
  i:int;
{$ENDIF}
begin
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
      ini.DeleteKey(sect, 'FixCompatibility');
{$ELSE}
      NoVideoDelays:= ini.ReadBool(sect, 'NoVideoDelays', true);
      HardenArtifacts:= ini.ReadBool(sect, 'HardenArtifacts', true);
      DisableAsyncMouse:= ini.ReadBool(sect, 'DisableAsyncMouse', true);
{$ENDIF}
      CapsLockToggleRun:= ReadBool('CapsLockToggleRun', false);

      QuickSavesCount:= ReadInteger('QuickSavesCount', 2);
{$IFNDEF mm8}
      i:= ini.ReadInteger(sect, 'QuickSaveKey', 11) + VK_F1 - 1;
      if (i < VK_F1) or (i > VK_F24) then
        i:= VK_F11;
      QuickSaveKey:= ReadInteger('QuickSavesKey', i);
      ini.DeleteKey(sect, 'QuickSaveKey');
      ini.DeleteKey(sect, 'QuickSaveSlot1');
      ini.DeleteKey(sect, 'QuickSaveSlot2');
      ini.DeleteKey(sect, 'QuickSaveName');
{$ELSE}
      QuickSaveKey:= ReadInteger('QuickSavesKey', VK_F11);
      ini.DeleteKey(sect, 'JumpSpeed');
{$ENDIF}
      if (QuickSaveKey < 0) or (QuickSaveKey > 255) then
        QuickSaveKey:= VK_F11;
      QuickLoadKey:= ReadInteger('QuickLoadKey', 0);

      NoDeathMovie:= ReadBool('NoDeathMovie', false);
      {$IFDEF mm6}_NoIntro^{$ELSE}NoIntro{$ENDIF}:= ReadBool('NoIntro', false);
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
      {$IFNDEF mm6}NoBitmapsHwl:= ReadBool('NoD3DBitmapHwl', true);{$ENDIF}
      MouseLook:= ReadBool('MouseLook', false);
      MLookSpeed.X:= ReadInteger('MouseSensitivityX', 35);
      MLookSpeed.Y:= ReadInteger('MouseSensitivityY', 35);
      MLookSpeed2.X:= ReadInteger('MouseSensitivityAltModeX', 75);
      MLookSpeed2.Y:= ReadInteger('MouseSensitivityAltModeY', 75);
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
      {$IFDEF mm7}PaletteSMul:= ReadFloat('PaletteSMul', 0.65);{$ENDIF}
      {$IFDEF mm8}PaletteSMul:= ReadFloat('PaletteSMul', 1);{$ENDIF}
      {$IFNDEF mm6}PaletteVMul:= ReadFloat('PaletteVMul', 1.1);{$ENDIF}
      {$IFDEF mm8}StartupCopyrightDelay:= ReadInteger('StartupCopyrightDelay', 5000);{$ENDIF}
      AutorunKey:= ReadInteger('AutorunKey', VK_F3);
{$IFNDEF mm6}
      if NoBitmapsHwl then
      begin
        HDWTRCount:= max(1, min(15, ini.ReadInteger(sect, 'HDWTRCount', {$IFDEF mm7}7{$ELSE}8{$ENDIF})));
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
      if WindowWidth <= 0 then
        if WindowHeight <= 0 then
        begin
          WindowWidth:= 640;
          WindowHeight:= 480;
        end else
          WindowWidth:= (WindowHeight*4 + 1) div 3
      else if WindowHeight <= 0 then
        WindowHeight:= (WindowWidth*3 + 2) div 4;
      WindowWidth:= max(640, WindowWidth);
      WindowHeight:= max(480, WindowHeight);
      StretchWidth:=  max(1, ReadFloat('StretchWidth', 1));
      StretchWidthFull:= max(StretchWidth, ReadFloat('StretchWidthFull', 1));
      StretchHeight:= max(1, ReadFloat('StretchHeight', 1));
      StretchHeightFull:= max(StretchHeight, ReadFloat('StretchHeightFull', 1.067)); // stretch to 5:4
      BorderlessFullscreen:= ReadBool('BorderlessFullscreen', true);
      BorderlessProportional:= ini.ReadBool(sect, 'BorderlessProportional', false);
      BorderlessWindowed:= true;
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

function PropagateColor(p: PWordArray; x, y, w, h, dx, dy: int; need: Word): Boolean; inline;
var
  c: Word;
begin
  Result:= false;
  if (dx < 0) and (x + dx < 0) then  exit;
  if (dy < 0) and (y + dy < 0) then  exit;
  if (dx > 0) and (x + dx >= w) then  exit;
  if (dy > 0) and (y + dy >= h) then  exit;
  c:= p[dx + dy*w];
  Result:= (c > need);
  if Result then
    p[0]:= c and $7FFF;
end;

procedure PropagateIntoTransparent(p: PWordArray; w, h: int);
var
  found: Boolean;
  x, y: int;
begin
  found:= false;
  for y:= 0 to h - 1 do
    for x:= 0 to w - 1 do
    begin
      found:= (p[0] = 0) and
        (PropagateColor(p, x, y, w, h, -1, 0, $7FFF) or
         PropagateColor(p, x, y, w, h, 1, 0, $7FFF) or
         PropagateColor(p, x, y, w, h, 0, -1, $7FFF) or
         PropagateColor(p, x, y, w, h, 0, 1, $7FFF)) or found;
      inc(PWord(p));
    end;
  if not found then
    exit;
  dec(PWord(p), w*h);
  for y:= 0 to h - 1 do
    for x:= 0 to w - 1 do
    begin
      if (p[0] <> 0) or
        PropagateColor(p, x, y, w, h, -1, 0, 0) or
        PropagateColor(p, x, y, w, h, 1, 0, 0) or
        PropagateColor(p, x, y, w, h, 0, -1, 0) or
        PropagateColor(p, x, y, w, h, 0, 1, 0) then ;
      inc(PWord(p));
    end;
end;

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
  w, h, SW, SH: int;
begin
  SW:= max(_ScreenW^, 640);
  SH:= max(_ScreenH^, 480);
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

procedure Wnd_Sizing(wnd: HWND; side: int; var r: TRect);
var
  CW: int absolute WindowWidth;
  CH: int absolute WindowHeight;
  w, h, w0, h0, SW, SH: int;
  r0, r1: TRect;
begin
  SW:= max(_ScreenW^, 640);
  SH:= max(_ScreenH^, 480);
  GetClientRect(wnd, r0);
  GetWindowRect(wnd, r1);
  w0:= r.Right - r.Left - r1.Right + r1.Left + r0.Right;
  h0:= r.Bottom - r.Top - r1.Bottom + r1.Top + r0.Bottom;
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

  if side in [WMSZ_LEFT, WMSZ_TOPLEFT, WMSZ_BOTTOMLEFT] then
    dec(r.Left, w - w0)
  else
    inc(r.Right, w - w0);

  if side in [WMSZ_TOP, WMSZ_TOPLEFT, WMSZ_TOPRIGHT] then
    dec(r.Top, h - h0)
  else
    inc(r.Bottom, h - h0);
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
    Result:= ptr(IsMM6*$5F7D74 + IsMM7*$6BE534 + IsMM8*$6F3CF4)
  else
    Result:= ptr(IsMM6*$689C78 + IsMM7*$6A1160 + IsMM8*$6CF0CC);
end;

exports
{$IFNDEF mm6}
  AddMipmapBase,
{$ENDIF}
  GetOptions;
end.

