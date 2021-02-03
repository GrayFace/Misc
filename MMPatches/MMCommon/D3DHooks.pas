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
procedure OnLoadedD3D;
function LoadSpriteD3DHook(Name: PChar; PalIndex: int): PHwlBitmap; stdcall;

implementation

//----- 32 and 16 bit color management

function GetColor(p: ptr; bt: int): uint; inline;
begin
  if bt = 4 then
    Result:= puint(p)^
  else
    Result:= pword(p)^;
end;

procedure SetColor(p: ptr; bt: int; c: uint); inline;
begin
  if bt = 4 then
    puint(p)^:= c
  else
    pword(p)^:= c;
end;

function PropagateColor(p: PChar; d, bt: int; mask: uint; c0: uint; get: Boolean): Boolean; inline;
var
  c: uint;
begin
  c:= GetColor(p + d*bt, bt);
  Result:= get and (c > mask) or not get and (c = 0);
  if Result then
    if get then
      SetColor(p, bt, c and mask)
    else
      SetColor(p + d*bt, bt, c0 and mask);
end;

function PropagateLoop(p: PChar; w, h, d1, d2, bt: int; mask: uint): Boolean; inline;
var
  c: uint;
  x, y: int;
begin
  Result:= false;
  inc(p, w*bt); 
  for y:= h - 2 downto 0 do
  begin
    inc(p, bt);
    for x:= w - 2 downto 0 do
    begin
      c:= GetColor(p, bt);
      if c = 0 then
        Result:= PropagateColor(p, d1, bt, mask, c, true) or PropagateColor(p, d2, bt, mask, c, true) or Result
      else if c > mask then
        Result:= PropagateColor(p, d1, bt, mask, c, false) or PropagateColor(p, d2, bt, mask, c, false) or Result;
      inc(p, bt);
    end;
  end;
end;

procedure DoPropagateIntoTransparent(p: PChar; w, h, bt, mask: int); inline;
begin
  if PropagateLoop(p, w, h, -1, -w, bt, mask) then  // up, left
    PropagateLoop(p, w, h, -w-1, -w+1, bt, mask);   // corders of top line
end;

procedure PropagateIntoTransparent(p: ptr; w, h: int; TrueColor: Boolean);
begin
  if TrueColor then
    DoPropagateIntoTransparent(p, w, h, 4, $FFFFFF)
  else
    DoPropagateIntoTransparent(p, w, h, 2, $7FFF);
end;

procedure ReadPalettedColor(p, p0: PChar; n: int; pal: PDWordArray; bt: int); inline;
var
  i: int;
begin
  inc(p, bt*n);
  inc(p0, n);
  for i:= n - 1 downto 0 do
  begin
    dec(p, bt);
    dec(p0);
    SetColor(p, bt, pal[ord(p0^)]);
  end;
end;

//----- HSV multiplication

// HSV aka HSB:
// V = max component
// S = (max - min)/V
// H = relative position of the middle component within [min, max] and info on which components are max and min
type
  TCConvTable = array[0..255] of array[0..255] of byte;
var
  CConvS, CConvV: array[Boolean] of Single;
  CConvDesat: Boolean;
  CConvTable: array[Boolean] of TCConvTable;
  DivTable: array[0..255] of uint;  // = 2^16 / i

function PrepareCConvTable(TrueColor: Boolean): Boolean;
var
  v, sat: ext;
  i, j: uint;
begin
  Result:= (CConvS[TrueColor] <> Options.PaletteSMul) or (CConvV[TrueColor] <> Options.PaletteVMul);
  if not Result then
    exit;
  Options.ResetPalettes:= true;
  CConvS[TrueColor]:= Options.PaletteSMul;
  CConvV[TrueColor]:= Options.PaletteVMul;
  CConvDesat:= (Options.PaletteSMul <= 1);
  // 15-bit mipmaps are a bit more saturated
  sat:= IfThen(TrueColor, 1.027, 1)*Options.PaletteSMul;
  for i:= 1 to 255 do
  begin
    v:= EnsureRange(i*246/255*Options.PaletteVMul, 0, 256); // trying to mimic original
    for j:= 0 to 255 do
      CConvTable[TrueColor][i][j]:= min(255, Trunc(v*EnsureRange(1 - (1 - j/i)*sat, 0, 1)));
    DivTable[i]:= $10101 div i; // $10101*$FF = $FFFFFF
  end;
end;

procedure ConvertColorOversat(var conv: TCConvTable; var a, b, c: byte); inline;
var
  i: uint;
begin
  i:= conv[a][255];
  b:= uint(b - c)*i*DivTable[a - c] shr 16;
  a:= i;
  c:= 0;
end;

// ordered: a > b > c
// not ordered: a = max(a, b, c)
procedure DoConvertColor(var conv: TCConvTable; var a, b, c: byte; desat, ordered: Boolean); inline;
var
  i, j: uint;
begin
  if desat then  // normal case (SMul <= 1)
  begin
    b:= conv[a][b];
    c:= conv[a][c];
    a:= conv[a][255];
    exit;
  end;
  i:= conv[a][b];
  j:= conv[a][c];
  if (j = 0) and (ordered or (c < b)) then
    ConvertColorOversat(conv, a, b, c)
  else if not ordered and (i = 0) and (b < c) then
    ConvertColorOversat(conv, a, c, b)
  else begin
    b:= i;
    c:= j;
    a:= conv[a][255];
  end;
end;

procedure ConvertColorSV(var conv: TCConvTable; var r, g, b: byte; desat: Boolean); inline; overload;
begin
  if r > g then
    if r > b then
      DoConvertColor(conv, r, g, b, desat, false)
    else
      DoConvertColor(conv, b, r, g, desat, true)
  else
    if g > b then
      DoConvertColor(conv, g, r, b, desat, false)
    else
      DoConvertColor(conv, b, g, r, desat, true);
end;

procedure ConvertColorSV(var r, g, b: byte; TrueColor: Boolean); inline; overload;
begin
  if TrueColor then
    ConvertColorSV(CConvTable[true], r, g, b, CConvDesat)
  else
    ConvertColorSV(CConvTable[false], r, g, b, CConvDesat);
end;

//----- Palettes

function StartReadingBitmap(Name: PChar; var bmp: TLodBitmap; var f: ptr): Boolean;
begin
  f:= _LodFind(0, 0, _BitmapsLod, 0, Name);
  Result:= (f <> nil);
  if Result then
    _fread(bmp, 1, $30, f); // read bitmap header
end;

function ConvertPalColor(c: int; TrueColor: Boolean): uint;
var
  r, g, b: byte;
begin
  r:= byte(c);
  g:= HiByte(c);
  b:= c shr 16;
  ConvertColorSV(r, b, g, TrueColor);
  if TrueColor then
    Result:= (r shl 16 + g shl 8 + b) or $FF000000
  else
    Result:= (r shr 3 shl 10 + g shr 3 shl 5 + b shr 3) or $8000;
end;

var
  LoadedPalettes: array of array[-1..255] of uint;
  LoadedPalN: int;

function LoadPaletteD3D(Id: uint; Trans: Boolean; TrueColor: Boolean): PDWordArray;
var
  pal: array[0..256*3] of byte;
  bmp: TLodBitmap;
  f: ptr;
  i: int;
begin
  PrepareCConvTable(TrueColor);
  if Options.ResetPalettes then
  begin
    LoadedPalN:= 0;
    if Options.TrueColorTextures <> Options.TrueColorSprites then
      PrepareCConvTable(not TrueColor);
  end;
  Options.ResetPalettes:= false;
  if Trans then
    inc(id, $10000);
  if TrueColor then
    inc(id, $20000);
  for i:= LoadedPalN - 1 downto 0 do
    if LoadedPalettes[i][-1] = Id then
    begin
      Result:= @LoadedPalettes[i][0];
      exit;
    end;
  i:= LoadedPalN;
  inc(LoadedPalN);
  if high(LoadedPalettes) < i then
    SetLength(LoadedPalettes, max(i*2, 128));
  LoadedPalettes[i][-1]:= Id;
  Result:= @LoadedPalettes[i][0];
  if not StartReadingBitmap(ptr(Format('pal%.3d', [Word(Id)])), bmp, f) then
    exit;
  if bmp.DataSize <> 0 then
    _fseek(f, bmp.DataSize, soFromCurrent);
  _fread(pal, 1, 256*3, f); // read bitmap header
  for i:= 0 to 255 do
    Result[i]:= ConvertPalColor(pint(@pal[i*3])^, TrueColor);
  if Trans then
    Result[0]:= 0;
end;

//----- No HWL for bitmaps

procedure ConvertColorHD(p: ptr; bt, c: int; desat: Boolean); inline;
var
  r, g, b: byte;
begin
  b:= byte(c);
  g:= HiByte(c);
  r:= c shr 16;
  ConvertColorSV(CConvTable[bt = 4], r, b, g, desat);
  if bt = 4 then
    puint(p)^:= (r shl 16 + g shl 8 + b) or $FF000000
  else
    pword(p)^:= (r shr 3 shl 10 + g shr 3 shl 5 + b shr 3) or $8000;
end;

procedure DoLoadBitmapHD(p, p1: PChar; w, h, trans, bt: int; transOk, desat: Boolean); inline;
var
  HasTrans: Boolean;
  i, c: int;
begin
  HasTrans:= false;
  inc(p, w*h*bt);
  inc(p1, w*h*3);
  for i:= w*h downto 1 do
  begin
    dec(p, bt);
    dec(p1, 3);
    c:= pint(p1)^;
    if transOk and (c and $FFFFFF = trans) then
    begin
      SetColor(p, bt, 0);
      HasTrans:= true;
    end else
      ConvertColorHD(p, bt, c, desat);
  end;
  if HasTrans then
    PropagateIntoTransparent(p, w, h, bt = 4);
end;

procedure LoadBitmapHD(p, p1: PChar; w, h, trans, bt: int); inline;
begin
  PrepareCConvTable(bt = 4);
  if (trans and not $FFFFFF) = 0 then
    if CConvDesat then
      DoLoadBitmapHD(p, p1, w, h, trans, bt, true, true)
    else
      DoLoadBitmapHD(p, p1, w, h, trans, bt, true, false)
  else
    if CConvDesat then
      DoLoadBitmapHD(p, p1, w, h, trans, bt, false, true)
    else
      DoLoadBitmapHD(p, p1, w, h, trans, bt, false, false);
end;

var
  TextureBuf: TRSByteArray;
  TextureMipW: uint;

function LoadBitmapD3DHook(n1, n2, this, PalIndex: int; Name: PChar): PHwlBitmap;
var
  bmp: TLodBitmap;
  f: ptr;
  pack: array of Byte;
  p, p1: ptr;
  pal: PDWordArray;
  hd, trans: Boolean;
  i, c, bt: int;
begin
  Result:= nil;
  if not StartReadingBitmap(Name, bmp, f) then  exit;
  Result:= _new(SizeOf(THwlBitmap));
  ZeroMemory(Result, SizeOf(THwlBitmap));
  with bmp, Result^ do
  begin
    FullW:= w;
    FullH:= h;
    AreaW:= w;
    AreaH:= h;
    if Options.TrueColorTextures then
    begin
      bt:= 4;
      if length(TextureBuf) < BmpSize*4 then
        SetLength(TextureBuf, BmpSize*4);
      p:= ptr(TextureBuf);
      DXProxyTrueColorTexture:= true;
    end else
    begin
      bt:= 2;
      Buffer:= _new(BmpSize*2);
      p:= Buffer;
    end;
    p1:= p;
    i:= BmpSize;
    hd:= (Palette = 0) and ((UnpSize > BmpSize*2) or (UnpSize = 0) and (DataSize > BmpSize*2));
    if hd then
    begin
      i:= BmpSize*3;
      if bt < 4 then
      begin
        if length(TextureBuf) < i then
          SetLength(TextureBuf, i + 1);
        p1:= ptr(TextureBuf);
      end;
      w:= PowerOf2[BmpWidthLn2];
      h:= PowerOf2[BmpHeightLn2];
    end;
    TextureMipW:= w;
    BufW:= w;
    BufH:= h;
    // Read bitmap data
    if UnpSize <> 0 then
    begin
      SetLength(pack, DataSize);
      _fread(pack[0], 1, DataSize, f);
      UnpSize:= min(UnpSize, i);
      _Deflate(0, @UnpSize, p1^, DataSize, pack[0]);
      pack:= nil;
    end else
      _fread(p1^, 1, min(DataSize, i), f);

    if hd then
    begin
      _fread(c, 1, 4, f);  // check first color
      if bt = 4 then
        LoadBitmapHD(p, p1, w, h, c, 4)
      else
        LoadBitmapHD(p, p1, w, h, c, 2);
      exit;
    end;

    // Get Palette
    c:= 0;
    _fread(c, 1, 3, f);  // check first color for transparency (margenta/light blue)
    trans:= (c = $FFFF00) or (c = $FF00FF) or (c = $FC00FC) or (c = $FCFC00);
    pal:= LoadPaletteD3D(Palette, trans, bt = 4);

    // Render
    if bt = 4 then
      ReadPalettedColor(p, p1, BmpSize, pal, 4)
    else
      ReadPalettedColor(p, p1, BmpSize, pal, 2);
    if trans then
      PropagateIntoTransparent(p, w, h, bt = 4);
  end;
end;

//----- No HWL for sprites

function Power2(n: int):int;
begin
  Result:= 4;
  while Result < n do
    Result:= Result*2;
end;

function ReadSprite(sp: PSprite; pal: PDWordArray; BufW, BufH, x1, y1, y2, bt: int): ptr; inline;
var
  p: PChar;
  i, j, w: int;
begin
  Result:= _new(BufW*BufH*bt);
  p:= Result;
  w:= BufW*bt;
  for i := y1 to y2 do
    with sp.Lines[i] do
      if (i >= 0) and (a1 >= 0) then
      begin
        j:= (a1 - x1)*bt;
        inc(p, j);
        ReadPalettedColor(p, pos, a2 - a1 + 1, pal, bt);
        inc(p, w - j);
      end else
        inc(p, w);
end;

function LoadSpriteD3DHook(Name: PChar; PalIndex: int): PHwlBitmap; stdcall;
var
  sprite: PSprite;
  i, x1, x2, y1, y2: int;
  pal: PDWordArray;
begin
  Result:= nil;
  sprite:= FindSprite(Name);
  if sprite = nil then
    exit;

  with sprite^ do
  begin
    Result:= _new(SizeOf(THwlBitmap));
    //ZeroMemory(Result, SizeOf(THwlBitmap)); // now done always
    // Find area bounds
    x1:= w;
    x2:= -1;
    y1:= -1;
    y2:= -1;
    for i := 0 to h - 1 do
      with Lines[i] do
        if a1 >= 0 then
        begin
          if y1 < 0 then  y1:= i;
          y2:= i;
          if a1 < x1 then  x1:= a1;
          if a2 > x2 then  x2:= a2;
        end;
    with Result^ do
    begin
      DXProxyTrueColorTexture:= Options.TrueColorSprites;
      FullW:= w;
      FullH:= h;
      if y1 < 0 then
      begin
        x1:= 0;
        y1:= 0;
      end;
      // Area dimensions must be powers of 2
      inc(x2);
      inc(y2);
      BufW:= Power2(x2 - x1 + 2); // 1 pixel on each side for smooth edge
      BufH:= Power2(y2 - y1 + 2);
      AreaW:= BufW;
      AreaH:= BufH;
      x1:= (x1 + x2 - BufW) div 2;
      //x1:= IntoRange(x1, 0, w - BufW);
      y1:= (y1 + y2 - BufH) div 2;
      //y1:= IntoRange(y1, 0, h - BufH);
      y2:= min(y1 + BufH, h) - 1;
      AreaX:= x1;
      AreaY:= y1;

      // Get Palette
      pal:= LoadPaletteD3D(PalIndex, true, Options.TrueColorSprites);
      // Render
      if Options.TrueColorSprites then
        Buffer:= ReadSprite(sprite, pal, BufW, BufH, x1, y1, y2, 4)
      else
        Buffer:= ReadSprite(sprite, pal, BufW, BufH, x1, y1, y2, 2);
      // Sparks spell ignores transparency bit, this check is to avoid interfering with it
      if _MainMenuCode^ < 0 then
        PropagateIntoTransparent(Buffer, BufW, BufH, Options.TrueColorSprites);
    end;
  end;
end;

//----- Take sprite contour into account when clicking it

var
  SpriteD3DHitStd: function(var draw: TDrawSpriteD3D; x, y: single): LongBool; stdcall;

function FindSpriteD3D(texture: ptr): PSpriteD3D;
var
  i: int;
begin
  i:= _SpritesLodCount^ - 1;
  Result:= @_SpritesD3D^[0];
  while (i > 0) and (Result.Texture <> texture) do
  begin
    inc(Result);
    dec(i);
  end;
  if i = 0 then
    Result:= nil;
end;

function SpriteD3DHitHook(var draw: TDrawSpriteD3D; x, y: single): LongBool; stdcall;
var
  sp3d: PSpriteD3D;
  sp: PSprite;
  drX, drW, drY, drH: Single;
  i, j: int;
begin
  Result:= SpriteD3DHitStd(draw, x, y);
  if not Result then
    exit;

  sp3d:= FindSpriteD3D(draw.Texture);
  if sp3d = nil then
    exit;
  with draw do
  begin
    drX:= Vert[0].sx;
    drW:= Vert[3].sx - drX;
    drY:= Vert[0].sy;
    drH:= Vert[1].sy - drY;
  end;
  i:= sp3d.AreaX + Floor(sp3d.AreaW * (x + 0.5 - drX) / drW);
  j:= sp3d.AreaY + Floor(sp3d.AreaH * (y + 0.5 - drY) / drH);
  sp:= FindSprite(sp3d^);
  if (sp = nil) or (sp.Lines = nil) then
    exit;

  Result:= false;
  if (j < 0) or (j >= sp.h) then  exit;
  with sp.Lines[j] do
  begin
    if (a1 < 0) or (i > a2) or (i < a1) then  exit;
    Result:= ((pos + i - a1)^ <> #0);
  end;
end;

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
  fadd Options.MouseDX
end;

procedure LoadMouseRemainderY;
asm
  fadd Options.MouseDY
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
  fw, fh: int;
begin
  Result:= DXProxyScaleRect(Options.RenderRect);
  with Result do
  begin
    Left:= max(Left, 0);
    Top:= max(Top, 0);
    Right:= min(Right, DXProxyRenderW);
    Bottom:= min(Bottom, DXProxyRenderH);
    fw:= RectW(Result);
    fh:= RectH(Result);
    if w*fh >= h*fw then
    begin
      h:= RDiv(h*fw, w);
      Result:= Bounds(Left, Top + (fh - h) div 2, fw, h);
    end else
    begin
      w:= RDiv(w*fh, h);
      Result:= Bounds(Left + (fw - w) div 2, Top, w, fh);
    end;
  end;
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
begin
  if (m8 = 1) or IsLayoutActive then
    with Options.RenderRect do
      v:= IndoorAntiFov*ViewMulFactor*DynamicFovFactor(Right - Left, Bottom - Top);
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
  x, y, z, m: ext;
begin
  Result:= @v;
  FillChar(v, SizeOf(v), 0);
  // dist mul:
  m:= dist*$10000/CastRay(x, y, z, x0, y0);
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

//----- 32 bit sprites

function DrawInfoSprite32(p: PChar; i: int; var desc: TDDSurfaceDesc2): Word;
var
  c, x: int;
begin
  Result:= 0;
  x:= i mod desc.lPitch;
  if x < 0 then
    dec(x, desc.lPitch);
  if not InRange((i - x) div desc.lPitch, 0, desc.dwHeight - 1) then
    exit;
  c:= pint(p + i + x)^;
  Result:= byte(c) shr 3 + c and $FC00 shr 5 + c and $F80000 shr 8;
end;

procedure DrawInfoSprite32Hook;
asm
  push ecx
  add edx, edx
  lea ecx, [ebp - $17C]
  call DrawInfoSprite32
  pop ecx
  mov dx, ax
end;

//----- 32 bit textures

function MixCl(c1, c2, c3, c4: uint): uint; inline;
begin
  // Mipmap gets darker than the base texture and this matches how MM generates mipmaps
  // This provides a nice slight shading effect
  Result:= (c1 and $FCFCFCFC shr 2 + c2 and $FCFCFCFC shr 2 + c3 and $FCFCFCFC shr 2 + c4 and $FCFCFCFC shr 2);
end;

procedure MakeMip(p: PDWordArray; w, h: int);
var
  p1: PDWordArray;
  x, y: int;
begin
  p1:= p;
  for y:= h downto 1 do
  begin
    for x:= w downto 1 do
    begin
      p[0]:= MixCl(p1[0], p1[1], p1[w*2], p1[w*2+1]);
      p:= @p[1];
      p1:= @p1[2];
    end;
    p1:= @p1[w*2];
  end;
end;

procedure CopyBufToSurface32(p, p1: PChar; w, h, d: int);
begin
  w:= w*4;
  for h:= h downto 1 do
  begin
    CopyMemory(p, p1, w);
    inc(p, d);
    inc(p1, w);
  end;
end;

function CopyTexture32Bit(const surf: IDirectDrawSurface4; var desc: TDDSurfaceDesc2; flags: int): Bool; stdcall;
begin
  Result:= false;
  if not LockSurface(ptr(surf), @desc, flags) then  exit;
  with desc do
  begin
    if dwWidth <> TextureMipW then
      MakeMip(ptr(TextureBuf), dwWidth, dwHeight);
    CopyBufToSurface32(lpSurface, ptr(TextureBuf), dwWidth, dwHeight, lPitch);
  end;
  surf.Unlock(nil);
end;

//----- Calculate mipmaps count depending on the texture in question

procedure GetMipmapsCountHook;
asm
  jz @std
  cmp DXProxyActive, true
  jnz @std
  mov eax, esi
  mov edx, ebx
  call GetMipmapsCountProc
  mov DXProxyMipmapCount, eax
  mov [esp], m7*$4A4DC2 + m8*$4A2C75
@std:
end;

//----- Fix water in maps without a building with WtrTyl texture and textures with water bit turning into water

procedure WatrTylFix;
begin
  _LoadBitmap(0, 0, _BitmapsLod, 0, 'WtrTyl');
end;

//----- Extend view distance

procedure GroundBoundsHook;
asm
  push ecx
  push edi
  push ebx  // X-Y swap

  xor ebx, ebx
	mov ecx, dword [ebp - $58]
  test ecx, ecx
  jz @NoSwap
  cmp ecx, 3
  jz @NoSwap
  cmp ecx, 4
  jz @NoSwap
  cmp ecx, 7
  jz @NoSwap
  // swap X and Y
  mov ebx, $7ABA10 - $7AB810
@NoSwap:

	lea edi, [m7*$76D848 + m8*$7AB810 + ebx]  // beginy
	mov ecx, ($7ABA10 - $7AB810)/4
	mov eax, 2
	rep stosd

	lea edi, [m7*$76D448 + m8*$7AB410 + ebx]  // endy
	mov ecx, ($7AB610 - $7AB410)/4
	mov eax, 125
	rep stosd

  neg ebx
  add ebx, m7*$76DA48 + m8*$7ABA10  // beginx
	mov ecx, 128
@loop:
	dec ecx
	mov [ebx + ecx*4], ecx
	jnz @loop

  pop ebx
	pop edi
  pop ecx
	mov eax, 128
	push m7*$47FF0C + m8*$47F707
end;

procedure RemoveViewLimits;
const
  count = 8192 + 64*128;  // support drawing all facets and half of all tiles at once
  PolySize = 268;
  oldHigh = pint(m7*$4787B7 + m8*$477261);
  hk0: TRSHookInfo = (t: RSht4);
{$IFDEF mm7}
	counts: array[1..9] of int = ($4787B7, $478C6A, $48062A, $480A5B, $480E58, $4814EC, $481802, $481ADF, $487499);
	refs: array[1..17] of int = ($4784D1, $478B5F, $479363, $479385, $47A568, $47A582, $480565, $48098D, $480D8A, $48141D, $48171C, $4819FF, $481EC8, $487366, $4873AC, $48745F, $487DAE);
	endrefs: array[1..3] of int = ($47A57A+1, $47A592+1, $487DBA+1);
	refs2: array[1..3] of int = ($4873BD, $4873ED, $48747A);
{$ELSE}
	counts: array[1..10] of int = ($477261, $477738, $477B9B, $47FE0F, $480234, $48064D, $480D56, $48106E, $48134B, $4872DF);
	refs: array[1..18] of int = ($476F6F, $477469, $477A90, $478294, $4782B8, $479750, $47976A, $47FD52, $48014A, $48057D, $480C86, $480F86, $48126B, $481734, $486CA6, $486CEC, $4872AB, $4876BF);
	endrefs: array[1..3] of int = ($4876CB+1, $479762+1, $47977A+1);
	refs2: array[1..3] of int = ($486CFD, $486D31, $4872C5);
{$ENDIF}
var
  hk: TRSHookInfo;

  procedure patch(const a: array of int; add: int);
  var
    i: int;
  begin
    hk.add:= add;
    for i := low(a) to high(a) do
    begin
      hk.p:= a[i];
      RSApplyHook(hk);
    end;
  end;

var
  dn: int;
  off: int;
begin
  dn:= count - oldHigh^ - 1;
  if dn <= 0 then  exit;
  hk:= hk0;
  off:= GetMemory(count*PolySize) - ppchar(refs[1])^;
	patch(counts, dn);
	patch(refs, off);
	patch(endrefs, off + dn*PolySize);
  off:= GetMemory(count*4) - ppchar(refs2[1])^;
	patch(refs2, off);
end;

//----- HooksList

var
  HooksCommon: array[1..3] of TRSHookInfo = (
    //(p: m7*$6BDF7C + m8*$6F3084; new: 200; t: RSht4; Querry: hqViewDistanceLimits), // Extend view distance
    //(p: m7*$6BDF80 + m8*$6F3088; new: 200; t: RSht4; Querry: hqViewDistanceLimits), // Extend view distance
    (p: m7*$6BDF84 + m8*$6F308C; new: 200; t: RSht4; Querry: hqViewDistanceLimits), // Extend view distance
    (p: m7*$47F8D2 + m8*$47F0CD; newp: @GroundBoundsHook; t: RShtJmp; size: 6; Querry: hqViewDistanceLimits), // Extend view distance
    ()
  );
{$IFDEF MM7}
  SkyExtra: Single = 50;
  Hooks: array[1..76] of TRSHookInfo = (
    (p: $4A4D93; old: $452504; newp: @LoadBitmapD3DHook; t: RShtCall; Querry: 13), // No HWL for bitmaps
    (p: $49EAE3; old: $4523AB; new: $45246B; t: RShtCall; Querry: 13), // No HWL for bitmaps
    (p: $49EB3B; size: 5; Querry: 13), // No HWL for bitmaps
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
    (p: $4C1508; old: $4C1579; backup: @@SpriteD3DHitStd; newp: @SpriteD3DHitHook; t: RShtCall), // Take sprite contour into account when clicking it
    (p: $4A50B1; size: 2; Querry: hqSprite32Bit), // 32 bit sprites
    (p: $4A50C1; size: 2; Querry: hqSprite32Bit), // 32 bit sprites
    (p: $4A50D3; size: 2; Querry: hqSprite32Bit), // 32 bit sprites
    (p: $41E944; newp: @DrawInfoSprite32Hook; t: RShtCall; size: $41E957 - $41E944; Querry: hqSprite32Bit), // 32 bit sprites (monster info)
    (p: $4A4E6E; old: $4A0ED0; newp: @CopyTexture32Bit; t: RShtCall; Querry: hqTex32Bit2), // 32 bit textures
    (p: $4A4F3C; old: $4A0ED0; newp: @CopyTexture32Bit; t: RShtCall; Querry: hqTex32Bit2), // 32 bit textures
    (p: $4A4D98; newp: @GetMipmapsCountHook; t: RShtAfter; size: 6; Querry: hqMipmaps), // Calculate mipmaps count depending on the texture in question
    (p: $4649B7; newp: @WatrTylFix; t: RShtBefore), // Fix water in maps without a building with WtrTyl texture and textures with water bit turning into water
    (p: $479A0D; old: $4D8770; newp: @SkyExtra; t: RSht4; Querry: hqViewDistanceLimits), // Extended view distance - draw bigger bottom part
    ()
  );
{$ELSE}
  Hooks: array[1..69] of TRSHookInfo = (
    (p: $4A2C46; old: $44FD37; newp: @LoadBitmapD3DHook; t: RShtCall; Querry: 13), // No HWL for bitmaps
    (p: $49C175; old: $44FBD0; new: $44FC90; t: RShtCall; Querry: 13), // No HWL for bitmaps
    (p: $49C1CD; size: 5; Querry: 13), // No HWL for bitmaps
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
    (p: $4784AC; newp: @PreciseSkyFtol; t: RShtCallStore), // Fix for 'jumping' of the top part of the sky
    (p: $47851F; newp: @PreciseSkyFtol; t: RShtCallStore), // Fix for 'jumping' of the top part of the sky
    (p: $47867B; newp: @PreciseSkyHook1; t: RShtBefore; size: 6), // Fix for 'jumping' of the top part of the sky
    (p: $478962; newp: @PreciseSkyHook1; t: RShtBefore; size: 6), // Fix for 'jumping' of the top part of the sky
    (p: $4BF072; old: $4BF0E3; backup: @@SpriteD3DHitStd; newp: @SpriteD3DHitHook; t: RShtCall), // Take sprite contour into account when clicking it
    (p: $4A2F64; size: 2; Querry: hqSprite32Bit), // 32 bit sprites
    (p: $4A2F74; size: 2; Querry: hqSprite32Bit), // 32 bit sprites
    (p: $4A2F86; size: 2; Querry: hqSprite32Bit), // 32 bit sprites
    (p: $41DF2B; newp: @DrawInfoSprite32Hook; t: RShtCall; size: $41DF3E - $41DF2B; Querry: hqSprite32Bit), // 32 bit sprites (monster info)
    (p: $4A2D21; old: $49E9C0; newp: @CopyTexture32Bit; t: RShtCall; Querry: hqTex32Bit2), // 32 bit textures
    (p: $4A2DEF; old: $49E9C0; newp: @CopyTexture32Bit; t: RShtCall; Querry: hqTex32Bit2), // 32 bit textures
    (p: $4A2C4B; newp: @GetMipmapsCountHook; t: RShtAfter; size: 6; Querry: hqMipmaps), // Calculate mipmaps count depending on the texture in question
    ()
  );
{$ENDIF}

procedure CheckHooksD3D;
begin
  CheckHooks(HooksCommon);
  CheckHooks(Hooks);
end;

procedure ApplyHooks(Querry: int);
begin
  RSApplyHooks(HooksCommon, Querry);
  RSApplyHooks(Hooks, Querry);
end;

procedure ApplyHooksD3D;
begin
  ApplyHooks(0);
  if Options.NoBitmapsHwl then
    ApplyHooks(13);
  if Options.SupportTrueColor then
    ApplyHooks(hqTrueColor);
  if Options.TrueColorTextures then
    ApplyHooks(hqTex32Bit);
  if Options.TrueColorTextures and Options.NoBitmapsHwl then
    ApplyHooks(hqTex32Bit2);
  if Options.TrueColorSprites then
    ApplyHooks(hqSprite32Bit);
  if MipmapsCount <> 0 then
    ApplyHooks(hqMipmaps);
  {if Options.SupportTrueColor and true then
    ApplyHooks(hqDelayedInterface);}
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
    ApplyHooks(hqLayout);
  end;
  if (Options.UILayout <> nil) or (IndoorAntiFov <> 369) {$IFDEF MM8}or FixIndoorFOV{$ENDIF} then
    ApplyHooks(hqFixIndoorFOV);
end;

procedure OnLoadedD3D;
begin
  if ViewDistanceD3D > $2000 then
    _dist_mist^:= ViewDistanceD3D;
  if ViewDistanceD3D > 10500 then
  begin
    RemoveViewLimits;
    ApplyHooks(hqViewDistanceLimits);
  end;
end;

end.
