unit Unit2;

interface

uses
  SysUtils, Windows, Messages, SysConst, Classes, RSQ, Types, Graphics,
  RSGraphics, Math, RSSysUtils;

// I really should have turned this all into an object, but I was lazy.

procedure SoftenShadow(b:TBitmap);
procedure MakeShadow(b:TBitmap; BaseY, y0, x1, y1:int);
procedure MakeSelection(b:TBitmap);
procedure MakeShadowFaint(BmpSpec:TBitmap);

var
  SpecColors: array[0..255] of int; // Inverted
  NonSpecialColor: int; // Inverted
  HasSpecialColors: Boolean;
  SpecL, SpecH: int;
  MaxShadowColor:int = 8;

procedure MakeBmpSpec8Bit(Bmp, BmpSpec:TBitmap; Neutral:Byte = 255);
procedure MakeBmpSpec(Bmp, BmpSpec:TBitmap; Tolerance:int; Neutral:Byte = 255);
procedure MakePlayerBmp(Bmp, BmpSpec:TBitmap; Tolerance:int = 0);
procedure PutBmpSpec(Bmp, BmpSpec:TBitmap; Neutral:Byte = 255);
procedure AddBmpSpec(Bmp1, Bmp2:TBitmap; Neutral1:int = 0;  Neutral2:int = 0);
procedure DeleteShadow(BmpSpec:TBitmap);
procedure ReplaceSpecColors(Bmp:TBitmap; c:int; Tolerance:int = 0); // c is inverted
procedure MoveBmpSpec(b:TBitmap; x,y:int; Neutral:Byte);

procedure MakeNewPal(var HPal:HPALETTE; count: int);
procedure ExtractPic(Bmp, Result:TBitmap);

//procedure CheckSamePal();

implementation

const
  PlayerL = 224;
  PlayerH = 255;

function MyAnyTransform(Source:TBitmap; proc:TRSSmoothTransformProc;
           Width, Height:integer; ClipRect:TRect;
           UserData:pointer=nil):TBitmap; overload;

  function SqDifference(cl1,cl2:TColor):integer;
  begin
    Result:=sqr(Byte(cl1)-Byte(cl2))
            + sqr(Byte(cl1 shr 8)-Byte(cl2 shr 8))
            + sqr(Byte(cl1 shr 16)-Byte(cl2 shr 16));
  end;

var w,dy,x,y,x1,y1:integer; a,s:PByte;
    xp,yp:Real; p:TRSFloatPoint;
    col:array[0..3] of byte;
    per:array[0..3] of integer;
    AllP:integer;
begin
  if ClipRect.Left<0 then ClipRect.Left:=0;
  if ClipRect.Top<0 then ClipRect.Top:=0;
  if ClipRect.Right>Source.Width then ClipRect.Right:=Source.Width;
  if ClipRect.Bottom>Source.Height then ClipRect.Bottom:=Source.Height;

  if (Source.HandleType=bmDDB) or (Source.PixelFormat<>pf8bit) or
     (ClipRect.Right - ClipRect.Left < 0) or
     (ClipRect.Bottom - ClipRect.Top < 0) then
    Assert(false);

  if Width<=0 then Width:= ClipRect.Right - ClipRect.Left;
  if Height<=0 then Height:= ClipRect.Bottom - ClipRect.Top;

  w:=Source.Width;

  Result:=TBitmap.Create;
  Result.HandleType:=bmDIB;
  Result.PixelFormat:=pf8bit;
  //Result.Palette:=Source.Palette;
  Result.Width:=Width;
  Result.Height:=Height;
  if (Result.Width = 0) or (Result.Height = 0) then  exit;

  s:=Source.ScanLine[0];
  dy:= -((w+3) and not 3);
  a:=Result.ScanLine[Height-1];

//  dec(ClipRect.Right);
//  dec(ClipRect.Bottom);
  dec(Width);
  dec(Height);

  for y:=Height downto 0 do
  begin
    for x:=0 to Width do
    begin
      p:=proc(UserData,point(x,y),Source,Result);
      x1:=trunc(p.x+1);
      y1:=trunc(p.y+1);
      if (x1>=ClipRect.Left) and (x1<=ClipRect.Right) and
         (y1>=ClipRect.Top) and (y1<=ClipRect.Bottom) then
      begin
        xp:=Frac(p.X+1);
        yp:=Frac(p.Y+1);

        per[0]:=floor((1-xp)*(1-yp)*256);
        per[1]:=floor((xp)*(1-yp)*256);
        per[2]:=floor((1-xp)*(yp)*256);
        per[3]:=floor((xp)*(yp)*256);

        if y1>0 then
        begin
          if x1>0 then col[0]:=PByte(integer(s)+(x1-1)+(y1-1)*dy)^
          else per[0]:=0;
          if x1<Source.Width then col[1]:=PByte(integer(s)+(x1)+(y1-1)*dy)^
          else per[1]:=0;
        end else
        begin
          per[0]:=0;
          per[1]:=0;
        end;

        if y1<Source.Height then
        begin
          if x1>0 then col[2]:=PByte(integer(s)+(x1-1)+(y1)*dy)^
          else per[2]:=0;
          if x1<Source.Width then col[3]:=PByte(integer(s)+(x1)+(y1)*dy)^
          else per[3]:=0;
        end else
        begin
          per[2]:=0;
          per[3]:=0;
        end;

        {
        AllP:=0;
         // — учетом нужных преобразований
        if per[0]>=128 then
          for i:=max(y1-2, 0) to min(y1, Source.Height) do
            if PByte(integer(s)+(x1-1)+(i)*dy)^<=8 then
              AllP:=AllP or 1
            else
              AllP:=AllP or 2;

        if per[0]<>256 then
          for i:=0 to 3 do
            if per[i]<>0 then
              if col[i]<=8 then
                AllP:=AllP or 1
              else
                AllP:=AllP or 2;

        case AllP of
          0,1: a^:=0;
          2: a^:=4;
          3: a^:=1;
        end;
        }
        AllP:=0;
        if per[1]>per[0] then AllP:=1;
        if per[2]>per[AllP] then AllP:=2;
        if per[3]>per[AllP] then AllP:=3;
        if col[AllP]<=MaxShadowColor then
          a^:=0
        else
          a^:=4;
      end else
        a^:=0;
      inc(a);
    end;
    inc(a, 3-(Width mod 4));
  end;
end;


function TransformProc(UserData:pointer; p:TPoint;
                                Source,Dest:TBitmap):TRSFloatPoint;
var r:PRect; Form:PRSXForm;
begin
  r:=PPointer(UserData)^;
  inc(PPointer(UserData));
  Form:=PPointer(UserData)^;
  p.X:=p.X+r.Left;
  p.Y:=p.Y+r.Top;
  Result.X:=(p.X+0.5)*Form.eM11+(p.Y+0.5)*Form.eM12-0.5;
  Result.Y:=(p.X+0.5)*Form.eM21+(p.Y+0.5)*Form.eM22-0.5;
 // 0.5 - это поправка на то, что пиксели - это не точки, а квадраты.
end;

function MyTransform(Source:TBitmap; Form:TRSXForm;
           Rect:TRect; CutRect:boolean;
           FirstPoint:PPoint=nil; PointsCount:DWord=0):TBitmap; overload;
var r:TRect;

  procedure ChangeRect(x,y:integer);
  var i,j:integer;
  begin
    i:=round(x*Form.eM11+y*Form.eM12);
    j:=round(x*Form.eM21+y*Form.eM22);
    if i<r.Left then r.Left:=i;
    if j<r.Top then r.Top:=j;
    if i>r.Right then r.Right:=i;
    if j>r.Bottom then r.Bottom:=j;
  end;

var w,h,x,y:integer;
    sr:TRect; UD:array[0..1] of pointer;
begin
  w:=Source.Width;
  h:=Source.Height;

  if Rect.Left<0 then Rect.Left:=0;
  if Rect.Top<0 then Rect.Top:=0;
  if Rect.Right>w then Rect.Right:=w;
  if Rect.Bottom>h then Rect.Bottom:=h;

  if (Source.HandleType=bmDDB) or (Source.PixelFormat<>pf8bit) or
     (Rect.Left>Rect.Right) or (Rect.Top>Rect.Bottom) then
    Assert(false);

  if CutRect then sr:=Rect
  else begin
    sr.Left:=0;
    sr.Top:=0;
    sr.Right:=Source.Width;
    sr.Bottom:=Source.Height;
  end;

  r.Left:=MaxInt;
  r.Top:=MaxInt;
  r.Right:=-MaxInt-1;
  r.Bottom:=-MaxInt-1;

  Form.eM12:=-Form.eM12; // ¬ математике ось y идет в другую сторону
  Form.eM21:=-Form.eM21;

  ChangeRect(Rect.Left,Rect.Top); // —читаем размеры результата
  ChangeRect(Rect.Right,Rect.Top);
  ChangeRect(Rect.Left,Rect.Bottom);
  ChangeRect(Rect.Right,Rect.Bottom);

  for x:=1 to PointsCount do // “очки прив€зки - дл€ удобства юзеров
  begin
    y:=FirstPoint.Y;
    FirstPoint.Y:=round((FirstPoint.X+0.5)*Form.eM21+(y+0.5)*Form.eM22-0.5)-r.Top;
    FirstPoint.X:=round((FirstPoint.X+0.5)*Form.eM11+(y+0.5)*Form.eM12-0.5)-r.Left;
    inc(FirstPoint);
   // 0.5 - это поправка на то, что пиксели - это не точки, а квадраты.
  end;

  Form.Inverse; // ќбратна€ матрица

  UD[0]:=@r;
  UD[1]:=@Form;
  Result:=MyAnyTransform(Source, TransformProc,
   (r.Right-r.Left), (r.Bottom-r.Top), sr, @UD);
end;

procedure SoftenShadow(b:TBitmap);
var x,y,w,h,dy:int; p:PChar;
begin
  w:=b.Width;
  h:=b.Height;
  dy:= (-w) and not 3;
  p:=b.ScanLine[0];

  for y:=0 to h-1 do
  begin
    for x:=0 to w-1 do
    begin
      if (p^=#4) and ((x=0) or ((p-1)^=#0) or (y=0) or ((p-dy)^=#0) or
                     (x+1=w) or ((p+1)^=#0) or (y+1=h) or ((p+dy)^=#0)) then
        p^:=#1;
      inc(p);
    end;
    inc(p, dy-w);
  end;
end;

procedure MakeShadow(b:TBitmap; BaseY, y0, x1, y1:int);
var x,y,w,h,dy,dy1:int; xf:TRSXForm; b1:TBitmap; p,p1:PByte;
begin
  if BaseY < 0 then  exit; // !!! Ќе сработает, если тень идет не в ту сторону

  if y0 > 0 then
  begin
    y0:= -y0;
    x1:= -x1;
    y1:= -y1;
  end;
  xf.SetTransform(Point(0,0), Point(-y0,0), Point(0, -y0),
                  Point(0,0), Point(-y0,0), Point(x1, -y1));
  b1:=MyTransform(b, xf, Rect(0, 0, MaxInt, BaseY), true);
  if (b1.Width = 0) or (b1.Height = 0) or (BaseY - b1.Height > b.Height) then // !!!
  begin
    SoftenShadow(b);
    exit;
  end;

  w:=b.Width;
  x:=b1.Width;
  if x1 < 0 then
    x1:= x - w
  else
    x1:= 0;

  h:=b1.Height;
  if y1 <= 0 then
    y1:=BaseY - h
  else
    y1:=BaseY;

  y:=max(y1, 0);
  p:=b.ScanLine[y];
  h:=min(h + y1 - y, b.Height - y);
  p1:=b1.ScanLine[y - y1];
  inc(p1, x1);
  dy:=(-w) and not 3 - w;
  dy1:=(-x) and not 3 - w;

  for y:=h downto 1 do
  begin
    for x:=w downto 1 do
    begin
      p^:=max(p^, p1^);
      inc(p);
      inc(p1);
    end;
    inc(p, dy);
    inc(p1, dy1);
  end;
  SoftenShadow(b);
end;

procedure MakeSelection(b:TBitmap);
var x,y,w,h,dy:int; p:PChar;
begin
  w:=b.Width;
  h:=b.Height;
  dy:= (-w) and not 3;
  p:=b.ScanLine[0];

  for y:=0 to h-1 do
  begin
    for x:=0 to w-1 do
    begin
      if (byte(p^)<=8) and
         ( (x>0) and (byte((p-1)^)>8) or (y>0) and (byte((p-dy)^)>8) or
           (x+1<w) and (byte((p+1)^)>8) or (y+1<h) and (byte((p+dy)^)>8) ) then
        case byte(p^) of
          1,7: p^:=#7;
          4,6: p^:=#6;
          else
            p^:=#5;
        end;
      inc(p);
    end;
    inc(p, dy-w);
  end;
end;

procedure MakeShadowFaint(BmpSpec:TBitmap);
var x,w,h:int; p:PByte;
begin
  h:= BmpSpec.Height;
  w:= -((-BmpSpec.Width) and not 3)*h;
  p:= BmpSpec.ScanLine[h-1];

  for x:= w downto 1 do
  begin
    if p^ = 4 then  p^:= 1  else
    if p^ = 6 then  p^:= 7;
    inc(p);
  end;
end;

procedure MakeBmpSpec8Bit(Bmp, BmpSpec:TBitmap; Neutral:Byte = 255);
var
  i,x,y,w,h,dy:int; p, p1:PByte;
begin
  w:=Bmp.Width;
  h:=Bmp.Height;
  with Bmp do
  begin
    HandleType:=bmDIB;
    PixelFormat:=pf8bit;
  end;
  with BmpSpec do
  begin
    Height:=0;
    HandleType:=bmDIB;
    PixelFormat:=pf8bit;
    Width:=w;
    Height:=h;
  end;

  if h = 0 then  exit;
  p:=Bmp.ScanLine[h-1];
  p1:=BmpSpec.ScanLine[h-1];
  dy:= (-w) and 3;

  for y:= h downto 1 do
  begin
    for x:= w downto 1 do
    begin
      i:=p^;
      if (i >= SpecL) and (i <= SpecH) and (SpecColors[i] >= 0) then
      begin
        p1^:= i;
        HasSpecialColors:= true;
      end else
        p1^:= Neutral;
        
      inc(p);
      inc(p1);
    end;
    inc(p, dy);
    inc(p1, dy);
  end;
end;

procedure MakeBmpSpec(Bmp, BmpSpec:TBitmap; Tolerance:int; Neutral:Byte = 255);
label  Next;
var
  i,j,x,y,w,h,dy:int; p:pint; p1:PByte;
begin
  Tolerance:=sqr(Tolerance);
  w:=Bmp.Width;
  h:=Bmp.Height;
  with Bmp do
  begin
    HandleType:=bmDIB;
    PixelFormat:=pf32bit;
  end;
  with BmpSpec do
  begin
    Height:=0;
    HandleType:=bmDIB;
    PixelFormat:=pf8bit;
    Width:=w;
    Height:=h;
  end;
  if h = 0 then  exit;
  p:=Bmp.ScanLine[h-1];
  p1:=BmpSpec.ScanLine[h-1];
  dy:= (-w) and 3;
  for y:= h downto 1 do
  begin
    for x:= w downto 1 do
    begin
      i:=SpecL;
      j:=p^;
      while (i<=SpecH) and (j<>SpecColors[i]) do  inc(i);

      if i>SpecH then
      begin
        p1^:=Neutral;

        if (not HasSpecialColors or (NonSpecialColor < 0)) and
           (SpecColors[255] >= 0) then
          if Tolerance <> 0 then
            for i:=224 to 255 do
              if SqDifference(j, SpecColors[i])<=Tolerance then
              begin
                HasSpecialColors:= true;
                goto Next;
              end else
          else
            for i:=224 to 255 do
              if j = SpecColors[i] then
              begin
                HasSpecialColors:= true;
                goto Next;
              end;

        if NonSpecialColor < 0 then
          NonSpecialColor:=j;
      end else
      begin
        p1^:= i;
        HasSpecialColors:= true;
      end;
Next:
      inc(p);
      inc(p1);
    end;
    inc(p1, dy);
  end;
end;

procedure MakePlayerBmp(Bmp, BmpSpec:TBitmap; Tolerance:int = 0);
const
  Neutral = 0;
var
  i,j,k,x,y,w,h,dy:int; Dif, MinDif:int; p:pint; p1:PByte;
begin
  Tolerance:= sqr(Tolerance);
  w:= Bmp.Width;
  h:= Bmp.Height;
  with Bmp do
  begin
    HandleType:= bmDIB;
    PixelFormat:= pf32bit;
  end;
  with BmpSpec do
  begin
    Height:= 0;
    HandleType:= bmDIB;
    PixelFormat:= pf8bit;
    Width:= w;
    Height:= h;
  end;
  p:= Bmp.ScanLine[h-1];
  p1:= BmpSpec.ScanLine[h-1];
  dy:= (-w) and 3;
  for y:= h-1 downto 0 do
  begin
    for x:= w downto 1 do
    begin
      j:=p^;
      if Tolerance = 0 then
      begin
        i:=PlayerL;
        while (i<=PlayerH) and (j<>SpecColors[i]) do  inc(i);
        if i>PlayerH then
          i:=Neutral;
        p1^:=i;
      end else
      begin
        MinDif:= Tolerance+1;
        k:= Neutral;
        for i:=PlayerL to PlayerH do
        begin
          Dif:= SqDifference(j, SpecColors[i]);
          if Dif<MinDif then
          begin
            k:=i;
            MinDif:=Dif;
          end;
        end;
        p1^:=k;
      end;
      inc(p);
      inc(p1);
    end;
    inc(p1, dy);
  end;
end;

procedure PutBmpSpec(Bmp, BmpSpec:TBitmap; Neutral:Byte = 255);
var x,y,w,h,dy:int; p:pint; p1:PByte;
begin
  with Bmp do
  begin
    HandleType:= bmDIB;
    PixelFormat:= pf32bit;
    w:= BmpSpec.Width;
    h:= BmpSpec.Height;
    Width:= w;
    Height:= h;
  end;
  p:= Bmp.ScanLine[h-1];
  p1:= BmpSpec.ScanLine[h-1];
  dy:= (-w) and 3;
  for y:= h downto 1 do
  begin
    for x:= w downto 1 do
    begin
      if p1^<>Neutral then
        p^:=SpecColors[p1^];
      inc(p);
      inc(p1);
    end;
    inc(p1, dy);
  end;
end;

procedure AddBmpSpec(Bmp1, Bmp2:TBitmap; Neutral1:int = 0;  Neutral2:int = 0);
var x,y,w,h,dy:int; p, p1:PByte;
begin
  w:=Bmp1.Width;
  h:=Bmp1.Height;
  p:=Bmp1.ScanLine[h-1];
  p1:=Bmp2.ScanLine[h-1];
  dy:= (-w) and 3;
  for y:= h downto 1 do
  begin
    for x:= w downto 1 do
    begin
      if (p1^<>Neutral1) and (p1^<>Neutral2) then
        p^:= p1^;
      inc(p);
      inc(p1);
    end;
    inc(p, dy);
    inc(p1, dy);
  end;
end;

procedure DeleteShadow(BmpSpec:TBitmap);
var x,w,h:int; p:PByte;
begin
  h:= BmpSpec.Height;
  w:= -((-BmpSpec.Width) and not 3)*h;
  p:= BmpSpec.ScanLine[h-1];

  for x:= w downto 1 do
  begin
    if p^ in [1..MaxShadowColor] then
      p^:=0;
    inc(p);
  end;
end;

{
function NonSpecColor(Bmp:TBitmap):int;
var i,k,w:int; p:pint;
begin
  w:=Bmp.Height;
  p:=Bmp.Scanline[w-1];
  w:=w*Bmp.Width;
  for i:=1000 downto 1 do
  begin
    k:=pint(int(p) + random(w)*4)^;
    if not IsSpecial(k) then
    begin
      Result:=k;
      exit;
    end;
  end;
  for i:=w downto 1 do
  begin
    k:=p^;
    if not IsSpecial(k) then
    begin
      Result:=k;
      exit;
    end;
    inc(p);
  end;
end;
}

function IsSpecial(c:int; Tolerance:int):Boolean;
var i:int;
begin
  Result:= true;
  for i:=SpecL to SpecH do
    if SpecColors[i]=c then
      exit;

  if SpecColors[PlayerH]>=0 then
    if Tolerance <> 0 then
    begin
      for i:= PlayerL to PlayerH do
        if SqDifference(SpecColors[i], c) <= Tolerance then
          exit;
    end else
      for i:= PlayerL to PlayerH do
        if SpecColors[i] = c then
          exit;

  Result:= false;
end;

procedure ReplaceSpecColors(Bmp:TBitmap; c:int; Tolerance:int = 0);
var i,w:int; p:pint;
begin
  Tolerance:= sqr(Tolerance);
  with Bmp do
  begin
    HandleType:= bmDIB;
    PixelFormat:= pf32bit;
  end;
  w:=Bmp.Height;
  p:=Bmp.Scanline[w-1];
  w:=w*Bmp.Width;
  for i:=w downto 1 do
  begin
    if IsSpecial(p^, Tolerance) then
      p^:=c;
    inc(p);
  end;
end;

procedure MoveBmpSpec(b:TBitmap; x,y:int; Neutral:Byte);
var w,h,dy,x1,x2,nx,nw,nh,dp:int; p:PChar;
begin
  if (x = 0) and (y = 0) then  exit;
  w:= b.Width;
  h:= b.Height;
  dy:= (-w) and not 3;
  if y<0 then
  begin
    dy:= -dy;
    p:= b.ScanLine[h-1];
  end else
    p:= b.ScanLine[0];

  nh:= min(abs(y), h);
  dec(h, nh);
  nw:= min(abs(x), w);
  if x<0 then
  begin
    x1:= 0;
    x2:= nw;
    nx:= w - nw;
  end else
  begin
    x1:= nw;
    x2:= 0;
    nx:= 0;
  end;
  dec(w, nw);
  dp:= dy*nh;

  for y:=h downto 1 do
  begin
    CopyMemory(p+x1, p+dp+x2, w);
    FillChar((p+nx)^, nw, Neutral);
    inc(p, dy);
  end;
  inc(w, nw);
  for y:=nh downto 1 do
  begin
    FillChar(p^, w, Neutral);
    inc(p, dy);
  end;
end;

var
  NewPal: array[-1..255] of int;
  Places: array[0..255] of int; // f: Old -> New

procedure MakeNewPal(var HPal:HPALETTE; count: int);
var
  Pal: array[-1..255] of int;
  i,j:int;
begin
  GetPaletteEntries(HPal, 0, 256, Pal[0]);
  for i := count to 255 do
    Pal[i]:= Pal[0];

  Pal[-1]:=$1000300;
  DeleteObject(HPal);
  HPal:= CreatePalette(PLogPalette(@Pal)^);

  NewPal[-1]:=$1000300;
  j:=0;
  for i:=0 to 255 do
    if SpecColors[i]<0 then
    begin
      NewPal[i]:= Pal[j];
      Places[j]:= i;
      inc(j);
    end else
      NewPal[i]:= RSSwapColor(SpecColors[i]);

  for j:= j to count - 1 do
    Places[j]:= j;
  for j:= count to 255 do
    Places[j]:= Places[0];
end;

procedure ExtractPic(Bmp, Result:TBitmap);
var x,y,dy,dy1,w,h:int; p,p1:pbyte;
begin
  w:= Bmp.Width;
  h:= Bmp.Height;
  with Result do
  begin
    Height:= 0;
    HandleType:= bmDIB;
    PixelFormat:= pf8bit;
    Palette:= CreatePalette(PLogPalette(@NewPal)^);
    Width:= w;
    Height:= h;
  end;
  if h=0 then  exit;
  dy:= (-w) and 3;
  dy1:= (-w) and 3;
  p:= Bmp.ScanLine[h-1];
  p1:= Result.ScanLine[h-1];
  for y:= h downto 1 do
  begin
    for x:= w downto 1 do
    begin
      p1^:= Places[p^];
      inc(p);
      inc(p1);
    end;
    inc(p, dy);
    inc(p1, dy1);
  end;
end;

end.
