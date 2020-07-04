unit MMHooks;

interface
{$I MMPatchVer.inc}

uses
  Windows, Messages, SysUtils, Classes, RSSysUtils, RSQ, Common, RSCodeHook,
  Math, MP3, RSDebug, IniFiles, Direct3D, Graphics, MMSystem, RSStrUtils,
  DirectDraw, DXProxy, {$IFNDEF MM6}LayoutSupport,{$ENDIF} MMCommon,
  RSResample{$IFDEF MM8}, MMLayout{$ENDIF};

procedure ApplyMMHooks;
procedure ApplyMMDeferredHooks;
procedure ApplyMMHooksSW;
procedure NeedWindowSize;
procedure LoadInterface;
procedure InterfaceColorChanged(_: Bool; Replace: Boolean; Align: int);
function GetCoordCorrectionIndoorX: ext;
function GetCoordCorrectionIndoorY: ext;
function IsLayoutActive(CanActivate: Boolean = true): Boolean; inline;
function TransformMousePos(x, y: int; out x1: int): int;
function MyGetAsyncKeyState(vKey: Integer): SHORT; {$IFNDEF MM6}stdcall;{$ENDIF}
function CheckKey(key: int):Boolean;
procedure CommonKeysProc;
procedure MyClipCursor;
procedure ProcessMouseLook;
procedure ProcessRawMouseLook(h: THandle);
procedure NeedScreenDraw(var scale: TRSResampleInfo; sw, sh, w, h: int);
procedure DrawScaled(var scale: TRSResampleInfo; sw, sh: int; scan: ptr; pitch: int);
{$IFNDEF MM6}
function FindSprite(Name: PChar): PSprite; overload;
function FindSprite(var sp3d: TSpriteD3D): PSprite; overload;
{$ENDIF}

var
  AllowMovieQuickLoad: Boolean;
  ArrowCur: HCURSOR;
  MouseLookOn, MLookIsTemp, SkipMouseLook: Boolean;

implementation

const
  RingsShown = int(_InventoryRingsShown);
  CurrentScreen = int(_CurrentScreen);
  CurrentMember = int(_CurrentMember);
  NeedRedraw = int(_NeedRedraw);

// Raw mouse input
const
  WM_INPUT = $00FF;
  HID_USAGE_GENERIC_MOUSE = 2;
  RIDEV_INPUTSINK = $100;
  RID_INPUT  = $10000003;
  RIM_TYPEMOUSE      = 0;

type
  RAWINPUTDEVICE = record
    usUsagePage: WORD; // Toplevel collection UsagePage
    usUsage: WORD;     // Toplevel collection Usage
    dwFlags: DWORD;
    hwndTarget: HWND;    // Target hwnd. NULL = follows keyboard focus
  end;
  RAWINPUTHEADER = record
    dwType: DWORD;
    dwSize: DWORD;
    hDevice: THANDLE;
    wParam: WPARAM;
  end;
  TRawInputMouse = record
    header: RAWINPUTHEADER;
    usFlags: WORD;
    union: record
    case Integer of
      0: (
        ulButtons: ULONG);
      1: (
        usButtonFlags: WORD;
        usButtonData: WORD);
    end;
    ulRawButtons: ULONG;
    lLastX: LongInt;
    lLastY: LongInt;
    ulExtraInformation: ULONG;
  end;

var
  RegisterRawInputDevices: function(var pRawInputDevices: RAWINPUTDEVICE;
    uiNumDevices: UINT; cbSize: UINT): BOOL stdcall;
  GetRawInputData: function(hRawInput: THandle; uiCommand: UINT; var Data;
    var pcbSize: UINT; cbSizeHeader: UINT): UINT stdcall;

//----- Support any FOV outdoors

function AbsCheckOutdoor(v: int): int; cdecl;
var
  m: int;
begin
  Result:= abs(v);
  with Options.RenderRect do
    m:= 300 - _ViewMulOutdoor^*460 div (Right - Left);
  if m > 0 then
    dec(Result, (Result div 300)*m);
end;

//----- Support any FOV indoors

function GetRelCoordMulIndoor: ext;
begin
{$IFNDEF MM6}
  if _IsD3D^ then
    Result:= psingle(ppchar(_CGame^ + $E54)^ + $C4)^/406.35934448242
  else
{$ENDIF}
    Result:= _ViewMulIndoorSW^/369;
end;

function GetCoordCorrectionIndoorX: ext;
begin
  Result:= min(1, GetRelCoordMulIndoor*460/RectW(Options.RenderRect));
end;

function GetCoordCorrectionIndoorY: ext;
begin
  Result:= min(1, GetRelCoordMulIndoor*344/RectH(Options.RenderRect));
end;

function AbsCheckIndoor(v: int): int; cdecl;
begin
  Result:= Round(abs(v)*GetCoordCorrectionIndoorX);
end;

//----- Keys

var
  KeysChecked: array[0..255] of Boolean;

function MyGetAsyncKeyState(vKey: Integer): SHORT; {$IFNDEF MM6}stdcall;{$ENDIF}
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

//----- Keys Handler

procedure CommonKeysProc;
begin
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

  // Select 1st player in shops if all are inactive
  if FixInactivePlayersActing and (_CurrentMember^ = 0) and (_CurrentScreen^ = 13) then
    _CurrentMember^:= 1;
end;

//----- Window procedure hook

procedure MyClipCursor;
var
  r: TRect;
begin
  GetClientRect(_MainWindow^, r);
{$IFNDEF MM6}
  if Layout.Active and Layout.CheckClipCursorArea(r) then
    exit;
{$ENDIF}
  ClipCursorRel(r);
end;

type
  TWndProc = function(w: HWND; msg: uint; wp: WPARAM; lp: LPARAM):HRESULT; stdcall;

function WindowProcHook(WindowProcStd: TWndProc; _, __, lp: LPARAM; wp: WPARAM;
   msg: uint; w: HWND):HRESULT;
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
  if (msg >= WM_MOUSEFIRST) and (msg <= WM_MOUSELAST) then
    xy.y:= TransformMousePos(xy.x, xy.y, lp);
{$IFNDEF MM6}
  if (msg >= WM_MOUSEFIRST) and (msg <= WM_MOUSELAST) and IsLayoutActive then
    Layout.MouseMessage(msg, wp);
{$ENDIF}

  Result:= WindowProcStd(w, msg, wp, lp);

  case msg of
    WM_MOUSEWHEEL:
      if Options.MouseWheelFly then
        if wp < 0 then
          _AddCommand(0, 0, _CommandsArray, 14)
        else
          _AddCommand(0, 0, _CommandsArray, 13);
{$IFDEF MM6}
    WM_KEYDOWN, WM_SYSKEYDOWN:
      if wp and not $ff = 0 then
        KeysChecked[wp]:= false;
{$ENDIF}
    WM_INPUT:
      if MLookRaw then
        ProcessRawMouseLook(lp);
  end;

  if IsLayoutActive or not Options.BorderlessWindowed and IsZoomed(w) then
    case msg of
      WM_ACTIVATEAPP:
        if wp = 0 then
          ClipCursor(nil)
        else
          MyClipCursor;
      WM_SYSCOMMAND:
        if wp and $FFF0 = SC_RESTORE then
          MyClipCursor;
      WM_SETFOCUS:
        MyClipCursor;
      WM_KILLFOCUS:
        ClipCursor(nil);
    end;

  if not IsLayoutActive and _Windowed^ and IsZoomed(w) then
    case msg of
      WM_NCCALCSIZE:
        if wp <> 0 then
          with PNCCalcSizeParams(lp)^ do
          begin
            Wnd_CalcClientRect(rgrc[0]);
            Result:= WVR_REDRAW;
          end
        else if IsZoomed(w) then
          Wnd_CalcClientRect(PRect(lp)^);
      WM_NCPAINT:
        Wnd_PaintBorders(w, wp);
      WM_NCHITTEST:
        if Result = HTNOWHERE then
          Result:= HTBORDER;
    end;

  if _Windowed^ and (msg = WM_SIZING) and not IsZoomed(w) then
    {$IFNDEF MM6}if IsLayoutActive then
      Layout.Sizing(w, wp, PRect(lp)^)
    else{$ENDIF}
      Wnd_Sizing(w, wp, PRect(lp)^);

  if Options.SupportTrueColor and (msg = WM_SIZE) then
    DXProxyOnResize;

  if AllowMovieQuickLoad and (msg = WM_KEYDOWN) and (wp = Options.QuickLoadKey) then
  begin
    AllowMovieQuickLoad:= false;
    _AbortMovie^:= true;
  end;
end;

//----- Mouse look

const
  MLSideX = (1-m8)*(640 - (m6*8*2 + m7*4*2 + 460));
  MLSideY = 480 - m6*(8*2 + 345) - m7*(8*2 + 344) - m8*(29*2 + 338);
    // +32 to MLSideY would make mouse fly exact in SW
var
  MLookPartX, MLookPartY, MLookDX, MLookDY: int;
  MWndPos, MCenter, MLastPos, MLookTempPos: TPoint;
  MLookStartTime: DWORD;
  EmptyCur: HCURSOR;

function GetMLookPoint(var p: TPoint): BOOL;
begin
  if MouseLookOn then
  begin
    GameCursorPos^:= MCenter;
    p:= MWndPos;
    ClientToScreen(_MainWindow^, p);
    Result:= true;
  end else
    Result:= GetCursorPos(p);
end;

procedure GetMLookCenter(var MCenter, p: TPoint);
var
  r: TRect;
begin
  GetClientRect(_MainWindow^, r);
  if IsLayoutActive then
  begin
    {$IFNDEF MM6}Layout.GetMLookCenter(MCenter, p, r);{$ENDIF}
  end else
  begin
    // compatibility with high resolution
    p.X:= (MCenter.X*r.Right + SW - 1) div SW;
    p.Y:= (MCenter.Y*r.Bottom + SH - 1) div SH;
  end;
end;

procedure StartRawMouseLook;
var
  a: RAWINPUTDEVICE;
begin
  MLookRaw:= false;
  if RSLoadProc(@RegisterRawInputDevices, user32, 'RegisterRawInputDevices', false) = 0 then  exit;
  if RSLoadProc(@GetRawInputData, user32, 'GetRawInputData', false) = 0 then  exit;
  a.usUsagePage:= 1;
  a.usUsage:= HID_USAGE_GENERIC_MOUSE;
  a.dwFlags:= RIDEV_INPUTSINK;
  a.hwndTarget:= _MainWindow^;
  MLookRaw:= RSWin32Check(RegisterRawInputDevices(a, 1, SizeOf(a)));
  MLookSpeed.X:= Round(MLookSpeed.X*MLookRawMul);
  MLookSpeed.Y:= Round(MLookSpeed.Y*MLookRawMul);
  MLookSpeed2.X:= Round(MLookSpeed2.X*MLookRawMul);
  MLookSpeed2.Y:= Round(MLookSpeed2.Y*MLookRawMul);
end;

procedure CheckMouseLook;
const
  myAnd: int = -1;
  myXor: int = 0;
var
  cur: HCURSOR;
begin
  if SkipMouseLook then  // a hack for right-then-left click combo
  begin
    SkipMouseLook:= false;
    exit;
  end;
  NeedScreenWH;
  // compatibility with resolution patches like mmtool's one
  MCenter.X:= (SW - MLSideX) div 2;
  MCenter.Y:= (SH - MLSideY) div 2;
  GetMLookCenter(MCenter, MWndPos);

  if EmptyCur = 0 then
    EmptyCur:= CreateCursor(GetModuleHandle(nil), 0, 0, 1, 1, @myAnd, @myXor);
  if MLookRaw and (@GetRawInputData = nil) then
    StartRawMouseLook;
  cur:= GetClassLong(_MainWindow^, -12);
  with Options do
    MouseLookOn:= MouseLook and (_CurrentScreen^ = 0) and (_MainMenuCode^ < 0) and
       ((cur = EmptyCur) or (cur = ArrowCur)) and not MLookRightPressed^ and
       ( (GetAsyncKeyState(MouseLookTempKey) and $8000 = 0) xor
          MouseLookChanged xor MouseLookUseAltMode xor
          (CapsLockToggleMouseLook and (GetKeyState(VK_CAPSLOCK) and 1 <> 0)));

  if MouseLookOn <> (cur = EmptyCur) then
  begin
    if not MouseLookOn then
    begin
      SetClassLong(_MainWindow^, -12, ArrowCur);
      if m6 = 0 then
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
    if not MLookRaw then
    begin
      MLookDX:= p.X - MLastPos.X;
      MLookDY:= p.Y - MLastPos.Y;
    end;
    dir^:= (dir^ - Partial(MLookDX, MLookPartX, speed.X)) and 2047;
    angle^:= IntoRange(angle^ - Partial(MLookDY, MLookPartY, speed.Y),
      -Options.MaxMLookAngle, Options.MaxMLookAngle);
    if (MLookDX <> 0) or (MLookDY <> 0) then  //(p.X <> MLastPos.X) or (p.Y <> MLastPos.Y) then
    begin
      p:= MWndPos;
      ClientToScreen(_MainWindow^, p);
      SetCursorPos(p.X, p.Y);
    end;
    MLookDX:= 0;
    MLookDY:= 0;
  end;
  MLastPos:= p;
end;

procedure ProcessRawMouseLook(h: THandle);
var
  a: TRawInputMouse;
  sz: uint;
begin
  sz:= SizeOf(a);
  GetRawInputData(h, RID_INPUT, a, sz, SizeOf(RAWINPUTHEADER));
  if a.header.dwType <> RIM_TYPEMOUSE then  exit;
  if a.usFlags and 1 = 0 then
  begin
    inc(MLookDX, a.lLastX);
    inc(MLookDY, a.lLastY);
  end; // else absolute position is given
end;

procedure MouseLookHook(p: TPoint); stdcall;
begin
  CheckMouseLook;
  if MouseLookOn then
    GameCursorPos^:= MCenter
  else
    GameCursorPos^:= p;
end;

function MouseLookHook2(var p: TPoint): BOOL; stdcall;
begin
  CheckMouseLook;
  Result:= GetMLookPoint(p);
end;

var
  MouseLookHook3Std: procedure(a1, a2, this: ptr);
  MLookBmp: TBitmap;

function LoadMLookBmp(const fname: string; fmt: TPixelFormat): TBitmap;
var
  b: TBitmap;
  exist: Boolean;
begin
  Result:= TBitmap.Create;
  with Result, Canvas do
  begin
    PixelFormat:= fmt;
    HandleType:= bmDIB;
    b:= nil;
    exist:= FileExists(fname);
    if exist then
      try
        b:= TBitmap.Create;
        b.LoadFromFile(fname);
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
    DrawIconEx(Handle, 32, 32, ArrowCur, 0, 0, 0, 0, DI_NORMAL);
  end;
end;

procedure MLookLoadBmp;
var
  fmt: TPixelFormat;
begin
  if _GreenColorBits^ = 5 then
    fmt:= pf15bit
  else
    fmt:= pf16bit;
  MLookBmp:= LoadMLookBmp('Data\MouseLookCursor.bmp', fmt);
end;

procedure MLookDraw;
var
  p1, p2: PChar;
  x, y, w, h, d1, d2: int;
  k, trans: Word;
begin
  if MLookBmp = nil then
    MLookLoadBmp;
  w:= MLookBmp.Width;
  h:= MLookBmp.Height;
  p1:= MLookBmp.ScanLine[0];
  d1:= PChar(MLookBmp.ScanLine[1]) - p1 - 2*w;
  p2:= PChar(_ScreenBuffer^) + 2*(_ScreenW^*(MCenter.Y - h div 2) + MCenter.X - w div 2);
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

procedure MLookDrawHD(const p: TPoint);
var
  r: TRect;
begin
  if DXProxyCursorBmp = nil then
    DXProxyCursorBmp:= LoadMLookBmp('Data\MouseLookCursorHD.bmp', pf32bit);
  GetClientRect(_MainWindow^, r);
  DXProxyCursorX:= (p.X*DXProxyRenderW*2 div r.Right + 1) div 2 - DXProxyCursorBmp.Width div 2;
  DXProxyCursorY:= (p.Y*DXProxyRenderH*2 div r.Bottom + 1) div 2 - DXProxyCursorBmp.Height div 2;
end;

procedure MouseLookHook3(a1, a2, this: ptr);
begin
  CheckMouseLook;
  if MouseLookOn and not MLookIsTemp then
    if MouseLookCursorHD and DXProxyActive and
       ((DXProxyRenderW > SW) or (DXProxyRenderH > SH) or IsLayoutActive) then
      MLookDrawHD(MWndPos)
    else
      MLookDraw;

  MouseLookHook3Std(nil, nil, this);
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

//----- Compatible movie render

var
  ScreenDraw: TBitmap; ScreenDrawScanline: ptr;

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
  r, r0: TRect;
  dc: HDC;
begin
  GetClientRect(_MainWindow^, r);
  r0:= r;
  if IsLayoutActive then
    Wnd_CalcClientRect(r);
  NeedScreenDraw(scale, sw, sh, RectW(r), RectH(r));
  RSResample16(scale, scan, pitch, ScreenDrawScanline, scale.DestW*4);
  dc:= GetDC(_MainWindow^);
  if (scale.DestW = RectW(r)) and (scale.DestH = RectH(r)) then
    BitBlt(dc, r.Left, r.Top, scale.DestW, scale.DestH, ScreenDraw.Canvas.Handle, 0, 0, cmSrcCopy)
  else
    StretchBlt(dc, r.Left, r.Top, RectW(r), RectH(r), ScreenDraw.Canvas.Handle, 0, 0, scale.DestW, scale.DestH, cmSrcCopy);
  FillRect(dc, Rect(r0.Left, r0.Top, r0.Right, r.Top), GetStockObject(BLACK_BRUSH));
  FillRect(dc, Rect(r0.Left, r.Top, r.Left, r.Bottom), GetStockObject(BLACK_BRUSH));
  FillRect(dc, Rect(r.Right, r.Top, r0.Right, r.Bottom), GetStockObject(BLACK_BRUSH));
  FillRect(dc, Rect(r0.Left, r.Bottom, r0.Right, r0.Bottom), GetStockObject(BLACK_BRUSH));
  ReleaseDC(_MainWindow^, dc);
end;

//----- Fix LoadBitmapInPlace

procedure FixLoadBitmapInPlace;
asm
  mov eax, [esi + $14]
  mov [esp + 4], eax
end;

//----- UI Layout

function IsLayoutActive(CanActivate: Boolean = true): Boolean; inline;
begin
{$IFDEF MM6}
  Result:= false;
{$ELSE}
  Result:= Layout.Active(CanActivate);
{$ENDIF}
end;

function TransformMouseCoord(x, sw, w: int; out dx: Double): int;
begin
  Result:= (x*2 + 1)*sw div (w*2);
  dx:= (x + 0.5)*sw/w - (Result + 0.5);
end;

function TransformMousePos(x, y: int; out x1: int): int;
var
  r: TRect;
begin
  GetClientRect(_MainWindow^, r);
  if not IsLayoutActive(false) then
  begin
    NeedScreenWH;
    x1:= TransformMouseCoord(x, SW, r.Right, Options.MouseDX);
    Result:= TransformMouseCoord(y, SH, r.Bottom, Options.MouseDY);
  end else
{$IFNDEF MM6}
    Layout.MapMouse(x1, Result, x, y, r.Right, r.Bottom);
{$ENDIF}
end;

//----- Paper doll in chests and support evt.Question in houses

function IsChestDollVisible: Boolean; inline;
begin
  Result:= (_CurrentScreen^ = 15) and (Options.PaperDollInChests > 0)
     or (_CurrentScreen^ = 10) and (Options.PaperDollInChests = 2);
end;

{$IFDEF MM7}
type
  TBoolFunction = function: Bool;
var
  HadRightSideBefore: Boolean;

function ScreenHasRightSideHook(f: TBoolFunction): Bool;
begin
  Result:= f or IsChestDollVisible;
  if _CurrentScreen^ = 19 then
    Result:= HadRightSideBefore;
  if IsLayoutActive and not Layout.Updating then
    Result:= Layout.ScreenHasRightSide;
  HadRightSideBefore:= Result;
end;
{$ENDIF}

//----- Paper doll in chests

var
  LastMouseItem: int;

{$IFNDEF MM8}
procedure PaperDollInChestCreateButtons;
begin
  _InventoryShowRingsButton^:= _AddButton(_ChestDlg^, 600, 300, 30, 30, 1, 0, 85, 0, 0, _ShowRingsHint^, nil);
  _InventoryPaperDollButton^:= _AddButton(_ChestDlg^, 476, 0, 164, 345, 1, 0, 133, 0, 0, _NoHint, nil);
end;

procedure PaperDollInChestsUpdate;
begin
  if IsChestDollVisible then
  begin
    if (_InventoryShowRingsButton^.Action = 0) or (_ItemInMouse^ <> LastMouseItem) then
    begin
      LastMouseItem:= _ItemInMouse^;
      _LoadPaperDollGraphics;
    end;
    if _InventoryShowRingsButton^.Action = 0 then
    begin
      _DeleteButton(0,0, _InventoryShowRingsButton^);
      _DeleteButton(0,0, _InventoryPaperDollButton^);
      PaperDollInChestCreateButtons;
    end;
  end
  else if (_CurrentScreen^ = 10) and (_InventoryShowRingsButton^.Action <> 0) then
  begin
    _InventoryShowRingsButton^.Action:= 0;
    _InventoryPaperDollButton^.Action:= 0;
    _InventoryRingsShown^:= false;
  end;
end;

procedure PaperDollInChestsInit;
begin
  LastMouseItem:= _ItemInMouse^;
  _LoadPaperDollGraphics;
  PaperDollInChestCreateButtons;
  _InventoryRingsShown^:= false;
  if Options.PaperDollInChests = 2 then
    _CurrentCharScreen^:= 103
  else
    PaperDollInChestsUpdate;
end;

procedure PaperDollInChestsDraw;
asm
{$IFDEF MM6}
  cmp dword ptr [CurrentScreen], 10
  jz @mine
  cmp dword ptr [CurrentScreen], 15
  jz @mine
  ret
@mine:
{$ENDIF}
  cmp dword ptr [RingsShown], 0
  mov eax, m6*$412370 + m7*$43CC9F
  jz @norings
  mov eax, m6*$412DB0 + m7*$43E848
@norings:
  mov ecx, [CurrentMember]
  test ecx, ecx
  jnz @ok
  inc ecx
  mov [CurrentMember], ecx
@ok:
  call eax
end;

procedure PaperDollInChestsRightClick6;
asm
  cmp dword ptr [$6A6120], 467
  jng @ok
  mov [esp], $411702
@ok:
end;

procedure PaperDollInChestsRightClick7;
asm
  cmp dword ptr [ebp-8], 467
  jng @ok
  mov [esp], $41752B
@ok:
end;

procedure PaperDollInChestsHook7b;
asm
  cmp dword ptr [RingsShown], 0
  jz @ok
  cmp dword ptr [esp+$5f8+4-$5e4], 1  // button press by mouse
  jnz @ok
  cmp dword ptr [CurrentScreen], 10
  jz @mine
  cmp dword ptr [CurrentScreen], 15
  jnz @ok
@mine:
  mov [esp], $434A38
@ok:
end;

procedure PaperDollInChestsHook7c;
asm
  mov [esp+4], 1
end;

{$ELSE}

const
  ChestBtnPosMine: TPoint = (X: 516; Y: 431);
  ChestBtnStdX = 514;
  ChestBtnStdY = 310;

var
  LastChestMember: int;
  ChestBtnPos: PPoint;
  ChestBtn: ptr;

procedure PaperDollInChestsInit(btn: PChar);
const
  GetRect: procedure(_,__:int; this: ptr; var r: TRect) = ptr($4C25D7);
begin
  LastChestMember:= -1;
  _InventoryRingsShown^:= false;
  if Options.PaperDollInChests = 2 then
    _CurrentCharScreen^:= 103;
  ChestBtn:= btn;
  ChestBtnPos:= ptr(btn + $AC);
end;

procedure PaperDollInChestsInitHook;
asm
  mov eax, edi
  call PaperDollInChestsInit
end;

procedure PaperDollInChestsDrawExit;
type
  TDrawProc = function(_,_2: int; this: ptr): int;
begin
  if (_CurrentScreen^ = 15) or (_CurrentScreen^ = 10) and (Options.PaperDollInChests = 2) then
    TDrawProc(pptr(ppchar(ChestBtn)^+8)^)(0,0, ChestBtn);
end;

procedure DrawPaperDollStuff;
const
  x = 466;
  x0 = 7;
  y = 23;
  h = 367 - y;
var
  p: PWordArray;
begin
  NeedScreenWH;
  p:= _ScreenBuffer^;
  if _CurrentScreen^ <> 15 then
    Draw16(@p[y*SW], @p[x - x0 + y*SW], SW*2, SW*2, x0 + 1, h, 0, ldkOpaque);
  with _IconsLodLoaded.Items[_LPicTopbar^] do
    Draw8(@Image[x], @p[x], Rec.w, SW*2, Rec.w - x, Rec.h, Palette16);
  ChestBtnPos^:= ChestBtnPosMine;
end;

procedure UpdatePaperDoll(_,__, pl: int);
begin
  if (pl = LastChestMember) and (_ItemInMouse^ = LastMouseItem) then  exit;
  _LoadPaperDollGraphics(0, 0, pl);
  LastMouseItem:= _ItemInMouse^;
  LastChestMember:= pl;
end;

procedure PaperDollInChestsDraw;
const
  Screen = $EC1980;
  Begin2D: int = $4A2FF2;
  End2D: int = $4A30A4;
asm
  cmp dword ptr [CurrentScreen], 15
  jz @draw
  cmp Options.PaperDollInChests, 2
  jz @draw
  mov [RingsShown], 0
  mov eax, ChestBtnPos
  mov dword ptr [eax], ChestBtnStdX
  mov dword ptr [eax + 4], ChestBtnStdY
  ret
@draw:
  mov ecx, [CurrentMember]
  dec ecx
  jge @ok
  inc ecx
  mov [CurrentMember], 1
@ok:
  mov ecx, [$B7CA4C + ecx*4]
  push ecx
  call UpdatePaperDoll
  mov ecx, Screen
  call Begin2D            // begin 2d
  pop ecx

  cmp dword ptr [RingsShown], 0
  mov eax, $43A363
  jz @norings
  mov eax, $43BB1A
@norings:
  push dword ptr [$F01A64]
  mov dword ptr [$F01A64], 1
  call eax                // paper doll
  pop dword ptr [$F01A64]
  mov eax, ebx
  call DrawPaperDollStuff // other stuff
  mov ecx, Screen
  call End2D              // end 2d
// std:
  mov ecx, ebx
end;

procedure PaperDollInChestsRightClick;
asm
  cmp dword ptr [CurrentScreen], 15
  jnz @ok
  mov [esp], $416CFA
@ok:
end;

procedure PaperDollInChestsRightClick2;
const
  x = -8;
  y = -4;
asm
  cmp [ebp + x], 467
  jl @std
  cmp [ebp + y], 367
  jg @std
  mov [esp], $416CFA
@std:
end;

const
  ItemPaperDoll: array[0..9] of int = (0,0,0,0,0,0,0,0, 133, 0);
  ItemViewRings: array[0..9] of int = (0,0,0,0,0,0,0,0, 85, 0);

procedure PaperDollInChestsClick; // hack instead of adding real dialog elements
asm
  cmp dword ptr [CurrentScreen], 15
  jz @chest
  cmp dword ptr [CurrentScreen], 10
  jnz @std
  cmp Options.PaperDollInChests, 2
  jnz @std
@chest:
  mov eax, [ebp - 8]  // x
  mov edx, [ebp - 4]  // y
  cmp eax, 467
  jl @std
  cmp edx, 23
  jl @std
  cmp edx, 367
  jg @std
  lea esi, ItemPaperDoll
  cmp eax, 606
  jl @add
  cmp eax, 636
  jg @add
  cmp edx, 299
  jl @add
  cmp edx, 330
  jg @add
  lea esi, ItemViewRings
@add:
  mov [esp], $416E93
@std:
end;
{$ENDIF}

//----- Enter key in load/save dialogs

procedure LoadSaveEnter;
asm
  mov byte ptr [esp + 8], 13
end;

procedure LoadSaveEnter8;
asm
  mov dword ptr [esi + $14], $10D
end;

//----- Control certain dialogs with keyboard

var
  KeyControlMouseBlocked, KeyControlMouseBlockScreen: int;

procedure KeyControlMouse;
asm
  cmp KeyControlMouseBlocked, esi
  mov KeyControlMouseBlocked, 0
  jnz @ok
  mov KeyControlMouseBlocked, esi
{$IFDEF mm6}
  sub edx, $22
{$ENDIF}
@ok:
  cmp KeyControlMouseBlocked, 0
end;

procedure KeyControlCancel;
asm
{$IFDEF mm6}
  mov edx, 0
{$ELSEIF defined(mm7)}
  mov ecx, 0
{$ELSE}
  mov eax, 0
{$IFEND}
  mov KeyControlMouseBlocked, 0
  cmp KeyControlMouseBlocked, 0
end;

procedure KeyControlEnter;
asm
  // check zero height items?
  mov byte ptr [NeedRedraw], 1
  mov [esp], m6*$419F47 + m7*$41D015 + m8*$41C40F
end;

procedure KeyControl;
asm
{$IFDEF mm6}
  cmp edx, $22
{$ENDIF}
  jz KeyControlMouse

  // bugfix: messing with evt.Question
  cmp dword ptr [esi + m6*$4D48F8 + m7*$506DD0 + $30], 0
  jz @ok
  push eax
  mov eax, [m6*$4D46BC + m7*$5074B0 + m8*$518CE8]
{$IFDEF mm6}
  cmp eax, [esp + $20 + 8]
{$ELSE}
  cmp eax, [ebp - $10]
{$ENDIF}
  pop eax
  jnz KeyControlCancel
@ok:

{$IFDEF mm6}
  cmp edx, VK_RETURN
{$ELSEIF defined(mm7)}
  cmp ecx, VK_RETURN - $22
{$ELSE}
  cmp eax, VK_RETURN - $22
{$IFEND}
  jz KeyControlEnter

  push eax
  mov eax, [CurrentScreen]
  mov KeyControlMouseBlockScreen, eax
  pop eax
  mov KeyControlMouseBlocked, esi
  cmp KeyControlMouseBlocked, 0
end;

procedure KeyControlCheckUnblock;
asm
  mov eax, [CurrentScreen]
  cmp KeyControlMouseBlockScreen, eax
  jnz @release
  mov eax, [esp + 4 + 8]
  cmp eax, WM_MOUSEFIRST
  jl @ok
  cmp eax, WM_MOUSELAST
  jg @ok
@release:
  mov KeyControlMouseBlocked, 0
@ok:
end;

//----- Allow right click in item spell dialogs

procedure EnchantItemRightClick;
asm
  cmp eax, 23 + m6*80
  jnz @ok
  mov [esp], m6*$4116F1 + m8*$416AB3
@ok:
end;

//----- Place items in chests vertically

procedure ChestVerticalHook;
const
  slot = -4;
  w = -$10*m7 -$18*m8;
asm
  mov eax, [ebp + w]
  add [ebp + slot], eax
  cmp [ebp + slot], esi
  jl @exit
  sub [ebp + slot], esi
  inc dword ptr [ebp + slot]
  cmp [ebp + slot], eax
  jl @exit
  mov [ebp + slot], esi
@exit:
end;

procedure ChestVerticalHook6;
asm
  jz @next
  mov [esp], $41E09B
  ret
@next:
  mov eax, [esp + $28 - $10]
  add esi, eax
  cmp esi, edi
  jl @exit
  sub esi, edi
  inc esi
  cmp esi, eax
  jl @exit
  mov esi, edi
@exit:
end;

//----- Fix GM Axe

{$IFNDEF MM6}
procedure ShowArmorHalved;
asm
  mov ecx, SArmorHalved
  push $41EC62
end;

function FixGMAxeProc1(pl: PChar): int;
var
  sk: int;
begin
  Result:= 0;
  sk:= _Character_GetSkillWithBonuses(0,0, pl, 3);
  if (sk and $100 <> 0) and (Random(Options.AxeGMFullProbabilityAt) < sk and $3F) then
    Result:= 2;
end;

{$IFDEF MM7}
procedure FixGMAxeHook1;
asm
  cmp [ebp - $2C], 3
  jnz @std
  push eax
  mov eax, edi
  call FixGMAxeProc1
  mov [ebp - $34], eax
  pop eax
@std:
end;
{$ELSE}
procedure FixGMAxeHook1;
asm
  cmp ebx, 3
  jnz @std
  push eax
  mov eax, [ebp - 8]
  call FixGMAxeProc1
  mov [ebp - $38], eax
  pop eax
@std:
end;
{$ENDIF}

procedure FixGMAxeProc2(pl, mon: PChar);
var
  sk: int;
begin
  sk:= _Character_GetSkillWithBonuses(0,0, pl, 3);
  SetSpellBuff(mon + m7*340 + m8*556, _Time^ + (sk and $3F)*256, 4, 0,0,0);
end;

var
  ParalyzedStr: ptr;

procedure FixGMAxeHook2;
const
  effect = -$34*m7 -$38*m8;
asm
  cmp [ebp + effect], 2
  jnz @std
  mov edx, SArmorHalvedMessage
  mov ParalyzedStr, edx
  mov [esp+8], 4  // physical
  pop edx
  call eax  // Monster_CalcEffectResistance
  test eax, eax
  jz @resist
{$IFDEF MM7}
  mov eax, edi
{$ELSE}
  mov eax, [ebp - 8]
{$ENDIF}
  mov edx, esi
  push m7*$439D33 + m8*$4377F2
  jmp FixGMAxeProc2
@resist:
  push m7*$439D6E + m8*$437825
  ret
@std:
  mov edx, [m7*$5E49F0 + m8*$601E38]
  mov ParalyzedStr, edx
  jmp eax
end;
{$ENDIF}

//----- Fix chests by compacting

function GetChestItemMask(p: pchar): string;
var
  i: int;
begin
  SetLength(Result, 140);
  FillChar(Result[1], 140, 1);
  inc(p, _ChestOff_Inventory);
  for i:= 0 to 139 do
    if pint2(p + i*2)^ > 0 then
      Result[pint2(p + i*2)^]:= #2;
end;

procedure ChestPlaceItem(p: pchar; index: int);
var
  chest, x, y, w, h, kind: int;
begin
  kind:= pint(p + _ChestOff_Items + _ItemOff_Size*index)^;
  if kind = 0 then  exit;
  chest:= int(p - _Chests) div _ChestOff_Size;
  w:= pint(_ChestWidth + 4*pword(p)^)^;
  h:= pint(_ChestHeight + 4*pword(p)^)^;
  inc(p, _ChestOff_Inventory);
  for y:= 0 to h - 1 do
    for x:= 0 to w - 1 do
      if (pint2(p + (y*w + x)*2)^ = 0) and _Chest_CanPlaceItem(0, kind, y*w + x, chest) then
      begin
        _Chest_PlaceItem(0, index, y*w + x, chest);
        exit;
      end;
end;

procedure FixChestsCompactProc(p: pchar);
var
  buf: array[1..140] of int2;
  s: string;
  i: int;
begin
  s:= GetChestItemMask(p);
  CopyMemory(@buf, p + _ChestOff_Inventory, 280);
  ZeroMemory(p + _ChestOff_Inventory, 280);
  for i:= 0 to 139 do
    ChestPlaceItem(p, i);
  if GetChestItemMask(p) > s then  exit;  // compact is better
  CopyMemory(p + _ChestOff_Inventory, @buf, 280);
end;

procedure FixChestsCompact;
asm
  push eax
  add eax, m6*(_Chests + 2) - 2
  call FixChestsCompactProc
  pop eax
end;

//----- Sprite angle compensation

type
  TSpriteDrawParams = packed record
    ScreenBuf, ObjectRefBuf: ptr;
    X, Y: int;
    ScaleX{$IFNDEF MM6}, ScaleY{$ENDIF}: int;
    _1,_2,_3,_4: int;
    ObjKind: int2;
    ZBuf: int2;
    // ...
  end;

{$IFNDEF MM6}
function FindSprite(Name: PChar): PSprite; overload;
var
  i: int;
begin
  i:= _SpritesLodCount^;
  Result:= @Sprites;
  while (i > 0) and (_strcmpi(@Result.Name, Name) <> 0) do
  begin
    inc(Result);
    dec(i);
  end;
  if i = 0 then
    Result:= nil;
end;

function FindSprite(var sp3d: TSpriteD3D): PSprite; overload;
var
  index: puint2;
begin
  index:= ptr(sp3d.Name + 18);  // there's 20 bytes allocated, so at the end is some unused space
  if (index^ > 0) and (index^ <= _SpritesLodCount^) then
  begin
    Result:= @Sprites[index^ - 1];
    exit;
  end;
  Result:= FindSprite(sp3d.Name);
  if Result <> nil then
    index^:= (PChar(Result) - @Sprites) div SizeOf(Result^) + 1;
end;

{
3D transform sprite rect (if it was an option):
y = y0 / L0    // height
x = x0 / L0    // X coordinate of either of top vertexes
y' = y*cos(a)
dL = y0*sin(a) = y*L0*sin(a)
x' = x0 / (L0 + dL) = x / (1 + y*sin(a))

In reality I just had to use a ton of hacks.
}

procedure SpritesAngleProc(spi: int2; var params: TSpriteDrawParams);
const
  Dist = 5000;  // don't straighten objects in the distance
  HLim = 500;  // don't straighten trees
var
  sprite: PSprite;
  mul, si, co, h: ext;
  n: int;
begin
  SinCos(_Party_Angle^*Pi/1024/3, si, co); // use 1/3 of the angle
  n:= 0;
  if _IsD3D^ then
    sprite:= FindSprite(_SpritesD3D^[spi])
  else
    sprite:= @Sprites[spi];
  with sprite^ do
  begin
    while (n < h) and ((Lines[n].a1 < 0) or (Lines[n].a1 > Lines[n].a2)) do
      inc(n);
    mul:= (h - n)*params.ScaleY/$10000/GetViewMul;
  end;
  h:= mul*params.ZBuf;
  if si < 0 then  // look down
    mul:= min(mul, 1)*0.75*EnsureRange(2 - params.ZBuf/Dist*2, 0, 1)*EnsureRange(2 - h/HLim*2, 0, 1)
  else
    mul:= min(mul - 1, 5)*0.35;
  mul:= 1/EnsureRange(1 + mul*si, 0.73, 2);
  with params do
  begin
    ScaleX:= Round(ScaleX*mul);
    if mul > 1 then  // look down
      ScaleY:= Round(ScaleY*min(1, co + (mul - 1))*mul)
    else
      ScaleY:= Round(ScaleY*min(co, mul));
  end;
end;

procedure SpritesAngleHook;
asm
  push eax
  push edx
  push ecx
  mov ax, di
  lea edx, [ebp - $60]
  call SpritesAngleProc
  pop ecx
  pop edx
  pop eax
end;

procedure SpritesAngleHook2;
asm
  push eax
  push edx
  push ecx
  lea edx, [ebp - $50]
  call SpritesAngleProc
  pop ecx
  pop edx
  pop eax
end;
{$ENDIF}

procedure SpritesAngleProc6(sprite: PSprite; var params: TSpriteDrawParams);
const
  Dist = 5000;
var
  mul, si, co: ext;
  n: int;
begin
  SinCos(_Party_Angle^*Pi/1024*0.4, si, co); // use 0.4 of the angle
  n:= 0;
  with sprite^ do
  begin
    while (n < h) and ((Lines[n].a1 < 0) or (Lines[n].a1 > Lines[n].a2)) do
      inc(n);
    mul:= (h - n)*params.ScaleX/$10000/GetViewMul;
  end;
  if si < 0 then  // look down
    mul:= min(mul, 1)*0.75*EnsureRange(2 - params.ZBuf/Dist*2, 0, 1)
  else
    mul:= min(mul - 1, 5)*0.35;
  mul:= 1/EnsureRange(1 + mul*si, 0.73, 2);
  with params do
    ScaleX:= Round(ScaleX*mul);
end;

procedure SpritesAngleHook6;
asm
  mov edx, [esp + 4]
  push eax
  push ecx
  mov eax, ecx
  call SpritesAngleProc6
  pop ecx
end;

//----- Save game bug in Windows Vista and higher (bug of OS or other software)

procedure SaveGameBugHook(old, new: PChar); cdecl;
var
  i: int;
begin
  for i:= 1 to 2000 do
  begin
    if MoveFile(old, new) then
      exit;
    Sleep(1);
    DeleteFileA(new);
  end;
  if not FileExists(new) then
  begin
    RSMessageBox(_MainWindow^, Format('Failed to rename %s. Check file permisions. Game wasn''t saved.', [old]), 'Saving Error');
    exit;
  end;
  // failed to delete - rename it
  for i:= 0 to 999999 do
    if MoveFile(new, pchar(ChangeFileExt(new, Format('.%.3d', [i])))) or not FileExists(Format('.%.3d', [i])) then
    begin
      RSMessageBox(_MainWindow^,
         Format('Failed to delete %s. Check file permisions. %s',
            [new, IfThen(MoveFile(old, new), 'Game was saved, but temporary file is left in Saves folder.',
             'Game may have been saved to Data\new.lod.')]),
         'Saving Error');
      exit;
    end;
end;

//----- Click through effects SW

function IsEffectSprite(i: int): Boolean;
const
  MapItems_TypeIndex = m6*$5C9AD8 + m7*$6650B0 + m8*$692FB8 + 2;
  MapItems_Sz = 112 - m6*12;
  ObjList = pint(m6*$5F6DF4 + m7*$680634 + m8*$6AE53C);
  ObjList_Bits = $26;
  ObjList_Sz = 56 - m6*4;
begin
  Result:= false;
  if i and 7 <> 2 then  exit;
  i:= i shr 3;
  i:= pint2(MapItems_TypeIndex + i*MapItems_Sz)^;
  i:= pbyte(ObjList^ + i*ObjList_Sz + ObjList_Bits)^;
  Result:= (i and $10) <> 0; // non-interactable object
end;

var
  ObjectByPixelBackup: array of int;
  WasSpriteIndex: array of int2;

procedure DrawEffectsHook(draw: TProcedure);
var
  i: int;
begin
  NeedScreenWH;
  while length(WasSpriteIndex) < _SpritesToDrawCount^ do
    SetLength(WasSpriteIndex, max(length(WasSpriteIndex)*2, 500));
  // disable effects sprites
  for i:= 0 to _SpritesToDrawCount^ - 1 do
    with _SpritesToDraw^^[i] do
    begin
      WasSpriteIndex[i]:= SpriteIndex;
      if (SpriteIndex >= 0) and IsEffectSprite(ObjKind) then
        SpriteIndex:= -1;
    end;
  draw;
  // backup ObjectByPixel without effects
  SetLength(ObjectByPixelBackup, SW*SH);
  Move(_ObjectByPixel^^[0], ObjectByPixelBackup[0], length(ObjectByPixelBackup)*4);
  // enable effects sprites, disable other sprites
  for i:= 0 to _SpritesToDrawCount^ - 1 do
    with _SpritesToDraw^^[i] do
      if WasSpriteIndex[i] >= 0 then
        if SpriteIndex < 0 then
          SpriteIndex:= WasSpriteIndex[i]
        else
          SpriteIndex:= -1;
  draw;
  // enable all sprites
  for i:= 0 to _SpritesToDrawCount^ - 1 do
    with _SpritesToDraw^^[i] do
      SpriteIndex:= WasSpriteIndex[i];
end;

procedure DrawDoneHook;
begin
  // restore ObjectByPixel without effects
  Move(ObjectByPixelBackup[0], _ObjectByPixel^[0], length(ObjectByPixelBackup)*4);
end;

//----- Proper D3DRend->Init error messages

procedure D3DErrorMessageHook;
asm
  mov eax, [esi + $40088]
  add eax, $48
  mov [esp + 4], eax
end;

//----- Allow entering maps from NPC dialog

procedure CloseNPCDialog;
var
  last: int;
begin
  while _CurrentScreen^ in [4, 13] do
  begin
    AddAction(113, 0, 0);
    last:= _SoundVolume^;
    _SoundVolume^:= 0;
    _ProcessActions;
    _SoundVolume^:= last;
  end;
end;

procedure CloseNPCDialog2;
begin
  if (_CurrentScreen^ <> 4) and (m6 = 0) or (_CurrentScreen^ <> 13) then  exit;
  CloseNPCDialog;
  _NeedRedraw^:= 0;
end;

procedure CloseNPCDialog6;
asm
  pushad
  call CloseNPCDialog
  popad
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
{$IFDEF mm6}
  add eax, 4
{$ELSEIF defined(MM7)}
  mov eax, ebx
{$ELSE}
  mov eax, edi
{$IFEND}
  call FixChestSmartProc
end;

//----- Fix buffs - prefer new ones if they're longer OR stronger

procedure FixCompareBuff;
asm
  jz @std
  push eax
{$IFDEF mm6}
  mov ax, [esp + 8+8 + $10]
{$ELSE}
  mov ax, [ebp + $14]
{$ENDIF}
  cmp ax, [esi + 8]
  pop eax
  jng @skip
  mov [esp], m6*$44A998 + m7*$45853F + m8*$455DBD
@skip:
  test esi, esi
@std:
end;

//----- Fix crash due to a facet with no vertexes

procedure FixZeroVertexFacet1;
asm
  mov al, [ebx + $5D]
  test al, al
  jnz @std
  mov [esp], m7*$4243CF + m8*$42283D
@std:
end;

//----- Allow running without HWLs

procedure FixNoHWL;
asm
  cmp [esi], 0
  jnz @ok
  mov [esp], m7*$452763 + m8*$44FF98
@ok:
end;

//----- Fix conditions priorities

procedure DoFixConditionPriorities;
const
  Cursed      = 0;
  Weak        = 1;
  Asleep      = 2;
  Afraid      = 3;
  Drunk       = 4;
  Insane      = 5;
  Poison1     = 6;
  Disease1    = 7;
  Poison2     = 8;
  Disease2    = 9;
  Poison3     = 10;
  Disease3    = 11;
  Paralyzed   = 12;
  Unconscious = 13;
  Dead        = 14;
  Stoned      = 15;
  Eradicated  = 16;
  Zombie      = 17;
  CondOrder: array[0..17] of int = (Eradicated, Dead, Stoned, Unconscious,
     Paralyzed, Asleep, Weak, Cursed, Disease3, Poison3, Disease2, Poison2,
     Disease1, Poison1, Insane, Drunk, Afraid, Zombie);
begin
  CopyMemory(ptr(m6*$4C276C + m7*$4EDDA0 + m8*$4FDFA8), @CondOrder, SizeOf(CondOrder) - m6*4);
end;

//----- Fix element hints staying active in some dialogs

var
  HintDelay: int;

procedure UpdateHintHook(std: TProcedure);
const
  p = PChar(int(_StatusText) + 200);
  MouseXY = PPoint($1006138);
  MDlgCount = pint($1006148+88);
var
  ok: Boolean;
  old: char;
  oldN: int;
begin
  if m8 = 0 then
    ok:= (_DialogsHigh^ > 0) and (_CurrentScreen^ <> 0)
  else
    with MouseXY^ do
      ok:= (Y < 389) and ((_CurrentScreen^ in [7,10,15,23]) or (_CurrentScreen^ = 29) and (MDlgCount^ = 2));
  if ok then
  begin
    old:= p^;
    oldN:= _ActionQueue^.Count;
    if old <> #0 then
      p^:= #1;
    std;
    if (p^ <> #1) or (_ActionQueue^.Count - oldN > 0) and (_ActionQueue^.Items[oldN].Action <> 122) then
      HintDelay:= HintStayTime + 1;
    if (HintDelay = 0) and (old <> #0) then
    begin
      if m6 = 1 then
        _SetHint(0,0,' ')
      else
        _NeedUpdateStatus^:= true;
      p^:= #0;
    end;
    if HintDelay > 0 then
      dec(HintDelay);
    if p^ = #1 then
      p^:= old;
  end else
    std;
end;

//----- Restore AnimatedTFT bit from Blv rather than Dlv to avoid crash

procedure FixReadFacetBit;
asm
	mov edx, [esp+4]
	mov edx, [edx]
	mov ecx, [eax]
	and cx, $4000
	and dx, $FFFF - $4000
	or dx, cx
	mov [eax], edx
end;

//----- Fix monsters blocking shots of other monsters

procedure FixMonsterBlockShots;
const
  Mon_IsAgainstMon: int = m7*$40104C + m8*$401051;
asm
  mov ecx, [ebp - $10]
  sub ecx, m7*$86 + m8*$8E
  lea edx, [_MapMonsters + eax]
  call Mon_IsAgainstMon
  test eax, eax
  push m7*$471724 + m8*$470282
end;

//----- Fix item spells when cast onto item with index 0

procedure FixItemSpells;
asm
{$IFDEF mm6}
  jnz @std
  cmp word ptr [ebx], 29  // Enchant Item
  jnz @std
{$ELSE}
	jz @std
	cmp ax, 4   // Fire Aura
	jz @mine
	cmp ax, 28  // Recharge Item
	jz @mine
	cmp ax, 30  // Enchant Item
	jz @mine
	cmp ax, 91  // Vampiric Weapon
	jz @mine
	jmp @std
{$ENDIF}
@mine:
	xor eax, eax
	mov [esp], m6*$42274F + m7*$427ED4 + m8*$42610B
@std:
end;

//----- Fix deliberately generated artifacts not marked as found
// In MM6 this routine ignores ArtifactsFound completely.

procedure FixUnmarkedArtifacts;
asm
  mov byte ptr [$ACD3FE + eax], 1
end;

//----- Fix item picture change causing inventory corruption

procedure RemoveInvItem(a: PIntegerArray; slot: int);
var
  i: int;
begin
  a[0]:= 0;
  a:= @a[-slot];
  slot:= -1 - slot;
  for i := 0 to 137 do
    if a[i] = slot then
      a[i]:= 0;
end;

var
  LastRemovedItem: int;

procedure FixRemoveInvItemPlayer;
asm
  // item number: ecx (mm6), esi (7-8)
  {$IFDEF mm6}mov LastRemovedItem, ecx{$ENDIF}
  {$IFDEF mm6}mov edx, ebx{$ELSE}mov edx, [esp + $14]{$ENDIF}
  mov eax, edi
  call RemoveInvItem
  push m6*$48755E + m7*$492AC6 + m8*$4913D7
  ret 4*m6
end;

procedure RemoveInvItemChest(a: PInt2Array; slot: int);
var
  i: int;
begin
  a[slot]:= 0;
  slot:= -1 - slot;
  for i := 0 to 137 do
    if a[i] = slot then
      a[i]:= 0;
end;

procedure FixRemoveInvItemChest;
asm
  add eax, _Chests + _ChestOff_Inventory
  {$IFDEF mm6}mov edx, [esp + $20 - 8]{$ENDIF}
  {$IFDEF mm7}mov edx, [ebp - $C]{$ENDIF}
  call RemoveInvItemChest
  push m6*$41EDB5 + m7*$420BA2 + m8*$420125
  ret 4*m6
end;

//----- Loot stolen items from thief's corpse

procedure FixMonStealCheck;
asm
  // only steal unenchanted items
  lea eax, [esi+ebx*4+128h]
  cmp dword ptr [eax + _ItemOff_Bonus], 0
  jnz @skip
  cmp dword ptr [eax + _ItemOff_Bonus2], 0
  jnz @skip
  test [eax + _ItemOff_Condition], (_ItemCond_Broken + _ItemCond_Stolen + _ItemCond_Hardened)
  jnz @skip
  mov eax, [eax + _ItemOff_Number]
  ret
@skip:
  xor eax, eax
end;

procedure FixMonSteal;
asm
  cmp [esp + 4], 20
  jz @steal
  jmp eax
@steal:
  cmp word ptr [edi + _MonOff_Item], 0
  jz @DoSteal
  ret 4
@DoSteal:
  mov LastRemovedItem, 0
  push [esp + 4]
  call eax
  mov eax, LastRemovedItem
  mov [edi + _MonOff_Item], ax
  ret 4
end;

//----- Don't show stealing animation if nothing's stolen

procedure FixMonStealDisplay;
asm
  cmp eax, 20
  jnz @std
  mov edx, [ebp + $C]
  cmp dword ptr [edx + _MonOff_Item1], 0
  jz @std
  cmp dword ptr [edx + _MonOff_Item2], 0
  jz @std
  mov ecx, -1
@std:
end;

//----- Show that stolen item was found

procedure FixStolenLootHint;
const
  TextBuffer2 = int(_TextBuffer2);
  _sprintf: int = m7*$4CAD70 + m8*$4D9F10;
asm
  push eax  // std function
  cmp dword ptr [ebp - 8], 0  // already found an item
  jnz @skip
  mov eax, [edi]
  // code based on 425108 (mm7)
  lea eax, [eax+eax*2]
  shl eax, 4
  mov edx, [m7*$426C53 + m8*$425118 - 4]
  mov eax, [eax + edx]
  mov edx, [ebp - 4]  // gold
  push eax  // item name
  mov eax, m7*$5E475C + m8*$601BA4
  cmp edx, 0
  jz @nogold
  push edx  // gold
  add eax, $5E47A8 - $5E475C
@nogold:
  push dword ptr [eax]  // format string
  push TextBuffer2
  call _sprintf
  add esp, 0Ch
  cmp dword [ebp - 4], 0
  jz @nogold2
  pop ecx
@nogold2:
  mov edx, 2
  mov ecx, TextBuffer2
  call _ShowStatusText
  mov ecx, esi
@skip:
end;

//----- Draw bitmap as internal minimap background

{var
  MinimapBkgPcx: TLoadedPcx;

procedure MinimapBkgHook(_,__, screen, color, height, width, top, left: int);
begin
  _DrawPcx(0,0, screen, MinimapBkgPcx, top, left);
end;}

var
  MinimapBkgBmp: int;

procedure MinimapBkgHook(_,__, screen, color, height, width, top, left: int);
begin
  _DrawBmpOpaque(0,0, screen, _IconsLodLoaded.Items[MinimapBkgBmp], top, left);
end;
{var
  p: PWordArray;
begin
  NeedScreenWH;
  p:= _ScreenBuffer^;
  with _IconsLodLoaded.Items[MinimapBkgBmp] do
    Draw8t(@Image[0], @p[left + top*SW], Rec.w, SW*2, Rec.w, Rec.h, Palette16);
end;}

//----- Load alignment-dependant interface

procedure InterfaceColorChangedHook;
asm
  push ecx
  push edx
  call InterfaceColorChanged
  pop edx
  pop ecx
end;

//----- Attack spell

const
  ASpellUpX = m6*242 + m7*477;
  ASpellUpY = m6*332 + m7*406;
  ASpellBtnX = m6*ASpellUpX + m7*517;
  ASpellBtnY = m6*ASpellUpY + m7*415;
var
  ASpellIcon: int = -1;
  ASpellIconDn: int = -1;
  ASpellPressed, ASpellHovered: Boolean;
  ASpellIconHover: PBoolean;

procedure DrawSpellBook;
var
  p: PWordArray;
begin
  NeedScreenWH;
  p:= _ScreenBuffer^;
  with _IconsLodLoaded.Items[ASpellIcon] do
    Draw8t(@Image[0], @p[ASpellUpX + ASpellUpY*SW], Rec.w, SW*2, Rec.w, Rec.h, Palette16);
  if (m7 = 1) and ASpellPressed then
    with _IconsLodLoaded.Items[ASpellIconDn] do
      Draw8t(@Image[0], @p[ASpellBtnX + ASpellBtnY*SW], Rec.w, SW*2, Rec.w, Rec.h, Palette16);
  ASpellPressed:= false;
end;

{$IFNDEF mm8}
procedure BuildSpellBook(dlg: ptr);
begin
  with _IconsLodLoaded.Items[ASpellIconDn].Rec do
    _AddButton(dlg, ASpellBtnX, ASpellBtnY, w, h, 1, 78, 88, 2, 0, _NoHint, nil);
end;
{$ELSE}
procedure BuildSpellBook(dlg: ptr);
var
  p: ptr;
begin
  p:= NewButtonMM8(88, 88, 2);
  ASpellIconHover:= ptr(PChar(p) + $13);
  ASpellHovered:= false;
  SetupButtonMM8(p, 0, 330, true, 'STSASu', 'STSASd');
  AddToDlgMM8(dlg, p);
end;
{$ENDIF}

procedure BuildSpellBookHook;
asm
{$IFDEF mm6}
  mov eax, edi
{$ELSE}
  mov eax, esi
{$ENDIF}
  jmp BuildSpellBook
end;

procedure FetchSpellSound(sp: int);
const
  base = m6*$939CA0 + m7*$A95F00 + m8*$ADEF80;
  f: procedure(_,__,this, pl, spell: int) = ptr(m6*$488BF0 + m7*$49482E + m8*$492B52);
var
  i: int;
begin
  i:= _CurrentMember^;
  f(0,0, base + $AFD8*i, i, sp);
end;

function GetSpName(sp: int): PChar;
begin
  if sp = 0 then
    Result:= _GlobalTxt[153]
  else
    Result:= pptr(m6*$56ABD0 + m7*$5CBEB0 + m8*$5E8278 + ($24 - m6*8)*sp)^;
end;

procedure ASpellBookAction(hint, cast: Boolean);
const
  aSet = 0;
  aRemove = 1;
  aNoSpell = 2;
var
  off, sp, qsp, code: int;
  pl: PByteArray;
begin
  if (m8 = 0) and not hint then
    PlaySound(75);
  if not (hint or cast) then
    ASpellPressed:= true;
  pl:= GetCurrentPlayer;
  if pl = nil then
    exit;
  off:= _CharOff_AttackQuickSpell;
  if cast then
    off:= _CharOff_QuickSpell;
  sp:= _SpellBookSelectedSpell^;
  if sp <> 0 then
    inc(sp, 11*pl[_CharOff_SpellBookPage]);
  qsp:= pl[off];
  code:= aSet;
  if (sp = 0) or (sp = qsp) then
    if qsp = 0 then
      code:= aNoSpell
    else
      code:= aRemove;
  if hint and cast then
  begin
    _ActionQueue.Items[0].Info1:= code and 1;
    exit;
  end;
  if hint then
    case code of
      aRemove:
        _SetHint(0,0, PChar(Format(SRemoveASpell, [GetSpName(qsp)])));
      aNoSpell:
        _SetHint(0,0, PChar(SChooseASpell));
      else
        if qsp = 0 then
          _SetHint(0,0, PChar(Format(SSetASpell, [GetSpName(sp)])))
        else
          _SetHint(0,0, PChar(Format(SSetASpell2, [GetSpName(qsp), GetSpName(sp)])));
    end
  else
    case code of
      aSet:
      begin
        pl[off]:= sp;
        FetchSpellSound(sp);
        _FaceAnim(0,0, pl, 0, 12);
      end;
      else begin
        pl[off]:= 0;
        PlaySound((1-m8)*203 + m8*136);
      end;
    end;
  _ActionQueue.Items[0].Action:= 0;
end;

//procedure ASpellUse;
//var
//  pl: ptr;
//begin
//  if (m7 = 1) and (pint($6BE244)^ = 1) then
//    exit;
//  if (m8 = 1) and (_ActionQueue.Count > 1) then
//    _ActionQueue.Count:= IfThen(_ActionQueue.Items[0].Info2 <> 0, 2, 1);
//  _ActionQueue.Items[0].Action:= 0;
//  pl:= GetCurrentPlayer;
//  if pl = nil then
//    exit;
//end;

procedure ASpellPopAction;
begin
  with _ActionQueue.Items[0] do
    case Action of
      78, 88: // hint, click
        if (Info1 = 2) or (Info1 = 0) and (m6 = 1) then
          ASpellBookAction(Action = 78, Info1 <> 2);
    end;
end;

var
  TestedASpell: Bool;

procedure AttackKeyHook;
asm
  xor TestedASpell, 1
  jz @std
  // check AttackSpell
  call GetCurrentPlayer
  test eax, eax
  jz @std
{$IFDEF mm6}
  mov esi, eax
  mov eax, 2E8BA2E9h
  mov bl, [esi + _CharOff_AttackQuickSpell]
{$ENDIF}
{$IFDEF mm7}
  mov esi, eax
  mov ebp, 0Bh
  mov bl, [esi + _CharOff_AttackQuickSpell]
{$ENDIF}
{$IFDEF mm8}
  mov edi, eax
  mov bl, [edi + _CharOff_AttackQuickSpell]
{$ENDIF}
  mov [esp], m6*$42B18D + m7*$4300AA + m8*$42E84C
  ret
@std:
  mov TestedASpell, 0
end;

procedure QSpellKeyHook;
asm
  // if it was an AttackSpell, set Info1 to 1
  mov ecx, TestedASpell
{$IFDEF mm6}
  mov [$4D5F50 + edx*4], ecx
{$ELSE}
  mov [m7*$50C870 + m8*$51E338 + eax*4], ecx
{$ENDIF}
  mov TestedASpell, 0
end;

procedure QSpellUseHook;
const
  info = m6*($3E4-$3C8) + m7*($5FC-$5E4) + m8*($6C0-$6A4);
asm
{$IFNDEF mm7}
  mov ecx, eax
{$ENDIF}
  cmp [esp + info], 1
  jnz @std
  movzx ecx, byte ptr [ecx + _CharOff_AttackQuickSpell]
  ret
@std:
  movzx ecx, byte ptr [ecx + _CharOff_QuickSpell]
end;

procedure ASpellHintMM8;
begin
  if ASpellIconHover^ then
    AddAction(78, 2, 0)
  else if ASpellHovered then
  begin
    _StatusText.Text[true][0]:= #0;
    _NeedUpdateStatus^:= true;
  end;
  ASpellHovered:= ASpellIconHover^;
end;

// Quick Spell buttons hints in MM8

//function SpellBookHoverItem(std: ptr; _: int; this: ptr; item: PChar): int;
//type
//  TF = function(_,__: int; this: ptr; item: PChar): int;
//var
//  id: int;
//begin
//  Result:= TF(std)(0,0, this, item);
//  if item = nil then
//  begin
//    _SetHint(0,0,'');
//    _NeedUpdateStatus^:= true;
//    exit;
//  end;
//  id:= pint(item + $C)^;
//  if id = 88 then
//    AddAction(78, pint(item + $CC)^, 0)
//  else if id = 113 then
//    _SetHint(0,0, _GlobalTxt[79]);
//end;

//----- HooksList

var
  HooksCommon: array[1..11] of TRSHookInfo = (
    (p: m6*$453ACE + m7*$463341 + m8*$461316; newp: @UpdateHintHook;
       t: RShtCallStore; Querry: hqFixStayingHints), // Fix element hints staying active in some dialogs
    (p: m6*$4226F8 + m7*$427E71 + m8*$4260A8; newp: @FixItemSpells;
       t: RShtAfter; size: 7 - m6), // Fix item spells when cast onto item with index 0
    (p: m6*$487496 + m7*$492A50 + m8*$49135D; newp: @FixRemoveInvItemPlayer;
       t: RShtJmp; size: 7 - m7*2), // Fix item picture change causing inventory corruption
    (p: m6*$41ECEF + m7*$420AEA + m8*$420078; newp: @FixRemoveInvItemChest;
       t: RShtJmp; size: 7), // Fix item picture change causing inventory corruption
    (p: HookLoadInterface; newp: @LoadInterface; t: RShtBefore),
    (p: m6*$40CF6E + m7*$4118B2 + m8*$4CA92C; newp: @BuildSpellBookHook;
       t: RShtAfter; Querry: hqAttackSpell), // Attack spell
    (p: HookPopAction; newp: @ASpellPopAction; t: RShtBefore; Querry: hqAttackSpell), // Attack spell
    (p: m6*$42B252 + m7*$43019B + m8*$42E928; newp: @AttackKeyHook;
       t: RShtBefore; Querry: hqAttackSpell), // Attack spell
    (p: m6*$42B1FD + m7*$43013D + m8*$42E8D7; newp: @QSpellKeyHook;
       t: RShtCall; size: 7; Querry: hqAttackSpell), // Attack spell
    (p: m6*$42C47C + m7*$433D3A + m8*$431591; newp: @QSpellUseHook;
       t: RShtCall; size: 7 - m6; Querry: hqAttackSpell), // Attack spell
    ()
  );
{$IFDEF MM6}
  Hooks: array[1..43] of TRSHookInfo = (
    (p: $457567; newp: @WindowWidth; newref: true; t: RSht4; Querry: hqWindowSize), // Configure window size
    (p: $45757D; newp: @WindowHeight; newref: true; t: RSht4; Querry: hqWindowSize), // Configure window size
    (p: $454340; newp: @WindowProcHook; t: RShtFunctionStart; size: 8), // Window procedure hook
    (p: $41EA02; newp: @PaperDollInChestsInit; t: RShtAfter; Querry: hqPaperDollInChests), // Full screen chests
    (p: $40FFB5; newp: @PaperDollInChestsDraw; t: RShtBefore; size: 6; Querry: hqPaperDollInChests), // Full screen chests
    (p: HookEachTick; newp: @PaperDollInChestsUpdate; t: RShtBefore; Querry: hqPaperDollInChests), // Full screen chests
    (p: $41000F; old: $4107EA; new: $40FFB5; t: RShtJmp; Querry: hqPaperDollInChests2), // Full screen chests
    (p: $411750; newp: @PaperDollInChestsRightClick6; t: RShtBefore; Querry: hqPaperDollInChests), // Full screen chests
    (p: $44E797; newp: @LoadSaveEnter; t: RShtBefore), // Enter key in load/save dialogs
    (p: $44ED0D; newp: @LoadSaveEnter; t: RShtBefore), // Enter key in load/save dialogs
    (p: $419DBF; newp: @KeyControl; t: RShtBefore; size: 6), // Control certain dialogs with keyboard
    (p: $45472C; size: 6), // Control certain dialogs with keyboard (allow keyboard everywhere)
    (p: HookWindowProc; newp: @KeyControlCheckUnblock; t: RShtBefore), // Control certain dialogs with keyboard
    (p: $40CEB8; old: 11; new: 0; t: RSht1), // Spellbook misbehaves when controlled with keyboard
    (p: $41146D; newp: @EnchantItemRightClick; t: RShtAfter), // Allow right click in item spell dialogs
    (p: $41E092; newp: @ChestVerticalHook6; t: RShtCall; Querry: hqPlaceChestItemsVertically), // Place items in chests vertically
    (p: $41E4D7; newp: @FixChestsCompact; t: RShtAfter; size: 7; Querry: hqFixChestsByCompacting), // Fix chests by compacting
    (p: $46B73E; newp: @SpritesAngleHook6; t: RShtCallStore; Querry: hqSpriteAngleCompensation), // Sprite angle compensation
    (p: $4348BA; newp: @SpritesAngleHook6; t: RShtCallStore; Querry: hqSpriteAngleCompensation), // Sprite angle compensation
    (p: $44417B; old: $7F; new: $7D; t: RSht1; Querry: hqFixSFT), // SFT.bin was animated incorrectly (first frame was longer, last frame was shorter)
    (p: $44D861; newp: @SaveGameBugHook; t: RShtCall), // Save game bug in Windows Vista and higher (bug of OS or other software)
    (p: $434737; old: $4347E0; newp: @DrawEffectsHook; t: RShtCallStore; Querry: hqClickThruEffects), // Click through effects SW (indoor)
    (p: $4371BE; newp: @DrawDoneHook; t: RShtAfter; Querry: hqClickThruEffects), // Click through effects SW (indoor)
    (p: $46A242; old: $46B650; newp: @DrawEffectsHook; t: RShtCallStore; Querry: hqClickThruEffects), // Click through effects SW (outdoor)
    (p: $4371FA; newp: @DrawDoneHook; t: RShtAfter; Querry: hqClickThruEffects), // Click through effects SW (outdoor)
    (p: $435296; newp: @DrawDoneHook; t: RShtAfter; Querry: hqClickThruEffects), // Click through effects SW (outdoor)
    (p: $43E37F; newp: @CloseNPCDialog6; t: RShtBefore; size: 6), // Allow entering maps from NPC dialog
    (p: $43DE74; newp: @CloseNPCDialog2; t: RShtBefore), // Allow entering maps from NPC dialog
    (p: $456347; newp: @FixChestSmartHook; t: RShtCall; size: 8; Querry: 19), // Fix chests: reorder to preserve important items
    (p: $44A97F; newp: @FixCompareBuff; t: RShtAfter; size: 6), // Fix buffs - prefer new ones if they're longer OR stronger
    (p: $45B860; newp: @MouseLookHook; t: RShtJmp; size: 8), // Mouse look
    (p: $4B9168; newp: @MouseLookHook2; t: RSht4), // Mouse look
    (p: $43532D; backup: @@MouseLookHook3Std; newp: @MouseLookHook3; t: RShtCall), // Mouse look
    (p: $44C880; newp: @ClearKeyStatesHook; t: RShtJmp; size: 8), // Clear my keys as well
    (p: $4A7316; old: 5000; newp: @WinScreenDelay; newref: true; t: RSht4), // Control Win screen delay during which all input is ignored
    (p: $411F7D; old: $4CB6B8; new: $4CB2C4; t: RSht4), // In Awards screen Up and Down arrows were switched when pressed
    (p: $411FA4; old: $4CB2C4; new: $4CB6B8; t: RSht4), // In Awards screen Up and Down arrows were switched when pressed
    (p: $41FCC7; old: 30; new: 36; t: RSht1), // Fix ring view magnifying glass click width
    (p: $42CF9C; old: 30; new: 36; t: RSht1), // Fix ring view magnifying glass click width
    (p: $480CE6; newp: @FixMonStealCheck; t: RShtCall; size: 7), // Loot stolen items from thief's corpse
    (p: $431DE7; newp: @FixMonSteal; t: RShtCallStore), // Loot stolen items from thief's corpse
    (p: $40DE33; newp: @DrawSpellBook; t: RShtAfter; Querry: hqAttackSpell), // Attack spell
    ()
  );
{$ELSEIF defined(MM7)}
  Hooks: array[1..76] of TRSHookInfo = (
    (p: $47B84E; old: $4CA62E; newp: @AbsCheckOutdoor; t: RShtCall), // Support any FOV outdoor (monsters)
    (p: $47B296; old: $4CA62E; newp: @AbsCheckOutdoor; t: RShtCall), // Support any FOV outdoor (items)
    (p: $47AD40; old: $4CA62E; newp: @AbsCheckOutdoor; t: RShtCall), // Support any FOV outdoor (sprites)
    (p: $48BAA0; old: $4CA62E; newp: @AbsCheckOutdoor; t: RShtCall), // Support any FOV outdoor (effects)
    (p: $47926B; old: $4CA62E; newp: @AbsCheckOutdoor; t: RShtCall), // Support any FOV outdoor (buildings)
    (p: $43FC31; old: $4CA62E; newp: @AbsCheckIndoor; t: RShtCallStore), // Support any FOV indoors (sprites)
    (p: $43FFFB; old: $4CA62E; newp: @AbsCheckIndoor; t: RShtCallStore), // Support any FOV indoors (monsters)
    (p: $46542F; newp: @NeedWindowSize; t: RShtAfter), // Just before creating the window
    (p: $465531; newp: @WindowWidth; newref: true; t: RSht4; Querry: hqWindowSize), // Configure window size
    (p: $465546; newp: @WindowHeight; newref: true; t: RSht4; Querry: hqWindowSize), // Configure window size
    (p: $463828; newp: @WindowProcHook; t: RShtFunctionStart; size: 6), // Window procedure hook
    (p: $4105F9; newp: @FixLoadBitmapInPlace; t: RShtBefore), // Fix LoadBitmapInPlace
    (p: $441030; newp: @ScreenHasRightSideHook; t: RShtFunctionStart), // Full screen chests and support evt.Question in houses
    (p: $420547; newp: @PaperDollInChestsInit; t: RShtAfter; Querry: hqPaperDollInChests), // Full screen chests
    (p: $41588A; newp: @PaperDollInChestsDraw; t: RShtBefore; Querry: hqPaperDollInChests), // Full screen chests
    (p: HookEachTick; newp: @PaperDollInChestsUpdate; t: RShtBefore; Querry: hqPaperDollInChests), // Full screen chests
    (p: $4158C1; old: $4160A3; new: $41588A; t: RShtJmp; Querry: hqPaperDollInChests2), // Full screen chests
    (p: $417149; newp: @PaperDollInChestsRightClick7; t: RShtBefore; Querry: hqPaperDollInChests2), // Full screen chests
    (p: $4320EC; newp: @PaperDollInChestsHook7b; t: RShtBefore; Querry: hqPaperDollInChestsAndOldCloseRings), // Full screen chests
    (p: $420505; newp: @PaperDollInChestsHook7c; t: RShtBefore; Querry: hqPaperDollInChestsAndOldCloseRings), // Full screen chests
    (p: $45E864; newp: @LoadSaveEnter; t: RShtBefore), // Enter key in load/save dialogs
    (p: $45EDB4; newp: @LoadSaveEnter; t: RShtBefore), // Enter key in load/save dialogs
    (p: $41CD35; newp: @KeyControl; t: RShtAfter; size: 6), // Control certain dialogs with keyboard
    (p: $463E05; size: 6), // Control certain dialogs with keyboard (allow keyboard everywhere)
    (p: HookWindowProc; newp: @KeyControlCheckUnblock; t: RShtBefore), // Control certain dialogs with keyboard
    (p: $4116FF; old: $FF; new: $53; t: RSht1; size: 4), // Spellbook misbehaves when controlled with keyboard
    (p: $41FFB9; newp: @ChestVerticalHook; t: RShtCall; size: 6; Querry: hqPlaceChestItemsVertically), // Place items in chests vertically
    (p: $41F432; old: $41ECC7; newp: @ShowArmorHalved; t: RSht4), // Fix GM Axe
    (p: $4397C0; newp: @FixGMAxeHook1; t: RShtBefore; size: 7), // Fix GM Axe
    (p: $439CDA; newp: @FixGMAxeHook2; t: RShtCallStore), // Fix GM Axe
    (p: $439D57; newp: @ParalyzedStr; t: RSht4), // Fix GM Axe
    (p: $42031F; newp: @FixChestsCompact; t: RShtAfter; size: 6; Querry: hqFixChestsByCompacting), // Fix chests by compacting
    (p: $47BB77; newp: @SpritesAngleHook; t: RShtBefore; size: 7; Querry: hqSpriteAngleCompensation), // Sprite angle compensation
    (p: $440D76; newp: @SpritesAngleHook2; t: RShtBefore; size: 7; Querry: hqSpriteAngleCompensation), // Sprite angle compensation
    (p: $44D93B; old: $7F; new: $7D; t: RSht1; Querry: hqFixSFT), // SFT.bin was animated incorrectly (first frame was longer, last frame was shorter)
    (p: $461EFF; newp: @SaveGameBugHook; t: RShtCall), // Save game bug in Windows Vista and higher (bug of OS or other software)
    (p: $4C078B; size: 2; Querry: hqSpriteInteractIgnoreId), // Don't consider sprites with Id interactable
    (p: $440C36; old: $440CDB; newp: @DrawEffectsHook; t: RShtCallStore; Querry: hqClickThruEffects), // Click through effects SW (indoor)
    (p: $441D10; newp: @DrawDoneHook; t: RShtAfter; Querry: hqClickThruEffects), // Click through effects SW (indoor)
    (p: $47A808; old: $47BAD3; newp: @DrawEffectsHook; t: RShtCallStore; Querry: hqClickThruEffects), // Click through effects SW (outdoor)
    (p: $441D42; newp: @DrawDoneHook; t: RShtAfter; Querry: hqClickThruEffects), // Click through effects SW (outdoor)
    (p: $4A0063; newp: @D3DErrorMessageHook; t: RShtAfter), // Proper D3DRend->Init error messages
    (p: $4A0662; newp: @D3DErrorMessageHook; t: RShtAfter), // Proper D3DRend->Init error messages
    (p: $48DF69; old: 8; new: 7; t: RSht1), // Poison2 and Poison3 swapped
    (p: $48DF75; old: 6; new: 9; t: RSht1), // Disease3 instead of Disease1
    (p: $48DF80; old: 8; new: 10; t: RSht1), // Disease2 and Disease3 not working
    (p: $48E12D+9*4; old: $48E0C8; new: $48DF73; t: RSht4), // Disease2 and Disease3 not working
    (p: $48E12D+10*4; old: $48E0C8; new: $48DF73; t: RSht4), // Disease2 and Disease3 not working
    (p: $4483D8; newp: @CloseNPCDialog; t: RShtBefore; size: 6), // Allow entering maps from NPC dialog
    (p: $448017; newp: @CloseNPCDialog2; t: RShtBefore; size: 7), // Allow entering maps from NPC dialog
    (p: $450284; newp: @FixChestSmartHook; t: RShtCall; size: 8; Querry: 19), // Fix chests: reorder to preserve important items
    (p: $45852A; newp: @FixCompareBuff; t: RShtAfter), // Fix buffs - prefer new ones if they're longer OR stronger
    (p: $423B32; newp: @FixZeroVertexFacet1; t: RShtBefore), // Fix crash due to a facet with no vertexes
    (p: $46A08E; newp: @MouseLookHook; t: RShtJmp; size: 10), // Mouse look
    (p: $4D825C; newp: @MouseLookHook2; t: RSht4), // Mouse look
    (p: $4160C5; backup: @@MouseLookHook3Std; newp: @MouseLookHook3; t: RShtCall), // Mouse look
    (p: $459E78; newp: @ClearKeyStatesHook; t: RShtJmp; size: 6), // Clear my keys as well
    (p: $4BFC6C; old: 5000; newp: @WinScreenDelay; newref: true; t: RSht4), // Control Win screen delay during which all input is ignored
    (p: $43C046; old: $5074F0; new: $5074E8; t: RSht4), // In Awards screen Up and Down arrows were switched when pressed
    (p: $43C06A; old: $5074E8; new: $5074F0; t: RSht4), // In Awards screen Up and Down arrows were switched when pressed
    (p: $422621; newp: ptr($422650); t: RShtJmp; size: 6), // Leftover code from MM6
    (p: $45275E; newp: @FixNoHWL; t: RShtBefore), // Allow running without HWLs
    (p: $421893; old: 30; new: 32; t: RSht1), // Fix ring view magnifying glass click width
    (p: $434A6C; old: 30; new: 32; t: RSht1), // Fix ring view magnifying glass click width
    (p: $49A745; old: $4CA780; newp: @FixReadFacetBit; t: RShtCall), // Restore AnimatedTFT bit from Blv rather than Dlv to avoid crash
    (p: $47E787; old: $4CA780; newp: @FixReadFacetBit; t: RShtCall), // Restore AnimatedTFT bit from Odm rather than Ddm to avoid crash
    (p: $4716EE; newp: @FixMonsterBlockShots; t: RShtJmp; size: 7; Querry: hqFixMonsterBlockShots), // Fix monsters blocking shots of other monsters
    (p: $450657; newp: @FixUnmarkedArtifacts; t: RShtBefore), // Fix deliberately generated artifacts not marked as found
    (p: $48DF0C; newp: @FixMonStealDisplay; t: RShtAfter; size: 6), // Don't show stealing animation if nothing's stolen
    //(p: $426D46; size: 12), // Demonstrate recovered stolen items
    (p: $426D49; newp: @FixStolenLootHint; t: RShtCallStore), // Show that stolen item was found
    (p: $426D61; size: 7), // Stolen items enabling multi-loot
    (p: $426D95; size: 7), // Stolen items enabling multi-loot
    (p: $441E26; newp: @MinimapBkgHook; t: RShtCall; Querry: hqMinimapBkg), // Draw bitmap as internal minimap background 
    (p: $422698; newp: @InterfaceColorChangedHook; t: RShtBefore), // Load alignment-dependant interface
    (p: $412B5B; newp: @DrawSpellBook; t: RShtAfter; Querry: hqAttackSpell), // Attack spell
    ()
  );
{$ELSE}
  Hooks: array[1..66] of TRSHookInfo = (
    (p: $47AB35; old: $4D9557; newp: @AbsCheckOutdoor; t: RShtCall), // Monsters not visible on the sides of the screen
    (p: $47A55E; old: $4D9557; newp: @AbsCheckOutdoor; t: RShtCall), // Items not visible on the sides of the screen
    (p: $48B37E; old: $4D9557; newp: @AbsCheckOutdoor; t: RShtCall), // Effects not visible on the sides of the screen
    (p: $47819E; old: $4D9557; newp: @AbsCheckOutdoor; t: RShtCall), // Buildings not visible on the sides of the screen
    (p: $43CBB5; old: $4D9557; newp: @AbsCheckIndoor; t: RShtCallStore), // Support any FOV indoors (sprites)
    (p: $43CF57; old: $4D9557; newp: @AbsCheckIndoor; t: RShtCallStore), // Support any FOV indoors (monsters)
    (p: $4636B6; newp: @NeedWindowSize; t: RShtAfter), // Just before creating the window
    (p: $4637B7; newp: @WindowWidth; newref: true; t: RSht4; Querry: hqWindowSize), // Configure window size
    (p: $4637CD; newp: @WindowHeight; newref: true; t: RSht4; Querry: hqWindowSize), // Configure window size
    (p: $4618FF; newp: @WindowProcHook; t: RShtFunctionStart; size: 6), // Window procedure hook
    (p: $4119FC; newp: @FixLoadBitmapInPlace; t: RShtBefore), // Fix LoadBitmapInPlace
    (p: $4D0839; newp: @PaperDollInChestsInitHook; t: RShtBefore; Querry: hqPaperDollInChests),
    (p: $415584; newp: @PaperDollInChestsDrawExit; t: RShtBefore; Querry: hqPaperDollInChests),
    (p: $4D06B2; newp: @PaperDollInChestsDraw; t: RShtBefore; Querry: hqPaperDollInChests),
    (p: $416CF1; newp: @PaperDollInChestsRightClick; t: RShtBefore; size: 7; Querry: hqPaperDollInChests),
    (p: $416990; newp: @PaperDollInChestsRightClick2; t: RShtBefore; Querry: hqPaperDollInChests2),
    (p: $416E52; newp: @PaperDollInChestsClick; t: RShtBefore; Querry: hqPaperDollInChests),
    (p: $45C472; newp: @LoadSaveEnter8; t: RShtBefore; size: 6), // Enter key in load/save dialogs
    (p: $45C881; newp: @LoadSaveEnter8; t: RShtBefore; size: 6), // Enter key in load/save dialogs
    (p: $41C25D; newp: @KeyControl; t: RShtAfter; size: 6), // Control certain dialogs with keyboard
    (p: $461F41; size: 2), // Control certain dialogs with keyboard (allow keyboard everywhere)
    (p: HookWindowProc; newp: @KeyControlCheckUnblock; t: RShtBefore), // Control certain dialogs with keyboard
    (p: $4163EA; newp: @EnchantItemRightClick; t: RShtAfter), // Allow right click in item spell dialogs
    (p: $41F433; newp: @ChestVerticalHook; t: RShtCall; size: 6; Querry: hqPlaceChestItemsVertically), // Place items in chests vertically
    (p: $4371A0; newp: @FixGMAxeHook1; t: RShtBefore), // Fix GM Axe
    (p: $437798; newp: @FixGMAxeHook2; t: RShtCallStore), // Fix GM Axe
    (p: $43780E; newp: @ParalyzedStr; t: RSht4), // Fix GM Axe
    (p: $41F808; newp: @FixChestsCompact; t: RShtAfter; size: 6; Querry: hqFixChestsByCompacting), // Fix chests by compacting
    (p: $47AE66; newp: @SpritesAngleHook; t: RShtBefore; size: 7; Querry: hqSpriteAngleCompensation), // Sprite angle compensation
    (p: $43DCC2; newp: @SpritesAngleHook2; t: RShtBefore; size: 7; Querry: hqSpriteAngleCompensation), // Sprite angle compensation
    (p: $44B020; old: $7F; new: $7D; t: RSht1; Querry: hqFixSFT), // SFT.bin was animated incorrectly (first frame was longer, last frame was shorter)
    (p: $45F91B; newp: @SaveGameBugHook; t: RShtCall), // Save game bug in Windows Vista and higher (bug of OS or other software)
    (p: $4BE379; size: 2; Querry: hqSpriteInteractIgnoreId), // Don't consider sprites with Id interactable
    (p: $43DB82; old: $43DC27; newp: @DrawEffectsHook; t: RShtCallStore; Querry: hqClickThruEffects), // Click through effects SW (indoor)
    (p: $43E967; newp: @DrawDoneHook; t: RShtAfter; Querry: hqClickThruEffects), // Click through effects SW (indoor)
    (p: $4799FF; old: $47ADC2; newp: @DrawEffectsHook; t: RShtCallStore; Querry: hqClickThruEffects), // Click through effects SW (outdoor)
    (p: $43E999; newp: @DrawDoneHook; t: RShtAfter; Querry: hqClickThruEffects), // Click through effects SW (outdoor)
    (p: $49D6C6; newp: @D3DErrorMessageHook; t: RShtAfter), // Proper D3DRend->Init error messages
    (p: $49DD01; newp: @D3DErrorMessageHook; t: RShtAfter), // Proper D3DRend->Init error messages
    (p: $48D3F2; old: 8; new: 7; t: RSht1), // Poison2 and Poison3 swapped
    (p: $48D40D; old: 6; new: 9; t: RSht1), // Disease3 instead of Disease1
    (p: $48D419; old: 8; new: 10; t: RSht1), // Disease2 and Disease3 not working
    (p: $48D5BC+9*4; old: $48D557; new: $48D40B; t: RSht4), // Disease2 and Disease3 not working
    (p: $48D5BC+10*4; old: $48D557; new: $48D40B; t: RSht4), // Disease2 and Disease3 not working
    (p: $4456ED; newp: @CloseNPCDialog; t: RShtBefore; size: 7), // Allow entering maps from NPC dialog
    (p: $44533D; newp: @CloseNPCDialog2; t: RShtBefore; size: 7), // Allow entering maps from NPC dialog
    (p: $44D9AC; newp: @FixChestSmartHook; t: RShtCall; size: 8; Querry: 19), // Fix chests: reorder to preserve important items
    (p: $455DA8; newp: @FixCompareBuff; t: RShtAfter), // Fix buffs - prefer new ones if they're longer OR stronger
    (p: $421FA9; newp: @FixZeroVertexFacet1; t: RShtBefore; size: 6), // Fix crash due to a facet with no vertexes
    (p: $4683FE; newp: @MouseLookHook; t: RShtJmp; size: 10), // Mouse look
    (p: $4E8210; newp: @MouseLookHook2; t: RSht4), // Mouse look
    (p: $415584; backup: @@MouseLookHook3Std; newp: @MouseLookHook3; t: RShtCall), // Mouse look
    (p: $45773F; newp: @ClearKeyStatesHook; t: RShtJmp; size: 6), // Clear my keys as well
    (p: $46504A; newp: @ClearKeyStatesHook; t: RShtBefore), // Clear keys when entering the game
    (p: $4BD7AE; old: 5000; newp: @WinScreenDelay; newref: true; t: RSht4), // Control Win screen delay during which all input is ignored
    (p: $44FF93; newp: @FixNoHWL; t: RShtBefore), // Allow running without HWLs
    (p: $497C3A; old: $4D96B0; newp: @FixReadFacetBit; t: RShtCall), // Restore AnimatedTFT bit from Blv rather than Dlv to avoid crash
    (p: $47DCAD; old: $4D96B0; newp: @FixReadFacetBit; t: RShtCall), // Restore AnimatedTFT bit from Odm rather than Ddm to avoid crash
    (p: $47024C; newp: @FixMonsterBlockShots; t: RShtJmp; size: 7; Querry: hqFixMonsterBlockShots), // Fix monsters blocking shots of other monsters
    (p: $48D396; newp: @FixMonStealDisplay; t: RShtAfter; size: 6), // Don't show stealing animation if nothing's stolen
    //(p: $425182; size: 12), // Demonstrate recovered stolen items
    (p: $425185; newp: @FixStolenLootHint; t: RShtCallStore), // Show that stolen item was found
    (p: $42519D; size: 7), // Stolen items enabling multi-loot
    (p: $4251D1; size: 7), // Stolen items enabling multi-loot
    (p: $43EA7C; newp: @MinimapBkgHook; t: RShtCall; Querry: hqMinimapBkg), // Draw bitmap as internal minimap background
    (p: $4CA240; newp: @ASpellHintMM8; t: RShtAfter; Querry: hqAttackSpell), // Attack spell
//    (p: $4E9BA4; newp: @SpellBookHoverItem; t: RShtCodePtrStore), // Quick Spell buttons hints
    ()
  );
{$IFEND}

procedure ApplyHooks(Querry: int);
begin
  RSApplyHooks(HooksCommon, Querry);
  RSApplyHooks(Hooks, Querry);
end;

procedure ApplyMMHooks;
begin
  CheckHooks(HooksCommon);
  CheckHooks(Hooks);
  ApplyHooks(0);
  if PlaceChestItemsVertically then
    ApplyHooks(hqPlaceChestItemsVertically);
  if FixChestsByCompacting then
    ApplyHooks(hqFixChestsByCompacting);
  if SpriteAngleCompensation then
    ApplyHooks(hqSpriteAngleCompensation);
  if SpriteInteractIgnoreId then
    ApplyHooks(hqSpriteInteractIgnoreId);
  if FixConditionPriorities then
    DoFixConditionPriorities;
  if HintStayTime > 0 then
    ApplyHooks(hqFixStayingHints);
  if Options.FixMonstersBlockingShots then
    ApplyHooks(hqFixMonsterBlockShots);
end;

procedure ApplyMMDeferredHooks;
begin
  if Options.PaperDollInChests > 0 then
    ApplyHooks(hqPaperDollInChests);
  if Options.PaperDollInChests = 2 then
    ApplyHooks(hqPaperDollInChests2);
  if (Options.PaperDollInChests > 0) and not Options.HigherCloseRingsButton then
    ApplyHooks(hqPaperDollInChestsAndOldCloseRings);
  if Options.FixSFT then
    ApplyHooks(hqFixSFT);
  if Options.FixChestsByReorder then
    ApplyHooks(19);
  if Options.EnableAttackSpell then
    ApplyHooks(hqAttackSpell);
end;

procedure ApplyMMHooksSW;
begin
  if ClickThroughEffects then
    ApplyHooks(hqClickThruEffects);
end;

procedure NeedWindowSize;
begin
{$IFNDEF MM6}
  if (Options.UILayout <> nil) and _IsD3D^ then
    Layout.Start;
{$ENDIF}
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
  ApplyHooks(hqWindowSize);
end;

procedure LoadInterface;
begin
{  c:= MinimapColor;
  i:= _GreenColorBits^;
  MinimapColor:= c shr (24-5) shl (i + 5) + Word(c) shr (16 - i) + byte(c) shr 3;}
  //  Count < 1000) and (_DoLoadLodBitmap(0,0, _IconsLod, 2, 'mapbkg', Items[Count]) <> -1) then
{  if (m6 = 0) and (_LodFind(0,0, _IconsLod, 0, 'mapbkg.pcx') <> nil) then
  begin
    _LoadPcx(0,0, MinimapBkgPcx, 0, 'mapbkg.pcx');
    RSApplyHooks(Hooks, hqMinimapBkg);
  end;}
  with _IconsLodLoaded^ do
    if (m6 = 0) and (Count < 1000) and (_DoLoadLodBitmap(0,0, _IconsLod, 2, 'mapbkg', Items[Count]) <> -1) then
    begin
      MinimapBkgBmp:= Count;
      inc(Count);
      ApplyHooks(hqMinimapBkg);
    end;
  if Options.EnableAttackSpell and (m6 = 1) then
  begin
    ASpellIcon:= _LoadLodBitmap(0,0, _IconsLod, 2, 'TabASpell');
    ASpellIconDn:= ASpellIcon;
  end;
  if Options.EnableAttackSpell and (m7 = 1) then
    ASpellIconDn:= _LoadLodBitmap(0,0, _IconsLod, 2, 'IB-ASpellD');
end;

procedure InterfaceColorChanged(_: Bool; Replace: Boolean; Align: int);
const
  ReplaceBmp: function(_,__,lod: int; PalKind: int; name: PChar; var bmp): int = ptr($4101BD);

  function Letter: string;
  begin
    case Align of
      0: Result:= 'B';
      2: Result:= 'C';
      else Result:= 'A';
    end;
  end;
  procedure Bmp(var i: int; const s: string);
  begin
    if Replace then
      ReplaceBmp(0,0, _IconsLod, 2, PChar(s + Letter), _IconsLodLoaded.Items[i])
    else
      i:= _LoadLodBitmap(0,0, _IconsLod, 2, PChar(s + Letter));
  end;
begin
  if Options.EnableAttackSpell then
    Bmp(ASpellIcon, 'IB-ASpell-');
end;

initialization
finalization
  if EmptyCur <> 0 then
    DestroyCursor(EmptyCur);
end.
