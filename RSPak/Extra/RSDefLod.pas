unit RSDefLod;

{ *********************************************************************** }
{                                                                         }
{ Copyright (c) Rozhenko Sergey                                           }
{ http://sites.google.com/site/sergroj/                                   }
{ sergroj@mail.ru                                                         }
{                                                                         }
{ See copyright notice at the end of RSSysUtils.pas file (MIT license).   }
{                                                                         }
{ *********************************************************************** }
{$I RSPak.inc}

interface

uses
  Windows, Classes, Messages, SysUtils, RSQ, Graphics, RSSysUtils, RSGraphics;

function RSMakePalette(HeroesPal:pointer):HPalette;

function RSMakeLogPalette(HeroesPal:pointer):PLogPalette;
procedure RSWritePalette(HeroesPal:pointer; Pal:HPALETTE);
function RSGetNonZeroColorRect(b: TBitmap): TRect;

implementation

type
  TLogPal = packed record
    palVersion: Word;
    palNumEntries: Word;
    palPalEntry: packed array[0..255] of TPaletteEntry;
  end;

  THeroesPalEntry = packed record
    Red:Byte;
    Green:Byte;
    Blue:Byte;
  end;
  THeroesPal = packed array[0..255] of THeroesPalEntry;
  PHeroesPal = ^THeroesPal;

function RSMakePalette(HeroesPal:pointer):HPalette;
var Pal:PLogPalette;
begin
  Pal:=RSMakeLogPalette(HeroesPal);
  Result:=RSWin32Check(CreatePalette(Pal^));
  FreeMem(Pal, 4 + 256*4);
end;

function RSMakeLogPalette(HeroesPal:pointer):PLogPalette;
var
  HerPal: PHeroesPal;
  i: int;
begin
  GetMem(Result, 4 + 256*4);
  HerPal:=HeroesPal;
  Result.palVersion:=$300;
  Result.palNumEntries:=256;
  for i:=0 to 255 do
  begin
    Result.palPalEntry[i].peRed:= HerPal[i].Red;
    Result.palPalEntry[i].peGreen:= HerPal[i].Green;
    Result.palPalEntry[i].peBlue:= HerPal[i].Blue;
    Result.palPalEntry[i].peFlags:= 0;
  end;
end;

procedure RSWritePalette(HeroesPal:pointer; Pal:HPALETTE);
var
  HerPal: PHeroesPal; LogPal: TLogPal;
  i: int;
begin
  HerPal:=HeroesPal;
  GetPaletteEntries(Pal, 0, 256, LogPal.palPalEntry[0]);
  for i:=0 to 255 do
  begin
    HerPal[i].Red:= LogPal.palPalEntry[i].peRed;
    HerPal[i].Green:= LogPal.palPalEntry[i].peGreen;
    HerPal[i].Blue:= LogPal.palPalEntry[i].peBlue;
  end;
end;

 // Frame otside which there are only 0 pixels.
function RSGetNonZeroColorRect(b: TBitmap): TRect;
var p:PByte; i,j,dy,w,h:int;
begin
  w:=b.Width;
  h:=b.Height;
  if (w=0) or (h=0) then
  begin
    Result:=Rect(0,0,0,0);
    exit;
  end;
  p:=b.ScanLine[0];
  dy:= (-w) and not 3 - w; // scanline length + width that's been travelled
  with Result do
  begin
    Left:=w;
    Top:=h;
    Right:=-1;
    Bottom:=-1;
  end;
  for j:=0 to h-1 do
  begin
    for i:=0 to w-1 do
    begin
      if p^<>0 then
        with Result do
        begin
          if Left>i then Left:=i;
          if Top>j then Top:=j;
          if Right<i then Right:=i;
          if Bottom<j then Bottom:=j;
        end;
      inc(p);
    end;
    inc(p, dy);
  end;
  inc(Result.Right);
  inc(Result.Bottom);
  if Result.Right=0 then
  begin
    Result.Left:=0;
    Result.Top:=0;
  end;
end;

end.
