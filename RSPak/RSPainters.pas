unit RSPainters;

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

uses
  Windows, Classes, Graphics, RSGraphics, RSQ;

type
  TRSColorTheme = class(TComponent)
  protected
    USelected1: TColor;
    USelected2: TColor;
    USelBorder: TColor;
    USelButton1: TColor;
    USelButton2: TColor;
    ULight: TColor;
    UDark: TColor;
    UCheck: TColor;
    UCheckedButton: TColor;
    URaised1: TColor;
    URaised2: TColor;
    UDisabled: TColor;
    UButton: TColor;
    UMenu: TColor;
    UGutter: TColor;

    FSelected1: TColor;
    FSelected2: TColor;
    FSelBorder: TColor;
    FSelButton1: TColor;
    FSelButton2: TColor;
    FLight: TColor;
    FDark: TColor;
    FCheck: TColor;
    FCheckedButton: TColor;
    FRaised1: TColor;
    FRaised2: TColor;
    FDisabled: TColor;
    FButton: TColor;
    FMenu: TColor;
    FGutter: TColor;

    FHighlight: TColor;
//    FSpecColors: array of TColor;

    FGrayscaleDisable: Boolean;
    FRaisedGlyphs: Boolean;

    procedure Initialize;
    function CheckCl(U:TColor; var F:TColor):boolean;
  public
//    SpecColors: array of TColor;

    constructor Create(AOwner:TComponent); override;

    procedure Assign(Source: TPersistent); override;

    procedure ColorsChanged;
    function CheckColors:boolean;

    procedure DrawGlyph(Canvas:TCanvas; x,y:int; Glyph:TBitmap;
       State:TOwnerDrawState; Back:TColor; TempGlyph:boolean=false);
    procedure DrawCheck(Canvas:TCanvas; r:TRect; Enabled:Boolean; RectEl:int; GradientEdge:int=1);
    procedure DrawHotTrackBackground(Canvas:TCanvas; const r:TRect);


    property Selected1: TColor read FSelected1;
    property Selected2: TColor read FSelected2;
    property SelBorder: TColor read FSelBorder;
    property SelButton1: TColor read FSelButton1;
    property SelButton2: TColor read FSelButton2;
    property Light: TColor read FLight;
    property Dark: TColor read FDark;
    property Check: TColor read FCheck;
    property CheckedButton: TColor read FCheckedButton;
    property Raised1: TColor read FRaised1;
    property Raised2: TColor read FRaised2;
    property Disabled: TColor read FDisabled;
    property Button: TColor read FButton;
    property Menu: TColor read FMenu;
    property Gutter: TColor read FGutter;
  published
    property SelectedColor1: TColor read USelected1 write USelected1 default clDefault;
    property SelectedColor2: TColor read USelected2 write USelected2 default clDefault;
    property SelBorderColor: TColor read USelBorder write USelBorder default clDefault;
    property SelButtonColor1: TColor read USelButton1 write USelButton1 default clDefault;
    property SelButtonColor2: TColor read USelButton2 write USelButton2 default clDefault;
    property LightColor: TColor read ULight write ULight default clDefault;
    property DarkColor: TColor read UDark write UDark default clDefault;
    property CheckColor: TColor read UCheck write UCheck default clDefault;
    property CheckedButtonColor: TColor read UCheckedButton write UCheckedButton default clDefault;
    property RaisedColor1: TColor read URaised1 write URaised1 default clDefault;
    property RaisedColor2: TColor read URaised2 write URaised2 default clDefault;
    property DisabledColor: TColor read UDisabled write UDisabled default clBtnShadow;
    property ButtonColor: TColor read UButton write UButton default clBtnFace;
    property MenuColor: TColor read UMenu write UMenu default clMenu;
    property GutterColor: TColor read UGutter write UGutter default clDefault;

    property GrayscaleDisable:boolean read FGrayscaleDisable write FGrayscaleDisable default true;
    property RaisedGlyphs: Boolean read FRaisedGlyphs write FRaisedGlyphs default true;
  end;

function RSColorTheme:TRSColorTheme;

{
 // Used internally
procedure RSSetCommonColors(var FColors:TRSColorTheme; v:boolean);
}

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('RSPak', [TRSColorTheme]);
end;

var
  Theme: TRSColorTheme;

function RSColorTheme:TRSColorTheme;
begin
  if Theme=nil then
    Theme:=TRSColorTheme.Create(nil);
  Result:=Theme;
end;

function SqDifference(cl1,cl2:TColor):integer;
begin
  cl1:=ColorToRGB(cl1);
  cl2:=ColorToRGB(cl2);
  Result:=sqr(Byte(cl1)-Byte(cl2))
          + sqr(Byte(cl1 shr 8)-Byte(cl2 shr 8))
          + sqr(Byte(cl1 shr 16)-Byte(cl2 shr 16));
end;

constructor TRSColorTheme.Create(AOwner:TComponent);
begin
  inherited;
  Initialize;
  ColorsChanged;
end;

procedure TRSColorTheme.Initialize;
begin
  USelected1:=clDefault;
  USelected2:=clDefault;
  USelBorder:=clDefault;
  USelButton1:=clDefault;
  USelButton2:=clDefault;
  ULight:=clDefault;
  UDark:=clDefault;
  UCheck:=clDefault;
  UCheckedButton:=clDefault;
  URaised1:=clDefault;
  URaised2:=clDefault;

  UDisabled:=clBtnShadow;
  UButton:=clBtnFace;
  UMenu:=clMenu;
  UGutter:=clDefault; //clBtnFace;

  FGrayscaleDisable:=true;
  FRaisedGlyphs:=true;
end;

procedure TRSColorTheme.Assign(Source: TPersistent);
var c:TRSColorTheme;
begin
  if Source = nil then
    Initialize
  else
    if Source is TRSColorTheme then
    begin
{      // Удобно, но немного кривовато
      SpecColors:=nil;
      FSpecColors:=nil;
      i:=TPersistent.InstanceSize;
      j:=TRSColorTheme.InstanceSize;
      CopyMemory(ptr(int(Self)+i), ptr(int(Source)+i), j-i);
      ptr(SpecColors):=nil;
      ptr(FSpecColors):=nil;
      SpecColors:=TRSColorTheme(Source).SpecColors;
      FSpecColors:=TRSColorTheme(Source).FSpecColors;
}
  // Для бешенной собаки с макросами в текстовом редакторе 20 строк - не крюк
      c:=TRSColorTheme(Source);

      USelected1:= c.USelected1;
      USelected2:= c.USelected2;
      USelBorder:= c.USelBorder;
      USelButton1:= c.USelButton1;
      USelButton2:= c.USelButton2;
      ULight:= c.ULight;
      UDark:= c.UDark;
      UCheck:= c.UCheck;
      UCheckedButton:= c.UCheckedButton;
      URaised1:= c.URaised1;
      URaised2:= c.URaised2;
      UDisabled:= c.UDisabled;
      UButton:= c.UButton;
      UMenu:= c.UMenu;
      UGutter:= c.UGutter;

      FSelected1:= c.FSelected1;
      FSelected2:= c.FSelected2;
      FSelBorder:= c.FSelBorder;
      FSelButton1:= c.FSelButton1;
      FSelButton2:= c.FSelButton2;
      FLight:= c.FLight;
      FDark:= c.FDark;
      FCheck:= c.FCheck;
      FCheckedButton:= c.FCheckedButton;
      FRaised1:= c.FRaised1;
      FRaised2:= c.FRaised2;
      FDisabled:= c.FDisabled;
      FButton:= c.FButton;
      FMenu:= c.FMenu;
      FGutter:= c.FGutter;

      FHighlight:= c.FHighlight;
      //FSpecColors:= c.FSpecColors;
      //SpecColors:= c.SpecColors;
      FGrayscaleDisable:= c.FGrayscaleDisable;
      FRaisedGlyphs:= c.FRaisedGlyphs;
    end else
      inherited;
end;

procedure TRSColorTheme.ColorsChanged;
var i:integer;
begin
  FSelected1:= ColorToRGB(USelected1);
  FSelected2:= ColorToRGB(USelected2);
  FSelBorder:= ColorToRGB(USelBorder);
  FLight:= ColorToRGB(ULight);
  FDark:= ColorToRGB(UDark);
  FCheck:= ColorToRGB(UCheck);
  FCheckedButton:= ColorToRGB(UCheckedButton);
  FRaised1:= ColorToRGB(URaised1);
  FRaised2:= ColorToRGB(URaised2);
  FDisabled:= ColorToRGB(UDisabled);
  FButton:= ColorToRGB(UButton);
  FMenu:= ColorToRGB(UMenu);
  FGutter:= ColorToRGB(UGutter);

  if USelBorder=clDefault then
  begin
    FSelBorder := ColorToRGB(clHighlight);
     // Затемняем слишком светлые цвета.
     // Office XP поступает так же, но делает это как-то иначе
    i:=RSGetIntensity(FSelBorder);
    if i>170 then
      FSelBorder := RSAdjustIntensity(FSelBorder,170-i);
  end;

  if UGutter=clDefault then
  begin
    FGutter:= ColorToRGB(clBtnFace);
    if FGutter = FMenu then
      FGutter:= RSMixColorsRGB(FGutter, FDisabled, 190);
  end;
  
  if USelected2=clDefault then
  begin
     // Почти как в Office
    FSelected2:=RSMixColorsRGB(FSelBorder,clWhite,75);

    if SqDifference(FSelBorder, FMenu)>2000 then
      while SqDifference(FSelected2, FMenu)<1100 do
        FSelected2:= RSMixColorsRGB(FSelBorder, FSelected2, 30);

    if SqDifference(FSelBorder, FGutter)>2000 then
      while SqDifference(FSelected2, FGutter)<1100 do
        FSelected2:= RSMixColorsRGB(FSelBorder, FSelected2, 30);
  end;

  if USelected1=clDefault then
    FSelected1:= RSMixColorsRGB(FSelected2, clWhite, 150);

  if ULight=clDefault then
    FLight:= RSMixColorsRGB(FSelected2, clWhite, 40);

  if UDark=clDefault then
    FDark:= RSMixColorsRGB(FSelBorder, FSelected1, 100);

  if UCheck=clDefault then
    FCheck:= RSMixColorsRGB(FSelected2, clWhite, 160);

  if UCheckedButton=clDefault then
    FCheckedButton:= RSMixColorsRGB(FCheck, FButton, 180);

  if URaised1=clDefault then
    FRaised1:= RSMixColorsRGB(FLight, FButton{FGutter}, 170);

  if URaised2=clDefault then
    FRaised2:= RSAdjustIntensity(FSelected2, -60);

  if USelButton1=clDefault then
    FSelButton1:= RSMixColorsRGB(FSelected1, FLight, 90);

  if USelButton2=clDefault then
    FSelButton2:= FSelected2;

  FHighlight:= ColorToRGB(clHighlight);
  {
  SetLength(FSpecColors, length(SpecColors));
  for i:=0 to length(SpecColors)-1 do
    FSpecColors[i]:= ColorToRGB(SpecColors[i]);
  }  
end;

function TRSColorTheme.CheckCl(U:TColor; var F:TColor):boolean;
begin
  if U<>clDefault then
  begin
    U:=ColorToRGB(U);
    Result:= F<>U;
    F:=U;
  end else
    Result:=false;
end;

function TRSColorTheme.CheckColors:boolean;
//var i:integer;
begin
  Result:=false;
  {
  if length(SpecColors)<>length(FSpecColors) then
    Result:=true
  else
    for i:=0 to length(SpecColors)-1 do
    begin
      Result:=ColorToRGB(SpecColors[i])<>FSpecColors[i];
      if Result then Break;
    end;
  }  

  if USelBorder=clDefault then
    Result:= CheckCl(clHighlight, FHighlight) or Result;

  Result:= CheckCl(USelected1, FSelected1) or Result;
  Result:= CheckCl(USelected2, FSelected2) or Result;
  Result:= CheckCl(USelBorder, FSelBorder) or Result;
  Result:= CheckCl(USelButton1, FSelButton1) or Result;
  Result:= CheckCl(USelButton2, FSelButton2) or Result;
  Result:= CheckCl(ULight, FLight) or Result;
  Result:= CheckCl(UDark, FDark) or Result;
  Result:= CheckCl(UCheck, FCheck) or Result;
  Result:= CheckCl(UButton, FButton) or Result;
  Result:= CheckCl(UCheckedButton, FCheckedButton) or Result;
  Result:= CheckCl(URaised1, FRaised1) or Result;
  Result:= CheckCl(URaised2, FRaised2) or Result;
  Result:= CheckCl(UDisabled, FDisabled) or Result;
  Result:= CheckCl(UMenu, FMenu) or Result;

  if Result then ColorsChanged;
end;

procedure TRSColorTheme.DrawGlyph(Canvas:TCanvas; x,y:int; Glyph:TBitmap;
   State:TOwnerDrawState; Back:TColor; TempGlyph:boolean=false);
var Bmp:TBitmap; i,j:int;
begin
  if odDisabled in State then
  begin
    if GrayscaleDisable then
    begin
      //i:=Disabled;

      i:=RSGetIntensity(ColorToRGB(Back));
      i:=i or i shl 8 or i shl 16;
      Back:=i;
      i:=RSGetIntensity(Disabled);
      i:=i or i shl 8 or i shl 16;
      {}
      if i>Back then
      begin
        j:=i;
        i:=Back;
        Back:=j;
      end;

      if TempGlyph then
      begin
        RSGrayscaleSpec(Glyph, Back, i);
        Canvas.Draw(x, y, Glyph);
      end else
      begin
        Bmp:=TBitmap.Create;
        Bmp.Assign(Glyph);
        try
          RSGrayscaleSpec(Bmp, Back, i);
          Canvas.Draw(x, y, Bmp);
        finally
          Bmp.Free;
        end;
      end;
    end else
    begin
      RSDrawDisabled(Canvas, Glyph, FHighlight, x, y+1);
      RSDrawDisabled(Canvas, Glyph, Disabled, x, y);
    end;
  end else
  begin
     // Выпячивание
    if (State*[odSelected, odHotLight]<>[]) and FRaisedGlyphs then
    begin
      RSDrawMask(Canvas, Glyph, Raised1, x-1, y-1);
      RSDrawMask(Canvas, Glyph, Raised2, x+1, y+1);
    end;

     // Картинка
    Canvas.Draw(x, y, Glyph);
  end;
end;

procedure TRSColorTheme.DrawCheck(Canvas:TCanvas; r:TRect; Enabled:Boolean;
   RectEl:int; GradientEdge:int=1);
begin
  with Canvas do
  begin
    Brush.Color := Check;
    if Enabled then
      Pen.Color := SelBorder
    else
      Pen.Color:=RSMixColors(SelBorder, Gutter, 160);

    RoundRect(r.Left, r.Top, r.Right, r.Bottom, RectEl, RectEl);

     // Не на всяких RectEl годится
    if Enabled then
    begin
      RSGradientV(Canvas, Rect(r.Left+GradientEdge, r.Top+1,
        r.Right-GradientEdge, r.Top+4+GradientEdge), Light, Check);
      RSGradientV(Canvas, Rect(r.Left+GradientEdge, r.Bottom-4-GradientEdge,
        r.Right-GradientEdge, r.Bottom-1), Check, Dark);
      {
      RSGradientV(Canvas, Rect(r.Left+GradientEdge, r.Top+1,
        r.Right-GradientEdge, r.Top+5), Light, Check);
      RSGradientV(Canvas, Rect(r.Left+GradientEdge, r.Bottom-5,
        r.Right-GradientEdge, r.Bottom-1), Check, Dark);
      }
    end;

    Brush.Style := bsClear;
    RoundRect(r.Left, r.Top, r.Right, r.Bottom, RectEl, RectEl);
    Brush.Style := bsSolid;
  end;
end;

procedure TRSColorTheme.DrawHotTrackBackground(Canvas:TCanvas; const r:TRect);
begin
  Canvas.Brush.Color:= SelBorder;
  Canvas.FrameRect(r);
  RSGradientV(Canvas, DecRect(r), Selected1, Selected2);
end;

{
procedure RSSetCommonColors(var FColors:TRSColorTheme; v:boolean);
begin
  if v then
  begin
    FColors.Free;
    FColors:=RSColorTheme;
  end else
  begin
    FColors:=TRSColorTheme.Create;
    FColors.Assign(RSColorTheme);
  end;
end;
}

initialization

finalization
  Theme.Free;
end.

