unit LayoutSupport;

interface

uses
  Windows, Messages, SysUtils, Classes, RSSysUtils, RSQ, Common, RSCodeHook,
  Math, MP3, RSDebug, IniFiles, Direct3D, Graphics, MMSystem, RSStrUtils,
  DirectDraw, DXProxy, RSResample, RSGraphics, MMCommon, MMLayout, Types;

{$I MMPatchVer.inc}

type
  TLayoutContextSwap = (lcsMenu, lcsItem);

  TLayoutScale = record
    info: TRSResampleInfo;
    sw, sh: int;
    dest: TRect;
  end;

  TLayoutButtonCanvas = record
    Action, Info1: int;
    IsButton: Boolean;
  end;

  TLayoutSupport = class
  protected
    L: TLayout;
    DL: TDrawLayout;
    ScreenW, ScreenH: int;
    Scale: array of TLayoutScale;
    CanvasUsed: array[3..CanvasMax] of Boolean;
    CanvasUsedRect: array[3..CanvasMax] of TRect;
    CanvasUsedOnScreen: array[3..CanvasMax] of Boolean;
    KeysNeeded: array[VK_F1..VK_F19] of Boolean;
    KeyDepressed: array[VK_F1..VK_F19] of Boolean;
    {$IFDEF MM7}Alignment: int;{$ENDIF}
    DrawIndex: int;
    DestBuf: ptr;
    DestStride: int;
    Drawn: Boolean;
    UpdateCountdown: int;
    DownCanvas, MouseCanvas: int;
    Status: array[0..0] of Word;
    PartyBuffs: array[0..19] of Word;
    CanvasBuf: array[0..1] of array[1..640*480] of Word;
    MLookPos: TPoint;
    LastContextMenu: TRect;
    LastContextMenuAlign: Boolean;
    Ini: TIniFile;
    IniSect: string;
    WasActive, Activated: Boolean;
    LastScreen: int;
    HintAreaTop, HintAreaRight: int;
    class var OnLoad: array of TProcedure;
    function GetMousePos: TPoint;
    function GetContextMenuPos(w, h, scale: int): TRect;
    procedure LoadPcx(const Name: string; var a: TWordDynArray; out w: int);
    procedure LoadIcon(const Name: string; var a: TWordDynArray; out w: int);
    procedure DrawArea(const Item: TLayoutItem; ps: ptr; ds: int);
    procedure CanAdd(var it: TLayoutItem; var add: Boolean);
    procedure BeforeDraw(var Item: TLayoutItem; OnlyVirtual: Boolean);
    procedure DefaultValue(const Name: string; v: ext);
    procedure UnsetVar(const Name: string; write: Boolean);
    procedure LoadIni;
    procedure UpdateClipCursor;
    procedure UpdateRenderRect(const r: TRect);
    procedure UpdateGameStatus;
    procedure Deactivate;
    procedure ReloadLayout;
    procedure UpdateMinMax;
    procedure HintSuppression;
  public
    RenderRect: TRect;
    RenderCenterX, RenderCenterY: ext;
    Updating, ScreenHasRightSide: Boolean;
    CanvasSwapUsed: array[TLayoutContextSwap] of Boolean;
    constructor Create;
    procedure Draw(src, dest: ptr; stride: int);
    procedure MapMouse(var x1, y1: int; x, y, fw, fh: int);
    procedure MouseMessage(msg, wp: int);
    procedure GetMLookCenter(var MCenter, p: TPoint; const r: TRect);
    function CheckClipCursorArea(var r: TRect; NoUpdate: Boolean = false): Boolean;
    function SwapCanvas(item: TLayoutContextSwap): Boolean;
    procedure Sizing(wnd: HWND; side: int; var r: TRect);
    function Update(Rendering: Boolean = false): Boolean;
    procedure Start;
    function Active(CanActivate: Boolean = true): Boolean;
  end;

var
  Layout: TLayoutSupport;

implementation

const
  TextColor: array[-1..1] of Word = (51200, 2048, 25);
  TextShColor: array[-1..1] of Word = (2048, 59064, 65311);

{ TLayoutSupport }

procedure TLayoutSupport.BeforeDraw(var Item: TLayoutItem;
  OnlyVirtual: Boolean);
begin
  if Item.Visible then
    if Item.Canvas = CanvasPopup then
      Item.Visible:= CanvasSwapUsed[lcsMenu]
    else if Item.Canvas = CanvasMouseItem then
      Item.Visible:= CanvasSwapUsed[lcsItem];
end;

procedure TLayoutSupport.CanAdd(var it: TLayoutItem; var add: Boolean);
begin
  if InRange(it.Canvas, low(CanvasUsedRect), high(CanvasUsedRect)) then
  begin
    CanvasUsed[it.Canvas]:= true;
    CanvasUsedRect[it.Canvas]:= it.New;
    CanvasUsedOnScreen[it.Canvas]:= (it.NewCanvas = CanvasScreen);
  end
  else if it.Canvas = CanvasRender then
    RenderRect:= it.New;
  if InRange(it.IfCanvas, low(CanvasUsedRect), high(CanvasUsedRect)) then
    CanvasUsed[it.IfCanvas]:= true;
end;

function TLayoutSupport.CheckClipCursorArea(var r: TRect; NoUpdate: Boolean): Boolean;
var
  p: TPoint;
begin
  if not NoUpdate then  Update;
  self:= Layout;
  p:= r.BottomRight;
  r:= CanvasUsedRect[CanvasLockMouse];
  r.Left:= RDiv(r.Left*p.X, ScreenW);
  r.Right:= RDiv(r.Right*p.X, ScreenW);
  r.Top:= RDiv(r.Top*p.Y, ScreenH);
  r.Bottom:= RDiv(r.Bottom*p.Y, ScreenH);
  Result:= IsRectEmpty(r);
end;

constructor TLayoutSupport.Create;
var
  v1, v2, v3, v4: int;
begin
  DL:= TDrawLayout.Create;
  L:= DL.Layout;
  L.OnCanAdd:= CanAdd;
  L.OnDefaultValue:= DefaultValue;
  L.OnUnsetVar:= UnsetVar;
  DL.OnLoadIcon:= LoadIcon;
  DL.OnDrawArea:= DrawArea;
  DL.OnBeforeDraw:= BeforeDraw;
  DL.AddFixedCanvas(lvcBase, nil, 640, 480);
  DL.AddFixedCanvas(lvcRender, nil, 0, 0);
  DL.AddFixedCanvas(lvcStatus, @Status, length(Status), 1);
  DL.AddFixedCanvas(lvcPopup, @CanvasBuf[0], 640, 480);
  DL.AddFixedCanvas(lvcMouseItem, @CanvasBuf[1], 640, 480);
  DL.AddFixedCanvas(lvcLockMouse, nil, 0, 0);
  DL.AddFixedCanvas(lvcPopupArea, nil, 0, 0);
  DL.AddFixedCanvas(lvcPopupArea2, nil, 0, 0);
  DL.AddFixedCanvas(lvcPartyBuffs, @PartyBuffs, length(PartyBuffs), 1);
  if RSGetModuleVersion(v1, v2, v3, v4) then
    L.Vars[lvVersion]:= v1*10000 + v2*100 + v3;
  L.Vars[lvRenderCenterX]:= 0.5;
  L.Vars[lvRenderCenterY]:= 0.5;
  L.Vars[lvDebug]:= NaN;
  L.Vars[lvFOVMul]:= 1;
end;

procedure TLayoutSupport.Deactivate;
begin
  L.Vars[lvRenderedScreen]:= -1;
  DXProxyMul:= 0;
  Options.RenderRect:= _RenderRect^;
  ViewMulFactor:= 1;
  _ViewMulOutdoor^:= 300;
  ShowTreeHints:= (TreeHintsVal <> 0);
{$IFDEF MM7}
  if _UITextColor^ and $10000 <> 0 then
  begin
    _UITextColor^:= TextColor[Alignment];
    _UITextShadowColor^:= TextShColor[Alignment];
  end;
{$ENDIF}
end;

procedure TLayoutSupport.DefaultValue(const Name: string; v: ext);
var
  i: int;
begin
  if RSStartsStr('Options.', Name, @i) then
    Ini.WriteString(IniSect, Copy(Name, i, MaxInt), FloatToStr(v, FormatSettingsEN));
end;

procedure TLayoutSupport.Draw(src, dest: ptr; stride: int);
begin
  DL.FixedCanvases[0]:= src;
  DestBuf:= dest;
  DestStride:= stride;
  if UpdateCountdown = 1 then
    L.Updated:= false;
  Update;
  self:= Layout;
  LastScreen:= _CurrentScreen^;
  if (_MainMenuCode^ >= 0) or _IsLoadingBig^ or _NoMusicDialog^ then
    LastScreen:= -1;
  UpdateCountdown:= max(0, UpdateCountdown - 1);
  UpdateGameStatus;
  DrawIndex:= 0;
  DL.Draw;
  Drawn:= true;
  if not CanvasSwapUsed[lcsMenu] then
    FillChar(LastContextMenu, SizeOf(LastContextMenu), -1);
  FillChar(CanvasSwapUsed, length(CanvasSwapUsed)*SizeOf(CanvasSwapUsed[lcsItem]), 0);
end;

procedure TLayoutSupport.DrawArea(const Item: TLayoutItem; ps: ptr; ds: int);
var
  info0: TRSResampleInfo;
  pd: PChar;
  r, nr: TRect;
  bw, bh: int;
begin
  if DestBuf = nil then
    exit;
  with Item do
  begin
    if DrawIndex >= length(Scale) then
      SetLength(Scale, DrawIndex + 1);
    with Scale[DrawIndex], info do
    begin
      inc(DrawIndex);
      bw:= RectW(Base);
      bh:= RectH(Base);
      nr:= New;
      pd:= DestBuf;
      case Item.Canvas of
        CanvasMouseItem:
          with GetMousePos do
            OffsetRect(nr, X, Y);
        CanvasPopup:
        begin
          r:= FindContextMenu(ps, TransparentColor16);
          if r.Left < 0 then  exit;
          nr:= GetContextMenuPos(RDiv(RectW(r)*RectW(nr), bw), RDiv(RectH(r)*RectH(nr), bh), RDiv(640*RectW(nr), bw));
          bw:= RectW(r);
          bh:= RectH(r);
          inc(PChar(ps), (r.Top - Base.Top)*ds + (r.Left - Base.Left)*2);
          inc(pd, nr.Top*DestStride + nr.Left*4);
          OffsetRect(nr, -nr.Left, -nr.Top);
        end;
      end;
      if (sw <> bw) or (sh <> bh) or not CompareMem(@Dest, @nr, SizeOf(nr)) then
      begin
        sw:= bw;
        sh:= bh;
        Dest:= nr;
        r:= Rect(0, 0, RectW(nr), RectH(nr));
        RSSetResampleParams(ScalingParam1, ScalingParam2);
        info0.Init(min(r.Right, sw), min(r.Bottom, sh), r.Right, r.Bottom);
        IntersectRect(r, r, Bounds(-nr.Left, -nr.Top, ScreenW, ScreenH));
        info:= info0.ScaleRect(r);
        inc(DestX, nr.Left);
        inc(DestY, nr.Top);
      end;
      if Draw = ldkTransparent then
        RSResampleTrans16_NoAlpha(info, ps, ds, pd, DestStride, DrawColor)
      else
        RSResample16(info, ps, ds, pd, DestStride);
    end;
  end;
end;

function TLayoutSupport.Active(CanActivate: Boolean): Boolean;
begin
  Result:= Activated and _Windowed^;
  if Result <> WasActive then
  begin
    L.Updated:= false;
    if Result then
      if CanActivate then
        Update(false)
      else
        Result:= false  // bugfix for switching to Windowed when not in borderless mode
    else
      Deactivate;
  end;
end;

function TLayoutSupport.GetContextMenuPos(w, h, scale: int): TRect;
const
  baseDist = 23;
  baseSide = 10;
var
  d: int;

  function main(x, w, fw, last: int): int;
  begin
    if (last - w div 2 < 0) or (last + w - w div 2 > fw)
       or (x >= last - w div 2 + d*4) and (x <= last + (w + 1) div 2 - d*4) then
      last:= fw div 2;
    if x >= last then
      if (x >= w + d div 2) or (x >= fw div 2) then
        Result:= max(0, min(fw, x - d) - w)
      else
        Result:= min(fw - w, x + d)
    else
      if (x <= fw - w - d div 2) or (x <= fw div 2) then
        Result:= min(fw - w, max(0, x + d))
      else
        Result:= max(0, x - d - w);
  end;

  function second(x, w, fw, last: int): int;
  var
    d1: int;
  begin
    if (last - w div 2 < 0) or (last + w - w div 2 > fw) or (abs(x - last) > d*5) then
      last:= fw div 2;
    d1:= w div 3;
    dec(last, w div 2);
    if x < last + d1 then
      Result:= max(0, x - d1)
    else if x > last + w - d1 then
      Result:= min(fw - w, x + d1 - w)
    else
      Result:= max(0, min(fw - w, last));
  end;

var
  p: TPoint;
  align: Boolean;
  fw, fh, s: int;
begin
  p:= GetMousePos;
  d:= RDiv(baseDist*scale, 640);
  s:= RDiv(baseSide*scale, 640);
  if IsRectEmpty(CanvasUsedRect[CanvasPopupArea]) then
    Result:= Rect(s, s, ScreenW - s, ScreenH - s)
  else
    Result:= CanvasUsedRect[CanvasPopupArea];
  fw:= RectW(Result);
  fh:= RectH(Result);
  if (RectW(LastContextMenu) = w) and (RectH(LastContextMenu) = h) then
    align:= LastContextMenuAlign
  else if (p.Y < Result.Top) or (p.Y >= Result.Bottom) then
    align:= false
  else if (p.X < Result.Left) or (p.X >= Result.Right) then
    align:= true
  else
    align:= (fw*h >= w*fh);
  if not IsRectEmpty(CanvasUsedRect[CanvasPopupArea2]) then
    with CanvasUsedRect[CanvasPopupArea2] do
      if align then
      begin
        Result.Top:= Top;
        Result.Bottom:= Bottom;
        fh:= RectH(Result);
      end else
      begin
        Result.Left:= Left;
        Result.Right:= Right;
        fw:= RectW(Result);
      end;
  LastContextMenuAlign:= align;
  OffsetRect(LastContextMenu, -Result.Left, -Result.Top);
  with LastContextMenu do
    if align then
    begin
      p.X:= main(p.X - Result.Left, w, fw, (Right + Left) div 2);
      p.Y:= second(p.Y - Result.Top, h, fh, (Top + Bottom) div 2);
    end else
    begin
      p.X:= second(p.X - Result.Left, w, fw, (Right + Left) div 2);
      p.Y:= main(p.Y - Result.Top, h, fh, (Top + Bottom) div 2);
    end;
  if w >= fw then
    p.X:= (fw - w) div 2;
  if h >= fh then
    p.Y:= (fh - h) div 2;
  Result:= Bounds(max(0, p.X + Result.Left), max(0, p.Y + Result.Top), w, h);
  LastContextMenu:= Result;
end;

procedure TLayoutSupport.GetMLookCenter(var MCenter, p: TPoint; const r: TRect);
begin
  Update;
  self:= Layout;
  MCenter:= _ScreenMiddle^;
  if IsRectEmpty(RenderRect) then
  begin
    p.X:= r.Right div 2;
    p.Y:= r.Bottom div 2;
  end else
  begin
    p.X:= Floor(r.Right*RenderCenterX/DXProxyRenderW);
    p.Y:= Floor(r.Bottom*RenderCenterY/DXProxyRenderH);
  end;
  MLookPos:= p;
end;

function TLayoutSupport.GetMousePos: TPoint;
var
  p: TPoint;
  r: TRect;
begin
  if DXProxyCursorX <= 0 then
  begin
    GetCursorPos(p);
    ScreenToClient(_MainWindow^, p);
  end else
    p:= MLookPos;
  GetClientRect(_MainWindow^, r);
  Result.X:= p.X*DXProxyRenderW div r.Right;
  Result.Y:= p.Y*DXProxyRenderH div r.Bottom;
end;

procedure TLayoutSupport.LoadIcon(const Name: string; var a: TWordDynArray;
  out w: int);
var
  bmp: TLoadedBitmap;
  i: int;
begin
  if SameText(ExtractFileExt(Name), '.pcx') then
  begin
    LoadPcx(Name, a, w);
    exit;
  end;
  _LoadBitmapInPlace(0,0, _IconsLod, 2, PChar(Name), bmp);
  with bmp do
  begin
    w:= Rec.w;
    SetLength(a, w*Rec.h);
    for i:= 0 to high(a) do
      a[i]:= Palette16[Image[i]];
  end;
  _free(bmp.Image);
  _free(bmp.Palette16);
end;

procedure TLayoutSupport.LoadIni;
var
  sl: TStringList;
  s: string;
  v: ext;
  i, k: int;
begin
  if Ini = nil then
    Ini:= TIniFile.Create(AppPath + SIni);
  sl:= TStringList.Create;
  with Ini do
    try
      IniSect:= 'UILayout=' + Options.UILayout;
      ReadSectionValues(IniSect, sl);
      for i:= 0 to sl.Count - 1 do
      begin
        s:= sl[i];
        k:= Pos('=', s);
        if RSVal(Copy(s, k + 1, MaxInt), v) then
          L.Vars['Options.' + Copy(s, 1, k - 1)]:= v;
      end;
    finally
      sl.Free;
    end;
end;

procedure TLayoutSupport.LoadPcx(const Name: string; var a: TWordDynArray;
  out w: int);
var
  pcx: TLoadedPcx;
begin
  FillChar(pcx, SizeOf(pcx), 0);
  _LoadPcx(0,0, pcx, 0, PChar(Name));
  w:= pcx.w;
  SetLength(a, w*pcx.h);
  if pcx.Buf = nil then  exit;
  CopyMemory(@a[0], pcx.Buf, length(a)*2);
  _FreePcx(0,0, pcx);
end;

function TransformMouseCoord(x, x1, sw, fw: int; dx: ext): ext;
begin
  Result:= ((x + 0.5)*sw/fw - dx)/DXProxyMul - x1 - 0.5;
end;

procedure TLayoutSupport.MapMouse(var x1, y1: int; x, y, fw, fh: int);
begin
  Update;
  self:= Layout;
  x1:= (x*2 + 1)*ScreenW div (fw*2);
  y1:= (y*2 + 1)*ScreenH div (fh*2);
  if not Drawn then
  begin
    if _ScreenBuffer^ = nil then
      exit;
    DL.FixedCanvases[0]:= _ScreenBuffer^;
    UpdateGameStatus;
    DL.Draw(true);
    Drawn:= true;
  end;
  Options.MouseDX:= 0;
  Options.MouseDY:= 0;
  if not DL.HitTest(x1, y1) then
  begin
    x1:= _ScreenMiddle.X;
    y1:= _ScreenMiddle.Y;
    if not IsRectEmpty(RenderRect) then
    begin
      Options.MouseDX:= TransformMouseCoord(x, x1, ScreenW, fw, DXProxyShiftX);
      Options.MouseDY:= TransformMouseCoord(y, y1, ScreenH, fh, DXProxyShiftY);
    end;
  end
  else if x1 < 0 then
  begin
    x1:= 320;
    y1:= 0;
  end;
end;

procedure TLayoutSupport.MouseMessage(msg, wp: int);
var
  i, c: int;
begin
  c:= 0;
  if (m7*msg = WM_LBUTTONDOWN) or
     (m8*msg = WM_LBUTTONUP) and (DL.MouseCanvas = DL.PressCanvas) then
    c:= DL.MouseCanvas;
  DL.MouseDown:= (wp and 1) <> 0;
  if c > 0 then
    for i:= 0 to high(L.Actions) do
      with L.Actions[i] do
        if Canvas = c then
          AddAction(X, Y, 0);
end;

procedure TLayoutSupport.ReloadLayout;
begin
  if Activated then
  begin
    Deactivate;
    Layout:= TLayoutSupport.Create;
    if FileExists('Data\' + Options.UILayout + '.txt') then
    begin
      Layout.Start;
      Layout.Update;
    end else
      pstring(@Options.UILayout)^:= '';
  end;
  Destroy;
end;

procedure TLayoutSupport.Sizing(wnd: HWND; side: int; var r: TRect);
var
  w, h: int;
begin
  Wnd_Sizing_GetWH(wnd, r, w, h);
  Wnd_Sizing_SetWH(wnd, side, r, max(w, L.MinWidth) - w, max(h, L.MinHeight) - h);
end;

procedure TLayoutSupport.Start;
var
  i: int;
begin
  try
    LoadIni;
    L.Read('Data\' + Options.UILayout + '.txt');
    with TRSFindFile.Create('Data\*.' + Options.UILayout + '.txt') do
      try
        while FindEachFile do
          L.Read(FileName);
      finally
        Free;
      end;
    UpdateMinMax;
  except
    RSShowException;
    Halt;
  end;
  for i:= 0 to high(OnLoad) do
    OnLoad[i]();
end;

procedure TLayoutSupport.HintSuppression;
begin
  if _StatusText.Text[true][0] = #0 then
    exit;
  if (HintAreaTop > 0) and ((HintAreaTop >= 480) or (GameCursorPos^.Y < HintAreaTop)) or
     (HintAreaRight <> 0) and ((HintAreaRight < 0) or (GameCursorPos^.X >= HintAreaRight)) then
  begin
    _StatusText.Text[true][0]:= #0;
    _NeedUpdateStatus^:= true;
  end;
end;

function TLayoutSupport.SwapCanvas(item: TLayoutContextSwap): Boolean;
var
  p: pptr;
  c: int;
begin
  Result:= false;
  c:= IfThen(item = lcsItem, CanvasMouseItem, CanvasPopup);
  p:= @DL.FixedCanvases[c];
  if not CanvasSwapUsed[item] then
    if IsRectEmpty(CanvasUsedRect[c]) then
      exit
    else
      Draw16(p^, p^, 0, 0, 640*480, 1, TransparentColor16, ldkNot);
  CanvasSwapUsed[item]:= true;
  zSwap(_ScreenBuffer^, p^);
  Result:= true;
end;

procedure TLayoutSupport.UnsetVar(const Name: string; write: Boolean);
var
  i: int;
begin
  if RSStartsStr(lvKeyPressed + 'F', Name, @i) and RSVal(Copy(Name, i, MaxInt), i) and (i in [1..19]) then
    KeysNeeded[VK_F1 + i - 1]:= true;
end;

function TLayoutSupport.Update(Rendering: Boolean): Boolean;
var
  b: Boolean;
  i: int;
begin
  Activated:= true;
  WasActive:= _Windowed^ and _IsD3D^;
  Result:= false;
  if not WasActive then
    exit;

  // prepare
  if (ScreenW <> DXProxyRenderW) or (ScreenH <> DXProxyRenderH) then
    Scale:= nil;
  ScreenW:= DXProxyRenderW;
  ScreenH:= DXProxyRenderH;
  if ScreenW = 0 then  ScreenW:= L.MinWidth;
  if ScreenH = 0 then  ScreenH:= L.MinHeight;
  L.Vars[lvWidth]:= ScreenW;
  L.Vars[lvHeight]:= ScreenH;
  L.Vars[lvScreen]:= _CurrentScreen^;
  L.Vars[lvCharScreen]:= _CurrentCharScreen^;
  L.Vars[lvHouseScreen]:= _HouseScreen^;
  L.Vars[lvMainMenuCode]:= _MainMenuCode^;
  L.Vars[lvOpaqueScreen]:= BoolToInt[(_MainMenuCode^ >= 0) or _IsLoadingBig^ or _IsMoviePlaying or _IsScreenOpaque];
  L.Vars[lvMoviePlaying]:= BoolToInt[_IsMoviePlaying];
  L.Vars[lvFullScreen]:= BoolToInt[not Options.BorderlessWindowed and IsZoomed(_MainWindow^)];
  if _IsLoadingBig^ then
    L.Vars[lvLoading]:= 1
  else if _IsLoadingSmall^ then
    L.Vars[lvLoading]:= 2
  else
    L.Vars[lvLoading]:= 0;
  L.Vars[lvArcomage]:= BoolToInt[_ArcomageActive^];
  if (_MainMenuCode^ >= 0) or _IsLoadingBig^ or _NoMusicDialog^ then
    L.Vars[lvRenderedScreen]:= -1
  else if Rendering then
    L.Vars[lvRenderedScreen]:= _CurrentScreen^;
  b:= (m7 = 0) or (LastScreen <> 0) or not (_CurrentScreen^ in [1, 3, 5, 8, 104]);
  L.Vars[lvDrawButton]:= BoolToInt[not b];

  for i:= low(KeysNeeded) to high(KeysNeeded) do
    if KeysNeeded[i] then
    begin
      b:= GetKeyState(i) < 0;
      L.Vars[lvKeyPressed + 'F' + IntToStr(i - VK_F1 + 1)]:= BoolToInt[b and KeyDepressed[i]];
      KeyDepressed[i]:= not b;
    end;
  L.Vars[lvPaperDollInChests]:= Options.PaperDollInChests;
  L.Vars[lvTreeHints]:= TreeHintsVal;
  L.Vars[lvEnableAttackSpell]:= BoolToInt[Options.EnableAttackSpell];
{$IFDEF MM7}
  if _UITextColor^ and $10000 = 0 then
  begin
    L.Updated:= false;
    if _UITextColor^ = TextColor[1] then
      Alignment:= 1
    else if _UITextColor^ = TextColor[-1] then
      Alignment:= -1
    else
      Alignment:= 0;
  end;
  L.Vars[lvNeutral]:= BoolToInt[Alignment = 0];
  L.Vars[lvGood]:= BoolToInt[Alignment > 0];
  L.Vars[lvEvil]:= BoolToInt[Alignment < 0];
  L.Vars[lvTextColor]:= TextColor[Alignment];
  L.Vars[lvTextShadowColor]:= TextShColor[Alignment];
  Updating:= true;
  if Rendering then
    L.Vars[lvCustomRightSide]:= BoolToInt[_IsScreenWithCustomRightSide];
  Updating:= false;
  i:= pint($507A64)^;
  L.Vars[lvQuestion]:= BoolToInt[(_CurrentScreen^ = 19) and (i <> 0) and (pint(i + $1C)^ = 26)];
{$ELSE}
  L.Vars[lvPlayers]:= _Party_MemberCount^;
{$ENDIF}
  Result:= not L.Updated;
  if L.Updated then
  begin
    HintSuppression;
    exit;
  end;

  // do update
  FillChar(CanvasUsed, length(CanvasUsed)*SizeOf(CanvasUsed[CanvasMax]), 0);
  FillChar(CanvasUsedRect, length(CanvasUsedRect)*SizeOf(CanvasUsedRect[CanvasMax]), 0);
  FillChar(CanvasUsedOnScreen, length(CanvasUsedOnScreen)*SizeOf(CanvasUsedOnScreen[CanvasMax]), 0);
  try
    L.Update;
  except
    on e: ELayoutException do
    begin
      RSShowException;
      Halt;
    end;
    on e: Exception do
    begin
      RSShowException;
      raise;
    end;
  end;
  Drawn:= false;
  if L.Locals[lvUpdateCountdown] > 0 then
    UpdateCountdown:= Round(L.Locals[lvUpdateCountdown]) + 1; // +1 drawing of current frame
  UpdateClipCursor;
  UpdateRenderRect(RenderRect);
  if not IsNan(L.Locals[lvDebug]) then
    SetWindowText(_MainWindow^, PChar(FloatToStr(L.Locals[lvDebug])));
  ShowTreeHints:= (L.Locals[lvTreeHints] <> 0);
  HintAreaTop:= Round(L.Locals[lvHintAreaTop]);
  HintAreaRight:= Round(L.Locals[lvHintAreaRight]);
{$IFDEF MM7}
  _UITextColor^:= Round(L.Locals[lvTextColor]) or $10000;
  _UITextShadowColor^:= Round(L.Locals[lvTextShadowColor]);
  ScreenHasRightSide:= L.Locals[lvCustomRightSide] <> 0;
{$ENDIF}
  HintSuppression;
  if L.Locals[lvReloadLayout] <> 0 then
    ReloadLayout;
end;

procedure TLayoutSupport.UpdateClipCursor;
var
  r: TRect;
begin
  GetClientRect(_MainWindow^, r);
  if CheckClipCursorArea(r, true) then
    ClipCursor(nil)
  else
    ClipCursorRel(r);
end;

procedure TLayoutSupport.UpdateGameStatus;
const
  bc: array[Boolean] of Word = (TransparentColor16, 0);
var
  i: int;
begin
  with _StatusText^ do
    Status[0]:= bc[Text[TmpTime = 0][0] <> #0];
  if CanvasUsed[CanvasPartyBuffs] then
    for i:= 0 to high(PartyBuffs) do
      PartyBuffs[i]:= bc[_PartyBuffs[i].Expires > 0];
end;

procedure TLayoutSupport.UpdateMinMax;
begin
  L.Update(true);
  if (WindowWidth < 0) and (WindowHeight > L.MinHeight) then
    WindowWidth:= (L.MinWidth*WindowHeight*2 div L.MinHeight + 1) div 2
  else if (WindowHeight < 0) and (WindowWidth > L.MinWidth) then
    WindowHeight:= (L.MinHeight*WindowWidth*2 div L.MinWidth + 1) div 2;
  WindowWidth:= max(WindowWidth, L.MinWidth);
  WindowHeight:= max(WindowHeight, L.MinHeight);
  DXProxyMul:= 1;
  DXProxyMinW:= L.MinWidth;
  DXProxyMinH:= L.MinHeight;
end;

procedure TLayoutSupport.UpdateRenderRect(const r: TRect);
var
  x, y, w, h: ext;
begin
  if IsRectEmpty(r) then
    exit;
  x:= L.Locals[lvRenderCenterX];
  y:= L.Locals[lvRenderCenterY];
  RenderCenterX:= r.Left*(1-x) + r.Right*x;
  RenderCenterY:= r.Top*(1-y) + r.Bottom*y;
  with _ScreenMiddle^, _RenderRect^ do
  begin
    w:= min(X - Left, Right - X)*2;
    h:= min(Y - Top, Bottom + 1 - Y)*2;
  end;
  DXProxyMul:= max(RectW(r)*(1 + abs(1 - 2*x))/w, RectH(r)*(1 + abs(1 - 2*y))/h);
  DXProxyShiftX:= RenderCenterX - _ScreenMiddle.X*DXProxyMul;
  DXProxyShiftY:= RenderCenterY - _ScreenMiddle.Y*DXProxyMul;
  Options.RenderRect:= Rect(
    Floor((r.Left - DXProxyShiftX)/DXProxyMul + 1e-12),
    Floor((r.Top - DXProxyShiftY)/DXProxyMul + 1e-12),
    Ceil((r.Right - DXProxyShiftX)/DXProxyMul - 1e-12),
    Ceil((r.Bottom - DXProxyShiftY)/DXProxyMul - 1e-12)
  );
  ViewMulFactor:= 1/L.Locals[lvFOVMul];
  with r do
    _ViewMulOutdoor^:= Round(300*ViewMulFactor*DynamicFovFactor(Right - Left, Bottom - Top)/DXProxyMul);
end;

procedure UILayoutSetVar(Name: PChar; var v: Double); stdcall;
begin
  Layout.L.Vars[Name]:= v;
end;

procedure UILayoutSetVarInt(Name: PChar; v: int); stdcall;
begin
  Layout.L.Vars[Name]:= v;
end;

function UILayoutGetLocal(Name: PChar; var v: Double): int; stdcall;
var
  x: ext;
begin
  x:= Layout.L.Locals[Name];
  if @v <> nil then
    v:= x;
  Result:= Round(x);
end;

function UILayoutAddCanvas(Name: PChar; w, h: int; p: ptr): int; stdcall;
begin
  Result:= Layout.DL.AddFixedCanvas(Name, p, w, h);
end;

function UILayoutUpdate: Bool; stdcall;
begin
  Result:= Layout.Update;
end;

procedure DoReadLayout(Name: PChar; str: Boolean);
begin
  if _IsD3D^ then
    try
      if str then
        Layout.L.DoRead(Name)
      else
        Layout.L.Read(Name);
      Layout.UpdateMinMax;
      Layout.Update;
    except
      RSShowException;
    end;
end;

procedure UILayoutReadString(Name: PChar); stdcall;
begin
  DoReadLayout(Name, true);
end;

procedure UILayoutReadFile(Name: PChar); stdcall;
begin
  DoReadLayout(Name, false);
end;

procedure ChangeUILayout(Name: PChar); stdcall;
begin
  pstring(@Options.UILayout)^:= Name;
  if _IsD3D^ then
    Layout.ReloadLayout;
end;

procedure UILayoutClearCache; stdcall;
begin
  Layout.DL.ClearCache;
end;

procedure UILayoutOnLoad(f: TProcedure); stdcall;
var
  i: int;
begin
  i:= length(TLayoutSupport.OnLoad);
  SetLength(TLayoutSupport.OnLoad, i + 1);
  TLayoutSupport.OnLoad[i]:= f;
end;

exports
  UILayoutSetVar,
  UILayoutSetVarInt,
  UILayoutGetLocal,
  UILayoutAddCanvas,
  UILayoutUpdate,
  UILayoutReadFile,
  UILayoutReadString,
  UILayoutClearCache,
  UILayoutOnLoad,
  ChangeUILayout;
initialization
  Layout:= TLayoutSupport.Create;
end.
