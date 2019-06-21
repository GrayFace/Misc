unit D3DHooks;

interface

uses
  Windows, Messages, SysUtils, Classes, RSSysUtils, RSQ, Common, RSCodeHook,
  Math, MP3, RSDebug, IniFiles, Direct3D, Graphics, MMSystem, RSStrUtils,
  DirectDraw, DXProxy, RSResample, RSGraphics, MMCommon, MMHooks,
  LayoutSupport;

{$I MMPatchVer.inc}

procedure CheckHooksD3D;
procedure ApplyHooksD3D;

implementation

//----- Attacking big monsters D3D

var
  SpriteD3DPoints: array[0..9] of single;
  SpriteCenterShift: Single;

function VisibleSpriteD3DProc(p: psingle; var count: int):psingle;
var
  i: int;
  xm, x1, x2, y1, y2: ext;
begin
  Result:= p;
  y1:= p^;
  y2:= p^;
  dec(p);
  x1:= p^;
  x2:= p^;
  inc(p, 8);
  for i:= 1 to 3 do
  begin
    if p^ < x1 then  x1:= p^;
    if p^ > x2 then  x2:= p^;
    inc(p);
    if p^ < y1 then  y1:= p^;
    if p^ > y2 then  y2:= p^;
    inc(p, 7);
  end;
  with Options.RenderRect do
  begin
    xm:= (Right + Left)/2;
    if x1 < xm then
      SpriteCenterShift:= max(0, xm - x2)
    else
      SpriteCenterShift:= x1 - xm;
    x1:= max(x1, Left + 0.1);
    x2:= min(x2, Right - 0.1);
    y1:= max(y1, Top + 0.1);
    y2:= min(y2, Bottom - 0.1);
  end;
  if (x1 > x2) or (y1 > y2) then
  begin
    count:= 3;  // just check 1 point
    exit;
  end;
  dec(count);  // 5 points instead of 4
  SpriteD3DPoints[0]:= (x1 + x2)/2;
  SpriteD3DPoints[1]:= (y1 + y2)/2;
  SpriteD3DPoints[2]:= x1;
  SpriteD3DPoints[3]:= y1;
  SpriteD3DPoints[4]:= x1;
  SpriteD3DPoints[5]:= y2;
  SpriteD3DPoints[6]:= x2;
  SpriteD3DPoints[7]:= y1;
  SpriteD3DPoints[8]:= x2;
  SpriteD3DPoints[9]:= y2;
  Result:= @SpriteD3DPoints[1];
end;

procedure VisibleSpriteD3DHook7;
asm
  lea eax, dword ptr $EF5144[esi]
  lea edx, [ebp + $C]  // number of points
  jmp VisibleSpriteD3DProc
end;

procedure VisibleSpriteD3DHook8;
asm
  lea eax, dword ptr $FC50DC[ebx]
  lea edx, [ebp - $18]  // number of points
  call VisibleSpriteD3DProc
  mov ebx, eax
end;

//----- Space and A buttons selecting sprites on the sides of the screen

const
  PickSidesMul = 1000;

function PrioritizeCenterSpritesHook(zval: uint): int;
const
  m = PickSidesMul;
begin
  Result:= zval;
  if zval <= $FFFFFFFF - m shl 16 then
    Result:= zval + uint(Round(Sqr(SpriteCenterShift*2/RectW(Options.RenderRect))*m)) shl 16;
end;

procedure PrioritizeCenterSpritesHook2;
asm
  mov SpriteCenterShift, 0
end;

//----- Precise sprites placement

var
  DrawSpritePos: array of array[0..1] of int2;
  DrawSpriteCount: int;
  DrawSpriteOff: int;
  FloatToIntShl16: single = 6755399441055744/$10000;

procedure ExtendDrawSpritePos(n: int);
begin
  DrawSpriteCount:= n + max(501, DrawSpriteCount);
  SetLength(DrawSpritePos, DrawSpriteCount);
end;

procedure CheckDrawSpriteCount;
asm
  push eax
  mov eax, [__SpritesToDrawCount]
  cmp eax, DrawSpriteCount
  jl @ok
  push edx
  push ecx
  call ExtendDrawSpritePos
  pop ecx
  pop edx
@ok:
  pop eax
end;

procedure StoreSpriteRemainder;
asm
  call CheckDrawSpriteCount
  // store ax as int16
  push edx
  mov edx, [__SpritesToDrawCount]
  shl edx, 2
  and DrawSpriteOff, 2
  add edx, DrawSpriteOff
  xor DrawSpriteOff, 2
  add edx, DrawSpritePos
  mov [edx], ax
  pop edx
end;

procedure StoreSpriteRemainderAndShr16;
asm
  call StoreSpriteRemainder
  add eax, $8000
  sar eax, 16
end;

procedure StoreSpriteRemainderEff;
asm
  call StoreSpriteRemainder
  add eax, $8000
end;

{$IFDEF MM7}
procedure StoreSpriteRemainderIndoor;
asm
  push eax
  cmp DrawSpriteOff, 2
  jz @y
  neg eax
@y:
  call StoreSpriteRemainder
  pop eax
  add eax, $8000
  sar eax, 16
end;
{$ELSE}
procedure StoreSpriteRemainderIndoor;
asm
  cmp DrawSpriteOff, 2
  jz StoreSpriteRemainderAndShr16
  neg eax
  call StoreSpriteRemainder
  neg eax
  add eax, $8000
  sar eax, 16
end;
{$ENDIF}

procedure LoadSpriteRemainder;
asm
  call CheckDrawSpriteCount
  push ecx
  shl eax, 16
  mov ecx, DrawSpriteOff
  add ecx, DrawSpritePos
  add DrawSpriteOff, 2
  movsx ecx, word ptr [ecx]
  sub eax, ecx
// check for loop end:
  mov ecx, [__SpritesToDrawCount]
  shl ecx, 2
  cmp ecx, DrawSpriteOff
  jg @ok
  and DrawSpriteOff, 2
@ok:
  pop ecx
end;

procedure FShr16;
const
  a: int = $10000;
asm
  fidiv a
end;

procedure FShr16x;
const
  a: int = $10000;
asm
  fild dword ptr [ebp - $14]
  fidiv a
  fld dword ptr [ebp + $C]
end;

procedure AddEffectSpriteProc(var a: TDrawSpriteD3D);
var
  i: int;
begin
  for i:= 0 to a.VertNum - 1 do
    with a.Vert[i] do
    begin
      sx:= sx - DrawSpritePos[_SpritesToDrawCount^][0]/$10000;
      sy:= sy - DrawSpritePos[_SpritesToDrawCount^][1]/$10000;
    end;
end;

procedure AddEffectSpriteHook;
asm
  lea eax, [esi + m7*$EF5138 + m8*$FC50D0]
  jmp AddEffectSpriteProc
end;

procedure AddEffectSpriteProc2(var a: TD3DTLVertex);
begin
  with a do
  begin
    sx:= sx - DrawSpritePos[_SpritesToDrawCount^][0]/$10000;
    sy:= sy - DrawSpritePos[_SpritesToDrawCount^][1]/$10000;
  end;
end;

procedure AddEffectSpriteHook2;
asm
  lea eax, [esi+48h]
  jmp AddEffectSpriteProc2
end;

//----- Precise mouse

procedure LoadMouseRemainderX;
asm
  fadd MouseDX
end;

procedure LoadMouseRemainderY;
asm
  fadd MouseDY
end;

//----- Support any FOV indoors

procedure FacetViewIntersectionProc(var x, y: int);
begin
  x:= Round(x*GetCoordCorrectionIndoorX);
  y:= Round(y*GetCoordCorrectionIndoorY);
end;

procedure FacetViewIntersectionHook;
asm
  push [esp + 7*4]
  push [esp + 7*4]
  push [esp + 7*4]
  push [esp + 7*4]
  push [esp + 7*4]
  push [esp + 7*4]
  push [esp + 7*4]
  call eax
  mov eax, [esp + 5*4]
  mov edx, [esp + 6*4]
  call FacetViewIntersectionProc
  ret 7*4
end;

//----- 32 bits support (Direct3D)

var
  RenderRectSet: Boolean;

procedure DrawD3D(SrcBuf: ptr; info: PDDSurfaceDesc2);
begin
  if not RenderRectSet then  // respect vx1, vx2, vy1, vy2
  begin
    Options.RenderRect:= _RenderRect^;
    inc(Options.RenderRect.Bottom);
    Options.RenderBottomPixel:= _RenderRect^.Bottom;
    RenderRectSet:= true;
  end;
  if Layout.Active then
  begin
    Layout.Draw(SrcBuf, info.lpSurface, info.lPitch);
    DXProxyDrawCursor(SrcBuf, info);
  end else
    DXProxyDraw(SrcBuf, info);
end;

procedure TrueColorHook;
asm
  lea edx, [ebp - $98]
  cmp dword ptr [edx + $54], 32
  jnz @std
  mov dword ptr [esp], (m7*$4A5AE7 + m8*$4A3978)
  jmp DrawD3D
@std:
end;

function MakePixel16(c32: int): Word;
asm
  ror eax, 8
  shr ah, 3
  shr ax, 2
  rol eax, 5
end;

var
  LockSurface: function(surf: ptr; info: PDDSurfaceDesc2; param: int): LongBool; stdcall;
  ShotBuf: array of Word;

procedure DoTrueColorShot(info: PDDSurfaceDesc2; ps: PWord; ds, w, h: int; const r: TRect);
var
  pd: PChar;
  x, y, pitch, wd, hd: int;
begin
  wd:= r.Right - r.Left;
  hd:= r.Bottom - r.Top;
  pd:= info.lpSurface;
  pitch:= info.lPitch;
  inc(pd, (r.Top + hd div (2*h))*pitch + (r.Left + wd div (2*w))*4);
  dec(ds, w*2);
  for y:= 0 to h - 1 do
  begin
    for x:= 0 to w - 1 do
    begin
      ps^:= MakePixel16(pint(pd + (x*wd div w)*4 + (y*hd div h)*pitch)^);
      inc(ps);
    end;
    inc(PChar(ps), ds);
  end;
end;

function GetShotRect(w, h: int): TRect;
var
  r: TRect;
  fw, fh: int;
begin
  r:= Options.RenderRect;
  fw:= RectW(r);
  fh:= RectH(r);
  if w*fh >= h*fw then
  begin
    h:= RDiv(h*fw, w);
    r:= Bounds(r.Left, r.Top + (fh - h) div 2, fw, h);
  end
  else
  begin
    w:= RDiv(w*fh, h);
    r:= Bounds(r.Left + (fw - w) div 2, r.Top, w, fh);
  end;
  Result:= DXProxyScaleRect(r);
end;

procedure TrueColorShotProc(info: PDDSurfaceDesc2; ps: PWord; w, h: int);
begin
  DoTrueColorShot(info, ps, w*2, w, h, GetShotRect(w, h));
end;

procedure TrueColorShotHook;
asm
  lea eax, [ebp - $A0]  // info
  cmp dword ptr [eax + $54], 32
  jnz @std
  mov ecx, [ebp - $10]  // h
  mov [esp], ecx
  mov ecx, [ebp - $4]  // w
  mov edx, ebx  // ps
  push m7*$45E1B6 + m8*$45BE12
  jmp TrueColorShotProc
@std:
end;

function TrueColorLloydHook(surf: ptr; info: PDDSurfaceDesc2; param: int): LongBool; stdcall;
const
  w = m7*92 + m8*128;
  h = m7*68 + m8*67;
begin
  Result:= LockSurface(surf, info, param);
  if not Result or (info.ddpfPixelFormat.dwRGBBitCount <> 32) then  exit;
  NeedScreenWH;
  SetLength(ShotBuf, SW*SH);
  with _RenderRect^ do
    DoTrueColorShot(info, @ShotBuf[Left + SW*Top], SW*2, Right - Left, Bottom - Top + 1, GetShotRect(w, h));
end;

//----- UI Layout

function IsVideoPlayingHook(b: Boolean): Boolean;
begin
  if Layout.Active then
  begin
    Layout.Update(true);
    Result:= b and IsRectEmpty(Layout.RenderRect);
  end else
    Result:= b;
end;

type
  TRightClickDrawProc = procedure(_,__, this: int);

procedure RightClickDrawHook(f: TRightClickDrawProc; _, this: int);
begin
  if Layout.Active and Layout.CanvasSwapUsed[lcsMenu] then
    exit;  // scroll message + rbutton menu: only draw scroll message
  if Layout.Active then
    Layout.SwapCanvas(lcsMenu);
  f(0,0, this);
  if Layout.Active then
    Layout.SwapCanvas(lcsMenu);
end;

procedure MouseItemDrawHook(f: TRightClickDrawProc; _, this: int);
var
  p: TPoint;
  i: int;
begin
  if (_ItemInMouse^ <> 0) and Layout.Active and Layout.SwapCanvas(lcsItem) then
  begin
    p:= GameCursorPos^;
    GameCursorPos^:= Point(0, 0);
    f(0,0, this);
    i:= _ItemInMouse^;
    _ItemInMouse^:= 0;
    f(0,0, this); // clear backup buffer
    _ItemInMouse^:= i;
    GameCursorPos^:= p;
    Layout.SwapCanvas(lcsItem);
  end else
    f(0,0, this);
end;

//----- Dynamic indoor FOV. MM8 Bugfix: indoor FOV wasn't extended like outdoor

procedure FixIndoorFOVProcD3D(var v: Single);
const
  base = 369;
begin
  if (m8 = 1) or IsLayoutActive then
    with Options.RenderRect do
      v:= base*ViewMulFactor*DynamicFovFactor(Right - Left, Bottom - Top);
end;

procedure FixIndoorFOVHookD3D;
asm
  lea eax, [esi + $C4]
  jmp FixIndoorFOVProcD3D
end;

//----- On right/left sides of the screen bottom of sprites didn't react to clicks

type
  TMMVertex = record
    x, y, z: Single;
    unk: array[0..8] of Single;
  end;
  TMMSegment = array[0..1] of TMMVertex;

function FixCastRay(var v: TMMSegment; x0, y0, dist: Single): ptr; stdcall;
var
  x, y, z, m, s, c: ext;
begin
  Result:= @v;
  FillChar(v, SizeOf(v), 0);
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
  // dist mul:
  m:= dist*$10000/sqrt(x*x + y*y + z*z);
  with _CameraPos^ do
  begin
    v[0].x:= X;
    v[0].y:= Y;
    v[0].z:= Z;
  end;
  v[1].x:= v[0].x + x*m;
  v[1].y:= v[0].y + y*m;
  v[1].z:= v[0].z + z*m;
end;

//----- Fix for 'jumping' of the top part of the sky

var
  PreciseSky: array[0..2] of Double;
  PreciseSkyOff: int;

procedure PreciseSkyFtol;
asm
  mov edx, PreciseSkyOff
  fst qword ptr PreciseSky[edx]
  xor edx, 8
  mov PreciseSkyOff, edx
  jmp eax
end;

function PreciseSky1(a, b: int): int64;
begin
  Result:= Round((PreciseSky[0] - a)*b);
end;

procedure PreciseSkyHook1;
asm
  mov eax, [ebp - m7*$34 - m8*$3C]
  mov edx, [ebp - m7*$24 - m8*$20]
  call PreciseSky1
  mov ecx, eax
end;

//----- Draw sprites at an angle

type
  TVisibleSprite = packed record
    Texture: int;
    VertCount: int;
    v1, v2, v3, v4: TD3DTLVertex;
    ZBuf, _1, _2, ZBufAndObjKind, SpriteToDrawIndex: int;
  end;

{
3D transform sprite rect:
y = y0 / L0
x = x0 / L0
y' = y*cos(a)
dL = y0*sin(a) = y*L0*sin(a)
x' = x0 / (L0 + dL) = x / (1 + y*sin(a))

0-3
| |
1-2
}

procedure SpritesAngleProc(var sprite: TDrawSpriteD3D);
var
  w, h, si, co, mul: ext;
begin
  SinCos(_Party_Angle^*Pi/1024/3, si, co);
  with sprite do
  begin
    //w:= Vert[3].sx - Vert[0].sx;
    h:= Vert[1].sy - Vert[0].sy;
    //w:= w/max(0.5, 1 + h/GetViewMul*si);
    mul:= 1/EnsureRange(1 + h/GetViewMul*si, 0.9, 1.25);
    Vert[0].sx:= (Vert[0].sx - _ScreenMiddle.X)*mul + _ScreenMiddle.X;
    Vert[3].sx:= (Vert[3].sx - _ScreenMiddle.X)*mul + _ScreenMiddle.X;
    Vert[0].sy:= Vert[1].sy - h*co;
    Vert[3].sy:= Vert[0].sy;
  end;
end;

{procedure SpritesAngleProc(var sprite: TDrawSpriteD3D);
var
  a: ext;
begin
  a:= _Party_Angle^*Pi/1024/4*0;
  with sprite do
    if a <> 0 then
    begin
      Vert[0].sy:= Vert[1].sy - (Vert[1].sy - Vert[0].sy)*cos(a);
      Vert[3].sy:= Vert[0].sy;
    end;
end;}

procedure SpritesAngleHook;
asm
  lea eax, $FC50D0[esi]
  call SpritesAngleProc
end;

//----- HooksList

var
{$IFDEF MM7}
  Hooks: array[1..63] of TRSHookInfo = (
    (p: $4C0A23; newp: @VisibleSpriteD3DHook7; t: RShtCall; size: 6), // Attacking big monsters D3D
    (p: $4A59A3; newp: @TrueColorHook; t: RShtAfter; size: 6; Querry: hqTrueColor), // 32 bit color support
    (p: $45E14D; newp: @TrueColorShotHook; t: RShtBefore; size: 6; Querry: hqTrueColor), // 32 bit color support
    (p: $49EDF7; old: $4A0ED0; backup: @@LockSurface; newp: @TrueColorLloydHook; t: RShtCall; Querry: hqTrueColor), // 32 bit color support
    (p: $436ABE; old: $4D8578; newp: @FloatToIntShl16; t: RSht4), // Precise sprites placement (indoor)
    (p: $436AED; old: $4D8578; newp: @FloatToIntShl16; t: RSht4), // Precise sprites placement (indoor)
    (p: $436AC2; newp: @StoreSpriteRemainderIndoor; t: RShtAfter; size: 6), // Precise sprites placement (indoor)
    (p: $436AF1; newp: @StoreSpriteRemainderIndoor; t: RShtAfter; size: 6), // Precise sprites placement (indoor)
    (p: $47B30D; newp: @StoreSpriteRemainder; t: RShtAfter; size: 6), // Precise sprites placement (items outdoor)
    (p: $47B336; newp: @StoreSpriteRemainder; t: RShtAfter; size: 6), // Precise sprites placement (items outdoor)
    (p: $47AD93; newp: @StoreSpriteRemainder; t: RShtAfter; size: 6), // Precise sprites placement (decor outdoor)
    (p: $47ADB9; newp: @StoreSpriteRemainder; t: RShtAfter; size: 6), // Precise sprites placement (decor outdoor)
    (p: $47B8BD; newp: @StoreSpriteRemainder; t: RShtAfter; size: 6), // Precise sprites placement (monsters outdoor)
    (p: $47B8E6; newp: @StoreSpriteRemainder; t: RShtAfter; size: 6), // Precise sprites placement (monsters outdoor)
    (p: $440D3D; newp: @LoadSpriteRemainder; t: RShtBefore; size: 6), // Precise sprites placement (indoor)
    (p: $440D46; newp: @LoadSpriteRemainder; t: RShtBefore; size: 6), // Precise sprites placement (indoor)
    (p: $4A4485; newp: @FShr16x; t: RShtCall; size: 6), // Precise sprites placement (indoor)
    (p: $4A44A6; newp: @FShr16; t: RShtBefore; size: 6), // Precise sprites placement (indoor)
    (p: $47BB3C; newp: @LoadSpriteRemainder; t: RShtBefore; size: 6), // Precise sprites placement (outdoor)
    (p: $47BB49; newp: @LoadSpriteRemainder; t: RShtBefore), // Precise sprites placement (outdoor)
    (p: $4A40FD; newp: @FShr16; t: RShtAfter; size: 6), // Precise sprites placement (outdoor)
    (p: $4A4120; newp: @FShr16; t: RShtBefore; size: 6), // Precise sprites placement (outdoor)
    (p: $4780E7; newp: @AddEffectSpriteHook2; t: RShtAfter; size: 6), // Precise effects placement (indoor) - implosion
    (p: $4A3A5D; newp: @AddEffectSpriteHook; t: RShtAfter; size: 6), // Precise effects placement (indoor)
    (p: $4A3FA7; newp: @AddEffectSpriteHook; t: RShtAfter; size: 6), // Precise effects placement (outdoor)
    (p: $48B7AF; newp: @StoreSpriteRemainderEff; t: RShtAfter; size: 6), // Precise effects placement (outdoor)
    (p: $48B7DC; newp: @StoreSpriteRemainderEff; t: RShtAfter; size: 6), // Precise effects placement (outdoor)
    (p: $48B9CD; newp: @StoreSpriteRemainderEff; t: RShtAfter; size: 6), // Precise effects placement (outdoor)
    (p: $48B9F7; newp: @StoreSpriteRemainderEff; t: RShtAfter; size: 6), // Precise effects placement (outdoor)
    (p: $48BAF2; newp: @StoreSpriteRemainderEff; t: RShtAfter; size: 6), // Precise effects placement (outdoor)
    (p: $48BB1C; newp: @StoreSpriteRemainderEff; t: RShtAfter; size: 6), // Precise effects placement (outdoor)
    (p: $44EB14; newp: @LoadMouseRemainderX; t: RShtAfter; size: 7), // Precise mouse
    (p: $44EB14; newp: @LoadMouseRemainderY; t: RShtBefore), // Precise mouse
    (p: $423BD1; newp: @FacetViewIntersectionHook; t: RShtCallStore), // Support any FOV indoors (portals D3D)
    (p: $441159; newp: @IsVideoPlayingHook; t: RShtAfter; Querry: hqLayout), // Show view in all screens
    (p: $44122F; newp: @IsVideoPlayingHook; t: RShtAfter; Querry: hqLayout), // Show view in all screens
    (p: $416D0B; newp: @RightClickDrawHook; t: RShtFunctionStart; size: 6; Querry: hqLayout), // Menus to separate canvas
    (p: $4159A4; newp: @RightClickDrawHook; t: RShtCallStore; Querry: hqLayout), // Menus to separate canvas
    (p: $469EA8; newp: @MouseItemDrawHook; t: RShtFunctionStart; size: 6; Querry: hqLayout), // Menus to separate canvas
    (p: $43787C; newp: @FixIndoorFOVHookD3D; t: RShtAfter; size: 6; Querry: hqFixIndoorFOV), // Indoor FOV wasn't extended like outdoor
    (p: $4C09DD; old: $F8BA94; newp: @Options.RenderRect.Left; t: RSht4; Querry: hqLayout), // Account for shrinked view size
    (p: $4C09FD; old: $F8BA98; newp: @Options.RenderRect.Top; t: RSht4; Querry: hqLayout), // Account for shrinked view size
    (p: $4C09ED; old: $F8BA9C; newp: @Options.RenderRect.Right; t: RSht4; Querry: hqLayout), // Account for shrinked view size
    (p: $4C0A0D; old: $F8BAA0; newp: @Options.RenderBottomPixel; t: RSht4; Querry: hqLayout), // Account for shrinked view size
    (p: $4C0A33; old: $F8BA94; newp: @Options.RenderRect.Left; t: RSht4; Querry: hqLayout), // Account for shrinked view size
    (p: $4C0A64; old: $F8BA98; newp: @Options.RenderRect.Top; t: RSht4; Querry: hqLayout), // Account for shrinked view size
    (p: $4C0A4F; old: $F8BA9C; newp: @Options.RenderRect.Right; t: RSht4; Querry: hqLayout), // Account for shrinked view size
    (p: $4C0A79; old: $F8BAA0; newp: @Options.RenderBottomPixel; t: RSht4; Querry: hqLayout), // Account for shrinked view size
    (p: $4C0BA9; old: $F8BA94; newp: @Options.RenderRect.Left; t: RSht4; Querry: hqLayout), // Account for shrinked view size
    (p: $4C0BD3; old: $F8BA98; newp: @Options.RenderRect.Top; t: RSht4; Querry: hqLayout), // Account for shrinked view size
    (p: $4C0BBE; old: $F8BA9C; newp: @Options.RenderRect.Right; t: RSht4; Querry: hqLayout), // Account for shrinked view size
    (p: $4C0BE7; old: $F8BAA0; newp: @Options.RenderBottomPixel; t: RSht4; Querry: hqLayout), // Account for shrinked view size
    (p: $4A8CAD; old: $F8BAA4; newp: @Options.RenderRect.Left; t: RSht4; Querry: hqLayout), // Account for shrinked view size
    (p: $4A8CE5; old: $F8BAA8; newp: @Options.RenderRect.Top; t: RSht4; Querry: hqLayout), // Account for shrinked view size
    (p: $4A8CCB; old: $F8BAAC; newp: @Options.RenderRect.Right; t: RSht4; Querry: hqLayout), // Account for shrinked view size
    (p: $4A8CB2; old: $F8BAB0; newp: @Options.RenderBottomPixel; t: RSht4; Querry: hqLayout), // Account for shrinked view size
    (p: $4C06CA; newp: @PrioritizeCenterSpritesHook; t: RShtAfter; size: 6), // Space and A buttons selecting sprites on the sides of the screen
    (p: $4C09B7; newp: @PrioritizeCenterSpritesHook2; t: RShtAfter), // Space and A buttons selecting sprites on the sides of the screen
    (p: $4C2400; newp: @FixCastRay; t: RShtJmp; size: 6), // On right/left sides of the screen bottom of sprites didn't react to clicks
    (p: $479577; newp: @PreciseSkyFtol; t: RShtCallStore), // Fix for 'jumping' of the top part of the sky
    (p: $4795EA; newp: @PreciseSkyFtol; t: RShtCallStore), // Fix for 'jumping' of the top part of the sky
    (p: $47978F; newp: @PreciseSkyHook1; t: RShtBefore; size: 6), // Fix for 'jumping' of the top part of the sky
    ()
  );
{$ELSE}
  Hooks: array[1..59] of TRSHookInfo = (
    (p: $4BE5D9; newp: @VisibleSpriteD3DHook8; t: RShtCall; size: 6), // Attacking big monsters D3D
    (p: $4A383A; newp: @TrueColorHook; t: RShtAfter; size: 6; Querry: hqTrueColor), // 32 bit color support
    (p: $45BDA1; newp: @TrueColorShotHook; t: RShtBefore; size: 6; Querry: hqTrueColor), // 32 bit color support
    (p: $49C46B; old: $49E9C0; backup: @@LockSurface; newp: @TrueColorLloydHook; t: RShtCall; Querry: hqTrueColor), // 32 bit color support
    (p: $43443B; old: $4E8590; newp: @FloatToIntShl16; t: RSht4), // Precise sprites placement (indoor)
    (p: $43446A; old: $4E8590; newp: @FloatToIntShl16; t: RSht4), // Precise sprites placement (indoor)
    (p: $43443F; newp: @StoreSpriteRemainderIndoor; t: RShtAfter; size: 6), // Precise sprites placement (indoor)
    (p: $43446E; newp: @StoreSpriteRemainderIndoor; t: RShtAfter; size: 6), // Precise sprites placement (indoor)
    (p: $47A5D5; newp: @StoreSpriteRemainder; t: RShtAfter; size: 6), // Precise sprites placement (items outdoor)
    (p: $47A5FE; newp: @StoreSpriteRemainder; t: RShtAfter; size: 6), // Precise sprites placement (items outdoor)
    (p: $479FFB; old: $4E8798; newp: @FloatToIntShl16; t: RSht4), // Precise sprites placement (decor outdoor)
    (p: $47A021; old: $4E8798; newp: @FloatToIntShl16; t: RSht4), // Precise sprites placement (decor outdoor)
    (p: $479FFF; newp: @StoreSpriteRemainderAndShr16; t: RShtAfter; size: 6), // Precise sprites placement (decor outdoor)
    (p: $47A025; newp: @StoreSpriteRemainderAndShr16; t: RShtAfter; size: 6), // Precise sprites placement (decor outdoor)
    (p: $47ABA4; newp: @StoreSpriteRemainder; t: RShtAfter; size: 6), // Precise sprites placement (monsters outdoor)
    (p: $47ABD3; newp: @StoreSpriteRemainder; t: RShtAfter; size: 6), // Precise sprites placement (monsters outdoor)
    (p: $43DC89; newp: @LoadSpriteRemainder; t: RShtBefore; size: 6), // Precise sprites placement (indoor)
    (p: $43DC8F; newp: @LoadSpriteRemainder; t: RShtBefore; size: 6), // Precise sprites placement (indoor)
    (p: $4A2338; newp: @FShr16; t: RShtAfter; size: 10), // Precise sprites placement (indoor)
    (p: $4A2359; newp: @FShr16; t: RShtBefore; size: 6), // Precise sprites placement (indoor)
    (p: $47AE2F; newp: @LoadSpriteRemainder; t: RShtBefore; size: 6), // Precise sprites placement (outdoor)
    (p: $47AE35; newp: @LoadSpriteRemainder; t: RShtBefore; size: 6), // Precise sprites placement (outdoor)
    (p: $4A1FB2; newp: @FShr16; t: RShtAfter), // Precise sprites placement (outdoor)
    (p: $4A1FD9; newp: @FShr16; t: RShtBefore; size: 6), // Precise sprites placement (outdoor)
    (p: $476BA0; newp: @AddEffectSpriteHook2; t: RShtAfter; size: 6), // Precise effects placement (indoor) - implosion
    (p: $4A1912; newp: @AddEffectSpriteHook; t: RShtAfter; size: 6), // Precise effects placement (indoor)
    (p: $4A1E5C; newp: @AddEffectSpriteHook; t: RShtAfter; size: 6), // Precise effects placement (outdoor)
    (p: $48B08D; newp: @StoreSpriteRemainderEff; t: RShtAfter; size: 6), // Precise effects placement (outdoor)
    (p: $48B0BA; newp: @StoreSpriteRemainderEff; t: RShtAfter; size: 6), // Precise effects placement (outdoor)
    (p: $48B2AB; newp: @StoreSpriteRemainderEff; t: RShtAfter; size: 6), // Precise effects placement (outdoor)
    (p: $48B2D5; newp: @StoreSpriteRemainderEff; t: RShtAfter; size: 6), // Precise effects placement (outdoor)
    (p: $48B3D0; newp: @StoreSpriteRemainderEff; t: RShtAfter; size: 6), // Precise effects placement (outdoor)
    (p: $48B3FD; newp: @StoreSpriteRemainderEff; t: RShtAfter; size: 6), // Precise effects placement (outdoor)
    (p: $44C26C; newp: @LoadMouseRemainderX; t: RShtAfter; size: 7), // Precise mouse
    (p: $44C26C; newp: @LoadMouseRemainderY; t: RShtBefore), // Precise mouse
    (p: $42203F; newp: @FacetViewIntersectionHook; t: RShtCallStore), // Support any FOV indoors (portals D3D)
    (p: $43E05E; newp: @IsVideoPlayingHook; t: RShtAfter; Querry: hqLayout), // Show view in all screens
    (p: $43E138; newp: @IsVideoPlayingHook; t: RShtAfter; Querry: hqLayout), // Show view in all screens
    (p: $41634C; newp: @RightClickDrawHook; t: RShtFunctionStart; size: 6; Querry: hqLayout), // Menus to separate canvas
    (p: $414D12; newp: @RightClickDrawHook; t: RShtCallStore; Querry: hqLayout), // Menus to separate canvas
    (p: $46821F; newp: @MouseItemDrawHook; t: RShtFunctionStart; size: 6; Querry: hqLayout), // Menus to separate canvas
    (p: $43520D; newp: @FixIndoorFOVHookD3D; t: RShtAfter; size: 6; Querry: hqFixIndoorFOV), // Indoor FOV wasn't extended like outdoor
    (p: $4BE7B9; old: $FFDE8C; newp: @Options.RenderRect.Left; t: RSht4; Querry: hqLayout), // Account for shrinked view size
    (p: $4BE7DB; old: $FFDE90; newp: @Options.RenderRect.Top; t: RSht4; Querry: hqLayout), // Account for shrinked view size
    (p: $4BE7CA; old: $FFDE94; newp: @Options.RenderRect.Right; t: RSht4; Querry: hqLayout), // Account for shrinked view size
    (p: $4BE7EC; old: $FFDE98; newp: @Options.RenderBottomPixel; t: RSht4; Querry: hqLayout), // Account for shrinked view size
    (p: $4A7318; old: $FFDE9C; newp: @Options.RenderRect.Left; t: RSht4; Querry: hqLayout), // Account for shrinked view size
    (p: $4A7356; old: $FFDEA0; newp: @Options.RenderRect.Top; t: RSht4; Querry: hqLayout), // Account for shrinked view size
    (p: $4A7338; old: $FFDEA4; newp: @Options.RenderRect.Right; t: RSht4; Querry: hqLayout), // Account for shrinked view size
    (p: $4A731D; old: $FFDEA8; newp: @Options.RenderBottomPixel; t: RSht4; Querry: hqLayout), // Account for shrinked view size
    (p: $4BE2AE; newp: @PrioritizeCenterSpritesHook; t: RShtAfter; size: 6), // Space and A buttons selecting sprites on the sides of the screen
    (p: $4BE5C5; newp: @PrioritizeCenterSpritesHook2; t: RShtAfter), // Space and A buttons selecting sprites on the sides of the screen
    (p: $4BFFAA; newp: @FixCastRay; t: RShtJmp; size: 6), // On right/left sides of the screen bottom of sprites didn't react to clicks
    //(p: $47847A; newp: @PreciseSky1; t: RShtFunctionStart; size: 9),
    //(p: $4A0D07; newp: @PreciseSkyHook2; t: RShtBefore),
    (p: $4784AC; newp: @PreciseSkyFtol; t: RShtCallStore), // Fix for 'jumping' of the top part of the sky
    (p: $47851F; newp: @PreciseSkyFtol; t: RShtCallStore), // Fix for 'jumping' of the top part of the sky
    (p: $47867B; newp: @PreciseSkyHook1; t: RShtBefore; size: 6), // Fix for 'jumping' of the top part of the sky
    (p: $478962; newp: @PreciseSkyHook1; t: RShtBefore; size: 6), // Fix for 'jumping' of the top part of the sky
    //(p: $47861A; newp: @PreciseSkyHook2; t: RShtCall; size: 6),
    //(p: $4788F0; newp: @PreciseSkyHook3; t: RShtCall; size: 6),
    (p: $4A21DB; newp: @SpritesAngleHook; t: RShtAfter; size: 6), // Draw sprites at an angle
    ()
  );
{$ENDIF}

procedure CheckHooksD3D;
begin
  CheckHooks(Hooks);
end;

procedure ApplyHooksD3D;
begin
  RSApplyHooks(Hooks);
  if Options.SupportTrueColor then
    RSApplyHooks(Hooks, hqTrueColor);
  if Options.UILayout <> nil then
  begin
    pint(_IconsLod + $11B8C)^:= 5;
    pint(_IconsLod + $11B90)^:= 6;
    pint(_IconsLod + $11B94)^:= 5;
    DXProxyOnResize;
    try
      Layout.Update;
    except
      RSShowException;
      Halt;
    end;
    RSApplyHooks(Hooks, hqLayout);
  end;
  if (Options.UILayout <> nil) {$IFDEF MM8}or FixIndoorFOV{$ENDIF} then
    RSApplyHooks(Hooks, hqFixIndoorFOV);
end;

end.
