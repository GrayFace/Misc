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
function GetCoordCorrectionIndoorX: ext;
function GetCoordCorrectionIndoorY: ext;
function IsLayoutActive(CanActivate: Boolean = true): Boolean; inline;
procedure NeedWindowSize;
function TransformMousePos(x, y: int; out x1: int): int;
function MyGetAsyncKeyState(vKey: Integer): SHORT; {$IFNDEF MM6}stdcall;{$ENDIF}
function CheckKey(key: int):Boolean;
procedure MyClipCursor;
function LoadMLookBmp(const fname: string; fmt: TPixelFormat): TBitmap;
procedure MLookDrawHD(const p: TPoint);
procedure NeedScreenDraw(var scale: TRSResampleInfo; sw, sh, w, h: int);
procedure DrawScaled(var scale: TRSResampleInfo; sw, sh: int; scan: ptr; pitch: int);
{$IFNDEF MM6}
function FindSprite(Name: PChar): PSprite; overload;
function FindSprite(var sp3d: TSpriteD3D): PSprite; overload;
{$ENDIF}

var
  AllowMovieQuickLoad: Boolean;
  ArrowCur: HCURSOR;

implementation

const
  RingsShown = int(_InventoryRingsShown);
  CurrentScreen = int(_CurrentScreen);
  CurrentMember = int(_CurrentMember);
  NeedRedraw = int(_NeedRedraw);

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
  if _Windowed^ and (msg >= WM_MOUSEFIRST) and (msg <= WM_MOUSELAST) then
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

//----- Mouse Look

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
    x1:= TransformMouseCoord(x, SW, r.Right, MouseDX);
    Result:= TransformMouseCoord(y, SH, r.Bottom, MouseDY);
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

procedure Draw8(ps: PByte; pd: PWord; ds, dd, w, h: int; pal: PWordArray); inline;
var
  x: int;
begin
  dec(ds, w);
  dec(dd, w*2);
  for h:= h downto 1 do
  begin
    for x:= w downto 1 do
    begin
      pd^:= pal[ps^];
      inc(ps);
      inc(pd);
    end;
    inc(PChar(ps), ds);
    inc(PChar(pd), dd);
  end;
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
  p:= _ScreenBuffer^;
  if _CurrentScreen^ <> 15 then
    Draw16(@p[y*640], @p[x - x0 + y*640], 640*2, 640*2, x0 + 1, h, 0, ldkOpaque);
  with _IconsLodLoaded.Items[_LPicTopbar^] do
    Draw8(@Image[x], @p[x], Rec.w, 640*2, Rec.w - x, Rec.h, Palette16);
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
  pop ecx
  cmp dword ptr [RingsShown], 0
  mov eax, $43A363
  jz @norings
  mov eax, $43BB1A
@norings:
  push dword ptr [$F01A64]
  mov dword ptr [$F01A64], 1
  call eax
  pop dword ptr [$F01A64]
  mov eax, ebx
  call DrawPaperDollStuff
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
{$ELSE}
  sub ecx, $22
{$ENDIF}
@ok:
  cmp KeyControlMouseBlocked, 0
end;

procedure KeyControlEnter;
asm
  mov byte ptr [NeedRedraw], 1
  mov [esp], m6*$419F47 + m7*$41D015 + m8*$41C40F
end;

procedure KeyControl;
asm
{$IFDEF mm6}
  cmp edx, $22
{$ENDIF}
  jz KeyControlMouse

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
  if (sk and $100 <> 0) and (Random(60) < sk and $3F) then
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
  Dist = 5000;
var
  sprite: PSprite;
  mul, si, co: ext;
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
  if si < 0 then  // look down
    mul:= min(mul, 1)*0.75*EnsureRange(2 - params.ZBuf/Dist*2, 0, 1)
  else
    mul:= min(mul, 5)*0.35;
  mul:= 1/EnsureRange(1 + mul*si, 0.7, 2);
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
  SinCos(_Party_Angle^*Pi/1024*0.4, si, co); // use 1/3 of the angle
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
    mul:= min(mul, 5)*0.35;
  mul:= 1/EnsureRange(1 + mul*si, 0.7, 2);
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

//----- HooksList

var
{$IFDEF MM6}
  Hooks: array[1..19] of TRSHookInfo = (
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
    (p: $41146D; newp: @EnchantItemRightClick; t: RShtAfter), // Allow right click in item spell dialogs
    (p: $41E092; newp: @ChestVerticalHook6; t: RShtCall; Querry: hqPlaceChestItemsVertically), // Place items in chests vertically
    (p: $41E4D7; newp: @FixChestsCompact; t: RShtAfter; size: 7; Querry: hqFixChestsByCompacting), // Fix chests by compacting
    (p: $46B73E; newp: @SpritesAngleHook6; t: RShtCallStore; Querry: hqSpriteAngleCompensation), // Sprite angle compensation
    (p: $4348BA; newp: @SpritesAngleHook6; t: RShtCallStore; Querry: hqSpriteAngleCompensation), // Sprite angle compensation
    ()
  );
{$ELSEIF defined(MM7)}
  Hooks: array[1..35] of TRSHookInfo = (
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
    ()
  );
{$ELSE}
  Hooks: array[1..31] of TRSHookInfo = (
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
    ()
  );
{$IFEND}

procedure ApplyMMHooks;
begin
  CheckHooks(Hooks);
  RSApplyHooks(Hooks);
  if PlaceChestItemsVertically then
    RSApplyHooks(Hooks, hqPlaceChestItemsVertically);
  if FixChestsByCompacting then
    RSApplyHooks(Hooks, hqFixChestsByCompacting);
  if SpriteAngleCompensation then
    RSApplyHooks(Hooks, hqSpriteAngleCompensation);
end;

procedure ApplyMMDeferredHooks;
begin
  if Options.PaperDollInChests > 0 then
    RSApplyHooks(Hooks, hqPaperDollInChests);
  if Options.PaperDollInChests = 2 then
    RSApplyHooks(Hooks, hqPaperDollInChests2);
  if (Options.PaperDollInChests > 0) and not Options.HigherCloseRingsButton then
    RSApplyHooks(Hooks, hqPaperDollInChestsAndOldCloseRings);
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
  RSApplyHooks(Hooks, hqWindowSize);
end;

end.
