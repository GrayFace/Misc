unit RSImgList;

{ *********************************************************************** }
{                                                                         }
{ RSPak                                    Copyright (c) Rozhenko Sergey  }
{ http://sites.google.com/site/sergroj/                                   }
{ sergroj@mail.ru                                                         }
{                                                                         }
{ See copyright notice at the end of RSSysUtils.pas file (MIT license).   }
{                                                                         }
{ *********************************************************************** }
{$I RSPak.inc}

interface

uses Windows, Classes, SysUtils, Graphics, Math, RSQ, ImgList, CommCtrl;

function RSImgListToBmp(il:TCustomImageList; Index:int; Bmp:TBitmap=nil):TBitmap;

implementation

function GetRGBColor(Value: TColor): DWORD;
begin
  Result := ColorToRGB(Value);
  case Result of
    clNone: Result := CLR_NONE;
    clDefault: Result := CLR_DEFAULT;
  end;
end;

function RSImgListToBmp(il:TCustomImageList; Index:int;  Bmp:TBitmap=nil):TBitmap;
var
  b: TBitmap;
begin
  if Bmp<>nil then
    Bmp.Height:= 0
  else
    Bmp:=TBitmap.Create;

  with Bmp do
  begin
    Width:=il.Width;
    Height:=il.Height;

    il.Draw(Canvas, 0, 0, Index);
    Transparent:= true;
    b:= TBitmap.Create;
    try
      b.HandleType:= bmDIB;
      b.Handle:= MaskHandle;
      b.Canvas.Brush.Color:= clWhite;
      b.Canvas.FillRect(Rect(0, 0, Width, Height));
      ImageList_Draw(il.Handle, Index, b.Canvas.Handle, 0, 0, ILD_MASK);
      MaskHandle:= b.ReleaseHandle;
    finally
      b.Free;
    end;
  end;
  Result:=Bmp;
end;

end.
