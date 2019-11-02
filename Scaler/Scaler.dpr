library Scaler;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  SysUtils, Classes, RSQ, RSSysUtils, Windows, Messages, Math, IniFiles,
  Graphics, Forms,
  HookSupport in 'HookSupport.pas';

{$R *.res}

var
  ScaleMul: int = 1;
  ScaleDiv: int = 1;
  MenuDelta: int;
  OuterWnd, InnerWnd: HWND;
  StdOuterWndProc, StdWndProc: ptr;
  BaseRect: TRect;
  BlackBackground: Boolean = true;
  NonIntegerScaling, OnlyControls, Windowed, WndMax, HasMenu, MenuFocus: Boolean;

procedure Scale(var x, y, w, h: int);
var
  mul: int absolute ScaleMul;
  d: int absolute ScaleDiv;
  x1, y1: int;
begin
  x1:= RDiv(x*mul, d);
  y1:= RDiv(y*mul, d);
  w:= RDiv((x + w)*mul, d) - x1;
  h:= RDiv((y + h)*mul, d) - y1;
  x:= x1;
  y:= y1;
end;

function MyBlt(DestDC: HDC; X, Y, Width, Height: Integer; SrcDC: HDC;
  XSrc, YSrc: Integer; Rop: DWORD): BOOL; stdcall;
var
  mul: int absolute ScaleMul;
  d: int absolute ScaleDiv;
  r: TRect;
  w, h: int;
begin
  if WindowFromDC(DestDC) <> InnerWnd then
  begin
    Result:= BitBlt(DestDC, X, Y, Width, Height, SrcDC, XSrc, YSrc, Rop);
    exit;
  end;
  if ScaleDiv <> 1 then
  begin
    GetClipBox(SrcDC, r);
    if XSrc + Width < r.Right then
      inc(Width);
    if XSrc > r.Left then
    begin
      dec(XSrc);
      dec(X);
      inc(Width);
    end;
    if YSrc + Height < r.Bottom then
      inc(Height);
    if YSrc > r.Top then
    begin
      dec(YSrc);
      dec(Y);
      inc(Height);
    end;
  end;
  w:= Width;
  h:= Height;
  Scale(X, Y, Width, Height);
  Result:= StretchBlt(DestDC, X, Y, Width, Height, SrcDC, XSrc, YSrc, w, h, Rop);
end;

function MyStretchBlt(DestDC: HDC; X, Y, Width, Height: Integer; SrcDC: HDC;
  XSrc, YSrc, SrcWidth, SrcHeight: Integer; Rop: DWORD): BOOL; stdcall;
begin
  if WindowFromDC(DestDC) <> InnerWnd then
  begin
    Result:= StretchBlt(DestDC, X, Y, Width, Height, SrcDC, XSrc, YSrc, SrcWidth, SrcHeight, Rop);
    exit;
  end;
  if (ScaleDiv <> 1) and (Width = SrcWidth) and (Height = SrcHeight) then
  begin
    Result:= MyBlt(DestDC, X, Y, Width, Height, SrcDC, XSrc, YSrc, Rop);
    exit;
  end;
  Scale(X, Y, Width, Height);
  Result:= StretchBlt(DestDC, X, Y, Width, Height, SrcDC, XSrc, YSrc, SrcWidth, SrcHeight, Rop);
end;

function MyInvalidateRect(hWnd: HWND; lpRect: PRect; bErase: BOOL): BOOL; stdcall;
begin
  if hWnd = InnerWnd then
    lpRect:= nil;
  Result:= InvalidateRect(hWnd, lpRect, bErase);
end;

function MySetWindowPos(wnd: HWND; hWndInsertAfter: HWND;
  X, Y, cx, cy: Integer; uFlags: UINT): BOOL; stdcall;
var
  mul: int absolute ScaleMul;
  d: int absolute ScaleDiv;
  r: TRect;
  s: string;
  w: HWND;
begin
  if (wnd = InnerWnd) and (uFlags and (SWP_NOSIZE + SWP_NOMOVE) <> (SWP_NOSIZE + SWP_NOMOVE)) then
  begin
    GetClientRect(OuterWnd, r);
    with r.BottomRight, BaseRect do
    begin
      cx:= RDiv(Right*mul, d);
      cy:= RDiv(Bottom*mul, d);
      Result:= SetWindowPos(wnd, 0, (X - cx) div 2, (Y - cy) div 2, cx, cy, SWP_NOZORDER or SWP_NOACTIVATE);
      InvalidateRect(wnd, nil, false);
    end;
  end else
    if (wnd <> OuterWnd) and (wnd <> InnerWnd) then
    begin
      w:= GetParent(wnd);
      if (w = OuterWnd) or (w = InnerWnd) then
      begin
        s:= TRSWnd(wnd).ClassName;
        if s = 'ComboBox' then
        begin
          if GetProp(wnd, 'Scaler.LastScaledWidth') <> uint(cx) then
          begin
            Scale(X, Y, cx, r.Top);
            SetProp(wnd, 'Scaler.LastScaledWidth', cx);
          end else
            Scale(X, Y, r.Top, r.Top);
        end
        else if s <> 'msctls_updown32' then
          Scale(X, Y, cx, cy);
      end;
      Result:= SetWindowPos(wnd, hWndInsertAfter, X, Y, cx, cy, uFlags);
    end else
      Result:= SetWindowPos(wnd, hWndInsertAfter, X - RDiv(cx*(mul - d), 2*d), Y - RDiv(cy*(mul - d), 2*d),
         RDiv(cx*mul, d), RDiv(cy*mul, d), uFlags);
end;

function MyCreateWindowExA(dwExStyle: DWORD; lpClassName: PAnsiChar;
  lpWindowName: PAnsiChar; dwStyle: DWORD; X, Y, nWidth, nHeight: Integer;
  hWndParent: HWND; hMenu: HMENU; hInstance: HINST; lpParam: Pointer): HWND; stdcall;
begin
  if (hWndParent = OuterWnd) or (hWndParent = InnerWnd) then
    Scale(X, Y, nWidth, nHeight);
  Result := CreateWindowExA(dwExStyle, lpClassName, lpWindowName, dwStyle,
    X, Y, nWidth, nHeight, hWndParent, hMenu, hInstance, lpParam);
end;

procedure Rescale(var x: int; const old: TPoint);
begin
  x:= RDiv(RDiv(x*old.Y, old.X)*ScaleMul, ScaleDiv);
end;

function RescaleChild(wnd: HWND; const old: TPoint): Bool; stdcall;
var
  r: TRect;
  h: int;
begin
  Result:= true;
  GetWindowRect(wnd, r);
  MapWindowPoints(0, InnerWnd, r, 2);
  h:= RectH(r);
  Rescale(r.Left, old);
  Rescale(r.Top, old);
  Rescale(r.Right, old);
  if TRSWnd(wnd).ClassName = 'ComboBox' then
  begin
    r.Bottom:= r.Top + h;
    SetProp(wnd, 'Scaler.LastScaledWidth', RectW(r));
  end else
    Rescale(r.Bottom, old);
  SetWindowPos(wnd, 0, r.Left, r.Top, RectW(r), RectH(r), SWP_NOZORDER or SWP_NOACTIVATE);
end;

procedure Resized;
var
  mul: int absolute ScaleMul;
  d: int absolute ScaleDiv;
  r: TRect;
  old: TPoint;
begin
  if IsIconic(OuterWnd) then
    exit;
  GetClientRect(OuterWnd, r);
  with r.BottomRight, BaseRect do
  begin
    old.X:= ScaleMul;
    old.Y:= ScaleDiv;
    if NonIntegerScaling then
    begin
      if Right*Y > Bottom*X then
      begin
        ScaleMul:= X;
        ScaleDiv:= Right;
      end else
      begin
        ScaleMul:= Y;
        ScaleDiv:= Bottom;
      end;
      ScaleDiv:= max(1, ScaleDiv);
      if (ScaleMul mod ScaleDiv = 0) or (ScaleMul < ScaleDiv) then
      begin
        ScaleMul:= ScaleMul div ScaleDiv;
        ScaleDiv:= 1;
      end;
      ScaleMul:= max(1, ScaleMul);
    end else
      ScaleMul:= max(1, min(X div Right, Y div Bottom));
    MySetWindowPos(InnerWnd, 0, 0, 0, 0, 0, SWP_NOZORDER or SWP_NOACTIVATE);
    if ScaleMul <> old.X then
      EnumChildWindows(InnerWnd, @RescaleChild, int(@old));
    InvalidateRect(OuterWnd, nil, false);
    InvalidateRect(InnerWnd, nil, false);
  end;
end;

var
  WndPos: TPoint;

procedure SwitchMenu;
begin
  if MenuDelta = 0 then
    exit;
  if SetWindowPos(OuterWnd, 0, WndPos.X, WndPos.Y + max(0, MenuDelta), 0, 0, SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE) then
    MenuDelta:= -MenuDelta;
end;

var
  SkipAltPress: Boolean;

procedure ProcessAlt(msg: UINT; wp: WPARAM);
begin
  if (msg = WM_SYSKEYDOWN) and (wp <> VK_ALT) and (MenuDelta > 0) then
    SkipAltPress:= true;
  if (msg = WM_SYSKEYUP) and (wp = VK_ALT) then
    if not SkipAltPress then
    begin
      if (MenuDelta < 0) or not MenuFocus then
        SwitchMenu
      else
        MenuFocus:= false;
    end else
      SkipAltPress:= false;
end;

function MyOuterWndProc(w: HWND; msg: UINT; wp: WPARAM; lp: LPARAM): LRESULT; stdcall;
var
  r: TRect;
  dc: HDC;
begin
  if msg = WM_GETMINMAXINFO then
  begin
    if HasMenu then
    begin
      GetWindowRect(w, r);
      ScreenToClient(w, r.TopLeft);
      MenuDelta:= -r.Top;
      with PMinMaxInfo(lp)^ do
      begin
        inc(ptMaxSize.Y, MenuDelta);
        inc(ptMaxTrackSize.Y, MenuDelta);
        dec(ptMaxPosition.Y, MenuDelta);
        WndPos:= ptMaxPosition;
      end;
    end;
    Result:= 0;
    exit;
  end;
  Result:= CallWindowProc(StdOuterWndProc, w, msg, wp, lp);
  if (msg = WM_ERASEBKGND) and BlackBackground then
  begin
    dc:= GetDC(OuterWnd);
    GetClipBox(dc, r);
    FillRect(dc, r, GetStockObject(BLACK_BRUSH));
    ReleaseDC(OuterWnd, dc);
  end;
  if msg = WM_ACTIVATE then
    SwitchMenu;
  if msg = WM_SIZE then
    Resized;
  if msg = WM_MENUSELECT then
  begin
    MenuFocus:= true;
    if MenuDelta > 0 then
      SwitchMenu;
  end;
  ProcessAlt(msg, wp);
end;

function MouseTranslate(x: int): int; inline;
begin
  Result:= (x*2 + 1)*ScaleDiv div (ScaleMul*2);
end;

function MyWndProc(w: HWND; msg: UINT; wp: WPARAM; lp: LPARAM): LRESULT; stdcall;
var
  xy: TSmallPoint absolute lp;
begin
  if (msg >= WM_MOUSEFIRST) and (msg <= WM_MOUSELAST) then
    with xy do
    begin
      X:= MouseTranslate(X);
      Y:= MouseTranslate(Y);
    end;
  Result:= CallWindowProc(StdWndProc, w, msg, wp, lp);
  ProcessAlt(msg, wp);
end;

function MyGetCursorPos(var p: TPoint): BOOL; stdcall;
var
  p1: TPoint;
begin
  Result:= GetCursorPos(p);
  if not Result then  exit;
  p1.X:= 0;
  p1.Y:= 0;
  if not ClientToScreen(InnerWnd, p1) then  exit;
  p.X:= MouseTranslate(p.X - p1.X) + p1.X;
  p.Y:= MouseTranslate(p.Y - p1.Y) + p1.Y;
end;

var
  Keys: array of array[0..255] of byte;

procedure ReadKeys(ini: TIniFile);
var
  num: array[0..255] of byte;
  used: array[0..255] of Boolean;
  i, k: int;
begin
  if not ini.SectionExists('Controls') then  exit;
  FillChar(num, SizeOf(num), 0);
  FillChar(used, SizeOf(used), 0);
  Keys:= nil;
  for i:= 1 to 255 do
  begin
    k:= ini.ReadInteger('Controls', 'Key' + IntToStr(i), -1);
    used[i]:= (k >= 0);
    if k in [1..255] then
    begin
      if length(Keys) = num[k] then
        SetLength(Keys, num[k] + 1);
      Keys[num[k]][k]:= i;
      inc(num[k]);
    end;
  end;
  for i:= 1 to 255 do
    if not used[i] and (num[i] = 0) then
      Keys[0][i]:= i;
end;

procedure DoReadIni(const path: string);
var
  ini: TIniFile;
begin
  ini:= TIniFile.Create(path);
  with ini do
    try
      Windowed:= ReadBool('Options', 'Windowed', Windowed);
      WndMax:= ReadBool('Options', 'Maximized', WndMax);
      BlackBackground:= ReadBool('Options', 'BlackBackground', BlackBackground);
      NonIntegerScaling:= ReadBool('Options', 'NonIntegerScaling', NonIntegerScaling);
      OnlyControls:= ReadBool('Options', 'OnlyControls', OnlyControls);
      ReadKeys(ini);
    finally
      Free;
    end;
end;

procedure ReadExeIni(const path: string);
begin
  DoReadIni(ExtractFilePath(path) + 'Scaler.ini');
  DoReadIni(ChangeFileExt(path, '.scaler.ini'));
end;

procedure ReadIni;
var
  i: int;
begin
  DoReadIni(ChangeFileExt(RSGetModuleFileName(HInstance), '.ini'));
  ReadExeIni(ParamStr(0));
  for i:= 1 to ParamCount do
    if ParamStr(i) = '/SF' then
    begin
      ReadExeIni(ParamStr(i + 1));
      break;
    end;
end;

type
  TGetKeyState = function(nVirtKey: Integer): SHORT stdcall;

function DoGetKeyState(key: Integer; get: TGetKeyState): SHORT; inline;
var
  i: int;
begin
  Result:= 0;
  if not (key in [1..255]) then  exit;
  for i:= 0 to high(Keys) do
  begin
    if Keys[i][key] = 0 then  break;
    Result:= Result or get(Keys[i][key]);
  end;
end;

function MyGetKeyState(nVirtKey: Integer): SHORT; stdcall;
begin
  Result:= DoGetKeyState(nVirtKey, @GetKeyState);
end;

function MyGetAsyncKeyState(vKey: Integer): SHORT; stdcall;
begin
  Result:= DoGetKeyState(vKey, @GetAsyncKeyState);
end;

function BaseWindowSize(const rm: TRect): Boolean;
var
  r, r2: TRect;
  i, mul, w, h, attr: int;
begin
  GetWindowRect(OuterWnd, r);
  GetClientRect(OuterWnd, r2);
  w:= RectW(rm) - RectW(r) + RectW(r2);
  h:= RectH(rm) - RectH(r) + RectH(r2);
  mul:= max(1, min(w div BaseRect.Right, h div BaseRect.Bottom));
  // after making it resizeable and calling SetWindowPos its size changes, need to repeat the process
  i:= GetWindowLong(OuterWnd, GWL_STYLE);
  attr:= i or WS_MAXIMIZEBOX or WS_SIZEBOX;
  Result:= i <> attr;
  with r do
  begin
    w:= BaseRect.Right*mul - RectW(r2);
    h:= BaseRect.Bottom*mul - RectH(r2);
    if (w = 0) and (h = 0) then
      if Result then
        inc(h)  // make sure it's resized
      else
        exit;
    r:= Rect(Left - w div 2, Top - h div 2, Right + (w+1) div 2, Bottom + (h+1) div 2);
    if Left < rm.Left then
      OffsetRect(r, rm.Left - Left, 0);
    if Right > rm.Right then
      OffsetRect(r, rm.Right - Right, 0);
    if Bottom > rm.Bottom then
      OffsetRect(r, 0, rm.Bottom - Bottom);
    if Top < rm.Top then
      OffsetRect(r, 0, rm.Top - Top);
    if Result then
      SetWindowLong(OuterWnd, GWL_STYLE, attr);
    SetWindowPos(OuterWnd, 0, r.Left, r.Top, RectW(r), RectH(r), SWP_NOZORDER or SWP_NOACTIVATE);
  end;
end;

var
  r: TRect;
  proc: ptr;
begin
  OuterWnd:= GetForegroundWindow;
  if TRSWnd(OuterWnd).ProcessId <> GetCurrentProcessId then  exit;
  InnerWnd:= GetWindow(OuterWnd, GW_CHILD);
  GetClientRect(InnerWnd, BaseRect);

  ReadIni;
  if Keys <> nil then
  begin
    RSLoadProc(proc, user32, 'GetKeyState', false, true);
    ReplaceIATEntryInAllMods(proc, @MyGetKeyState);
    RSLoadProc(proc, user32, 'GetAsyncKeyState', false, true);
    ReplaceIATEntryInAllMods(proc, @MyGetAsyncKeyState);
  end;
  if OnlyControls then
    exit;
  RSLoadProc(proc, gdi32, 'BitBlt', false, true);
  ReplaceIATEntryInAllMods(proc, @MyBlt);
  RSLoadProc(proc, gdi32, 'StretchBlt', false, true);
  ReplaceIATEntryInAllMods(proc, @MyStretchBlt);
  RSLoadProc(proc, user32, 'InvalidateRect', false, true);
  ReplaceIATEntryInAllMods(proc, @MyInvalidateRect);
  RSLoadProc(proc, user32, 'SetWindowPos', false, true);
  ReplaceIATEntryInAllMods(proc, @MySetWindowPos);
  RSLoadProc(proc, user32, 'CreateWindowExA', false, true);
  ReplaceIATEntryInAllMods(proc, @MyCreateWindowExA);
  RSLoadProc(proc, user32, 'GetCursorPos', false, true);
  ReplaceIATEntryInAllMods(proc, @MyGetCursorPos);

  StdOuterWndProc:= ptr(SetWindowLong(OuterWnd, GWL_WNDPROC, int(@MyOuterWndProc)));
  StdWndProc:= ptr(SetWindowLong(InnerWnd, GWL_WNDPROC, int(@MyWndProc)));
  ScaleMul:= 1;
  if Windowed then
  begin
    r:= Screen.MonitorFromWindow(OuterWnd).WorkareaRect;
    if BaseWindowSize(r) then
      BaseWindowSize(r);
    if WndMax then
      SendMessage(OuterWnd, WM_SYSCOMMAND, SC_MAXIMIZE, 0);
  end else
  begin
    HasMenu:= GetMenuItemCount(GetMenu(OuterWnd)) > 0;
    SwitchMenu;
    SetWindowLong(OuterWnd, GWL_STYLE, GetWindowLong(OuterWnd, GWL_STYLE) and not (WS_BORDER + WS_DLGFRAME + WS_SYSMENU + WS_MINIMIZEBOX + WS_MAXIMIZEBOX));
    SetWindowLong(OuterWnd, GWL_EXSTYLE, GetWindowLong(OuterWnd, GWL_EXSTYLE) and not (WS_EX_WINDOWEDGE));
    SendMessage(OuterWnd, WM_SYSCOMMAND, SC_MAXIMIZE, 0);
  end;
  Resized;
end.

