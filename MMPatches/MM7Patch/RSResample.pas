unit RSResample;

interface

uses
  Windows, Messages, SysUtils, RSSysUtils, Classes, RSQ, Math, Graphics;

type
  TRSResampleInfo = record
    SrcW, SrcH, DestW, DestH: int;
    SrcX, SrcY, DestX, DestY: int;
    CmdX: TRSByteArray;
    CmdY: TRSByteArray;
    procedure Init(sW, sH, dW, dH: int);
    function ScaleRect(const r: TRect): TRSResampleInfo;
  end;

// 1.11 for linear scaling, 2 is good for interface to preserve pixels
procedure RSSetResampleParams(Sigma: ext = 2.5; MiddleShift: ext = 0.7);
procedure RSResample16(const info: TRSResampleInfo; Src: ptr; SrcPitch: IntPtr; Dest: ptr; DestPitch: IntPtr); overload;
procedure RSResample16(const info: TRSResampleInfo; Src, Dest: TBitmap); overload;
procedure RSResample16(Src, Dest: TBitmap); overload;
procedure RSResampleTrans16(const info: TRSResampleInfo; Src: ptr; SrcPitch: int; Dest: ptr; DestPitch: int; Trans: int);
procedure RSResampleTrans16_NoAlpha(const info: TRSResampleInfo; Src: ptr; SrcPitch: int; Dest: ptr; DestPitch: int; Trans: int);

implementation

{$I RSPak.inc}

const
  MaxMix = 8;  // 8 shades
  MixBits = 3;
  MixMask = $F8F8F8;
  MixRemainder = $070707;
  // Remainder is considered non-important, so it's not mixed. Instead, it's
  // taken as is from one of the pixels

var
  isigma: ext = 2.5;
  mshift: ext = 0.7;
  // e.g. x2 scale results in blocks (x, 1)
  // mshift = 1:  x = 0.5
  // mshift = 0:  x >= 0.75  (0.75 with linear, more with gaussian)

procedure RSSetResampleParams(Sigma, MiddleShift: ext);
begin
  isigma:= Sigma;
  mshift:= MiddleShift;
end;

// errf approximation with precision 1.5E-7
// http://kaktusenok.blogspot.ru/2011/09/erf-cc.html
function errf(x: ext): ext;
var
  y: ext;
begin
  y:= 1.0 / ( 1.0 + 0.3275911 * abs(x));
  Result:= 1 - (((((
        + 1.061405429  * y
        - 1.453152027) * y
        + 1.421413741) * y
        - 0.284496736) * y
        + 0.254829592) * y)
        * exp (-x * x);
  if x < 0 then
    Result:= -Result;
end;

function ResampleCoreInt(mid, x1, x2, scale: ext): ext;
begin
  x1:= (x1 - mid)*scale;
  x2:= (x2 - mid)*scale;
  // domain from -1 to +1
  // Let's use gaussian with sigma = 2 at x = 1 (so sigma = 1/2)
  // Graph: https://www.graphsketch.com/?eqn1_color=1&eqn1_eqn=8*(exp(-(2.0*x)%5E2)%20-%20exp(-(2.0)%5E2))%2F(exp(-(2.0*x)%5E2)%2Bexp(-(2.0*(x-1))%5E2)%20-%20exp(-(2.0)%5E2)*2)%2B0.5&eqn2_color=2&eqn2_eqn=&eqn3_color=3&eqn3_eqn=&eqn4_color=4&eqn4_eqn=&eqn5_color=5&eqn5_eqn=&eqn6_color=6&eqn6_eqn=&x_min=-0.5&x_max=1.5&y_min=0.5&y_max=8.5&x_tick=0.2&y_tick=1&x_label_freq=5&y_label_freq=1&do_grid=0&do_grid=1&bold_labeled_lines=0&bold_labeled_lines=1&line_width=4&image_w=850&image_h=525
  // x5 resample check: https://www.graphsketch.com/parametric.php?mode=para&eqn1_color=1&eqn1_x=t*6%2F5&eqn1_y=8*%28exp%28-%282.0*t%29%5E2%29+-+exp%28-%282.0%29%5E2%29%29%2F%28exp%28-%282.0*t%29%5E2%29%2Bexp%28-%282.0*%28t-1%29%29%5E2%29+-+exp%28-%282.0%29%5E2%29*2%29%2B0.5&eqn2_color=2&eqn2_x=&eqn2_y=&eqn3_color=3&eqn3_x=&eqn3_y=&x_min=-0.5&x_max=1.5&y_min=0.5&y_max=8.5&t_min=0&t_max=1&x_tick=0.2&y_tick=1&x_label_freq=6&y_label_freq=1&do_grid=0&do_grid=1&bold_labeled_lines=0&bold_labeled_lines=1&line_width=4&image_w=850&image_h=525
  Result:= errf(x2*isigma) - errf(x1*isigma) - (x2 - x1)*exp(-isigma*isigma);
end;

function PrepareResampleArray(sw, dw: int): TRSByteArray;
var
  a: array of int;
  scale, v, mid, last: ext;
  i, j, main: int;
begin
  Assert(dw >= sw, 'Downsampling is not supported');
  SetLength(a, dw); // packed: (opacity from 1 to MaxMix) + i*MaxMix
  scale:= dw/sw;
  j:= 0;
  mid:= 0;
  last:= 0;
  for i:= 0 to dw - 1 do
  begin
    main:= (2*j + 1)*dw div (2*sw);  // = Floor((j + 0.5)*scale) - full color point, to reduce blurriness
    if main < i then
    begin
      last:= mid;
      inc(j);
      main:= (2*j + 1)*dw div (2*sw);
    end;
    mid:= mshift*(main + 0.5) + (1 - mshift)*(j + 0.5)*scale;;  // shift middle point towards the main point
    a[i]:= min(j, sw - 1)*MaxMix + MaxMix;
    if (i = main) or (j = 0) or (j >= sw) then
      continue;
    v:= ResampleCoreInt(mid, i, i + 1, 1/(mid - last));
    v:= v/(v + ResampleCoreInt(last, i, i + 1, 1/(mid - last)));
    a[i]:= j*MaxMix + Round(v*MaxMix);
  end;
  SetLength(Result, dw + 1);
  j:= 0;
  for i:= 0 to dw - 1 do
  begin
    Result[i]:= a[i] - j;
    j:= a[i];
  end;
  Result[dw]:= MaxMix + 1;
end;

function CutResampleArray(const a: TRSByteArray; x, w: int; out sx: int): TRSByteArray;
var
  i, k, v: int;
begin
  SetLength(Result, w + 1);
  k:= 0;
  v:= MaxMix;
  for i:= 0 to x + w - 1 do
  begin
    inc(v, a[i]);
    if v > MaxMix then
    begin
      dec(v, MaxMix);
      if i <= x then
        inc(k);
    end;
    if i = x then
      Result[0]:= v;
  end;
  CopyMemory(@Result[1], @a[x + 1], w - 1);
  Result[w]:= MaxMix*2 + 1 - v;
  sx:= k-1;
end;

//----- 16 bit color

function GetPixel16(c: uint): uint;
begin
  Result:= (c and $F81F)*33 shr 2;  // r,b components - 5 bit: *(2^5 + 1) shr 2
  Result:= byte(Result) + Result shr 11 shl 16;
  inc(Result, (c and $7E0)*65 shr 9 shl 8);  // g component - 6 bit: *(2^6 + 1) shr 4
end;

var
  //ToTrueColor: array[0..$FFFF] of int;
  ToBits: array[0..$FFFF] of array[0..1] of uint;
  TransMix: array[0..MaxMix*MaxMix*MaxMix*4 - 1] of uint;

procedure Prepare16to32;
var
  i: int;
  v: uint;
begin
  for i:= 0 to $FFFF do
  begin
    v:= GetPixel16(i);
    ToBits[i][0]:= (v and MixMask) div MaxMix;
    ToBits[i][1]:= v and MixRemainder;
  end;
end;

procedure PrepareTransMix;
var
  x0, x, y0, y, v, i, x1, sum, a: uint;
begin
  i:= 0;
  for v:= 1 to MaxMix do
    for y0:= 0 to MaxMix*2 - 1 do
      for x0:= 0 to MaxMix*2 - 1 do
      begin
        x:= (x0 + 1) shr 1;
        y:= (y0 + 1) shr 1;
        // x' = x*v, y' = y*(MaxMix - v)
        // alpha' = (x' + y')*256/MaxMix/MaxMix
        // v' = Round(8*x''/(x'' + y'')),  '' - new opacity
        x1:= (MaxMix - x)*v;
        sum:= x1 + (MaxMix - y)*(MaxMix - v);
        if sum <> 0 then
        begin
          a:= (x1*MaxMix*2 + sum) div (2*sum);  // new 'v'
          a:= a + (x*v + y*(MaxMix - v)) shl (32 - MixBits*2);  // +new alpha
        end else
          a:= $FF000000;
        TransMix[i]:= a;
        inc(i);
      end;
end;

//----- 16 bit color resample

procedure ResampleH16_Opaque(var cmd: PByte; var p: puint;
   var v: uint; h, lh, lo: uint); inline;
var
  c: uint;
begin
  repeat
    // mix colors
    if v = MaxMix then
    begin
      p^:= h;
      inc(p);
      p^:= lo;
      inc(p);
    end else
    begin
      c:= h*v + lh*(MaxMix - v) + lo;
      p^:= (c and MixMask) div MaxMix;
      inc(p);
      p^:= c and MixRemainder;
      inc(p);
    end;
    inc(v, cmd^);
    inc(cmd);
  until v > MaxMix;
end;

function ResampleH16_Trans(var cmd: PByte; var p: puint;
   var v, h, lh, lo: uint; var ps: PWord; trans: int): Boolean; inline;
label
  start, stop;
const
  AlphaFF = ($FF000000 div MaxMix) and $FF000000;
  AlphaRemFF = $FF000000 and MixRemainder;
var
  n: int;
begin
  Result:= true;
  n:= 0;
start:
  // step 1: last value is non-transparent
  if h <> $FF000000 then
    while true do
    begin
      if v > MaxMix then
      begin
        dec(v, MaxMix);
        if v = MaxMix + 1 then
          goto stop;
        inc(ps);
        break;
      end else if v = MaxMix then
      begin
        inc(n);
        p^:= AlphaFF;
        inc(p);
        p^:= AlphaRemFF;
        inc(p);
      end else
      begin
        p^:= h + v shl (32 - MixBits*2);
        inc(p);
        p^:= lo;
        inc(p);
      end;
      inc(v, cmd^);
      inc(cmd);
    end;
  // step 2: fully transparent
  if ps^ = trans then
    while true do
    begin
      inc(n);
      p^:= AlphaFF;
      inc(p);
      p^:= AlphaRemFF;
      inc(p);
      inc(v, cmd^);
      inc(cmd);
      if v > MaxMix then
      begin
        dec(v, MaxMix);
        if v = MaxMix + 1 then
          goto stop;
        inc(ps);
        if ps^ <> trans then
          break;
      end;
    end;
  if n > 0 then
    puint(PChar(p) - n*8)^:= AlphaFF + n;  // RLE speed up
  n:= 0;
  // step 3: new non-transparent value
  h:= ToBits[ps^][0];
  lo:= ToBits[ps^][1];
  while true do
  begin
    if v > MaxMix then
    begin
      inc(ps);
      dec(v, MaxMix);
      if v = MaxMix + 1 then
        exit;
      if ps^ = trans then
        goto start;
      break;
    end else if v = MaxMix then
      p^:= h
    else
      p^:= h + (MaxMix - v) shl (32 - MixBits*2);
    inc(p);
    p^:= lo;
    inc(p);
    inc(v, cmd^);
    inc(cmd);
  end;
  Result:= false;
stop:
  if n > 0 then
    puint(PChar(p) - n*8)^:= AlphaFF + n;
end;

procedure ResampleH16_Any(cmd: PByte; ps: PWord; p: puint; trans: int; HasTrans: Boolean); inline;
var
  v: uint;
  h, lo, lh: uint;
begin
  h:= $FF000000;
  lo:= 0;
  lh:= 0;
  v:= MaxMix + cmd^;
  inc(cmd);
  if (v <> MaxMix*2) and (not HasTrans or (PWord(PChar(ps) - 2)^ <> trans)) then
  begin
    h:= ToBits[PWord(PChar(ps) - 2)^][0];
    lo:= ToBits[PWord(PChar(ps) - 2)^][1];
  end;
  while true do
  begin
    dec(v, MaxMix);
    if v = MaxMix + 1 then  break;
    // transparent?
    if HasTrans and (ps^ = trans) and ResampleH16_Trans(cmd, p, v, h, lh, lo, ps, trans) then
      exit;
    // read new source pixel
    lh:= h;
    h:= ToBits[ps^][0];
    lo:= ToBits[ps^][1];
    inc(ps);
    // non-transparent
    ResampleH16_Opaque(cmd, p, v, h, lh, lo);
  end;
end;

procedure ResampleH16(cmd: PByte; ps: PWord; p: puint);
begin
  ResampleH16_Any(cmd, ps, p, 0, false);
end;

procedure ResampleTransH16(cmd: PByte; ps: PWord; p: puint; trans: int);
begin
  ResampleH16_Any(cmd, ps, p, trans, true);
end;

procedure ResampleV(p, p2: puint; v: uint; pc, pl: puint);
var
  c, v2: uint;
begin
  v2:= MaxMix - v;
  if v2 = 0 then
    while p <> p2 do
    begin
      c:= pc^*MaxMix;
      inc(pc);
      p^:= c + pc^;
      inc(pc);
      inc(p);
    end
  else
    while p <> p2 do
    begin
      c:= pc^*v + pl^*v2;
      inc(pl, 2);
      inc(pc);
      p^:= c + pc^;
      inc(pc);
      inc(p);
    end;
end;

procedure ResampleTransV(p, p2: puint; v: uint; pc, pl: puint);
const
  AlphaFF = ($FF000000 div MaxMix) and $FF000000;
var
  tr: PIntegerArray;
  c, a: uint;
begin
  tr:= @TransMix[(v - 1) shl (MixBits*2 + 2)];
  if v = MaxMix then
    while p <> p2 do
    begin
      c:= pc^*MaxMix;
      inc(pc);
      p^:= c + pc^;
      inc(pc);
      inc(p);
    end
  else
    while p <> p2 do
    begin
      // TODO: use RLE optimization?
      v:= tr[pc^ shr (31 - MixBits*2) + pl^ shr (31 - MixBits*2) shl (MixBits + 1)];
      a:= v and $FF000000;
      v:= byte(v);
      c:= pc^*v + pl^*(MaxMix - v);
      inc(pl, 2);
      inc(pc);
      p^:= (c + pc^) and $FFFFFF + a;
      inc(pc);
      inc(p);
    end;
end;

procedure ResampleTransV_NoAlpha(p, p2: puint; v: uint; pc, pl: puint);
const
  AlphaFF = ($FF000000 div MaxMix) and $FF000000;
var
  tr: PIntegerArray;
  c: uint;
begin
  tr:= @TransMix[(v - 1) shl (MixBits*2 + 2)];
  if v = MaxMix then
    while p <> p2 do
    begin
      c:= pc^*MaxMix;
      inc(pc);
      if int(c) >= 0 then
        p^:= c + pc^
      else if c >= uint(AlphaFF)*MaxMix then  // RLE
      begin
        c:= c and $FFFFFF;
        inc(pc, c*2 div MaxMix - 1);
        inc(p, c div MaxMix);
        continue;
      end;
      inc(pc);
      inc(p);
    end
  else
    while p <> p2 do
    begin
      if pc^ shr (31 - MixBits*2) > 15 then
        msgH(pc^);
      v:= tr[pc^ shr (31 - MixBits*2) + pl^ shr (31 - MixBits*2) shl (MixBits + 1)];
      if int(v) >= 0 then
      begin
        v:= byte(v);
        c:= pc^*v + pl^*(MaxMix - v);
        inc(pl, 2);
        inc(pc);
        p^:= (c + pc^) and $FFFFFF;
        inc(pc);
        inc(p);
      end else
      if (v >= $FF000000) and (pc^ and pl^ >= AlphaFF) then  // RLE
      begin
        c:= max(pc^, pl^) and $FFFFFF;
        inc(pl, c*2);
        inc(pc, c*2);
        inc(p, c);
      end else
      begin
        inc(pl, 2);
        inc(pc, 2);
        inc(p);
      end;
    end;
end;

procedure RSResample16_Any(const info: TRSResampleInfo; Src: ptr; SrcPitch: int;
   Dest: ptr; DestPitch: int; Trans: int; HasTrans: Boolean; NoAlpha: Boolean); inline;
var
  buf: array of uint;
  pc, pl, p2: puint;
  cmd: PByte;
  v: uint;
begin
  if (info.DestW = 0) or (info.DestH = 0) then
    exit;
  if ToBits[$FFFF][0] = 0 then
    Prepare16to32;
  if HasTrans and (TransMix[MaxMix*2] = 0) then
    PrepareTransMix;
  inc(PChar(Src), info.SrcX*2 + info.SrcY*SrcPitch);
  inc(PChar(Dest), info.DestX*4 + info.DestY*DestPitch);
  SetLength(buf, info.DestW*4);
  pc:= ptr(buf);
  pl:= @buf[info.DestW*2];
  cmd:= ptr(info.CmdY);
  if cmd^ <> MaxMix then
    if HasTrans then
      ResampleTransH16(ptr(info.CmdX), Src, pc, trans)
    else
      ResampleH16(ptr(info.CmdX), ptr(PChar(Src) - SrcPitch), pc);
  v:= MaxMix;
  while true do
  begin
    inc(v, cmd^);
    inc(cmd);
    if v > MaxMix then
    begin
      dec(v, MaxMix);
      if v = MaxMix + 1 then  break;
      // scale new source line horizontally
      zSwap(pc, pl);
      if HasTrans then
        ResampleTransH16(ptr(info.CmdX), Src, pc, trans)
      else
        ResampleH16(ptr(info.CmdX), Src, pc);
      inc(PChar(Src), SrcPitch);
    end;
    // write dest line by scaling vertically using stored h-scaled lines
    p2:= Dest;
    inc(p2, info.DestW);
    if HasTrans then
      if NoAlpha then
        ResampleTransV_NoAlpha(Dest, p2, v, pc, pl)
      else
        ResampleTransV(Dest, p2, v, pc, pl)
    else
      ResampleV(Dest, p2, v, pc, pl);
    inc(PChar(Dest), DestPitch);
  end;
end;

procedure RSResample16(const info: TRSResampleInfo; Src: ptr; SrcPitch: IntPtr; Dest: ptr; DestPitch: IntPtr); overload;
begin
  RSResample16_Any(info, Src, SrcPitch, Dest, DestPitch, 0, false, false);
end;

procedure RSResample16(const info: TRSResampleInfo; Src, Dest: TBitmap); overload;
var
  s, d: PChar;
  sp, dp: IntPtr;
begin
  if info.SrcH = 0 then  exit;
  s:= Src.ScanLine[info.SrcH - 1];
  sp:= 0;
  if info.SrcH > 1 then
    sp:= Src.ScanLine[info.SrcH - 2] - s;
  d:= Dest.ScanLine[info.DestH - 1];
  dp:= 0;
  if info.DestH > 1 then
    dp:= Dest.ScanLine[info.DestH - 2] - d;
  RSResample16(info, s, sp, d, dp);
end;

procedure RSResample16(Src, Dest: TBitmap); overload;
var
  info: TRSResampleInfo;
begin
  info.Init(Src.Width, Src.Height, Dest.Width, Dest.Height);
  Src.HandleType:= bmDIB;
  Src.PixelFormat:= pf16bit;
  Dest.HandleType:= bmDIB;
  Dest.PixelFormat:= pf32bit;
  RSResample16(info, Src, Dest);
end;

procedure RSResampleTrans16(const info: TRSResampleInfo; Src: ptr; SrcPitch: int; Dest: ptr; DestPitch: int; Trans: int);
begin
  RSResample16_Any(info, Src, SrcPitch, Dest, DestPitch, Trans, true, false);
end;

procedure RSResampleTrans16_NoAlpha(const info: TRSResampleInfo; Src: ptr; SrcPitch: int; Dest: ptr; DestPitch: int; Trans: int);
begin
  RSResample16_Any(info, Src, SrcPitch, Dest, DestPitch, Trans, true, true);
end;

{ TRSResampleInfo }

function TRSResampleInfo.ScaleRect(const r: TRect): TRSResampleInfo;
begin
  Result.SrcW:= SrcW;
  Result.SrcH:= SrcH;
  Result.DestX:= r.Left + DestX;
  Result.DestW:= r.Right - r.Left;
  Result.DestY:= r.Top + DestY;
  Result.DestH:= r.Bottom - r.Top;
  Result.CmdX:= CutResampleArray(CmdX, r.Left, Result.DestW, Result.SrcX);
  inc(Result.SrcX, SrcX);
  Result.CmdY:= CutResampleArray(CmdY, r.Top, Result.DestH, Result.SrcY);
  inc(Result.SrcY, SrcY);
end;

procedure TRSResampleInfo.Init(sW, sH, dW, dH: int);
begin
  SrcX:= 0; SrcY:= 0; DestX:= 0; DestY:= 0;
  SrcW:= sW;
  SrcH:= sH;
  DestW:= dW;
  DestH:= dH;
  CmdX:= PrepareResampleArray(sW, dW);
  CmdY:= PrepareResampleArray(sH, dH);
end;

end.
