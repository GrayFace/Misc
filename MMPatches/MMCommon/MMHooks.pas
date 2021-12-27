unit MMHooks;

interface
{$I MMPatchVer.inc}

uses
  Windows, Messages, SysUtils, Classes, RSSysUtils, RSQ, Common, RSCodeHook,
  Math, MP3, RSDebug, RSIni, Direct3D, Graphics, MMSystem, RSStrUtils,
  DirectDraw, DXProxy, {$IFNDEF MM6}LayoutSupport,{$ENDIF} MMCommon,
  RSResample{$IFDEF MM8}, MMLayout{$ENDIF};

procedure CheckMMHooks;
procedure ApplyMMHooks;
procedure ApplyMMDeferredHooks;
procedure ApplyMMHooksLodsLoaded;
procedure NeedWindowSize;
procedure LoadInterface;
procedure InterfaceColorChanged(_: Bool; Replace: Boolean; Align: int);
procedure DrawMyInterface;
function GetCoordCorrectionIndoorX: ext;
function GetCoordCorrectionIndoorY: ext;
function IsLayoutActive(CanActivate: Boolean = true): Boolean; inline;
function TransformMousePos(x, y: int; out x1: int): int;
function MyGetAsyncKeyState(vKey: Integer): SHORT; inline; //{$IFNDEF MM6}stdcall;{$ELSE}inline;{$ENDIF}
function CheckKey(key: int):Boolean;
procedure CommonKeysProc;
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
  MouseLookOn, WasMouseLookOn, MLookIsTemp, SkipMouseLook: Boolean;

implementation

{$IFNDEF MM6}uses D3DHooks;{$ENDIF}

const
  RingsShown = int(_InventoryRingsShown);
  CurrentScreen = int(_CurrentScreen);
  CurrentMember = int(_CurrentMember);
  NeedRedraw = int(_NeedRedraw);
  ShooterFirstDelay = 300;
  ShooterNextDelay = 70;

// Raw mouse input
const
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

{var
  KeysChecked: array[0..255] of Boolean;}

function MyGetAsyncKeyState(vKey: Integer): SHORT; inline;//{$IFNDEF MM6}stdcall;{$ELSE}inline;{$ENDIF}
begin
  //vKey:= vKey and $ff;
  Result:= GetAsyncKeyState(vKey);
  {if (Result < 0) and not KeysChecked[vKey] then
    Result:= Result or 1;
  KeysChecked[vKey]:= Result < 0;}
end;

function CheckKey(key: int): Boolean;
begin
  Result:= (MyGetAsyncKeyState(key) and 1) <> 0;
end;

function CheckMouseKey(right: Boolean): Boolean;
const
  Btn: array[Boolean] of int = (VK_LBUTTON, VK_RBUTTON);
begin
  Result:= GetAsyncKeyState(Btn[(GetSystemMetrics(SM_SWAPBUTTON) <> 0) xor right]) < 0;
end;

//----- Now time isn't resumed when mouse exits, need to check if it's still pressed

procedure CheckRightPressed;
begin
  if not CheckMouseKey(true) then
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

  // MouseLookPermKey
  if CheckKey(Options.MouseLookPermKey) then
    MouseLookChanged2:= not MouseLookChanged2;

  // MouseLook
  if Options.MouseLook then
    ProcessMouseLook;

  // Now time isn't resumed when mouse exits, need to check if it's still pressed
  if _Windowed^ and _RightButtonPressed^ then
    CheckRightPressed;

  // Select 1st player in shops if all are inactive
  if FixInactivePlayersActing and (_CurrentMember^ = 0) and (_CurrentScreen^ = 13) then
    _CurrentMember^:= 1;

  WasInDialog:= (_DialogsHigh^ > 0) or (_CurrentScreen^ <> 0);
end;

//----- Window procedure hook

var
  BackupStatusTime: uint;
  BackupStatusStr: array[0..199] of Char;

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

procedure ShooterPress(const xy: TSmallPoint; right: Boolean);
begin
  if (Options.ShooterMode = fpsOn) and MouseLookOn and (_Paused^ = 0) and PtInView(xy.x, xy.y) then
  begin
    ShooterButtons[right]:= true;
    ShooterDelay:= 0;
  end;
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
  if (msg = WM_LBUTTONDOWN) or (msg = WM_LBUTTONDBLCLK) then
    ShooterPress(xy, false);
  if msg = WM_RBUTTONDOWN then
    ShooterPress(xy, true);
  if (msg = WM_RBUTTONDOWN) and ShowHintWithRMB then
  begin
    BackupStatusTime:= _StatusText.TmpTime;
    if BackupStatusTime <> 0 then
    begin
      CopyMemory(@BackupStatusStr[1], @_StatusText.Text[false], 200);
      _StatusText.Text[false][0]:= #0;
      _StatusText.TmpTime:= 0;
    end;
  end;
  if (msg = WM_RBUTTONUP) and (BackupStatusTime <> 0) and (_StatusText.Text[false][0] = #0) and
     (int(BackupStatusTime - GetTickCount) > 0) then
  begin
    _StatusText.TmpTime:= BackupStatusTime;
    _StatusText.Text[true][0]:= #0;
    CopyMemory(@_StatusText.Text[false], @BackupStatusStr[1], 200);
    BackupStatusTime:= 0;
  end;
  if (msg = WM_RBUTTONDOWN) and ExitTalkingWithRightButton then
    if (_CurrentScreen^ in [4, 17, 18]) or
       (_CurrentScreen^ = 13) and ((_HouseScreen^ in [0, 1, 96, 101, 102, 103]) or (_HouseScreen^ = -1)) or
       (_CurrentScreen^ = 19) and ((_Dlg_SimpleMessage^ = nil) or (_Dlg_SimpleMessage^.DlgParam <> $1A)) then
      ExitScreen;

  Result:= WindowProcStd(w, msg, wp, lp);

  case msg of
    WM_MOUSEWHEEL:
      if Options.MouseWheelFly then
        if wp < 0 then
          _AddCommand(0, 0, _CommandsArray, 14)
        else
          _AddCommand(0, 0, _CommandsArray, 13);
{ $IFDEF MM6
    WM_KEYDOWN, WM_SYSKEYDOWN:
      if wp and not $ff = 0 then
        KeysChecked[wp]:= false;
{$ENDIF}
    WM_INPUT:
      if (byte(wp) = 0) and MLookRaw then
        ProcessRawMouseLook(lp);
  end;

  if IsLayoutActive or not Options.BorderlessWindowed and IsZoomed(w) then
    case msg of
      WM_ACTIVATEAPP:
        if wp = 0 then
        begin
          ClipCursor(nil);
          if BorderlessTopmost then
            SendMessage(w, WM_SYSCOMMAND, SC_MINIMIZE, 0);
        end else
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

//----- Borderless fullscreen (also see WindowProcHook)

procedure SwitchToWindowedHook;
begin
  Options.BorderlessWindowed:= true;
  if BorderlessTopmost then
    SetWindowPos(_MainWindow^, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE + SWP_NOSIZE);
  SetWindowPos(_MainWindow^, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE + SWP_NOSIZE);
  ShowWindow(_MainWindow^, SW_SHOWNORMAL);
  SetWindowLong(_MainWindow^, GWL_STYLE, GetWindowLong(_MainWindow^, GWL_STYLE) or _WindowedGWLStyle^);
  ClipCursor(nil);
end;

procedure SwitchToFullscreenHook;
begin
  Options.BorderlessWindowed:= false;
  if BorderlessTopmost then
    SetWindowPos(_MainWindow^, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE + SWP_NOSIZE);
  ShowWindow(_MainWindow^, SW_SHOWMAXIMIZED);
  PostMessage(_MainWindow^, WM_SYSCOMMAND, SC_MAXIMIZE, 0);
  MyClipCursor;
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
  WasMouseLookOn:= MouseLookOn;
  if SkipMouseLook then  // a hack for right-then-left click combo
  begin
    SkipMouseLook:= false;
    exit;
  end;
  NeedScreenWH;
  // compatibility with resolution patches like mmtool's one
  if Options.ShooterMode = 0 then
  begin
    MCenter.X:= (SW - MLSideX) div 2;
    MCenter.Y:= (SH - MLSideY) div 2;
  end else
  begin
    MCenter:= _ScreenMiddle^;
    inc(MCenter.X, IfThen(_IsD3D^, 1, 2));
    inc(MCenter.Y, 1);
  end;
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
          MouseLookChanged xor MouseLookChanged2 xor MouseLookUseAltMode xor
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
    Result:= (x + 1024) and not 2047;
    part:= x - Result;
    Result:= Result div 2048;
  end;

const
  dir = _Party_Direction;
  angle = _Party_Angle;
var
  p: TPoint;
  speed: PPoint;
  a: int;
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
    a:= angle^ - Partial(MLookDY, MLookPartY, speed.Y);
    with Options do
      angle^:= IntoRange(a, -MaxMLookAngle, max(MaxMLookAngle, MaxMLookUpAngle));
    if (MLookDX <> 0) or (MLookDY <> 0) then  //(p.X <> MLastPos.X) or (p.Y <> MLastPos.Y) then
    begin
      p:= MWndPos;
      ClientToScreen(_MainWindow^, p);
      SetCursorPos(p.X, p.Y);
    end;
  end;
  if MLookRaw then
  begin
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
  if (a.header.dwType <> RIM_TYPEMOUSE) or (a.usFlags and 1 <> 0) then  exit;
  MouseLookOn:= MouseLookOn and (_MainMenuCode^ < 0) and (GetForegroundWindow = _MainWindow^);
  if MouseLookOn and WasMouseLookOn then
  begin
    inc(MLookDX, a.lLastX);
    inc(MLookDY, a.lLastY);
  end;
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
  MouseLookHook3Std: function(a1, a2, this: ptr): int;
  MLookBmp, MLookBmpShooter, MLookHDBmp, MLookHDBmpShooter: TBitmap;

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
  if (Options.ShooterMode <> 0) and FileExists('Data\MouseCursorShooter.bmp') then
    MLookBmpShooter:= LoadMLookBmp('Data\MouseCursorShooter.bmp', fmt);
  if MLookBmpShooter = nil then
    MLookBmpShooter:= MLookBmp;
end;

procedure MLookDraw;
var
  p1, p2: PChar;
  x, y, w, h, d1, d2: int;
  k, trans: Word;
  b: TBitmap;
begin
  if MLookBmp = nil then
    MLookLoadBmp;
  b:= MLookBmp;
  if Options.ShooterMode = fpsOn then
    b:= MLookBmpShooter;
  w:= b.Width;
  h:= b.Height;
  p1:= b.ScanLine[0];
  d1:= PChar(b.ScanLine[1]) - p1 - 2*w;
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
  if MLookHDBmp = nil then
  begin
    MLookHDBmp:= LoadMLookBmp('Data\MouseLookCursorHD.bmp', pf32bit);
    if (Options.ShooterMode <> 0) and FileExists('Data\MouseCursorShooterHD.bmp') then
      MLookHDBmpShooter:= LoadMLookBmp('Data\MouseCursorShooterHD.bmp', pf32bit);
    if MLookHDBmpShooter = nil then
      MLookHDBmpShooter:= MLookHDBmp;
  end;
  DXProxyCursorBmp:= MLookHDBmp;
  if Options.ShooterMode = fpsOn then
    DXProxyCursorBmp:= MLookHDBmpShooter;
  GetClientRect(_MainWindow^, r);
  DXProxyCursorX:= (p.X*DXProxyRenderW*2 div r.Right + 1) div 2 - DXProxyCursorBmp.Width div 2;
  DXProxyCursorY:= (p.Y*DXProxyRenderH*2 div r.Bottom + 1) div 2 - DXProxyCursorBmp.Height div 2;
end;

function MouseLookHook3(std, a2, this: ptr): int;
begin
  CheckMouseLook;
  if MouseLookOn and not MLookIsTemp then
    if MouseLookCursorHD and DXProxyActive and
       ((DXProxyRenderW > SW) or (DXProxyRenderH > SH) or IsLayoutActive) then
      MLookDrawHD(MWndPos)
    else
      MLookDraw;

  DrawMyInterface;
  Result:= MouseLookHook3Std(nil, nil, this);
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

procedure KeyControlCheckInvis;
asm
{$IFDEF MM7}
  cmp dword ptr [ecx + $C], 0
{$ELSE}
  cmp dword ptr [eax + $C], 0
{$ENDIF}
  jnz @ok
  mov [esp], m6*$419FA2 + m7*$41CF5A + m8*$41C3E9
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

//----- Click through effects D3D

procedure CheckSpriteD3D;
asm
  push edx
  push eax
  call IsEffectSprite
  test al, al
  pop eax
  pop edx
  jz @std
  xor edx, edx
  mov eax, 6
@std:
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
    ExitScreen;
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
  CondOrder: array[0..17 - m6] of int = (Eradicated, Dead, Stoned, Unconscious,
     Paralyzed, Asleep, Weak, Cursed{$IFNDEF mm6}, Zombie{$ENDIF}, Disease3,
     Poison3, Disease2, Poison2, Disease1, Poison1, Insane, Drunk, Afraid);
  OldCond = m6*$4C276C + m7*$4EDDA0 + m8*$4FDFA8;
  CodeStart = m6*$482D30 + m7*$48E9EC + m8*$48E127;
  CodeSize = m6*$482D74 + m7*$48EA13 + m8*$48E14E - CodeStart;
{$IFDEF mm6}
  ArrRef: array[0..5] of int = ($4849B0, $4849D4, $484A34, $482D36, $482D5A, $482D6C);
  CodeRef: array[0..2] of int = ($417124, $41AB1D, $42D410);
{$ELSEIF defined(mm7)}
  ArrRef: array[0..1] of int = ($48E9F2, $48EA0D);
  CodeRef: array[0..3] of int = ($41AA48, $41D583, $434E18, $490A1D);
{$ELSE}
  ArrRef: array[0..1] of int = ($48E12D, $48E148);
  CodeRef: array[0..6] of int = ($41AAA5, $41CAD7, $4304E2, $43260A, $43278B, $48FB88, $4C915A);
{$IFEND}
  HookCode: TRSHookInfo = (old: CodeStart; t: RShtCall);
  HookArr: TRSHookInfo = (old: OldCond; newp: @CondOrder; t: RSht4);
var
  hk: TRSHookInfo;
  i, p: int;
begin
  //CopyMemory(ptr(OldCond), @CondOrder, SizeOf(CondOrder));
  p:= RSAllocCode(CodeSize);
  CopyMemory(ptr(p), ptr(CodeStart), CodeSize);
  hk:= HookCode;
  hk.new:= p;
  for i := 0 to high(CodeRef) do
  begin
    hk.p:= CodeRef[i];
    CheckHook(hk);
    RSApplyHook(hk);
  end;

  for i := 0 to high(ArrRef) do
  begin
    hk:= HookArr;
    hk.p:= ArrRef[i];
    if uint(hk.p - CodeStart) < CodeSize then
      inc(hk.p, p - CodeStart);
    if pint(hk.p)^ <> OldCond then
    begin
      inc(hk.old, SizeOf(CondOrder));
      inc(PChar(hk.newp), SizeOf(CondOrder));
    end;
    CheckHook(hk);
    RSApplyHook(hk);
  end;
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
  mov eax, [esp+4]
	mov edx, [esp+8]
	mov edx, [edx]
	mov ecx, [eax]
	and cx, $4000
	and dx, $FFFF - $4000
	or dx, cx
	mov [eax], edx
end;

//----- Fix monsters blocking shots of other monsters

procedure FixMonsterBlockShots;
asm
  mov ecx, [ebp - $10]
  sub ecx, m7*$86 + m8*$8E
  lea edx, [_MapMonsters + eax]
  call _Mon_IsAgainstMon
  test eax, eax
  push m7*$471724 + m8*$470282
end;

//----- Fix monsters shot at from a distance appearing green on minimap

procedure FixFarMonstersAppearGreen;
asm
  test byte ptr [esi+25h], 080h  // ShowOnMap
  jnz @std
  xor edx, edx
  mov ecx, esi
  call _Mon_IsAgainstMon
  test eax, eax
  jz @std
  or byte ptr [esi+27h], 1  // ShowAsHostile
@std:
end;

//----- Fix item spells when cast onto item with index 0

procedure FixItemSpells;
asm
{$IFDEF mm6}
  jnz @std
  cmp word ptr [ebx], 29  // Enchant Item
  jnz @test
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
{$IFDEF mm6}
@test:
  test eax, eax
{$ENDIF}
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
  for i := 0 to 137 do
    if (a[i] < 0) and (a[-1 - a[i]] <= 0) then
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
  for i := 0 to 137 do
    if (a[i] < 0) and (a[-1 - a[i]] <= 0) then
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

//----- Inactive players could attack

procedure InactivePlayerActFix;
var
  old: int;
begin
  old:= _CurrentMember^;
  if (old = 0) or (pword(int(GetCurrentPlayer) + _CharOff_Recover)^ > 0) then
  begin
    _CurrentMember^:= _FindActiveMember;
    if _CurrentMember^ <> old then
      _NeedRedraw^:= 1;
  end;
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

//----- Draw bitmap as dungeon minimap background

var
  MinimapBkgBmp: int;

procedure MinimapBkgHook(_,__, screen, color, height, width, top, left: int);
begin
  _DrawBmpOpaque(0,0, screen, _IconsLodLoaded.Items[MinimapBkgBmp], top, left);
end;

//----- Load alignment-dependant interface

procedure InterfaceColorChangedHook;
asm
  pop eax
  push ecx
  push edx
  call eax
  pop edx
  pop ecx
  jmp InterfaceColorChanged
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
  ASpellPressed: Boolean;
  ASpellIconHover: PBoolean;
  ASpellHint: ShortString;

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
  ASpellHint:= '';
  SetupButtonMM8(p, 0, 330, true, 'GF-ASpell', 'GF-ASpellD');
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

{procedure LoadSpellSound(sp: int);
var
  i: int;
begin
  i:= _SpellSounds[sp];
  for i:= i to i + 1 do
    LoadSound(i, true);
end;}

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
        if cast then
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
  TestedASpell, WasASpell: Bool;

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
{$ENDIF}{$IFDEF mm7}
  mov esi, eax
  mov ebp, 0Bh
  mov bl, [esi + _CharOff_AttackQuickSpell]
{$ENDIF}{$IFDEF mm8}
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
  info = m6*($3E4-$3C8) + m7*($5FC-$5E4) + m8*($6C0-$6A4-4);
asm
{$IFNDEF mm7}
  mov ecx, eax
{$ENDIF}
  push eax
  cmp dword ptr [esp + info + 4], 1
  movzx eax, byte ptr [ecx + _CharOff_QuickSpell]
  jnz @fetch
  movzx eax, byte ptr [ecx + _CharOff_AttackQuickSpell]
  mov WasASpell, 2  // always reload ASpell
@fetch:
  push eax
  cmp WasASpell, 0  // last cast was quick spell?
  jz @noswitch
  dec WasASpell
  push edx
  call FetchSpellSound
  pop edx
@noswitch:
  pop ecx
  pop eax
end;

function TryASpell: Boolean;
var
  p: PChar;
  sp, i: int;
begin
  Result:= false;
  p:= GetCurrentPlayer;
  if p = nil then  exit;
  sp:= pword(p + _CharOff_AttackQuickSpell)^;
  if sp = 0 then  exit;
  i:= PSkills(p + _CharOff_Skills)[(sp-1) div 11 + 12];
  if i >= 256 then
    i:= 4
  else if i >= 128 then
    i:= 3
  else if i >= 64 then
    i:= 2
  else
    i:= 1;
  i:= _SpellInfo[sp].SpellPoints[i];
  if pint(p + _CharOff_SpellPoints)^ < i then  exit;
  Result:= true;
  AddAction(25, 1, 0);
end;

procedure ASpellClickMon;
asm
  jge @std
  call TryASpell
  cmp al, 1
@std:
end;

procedure ASpellHintMM8;
begin
  if ASpellIconHover^ then
  begin
    ASpellBookAction(true, false);
    ASpellHint:= _StatusText.Text[true];
  end
  else if ASpellHint <> '' then
  begin
    if ASpellHint = _StatusText.Text[true] then
    begin
      _StatusText.Text[true][0]:= #0;
      _NeedUpdateStatus^:= true;
    end;
    ASpellHint:= '';
  end;
end;

//----- Shooter mode

const
  ShooterSwordDelay = 1500;
  ShooterSwordIconNames: array[0..4] of string = ('GF-Swrd-Red', 'GF-Swrd-Yel', 'GF-Swrd-Gre', 'GF-Swrd-NA', 'GF-Swrd');
  ShooterSwordCheckMul: array[0..4] of int = (0, 1, 2, -1, 0);
var
  ShooterSwordMon: PChar;
  ShooterSwordTime: uint;
  ShooterSwordIcons: array[0..4] of int;
  ShooterDrawn, ShooterQSpell: Boolean;

function ShooterCheckKey(r, left: Boolean): Boolean;
begin
  if left and r then
    Options.ShooterMode:= fpsOn + fpsOff - Options.ShooterMode;
  Result:= r and not left;
  if (Options.ShooterMode <> fpsOn) or not ShooterButtons[not left] then
    exit;
  // tmp?
  ShooterButtons[not left]:= CheckMouseKey(not left);
  if not MouseLookOn then
    exit;
  Result:= false;
  if (ShooterDelay <> 0) and (int(ShooterDelay - GetTickCount) > 0) then
    exit;
  if not left then
    ShooterQSpell:= ShooterButtons[true] or r;
  if ShooterQSpell then
    Result:= not left
  else if left then
    Result:= ShooterButtons[false];
  if left then
    ShooterQSpell:= false;
  if _TurnBased^ and Result then
    if ShooterDelay = 0 then
    begin
      ShooterDelay:= GetTickCount + ShooterFirstDelay;
      _ActionQueue.Count:= 0;  // ignore click
    end else
      ShooterDelay:= GetTickCount + ShooterNextDelay;
end;

procedure ShooterCheckKeyHook;
asm
{$IFDEF mm6}
  setnz al
  mov edx, esi
{$ELSE}
  mov edx, [esp + $1C - 8]
{$ENDIF}
  sub edx, 7
  jz @check
  cmp edx, 1
  jnz @std
@check:
  call ShooterCheckKey
@std:
{$IFDEF mm6}
  test al, al
{$ENDIF}
end;

procedure ShooterEachTickHook;
begin
  if (_CurrentScreen^ <> 0) or (_Paused^ <> 0) then
  begin
    ShooterButtons[false]:= false;
    ShooterButtons[true]:= ShooterButtons[true] and CheckMouseKey(true);
  end;
end;

function ShooterCheckMon(std, _, m: PChar): Bool;
type
  TF = function(_,__:int; m: PChar): Bool;
begin
  if Options.ShooterMode = fpsOn then
    Result:= IsMonAlive(m, true)
  else
    Result:= TF(std)(0,0, m);
end;

procedure ShooterFindMon;
asm
  cmp Options.ShooterMode, fpsOn
  jnz @std
  cmp MouseLookOn, true
  jnz @std
  xor eax, eax
  ret $C - m6*4
@std:
  jmp eax
end;

procedure ShooterCheckMonDirection;
asm
  jnz @std
  cmp Options.ShooterMode, fpsOff
  jz @std
  cmp MouseLookOn, false
  jz @std
  cmp WasInDialog, true
@std:
end;

procedure ShooterRightClick;
asm
  cmp Options.ShooterMode, fpsOn
  jnz @std
  cmp MouseLookOn, true
  jnz @std
  cmp byte ptr [ShooterButtons+1], 0
  jnz @skip
@std:
  jmp eax
@skip:
end;

procedure ShooterSetSwordMon(m: PChar);
begin
  ShooterSwordMon:= m;
  ShooterSwordTime:= GetTickCount + ShooterSwordDelay;
end;

procedure ShooterSetSwordMonHook;
asm
  mov eax, esi
  jmp ShooterSetSwordMon
end;

function DrawShooter: Boolean;
const
  DrawX = (1-m8)*(394 + 18) + m8*(574 + 16) + 42;
  DrawY = (1-m8)*(288 + 10) + m8*(298 + 18);
  DeltaW = 40 - 12;
  MinW = 32 - DeltaW;
  MinH = 31 - DeltaW;
var
  mon: PChar;
  p: PWordArray;
  i, hp, full, stage, w, h: int;
begin
  Result:= true;
  NeedScreenWH;
  p:= _ScreenBuffer^;
  if ShooterSwordMon <> nil then
    if (uint(ShooterSwordTime - GetTickCount) > ShooterSwordDelay) or not IsMonAlive(ShooterSwordMon, false) then
      ShooterSwordMon:= nil;
  mon:= ShooterSwordMon;
  if mon = nil then
  begin
    i:= GetMouseTarget;
    if i and 7 = 3 then
    begin
      mon:= ptr(_MapMonsters + _MonOff_Size*(i div 8));
      if not IsMonAlive(mon, true) then
        mon:= nil;
    end;
  end;
  hp:= 0;
  full:= 1;
  if mon <> nil then
  begin
    hp:= pint2(mon + _MonOff_HP)^;
    full:= pint(mon + _MonOff_FullHP)^;
  end;
  stage:= 3*2;
  w:= 0; h:= 0; // Delphi compiler bug (warning)
  for i := high(ShooterSwordIcons) downto 0 do
    if (i < stage) and (hp*4 > full*ShooterSwordCheckMul[i]) then
      with _IconsLodLoaded.Items[ShooterSwordIcons[i]] do
      begin
        dec(stage, 3);
        if (stage > 0) then
        begin
          w:= Rec.w;
          h:= Rec.h;
        end else
        begin
          if hp >= full then
            continue;
          h:= DeltaW*(full - hp) div full;
          w:= MinW + h;
          h:= MinH + h;
        end;
//        Draw8t(@Image[(Rec.h - h)*Rec.w], @p[DrawX + (DrawY - h)*SW], Rec.w, SW*2, w, h, Palette16);
        Draw8t(@Image[Rec.w - w], @p[DrawX - w + DrawY*SW], Rec.w, SW*2, w, h, Palette16);
      end;
end;

procedure ShooterFixProjectilePos(_,__, a: PChar);
var
  z: int;
begin
  z:= pint(a + _ObjOff_Z)^ - _Party_Z^;
  if (z >= 0) and (z <= _Party_Height^) then
    pint(a + _ObjOff_Z)^:= _Party_Z^ + _Party_EyeLevel^ - _Party_Height^ div 6;
end;

procedure ShooterCreateProjectile;
asm
  cmp Options.ShooterMode, fpsOn
  jnz @std
  cmp MouseLookOn, true
  jnz @std
  cmp WasInDialog, 0
  jnz @std
  mov eax, [esp+4]
  cmp eax, m6*$422580 + m7*$427DB8 + m8*$425FF4
  jb @std
  cmp eax, m6*$429C74 + m7*$42E969 + m8*$42D525
  ja @std
  push ecx
  push edx
  call ShooterFixProjectilePos
  pop edx
  pop ecx
@std:
end;

//----- Attacking dying monsters

function CanAttackMon(m: PChar): Boolean;
begin
  Result:= IsMonAlive(m, false);
  if Result and (Options.ShooterMode = fpsOn) then
    ShooterSetSwordMon(m);
end;

procedure AttackMonHook;
asm
  push eax
  push ecx
  mov eax, esi
  call CanAttackMon
  test al, al
  pop ecx
  pop eax
  jnz @ok
  mov [esp], $430F02
  ret
@ok:
  test ecx, ecx
end;

procedure AttackMonHook2;
asm
  jz @std
  cmp ax, $B
  jz @std
  cmp ax, 17
  jz @std
  cmp ax, 19
@std:
end;

//----- Attacking friendly monsters

procedure FixAttackMonster;
asm
  mov dword ptr [esp+8], 1
  jmp eax
end;

//----- Fix shooting distant monsters indoor

procedure HookHitDistantMonster;
const
  IndoorOrOutdoor = int(_IndoorOrOutdoor);
asm
{  jz @no
  cmp dword ptr [IndoorOrOutdoor], 2
  jnz @no
  cmp dword ptr [ebp - $14 - m8*4], 5120 + 250
  jl @ok
@no:}
  mov [esp], m7*$439E0F + m8*$4378C6
@ok:
end;

//----- Fix character switch when Endurance eliminates hit recovery

procedure FixZeroRecovery;
asm
  cmp dword ptr [esp+4], 0
  jg @std
  pop eax
  pop ecx
@std:
  jmp eax
end;

//----- Show items in green while right mouse buttom is pressed

procedure RMBColorItems;
const
  RightButtonPressed = int(_RightButtonPressed);
asm
  jz @std
  cmp dword ptr [RightButtonPressed], 1
@std:
end;

//----- Fix wrong Quick Spell spell points check

procedure FixQSpellPointsCheck;
asm
{$IFDEF mm6}
  mov eax, $2E8BA2E9
  push ecx
  dec ecx
  imul ecx
  pop ecx
{$ELSE}
  dec eax
{$ENDIF}
end;

//----- Negative resistance may lead to devision by zero

procedure NegativeResHook;
asm
  cmp ecx, 0
  jg @ok
  mov ecx, 1
@ok:
end;

//----- Display Inventory screen didn't work with unconscious players

procedure FixDeadDisplayInventory;
const
  HouseScreen = int(_HouseScreen);
asm
  cmp dword ptr [HouseScreen], 94
  jz @skip
  jmp eax
@skip:
  mov eax, 1
end;

//----- Unconscious players identifying items in shop screens and on map

procedure FixDeadIdentifyItemProc;
asm
  push edx
  push ecx
  call GetCurrentPlayer
  test eax, eax
  jz @skip
  mov ecx, eax
  call _Character_IsAlive
  test eax, eax
  jz @skip
  mov eax, [__CurrentMember]
@skip:
  pop ecx
  pop edx
end;

//----- Show item descriptions even for unconscious players

procedure DoShowItemInfo(index: int);
var
  p: PChar;
begin
  p:= GetCurrentPlayer;
  if p = nil then
    exit;
  _DrawItemInfoBox(0,0, p + _CharOff_Items + index*_ItemOff_Size);
end;

procedure DeadShowItemInfoProc;
asm
{$IFDEF mm6}mov eax, ebp{$ENDIF}
{$IFDEF mm7}mov eax, [ebp - 8]{$ENDIF}
{$IFDEF mm8}mov eax, [ebp - $C]{$ENDIF}
  jmp DoShowItemInfo
end;

//----- Fix Assassins' and Barbarians' enchantments

procedure FixItemsAssassinsBarbarians;
asm
{$IFDEF mm7}mov eax, ebx{$ENDIF}
  cmp eax, 67
  jz @ass
  cmp eax, 68
  mov eax, 5  // Barbarians' = of Frost
  jz @ok
  push m7*$439FA3 + m8*$437AE8
  ret
@ass:
  mov eax, 13  // Assassins' = of Poison
@ok:
{$IFDEF mm7}mov ebx, eax{$ENDIF}
  push m7*$439E7D + m8*$4379AC
end;

//----- AOE damage wasn't dealt to paralyzed monsters

function MonsterIsAliveHook(_, __, m: PChar): Bool;
begin
  Result:= IsMonAlive(m, true);
end;

//----- Fix 'GM' not being read in Monsters.txt

function FixMonstersSpellGM(str, gm: PChar): int; cdecl;
begin
  Result:= _strcmpi(str, gm);
  if Result <> 0 then
    Result:= _strcmpi(str, 'GM');
end;

//----- Monsters.txt - Fix 'Ice Bolt' turning into 'Ice Blast' and vice versa

procedure IceBoltBlastFix;
const
  blast: PChar = 'Blast';
asm
  mov eax, blast
  push eax
  push dword ptr [edi + 8]
  call _strcmpi
  test eax, eax
  pop ecx
  pop ecx
  mov eax, 32  // blast
  jz @ok
  mov eax, 26  // bolt
@ok:
  mov [esp + 4], eax
end;

//----- Monster sprites size multiplier SW

procedure MonSpritesSizeSW;
asm
  cmp Options.MonSpritesSizeMul, 0
  jz @std
  mov eax, Options.MonSpritesSizeMul
{$IFDEF mm6}mov [esp+58h-24h], eax{$ENDIF}
@std:
end;

procedure MonSpritesSizeSW2;
asm
  cmp Options.MonSpritesSizeMul, 0
  jz @std
{$IFDEF mm6}xchg eax, ecx{$ENDIF}
  imul eax, Options.MonSpritesSizeMul
  sar eax, 16
{$IFDEF mm6}xchg eax, ecx{$ENDIF}
@std:
end;

//----- Monster sprites size multiplier D3D

var
  MonSpritesMulBuf: array[0..$27] of byte;

procedure MonSpritesSizeHW;
const
  BufSize = SizeOf(MonSpritesMulBuf);
asm
  cmp Options.MonSpritesSizeMul, 0
  jz @std
	mov eax, offset MonSpritesMulBuf
@loop:  // copy to buf
	mov ecx, [edi]
	mov [eax], ecx
	add eax, 4
	add edi, 4
	cmp eax, offset MonSpritesMulBuf + BufSize
	jnz @loop
	mov edi, offset MonSpritesMulBuf

	// width
	mov eax, [edi + $20]
	imul eax, Options.MonSpritesSizeMul
	sar eax, 16
	mov [edi + $20], eax

	// height
	mov eax, [edi + $24]
	imul eax, Options.MonSpritesSizeMul
	sar eax, 16
	mov [edi + $24], eax

	// U
	mov eax, [edi + $10]
	imul eax, Options.MonSpritesSizeMul
	sar eax, 16
	mov [edi + $10], eax

	// V
	mov eax, [edi + $14]
	imul eax, Options.MonSpritesSizeMul
	sar eax, 16
	mov [edi + $14], eax
@std:
end;

//----- Keep temporary files in memory

const
  SHARE_ALL = FILE_SHARE_DELETE or FILE_SHARE_READ or FILE_SHARE_WRITE;
var
  IsTempFile, IsReadTempFile: Boolean;
  FTempFilesCache: TStringList;

function TempFilesCache: TStringList;
begin
  Result:= FTempFilesCache;
  if Result <> nil then  exit;
  Result:= TStringList.Create;
  Result.CaseSensitive:= false;
  Result.Duplicates:= dupIgnore;
  Result.Sorted:= true;
  FTempFilesCache:= Result;
end;

procedure DelFromCache(lpFileName: PChar);
var
  i: int;
begin
  with TempFilesCache do
    if Find(lpFileName, i) then
    begin
      CloseHandle(THandle(Objects[i]));
      Delete(i);
    end;
end;

function CreateTempFileProc(lpFileName: PChar; dwDesiredAccess, dwShareMode: DWORD;
  lpSecurityAttributes: PSecurityAttributes; dwCreationDisposition, dwFlagsAndAttributes: DWORD;
  hTemplateFile: THandle): THandle; stdcall;
begin
  IsTempFile:= false;
  DelFromCache(lpFileName);
  Result:= CreateFile(lpFileName, dwDesiredAccess, SHARE_ALL,
     lpSecurityAttributes, dwCreationDisposition,
     FILE_ATTRIBUTE_TEMPORARY or FILE_FLAG_DELETE_ON_CLOSE, hTemplateFile);
  // save handle duplicate to avoid immediate deletion
  if Result <> INVALID_HANDLE_VALUE then
  begin
    TempFilesCache.AddObject(lpFileName, ptr(Result));
    RSWin32Check(DuplicateHandle(GetCurrentProcess, Result, GetCurrentProcess,
       @Result, 0, false, DUPLICATE_SAME_ACCESS));
  end;
end;

procedure CreateFileHook;
asm
  cmp IsTempFile, false
  jnz CreateTempFileProc
  cmp IsReadTempFile, false
  jz @std
  mov dword ptr [esp + 12], SHARE_ALL
  mov IsReadTempFile, false
@std:
  jmp CreateFile
end;

procedure SetTempFile;
asm
  mov IsTempFile, true
  jmp eax
end;

procedure SetReadTempFile;
asm
  mov IsReadTempFile, true
  jmp eax
end;

procedure SetReadTempFileDel;
asm
  mov IsReadTempFile, true
  push eax
  mov eax, [esp + 8]
  push ecx
  call DelFromCache
  pop ecx
end;

function DeleteFileHook(lpFileName: PAnsiChar): BOOL; stdcall;
begin
  DelFromCache(lpFileName);
  Result:= DeleteFileA(lpFileName);
end;

procedure NoGammaPcxHook(var _,__, b: TLoadedPcx; h, w: int; buf: ptr);
begin
  b.WHProduct:= w*h;
  b.w:= w;
  b.h:= h;
  b.Bits:= b.Bits or 1;
  b.Buf:= buf;
end;

//----- Buffer house animations, don't restart

type
  TSmkStruct = packed record
    Version: int;
    Width: int;
    Height: int;
  end;
  TSmackToBufferParams = record
    smk: ^TSmkStruct;
    x, y, w2, h: int;
    buf: PChar;
  end;

var
  HouseAnimBuf: array of Word;
  HouseAnimParams: TSmackToBufferParams;

procedure CopyHouseAnimation(reverse: Boolean); inline;
var
  p, p0: PChar;
  i: uint;
begin
  with HouseAnimParams do
  begin
    p:= buf + y*w2 + x*2;
    p0:= ptr(HouseAnimBuf);
    for i:= smk.Height downto 1 do
    begin
      if reverse then
        CopyMemory(p0, p, smk.Width*2)
      else
        CopyMemory(p, p0, smk.Width*2);
      inc(p0, smk.Width*2);
      inc(p, w2);
    end;
  end;
end;

procedure SmackToBufferProc(var params: TSmackToBufferParams);
begin
  HouseAnimParams:= params;
  with params do
  begin
    SetLength(HouseAnimBuf, smk^.Width*smk^.Height);
    CopyHouseAnimation(true);
    x:= 0;
    y:= 0;
    w2:= smk.Width*2;
    h:= smk.Height;
    buf:= ptr(HouseAnimBuf);
  end;
end;

procedure SmackToBufferHook;
asm
  lea eax, [esp + 4]
  jmp SmackToBufferProc
end;

procedure SmackDoFrameHook;
begin
  CopyHouseAnimation(false);
end;

//----- Fix monsters dealing Ener damage type

procedure FixMonEnergyDamage;
asm
  cmp eax, 'n'
  jnz @std
  mov ecx, 12
  xchg ecx, [esp + 4]
  add [esp], 3
@std:
end;

//----- Fix FireAr and Rock missiles

function FixMonMissilesProc(_, s, s2: PChar): int; cdecl;
begin
  if _strcmpi(s, s2) = 0 then
    Result:= 0
  else if _strcmpi(s, 'FireAr') = 0 then
    Result:= 2+1
  else if _strcmpi(s, 'Rock') = 0 then
    Result:= 6+1  // Use Earth, because there's no Rock projectile
  else
    Result:= 1;
end;

procedure FixMonMissiles;
asm
  call FixMonMissilesProc
  lea edi, [eax - 1]  // if no matches are found, this will be used
end;

//----- Monster spells were broken

procedure FixMonsterSpells;
asm
  mov dx, [ebp + $C]
  mov [ebp - m7*$23 - m8*$1F], dx
end;

//----- Fix monsters' Shrapmetal spread

procedure FixShrapmetal;
asm
  movzx edx, ax
end;

//----- All spells were doing Fire damage in MM6

procedure FixMonsterSpellsMM6;
asm
  dec eax
  jz @mine
  xor eax, eax
  ret
@mine:
  movzx eax, byte ptr [edi + 78]
  imul eax, $1C
  add eax, [$42C992]
  movzx eax, byte ptr [eax + $18]
  add [esp], 3
end;

//----- Check for 10MB+ before allowing saving

procedure FreeSpaceCheck;
const
  Msg = 'Unable to save the game due to insufficient disk space.'#13#10
    + 'Please press Alt+Tab and free up some space, then press Retry.';
  MinSpace = 10*1024*1024;
var
  FreeSpace: Int64;
begin
  while GetDiskFreeSpaceEx('Data', FreeSpace, int64(nil^), nil) and (FreeSpace <= MinSpace) do
    case RSMessageBox(_MainWindow^, Msg, SCaption, MB_ICONERROR or MB_ABORTRETRYIGNORE or MB_DEFBUTTON2) of
      ID_IGNORE: break;
      ID_ABORT: ExitProcess(0);
    end;
end;

//----- Don't show sprites from another side of the map with increased FOV

procedure FixSpritesWrapAround;
const
  CameraX = m7*$507B60 + m8*$519438;
  CameraY = CameraX + 4;
  CameraDir = CameraX + $18;
asm
  push eax
  movsx eax, word ptr [esi - 6]  // sprite Y
  sub eax, [CameraY]
  jnl @ch1
  neg eax
@ch1:
  cmp eax, $ffff - 22528  // 43007 max dist_mist
  jg @skip
  movsx eax, word ptr [esi - 8]  // sprite X
  sub eax, [CameraX]
  jnl @ch2
  neg eax
@ch2:
  cmp eax, $ffff - 22528
  jng @ok
@skip:
  mov dword ptr [esp + 4], m7*$47BC54 + m8*$47AF43
@ok:
  pop eax
end;

//----- Another crash due to facets without vertexes

procedure NoVertexHook;
asm
  cmp byte ptr [ebx + _FacetOff_VertexCount], 0
  jnz @ok
  xor eax, eax
  mov [esp], m6*$491A0D + m7*$42451D + m8*$42298C
@ok:
end;

//----- Souldrinker was hitting monsters beyond party range

procedure FixSouldrinkerHook;
const
  range: Single = 5120;
asm
  fld range
end;

//----- Acid Burst doing physical damage

procedure FixAcidBurst;
asm
  cmp dword ptr [esp + $24 - 8], 29
  jnz @std
  mov byte ptr [edi], 2
@std:
end;

//----- Spells that couldn't be cast by monsters before

procedure FixMonSpellCast;
asm
	mov edx, 3
	cmp ecx, 7   // Fire Spike
	jz @proj
	cmp ecx, 32  // Ice Blast
	jz @proj
	cmp ecx, 37  // Deadly Swarm
	jz @proj
	cmp ecx, 76  // Flying Fist
	jz @proj
	cmp ecx, 87  // Sunray
	jnz @std
@proj:
	mov [esp], $40551D
@std:
end;

//----- Unable to equip sword or dagger when non-master spear is equipped

procedure EquipOnSpearHook;
const
  ItemType = m7*$468FDC + m8*$467460 - 5;
asm
  push eax
  add eax, [ItemType]
  cmp byte ptr [eax + 1], 4
  jnz @std
  push edx
  push ecx
  push 4
  mov ecx, ebx
  call _Character_GetSkillWithBonuses
  cmp ax, $80
  pop ecx
  pop edx
  jnb @std
{$IFDEF mm7}
  mov [ebp - $10], ecx
{$ELSE}
  mov [ebp - $C], edi
{$ENDIF}
@std:
  pop eax
end;

//----- Fix Arcomage hanging

procedure FixArcomage;
const
  MouseEvent = m7*$505720 + m8*$516D78;
asm
  cmp dword ptr [MouseEvent], 0
  jnz @ok
{$IFDEF mm7}
  mov edx, ebp
{$ELSE}
  mov edx, [ebp - 4]
{$ENDIF}
  mov [esp], m7*$40DC42 + m8*$40EF85
@ok:
end;

//----- Fix damage kind from walking on water

procedure FixWaterWalkDamage;
asm
  mov edx, Options.WaterWalkDamage
  mov [esp + 8], edx
  jmp eax
end;

//----- Fix +Bow skill items not affecting damage on GM

procedure FixBowSkillDamageBonus7;
asm
  lea ecx, [edi - $112]
  push 5
  call _Character_GetSkillWithBonuses
end;

procedure FixBowSkillDamageBonus8;
asm
  lea ecx, [ebx - $382]
  push 5
  call _Character_GetSkillWithBonuses
end;

procedure FixBowSkillDamageBonusStat;
asm
  mov ecx, esi
  push 5
  call _Character_GetSkillWithBonuses
end;

//----- Fix full brightness for a minute at 5:00 AM

procedure FixBright5AM;
asm
  mov eax, [__TimeMinute]
  mov [ecx + m6*$7C264 + m7*$1C288 + m8*$23A7C], eax
end;

//----- Fix copyright screen staying visible on startup

procedure FixStartupCopyright;
begin
  if GetForegroundWindow = _MainWindow^ then
    PostMessage(_MainWindow^, WM_ACTIVATEAPP, 1, GetCurrentThreadId);
  WaitMessage;
end;

//----- Play horseman/boatman sounds just enough time

procedure TravelDelayHook1;
asm
  mov Options.LastSoundSample, 0
end;

procedure TravelDelayHook2;
asm
  mov eax, [esp + 4]
  mov Options.LastSoundSample, eax
end;

procedure TravelDelayHook3;
asm
@loop:
  mov eax, Options.LastSoundSample
  test eax, eax
  jz @stop // no sound
  push eax
  call ds:[m6*$4B9278 + m7*$4D82F8 + m8*$04E83B4] // AIL_sample_status
  cmp eax, 2 // stopped?
  jnz @cont
  push 10*(1 - m8) // wait a little bit after the sample ends before playing the clicking sound
  call Sleep
  ret
@cont:
  push 1
  call Sleep // important for PlayMP3, good in any case
{$IFDEF MM6}
  call edi
  cmp eax, esi
  jb @loop
{$ELSE}
  {$IFDEF MM7}
    call esi
  {$ELSE}
    call ebp
  {$ENDIF}
  cmp eax, edi
  jnb @stop
  mov [esp], m7*$4B6B91 + m8*$4B51F6 // continue loop
{$ENDIF}
@stop:
end;

//----- Fix awards not updating when pressing Tab

procedure UpdateAfterTab;
const
  _UpdateAwards: TProcedure = ptr(m6*$415160 + m7*$4190A9);
begin
  if (_CurrentScreen^ in [7, 14]) and (_CurrentCharScreen^ = 102) then
    _UpdateAwards;
end;

//----- Fix random item generation

procedure FixItemGeneration;
asm
{$IFDEF mm6}
  inc edx
{$ELSE}
  inc ebx
{$ENDIF}
end;

//----- Fix cubs

procedure FixClubs;
asm
  cmp eax, _Skill_Club
  jnz @std
  mov eax, 6  // Mace delay and sound
@std:
end;

//----- Fix buff duration display

function DoFixBuffTime(var time: int64): int64;
var
  n, left: int;
begin
  Result:= time*15 div 64;
  left:= Result mod (60*60*24);
  n:= 0;  // number of numbers displayed - need to show only 2
  if left <> Result then  // has days
    n:= 1;
  if left >= 60*60 then  // has hours
    inc(n);
  left:= left mod (60*60);
  if (n < 2) and (left >= 60) then  // has minutes
  begin
    inc(n);
    left:= left mod 60;
  end;
  if n < 2 then  // has seconds
    left:= 0;
  Result:= Result - left;
end;

procedure FixBuffTime;
asm
  lea eax, [esp + $30 - 8*m6 + 4 + 4]
  jmp DoFixBuffTime
end;

//----- Fix removed objects reappearing when dropping one on the ground or saving
//(Elemental Mod does it, but I haven't been able to reproduce the bug, at least in MM6)

//procedure FixSummonObject;
//asm
//{$IFDEF mm6}
//  cmp edx, dword ptr [__ObjectsCount]
//{$ELSE}
//  cmp ebx, dword ptr [__ObjectsCount]
//{$ENDIF}
//end;

//----- Fix potion explosions breaking hardened items

procedure FixPotionBreakItem;
asm
  test dword ptr [eax], $200
  jnz @skip
  or dword ptr [eax], 2
@skip:
end;

//----- Fix monsters under Berserk hitting party from a far if their target died
//(preserve targets of monsters in the 'MeleeAttack' state in real time mode)

const
  _pMonTargets = m7*$401E6E + m8*$401EA2 - 4;

procedure FixBerserkHitParty;
asm
  jz @std
  cmp ax, 2
  jnz @std
  mov [esp], m7*$401C8B + m8*$401CBA
@std:
end;

procedure FixBerserkHitParty2; // assumes FixMonsterAttackCorpse is active
asm
  cmp word ptr [ebx + _MonOff_AIState], 2
  jnz @std
  cmp dword ptr [edx], 0
  jz @std
  cmp dword ptr [edx], 4
  jz @std
  ret 4
@std:
  mov [edx], 4
  jmp eax
end;

procedure FixBerserkHitParty3; // reset on map load
var
  i: int;
begin
  for i := 0 to _MonstersCount^ - 1 do
    pint(pint(_pMonTargets)^ + i*4)^:= 0;
end;

//----- Fix monsters attacking corpses
//(leave 1 frame between ending a blow to a monster and starting a new one)

procedure DoFixMonsterAttackCorpse(p: PChar);
begin
  pint2(p + _MonOff_AIState)^:= 1;
  pint2(p + _MonOff_CurrentActionStep)^:= max(0, pint2(p + _MonOff_CurrentActionLength)^ - 1);
end;

procedure FixMonsterAttackCorpse;
asm
  mov eax, [_pMonTargets]
  mov eax, [eax + esi*4]
  and eax, 7
  cmp eax, 3
  jnz @std  // not hitting a monster
  mov eax, ebx
  mov [esp], m7*$402606 + m8*$4026DD
  jmp DoFixMonsterAttackCorpse
@std:
end;

//----- Fix Light Bolt no x2 damage to Undead

procedure FixLightBolt;
const
  IsMonOfKind: int = m7*$438BCE + m8*$436542;
asm
{$IFDEF mm7}
  cmp dword ptr [ebx + $48], 78
{$ELSE}
  cmp dword ptr [edi + $48], 78
{$ENDIF}
  jnz @std
  push eax
  movzx ecx, word ptr [esi + m7*96 + m8*106]
  mov edx, 1  // undead
  call IsMonOfKind
  test eax, eax
  pop eax
  jz @std
  sal eax, 1
@std:
end;

//----- Fix LeaveMap event not called on travel

procedure FixCallLeaveMap;
const
  OnLeaveMap: int = m7*$443FB8 + m8*$440DBC;
asm
  push ecx
  push edx
  call OnLeaveMap
  pop edx
  pop ecx
end;

//----- Fix monsters summoning causing a crash

procedure FixMonstersSummon;
asm
  push eax
  mov eax, [__MonstersCount]
  cmp eax, [__MonstersSummonLimit]
  jl @ok
  pop eax
@ok:
end;

//----- Fix reading of Body attack type of monsters

procedure FixMonstersBodyAttack;
asm
	cmp eax, 'b'
	jnz @std
	mov eax, 8
	mov [esp], m7*$454DA6 + m8*$45258D
@std:
end;

//----- Fix Water Walk draining mana every 5 minutes instead of 20

function CheckNoWaterWalkDrain: Boolean;
const
  step = 20*256;
begin
  Result:= (_Time^ div step) = (_LastRegenTime^ div step);
end;

procedure FixWaterWalkManaDrain;
asm
  jnz @std
  push eax
  push edx
  call CheckNoWaterWalkDrain
  test al, al
  pop edx
  pop eax
@std:
end;

//----- Keep wands without charges

procedure EmptyWandProc;
asm
{$IFDEF mm6}
  or [eax+128h + $14], 2
{$ELSEIF defined(MM7)}
  or [eax + $14], 2
{$ELSE}
  or [edx + $14], 2
{$IFEND}
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
  ret

@bad:
  pop edx
  xor eax, eax
  ret 8 + 4*m8
end;

//----- Show Energy damage type in monster info

procedure FixIdMonEnergyDamage;
asm
  cmp eax, 10
  jna @std
  mov edx, SEnergy
  mov [esp + 4], edx
@std:
end;

//----- Fix "Nothing here" after a simple message dialog

procedure FixNothingHere;
asm
  test ecx, ecx
  jnz @ok
  pop eax
  ret 4
@ok:
end;

//----- Don't cancel simple message dialog after any input

procedure DontSkipSimpleMessage;
begin
  if not (_TextInput^ in [' ', #13, #10, #0]) then
  begin
    _TextInput^:= #0;
    _TextInputChar^:= 0;
  end;
end;

//----- HooksList

var
  HooksCommon: array[1..77] of TRSHookInfo = (
    (p: m6*$453ACE + m7*$463341 + m8*$461316; newp: @UpdateHintHook;
       t: RShtCallStore; Querry: hqFixStayingHints), // Fix element hints staying active in some dialogs
    (p: m6*$4226F8 + m7*$427E71 + m8*$4260A8; newp: @FixItemSpells;
       t: RShtAfter; size: 7 - m6), // Fix item spells when cast onto item with index 0
    (p: m6*$487496 + m7*$492A50 + m8*$49135D; newp: @FixRemoveInvItemPlayer;
       t: RShtJmp; size: 7 - m7*2), // Fix item picture change causing inventory corruption
    (p: m6*$41ECEF + m7*$420AEA + m8*$420078; newp: @FixRemoveInvItemChest;
       t: RShtJmp; size: 7), // Fix item picture change causing inventory corruption
    (p: m6*$42022C + m7*$421E12 + m8*$420E14; size: 6 - m7*4;
       Querry: hqInactivePlayersFix), // Inactive characters couldn't interact with chests (6-7) + allow selecting them regularly
    (p: m6*$42C4CE + m7*$433EB9 + m8*$4316B2; newp: @InactivePlayerActFix;
       t: RShtBefore; size: 6; Querry: hqInactivePlayersFix), // Inactive players could attack
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
    (p: m6*$420C3E + m7*$422559 + m8*$421774; newp: @ASpellClickMon;
       t: RShtAfter; size: 8; Querry: hqAttackSpell), // Attack spell
    (p: m6*$42AE57 + m7*$42FCC3 + m8*$42E608; newp: @ShooterCheckKeyHook;
       t: RShtAfter; Querry: hqShooterMode), // Shooter mode
    (p: HookEachTick; newp: @ShooterEachTickHook; t: RShtBefore; Querry: hqShooterMode), // Shooter mode
    (p: m6*$42273E + m7*$427EC4 + m8*$4260FB; newp: @ShooterCheckMon;
       t: RShtCallStore; Querry: hqShooterMode), // Shooter mode - Monster_CanAct
    (p: m6*$42A010 + m7*$42ED94 + m8*$42D91D; newp: @ShooterCheckMon;
       t: RShtCallStore; Querry: hqShooterMode), // Shooter mode - Monster_CanAct
    (p: m6*$42270C + m7*$427E97 + m8*$4260CE; newp: @ShooterFindMon;
       t: RShtCallStore; Querry: hqShooterMode), // Shooter mode - FindClosestMonster
    (p: m6*$42A024 + m7*$42EDA9 + m8*$42D932; newp: @ShooterFindMon;
       t: RShtCallStore; Querry: hqShooterMode), // Shooter mode - FindClosestMonster
    (p: m6*$42276C + m7*$427EF1 + m8*$426128; newp: @ShooterCheckMonDirection;
       t: RShtAfter; size: 5 + m6; Querry: hqShooterMode), // Shooter mode - CalcMissileDirection
    (p: m6*$454801 + m7*$464366 + m8*$4623E9; newp: @ShooterRightClick;
       t: RShtCallStore; Querry: hqShooterMode), // Shooter mode - ignore right click
    (p: m7*$43951B + m8*$436EF2; newp: @ShooterSetSwordMonHook;
       t: RShtBefore; size: 12; Querry: hqShooterMode), // Shooter mode - last hit monster
    (p: m6*$42A730 + m7*$42F5C9 + m8*$42E05C; newp: @ShooterCreateProjectile;
       t: RShtBefore; size: 6; Querry: hqShooterMode), // Shooter mode - shoot from screen middle
    (p: m6*$42A024 + m7*$42EDA9 + m8*$42D932; newp: @FixAttackMonster;
       t: RShtCallStore), // Attacking friendly monsters
    (p: m7*$4395F5 + m8*$436FC3; newp: @HookHitDistantMonster;
       t: RShtCall; size: 6; Querry: hqFixHitDistantMonstersIndoor), // Fix shooting distant monsters indoor
    (p: m6*$431E27 + m7*$43A38A + m8*$437EA1; newp: @FixZeroRecovery;
       t: RShtCallStore), // Fix character switch when Endurance eliminates hit recovery
    (p: m6*$4320C3 + m7*$43A8B0 + m8*$438341; newp: @FixZeroRecovery;
       t: RShtCallStore), // Fix character switch when Endurance eliminates hit recovery
    (p: m6*$416716 + m7*$41A49E + m8*$41A4A0; newp: @RMBColorItems;
       t: RShtAfter; size: 7; Querry: hqGreenItemsWhileRightClick), // Show items in green while right mouse buttom is pressed
    (p: m6*$42B197 + m7*$4300AF + m8*$42E855; newp: @FixQSpellPointsCheck;
       t: RShtBefore; size: 6 + m6), // Fix wrong Quick Spell spell points check
    (p: m6*$41C58E + m7*$41D96A + m8*$41CEF0; newp: @FixDeadIdentifyItemProc;
       t: RShtCall; Querry: hqFixDeadIdentifyItem), // Unconscious players identifying items in shop screens and on map
    (p: m6*$411049 + m7*$4169FD + m8*$4162A5; newp: @DeadShowItemInfoProc;
       t: RShtCall; size: 6 - m6; Querry: hqDeadShowItemInfo), // Show item descriptions even for unconscious players
    (p: m6*$41104E + m7*$416A03 + m8*$4162AB; newp: ptr(m6*$4110A8 + m7*$416A81 + m8*$416323);
       t: RShtJmp; size: 6; Querry: hqDeadShowItemInfo), // Show item descriptions even for unconscious players
    (p: m6*$430CD9 + m7*$4392F0 + m8*$436CB3; newp: @MonsterIsAliveHook;
       t: RShtCall), // AOE damage wasn't dealt to paralyzed monsters
    (p: m6*$41CFED + m7*$41E51A + m8*$41DAF8; newp: @MonSpritesSizeSW;
       t: RShtBefore; size: 6 - m6), // Monster sprites size multiplier SW
    (p: m6*$41D06A + m7*$41E52A + m8*$41DB08; newp: @MonSpritesSizeSW2;
       t: RShtBefore; size: 5 + m6*3), // Monster sprites size multiplier SW
    (p: m6*$44F3D9 + m7*$45F4E0 + m8*$45CFA7; newp: @FreeSpaceCheck;
       t: RShtBefore; Querry: hqCheckFreeSpace), // Check for 10MB+ before allowing saving
    (p: m6*$4919B6 + m7*$423B32 + m8*$421F9C; newp: @NoVertexHook;
       t: RShtBefore; size: m6*7 + m7*5 + m8*6), // Another crash due to facets without vertexes
    (p: m6*$4155D2 + m7*$4194F2 + m8*$419141; size: 2 + m8*4), // Don't hide skills that overflow
    (p: m6*$4881DF + m7*$494139 + m8*$49236F; old: $86; new: $84;
      t: RSht1), // New Day wasn't triggered on beginning of a month when resting until down and pressing Esc
    (p: m6*$47BFE1 + m7*$4892D0 + m8*$488BE7; newp: @FixBright5AM;
      t: RShtBefore), // Fix full brightness for a minute at 5:00 AM
    (p: m6*$49D8DD + m7*$4B6AEE + m8*$4B51A8; newp: @TravelDelayHook1;
      t: RShtBefore; size: 6 - m8), // Horseman and boatman automatic speaking time
    (p: m6*$48EF7A + m7*$4AABEE + m8*$4A9141; newp: @TravelDelayHook2;
      t: RShtBefore; size: 6), // Horseman and boatman automatic speaking time
    (p: m6*$49D9E1 + m7*$4B6BA6 + m8*$4B520B; newp: @TravelDelayHook3;
      t: RShtCall; size: 6), // Horseman and boatman automatic speaking time
    (p: m6*$448A33 + m7*$45685E + m8*$4540CF; newp: @FixItemGeneration;
      t: RShtAfter; size: 6 + m6*2), // Fix random item generation
    (p: m7*$42F0E2 + m8*$42DB91; newp: @FixClubs;
      t: RShtAfter; size: 7), // Fix clubs having no sound
    (p: m7*$48E27C + m8*$48D70B; newp: @FixClubs;
      t: RShtBefore; size: 8; Querry: hqFixClubsDelay), // Fix clubs having no delay
    (p: m6*$41A2F3 + m7*$41D1B9 + m8*$41C5F4; size: 4), // Fix buff duration display
    (p: m6*$41A2FE + m7*$41D1C1 + m8*$41C5FB; size: 6), // Fix buff duration display
    (p: m6*$41A309 + m7*$41D1CF + m8*$41C60A; newp: @FixBuffTime; t: RShtCall), // Fix buff duration display
    (p: m6*$41A472 + m7*$41D2CE + m8*$41C709; size: 2), // Fix buff duration display
    (p: m6*$41A4DE + m7*$41D30D + m8*$41C748; size: 2), // Fix buff duration display
//    (p: m6*$42A74B + m7*$42F5F0 + m8*$42E083; newp: @FixSummonObject;
//      t: RShtCall; size: 6), // Fix removed objects reappearing when dropping one on the ground or saving
    (p: m7*$41617B + m8*$415636; size: 10), // Fix potion explosions breaking hardened items
    (p: m7*$41619F + m8*$41565A; size: 3), // Fix potion explosions breaking hardened items
    (p: m7*$416198 + m8*$415653; newp: @FixPotionBreakItem;
      t: RShtAfter; size: 7), // Fix potion explosions breaking hardened items
    (p: m7*$43B2D1 + m8*$438EEC; old: $4E; new: $4F; t: RSht1), // When a monster used a spell vs another one, wrong spell was used in damage calculation
    (p: m7*$43B2E2 + m8*$438EDB; old: $4E; new: $4F; t: RSht1), // When a monster used a spell vs another one, wrong spell was used in damage calculation
    (p: m7*$401C5F + m8*$401C8E; newp: @FixBerserkHitParty;
      t: RShtAfter; size: 7), // Fix monsters under Berserk hitting party from a far if their target died
    (p: m7*$401E76 + m8*$401EAF; newp: @FixBerserkHitParty2;
      t: RShtCallStore), // Fix monsters under Berserk hitting party from a far if their target died
    (p: HookMapLoaded*(1 - m6); newp: @FixBerserkHitParty3;
      t: RShtBefore), // Fix monsters under Berserk hitting party from a far if their target died
    (p: m7*$4021A2 + m8*$4021F0; newp: @FixMonsterAttackCorpse;
      t: RShtAfter), // Fix monsters attacking corpses (required by FixBerserkHitParty)
    (p: m7*$43976B + m8*$437150; newp: @FixLightBolt;
      t: RShtBefore; size: 7; Querry: hqFixLightBolt), // Fix Light Bolt no x2 damage to Undead
    (p: m6*$401910 + m7*$401B74 + m8*$401B9B; old: 5 - 4*m6; newp: @Options.ArmageddonElement;
      newref: true; t: RSht1; Querry: -1), // Fix Armageddon dealing unresistable damage
    (p: m6*$4019A9 + m7*$401BFB + m8*$401C28; old: 5 - 4*m6; newp: @Options.ArmageddonElement;
      newref: true; t: RSht1; Querry: -1), // Fix Armageddon dealing unresistable damage
    (p: m7*$44FD55 + m8*$44D4A3; newp: @FixMonstersSummon;
      t: RShtFunctionStart; size: 6), // Fix monsters summoning causing a crash
    (p: m7*$454D9A + m8*$452580; newp: @FixMonstersBodyAttack;
      t: RShtBefore), // Fix reading of Body attack type of monsters
    (p: m7*$47445B + m8*$4732E7; old: $C1; new: $41;
      t: RSht1; Querry: hqClimbBetter), // Climb mountains better
    (p: m6*$487AF9 + m7*$493A02 + m8*$491DAD; newp: @FixWaterWalkManaDrain;
      t: RShtAfter; size: 7; Querry: hqFixWaterWalkManaDrain), // Fix Water Walk draining mana every 5 minutes instead of 20
    (p: m6*$47EF5C + m7*$48D3CC + m8*$48CCD4; newp: @SNotAvailable;
      newref: true; t: RSht4), // Fix Water Walk draining mana every 5 minutes instead of 20
    (p: m6*$429FC3 + m7*$42ED4F + m8*$42D8E7; newp: @EmptyWandProc;
      t: RShtCall; size: 8 + 4*m6; Querry: hqKeepEmptyWands), // Keep wands without charges
    (p: m6*$42A184 + m7*$42F077 + m8*$42DB17; old: $8F0F; new: $E990;
      t: RSht2; Querry: hqKeepEmptyWands), // Keep wands without charges
    (p: m6*$42A31B + m7*$42EEAE;
      size: 12 + 2*m7; Querry: hqKeepEmptyWands), // Keep wands without charges
    (p: m7*$4270B9 + m8*$4254BA; newp: @FixUnimplementedSpells;
      t: RShtBefore; size: 6; Querry: hqFixUnimplementedSpells), // Monsters can't cast some spells, but waste turn
    (p: m7*$49DB05 + m8*$49AFCD; size: 2), // Windows 10 incompatibility
    (p: m7*$41EF8F + m8*$41E500; newp: @FixIdMonEnergyDamage;
      t: RShtAfter; size: 7), // Show Energy damage type in monster info
    (p: m7*$44530E + m8*$442504; newp: @FixNothingHere;
      t: RShtCallBefore), // Fix "Nothing here" after a simple message dialog
    (p: m6*$43AA82 + m7*$44519A; newp: @DontSkipSimpleMessage; t: RShtBefore;
      size: 6 + m7; Querry: hqDontSkipSimpleMessage), // Don't cancel simple message dialog after any input
    ()
  );
{$IFDEF MM6}
  Hooks: array[1..88] of TRSHookInfo = (
    (p: $457567; newp: @WindowWidth; newref: true; t: RSht4; Querry: hqWindowSize), // Configure window size
    (p: $45757D; newp: @WindowHeight; newref: true; t: RSht4; Querry: hqWindowSize), // Configure window size
    (p: $454340; newp: @WindowProcHook; t: RShtFunctionStart; size: 8), // Window procedure hook
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
    (p: $419F63; newp: @KeyControlCheckInvis; t: RShtBefore; size: 6), // Don't allow using invisible topics with keyboard
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
    (p: $430E72; newp: @AttackMonHook; t: RShtAfter; size: 7), // Attacking dying monsters
    (p: $42A4D0; newp: @AttackMonHook2; t: RShtCall; size: 6), // Attacking dying monsters
    (p: $4091B7; newp: @AttackMonHook2; t: RShtAfter; size: 6), // Attacking dying monsters
    (p: $47F8C6; newp: @NegativeResHook; t: RShtBefore; size: 6), // Negative resistance may lead to devision by zero
    (p: $4B6511; newp: @CreateFileHook; t: RShtCall; size: 6), // Keep temporary files in memory
    (p: $4AF6D2; newp: @DeleteFileHook; t: RShtCall; size: 6), // Keep temporary files in memory
    (p: $44FEDE; newp: @SetTempFile; t: RShtCallStore), // Keep temporary files in memory (lloyd)
    (p: $40D179; newp: @SetReadTempFile; t: RShtCallStore), // Keep temporary files in memory (lloyd)
    (p: $44F91C; newp: @SetReadTempFile; t: RShtCallStore), // Keep temporary files in memory (lloyd)
    (p: $4A68B3; newp: ptr($4A68D3); t: RShtJmp; Querry: hqFixHouseAnimationRestart), // Buffer house animations, don't restart
    (p: $4A6577; newp: @SmackToBufferHook; t: RShtBefore; size: 6), // Buffer house animations, don't restart
    (p: $4A60E5; newp: @SmackDoFrameHook; t: RShtAfter; size: 6), // Buffer house animations, don't restart
    (p: $4581C5; old: $2000; newp: @dist_mist; newref: true; t: RSht4), // dist_mist
    (p: $431D8A; newp: @FixMonsterSpellsMM6; t: RShtCall; Querry: hqFixMonsterSpells), // All spells were doing Fire damage
    (p: $43201A; newp: @FixMonsterSpellsMM6; t: RShtCall; Querry: hqFixMonsterSpells), // All spells were doing Fire damage
    (p: $450A2B; newp: @FixStartupCopyright; t: RShtCall; size: 6), // Fix copyright screen staying visible on startup
    (p: $42DFBF; newp: @UpdateAfterTab; t: RShtAfter), // Fix awards not updating when pressing Tab
    ()
  );
{$ELSEIF defined(MM7)}
  Hooks: array[1..135] of TRSHookInfo = (
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
    (p: $41CFA8; newp: @KeyControlCheckInvis; t: RShtBefore; size: 6), // Don't allow using invisible topics with keyboard
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
    (p: $4C0739; newp: @CheckSpriteD3D; t: RShtBefore; Querry: hqClickThruEffectsD3D), // Click through effects D3D
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
    (p: $43951B; newp: @FixFarMonstersAppearGreen; t: RShtBefore; size: 12), // Fix monsters shot at from a distance appearing green on minimap
    (p: $450657; newp: @FixUnmarkedArtifacts; t: RShtBefore; Querry: hqFixUnmarkedArtifacts), // Fix deliberately generated artifacts not marked as found
    (p: $48DF0C; newp: @FixMonStealDisplay; t: RShtAfter; size: 6), // Don't show stealing animation if nothing's stolen
    //(p: $426D46; size: 12), // Demonstrate recovered stolen items
    (p: $426D49; newp: @FixStolenLootHint; t: RShtCallStore), // Show that stolen item was found
    (p: $426D61; size: 7), // Stolen items enabling multi-loot
    (p: $426D95; size: 7), // Stolen items enabling multi-loot
    (p: $441E26; newp: @MinimapBkgHook; t: RShtCall; Querry: hqMinimapBkg), // Draw bitmap as dungeon minimap background
    (p: $422698; newp: @InterfaceColorChangedHook; t: RShtBefore), // Load alignment-dependant interface
    (p: $412B5B; newp: @DrawSpellBook; t: RShtAfter; Querry: hqAttackSpell), // Attack spell
    (p: $48D506; old: $84; new: $8E; t: RSht1), // Negative resistance may lead to devision by zero
    (p: $4BDAE3; newp: @FixDeadDisplayInventory; t: RShtCallStore), // Display Inventory screen didn't work with unconscious players
    (p: $439E71; old: $439FA3; newp: @FixItemsAssassinsBarbarians; t: RShtJmp6), // Fix Assassins' and Barbarians' enchantments
    (p: $455DD6; old: $4CAAF0; newp: @FixMonstersSpellGM; t: RShtCall), // Fix 'GM' not being read in Monsters.txt
    (p: $455EEC; old: $4CAAF0; newp: @FixMonstersSpellGM; t: RShtCall), // Fix 'GM' not being read in Monsters.txt
    (p: $454B8E; newp: @IceBoltBlastFix; t: RShtBefore; Querry: hqFixIceBoltBlast), // Monsters.txt - Fix 'Ice Bolt' turning into 'Ice Blast'
    (p: $41E5E6; newp: @MonSpritesSizeHW; t: RShtBefore; size: 6), // Monster sprites size multiplier D3D
    (p: $41E649; newp: @MonSpritesSizeSW2; t: RShtBefore; size: 6), // Monster sprites size multiplier D3D
    (p: $4D4C8F; newp: @CreateFileHook; t: RShtCall; size: 6), // Keep temporary files in memory
    (p: $4CCC18; newp: @DeleteFileHook; t: RShtCall; size: 6), // Keep temporary files in memory
    (p: $45E2C1; newp: @SetTempFile; t: RShtCallStore), // Keep temporary files in memory (lloyd)
    (p: $411B8E; newp: @SetReadTempFile; t: RShtCallStore), // Keep temporary files in memory (lloyd)
    (p: $45FA0C; newp: @SetReadTempFile; t: RShtCallStore), // Keep temporary files in memory (lloyd)
    (p: $432B2D; size: $432B47 - $432B2D), // Don't save gamma.pcx
    (p: $432B4C; old: $40E56A; newp: @NoGammaPcxHook; t: RShtCall), // Don't save gamma.pcx
    (p: $434983; size: $43499D - $434983), // Don't save gamma.pcx
    (p: $4349A2; old: $40E56A; newp: @NoGammaPcxHook; t: RShtCall), // Don't save gamma.pcx
    //(p: $4BF533; newp: ptr($4BF586); t: RShtJmp; Querry: hqFixHouseAnimationRestart), // Buffer house animations, don't restart
    (p: $4BF559; newp: ptr($4BF586); t: RShtJmp; size: 10; Querry: hqFixHouseAnimationRestart), // Buffer house animations, don't restart
    (p: $4BF31E; newp: @SmackToBufferHook; t: RShtBefore; size: 6; Querry: hqFixHouseAnimationRestart), // Buffer house animations, don't restart
    (p: $4BF06E; newp: @SmackDoFrameHook; t: RShtAfter; size: 6; Querry: hqFixHouseAnimationRestart), // Buffer house animations, don't restart
    (p: $4BF011; old: $4BE8BD; new: $4BF02F; t: RShtJmp; Querry: hqFixHouseAnimationRestart), // Buffer house animations, don't restart
    (p: $454D3A; newp: @FixMonEnergyDamage; t: RShtAfter; Querry: hqFixMonsterAttackTypes), // Fix monsters dealing Ener damage type
    (p: $454E89; newp: @FixMonMissiles; t: RShtCall; Querry: hqFixMonsterAttackTypes), // Fix FireAr and Rock missiles
    //(p: $466528 + m8*$4648D5; old: $2000; new: 10500; t: RSht4), // Default dist_mist
    (p: $404AF0; newp: @FixMonsterSpells; t: RShtBefore; Querry: hqFixMonsterSpells), // Monster spells were broken
    (p: $40583A; t: RShtNop; size: 4; Querry: hqFixMonsterSpells), // Monster spells were broken
    (p: $404F99; t: RShtNop; size: 4; Querry: hqFixMonsterSpells), // Monster spells were broken
    (p: $40570B; newp: @FixShrapmetal; t: RShtBefore; Querry: hqFixMonsterSpells), // Fix monsters' Shrapmetal spread
    (p: $47BB77; newp: @FixSpritesWrapAround; t: RShtBefore; size: 7), // Don't show sprites from another side of the map with increased FOV
    (p: $42E4F0; old: $43642D; newp: @FixSouldrinkerHook; t: RShtCall; Querry: hqFixSouldrinker), // Souldrinker was hitting monsters beyond party range
    (p: $453A31; old: $453AE6; newp: @FixAcidBurst; t: RShtBeforeJmp6), // Acid Burst doing physical damage
    (p: $404B02; newp: @FixMonSpellCast; t: RShtBefore), // Spells that couldn't be cast by monsters before
    (p: $468FCF; newp: @EquipOnSpearHook; t: RShtAfter; size: 6), // Unable to equip sword or dagger when non-master spear is equipped
    (p: $469037; size: $469041 - $469037), // Unable to equip sword or dagger when non-master spear is equipped
    (p: $40DC7F; newp: @FixArcomage; t: RShtAfter; size: 6), // Fix Arcomage hanging
    (p: $49431F; newp: @FixWaterWalkDamage; t: RShtCallStore), // Fix kind damage from walking on water
    (p: $48D2C2; newp: @FixBowSkillDamageBonus7; t: RShtBefore), // Fix +Bow skill items not affecting damage on GM
    (p: $48D15E; newp: @FixBowSkillDamageBonusStat; t: RShtCall; size: 6), // Fix +Bow skill items not affecting damage on GM
    (p: $48D1CB; newp: @FixBowSkillDamageBonusStat; t: RShtCall; size: 6), // Fix +Bow skill items not affecting damage on GM
    (p: $462B21; newp: @FixStartupCopyright; t: RShtCall; size: 6), // Fix copyright screen staying visible on startup
    (p: $433259; newp: @UpdateAfterTab; t: RShtAfter), // Fix awards not updating when pressing Tab
    (p: $433324; newp: @FixCallLeaveMap; t: RShtCallBefore), // Fix LeaveMap event not called on travel
    (p: $44800F; newp: @FixCallLeaveMap; t: RShtCallBefore), // Fix LeaveMap event not called on travel
    (p: $44C30F; newp: @FixCallLeaveMap; t: RShtCallBefore), // Fix LeaveMap event not called on travel
    (p: $4B6A96; newp: @FixCallLeaveMap; t: RShtCallBefore), // Fix LeaveMap event not called on travel
    ()
  );
{$ELSE}
  FogRange: int;
  FogRangeFloat, FogRangeMul, FogRangeMul2: Single;

  Hooks: array[1..134] of TRSHookInfo = (
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
    (p: $41C419; newp: @KeyControlCheckInvis; t: RShtBefore; size: 6), // Don't allow using invisible topics with keyboard
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
    (p: $4BE327; newp: @CheckSpriteD3D; t: RShtBefore; Querry: hqClickThruEffectsD3D), // Click through effects D3D
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
    (p: $436EF2; newp: @FixFarMonstersAppearGreen; t: RShtBefore; size: 12), // Fix monsters shot at from a distance appearing green on minimap
    (p: $48D396; newp: @FixMonStealDisplay; t: RShtAfter; size: 6), // Don't show stealing animation if nothing's stolen
    //(p: $425182; size: 12), // Demonstrate recovered stolen items
    (p: $425185; newp: @FixStolenLootHint; t: RShtCallStore), // Show that stolen item was found
    (p: $42519D; size: 7), // Stolen items enabling multi-loot
    (p: $4251D1; size: 7), // Stolen items enabling multi-loot
    (p: $43EA7C; newp: @MinimapBkgHook; t: RShtCall; Querry: hqMinimapBkg), // Draw bitmap as dungeon minimap background
    (p: $4CA240; newp: @ASpellHintMM8; t: RShtAfter; Querry: hqAttackSpell), // Attack spell
    (p: $48CE11; old: $74; new: $7E; t: RSht1), // Negative resistance may lead to devision by zero
//    (p: $4E9BA4; newp: @SpellBookHoverItem; t: RShtCodePtrStore), // Quick Spell buttons hints
    (p: $4BB6EA; newp: @FixDeadDisplayInventory; t: RShtCallStore), // Display Inventory screen didn't work with unconscious players
    (p: $4379A0; old: $437AE8; newp: @FixItemsAssassinsBarbarians; t: RShtJmp6), // Fix Assassins' and Barbarians' enchantments
    (p: $4535E2; old: $4DA920; newp: @FixMonstersSpellGM; t: RShtCall), // Fix 'GM' not being read in Monsters.txt
    (p: $4536FC; old: $4DA920; newp: @FixMonstersSpellGM; t: RShtCall), // Fix 'GM' not being read in Monsters.txt
    (p: $4522F6; newp: @IceBoltBlastFix; t: RShtBefore; Querry: hqFixIceBoltBlast), // Monsters.txt - Fix 'Ice Bolt' turning into 'Ice Blast'
    (p: $41DBC8; newp: @MonSpritesSizeHW; t: RShtBefore; size: 6), // Monster sprites size multiplier D3D
    (p: $41DC30; newp: @MonSpritesSizeSW2; t: RShtBefore; size: 6), // Monster sprites size multiplier D3D
    (p: $4E3C8B; newp: @CreateFileHook; t: RShtCall; size: 6), // Keep temporary files in memory
    (p: $4DB1E8; newp: @DeleteFileHook; t: RShtCall; size: 6), // Keep temporary files in memory
    (p: $45BF4A; newp: @SetTempFile; t: RShtCallStore), // Keep temporary files in memory (lloyd)
    (p: $412976; newp: @SetReadTempFile; t: RShtCallStore), // Keep temporary files in memory (lloyd)
    (p: $45D44F; newp: @SetReadTempFile; t: RShtCallStore), // Keep temporary files in memory (lloyd)
    (p: $432233; size: $432250 - $432233), // Don't save gamma.pcx
    (p: $432255; old: $40F835; newp: @NoGammaPcxHook; t: RShtCall), // Don't save gamma.pcx
    (p: $43225B; size: 5), // Don't save gamma.pcx
    (p: $45D46E; old: $4F91C0; new: $4F36D4; t: RSht4), // Fix Llloyd names mismatch
    (p: $45D439; old: $4F917C; new: $4F36E4; t: RSht4), // Fix Llloyd names mismatch
    (p: $45C93A; old: $4F917C; new: $4F36E4; t: RSht4), // Fix Llloyd names mismatch
    (p: $461167; old: $4F917C; new: $4F36E4; t: RSht4), // Fix Llloyd names mismatch
    (p: $4642CB; old: $4F917C; new: $4F36E4; t: RSht4), // Fix Llloyd names mismatch
    (p: $45C937; old: $57; new: $50; t: RSht1), // Fix Llloyd names mismatch
    //(p: $4BD173; newp: ptr($4BD1DC); t: RShtJmp; size: 10; Querry: hqFixHouseAnimationRestart), // Buffer house animations, don't restart
    (p: $4BD19C; newp: ptr($4BD1DC); t: RShtJmp; size: 6; Querry: hqFixHouseAnimationRestart), // Buffer house animations, don't restart
    (p: $4BCF5F; newp: @SmackToBufferHook; t: RShtBefore; size: 6; Querry: hqFixHouseAnimationRestart), // Buffer house animations, don't restart
    (p: $4BCCA1; newp: @SmackDoFrameHook; t: RShtAfter; size: 6; Querry: hqFixHouseAnimationRestart), // Buffer house animations, don't restart
    (p: $4BCC36; old: $4BC4D8; new: $4BCC62; t: RShtJmp; Querry: hqFixHouseAnimationRestart), // Buffer house animations, don't restart
    (p: $45251F; newp: @FixMonEnergyDamage; t: RShtAfter; Querry: hqFixMonsterAttackTypes), // Fix monsters dealing Ener damage type
    (p: $452670; newp: @FixMonMissiles; t: RShtCall; Querry: hqFixMonsterAttackTypes), // Fix FireAr and Rock missiles
    //(p: $4648D5; old: $2000; new: 10500; t: RSht4), // Default dist_mist
    (p: $47B7AB; old: 14192; newp: @FogRange; newref: true; t: RSht4; Querry: hqViewDistance), // Extend view distance
    (p: $4E87AC; newp: @FogRangeFloat; newref: true; t: RSht4; Querry: hqViewDistance), // Extend view distance
    (p: $4E87A8; newp: @FogRangeMul; newref: true; t: RSht4; Querry: hqViewDistance), // Extend view distance
    (p: $4E87A4; newp: @FogRangeMul2; newref: true; t: RSht4; Querry: hqViewDistance), // Extend view distance
    (p: $404D8C; newp: @FixMonsterSpells; t: RShtBefore; Querry: hqFixMonsterSpells), // Monster spells were broken
    (p: $404E45; t: RShtNop; size: 4; Querry: hqFixMonsterSpells), // Monster spells were broken
    (p: $405895; t: RShtNop; size: 4; Querry: hqFixMonsterSpells), // Monster spells were broken
    (p: $40531F; newp: @FixShrapmetal; t: RShtBefore; size: 8; Querry: hqFixMonsterSpells), // Fix Shrapmetal spread
    (p: $47AE66; newp: @FixSpritesWrapAround; t: RShtBefore; size: 7), // Don't show sprites from another side of the map with increased FOV
    (p: $42C730; old: $433D70; newp: @FixSouldrinkerHook; t: RShtCall; Querry: hqFixSouldrinker), // Souldrinker was hitting monsters beyond party range
    (p: $45119B; old: $451250; newp: @FixAcidBurst; t: RShtBeforeJmp6), // Acid Burst doing physical damage
    (p: $467453; newp: @EquipOnSpearHook; t: RShtAfter; size: 6), // Unable to equip sword or dagger when non-master spear is equipped
    (p: $4674BB; size: $4674C5 - $4674BB), // Unable to equip sword or dagger when non-master spear is equipped
    (p: $40EFC3; newp: @FixArcomage; t: RShtAfter; size: 6), // Fix Arcomage hanging
    (p: $406015+7; old: $13; new: 0; t: RSht1), // Let monsters cast Fire Spike
    (p: $406015+37; old: $13; new: 0; t: RSht1), // Let monsters cast Deadly Swarm
    (p: $406015+76; old: $13; new: 0; t: RSht1), // Let monsters cast Flying Fist
    (p: $49270A; newp: @FixWaterWalkDamage; t: RShtCallStore), // Fix damage kind from walking on water
    (p: $48CBED; newp: @FixBowSkillDamageBonus8; t: RShtBefore), // Fix +Bow skill items not affecting damage on GM
    (p: $48CA86; newp: @FixBowSkillDamageBonusStat; t: RShtCall; size: 6), // Fix +Bow skill items not affecting damage on GM
    (p: $48CAEE; newp: @FixBowSkillDamageBonusStat; t: RShtCall; size: 6), // Fix +Bow skill items not affecting damage on GM
    (p: $430BC3; newp: @FixCallLeaveMap; t: RShtCallBefore), // Fix LeaveMap event not called on travel
    (p: $445335; newp: @FixCallLeaveMap; t: RShtCallBefore), // Fix LeaveMap event not called on travel
    (p: $4B52F5; newp: @FixCallLeaveMap; t: RShtCallBefore), // Fix LeaveMap event not called on travel
    ()
  );
{$IFEND}

procedure ApplyHooks(Querry: int);
begin
  RSApplyHooks(HooksCommon, Querry);
  RSApplyHooks(Hooks, Querry);
end;

procedure CheckMMHooks;
begin
  CheckHooks(HooksCommon);
  CheckHooks(Hooks);
end;

procedure ApplyMMHooks;
begin
  ApplyHooks(0);
  if BorderlessFullscreen then
    ApplyHooks(hqBorderless);
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
  if FixInactivePlayersActing then
    ApplyHooks(hqInactivePlayersFix);
  if Options.ShooterMode <> 0 then
    ApplyHooks(hqShooterMode);
  if FixHitDistantMonstersIndoor then
    ApplyHooks(hqFixHitDistantMonstersIndoor);
  if GreenItemsWhileRightClick then
    ApplyHooks(hqGreenItemsWhileRightClick);
  if ClickThroughEffects then
    ApplyHooks(hqClickThruEffectsD3D);
  if FixDeadPlayerIdentifyItem then
    ApplyHooks(hqFixDeadIdentifyItem);
  if DeadPlayerShowItemInfo then
    ApplyHooks(hqDeadShowItemInfo);
  if FixHouseAnimationRestart then
    ApplyHooks(hqFixHouseAnimationRestart);
  if NeedFreeSpaceCheck then
    ApplyHooks(hqCheckFreeSpace);
  ApplyBytePatches;
end;

procedure ApplyMMDeferredHooks;
begin
  ApplyHooks(-1);
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
  if Options.FixIceBoltBlast then
    ApplyHooks(hqFixIceBoltBlast);
  if Options.FixMonsterAttackTypes then
    ApplyHooks(hqFixMonsterAttackTypes);
  if Options.FixMonsterSpells then
    ApplyHooks(hqFixMonsterSpells);
  if Options.FixSouldrinker then
    ApplyHooks(hqFixSouldrinker);
  if Options.FixUnmarkedArtifacts then
    ApplyHooks(hqFixUnmarkedArtifacts);
  if Options.FixClubsDelay then
    ApplyHooks(hqFixClubsDelay);
  if Options.FixLightBolt then
    ApplyHooks(hqFixLightBolt);
  if Options.ClimbBetter then
    ApplyHooks(hqClimbBetter);
  if Options.FixWaterWalkManaDrain then
    ApplyHooks(hqFixWaterWalkManaDrain);
  if Options.KeepEmptyWands then
    ApplyHooks(hqKeepEmptyWands);
  if Options.FixUnimplementedSpells then
    ApplyHooks(hqFixUnimplementedSpells);
  if Options.DontSkipSimpleMessage then
    ApplyHooks(hqDontSkipSimpleMessage);
end;

procedure ApplyMMHooksSW;
begin
  if ClickThroughEffects then
    ApplyHooks(hqClickThruEffects);
end;

procedure ApplyMMHooksLodsLoaded;
begin
  if not _IsD3D^ then
    ApplyMMHooksSW;
end;

procedure OnLoaded;
begin
{$IFNDEF MM6}
  if dist_mist > 0 then
    _dist_mist^:= dist_mist;
  OnLoadedD3D;
{$ENDIF}
{$IFDEF MM8}
  if _dist_mist^ > $2000 then
  begin
    FogRange:= min(_dist_mist^ + 6000, $7fff);
    FogRangeFloat:= _dist_mist^ + 6000;
    FogRangeMul:= 1/(FogRangeFloat - 1024);
    FogRangeMul2:= 216/(FogRangeFloat - 1024);
    ApplyHooks(hqViewDistance);
  end;
{$ENDIF}
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
var
  i: int;
begin
  with _IconsLodLoaded^ do
    if (m6 = 0) and (Count < 1000) and (_DoLoadLodBitmap(0,0, _IconsLod, 2, 'mapbkg', Items[Count]) <> -1) then
    begin
      MinimapBkgBmp:= Count;
      inc(Count);
      ApplyHooks(hqMinimapBkg);
    end;
  if Options.EnableAttackSpell and (m6 = 1) then
  begin
    ASpellIcon:= LoadIcon('GF-ASpell');
    ASpellIconDn:= ASpellIcon;
  end;
  if Options.EnableAttackSpell and (m7 = 1) then
    ASpellIconDn:= LoadIcon('GF-ASpellD');
  if Options.ShooterMode <> 0 then
    for i := 0 to high(ShooterSwordIcons) do
      ShooterSwordIcons[i]:= LoadIcon(ShooterSwordIconNames[i]);

  OnLoaded;
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
      i:= LoadIcon(s + Letter);
  end;
begin
  if Options.EnableAttackSpell then
    Bmp(ASpellIcon, 'GF-ASpell-');
end;

var
  ScreenDirty, TurnBased: Boolean;

procedure DrawMyInterface;
begin
  if _CurrentScreen^ = 0 then
  begin
    if Options.ShooterMode = fpsOn then
      ScreenDirty:= DrawShooter or ScreenDirty
    else if ScreenDirty and (m6 = 0) then
      _NeedRedraw^:= 1;
    if (m7 = 1) and TurnBased and not _TurnBased^ then
      _NeedRedraw^:= 1;  // fix hand staying sometimes
    if m7 = 1 then
      TurnBased:= _TurnBased^;
  end;
  if _NeedRedraw^ <> 0 then
    ScreenDirty:= false;
end;

initialization
finalization
  if EmptyCur <> 0 then
    DestroyCursor(EmptyCur);
end.
